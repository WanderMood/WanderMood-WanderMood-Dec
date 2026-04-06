import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/providers/feature_flags_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/features/home/domain/enums/moody_feature.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/onboarding/domain/guest_demo_activities_builder.dart';
import 'package:wandermood/features/onboarding/domain/guest_demo_l10n_helpers.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/presentation/widgets/day_plan_activity_card.dart';
import 'package:wandermood/features/plans/widgets/activity_detail_screen.dart';
import 'package:wandermood/l10n/app_localizations.dart';

const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

/// Guest preview of the real [DayPlanScreen] layout after the interactive demo.
class GuestDayPlanScreen extends ConsumerStatefulWidget {
  const GuestDayPlanScreen({super.key});

  @override
  ConsumerState<GuestDayPlanScreen> createState() => _GuestDayPlanScreenState();
}

class _GuestDayPlanScreenState extends ConsumerState<GuestDayPlanScreen> {
  bool _redirectScheduled = false;

  String _moodDisplayName(BuildContext context, String mood) {
    final l10n = AppLocalizations.of(context)!;
    final lower = mood.toLowerCase();
    if (lower == 'surprise_me') return l10n.demoMoodSurpriseMe;
    if (lower.contains('cultural') || lower.contains('culture')) return l10n.moodCultural;
    if (lower.contains('cozy') || lower.contains('cosy')) return l10n.moodCozy;
    if (lower.contains('food') || lower.contains('foody')) return l10n.moodFoody;
    if (lower.contains('relax')) return l10n.moodRelaxed;
    if (lower.contains('adventure') || lower.contains('adventurous')) return l10n.moodAdventurous;
    if (lower.contains('social')) return l10n.moodSocial;
    if (lower.contains('creative')) return l10n.moodCreative;
    if (lower.contains('romantic')) return l10n.moodRomantic;
    if (lower.contains('energetic')) return l10n.moodEnergetic;
    if (lower.contains('curious')) return l10n.moodCurious;
    return mood;
  }

  String _moodEmoji(String mood) {
    final m = mood.toLowerCase();
    if (m == 'surprise_me') return '✨';
    if (m.contains('food') || m.contains('foody')) return '🍜';
    if (m.contains('cultural') || m.contains('culture')) return '🏛️';
    if (m.contains('curious')) return '😀';
    if (m.contains('relax')) return '🧘';
    if (m.contains('adventure')) return '🏔️';
    if (m.contains('social')) return '👥';
    if (m.contains('creative')) return '🎨';
    if (m.contains('romantic')) return '💕';
    if (m.contains('energetic')) return '⚡';
    if (m.contains('contemplative')) return '🌿';
    return '✨';
  }

  /// Guest flow uses a single mood, so [DayPlanScreen]'s per-slot indexing would always pick
  /// moods[0]. Map [timeSlotIndex] 0/1/2 (morning/afternoon/evening) to distinct themes per mood.
  String _guestThemeForTimeSlot(BuildContext context, String moodTag, int timeSlotIndex) {
    final l10n = AppLocalizations.of(context)!;
    final i = timeSlotIndex.clamp(0, 2);
    final m = moodTag.toLowerCase();

    String pick(List<String> keys) => keys[i];

    if (m.contains('food') || m == 'foody') {
      return pick([
        l10n.dayPlanThemeFoodieFind,
        l10n.dayPlanThemeTrueLocalFind,
        l10n.dayPlanThemeWindDownCulture,
      ]);
    }
    if (m.contains('social')) {
      return pick([
        l10n.dayPlanThemeExploreDiscover,
        l10n.dayPlanThemeTrueLocalFind,
        l10n.dayPlanThemeSunsetVibes,
      ]);
    }
    if (m.contains('adventure')) {
      return pick([
        l10n.dayPlanThemeAdventureAwaits,
        l10n.dayPlanThemeOutdoorNature,
        l10n.dayPlanThemeTrueLocalFind,
      ]);
    }
    if (m.contains('cultural')) {
      return pick([
        l10n.dayPlanThemeCulturalDeepDive,
        l10n.dayPlanThemeTrueLocalFind,
        l10n.dayPlanThemeWindDownCulture,
      ]);
    }
    if (m.contains('romantic') || m == 'surprise_me') {
      return pick([
        l10n.dayPlanThemeRomanticMoments,
        l10n.dayPlanThemeCreativeVibes,
        l10n.dayPlanThemeSunsetVibes,
      ]);
    }
    if (m.contains('relax')) {
      return pick([
        l10n.dayPlanThemeOutdoorNature,
        l10n.dayPlanThemeTrueLocalFind,
        l10n.dayPlanThemeWindDownRelax,
      ]);
    }
    if (m.contains('creative') || m.contains('art')) {
      return pick([
        l10n.dayPlanThemeCreativeVibes,
        l10n.dayPlanThemeTrueLocalFind,
        l10n.dayPlanThemeWindDownCulture,
      ]);
    }
    return pick([
      l10n.dayPlanThemeExploreDiscover,
      l10n.dayPlanThemeTrueLocalFind,
      l10n.dayPlanThemeWindDownCulture,
    ]);
  }

