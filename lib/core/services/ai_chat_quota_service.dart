import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/constants/api_usage_limits.dart';
import 'package:wandermood/core/utils/moody_clock.dart';

/// Client-side daily caps for Moody chat to protect Edge/OpenAI spend.
/// Premium (`subscriptions.plan_type == premium` and `status == active`) bypasses.
class AiChatQuotaService {
  AiChatQuotaService._();

  static const _countPrefix = 'wm_moody_chat_ok_';

  static bool? _premiumCached;
  static DateTime? _premiumCacheUntil;

  static Future<void> clearPremiumCache() {
    _premiumCached = null;
    _premiumCacheUntil = null;
    return Future.value();
  }

  static Future<bool> _isPremium(SupabaseClient supabase) async {
    final now = MoodyClock.now();
    if (_premiumCacheUntil != null &&
        now.isBefore(_premiumCacheUntil!) &&
        _premiumCached != null) {
      return _premiumCached!;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      _premiumCached = false;
      _premiumCacheUntil = now.add(const Duration(minutes: 1));
      return false;
    }

    try {
      final row = await supabase
          .from('subscriptions')
          .select('plan_type, status')
          .eq('user_id', user.id)
          .maybeSingle();

      final premium = row != null &&
          row['plan_type'] == 'premium' &&
          row['status'] == 'active';
      _premiumCached = premium;
      _premiumCacheUntil = now.add(const Duration(minutes: 5));
      return premium;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AiChatQuotaService: premium check failed: $e');
      }
      _premiumCached = false;
      _premiumCacheUntil = now.add(const Duration(minutes: 1));
      return false;
    }
  }

  static String _dayKey() =>
      MoodyClock.now().toUtc().toIso8601String().substring(0, 10);

  static Future<String> _storageKey(SupabaseClient supabase) async {
    final user = supabase.auth.currentUser;
    final day = _dayKey();
    if (user != null) {
      return '$_countPrefix${user.id}_$day';
    }
    return '${_countPrefix}guest_$day';
  }

  /// Null = allowed. Non-null = user-facing message (do not call the Edge function).
  static Future<String?> blockingMessageIfOverQuota(
    SupabaseClient supabase,
  ) async {
    if (await _isPremium(supabase)) return null;

    final prefs = await SharedPreferences.getInstance();
    final key = await _storageKey(supabase);
    final cap = supabase.auth.currentUser == null
        ? ApiUsageLimits.guestMoodyChatsPerDay
        : ApiUsageLimits.freeTierMoodyChatsPerDay;
    final count = prefs.getInt(key) ?? 0;
    if (count >= cap) {
      return "You've reached today's free chat limit for Moody. "
          'Premium will unlock more soon — thanks for exploring WanderMood!';
    }
    return null;
  }

  /// Call only after a successful Moody chat HTTP 200 (counts real API use).
  static Future<void> recordSuccessfulChat(SupabaseClient supabase) async {
    if (await _isPremium(supabase)) return;

    final prefs = await SharedPreferences.getInstance();
    final key = await _storageKey(supabase);
    final n = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, n);
  }
}
