import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/domain/models/user_preferences.dart';
import 'package:wandermood/core/notifications/user_preferences_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:wandermood/core/config/env_config.dart';
import 'package:wandermood/core/config/supabase_config.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  return UserPreferencesNotifier(sharedPrefs);
});

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  final SharedPreferences _prefs;
  static const String _prefsKey = userPreferencesSharedPrefsKey;

  UserPreferencesNotifier(this._prefs) : super(UserPreferences()) {
    _loadPreferences();
    _listenToAuthChanges();
  }

  // Listen to authentication changes and retry saving to Supabase
  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        debugPrint('🔄 User authenticated - retrying Supabase save...');
        retrySaveToSupabase();
      }
    });
  }

  Future<void> _loadPreferences() async {
    // First try to load from SharedPreferences for offline access
    final prefsJson = _prefs.getString(_prefsKey);
    if (prefsJson != null) {
      try {
        state = UserPreferences.fromJson(prefsJson);
      } catch (e) {
        debugPrint('Error loading preferences from SharedPreferences: $e');
        state = UserPreferences();
      }
    }

    // Then try to load from Supabase if user is authenticated
    final user = SupabaseConfig.auth.currentUser;
    if (user != null) {
      try {
        final response = await SupabaseConfig.client
            .from(SupabaseConfig.userPreferencesTable)
            .select()
            .eq('user_id', user.id)
            .single();

        if (response != null) {
          final supabasePrefs = UserPreferences.fromMap({
            'darkMode': response['dark_mode'],
            'useSystemTheme': response['use_system_theme'],
            'useAnimations': response['use_animations'],
            'showConfetti': response['show_confetti'],
            'showProgress': response['show_progress'],
            'tripReminders': response['trip_reminders'],
            'weatherUpdates': response['weather_updates'],
          });

          // Update state and local storage with Supabase data
          state = supabasePrefs;
          await _saveToSharedPreferences();
          
          if (kDebugMode) {
            debugPrint('✅ Loaded preferences from Supabase: $supabasePrefs');
          }
        }
      } catch (e) {
        debugPrint('Error loading preferences from Supabase: $e');
        // If no preferences exist in Supabase, save current state
        await _saveToSupabase();
      }
    }
  }

  Future<void> _saveToSharedPreferences() async {
    await _prefs.setString(_prefsKey, state.toJson());
    if (kDebugMode) {
      debugPrint('✅ Saved preferences to SharedPreferences: $state');
    }
  }

  Future<void> _saveToSupabase() async {
    final user = SupabaseConfig.auth.currentUser;
    final session = SupabaseConfig.auth.currentSession;
    
    if (kDebugMode) {
      debugPrint('🔍 Attempting to save preferences to Supabase...');
      debugPrint('🔍 User: ${user?.id}');
      debugPrint('🔍 Session: ${session?.user?.id}');
    }
    
    if (user != null && session != null) {
      try {
        final dataToSave = {
          'user_id': user.id,
          'dark_mode': state.darkMode,
          'use_system_theme': state.useSystemTheme,
          'use_animations': state.useAnimations,
          'show_confetti': state.showConfetti,
          'show_progress': state.showProgress,
          'trip_reminders': state.tripReminders,
          'weather_updates': state.weatherUpdates,
        };
        
        if (kDebugMode) {
          debugPrint('🔧 Saving data to Supabase: $dataToSave');
        }
        
        await SupabaseConfig.client
            .from(SupabaseConfig.userPreferencesTable)
            .upsert(dataToSave, onConflict: 'user_id');
            
        if (kDebugMode) {
          debugPrint('✅ Successfully saved preferences to Supabase for user: ${user.id}');
        }
      } catch (e) {
        debugPrint('❌ Error saving preferences to Supabase: $e');
        debugPrint('❌ User ID: ${user.id}');
        debugPrint('❌ Session valid: ${session.isExpired ? 'NO' : 'YES'}');
      }
    } else {
      debugPrint('⚠️ Cannot save to Supabase - user not authenticated');
      debugPrint('⚠️ User: ${user?.id ?? 'null'}');
      debugPrint('⚠️ Session: ${session?.user?.id ?? 'null'}');
    }
  }

  Future<void> _savePreferences() async {
    // Always save to SharedPreferences for offline access
    await _saveToSharedPreferences();
    
    // Always attempt to save to Supabase (will handle auth check internally)
    await _saveToSupabase();
  }

  // Method to retry saving to Supabase when user becomes authenticated
  Future<void> retrySaveToSupabase() async {
    final user = SupabaseConfig.auth.currentUser;
    final session = SupabaseConfig.auth.currentSession;
    
    if (user != null && session != null) {
      debugPrint('🔄 Retrying save to Supabase after authentication...');
      await _saveToSupabase();
    }
  }

  // Update methods for settings screen
  Future<void> updateUseSystemTheme(bool value) async {
    state = state.copyWith(useSystemTheme: value);
    await _savePreferences();
  }

  Future<void> updateDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    await _savePreferences();
  }

  Future<void> updateUseAnimations(bool value) async {
    state = state.copyWith(useAnimations: value);
    await _savePreferences();
  }

  Future<void> updateTripReminders(bool value) async {
    state = state.copyWith(tripReminders: value);
    await _savePreferences();
  }

  Future<void> updateWeatherUpdates(bool value) async {
    state = state.copyWith(weatherUpdates: value);
    await _savePreferences();
  }

  Future<void> updateShowConfetti(bool value) async {
    state = state.copyWith(showConfetti: value);
    await _savePreferences();
  }

  Future<void> updateShowProgress(bool value) async {
    state = state.copyWith(showProgress: value);
    await _savePreferences();
  }

  Future<void> resetToDefaults() async {
    state = UserPreferences();
    await _savePreferences();
  }
} 
 
 
 