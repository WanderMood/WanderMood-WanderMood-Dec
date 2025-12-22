import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../profile/domain/providers/profile_provider.dart';

/// Overlay widget that introduces Moody to first-time users
/// Shows as a centered modal on top of blurred Moody Hub background
class MoodyIntroOverlay extends ConsumerWidget {
  final VoidCallback onCreateDay;
  final VoidCallback onSkip;

  const MoodyIntroOverlay({
    super.key,
    required this.onCreateDay,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user's name from profile
    final profileAsync = ref.watch(profileProvider);
    final userName = profileAsync.when(
      data: (profile) {
        final fullName = profile?.fullName;
        if (fullName != null && fullName.isNotEmpty) {
          return fullName.split(' ').first;
        }
        return 'there';
      },
      loading: () => 'there',
      error: (_, __) => 'there',
    );

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withOpacity(0.3), // Light dark overlay
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 48,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                // Moody Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF12B347),
                        Color(0xFF6DE89A),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF12B347).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: MoodyCharacter(
                      size: 75,
                      mood: 'excited',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Greeting
                Text(
                  'Hey $userName! 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A202C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'I\'m Moody.',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A202C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Subtext
                Text(
                  'I\'m here to help you plan days that match your mood, energy, and vibe.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: const Color(0xFF4A5568),
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Preview Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I\'ll suggest activities like:',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF4A5568),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildPreviewItem('☕', 'Morning coffee spot'),
                      const SizedBox(height: 10),
                      _buildPreviewItem('🛍️', 'Local market visit'),
                      const SizedBox(height: 10),
                      _buildPreviewItem('🌅', 'Evening walk with a view'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Question
                Text(
                  'Ready to create your first day?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A202C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Primary CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onCreateDay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12B347),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Create my first day',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Micro-copy
                Text(
                  'Takes less than a minute • Uses your preferences',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF718096),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Skip link
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  ),
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF718096),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF718096),
                    ),
                  ),
                ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF1A202C), // Dark text for readability
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

