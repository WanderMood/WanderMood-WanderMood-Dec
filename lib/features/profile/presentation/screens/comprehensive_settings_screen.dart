import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/settings_providers.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/home/presentation/main_app_tour.dart';
import 'package:wandermood/features/profile/presentation/widgets/travel_mode_toggle.dart';

// v2 design tokens
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmSunsetTint = Color(0xFFFDF0E8);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmSkyTint = Color(0xFFEDF5F9);
const Color _wmErrorRed = Color(0xFFDC2626);
const Color _wmErrorRedTint = Color(0xFFFEE2E2);

List<BoxShadow> _settingsCardShadow() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];

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
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: _wmCream,
      body: Column(
        children: [
          Container(
            color: _wmWhite,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 4),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: _wmDusk, size: 20),
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                    Expanded(
                      child: Text(
                        l10n.settingsHubTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _wmCharcoal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: _wmParchment),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                _buildQuickTipBanner(l10n),
                const SizedBox(height: 28),

                _buildSectionHeader(l10n.settingsSectionPrivacySecurity),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.shield_outlined,
                  label: l10n.settingsPrivacyTitle,
                  subtitle: l10n.settingsPrivacySubtitle,
                  iconBgColor: _wmForestTint,
                  iconColor: _wmForest,
                  onTap: () => context.push('/settings/privacy'),
                ),

                const SizedBox(height: 28),

                _buildSectionHeader(l10n.settingsSectionAppSettings),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.notifications_outlined,
                  label: l10n.settingsNotificationsTitle,
                  subtitle: l10n.settingsHubNotificationsSubtitle,
                  iconBgColor: _wmSkyTint,
                  iconColor: _wmSky,
                  onTap: () => context.push('/settings/notifications'),
                ),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.location_on_outlined,
                  label: l10n.settingsLocationLabel,
                  subtitle: l10n.settingsLocationSubtitle,
                  iconBgColor: _wmSunsetTint,
                  iconColor: _wmSunset,
                  onTap: () => context.push('/settings/location'),
                ),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.language_rounded,
                  label: l10n.settingsLanguageLabel,
                  subtitle: Localizations.localeOf(context).languageCode.toUpperCase(),
                  iconBgColor: _wmForestTint,
                  iconColor: _wmForest,
                  onTap: () => context.push('/settings/language'),
                ),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.travel_explore_rounded,
                  label: l10n.settingsTravelModeHelpLabel,
                  subtitle: l10n.settingsTravelModeHelpSubtitle,
                  iconBgColor: _wmSkyTint,
                  iconColor: _wmForest,
                  onTap: () => _showTravelModeHelp(context),
                ),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.psychology_alt_outlined,
                  label: l10n.moodyMemoryTitle,
                  subtitle: l10n.moodyMemorySubtitle,
                  iconBgColor: _wmForestTint,
                  iconColor: _wmForest,
                  onTap: () => context.push('/settings/moody-memory'),
                ),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.palette_outlined,
                  label: l10n.settingsThemeLabel,
                  subtitle: l10n.settingsThemeValueSystem,
                  iconBgColor: const Color(0xFFF5F0E8),
                  iconColor: _wmDusk,
                  onTap: () => context.push('/settings/theme'),
                ),

                const SizedBox(height: 28),

                _buildSectionHeader(l10n.settingsSectionMore),
                const SizedBox(height: 10),
                subscriptionAsync.when(
                  data: (_) => _buildSettingButton(
                    icon: Icons.card_membership_outlined,
                    label: l10n.settingsSubscriptionLabel,
                    subtitle: l10n.settingsSubscriptionSubtitleFree,
                    iconBgColor: _wmForestTint,
                    iconColor: _wmForest,
                    badge: l10n.settingsSubscriptionBadgeFree,
                    onTap: () => context.push('/settings/subscription'),
                  ),
                  loading: () => _buildSettingButton(
                    icon: Icons.card_membership_outlined,
                    label: l10n.settingsSubscriptionLabel,
                    subtitle: l10n.settingsSubscriptionSubtitleFree,
                    iconBgColor: _wmForestTint,
                    iconColor: _wmForest,
                    badge: l10n.settingsSubscriptionBadgeFree,
                    onTap: () => context.push('/settings/subscription'),
                  ),
                  error: (_, __) => _buildSettingButton(
                    icon: Icons.card_membership_outlined,
                    label: l10n.settingsSubscriptionLabel,
                    subtitle: l10n.settingsSubscriptionSubtitleFree,
                    iconBgColor: _wmForestTint,
                    iconColor: _wmForest,
                    badge: l10n.settingsSubscriptionBadgeFree,
                    onTap: () => context.push('/settings/subscription'),
                  ),
                ),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.download_outlined,
                  label: l10n.settingsDataStorageLabel,
                  subtitle: l10n.settingsDataStorageSubtitle,
                  iconBgColor: _wmSkyTint,
                  iconColor: _wmSky,
                  onTap: () => context.push('/settings/data'),
                ),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.touch_app_outlined,
                  label: l10n.settingsAppTourLabel,
                  subtitle: l10n.settingsAppTourSubtitle,
                  iconBgColor: _wmForestTint,
                  iconColor: _wmForest,
                  onTap: () {
                    requestMainAppTour(ref);
                    context.go('/main?tab=0');
                  },
                ),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.help_outline_rounded,
                  label: l10n.settingsHelpSupportLabel,
                  subtitle: l10n.settingsHelpSupportSubtitle,
                  iconBgColor: _wmForestTint,
                  iconColor: _wmForest,
                  onTap: () => context.push('/settings/help'),
                ),

                const SizedBox(height: 28),

                _buildSectionHeader(l10n.settingsSectionDangerZone, isDanger: true),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.delete_outline_rounded,
                  label: l10n.settingsDangerDeleteAccountLabel,
                  subtitle: l10n.settingsDangerDeleteAccountSubtitle,
                  iconBgColor: _wmErrorRedTint,
                  iconColor: _wmErrorRed,
                  isDanger: true,
                  onTap: () => context.push('/settings/delete-account'),
                ),
                const SizedBox(height: 10),
                _buildSettingButton(
                  icon: Icons.logout_rounded,
                  label: l10n.settingsDangerSignOutLabel,
                  subtitle: l10n.settingsDangerSignOutSubtitle,
                  iconBgColor: _wmErrorRedTint,
                  iconColor: _wmErrorRed,
                  isDanger: true,
                  onTap: () => _handleSignOut(context),
                ),

                const SizedBox(height: 16),
                _buildAppVersion(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTipBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmForestTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _wmParchment, width: 1),
        boxShadow: _settingsCardShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _wmWhite,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _wmParchment, width: 1),
            ),
            child: const Icon(Icons.tips_and_updates_outlined, color: _wmForest, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsQuickTipTitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _wmCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.settingsQuickTipBody,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _wmDusk,
                    height: 1.45,
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
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDanger ? _wmErrorRed : _wmStone,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _wmWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDanger ? const Color(0xFFFECACA) : _wmParchment,
              width: 1,
            ),
            boxShadow: _settingsCardShadow(),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
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
                              fontSize: 15,
                              color: isDanger ? _wmErrorRed : _wmCharcoal,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _wmSunsetTint,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _wmParchment, width: 1),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _wmSunset,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDanger ? _wmErrorRed.withValues(alpha: 0.75) : _wmStone,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDanger ? const Color(0xFFFCA5A5) : _wmStone,
                size: 20,
              ),
            ],
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
            style: GoogleFonts.poppins(fontSize: 13, color: _wmStone),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settingsAppTagline,
            style: GoogleFonts.poppins(fontSize: 11, color: _wmStone),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
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
          showWanderMoodToast(
            context,
            message: l10n.drawerErrorSigningOut(e.toString()),
            isError: true,
          );
        }
      }
    }
  }

  void _showTravelModeHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TravelModeExplanationModal(),
    );
  }
}
