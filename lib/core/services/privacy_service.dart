import 'package:flutter/foundation.dart';
import 'package:wandermood/core/config/supabase_config.dart';

/// Service that enforces privacy settings (profile visibility)
class PrivacyService {
  final SupabaseConfig _supabase = SupabaseConfig.client;

  /// Check if a user's profile is visible to the current user
  /// Returns true if:
  /// - The profile is public (isPublic = true)
  /// - OR the current user is viewing their own profile
  /// - OR the current user is friends with the profile owner
  Future<bool> canViewProfile(String profileUserId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Users can always view their own profile
      if (currentUser.id == profileUserId) return true;

      // Get the profile's privacy settings
      final response = await _supabase
          .from('profiles')
          .select('is_public')
          .eq('id', profileUserId)
          .maybeSingle();

      if (response == null) return false;

      final isPublic = response['is_public'] as bool? ?? true;

      // If profile is public, anyone can view it
      if (isPublic) return true;

      // If profile is private, check if users are friends
      // TODO: Implement friend check when friendship system is ready
      // For now, private profiles are only visible to the owner
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking profile visibility: $e');
      }
      return false; // Default to private on error
    }
  }

  /// Check if a user's posts are visible to the current user
  Future<bool> canViewPosts(String postUserId) async {
    // Posts visibility is typically controlled by the post's is_public flag
    // But we can also check if the user's profile is public
    return await canViewProfile(postUserId);
  }

  /// Get a filtered profile that respects privacy settings
  /// Returns null if the profile is not visible
  Future<Map<String, dynamic>?> getProfileIfVisible(String profileUserId) async {
    final canView = await canViewProfile(profileUserId);
    if (!canView) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', profileUserId)
          .maybeSingle();

      return response as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error fetching profile: $e');
      }
      return null;
    }
  }
}

/// Provider for PrivacyService
final privacyServiceProvider = Provider<PrivacyService>((ref) {
  return PrivacyService();
});

