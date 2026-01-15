import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';

/// Provider for the app's current locale based on user profile preference
/// Returns null to use system locale, or a specific Locale if user has set a preference
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale?> {
  final Ref _ref;
  static const String _localeKey = 'app_locale';
  static const String _useSystemKey = 'use_system_locale';
  
  LocaleNotifier(this._ref) : super(null) { // Start with null (system default)
    _loadLocale();
    // Watch profile changes to update locale when user changes language preference
    _ref.listen(profileProvider, (previous, next) {
      next.whenData((profile) {
        if (profile?.languagePreference != null) {
          _updateLocaleFromProfile(profile!.languagePreference!);
        }
      });
    });
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user explicitly wants to use system locale
      final useSystem = prefs.getBool(_useSystemKey) ?? false;
      if (useSystem) {
        state = null; // Use system locale
        return;
      }
      
      // Check if user has ever set a language preference
      final hasSetLanguage = prefs.containsKey(_localeKey);
      
      if (hasSetLanguage) {
        // User has set a preference - use it
        final profileAsync = _ref.read(profileProvider);
        profileAsync.whenData((profile) {
          if (profile?.languagePreference != null) {
            _updateLocaleFromProfile(profile!.languagePreference!);
            return;
          }
        });
        
        // Fallback to SharedPreferences
        final localeCode = prefs.getString(_localeKey) ?? 'en';
        state = Locale(localeCode);
      } else {
        // First install - use system locale (null)
        state = null;
      }
    } catch (e) {
      state = null; // Default to system locale on error
    }
  }

  void _updateLocaleFromProfile(String languageCode) {
    // Map language codes from profile to Flutter Locale
    final localeMap = {
      'en': const Locale('en'),
      'nl': const Locale('nl'),
      'es': const Locale('es'),
      'fr': const Locale('fr'),
      'de': const Locale('de'),
    };
    
    state = localeMap[languageCode.toLowerCase()] ?? const Locale('en');
    
    // Also save to SharedPreferences for offline access
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_localeKey, languageCode);
      prefs.setBool(_useSystemKey, false);
    });
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    
    final prefs = await SharedPreferences.getInstance();
    
    if (locale == null) {
      // User selected "System default"
      await prefs.setBool(_useSystemKey, true);
      await prefs.remove(_localeKey);
    } else {
      // User selected a specific language
      await prefs.setBool(_useSystemKey, false);
      await prefs.setString(_localeKey, locale.languageCode);
      
      // Try to sync with profile (optional, works offline)
      try {
        await _ref.read(profileProvider.notifier).updateProfile(
          languagePreference: locale.languageCode,
        );
      } catch (e) {
        // Continue - local preference still works
      }
    }
  }
}

