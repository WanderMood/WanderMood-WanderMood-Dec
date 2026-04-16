import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/constants/api_constants.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/providers/communication_style_provider.dart';
import 'package:wandermood/core/services/moody_ai_service.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/features/places/data/moody_place_blurb_cache.dart';
import 'package:wandermood/features/places/data/moody_place_blurb_edge.dart';
import 'package:wandermood/features/places/data/moody_place_blurb_facts.dart';
import 'package:wandermood/features/places/data/moody_place_card_ui_cache.dart';
import 'package:wandermood/features/places/data/place_card_ui_description.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

String _googleDetailsId(Place place) {
  final id = place.id.trim();
  if (id.startsWith('google_')) {
    final raw = id.substring('google_'.length);
    return raw.isNotEmpty ? raw : '';
  }
  if (id.isNotEmpty && !id.startsWith('asset_')) return id;
  return '';
}

AppLocalizations _l10nFor(ui.Locale locale) {
  try {
    return lookupAppLocalizations(locale);
  } catch (_) {
    try {
      return lookupAppLocalizations(ui.Locale(locale.languageCode));
    } catch (_) {
      return lookupAppLocalizations(const ui.Locale('en'));
    }
  }
}

class _PlaceBlurbContext {
  _PlaceBlurbContext({
    required this.facts,
    required this.lang,
    required this.l10n,
    this.editorial,
  });

  final String facts;
  final String lang;
  final AppLocalizations l10n;
  final String? editorial;
}

Future<_PlaceBlurbContext> _loadPlaceBlurbContext(
  Ref ref,
  Place place,
  ui.Locale locale,
) async {
  final l10n = _l10nFor(locale);
  final lang = locale.languageCode;

  final places = ref.read(placesServiceProvider.notifier);
  String? editorial;
  final snippets = <String>[];
  var reviewCount = place.reviewCount;

  final gid = _googleDetailsId(place);
  if (gid.isNotEmpty) {
    try {
      final details = await places.getPlaceDetails(gid);
      if (details.isNotEmpty) {
        editorial = details['description'] as String?;
        final rawReviews = details['reviews'];
        if (rawReviews is List<dynamic>) {
          for (final r in rawReviews) {
            if (snippets.length >= 6) break;
            if (r is Map<String, dynamic> && r['text'] is String) {
              var t = (r['text'] as String).trim();
              if (t.length < 20) continue;
              if (t.length > 220) t = '${t.substring(0, 217)}…';
              snippets.add(t);
            }
          }
        }
        final urt = details['user_ratings_total'];
        if (urt is int && urt > reviewCount) reviewCount = urt;
        if (urt is num && urt.toInt() > reviewCount) reviewCount = urt.toInt();
      }
    } catch (_) {}
  }

  final facts = buildMoodyPlaceBlurbFactsBlock(
    l10n,
    place,
    editorialOverride: editorial,
    reviewSnippets: snippets.isNotEmpty ? snippets : null,
    reviewCountOverride: reviewCount > 0 ? reviewCount : null,
  );

  return _PlaceBlurbContext(
    facts: facts,
    lang: lang,
    l10n: l10n,
    editorial: editorial,
  );
}

/// Explore card line from on-model editorial or Google `description` after details fetch.
String? _editorialLineFromPlaceOrGoogle(
  Place place,
  AppLocalizations l10n,
  String? googleDescription,
) {
  final fromPlace = ExplorePlaceCardCopy.usableEditorialExcludingTypeFallback(place);
  if (fromPlace != null) {
    return ExplorePlaceCardCopy.editorialLineForExploreCard(fromPlace);
  }
  final g = googleDescription?.trim();
  if (g != null &&
      g.isNotEmpty &&
      !ExplorePlaceCardCopy.isBoilerplateDescription(g)) {
    return ExplorePlaceCardCopy.editorialLineForExploreCard(g);
  }
  return null;
}

