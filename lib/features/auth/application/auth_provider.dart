import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/user_profile.dart';
import '../repositories/profile_repository.dart';
import '../repositories/auth_repository.dart';

// ============================================================================
// CORE AUTH STATE PROVIDERS
// ============================================================================

/// Current Supabase auth user
final authUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((event) => event.session?.user);
});

/// Current user profile (with caching)
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authUserProvider).valueOrNull;
  if (user == null) return null;
  
  final profileRepo = ref.read(profileRepositoryProvider);
  return await profileRepo.getCurrentUserProfile();
});

/// Auth loading state
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Auth error state
final authErrorProvider = StateProvider<String?>((ref) => null);

// ============================================================================
// AUTH ACTIONS PROVIDER
// ============================================================================

final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref);
});

class AuthActions {
  final Ref ref;
  
  AuthActions(this.ref);
  
  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    ref.read(authLoadingProvider.notifier).state = true;
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.signUp(
        email: email,
        password: password,
        name: name,
      );
      
      if (result.isSuccess) {
        // Trigger profile fetch
        ref.invalidate(currentUserProfileProvider);
      } else {
        ref.read(authErrorProvider.notifier).state = result.error;
      }
      
      return result;
    } catch (e) {
      final error = 'Unexpected error: $e';
      ref.read(authErrorProvider.notifier).state = error;
      return AuthResult.error(error);
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }
  
  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    ref.read(authLoadingProvider.notifier).state = true;
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.signIn(
        email: email,
        password: password,
      );
      
      if (result.isSuccess) {
        // Trigger profile fetch and cache warming
        ref.invalidate(currentUserProfileProvider);
        _warmUserCache();
      } else {
        ref.read(authErrorProvider.notifier).state = result.error;
      }
      
      return result;
    } catch (e) {
      final error = 'Unexpected error: $e';
      ref.read(authErrorProvider.notifier).state = error;
      return AuthResult.error(error);
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    ref.read(authLoadingProvider.notifier).state = true;
    
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
      
      // Clear all cached data
      ref.invalidate(currentUserProfileProvider);
      ref.read(profileRepositoryProvider).clearCache();
      
      // Clear error state
      ref.read(authErrorProvider.notifier).state = null;
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = 'Sign out failed: $e';
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }
  
  /// Reset password
  Future<AuthResult> resetPassword(String email) async {
    ref.read(authLoadingProvider.notifier).state = true;
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.resetPassword(email);
      
      if (!result.isSuccess) {
        ref.read(authErrorProvider.notifier).state = result.error;
      }
      
      return result;
    } catch (e) {
      final error = 'Unexpected error: $e';
      ref.read(authErrorProvider.notifier).state = error;
      return AuthResult.error(error);
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }
  
  /// Update current user profile
  Future<bool> updateProfile(UserProfile profile) async {
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final success = await profileRepo.updateProfile(profile);
      
      if (success) {
        // Refresh the profile in cache
        ref.invalidate(currentUserProfileProvider);
      }
      
      return success;
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = 'Update failed: $e';
      return false;
    }
  }
  
  /// Upload profile avatar
  Future<String?> uploadAvatar(String filePath) async {
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      return await profileRepo.uploadAvatar(filePath);
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = 'Upload failed: $e';
      return null;
    }
  }
  
  /// Clear auth error
  void clearError() {
    ref.read(authErrorProvider.notifier).state = null;
  }
  
  /// Warm up user cache after login
  Future<void> _warmUserCache() async {
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      // Preload user data in background
      await profileRepo.warmCache();
    } catch (e) {
      // Silent fail - cache warming is not critical
      if (kDebugMode) debugPrint('Cache warming failed: $e');
    }
  }
}

// ============================================================================
// AUTH RESULT MODEL
// ============================================================================

class AuthResult {
  final bool isSuccess;
  final String? error;
  final User? user;
  
  AuthResult._({
    required this.isSuccess,
    this.error,
    this.user,
  });
  
  factory AuthResult.success(User user) {
    return AuthResult._(
      isSuccess: true,
      user: user,
    );
  }
  
  factory AuthResult.error(String error) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}

// ============================================================================
// COMPUTED PROVIDERS (CONVENIENCE)
// ============================================================================

/// Whether user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(authUserProvider).valueOrNull;
  return user != null;
});

/// Whether user has completed profile setup
final isProfileCompleteProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.when(
    data: (profile) => profile?.bio?.isNotEmpty == true,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Current user display name
final userDisplayNameProvider = Provider<String>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.when(
    data: (profile) => profile?.displayName ?? 'User',
    loading: () => 'Loading...',
    error: (_, __) => 'User',
  );
});

/// Whether user is a new user (for onboarding)
final isNewUserProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.when(
    data: (profile) => profile?.isNewUser ?? true,
    loading: () => false,
    error: (_, __) => false,
  );
}); 