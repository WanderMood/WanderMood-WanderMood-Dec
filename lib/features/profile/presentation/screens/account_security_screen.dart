import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_screen_template.dart';

class AccountSecurityScreen extends ConsumerWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountSecurityAsync = ref.watch(accountSecurityProvider);
    
    return SettingsScreenTemplate(
      title: 'Account Security',
      onBack: () => context.pop(),
      child: accountSecurityAsync.when(
        data: (security) => _buildContent(context, security),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildContent(context, null),
      ),
    );
  }

  Widget _buildContent(BuildContext context, accountSecurity) {
    final passwordChangedAt = accountSecurity?.passwordChangedAt;
    final twoFactorEnabled = accountSecurity?.twoFactorEnabled ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingCard(
          context: context,
          icon: Icons.lock,
          title: 'Change Password',
          subtitle: passwordChangedAt != null
              ? 'Last changed ${_formatDate(passwordChangedAt)}'
              : 'Last changed 3 months ago',
          onTap: () => context.push('/settings/change-password'),
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          context: context,
          icon: Icons.shield,
          title: 'Two-Factor Authentication',
          subtitle: twoFactorEnabled ? 'Enabled' : 'Not enabled',
          badge: twoFactorEnabled ? null : 'Recommended',
          onTap: () => context.push('/settings/2fa'),
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          context: context,
          icon: Icons.visibility,
          title: 'Active Sessions',
          subtitle: '3 devices',
          onTap: () => context.push('/settings/sessions'),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // rounded-xl
        border: Border.all(
          color: const Color(0xFFF3F4F6), // gray-100
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF374151), size: 20), // gray-600
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: const Color(0xFF1F2937), // gray-800
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5), // green-100
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF16A34A), // green-600
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280), // gray-500
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF), // gray-400
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
