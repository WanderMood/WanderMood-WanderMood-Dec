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

  /// Local calendar day (`yyyy-MM-dd`) of the first [recordAppOpen] — used so day-1 idle
  /// shows the full “tap Moody” teaching UI; from day 2 onward a single short line.
  static const String _prefsKeyFirstInstallLocalDay =
      'moody_first_install_local_day';

  static String _localDayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

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

  /// If [recordAppOpen] has not run yet this install, stamp the first local day **before**
  /// showing the idle gate so [shouldShowVerboseIdleTapHint] can resolve (e.g. app update
  /// where [recordAppOpen] still runs only after the idle route pops).
  static Future<void> ensureFirstInstallLocalDayIfMissing() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_prefsKeyFirstInstallLocalDay) != null) return;
    await prefs.setString(
        _prefsKeyFirstInstallLocalDay, _localDayKey(MoodyClock.now()));
  }

  /// Call when the app becomes active / resumes so the next open can measure idle time.
  static Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final now = MoodyClock.now();
    if (prefs.getString(_prefsKeyFirstInstallLocalDay) == null) {
      await prefs.setString(_prefsKeyFirstInstallLocalDay, _localDayKey(now));
    }
    await prefs.setString(_prefsKeyLastAppOpen, now.toIso8601String());
  }

  /// Full tap-teaching card on the **local calendar day** that matches the first
  /// [recordAppOpen] stamp; a single short line on later days. If the stamp is missing
  /// (very old installs), [recordAppOpen] will set it on the next session.
  static Future<bool> shouldShowVerboseIdleTapHint() async {
    final prefs = await SharedPreferences.getInstance();
    final first = prefs.getString(_prefsKeyFirstInstallLocalDay);
    if (first == null) return false;
    return first == _localDayKey(MoodyClock.now());
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
