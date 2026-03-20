import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/mood/services/check_in_service.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class ProfileStatsCards extends ConsumerStatefulWidget {
  const ProfileStatsCards({super.key});

  @override
  ConsumerState<ProfileStatsCards> createState() => _ProfileStatsCardsState();
}

class _ProfileStatsCardsState extends ConsumerState<ProfileStatsCards> {
  int _checkInStreak = 0;
  int _placesCount = 0;
  String _topMood = 'adventurous';
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
      // Load check-in streak
      final checkInService = ref.read(checkInServiceProvider);
      final streak = await checkInService.getCheckInStreak();

      // Load places count
      final savedPlacesService = ref.read(savedPlacesServiceProvider);
      final placesCount = await savedPlacesService.getSavedPlacesCount();

      // Calculate top mood from recent check-ins
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
        _topMood = topMood ?? 'adventurous';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            l10n.profileStatsTitle,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Check-ins card
              Expanded(
                child: _buildCheckInsCard(),
              ),
              const SizedBox(width: 12),
              // Places Visited card (tappable)
              Expanded(
                child: _buildPlacesCard(),
              ),
              const SizedBox(width: 12),
              // Top Mood card
              Expanded(
                child: _buildTopMoodCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInsCard() {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () {
        context.push('/moods/history');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF0EE), // wmSunsetTint
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFFE8784A), // wmSunset
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_checkInStreak',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            l10n.profileStatsCheckinsTitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
        ),
    );
  }

  Widget _buildPlacesCard() {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () {
        context.push('/places/saved');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon with badge
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF5F9), // wmSkyTint
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.place,
                    color: Color(0xFFA8C8DC), // wmSky
                    size: 24,
                  ),
                ),
                if (_placesCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        _placesCount > 9 ? '9+' : '$_placesCount',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$_placesCount',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              l10n.profileStatsPlacesTitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.profileStatsPlacesSubtitle} →',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMoodCard() {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () {
        context.push('/moods/history');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.pink.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EE), // wmForestTint
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up,
              color: Color(0xFF2A6049), // wmForest
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _topMood.length > 8 ? '${_topMood.substring(0, 8)}...' : _topMood,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            l10n.profileStatsTopMoodTitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildExploreJourneyCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.profileMoodJourneyTitle,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.profileMoodJourneySubtitle,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }
}