import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthResult {
  final bool success;
  final String? message;
  final User? user;

  AuthResult({
    required this.success,
    this.message,
    this.user,
  });

  factory AuthResult.success(User user) {
    return AuthResult(
      success: true,
      user: user,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult(
      success: false,
      message: message,
    );
  }
}

class AuthService {
  final _supabase = Supabase.instance.client;

  // Huidige gebruiker ophalen
  User? get currentUser => _supabase.auth.currentUser;
  
  // Controleren of een gebruiker is ingelogd
  bool get isUserLoggedIn => _supabase.auth.currentUser != null;

  // Registreren met email en wachtwoord
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      debugPrint('🔐 Starting signup process for email: $email');
      
      // Step 1: Create user in Supabase auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'full_name': name,
        },
        emailRedirectTo: 'io.supabase.wandermood://auth-callback',
      );
      
      if (response.user == null) {
        debugPrint('❌ Signup failed: No user returned');
        return AuthResult.error('Registratie mislukt, probeer het opnieuw');
      }
      
      final user = response.user!;
      debugPrint('✅ User created in auth.users: ${user.id}');
      
      // Step 2: If we have a session, create the profile immediately
      if (response.session != null) {
        debugPrint('🔄 Session established, creating profile...');
        await _createUserProfile(user, name);
      } else {
        debugPrint('⚠️ No session yet, profile will be created on email confirmation');
      }
      
      return AuthResult.success(user);
      
    } on AuthException catch (e) {
      debugPrint('❌ Auth exception during signup: ${e.message}');
      return _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error during signup: $e');
      return AuthResult.error('Er is een onverwachte fout opgetreden: $e');
    }
  }

  // Helper method to create user profile with proper RLS context
  Future<void> _createUserProfile(User user, String name) async {
    try {
      debugPrint('🔄 Creating profile for user: ${user.id}');
      
      // First check if profile already exists (might have been created by trigger)
      final existingProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      
      if (existingProfile != null) {
        debugPrint('✅ Profile already exists for user: ${user.id} (created by trigger)');
        return;
      }
      
      // Generate unique username
      String username = 'wanderer_${user.id.substring(0, 8)}';
      
      // Check if username already exists and make it unique
      var attempt = 0;
      while (await _usernameExists(username)) {
        attempt++;
        username = 'wanderer_${user.id.substring(0, 8)}_$attempt';
        if (attempt > 10) break; // Safety break
      }
      
      final profileData = {
        'id': user.id,
        'username': username,
        'full_name': name,
        'email': user.email ?? '',
        'bio': 'Hello! I\'m new to WanderMood 👋',
        'currently_exploring': 'Rotterdam, Netherlands',
        'travel_style': 'adventurous',
        'travel_vibes': ['Spontaneous', 'Social', 'Relaxed'],
        'favorite_mood': 'happy',
        'is_public': true,
        'language_preference': 'en',
        'theme_preference': 'system',
        'notification_preferences': {
          'push': true,
          'email': true,
          'travel_tips': true
        },
        'location_sharing': true,
        'mood_sharing': true,
        'mood_streak': 0,
        'total_points': 0,
        'achievements': [],
        'level': 1,
        'followers_count': 0,
        'following_count': 0,
        'posts_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_active_at': DateTime.now().toIso8601String(),
      };
      
      debugPrint('📝 Inserting profile data: $profileData');
      
      await _supabase
          .from('profiles')
          .insert(profileData);
      
      debugPrint('✅ Profile created successfully for user: ${user.id}');
      
    } catch (e) {
      debugPrint('❌ Error creating profile: $e');
      // Check if it's a duplicate key error (profile already exists)
      if (e.toString().contains('duplicate key') || e.toString().contains('already exists')) {
        debugPrint('⚠️ Profile already exists, this is okay');
        return;
      }
      // Don't throw - allow signup to succeed even if profile creation fails
      // Profile can be created later when user signs in
    }
  }

  // Helper method to check if username exists
  Future<bool> _usernameExists(String username) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('⚠️ Error checking username existence: $e');
      return false; // Assume it doesn't exist if we can't check
    }
  }

  // Enhanced sign in that ensures profile exists
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting to sign in with email: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        return AuthResult.error('Inloggen mislukt, probeer het opnieuw');
      }
      
      final user = response.user!;
      debugPrint('Sign in successful for user: ${user.id}');
      
      // Ensure profile exists after successful sign in
      await _ensureProfileExists(user);
      
      return AuthResult.success(user);
      
    } on AuthException catch (e) {
      debugPrint('AuthException during sign in: $e');
      return _handleAuthException(e);
    } catch (e) {
      debugPrint('Exception during sign in: $e');
      return AuthResult.error('Er is een onverwachte fout opgetreden: $e');
    }
  }

  // Helper method to ensure profile exists for existing users
  Future<void> _ensureProfileExists(User user) async {
    try {
      // Check if profile exists
      final existingProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      
      if (existingProfile == null) {
        debugPrint('⚠️ Profile missing for user ${user.id}, creating...');
        // Extract name from user metadata or use default
        final name = user.userMetadata?['name'] ?? 
                    user.userMetadata?['full_name'] ?? 
                    'WanderMood User';
        await _createUserProfile(user, name);
      } else {
        debugPrint('✅ Profile exists for user: ${user.id}');
      }
    } catch (e) {
      debugPrint('⚠️ Error ensuring profile exists: $e');
      // Don't throw - sign in should succeed even if profile check fails
    }
  }

  // Uitloggen
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Wachtwoord vergeten / reset
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.wandermood://reset-callback/',
      );
      
      return AuthResult(
        success: true,
        message: 'Wachtwoord reset link is verzonden naar $email',
      );
    } on AuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return AuthResult.error('Er is een onverwachte fout opgetreden: $e');
    }
  }

  // Helper methode om auth exceptions te verwerken
  AuthResult _handleAuthException(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return AuthResult.error('Ongeldige inloggegevens');
      case 'Email not confirmed':
        return AuthResult.error('Email is nog niet bevestigd');
      case 'User already registered':
        return AuthResult.error('Dit email adres is al geregistreerd');
      case 'Password should be at least 6 characters':
        return AuthResult.error('Wachtwoord moet minimaal 6 tekens bevatten');
      default:
        return AuthResult.error(e.message);
    }
  }
} 