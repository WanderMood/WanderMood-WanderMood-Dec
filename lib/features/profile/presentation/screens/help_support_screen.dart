import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/home/presentation/main_app_tour.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/core/constants/legal_urls.dart';
import 'package:wandermood/core/utils/legal_url_launcher.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../widgets/settings_screen_template.dart';

const Color _hsWmForest = Color(0xFF2A6049);
const Color _hsWmForestTint = Color(0xFFEBF3EE);
const Color _hsWmParchment = Color(0xFFE8E2D8);

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsScreenTemplate(
      title: l10n.helpSupportScreenTitle,
      onBack: () => context.pop(),
      wanderMoodV2Chrome: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hsWmParchment,
                width: 0.5,
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.helpSupportSearchHint,
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: _hsWmForest,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.helpSupportQuickLinksTitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.email_outlined,
            title: l10n.helpSupportEmailSupportTitle,
            subtitle: l10n.helpSupportEmailAddress,
            onTap: () => _sendEmail(context),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.touch_app_outlined,
            title: l10n.helpSupportAppTourTitle,
            subtitle: l10n.helpSupportAppTourSubtitle,
            onTap: () {
              requestMainAppTour(ref);
              context.go('/main?tab=0');
            },
          ),
          const SizedBox(height: 24),
          Text(
            l10n.helpSupportLegalTitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.shield,
            title: l10n.helpSupportPrivacyTitle,
            subtitle: l10n.helpSupportPrivacySubtitle,
            onTap: () => _openPrivacyPolicy(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hsWmParchment,
          width: 0.5,
        ),
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
                Icon(icon, color: _hsWmForest, size: 20),
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
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _hsWmForestTint,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _hsWmForest,
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
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri(
      scheme: 'mailto',
      path: l10n.helpSupportEmailAddress,
      queryParameters: {'subject': l10n.helpSupportEmailSubject},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final code = Localizations.localeOf(context).languageCode;
    final uri = LegalUrls.privacyForLanguageCode(code);
    await launchExternalLegalUrl(uri);
  }
}
