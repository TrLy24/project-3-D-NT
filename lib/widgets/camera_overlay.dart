import 'package:flutter/material.dart';

class CameraScannerOverlay extends StatefulWidget {
  final double scanWidth;
  final double scanHeight;

  const CameraScannerOverlay({
    super.key,
    this.scanWidth = 280,
    this.scanHeight = 360,
  });

  @override
  State<CameraScannerOverlay> createState() => _CameraScannerOverlayState();
}

class _CameraScannerOverlayState extends State<CameraScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _OverlayPainter(
            scanWidth: widget.scanWidth,
            scanHeight: widget.scanHeight,
            laserProgress: _animController.value,
          ),
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double scanWidth;
  final double scanHeight;
  final double laserProgress;

  _OverlayPainter({
    required this.scanWidth,
    required this.scanHeight,
    required this.laserProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scanRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: scanWidth,
      height: scanHeight,
    );

    // 1. Semi-transparent dark overlay outside the scan box
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(bgPath, bgPaint);

    // 2. Scan box border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
      borderPaint,
    );

    // 3. Four corner guide brackets
    final cornerPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;

    // Top-Left
    canvas.drawLine(
      scanRect.topLeft,
      scanRect.topLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.topLeft,
      scanRect.topLeft + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Top-Right
    canvas.drawLine(
      scanRect.topRight,
      scanRect.topRight - const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.topRight,
      scanRect.topRight + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom-Left
    canvas.drawLine(
      scanRect.bottomLeft,
      scanRect.bottomLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.bottomLeft,
      scanRect.bottomLeft - const Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom-Right
    canvas.drawLine(
      scanRect.bottomRight,
      scanRect.bottomRight - const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.bottomRight,
      scanRect.bottomRight - const Offset(0, cornerLength),
      cornerPaint,
    );

    // 4. Animated Laser Line
    final laserY = scanRect.top + (scanRect.height * laserProgress);
    final laserPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF818CF8).withValues(alpha: 0.9),
              const Color(0xFF6366F1),
              const Color(0xFF818CF8).withValues(alpha: 0.9),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(scanRect.left, laserY - 1, scanRect.width, 2),
          )
      ..strokeWidth = 2.5;

    canvas.drawLine(
      Offset(scanRect.left + 8, laserY),
      Offset(scanRect.right - 8, laserY),
      laserPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.laserProgress != laserProgress;
  }
}
