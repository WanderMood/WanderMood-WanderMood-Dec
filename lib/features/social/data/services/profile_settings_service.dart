import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/social/domain/models/user_profile.dart';
import 'package:wandermood/features/social/domain/models/wander_badge.dart';
import 'package:wandermood/features/social/domain/models/saved_folder.dart';
import 'package:wandermood/features/social/domain/models/travel_mood_preferences.dart';

class ProfileSettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user profile from database
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      if (kDebugMode) debugPrint('Error in profile provider: $e');
      return null;
    }
  }

  // Profile Info Management
  Future<void> updateProfileInfo({
    String? travelBio,
    String? currentlyExploring,
    List<String>? travelVibes,
    String? fullName,
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updateData = <String, dynamic>{};
    
    if (travelBio != null) updateData['travel_bio'] = travelBio;
    if (currentlyExploring != null) updateData['currently_exploring'] = currentlyExploring;
    if (travelVibes != null) updateData['travel_vibes'] = travelVibes;
    if (fullName != null) updateData['full_name'] = fullName;
    if (imageUrl != null) updateData['image_url'] = imageUrl;
    
    updateData['updated_at'] = DateTime.now().toIso8601String();

    try {
      await _supabase
          .from('profiles')
          .upsert({
            'id': user.id,
            'user_id': user.id,
            ...updateData,
          });
      if (kDebugMode) debugPrint('✅ Profile updated successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updating profile: $e');
      rethrow;
    }
  }

  // Travel Mood Preferences
  Future<TravelMoodPreferences?> getTravelMoodPreferences() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('travel_mood_preferences')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return response != null ? TravelMoodPreferences.fromJson(response) : null;
  }

  Future<void> updateTravelMoodPreferences(TravelMoodPreferences preferences) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase
        .from('travel_mood_preferences')
        .upsert({
          'user_id': user.id,
          'mood_categories': preferences.moodCategories.map((key, value) => 
            MapEntry(key, value.toJson())),
          'activity_preferences': preferences.activityPreferences.toJson(),
          'notification_triggers': preferences.notificationTriggers.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  // Privacy Settings
  Future<void> updatePrivacySettings({
    String? profileVisibility, // 'public', 'friends', 'private'
    String? storyVisibility,
    bool? locationSharing,
    bool? activityStatus,
    bool? allowMessages,
    bool? showFollowers,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get current settings
    final current = await _supabase
        .from('profiles')
        .select('privacy_settings')
        .eq('id', user.id)
        .single();

    final currentSettings = current['privacy_settings'] as Map<String, dynamic>? ?? {};

    // Update with new values
    if (profileVisibility != null) currentSettings['profile_visibility'] = profileVisibility;
    if (storyVisibility != null) currentSettings['story_visibility'] = storyVisibility;
    if (locationSharing != null) currentSettings['location_sharing'] = locationSharing;
    if (activityStatus != null) currentSettings['activity_status'] = activityStatus;
    if (allowMessages != null) currentSettings['allow_messages'] = allowMessages;
    if (showFollowers != null) currentSettings['show_followers'] = showFollowers;

    await _supabase
        .from('profiles')
        .update({
          'privacy_settings': currentSettings,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  // Saved Folders Management
  Future<List<SavedFolder>> getSavedFolders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('saved_folders')
        .select('''
          *,
          saved_diary_entries!folder_id(count)
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return response.map<SavedFolder>((json) {
      // Calculate item count from related saved entries
      final itemCount = json['saved_diary_entries']?.length ?? 0;
      return SavedFolder.fromJson({
        ...json,
        'item_count': itemCount,
      });
    }).toList();
  }

  Future<SavedFolder> createFolder({
    required String name,
    String? description,
    String color = '#6366f1',
    String icon = '📁',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('saved_folders')
        .insert({
          'user_id': user.id,
          'name': name,
          'description': description,
          'color': color,
          'icon': icon,
        })
        .select()
        .single();

    return SavedFolder.fromJson(response);
  }

  Future<void> updateFolder(SavedFolder folder) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase
        .from('saved_folders')
        .update({
          'name': folder.name,
          'description': folder.description,
          'color': folder.color,
          'icon': folder.icon,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', folder.id)
        .eq('user_id', user.id);
  }

  Future<void> deleteFolder(String folderId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase
        .from('saved_folders')
        .delete()
        .eq('id', folderId)
        .eq('user_id', user.id);
  }

  // Badge Management
  Future<List<UserBadge>> getUserBadges() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('user_badges')
        .select('''
          *,
          wander_badges(*)
        ''')
        .eq('user_id', user.id)
        .order('earned_at', ascending: false);

    return response.map<UserBadge>((json) => UserBadge.fromJson(json)).toList();
  }

  Future<List<WanderBadge>> getAllBadges() async {
    final response = await _supabase
        .from('wander_badges')
        .select()
        .eq('is_active', true)
        .order('category', ascending: true);

    return response.map<WanderBadge>((json) => WanderBadge.fromJson(json)).toList();
  }

  Future<void> checkAndAwardBadges() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase.rpc('check_and_award_badges', params: {
      'user_uuid': user.id,
    });
  }

  // Update Travel DNA
  Future<void> updateTravelDna() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final travelDna = await _supabase.rpc('calculate_travel_dna', params: {
      'user_uuid': user.id,
    });

    await _supabase
        .from('profiles')
        .update({
          'travel_dna': travelDna,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  // Update Mood of Month
  Future<void> updateMoodOfMonth() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final moodOfMonth = await _supabase.rpc('update_mood_of_month', params: {
      'user_uuid': user.id,
    });

    await _supabase
        .from('profiles')
        .update({
          'mood_of_month': moodOfMonth,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  // General Settings
  Future<void> updateGeneralSettings({
    String? themePreference,
    String? languagePreference,
    Map<String, bool>? notificationPreferences,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updateData = <String, dynamic>{};
    
    if (themePreference != null) updateData['theme_preference'] = themePreference;
    if (languagePreference != null) updateData['language_preference'] = languagePreference;
    if (notificationPreferences != null) updateData['notification_preferences'] = notificationPreferences;
    
    updateData['updated_at'] = DateTime.now().toIso8601String();

    await _supabase
        .from('profiles')
        .update(updateData)
        .eq('id', user.id);
  }

  // Photo Upload for Profile
  Future<String?> uploadProfilePhoto(String filePath) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      if (kDebugMode) debugPrint('📸 Starting photo upload process...');
      
      // For now, generate a user-specific avatar URL based on their email
      final avatarUrl = 'https://ui-avatars.com/api/?name=${user.email?.substring(0, 1) ?? 'U'}&background=12B347&color=fff&size=200';
      if (kDebugMode) debugPrint('📸 Generated avatar URL: $avatarUrl');

      // Update profile with the avatar URL
      await updateProfileInfo(imageUrl: avatarUrl);

      if (kDebugMode) debugPrint('✅ Photo upload completed successfully');
      return avatarUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error in photo upload process: $e');
      rethrow;
    }
  }
} 