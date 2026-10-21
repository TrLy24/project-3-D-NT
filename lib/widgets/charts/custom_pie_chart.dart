import 'dart:math' as math;

import 'package:flutter/material.dart';

class ChartDataPoint {
  final String label;
  final double value;
  final Color color;
  final String categoryId;

  const ChartDataPoint({
    required this.label,
    required this.value,
    required this.color,
    required this.categoryId,
  });
}

class CustomDonutChart extends StatefulWidget {
  final List<ChartDataPoint> data;
  final double totalAmount;
  final bool isDonut;
  final double size;
  final Function(int? selectedIndex)? onSegmentSelected;

  const CustomDonutChart({
    super.key,
    required this.data,
    required this.totalAmount,
    this.isDonut = true,
    this.size = 240,
    this.onSegmentSelected,
  });

  @override
  State<CustomDonutChart> createState() => _CustomDonutChartState();
}

class _CustomDonutChartState extends State<CustomDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(CustomDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount ||
        oldWidget.data.length != widget.data.length) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final outerRadius = math.min(size.width, size.height) / 2 * 0.9;
    final innerRadius = widget.isDonut ? outerRadius * 0.62 : 0.0;

    if (distance < innerRadius || distance > outerRadius) {
      setState(() => _hoveredIndex = null);
      widget.onSegmentSelected?.call(null);
      return;
    }

    // Angle in radians from [-pi, pi], convert to [0, 2*pi] with -pi/2 offset
    var angle = math.atan2(dy, dx) + (math.pi / 2);
    if (angle < 0) angle += 2 * math.pi;

    double currentAngle = 0.0;
    final total = widget.totalAmount > 0 ? widget.totalAmount : 1.0;

    for (int i = 0; i < widget.data.length; i++) {
      final sweep = (widget.data[i].value / total) * 2 * math.pi;
      if (angle >= currentAngle && angle <= currentAngle + sweep) {
        setState(() {
          _hoveredIndex = (_hoveredIndex == i) ? null : i;
        });
        widget.onSegmentSelected?.call(_hoveredIndex);
        return;
      }
      currentAngle += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GestureDetector(
          onTapUp: (details) =>
              _handleTap(details.localPosition, Size(widget.size, widget.size)),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              key: const ValueKey('CustomDonutChartCanvas'),
              painter: _DonutChartPainter(
                data: widget.data,
                totalAmount: widget.totalAmount,
                isDonut: widget.isDonut,
                progress: _animation.value,
                selectedIndex: _hoveredIndex,
                surfaceColor: Theme.of(context).colorScheme.surface,
                textColor: Theme.of(context).colorScheme.onSurface,
                secondaryTextColor: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                emptyColor: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double totalAmount;
  final bool isDonut;
  final double progress;
  final int? selectedIndex;
  final Color surfaceColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color emptyColor;

  _DonutChartPainter({
    required this.data,
    required this.totalAmount,
    required this.isDonut,
    required this.progress,
    required this.surfaceColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.emptyColor,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 * 0.9;
    final innerRadius = isDonut ? outerRadius * 0.62 : 0.0;

    if (data.isEmpty || totalAmount <= 0) {
      _drawEmptyState(canvas, center, outerRadius, innerRadius);
      return;
    }

    double startAngle = -math.pi / 2; // Start at 12 o'clock

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweepAngle = (item.value / totalAmount) * 2 * math.pi * progress;
      final isSelected = selectedIndex == i;

      // Slice translation offset when selected (highlight interaction)
      Offset sliceCenter = center;
      if (isSelected) {
        final midAngle = startAngle + (sweepAngle / 2);
        const offsetDist = 8.0;
        sliceCenter = Offset(
          center.dx + math.cos(midAngle) * offsetDist,
          center.dy + math.sin(midAngle) * offsetDist,
        );
      }

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      // Draw shadow for selected slice
      if (isSelected) {
        final shadowPaint = Paint()
          ..color = item.color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        final shadowPath = _buildArcPath(
          sliceCenter,
          innerRadius,
          outerRadius + 3,
          startAngle,
          sweepAngle,
        );
        canvas.drawPath(shadowPath, shadowPaint);
      }

      final path = _buildArcPath(
        sliceCenter,
        innerRadius,
        isSelected ? outerRadius + 4 : outerRadius,
        startAngle,
        sweepAngle,
      );

      canvas.drawPath(path, paint);

      // Draw slice border separator
      final borderPaint = Paint()
        ..color = surfaceColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..isAntiAlias = true;
      canvas.drawPath(path, borderPaint);

      startAngle += sweepAngle;
    }

    // Draw Donut Center Hole Text & Info
    if (isDonut) {
      _drawCenterHoleContent(canvas, center, innerRadius);
    }
  }

  Path _buildArcPath(
    Offset center,
    double innerR,
    double outerR,
    double startA,
    double sweepA,
  ) {
    final path = Path();
    if (innerR <= 0) {
      // Full Pie slice
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerR),
        startA,
        sweepA,
        false,
      );
      path.close();
    } else {
      // Donut segment (Annulus sector)
      final outerRect = Rect.fromCircle(center: center, radius: outerR);
      final innerRect = Rect.fromCircle(center: center, radius: innerR);

      path.arcTo(outerRect, startA, sweepA, false);
      // Connect to inner arc and sweep backwards
      path.arcTo(innerRect, startA + sweepA, -sweepA, false);
      path.close();
    }
    return path;
  }

  void _drawCenterHoleContent(
    Canvas canvas,
    Offset center,
    double innerRadius,
  ) {
    // Inner background circle with subtle shadow
    final bgPaint = Paint()..color = surfaceColor;
    canvas.drawCircle(center, innerRadius - 2, bgPaint);

    final titlePainter = TextPainter(
      text: TextSpan(
        text: 'Tổng chi tiêu',
        style: TextStyle(
          color: secondaryTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: innerRadius * 1.8);

    final totalText = _formatCompactCurrency(totalAmount);
    final valuePainter = TextPainter(
      text: TextSpan(
        text: totalText,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: innerRadius * 1.8);

    titlePainter.paint(
      canvas,
      Offset(center.dx - (titlePainter.width / 2), center.dy - 16),
    );
    valuePainter.paint(
      canvas,
      Offset(center.dx - (valuePainter.width / 2), center.dy + 2),
    );
  }

  void _drawEmptyState(
    Canvas canvas,
    Offset center,
    double outerR,
    double innerR,
  ) {
    final paint = Paint()
      ..color = emptyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDonut ? (outerR - innerR) : outerR;

    final circleRadius = isDonut ? (outerR + innerR) / 2 : outerR / 2;
    canvas.drawCircle(center, circleRadius, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Chưa có chi tiêu',
        style: TextStyle(color: secondaryTextColor, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)} Tr';
    }
    return '${(amount / 1000).toStringAsFixed(0)}k ₫';
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.totalAmount != totalAmount ||
        oldDelegate.data != data ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.secondaryTextColor != secondaryTextColor ||
        oldDelegate.emptyColor != emptyColor;
  }
}
