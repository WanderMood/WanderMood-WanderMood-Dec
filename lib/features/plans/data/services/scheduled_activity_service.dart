import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/providers/supabase_provider.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wandermood/features/plans/data/services/schema_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:wandermood/core/services/taste_profile_service.dart';

/// Provider for the ScheduledActivityService
final scheduledActivityServiceProvider = Provider<ScheduledActivityService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final schemaHelper = ref.watch(schemaHelperProvider);
  return ScheduledActivityService(supabaseClient, schemaHelper);
});

/// Service class responsible for managing scheduled activities in Supabase
class ScheduledActivityService {
  final SupabaseClient _client;
  final SchemaHelper _schemaHelper;
  
  // In-memory fallback storage
  static final List<Activity> _inMemoryActivities = [];
  
  ScheduledActivityService(this._client, this._schemaHelper);
  
  /// Save a list of activities to the scheduled_activities table.
  /// Returns how many rows were inserted (0 if all were duplicates or on auth failure in fallback path).
  Future<int> saveScheduledActivities(List<Activity> activities, {bool isConfirmed = false}) async {
    try {
      debugPrint('ScheduledActivityService: saveScheduledActivities called with ${activities.length} activities');
      
      // Require authentication
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to save scheduled activities');
      }
      
      debugPrint('ScheduledActivityService: User ID: $userId');
      final activityData = _prepareActivityData(activities, userId, isConfirmed);
      return await _insertActivities(activityData);
    } catch (e) {
      debugPrint('ScheduledActivityService: Database save failed: $e');
      debugPrint('ScheduledActivityService: Using in-memory fallback storage');
      
      // Fallback to in-memory storage
      _inMemoryActivities.clear();
      _inMemoryActivities.addAll(activities);
      
      debugPrint('ScheduledActivityService: Saved ${activities.length} activities to memory');
      return activities.length;
    }
  }

  /// Which time-of-day slots (`morning` / `afternoon` / `evening`) already have this [placeId] on [date].
  Future<Set<String>> getOccupiedTimeSlotKeysForPlaceOnDate({
    required String placeId,
    required DateTime date,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final targetDate = DateTime(date.year, date.month, date.day);
    final dateStr =
        '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    try {
      final response = await _client
          .from('scheduled_activities')
          .select('start_time')
          .eq('user_id', userId)
          .eq('place_id', placeId)
          .eq('scheduled_date', dateStr);

      final out = <String>{};
      for (final row in response as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final st = map['start_time'] as String?;
        if (st == null) continue;
        final hour = DateTime.parse(st).hour;
        out.add(_timeSlotKeyFromHour(hour));
      }
      return out;
    } catch (e) {
      debugPrint('ScheduledActivityService: getOccupiedTimeSlotKeysForPlaceOnDate failed: $e');
      return {};
    }
  }

  static String _timeSlotKeyFromHour(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    return 'evening';
  }
  
  /// Clear all scheduled activities for the current user (used when generating new mood-based plans)
  Future<void> clearAllScheduledActivities() async {
    try {
      // Require authentication
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to clear scheduled activities');
      }
      
      debugPrint('🧹 Clearing all scheduled activities for user $userId');
      
      await _client
          .from('scheduled_activities')
          .delete()
          .eq('user_id', userId);
      
      debugPrint('✅ Successfully cleared all scheduled activities');
      
      _inMemoryActivities.clear();
      debugPrint('✅ Cleared in-memory fallback storage');
      
    } catch (e) {
      debugPrint('❌ Error clearing scheduled activities: $e');
      _inMemoryActivities.clear();
      debugPrint('✅ Cleared in-memory fallback storage (database failed)');
      rethrow;
    }
  }
  
  // Helper to prepare activity data for insertion
  List<Map<String, dynamic>> _prepareActivityData(List<Activity> activities, String userId, bool isConfirmed) {
    return activities.map((activity) {
      // Derive scheduled_date from activity's startTime (date-only, YYYY-MM-DD)
      final scheduledDate = '${activity.startTime.year}-${activity.startTime.month.toString().padLeft(2, '0')}-${activity.startTime.day.toString().padLeft(2, '0')}';
      return {
        'user_id': userId,
        'activity_id': activity.id,
        'name': activity.name,
        'description': activity.description,
        'image_url': activity.imageUrl,
        'start_time': activity.startTime.toIso8601String(),
        'duration': activity.duration,
        'location_name': activity.location.toString(),
        'latitude': activity.location.latitude,
        'longitude': activity.location.longitude,
        'is_confirmed': isConfirmed,
        'tags': activity.tags.join(','),
        'payment_type': activity.paymentType.toString().split('.').last,
        'place_id': activity.placeId,
        'rating': activity.rating,
        'scheduled_date': scheduledDate,
        'created_at': DateTime.now().toIso8601String(),
      };
    }).toList();
  }
  
  // Helper to insert activities with duplicate checking
  Future<int> _insertActivities(List<Map<String, dynamic>> activityData) async {
    try {
      debugPrint('ScheduledActivityService: Inserting ${activityData.length} activities');
      
      // Require authentication
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to save scheduled activities');
      }
      
      // Filter out duplicates before inserting
      final filteredActivities = <Map<String, dynamic>>[];
      
      for (final activity in activityData) {
        // Check if an activity with the same name, start_time, and location already exists
        final existingActivity = await _client
            .from('scheduled_activities')
            .select()
            .eq('user_id', userId)
            .eq('name', activity['name'] as String)
            .eq('start_time', activity['start_time'] as String)
            .eq('latitude', activity['latitude'] as double)
            .eq('longitude', activity['longitude'] as double)
            .maybeSingle();
        
        if (existingActivity != null) {
          debugPrint('ScheduledActivityService: Duplicate activity "${activity['name']}" found, skipping insert');
          continue;
        }

        final placeId = activity['place_id'] as String?;
        final scheduledDate = activity['scheduled_date'] as String?;
        if (placeId != null && placeId.isNotEmpty && scheduledDate != null) {
          final newStart = DateTime.parse(activity['start_time'] as String);
          final newSlot = _timeSlotKeyFromHour(newStart.hour);
          final samePlaceRows = await _client
              .from('scheduled_activities')
              .select('start_time')
              .eq('user_id', userId)
              .eq('place_id', placeId)
              .eq('scheduled_date', scheduledDate);
          var slotTaken = false;
          for (final row in samePlaceRows as List) {
            final map = Map<String, dynamic>.from(row as Map);
            final st = map['start_time'] as String?;
            if (st == null) continue;
            if (_timeSlotKeyFromHour(DateTime.parse(st).hour) == newSlot) {
              slotTaken = true;
              break;
            }
          }
          if (slotTaken) {
            debugPrint(
                'ScheduledActivityService: Same place+date+slot for "${activity['name']}", skipping');
            continue;
          }
        }

        filteredActivities.add(activity);
        debugPrint('ScheduledActivityService: Activity "${activity['name']}" is new, will be inserted');
      }
      
      if (filteredActivities.isEmpty) {
        debugPrint('ScheduledActivityService: All activities are duplicates, nothing to insert');
        return 0;
      }
      
      debugPrint('ScheduledActivityService: Inserting ${filteredActivities.length} new activities (${activityData.length - filteredActivities.length} duplicates skipped)');
      
      // Mark that user has completed their first plan
      if (filteredActivities.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final hasCompletedFirstPlan = prefs.getBool('has_completed_first_plan') ?? false;
          if (!hasCompletedFirstPlan) {
            await prefs.setBool('has_completed_first_plan', true);
            if (kDebugMode) {
              debugPrint('🎉 First plan completed! User has created their first day plan.');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to set first plan flag: $e');
          }
        }
      }
      
      await _client.from('scheduled_activities').insert(filteredActivities);
      debugPrint('ScheduledActivityService: Activities inserted successfully');
      for (final row in filteredActivities) {
        final pid = row['place_id'] as String?;
        if (pid == null || pid.isEmpty) continue;
        final start = DateTime.parse(row['start_time'] as String);
        TasteProfileService.recordFromActivityRaw(
          row,
          interactionType: 'added_to_day',
          timeSlot: _timeSlotKeyFromHour(start.hour),
        );
      }
      return filteredActivities.length;
    } catch (e) {
      debugPrint('ScheduledActivityService: Failed to save activities to Supabase: $e');
      
      // Try to create the table if it doesn't exist
      if (e.toString().contains('does not exist') || e.toString().contains('relation') || e.toString().contains('42P01')) {
        debugPrint('ScheduledActivityService: Table may not exist, attempting to create it...');
        try {
          await _schemaHelper.createScheduledActivitiesTable();
          debugPrint('ScheduledActivityService: Table created successfully, retrying insert');
          return await _insertActivities(activityData);
        } catch (tableError) {
          debugPrint('ScheduledActivityService: Failed to create table: $tableError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  Activity _rowToActivity(Map<String, dynamic> json) {
    debugPrint('ScheduledActivityService: Processing activity: ${json['name']}');

    final tagsRaw = json['tags'];
    final tags = tagsRaw is String && tagsRaw.isNotEmpty
        ? tagsRaw.split(',').where((s) => s.isNotEmpty).toList()
        : <String>['activity'];

    final lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    final location = LatLng(lat, lng);

    final paymentTypeStr = json['payment_type'] as String? ?? 'free';
    final paymentType = PaymentType.values.firstWhere(
      (e) => e.toString().split('.').last == paymentTypeStr,
      orElse: () => PaymentType.free,
    );

    final startTime = DateTime.parse(json['start_time'] as String);
    final hour = startTime.hour;
    TimeSlot timeSlotEnum;
    String timeSlot;

    if (hour >= 5 && hour < 12) {
      timeSlotEnum = TimeSlot.morning;
      timeSlot = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeSlotEnum = TimeSlot.afternoon;
      timeSlot = 'afternoon';
    } else {
      timeSlotEnum = TimeSlot.evening;
      timeSlot = 'evening';
    }

    return Activity(
      id: (json['activity_id'] as String?) ??
          'row_${json['start_time']}_${json['name']}',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      startTime: startTime,
      duration: json['duration'] as int? ?? 60,
      timeSlot: timeSlot,
      timeSlotEnum: timeSlotEnum,
      tags: tags,
      location: location,
      paymentType: paymentType,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      isPaid: paymentType != PaymentType.free,
      placeId: json['place_id'] as String?,
      groupSessionId: json['group_session_id'] as String?,
    );
  }
  
  /// Get all scheduled activities for the current user (today only, filtered by scheduled_date)
  Future<List<Activity>> getScheduledActivities() async {
    return getScheduledActivitiesForDate(DateTime.now());
  }

  /// Get scheduled activities for a specific date (filtered by scheduled_date).
  Future<List<Activity>> getScheduledActivitiesForDate(DateTime date) async {
    try {
      // Require authentication
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to view scheduled activities');
      }
      
      final targetDate = DateTime(date.year, date.month, date.day);
      final targetDateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
      
      debugPrint('ScheduledActivityService: Getting activities for user $userId (scheduled_date=$targetDateStr)');
      
      // Query only selected date activities (scheduled_date = selected date)
      // Fallback: if column doesn't exist yet, fetch all and filter by startTime in Dart
      List<dynamic> response;
      try {
        response = await _client
            .from('scheduled_activities')
            .select()
            .eq('user_id', userId)
            .eq('scheduled_date', targetDateStr)
            .order('start_time', ascending: true);
      } catch (columnError) {
        if (columnError.toString().contains('scheduled_date') || columnError.toString().contains('column')) {
          debugPrint('ScheduledActivityService: scheduled_date column missing, falling back to startTime filter');
          final all = await _client
              .from('scheduled_activities')
              .select()
              .eq('user_id', userId)
              .order('start_time', ascending: true);
          response = (all as List).where((r) {
            final st = r['start_time'] as String?;
            if (st == null) return false;
            final dt = DateTime.parse(st);
            return dt.year == targetDate.year &&
                dt.month == targetDate.month &&
                dt.day == targetDate.day;
          }).toList();
        } else {
          rethrow;
        }
      }
      
      debugPrint('ScheduledActivityService: Raw response length: ${response.length}');
      
      final activities = response
          .map((row) => _rowToActivity(Map<String, dynamic>.from(row as Map)))
          .toList();
      
      debugPrint('ScheduledActivityService: Returning ${activities.length} activities');
      return activities;
    } catch (e) {
      debugPrint('ScheduledActivityService: Database query failed: $e');
      debugPrint('ScheduledActivityService: Using in-memory fallback storage');
      
      // Return in-memory activities as fallback
      final activities = _inMemoryActivities.where((activity) {
        // Filter activities for selected date
        final targetDate = DateTime(date.year, date.month, date.day);
        final activityDate = activity.startTime;
        return activityDate.year == targetDate.year &&
               activityDate.month == targetDate.month &&
               activityDate.day == targetDate.day;
      }).toList();
      
      debugPrint('ScheduledActivityService: Returning ${activities.length} activities from memory');
      return activities;
    }
  }

  /// All rows in [scheduled_activities] for the user (for Agenda and merged activity feeds).
  Future<List<Activity>> getAllScheduledActivitiesForUser() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to view scheduled activities');
      }

      final response = await _client
          .from('scheduled_activities')
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: true);

      return response
          .map((row) => _rowToActivity(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      debugPrint('ScheduledActivityService: getAllScheduledActivitiesForUser failed: $e');
      return List<Activity>.from(_inMemoryActivities);
    }
  }
  
  /// Update the confirmation status of an activity
  Future<void> updateActivityConfirmation(String activityId, bool isConfirmed) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      await _client
          .from('scheduled_activities')
          .update({'is_confirmed': isConfirmed})
          .eq('user_id', userId)
          .eq('activity_id', activityId);
    } catch (e) {
      debugPrint('Error updating activity confirmation: $e');
      rethrow;
    }
  }
  
  /// Delete a scheduled activity
  Future<void> deleteScheduledActivity(String activityId) async {
    try {
      // Require authentication
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to delete scheduled activities');
      }
      
      debugPrint('ScheduledActivityService: Deleting activity $activityId for user $userId');
      
      await _client
          .from('scheduled_activities')
          .delete()
          .eq('user_id', userId)
          .eq('activity_id', activityId);
      
      debugPrint('ScheduledActivityService: Activity deleted successfully');
    } catch (e) {
      debugPrint('ScheduledActivityService: Error deleting scheduled activity: $e');
      rethrow;
    }
  }
  
  /// Update a scheduled activity
  Future<void> updateScheduledActivity(String activityId, Map<String, dynamic> updates) async {
    try {
      // Require authentication
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to update scheduled activities');
      }
      
      debugPrint('ScheduledActivityService: Updating activity $activityId for user $userId');
      
      await _client
          .from('scheduled_activities')
          .update(updates)
          .eq('user_id', userId)
          .eq('activity_id', activityId);
      
      debugPrint('ScheduledActivityService: Activity updated successfully');
    } catch (e) {
      debugPrint('ScheduledActivityService: Error updating scheduled activity: $e');
      rethrow;
    }
  }
} 