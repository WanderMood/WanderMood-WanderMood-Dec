/// v1 group mood planning — maps to `group_sessions` / `group_session_members` / `group_plans`.
class GroupSessionRow {
  const GroupSessionRow({
    required this.id,
    required this.createdBy,
    this.title,
    required this.joinCode,
    required this.status,
    required this.maxMembers,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.plannedDate,
    this.proposedByUserId,
    this.proposedSlot,
  });

  final String id;
  final String createdBy;
  final String? title;
  final String joinCode;
  final String status;
  final int maxMembers;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? plannedDate; // YYYY-MM-DD, written by owner in day picker
  final String? proposedByUserId;
  final String? proposedSlot;

  factory GroupSessionRow.fromMap(Map<String, dynamic> map) {
    return GroupSessionRow(
      id: map['id'] as String,
      createdBy: map['created_by'] as String,
      title: map['title'] as String?,
      joinCode: map['join_code'] as String,
      status: map['status'] as String,
      maxMembers: (map['max_members'] as num?)?.toInt() ?? 2,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      plannedDate: map['planned_date'] as String?,
      proposedByUserId: map['proposed_by_user_id'] as String?,
      proposedSlot: map['proposed_slot'] as String?,
    );
  }
}

/// Session row plus member rows from a single `group_sessions` + nested select.
class GroupSessionDetail {
  const GroupSessionDetail({
    required this.session,
    required this.members,
  });

  final GroupSessionRow session;
  final List<GroupMemberRow> members;
}

class GroupMemberRow {
  const GroupMemberRow({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.moodTag,
    this.submittedAt,
  });

  final String id;
  final String sessionId;
  final String userId;
  final String? moodTag;
  final DateTime? submittedAt;

  bool get hasSubmittedMood => moodTag != null && moodTag!.trim().isNotEmpty;

  factory GroupMemberRow.fromMap(Map<String, dynamic> map) {
    return GroupMemberRow(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      userId: map['user_id'] as String,
      moodTag: map['mood_tag'] as String?,
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'] as String)
          : null,
    );
  }
}

class GroupMemberView {
  const GroupMemberView({
    required this.member,
    this.username,
    this.fullName,
    this.avatarUrl,
  });

  final GroupMemberRow member;
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  String get displayName {
    final u = username?.trim();
    if (u != null && u.isNotEmpty) return '@$u';
    final f = fullName?.trim();
    if (f != null && f.isNotEmpty) return f;
    return 'Traveler';
  }
}

class GroupPlanRow {
  const GroupPlanRow({
    required this.id,
    required this.sessionId,
    required this.planData,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final Map<String, dynamic> planData;
  final DateTime createdAt;

  factory GroupPlanRow.fromMap(Map<String, dynamic> map) {
    final raw = map['plan_data'];
    return GroupPlanRow(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      planData: raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
