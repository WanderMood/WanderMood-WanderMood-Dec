import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/auth_helper.dart';
import 'package:wandermood/core/utils/moody_idle_checker.dart';

/// `moody` edge function — `action: idle_message` (Feature 3 spec).
class MoodyIdleMessageService {
  MoodyIdleMessageService._();

  static const Duration _timeout = Duration(milliseconds: 1500);

  /// Returns `null` on timeout / error / missing `message`.
  static Future<String?> fetchIdleMessage({
    required MoodyIdleState idleState,
    Map<String, dynamic>? userPreferences,
    String? topInterest,
  }) async {
    try {
      await AuthHelper.ensureValidSession();
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return null;

      final response = await client.functions
          .invoke(
            'moody',
            body: {
              'action': 'idle_message',
              'idle_state': idleState.name,
              'user_id': user.id,
              'user_preferences': userPreferences ?? <String, dynamic>{},
              if (topInterest != null && topInterest.isNotEmpty)
                'top_interest': topInterest,
            },
          )
          .timeout(_timeout);

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint('⚠️ idle_message status ${response.status}');
        }
        return null;
      }

      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final m = raw['message'] as String?;
        if (m != null && m.trim().isNotEmpty) return m.trim();
      }
      return null;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('⚠️ idle_message failed: $e\n$st');
      }
      return null;
    }
  }
}
