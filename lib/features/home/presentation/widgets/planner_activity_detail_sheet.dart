import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_v2.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/core/presentation/widgets/guest_demo_about_sections.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/screens/place_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/features/home/presentation/utils/my_day_display_title.dart';
import 'package:wandermood/features/home/presentation/widgets/planner_mood_match_quick_chrome.dart';

const Color _wmForest = Color(0xFF2A6049);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);
const Color _placeQuickSheetFooterCream = Color(0xFFF5F0E8);

/// Footer strip matching sheet cream (`wmCream`) so CTAs sit on the same ground.
class PlaceQuickDetailSheetFooter extends StatelessWidget {
  const PlaceQuickDetailSheetFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _placeQuickSheetFooterCream,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFCFC4B8), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Strong outline style for tertiary CTAs on quick sheets (e.g. “Open full place”).
ButtonStyle placeQuickSheetOutlinedButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF163D2C),
    backgroundColor: _placeQuickSheetFooterCream,
    side: const BorderSide(color: Color(0xFF2A6049), width: 2),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
  );
}

/// Filled mint secondary — reads clearly on white footer (e.g. Add to My Day / Save).
ButtonStyle placeQuickSheetSecondaryFilledButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFC9E0D2),
    foregroundColor: const Color(0xFF143D2E),
    disabledForegroundColor: const Color(0xFF143D2E).withValues(alpha: 0.45),
    elevation: 3,
    shadowColor: const Color(0xFF1E1C18).withValues(alpha: 0.2),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
  );
}

/// Explore (and others): same quick sheet as My Day, built from a live [Place].
Future<void> showPlaceQuickDetailSheet(
  BuildContext context, {
  required Place place,
  required Widget Function(void Function() popSheet) footerBuilder,
  String? scheduledTimeLabel,
}) {
  String normalizedId(String raw) {
    final t = raw.trim();
    if (t.startsWith('google_')) return t;
    if (t.startsWith('ChIJ') || t.startsWith('EhIJ')) return 'google_$t';
    return t;
  }

  final targetId = normalizedId(place.id);
  final seeded =
      targetId != place.id ? place.copyWith(id: targetId) : place;

  return showPlannerActivityDetailSheet(
    context,
    activity: <String, dynamic>{
      'placeId': targetId,
      'place': seeded,
      'title': seeded.name,
    },
    scheduledTimeLabel: scheduledTimeLabel,
    footerBuilder: footerBuilder,
  );
}

/// Builds the route param for [GoRoute] `place-detail` from scheduled activity data.
String? resolvePlannerPlaceDetailRouteId(Map<String, dynamic> activity) {
  final raw = (activity['placeId'] ?? activity['place_id'])?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  final norm = GroupPlanV2.normalizeGooglePlaceIdCandidate(raw);
  if (norm == null) return null;
  if (norm.startsWith('google_')) return norm;
  return 'google_$norm';
}

/// Non-null when this planner row came from a Mood Match session.
String? resolvePlannerGroupSessionId(Map<String, dynamic> activity) {
  final a = activity['groupSessionId']?.toString().trim();
  if (a != null && a.isNotEmpty) return a;
  final b = activity['group_session_id']?.toString().trim();
  if (b != null && b.isNotEmpty) return b;
  return null;
}

String _capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Shared “Moody says” copy for planner detail sheet (My Day + Agenda).
/// Localized via [AppLocalizations] so it matches the user’s locale.
String plannerMoodyAdviceForActivity(
  AppLocalizations l10n,
  Map<String, dynamic> activity,
) {
  // Mood Match: pair story + notes live in [PlannerMoodMatchQuickChrome] above
  // the tabs — skip the duplicate “talking to both of you” bubble in legacy
  // [_DetailsPane] (same copy felt hollow next to the real pair rationale).
  if (resolvePlannerGroupSessionId(activity) != null) {
    return '';
  }
  return l10n.plannerMoodyAdviceBlurb;
}

List<String> _photoUrlsForActivity(Map<String, dynamic> activity) {
  final urls = <String>[];
  final main = activity['imageUrl']?.toString().trim();
  if (main != null && main.isNotEmpty) urls.add(main);
  final extra = activity['imageUrls'];
  if (extra is List) {
    for (final e in extra) {
      final s = e?.toString().trim();
      if (s != null && s.isNotEmpty && !urls.contains(s)) urls.add(s);
    }
  }
  return urls;
}

