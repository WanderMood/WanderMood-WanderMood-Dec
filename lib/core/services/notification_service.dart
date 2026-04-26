import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/notifications/notification_ids.dart';
import 'package:wandermood/core/services/push_notify_edge.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../notifications/notification_copy.dart';

/// Low-level wrapper around flutter_local_notifications.
///
/// Responsibilities:
///   • Initialize the plugin once on app start.
///   • Request OS permission (Android 13+, iOS).
///   • Show immediate, one-shot, and recurring notifications.
///   • Cancel individual or all notifications.
///
/// Do NOT add business logic here — keep it in [NotificationScheduler] /
/// [NotificationTriggers].
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Set before [initialize]. Called when the user taps a notification (foreground / background).
  void Function(String? payload)? onNotificationPayload;

  String? _pendingLaunchPayload;

  /// Payload from opening the app via a notification (terminated state). Consume once after init.
  String? consumePendingLaunchPayload() {
    final p = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    return p;
  }

  // ────────────────────────────────────────────────────────────────
  // Initialization
  // ────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // Timezone database is required for TZDateTime scheduling.
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We request explicitly below.
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _mirrorLocalNotificationTapToInApp(response.id, response.payload);
        final p = response.payload;
        if (p != null && p.isNotEmpty) {
          onNotificationPayload?.call(p);
        }
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _mirrorLocalNotificationTapToInApp(
        launchDetails!.notificationResponse?.id,
        launchDetails.notificationResponse?.payload,
      );
      final p = launchDetails!.notificationResponse?.payload;
      if (p != null && p.isNotEmpty) {
        _pendingLaunchPayload = p;
      }
    }

    _initialized = true;

    if (kDebugMode) debugPrint('✅ NotificationService initialized');
  }

  // ────────────────────────────────────────────────────────────────
  // Permission
  // ────────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  // ────────────────────────────────────────────────────────────────
  // Show helpers
  // ────────────────────────────────────────────────────────────────

  /// Show an immediate notification.
  Future<void> show(int id, NotificationCopy copy) async {
    await _plugin.show(
      id,
      copy.title,
      copy.body,
      _details(),
      payload: copy.payload,
    );
  }

  /// Schedule a one-shot notification at [scheduledDate] (local time).
  Future<void> scheduleAt(
    int id,
    NotificationCopy copy,
    DateTime scheduledDate,
  ) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    await _plugin.zonedSchedule(
      id,
      copy.title,
      copy.body,
      tzDate,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: copy.payload,
    );
  }

  /// Schedule a notification that repeats daily at [hour]:[minute] (local time).
  Future<void> scheduleDailyAt(
    int id,
    NotificationCopy copy, {
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      copy.title,
      copy.body,
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: copy.payload,
    );
  }

  /// Schedule a notification that fires once a week on [weekday] at [hour]:[minute].
  /// [weekday] follows Dart's DateTime convention: 1 = Monday … 7 = Sunday.
  Future<void> scheduleWeeklyAt(
    int id,
    NotificationCopy copy, {
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // Advance to the correct weekday.
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      copy.title,
      copy.body,
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: copy.payload,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Cancel
  // ────────────────────────────────────────────────────────────────

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  // ────────────────────────────────────────────────────────────────
  // Internal
  // ────────────────────────────────────────────────────────────────

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      'wandermood_main',
      'WanderMood',
      channelDescription: 'WanderMood notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(android: android, iOS: ios);
  }

  /// Mirror locally scheduled reminders to in-app notifications when the user
  /// opens/taps them, so OS tray and My Day bell stay aligned.
  void _mirrorLocalNotificationTapToInApp(int? id, String? payload) {
    final mapped = _mapLocalNotificationToRealtime(id, payload);
    if (mapped == null) return;
    Future<void>(() async {
      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user == null) return;
        final nl = (await wandermoodNotificationLangCode())
            .toLowerCase()
            .startsWith('nl');
        final title = nl ? 'Moody' : 'Moody';
        final message = nl ? mapped.messageNl : mapped.messageEn;
        await client.rpc(
          'send_realtime_notification',
          params: {
            'target_user_id': user.id,
            'event_type': 'systemUpdate',
            'event_title': title,
            'event_message': message,
            'event_data': {
              'event': mapped.event,
              'notification_id': id,
              'payload': payload ?? '',
              'source': 'local_notification_tap',
            },
            'source_user_id': user.id,
            'related_post_id': null,
            'priority_level': 2,
          },
        );
      } catch (_) {
        // Non-blocking: failing to mirror should never break app open.
      }
    });
  }

  _MappedRealtimeNotification? _mapLocalNotificationToRealtime(
    int? id,
    String? payload,
  ) {
    switch (id) {
      case NotificationIds.dailyMoodCheckIn:
        return const _MappedRealtimeNotification(
          event: 'daily_mood_check_in',
          messageEn: 'How are you feeling today? Tap to check in with Moody.',
          messageNl: 'Hoe voel je je vandaag? Tik om bij Moody in te checken.',
        );
      case NotificationIds.companionMorning:
      case NotificationIds.companionAfternoon:
      case NotificationIds.companionEvening:
        return const _MappedRealtimeNotification(
          event: 'companion_check_in',
          messageEn: 'How was your day? Want to check in and talk with Moody?',
          messageNl: 'Hoe was je dag? Wil je inchecken en even met Moody praten?',
        );
      case NotificationIds.moodFollowUp:
        return const _MappedRealtimeNotification(
          event: 'mood_follow_up',
          messageEn: 'Quick mood follow-up from Moody.',
          messageNl: 'Een snelle mood-follow-up van Moody.',
        );
      case NotificationIds.generateMyDay:
        return const _MappedRealtimeNotification(
          event: 'generate_my_day',
          messageEn: 'Ready to plan your day with Moody?',
          messageNl: 'Klaar om je dag met Moody te plannen?',
        );
      default:
        if (payload == null || payload.isEmpty) return null;
        // Legacy payload for mood check-in route.
        if (payload == 'wm_nav_main_2' || payload == 'wm_nav_main_2_checkin') {
          return const _MappedRealtimeNotification(
            event: 'moody_chat_reminder',
            messageEn: 'Moody reminded you to check in.',
            messageNl: 'Moody heeft je eraan herinnerd om in te checken.',
          );
        }
        return null;
    }
  }
}

class _MappedRealtimeNotification {
  final String event;
  final String messageEn;
  final String messageNl;

  const _MappedRealtimeNotification({
    required this.event,
    required this.messageEn,
    required this.messageNl,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ──────────────────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});
