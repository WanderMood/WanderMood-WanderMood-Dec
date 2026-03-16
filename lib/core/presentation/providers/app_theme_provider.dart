import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';

/// Provider that determines the app's theme mode based on user profile preferences
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  final profileAsync = ref.watch(profileProvider);
  
  return profileAsync.when(
    data: (profile) {
      final themePreference = profile?.themePreference ?? 'system';
      if (kDebugMode) debugPrint('Theme Provider: preference: $themePreference');
      
      switch (themePreference.toLowerCase()) {
        case 'light':
          if (kDebugMode) debugPrint('Theme Provider: ThemeMode.light');
          return ThemeMode.light;
        case 'dark':
          if (kDebugMode) debugPrint('Theme Provider: ThemeMode.dark');
          return ThemeMode.dark;
        case 'system':
        default:
          if (kDebugMode) debugPrint('Theme Provider: ThemeMode.system');
          return ThemeMode.system;
      }
    },
    loading: () {
      if (kDebugMode) debugPrint('Theme Provider: loading');
      return ThemeMode.system;
    },
    error: (error, _) {
      if (kDebugMode) debugPrint('Theme Provider: error: $error');
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