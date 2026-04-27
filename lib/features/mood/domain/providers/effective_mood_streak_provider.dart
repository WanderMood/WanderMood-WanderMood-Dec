import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/mood/services/check_in_service.dart';
import 'package:wandermood/features/profile/domain/providers/current_user_profile_provider.dart';

/// Unified consecutive-day streak (moods + check-ins + My Day schedule) vs
/// [profiles.mood_streak]. Use the higher value so UI stays aligned with
/// whichever source was updated last.
final effectiveMoodStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profileStreak = profileAsync.valueOrNull?.moodStreak ?? 0;
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return profileStreak;
  final unified = await CheckInService(Supabase.instance.client)
      .getUnifiedEngagementStreak();
  return math.max(profileStreak, unified);
});
