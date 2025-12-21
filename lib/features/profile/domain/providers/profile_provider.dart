import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/profile/domain/models/profile_model.dart';
import 'package:wandermood/features/auth/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(() {
  return ProfileNotifier();
});

class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    // Watch auth state changes
    final authState = ref.watch(authStateChangesProvider);
    return authState.when(
      data: (_) => _fetchProfile(),
      loading: () => null,
      error: (_, __) => null,
    );
  }

  Future<Profile?> _fetchProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) return null;

    try {
      // First try to fetch the profile
      // Select specific columns to avoid errors if some columns don't exist
      final response = await supabase
          .from('profiles')
          .select('id, email, username, full_name, image_url, date_of_birth, bio, favorite_mood, mood_streak, followers_count, following_count, is_public, notification_preferences, theme_preference, language_preference, achievements, created_at, updated_at')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return Profile.fromSupabase(response);
      }

      // If no profile exists, create one with default values
      final defaultProfile = {
        'id': user.id,
        'email': user.email,
        'username': 'user_${user.id.substring(0, 8)}',
        'full_name': user.userMetadata?['name'] ?? 'New User',
        'bio': 'Hello! I\'m new to WanderMood 👋',
        'mood_streak': 0,
        'followers_count': 0,
        'following_count': 0,
        'is_public': true,
        'notification_preferences': {
          'push': true,
          'email': true
        },
        'theme_preference': 'system',
        'language_preference': 'en',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String()
      };

      final result = await supabase
          .from('profiles')
          .upsert(defaultProfile)
          .select()
          .single();

      return Profile.fromSupabase(result);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in profile provider: $e');
      }
      return null;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? imageUrl,
    DateTime? dateOfBirth,
    String? bio,
    String? username,
    String? favoriteMood,
    bool? isPublic,
    Map<String, bool>? notificationPreferences,
    String? themePreference,
    String? languagePreference,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) throw Exception('User not authenticated');

    state = const AsyncValue.loading();
    
    try {
      final currentProfile = await _fetchProfile();
      if (currentProfile == null) throw Exception('Profile not found');

      final updatedProfile = currentProfile.copyWith(
        fullName: fullName ?? currentProfile.fullName,
        imageUrl: imageUrl ?? currentProfile.imageUrl,
        dateOfBirth: dateOfBirth ?? currentProfile.dateOfBirth,
        bio: bio ?? currentProfile.bio,
        username: username ?? currentProfile.username,
        favoriteMood: favoriteMood ?? currentProfile.favoriteMood,
        isPublic: isPublic ?? currentProfile.isPublic,
        notificationPreferences: notificationPreferences ?? currentProfile.notificationPreferences,
        themePreference: themePreference ?? currentProfile.themePreference,
        languagePreference: languagePreference ?? currentProfile.languagePreference,
        updatedAt: DateTime.now(),
      );

      await supabase
          .from('profiles')
          .update(updatedProfile.toSupabase())
          .eq('id', user.id);

      state = AsyncValue.data(updatedProfile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<String?> uploadProfileImage(String filePath) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) throw Exception('User not authenticated');

    try {
      final file = File(filePath);
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Try 'avatars' bucket first (standard), fallback to 'profile_images'
      String bucketName = 'avatars';
      try {
        // Check if bucket exists by trying to list (will throw if doesn't exist)
        await supabase.storage.from(bucketName).list();
      } catch (e) {
        // If 'avatars' doesn't exist, try 'profile_images'
        bucketName = 'profile_images';
      }
      
      // Upload with overwrite option
      await supabase.storage
          .from(bucketName)
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final imageUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);

      if (kDebugMode) {
        debugPrint('✅ Profile image uploaded to $bucketName/$fileName');
      }

      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading profile image: $e');
      }
      rethrow; // Re-throw so caller can handle the error
    }
  }
} 