import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GreetingWidget extends StatelessWidget {
  const GreetingWidget({super.key});

  String _getTimeBasedGreeting() {
    final hour = MoodyClock.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning explorer 👋';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon explorer 👋';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening explorer 👋';
    } else {
      return 'Hi night owl explorer 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _getTimeBasedGreeting(),
      style: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
} 