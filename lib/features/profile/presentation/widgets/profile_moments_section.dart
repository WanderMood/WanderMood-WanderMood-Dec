import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/widgets/activity_review_sheet.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:wandermood/features/mood/services/activity_rating_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/features/profile/presentation/widgets/visit_rating_thumbnail.dart';

/// Profile home — featured block for rated visits (not a single skinny row).
class ProfileMomentsSection extends ConsumerWidget {
  const ProfileMomentsSection({super.key});

  static const _cream = Color(0xFFF5F0E8);
  static const _forest = Color(0xFF2A6049);
  static const _sunset = Color(0xFFE8784A);
  static const _parchment = Color(0xFFE8E2D8);
  static const _dusk = Color(0xFF4A4640);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(userActivityMomentsProvider);

    return async.when(
      data: (list) => _buildLoaded(context, ref, l10n, list),
      loading: () => _skeleton(),
      error: (_, __) => _buildLoaded(context, ref, l10n, const []),
    );
  }

  Widget _skeleton() {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _parchment),
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: _forest),
        ),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<ActivityRating> list,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _parchment),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _forest,
                  Color.lerp(_forest, const Color(0xFF1E4A38), 0.35)!,
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileMomentsTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.98),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.profileMomentsSubtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                if (list.isNotEmpty)
                  TextButton(
                    onPressed: () => context.push('/profile/moments'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.profileMomentsSeeAll,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: list.isEmpty
                ? _emptyBody(context, l10n)
                : _horizontalPreviews(context, ref, l10n, list),
          ),
        ],
      ),
    );
  }

  Widget _emptyBody(BuildContext context, AppLocalizations l10n) {
    return Material(
      color: _cream.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/profile/moments'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _sunset.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.rate_review_rounded, color: _sunset, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.profileMomentsEmptyCta,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.4,
                    color: _dusk,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _dusk.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _horizontalPreviews(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<ActivityRating> list,
  ) {
    final n = math.min(list.length, 12);
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: n,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final r = list[i];
          return _VisitPreviewCard(
            rating: r,
            onTap: () => showActivityReviewSheetForRating(context, r),
          );
        },
      ),
    );
  }
}

class _VisitPreviewCard extends ConsumerWidget {
  const _VisitPreviewCard({
    required this.rating,
    required this.onTap,
  });

  final ActivityRating rating;
  final VoidCallback onTap;

  static const _charcoal = Color(0xFF1E1C18);
  static const _forest = Color(0xFF2A6049);
  static const _sunset = Color(0xFFE8784A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final name = rating.activityName;
    final shortName =
        name.length > 22 ? '${name.substring(0, 20)}…' : name;

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 132,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: LayoutBuilder(
                  builder: (context, c) {
                    return VisitRatingThumbnail(
                      rating: rating,
                      width: c.maxWidth,
                      height: c.maxHeight,
                      borderRadius: 0,
                      forestTint: _forest,
                    );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shortName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _charcoal,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.momentsStarsCount(rating.stars),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _sunset.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
