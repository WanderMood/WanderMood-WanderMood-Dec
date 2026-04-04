import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import 'package:wandermood/core/providers/communication_style_provider.dart';
import 'package:wandermood/core/services/notification_service.dart';
import 'localised_mood_name.dart';
import 'notification_category.dart';
import 'notification_copy_provider.dart';
import 'notification_ids.dart';
import 'user_preferences_storage.dart';

/// Fires event-driven notifications in response to in-app actions.
///
/// All methods are safe to call and will silently no-op on error.
class NotificationTriggers {
  final NotificationService _svc;
  final NotificationCopyProvider _copy;
  final SharedPreferences _prefs;
  final AppLocalizations _l10n;
  final CommunicationStyle _style;

  NotificationTriggers({
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

  bool get _tripRemindersEnabled =>
      userPreferencesFromSharedPrefs(_prefs).tripReminders;

  bool get _weatherUpdatesEnabled =>
      userPreferencesFromSharedPrefs(_prefs).weatherUpdates;

  // ────────────────────────────────────────────────────────────────
  // Gamification
  // ────────────────────────────────────────────────────────────────

  /// Call when the user hits a streak milestone.
  /// [days] must be one of the milestone values (7, 14, 30, 60, 90, 180, 365).
  Future<void> onStreakMilestone(int days) async {
    try {
      final copy = await _copy.nextCopy(
        NotificationCategory.streakMilestone,
        _style,
        _prefs,
        _l10n,
        params: {'days': '$days'},
      );
      await _svc.show(NotificationIds.streakMilestoneId(days), copy);
    } catch (_) {}
  }

  /// Call when an achievement is unlocked.
  /// [index] is a stable integer that identifies the achievement (used for ID).
  Future<void> onAchievementUnlocked(String title, {int index = 0}) async {
    try {
      final copy = await _copy.nextCopy(
        NotificationCategory.achievementUnlocked,
        _style,
        _prefs,
        _l10n,
        params: {'achievementTitle': title},
      );
      await _svc.show(NotificationIds.achievementId(index), copy);
    } catch (_) {}
  }

  // ────────────────────────────────────────────────────────────────
  // Mood
  // ────────────────────────────────────────────────────────────────

  /// Schedule a mood follow-up 4 hours after the user logs their mood.
  /// [moodType] is the string label stored in MoodData (e.g. "adventurous").
  Future<void> onMoodLogged(String moodType) async {
    try {
      // Cancel any pending follow-up before scheduling a new one.
      await _svc.cancel(NotificationIds.moodFollowUp);
      final copy = await _copy.nextCopy(
        NotificationCategory.moodFollowUp,
        _style,
        _prefs,
        _l10n,
        params: {'moodType': localisedMoodName(moodType, _l10n)},
      );
      final fireAt = DateTime.now().add(const Duration(hours: 4));
      await _svc.scheduleAt(NotificationIds.moodFollowUp, copy, fireAt);
    } catch (_) {}
  }

  // ────────────────────────────────────────────────────────────────
  // Trip / Plan
  // ────────────────────────────────────────────────────────────────

  /// Call when a trip/plan is marked as completed.
  Future<void> onTripCompleted() async {
    if (!_tripRemindersEnabled) return;
    try {
      final copy = await _copy.nextCopy(
        NotificationCategory.postTripReflection,
        _style,
        _prefs,
        _l10n,
      );
      await _svc.show(NotificationIds.postTripReflection, copy);
    } catch (_) {}
  }

  // ────────────────────────────────────────────────────────────────
  // Contextual / location-aware
  // ────────────────────────────────────────────────────────────────

  /// Call when a significant weather change is detected.
  Future<void> onWeatherChange() async {
    if (!_weatherUpdatesEnabled) return;
    try {
      final copy = await _copy.nextCopy(
        NotificationCategory.weatherNudge,
        _style,
        _prefs,
        _l10n,
      );
      await _svc.show(NotificationIds.weatherNudge, copy);
    } catch (_) {}
  }

  /// Call when a new interesting location is discovered near the user.
  Future<void> onLocationDiscovery() async {
    if (!_tripRemindersEnabled) return;
    try {
      final copy = await _copy.nextCopy(
        NotificationCategory.locationDiscovery,
        _style,
        _prefs,
        _l10n,
      );
      await _svc.show(NotificationIds.locationDiscovery, copy);
    } catch (_) {}
  }

  /// Call to nudge the user about a specific saved activity.
  /// [index] is a stable index into the saved-activities list.
  Future<void> onSavedActivityReminder({int index = 0}) async {
    if (!_tripRemindersEnabled) return;
    try {
      final copy = await _copy.nextCopy(
        NotificationCategory.savedActivityReminder,
        _style,
        _prefs,
        _l10n,
      );
      await _svc.show(NotificationIds.savedActivityId(index), copy);
    } catch (_) {}
  }
}
