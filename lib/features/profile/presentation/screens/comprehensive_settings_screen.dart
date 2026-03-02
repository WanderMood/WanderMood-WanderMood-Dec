import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../domain/providers/profile_provider.dart';
import '../../../gamification/providers/gamification_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/presentation/providers/local_theme_provider.dart';
import '../providers/settings_providers.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';

class ComprehensiveSettingsScreen extends ConsumerStatefulWidget {
  const ComprehensiveSettingsScreen({super.key});

  @override
  ConsumerState<ComprehensiveSettingsScreen> createState() => _ComprehensiveSettingsScreenState();
}

class _ComprehensiveSettingsScreenState extends ConsumerState<ComprehensiveSettingsScreen> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileProvider);
    final gamificationState = ref.watch(gamificationProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);
    
    // Get unlocked achievements count
    final unlockedCount = gamificationState.achievements
        .where((a) => a.unlocked)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SwirlBackground(
        child: Column(
          children: [
            // Header - white background, border-bottom, sticky
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 4,
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF374151), size: 20), // gray-600
                        onPressed: () => context.pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.settingsHubTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937), // gray-800
                          ),
                        ),
                      ),
                      const SizedBox(width: 44), // Empty space on right
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)), // border-gray-200
            
            // Body
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                  // Quick Tip Banner
                  _buildQuickTipBanner(l10n),
                  const SizedBox(height: 32), // space-y-8
                  
                  // Privacy & Security Section
                  _buildSectionHeader(l10n.settingsSectionPrivacySecurity),
                  const SizedBox(height: 12), // mb-3
                  _buildSettingButton(
                    icon: Icons.lock,
                    label: l10n.settingsAccountSecurityTitle,
                    subtitle: l10n.settingsAccountSecuritySubtitle,
                    iconBgColor: const Color(0xFFFEE2E2), // red-100
                    iconColor: const Color(0xFFDC2626), // red-600
                    onTap: () => context.push('/settings/account-security'),
                  ),
                  const SizedBox(height: 12), // space-y-3
                  _buildSettingButton(
                    icon: Icons.shield,
                    label: l10n.settingsPrivacyTitle,
                    subtitle: l10n.settingsPrivacySubtitle,
                    iconBgColor: const Color(0xFFDCFCE7), // green-100
                    iconColor: const Color(0xFF16A34A), // green-600
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  
                  const SizedBox(height: 32), // space-y-8
                  
                  // App Settings Section
                  _buildSectionHeader(l10n.settingsSectionAppSettings),
                  const SizedBox(height: 12), // mb-3
                  _buildSettingButton(
                    icon: Icons.notifications,
                    label: l10n.settingsNotificationsTitle,
                    subtitle: l10n.settingsHubNotificationsSubtitle,
                    iconBgColor: const Color(0xFFDBEAFE), // blue-100
                    iconColor: const Color(0xFF2563EB), // blue-600
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  const SizedBox(height: 12), // space-y-3
                  _buildSettingButton(
                    icon: Icons.location_on,
                    label: l10n.settingsLocationLabel,
                    subtitle: l10n.settingsLocationSubtitle,
                    iconBgColor: const Color(0xFFF3E8FF), // purple-100
                    iconColor: const Color(0xFF9333EA), // purple-600
                    onTap: () => context.push('/settings/location'),
                  ),
                  const SizedBox(height: 12), // space-y-3
                  _buildSettingButton(
                    icon: Icons.language,
                    label: l10n.settingsLanguageLabel,
                    subtitle: Localizations.localeOf(context).languageCode.toUpperCase(),
                    iconBgColor: const Color(0xFFE0E7FF), // indigo-100
                    iconColor: const Color(0xFF4F46E5), // indigo-600
                    onTap: () => context.push('/settings/language'),
                  ),
                  const SizedBox(height: 12), // space-y-3
                  _buildSettingButton(
                    icon: Icons.palette,
                    label: l10n.settingsThemeLabel,
                    subtitle: l10n.settingsThemeValueSystem,
                    iconBgColor: const Color(0xFFFCE7F3), // pink-100
                    iconColor: const Color(0xFFEC4899), // pink-600
                    onTap: () => context.push('/settings/theme'),
                  ),
                  
                  const SizedBox(height: 32), // space-y-8
                  
                  // More Section
                  _buildSectionHeader(l10n.settingsSectionMore),
                  const SizedBox(height: 12), // mb-3
                  subscriptionAsync.when(
                    data: (subscription) => _buildSettingButton(
                      icon: Icons.credit_card,
                      label: l10n.settingsSubscriptionLabel,
                      subtitle: l10n.settingsSubscriptionSubtitleFree,
                      iconBgColor: const Color(0xFFD1FAE5), // emerald-100
                      iconColor: const Color(0xFF10B981), // emerald-600
                      badge: l10n.settingsSubscriptionBadgeFree,
                      onTap: () => context.push('/settings/subscription'),
                    ),
                    loading: () => _buildSettingButton(
                      icon: Icons.credit_card,
                      label: l10n.settingsSubscriptionLabel,
                      subtitle: l10n.settingsSubscriptionSubtitleFree,
                      iconBgColor: const Color(0xFFD1FAE5),
                      iconColor: const Color(0xFF10B981),
                      badge: l10n.settingsSubscriptionBadgeFree,
                      onTap: () => context.push('/settings/subscription'),
                    ),
                    error: (_, __) => _buildSettingButton(
                      icon: Icons.credit_card,
                      label: l10n.settingsSubscriptionLabel,
                      subtitle: l10n.settingsSubscriptionSubtitleFree,
                      iconBgColor: const Color(0xFFD1FAE5),
                      iconColor: const Color(0xFF10B981),
                      badge: l10n.settingsSubscriptionBadgeFree,
                      onTap: () => context.push('/settings/subscription'),
                    ),
                  ),
                  const SizedBox(height: 12), // space-y-3
                  _buildSettingButton(
                    icon: Icons.download,
                    label: l10n.settingsDataStorageLabel,
                    subtitle: l10n.settingsDataStorageSubtitle,
                    iconBgColor: const Color(0xFFCFFAFE), // cyan-100
                    iconColor: const Color(0xFF06B6D4), // cyan-600
                    onTap: () => context.push('/settings/data'),
                  ),
                  const SizedBox(height: 12), // space-y-3
                  _buildSettingButton(
                    icon: Icons.help_outline,
                    label: l10n.settingsHelpSupportLabel,
                    subtitle: l10n.settingsHelpSupportSubtitle,
                    iconBgColor: const Color(0xFFCCFBF1), // teal-100
                    iconColor: const Color(0xFF14B8A6), // teal-600
                    onTap: () => context.push('/settings/help'),
                  ),
                  
                  const SizedBox(height: 32), // space-y-8
                  
                  // Danger Zone
                  _buildSectionHeader(l10n.settingsSectionDangerZone, isDanger: true),
                  const SizedBox(height: 12), // mb-3
                  _buildSettingButton(
                    icon: Icons.delete_outline,
                    label: l10n.settingsDangerDeleteAccountLabel,
                    subtitle: l10n.settingsDangerDeleteAccountSubtitle,
                    iconBgColor: const Color(0xFFFEE2E2), // red-100
                    iconColor: const Color(0xFFDC2626), // red-600
                    isDanger: true,
                    onTap: () => context.push('/settings/delete-account'),
                  ),
                  const SizedBox(height: 12), // space-y-3
                  _buildSettingButton(
                    icon: Icons.logout,
                    label: l10n.settingsDangerSignOutLabel,
                    subtitle: l10n.settingsDangerSignOutSubtitle,
                    iconBgColor: const Color(0xFFFEE2E2), // red-100
                    iconColor: const Color(0xFFDC2626), // red-600
                    isDanger: true,
                    onTap: () => _handleSignOut(context),
                  ),
                  
                  const SizedBox(height: 16), // pt-4
                  
                  // App Version
                  _buildAppVersion(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTipBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFEDD5), // orange-100
            Color(0xFFFCE7F3), // pink-100
          ],
        ),
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        border: Border.all(
          color: const Color(0xFFFED7AA), // orange-200
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
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF97316), // orange-500
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 ${l10n.settingsQuickTipTitle}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF1F2937), // gray-800
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.settingsQuickTipBody,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF374151), // gray-700
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8), // px-2
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDanger 
              ? const Color(0xFFEF4444) // red-500
              : const Color(0xFF6B7280), // gray-500
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
    String? badge,
    bool isDanger = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // rounded-2xl
        border: isDanger
            ? Border.all(
                color: const Color(0xFFFECACA), // red-200
                width: 2,
              )
            : null,
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
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isDanger
                                    ? const Color(0xFFDC2626) // red-600
                                    : const Color(0xFF1F2937), // gray-800
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5), // orange-100
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFEA580C), // orange-600
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDanger
                              ? const Color(0xFFEF4444) // red-500
                              : const Color(0xFF6B7280), // gray-500
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: isDanger
                      ? const Color(0xFFFCA5A5) // red-400
                      : const Color(0xFF9CA3AF), // gray-400
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppVersion() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        children: [
          Text(
            l10n.settingsAppVersion(_appVersion ?? '1.0.0'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF9CA3AF), // gray-400
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settingsAppTagline,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9CA3AF), // gray-400
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogTheme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppLocalizations.of(dialogContext)!.settingsSignOutTitle,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppLocalizations.of(dialogContext)!.settingsSignOutMessage,
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(dialogContext)!.settingsDialogCancel, style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogTheme.colorScheme.error,
                foregroundColor: dialogTheme.colorScheme.onError,
              ),
              child: Text(AppLocalizations.of(dialogContext)!.settingsSignOutConfirm, style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true && mounted) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          context.go('/auth');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.drawerErrorSigningOut(e.toString())),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
