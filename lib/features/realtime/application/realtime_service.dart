import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/realtime_event.dart';

part 'realtime_service.g.dart';

@riverpod
class RealtimeService extends _$RealtimeService {
  final _supabase = Supabase.instance.client;
  
  // Stream controllers for different types of real-time updates
  final _notificationController = StreamController<RealtimeEvent>.broadcast();
  final _liveUpdateController = StreamController<LiveUpdate>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Subscription management
  RealtimeChannel? _notificationChannel;
  RealtimeChannel? _presenceChannel;
  List<RealtimeChannel> _tableChannels = [];
  
  // Cache for unread notifications
  List<RealtimeEvent> _unreadNotifications = [];
  NotificationSettings? _notificationSettings;
  
  @override
  Future<List<RealtimeEvent>> build() async {
    // Initialize real-time subscriptions when service is first accessed
    await _initializeRealtimeSubscriptions();
    
    // Load initial notifications
    return await _loadNotifications();
  }

  /// Initialize all real-time subscriptions
  Future<void> _initializeRealtimeSubscriptions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('No authenticated user for realtime subscriptions');
        return;
      }

      print('Initializing realtime subscriptions for user: ${user.id}');

      // Subscribe to user-specific notifications
      await _subscribeToNotifications(user.id);
      
      // Subscribe to user presence updates
      await _subscribeToPresence();
      
      // Subscribe to relevant table updates
      await _subscribeToTableUpdates();
      
      // Update user presence
      await _updateUserPresence('online');
      
      print('Realtime subscriptions initialized successfully');
    } catch (e) {
      print('Error initializing realtime subscriptions: $e');
    }
  }

  /// Subscribe to user-specific notification events
  Future<void> _subscribeToNotifications(String userId) async {
    try {
      _notificationChannel = _supabase
          .channel('notifications:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'realtime_events',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) => _handleNotificationInsert(payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'realtime_events',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) => _handleNotificationUpdate(payload),
          )
          .subscribe();

      print('Subscribed to notifications for user: $userId');
    } catch (e) {
      print('Error subscribing to notifications: $e');
    }
  }

  /// Subscribe to user presence updates
  Future<void> _subscribeToPresence() async {
    try {
      _presenceChannel = _supabase
          .channel('presence')
          .onPresenceSync((payload) => _handlePresenceSync(payload))
          .onPresenceJoin((payload) => _handlePresenceJoin(payload))
          .onPresenceLeave((payload) => _handlePresenceLeave(payload))
          .subscribe();

      print('Subscribed to presence updates');
    } catch (e) {
      print('Error subscribing to presence: $e');
    }
  }

  /// Subscribe to table updates for live data synchronization
  Future<void> _subscribeToTableUpdates() async {
    try {
      // Subscribe to travel posts updates
      final postsChannel = _supabase
          .channel('posts_updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'diary_entries',
            callback: (payload) => _handleTableUpdate('diary_entries', payload),
          )
          .subscribe();

      // Subscribe to post reactions updates
      final reactionsChannel = _supabase
          .channel('reactions_updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'post_reactions',
            callback: (payload) => _handleTableUpdate('post_reactions', payload),
          )
          .subscribe();

      // Subscribe to user profiles updates
      final profilesChannel = _supabase
          .channel('profiles_updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'profiles',
            callback: (payload) => _handleTableUpdate('profiles', payload),
          )
          .subscribe();

      _tableChannels = [postsChannel, reactionsChannel, profilesChannel];
      print('Subscribed to table updates');
    } catch (e) {
      print('Error subscribing to table updates: $e');
    }
  }

  /// Handle new notification insert
  void _handleNotificationInsert(PostgresChangePayload payload) {
    try {
      final eventData = payload.newRecord;
      final event = RealtimeEvent.fromJson(eventData);
      
      print('New notification received: ${event.type} - ${event.title}');
      
      // Add to unread notifications cache
      _unreadNotifications.add(event);
      
      // Emit the notification event
      _notificationController.add(event);
      
      // Update the state
      state = AsyncValue.data([event, ...state.value ?? []]);
      
    } catch (e) {
      print('Error handling notification insert: $e');
    }
  }

  /// Handle notification update (e.g., mark as read)
  void _handleNotificationUpdate(PostgresChangePayload payload) {
    try {
      final eventData = payload.newRecord;
      final updatedEvent = RealtimeEvent.fromJson(eventData);
      
      // Update unread notifications cache
      _unreadNotifications.removeWhere((e) => e.id == updatedEvent.id);
      if (!updatedEvent.isRead) {
        _unreadNotifications.add(updatedEvent);
      }
      
      // Update state
      final currentNotifications = state.value ?? [];
      final updatedNotifications = currentNotifications.map((notification) {
        return notification.id == updatedEvent.id ? updatedEvent : notification;
      }).toList();
      
      state = AsyncValue.data(updatedNotifications);
      
    } catch (e) {
      print('Error handling notification update: $e');
    }
  }

  /// Handle presence sync events
  void _handlePresenceSync(List<Map<String, dynamic>> presences) {
    try {
      print('Presence sync: ${presences.length} users online');
      _presenceController.add({'type': 'sync', 'presences': presences});
    } catch (e) {
      print('Error handling presence sync: $e');
    }
  }

  /// Handle user joining presence
  void _handlePresenceJoin(Map<String, dynamic> presence) {
    try {
      print('User joined: ${presence['user_id']}');
      _presenceController.add({'type': 'join', 'presence': presence});
    } catch (e) {
      print('Error handling presence join: $e');
    }
  }

  /// Handle user leaving presence
  void _handlePresenceLeave(Map<String, dynamic> presence) {
    try {
      print('User left: ${presence['user_id']}');
      _presenceController.add({'type': 'leave', 'presence': presence});
    } catch (e) {
      print('Error handling presence leave: $e');
    }
  }

  /// Handle table update events
  void _handleTableUpdate(String tableName, PostgresChangePayload payload) {
    try {
      final updateType = _mapEventToUpdateType(payload.eventType);
      
      final liveUpdate = LiveUpdate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        table: tableName,
        type: updateType,
        record: payload.newRecord,
        oldRecord: payload.oldRecord,
        timestamp: DateTime.now(),
        userId: payload.newRecord['user_id'] as String?,
      );
      
      print('Table update: $tableName - $updateType');
      _liveUpdateController.add(liveUpdate);
      
    } catch (e) {
      print('Error handling table update: $e');
    }
  }

  /// Map Supabase event type to our update type
  LiveUpdateType _mapEventToUpdateType(PostgresChangeEvent event) {
    switch (event) {
      case PostgresChangeEvent.insert:
        return LiveUpdateType.insert;
      case PostgresChangeEvent.update:
        return LiveUpdateType.update;
      case PostgresChangeEvent.delete:
        return LiveUpdateType.delete;
      default:
        return LiveUpdateType.update;
    }
  }

  /// Load initial notifications from database
  Future<List<RealtimeEvent>> _loadNotifications({int limit = 50}) async {
    try {
      print('Loading notifications...');
      
      final response = await _supabase
          .from('realtime_events')
          .select()
          .order('timestamp', ascending: false)
          .limit(limit);

      final notifications = response
          .map<RealtimeEvent>((data) => RealtimeEvent.fromJson(data))
          .toList();

      // Cache unread notifications
      _unreadNotifications = notifications.where((n) => !n.isRead).toList();
      
      print('Loaded ${notifications.length} notifications (${_unreadNotifications.length} unread)');
      return notifications;
      
    } catch (e) {
      print('Error loading notifications: $e');
      return [];
    }
  }

  /// Get notification stream
  Stream<RealtimeEvent> get notificationStream => _notificationController.stream;

  /// Get live update stream
  Stream<LiveUpdate> get liveUpdateStream => _liveUpdateController.stream;

  /// Get presence stream
  Stream<Map<String, dynamic>> get presenceStream => _presenceController.stream;

  /// Get unread notification count
  int get unreadCount => _unreadNotifications.length;

  /// Get unread notifications
  List<RealtimeEvent> get unreadNotifications => List.unmodifiable(_unreadNotifications);

  /// Mark notifications as read
  Future<void> markAsRead(List<String> eventIds) async {
    try {
      print('Marking ${eventIds.length} notifications as read');
      
      final response = await _supabase.rpc('mark_events_as_read', params: {
        'event_ids': eventIds,
      });

      print('Marked $response notifications as read');
      
      // Update local cache
      _unreadNotifications.removeWhere((n) => eventIds.contains(n.id));
      
      // Refresh state
      await _loadNotifications();
      
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final unreadIds = _unreadNotifications.map((n) => n.id).toList();
      if (unreadIds.isNotEmpty) {
        await markAsRead(unreadIds);
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Send a notification to a user
  Future<String?> sendNotification({
    required String targetUserId,
    required RealtimeEventType type,
    required String title,
    required String message,
    Map<String, dynamic> data = const {},
    String? sourceUserId,
    String? relatedPostId,
    int priority = 0,
  }) async {
    try {
      print('Sending notification: $type to $targetUserId');
      
      final response = await _supabase.rpc('send_realtime_notification', params: {
        'target_user_id': targetUserId,
        'event_type': type.name,
        'event_title': title,
        'event_message': message,
        'event_data': data,
        'source_user_id': sourceUserId,
        'related_post_id': relatedPostId,
        'priority_level': priority,
      });

      print('Notification sent with ID: $response');
      return response as String?;
      
    } catch (e) {
      print('Error sending notification: $e');
      return null;
    }
  }

  /// Update user presence and activity status
  Future<void> _updateUserPresence(
    String activityStatus, {
    Map<String, dynamic>? locationData,
    bool shareLocation = false,
  }) async {
    try {
      await _supabase.rpc('update_user_presence', params: {
        'activity_status': activityStatus,
        'location_data': locationData,
        'share_location': shareLocation,
      });

      print('User presence updated: $activityStatus');
    } catch (e) {
      print('Error updating user presence: $e');
    }
  }

  /// Set user as online
  Future<void> setOnline() async {
    await _updateUserPresence('online');
  }

  /// Set user as away
  Future<void> setAway() async {
    await _updateUserPresence('away');
  }

  /// Set user as traveling with location
  Future<void> setTraveling({Map<String, dynamic>? location}) async {
    await _updateUserPresence('traveling', locationData: location, shareLocation: true);
  }

  /// Set user as offline
  Future<void> setOffline() async {
    await _updateUserPresence('offline');
  }

  /// Get notification settings for current user
  Future<NotificationSettings?> getNotificationSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('notification_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        _notificationSettings = NotificationSettings.fromJson(response);
        return _notificationSettings;
      }

      // Create default settings if none exist
      final defaultSettings = NotificationSettings(userId: user.id);
      await _saveNotificationSettings(defaultSettings);
      return defaultSettings;
      
    } catch (e) {
      print('Error getting notification settings: $e');
      return null;
    }
  }

  /// Save notification settings
  Future<void> _saveNotificationSettings(NotificationSettings settings) async {
    try {
      await _supabase
          .from('notification_settings')
          .upsert(settings.toJson());

      _notificationSettings = settings;
      print('Notification settings saved');
      
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    await _saveNotificationSettings(settings);
  }

  /// Get online users
  Future<List<Map<String, dynamic>>> getOnlineUsers() async {
    try {
      final response = await _supabase
          .from('user_presence')
          .select('''
            user_id,
            is_online,
            last_seen,
            activity_status,
            current_location,
            is_sharing_location,
            profiles!inner(
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('is_online', true)
          .order('last_seen', ascending: false);

      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      print('Error getting online users: $e');
      return [];
    }
  }

  /// Refresh notifications from server
  Future<void> refreshNotifications() async {
    try {
      final notifications = await _loadNotifications();
      state = AsyncValue.data(notifications);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Clean up resources when service is disposed
  void dispose() {
    print('Disposing realtime service...');
    
    // Set user offline
    _updateUserPresence('offline');
    
    // Close stream controllers
    _notificationController.close();
    _liveUpdateController.close();
    _presenceController.close();
    
    // Unsubscribe from channels
    _notificationChannel?.unsubscribe();
    _presenceChannel?.unsubscribe();
    
    for (final channel in _tableChannels) {
      channel.unsubscribe();
    }
    
    print('Realtime service disposed');
  }
} 