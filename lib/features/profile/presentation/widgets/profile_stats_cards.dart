import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/mood/domain/providers/effective_mood_streak_provider.dart';
import 'package:wandermood/features/profile/domain/providers/current_user_profile_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// v2 design tokens — profile stats (mood streak card; saved places live above).
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmSunsetTint = Color(0xFFFDF0E8);
const Color _wmForest = Color(0xFF2A6049);

List<BoxShadow> _profileStatsShadow() {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Uses [profiles.mood_streak] via [currentUserProfileProvider] so this matches
/// My Day (activity-completion streak) and the drawer, not only check-in rows.
class ProfileStatsCards extends ConsumerWidget {
  const ProfileStatsCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      data: (profile) => ref.watch(effectiveMoodStreakProvider).when(
            data: (streak) => _statsBody(context, l10n, streak),
            loading: () => _statsBody(context, l10n, profile?.moodStreak ?? 0),
            error: (_, __) => _statsBody(context, l10n, profile?.moodStreak ?? 0),
          ),
      loading: () => const SizedBox(
        height: 88,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _wmForest,
            ),
          ),
        ),
      ),
      error: (_, __) => _statsBody(context, l10n, 0),
    );
  }

  Widget _statsBody(
    BuildContext context,
    AppLocalizations l10n,
    int moodStreak,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _wmParchment, width: 1),
        boxShadow: _profileStatsShadow(),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/moods/history'),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _wmSunsetTint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _wmParchment, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department_outlined,
                    color: _wmSunset,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$moodStreak',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _wmCharcoal,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.profileStatsStreakSubtitle(moodStreak),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _wmDusk,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _wmStone, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
