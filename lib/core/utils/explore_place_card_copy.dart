import 'package:flutter/material.dart';
import 'package:wandermood/core/utils/place_type_formatter.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Copy + pricing rules for Explore list/grid cards (shared pipeline).
class ExplorePlaceCardCopy {
  ExplorePlaceCardCopy._();

  /// Compact review total for card chrome (e.g. `122`, `1.2k`, `12k`).
  static String formatReviewCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return k >= 10 ? '${k.round()}k' : '${k.toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  /// Google / Moody types that almost always charge (entry or consumption).
  static const Set<String> _typicallyPaidRoots = {
    'restaurant',
    'bar',
    'night_club',
    'cafe',
    'coffee_shop',
    'bakery',
    'meal_takeaway',
    'food',
    'zoo',
    'aquarium',
    'museum',
    'art_gallery',
    'tourist_attraction',
    'amusement_park',
    'spa',
    'movie_theater',
    'bowling_alley',
    'casino',
    'stadium',
    'gym',
    'shopping_mall',
    'clothing_store',
    'store',
  };

  /// Types where public access is often free (still not "free" if price_level says paid).
  static const Set<String> _oftenFreeEntryRoots = {
    'park',
    'natural_feature',
    'public_square',
    'plaza',
    'neighborhood',
    'locality',
    'viewpoint',
    'hiking_area',
    'beach',
    'cemetery',
    'church',
    'mosque',
    'synagogue',
    'hindu_temple',
    'library',
  };

  static List<String> _typesLower(Place place) =>
      place.types.map((t) => t.toLowerCase()).toList();

  static bool typesImplyTypicallyPaid(List<String> typesLower) {
    for (final t in typesLower) {
      for (final p in _typicallyPaidRoots) {
        if (t == p || t.contains(p)) return true;
      }
    }
    return false;
  }

  static bool typesImplyOftenFreeEntry(List<String> typesLower) {
    for (final t in typesLower) {
      for (final f in _oftenFreeEntryRoots) {
        if (t == f || t.contains(f)) return true;
      }
    }
    return false;
  }

  /// Moody explore card → safe [Place.isFree] (never true for unknown price on paid venues).
  static bool inferIsFreeFromExploreCard(Map<String, dynamic> card) {
    final explicit = card['is_free'];
    if (explicit == true) return true;
    if (explicit == false) return false;

    final types = ((card['types'] as List<dynamic>?) ?? const [])
        .map((e) => e.toString().toLowerCase())
        .toList();
    final pl = card['price_level'];
    final priceLevel = pl is num ? pl.toInt() : null;

    if (priceLevel != null && priceLevel >= 1 && priceLevel <= 4) {
      return false;
    }
    if (typesImplyTypicallyPaid(types)) {
      return false;
    }
    if (typesImplyOftenFreeEntry(types)) {
      return priceLevel == null || priceLevel == 0;
    }
    return false;
  }

  /// After [Place] is built (e.g. from details API): conservative isFree.
  static bool inferIsFreeFromDetails({
    required List<String> types,
    required int? priceLevel,
  }) {
    final typesLower = types.map((e) => e.toLowerCase()).toList();
    if (typesImplyTypicallyPaid(typesLower)) {
      return false;
    }
    if (priceLevel != null && priceLevel >= 1 && priceLevel <= 4) {
      return false;
    }
    if (priceLevel == 0) {
      return true;
    }
    if (typesImplyOftenFreeEntry(typesLower) &&
        (priceLevel == null || priceLevel == 0)) {
      return true;
    }
    return false;
  }

  /// Search-result style: priceLevel 0 only if not a paid venue type.
  static bool inferIsFreeFromSearch({
    required List<String> types,
    required int? priceLevel,
    required bool isFreePlaceType,
  }) {
    final typesLower = types.map((e) => e.toLowerCase()).toList();
    if (typesImplyTypicallyPaid(typesLower)) {
      return false;
    }
    final byPrice = priceLevel != null && priceLevel == 0;
    if (byPrice) return true;
    return isFreePlaceType && (priceLevel == null || priceLevel == 0);
  }

  // --- Description ---

