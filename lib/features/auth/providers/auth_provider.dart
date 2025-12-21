import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Initialize user profile on signup/login
// Note: Profile creation is handled by auth_service.dart and profile_provider.dart
// This provider only listens to auth state changes
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = Supabase.instance.client;
  
  // Listen for auth state changes
  return client.auth.onAuthStateChange;
}); 