import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/domain/models/user_preferences.dart';
import 'package:wandermood/features/settings/presentation/providers/user_preferences_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationTrackingEnabled = true;
  bool _darkModeEnabled = false;
  double _distanceRadius = 10.0; // in kilometers

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
          title: Text(
            l10n.appSettings,
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12B347),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(l10n.settingsSectionGeneral),
                  
                  // Notifications
                  _buildSwitchTile(
                    title: l10n.settingsNotificationsTitle,
                    subtitle: l10n.settingsNotificationsSubtitle,
                    value: _notificationsEnabled,
          onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
          },
        ),
                  
                  // Location Tracking
                  _buildSwitchTile(
                    title: l10n.settingsLocationTrackingTitle,
                    subtitle: l10n.settingsLocationTrackingSubtitle,
                    value: _locationTrackingEnabled,
          onChanged: (value) {
                      setState(() {
                        _locationTrackingEnabled = value;
                      });
          },
        ),
                  
                  // Dark Mode
                  _buildSwitchTile(
                    title: l10n.settingsDarkModeTitle,
                    subtitle: l10n.settingsDarkModeSubtitle,
                    value: _darkModeEnabled,
          onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader(l10n.settingsSectionDiscovery),
                  
                  // Distance Radius Slider
                  ListTile(
                    title: Text(
                      l10n.settingsDiscoveryRadiusTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsDiscoveryRadiusSubtitle(
                            _distanceRadius.toStringAsFixed(1),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Slider(
                          value: _distanceRadius,
                          min: 1.0,
                          max: 50.0,
                          divisions: 49,
                          activeColor: const Color(0xFF12B347),
          onChanged: (value) {
                            setState(() {
                              _distanceRadius = value;
                            });
          },
        ),
      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader(l10n.settingsSectionDataPrivacy),
                  
                  // Clear Cache
        ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined, color: Color(0xFF12B347)),
                    title: Text(
                      l10n.settingsClearCacheTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      l10n.settingsClearCacheSubtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () => _showClearCacheDialog(),
        ),
                  
                  // Privacy Policy
        ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF12B347)),
                    title: Text(
                      l10n.settingsPrivacyPolicyTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      l10n.settingsPrivacyPolicySubtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
          onTap: () => _openPrivacyPolicy(),
        ),
                  
                  // Terms of Service
        ListTile(
                    leading: const Icon(Icons.gavel_outlined, color: Color(0xFF12B347)),
                    title: Text(
                      l10n.settingsTermsOfServiceTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      l10n.settingsTermsOfServiceSubtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
          onTap: () => _openTermsOfService(),
        ),
                  
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12B347),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.settingsSaveButton,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to build section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF12B347),
            ),
          ),
          const Divider(thickness: 1),
        ],
      ),
    );
  }
  
  // Helper method to build switch tiles
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      activeColor: const Color(0xFF12B347),
      onChanged: onChanged,
    );
  }
  
  // Show confirmation dialog for clearing cache
  void _showClearCacheDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.settingsClearCacheDialogTitle,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          l10n.settingsClearCacheDialogBody,
          style: GoogleFonts.poppins(
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.settingsDialogCancel,
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                ),
          ),
        ),
          ElevatedButton(
            onPressed: () {
              // Clear cache logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.settingsCacheCleared),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12B347),
            ),
            child: Text(
              l10n.settingsDialogConfirmClear,
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          ),
      ],
      ),
    );
  }
  
  // Save settings method
  void _saveSettings() {
    final l10n = AppLocalizations.of(context)!;
    // Save settings logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsSaved),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Open Privacy Policy in external browser
  Future<void> _openPrivacyPolicy() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final url = Uri.parse('https://wandermood.app/privacy-policy');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settingsOpenPrivacyNetworkError),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsOpenPrivacyError(e.toString())),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Open Terms of Service in external browser
  Future<void> _openTermsOfService() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final url = Uri.parse('https://wandermood.app/terms-of-service');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settingsOpenTermsNetworkError),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsOpenTermsError(e.toString())),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}