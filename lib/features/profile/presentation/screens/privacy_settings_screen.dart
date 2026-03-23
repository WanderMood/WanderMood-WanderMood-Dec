import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers/profile_provider.dart';
import '../widgets/settings_screen_template.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

const Color _privacyWmForest = Color(0xFF2A6049);
const Color _privacyWmForestTint = Color(0xFFEBF3EE);

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  String _selectedVisibility = 'public';
  bool _showEmail = false;
  bool _showAge = true;

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
          _selectedVisibility = profile.profileVisibility;
          _showEmail = profile.showEmail;
          _showAge = profile.showAge;
        });
      }
    });
  }

  Future<void> _updateVisibility(String value) async {
    setState(() => _selectedVisibility = value);
    try {
      await ref.read(profileProvider.notifier).updateProfile(
        profileVisibility: value,
      );
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Profile visibility updated',
        );
      }
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Error: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _updateShowEmail(bool value) async {
    setState(() => _showEmail = value);
    try {
      await ref.read(profileProvider.notifier).updateProfile(showEmail: value);
      if (mounted) {
        showWanderMoodToast(
          context,
          message: value ? 'Email will be visible to others' : 'Email is now hidden',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _showEmail = !value);
        showWanderMoodToast(
          context,
          message: 'Error: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _updateShowAge(bool value) async {
    setState(() => _showAge = value);
    try {
      await ref.read(profileProvider.notifier).updateProfile(showAge: value);
      if (mounted) {
        showWanderMoodToast(
          context,
          message: value ? 'Age will be visible to others' : 'Age is now hidden',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _showAge = !value);
        showWanderMoodToast(
          context,
          message: 'Error: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenTemplate(
      title: 'Privacy',
      onBack: () => context.pop(),
      wanderMoodV2Chrome: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Visibility',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          _buildRadioOption(
            label: 'Public',
            subtitle: 'Anyone can see your profile',
            value: 'public',
            selected: _selectedVisibility == 'public',
            onTap: () => _updateVisibility('public'),
          ),
          const SizedBox(height: 8),
          _buildRadioOption(
            label: 'Friends Only',
            subtitle: 'Only your friends can see',
            value: 'friends',
            selected: _selectedVisibility == 'friends',
            onTap: () => _updateVisibility('friends'),
          ),
          const SizedBox(height: 8),
          _buildRadioOption(
            label: 'Private',
            subtitle: 'Only you can see',
            value: 'private',
            selected: _selectedVisibility == 'private',
            onTap: () => _updateVisibility('private'),
          ),
          const SizedBox(height: 24),
          Text(
            'What Others Can See',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: 'Show Email Address',
            checked: _showEmail,
            onChange: () => _updateShowEmail(!_showEmail),
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            label: 'Show Age',
            checked: _showAge,
            onChange: () => _updateShowAge(!_showAge),
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
          color: selected ? _privacyWmForest : const Color(0xFFE5E7EB),
          width: 2,
        ),
      ),
      child: Material(
        color: selected ? _privacyWmForestTint : Colors.transparent,
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
                      color: selected ? _privacyWmForest : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: _privacyWmForest,
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

  Widget _buildToggleOption({
    required String label,
    String? subtitle,
    required bool checked,
    required VoidCallback onChange,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 2,
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
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: onChange,
              child: Container(
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  color: checked ? _privacyWmForest : const Color(0xFFD1D5DB),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
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
