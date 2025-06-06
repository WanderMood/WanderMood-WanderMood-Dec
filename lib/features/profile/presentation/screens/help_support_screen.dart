import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Help & Support',
            style: GoogleFonts.poppins(
              color: const Color(0xFF4CAF50),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF4CAF50)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Quick Actions Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            Icons.email_outlined,
                            'Contact Us',
                            () => _sendEmail(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            Icons.chat_bubble_outline,
                            'Live Chat',
                            () => _showLiveChatDialog(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // FAQ Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 12),
                        Text(
                          'Frequently Asked Questions',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildFAQItem(
                    'How do I track my mood?',
                    'Go to the Moody tab and tap the mood tracker to record your current feeling.',
                  ),
                  _buildFAQItem(
                    'How do I save places I like?',
                    'When viewing a place in Explore, tap the heart icon to save it to your favorites.',
                  ),
                  _buildFAQItem(
                    'Can I share my activities with friends?',
                    'Yes! Use the Social tab to share activities and see what your friends are doing.',
                  ),
                  _buildFAQItem(
                    'How do I change my profile picture?',
                    'Go to Profile > Edit Profile and tap on your current profile picture.',
                  ),
                  _buildFAQItem(
                    'How do I turn off notifications?',
                    'Go to Profile > Notifications to customize your notification preferences.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // App Info Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInfoItem(
                    Icons.info_outline,
                    'App Version',
                    '1.0.0',
                    null,
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    Icons.privacy_tip_outlined,
                    'Privacy Policy',
                    'View our privacy policy',
                    () => _openPrivacyPolicy(),
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    Icons.description_outlined,
                    'Terms of Service',
                    'View terms and conditions',
                    () => _openTermsOfService(),
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    Icons.star_outline,
                    'Rate the App',
                    'Help us improve WanderMood',
                    () => _rateApp(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Troubleshooting Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.build_outlined, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 12),
                        Text(
                          'Troubleshooting',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildInfoItem(
                    Icons.refresh,
                    'Reset App Data',
                    'Clear cache and refresh',
                    () => _showResetDialog(context),
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    Icons.bug_report_outlined,
                    'Report a Bug',
                    'Help us fix issues',
                    () => _reportBug(),
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    Icons.feedback_outlined,
                    'Send Feedback',
                    'Share your suggestions',
                    () => _sendFeedback(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Contact Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Need More Help?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our support team is here to help you Monday through Friday, 9 AM to 6 PM.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email, color: Color(0xFF4CAF50), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'support@wandermood.app',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4CAF50), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4CAF50),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
      iconColor: const Color(0xFF4CAF50),
      collapsedIconColor: Colors.grey[600],
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            answer,
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: onTap != null 
          ? const Icon(Icons.chevron_right, color: Color(0xFF4CAF50))
          : null,
      onTap: onTap,
    );
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@wandermood.app',
      query: 'subject=WanderMood Support Request',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://wandermood.app/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openTermsOfService() async {
    final Uri url = Uri.parse('https://wandermood.app/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _rateApp() async {
    // This would open the app store for rating
    // For iOS: App Store
    // For Android: Google Play Store
  }

  Future<void> _reportBug() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'bugs@wandermood.app',
      query: 'subject=Bug Report - WanderMood',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _sendFeedback() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'feedback@wandermood.app',
      query: 'subject=Feedback - WanderMood',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _showLiveChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Live Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Live chat is currently unavailable. Please contact us via email for immediate assistance.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendEmail();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset App Data',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will clear your app cache and preferences. Your profile data will remain safe.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'App data reset successfully',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
} 