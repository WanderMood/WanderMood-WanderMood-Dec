import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../../domain/providers/profile_provider.dart';
import '../../../../core/presentation/providers/local_theme_provider.dart';
import '../widgets/settings_screen_template.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

const Color _themeWmForest = Color(0xFF2A6049);
const Color _themeWmForestTint = Color(0xFFEBF3EE);

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  String _selectedTheme = 'system';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final themeNotifier = ref.read(localThemeProvider.notifier);
    if (mounted) {
      setState(() {
        _selectedTheme = themeNotifier.currentThemeString;
      });
    }
  }

  Future<void> _updateTheme(String theme) async {
    setState(() => _selectedTheme = theme);
    try {
      final l10n = AppLocalizations.of(context)!;
      await ref.read(localThemeProvider.notifier).setThemeFromString(theme);
      await ref.read(profileProvider.notifier).updateProfile(
        themePreference: theme,
      );
      if (mounted) {
        String themeLabel;
        if (theme == 'light') {
          themeLabel = l10n.lightTheme;
        } else if (theme == 'dark') {
          themeLabel = l10n.darkTheme;
        } else {
          themeLabel = l10n.system;
        }
        showWanderMoodToast(
          context,
          message: l10n.themeUpdatedTo(themeLabel),
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsScreenTemplate(
      title: l10n.themeSettings,
      onBack: () => context.pop(),
      wanderMoodV2Chrome: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRadioOption(
            label: l10n.light,
            subtitle: l10n.lightTheme,
            value: 'light',
            selected: _selectedTheme == 'light',
            onTap: () => _updateTheme('light'),
          ),
          const SizedBox(height: 8),
          _buildRadioOption(
            label: l10n.dark,
            subtitle: l10n.darkTheme,
            value: 'dark',
            selected: _selectedTheme == 'dark',
            onTap: () => _updateTheme('dark'),
          ),
          const SizedBox(height: 8),
          _buildRadioOption(
            label: l10n.system,
            subtitle: l10n.followSystemTheme,
            value: 'system',
            selected: _selectedTheme == 'system',
            onTap: () => _updateTheme('system'),
            badge: l10n.settingsTwoFactorBadgeRecommended,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required String subtitle,
    required String value,
    required bool selected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _themeWmForest : const Color(0xFFE5E7EB),
          width: 2,
        ),
      ),
      child: Material(
        color: selected ? _themeWmForestTint : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2A6049),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? _themeWmForest : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: _themeWmForest,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