/// Planner bottom sheet: when [activity] has a Google-backed [placeId], embeds
/// [PlaceDetailScreen] quick view (same tabs / photos / reviews / Moody about as
/// full detail). Otherwise falls back to the legacy planner tabs.
Future<void> showPlannerActivityDetailSheet(
  BuildContext context, {
  required Map<String, dynamic> activity,
  required Widget Function(void Function() popSheet) footerBuilder,
  String? scheduledTimeLabel,
}) async {
  var effective = Map<String, dynamic>.from(activity);
  final sessionId = resolvePlannerGroupSessionId(effective);
  if (sessionId != null && sessionId.isNotEmpty) {
    try {
      final container = ProviderScope.containerOf(context);
      final repo = container.read(groupPlanningRepositoryProvider);
      effective = await repo.enrichActivityMapFromGroupPlan(effective);
      // Plan rows sometimes omit `place_id`; without it we stay on the legacy
      // tabs. Resolve via the same text search pipeline Explore uses so Mood
      // Match opens [PlaceDetailScreen] like the quick place sheet.
      if (resolvePlannerPlaceDetailRouteId(effective) == null) {
        await _tryResolvePlaceIdForMoodMatchPlannerSheet(container, effective);
      }
    } catch (e, st) {
      debugPrint('showPlannerActivityDetailSheet enrich: $e\n$st');
    }
  }

  if (!context.mounted) return;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      void popSheet() => Navigator.of(sheetContext).pop();
      final height = MediaQuery.sizeOf(sheetContext).height * 0.92;
      final l10n = AppLocalizations.of(sheetContext)!;
      final routePlaceId = resolvePlannerPlaceDetailRouteId(effective);
      final moodMatchSessionId = resolvePlannerGroupSessionId(effective);
      final rawSeed = effective['place'];
      final Place? seedPlace = rawSeed is Place ? rawSeed : null;
      final activityTitleForMatch =
          (effective['title'] ?? effective['name'])?.toString();

      final sheetChrome = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
        ],
      );

      final footer = PlaceQuickDetailSheetFooter(
        child: footerBuilder(popSheet),
      );

      final Widget body;
      if (routePlaceId != null) {
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sheetChrome,
            if (moodMatchSessionId != null)
              _moodMatchChromeLimited(
                sheetHeight: height,
                sessionId: moodMatchSessionId,
                activityTitle: activityTitleForMatch,
                placeId: routePlaceId,
              ),
            Expanded(
              child: PlaceDetailScreen(
                placeId: routePlaceId,
                quickViewLayout: true,
                seedPlace: seedPlace,
                scheduledTimeLabel: scheduledTimeLabel,
              ),
            ),
            footer,
          ],
        );
      } else {
        body = DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sheetChrome,
              if (moodMatchSessionId != null)
                _moodMatchChromeLimited(
                  sheetHeight: height,
                  sessionId: moodMatchSessionId,
                  activityTitle: activityTitleForMatch,
                  placeId: (effective['placeId'] ?? effective['place_id'])
                      ?.toString(),
                ),
              TabBar(
                labelColor: _wmForest,
                unselectedLabelColor: _wmStone,
                indicatorColor: _wmForest,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n.plannerSheetTabDetails),
                      ],
                    ),
                  ),
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n.plannerSheetTabPhotos),
                      ],
                    ),
                  ),
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_outline, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n.plannerSheetTabReviews),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, thickness: 1, color: _wmParchment),
              Expanded(
                child: TabBarView(
                  children: [
                    _DetailsPane(
                      activity: effective,
                      scheduledTimeLabel: scheduledTimeLabel,
                      moodyTip: plannerMoodyAdviceForActivity(l10n, effective),
                    ),
                    _PhotosPane(
                      urls: _photoUrlsForActivity(effective),
                      l10n: l10n,
                    ),
                    _ReviewsPane(activity: effective, l10n: l10n),
                  ],
                ),
              ),
              footer,
            ],
          ),
        );
      }

      return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              decoration: BoxDecoration(
                color: moodMatchSessionId != null
                    ? const Color(0xFFF5EDE4)
                    : (routePlaceId != null
                        ? const Color(0xFFF5F0E8)
                        : Colors.white),
              ),
              child: body,
            ),
          ),
        ),
      );
    },
  );
}

