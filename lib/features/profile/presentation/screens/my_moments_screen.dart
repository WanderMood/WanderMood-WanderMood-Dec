import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/home/presentation/widgets/activity_review_sheet.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:wandermood/features/mood/services/activity_rating_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/profile/presentation/widgets/visit_rating_thumbnail.dart';

/// Profile — list of saved visit ratings (`activity_ratings`); tap to view, delete from menu.
class MyMomentsScreen extends ConsumerWidget {
  const MyMomentsScreen({super.key});

  static const _cream = Color(0xFFF5F0E8);
  static const _charcoal = Color(0xFF1E1C18);
  static const _forest = Color(0xFF2A6049);
  static const _sunset = Color(0xFFE8784A);
  static const _parchment = Color(0xFFE8E2D8);
  static const _dusk = Color(0xFF4A4640);
  static const _starGold = Color(0xFFD4A012);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(userActivityMomentsProvider);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        foregroundColor: _charcoal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.profileMomentsTitle,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _charcoal,
          ),
        ),
      ),
      body: async.when(
        data: (list) => RefreshIndicator(
          color: _forest,
          onRefresh: () async {
            ref.invalidate(userActivityMomentsProvider);
            await ref.read(userActivityMomentsProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _VisitsHeroCard(
                    title: l10n.profileMomentsTitle,
                    line: l10n.momentsListHeroLine,
                  ),
                ),
              ),
              if (list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.momentsListEmptyTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _charcoal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.momentsListEmptySubtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.45,
                            color: _dusk,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 28),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final r = list[i];
                      return _VisitTile(
                        rating: r,
                        forest: _forest,
                        charcoal: _charcoal,
                        dusk: _dusk,
                        sunset: _sunset,
                        parchment: _parchment,
                        starGold: _starGold,
                        onTap: () => showActivityReviewSheetForRating(context, r),
                        onDelete: () => _confirmDelete(context, ref, r),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: _forest)),
        error: (_, __) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _VisitsHeroCard(
                  title: l10n.profileMomentsTitle,
                  line: l10n.momentsListHeroLine,
                ),
              ),
            ),
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.momentsListError,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: _dusk),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ActivityRating r,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final place = (r.placeName?.trim().isNotEmpty == true)
        ? r.placeName!.trim()
        : r.activityName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.momentsDeleteConfirmTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.momentsDeleteConfirmBody(place),
          style: GoogleFonts.poppins(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.momentsRemoveCta,
              style: const TextStyle(color: _sunset),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(activityRatingServiceProvider).deleteRatingForActivity(r.activityId);
    ref.invalidate(userActivityMomentsProvider);
    ref.invalidate(activityRatingForActivityProvider(r.activityId));
    if (context.mounted) {
      showWanderMoodToast(context, message: l10n.momentsRemovedToast);
    }
  }
}

class _VisitsHeroCard extends StatelessWidget {
  const _VisitsHeroCard({
    required this.title,
    required this.line,
  });

  final String title;
  final String line;

  static const _forest = Color(0xFF2A6049);
  static const _forestDeep = Color(0xFF1E4A38);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _forest,
            Color.lerp(_forest, _forestDeep, 0.35)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _forest.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.98),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  line,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const MoodyCharacter(
            size: 68,
            mood: 'happy',
            glowOpacityScale: 0.38,
          ),
        ],
      ),
    );
  }
}

class _VisitTile extends ConsumerWidget {
  const _VisitTile({
    required this.rating,
    required this.forest,
    required this.charcoal,
    required this.dusk,
    required this.sunset,
    required this.parchment,
    required this.starGold,
    required this.onTap,
    required this.onDelete,
  });

  final ActivityRating rating;
  final Color forest;
  final Color charcoal;
  final Color dusk;
  final Color sunset;
  final Color parchment;
  final Color starGold;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _displayTitle() {
    final p = rating.placeName?.trim();
    if (p != null && p.isNotEmpty) return p;
    return rating.activityName;
  }

  String? _secondaryLine() {
    final p = rating.placeName?.trim();
    if (p != null && p.isNotEmpty && rating.activityName.trim() != p) {
      return rating.activityName.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loc = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(loc).add_jm().format(rating.completedAt.toLocal());
    final title = _displayTitle();
    final secondary = _secondaryLine();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: parchment),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        forest,
                        Color.lerp(forest, const Color(0xFF4A8F6F), 0.4)!,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 14, 8, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VisitRatingThumbnail(
                              rating: rating,
                              size: 52,
                              borderRadius: 14,
                              forestTint: forest,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: charcoal,
                                      height: 1.25,
                                    ),
                                  ),
                                  if (secondary != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      secondary,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: dusk.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  _StarRow(count: rating.stars, gold: starGold),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: dusk.withValues(alpha: 0.72),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (rating.notes != null && rating.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            rating.notes!.trim(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              height: 1.4,
                              color: dusk.withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          l10n.momentsTapToEdit,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sunset.withValues(alpha: 0.95),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4, top: 4),
                  child: IconButton(
                    tooltip: l10n.momentsRemoveCta,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: dusk.withValues(alpha: 0.42),
                    ),
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.count, required this.gold});

  final int count;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final n = count.clamp(0, 5);
    return Row(
      children: [
        ...List.generate(5, (i) {
          final filled = i < n;
          return Padding(
            padding: EdgeInsetsDirectional.only(end: i < 4 ? 2 : 0),
            child: Icon(
              Icons.star_rounded,
              size: 18,
              color: filled ? gold : gold.withValues(alpha: 0.22),
            ),
          );
        }),
        const SizedBox(width: 6),
        Text(
          l10n.momentsStarsCount(n),
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4640).withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
