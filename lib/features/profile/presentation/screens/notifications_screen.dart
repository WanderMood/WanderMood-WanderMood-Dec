import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Notification settings - loaded from profile
  bool _allowNotifications = true;
  bool _activityReminders = true;
  bool _moodTracking = true;
  bool _specialOffers = false;
  bool _friendActivity = true;
  bool _weatherAlerts = true;
  bool _travelTips = true;
  bool _localEvents = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final profileAsync = ref.read(profileProvider);
    profileAsync.whenData((profile) {
      if (profile?.notificationPreferences != null && mounted) {
        final prefs = profile!.notificationPreferences;
        setState(() {
          _allowNotifications = prefs['push'] ?? true;
          _activityReminders = prefs['activityReminders'] ?? prefs['travelTips'] ?? true;
          _moodTracking = prefs['moodTracking'] ?? true;
          _weatherAlerts = prefs['weatherAlerts'] ?? prefs['travelTips'] ?? true;
          _travelTips = prefs['travelTips'] ?? true;
          _friendActivity = prefs['friendActivity'] ?? prefs['socialUpdates'] ?? true;
          _specialOffers = prefs['specialOffers'] ?? prefs['marketing'] ?? false;
          _localEvents = prefs['localEvents'] ?? false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Notifications',
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12B347),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Master toggle
                  SwitchListTile(
                    title: Text(
                      'Allow Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Master control for all notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    value: _allowNotifications,
                    activeColor: const Color(0xFF12B347),
                    onChanged: (value) async {
                      setState(() {
                        _allowNotifications = value;
                        // Toggle all notifications when master is toggled
                        _activityReminders = value;
                        _moodTracking = value;
                        _specialOffers = value;
                        _friendActivity = value;
                        _weatherAlerts = value;
                        _travelTips = value;
                        _localEvents = value;
                      });
                      await _saveNotificationSettings();
                    },
                  ),
                  
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Activity Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF12B347),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildNotificationTile(
                    title: 'Activity Reminders',
                    subtitle: 'Reminders for upcoming activities and plans',
                    value: _activityReminders,
                    onChanged: (value) async {
                      setState(() {
                        _activityReminders = value;
                      });
                      await _saveNotificationSettings();
                    },
                  ),
                  
                  _buildNotificationTile(
                    title: 'Mood Tracking',
                    subtitle: 'Daily prompts to track your mood',
                    value: _moodTracking,
                    onChanged: (value) async {
                      setState(() {
                        _moodTracking = value;
                      });
                      await _saveNotificationSettings();
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Travel & Weather',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF12B347),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildNotificationTile(
                    title: 'Weather Alerts',
                    subtitle: 'Get alerts about weather changes',
                    value: _weatherAlerts,
                    onChanged: (value) async {
                      setState(() {
                        _weatherAlerts = value;
                      });
                      await _saveNotificationSettings();
                    },
                  ),
                  
                  _buildNotificationTile(
                    title: 'Travel Tips',
                    subtitle: 'Suggestions for your trips and activities',
                    value: _travelTips,
                    onChanged: (value) async {
                      setState(() {
                        _travelTips = value;
                      });
                      await _saveNotificationSettings();
                    },
                  ),
                  
                  _buildNotificationTile(
                    title: 'Local Events',
                    subtitle: 'Notifications about events in your area',
                    value: _localEvents,
                    onChanged: (value) async {
                      setState(() {
                        _localEvents = value;
                      });
                      await _saveNotificationSettings();
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Social',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF12B347),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildNotificationTile(
                    title: 'Friend Activity',
                    subtitle: 'When friends share trips or activities',
                    value: _friendActivity,
                    onChanged: (value) async {
                      setState(() {
                        _friendActivity = value;
                      });
                      await _saveNotificationSettings();
                    },
                  ),
                  
                  _buildNotificationTile(
                    title: 'Special Offers',
                    subtitle: 'Promotional offers and app updates',
                    value: _specialOffers,
                    onChanged: (value) async {
                      setState(() {
                        _specialOffers = value;
                      });
                      await _saveNotificationSettings();
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Schedule',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can adjust when you receive notifications by setting quiet hours in your device settings.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            // Open device notification settings
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF12B347),
                            side: const BorderSide(color: Color(0xFF12B347)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Open Device Settings',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveNotificationSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12B347),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Save Settings',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper widget for notification toggles
  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      activeColor: const Color(0xFF12B347),
      onChanged: onChanged,
    );
  }
  
  // Save notification settings to profile
  Future<void> _saveNotificationSettings() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Map local state to notification preferences format
      final notificationPrefs = {
        'push': _allowNotifications,
        'email': _allowNotifications, // Can be separated later
        'travelTips': _travelTips,
        'socialUpdates': _friendActivity,
        'marketing': _specialOffers,
        // Additional preferences that can be added to the model
        'activityReminders': _activityReminders,
        'moodTracking': _moodTracking,
        'weatherAlerts': _weatherAlerts,
        'localEvents': _localEvents,
      };
      
      await ref.read(profileProvider.notifier).updateProfile(
        notificationPreferences: notificationPrefs,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification settings saved',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF12B347),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving notification settings: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save settings: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
} 