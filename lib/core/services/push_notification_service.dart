import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/firebase_options.dart';
import 'push_notify_edge.dart';

/// Registers FCM token with Supabase [push_tokens] and wires foreground/background handlers.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  // ignore: unused_field
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _started = false;

  Future<void> initIfAvailable() async {
    if (_started) return;
    _started = true;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase init skipped: $e');
      return;
    }

    await FirebaseMessaging.instance.requestPermission();

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _pendingOpen = initial.data;
    }

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await _upsertTokenForUser(uid);
    }

    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      final u = Supabase.instance.client.auth.currentUser?.id;
      if (u != null) await _persistToken(u, t);
    });

    FirebaseMessaging.onMessage.listen((remote) async {
      try {
        await _mirrorPushToInAppIfNeeded(remote);
      } catch (e) {
        if (kDebugMode) debugPrint('onMessage mirror: $e');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((remote) {
      // Deep link handled from app shell via [pendingWmPushNavigationProvider].
      _pendingOpen = remote.data;
      if (kDebugMode) debugPrint('push opened: ${remote.data}');
    });
  }

  Map<String, dynamic>? _pendingOpen;
  Map<String, dynamic>? consumePendingOpenPayload() {
    final p = _pendingOpen;
    _pendingOpen = null;
    return p;
  }

  Future<void> onLogin() async {
    try {
      await initIfAvailable();
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      await _upsertTokenForUser(uid);
    } catch (e) {
      if (kDebugMode) debugPrint('Push onLogin: $e');
    }
  }

  Future<void> deleteTokensForUser(String userId) async {
    try {
      await Supabase.instance.client
          .from('push_tokens')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('push token delete: $e');
    }
  }

  Future<void> onLogout() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) await deleteTokensForUser(uid);
  }

  /// Invalidates the device FCM token so the token cannot receive remote pushes
  /// after account deletion. Safe if Firebase was never initialized.
  Future<void> revokeDevicePushRegistration() async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      if (kDebugMode) debugPrint('FCM deleteToken: $e');
    }
  }

  Future<void> _upsertTokenForUser(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await _persistToken(userId, token);
  }

  Future<void> _persistToken(String userId, String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await Supabase.instance.client.from('push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,token',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('push_tokens upsert: $e');
    }
  }

  /// When app is foreground, mirror FCM payload into [realtime_events] so the centre stays single source in UI.
  Future<void> _mirrorPushToInAppIfNeeded(RemoteMessage remote) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final data = Map<String, dynamic>.from(remote.data);
    final event = data['event']?.toString() ?? '';
    if (event.isEmpty) return;

    final senderId = data['sender_id']?.toString().trim();
    if (senderId != null &&
        senderId.isNotEmpty &&
        senderId == uid) {
      return;
    }

    final sessionId = data['session_id']?.toString().trim() ?? '';
    try {
      final since = DateTime.now()
          .toUtc()
          .subtract(const Duration(seconds: 10));
      final rows = await Supabase.instance.client
          .from('realtime_events')
          .select('id,data')
          .eq('user_id', uid)
          .eq('type', 'systemUpdate')
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: false)
          .limit(30);
      for (final row in rows) {
        final raw = (row as Map)['data'];
        if (raw is! Map) continue;
        final prior = Map<String, dynamic>.from(raw);
        if (prior['event']?.toString() == event &&
            sessionId.isNotEmpty &&
            prior['session_id']?.toString() == sessionId) {
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('onMessage dedupe query: $e');
    }

    final nl = await wandermoodNotificationLangCode() == 'nl';
    final body = remote.notification?.body ??
        remote.notification?.title ??
        (nl ? 'Je hebt een update.' : 'You have an update.');

    await Supabase.instance.client.rpc(
      'send_realtime_notification',
      params: {
        'target_user_id': uid,
        'event_type': 'systemUpdate',
        'event_title': 'WanderMood',
        'event_message': body,
        'event_data': data,
        'source_user_id': null,
        'related_post_id': null,
        'priority_level': 1,
      },
    );
  }
}
