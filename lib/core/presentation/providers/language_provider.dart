import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';

/// Provider for the app's current locale based on user profile preference
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref _ref;
  static const String _localeKey = 'app_locale';
  
  LocaleNotifier(this._ref) : super(const Locale('en')) {
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
        // First install - detect system locale
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
        final systemLanguageCode = systemLocale.languageCode.toLowerCase();
        
        // Supported languages: en, nl, es, fr, de
        final supportedLanguages = ['en', 'nl', 'es', 'fr', 'de'];
        final detectedLanguage = supportedLanguages.contains(systemLanguageCode) 
            ? systemLanguageCode 
            : 'en'; // Default to English if system language not supported
        
        state = Locale(detectedLanguage);
        
        // Save detected language to preferences
        await prefs.setString(_localeKey, detectedLanguage);
        
        // Try to save to profile (optional, works offline)
        try {
          final profileAsync = _ref.read(profileProvider);
          profileAsync.whenData((profile) async {
            if (profile != null) {
              await _ref.read(profileProvider.notifier).updateProfile(
                languagePreference: detectedLanguage,
              );
            }
          });
        } catch (e) {
          // Continue - local preference still works
        }
      }
    } catch (e) {
      state = const Locale('en');
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
    });
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
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

