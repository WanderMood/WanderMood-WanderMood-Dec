import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import '../models/mood_option.dart';

class MoodOptionsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // 🚨 ZERO API CALLS: toggle to completely skip Supabase for mood options
  static const bool _enableApiCalls = false;

  /// Offline / empty-DB mood grid (English labels; use [localizedMoodDisplayLabel] in UI).
  static List<MoodOption> fallbackMoodOptions() {
    final now = MoodyClock.now();
    return [
      MoodOption(
        id: 'happy',
        label: 'Happy',
        emoji: '😊',
        colorHex: '#FCDF7E',
        displayOrder: 1,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      MoodOption(
        id: 'adventurous',
        label: 'Adventurous',
        emoji: '🚀',
        colorHex: '#F79F9C',
        displayOrder: 2,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      MoodOption(
        id: 'relaxed',
        label: 'Relaxed',
        emoji: '😌',
        colorHex: '#72DED5',
        displayOrder: 3,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      MoodOption(
        id: 'energetic',
        label: 'Energetic',
        emoji: '⚡',
        colorHex: '#84C8F0',
        displayOrder: 4,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      MoodOption(
        id: 'romantic',
        label: 'Romantic',
        emoji: '💕',
        colorHex: '#F4A9D3',
        displayOrder: 5,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      MoodOption(
        id: 'social',
        label: 'Social',
        emoji: '👥',
        colorHex: '#ECCBA3',
        displayOrder: 6,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      MoodOption(
        id: 'cultural',
        label: 'Cultural',
        emoji: '🎭',
        colorHex: '#BFA8E0',
        displayOrder: 7,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      MoodOption(
        id: 'curious',
        label: 'Curious',
        emoji: '🔍',
        colorHex: '#EFB887',
        displayOrder: 8,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      MoodOption(
        id: 'cozy',
        label: 'Cozy',
        emoji: '☕',
        colorHex: '#D2A08B',
        displayOrder: 9,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      MoodOption(
        id: 'excited',
        label: 'Excited',
        emoji: '🤩',
        colorHex: '#A3E0A3',
        displayOrder: 10,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      MoodOption(
        id: 'foody',
        label: 'Foody',
        emoji: '🍽️',
        colorHex: '#FFD3A3',
        displayOrder: 11,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      MoodOption(
        id: 'surprise',
        label: 'Surprise',
        emoji: '😲',
        colorHex: '#C0D3E0',
        displayOrder: 12,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Fetch all mood options
  static Future<List<MoodOption>> getMoodOptions() async {
    if (!_enableApiCalls) {
      return fallbackMoodOptions();
    }

    try {
      final response = await _supabase
          .from('mood_options')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      if (response.isEmpty) {
        return fallbackMoodOptions();
      }

      final moodOptions = (response as List)
          .map((json) => MoodOption.fromJson(json))
          .toList();

      return moodOptions;
    } catch (_) {
      return fallbackMoodOptions();
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