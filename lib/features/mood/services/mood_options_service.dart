import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mood_option.dart';

class MoodOptionsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all mood options
  static Future<List<MoodOption>> getMoodOptions() async {
    try {
      final response = await _supabase
          .from('mood_options')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      if (response.isEmpty) {
        print('⚠️ No mood options found in database');
        return [];
      }

      final moodOptions = (response as List)
          .map((json) => MoodOption.fromJson(json))
          .toList();

      print('✅ Loaded ${moodOptions.length} mood options from database');
      return moodOptions;
    } catch (e, stackTrace) {
      print('❌ Error fetching mood options: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fetch a specific mood option by ID
  static Future<MoodOption?> getMoodOption(String id) async {
    try {
      final response = await _supabase
          .from('mood_options')
          .select()
          .eq('id', id)
          .single();

      return MoodOption.fromJson(response);
    } catch (e) {
      print('❌ Error fetching mood option $id: $e');
      return null;
    }
  }

  /// Get active mood options by display order range
  static Future<List<MoodOption>> getMoodOptionsByDisplayOrder(
    int minOrder,
    int maxOrder,
  ) async {
    try {
      final response = await _supabase
          .from('mood_options')
          .select()
          .eq('is_active', true)
          .gte('display_order', minOrder)
          .lte('display_order', maxOrder)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => MoodOption.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching mood options by display order: $e');
      return [];
    }
  }

  /// Stream of mood options for real-time updates
  static Stream<List<MoodOption>> watchMoodOptions() {
    return _supabase
        .from('mood_options')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('display_order', ascending: true)
        .map((data) => data.map((json) => MoodOption.fromJson(json)).toList());
  }
} 