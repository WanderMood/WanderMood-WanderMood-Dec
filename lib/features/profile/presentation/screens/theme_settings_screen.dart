import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/core/presentation/providers/local_theme_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(localThemeProvider);
    final localThemeNotifier = ref.read(localThemeProvider.notifier);
    final themeBrightness = Theme.of(context).brightness;
    
    print('🎨 ThemeSettingsScreen: currentTheme=$currentTheme, brightness=$themeBrightness');

    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Theme Settings',
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
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildThemeOption(
                    context,
                    ref,
                    'System',
                    'system',
                    Icons.brightness_auto,
                    'Follow system theme',
                    localThemeNotifier.currentThemeString,
                  ),
                  const Divider(height: 1),
                  _buildThemeOption(
                    context,
                    ref,
                    'Light',
                    'light',
                    Icons.light_mode,
                    'Light theme',
                    localThemeNotifier.currentThemeString,
                  ),
                  const Divider(height: 1),
                  _buildThemeOption(
                    context,
                    ref,
                    'Dark',
                    'dark',
                    Icons.dark_mode,
                    'Dark theme',
                    localThemeNotifier.currentThemeString,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose your preferred theme for the app. You can follow your system settings or choose a specific theme.',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Debug info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Local Theme: ${localThemeNotifier.currentThemeString}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    Text(
                      'App Theme Mode: $currentTheme',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    Text(
                      'UI Brightness: $themeBrightness',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String title,
    String value,
    IconData icon,
    String description,
    String currentTheme,
  ) {
    final isSelected = currentTheme == value;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        description,
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF4CAF50))
          : null,
      onTap: () async {
        try {
          // Update local theme immediately (works offline)
          await ref.read(localThemeProvider.notifier).setThemeFromString(value);
          
          // Try to sync with profile when network is available (optional)
          try {
            await ref.read(profileProvider.notifier).updateProfile(
              themePreference: value,
            );
            print('🎨 Theme synced to profile successfully');
          } catch (e) {
            print('🎨 Could not sync theme to profile (offline): $e');
            // Continue - local theme still works
          }
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Theme updated to $title',
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
                  'Failed to update theme: ${e.toString()}',
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