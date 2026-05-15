import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';

/// Locally remembers friends picked via search for quicker re-invites.
class PlanWithFriendRecentFriendsStore {
  PlanWithFriendRecentFriendsStore._();

  static const _key = 'plan_with_friend_recent_friends_v1';
  static const _max = 8;

  static Future<List<PlanMetVriendFriend>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => _fromJson(Map<String, dynamic>.from(e as Map)))
          .where((f) => f.userId.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> remember(PlanMetVriendFriend friend) async {
    if (friend.userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final next = [
      friend,
      ...current.where((f) => f.userId != friend.userId),
    ].take(_max).toList();
    await prefs.setString(
      _key,
      jsonEncode(next.map(_toJson).toList()),
    );
  }

  static Map<String, dynamic> _toJson(PlanMetVriendFriend f) => {
        'userId': f.userId,
        'displayName': f.displayName,
        'username': f.username,
        'avatarUrl': f.avatarUrl,
      };

  static PlanMetVriendFriend _fromJson(Map<String, dynamic> j) {
    return PlanMetVriendFriend(
      userId: j['userId'] as String? ?? '',
      displayName: j['displayName'] as String? ?? 'Wanderer',
      username: j['username'] as String?,
      avatarUrl: j['avatarUrl'] as String?,
    );
  }
}
