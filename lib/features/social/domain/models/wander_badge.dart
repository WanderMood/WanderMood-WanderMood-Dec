class WanderBadge {
  final String id;
  final String badgeKey;
  final String name;
  final String description;
  final String icon;
  final String color;
  final String category;
  final String requirementType;
  final int requirementValue;
  final bool isActive;
  final DateTime createdAt;

  const WanderBadge({
    required this.id,
    required this.badgeKey,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.requirementType,
    required this.requirementValue,
    required this.isActive,
    required this.createdAt,
  });

  factory WanderBadge.fromJson(Map<String, dynamic> json) {
    return WanderBadge(
      id: json['id'] as String,
      badgeKey: json['badge_key'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      category: json['category'] as String,
      requirementType: json['requirement_type'] as String,
      requirementValue: json['requirement_value'] as int,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'badge_key': badgeKey,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'category': category,
      'requirement_type': requirementType,
      'requirement_value': requirementValue,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserBadge {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime? earnedAt;
  final int progress;
  final WanderBadge? badge; // Include badge details

  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    this.earnedAt,
    required this.progress,
    this.badge,
  });

  bool get isEarned => earnedAt != null;

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeId: json['badge_id'] as String,
      earnedAt: json['earned_at'] != null 
          ? DateTime.parse(json['earned_at'] as String) 
          : null,
      progress: json['progress'] as int,
      badge: json['wander_badges'] != null 
          ? WanderBadge.fromJson(json['wander_badges'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'badge_id': badgeId,
      'earned_at': earnedAt?.toIso8601String(),
      'progress': progress,
    };
  }
} 