/// Unified Explore card copy: tries `place_explore_rich` (sectioned, grounded), then editorial line, then legacy blurb.
final moodyPlaceCardUiDescriptionProvider =
    FutureProvider.autoDispose.family<PlaceCardUiDescription, Place>(
        (ref, place) async {
  final appLocale = ref.watch(localeProvider);
  final locale = appLocale ?? ui.PlatformDispatcher.instance.locale;
  final l10n = _l10nFor(locale);
  final comm =
      ref.read(communicationStyleProvider.notifier).getCurrentStyleString();
  final lang = locale.languageCode;
  final stableKey =
      MoodyPlaceCardUiCache.stableCacheKey(place.id, lang, comm);

  // Instant path: we already resolved copy for this place this session (facts-based
  // key alone misses until after a slow [getPlaceDetails] + hash).
  final stableHit = MoodyPlaceCardUiCache.get(stableKey);
  if (stableHit != null) {
    if (kDebugMode) {
      debugPrint(
        'moodyPlaceCardUiDescriptionProvider: stable cache hit ${place.name} id=${place.id}',
      );
    }
    return stableHit;
  }

  final ctx = await _loadPlaceBlurbContext(ref, place, locale);
  final factsForModel = clampMoodyPlaceBlurbFactsForEdge(ctx.facts);

  final uiKey = MoodyPlaceCardUiCache.cacheKey(
    place.id,
    ctx.lang,
    factsForModel.hashCode,
  );
  final uiHit = MoodyPlaceCardUiCache.get(uiKey);
  if (uiHit != null) {
    MoodyPlaceCardUiCache.putWithStableAlias(uiKey, stableKey, uiHit);
    return uiHit;
  }

  final uiExisting = MoodyPlaceCardUiCache.inflight(uiKey);
  if (uiExisting != null) return await uiExisting;

  final uiFuture = () async {
    PlaceCardUiDescription out;

    final rich = await moodyPlaceExploreRichFromEdge(
      facts: factsForModel,
      languageCode: ctx.lang,
      communicationStyle: comm,
    );
    if (rich != null && rich.isValid) {
      out = PlaceCardUiDescription.rich(
        hook: rich.hook,
        sectionsSource: rich.sectionsJoined,
      );
      MoodyPlaceCardUiCache.putWithStableAlias(uiKey, stableKey, out);
      if (kDebugMode) {
        debugPrint(
          'moodyPlaceCardUiDescriptionProvider: rich place=${place.name} id=${place.id}',
        );
      }
      return out;
    }

    final syncLine =
        _editorialLineFromPlaceOrGoogle(place, l10n, ctx.editorial);
    if (syncLine != null && syncLine.isNotEmpty) {
      out = PlaceCardUiDescription.plain(syncLine);
      MoodyPlaceCardUiCache.putWithStableAlias(uiKey, stableKey, out);
      return out;
    }

    final g = ctx.editorial?.trim();
    if (g != null &&
        g.isNotEmpty &&
        !ExplorePlaceCardCopy.isBoilerplateDescription(g)) {
      final sc = ExplorePlaceCardCopy.sentenceCount(g);
      if (sc >= 3 || g.length >= 360) {
        final line = ExplorePlaceCardCopy.editorialLineForExploreCard(g);
        if (line.isNotEmpty) {
          out = PlaceCardUiDescription.plain(line);
          MoodyPlaceCardUiCache.putWithStableAlias(uiKey, stableKey, out);
          return out;
        }
      }
    }

    final legacyKey = MoodyPlaceBlurbCache.cacheKey(
      place.id,
      ctx.lang,
      factsForModel.hashCode,
      variant: 'card_v5',
    );
    var plain = MoodyPlaceBlurbCache.get(legacyKey) ?? '';
    if (plain.isEmpty) {
      final ai = ref.read(moodyAIServiceProvider);
      if (ApiConstants.openAiApiKey.isNotEmpty) {
        plain = (await ai.generatePlaceCardBlurb(
          l10n: ctx.l10n,
          factsBlock: factsForModel,
          bcp47LanguageCode: ctx.lang,
        ))
            .trim();
      }
      if (plain.isEmpty) {
        plain = (await moodyPlaceCardBlurbFromEdge(
          facts: factsForModel,
          languageCode: ctx.lang,
        ))
            .trim();
      }
      if (plain.isNotEmpty) {
        MoodyPlaceBlurbCache.put(legacyKey, plain);
      }
    }
    if (plain.isEmpty) {
      plain = ExplorePlaceCardCopy.cardDescription(place, l10n);
    }
    out = PlaceCardUiDescription.plain(plain);
    MoodyPlaceCardUiCache.putWithStableAlias(uiKey, stableKey, out);
    return out;
  }();

  MoodyPlaceCardUiCache.setInflight(uiKey, uiFuture);
  try {
    return await uiFuture;
  } finally {
    MoodyPlaceCardUiCache.clearInflight(uiKey);
  }
});

