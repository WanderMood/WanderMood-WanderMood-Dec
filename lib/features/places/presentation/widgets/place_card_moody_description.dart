import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/presentation/widgets/guest_demo_about_sections.dart';
import 'package:wandermood/core/providers/communication_style_provider.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/features/places/data/moody_place_card_ui_cache.dart';
import 'package:wandermood/features/places/data/place_card_ui_description.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/moody_explore_provider.dart';
import 'package:wandermood/features/places/providers/moody_place_card_blurb_provider.dart';
import 'package:wandermood/features/places/utils/moody_explore_filter_digest.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Explore / list card: grounded multi-section Moody copy when available.
///
/// Stays a [ConsumerWidget] (not [ConsumerStatefulWidget]) so hot reload and
/// nested [Consumer] builders keep a consistent widget type.
///
/// [ListenableBuilder] on [MoodyPlaceCardUiCache.revision] rebuilds when the
/// Explore prewarm queue writes rich copy to disk-backed cache.
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
    this.cacheOnly = false,

    /// When true (e.g. partner carousel): show only the green Moody hook line —
    /// no "Wat is dit?" / section blocks and no merged body paragraph.
    this.hookLineOnly = false,
  });

  final Place place;
  final TextStyle textStyle;

  /// Used for plain-text path only.
  final int? maxLines;
  final double paddingTop;
  final bool useCardStackLayout;
  final double? structuredTitleFontSize;
  final double? structuredBodyFontSize;
  final bool cacheOnly;
  final bool hookLineOnly;

  static const Color _wmForest = Color(0xFF2A6049);

  static const double _kRichHookLineFontSize = 13;
  static const double _kRichHookLineHeight = 1.35;
  static const int _kRichHookMaxLines = 2;
  static const double _kRichHookAfterGap = 8;
  static const double _kRichHookSlotHeight =
      _kRichHookLineFontSize * _kRichHookLineHeight * _kRichHookMaxLines +
          _kRichHookAfterGap;

  int _effectiveMaxLines() => maxLines ?? 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fallback = ExplorePlaceCardCopy.cardDescription(place, l10n);
    if (fallback.isEmpty) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: MoodyPlaceCardUiCache.revision,
      builder: (context, _) {
        final appLocale = ref.watch(localeProvider);
        final locale = appLocale ?? ui.PlatformDispatcher.instance.locale;
        final comm = ref
            .read(communicationStyleProvider.notifier)
            .getCurrentStyleString();

        final named = ref.watch(moodyExploreBackendNamedFiltersProvider);
        final hard = ref.watch(moodyExploreBackendFiltersProvider);
        final filterDigest = moodyExploreFilterDigest(named, hard);

        final cachedSync = MoodyPlaceCardUiCache.peekStable(
          place.id,
          locale.languageCode,
          comm,
          filterDigest,
        );
        if (cachedSync != null) {
          return _renderUi(
            cachedSync,
            fallback,
            l10n,
          );
        }

        if (cacheOnly) {
          final uiAsync = ref.watch(
            moodyPlaceCardUiDescriptionCacheOnlyProvider(place),
          );
          final ui = uiAsync.maybeWhen(
            data: (d) => d,
            orElse: () => PlaceCardUiDescription.plain(fallback),
          );
          return _renderUi(ui, fallback, l10n);
        }

        final uiAsync = ref.watch(moodyPlaceCardUiDescriptionProvider(place));
        return uiAsync.when(
          data: (d) => _renderUi(d, fallback, l10n),
          loading: () =>
              _renderUi(PlaceCardUiDescription.plain(fallback), fallback, l10n),
          error: (_, __) =>
              _renderUi(PlaceCardUiDescription.plain(fallback), fallback, l10n),
        );
      },
    );
  }

  Widget _renderUi(
    PlaceCardUiDescription uiDesc,
    String fallback,
    AppLocalizations l10n,
  ) {
    if (kDebugMode) {
      debugPrint(
        'PlaceCardMoodyDescription rich=${uiDesc.isRich} plainLen=${uiDesc.plainText?.length ?? 0}',
      );
    }
    final lineCap = _effectiveMaxLines();

    String displayPlain(String raw) {
      final trimmed = raw.trim();
      final base = trimmed.isNotEmpty ? trimmed : fallback;
      return ExplorePlaceCardCopy.ensureMinSentencesForCard(
        place,
        base,
        l10n,
      );
    }

    String richMergedForTightLayout(PlaceCardUiDescription rich) {
      final parts = <String>[];
      final h = rich.hook?.trim();
      if (h != null && h.isNotEmpty) parts.add(h);
      if (rich.sectionsSource != null &&
          rich.sectionsSource!.trim().isNotEmpty) {
        final sections = parseGuestDemoAboutSections(rich.sectionsSource!);
        if (sections.isNotEmpty) {
          parts.add(
            sections.first.body.replaceAll(RegExp(r'\s+'), ' ').trim(),
          );
        }
      }
      final merged = parts.join(' ').trim();
      return displayPlain(merged.isNotEmpty ? merged : fallback);
    }

    if (uiDesc.isRich) {
      final hookText = uiDesc.hook?.trim();
      final hasHook = hookText != null && hookText.isNotEmpty;
      String hookLineForStack() {
        if (hasHook) return hookText!;
        var line = ExplorePlaceCardCopy.editorialLineForExploreCard(fallback);
        if (line.trim().isEmpty) {
          final f = fallback.trim();
          line = f.length > 120 ? '${f.substring(0, 117)}…' : f;
        }
        return line;
      }

      if (hookLineOnly) {
        final stackHook = hookLineForStack();
        return Padding(
          padding: EdgeInsets.only(top: paddingTop),
          child: SizedBox(
            height: _kRichHookSlotHeight,
            width: double.infinity,
            child: Align(
              alignment: Alignment.topLeft,
              child: stackHook.isNotEmpty
                  ? Text(
                      stackHook,
                      style: GoogleFonts.poppins(
                        fontSize: _kRichHookLineFontSize,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: _wmForest,
                        height: _kRichHookLineHeight,
                      ),
                      maxLines: _kRichHookMaxLines,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      }

      if (useCardStackLayout) {
        final bodyLines = (lineCap - _kRichHookMaxLines).clamp(2, 10);
        final stackHook = hookLineForStack();
        return Padding(
          padding: EdgeInsets.only(top: paddingTop),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _kRichHookSlotHeight,
                width: double.infinity,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: stackHook.isNotEmpty
                      ? Text(
                          stackHook,
                          style: GoogleFonts.poppins(
                            fontSize: _kRichHookLineFontSize,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: _wmForest,
                            height: _kRichHookLineHeight,
                          ),
                          maxLines: _kRichHookMaxLines,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              GuestDemoAboutSectionsView(
                source: uiDesc.sectionsSource!,
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
            richMergedForTightLayout(uiDesc),
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
                hookText!,
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
              source: uiDesc.sectionsSource!,
              compact: true,
              compactBodyMaxLines: bodyLines,
            ),
          ],
        ),
      );
    }

    final plain = uiDesc.plainText ?? '';
    if (hookLineOnly) {
      final line = ExplorePlaceCardCopy.editorialLineForExploreCard(
        displayPlain(plain),
      );
      final stackHook = line.trim().isEmpty
          ? (plain.trim().length > 120
              ? '${plain.trim().substring(0, 117)}…'
              : plain.trim())
          : line;
      return Padding(
        padding: EdgeInsets.only(top: paddingTop),
        child: SizedBox(
          height: _kRichHookSlotHeight,
          width: double.infinity,
          child: Align(
            alignment: Alignment.topLeft,
            child: stackHook.isNotEmpty
                ? Text(
                    stackHook,
                    style: GoogleFonts.poppins(
                      fontSize: _kRichHookLineFontSize,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: _wmForest,
                      height: _kRichHookLineHeight,
                    ),
                    maxLines: _kRichHookMaxLines,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: paddingTop),
      child: Text(
        displayPlain(plain),
        style: textStyle,
        maxLines: lineCap,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
