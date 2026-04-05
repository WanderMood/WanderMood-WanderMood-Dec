import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/moody_place_card_blurb_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Card vs detail: different async blurb (short card copy vs longer detail copy).
enum PlaceCardMoodyDescriptionSurface {
  card,
  detail,
}

/// Card description: shows Places-backed fallback immediately, then Moody + OpenAI when ready.
class PlaceCardMoodyDescription extends ConsumerWidget {
  const PlaceCardMoodyDescription({
    super.key,
    required this.place,
    required this.textStyle,
    this.surface = PlaceCardMoodyDescriptionSurface.card,
    this.maxLines,
    this.paddingTop = 10,
  });

  final Place place;
  final TextStyle textStyle;
  final PlaceCardMoodyDescriptionSurface surface;

  /// When null: 4 lines on [card], unlimited on [detail].
  final int? maxLines;
  final double paddingTop;

  int? get _effectiveMaxLines {
    if (maxLines != null) return maxLines;
    return surface == PlaceCardMoodyDescriptionSurface.detail ? null : 4;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fallback = surface == PlaceCardMoodyDescriptionSurface.detail
        ? ExplorePlaceCardCopy.detailFallbackDescription(place, l10n)
        : ExplorePlaceCardCopy.cardDescription(place, l10n);
    if (fallback.isEmpty) return const SizedBox.shrink();

    final provider = surface == PlaceCardMoodyDescriptionSurface.detail
        ? moodyPlaceDetailBlurbProvider(place)
        : moodyPlaceCardBlurbProvider(place);
    // Must watch (not read) so the card rebuilds when the Future completes.
    final asyncBlurb = ref.watch(provider);
    final lineCap = _effectiveMaxLines;

    if (kDebugMode) {
      debugPrint(
        'PlaceCardMoodyDescription(${surface.name}) card blurb state: ${asyncBlurb.asData?.value}',
      );
    }

    String displayText(String raw) {
      final trimmed = raw.trim();
      final base = trimmed.isNotEmpty ? trimmed : fallback;
      return surface == PlaceCardMoodyDescriptionSurface.detail
          ? ExplorePlaceCardCopy.ensureMinSentencesForDetail(place, base, l10n)
          : ExplorePlaceCardCopy.ensureMinSentencesForCard(place, base, l10n);
    }

    return asyncBlurb.when(
      data: (blurb) {
        return Padding(
          padding: EdgeInsets.only(top: paddingTop),
          child: Text(
            displayText(blurb),
            style: textStyle,
            maxLines: lineCap,
            overflow:
                lineCap != null ? TextOverflow.ellipsis : null,
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(top: paddingTop),
        child: Text(
          fallback,
          style: textStyle,
          maxLines: lineCap,
          overflow:
              lineCap != null ? TextOverflow.ellipsis : null,
        ),
      ),
      error: (_, __) => Padding(
        padding: EdgeInsets.only(top: paddingTop),
        child: Text(
          fallback,
          style: textStyle,
          maxLines: lineCap,
          overflow:
              lineCap != null ? TextOverflow.ellipsis : null,
        ),
      ),
    );
  }
}
