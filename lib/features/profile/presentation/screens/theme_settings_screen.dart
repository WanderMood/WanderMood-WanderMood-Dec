import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers/profile_provider.dart';
import '../../../../core/presentation/providers/local_theme_provider.dart';
import '../widgets/settings_screen_template.dart';

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
      await ref.read(localThemeProvider.notifier).setThemeFromString(theme);
      await ref.read(profileProvider.notifier).updateProfile(
        themePreference: theme,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Theme updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenTemplate(
      title: 'Theme',
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRadioOption(
            label: 'Light',
            subtitle: 'Always use light theme',
            value: 'light',
            selected: _selectedTheme == 'light',
            onTap: () => _updateTheme('light'),
          ),
          const SizedBox(height: 8),
          _buildRadioOption(
            label: 'Dark',
            subtitle: 'Always use dark theme',
            value: 'dark',
            selected: _selectedTheme == 'dark',
            onTap: () => _updateTheme('dark'),
          ),
          const SizedBox(height: 8),
          _buildRadioOption(
            label: 'System',
            subtitle: 'Match your device settings',
            value: 'system',
            selected: _selectedTheme == 'system',
            onTap: () => _updateTheme('system'),
            badge: 'Recommended',
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
          color: selected ? const Color(0xFFFB923C) : const Color(0xFFE5E7EB),
          width: 2,
        ),
      ),
      child: Material(
        color: selected ? const Color(0xFFFFF7ED) : Colors.transparent,
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
                                  color: const Color(0xFF16A34A),
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
                      color: selected ? const Color(0xFFF97316) : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF97316),
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
