import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../profile/domain/providers/profile_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

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
    
    final l10n = AppLocalizations.of(context)!;
    final userName = profileAsync.when(
      data: (profile) {
        final fullName = profile?.fullName;
        if (fullName != null && fullName.isNotEmpty) {
          return fullName.split(' ').first;
        }
        return l10n.moodyIntroNameFallback;
      },
      loading: () => l10n.moodyIntroNameFallback,
      error: (_, __) => l10n.moodyIntroNameFallback,
    );

    // Generate personalized preview activities based on preferences
    final previewActivities = _generatePreviewActivities(preferences, l10n);

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
                        Color(0xFF2A6049),
                        Color(0xFF6DE89A),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A6049).withOpacity(0.3),
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
                  l10n.moodyIntroGreeting(userName),
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A202C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.moodyIntroImMoody,
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
                  l10n.moodyIntroSubtext,
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
                        l10n.moodyIntroSuggestActivities,
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
                  l10n.readyToCreateYourFirstDay,
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
                      backgroundColor: const Color(0xFF2A6049),
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
                            l10n.createMyFirstDay,
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
                  l10n.moodyIntroTakesLessThan,
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
                    l10n.skipForNow,
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
  List<Map<String, String>> _generatePreviewActivities(UserPreferences prefs, AppLocalizations l10n) {
    final activities = <Map<String, String>>[];
    
    // Map travel interests to activity examples (keys match provider: Food, Arts, etc. or legacy Food & Dining)
    final interests = prefs.travelInterests;
    final styles = prefs.travelStyles;
    
    if (interests.contains('Food') || interests.contains('Food & Dining')) {
      activities.add({'emoji': '🍽️', 'text': l10n.moodyIntroActLocalRestaurant});
    } else if (interests.contains('Arts') || interests.contains('Arts & Culture')) {
      activities.add({'emoji': '🎨', 'text': l10n.moodyIntroActMuseum});
    } else if (interests.contains('Shopping') || interests.contains('Shopping & Markets')) {
      activities.add({'emoji': '🛍️', 'text': l10n.moodyIntroActLocalMarket});
    } else if (interests.contains('Nature & Outdoors')) {
      activities.add({'emoji': '🌲', 'text': l10n.moodyIntroActNature});
    } else if (interests.contains('Nightlife')) {
      activities.add({'emoji': '🍸', 'text': l10n.moodyIntroActNightlife});
    } else if (interests.contains('Wellness & Relaxation')) {
      activities.add({'emoji': '🧘', 'text': l10n.moodyIntroActSpa});
    } else {
      activities.add({'emoji': '☕', 'text': l10n.moodyIntroActCoffee});
    }
    
    if (styles.contains('Adventurous') || styles.contains('Spontaneous')) {
      activities.add({'emoji': '🏃', 'text': l10n.moodyIntroActAdventure});
    } else if (styles.contains('Relaxed')) {
      activities.add({'emoji': '🌅', 'text': l10n.moodyIntroActPeacefulWalk});
    } else if (styles.contains('Cultural') || styles.contains('Local Experience')) {
      activities.add({'emoji': '🏛️', 'text': l10n.moodyIntroActHistorical});
    } else if (styles.contains('Romantic')) {
      activities.add({'emoji': '💕', 'text': l10n.moodyIntroActRomantic});
    } else if (styles.contains('Social')) {
      activities.add({'emoji': '👥', 'text': l10n.moodyIntroActSocial});
    } else {
      activities.add({'emoji': '🌆', 'text': l10n.moodyIntroActScenic});
    }
    
    if (prefs.preferredTimeSlots.contains('morning')) {
      activities.add({'emoji': '🌄', 'text': l10n.moodyIntroActEarlyMorning});
    } else if (prefs.preferredTimeSlots.contains('evening')) {
      activities.add({'emoji': '🌃', 'text': l10n.moodyIntroActEvening});
    } else if (prefs.preferredTimeSlots.contains('afternoon')) {
      activities.add({'emoji': '🎭', 'text': l10n.moodyIntroActAfternoon});
    } else {
      activities.add({'emoji': '✨', 'text': l10n.moodyIntroActSurprise});
    }
    
    final defaultActivities = _getDefaultPreviewActivities(l10n);
    while (activities.length < 3) {
      final defaultToAdd = defaultActivities[activities.length % defaultActivities.length];
      if (!activities.any((a) => a['text'] == defaultToAdd['text'])) {
        activities.add(defaultToAdd);
      } else {
        final nextDefault = defaultActivities[(activities.length + 1) % defaultActivities.length];
        activities.add(nextDefault);
      }
    }
    
    return activities.take(3).toList();
  }

  /// Default preview activities when preferences are not available
  List<Map<String, String>> _getDefaultPreviewActivities(AppLocalizations l10n) {
    return [
      {'emoji': '☕', 'text': l10n.moodyIntroActCoffee},
      {'emoji': '🛍️', 'text': l10n.moodyIntroActMarketVisit},
      {'emoji': '🌅', 'text': l10n.moodyIntroActEveningWalk},
    ];
  }
}

