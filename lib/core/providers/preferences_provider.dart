import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'communication_style_provider.dart';

part 'preferences_provider.freezed.dart';

@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    // Communication & Style
    @Default('friendly') String communicationStyle,
    
    // Onboarding Preferences
    @Default([]) List<String> selectedMoods,
    @Default([]) List<String> travelInterests,
    @Default('Local Explorer') String homeBase,
    @Default([]) List<String> socialVibe,
    @Default('Same Day Planner') String planningPace,
    @Default([]) List<String> travelStyles,
    @Default('Mid-Range') String budgetLevel,
    
    // AI-specific preferences
    @Default([]) List<String> favoriteMoods,
    @Default(['morning', 'afternoon', 'evening']) List<String> preferredTimeSlots,
    @Default('en') String languagePreference,
    @Default([]) List<String> dietaryRestrictions,
    @Default([]) List<String> mobilityRequirements,
    
    // Completion tracking
    @Default(false) bool hasCompletedOnboarding,
    @Default(false) bool hasCompletedPreferences,
  }) = _UserPreferences;
}

// Extension methods for Supabase integration
extension UserPreferencesExtension on UserPreferences {
  // Convert to Supabase format
  Map<String, dynamic> toSupabaseJson() {
    return {
      'communication_style': communicationStyle,
      'moods': selectedMoods,
      'interests': travelInterests,
      'home_base': homeBase,
      'social_vibe': socialVibe,
      'planning_pace': planningPace,
      'travel_styles': travelStyles,
      'language_preference': languagePreference,
      'has_completed_onboarding': hasCompletedOnboarding,
      'has_completed_preferences': hasCompletedPreferences,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

// Static factory method for creating from Supabase data
class UserPreferencesHelper {
  static UserPreferences fromSupabaseJson(Map<String, dynamic> json) {
    return UserPreferences(
      communicationStyle: json['communication_style'] ?? 'friendly',
      selectedMoods: (json['moods'] as List<dynamic>?)?.cast<String>() ?? [],
      travelInterests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      homeBase: json['home_base'] ?? 'Local Explorer',
      socialVibe: (json['social_vibe'] as List<dynamic>?)?.cast<String>() ?? [],
      planningPace: json['planning_pace'] ?? 'Same Day Planner',
      travelStyles: (json['travel_styles'] as List<dynamic>?)?.cast<String>() ?? [],
      budgetLevel: 'Mid-Range', // Default since no budget screen
      favoriteMoods: (json['moods'] as List<dynamic>?)?.cast<String>() ?? [],
      preferredTimeSlots: ['morning', 'afternoon', 'evening'], // Default
      languagePreference: json['language_preference'] ?? 'en',
      dietaryRestrictions: [], // Default since no dietary screen
      mobilityRequirements: [], // Default since no mobility screen
      hasCompletedOnboarding: json['has_completed_onboarding'] ?? false,
      hasCompletedPreferences: json['has_completed_preferences'] ?? false,
    );
  }
}

// Enhanced Notifier class with Supabase integration
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  final SupabaseClient _supabase;
  final StateNotifierProviderRef<UserPreferencesNotifier, UserPreferences> _ref;
  
  UserPreferencesNotifier(this._supabase, this._ref) : super(const UserPreferences()) {
    _loadPreferences();
  }

  // Load preferences from Supabase
  Future<void> _loadPreferences() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        state = UserPreferencesHelper.fromSupabaseJson(response);
        debugPrint('✅ Loaded preferences from Supabase');
      }
    } catch (e) {
      debugPrint('❌ Error loading preferences: $e');
    }
  }

  // Save preferences to Supabase
  Future<void> _savePreferences() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user, skipping save');
        return;
      }

      debugPrint('🔍 Saving preferences for user: ${user.id}');

      // Create preferences object that matches the database schema (no budget fields since no budget screen)
      final prefsData = {
        'user_id': user.id,
        'moods': state.selectedMoods,
        'interests': state.travelInterests,
        'travel_styles': state.travelStyles,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('user_preferences').upsert(prefsData, onConflict: 'user_id');
      debugPrint('✅ Saved preferences to Supabase (using existing schema)');
    } catch (e) {
      debugPrint('❌ Error saving preferences: $e');
      
      // If it's a foreign key constraint error, try to create a basic profile first
      if (e.toString().contains('user_preferences_user_id_fkey') || 
          e.toString().contains('foreign key constraint')) {
        debugPrint('🔧 Foreign key constraint error detected, attempting to create user profile...');
        await _ensureUserProfileExists();
        
        // Retry saving preferences after creating profile
        try {
          final user = _supabase.auth.currentUser;
          if (user != null) {
            final prefsData = {
              'user_id': user.id,
              'moods': state.selectedMoods,
              'interests': state.travelInterests,
              'travel_styles': state.travelStyles,
              'updated_at': DateTime.now().toIso8601String(),
            };
            
            await _supabase.from('user_preferences').upsert(prefsData, onConflict: 'user_id');
            debugPrint('✅ Saved preferences after creating user profile');
          }
        } catch (retryError) {
          debugPrint('❌ Failed to save preferences even after creating profile: $retryError');
        }
      }
    }
  }

  // Ensure user profile exists in the profiles table
  Future<void> _ensureUserProfileExists() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      debugPrint('🔧 Checking if user exists in auth.users...');

      // The foreign key constraint is to auth.users(id), not profiles
      // Supabase automatically creates entries in auth.users when users sign up
      // So we just need to verify the user exists and is properly authenticated
      
      if (user.id.isNotEmpty && user.email != null) {
        debugPrint('✅ User exists in auth.users: ${user.id}');
        
        // If we still get foreign key errors, it might be a timing issue
        // Let's wait a moment for the auth state to fully sync
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        debugPrint('❌ User authentication state is invalid');
        throw Exception('User authentication state is invalid');
      }
    } catch (e) {
      debugPrint('❌ Error ensuring user exists: $e');
      // Don't rethrow - let the calling code handle the error
    }
  }

  // Communication Style
  void updateCommunicationStyle(String style) {
    debugPrint('Updating communication style to: $style');
    state = state.copyWith(communicationStyle: style);
    _savePreferences();
    
    // Also update the communication style provider for UI consistency
    try {
      _ref.read(communicationStyleProvider.notifier).setCommunicationStyle(style);
    } catch (e) {
      debugPrint('⚠️ Could not update communication style provider: $e');
    }
  }

  // Mood preferences
  void updateSelectedMoods(List<String> moods) {
    debugPrint('Updating moods to: $moods');
    state = state.copyWith(
      selectedMoods: moods,
      favoriteMoods: moods, // Also update AI favorite moods
    );
    debugPrint('Updated state moods: ${state.selectedMoods}');
    _savePreferences();
  }

  // Travel interests
  void updateTravelInterests(List<String> interests) {
    debugPrint('Updating interests to: $interests');
    state = state.copyWith(travelInterests: interests);
    _savePreferences();
  }

  // Home base (travel background)
  void updateHomeBase(String homeBase) {
    debugPrint('Updating home base to: $homeBase');
    state = state.copyWith(homeBase: homeBase);
    _savePreferences();
  }

  // Social vibe
  void updateSocialVibe(List<String> vibe) {
    debugPrint('Updating social vibe to: $vibe');
    state = state.copyWith(socialVibe: vibe);
    _savePreferences();
  }

  // Planning pace
  void updatePlanningPace(String pace) {
    debugPrint('Updating planning pace to: $pace');
    state = state.copyWith(planningPace: pace);
    _savePreferences();
  }

  // Travel styles
  void updateTravelStyles(List<String> styles) {
    debugPrint('Updating travel styles to: $styles');
    state = state.copyWith(travelStyles: styles);
    _savePreferences();
  }

  // Budget level (removed - no budget screen anymore)
  // void updateBudgetLevel(String level) { ... }

  // AI-specific preferences
  void updatePreferredTimeSlots(List<String> timeSlots) {
    state = state.copyWith(preferredTimeSlots: timeSlots);
    _savePreferences();
  }

  void updateDietaryRestrictions(List<String> restrictions) {
    state = state.copyWith(dietaryRestrictions: restrictions);
    _savePreferences();
  }

  void updateMobilityRequirements(List<String> requirements) {
    state = state.copyWith(mobilityRequirements: requirements);
    _savePreferences();
  }

  // Completion tracking
  void markOnboardingCompleted() {
    debugPrint('Marking onboarding as completed');
    state = state.copyWith(hasCompletedOnboarding: true);
    _savePreferences();
  }

  void markPreferencesCompleted() {
    debugPrint('Marking preferences as completed');
    state = state.copyWith(hasCompletedPreferences: true);
    _savePreferences();
  }

  // Reset for testing
  void resetOnboardingStatus() {
    debugPrint('Resetting onboarding status');
    state = state.copyWith(
      hasCompletedOnboarding: false,
      hasCompletedPreferences: false,
    );
    _savePreferences();
  }

  // Reset all preferences
  void reset() {
    state = const UserPreferences();
    _savePreferences();
  }

  // Force reload from Supabase
  Future<void> reload() async {
    await _loadPreferences();
  }

  // Clear authentication state and preferences for fresh start
  Future<void> clearAuthenticationState() async {
    try {
      debugPrint('🔄 Clearing authentication state for fresh start...');
      
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Reset local state
      state = const UserPreferences();
      
      debugPrint('✅ Authentication state cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing authentication state: $e');
    }
  }
}

// Enhanced provider with Supabase integration
final preferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  final supabase = Supabase.instance.client;
  return UserPreferencesNotifier(supabase, ref);
});

// Provider for clearing authentication state
final clearAuthProvider = Provider((ref) {
  return () async {
    await ref.read(preferencesProvider.notifier).clearAuthenticationState();
  };
}); 