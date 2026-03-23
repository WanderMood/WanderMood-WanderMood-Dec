import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_screen_template.dart';

const Color _secWmForest = Color(0xFF2A6049);
const Color _secWmForestTint = Color(0xFFEBF3EE);
const Color _secWmParchment = Color(0xFFE8E2D8);

class AccountSecurityScreen extends ConsumerWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountSecurityAsync = ref.watch(accountSecurityProvider);

    return SettingsScreenTemplate(
      title: l10n.settingsAccountSecurityTitle,
      onBack: () => context.pop(),
      wanderMoodV2Chrome: true,
      child: accountSecurityAsync.when(
        data: (security) => _buildContent(context, security),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildContent(context, null),
      ),
    );
  }

  Widget _buildContent(BuildContext context, accountSecurity) {
    final l10n = AppLocalizations.of(context)!;
    final twoFactorEnabled = accountSecurity?.twoFactorEnabled ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingCard(
          context: context,
          icon: Icons.shield,
          title: l10n.settingsTwoFactorTitle,
          subtitle: twoFactorEnabled ? l10n.settingsTwoFactorEnabled : l10n.settingsTwoFactorNotEnabled,
          badge: twoFactorEnabled ? null : l10n.settingsTwoFactorBadgeRecommended,
          onTap: () => context.push('/settings/2fa'),
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          context: context,
          icon: Icons.visibility,
          title: l10n.settingsActiveSessionsTitle,
          subtitle: l10n.settingsActiveSessionsSubtitle('3'),
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
          color: _secWmParchment,
          width: 0.5,
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
                Icon(icon, color: _secWmForest, size: 20),
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
                                color: _secWmForestTint,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _secWmForest,
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
}
