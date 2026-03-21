import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../widgets/settings_screen_template.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsScreenTemplate(
      title: l10n.helpSupportScreenTitle,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 2,
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
                  color: Color(0xFF9CA3AF),
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
            icon: Icons.help_outline,
            title: l10n.helpSupportFaqTitle,
            subtitle: l10n.helpSupportFaqSubtitle,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.mail,
            title: l10n.helpSupportContactTitle,
            subtitle: l10n.helpSupportContactSubtitle,
            onTap: () => _sendEmail(context),
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.message,
            title: l10n.helpSupportLiveChatTitle,
            subtitle: l10n.helpSupportLiveChatSubtitle,
            badge: l10n.helpSupportLiveChatBadgeOnline,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.phone,
            title: l10n.helpSupportReportBugTitle,
            subtitle: l10n.helpSupportReportBugSubtitle,
            onTap: () {},
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
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.shield,
            title: l10n.helpSupportTermsTitle,
            subtitle: l10n.helpSupportTermsSubtitle,
            onTap: () {},
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
          color: const Color(0xFFF3F4F6),
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
                Icon(icon, color: const Color(0xFF374151), size: 20),
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
      query: 'subject=${Uri.encodeComponent(l10n.helpSupportEmailSubject)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
