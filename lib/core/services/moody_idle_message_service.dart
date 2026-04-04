import 'dart:ui';

import 'package:wandermood/core/services/moody_hub_message_service.dart';
import 'package:wandermood/core/utils/moody_idle_checker.dart';

/// Idle welcome line for [MoodyIdleScreen].
///
/// Uses the same `moody` action as the hub: **`generate_hub_message`** (v63+).
/// The legacy `idle_message` action is not implemented on the edge function.
class MoodyIdleMessageService {
  MoodyIdleMessageService._();

  /// Maps idle bucket → `time_of_day` for the hub prompt.
  static String _timeOfDayFor(MoodyIdleState state) {
    switch (state) {
      case MoodyIdleState.sleeping:
      case MoodyIdleState.lateNight:
        return 'night';
      case MoodyIdleState.morning:
        return 'morning';
      case MoodyIdleState.lunch:
        return 'midday';
      case MoodyIdleState.afternoon:
        return 'afternoon';
      case MoodyIdleState.evening:
        return 'evening';
    }
  }

  /// Mood strings for OpenAI context when no [topInterest] is provided.
  static List<String> _moodsFor(MoodyIdleState state, String? topInterest) {
    final t = topInterest?.trim();
    if (t != null && t.isNotEmpty) return [t];
    switch (state) {
      case MoodyIdleState.sleeping:
        return ['restful'];
      case MoodyIdleState.morning:
        return ['morning'];
      case MoodyIdleState.lunch:
        return ['midday'];
      case MoodyIdleState.afternoon:
        return ['afternoon'];
      case MoodyIdleState.evening:
        return ['evening'];
      case MoodyIdleState.lateNight:
        return ['late night'];
    }
  }

  /// Returns `null` on timeout / error / missing `message`.
  static Future<String?> fetchIdleMessage({
    required MoodyIdleState idleState,
    Map<String, dynamic>? userPreferences,
    String? topInterest,
  }) {
    final languageCode = PlatformDispatcher.instance.locale.languageCode;
    return MoodyHubMessageService.fetchHubMessage(
      currentMoods: _moodsFor(idleState, topInterest),
      timeOfDay: _timeOfDayFor(idleState),
      activitiesCount: 0,
      languageCode: languageCode,
      userPreferences: userPreferences,
    );
  }
}
