import 'dart:math' as math;

import 'package:flutter/material.dart';

class DailySpendPoint {
  final String dayLabel; // "T2", "T3", "T4", "T5", "T6", "T7", "CN"
  final double amount;
  final bool isToday;

  const DailySpendPoint({
    required this.dayLabel,
    required this.amount,
    this.isToday = false,
  });
}

class WeeklyBarChart extends StatefulWidget {
  final List<DailySpendPoint> dailyData;
  final double height;
  final Function(int? selectedDayIndex)? onDaySelected;

  const WeeklyBarChart({
    super.key,
    required this.dailyData,
    this.height = 190,
    this.onDaySelected,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  int? _selectedBarIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dailyData != widget.dailyData) {
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
    if (widget.dailyData.isEmpty) return;

    const leftPadding = 36.0;
    const rightPadding = 16.0;
    final availableWidth = size.width - leftPadding - rightPadding;
    final slotWidth = availableWidth / widget.dailyData.length;

    if (localPosition.dx < leftPadding ||
        localPosition.dx > size.width - rightPadding) {
      setState(() => _selectedBarIndex = null);
      widget.onDaySelected?.call(null);
      return;
    }

    final tappedIndex = ((localPosition.dx - leftPadding) / slotWidth).floor();
    if (tappedIndex >= 0 && tappedIndex < widget.dailyData.length) {
      setState(() {
        _selectedBarIndex = (_selectedBarIndex == tappedIndex)
            ? null
            : tappedIndex;
      });
      widget.onDaySelected?.call(_selectedBarIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, widget.height);
            return GestureDetector(
              onTapUp: (details) => _handleTap(details.localPosition, size),
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: CustomPaint(
                  key: const ValueKey('WeeklyBarChartCanvas'),
                  painter: _WeeklyBarChartPainter(
                    dailyData: widget.dailyData,
                    progress: _animation.value,
                    selectedBarIndex: _selectedBarIndex,
                    surfaceColor: Theme.of(context).colorScheme.surface,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    secondaryTextColor: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                    gridColor: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WeeklyBarChartPainter extends CustomPainter {
  final List<DailySpendPoint> dailyData;
  final double progress;
  final int? selectedBarIndex;
  final Color surfaceColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color gridColor;

  _WeeklyBarChartPainter({
    required this.dailyData,
    required this.progress,
    required this.surfaceColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.gridColor,
    this.selectedBarIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 38.0;
    const rightPadding = 14.0;
    const bottomPadding = 26.0;
    const topPadding = 24.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - bottomPadding - topPadding;
    final baselineY = size.height - bottomPadding;

    // Calculate max value for scaling
    double maxVal = 0.0;
    for (final item in dailyData) {
      if (item.amount > maxVal) maxVal = item.amount;
    }
    if (maxVal <= 0) maxVal = 100000; // Default reference scale

    // 1. Draw horizontal gridlines & Y-axis labels
    _drawGridLines(
      canvas,
      leftPadding,
      chartWidth,
      topPadding,
      chartHeight,
      baselineY,
      maxVal,
    );

    if (dailyData.isEmpty) return;

    // 2. Draw bars
    final barCount = dailyData.length;
    final slotWidth = chartWidth / barCount;
    final barWidth = math.min(slotWidth * 0.48, 22.0);

    for (int i = 0; i < barCount; i++) {
      final point = dailyData[i];
      final isSelected = selectedBarIndex == i;
      final slotCenterX = leftPadding + (i * slotWidth) + (slotWidth / 2);

      final barLeft = slotCenterX - (barWidth / 2);
      final normalizedHeight = (point.amount / maxVal) * chartHeight * progress;
      final barTop = baselineY - normalizedHeight;

      // Draw background bar track
      final trackPaint = Paint()
        ..color = surfaceColor
        ..style = PaintingStyle.fill;
      final trackRRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(barLeft, topPadding, barWidth, chartHeight),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
      );
      canvas.drawRRect(trackRRect, trackPaint);

      // Draw active filled bar with gradient
      if (normalizedHeight > 0) {
        final gradientColors = point.isToday || isSelected
            ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
            : [const Color(0xFF38BDF8), const Color(0xFF0284C7)];

        final barRect = Rect.fromLTWH(
          barLeft,
          barTop,
          barWidth,
          normalizedHeight,
        );
        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ).createShader(barRect)
          ..style = PaintingStyle.fill;

        // Shadow for selected or today
        if (isSelected || point.isToday) {
          final shadowPaint = Paint()
            ..color = const Color(0xFF6366F1).withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              barRect,
              topLeft: const Radius.circular(5),
              topRight: const Radius.circular(5),
            ),
            shadowPaint,
          );
        }

        final barRRect = RRect.fromRectAndCorners(
          barRect,
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        );
        canvas.drawRRect(barRRect, barPaint);
      }

      // Draw day label below baseline
      final labelColor = point.isToday
          ? const Color(0xFF818CF8)
          : (isSelected ? textColor : secondaryTextColor);
      final labelWeight = (point.isToday || isSelected)
          ? FontWeight.bold
          : FontWeight.w500;

      final labelPainter = TextPainter(
        text: TextSpan(
          text: point.dayLabel,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: labelWeight,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(slotCenterX - (labelPainter.width / 2), baselineY + 7),
      );

      // Draw Tooltip if selected
      if (isSelected && point.amount > 0) {
        _drawTooltip(canvas, slotCenterX, barTop, point.amount);
      }
    }
  }

  void _drawGridLines(
    Canvas canvas,
    double leftPadding,
    double chartWidth,
    double topPadding,
    double chartHeight,
    double baselineY,
    double maxVal,
  ) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const divisions = 3;
    for (int i = 0; i <= divisions; i++) {
      final y = baselineY - (i * (chartHeight / divisions));
      // Grid line
      canvas.drawLine(
        Offset(leftPadding - 4, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );

      // Y-axis value text
      final val = (maxVal / divisions) * i;
      final valStr = val >= 1000000
          ? '${(val / 1000000).toStringAsFixed(1)}M'
          : '${(val / 1000).toStringAsFixed(0)}k';

      final yLabelPainter = TextPainter(
        text: TextSpan(
          text: valStr,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      yLabelPainter.paint(
        canvas,
        Offset(
          leftPadding - yLabelPainter.width - 7,
          y - (yLabelPainter.height / 2),
        ),
      );
    }
  }

  void _drawTooltip(Canvas canvas, double cx, double cy, double amount) {
    final amountText = amount >= 1000000
        ? '${(amount / 1000000).toStringAsFixed(2)} Tr ₫'
        : '${(amount / 1000).toStringAsFixed(0)}k ₫';

    final textPainter = TextPainter(
      text: TextSpan(
        text: amountText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tooltipW = textPainter.width + 12;
    final tooltipH = textPainter.height + 6;
    final tooltipX = cx - (tooltipW / 2);
    final tooltipY = cy - tooltipH - 6;

    final bgPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipW, tooltipH),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, bgPaint);

    textPainter.paint(canvas, Offset(tooltipX + 6, tooltipY + 3));
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedBarIndex != selectedBarIndex ||
        oldDelegate.dailyData != dailyData ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.secondaryTextColor != secondaryTextColor ||
        oldDelegate.gridColor != gridColor;
  }
}
