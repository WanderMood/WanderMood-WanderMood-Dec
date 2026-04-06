import 'dart:convert';

import 'package:wandermood/core/presentation/widgets/guest_demo_about_sections.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Rich Explore card (hook + sectioned copy) or a single plain line from editorial / Moody teaser.
class PlaceCardUiDescription {
  const PlaceCardUiDescription._({
    this.hook,
    this.sectionsSource,
    this.plainText,
  });

  factory PlaceCardUiDescription.rich({
    String? hook,
    required String sectionsSource,
  }) {
    final h = hook?.trim();
    return PlaceCardUiDescription._(
      hook: (h == null || h.isEmpty) ? null : h,
      sectionsSource: sectionsSource.trim(),
      plainText: null,
    );
  }

  factory PlaceCardUiDescription.plain(String text) {
    final t = text.trim();
    return PlaceCardUiDescription._(
      hook: null,
      sectionsSource: null,
      plainText: t,
    );
  }

  final String? hook;
  /// Delimited blocks for [GuestDemoAboutSectionsView].
  final String? sectionsSource;
  final String? plainText;

  bool get isRich =>
      sectionsSource != null && sectionsSource!.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        if (hook != null) 'hook': hook,
        if (sectionsSource != null) 'sections': sectionsSource,
        if (plainText != null) 'plain': plainText,
      };

  factory PlaceCardUiDescription.fromJson(Map<String, dynamic> j) {
    final sections = j['sections'] as String?;
    if (sections != null && sections.trim().isNotEmpty) {
      return PlaceCardUiDescription.rich(
        hook: j['hook'] as String?,
        sectionsSource: sections,
      );
    }
    final plain = j['plain'] as String? ?? '';
    return PlaceCardUiDescription.plain(plain);
  }

  String toCacheString() => jsonEncode(toJson());

  static PlaceCardUiDescription? fromCacheString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return PlaceCardUiDescription.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  /// Single-line string for legacy [moodyPlaceCardBlurbProvider].
  String asLegacyBlurbLine(AppLocalizations l10n, Place place) {
    if (plainText != null && plainText!.isNotEmpty) {
      return ExplorePlaceCardCopy.ensureMinSentencesForCard(
        place,
        plainText!,
        l10n,
      );
    }
    if (isRich) {
      final sections = parseGuestDemoAboutSections(sectionsSource!);
      if (sections.isEmpty) {
        return ExplorePlaceCardCopy.cardDescription(place, l10n);
      }
      final first = sections.first;
      final line = first.body.replaceAll(RegExp(r'\s+'), ' ').trim();
      return ExplorePlaceCardCopy.ensureMinSentencesForCard(place, line, l10n);
    }
    return ExplorePlaceCardCopy.cardDescription(place, l10n);
  }
}

/// Parsed edge response for `place_explore_rich`.
class PlaceExploreRichResult {
  PlaceExploreRichResult({this.hook, required this.sectionsJoined});

  final String? hook;
  final String sectionsJoined;

  bool get isValid {
    final sections = parseGuestDemoAboutSections(sectionsJoined);
    return sections.length >= 2 &&
        sections.every(
          (s) =>
              s.title.trim().isNotEmpty &&
              s.body.trim().length >= 12,
        );
  }

  static PlaceExploreRichResult? tryParse(Map<String, dynamic> raw) {
    final hook = raw['hook'];
    final hookStr = hook is String ? hook.trim() : '';
    final sectionsRaw = raw['sections'];
    if (sectionsRaw is! List) return null;
    final pairs = <({String title, String body})>[];
    for (final item in sectionsRaw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final title = (m['title'] as String?)?.trim() ?? '';
      final body = (m['body'] as String?)?.trim() ?? '';
      if (title.isEmpty || body.length < 8) continue;
      pairs.add((title: title, body: body));
    }
    if (pairs.length < 2) return null;
    final joined = pairs
        .map((s) => '${s.title}\n${s.body}')
        .join(guestDemoAboutSectionDelimiter);
    return PlaceExploreRichResult(
      hook: hookStr.isEmpty ? null : hookStr,
      sectionsJoined: joined,
    );
  }
}
