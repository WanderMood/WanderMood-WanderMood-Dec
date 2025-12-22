import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider voor de splash service
final splashServiceProvider = Provider<SplashService>((ref) {
  return SplashService(ref);
});

class SplashService {
  final Ref ref;
  
  SplashService(this.ref);
  
  // Constante key voor shared preferences
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';  // Same key as in router

  Future<void> handleSplashNavigation(BuildContext context) async {
    try {
      // Wait for a better splash experience
      await Future.delayed(const Duration(seconds: 2));
      
      if (!context.mounted) return;

      // Check if user has completed onboarding
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('has_completed_preferences') ?? false;
      
      if (hasCompletedOnboarding) {
        // CRITICAL: DO NOT prefetch here - causes infinite API loop
        // Prefetch is handled in main_screen.dart using Edge Function (moodyExploreAutoProvider)
        // The old explorePlacesProvider() was making hundreds of API calls for ALL cities
        debugPrint('🎯 RETURNING USER: Navigating to home (prefetch handled by main_screen)');
        
        // Navigate to home - prefetch will happen in main_screen.dart
        context.go('/home');
      } else {
        // Always show onboarding for better testing or new users
      await resetOnboardingFlag();
      context.go('/onboarding');
      }
    } catch (e) {
      debugPrint('Error during splash navigation: $e');
      if (context.mounted) {
        context.go('/onboarding');  // Default to onboarding screen on error
      }
    }
  }
  
  // Methode om bij te houden dat gebruiker onboarding heeft gezien
  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }

  // Helper method to reset onboarding flag (FOR TESTING ONLY)
  Future<void> resetOnboardingFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenOnboardingKey);
  }
} 