  Widget _buildSectionHeader(
    BuildContext context,
    Activity activity,
    int index,
    String moodTag,
  ) {
    final l10n = AppLocalizations.of(context)!;

    late final String label;
    late final String emoji;
    late final int themeIndex;

    switch (activity.timeSlotEnum) {
      case TimeSlot.morning:
        label = l10n.dayPlanMorning;
        emoji = '☀️';
        themeIndex = 0;
        break;
      case TimeSlot.afternoon:
        label = l10n.dayPlanAfternoon;
        emoji = '🌤️';
        themeIndex = 1;
        break;
      case TimeSlot.evening:
      case TimeSlot.night:
        label = l10n.dayPlanEvening;
        emoji = '🌆';
        themeIndex = 2;
        break;
    }

    final theme = _guestThemeForTimeSlot(context, moodTag, themeIndex);
    return Padding(
      padding: EdgeInsets.only(top: index == 0 ? 4 : 20, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '· $theme',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openActivityDetail(Activity activity, {String? distanceKm}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ActivityDetailScreen(activity: activity, distanceKm: distanceKm),
      ),
    );
  }

  void _navigateToSignup() {
    ref.read(onboardingProgressProvider.notifier).markGuestExploreCompleted();
    ref.read(currentOnboardingStepProvider.notifier).state = OnboardingStep.signup;
    context.go('/auth/magic-link');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mood = ref.watch(guestDemoMoodProvider);

    if (mood == null || mood.isEmpty) {
      if (!_redirectScheduled) {
        _redirectScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/demo');
        });
      }
      return const Scaffold(
        backgroundColor: _wmCream,
        body: Center(child: CircularProgressIndicator(color: _wmForest)),
      );
    }

    final activities = buildGuestDemoActivities(mood, l10n);
    if (activities.isEmpty) {
      if (!_redirectScheduled) {
        _redirectScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/demo');
        });
      }
      return const Scaffold(
        backgroundColor: _wmCream,
        body: Center(child: CircularProgressIndicator(color: _wmForest)),
      );
    }

    final moodTag = guestDemoMoodKeyForDayPlan(mood);

    final userPos = ref.watch(userLocationProvider).valueOrNull;

    return Scaffold(
      backgroundColor: _wmCream,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/demo'),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: _wmCharcoal,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.guestDemoResultTitleWithMood(
                                  guestDemoMoodDisplayLabel(context, mood),
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: _wmCharcoal,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                l10n.guestPreviewMode,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: _wmStone,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _wmForestTint,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _wmForest, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 16, color: _wmForest),
                              const SizedBox(width: 6),
                              Text(
                                l10n.guestGuest,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _wmForest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const MoodyCharacter(
                                      size: 48,
                                      mood: 'happy',
                                      currentFeature: MoodyFeature.none,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.guestDayPlanHeadingMadeForYou,
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: _wmCharcoal,
                                              letterSpacing: -0.5,
                                              height: 1.15,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            l10n.guestDayPlanHeroHint,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: _wmStone,
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                                    .animate()
                                    .fadeIn(duration: 450.ms, curve: Curves.easeOutQuad)
                                    .slideY(
                                      begin: 0.05,
                                      end: 0,
                                      curve: Curves.easeOutQuad,
                                    ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF8A00),
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF8A00).withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(_moodEmoji(moodTag), style: const TextStyle(fontSize: 18)),
                                          const SizedBox(width: 6),
                                          Text(
                                            _moodDisplayName(context, moodTag),
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final activity = activities[i];
                                String? distanceLine;
                                if (userPos != null) {
                                  final km = DistanceService.calculateDistance(
                                    userPos.latitude,
                                    userPos.longitude,
                                    activity.location.latitude,
                                    activity.location.longitude,
                                  );
                                  distanceLine = DistanceService.formatDistance(km);
                                }
                                final moodyLine = guestDemoMoodyPersonalityLine(l10n, mood, i);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildSectionHeader(context, activity, i, moodTag),
                                    DayPlanActivityCard(
                                      activity: activity,
                                      guestPreviewMode: true,
                                      onTap: (a, {String? distanceKm}) => _openActivityDetail(
                                        a,
                                        distanceKm: distanceKm ?? distanceLine,
                                      ),
                                      onNotFeelingThis: null,
                                      distanceKm: distanceLine,
                                      locationLabel: null,
                                      moodyPersonalityLine: moodyLine,
                                    ),
                                    if (i < activities.length - 1) const SizedBox(height: 8),
                                  ],
                                );
                              },
                              childCount: activities.length,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _navigateToSignup();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wmForest,
                    foregroundColor: _wmWhite,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: _wmWhite, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        l10n.guestDayPlanContinueWithMoody,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _wmWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
