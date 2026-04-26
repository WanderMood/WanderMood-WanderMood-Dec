import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Shimmer “searching” placeholder for Explore when sections are still loading.
/// Isolated from [ExploreScreen] to keep the 4k+ screen file from growing.
class ExploreFeedLoadingSurface extends StatelessWidget {
  const ExploreFeedLoadingSurface({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _skeletonBar(height: 14, widthFactor: 0.42, shimmerDelayMs: 0),
          const SizedBox(height: 18),
          _skeletonBar(height: 112, widthFactor: 1, shimmerDelayMs: 120),
          const SizedBox(height: 14),
          _skeletonBar(height: 112, widthFactor: 1, shimmerDelayMs: 240),
          const SizedBox(height: 22),
          Text(
            l10n.exploreSearching,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8C8780),
            ),
          ).animate().fadeIn(duration: 420.ms, delay: 100.ms),
        ],
      ),
    );
  }
}

Widget _skeletonBar({
  required double height,
  required double widthFactor,
  int shimmerDelayMs = 0,
}) {
  return Align(
    alignment: Alignment.center,
    child: FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E2D8),
          borderRadius: BorderRadius.circular(14),
        ),
      )
          .animate(
            onPlay: (c) => c.repeat(reverse: true),
          )
          .shimmer(
            delay: Duration(milliseconds: shimmerDelayMs),
            duration: const Duration(milliseconds: 1800),
            color: Colors.white.withValues(alpha: 0.55),
          ),
    ),
  );
}