/// Caps Mood Match chrome height so the sheet leaves room for place tabs /
/// [PlaceDetailScreen] to scroll (otherwise the flex region can collapse to ~0).
Widget _moodMatchChromeLimited({
  required double sheetHeight,
  required String sessionId,
  required String? activityTitle,
  required String? placeId,
}) {
  // Tighter cap now that inline notes are optional off in chrome — more flex
  // for [PlaceDetailScreen] / tab bodies.
  final cap = math.min(240.0, math.max(140.0, sheetHeight * 0.28));
  return ConstrainedBox(
    constraints: BoxConstraints(maxHeight: cap),
    child: SingleChildScrollView(
      primary: false,
      physics: const BouncingScrollPhysics(),
      child: PlannerMoodMatchQuickChrome(
        sessionId: sessionId,
        activityTitle: activityTitle,
        placeId: placeId,
      ),
    ),
  );
}

class _DetailsPane extends StatelessWidget {
  final Map<String, dynamic> activity;
  final String? scheduledTimeLabel;
  final String moodyTip;

  const _DetailsPane({
    required this.activity,
    required this.scheduledTimeLabel,
    required this.moodyTip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = activity['duration'] as int? ?? 60;
    final category = _capitalizeFirst(
      (activity['category'] ?? l10n.dayPlanCardActivity).toString(),
    );
    final price = (activity['price'] as num?)?.toDouble() ?? 0.0;
    final payment = (activity['paymentStatus'] ?? 'free').toString();
    final rawTitle = activity['title']?.toString();
    final headlineShort = myDayShortActivityTitle(rawTitle, maxChars: 52);
    final headline = headlineShort.isNotEmpty
        ? headlineShort
        : (rawTitle != null && rawTitle.trim().isNotEmpty
            ? rawTitle.trim()
            : l10n.dayPlanCardActivity);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: WmPlaceOrHttpsNetworkImage(
              activity['imageUrl']?.toString() ??
                  'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80',
              fit: BoxFit.cover,
              progressIndicatorBuilder: (context, url, progress) =>
                  Container(color: Colors.grey[200]),
              errorBuilder: (context, error, stackTrace) => Container(
                color: _wmForest.withValues(alpha: 0.15),
                child: const Icon(Icons.image, color: _wmForest, size: 48),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          headline,
          style: GoogleFonts.museoModerno(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _wmCharcoal,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickChip(
                icon: Icons.schedule_rounded,
                label: l10n.dayPlanDurationMinutesOnly(duration),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickChip(
                icon: Icons.payments_outlined,
                label: price <= 0 || payment == 'free'
                    ? l10n.dayPlanCardFree
                    : '€${price.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickChip(
                icon: Icons.category_outlined,
                label: category.length > 12
                    ? '${category.substring(0, 12)}…'
                    : category,
              ),
            ),
          ],
        ),
        if (scheduledTimeLabel != null) ...[
          const SizedBox(height: 12),
          _InfoLine(
            icon: Icons.event_available_outlined,
            text: l10n.plannerSheetScheduledPrefix(scheduledTimeLabel!),
          ),
        ],
        if (moodyTip.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final cleaned = wmStripMoodyTipsHeadingLine(moodyTip);
              final text = cleaned.isEmpty ? moodyTip.trim() : cleaned;
              return Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.92,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEBF3EE), Color(0xFFE8F4FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: _wmForest.withValues(alpha: 0.16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E1C18).withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MoodyCharacter(size: 36, mood: 'happy'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              text,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                                color: _wmCharcoal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.plannerSheetAbout,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _wmCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          () {
            final d = activity['description']?.toString().trim() ?? '';
            return d.isNotEmpty ? d : l10n.plannerSheetNoDescription;
          }(),
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.5,
            color: _wmStone,
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _wmParchment),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: _wmForest),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _wmCharcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _wmForest),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _wmCharcoal,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotosPane extends StatelessWidget {
  final List<String> urls;
  final AppLocalizations l10n;

  const _PhotosPane({required this.urls, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.plannerSheetNoExtraPhotos,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.45,
              color: _wmStone,
            ),
          ),
        ),
      );
    }

