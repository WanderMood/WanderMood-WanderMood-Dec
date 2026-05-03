import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/features/onboarding/domain/guest_demo_l10n_helpers.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class _GuestDemoSlotDef {
  const _GuestDemoSlotDef({
    required this.rating,
    required this.imageUrl,
    required this.timeSlotEnum,
    required this.hoursStart,
    required this.durationMinutes,
    required this.lat,
    required this.lng,
    required this.isFree,
    required this.priceLevel,
    required this.tags,
    required this.guestWalkDistanceMeters,
  });

  final double rating;
  final String imageUrl;
  final TimeSlot timeSlotEnum;
  final String hoursStart;
  final int durationMinutes;
  final double lat;
  final double lng;
  final bool isFree;
  /// Numeric level as in planner: '0' free, '1'–'3' paid tiers.
  final String priceLevel;
  final List<String> tags;
  /// Shown on guest day-plan only — plausible walking / city-hop distances (NL-wide demo).
  final int guestWalkDistanceMeters;
}

String _timeSlotKey(TimeSlot s) {
  switch (s) {
    case TimeSlot.morning:
      return 'morning';
    case TimeSlot.afternoon:
      return 'afternoon';
    case TimeSlot.evening:
    case TimeSlot.night:
      return 'evening';
  }
}

DateTime _startTimeToday(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts[0]) ?? 9;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, h, m);
}

/// English mood tokens understood by [DayPlanScreen] pill labels / themes.
String guestDemoMoodKeyForDayPlan(String mood) {
  switch (mood.toLowerCase()) {
    case 'foodie':
      return 'foody';
    default:
      return mood.toLowerCase();
  }
}

