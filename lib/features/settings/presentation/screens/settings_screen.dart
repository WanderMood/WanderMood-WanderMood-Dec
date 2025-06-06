import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/domain/models/user_preferences.dart';
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
          onTap: () {
            // Navigate to privacy policy
          },
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
          onTap: () {
            // Navigate to terms of service
          },
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
} 
 
 
 