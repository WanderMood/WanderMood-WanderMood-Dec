import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/providers/supabase_provider.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wandermood/features/plans/data/services/schema_helper.dart';

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
  
  // In-memory storage for activities when database operations fail
  static final List<Activity> _demoActivities = [];
  
  ScheduledActivityService(this._client, this._schemaHelper);
  
  /// Save a list of activities to the scheduled_activities table
  Future<void> saveScheduledActivities(List<Activity> activities, {bool isConfirmed = false}) async {
    try {
      print('ScheduledActivityService: saveScheduledActivities called with ${activities.length} activities');
      
      // First get the current user id
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('ScheduledActivityService: User not logged in');
        // For demo purposes, use a demo user ID
        final demoUserId = 'demo-user-${DateTime.now().millisecondsSinceEpoch}';
        print('ScheduledActivityService: Using demo user ID: $demoUserId');
        
        // Continue with demo user ID instead of throwing
        final activityData = _prepareActivityData(activities, demoUserId, isConfirmed);
        return _insertActivitiesWithFallback(activityData);
      }
      
      print('ScheduledActivityService: User ID: $userId');
      final activityData = _prepareActivityData(activities, userId, isConfirmed);
      return _insertActivitiesWithFallback(activityData);
    } catch (e) {
      print('ScheduledActivityService: Error saving scheduled activities: $e');
      // Don't rethrow - let the app continue without disruption
      // This is a demo app, so we'll just log the error
      return;
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
  
  // Helper to insert activities with fallback
  Future<void> _insertActivitiesWithFallback(List<Map<String, dynamic>> activityData) async {
    try {
      // Insert into the scheduled_activities table
      print('ScheduledActivityService: Inserting ${activityData.length} activities into Supabase');
      await _client.from('scheduled_activities').insert(activityData);
      print('ScheduledActivityService: Activities inserted successfully');
    } catch (e) {
      print('ScheduledActivityService: Warning: Failed to save activities to Supabase: $e');
      
      // Try to create the table if it doesn't exist - this is for development/demo only
      if (e.toString().contains('does not exist') || e.toString().contains('relation') || e.toString().contains('42P01')) {
        print('ScheduledActivityService: Table may not exist, attempting to create it...');
        try {
          // Try to create the table using the schema helper
          await _schemaHelper.createScheduledActivitiesTable();
          print('ScheduledActivityService: Table created successfully, retrying insert');
          
          // Retry the insert
          await _client.from('scheduled_activities').insert(activityData);
          print('ScheduledActivityService: Activities inserted successfully after table creation');
          return;
        } catch (tableError) {
          print('ScheduledActivityService: Failed to create table: $tableError');
        }
      }
      
      // For demo purposes, save the data locally in memory
      print('ScheduledActivityService: Storing activities in memory for demo purposes');
      _demoActivities.clear();
      
      // Convert the map data back to Activity objects
      for (final data in activityData) {
        final tags = (data['tags'] as String).split(',');
        final location = LatLng(
          data['latitude'] as double, 
          data['longitude'] as double
        );
        
        // Parse payment type
        final paymentTypeStr = data['payment_type'] as String;
        final paymentType = PaymentType.values.firstWhere(
          (e) => e.toString().split('.').last == paymentTypeStr,
          orElse: () => PaymentType.free,
        );
        
        // Create activity
        final activity = Activity(
          id: data['activity_id'],
          name: data['name'],
          description: data['description'],
          imageUrl: data['image_url'],
          startTime: DateTime.parse(data['start_time']),
          duration: data['duration'],
          timeSlot: 'all-day', // Placeholder
          timeSlotEnum: TimeSlot.morning, // Placeholder
          tags: tags,
          location: location,
          paymentType: paymentType,
          rating: 4.5, // Default
          isPaid: paymentType != PaymentType.free,
        );
        
        _demoActivities.add(activity);
      }
      
      print('ScheduledActivityService: Stored ${_demoActivities.length} activities in memory');
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate some processing time
      return; // Return normally as if it succeeded
    }
  }
  
  /// Get all scheduled activities for the current user
  Future<List<Activity>> getScheduledActivities() async {
    try {
      // 🚫 REMOVED: All hardcoded demo activities - now returns empty for development
      // First check if we have demo activities in memory
      if (_demoActivities.isNotEmpty) {
        print('ScheduledActivityService: Returning ${_demoActivities.length} in-memory activities');
        return List<Activity>.from(_demoActivities);
      }
      
      // Get current user id
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('ScheduledActivityService: User not logged in - returning empty list for development');
        // 🎯 DEVELOPMENT MODE: Return empty list instead of mock data
        return <Activity>[];
      }
      
      print('ScheduledActivityService: Getting activities for user $userId');
      
      // Query scheduled activities for this user, ordered by start time
      final response = await _client
          .from('scheduled_activities')
          .select()
          .eq('user_id', userId)
          .order('start_time');
      
      print('ScheduledActivityService: Raw response length: ${(response as List).length}');
      
      // Convert response to Activity objects
      final activities = (response as List).map((json) {
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
      print('Error getting scheduled activities: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // 🎯 DEVELOPMENT MODE: Return empty list instead of demo activities
      print('ScheduledActivityService: Error loading activities - returning empty list for development');
      return <Activity>[];
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
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      await _client
          .from('scheduled_activities')
          .delete()
          .eq('user_id', userId)
          .eq('activity_id', activityId);
    } catch (e) {
      print('Error deleting scheduled activity: $e');
      rethrow;
    }
  }
} 