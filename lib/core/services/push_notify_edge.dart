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
  bool persistInApp = true,
}) {
  unawaited(() async {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession == null) return;
      final langCode = lang ?? await wandermoodNotificationLangCode();
      final payload = {
        'recipient_id': recipientId,
        'event': event,
        'lang': langCode,
        'data': data,
        'persist_in_app': persistInApp,
      };
      final res = await _invokePushNotifyWithRetry(client, payload);
      if (kDebugMode) {
        debugPrint('push-notify response: ${res.data}');
      }
    } on FunctionException catch (e) {
      // Push is secondary for Mood Match. Invite/session UX must continue even
      // when push edge is temporarily unavailable (e.g. 5xx).
      final status = e.status ?? 0;
      if (kDebugMode) {
        if (status >= 500) {
          debugPrint(
            'push-notify temporarily unavailable (HTTP $status), continuing without push.',
          );
        } else {
          debugPrint('push-notify FunctionException(HTTP $status): ${e.reasonPhrase}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('push-notify unexpected error (non-blocking): $e');
      }
    }
  }());
}

Future<FunctionResponse> _invokePushNotifyWithRetry(
  SupabaseClient client,
  Map<String, dynamic> payload,
) async {
  try {
    return await client.functions.invoke('push-notify', body: payload);
  } on FunctionException catch (e) {
    final status = e.status ?? 0;
    if (status >= 500) {
      // One short retry for transient gateway/cold-start edge failures.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return await client.functions.invoke('push-notify', body: payload);
    }
    rethrow;
  }
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
