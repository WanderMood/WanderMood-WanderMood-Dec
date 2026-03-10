import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/profile/domain/models/profile_model.dart';
import 'package:wandermood/features/auth/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';

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
      // Select only columns that exist in profiles table (avoid 42703 errors)
      final response = await supabase
          .from('profiles')
          .select('id, email, username, full_name, image_url, avatar_url, date_of_birth, bio, favorite_mood, mood_streak, is_public, created_at, updated_at')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return Profile.fromSupabase(response);
      }

      // If no profile exists, create one with default values (core columns only)
      final defaultProfile = {
        'id': user.id,
        'email': user.email,
        'username': 'user_${user.id.substring(0, 8)}',
        'full_name': user.userMetadata?['name'] ?? 'New User',
        'bio': 'Hello! I\'m new to WanderMood 👋',
        'mood_streak': 0,
        'is_public': true,
        'updated_at': DateTime.now().toIso8601String(),
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
    String? profileVisibility,
    bool? showEmail,
    bool? showAge,
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
        isPublic: isPublic ?? (profileVisibility == null ? currentProfile.isPublic : profileVisibility == 'public'),
        profileVisibility: profileVisibility ?? currentProfile.profileVisibility,
        showEmail: showEmail ?? currentProfile.showEmail,
        showAge: showAge ?? currentProfile.showAge,
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
      
      // Check file size (max 5MB)
      final fileSize = await file.length();
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (fileSize > maxSize) {
        throw Exception('Image file is too large. Please select an image smaller than 5MB.');
      }
      
      if (kDebugMode) {
        debugPrint('📤 Uploading profile image: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }
      
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
      
      // Retry logic for network/TLS errors
      int maxRetries = 3;
      int retryCount = 0;
      Exception? lastError;
      
      while (retryCount < maxRetries) {
        try {
          // Upload with overwrite option and timeout
          await supabase.storage
              .from(bucketName)
              .upload(
                fileName, 
                file, 
                fileOptions: const FileOptions(
                  upsert: true,
                  cacheControl: '3600',
                ),
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw TimeoutException('Upload timed out after 30 seconds');
                },
              );

          final imageUrl = supabase.storage
              .from(bucketName)
              .getPublicUrl(fileName);

          if (kDebugMode) {
            debugPrint('✅ Profile image uploaded to $bucketName/$fileName');
          }

          return imageUrl;
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          
          // Check if it's a network/TLS error that we should retry
          final errorString = e.toString().toLowerCase();
          final isRetryableError = errorString.contains('ssl') ||
              errorString.contains('tls') ||
              errorString.contains('timeout') ||
              errorString.contains('network') ||
              errorString.contains('connection');
          
          if (isRetryableError && retryCount < maxRetries - 1) {
            retryCount++;
            final delay = Duration(seconds: retryCount * 2); // Exponential backoff: 2s, 4s, 6s
            
            if (kDebugMode) {
              debugPrint('⚠️ Upload failed (attempt $retryCount/$maxRetries), retrying in ${delay.inSeconds}s...');
            }
            
            await Future.delayed(delay);
            continue;
          } else {
            // Not retryable or max retries reached
            rethrow;
          }
        }
      }
      
      // If we get here, all retries failed
      throw lastError ?? Exception('Upload failed after $maxRetries attempts');
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading profile image: $e');
      }
      
      // Provide user-friendly error messages
      if (e.toString().contains('SSL') || e.toString().contains('TLS')) {
        throw Exception('Network error. Please check your connection and try again.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Upload timed out. Please try again with a smaller image.');
      } else if (e.toString().contains('too large')) {
        rethrow; // Already user-friendly
      } else {
        rethrow;
      }
    }
  }
} 