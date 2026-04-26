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
import 'package:wandermood/l10n/app_localizations.dart';

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

_PlaceBlurbContext _loadPlaceBlurbContext(
  Place place,
  ui.Locale locale,
) {
  final l10n = _l10nFor(locale);
  final lang = locale.languageCode;
  final editorial = place.editorialSummary?.trim();

  final facts = buildMoodyPlaceBlurbFactsBlock(
    l10n,
    place,
    editorialOverride:
        (editorial != null && editorial.isNotEmpty) ? editorial : null,
    reviewCountOverride: place.reviewCount > 0 ? place.reviewCount : null,
  );

  return _PlaceBlurbContext(
    facts: facts,
    lang: lang,
    l10n: l10n,
    editorial: editorial,
  );
}

/// Explore card line from already-available place editorial fields only.
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
  // Skip the disk-hydration await when both caches are already warm — this
  // keeps the provider completing in the same microtask batch as any concurrent
  // setState (e.g. photo resolution), preventing an extra Riverpod rebuild.
  if (!MoodyPlaceCardUiCache.isHydrated || !MoodyPlaceBlurbCache.isHydrated) {
    await Future.wait([
      MoodyPlaceCardUiCache.ensureHydrated(),
      MoodyPlaceBlurbCache.ensureHydrated(),
    ]);
  }
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
  if (stableHit != null && stableHit.isRich) {
    if (kDebugMode) {
      debugPrint(
        'moodyPlaceCardUiDescriptionProvider: stable cache hit ${place.name} id=${place.id}',
      );
    }
    return stableHit;
  }

  final ctx = _loadPlaceBlurbContext(place, locale);
  final factsForModel = clampMoodyPlaceBlurbFactsForEdge(ctx.facts);

  final uiKey = MoodyPlaceCardUiCache.cacheKey(
    place.id,
    ctx.lang,
    factsForModel.hashCode,
  );
  final uiHit = MoodyPlaceCardUiCache.get(uiKey);
  if (uiHit != null) {
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
      placeId: place.id.startsWith('google_') ? place.id.substring(7) : place.id,
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
          placeId: place.id.startsWith('google_') ? place.id.substring(7) : place.id,
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

/// Cache-only variant for scroll surfaces (Explore cards): never calls AI/edge.
final moodyPlaceCardUiDescriptionCacheOnlyProvider =
    FutureProvider.autoDispose.family<PlaceCardUiDescription, Place>(
        (ref, place) async {
  if (!MoodyPlaceCardUiCache.isHydrated || !MoodyPlaceBlurbCache.isHydrated) {
    await Future.wait([
      MoodyPlaceCardUiCache.ensureHydrated(),
      MoodyPlaceBlurbCache.ensureHydrated(),
    ]);
  }
  final appLocale = ref.watch(localeProvider);
  final locale = appLocale ?? ui.PlatformDispatcher.instance.locale;
  final l10n = _l10nFor(locale);
  final comm =
      ref.read(communicationStyleProvider.notifier).getCurrentStyleString();
  final lang = locale.languageCode;
  final stableKey = MoodyPlaceCardUiCache.stableCacheKey(place.id, lang, comm);

  final stableHit = MoodyPlaceCardUiCache.get(stableKey);
  if (stableHit != null) return stableHit;

  final ctx = _loadPlaceBlurbContext(place, locale);
  final factsForModel = clampMoodyPlaceBlurbFactsForEdge(ctx.facts);
  final uiKey = MoodyPlaceCardUiCache.cacheKey(
    place.id,
    ctx.lang,
    factsForModel.hashCode,
  );
  final uiHit = MoodyPlaceCardUiCache.get(uiKey);
  if (uiHit != null && uiHit.isRich) {
    MoodyPlaceCardUiCache.putWithStableAlias(uiKey, stableKey, uiHit);
    return uiHit;
  }

  final syncLine = _editorialLineFromPlaceOrGoogle(place, l10n, ctx.editorial);
  if (syncLine != null && syncLine.isNotEmpty) {
    return PlaceCardUiDescription.plain(syncLine);
  }

  final legacyKey = MoodyPlaceBlurbCache.cacheKey(
    place.id,
    ctx.lang,
    factsForModel.hashCode,
    variant: 'card_v5',
  );
  final cachedLegacy = MoodyPlaceBlurbCache.get(legacyKey);
  if (cachedLegacy != null && cachedLegacy.trim().isNotEmpty) {
    return PlaceCardUiDescription.plain(cachedLegacy.trim());
  }

  final fallback = ExplorePlaceCardCopy.cardDescription(place, l10n);
  return PlaceCardUiDescription.plain(fallback);
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
  await MoodyPlaceBlurbCache.ensureHydrated();
  final appLocale = ref.watch(localeProvider);
  final locale = appLocale ?? ui.PlatformDispatcher.instance.locale;
  final ctx = _loadPlaceBlurbContext(place, locale);

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
        placeId: place.id.startsWith('google_') ? place.id.substring(7) : place.id,
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
