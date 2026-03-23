import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/auth_helper.dart';

/// Calls the `moody` edge function for a short Moody Hub line (Feature 1 spec).
class MoodyHubMessageService {
  MoodyHubMessageService._();

  /// Edge + optional OpenAI needs more than a tight client timeout.
  static const Duration _timeout = Duration(seconds: 8);

  /// Returns `null` on timeout, non-200, or missing `message` — caller shows fallback.
  static Future<String?> fetchHubMessage({
    required List<String> currentMoods,
    required String timeOfDay,
    required int activitiesCount,
    Map<String, dynamic>? userPreferences,
  }) async {
    try {
      await AuthHelper.ensureValidSession();
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return null;

      final response = await client.functions.invoke(
        'moody',
        body: {
          'action': 'generate_hub_message',
          'user_id': user.id,
          'current_moods': currentMoods,
          'time_of_day': timeOfDay,
          'activities_count': activitiesCount,
          'user_preferences': userPreferences ?? <String, dynamic>{},
        },
      ).timeout(_timeout);

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint('⚠️ generate_hub_message status ${response.status}');
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
        debugPrint('⚠️ generate_hub_message failed: $e\n$st');
      }
      return null;
    }
  }
}
