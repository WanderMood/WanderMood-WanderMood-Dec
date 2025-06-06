import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';

/// Provider that determines the app's theme mode based on user profile preferences
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  final profileAsync = ref.watch(profileProvider);
  
  return profileAsync.when(
    data: (profile) {
      final themePreference = profile?.themePreference ?? 'system';
      print('🎨 Theme Provider: Profile loaded, theme preference: $themePreference');
      
      switch (themePreference.toLowerCase()) {
        case 'light':
          print('🎨 Theme Provider: Returning ThemeMode.light');
          return ThemeMode.light;
        case 'dark':
          print('🎨 Theme Provider: Returning ThemeMode.dark');
          return ThemeMode.dark;
        case 'system':
        default:
          print('🎨 Theme Provider: Returning ThemeMode.system');
          return ThemeMode.system;
      }
    },
    loading: () {
      print('🎨 Theme Provider: Profile loading, returning ThemeMode.system');
      return ThemeMode.system;
    },
    error: (error, _) {
      print('🎨 Theme Provider: Profile error: $error, returning ThemeMode.system');
      return ThemeMode.system;
    },
  );
});

/// Provider for detecting if the current theme is dark
final isDarkThemeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(appThemeModeProvider);
  
  // If it's system, we'd need to check the platform brightness
  // For now, we'll return true only if explicitly set to dark
  return themeMode == ThemeMode.dark;
}); 