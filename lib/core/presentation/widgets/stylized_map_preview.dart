import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Decorative map-style preview when a live static map is loading or unavailable.
class StylizedMapPreview extends StatelessWidget {
  const StylizedMapPreview({
    super.key,
    required this.lat,
    required this.lng,
    this.showPin = true,
  });

  final double lat;
  final double lng;
  final bool showPin;

  @override
  Widget build(BuildContext context) {
    final seed = (lat.abs() * 1e4 + lng.abs() * 1e4).floor();
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _StylizedMapPainter(seed: seed)),
        if (showPin)
          Center(
            child: Icon(
              Icons.location_on,
              size: 44,
              color: const Color(0xFF2A6049),
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StylizedMapPainter extends CustomPainter {
  _StylizedMapPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE8EFE9),
          Color(0xFFDDE8DF),
          Color(0xFFE5EDE7),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    final rnd = math.Random(seed);
    final blockPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 14; i++) {
      final w = size.width * (0.08 + rnd.nextDouble() * 0.18);
      final h = size.height * (0.08 + rnd.nextDouble() * 0.22);
      final maxLeft = size.width > w ? size.width - w : 0.0;
      final maxTop = size.height > h ? size.height - h : 0.0;
      final left = rnd.nextDouble() * maxLeft;
      final top = rnd.nextDouble() * maxTop;
      final light = rnd.nextBool();
      blockPaint.color = light
          ? const Color(0xFFD0DCD3).withValues(alpha: 0.55)
          : const Color(0xFFC5D1C8).withValues(alpha: 0.45);
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(r, blockPaint);
    }

    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.42),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, 0),
      Offset(size.width * 0.48, size.height),
      roadPaint,
    );

    final riverPaint = Paint()
      ..color = const Color(0xFFB8D4E8).withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.52,
        size.width * 0.92,
        size.height * 0.18,
      );
    canvas.drawPath(path, riverPaint);
  }

  @override
  bool shouldRepaint(covariant _StylizedMapPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
