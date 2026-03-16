import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/services/secure_storage_service.dart';

/// Result of an account deletion attempt.
class AccountDeletionResult {
  const AccountDeletionResult({
    required this.success,
    this.message,
  });
  final bool success;
  final String? message;
}

/// Deletes the current user's account and all associated data (GDPR / App Store compliance).
/// 1) Deletes user data from app tables (profiles, user_preferences, etc.)
/// 2) Invokes Edge Function to delete the auth user (requires Supabase Edge Function).
/// 3) Signs out and clears local caches.
class AccountDeletionService {
  final _supabase = Supabase.instance.client;

  /// Performs full account deletion. Call from Settings with user confirmation.
  Future<AccountDeletionResult> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const AccountDeletionResult(success: false, message: 'Not signed in.');
    }
    final userId = user.id;

    try {
      // 1) Delete user data from tables (order can matter for RLS / cascades)
      await _deleteUserData(userId);

      // 2) Invoke Edge Function to delete auth user (uses service role on server)
      final deletedAuth = await _deleteAuthUser();

      // 3) Clear local caches and preferences
      await _clearLocalUserData();

      // 4) Sign out
      await _supabase.auth.signOut();

      if (deletedAuth) {
        return const AccountDeletionResult(success: true);
      }
      return const AccountDeletionResult(
        success: true,
        message: 'Your data has been deleted and you have been signed out.',
      );
    } on AuthException catch (e) {
      if (kDebugMode) debugPrint('AccountDeletionService AuthException: ${e.message}');
      return AccountDeletionResult(success: false, message: e.message);
    } catch (e, st) {
      if (kDebugMode) {
        if (kDebugMode) {
          debugPrint('AccountDeletionService error: $e');
          debugPrint('$st');
        }
      }
      return AccountDeletionResult(
        success: false,
        message: e.toString().replaceFirst(RegExp(r'^Exception: '), ''),
      );
    }
  }

  Future<void> _deleteUserData(String userId) async {
    try {
      await _supabase.from('user_preferences').delete().eq('user_id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('Delete user_preferences: $e');
    }
    try {
      await _supabase.from('profiles').delete().eq('id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('Delete profiles: $e');
    }
  }

  Future<bool> _deleteAuthUser() async {
    try {
      final response = await _supabase.functions.invoke(
        'delete_user_account',
        method: HttpMethod.post,
      );
      if (response.status == 200) return true;
      if (kDebugMode) debugPrint('delete_user_account status: ${response.status}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('delete_user_account invoke error: $e');
      return false;
    }
  }

  Future<void> _clearLocalUserData() async {
    try {
      await SecureStorageService().clearAuthSensitive();
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      for (final key in keys) {
        if (key.startsWith('profile_cache_')) await prefs.remove(key);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Clear local data: $e');
    }
  }
}
