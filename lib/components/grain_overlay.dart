import 'dart:math';
import 'dart:ui'; // Needed for PointMode
import 'package:flutter/material.dart';

class GrainOverlay extends StatelessWidget {
  const GrainOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.06, // Slight visibility
        child: CustomPaint(painter: _GrainPainter(), size: Size.infinite),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    final random = Random(42);

    final area = size.width * size.height;
    final pointCount = (area * 0.005).toInt().clamp(
      0,
      10000,
    ); // 0.5% coverage, capped

    final points = List.generate(pointCount, (index) {
      return Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
    });

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
