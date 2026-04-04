import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import 'package:wandermood/core/notifications/notification_category.dart';
import 'package:wandermood/core/notifications/notification_copy_provider.dart';
import 'package:wandermood/core/notifications/notification_scheduler.dart';
import 'package:wandermood/core/notifications/notification_triggers.dart';
import 'package:wandermood/core/providers/communication_style_provider.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/services/notification_service.dart';
import 'package:wandermood/features/gamification/providers/gamification_provider.dart';
import 'package:wandermood/features/settings/presentation/providers/user_preferences_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Resolve AppLocalizations without BuildContext
// ──────────────────────────────────────────────────────────────────────────────

/// Derives [AppLocalizations] from the current [localeProvider] value.
///
/// Falls back to English when the locale is null (system default) or when
/// [lookupAppLocalizations] is unavailable for the system locale.
final notificationL10nProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  final effectiveLocale = locale ?? const Locale('en');

  try {
    return lookupAppLocalizations(effectiveLocale);
  } catch (_) {
    // Fallback — should only happen if a new locale is added without gen-l10n.
    return lookupAppLocalizations(const Locale('en'));
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// NotificationScheduler provider
// ──────────────────────────────────────────────────────────────────────────────

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(
    svc: ref.watch(notificationServiceProvider),
    copy: ref.watch(notificationCopyProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    l10n: ref.watch(notificationL10nProvider),
    style: ref.watch(communicationStyleProvider),
  );
});

// ──────────────────────────────────────────────────────────────────────────────
// NotificationTriggers provider
// ──────────────────────────────────────────────────────────────────────────────

final notificationTriggersProvider = Provider<NotificationTriggers>((ref) {
  return NotificationTriggers(
    svc: ref.watch(notificationServiceProvider),
    copy: ref.watch(notificationCopyProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    l10n: ref.watch(notificationL10nProvider),
    style: ref.watch(communicationStyleProvider),
  );
});

// ──────────────────────────────────────────────────────────────────────────────
// Gamification bridge
//
// Listens to [gamificationProvider] and fires push notifications when:
//   • A new achievement is unlocked  (lastUnlockedAchievementId changes)
//   • The streak hits a milestone     (streak.currentStreak ∈ [7,14,30,60,90,180,365])
//
// We do NOT modify gamification_provider.dart — all the wiring lives here.
// ──────────────────────────────────────────────────────────────────────────────

const _streakMilestones = {7, 14, 30, 60, 90, 180, 365};

/// Activate this provider in main.dart / appInitializerProvider to start
/// listening.  It is intentionally a [Provider<void>] so it stays alive for
/// the lifetime of the ProviderScope.
final notificationBridgeProvider = Provider<void>((ref) {
  final triggers = ref.watch(notificationTriggersProvider);

  // ── Streak milestones ──────────────────────────────────────────────────────
  // We track the last seen streak so we only fire once per milestone.
  var _lastNotifiedStreak = -1;

  ref.listen<GamificationState>(gamificationProvider, (previous, next) {
    final streak = next.streak.currentStreak;

    if (_streakMilestones.contains(streak) && streak != _lastNotifiedStreak) {
      _lastNotifiedStreak = streak;
      triggers.onStreakMilestone(streak);
    }

    // ── Achievement unlocked ─────────────────────────────────────────────────
    final prevId = previous?.lastUnlockedAchievementId;
    final nextId = next.lastUnlockedAchievementId;

    if (nextId != null && nextId != prevId) {
      // Look up the achievement title from the list.
      final achievement = next.achievements
          .where((a) => a.id == nextId)
          .firstOrNull;

      final title = achievement?.title ?? nextId;
      final index = next.achievements.indexWhere((a) => a.id == nextId);

      triggers.onAchievementUnlocked(title, index: index.clamp(0, 49));
    }
  });
});
