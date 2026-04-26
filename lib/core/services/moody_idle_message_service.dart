import 'package:wandermood/core/services/moody_hub_message_service.dart';
import 'package:wandermood/core/utils/moody_idle_checker.dart';

/// Idle welcome line for [MoodyIdleScreen].
///
/// Uses the same `moody` action as the hub: **`generate_hub_message`** (v63+).
/// The app has four [MoodyIdleState] buckets; we send hub `time_of_day` as
/// **`morning` / `afternoon` / `evening` / `night`** (the [MoodyIdleState.day]
/// bucket maps to `afternoon`, which is what the edge prompt already expects).
class MoodyIdleMessageService {
  MoodyIdleMessageService._();

  static String _timeOfDayFor(MoodyIdleState state) {
    switch (state) {
      case MoodyIdleState.morning:
        return 'morning';
      case MoodyIdleState.day:
        return 'afternoon';
      case MoodyIdleState.evening:
        return 'evening';
      case MoodyIdleState.night:
        return 'night';
    }
  }

  static List<String> _moodsFor(MoodyIdleState state, String? topInterest) {
    final t = topInterest?.trim();
    if (t != null && t.isNotEmpty) return [t];
    switch (state) {
      case MoodyIdleState.morning:
        return ['morning'];
      case MoodyIdleState.day:
        return ['afternoon'];
      case MoodyIdleState.evening:
        return ['evening'];
      case MoodyIdleState.night:
        return ['restful'];
    }
  }

  /// Returns `null` on timeout / error / missing `message`.
  static Future<String?> fetchIdleMessage({
    required MoodyIdleState idleState,
    required String languageCode,
    Map<String, dynamic>? userPreferences,
    String? topInterest,
  }) {
    return MoodyHubMessageService.fetchHubMessage(
      currentMoods: _moodsFor(idleState, topInterest),
      timeOfDay: _timeOfDayFor(idleState),
      activitiesCount: 0,
      languageCode: languageCode.trim().isEmpty ? 'en' : languageCode.trim(),
      userPreferences: userPreferences,
    ).then((r) => r?.message);
  }
}