    return PageView.builder(
      itemCount: urls.length,
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: WmPlaceOrHttpsNetworkImage(
              urls[i],
              fit: BoxFit.cover,
              width: double.infinity,
              progressIndicatorBuilder: (context, url, progress) =>
                  Container(color: Colors.grey[200]),
              errorBuilder: (context, error, stackTrace) => Container(
                color: _wmForest.withValues(alpha: 0.12),
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReviewsPane extends StatelessWidget {
  final Map<String, dynamic> activity;
  final AppLocalizations l10n;

  const _ReviewsPane({required this.activity, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final rating = (activity['rating'] as num?)?.toDouble() ?? 0.0;
    final hasNumeric = rating > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (hasNumeric) ...[
          Text(
            l10n.plannerSheetRatingOnPlan,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _wmCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < rating.round().clamp(1, 5)
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _wmCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        Text(
          l10n.plannerSheetWrittenReviews,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _wmCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasNumeric
              ? l10n.plannerSheetReviewsExplainerWithRating
              : l10n.plannerSheetReviewsExplainerNoRating,
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.5,
            color: _wmStone,
          ),
        ),
      ],
    );
  }
}

/// When Mood Match / plan rows omit `place_id`, resolve the venue with the same
/// text search used elsewhere so the sheet can embed [PlaceDetailScreen].
Future<void> _tryResolvePlaceIdForMoodMatchPlannerSheet(
  ProviderContainer container,
  Map<String, dynamic> effective,
) async {
  if (resolvePlannerPlaceDetailRouteId(effective) != null) return;
  if (resolvePlannerGroupSessionId(effective) == null) return;

  final title = (effective['title'] ?? effective['name'])?.toString().trim();
  if (title == null || title.length < 2) return;

  final scheduleCoords = _latLngFromActivityMap(effective);

  try {
    await container.read(placesServiceProvider.future);
    final notifier = container.read(placesServiceProvider.notifier);
    final results = await notifier.searchPlaces(title);
    if (results.isEmpty) return;

    PlacesSearchResult? bestByDistance;
    var bestKm = double.infinity;
    if (scheduleCoords != null) {
      for (final r in results) {
        final lat = r.geometry?.location.lat;
        final lng = r.geometry?.location.lng;
        if (lat == null || lng == null) continue;
        final d = _haversineKm(
          scheduleCoords.lat,
          scheduleCoords.lng,
          lat,
          lng,
        );
        if (d < bestKm) {
          bestKm = d;
          bestByDistance = r;
        }
      }
      if (bestByDistance != null && bestKm > 30.0) {
        bestByDistance = null;
      }
    }

    PlacesSearchResult? byName;
    final want = _plannerSheetNormTitle(title);
    for (final r in results) {
      if (_plannerSheetNormTitle(r.name) == want) {
        byName = r;
        break;
      }
    }

    final pick = bestByDistance ?? byName ?? results.first;
    final pid = pick.placeId.trim();
    if (pid.isEmpty) return;
    if (GroupPlanV2.normalizeGooglePlaceIdCandidate(pid) == null) return;

    effective['place_id'] = pid;
    effective['placeId'] = pid;
  } catch (e, st) {
    debugPrint('_tryResolvePlaceIdForMoodMatchPlannerSheet: $e\n$st');
  }
}

String _plannerSheetNormTitle(String s) =>
    s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

({double lat, double lng})? _latLngFromActivityMap(Map<String, dynamic> m) {
  final latN = m['lat'] ?? m['latitude'];
  final lngN = m['lng'] ?? m['longitude'];
  if (latN is num && lngN is num) {
    final lat = latN.toDouble();
    final lng = lngN.toDouble();
    if (_isPlausibleLatLng(lat, lng)) return (lat: lat, lng: lng);
  }
  final raw = m['location']?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(',');
  if (parts.length < 2) return null;
  final lat = double.tryParse(parts[0].trim());
  final lng = double.tryParse(parts[1].trim());
  if (lat == null || lng == null) return null;
  if (!_isPlausibleLatLng(lat, lng)) return null;
  return (lat: lat, lng: lng);
}

bool _isPlausibleLatLng(double lat, double lng) =>
    lat.abs() > 1e-5 &&
    lng.abs() > 1e-5 &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180 &&
    !(lat.abs() < 0.02 && lng.abs() < 0.02);

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earthKm = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.asin(math.min(1.0, math.sqrt(a)));
  return earthKm * c;
}

double _rad(double deg) => deg * math.pi / 180.0;
