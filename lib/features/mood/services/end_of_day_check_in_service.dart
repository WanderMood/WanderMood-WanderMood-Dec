import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:uuid/uuid.dart';

/// Supabase helpers for the Moody Hub end-of-day reflection (metadata `type: end_of_day`).
class EndOfDayCheckInService {
  EndOfDayCheckInService._();

  static const _uuid = Uuid();

  /// Local calendar date `YYYY-MM-DD`.
  static String todayDateString([DateTime? now]) {
    final n = now ?? MoodyClock.now();
    final y = n.year.toString().padLeft(4, '0');
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Names of today's [scheduled_activities] rows with `metadata.status == 'done'`.
  static Future<List<String>> fetchDoneActivityNamesToday(
      SupabaseClient client) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final today = todayDateString();
    try {
      final rows = await client
          .from('scheduled_activities')
          .select('name, metadata')
          .eq('user_id', userId)
          .eq('scheduled_date', today) as List<dynamic>;

      final names = <String>[];
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        final meta = row['metadata'];
        String? status;
        if (meta is Map) {
          status = meta['status'] as String?;
        }
        if (status != 'done') continue;
        final n = row['name'] as String?;
        if (n != null && n.trim().isNotEmpty) {
          names.add(n.trim());
        }
      }
      return names;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('⚠️ EndOfDayCheckInService.fetchDoneActivityNamesToday: $e\n$st');
      }
      return [];
    }
  }

  /// True if a row exists for this user with `metadata.type == end_of_day` and matching `date`.
  static Future<bool> hasCompletedEndOfDayToday(SupabaseClient client) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return true;

    final today = todayDateString();
    try {
      final rows = await client
          .from('user_check_ins')
          .select('metadata')
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(40);

      if (rows.isEmpty) return false;

      for (final row in rows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final meta = map['metadata'];
        if (meta is Map<String, dynamic>) {
          if (meta['type'] == 'end_of_day' && meta['date'] == today) {
            return true;
          }
        }
      }
      return false;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ EndOfDayCheckInService.hasCompletedEndOfDayToday: $e\n$st');
      }
      return true;
    }
  }

  /// Persists `user_check_ins` row for end-of-day flows.
  ///
  /// Canonical metadata: [dayRating], [highlight], optional [closingMessage].
  /// Optional [reflectionText] is stored in the `text` column (user’s own words).
  /// Also writes `best_moment` / `activity_rating` as aliases of
  /// [highlight] / [dayRating] so older readers keep working.
  static Future<void> submit({
    required SupabaseClient client,
    required String userId,
    required String mood,
    required List<String> completedActivityNames,
    required List<String> reactions,
    required String dateYyyyMmDd,
    required String dayRating,
    required String highlight,
    String? closingMessage,
    String? endMoodLabel,
    String? reflectionText,
  }) async {
    final trimmedNote = reflectionText?.trim();
    final meta = <String, dynamic>{
      'type': 'end_of_day',
      'date': dateYyyyMmDd,
      'day_rating': dayRating,
      'highlight': highlight,
      'best_moment': highlight,
      'activity_rating': dayRating,
      if (closingMessage != null && closingMessage.trim().isNotEmpty)
        'closing_message': closingMessage.trim(),
      if (endMoodLabel != null && endMoodLabel.trim().isNotEmpty)
        'end_mood': endMoodLabel.trim(),
    };

    try {
      await client.from('user_check_ins').insert({
        'id': _uuid.v4(),
        'user_id': userId,
        'mood': mood,
        'text': (trimmedNote != null && trimmedNote.isNotEmpty)
            ? trimmedNote
            : null,
        'activities': completedActivityNames,
        'reactions': reactions,
        'timestamp': MoodyClock.now().toIso8601String(),
        'metadata': meta,
      });
    } on PostgrestException catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'EndOfDayCheckInService.submit PostgrestException: ${e.message} '
          '(code=${e.code}) details=${e.details}\n$st',
        );
      }
      rethrow;
    }
  }
}
