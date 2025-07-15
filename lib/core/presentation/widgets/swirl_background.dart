import 'package:flutter/material.dart';
import 'dart:math' as math;

class SwirlingGradientPainter extends CustomPainter {
  final bool isDarkMode;
  
  SwirlingGradientPainter({this.isDarkMode = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create flowing wave gradients with colors based on theme
    final Paint wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDarkMode ? [
          const Color(0xFF0D1117).withOpacity(0.95),  // Dark blue-gray
          const Color(0xFF161B22).withOpacity(0.85),  // Lighter dark gray
          const Color(0xFF21262D).withOpacity(0.75),  // Medium dark gray
        ] : [
          const Color(0xFFFFFDF5).withOpacity(0.95),  // Warm cream yellow
          const Color(0xFFFFF3E0).withOpacity(0.85),  // Slightly darker warm yellow
          const Color(0xFFFFF9E8).withOpacity(0.75),  // Medium warm yellow
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Create accent wave paint with higher opacity
    final Paint accentPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDarkMode ? [
          const Color(0xFF161B22).withOpacity(0.85),  // Lighter dark gray
          const Color(0xFF21262D).withOpacity(0.75),  // Medium dark gray
          const Color(0xFF0D1117).withOpacity(0.65),  // Dark blue-gray
        ] : [
          const Color(0xFFFFF3E0).withOpacity(0.85),  // Slightly darker warm yellow
          const Color(0xFFFFF9E8).withOpacity(0.75),  // Medium warm yellow
          const Color(0xFFFFFDF5).withOpacity(0.65),  // Warm cream yellow
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final Path mainWavePath = Path();
    final Path accentWavePath = Path();

    // Create multiple flowing wave layers with larger amplitude
    for (int i = 0; i < 3; i++) {
      double amplitude = size.height * 0.12;  // Increased from 0.08
      double frequency = math.pi / (size.width * 0.4);  // Adjusted for wider waves
      double verticalOffset = size.height * (0.2 + i * 0.3);

      mainWavePath.moveTo(0, verticalOffset);
      
      // Create more pronounced flowing wave
      for (double x = 0; x <= size.width; x += 4) {  // Decreased step for smoother waves
        double y = verticalOffset + 
                   math.sin(x * frequency + i) * amplitude +
                   math.cos(x * frequency * 0.5) * amplitude * 0.9;  // Increased from 0.7
        
        if (x == 0) {
          mainWavePath.moveTo(x, y);
        } else {
          mainWavePath.lineTo(x, y);
        }
      }

      // Create accent waves with larger amplitude
      amplitude = size.height * 0.09;  // Increased from 0.06
      verticalOffset = size.height * (0.1 + i * 0.3);
      
      for (double x = 0; x <= size.width; x += 4) {  // Decreased step for smoother waves
        double y = verticalOffset + 
                   math.sin(x * frequency * 1.5 + i + math.pi) * amplitude +
                   math.cos(x * frequency * 0.7) * amplitude * 1.2;  // Increased multiplier
        
        if (x == 0) {
          accentWavePath.moveTo(x, y);
        } else {
          accentWavePath.lineTo(x, y);
        }
      }
    }

    // Create more pronounced flowing curves
    for (int i = 0; i < 2; i++) {
      double startY = size.height * (0.3 + i * 0.4);
      double controlY = size.height * (0.1 + i * 0.4);  // Lower control point for more curve
      
      mainWavePath.moveTo(0, startY);
      mainWavePath.quadraticBezierTo(
        size.width * 0.5,
        controlY,
        size.width,
        startY
      );
    }

    // Add larger dots along the waves
    for (int i = 0; i < 15; i++) {  // Increased number of dots
      double x = size.width * (i / 15);
      double y = size.height * (0.3 + math.sin(i * 0.8) * 0.25);  // Increased amplitude
      
      canvas.drawCircle(
        Offset(x, y),
        5,  // Increased from 4
        wavePaint
      );
    }

    // Draw all elements with stronger blur effect
    canvas.drawPath(mainWavePath, wavePaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));  // Increased from 4
    canvas.drawPath(accentWavePath, accentPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));  // Increased from 3
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SwirlBackground extends StatelessWidget {
  final Widget child;

  const SwirlBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode ? [
            const Color(0xFF0D1117), // Very dark blue-gray
            const Color(0xFF161B22), // Slightly lighter dark gray
          ] : [
            const Color(0xFFFFFDF5), // Warm cream yellow
            const Color(0xFFFFF3E0), // Slightly darker warm yellow
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background swirl effect
          Positioned.fill(
            child: CustomPaint(
              painter: SwirlingGradientPainter(isDarkMode: isDarkMode),
            ),
          ),
          // Main content
          child,
        ],
      ),
    );
  }
} 