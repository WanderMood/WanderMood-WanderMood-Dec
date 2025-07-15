import 'package:flutter/material.dart';
import 'dart:math' as math;

class CirclePatternPainter extends CustomPainter {
  final Color color;
  final int density;
  final double maxRadius;

  CirclePatternPainter({
    required this.color,
    this.density = 20,
    this.maxRadius = 30,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final random = math.Random(42); // Fixed seed for consistent pattern
    
    for (var i = 0; i < density; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * maxRadius;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
      
      // Add some connecting lines for extra visual interest
      if (i > 0) {
        final prevX = random.nextDouble() * size.width;
        final prevY = random.nextDouble() * size.height;
        canvas.drawLine(
          Offset(x, y),
          Offset(prevX, prevY),
          paint..strokeWidth = 0.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CirclePatternPainter oldDelegate) =>
      color != oldDelegate.color ||
      density != oldDelegate.density ||
      maxRadius != oldDelegate.maxRadius;
} 