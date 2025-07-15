import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../application/auth_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

abstract class AuthRepository {
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  });
  
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });
  
  Future<void> signOut();
  
  Future<AuthResult> resetPassword(String email);
  
  User? get currentUser;
  bool get isAuthenticated;
}

class AuthRepositoryImpl implements AuthRepository {
  final _supabase = Supabase.instance.client;
  
  @override
  User? get currentUser => _supabase.auth.currentUser;
  
  @override
  bool get isAuthenticated => currentUser != null;
  
  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'full_name': name,
        },
      );
      
      if (response.user != null) {
        return AuthResult.success(response.user!);
      } else {
        return AuthResult.error('Registration failed. Please try again.');
      }
    } on AuthException catch (e) {
      return AuthResult.error(_handleAuthException(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred: $e');
    }
  }
  
  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        return AuthResult.success(response.user!);
      } else {
        return AuthResult.error('Login failed. Please check your credentials.');
      }
    } on AuthException catch (e) {
      return AuthResult.error(_handleAuthException(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred: $e');
    }
  }
  
  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  @override
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult.success(currentUser!); // Won't be null after reset
    } on AuthException catch (e) {
      return AuthResult.error(_handleAuthException(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred: $e');
    }
  }
  
  /// Handle Supabase auth exceptions with user-friendly messages
  String _handleAuthException(AuthException e) {
    switch (e.message.toLowerCase()) {
      case 'invalid login credentials':
        return 'Invalid email or password. Please try again.';
      case 'email not confirmed':
        return 'Please check your email and click the confirmation link.';
      case 'user already registered':
        return 'An account with this email already exists.';
      case 'password should be at least 6 characters':
        return 'Password must be at least 6 characters long.';
      case 'signup is disabled':
        return 'Account registration is currently disabled.';
      case 'email rate limit exceeded':
        return 'Too many requests. Please wait before trying again.';
      default:
        return e.message;
    }
  }
} 