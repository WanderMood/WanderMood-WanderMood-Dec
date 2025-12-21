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
  
  /// Save a list of activities to the scheduled_activities table
  Future<void> saveScheduledActivities(List<Activity> activities, {bool isConfirmed = false}) async {
    try {
      print('ScheduledActivityService: saveScheduledActivities called with ${activities.length} activities');
      
      // Require authentication
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to save scheduled activities');
      }
      
      print('ScheduledActivityService: User ID: $userId');
      final activityData = _prepareActivityData(activities, userId, isConfirmed);
      await _insertActivities(activityData);
    } catch (e) {
      print('ScheduledActivityService: Database save failed: $e');
      print('ScheduledActivityService: Using in-memory fallback storage');
      
      // Fallback to in-memory storage
      _inMemoryActivities.clear();
      _inMemoryActivities.addAll(activities);
      
      print('ScheduledActivityService: Saved ${activities.length} activities to memory');
      // Don't rethrow - we have a fallback solution
    }
  }
  
  /// Clear all scheduled activities for the current user (used when generating new mood-based plans)
  Future<void> clearAllScheduledActivities() async {
    try {
      // Require authentication
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to clear scheduled activities');
      }
      
      print('🧹 Clearing all scheduled activities for user $userId');
      
      await _client
          .from('scheduled_activities')
          .delete()
          .eq('user_id', userId);
      
      print('✅ Successfully cleared all scheduled activities');
      
      // Also clear in-memory fallback storage
      _inMemoryActivities.clear();
      print('✅ Cleared in-memory fallback storage');
      
    } catch (e) {
      print('❌ Error clearing scheduled activities: $e');
      // Clear in-memory fallback even if database fails
      _inMemoryActivities.clear();
      print('✅ Cleared in-memory fallback storage (database failed)');
      rethrow;
    }
  }
  
  // Helper to prepare activity data for insertion
  List<Map<String, dynamic>> _prepareActivityData(List<Activity> activities, String userId, bool isConfirmed) {
    return activities.map((activity) {
      // Create a simplified map for the database
      return {
        'user_id': userId,
        'activity_id': activity.id,
        'name': activity.name,
        'description': activity.description,
        'image_url': activity.imageUrl,
        'start_time': activity.startTime.toIso8601String(),
        'duration': activity.duration,
        'location_name': activity.location.toString(), // Simplified for now
        'latitude': activity.location.latitude,
        'longitude': activity.location.longitude,
        'is_confirmed': isConfirmed,
        'tags': activity.tags.join(','),
        'payment_type': activity.paymentType.toString().split('.').last,
        'created_at': DateTime.now().toIso8601String(),
      };
    }).toList();
  }
  
  // Helper to insert activities with duplicate checking
  Future<void> _insertActivities(List<Map<String, dynamic>> activityData) async {
    try {
      print('ScheduledActivityService: Inserting ${activityData.length} activities');
      
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
        
        if (existingActivity == null) {
          // No duplicate found, add to insert list
          filteredActivities.add(activity);
          print('ScheduledActivityService: Activity "${activity['name']}" is new, will be inserted');
        } else {
          print('ScheduledActivityService: Duplicate activity "${activity['name']}" found, skipping insert');
          print('   Existing: ${existingActivity['activity_id']}, New: ${activity['activity_id']}');
        }
      }
      
      if (filteredActivities.isEmpty) {
        print('ScheduledActivityService: All activities are duplicates, nothing to insert');
        return;
      }
      
      print('ScheduledActivityService: Inserting ${filteredActivities.length} new activities (${activityData.length - filteredActivities.length} duplicates skipped)');
      
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
      print('ScheduledActivityService: Activities inserted successfully');
    } catch (e) {
      print('ScheduledActivityService: Failed to save activities to Supabase: $e');
      
      // Try to create the table if it doesn't exist
      if (e.toString().contains('does not exist') || e.toString().contains('relation') || e.toString().contains('42P01')) {
        print('ScheduledActivityService: Table may not exist, attempting to create it...');
        try {
          await _schemaHelper.createScheduledActivitiesTable();
          print('ScheduledActivityService: Table created successfully, retrying insert');
          
          // Retry with duplicate checking
          await _insertActivities(activityData);
          print('ScheduledActivityService: Activities inserted successfully after table creation');
        } catch (tableError) {
          print('ScheduledActivityService: Failed to create table: $tableError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }
  
  /// Get all scheduled activities for the current user
  Future<List<Activity>> getScheduledActivities() async {
    try {
      // Require authentication
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to view scheduled activities');
      }
      
      print('ScheduledActivityService: Getting activities for user $userId');
      
      // Query the scheduled_activities table
      final response = await _client
          .from('scheduled_activities')
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: true);
      
      print('ScheduledActivityService: Raw response length: ${response.length}');
      
      // Convert response to Activity objects
      final activities = response.map((json) {
        print('ScheduledActivityService: Processing activity: ${json['name']}');
        
        // Parse tags and create a LatLng object
        final tags = (json['tags'] as String).split(',');
        final location = LatLng(
          json['latitude'] as double, 
          json['longitude'] as double
        );
        
        // Parse payment type
        final paymentTypeStr = json['payment_type'] as String;
        final paymentType = PaymentType.values.firstWhere(
          (e) => e.toString().split('.').last == paymentTypeStr,
          orElse: () => PaymentType.free,
        );
        
        // Determine time slot based on the start time
        final startTime = DateTime.parse(json['start_time']);
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
          // Both evening and night hours are assigned to 'evening' time slot
          timeSlotEnum = TimeSlot.evening;
          timeSlot = 'evening';
        }
        
        // Create and return Activity object
        return Activity(
          id: json['activity_id'],
          name: json['name'],
          description: json['description'],
          imageUrl: json['image_url'],
          startTime: startTime,
          duration: json['duration'],
          timeSlot: timeSlot,
          timeSlotEnum: timeSlotEnum,
          tags: tags,
          location: location,
          paymentType: paymentType,
          rating: 4.5, // Default rating if not available
          isPaid: paymentType != PaymentType.free,
        );
      }).toList();
      
      print('ScheduledActivityService: Returning ${activities.length} activities');
      return activities;
    } catch (e) {
      print('ScheduledActivityService: Database query failed: $e');
      print('ScheduledActivityService: Using in-memory fallback storage');
      
      // Return in-memory activities as fallback
      final activities = _inMemoryActivities.where((activity) {
        // Filter activities for today
        final now = DateTime.now();
        final activityDate = activity.startTime;
        return activityDate.year == now.year &&
               activityDate.month == now.month &&
               activityDate.day == now.day;
      }).toList();
      
      print('ScheduledActivityService: Returning ${activities.length} activities from memory');
      return activities;
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
      print('Error updating activity confirmation: $e');
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
      
      print('ScheduledActivityService: Deleting activity $activityId for user $userId');
      
      await _client
          .from('scheduled_activities')
          .delete()
          .eq('user_id', userId)
          .eq('activity_id', activityId);
      
      print('ScheduledActivityService: Activity deleted successfully');
    } catch (e) {
      print('ScheduledActivityService: Error deleting scheduled activity: $e');
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
      
      print('ScheduledActivityService: Updating activity $activityId for user $userId');
      
      await _client
          .from('scheduled_activities')
          .update(updates)
          .eq('user_id', userId)
          .eq('activity_id', activityId);
      
      print('ScheduledActivityService: Activity updated successfully');
    } catch (e) {
      print('ScheduledActivityService: Error updating scheduled activity: $e');
      rethrow;
    }
  }
} 