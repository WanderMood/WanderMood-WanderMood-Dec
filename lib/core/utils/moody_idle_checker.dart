import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/utils/moody_clock.dart';

/// Time-of-day buckets for Moody idle / welcome (four simple windows).
///
/// - [morning]: 06:00–12:00
/// - [day]: 12:00–17:00 (lunch + afternoon merged)
/// - [evening]: 17:00–22:00
/// - [night]: 22:00–06:00 (late night + overnight “sleep” merged)
enum MoodyIdleState {
  morning,
  day,
  evening,
  night,
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
    if (hour >= 6 && hour < 12) return MoodyIdleState.morning;
    if (hour >= 12 && hour < 17) return MoodyIdleState.day;
    if (hour >= 17 && hour < 22) return MoodyIdleState.evening;
    return MoodyIdleState.night;
  }
}
