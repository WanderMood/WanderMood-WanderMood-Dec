import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final socialAuthServiceProvider = Provider((ref) => SocialAuthService());

class SocialAuthService {
  final _supabase = Supabase.instance.client;
  final _googleSignIn = GoogleSignIn();

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Check if Google Sign-In is available
      if (!await _googleSignIn.isSignedIn()) {
        print('🔍 Google Sign-In: Starting sign-in process...');
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ Google Sign-In: User cancelled sign-in');
        return null;
      }

      print('✅ Google Sign-In: User selected, getting authentication...');
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        print('❌ Google Sign-In: No access token received');
        return null;
      }

      print('🔐 Google Sign-In: Authenticating with Supabase...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken!,
        accessToken: accessToken,
      );

      print('✅ Google Sign-In: Successfully authenticated with Supabase');
      return response;
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      // Handle specific Google Sign-In errors
      if (e.toString().contains('sign_in_failed') || 
          e.toString().contains('GoogleService-Info.plist')) {
        throw Exception('Google Sign-In not configured. Please add GoogleService-Info.plist to your iOS project.');
      } else if (e.toString().contains('network_error')) {
        throw Exception('Network error. Please check your internet connection.');
      } else if (e.toString().contains('sign_in_canceled')) {
        throw Exception('Sign-in cancelled by user.');
      } else {
        throw Exception('Google Sign-In failed: ${e.toString()}');
      }
    }
  }

  Future<AuthResponse?> signInWithFacebook() async {
    try {
      print('🔍 Facebook Sign-In: Starting sign-in process...');
      final result = await FacebookAuth.instance.login();
      
      if (result.status != LoginStatus.success) {
        print('❌ Facebook Sign-In: ${result.status} - ${result.message}');
        if (result.status == LoginStatus.cancelled) {
          throw Exception('Facebook sign-in cancelled by user.');
        }
        return null;
      }

      final accessToken = result.accessToken?.toJson()['token'] as String?;
      if (accessToken == null) {
        print('❌ Facebook Sign-In: No access token received');
        return null;
      }

      print('🔐 Facebook Sign-In: Authenticating with Supabase...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: accessToken,
      );

      print('✅ Facebook Sign-In: Successfully authenticated with Supabase');
      return response;
    } catch (e) {
      print('❌ Facebook Sign-In Error: $e');
      if (e.toString().contains('not configured') || 
          e.toString().contains('Invalid key hash')) {
        throw Exception('Facebook Sign-In not configured. Please add Facebook App ID to your iOS project.');
      } else if (e.toString().contains('network_error')) {
        throw Exception('Network error. Please check your internet connection.');
      } else {
        throw Exception('Facebook Sign-In failed: ${e.toString()}');
      }
    }
  }

  Future<AuthResponse?> signInWithApple() async {
    try {
      print('🔍 Apple Sign-In: Starting sign-in process...');
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        print('❌ Apple Sign-In: No identity token received');
        return null;
      }

      print('🔐 Apple Sign-In: Authenticating with Supabase...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
      );

      print('✅ Apple Sign-In: Successfully authenticated with Supabase');
      return response;
    } catch (e) {
      print('❌ Apple Sign-In Error: $e');
      if (e.toString().contains('not configured') || 
          e.toString().contains('not available')) {
        throw Exception('Apple Sign-In not configured. Please enable Sign in with Apple in your iOS project.');
      } else if (e.toString().contains('canceled')) {
        throw Exception('Apple Sign-In cancelled by user.');
      } else {
        throw Exception('Apple Sign-In failed: ${e.toString()}');
      }
    }
  }
} 