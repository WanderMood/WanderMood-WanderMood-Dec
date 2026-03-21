import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';

class PlanLoadingOverlay extends StatelessWidget {
  final String message;

  const PlanLoadingOverlay({
    super.key,
    this.message = 'Preparing your adventure...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Moody character
            Container(
              height: 180,
              alignment: Alignment.center,
              child: MoodyCharacter(
                size: 150,
                mood: 'celebrating',
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).scale(
                duration: const Duration(milliseconds: 2000),
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                curve: Curves.easeInOut,
              ),
            ),
            const SizedBox(height: 24),
            // Loading message
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2A6049),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
            ),
          ],
        ),
      ),
    );
  }
} 