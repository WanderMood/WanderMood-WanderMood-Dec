import 'package:wandermood/core/presentation/widgets/guest_demo_about_sections.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/features/places/data/place_card_ui_description.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Decision-layer copy for Explore quick peek (not the card teaser).
class ExploreQuickPeekCopy {
  ExploreQuickPeekCopy._();

  static String moodDisplayLabel(String? moodSlug, AppLocalizations l10n) {
    switch (moodSlug?.trim().toLowerCase()) {
      case 'cozy':
      case 'gezellig':
        return l10n.moodCozy;
      case 'relaxed':
      case 'ontspannen':
        return l10n.moodRelaxed;
      case 'adventurous':
      case 'avontuurlijk':
        return l10n.moodAdventurous;
      case 'cultural':
      case 'cultureel':
        return l10n.moodCultural;
      case 'romantic':
      case 'romantisch':
        return l10n.moodRomantic;
      case 'social':
      case 'sociaal':
        return l10n.moodSocial;
      case 'energetic':
      case 'energiek':
        return l10n.moodEnergetic;
      case 'contemplative':
        return l10n.moodRelaxed;
      default:
        return moodSlug?.trim().isNotEmpty == true
            ? moodSlug!.trim()[0].toUpperCase() +
                moodSlug.trim().substring(1)
            : l10n.moodRelaxed;
    }
  }

  static String? whyFitsLine(String? moodSlug, AppLocalizations l10n) {
    final slug = moodSlug?.trim();
    if (slug == null || slug.isEmpty) return null;
    return l10n.explorePeekWhyFits(moodDisplayLabel(slug, l10n));
  }

  /// Moody voice line — prefer edge hook / first insight, not the card one-liner.
  static String? moodyTakeLine(
    PlaceCardUiDescription? ui,
    Place place,
    AppLocalizations l10n,
  ) {
    final hook = ui?.hook?.trim();
    if (hook != null && hook.length > 24) {
      return hook;
    }
    if (ui != null && ui.isRich) {
      final sections = parseGuestDemoAboutSections(ui.sectionsSource!);
      for (final s in sections) {
        final body = s.body.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (body.length >= 28) {
          return ExplorePlaceCardCopy.firstSentenceTeaser(body);
        }
      }
    }
    final editorial = ExplorePlaceCardCopy.usableEditorialExcludingTypeFallback(place);
    if (editorial != null && editorial.length > 40) {
      return ExplorePlaceCardCopy.firstSentenceTeaser(editorial);
    }
    return hook?.isNotEmpty == true ? hook : null;
  }

  /// Up to four “good for” chips — distinct from practical metadata chips.
  static List<String> fitsForLabels(
    Place place,
    AppLocalizations l10n, {
    String? moodSlug,
  }) {
    final scores = <String, int>{};

    void bump(String key, int points) {
      if (key.isEmpty) return;
      scores[key] = (scores[key] ?? 0) + points;
    }

    for (final raw in place.types) {
      final t = raw.toLowerCase();
      if (t.contains('cafe') || t.contains('coffee')) {
        bump('coffee', 4);
        bump('solo', 2);
        bump('cozy', 2);
        bump('work', 1);
      } else if (t.contains('restaurant') || t.contains('food')) {
        bump('friends', 3);
        bump('date', 2);
      } else if (t.contains('bar') || t.contains('night_club')) {
        bump('friends', 4);
      } else if (t.contains('museum') ||
          t.contains('gallery') ||
          t.contains('art')) {
        bump('culture', 4);
        bump('solo', 2);
      } else if (t.contains('park') || t.contains('garden')) {
        bump('outdoor', 3);
        bump('solo', 2);
        bump('friends', 1);
      } else if (t.contains('bakery')) {
        bump('brunch', 3);
        bump('coffee', 2);
      } else if (t.contains('library')) {
        bump('work', 3);
        bump('solo', 3);
      }
    }

    final energy = place.energyLevel.trim().toLowerCase();
    if (energy == 'low') bump('cozy', 2);
    if (energy == 'high') bump('friends', 1);

    switch (place.socialSignal?.trim().toLowerCase()) {
      case 'hidden_gem':
        bump('solo', 2);
      case 'loved_by_locals':
        bump('friends', 1);
      case 'trending':
        bump('friends', 2);
      default:
        break;
    }

    switch (moodSlug?.trim().toLowerCase()) {
      case 'romantic':
        bump('date', 4);
      case 'social':
        bump('friends', 4);
      case 'cultural':
      case 'cultureel':
        bump('culture', 4);
      case 'relaxed':
      case 'cozy':
      case 'gezellig':
        bump('cozy', 3);
        bump('solo', 2);
      case 'adventurous':
        bump('outdoor', 3);
      default:
        break;
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final labels = <String>[];
    for (final e in ranked) {
      final label = _fitsKeyLabel(e.key, l10n);
      if (label == null) continue;
      if (labels.contains(label)) continue;
      labels.add(label);
      if (labels.length >= 4) break;
    }
    return labels;
  }

  static String? _fitsKeyLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'coffee':
        return l10n.explorePeekFitsCoffee;
      case 'work':
        return l10n.explorePeekFitsWork;
      case 'friends':
        return l10n.explorePeekFitsFriends;
      case 'solo':
        return l10n.explorePeekFitsSolo;
      case 'cozy':
        return l10n.explorePeekFitsCozy;
      case 'date':
        return l10n.explorePeekFitsDate;
      case 'culture':
        return l10n.explorePeekFitsCulture;
      case 'brunch':
        return l10n.explorePeekFitsBrunch;
      case 'outdoor':
        return l10n.explorePeekFitsOutdoor;
      default:
        return null;
    }
  }

  static String? miniReviewSnippet(Map<String, dynamic>? review) {
    if (review == null) return null;
    final text = (review['text'] as String?)?.trim() ??
        (review['review_text'] as String?)?.trim() ??
        '';
    if (text.isEmpty) return null;
    return ExplorePlaceCardCopy.firstSentenceTeaser(text);
  }

  static String? miniReviewAuthor(Map<String, dynamic>? review) {
    final name = (review?['author_name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }
}
