import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Below Edge `invalid_facts` limit (12k) so JSON body + overhead stay safe.
const int kMoodyPlaceBlurbFactsMaxChars = 11500;

/// Truncates [facts] at a line boundary when over [kMoodyPlaceBlurbFactsMaxChars].
String clampMoodyPlaceBlurbFactsForEdge(String facts) {
  final t = facts.trim();
  if (t.length <= kMoodyPlaceBlurbFactsMaxChars) return t;
  var cut = t.substring(0, kMoodyPlaceBlurbFactsMaxChars);
  final li = cut.lastIndexOf('\n');
  if (li > kMoodyPlaceBlurbFactsMaxChars ~/ 2) cut = cut.substring(0, li);
  return cut.trim();
}

/// Builds a grounded fact block for the Moody place-card model (localized labels).
String buildMoodyPlaceBlurbFactsBlock(
  AppLocalizations l10n,
  Place place, {
  String? editorialOverride,
  List<String>? reviewSnippets,
  int? reviewCountOverride,
}) {
  final lines = <String>[];
  lines.add('${l10n.moodyPlaceBlurbLabelName}: ${place.name}');
  final addr = place.address.trim();
  if (addr.isNotEmpty) {
    lines.add('${l10n.moodyPlaceBlurbLabelAddress}: $addr');
  }
  if (place.types.isNotEmpty) {
    lines.add('${l10n.moodyPlaceBlurbLabelTypes}: ${place.types.join(', ')}');
  }
  if (place.rating > 0) {
    lines.add(
      '${l10n.moodyPlaceBlurbLabelRating}: ${place.rating.toStringAsFixed(1)} / 5',
    );
  }
  final rc = reviewCountOverride ?? place.reviewCount;
  if (rc > 0) {
    lines.add('${l10n.moodyPlaceBlurbLabelReviewCount}: $rc');
  }

  final overview = (editorialOverride ??
          place.editorialSummary ??
          place.description ??
          '')
      .trim();
  if (overview.isNotEmpty &&
      !ExplorePlaceCardCopy.isBoilerplateDescription(overview)) {
    lines.add('${l10n.moodyPlaceBlurbLabelOverview}: $overview');
  }

  if (reviewSnippets != null && reviewSnippets.isNotEmpty) {
    lines.add('${l10n.moodyPlaceBlurbLabelVisitorNotes}:');
    for (final r in reviewSnippets) {
      final t = r.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (t.length < 12) continue;
      lines.add('- $t');
    }
  }

  return lines.join('\n');
}
