import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    await _plugin.initialize(settings);
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
}

// ──────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ──────────────────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});
