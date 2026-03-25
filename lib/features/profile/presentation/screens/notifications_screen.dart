import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/l10n/app_localizations.dart';
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
  bool _tripReminders = true;
  bool _weatherUpdates = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final prefs = await Supabase.instance.client
          .from('user_preferences')
          .select('trip_reminders, weather_updates')
          .eq('user_id', user.id)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _tripReminders = (prefs?['trip_reminders'] as bool?) ?? true;
        _weatherUpdates = (prefs?['weather_updates'] as bool?) ?? true;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotifications({
    required bool? tripReminders,
    required bool? weatherUpdates,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client
          .from('user_preferences')
          .upsert({
            'user_id': user.id,
            if (tripReminders != null) 'trip_reminders': tripReminders,
            if (weatherUpdates != null) 'weather_updates': weatherUpdates,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsScreenTemplate(
      title: l10n.settingsNotificationsTitle,
      onBack: () => context.pop(),
      wanderMoodV2Chrome: true,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _wmForest),
            )
          : Column(
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
                _buildToggleOption(
                  label: l10n.settingsNotificationsTripRemindersLabel,
                  subtitle: l10n.settingsNotificationsTripRemindersSubtitle,
                  checked: _tripReminders,
                  onChange: () async {
                    final next = !_tripReminders;
                    setState(() => _tripReminders = next);
                    await _updateNotifications(
                      tripReminders: next,
                      weatherUpdates: null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildToggleOption(
                  label: l10n.settingsNotificationsWeatherUpdatesLabel,
                  subtitle: l10n.settingsNotificationsWeatherUpdatesSubtitle,
                  checked: _weatherUpdates,
                  onChange: () async {
                    final next = !_weatherUpdates;
                    setState(() => _weatherUpdates = next);
                    await _updateNotifications(
                      tripReminders: null,
                      weatherUpdates: next,
                    );
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
