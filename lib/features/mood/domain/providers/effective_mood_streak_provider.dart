import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/mood/services/check_in_service.dart';
import 'package:wandermood/features/profile/domain/providers/current_user_profile_provider.dart';

/// Consecutive check-ins (computed) vs [profiles.mood_streak] (activity / legacy).
/// Use the higher value so the drawer, profile, and Moody Hub stay aligned.
final effectiveMoodStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profileStreak = profileAsync.valueOrNull?.moodStreak ?? 0;
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return profileStreak;
  final checkInStreak =
      await CheckInService(Supabase.instance.client).getCheckInStreak();
  return checkInStreak > profileStreak ? checkInStreak : profileStreak;
});
