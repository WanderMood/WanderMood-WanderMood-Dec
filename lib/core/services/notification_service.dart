import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/core/config/supabase_config.dart';

/// Service that handles notifications and respects user preferences
class NotificationService {
  final SupabaseConfig _supabase = SupabaseConfig.client;

  /// Check if a specific notification type is enabled for the user
  Future<bool> isNotificationEnabled(String notificationType) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Get user profile to check notification preferences
      final response = await _supabase
          .from('profiles')
          .select('notification_preferences')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return true; // Default to enabled

      final prefs = response['notification_preferences'] as Map<String, dynamic>?;
      if (prefs == null) return true; // Default to enabled

      // Map notification types to preference keys
      final typeMap = {
        'activity_reminders': 'activityReminders',
        'mood_tracking': 'moodTracking',
        'weather_alerts': 'weatherAlerts',
        'travel_tips': 'travelTips',
        'local_events': 'localEvents',
        'friend_activity': 'friendActivity',
        'special_offers': 'specialOffers',
        'push': 'push',
        'email': 'email',
      };

      final key = typeMap[notificationType] ?? notificationType;
      return prefs[key] as bool? ?? true; // Default to enabled
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking notification preference: $e');
      }
      return true; // Default to enabled on error
    }
  }

  /// Send a notification if the user has it enabled
  /// This is a placeholder - actual implementation would integrate with FCM/push service
  Future<bool> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if this notification type is enabled
      final isEnabled = await isNotificationEnabled(type);
      if (!isEnabled) {
        if (kDebugMode) {
          debugPrint('🔕 Notification $type is disabled for user $userId');
        }
        return false;
      }

      // Check if push notifications are enabled
      final pushEnabled = await isNotificationEnabled('push');
      if (!pushEnabled) {
        if (kDebugMode) {
          debugPrint('🔕 Push notifications are disabled for user $userId');
        }
        return false;
      }

      // TODO: Integrate with actual push notification service (FCM, OneSignal, etc.)
      // For now, we'll just log that a notification would be sent
      if (kDebugMode) {
        debugPrint('📲 Would send notification: $title - $message (type: $type)');
      }

      // In the future, this would:
      // 1. Get FCM token from user's device
      // 2. Send push notification via FCM API
      // 3. Optionally send email notification if email notifications are enabled

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending notification: $e');
      }
      return false;
    }
  }

  /// Send email notification if enabled
  /// This would integrate with an email service (SendGrid, Mailgun, Supabase Edge Function, etc.)
  Future<bool> sendEmailNotification({
    required String userId,
    required String type,
    required String subject,
    required String body,
  }) async {
    try {
      // Check if email notifications are enabled
      final emailEnabled = await isNotificationEnabled('email');
      if (!emailEnabled) {
        if (kDebugMode) {
          debugPrint('🔕 Email notifications are disabled for user $userId');
        }
        return false;
      }

      // Check if this specific notification type is enabled
      final typeEnabled = await isNotificationEnabled(type);
      if (!typeEnabled) {
        if (kDebugMode) {
          debugPrint('🔕 Notification type $type is disabled for user $userId');
        }
        return false;
      }

      // TODO: Integrate with email service
      // This would typically call a Supabase Edge Function that sends emails
      if (kDebugMode) {
        debugPrint('📧 Would send email: $subject (type: $type)');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending email notification: $e');
      }
      return false;
    }
  }
}

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

