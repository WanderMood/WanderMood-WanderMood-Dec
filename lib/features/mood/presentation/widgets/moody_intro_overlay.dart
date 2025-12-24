import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../profile/domain/providers/profile_provider.dart';
import '../../../../core/providers/preferences_provider.dart';

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
    final preferences = ref.watch(preferencesProvider);
    
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

    // Generate personalized preview activities based on preferences
    final previewActivities = _generatePreviewActivities(preferences);

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

                // Preview Card - Personalized based on user preferences
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
                      ...previewActivities.asMap().entries.map((entry) {
                        final index = entry.key;
                        final activity = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < previewActivities.length - 1 ? 10 : 0),
                          child: _buildPreviewItem(activity['emoji']!, activity['text']!),
                        );
                      }),
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

  /// Generate personalized preview activities based on user preferences
  List<Map<String, String>> _generatePreviewActivities(UserPreferences prefs) {
    final activities = <Map<String, String>>[];
    
    // Map travel interests to activity examples
    final interests = prefs.travelInterests;
    final styles = prefs.travelStyles;
    
    // Generate activities based on preferences
    if (interests.contains('Food & Dining')) {
      activities.add({'emoji': '🍽️', 'text': 'Local restaurant discovery'});
    } else if (interests.contains('Arts & Culture')) {
      activities.add({'emoji': '🎨', 'text': 'Museum or gallery visit'});
    } else if (interests.contains('Shopping & Markets')) {
      activities.add({'emoji': '🛍️', 'text': 'Local market exploration'});
    } else if (interests.contains('Nature & Outdoors')) {
      activities.add({'emoji': '🌲', 'text': 'Nature walk or park visit'});
    } else if (interests.contains('Nightlife')) {
      activities.add({'emoji': '🍸', 'text': 'Evening bar or lounge'});
    } else if (interests.contains('Wellness & Relaxation')) {
      activities.add({'emoji': '🧘', 'text': 'Spa or wellness experience'});
    } else {
      activities.add({'emoji': '☕', 'text': 'Morning coffee spot'});
    }
    
    // Add activity based on travel styles
    if (styles.contains('Adventurous')) {
      activities.add({'emoji': '🏃', 'text': 'Active outdoor adventure'});
    } else if (styles.contains('Relaxed')) {
      activities.add({'emoji': '🌅', 'text': 'Peaceful evening walk'});
    } else if (styles.contains('Cultural')) {
      activities.add({'emoji': '🏛️', 'text': 'Historical site visit'});
    } else if (styles.contains('Romantic')) {
      activities.add({'emoji': '💕', 'text': 'Romantic dining experience'});
    } else if (styles.contains('Social')) {
      activities.add({'emoji': '👥', 'text': 'Social gathering spot'});
    } else {
      activities.add({'emoji': '🌆', 'text': 'Scenic viewpoint'});
    }
    
    // Add a third activity based on preferred time slots
  if (prefs.preferredTimeSlots.contains('morning')) {
      activities.add({'emoji': '🌄', 'text': 'Early morning experience'});
    } else if (prefs.preferredTimeSlots.contains('evening')) {
      activities.add({'emoji': '🌃', 'text': 'Evening entertainment'});
    } else if (prefs.preferredTimeSlots.contains('afternoon')) {
      activities.add({'emoji': '🎭', 'text': 'Afternoon activity'});
    } else {
      activities.add({'emoji': '✨', 'text': 'Surprise discovery'});
    }
    
    // Ensure we have exactly 3 activities (fill with defaults if needed)
    final defaultActivities = _getDefaultPreviewActivities();
    while (activities.length < 3) {
      final defaultToAdd = defaultActivities[activities.length % defaultActivities.length];
      if (!activities.any((a) => a['text'] == defaultToAdd['text'])) {
        activities.add(defaultToAdd);
      } else {
        // If duplicate, add a different default
        final nextDefault = defaultActivities[(activities.length + 1) % defaultActivities.length];
        activities.add(nextDefault);
      }
    }
    
    return activities.take(3).toList();
  }

  /// Default preview activities when preferences are not available
  List<Map<String, String>> _getDefaultPreviewActivities() {
    return [
      {'emoji': '☕', 'text': 'Morning coffee spot'},
      {'emoji': '🛍️', 'text': 'Local market visit'},
      {'emoji': '🌅', 'text': 'Evening walk with a view'},
    ];
  }
}