/// Guest demo days follow one arc: **morning** = peak / start energy, **afternoon** = recovery
/// (food, view, café, light social), **evening** = wind-down (dinner, bar, sunset) — not “max energy” all day.
const Map<String, List<_GuestDemoSlotDef>> _guestDemoSlotDefs = {
  'relaxed': [
    _GuestDemoSlotDef(
      rating: 4.9,
      imageUrl: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400',
      timeSlotEnum: TimeSlot.morning,
      hoursStart: '09:00',
      durationMinutes: 75,
      lat: 51.9244,
      lng: 4.4777,
      isFree: true,
      priceLevel: '0',
      tags: ['relaxed', 'walk', 'nature'],
      guestWalkDistanceMeters: 620,
    ),
    _GuestDemoSlotDef(
      rating: 4.8,
      // photo-1544787219-7f627064feb0 removed from CDN (404).
      imageUrl: 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=800&q=80',
      timeSlotEnum: TimeSlot.afternoon,
      hoursStart: '12:30',
      durationMinutes: 90,
      lat: 51.9254,
      lng: 4.4787,
      isFree: false,
      priceLevel: '2',
      tags: ['relaxed', 'cafe', 'calm'],
      guestWalkDistanceMeters: 1350,
    ),
    _GuestDemoSlotDef(
      rating: 4.7,
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
      timeSlotEnum: TimeSlot.evening,
      hoursStart: '18:00',
      durationMinutes: 180,
      lat: 51.9234,
      lng: 4.4767,
      isFree: false,
      priceLevel: '3',
      tags: ['relaxed', 'restaurant', 'sunset'],
      guestWalkDistanceMeters: 2180,
    ),
  ],
  'foodie': [
    _GuestDemoSlotDef(
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
      timeSlotEnum: TimeSlot.morning,
      hoursStart: '08:00',
      durationMinutes: 120,
      lat: 51.9240,
      lng: 4.4770,
      isFree: false,
      priceLevel: '1',
      tags: ['foody', 'breakfast', 'cafe'],
      guestWalkDistanceMeters: 480,
    ),
    _GuestDemoSlotDef(
      rating: 4.7,
      // Previous Unsplash id (photo-1556910096) returns 404 from images.unsplash.com.
      imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&q=80',
      timeSlotEnum: TimeSlot.afternoon,
      hoursStart: '12:00',
      durationMinutes: 150,
      lat: 51.9250,
      lng: 4.4780,
      isFree: false,
      priceLevel: '2',
      tags: ['foody', 'market', 'lunch'],
      guestWalkDistanceMeters: 1640,
    ),
    _GuestDemoSlotDef(
      rating: 4.9,
      imageUrl: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400',
      timeSlotEnum: TimeSlot.evening,
      hoursStart: '19:00',
      durationMinutes: 180,
      lat: 51.9230,
      lng: 4.4760,
      isFree: false,
      priceLevel: '3',
      tags: ['foody', 'restaurant', 'dinner'],
      guestWalkDistanceMeters: 2390,
    ),
  ],
  'social': [
    _GuestDemoSlotDef(
      rating: 4.6,
      imageUrl: 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=400',
      timeSlotEnum: TimeSlot.morning,
      hoursStart: '07:30',
      durationMinutes: 60,
      lat: 51.9248,
      lng: 4.4782,
      isFree: true,
      priceLevel: '0',
      tags: ['social', 'active', 'outdoor'],
      guestWalkDistanceMeters: 890,
    ),
    _GuestDemoSlotDef(
      rating: 4.7,
      imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&q=80',
      timeSlotEnum: TimeSlot.afternoon,
      hoursStart: '13:00',
      durationMinutes: 90,
      lat: 51.9252,
      lng: 4.4790,
      isFree: false,
      priceLevel: '2',
      tags: ['social', 'lunch', 'market'],
      guestWalkDistanceMeters: 1520,
    ),
    _GuestDemoSlotDef(
      rating: 4.5,
      imageUrl: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=400',
      timeSlotEnum: TimeSlot.evening,
      hoursStart: '21:00',
      durationMinutes: 150,
      lat: 51.9228,
      lng: 4.4758,
      isFree: false,
      priceLevel: '2',
      tags: ['social', 'nightlife', 'music'],
      guestWalkDistanceMeters: 2750,
    ),
  ],
  'adventurous': [
    _GuestDemoSlotDef(
      rating: 4.9,
      imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=400',
      timeSlotEnum: TimeSlot.morning,
      hoursStart: '06:00',
      durationMinutes: 180,
      lat: 51.9260,
      lng: 4.4800,
      isFree: true,
      priceLevel: '0',
      tags: ['adventurous', 'outdoor', 'hiking'],
      guestWalkDistanceMeters: 1240,
    ),
    _GuestDemoSlotDef(
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
      timeSlotEnum: TimeSlot.afternoon,
      hoursStart: '13:00',
      durationMinutes: 90,
      lat: 51.9242,
      lng: 4.4772,
      isFree: false,
      priceLevel: '2',
      tags: ['adventurous', 'lunch', 'view'],
      guestWalkDistanceMeters: 780,
    ),
    _GuestDemoSlotDef(
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=400',
      timeSlotEnum: TimeSlot.evening,
      hoursStart: '19:00',
      durationMinutes: 150,
      lat: 51.9236,
      lng: 4.4762,
      isFree: false,
      priceLevel: '2',
      tags: ['adventurous', 'sunset', 'bar'],
      guestWalkDistanceMeters: 2050,
    ),
  ],
  'cultural': [
    _GuestDemoSlotDef(
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1561214115-f2f134cc4912?w=400',
      timeSlotEnum: TimeSlot.morning,
      hoursStart: '10:00',
      durationMinutes: 120,
      lat: 51.9246,
      lng: 4.4774,
      isFree: false,
      priceLevel: '1',
      tags: ['cultural', 'museum', 'art'],
      guestWalkDistanceMeters: 710,
    ),
    _GuestDemoSlotDef(
      rating: 4.9,
      imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
      timeSlotEnum: TimeSlot.afternoon,
      hoursStart: '14:00',
      durationMinutes: 75,
      lat: 51.9256,
      lng: 4.4784,
      isFree: false,
      priceLevel: '1',
      tags: ['cultural', 'cafe', 'garden'],
      guestWalkDistanceMeters: 980,
    ),
    _GuestDemoSlotDef(
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=400',
      timeSlotEnum: TimeSlot.evening,
      hoursStart: '20:00',
      durationMinutes: 120,
      lat: 51.9232,
      lng: 4.4764,
      isFree: false,
      priceLevel: '2',
      tags: ['cultural', 'jazz', 'wine'],
      guestWalkDistanceMeters: 2280,
    ),
  ],
  'romantic': [
    _GuestDemoSlotDef(
      rating: 4.7,
      imageUrl: 'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=400',
      timeSlotEnum: TimeSlot.morning,
      hoursStart: '10:00',
      durationMinutes: 90,
      lat: 51.9244,
      lng: 4.4776,
      isFree: false,
      priceLevel: '2',
      tags: ['romantic', 'cafe', 'cozy'],
      guestWalkDistanceMeters: 550,
    ),
    _GuestDemoSlotDef(
      rating: 4.6,
      imageUrl: 'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?w=400',
      timeSlotEnum: TimeSlot.afternoon,
      hoursStart: '15:00',
      durationMinutes: 120,
      lat: 51.9251,
      lng: 4.4781,
      isFree: false,
      priceLevel: '1',
      tags: ['romantic', 'cultural', 'quiet'],
      guestWalkDistanceMeters: 1420,
    ),
    _GuestDemoSlotDef(
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=400',
      timeSlotEnum: TimeSlot.evening,
      hoursStart: '20:00',
      durationMinutes: 150,
      lat: 51.9229,
      lng: 4.4759,
      isFree: false,
      priceLevel: '3',
      tags: ['romantic', 'drinks', 'evening'],
      guestWalkDistanceMeters: 1960,
    ),
  ],
};

