import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper utilities for authentication and session management
class AuthHelper {
  /// Ensures the Supabase session is valid before making Edge Function calls
  /// 
  /// CRITICAL: Does NOT call refreshSession() to avoid rate limiting
  /// Supabase Flutter automatically refreshes tokens in the background.
  /// This method only validates that a session exists.
  /// 
  /// Call this before any Edge Function invocation to prevent auth errors.
  static Future<void> ensureValidSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;
      
      // If no session or user, throw error
      if (session == null || user == null) {
        throw Exception('User not authenticated. Please sign in again.');
      }
      
      // CRITICAL: Don't call refreshSession() here to avoid rate limiting
      // Supabase Flutter automatically refreshes tokens in the background
      // We just validate that a session exists
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeUntilExpiry = expiresAt - now;
        
        if (kDebugMode) {
          debugPrint('✅ Session valid (expires in ${timeUntilExpiry}s)');
        }
        
        // If session is already expired, throw error
        if (timeUntilExpiry < 0) {
          throw Exception('Session expired. Please sign in again.');
        }
      } else {
        if (kDebugMode) {
          debugPrint('✅ Session exists (no expiry info)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error ensuring valid session: $e');
      }
      rethrow;
    }
  }
  
  /// Checks if user is authenticated (has valid session)
  static bool isAuthenticated() {
    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;
    return session != null && user != null;
  }
  
  /// Gets the current user ID, throws if not authenticated
  static String getCurrentUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.id;
  }
}

