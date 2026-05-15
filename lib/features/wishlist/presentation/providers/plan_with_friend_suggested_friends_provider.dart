import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';

/// Followed Wanderers shown as horizontal suggestions in the plan-with-friend sheet.
final planWithFriendSuggestedFriendsProvider =
    FutureProvider.autoDispose<List<PlanMetVriendFriend>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final follows = await Supabase.instance.client
      .from('user_follows')
      .select('followed_user_id')
      .eq('follower_user_id', userId)
      .limit(12);

  final ids = (follows as List)
      .map((r) => r['followed_user_id'] as String)
      .where((id) => id.isNotEmpty)
      .toList();
  if (ids.isEmpty) return [];

  final profiles = await Supabase.instance.client
      .from('profiles')
      .select('id, full_name, username, image_url')
      .inFilter('id', ids);

  return (profiles as List).map((p) {
    final username = (p['username'] as String?)?.trim();
    final fullName = (p['full_name'] as String?)?.trim();
    return PlanMetVriendFriend(
      userId: p['id'] as String,
      displayName: fullName != null && fullName.isNotEmpty
          ? fullName
          : (username != null && username.isNotEmpty ? username : 'Wanderer'),
      username: username,
      avatarUrl: p['image_url'] as String?,
    );
  }).toList();
});
