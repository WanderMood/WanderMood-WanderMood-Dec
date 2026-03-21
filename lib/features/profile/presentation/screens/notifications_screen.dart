import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../../domain/providers/profile_provider.dart';
import '../widgets/settings_screen_template.dart';

/// v2 tokens
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

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
    final l10n = AppLocalizations.of(context)!;
    return SettingsScreenTemplate(
      title: l10n.settingsNotificationsTitle,
      onBack: () => context.pop(),
      wanderMoodV2Chrome: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.notificationsMethodsTitle.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
              color: _wmStone,
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: l10n.notificationsPushTitle,
            subtitle: l10n.notificationsPushSubtitle,
            checked: _pushNotifications,
            onChange: () {
              setState(() => _pushNotifications = !_pushNotifications);
              _updateNotifications();
            },
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: l10n.notificationsEmailTitle,
            subtitle: l10n.notificationsEmailSubtitle,
            checked: _emailNotifications,
            onChange: () {
              setState(() => _emailNotifications = !_emailNotifications);
              _updateNotifications();
            },
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: l10n.notificationsInAppTitle,
            subtitle: l10n.notificationsInAppSubtitle,
            checked: _inAppNotifications,
            onChange: () {
              setState(() => _inAppNotifications = !_inAppNotifications);
              _updateNotifications();
            },
          ),
          const SizedBox(height: 24),
          Text(
            l10n.notificationsWhatToNotifyTitle.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
              color: _wmStone,
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: l10n.notificationsNewActivitiesTitle,
            subtitle: l10n.notificationsNewActivitiesSubtitle,
            checked: _newActivities,
            onChange: () {
              setState(() => _newActivities = !_newActivities);
              _updateNotifications();
            },
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: l10n.notificationsNearbyEventsTitle,
            subtitle: l10n.notificationsNearbyEventsSubtitle,
            checked: _nearbyEvents,
            onChange: () {
              setState(() => _nearbyEvents = !_nearbyEvents);
              _updateNotifications();
            },
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: l10n.notificationsFriendActivityTitle,
            subtitle: l10n.notificationsFriendActivitySubtitle,
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
        color: _wmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _wmParchment,
          width: 0.5,
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
                      color: _wmCharcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _wmStone,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onChange,
              child: Semantics(
                toggled: checked,
                label: label,
                child: Container(
                  width: 48,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999),
                    color: checked ? _wmForest : _wmParchment,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
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
