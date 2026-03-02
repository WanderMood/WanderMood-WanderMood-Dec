import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../../domain/providers/profile_provider.dart';
import '../../../../core/presentation/providers/language_provider.dart';
import '../widgets/settings_screen_template.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final profileAsync = ref.read(profileProvider);
    profileAsync.whenData((profile) {
      if (mounted && profile != null) {
        setState(() {
          _selectedLanguage = profile.languagePreference;
        });
      }
    });
  }

  Future<void> _updateLanguage(String code) async {
    setState(() => _selectedLanguage = code);
    try {
      final l10n = AppLocalizations.of(context)!;
      await ref.read(localeProvider.notifier).setLocale(Locale(code));
      await ref.read(profileProvider.notifier).updateProfile(
        languagePreference: code,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.languageUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsScreenTemplate(
      title: l10n.languageSettings,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLanguageOption(
            code: 'en',
            name: 'English',
            native: 'English',
            selected: _selectedLanguage == 'en',
            onTap: () => _updateLanguage('en'),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            code: 'nl',
            name: 'Dutch',
            native: 'Nederlands',
            selected: _selectedLanguage == 'nl',
            onTap: () => _updateLanguage('nl'),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            code: 'es',
            name: 'Spanish',
            native: 'Español',
            selected: _selectedLanguage == 'es',
            onTap: () => _updateLanguage('es'),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            code: 'fr',
            name: 'French',
            native: 'Français',
            selected: _selectedLanguage == 'fr',
            onTap: () => _updateLanguage('fr'),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            code: 'de',
            name: 'German',
            native: 'Deutsch',
            selected: _selectedLanguage == 'de',
            onTap: () => _updateLanguage('de'),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            code: 'it',
            name: 'Italian',
            native: 'Italiano',
            selected: _selectedLanguage == 'it',
            onTap: () => _updateLanguage('it'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String code,
    required String name,
    required String native,
    required bool selected,
    required VoidCallback onTap,
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
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        native,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check,
                    color: Color(0xFFF97316),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
