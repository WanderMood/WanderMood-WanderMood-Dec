import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import 'package:wandermood/core/providers/communication_style_provider.dart';
import 'notification_category.dart';
import 'notification_copy.dart';

/// Central provider for all push notification copy.
///
/// All strings live in the ARB localization files — no hardcoded copy here.
/// This class simply maps [NotificationCategory] + [CommunicationStyle] to the
/// correct ARB keys, handles variant rotation, and returns a [NotificationCopy].
///
/// Placeholders in some categories:
///   - [NotificationCategory.streakMilestone]      → {days}
///   - [NotificationCategory.achievementUnlocked]  → {achievementTitle}
///   - [NotificationCategory.moodFollowUp]         → {moodType}
///
/// Pass these via the [params] map in [nextCopy].
class NotificationCopyProvider {
  static const _rotationKeyPrefix = 'notif_rotation_';

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// All variants for [category] + [style], built from localized strings.
  ///
  /// For parameterized categories, [params] must contain the required values.
  List<NotificationCopy> variantsFor(
    NotificationCategory category,
    CommunicationStyle style,
    AppLocalizations l10n, {
    Map<String, String> params = const {},
  }) {
    switch (category) {
      case NotificationCategory.reEngagement:
        return _reEngagement(style, l10n);
      case NotificationCategory.dailyMoodCheckIn:
        return _dailyMoodCheckIn(style, l10n);
      case NotificationCategory.generateMyDay:
        return _generateMyDay(style, l10n);
      case NotificationCategory.weatherNudge:
        return _weatherNudge(style, l10n);
      case NotificationCategory.locationDiscovery:
        return _locationDiscovery(style, l10n);
      case NotificationCategory.savedActivityReminder:
        return _savedActivityReminder(style, l10n);
      case NotificationCategory.festivalEvent:
        return _festivalEvent(style, l10n);
      case NotificationCategory.companionCheckInMorning:
        return _companionMorning(style, l10n);
      case NotificationCategory.companionCheckInAfternoon:
        return _companionAfternoon(style, l10n);
      case NotificationCategory.companionCheckInEvening:
        return _companionEvening(style, l10n);
      case NotificationCategory.streakMilestone:
        final days = params['days'] ?? '';
        return _streakMilestone(style, l10n, days);
      case NotificationCategory.achievementUnlocked:
        final title = params['achievementTitle'] ?? '';
        return _achievementUnlocked(style, l10n, title);
      case NotificationCategory.weeklyMoodRecap:
        return _weeklyMoodRecap(style, l10n);
      case NotificationCategory.postTripReflection:
        return _postTripReflection(style, l10n);
      case NotificationCategory.moodFollowUp:
        final moodType = params['moodType'] ?? '';
        return _moodFollowUp(style, l10n, moodType);
      case NotificationCategory.socialEngagement:
        return _socialEngagement(style, l10n);
      case NotificationCategory.friendActivity:
        return _friendActivity(style, l10n);
      case NotificationCategory.weekendPlanningNudge:
        return _weekendPlanningNudge(style, l10n);
      case NotificationCategory.trendingInYourCity:
        return _trendingInYourCity(style, l10n);
    }
  }

