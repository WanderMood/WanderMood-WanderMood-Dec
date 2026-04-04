import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import 'package:wandermood/core/providers/communication_style_provider.dart';
import 'package:wandermood/core/services/notification_service.dart';
import 'notification_category.dart';
import 'notification_copy_provider.dart';
import 'notification_ids.dart';
import 'user_preferences_storage.dart';

/// Schedules all recurring / time-based notifications.
///
/// Call [rescheduleAll] on every app launch (after the user is authenticated)
/// to ensure all notifications are up-to-date.  Each method cancels the
/// existing notification before rescheduling so there are no duplicates.
class NotificationScheduler {
  final NotificationService _svc;
  final NotificationCopyProvider _copy;
  final SharedPreferences _prefs;
  final AppLocalizations _l10n;
  final CommunicationStyle _style;

  NotificationScheduler({
    required NotificationService svc,
    required NotificationCopyProvider copy,
    required SharedPreferences prefs,
    required AppLocalizations l10n,
    required CommunicationStyle style,
  })  : _svc = svc,
        _copy = copy,
        _prefs = prefs,
        _l10n = l10n,
        _style = style;

  // ────────────────────────────────────────────────────────────────
  // Top-level entry point
  // ────────────────────────────────────────────────────────────────

  Future<void> rescheduleAll() async {
    final userPrefs = userPreferencesFromSharedPrefs(_prefs);

    await Future.wait([
      scheduleDailyMoodCheckIn(),
      scheduleWeeklyMoodRecap(),
      scheduleReEngagement(),
      ...(userPrefs.tripReminders
          ? [
              scheduleCompanionCheckIns(),
              scheduleWeekendPlanningNudge(),
              scheduleGenerateMyDay(),
            ]
          : [_cancelTripPlanningNotifications()]),
    ]);
  }

  /// Clears day-planning / trip-style recurring slots when the user disables
  /// trip reminders in Settings → Notifications.
  Future<void> _cancelTripPlanningNotifications() async {
    await Future.wait([
      _svc.cancel(NotificationIds.companionMorning),
      _svc.cancel(NotificationIds.companionAfternoon),
      _svc.cancel(NotificationIds.companionEvening),
      _svc.cancel(NotificationIds.weekendPlanningNudge),
      _svc.cancel(NotificationIds.generateMyDay),
    ]);
  }

  // ────────────────────────────────────────────────────────────────
  // Individual schedulers
  // ────────────────────────────────────────────────────────────────

  /// Daily mood check-in at 09:00.
  Future<void> scheduleDailyMoodCheckIn() async {
    await _svc.cancel(NotificationIds.dailyMoodCheckIn);
    final copy = await _copy.nextCopy(
      NotificationCategory.dailyMoodCheckIn,
      _style,
      _prefs,
      _l10n,
    );
    await _svc.scheduleDailyAt(
      NotificationIds.dailyMoodCheckIn,
      copy,
      hour: 9,
      minute: 0,
    );
  }

  /// Three companion check-ins: morning 08:00, afternoon 13:00, evening 20:00.
  Future<void> scheduleCompanionCheckIns() async {
    await Future.wait([
      _scheduleCompanion(
        NotificationIds.companionMorning,
        NotificationCategory.companionCheckInMorning,
        hour: 8,
        minute: 0,
      ),
      _scheduleCompanion(
        NotificationIds.companionAfternoon,
        NotificationCategory.companionCheckInAfternoon,
        hour: 13,
        minute: 0,
      ),
      _scheduleCompanion(
        NotificationIds.companionEvening,
        NotificationCategory.companionCheckInEvening,
        hour: 20,
        minute: 0,
      ),
    ]);
  }

  Future<void> _scheduleCompanion(
    int id,
    NotificationCategory category, {
    required int hour,
    required int minute,
  }) async {
    await _svc.cancel(id);
    final copy = await _copy.nextCopy(category, _style, _prefs, _l10n);
    await _svc.scheduleDailyAt(id, copy, hour: hour, minute: minute);
  }

  /// Weekly mood recap every Sunday at 18:00.
  Future<void> scheduleWeeklyMoodRecap() async {
    await _svc.cancel(NotificationIds.weeklyMoodRecap);
    final copy = await _copy.nextCopy(
      NotificationCategory.weeklyMoodRecap,
      _style,
      _prefs,
      _l10n,
    );
    await _svc.scheduleWeeklyAt(
      NotificationIds.weeklyMoodRecap,
      copy,
      weekday: DateTime.sunday,
      hour: 18,
      minute: 0,
    );
  }

  /// Weekend planning nudge every Friday at 17:00.
  Future<void> scheduleWeekendPlanningNudge() async {
    await _svc.cancel(NotificationIds.weekendPlanningNudge);
    final copy = await _copy.nextCopy(
      NotificationCategory.weekendPlanningNudge,
      _style,
      _prefs,
      _l10n,
    );
    await _svc.scheduleWeeklyAt(
      NotificationIds.weekendPlanningNudge,
      copy,
      weekday: DateTime.friday,
      hour: 17,
      minute: 0,
    );
  }

  /// Generate My Day nudge every morning at 07:30.
  Future<void> scheduleGenerateMyDay() async {
    await _svc.cancel(NotificationIds.generateMyDay);
    final copy = await _copy.nextCopy(
      NotificationCategory.generateMyDay,
      _style,
      _prefs,
      _l10n,
    );
    await _svc.scheduleDailyAt(
      NotificationIds.generateMyDay,
      copy,
      hour: 7,
      minute: 30,
    );
  }

  /// Re-engagement: fires 72 hours after the current app launch.
  ///
  /// Cancelled and rescheduled on every launch so the clock always resets.
  Future<void> scheduleReEngagement() async {
    await _svc.cancel(NotificationIds.reEngagement);
    final copy = await _copy.nextCopy(
      NotificationCategory.reEngagement,
      _style,
      _prefs,
      _l10n,
    );
    final fireAt = DateTime.now().add(const Duration(hours: 72));
    await _svc.scheduleAt(NotificationIds.reEngagement, copy, fireAt);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Riverpod provider — built after notificationL10nProvider is resolved.
// Declared in notification_provider.dart to avoid circular deps.
// ──────────────────────────────────────────────────────────────────────────────
