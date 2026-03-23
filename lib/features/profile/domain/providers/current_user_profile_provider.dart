import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    return _fetch();
  }

  Future<CurrentUserProfile?> _fetch() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final profileRes = await supabase
          .from('profiles')
          // Some environments don't have `avatar_url` in the profiles table.
          // Prefer `image_url` and never request `avatar_url` to avoid 42703 errors.
          .select('full_name, username, bio, image_url, mood_streak')
          .eq('id', userId)
          .maybeSingle();

      final prefsRes = await supabase
          .from('user_preferences')
          .select(
              'home_base, age_group, selected_moods, budget_level, social_vibe, '
              'dietary_restrictions, activity_pace, time_available, interests')
          .eq('user_id', userId)
          .maybeSingle();

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
        moodStreak: moodStreak,
        homeBase: prefsRes?['home_base'] as String?,
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
    await supabase.from('user_preferences').update({
      'home_base': isLocal ? 'Local Explorer' : 'Traveler',
    }).eq('user_id', userId);
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
