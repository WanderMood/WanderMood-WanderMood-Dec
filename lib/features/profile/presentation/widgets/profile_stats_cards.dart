import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/mood/services/check_in_service.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// v2 design tokens — profile stats row (no shadows; mood history only via journey card).
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmSunsetTint = Color(0xFFFDF0E8);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmSkyTint = Color(0xFFEDF5F9);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);

class ProfileStatsCards extends ConsumerStatefulWidget {
  const ProfileStatsCards({super.key});

  @override
  ConsumerState<ProfileStatsCards> createState() => _ProfileStatsCardsState();
}

class _ProfileStatsCardsState extends ConsumerState<ProfileStatsCards> {
  int _checkInStreak = 0;
  int _placesCount = 0;
  String _topMood = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final checkInService = ref.read(checkInServiceProvider);
      final streak = await checkInService.getCheckInStreak();

      final savedPlacesService = ref.read(savedPlacesServiceProvider);
      final placesCount = await savedPlacesService.getSavedPlacesCount();

      final checkIns = await checkInService.getRecentCheckIns(limit: 30);
      String? topMood;
      if (checkIns.isNotEmpty) {
        final moodCounts = <String, int>{};
        for (final checkIn in checkIns) {
          if (checkIn.mood != null && checkIn.mood!.isNotEmpty) {
            moodCounts[checkIn.mood!] = (moodCounts[checkIn.mood!] ?? 0) + 1;
          }
        }
        if (moodCounts.isNotEmpty) {
          final sortedMoods = moodCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          topMood = sortedMoods.first.key;
        }
      }

      setState(() {
        _checkInStreak = streak;
        _placesCount = placesCount;
        _topMood = topMood ?? '';
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _displayMood(AppLocalizations l10n) {
    if (_topMood.isEmpty) return l10n.profileTopMoodEmpty;
    if (_topMood.length <= 11) {
      return '${_topMood[0].toUpperCase()}${_topMood.substring(1)}';
    }
    return '${_topMood.substring(0, 10)}…';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const SizedBox(
        height: 120,
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
      );
    }

    return Row(
      children: [
        Expanded(child: _statCard(
          tint: _wmSunsetTint,
          icon: Icons.local_fire_department_outlined,
          iconColor: _wmSunset,
          value: '$_checkInStreak',
          label: l10n.profileStatsStreakTitle,
        )),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/places/saved'),
              child: _statCard(
                tint: _wmSkyTint,
                icon: Icons.place_outlined,
                iconColor: _wmSky,
                value: '$_placesCount',
                label: l10n.profileStatsPlacesTitle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            tint: _wmForestTint,
            icon: Icons.trending_up,
            iconColor: _wmForest,
            value: _displayMood(l10n),
            label: l10n.profileStatsTopMoodTitle,
            valueFontSize: _topMood.length > 8 ? 14 : 20,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required Color tint,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    double valueFontSize = 20,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: _wmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmParchment, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
              color: _wmCharcoal,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _wmStone,
            ),
          ),
        ],
      ),
    );
  }
}
