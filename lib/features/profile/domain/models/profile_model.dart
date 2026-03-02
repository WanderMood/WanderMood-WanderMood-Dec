import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String email,
    String? username,
    String? fullName,
    String? imageUrl,
    DateTime? dateOfBirth,
    String? bio,
    String? favoriteMood,
    @Default(0) int moodStreak,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(true) bool isPublic,
    @Default('public') String profileVisibility,
    @Default(false) bool showEmail,
    @Default(true) bool showAge,
    @Default({
      'push': true,
      'email': true,
    }) Map<String, bool> notificationPreferences,
    @Default('system') String themePreference,
    @Default('en') String languagePreference,
    @Default([]) List<String> achievements,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  static Profile fromSupabase(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String,
      username: map['username'] as String?,
      fullName: map['full_name'] as String?,
      imageUrl: map['image_url'] as String? ?? map['avatar_url'] as String?,
      dateOfBirth: map['date_of_birth'] != null 
          ? DateTime.parse(map['date_of_birth'] as String)
          : null,
      bio: map['bio'] as String?,
      favoriteMood: map['favorite_mood'] as String?,
      moodStreak: map['mood_streak'] as int? ?? 0,
      followersCount: map['followers_count'] as int? ?? 0,
      followingCount: map['following_count'] as int? ?? 0,
      isPublic: map['is_public'] as bool? ?? true,
      profileVisibility: map['profile_visibility'] as String? ?? (map['is_public'] == false ? 'private' : 'public'),
      showEmail: map['show_email'] as bool? ?? false,
      showAge: map['show_age'] as bool? ?? true,
      notificationPreferences: (map['notification_preferences'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as bool),
      ) ?? {'push': true, 'email': true},
      themePreference: map['theme_preference'] as String? ?? 'system',
      languagePreference: map['language_preference'] as String? ?? 'en',
      achievements: (map['achievements'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  const Profile._();

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'image_url': imageUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'bio': bio,
      'favorite_mood': favoriteMood,
      'mood_streak': moodStreak,
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_public': profileVisibility == 'public',
      'profile_visibility': profileVisibility,
      'show_email': showEmail,
      'show_age': showAge,
      'notification_preferences': notificationPreferences,
      'theme_preference': themePreference,
      'language_preference': languagePreference,
      'achievements': achievements,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
} 