  static bool isBoilerplateDescription(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('rated ') && lower.contains('stars')) return true;
    if (lower.contains(' reviews') ||
        lower.contains(' recensies') ||
        lower.contains('recensies ') ||
        RegExp(r'\d+\s+reviews').hasMatch(lower) ||
        RegExp(r'\d+\s+recensies?').hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'\bhas\s+\d+\s+reviews?\b').hasMatch(lower)) return true;
    if (RegExp(r'\bheeft\s+\d+\s+recensies\b').hasMatch(lower)) return true;
    if (lower.contains('beoordeling') && lower.contains('sterren')) return true;
    if (lower.contains('populair restaurant') || lower.contains('popular restaurant')) {
      return true;
    }
    if (lower.contains('uitstekende keuze') ||
        lower.contains('excellent choice') ||
        lower.contains('great choice')) {
      return true;
    }
    if (lower.contains('offers ') && lower.contains(' cuisine')) return true;
    if (lower.contains('perfect for your') ||
        lower.contains('perfect for happy') ||
        lower.contains('is a highly-rated')) {
      return true;
    }
    if (lower.contains('top spot for your') || lower.contains('topadres voor je')) {
      return true;
    }
    if (lower.contains('gewaardeerd') && lower.contains('sterren')) return true;
    if (RegExp(r'^\d').hasMatch(raw.trim())) return true;
    // Legacy Explore search templates (English) — treat as non-editorial.
    if (lower.contains('immerse yourself in culture at')) return true;
    if (lower.contains('discover culinary delights at')) return true;
    if (lower.contains('enjoy the outdoors at') &&
        lower.contains('connecting with nature')) {
      return true;
    }
    if (lower.contains('experience the unique charm of') &&
        lower.contains('must-visit destination')) {
      return true;
    }
    if (lower.contains('popular local destination offering unique experiences')) {
      return true;
    }
    return false;
  }

  /// Raw paragraph: editorial summary if clean, else [Place.description], else type blurb.
  static String cardPrimaryDescription(Place place, AppLocalizations l10n) {
    final ed = usableEditorialExcludingTypeFallback(place);
    if (ed != null) return ed;
    return typeFallbackBlurb(place, l10n);
  }

  /// Google-style editorial on the place model (not the generic type fallback).
  static String? usableEditorialExcludingTypeFallback(Place place) {
    final ed = place.editorialSummary?.trim();
    if (ed != null && ed.isNotEmpty && !isBoilerplateDescription(ed)) {
      return ed;
    }
    final raw = place.description?.trim();
    if (raw != null && raw.isNotEmpty && !isBoilerplateDescription(raw)) {
      return raw;
    }
    return null;
  }

  /// One rich line for Explore cards from a full editorial paragraph.
  static String editorialLineForExploreCard(String editorial) {
    var t = editorial.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return '';
    final parts = t
        .split(RegExp(r'(?<=[.!?…])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 8)
        .toList();
    if (parts.isEmpty) {
      return t.length > 320 ? '${t.substring(0, 317)}…' : t;
    }
    var out = parts.first;
    if (out.length < 90 && parts.length > 1) {
      out = '${parts[0]} ${parts[1]}'.trim();
    }
    if (out.length > 320) out = '${out.substring(0, 317)}…';
    return out;
  }

  /// `€` repeated [priceLevel] times (1–4). Empty for 0, null, or out of range.
  static String priceLevelEuroSymbols(int? priceLevel) {
    if (priceLevel == null || priceLevel <= 0 || priceLevel > 4) return '';
    return List.filled(priceLevel, '€').join();
  }

  /// Title-row price tier: real [Place.priceLevel] when present; otherwise `€€`
  /// for venue types that usually charge (Explore often omits `price_level`).
  static String exploreCardPriceTierEuros(Place place) {
    final fromLevel = priceLevelEuroSymbols(place.priceLevel);
    if (fromLevel.isNotEmpty) return fromLevel;
    if (_showFreePill(place)) return '';
    final types = _typesLower(place);
    if (typesImplyTypicallyPaid(types)) {
      return '€€';
    }
    return '';
  }

  static const Set<String> _genericVenueTypes = {
    'point_of_interest',
    'establishment',
    'premise',
  };

  static String? _firstNonGenericType(Iterable<String> typesLower) {
    for (final t in typesLower) {
      final s = t.trim().toLowerCase();
      if (s.isEmpty) continue;
      if (!_genericVenueTypes.contains(s)) return s;
    }
    return null;
  }

  /// Short explore-card pill label for a concrete Places type.
  static String _concreteVenuePillLabel(String t, AppLocalizations l10n) {
    switch (t) {
      case 'restaurant':
      case 'food':
        return l10n.placeTypeRestaurant;
      case 'cafe':
      case 'coffee_shop':
        return l10n.placeTypeCafe;
      case 'bar':
        return l10n.placeTypeBar;
      case 'bakery':
        return l10n.placeTypeBakery;
      case 'museum':
        return l10n.placeTypeMuseum;
      case 'art_gallery':
        return l10n.placeCardVenueGallery;
      case 'night_club':
        return l10n.placeCardVenueClub;
      case 'park':
      case 'natural_feature':
        return l10n.placeTypePark;
      case 'tourist_attraction':
        return l10n.placeCardVenueAttraction;
      case 'lodging':
      case 'hotel':
        return l10n.placeCardVenueHotel;
      default:
        return formatPlaceType(t, languageCode: l10n.localeName);
    }
  }

  static String _resolveVenueTypeForPill(
    String typeLower,
    List<String> typesLower,
    AppLocalizations l10n,
  ) {
    if (_genericVenueTypes.contains(typeLower)) {
      final next = _firstNonGenericType(typesLower);
      if (next != null) {
        return _concreteVenuePillLabel(next, l10n);
      }
      return l10n.placeCardVenuePlace;
    }
    return _concreteVenuePillLabel(typeLower, l10n);
  }

  static String? bestTimeDisplayLabel(String? bestTime, AppLocalizations l10n) {
    switch (bestTime?.trim().toLowerCase()) {
      case 'morning':
        return l10n.placeCardBestMorning;
      case 'afternoon':
        return l10n.placeCardBestAfternoon;
      case 'evening':
        return l10n.placeCardBestEvening;
      case 'all_day':
        return l10n.placeCardBestAllDay;
      default:
        return null;
    }
  }

  /// Rough typical visit length for Explore cards (same heuristics as My Day free-time carousel).
  static int estimateVisitMinutes(Place place) {
    final types = _typesLower(place);
    if (types.any((t) =>
        ['restaurant', 'cafe', 'bakery', 'meal_takeaway', 'food'].contains(t))) {
      return 90;
    }
    if (types.any((t) =>
        ['gym', 'stadium', 'park', 'natural_feature'].contains(t))) {
      return 60;
    }
    if (types.any((t) => [
          'shopping_mall',
          'store',
          'clothing_store',
          'shoe_store',
        ].contains(t))) {
      return 45;
    }
    if (types.any((t) => [
          'movie_theater',
          'night_club',
          'bowling_alley',
          'casino',
        ].contains(t))) {
      return 120;
    }
    if (types.any((t) => [
          'museum',
          'art_gallery',
          'tourist_attraction',
          'church',
          'place_of_worship',
        ].contains(t))) {
      return 60;
    }
    return 60;
  }

  /// Localized "~90 min" style line for cards ([myDayFreeTimeInsightDuration]).
  static String exploreCardVisitDurationLabel(
    Place place,
    AppLocalizations l10n,
  ) {
    return l10n.myDayFreeTimeInsightDuration(estimateVisitMinutes(place));
  }

  /// Background, foreground, label for explore social signal pill; null if unknown/absent.
  static ({Color background, Color foreground, String label})? socialSignalChipStyle(
    String? socialSignal,
    AppLocalizations l10n,
  ) {
    const parchment = Color(0xFFE8E2D8);
    const charcoal = Color(0xFF1E1C18);
    const sunset = Color(0xFFE8784A);
    const forest = Color(0xFF2A6049);
    const dusk = Color(0xFF4A4640);
    switch (socialSignal?.trim().toLowerCase()) {
      case 'trending':
        return (
          background: sunset,
          foreground: Colors.white,
          label: l10n.placeCardSocialTrending,
        );
      case 'hidden_gem':
        return (
          background: charcoal,
          foreground: Colors.white,
          label: l10n.placeCardSocialHiddenGem,
        );
      case 'loved_by_locals':
        return (
          background: forest,
          foreground: Colors.white,
          label: l10n.placeCardSocialLovedByLocals,
        );
      case 'popular':
        return (
          background: parchment,
          foreground: dusk,
          label: l10n.placeCardSocialPopular,
        );
      default:
        return null;
    }
  }

  /// Label for cuisine/type pill: [Place.primaryType] or first entry in [Place.types].
  /// Generic types (`point_of_interest`, `establishment`, `premise`) resolve via first
  /// non-generic type, else localized "Place". Unknown concrete types → "Place".
  /// Returns null when there is no useful label or only the vague generic "Place" pill.
  static String? primaryTypeLabelForCard(Place place, AppLocalizations l10n) {
    final typesLower = place.types
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    final genericPlace = l10n.placeCardVenuePlace;

    final primaryRaw = place.primaryType?.trim().toLowerCase();
    if (primaryRaw != null && primaryRaw.isNotEmpty) {
      final label = _resolveVenueTypeForPill(primaryRaw, typesLower, l10n);
      final t = label.trim();
      if (t.isEmpty || t == genericPlace) return null;
      return t;
    }

    if (typesLower.isEmpty) return null;

    for (final t in typesLower) {
      final label = _resolveVenueTypeForPill(t, typesLower, l10n);
      final trimmed = label.trim();
      if (trimmed.isEmpty || trimmed == genericPlace) continue;
      return trimmed;
    }
    return null;
  }

  /// One or more sentences for Explore cards (at least two when possible).
  static String cardDescription(Place place, AppLocalizations l10n) {
    return ensureMinSentencesForCard(place, cardPrimaryDescription(place, l10n), l10n);
  }

  /// Detail info card when Moody/detail AI is empty: richer than [cardDescription].
  static String detailFallbackDescription(Place place, AppLocalizations l10n) {
    return ensureMinSentencesForDetail(place, '', l10n);
  }

  static int sentenceCount(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    final byStop = t.split(RegExp(r'(?<=[.!?…])\s+')).where((s) => s.trim().length > 4).toList();
    return byStop.length.clamp(1, 99);
  }

  static bool textMentionsRating(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('/5')) return true;
    if (lower.contains('out of 5')) return true;
    if (lower.contains('van de 5')) return true;
    if (lower.contains('sur 5')) return true;
    if (lower.contains('von 5')) return true;
    if (RegExp(r'\b\d+[.,]\d\s*/\s*5\b').hasMatch(lower)) return true;
    if (lower.contains('bezoekers geven') && RegExp(r'\d').hasMatch(lower)) {
      return true;
    }
    if (lower.contains('visitor') && lower.contains('rating')) return true;
    return false;
  }

  static bool _textContainsAddressSnippet(String text, String address) {
    final a = address.trim().toLowerCase();
    if (a.length < 8) return false;
    final head = a.split(',').first.trim();
    if (head.length < 6) return false;
    return text.toLowerCase().contains(head);
  }

  /// List/grid card copy: trimmed only. No extra “tap for reviews / bezoekers geven …”
  /// line — star rating is already on the card.
  static String ensureMinSentencesForCard(
    Place place,
    String text,
    AppLocalizations l10n,
  ) {
    Object.hash(place.id, l10n.hashCode);
    return text.trim();
  }

  /// Extra copy for the place detail info card (third paragraph + context).
  static String ensureMinSentencesForDetail(
    Place place,
    String text,
    AppLocalizations l10n,
  ) {
    var t = text.trim();
    if (t.isEmpty) {
      t = cardDescription(place, l10n);
    } else {
      t = ensureMinSentencesForCard(place, t, l10n);
    }
    if (sentenceCount(t) >= 3 && t.length >= 220) return t;

    final parts = <String>[t];
    if (place.address.isNotEmpty &&
        !_textContainsAddressSnippet(t, place.address)) {
      parts.add(l10n.placeDetailBlurbExtraAddress);
    }
    if (place.rating > 0 && !textMentionsRating(t)) {
      if (place.reviewCount > 0) {
        parts.add(
          l10n.placeDetailBlurbExtraRatingCount(
            place.rating.toStringAsFixed(1),
            place.reviewCount,
          ),
        );
      } else {
        parts.add(
          l10n.placeDetailBlurbExtraRatingOnly(
            place.rating.toStringAsFixed(1),
          ),
        );
      }
    }
    parts.add(l10n.placeDetailBlurbExtraReviewsTab);
    return parts.join('\n\n');
  }

  static String typeFallbackBlurb(Place place, AppLocalizations l10n) {
    final types = _typesLower(place);

    if (types.any((t) => t == 'zoo' || t.contains('zoo'))) {
      return l10n.exploreCardBlurbZoo;
    }
    if (types.any((t) => t == 'aquarium' || t.contains('aquarium'))) {
      return l10n.exploreCardBlurbAquarium;
    }
    if (types.any((t) => t == 'night_club')) {
      return l10n.exploreCardBlurbNightlife;
    }
    if (types.any((t) => t == 'bar')) {
      return l10n.exploreCardBlurbBar;
    }
    if (types.any((t) => t == 'cafe' || t == 'coffee_shop')) {
      return l10n.exploreCardBlurbCafe;
    }
    if (types.any((t) => t == 'bakery')) {
      return l10n.exploreCardBlurbBakery;
    }
    if (types.any((t) => t == 'meal_takeaway')) {
      return l10n.exploreCardBlurbTakeaway;
    }
    if (types.any((t) => t == 'restaurant' || t == 'food')) {
      return l10n.exploreCardBlurbRestaurant;
    }
    if (types.any((t) => t == 'museum' || t == 'art_gallery')) {
      return l10n.exploreCardBlurbMuseum;
    }
    if (types.any((t) => t == 'spa' || t == 'beauty_salon')) {
      return l10n.exploreCardBlurbSpa;
    }
    if (types.any((t) =>
        t == 'shopping_mall' || t == 'clothing_store' || t == 'store')) {
      return l10n.exploreCardBlurbShopping;
    }
    if (types.any((t) => t == 'park' || t == 'natural_feature')) {
      return l10n.exploreCardBlurbPark;
    }
    if (types.any((t) => t == 'tourist_attraction')) {
      return l10n.exploreCardBlurbAttraction;
    }
    if (types.any((t) =>
        t == 'travel_agency' ||
        t == 'tour_operator' ||
        (t.contains('tour') && !t.contains('tourist')))) {
      return l10n.exploreCardBlurbTour;
    }
    if (types.any((t) =>
        t == 'point_of_interest' ||
        t == 'establishment' ||
        t == 'premise')) {
      return l10n.exploreCardBlurbPoiNamed(place.name);
    }
    return l10n.exploreCardBlurbDefault;
  }

  // --- Price badge (Explore cards only) ---

  static bool shouldShowExplorePriceBadge(Place place) {
    final hasRange =
        place.priceRange != null && place.priceRange!.trim().isNotEmpty;
    if (hasRange) return true;
    final pl = place.priceLevel;
    if (pl != null && pl >= 1 && pl <= 4) return true;
    if (_showFreePill(place)) return true;
    final types = _typesLower(place);
    if (typesImplyTypicallyPaid(types) && !_showFreePill(place)) return true;
    return false;
  }

  static bool _showFreePill(Place place) {
    if (!place.isFree && place.priceLevel != 0) return false;
    final types = _typesLower(place);
    if (typesImplyTypicallyPaid(types)) return false;
    return place.isFree || place.priceLevel == 0;
  }

  static String explorePriceBadgeText(
    Place place,
    AppLocalizations l10n, {
    String currency = '€',
  }) {
    if (_showFreePill(place)) {
      return l10n.dayPlanCardFree;
    }
    if (place.priceRange != null && place.priceRange!.trim().isNotEmpty) {
      return place.priceRange!.replaceAll(RegExp(r'[€£\$]'), currency);
    }
    final pl = place.priceLevel;
    if (pl != null && pl >= 1 && pl <= 4) {
      return _priceLevelLabel(pl, currency, l10n);
    }
    final types = _typesLower(place);
    if (typesImplyTypicallyPaid(types) && !_showFreePill(place)) {
      return l10n.placeCardPriceVaries;
    }
    return '';
  }

  static Color explorePriceBadgeColor(Place place) {
    if (_showFreePill(place)) {
      return const Color(0xFF2A6049);
    }
    final pl = place.priceLevel;
    if (pl != null) {
      switch (pl) {
        case 1:
          return const Color(0xFF2A6049);
        case 2:
          return const Color(0xFFFF9800);
        case 3:
          return const Color(0xFFE91E63);
        case 4:
          return const Color(0xFF9C27B0);
        default:
          return const Color(0xFF4A4640);
      }
    }
    final types = _typesLower(place);
    if (typesImplyTypicallyPaid(types) && !_showFreePill(place)) {
      return const Color(0xFFFF9800);
    }
    return const Color(0xFF4A4640);
  }

  static String _priceLevelLabel(
    int priceLevel,
    String currency,
    AppLocalizations l10n,
  ) {
    switch (priceLevel) {
      case 1:
        return '$currency 5-15';
      case 2:
        return '$currency 15-30';
      case 3:
        return '$currency 30-50';
      case 4:
        return '$currency 50+';
      default:
        return l10n.placeCardPriceVaries;
    }
  }
}
