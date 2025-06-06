import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Notification settings
  bool _activityReminders = true;
  bool _moodTracking = true;
  bool _specialOffers = false;
  bool _friendActivity = true;
  bool _weatherAlerts = true;
  bool _travelTips = true;
  bool _localEvents = false;

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
                    value: true, // This would be a global setting
                    activeColor: const Color(0xFF12B347),
                    onChanged: (value) {
                      // This would toggle all notifications
                      setState(() {
                        _activityReminders = value;
                        _moodTracking = value;
                        _specialOffers = value;
                        _friendActivity = value;
                        _weatherAlerts = value;
                        _travelTips = value;
                        _localEvents = value;
                      });
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
                    onChanged: (value) {
                      setState(() {
                        _activityReminders = value;
                      });
                    },
                  ),
                  
                  _buildNotificationTile(
                    title: 'Mood Tracking',
                    subtitle: 'Daily prompts to track your mood',
                    value: _moodTracking,
                    onChanged: (value) {
                      setState(() {
                        _moodTracking = value;
                      });
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
                    onChanged: (value) {
                      setState(() {
                        _weatherAlerts = value;
                      });
                    },
                  ),
                  
                  _buildNotificationTile(
                    title: 'Travel Tips',
                    subtitle: 'Suggestions for your trips and activities',
                    value: _travelTips,
                    onChanged: (value) {
                      setState(() {
                        _travelTips = value;
                      });
                    },
                  ),
                  
                  _buildNotificationTile(
                    title: 'Local Events',
                    subtitle: 'Notifications about events in your area',
                    value: _localEvents,
                    onChanged: (value) {
                      setState(() {
                        _localEvents = value;
                      });
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
                    onChanged: (value) {
                      setState(() {
                        _friendActivity = value;
                      });
                    },
                  ),
                  
                  _buildNotificationTile(
                    title: 'Special Offers',
                    subtitle: 'Promotional offers and app updates',
                    value: _specialOffers,
                    onChanged: (value) {
                      setState(() {
                        _specialOffers = value;
                      });
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
  
  // Save notification settings
  void _saveNotificationSettings() {
    // Here you would persist the settings to your backend or local storage
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 