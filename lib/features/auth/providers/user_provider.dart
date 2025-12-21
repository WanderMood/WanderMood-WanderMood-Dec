import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Current user provider
final userProvider = StreamProvider<User?>((ref) {
  final client = Supabase.instance.client;
  return client.auth.onAuthStateChange.map((data) => data.session?.user);
});

// User data provider (including metadata)
final userDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(userProvider).valueOrNull;
  if (user == null) return null;
  
  final client = Supabase.instance.client;
  try {
    // Get user profile data from Supabase
    final response = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    
    return {
      'id': user.id,
      'email': user.email,
      'name': response['full_name'] ?? user.userMetadata?['name'] ?? 'User',
      'avatarUrl': response['avatar_url'],
      'metadata': user.userMetadata ?? {},
    };
  } catch (e) {
    // If no profile exists yet, return basic user data
    return {
      'id': user.id,
      'email': user.email,
      'name': user.userMetadata?['name'] ?? 'User',
      'metadata': user.userMetadata ?? {},
    };
  }
});

// Note: Profile creation is handled by auth_service.dart and profile_provider.dart
// This provider only provides user data, not profile initialization 