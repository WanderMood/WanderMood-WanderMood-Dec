import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/domain/models/user_preferences.dart';
import 'package:wandermood/core/services/account_deletion_service.dart';
import 'package:wandermood/features/settings/presentation/providers/user_preferences_provider.dart';

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
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
          title: Text(
            'App Settings',
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
                  _buildSectionHeader('General'),
                  
                  // Notifications
                  _buildSwitchTile(
                    title: 'Notifications',
                    subtitle: 'Enable push notifications',
                    value: _notificationsEnabled,
          onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
          },
        ),
                  
                  // Location Tracking
                  _buildSwitchTile(
                    title: 'Location Tracking',
                    subtitle: 'Allow app to track your location',
                    value: _locationTrackingEnabled,
          onChanged: (value) {
                      setState(() {
                        _locationTrackingEnabled = value;
                      });
          },
        ),
                  
                  // Dark Mode
                  _buildSwitchTile(
                    title: 'Dark Mode',
                    subtitle: 'Use dark theme throughout the app',
                    value: _darkModeEnabled,
          onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader('Discovery'),
                  
                  // Distance Radius Slider
                  ListTile(
                    title: Text(
                      'Discovery Radius',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Show places within ${_distanceRadius.toStringAsFixed(1)} km',
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
                  _buildSectionHeader('Data & Privacy'),
                  
                  // Clear Cache
        ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined, color: Color(0xFF12B347)),
                    title: Text(
                      'Clear App Cache',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Free up space by removing cached images and data',
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
                      'Privacy Policy',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Read our privacy policy',
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
                      'Terms of Service',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Read our terms of service',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
          onTap: () => _openTermsOfService(),
        ),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader('Account'),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                    title: Text(
                      'Delete Account',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    subtitle: Text(
                      'Permanently delete your account and all data',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () => _showDeleteAccountDialog(),
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
                        'Save Settings',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Cache?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will remove all cached data. Your saved places and settings will not be affected.',
          style: GoogleFonts.poppins(
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
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
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12B347),
            ),
            child: Text(
              'Clear',
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
    // Save settings logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Open Privacy Policy in external browser
  Future<void> _openPrivacyPolicy() async {
    try {
      final url = Uri.parse('https://wandermood.com/en/privacy');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open Privacy Policy. Please check your internet connection.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Privacy Policy: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Open Terms of Service in external browser
  Future<void> _openTermsOfService() async {
    try {
      final url = Uri.parse('https://wandermood.com/en/terms');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open Terms of Service. Please check your internet connection.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Terms of Service: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteAccountDialog(
        onCancel: () => Navigator.pop(ctx),
        onDeleted: () {
          Navigator.pop(ctx);
          context.go('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted. You have been signed out.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onError: (String message) {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({
    required this.onCancel,
    required this.onDeleted,
    required this.onError,
  });
  final VoidCallback onCancel;
  final VoidCallback onDeleted;
  final void Function(String message) onError;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);
    final result = await AccountDeletionService().deleteAccount();
    if (!mounted) return;
    if (result.success) {
      widget.onDeleted();
    } else {
      widget.onError(result.message ?? 'Failed to delete account. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Delete Account?',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: _isDeleting
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 16),
                Text(
                  'Deleting your account…',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            )
          : Text(
              'This will permanently delete your account and all your data (profile, preferences, plans, posts). This cannot be undone.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : widget.onCancel,
          child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[700])),
        ),
        TextButton(
          onPressed: _isDeleting ? null : _deleteAccount,
          child: Text(
            _isDeleting ? 'Deleting…' : 'Delete my account',
            style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}