  /// Returns the next rotating variant and persists the new index.
  Future<NotificationCopy> nextCopy(
    NotificationCategory category,
    CommunicationStyle style,
    SharedPreferences prefs,
    AppLocalizations l10n, {
    Map<String, String> params = const {},
  }) async {
    final key = '$_rotationKeyPrefix${category.name}';
    final lastIndex = prefs.getInt(key) ?? -1;
    final variants = variantsFor(category, style, l10n, params: params);
    final nextIndex = (lastIndex + 1) % variants.length;
    await prefs.setInt(key, nextIndex);
    return variants[nextIndex];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Per-category builders
  // ─────────────────────────────────────────────────────────────────────────

  List<NotificationCopy> _reEngagement(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifReEngagementEnergeticV0Title, body: l.notifReEngagementEnergeticV0Body),
          NotificationCopy(title: l.notifReEngagementEnergeticV1Title, body: l.notifReEngagementEnergeticV1Body),
          NotificationCopy(title: l.notifReEngagementEnergeticV2Title, body: l.notifReEngagementEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifReEngagementFriendlyV0Title, body: l.notifReEngagementFriendlyV0Body),
          NotificationCopy(title: l.notifReEngagementFriendlyV1Title, body: l.notifReEngagementFriendlyV1Body),
          NotificationCopy(title: l.notifReEngagementFriendlyV2Title, body: l.notifReEngagementFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifReEngagementProfessionalV0Title, body: l.notifReEngagementProfessionalV0Body),
          NotificationCopy(title: l.notifReEngagementProfessionalV1Title, body: l.notifReEngagementProfessionalV1Body),
          NotificationCopy(title: l.notifReEngagementProfessionalV2Title, body: l.notifReEngagementProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifReEngagementDirectV0Title, body: l.notifReEngagementDirectV0Body),
          NotificationCopy(title: l.notifReEngagementDirectV1Title, body: l.notifReEngagementDirectV1Body),
          NotificationCopy(title: l.notifReEngagementDirectV2Title, body: l.notifReEngagementDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _dailyMoodCheckIn(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifDailyMoodCheckInEnergeticV0Title, body: l.notifDailyMoodCheckInEnergeticV0Body),
          NotificationCopy(title: l.notifDailyMoodCheckInEnergeticV1Title, body: l.notifDailyMoodCheckInEnergeticV1Body),
          NotificationCopy(title: l.notifDailyMoodCheckInEnergeticV2Title, body: l.notifDailyMoodCheckInEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifDailyMoodCheckInFriendlyV0Title, body: l.notifDailyMoodCheckInFriendlyV0Body),
          NotificationCopy(title: l.notifDailyMoodCheckInFriendlyV1Title, body: l.notifDailyMoodCheckInFriendlyV1Body),
          NotificationCopy(title: l.notifDailyMoodCheckInFriendlyV2Title, body: l.notifDailyMoodCheckInFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifDailyMoodCheckInProfessionalV0Title, body: l.notifDailyMoodCheckInProfessionalV0Body),
          NotificationCopy(title: l.notifDailyMoodCheckInProfessionalV1Title, body: l.notifDailyMoodCheckInProfessionalV1Body),
          NotificationCopy(title: l.notifDailyMoodCheckInProfessionalV2Title, body: l.notifDailyMoodCheckInProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifDailyMoodCheckInDirectV0Title, body: l.notifDailyMoodCheckInDirectV0Body),
          NotificationCopy(title: l.notifDailyMoodCheckInDirectV1Title, body: l.notifDailyMoodCheckInDirectV1Body),
          NotificationCopy(title: l.notifDailyMoodCheckInDirectV2Title, body: l.notifDailyMoodCheckInDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _generateMyDay(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifGenerateMyDayEnergeticV0Title, body: l.notifGenerateMyDayEnergeticV0Body),
          NotificationCopy(title: l.notifGenerateMyDayEnergeticV1Title, body: l.notifGenerateMyDayEnergeticV1Body),
          NotificationCopy(title: l.notifGenerateMyDayEnergeticV2Title, body: l.notifGenerateMyDayEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifGenerateMyDayFriendlyV0Title, body: l.notifGenerateMyDayFriendlyV0Body),
          NotificationCopy(title: l.notifGenerateMyDayFriendlyV1Title, body: l.notifGenerateMyDayFriendlyV1Body),
          NotificationCopy(title: l.notifGenerateMyDayFriendlyV2Title, body: l.notifGenerateMyDayFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifGenerateMyDayProfessionalV0Title, body: l.notifGenerateMyDayProfessionalV0Body),
          NotificationCopy(title: l.notifGenerateMyDayProfessionalV1Title, body: l.notifGenerateMyDayProfessionalV1Body),
          NotificationCopy(title: l.notifGenerateMyDayProfessionalV2Title, body: l.notifGenerateMyDayProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifGenerateMyDayDirectV0Title, body: l.notifGenerateMyDayDirectV0Body),
          NotificationCopy(title: l.notifGenerateMyDayDirectV1Title, body: l.notifGenerateMyDayDirectV1Body),
          NotificationCopy(title: l.notifGenerateMyDayDirectV2Title, body: l.notifGenerateMyDayDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _weatherNudge(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifWeatherNudgeEnergeticV0Title, body: l.notifWeatherNudgeEnergeticV0Body),
          NotificationCopy(title: l.notifWeatherNudgeEnergeticV1Title, body: l.notifWeatherNudgeEnergeticV1Body),
          NotificationCopy(title: l.notifWeatherNudgeEnergeticV2Title, body: l.notifWeatherNudgeEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifWeatherNudgeFriendlyV0Title, body: l.notifWeatherNudgeFriendlyV0Body),
          NotificationCopy(title: l.notifWeatherNudgeFriendlyV1Title, body: l.notifWeatherNudgeFriendlyV1Body),
          NotificationCopy(title: l.notifWeatherNudgeFriendlyV2Title, body: l.notifWeatherNudgeFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifWeatherNudgeProfessionalV0Title, body: l.notifWeatherNudgeProfessionalV0Body),
          NotificationCopy(title: l.notifWeatherNudgeProfessionalV1Title, body: l.notifWeatherNudgeProfessionalV1Body),
          NotificationCopy(title: l.notifWeatherNudgeProfessionalV2Title, body: l.notifWeatherNudgeProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifWeatherNudgeDirectV0Title, body: l.notifWeatherNudgeDirectV0Body),
          NotificationCopy(title: l.notifWeatherNudgeDirectV1Title, body: l.notifWeatherNudgeDirectV1Body),
          NotificationCopy(title: l.notifWeatherNudgeDirectV2Title, body: l.notifWeatherNudgeDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _locationDiscovery(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifLocationDiscoveryEnergeticV0Title, body: l.notifLocationDiscoveryEnergeticV0Body),
          NotificationCopy(title: l.notifLocationDiscoveryEnergeticV1Title, body: l.notifLocationDiscoveryEnergeticV1Body),
          NotificationCopy(title: l.notifLocationDiscoveryEnergeticV2Title, body: l.notifLocationDiscoveryEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifLocationDiscoveryFriendlyV0Title, body: l.notifLocationDiscoveryFriendlyV0Body),
          NotificationCopy(title: l.notifLocationDiscoveryFriendlyV1Title, body: l.notifLocationDiscoveryFriendlyV1Body),
          NotificationCopy(title: l.notifLocationDiscoveryFriendlyV2Title, body: l.notifLocationDiscoveryFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifLocationDiscoveryProfessionalV0Title, body: l.notifLocationDiscoveryProfessionalV0Body),
          NotificationCopy(title: l.notifLocationDiscoveryProfessionalV1Title, body: l.notifLocationDiscoveryProfessionalV1Body),
          NotificationCopy(title: l.notifLocationDiscoveryProfessionalV2Title, body: l.notifLocationDiscoveryProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifLocationDiscoveryDirectV0Title, body: l.notifLocationDiscoveryDirectV0Body),
          NotificationCopy(title: l.notifLocationDiscoveryDirectV1Title, body: l.notifLocationDiscoveryDirectV1Body),
          NotificationCopy(title: l.notifLocationDiscoveryDirectV2Title, body: l.notifLocationDiscoveryDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _savedActivityReminder(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifSavedActivityReminderEnergeticV0Title, body: l.notifSavedActivityReminderEnergeticV0Body),
          NotificationCopy(title: l.notifSavedActivityReminderEnergeticV1Title, body: l.notifSavedActivityReminderEnergeticV1Body),
          NotificationCopy(title: l.notifSavedActivityReminderEnergeticV2Title, body: l.notifSavedActivityReminderEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifSavedActivityReminderFriendlyV0Title, body: l.notifSavedActivityReminderFriendlyV0Body),
          NotificationCopy(title: l.notifSavedActivityReminderFriendlyV1Title, body: l.notifSavedActivityReminderFriendlyV1Body),
          NotificationCopy(title: l.notifSavedActivityReminderFriendlyV2Title, body: l.notifSavedActivityReminderFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifSavedActivityReminderProfessionalV0Title, body: l.notifSavedActivityReminderProfessionalV0Body),
          NotificationCopy(title: l.notifSavedActivityReminderProfessionalV1Title, body: l.notifSavedActivityReminderProfessionalV1Body),
          NotificationCopy(title: l.notifSavedActivityReminderProfessionalV2Title, body: l.notifSavedActivityReminderProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifSavedActivityReminderDirectV0Title, body: l.notifSavedActivityReminderDirectV0Body),
          NotificationCopy(title: l.notifSavedActivityReminderDirectV1Title, body: l.notifSavedActivityReminderDirectV1Body),
          NotificationCopy(title: l.notifSavedActivityReminderDirectV2Title, body: l.notifSavedActivityReminderDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _festivalEvent(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifFestivalEventEnergeticV0Title, body: l.notifFestivalEventEnergeticV0Body),
          NotificationCopy(title: l.notifFestivalEventEnergeticV1Title, body: l.notifFestivalEventEnergeticV1Body),
          NotificationCopy(title: l.notifFestivalEventEnergeticV2Title, body: l.notifFestivalEventEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifFestivalEventFriendlyV0Title, body: l.notifFestivalEventFriendlyV0Body),
          NotificationCopy(title: l.notifFestivalEventFriendlyV1Title, body: l.notifFestivalEventFriendlyV1Body),
          NotificationCopy(title: l.notifFestivalEventFriendlyV2Title, body: l.notifFestivalEventFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifFestivalEventProfessionalV0Title, body: l.notifFestivalEventProfessionalV0Body),
          NotificationCopy(title: l.notifFestivalEventProfessionalV1Title, body: l.notifFestivalEventProfessionalV1Body),
          NotificationCopy(title: l.notifFestivalEventProfessionalV2Title, body: l.notifFestivalEventProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifFestivalEventDirectV0Title, body: l.notifFestivalEventDirectV0Body),
          NotificationCopy(title: l.notifFestivalEventDirectV1Title, body: l.notifFestivalEventDirectV1Body),
          NotificationCopy(title: l.notifFestivalEventDirectV2Title, body: l.notifFestivalEventDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _companionMorning(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifCompanionMorningEnergeticV0Title, body: l.notifCompanionMorningEnergeticV0Body),
          NotificationCopy(title: l.notifCompanionMorningEnergeticV1Title, body: l.notifCompanionMorningEnergeticV1Body),
          NotificationCopy(title: l.notifCompanionMorningEnergeticV2Title, body: l.notifCompanionMorningEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifCompanionMorningFriendlyV0Title, body: l.notifCompanionMorningFriendlyV0Body),
          NotificationCopy(title: l.notifCompanionMorningFriendlyV1Title, body: l.notifCompanionMorningFriendlyV1Body),
          NotificationCopy(title: l.notifCompanionMorningFriendlyV2Title, body: l.notifCompanionMorningFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifCompanionMorningProfessionalV0Title, body: l.notifCompanionMorningProfessionalV0Body),
          NotificationCopy(title: l.notifCompanionMorningProfessionalV1Title, body: l.notifCompanionMorningProfessionalV1Body),
          NotificationCopy(title: l.notifCompanionMorningProfessionalV2Title, body: l.notifCompanionMorningProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifCompanionMorningDirectV0Title, body: l.notifCompanionMorningDirectV0Body),
          NotificationCopy(title: l.notifCompanionMorningDirectV1Title, body: l.notifCompanionMorningDirectV1Body),
          NotificationCopy(title: l.notifCompanionMorningDirectV2Title, body: l.notifCompanionMorningDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _companionAfternoon(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifCompanionAfternoonEnergeticV0Title, body: l.notifCompanionAfternoonEnergeticV0Body),
          NotificationCopy(title: l.notifCompanionAfternoonEnergeticV1Title, body: l.notifCompanionAfternoonEnergeticV1Body),
          NotificationCopy(title: l.notifCompanionAfternoonEnergeticV2Title, body: l.notifCompanionAfternoonEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifCompanionAfternoonFriendlyV0Title, body: l.notifCompanionAfternoonFriendlyV0Body),
          NotificationCopy(title: l.notifCompanionAfternoonFriendlyV1Title, body: l.notifCompanionAfternoonFriendlyV1Body),
          NotificationCopy(title: l.notifCompanionAfternoonFriendlyV2Title, body: l.notifCompanionAfternoonFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifCompanionAfternoonProfessionalV0Title, body: l.notifCompanionAfternoonProfessionalV0Body),
          NotificationCopy(title: l.notifCompanionAfternoonProfessionalV1Title, body: l.notifCompanionAfternoonProfessionalV1Body),
          NotificationCopy(title: l.notifCompanionAfternoonProfessionalV2Title, body: l.notifCompanionAfternoonProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifCompanionAfternoonDirectV0Title, body: l.notifCompanionAfternoonDirectV0Body),
          NotificationCopy(title: l.notifCompanionAfternoonDirectV1Title, body: l.notifCompanionAfternoonDirectV1Body),
          NotificationCopy(title: l.notifCompanionAfternoonDirectV2Title, body: l.notifCompanionAfternoonDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _companionEvening(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifCompanionEveningEnergeticV0Title, body: l.notifCompanionEveningEnergeticV0Body),
          NotificationCopy(title: l.notifCompanionEveningEnergeticV1Title, body: l.notifCompanionEveningEnergeticV1Body),
          NotificationCopy(title: l.notifCompanionEveningEnergeticV2Title, body: l.notifCompanionEveningEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifCompanionEveningFriendlyV0Title, body: l.notifCompanionEveningFriendlyV0Body),
          NotificationCopy(title: l.notifCompanionEveningFriendlyV1Title, body: l.notifCompanionEveningFriendlyV1Body),
          NotificationCopy(title: l.notifCompanionEveningFriendlyV2Title, body: l.notifCompanionEveningFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifCompanionEveningProfessionalV0Title, body: l.notifCompanionEveningProfessionalV0Body),
          NotificationCopy(title: l.notifCompanionEveningProfessionalV1Title, body: l.notifCompanionEveningProfessionalV1Body),
          NotificationCopy(title: l.notifCompanionEveningProfessionalV2Title, body: l.notifCompanionEveningProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifCompanionEveningDirectV0Title, body: l.notifCompanionEveningDirectV0Body),
          NotificationCopy(title: l.notifCompanionEveningDirectV1Title, body: l.notifCompanionEveningDirectV1Body),
          NotificationCopy(title: l.notifCompanionEveningDirectV2Title, body: l.notifCompanionEveningDirectV2Body),
        ];
    }
  }

  // days is already substituted by AppLocalizations method call
  List<NotificationCopy> _streakMilestone(CommunicationStyle s, AppLocalizations l, String days) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifStreakMilestoneEnergeticV0Title(days), body: l.notifStreakMilestoneEnergeticV0Body),
          NotificationCopy(title: l.notifStreakMilestoneEnergeticV1Title(days), body: l.notifStreakMilestoneEnergeticV1Body),
          NotificationCopy(title: l.notifStreakMilestoneEnergeticV2Title(days), body: l.notifStreakMilestoneEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifStreakMilestoneFriendlyV0Title(days), body: l.notifStreakMilestoneFriendlyV0Body),
          NotificationCopy(title: l.notifStreakMilestoneFriendlyV1Title(days), body: l.notifStreakMilestoneFriendlyV1Body),
          NotificationCopy(title: l.notifStreakMilestoneFriendlyV2Title(days), body: l.notifStreakMilestoneFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifStreakMilestoneProfessionalV0Title(days), body: l.notifStreakMilestoneProfessionalV0Body),
          NotificationCopy(title: l.notifStreakMilestoneProfessionalV1Title, body: l.notifStreakMilestoneProfessionalV1Body(days)),
          NotificationCopy(title: l.notifStreakMilestoneProfessionalV2Title(days), body: l.notifStreakMilestoneProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifStreakMilestoneDirectV0Title(days), body: l.notifStreakMilestoneDirectV0Body),
          NotificationCopy(title: l.notifStreakMilestoneDirectV1Title(days), body: l.notifStreakMilestoneDirectV1Body),
          NotificationCopy(title: l.notifStreakMilestoneDirectV2Title(days), body: l.notifStreakMilestoneDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _achievementUnlocked(CommunicationStyle s, AppLocalizations l, String achievementTitle) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifAchievementUnlockedEnergeticV0Title(achievementTitle), body: l.notifAchievementUnlockedEnergeticV0Body),
          NotificationCopy(title: l.notifAchievementUnlockedEnergeticV1Title(achievementTitle), body: l.notifAchievementUnlockedEnergeticV1Body),
          NotificationCopy(title: l.notifAchievementUnlockedEnergeticV2Title(achievementTitle), body: l.notifAchievementUnlockedEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifAchievementUnlockedFriendlyV0Title, body: l.notifAchievementUnlockedFriendlyV0Body(achievementTitle)),
          NotificationCopy(title: l.notifAchievementUnlockedFriendlyV1Title(achievementTitle), body: l.notifAchievementUnlockedFriendlyV1Body),
          NotificationCopy(title: l.notifAchievementUnlockedFriendlyV2Title(achievementTitle), body: l.notifAchievementUnlockedFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifAchievementUnlockedProfessionalV0Title(achievementTitle), body: l.notifAchievementUnlockedProfessionalV0Body),
          NotificationCopy(title: l.notifAchievementUnlockedProfessionalV1Title(achievementTitle), body: l.notifAchievementUnlockedProfessionalV1Body),
          NotificationCopy(title: l.notifAchievementUnlockedProfessionalV2Title(achievementTitle), body: l.notifAchievementUnlockedProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifAchievementUnlockedDirectV0Title(achievementTitle), body: l.notifAchievementUnlockedDirectV0Body),
          NotificationCopy(title: l.notifAchievementUnlockedDirectV1Title(achievementTitle), body: l.notifAchievementUnlockedDirectV1Body),
          NotificationCopy(title: l.notifAchievementUnlockedDirectV2Title(achievementTitle), body: l.notifAchievementUnlockedDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _weeklyMoodRecap(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifWeeklyMoodRecapEnergeticV0Title, body: l.notifWeeklyMoodRecapEnergeticV0Body),
          NotificationCopy(title: l.notifWeeklyMoodRecapEnergeticV1Title, body: l.notifWeeklyMoodRecapEnergeticV1Body),
          NotificationCopy(title: l.notifWeeklyMoodRecapEnergeticV2Title, body: l.notifWeeklyMoodRecapEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifWeeklyMoodRecapFriendlyV0Title, body: l.notifWeeklyMoodRecapFriendlyV0Body),
          NotificationCopy(title: l.notifWeeklyMoodRecapFriendlyV1Title, body: l.notifWeeklyMoodRecapFriendlyV1Body),
          NotificationCopy(title: l.notifWeeklyMoodRecapFriendlyV2Title, body: l.notifWeeklyMoodRecapFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifWeeklyMoodRecapProfessionalV0Title, body: l.notifWeeklyMoodRecapProfessionalV0Body),
          NotificationCopy(title: l.notifWeeklyMoodRecapProfessionalV1Title, body: l.notifWeeklyMoodRecapProfessionalV1Body),
          NotificationCopy(title: l.notifWeeklyMoodRecapProfessionalV2Title, body: l.notifWeeklyMoodRecapProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifWeeklyMoodRecapDirectV0Title, body: l.notifWeeklyMoodRecapDirectV0Body),
          NotificationCopy(title: l.notifWeeklyMoodRecapDirectV1Title, body: l.notifWeeklyMoodRecapDirectV1Body),
          NotificationCopy(title: l.notifWeeklyMoodRecapDirectV2Title, body: l.notifWeeklyMoodRecapDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _postTripReflection(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifPostTripReflectionEnergeticV0Title, body: l.notifPostTripReflectionEnergeticV0Body),
          NotificationCopy(title: l.notifPostTripReflectionEnergeticV1Title, body: l.notifPostTripReflectionEnergeticV1Body),
          NotificationCopy(title: l.notifPostTripReflectionEnergeticV2Title, body: l.notifPostTripReflectionEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifPostTripReflectionFriendlyV0Title, body: l.notifPostTripReflectionFriendlyV0Body),
          NotificationCopy(title: l.notifPostTripReflectionFriendlyV1Title, body: l.notifPostTripReflectionFriendlyV1Body),
          NotificationCopy(title: l.notifPostTripReflectionFriendlyV2Title, body: l.notifPostTripReflectionFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifPostTripReflectionProfessionalV0Title, body: l.notifPostTripReflectionProfessionalV0Body),
          NotificationCopy(title: l.notifPostTripReflectionProfessionalV1Title, body: l.notifPostTripReflectionProfessionalV1Body),
          NotificationCopy(title: l.notifPostTripReflectionProfessionalV2Title, body: l.notifPostTripReflectionProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifPostTripReflectionDirectV0Title, body: l.notifPostTripReflectionDirectV0Body),
          NotificationCopy(title: l.notifPostTripReflectionDirectV1Title, body: l.notifPostTripReflectionDirectV1Body),
          NotificationCopy(title: l.notifPostTripReflectionDirectV2Title, body: l.notifPostTripReflectionDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _moodFollowUp(CommunicationStyle s, AppLocalizations l, String moodType) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifMoodFollowUpEnergeticV0Title(moodType), body: l.notifMoodFollowUpEnergeticV0Body),
          NotificationCopy(title: l.notifMoodFollowUpEnergeticV1Title(moodType), body: l.notifMoodFollowUpEnergeticV1Body),
          NotificationCopy(title: l.notifMoodFollowUpEnergeticV2Title(moodType), body: l.notifMoodFollowUpEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifMoodFollowUpFriendlyV0Title(moodType), body: l.notifMoodFollowUpFriendlyV0Body),
          NotificationCopy(title: l.notifMoodFollowUpFriendlyV1Title(moodType), body: l.notifMoodFollowUpFriendlyV1Body),
          NotificationCopy(title: l.notifMoodFollowUpFriendlyV2Title(moodType), body: l.notifMoodFollowUpFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifMoodFollowUpProfessionalV0Title, body: l.notifMoodFollowUpProfessionalV0Body(moodType)),
          NotificationCopy(title: l.notifMoodFollowUpProfessionalV1Title, body: l.notifMoodFollowUpProfessionalV1Body(moodType)),
          NotificationCopy(title: l.notifMoodFollowUpProfessionalV2Title, body: l.notifMoodFollowUpProfessionalV2Body(moodType)),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifMoodFollowUpDirectV0Title(moodType), body: l.notifMoodFollowUpDirectV0Body),
          NotificationCopy(title: l.notifMoodFollowUpDirectV1Title, body: l.notifMoodFollowUpDirectV1Body(moodType)),
          NotificationCopy(title: l.notifMoodFollowUpDirectV2Title(moodType), body: l.notifMoodFollowUpDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _socialEngagement(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifSocialEngagementEnergeticV0Title, body: l.notifSocialEngagementEnergeticV0Body),
          NotificationCopy(title: l.notifSocialEngagementEnergeticV1Title, body: l.notifSocialEngagementEnergeticV1Body),
          NotificationCopy(title: l.notifSocialEngagementEnergeticV2Title, body: l.notifSocialEngagementEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifSocialEngagementFriendlyV0Title, body: l.notifSocialEngagementFriendlyV0Body),
          NotificationCopy(title: l.notifSocialEngagementFriendlyV1Title, body: l.notifSocialEngagementFriendlyV1Body),
          NotificationCopy(title: l.notifSocialEngagementFriendlyV2Title, body: l.notifSocialEngagementFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifSocialEngagementProfessionalV0Title, body: l.notifSocialEngagementProfessionalV0Body),
          NotificationCopy(title: l.notifSocialEngagementProfessionalV1Title, body: l.notifSocialEngagementProfessionalV1Body),
          NotificationCopy(title: l.notifSocialEngagementProfessionalV2Title, body: l.notifSocialEngagementProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifSocialEngagementDirectV0Title, body: l.notifSocialEngagementDirectV0Body),
          NotificationCopy(title: l.notifSocialEngagementDirectV1Title, body: l.notifSocialEngagementDirectV1Body),
          NotificationCopy(title: l.notifSocialEngagementDirectV2Title, body: l.notifSocialEngagementDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _friendActivity(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifFriendActivityEnergeticV0Title, body: l.notifFriendActivityEnergeticV0Body),
          NotificationCopy(title: l.notifFriendActivityEnergeticV1Title, body: l.notifFriendActivityEnergeticV1Body),
          NotificationCopy(title: l.notifFriendActivityEnergeticV2Title, body: l.notifFriendActivityEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifFriendActivityFriendlyV0Title, body: l.notifFriendActivityFriendlyV0Body),
          NotificationCopy(title: l.notifFriendActivityFriendlyV1Title, body: l.notifFriendActivityFriendlyV1Body),
          NotificationCopy(title: l.notifFriendActivityFriendlyV2Title, body: l.notifFriendActivityFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifFriendActivityProfessionalV0Title, body: l.notifFriendActivityProfessionalV0Body),
          NotificationCopy(title: l.notifFriendActivityProfessionalV1Title, body: l.notifFriendActivityProfessionalV1Body),
          NotificationCopy(title: l.notifFriendActivityProfessionalV2Title, body: l.notifFriendActivityProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifFriendActivityDirectV0Title, body: l.notifFriendActivityDirectV0Body),
          NotificationCopy(title: l.notifFriendActivityDirectV1Title, body: l.notifFriendActivityDirectV1Body),
          NotificationCopy(title: l.notifFriendActivityDirectV2Title, body: l.notifFriendActivityDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _weekendPlanningNudge(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifWeekendPlanningNudgeEnergeticV0Title, body: l.notifWeekendPlanningNudgeEnergeticV0Body),
          NotificationCopy(title: l.notifWeekendPlanningNudgeEnergeticV1Title, body: l.notifWeekendPlanningNudgeEnergeticV1Body),
          NotificationCopy(title: l.notifWeekendPlanningNudgeEnergeticV2Title, body: l.notifWeekendPlanningNudgeEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifWeekendPlanningNudgeFriendlyV0Title, body: l.notifWeekendPlanningNudgeFriendlyV0Body),
          NotificationCopy(title: l.notifWeekendPlanningNudgeFriendlyV1Title, body: l.notifWeekendPlanningNudgeFriendlyV1Body),
          NotificationCopy(title: l.notifWeekendPlanningNudgeFriendlyV2Title, body: l.notifWeekendPlanningNudgeFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifWeekendPlanningNudgeProfessionalV0Title, body: l.notifWeekendPlanningNudgeProfessionalV0Body),
          NotificationCopy(title: l.notifWeekendPlanningNudgeProfessionalV1Title, body: l.notifWeekendPlanningNudgeProfessionalV1Body),
          NotificationCopy(title: l.notifWeekendPlanningNudgeProfessionalV2Title, body: l.notifWeekendPlanningNudgeProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifWeekendPlanningNudgeDirectV0Title, body: l.notifWeekendPlanningNudgeDirectV0Body),
          NotificationCopy(title: l.notifWeekendPlanningNudgeDirectV1Title, body: l.notifWeekendPlanningNudgeDirectV1Body),
          NotificationCopy(title: l.notifWeekendPlanningNudgeDirectV2Title, body: l.notifWeekendPlanningNudgeDirectV2Body),
        ];
    }
  }

  List<NotificationCopy> _trendingInYourCity(CommunicationStyle s, AppLocalizations l) {
    switch (s) {
      case CommunicationStyle.energetic:
        return [
          NotificationCopy(title: l.notifTrendingInYourCityEnergeticV0Title, body: l.notifTrendingInYourCityEnergeticV0Body),
          NotificationCopy(title: l.notifTrendingInYourCityEnergeticV1Title, body: l.notifTrendingInYourCityEnergeticV1Body),
          NotificationCopy(title: l.notifTrendingInYourCityEnergeticV2Title, body: l.notifTrendingInYourCityEnergeticV2Body),
        ];
      case CommunicationStyle.friendly:
        return [
          NotificationCopy(title: l.notifTrendingInYourCityFriendlyV0Title, body: l.notifTrendingInYourCityFriendlyV0Body),
          NotificationCopy(title: l.notifTrendingInYourCityFriendlyV1Title, body: l.notifTrendingInYourCityFriendlyV1Body),
          NotificationCopy(title: l.notifTrendingInYourCityFriendlyV2Title, body: l.notifTrendingInYourCityFriendlyV2Body),
        ];
      case CommunicationStyle.professional:
        return [
          NotificationCopy(title: l.notifTrendingInYourCityProfessionalV0Title, body: l.notifTrendingInYourCityProfessionalV0Body),
          NotificationCopy(title: l.notifTrendingInYourCityProfessionalV1Title, body: l.notifTrendingInYourCityProfessionalV1Body),
          NotificationCopy(title: l.notifTrendingInYourCityProfessionalV2Title, body: l.notifTrendingInYourCityProfessionalV2Body),
        ];
      case CommunicationStyle.direct:
        return [
          NotificationCopy(title: l.notifTrendingInYourCityDirectV0Title, body: l.notifTrendingInYourCityDirectV0Body),
          NotificationCopy(title: l.notifTrendingInYourCityDirectV1Title, body: l.notifTrendingInYourCityDirectV1Body),
          NotificationCopy(title: l.notifTrendingInYourCityDirectV2Title, body: l.notifTrendingInYourCityDirectV2Body),
        ];
    }
  }
}

final notificationCopyProvider = Provider<NotificationCopyProvider>((ref) {
  return NotificationCopyProvider();
});
