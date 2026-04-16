import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';

/// Builds an [Activity] for [scheduled_activities] from a group plan recommendation map
/// (same shape as [AIRecommendation.toJson]).
Activity activityFromGroupPlanRecommendation({
  required Map<String, dynamic> json,
  required String sessionId,
  required int listIndex,
  required DateTime scheduledDay,
  required double fallbackLat,
  required double fallbackLng,
}) {
  final name = (json['name'] as String?)?.trim().isNotEmpty == true
      ? json['name'] as String
      : 'Place';
  final description = (json['description'] as String?)?.trim() ?? '';
  final type = (json['type'] as String?)?.trim().toLowerCase() ?? 'place';
  final tags = <String>[if (type.isNotEmpty) type else 'explore'];
  final rating = (json['rating'] as num?)?.toDouble() ?? 4.2;
  final imageUrl = (json['imageUrl'] as String?)?.trim() ?? '';

  final loc = json['location'];
  double lat = fallbackLat;
  double lng = fallbackLng;
  if (loc is Map) {
    final m = Map<String, dynamic>.from(loc);
    final la = (m['latitude'] as num?)?.toDouble();
    final ln = (m['longitude'] as num?)?.toDouble();
    if (la != null && ln != null && la.abs() > 1e-6 && ln.abs() > 1e-6) {
      lat = la;
      lng = ln;
    }
  }

  final durationMin = _parseDurationMinutes(json['duration'] as String?);
  final startTime = _startTimeForSlot(scheduledDay, listIndex);
  final slotEnum = _timeSlotEnumForHour(startTime.hour);
  final timeSlotStr = slotEnum.name;

  final paymentType = _paymentTypeForType(type);

  final id =
      'groupplan_${sessionId}_${listIndex}_${MoodyClock.now().millisecondsSinceEpoch}';

  return Activity(
    id: id,
    name: name,
    description: description.isNotEmpty ? description : 'From your group plan',
    imageUrl: imageUrl,
    rating: rating,
    startTime: startTime,
    duration: durationMin,
    timeSlot: timeSlotStr,
    timeSlotEnum: slotEnum,
    tags: tags,
    location: LatLng(lat, lng),
    paymentType: paymentType,
    priceLevel: json['cost'] as String?,
  );
}

int _parseDurationMinutes(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 90;
  final m = RegExp(r'(\d+)').firstMatch(raw);
  if (m == null) return 90;
  final n = int.tryParse(m.group(1)!);
  if (n == null || n <= 0) return 90;
  return n.clamp(15, 480);
}

DateTime _startTimeForSlot(DateTime day, int index) {
  const hours = <int>[10, 13, 16, 19];
  final h = hours[index % hours.length];
  return DateTime(day.year, day.month, day.day, h, 0);
}

TimeSlot _timeSlotEnumForHour(int hour) {
  if (hour >= 5 && hour < 12) return TimeSlot.morning;
  if (hour >= 12 && hour < 17) return TimeSlot.afternoon;
  if (hour >= 17 && hour < 22) return TimeSlot.evening;
  return TimeSlot.night;
}

PaymentType _paymentTypeForType(String typeLower) {
  if (typeLower.contains('restaurant') ||
      typeLower.contains('cafe') ||
      typeLower.contains('food')) {
    return PaymentType.reservation;
  }
  return PaymentType.free;
}
