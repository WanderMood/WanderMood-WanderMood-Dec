import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/utils/legal_url_launcher.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/constants/legal_urls.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final List<bool> _expandedItems = List.generate(6, (index) => false);

  List<({String q, String a})> _faqPairs(AppLocalizations l) => [
        (q: l.supportFaq1Q, a: l.supportFaq1A),
        (q: l.supportFaq2Q, a: l.supportFaq2A),
        (q: l.supportFaq3Q, a: l.supportFaq3A),
        (q: l.supportFaq4Q, a: l.supportFaq4A),
        (q: l.supportFaq5Q, a: l.supportFaq5A),
        (q: l.supportFaq6Q, a: l.supportFaq6A),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faq = _faqPairs(l10n);
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            l10n.helpSupport,
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2A6049),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Support options
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    l10n.supportHowCanWeHelp,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Support cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSupportCard(
                          icon: Icons.mail_outline,
                          title: l10n.supportContactUsCard,
                          onTap: _contactSupport,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSupportCard(
                          icon: Icons.feedback_outlined,
                          title: l10n.supportSendFeedbackCard,
                          onTap: _sendFeedback,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSupportCard(
                          icon: Icons.help_outline,
                          title: l10n.supportTutorialCard,
                          onTap: _showTutorial,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSupportCard(
                          icon: Icons.report_problem_outlined,
                          title: l10n.supportReportIssueCard,
                          onTap: _reportIssue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // FAQ section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    l10n.supportFaqSectionTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2A6049),
                    ),
                  ),
                ),
                
                // FAQ items
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: faq.length,
                  itemBuilder: (context, index) {
                    final pair = faq[index];
                    return Card(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: ExpansionTile(
                        initiallyExpanded: _expandedItems[index],
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _expandedItems[index] = expanded;
                          });
                        },
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          pair.q,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: Icon(
                          _expandedItems[index] 
                              ? Icons.keyboard_arrow_up 
                              : Icons.keyboard_arrow_down,
                          color: const Color(0xFF2A6049),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              pair.a,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Additional resources
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    l10n.supportAdditionalResources,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2A6049),
                    ),
                  ),
                ),
                
                _buildResourceItem(
                  title: l10n.settingsPrivacyPolicyTitle,
                  icon: Icons.privacy_tip_outlined,
                  onTap: () => _openPrivacyPolicy(),
                ),
                
                _buildResourceItem(
                  title: l10n.settingsTermsOfServiceTitle,
                  icon: Icons.gavel_outlined,
                  onTap: () => _openTermsOfService(),
                ),
                
                _buildResourceItem(
                  title: l10n.supportAppVersionLabel,
                  icon: Icons.info_outline,
                  trailing: Text(
                    '1.0.2',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    // Show version info
                  },
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Support card widget
  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF2A6049),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // Resource item widget
  Widget _buildResourceItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2A6049)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
  
  // Contact support action
  void _contactSupport() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l10n.supportContactDialogTitle,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.supportEmailUsAt,
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.helpSupportEmailAddress,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2A6049),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.supportEmailSupportHours,
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.dialogClose,
              style: GoogleFonts.poppins(
                color: const Color(0xFF2A6049),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _sendFeedback() {
    final l10n = AppLocalizations.of(context)!;
    showWanderMoodToast(context, message: l10n.supportToastOpeningFeedback);
  }
  
  void _showTutorial() {
    final l10n = AppLocalizations.of(context)!;
    showWanderMoodToast(context, message: l10n.supportToastOpeningTutorial);
  }
  
  void _reportIssue() {
    final l10n = AppLocalizations.of(context)!;
    showWanderMoodToast(context, message: l10n.supportToastOpeningIssue);
  }

  /// Open Privacy Policy in external browser
  Future<void> _openPrivacyPolicy() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final code = Localizations.localeOf(context).languageCode;
      final url = LegalUrls.privacyForLanguageCode(code);
      final ok = await launchExternalLegalUrl(url);
      if (!ok && mounted) {
        showWanderMoodToast(
          context,
          message: l10n.settingsOpenPrivacyNetworkError,
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.settingsOpenPrivacyError('$e'),
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _openTermsOfService() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final code = Localizations.localeOf(context).languageCode;
      final url = LegalUrls.termsForLanguageCode(code);
      final ok = await launchExternalLegalUrl(url);
      if (!ok && mounted) {
        showWanderMoodToast(
          context,
          message: l10n.settingsOpenTermsNetworkError,
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.settingsOpenTermsError('$e'),
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
} 