/// Formatted distance line for guest preview cards (matches [DistanceService] style).
String guestDemoFormatWalkMeters(int meters) {
  final km = meters / 1000.0;
  return DistanceService.formatDistance(km);
}

/// Same slot order as [buildGuestDemoActivities] — use for distance pills on guest day plan.
List<String> buildGuestDemoDistanceLabels(String mood) {
  final moodKey = mood.toLowerCase();
  final slotKey = moodKey == 'surprise_me' ? 'romantic' : moodKey;
  final defs = _guestDemoSlotDefs[slotKey];
  if (defs == null) return [];
  return defs
      .map((d) => guestDemoFormatWalkMeters(d.guestWalkDistanceMeters))
      .toList();
}

/// Builds three [Activity] rows for the guest day-plan preview.
List<Activity> buildGuestDemoActivities(String mood, AppLocalizations l10n) {
  final moodKey = mood.toLowerCase();
  final slotKey = moodKey == 'surprise_me' ? 'romantic' : moodKey;
  final defs = _guestDemoSlotDefs[slotKey];
  if (defs == null) return [];

  return List.generate(defs.length, (i) {
    final d = defs[i];
    final tags = d.tags.map((tagKey) {
      if (tagKey == 'romantic' && moodKey == 'surprise_me') {
        return l10n.demoMoodSurpriseMe;
      }
      return guestDemoActivityTag(l10n, tagKey);
    }).toList();
    return Activity(
      id: 'guest_demo_${slotKey}_$i',
      name: guestDemoPlaceName(l10n, moodKey, i),
      description: guestDemoPlaceMoodyAbout(l10n, moodKey, i),
      imageUrl: d.imageUrl,
      rating: d.rating,
      startTime: _startTimeToday(d.hoursStart),
      duration: d.durationMinutes,
      timeSlot: _timeSlotKey(d.timeSlotEnum),
      tags: tags,
      isPaid: !d.isFree,
      paymentType: d.isFree ? PaymentType.free : PaymentType.ticket,
      timeSlotEnum: d.timeSlotEnum,
      location: LatLng(d.lat, d.lng),
      priceLevel: d.priceLevel,
      placeId: null,
    );
  });
}
