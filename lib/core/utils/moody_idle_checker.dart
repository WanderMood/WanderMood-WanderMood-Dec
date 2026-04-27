import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/l10n/app_localizations.dart';

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

/// Morning / evening gates only — at most one full-screen idle per slot per calendar day.
enum MoodyIdleGateSlot {
  morning,
  evening,
}

/// Result of [MoodyIdleChecker.evaluateIdleGate]; call [MoodyIdleChecker.completeIdleGate]
/// after the user finishes the idle route so the day stamp and line rotation update.
class IdleGateDecision {
  const IdleGateDecision({
    required this.slot,
    required this.visualState,
    required this.rotationIndex,
    required this.openingLine,
  });

  final MoodyIdleGateSlot slot;
  final MoodyIdleState visualState;
  final int rotationIndex;
  final String openingLine;
}

/// Decides when to show the Moody idle screen and which idle bucket applies.
class MoodyIdleChecker {
  MoodyIdleChecker._();

  static const int _idleGateLineCount = 5;

  static const String _prefsKeyLastAppOpen = 'last_app_open';
  static const String _prefsKeyGateMorningDay = 'moody_idle_gate_morning_day';
  static const String _prefsKeyGateEveningDay = 'moody_idle_gate_evening_day';
  static const String _prefsKeyGateMorningRotate = 'moody_idle_gate_morning_rot';
  static const String _prefsKeyGateEveningRotate = 'moody_idle_gate_evening_rot';

  /// Local calendar day (`yyyy-MM-dd`) of the first [recordAppOpen] — used so day-1 idle
  /// shows the full “tap Moody” teaching UI; from day 2 onward a single short line.
  static const String _prefsKeyFirstInstallLocalDay =
      'moody_first_install_local_day';

  static String _localDayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// Which gate slot applies **right now**, or `null` outside morning / evening windows.
  ///
  /// Morning: 06:00–11:59. Evening: 17:00–21:59 (local time, [MoodyClock]).
  static MoodyIdleGateSlot? currentGateSlot() {
    final h = MoodyClock.now().hour;
    if (h >= 6 && h < 12) return MoodyIdleGateSlot.morning;
    if (h >= 17 && h < 22) return MoodyIdleGateSlot.evening;
    return null;
  }

  static MoodyIdleState _visualForSlot(MoodyIdleGateSlot slot) {
    switch (slot) {
      case MoodyIdleGateSlot.morning:
        return MoodyIdleState.morning;
      case MoodyIdleGateSlot.evening:
        return MoodyIdleState.evening;
    }
  }

  static String _openingLine(AppLocalizations l10n, MoodyIdleGateSlot slot, int index) {
    final i = index % _idleGateLineCount;
    switch (slot) {
      case MoodyIdleGateSlot.morning:
        switch (i) {
          case 0:
            return l10n.moodyIdleGateMorning0;
          case 1:
            return l10n.moodyIdleGateMorning1;
          case 2:
            return l10n.moodyIdleGateMorning2;
          case 3:
            return l10n.moodyIdleGateMorning3;
          default:
            return l10n.moodyIdleGateMorning4;
        }
      case MoodyIdleGateSlot.evening:
        switch (i) {
          case 0:
            return l10n.moodyIdleGateEvening0;
          case 1:
            return l10n.moodyIdleGateEvening1;
          case 2:
            return l10n.moodyIdleGateEvening2;
          case 3:
            return l10n.moodyIdleGateEvening3;
          default:
            return l10n.moodyIdleGateEvening4;
        }
    }
  }

  /// When non-null, show the idle gate: first open in this slot today, inside a time window.
  static Future<IdleGateDecision?> evaluateIdleGate(AppLocalizations l10n) async {
    final slot = currentGateSlot();
    if (slot == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final today = _localDayKey(MoodyClock.now());
    final shownKey = slot == MoodyIdleGateSlot.morning
        ? _prefsKeyGateMorningDay
        : _prefsKeyGateEveningDay;
    if (prefs.getString(shownKey) == today) return null;

    final rotKey = slot == MoodyIdleGateSlot.morning
        ? _prefsKeyGateMorningRotate
        : _prefsKeyGateEveningRotate;
    final idx = prefs.getInt(rotKey) ?? 0;
    final line = _openingLine(l10n, slot, idx);
    return IdleGateDecision(
      slot: slot,
      visualState: _visualForSlot(slot),
      rotationIndex: idx,
      openingLine: line,
    );
  }

  /// Call after the user completes the idle gate (tap + wake line). Updates “shown today”
  /// and advances the rotating line index for that slot.
  static Future<void> completeIdleGate(IdleGateDecision decision) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _localDayKey(MoodyClock.now());
    if (decision.slot == MoodyIdleGateSlot.morning) {
      await prefs.setString(_prefsKeyGateMorningDay, today);
      await prefs.setInt(_prefsKeyGateMorningRotate, decision.rotationIndex + 1);
    } else {
      await prefs.setString(_prefsKeyGateEveningDay, today);
      await prefs.setInt(_prefsKeyGateEveningRotate, decision.rotationIndex + 1);
    }
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
