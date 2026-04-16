import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/auth/providers/auth_provider.dart';
import '../models/current_user_profile.dart';

final currentUserProfileProvider =
    AsyncNotifierProvider<CurrentUserProfileNotifier, CurrentUserProfile?>(() {
  return CurrentUserProfileNotifier();
});

class CurrentUserProfileNotifier extends AsyncNotifier<CurrentUserProfile?> {
  List<String> _dedupeVibes(List<String> vibes) {
    final seen = <String>{};
    final result = <String>[];
    for (final vibe in vibes) {
      final cleaned = vibe.trim();
      final key = cleaned.toLowerCase();
      if (cleaned.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      result.add(cleaned);
      if (result.length == 5) break;
    }
    return result;
  }

  @override
  Future<CurrentUserProfile?> build() async {
    // Re-run when auth hydrates so Profile tab does not stick on a null spinner.
    ref.watch(authStateChangesProvider);
    return _fetch();
  }

  Future<Map<String, dynamic>?> _fetchProfileRow(
    SupabaseClient supabase,
    String userId,
  ) async {
    try {
      return await supabase
          .from('profiles')
          .select(
              'full_name, username, bio, image_url, mood_streak, currently_exploring')
          .eq('id', userId)
          .maybeSingle();
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('column') && msg.contains('does not exist')) {
        return await supabase
            .from('profiles')
            .select('full_name, username, bio, image_url, mood_streak')
            .eq('id', userId)
            .maybeSingle();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchPrefsRow(
    SupabaseClient supabase,
    String userId,
  ) async {
    return await supabase
        .from('user_preferences')
        // Avoid hardcoding columns here: some environments diverge and selecting
        // missing columns causes noisy 400s on launch.
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<CurrentUserProfile?> _fetch() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final profileRes = await _fetchProfileRow(supabase, userId);
      Map<String, dynamic>? prefsRes;
      try {
        prefsRes = await _fetchPrefsRow(supabase, userId);
      } catch (_) {
        prefsRes = null;
      }

      final avatarUrl = profileRes?['image_url'] as String?;

      List<String> selectedMoods = [];
      if (prefsRes?['selected_moods'] != null) {
        selectedMoods = _dedupeVibes(
          List<String>.from(prefsRes!['selected_moods'] as List),
        );
      }

      List<String> dietaryRestrictions = [];
      if (prefsRes?['dietary_restrictions'] != null) {
        dietaryRestrictions =
            List<String>.from(prefsRes!['dietary_restrictions'] as List);
      }

      String? socialVibe;
      final sv = prefsRes?['social_vibe'];
      if (sv is List && sv.isNotEmpty) {
        socialVibe = sv.first.toString();
      } else if (sv is String && sv.isNotEmpty) {
        socialVibe = sv;
      }

      final moodStreak = profileRes?['mood_streak'] as int? ?? 0;

      return CurrentUserProfile(
        userId: userId,
        fullName: profileRes?['full_name'] as String?,
        username: profileRes?['username'] as String?,
        bio: profileRes?['bio'] as String?,
        avatarUrl: avatarUrl,
        ageGroup: prefsRes?['age_group'] as String?,
        gender: prefsRes?['gender'] as String?,
        moodStreak: moodStreak,
        homeBase: (profileRes?['currently_exploring'] as String?) ??
            (prefsRes?['home_base'] as String?),
        selectedMoods: selectedMoods,
        budgetLevel: prefsRes?['budget_level'] as String?,
        socialVibe: socialVibe,
        dietaryRestrictions: dietaryRestrictions,
        activityPace: prefsRes?['activity_pace'] as String?,
        timeAvailable: prefsRes?['time_available'] as String?,
        interests: prefsRes?['interests'],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  void updateAvatarUrl(String url) {
    state.whenData((p) {
      if (p != null) state = AsyncValue.data(p.copyWith(avatarUrl: url));
    });
  }

  Future<void> updateTravelMode(bool isLocal) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('profiles').update({
      'currently_exploring': isLocal ? 'local' : 'traveling',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
    await refresh();
  }

  void updateVibes(List<String> vibes) {
    state.whenData((p) {
      if (p != null) {
        state = AsyncValue.data(
          p.copyWith(selectedMoods: _dedupeVibes(vibes)),
        );
      }
    });
  }
}
