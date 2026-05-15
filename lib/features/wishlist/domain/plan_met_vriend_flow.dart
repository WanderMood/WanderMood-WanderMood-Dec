import 'package:wandermood/features/places/models/place.dart';

/// Friend selected for plan-met-vriend.
class PlanMetVriendFriend {
  const PlanMetVriendFriend({
    required this.userId,
    required this.displayName,
    this.username,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
}

/// Anchor place context carried through the flow.
class PlanMetVriendPlace {
  const PlanMetVriendPlace({
    required this.placeId,
    required this.placeName,
    required this.placeData,
    this.place,
    this.sourceUrl,
  });

  final String placeId;
  final String placeName;
  final Map<String, dynamic> placeData;
  final Place? place;
  final String? sourceUrl;

  String? get photoUrl {
    final p = place;
    if (p != null && p.photos.isNotEmpty) return p.photos.first;
    final direct = placeData['photo_url'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final photos = placeData['photos'];
    if (photos is List && photos.isNotEmpty) {
      return photos.first?.toString();
    }
    return null;
  }
}

/// After invite is sent — waiting screen.
class PlanMetVriendWaitingArgs {
  const PlanMetVriendWaitingArgs({
    required this.sessionId,
    required this.inviteId,
    required this.friend,
    required this.place,
    this.inviterDisplayName,
    this.inviterAvatarUrl,
  });

  final String sessionId;
  final String inviteId;
  final PlanMetVriendFriend friend;
  final PlanMetVriendPlace place;
  final String? inviterDisplayName;
  final String? inviterAvatarUrl;
}

/// Friend opens push / deep link.
class PlanMetVriendInviteResponseArgs {
  const PlanMetVriendInviteResponseArgs({
    required this.sessionId,
    required this.inviteId,
  });

  final String sessionId;
  final String inviteId;
}

/// Match celebration.
class PlanMetVriendMatchArgs {
  const PlanMetVriendMatchArgs({
    required this.sessionId,
    required this.inviteId,
    required this.friend,
    required this.place,
    required this.matchedDate,
  });

  final String sessionId;
  final String inviteId;
  final PlanMetVriendFriend friend;
  final PlanMetVriendPlace place;
  final DateTime matchedDate;
}

/// Visual state for a plan card on [PlanMetVriendPlansScreen].
enum PlanMetVriendPlanCardKind {
  waiting,
  confirmed,
  needsReply,
}

/// Row for the hamburger-menu list of active friend plans.
class PlanMetVriendPlanListItem {
  const PlanMetVriendPlanListItem({
    required this.sessionId,
    required this.placeName,
    required this.status,
    required this.isHost,
    required this.cardKind,
    this.isCompleted = false,
    this.plannedDate,
    this.friendLabel,
    this.friendAvatarUrl,
    this.photoUrl,
    this.placeId,
    this.timeSlot,
    this.proposedByUserId,
    this.inviteId,
    this.friendUserId,
    this.locationLabel,
    required this.updatedAt,
  });

  final String sessionId;
  final String placeName;
  final String status;
  final bool isHost;
  final PlanMetVriendPlanCardKind cardKind;
  /// Saved to My Day or session [completed_at] set.
  final bool isCompleted;
  final DateTime? plannedDate;
  final String? friendLabel;
  final String? friendAvatarUrl;
  final String? photoUrl;
  final String? placeId;
  /// `morning` | `afternoon` | `evening` | `whole_day`
  final String? timeSlot;
  final String? proposedByUserId;
  final String? inviteId;
  final String? friendUserId;
  final String? locationLabel;
  final DateTime updatedAt;

  String? get friendFirstName {
    final label = friendLabel?.trim();
    if (label == null || label.isEmpty) return null;
    return label.split(RegExp(r'\s+')).first;
  }
}

class PlanMetVriendNoOverlapArgs {
  const PlanMetVriendNoOverlapArgs({
    required this.sessionId,
    required this.inviteId,
    required this.friend,
    required this.place,
    this.sourceUrl,
  });

  final String sessionId;
  final String inviteId;
  final PlanMetVriendFriend friend;
  final PlanMetVriendPlace place;
  final String? sourceUrl;
}
