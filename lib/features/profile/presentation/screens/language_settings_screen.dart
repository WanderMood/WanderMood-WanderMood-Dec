import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../../domain/providers/profile_provider.dart';
import '../../../../core/presentation/providers/language_provider.dart';
import '../widgets/settings_screen_template.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

/// v2 design tokens
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

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
        showWanderMoodToast(
          context,
          message: l10n.languageUpdated,
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
      wanderMoodV2Chrome: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLanguageOption(
            code: 'en',
            name: l10n.languageNameEn,
            native: l10n.languageNativeEn,
            selected: _selectedLanguage == 'en',
            onTap: () => _updateLanguage('en'),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            code: 'nl',
            name: l10n.languageNameNl,
            native: l10n.languageNativeNl,
            selected: _selectedLanguage == 'nl',
            onTap: () => _updateLanguage('nl'),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            code: 'es',
            name: l10n.languageNameEs,
            native: l10n.languageNativeEs,
            selected: _selectedLanguage == 'es',
            onTap: () => _updateLanguage('es'),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            code: 'fr',
            name: l10n.languageNameFr,
            native: l10n.languageNativeFr,
            selected: _selectedLanguage == 'fr',
            onTap: () => _updateLanguage('fr'),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            code: 'de',
            name: l10n.languageNameDe,
            native: l10n.languageNativeDe,
            selected: _selectedLanguage == 'de',
            onTap: () => _updateLanguage('de'),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            code: 'it',
            name: l10n.languageNameIt,
            native: l10n.languageNativeIt,
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
        color: _wmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _wmForest : _wmParchment,
          width: selected ? 1.5 : 0.5,
        ),
      ),
      child: Material(
        color: selected ? _wmForestTint : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: _wmForest.withValues(alpha: 0.08),
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
                          color: _wmCharcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        native,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _wmStone,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    color: _wmForest,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
