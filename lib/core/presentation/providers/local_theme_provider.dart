import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local theme provider that works offline and stores preferences locally
final localThemeProvider = StateNotifierProvider<LocalThemeNotifier, ThemeMode>((ref) {
  return LocalThemeNotifier();
});

class LocalThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_preference';
  
  LocalThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey) ?? 'system';
      
      switch (themeString.toLowerCase()) {
        case 'light':
          state = ThemeMode.light;
          break;
        case 'dark':
          state = ThemeMode.dark;
          break;
        case 'system':
        default:
          state = ThemeMode.system;
          break;
      }
      
      print('🎨 Local Theme: Loaded theme preference: $themeString -> ${state}');
    } catch (e) {
      print('🎨 Local Theme: Error loading theme preference: $e');
      state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    state = themeMode;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (themeMode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
        default:
          themeString = 'system';
          break;
      }
      
      await prefs.setString(_themeKey, themeString);
      print('🎨 Local Theme: Saved theme preference: $themeString');
    } catch (e) {
      print('🎨 Local Theme: Error saving theme preference: $e');
    }
  }

  Future<void> setThemeFromString(String themeString) async {
    ThemeMode themeMode;
    
    switch (themeString.toLowerCase()) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeMode = ThemeMode.system;
        break;
    }
    
    await setTheme(themeMode);
  }

  String get currentThemeString {
    switch (state) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
} 