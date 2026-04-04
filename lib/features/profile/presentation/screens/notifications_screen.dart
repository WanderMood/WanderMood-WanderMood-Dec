import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/providers/notification_provider.dart';
import 'package:wandermood/features/settings/presentation/providers/user_preferences_provider.dart';
import '../widgets/settings_screen_template.dart';

/// v2 tokens
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(userPreferencesProvider);

    return SettingsScreenTemplate(
      title: l10n.settingsNotificationsTitle,
      onBack: () => context.pop(),
      wanderMoodV2Chrome: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsNotificationsSectionTitle.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
              color: _wmStone,
            ),
          ),
          const SizedBox(height: 12),
          _ToggleOption(
            label: l10n.settingsNotificationsTripRemindersLabel,
            subtitle: l10n.settingsNotificationsTripRemindersSubtitle,
            checked: prefs.tripReminders,
            onChange: () async {
              final next = !prefs.tripReminders;
              await ref.read(userPreferencesProvider.notifier).updateTripReminders(next);
              await ref.read(notificationSchedulerProvider).rescheduleAll();
            },
          ),
          const SizedBox(height: 12),
          _ToggleOption(
            label: l10n.settingsNotificationsWeatherUpdatesLabel,
            subtitle: l10n.settingsNotificationsWeatherUpdatesSubtitle,
            checked: prefs.weatherUpdates,
            onChange: () async {
              final next = !prefs.weatherUpdates;
              await ref.read(userPreferencesProvider.notifier).updateWeatherUpdates(next);
              await ref.read(notificationSchedulerProvider).rescheduleAll();
            },
          ),
          const SizedBox(height: 16),
          Text(
            l10n.settingsNotificationsLocalDeviceFootnote,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _wmStone,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool checked;
  final Future<void> Function() onChange;

  const _ToggleOption({
    required this.label,
    required this.subtitle,
    required this.checked,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
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
              onTap: () => onChange(),
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
                      alignment:
                          checked ? Alignment.centerRight : Alignment.centerLeft,
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
