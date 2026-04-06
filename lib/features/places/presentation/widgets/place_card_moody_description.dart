import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/guest_demo_about_sections.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/features/places/data/place_card_ui_description.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/widgets/place_moody_copy_skeleton.dart';
import 'package:wandermood/features/places/providers/moody_place_card_blurb_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Explore / list card: grounded multi-section Moody copy when available; skeleton while loading.
class PlaceCardMoodyDescription extends ConsumerWidget {
  const PlaceCardMoodyDescription({
    super.key,
    required this.place,
    required this.textStyle,
    this.maxLines,
    this.paddingTop = 10,
    /// Explore / My Day: show Moody's hook + first section title + body (like place detail).
    /// When false, very tight [maxLines] merges rich copy into one clipped paragraph.
    this.useCardStackLayout = false,
    /// Smaller section typography on compact grid cards (only with [useCardStackLayout] + rich).
    this.structuredTitleFontSize,
    this.structuredBodyFontSize,
  });

  final Place place;
  final TextStyle textStyle;

  /// Used for plain-text path only.
  final int? maxLines;
  final double paddingTop;
  final bool useCardStackLayout;
  final double? structuredTitleFontSize;
  final double? structuredBodyFontSize;

  int get _effectiveMaxLines => maxLines ?? 4;

  static const Color _wmForest = Color(0xFF2A6049);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fallback = ExplorePlaceCardCopy.cardDescription(place, l10n);
    if (fallback.isEmpty) return const SizedBox.shrink();

    final uiAsync = ref.watch(moodyPlaceCardUiDescriptionProvider(place));
    final lineCap = _effectiveMaxLines;

    String displayPlain(String raw) {
      final trimmed = raw.trim();
      final base = trimmed.isNotEmpty ? trimmed : fallback;
      return ExplorePlaceCardCopy.ensureMinSentencesForCard(place, base, l10n);
    }

    /// Rich layout ignores [maxLines] unless we merge or cap sections — avoids
    /// RenderFlex overflow in fixed-height list/grid cards.
    String richMergedForTightLayout(PlaceCardUiDescription ui) {
      final parts = <String>[];
      final h = ui.hook?.trim();
      if (h != null && h.isNotEmpty) parts.add(h);
      if (ui.sectionsSource != null && ui.sectionsSource!.trim().isNotEmpty) {
        final sections = parseGuestDemoAboutSections(ui.sectionsSource!);
        if (sections.isNotEmpty) {
          parts.add(
            sections.first.body.replaceAll(RegExp(r'\s+'), ' ').trim(),
          );
        }
      }
      final merged = parts.join(' ').trim();
      return displayPlain(merged.isNotEmpty ? merged : fallback);
    }

    return uiAsync.when(
      data: (ui) {
        if (kDebugMode) {
          debugPrint(
            'PlaceCardMoodyDescription rich=${ui.isRich} plainLen=${ui.plainText?.length ?? 0}',
          );
        }
        if (ui.isRich) {
          final hookText = ui.hook?.trim();
          final hasHook = hookText != null && hookText.isNotEmpty;

          if (useCardStackLayout) {
            final bodyLines = hasHook
                ? (lineCap - 2).clamp(2, 10)
                : lineCap.clamp(2, 10);
            return Padding(
              padding: EdgeInsets.only(top: paddingTop),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasHook) ...[
                    Text(
                      hookText,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: _wmForest,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  GuestDemoAboutSectionsView(
                    source: ui.sectionsSource!,
                    compact: true,
                    compactBodyMaxLines: bodyLines,
                    compactTitleFontSize: structuredTitleFontSize,
                    compactBodyFontSize: structuredBodyFontSize,
                  ),
                ],
              ),
            );
          }

          if (lineCap <= 4) {
            return Padding(
              padding: EdgeInsets.only(top: paddingTop),
              child: Text(
                richMergedForTightLayout(ui),
                style: textStyle,
                maxLines: lineCap,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }
          final bodyLines = (lineCap - 3).clamp(1, 12);
          return Padding(
            padding: EdgeInsets.only(top: paddingTop),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasHook) ...[
                  Text(
                    hookText,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: _wmForest,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                GuestDemoAboutSectionsView(
                  source: ui.sectionsSource!,
                  compact: true,
                  compactBodyMaxLines: bodyLines,
                ),
              ],
            ),
          );
        }
        final plain = ui.plainText ?? '';
        return Padding(
          padding: EdgeInsets.only(top: paddingTop),
          child: Text(
            displayPlain(plain),
            style: textStyle,
            maxLines: lineCap,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(top: paddingTop),
        child: const PlaceMoodyCopySkeleton(compact: true),
      ),
      error: (_, __) => Padding(
        padding: EdgeInsets.only(top: paddingTop),
        child: Text(
          fallback,
          style: textStyle,
          maxLines: lineCap,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
