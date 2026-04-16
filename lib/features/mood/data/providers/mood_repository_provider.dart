import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/providers/supabase_provider.dart';
import 'package:wandermood/features/mood/data/repositories/supabase_mood_repository.dart';
import 'package:wandermood/features/mood/domain/repositories/mood_repository.dart';

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseMoodRepository(supabase);
}); 