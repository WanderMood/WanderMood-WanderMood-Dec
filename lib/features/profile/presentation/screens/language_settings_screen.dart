import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileProvider);

    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            l10n?.languageSettings ?? 'Language Settings',
            style: GoogleFonts.poppins(
              color: const Color(0xFF4CAF50),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF4CAF50)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: profileAsync.when(
          data: (profile) {
            // Get current language from profile or default to 'en'
            final currentLanguage = profile?.languagePreference ?? 'en';
            
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildLanguageOption(
                        context,
                        ref,
                        'English',
                        'en',
                        currentLanguage,
                      ),
                      const Divider(height: 1),
                      _buildLanguageOption(
                        context,
                        ref,
                        'Nederlands',
                        'nl',
                        currentLanguage,
                      ),
                      const Divider(height: 1),
                      _buildLanguageOption(
                        context,
                        ref,
                        'Español',
                        'es',
                        currentLanguage,
                      ),
                      const Divider(height: 1),
                      _buildLanguageOption(
                        context,
                        ref,
                        'Français',
                        'fr',
                        currentLanguage,
                      ),
                      const Divider(height: 1),
                      _buildLanguageOption(
                        context,
                        ref,
                        'Deutsch',
                        'de',
                        currentLanguage,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.chooseYourPreferredLanguage ?? 'Choose your preferred language for the app interface. This will affect all text and content throughout the app.',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            final errorL10n = AppLocalizations.of(context);
            // Even if profile fails to load, show language options with default 'en'
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildLanguageOption(
                        context,
                        ref,
                        'English',
                        'en',
                        'en', // Default to English if profile can't load
                      ),
                      const Divider(height: 1),
                      _buildLanguageOption(
                        context,
                        ref,
                        'Nederlands',
                        'nl',
                        'en',
                      ),
                      const Divider(height: 1),
                      _buildLanguageOption(
                        context,
                        ref,
                        'Español',
                        'es',
                        'en',
                      ),
                      const Divider(height: 1),
                      _buildLanguageOption(
                        context,
                        ref,
                        'Français',
                        'fr',
                        'en',
                      ),
                      const Divider(height: 1),
                      _buildLanguageOption(
                        context,
                        ref,
                        'Deutsch',
                        'de',
                        'en',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  errorL10n?.chooseYourPreferredLanguage ?? 'Choose your preferred language for the app interface. This will affect all text and content throughout the app.',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    String language,
    String code,
    String currentLanguage,
  ) {
    final isSelected = currentLanguage == code;

    return ListTile(
      title: Text(
        language,
        style: GoogleFonts.poppins(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF4CAF50))
          : null,
      onTap: () async {
        try {
          // Update locale immediately (works offline)
          await ref.read(localeProvider.notifier).setLocale(Locale(code));
          
          // Try to sync with profile when network is available (optional)
          try {
            await ref.read(profileProvider.notifier).updateProfile(
              languagePreference: code,
            );
          } catch (e) {
            // Continue - local locale still works
          }
          
          if (context.mounted) {
            final updatedL10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  updatedL10n?.languageUpdatedTo(language) ?? 'Language updated to $language',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: const Color(0xFF4CAF50),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to update language: ${e.toString()}',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
} 