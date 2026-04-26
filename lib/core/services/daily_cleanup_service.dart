import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service that removes old scheduled activities on app startup.
/// Deletes activities where scheduled_date < today (or scheduled_date is null).
class DailyCleanupService {
  final SupabaseClient _client;

  DailyCleanupService(this._client);

  /// Delete all scheduled_activities where scheduled_date is before today,
  /// or where scheduled_date is null (legacy rows).
  /// Only runs for authenticated users.
  Future<void> cleanupOldActivities() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('DailyCleanupService: No user, skipping cleanup');
        return;
      }

      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      debugPrint('DailyCleanupService: Cleaning up activities before $todayStr for user $userId');

      // Delete rows where scheduled_date < today
      try {
        await _client
            .from('scheduled_activities')
            .delete()
            .eq('user_id', userId)
            .lt('scheduled_date', todayStr);
        debugPrint('DailyCleanupService: Deleted past activities');
      } catch (e) {
        if (e.toString().contains('scheduled_date') || e.toString().contains('column')) {
          debugPrint('DailyCleanupService: scheduled_date column not yet migrated, skipping');
          return;
        }
        rethrow;
      }

      // Delete rows where scheduled_date is null (legacy data)
      try {
        await _client
            .from('scheduled_activities')
            .delete()
            .eq('user_id', userId)
            .isFilter('scheduled_date', null);
      } catch (e) {
        if (e.toString().contains('scheduled_date') || e.toString().contains('column')) {
          return;
        }
        debugPrint('DailyCleanupService: Could not delete null scheduled_date rows: $e');
      }

      debugPrint('DailyCleanupService: Cleanup complete');
    } catch (e) {
      debugPrint('DailyCleanupService: Cleanup failed (non-fatal): $e');
      // Non-fatal - app continues, old data may persist until next run
    }
  }
}
