import 'dart:math' as math;
import 'package:flutter/material.dart';

class CountdownRingPainter extends CustomPainter {
  final double progress; // 0.0 = empty, 1.0 = full
  final Color ringColor;
  final Color bgColor;
  final double strokeWidth;
  final bool isWarning;

  CountdownRingPainter({
    required this.progress,
    this.ringColor = const Color(0xFFFFE066),
    this.bgColor = const Color(0xFFE8E8E8),
    this.strokeWidth = 8,
    this.isWarning = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = isWarning ? const Color(0xFFDC2626) : ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isWarning != isWarning;
}