/// Single-line / legacy blurb derived from [moodyPlaceCardUiDescriptionProvider].
final moodyPlaceCardBlurbProvider =
    FutureProvider.autoDispose.family<String, Place>((ref, place) async {
  final appLocale = ref.watch(localeProvider);
  final locale = appLocale ?? ui.PlatformDispatcher.instance.locale;
  final l10n = _l10nFor(locale);
  final uiDesc =
      await ref.watch(moodyPlaceCardUiDescriptionProvider(place).future);
  return uiDesc.asLegacyBlurbLine(l10n, place);
});

/// Longer Moody blurb for place detail (separate cache from [moodyPlaceCardBlurbProvider]).
final moodyPlaceDetailBlurbProvider =
    FutureProvider.autoDispose.family<String, Place>((ref, place) async {
  final appLocale = ref.watch(localeProvider);
  final locale = appLocale ?? ui.PlatformDispatcher.instance.locale;
  final ctx = await _loadPlaceBlurbContext(ref, place, locale);

  String? editorialBase =
      ExplorePlaceCardCopy.usableEditorialExcludingTypeFallback(place);
  final g = ctx.editorial?.trim();
  if (g != null &&
      g.isNotEmpty &&
      !ExplorePlaceCardCopy.isBoilerplateDescription(g)) {
    if (editorialBase == null || g.length > editorialBase.length) {
      editorialBase = g;
    }
  }
  if (editorialBase != null) {
    final sc = ExplorePlaceCardCopy.sentenceCount(editorialBase);
    if (sc >= 3 || editorialBase.length >= 360) {
      final t = editorialBase.trim();
      return t.length > 2000 ? '${t.substring(0, 1997)}…' : t;
    }
  }

  final factsForModel = clampMoodyPlaceBlurbFactsForEdge(ctx.facts);

  final key = MoodyPlaceBlurbCache.cacheKey(
    place.id,
    ctx.lang,
    factsForModel.hashCode,
    variant: 'detail_v4',
  );
  final hit = MoodyPlaceBlurbCache.get(key);
  if (hit != null) return hit;

  final existing = MoodyPlaceBlurbCache.inflight(key);
  if (existing != null) return existing;

  final ai = ref.read(moodyAIServiceProvider);
  final future = () async {
    var out = '';
    if (ApiConstants.openAiApiKey.isNotEmpty) {
      out = (await ai.generatePlaceDetailBlurb(
        l10n: ctx.l10n,
        factsBlock: factsForModel,
        bcp47LanguageCode: ctx.lang,
      ))
          .trim();
    }
    if (out.isEmpty) {
      out = (await moodyPlaceDetailBlurbFromEdge(
        facts: factsForModel,
        languageCode: ctx.lang,
      ))
          .trim();
      if (out.isNotEmpty && kDebugMode) {
        debugPrint(
          'moodyPlaceDetailBlurbProvider: non-empty edge blurb place=${place.name} id=${place.id} len=${out.length}',
        );
      }
    }
    if (out.isEmpty) {
      final ed = (editorialBase ?? ctx.editorial)?.trim();
      if (ed != null && ed.length >= 80) {
        out = ed.length > 2000 ? '${ed.substring(0, 1997)}…' : ed;
      }
    }
    if (out.isNotEmpty) {
      MoodyPlaceBlurbCache.put(key, out);
    }
    return out;
  }();

  MoodyPlaceBlurbCache.setInflight(key, future);
  try {
    return await future;
  } finally {
    MoodyPlaceBlurbCache.clearInflight(key);
  }
});
