import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String> wandermoodNotificationLangCode() async {
  try {
    final p = await SharedPreferences.getInstance();
    if (p.getBool('use_system_locale') == true) {
      return 'en';
    }
    final raw = p.getString('app_locale');
    if (raw != null && raw.toLowerCase().startsWith('nl')) return 'nl';
  } catch (_) {}
  return 'en';
}

Future<String?> fetchProfileDisplayUsername(
  SupabaseClient client,
  String userId,
) async {
  try {
    final row = await client
        .from('profiles')
        .select('username, full_name')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    final u = row['username'] as String?;
    if (u != null && u.trim().isNotEmpty) return u.trim();
    final f = row['full_name'] as String?;
    if (f != null && f.trim().isNotEmpty) {
      final parts = f.trim().split(RegExp(r'\s+'));
      return parts.isNotEmpty ? parts.first : f.trim();
    }
  } catch (_) {}
  return null;
}

/// Fire-and-forget remote push via Supabase Edge `push-notify`.
void schedulePushNotify({
  required String recipientId,
  required String event,
  required Map<String, dynamic> data,
  String? lang,
}) {
  unawaited(() async {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession == null) return;
      final langCode = lang ?? await wandermoodNotificationLangCode();
      final res = await client.functions.invoke(
        'push-notify',
        body: {
          'recipient_id': recipientId,
          'event': event,
          'lang': langCode,
          'data': data,
        },
      );
      if (kDebugMode) {
        debugPrint('push-notify response: ${res.data}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('push-notify: $e');
    }
  }());
}

String? pushEventForPlanSideEffect(String event) {
  switch (event) {
    case 'plan_ready':
      return 'plan_ready';
    case 'day_proposed':
      return 'day_proposed';
    case 'day_accepted':
      return 'day_accepted';
    case 'day_counter_proposed':
      return 'day_counter_proposed';
    case 'swap_counter_proposed':
      return 'swap_counter_proposed';
    case 'swap_requested':
      return 'swap_requested';
    case 'swap_accepted':
      return 'swap_accepted';
    case 'swap_declined':
      return 'swap_declined';
    case 'both_confirmed':
      return 'both_confirmed';
    default:
      return null;
  }
}
