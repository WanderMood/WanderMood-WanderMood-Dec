import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/notifications/notification_copy.dart';
import 'package:wandermood/core/notifications/notification_ids.dart';
import 'package:wandermood/core/services/notification_service.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Shows a single local notification on the user's birthday (once per local day).
class BirthdayCongratsTrigger {
  BirthdayCongratsTrigger._();

  static const _prefsKey = 'birthday_congrats_last_yyyy_mm_dd';

  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    try {
      final profile = await ref.read(profileProvider.future);
      if (!context.mounted) return;
      final dob = profile?.dateOfBirth;
      if (dob == null) return;

      final now = DateTime.now();
      if (dob.month != now.month || dob.day != now.day) return;

      final dayKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_prefsKey) == dayKey) return;

      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;

      await prefs.setString(_prefsKey, dayKey);

      await NotificationService.instance.show(
        NotificationIds.birthdayCongrats,
        NotificationCopy(
          title: l10n.notifBirthdayCongratsTitle,
          body: l10n.notifBirthdayCongratsBody,
          payload: 'birthday',
        ),
      );
    } catch (_) {}
  }
}
