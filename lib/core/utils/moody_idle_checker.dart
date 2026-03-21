import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/utils/moody_clock.dart';

/// Time-of-day buckets for Moody idle / welcome experiences.
enum MoodyIdleState {
  sleeping, // 00:00 - 08:00
  morning, // 08:00 - 12:00
  lunch, // 12:00 - 14:00
  afternoon, // 14:00 - 18:00
  evening, // 18:00 - 21:00
  lateNight, // 21:00 - 24:00
}

/// Decides when to show the Moody idle screen and which idle bucket applies.
class MoodyIdleChecker {
  MoodyIdleChecker._();

  static const int minIdleMinutes = 30;

  static const String _prefsKeyLastAppOpen = 'last_app_open';

  /// True when the user was away at least [minIdleMinutes] since [recordAppOpen] last ran.
  /// False on first launch (no stored timestamp).
  static Future<bool> shouldShowIdleScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenStr = prefs.getString(_prefsKeyLastAppOpen);

    if (lastOpenStr == null) return false;

    final lastOpen = DateTime.parse(lastOpenStr);
    final now = MoodyClock.now();
    final minutesAway = now.difference(lastOpen).inMinutes;

    return minutesAway >= minIdleMinutes;
  }

  /// Call when the app becomes active / resumes so the next open can measure idle time.
  static Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKeyLastAppOpen, MoodyClock.now().toIso8601String());
  }

  /// Idle visual / copy bucket from the current local hour.
  static MoodyIdleState getIdleState() {
    final hour = MoodyClock.now().hour;
    if (hour >= 0 && hour < 8) return MoodyIdleState.sleeping;
    if (hour >= 8 && hour < 12) return MoodyIdleState.morning;
    if (hour >= 12 && hour < 14) return MoodyIdleState.lunch;
    if (hour >= 14 && hour < 18) return MoodyIdleState.afternoon;
    if (hour >= 18 && hour < 21) return MoodyIdleState.evening;
    return MoodyIdleState.lateNight;
  }
}
