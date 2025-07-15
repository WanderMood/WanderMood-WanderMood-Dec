import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String username,
    String? fullName,
    String? email,
    String? bio,
    String? avatarUrl,
    
    // Travel-specific fields
    String? currentlyExploring,
    @Default('adventurous') String travelStyle,
    @Default(['Spontaneous', 'Social', 'Relaxed']) List<String> travelVibes,
    @Default('happy') String favoriteMood,
    
    // Social stats
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(0) int postsCount,
    
    // Preferences
    @Default(true) bool isPublic,
    @Default('en') String languagePreference,
    @Default('system') String themePreference,
    @Default(NotificationPreferences()) NotificationPreferences notificationPreferences,
    
    // Privacy
    @Default(true) bool locationSharing,
    @Default(true) bool moodSharing,
    
    // Gamification
    @Default(0) int moodStreak,
    @Default(0) int totalPoints,
    @Default([]) List<String> achievements,
    @Default(1) int level,
    
    // Timestamps
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

@freezed
class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    @Default(true) bool push,
    @Default(true) bool email,
    @Default(true) bool travelTips,
    @Default(true) bool socialUpdates,
    @Default(false) bool marketing,
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);
}

// Extensions for business logic
extension UserProfileX on UserProfile {
  bool get isNewUser => postsCount == 0 && followersCount == 0;
  
  bool get isActiveUser => lastActiveAt != null && 
    lastActiveAt!.isAfter(DateTime.now().subtract(const Duration(days: 7)));
  
  String get displayName => fullName?.isNotEmpty == true ? fullName! : username;
  
  String get initials {
    final name = displayName;
    if (name.length < 2) return name.toUpperCase();
    
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
  
  // Calculate user level based on points
  int get calculatedLevel {
    if (totalPoints < 100) return 1;
    if (totalPoints < 500) return 2;
    if (totalPoints < 1000) return 3;
    if (totalPoints < 2000) return 4;
    return 5; // Max level
  }
  
  // Get next level points requirement
  int get pointsToNextLevel {
    switch (calculatedLevel) {
      case 1: return 100 - totalPoints;
      case 2: return 500 - totalPoints;
      case 3: return 1000 - totalPoints;
      case 4: return 2000 - totalPoints;
      default: return 0;
    }
  }
}

// Helper for mapping database fields
extension UserProfileFromDatabase on UserProfile {
  static UserProfile fromDatabase(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] as String,
      username: data['username'] as String,
      fullName: data['full_name'] as String?,
      email: data['email'] as String?,
      bio: data['bio'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      currentlyExploring: data['currently_exploring'] as String?,
      travelStyle: data['travel_style'] as String? ?? 'adventurous',
      travelVibes: (data['travel_vibes'] as List<dynamic>?)?.cast<String>() ?? 
                   ['Spontaneous', 'Social', 'Relaxed'],
      favoriteMood: data['favorite_mood'] as String? ?? 'happy',
      followersCount: data['followers_count'] as int? ?? 0,
      followingCount: data['following_count'] as int? ?? 0,
      postsCount: data['posts_count'] as int? ?? 0,
      isPublic: data['is_public'] as bool? ?? true,
      languagePreference: data['language_preference'] as String? ?? 'en',
      themePreference: data['theme_preference'] as String? ?? 'system',
      notificationPreferences: data['notification_preferences'] != null
          ? NotificationPreferences.fromJson(data['notification_preferences'])
          : const NotificationPreferences(),
      locationSharing: data['location_sharing'] as bool? ?? true,
      moodSharing: data['mood_sharing'] as bool? ?? true,
      moodStreak: data['mood_streak'] as int? ?? 0,
      totalPoints: data['total_points'] as int? ?? 0,
      achievements: (data['achievements'] as List<dynamic>?)?.cast<String>() ?? [],
      level: data['level'] as int? ?? 1,
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : null,
      updatedAt: data['updated_at'] != null 
          ? DateTime.parse(data['updated_at']) 
          : null,
      lastActiveAt: data['last_active_at'] != null 
          ? DateTime.parse(data['last_active_at']) 
          : null,
    );
  }
  
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'bio': bio,
      'avatar_url': avatarUrl,
      'currently_exploring': currentlyExploring,
      'travel_style': travelStyle,
      'travel_vibes': travelVibes,
      'favorite_mood': favoriteMood,
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'is_public': isPublic,
      'language_preference': languagePreference,
      'theme_preference': themePreference,
      'notification_preferences': notificationPreferences.toJson(),
      'location_sharing': locationSharing,
      'mood_sharing': moodSharing,
      'mood_streak': moodStreak,
      'total_points': totalPoints,
      'achievements': achievements,
      'level': level,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
} 