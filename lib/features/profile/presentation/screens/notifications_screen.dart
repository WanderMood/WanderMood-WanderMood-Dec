import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers/profile_provider.dart';
import '../widgets/settings_screen_template.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _inAppNotifications = true;
  bool _newActivities = true;
  bool _nearbyEvents = true;
  bool _friendActivity = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final profileAsync = ref.read(profileProvider);
    profileAsync.whenData((profile) {
      if (mounted && profile != null) {
        final prefs = profile.notificationPreferences;
        setState(() {
          _pushNotifications = prefs['push'] ?? true;
          _emailNotifications = prefs['email'] ?? false;
          _inAppNotifications = prefs['inApp'] ?? true;
          _newActivities = prefs['newActivities'] ?? true;
          _nearbyEvents = prefs['nearbyEvents'] ?? true;
          _friendActivity = prefs['friendActivity'] ?? false;
        });
      }
    });
  }

  Future<void> _updateNotifications() async {
    try {
      await ref.read(profileProvider.notifier).updateProfile(
        notificationPreferences: {
          'push': _pushNotifications,
          'email': _emailNotifications,
          'inApp': _inAppNotifications,
          'newActivities': _newActivities,
          'nearbyEvents': _nearbyEvents,
          'friendActivity': _friendActivity,
        },
      );
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenTemplate(
      title: 'Notifications',
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Methods',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: 'Push Notifications',
            subtitle: 'Receive push notifications on this device',
            checked: _pushNotifications,
            onChange: () {
              setState(() => _pushNotifications = !_pushNotifications);
              _updateNotifications();
            },
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: 'Email Notifications',
            subtitle: 'Receive updates via email',
            checked: _emailNotifications,
            onChange: () {
              setState(() => _emailNotifications = !_emailNotifications);
              _updateNotifications();
            },
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: 'In-App Notifications',
            subtitle: 'See notifications inside the app',
            checked: _inAppNotifications,
            onChange: () {
              setState(() => _inAppNotifications = !_inAppNotifications);
              _updateNotifications();
            },
          ),
          const SizedBox(height: 24),
          Text(
            'What to Notify',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: 'New Activities',
            subtitle: 'When new activities match your vibe',
            checked: _newActivities,
            onChange: () {
              setState(() => _newActivities = !_newActivities);
              _updateNotifications();
            },
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: 'Nearby Events',
            subtitle: 'Events happening around you',
            checked: _nearbyEvents,
            onChange: () {
              setState(() => _nearbyEvents = !_nearbyEvents);
              _updateNotifications();
            },
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: 'Friend Activity',
            subtitle: 'When friends share or like something',
            checked: _friendActivity,
            onChange: () {
              setState(() => _friendActivity = !_friendActivity);
              _updateNotifications();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required String subtitle,
    required bool checked,
    required VoidCallback onChange,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onChange,
              child: Container(
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  gradient: checked
                      ? const LinearGradient(
                          colors: [Color(0xFFFB923C), Color(0xFFEC4899)],
                        )
                      : null,
                  color: checked ? null : const Color(0xFFD1D5DB),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
