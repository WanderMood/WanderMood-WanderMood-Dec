import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  // Track expanded FAQ items
  final List<bool> _expandedItems = List.generate(6, (index) => false);
  
  // FAQ items
  final List<Map<String, String>> _faqItems = [
    {
      'question': 'How do I plan a new adventure?',
      'answer': 'To plan a new adventure, go to the Explore tab and select "New Adventure". You can then choose your mood, interests, and travel preferences to get personalized recommendations.'
    },
    {
      'question': 'Can I save places for later?',
      'answer': 'Yes! When viewing a place, tap the heart icon to save it to your Saved Places, which you can access from your profile menu.'
    },
    {
      'question': 'How do I track my mood?',
      'answer': 'WanderMood will remind you to track your mood daily. You can also manually add a mood entry by tapping the Moody tab and selecting "How are you feeling today?"'
    },
    {
      'question': 'What do the achievement badges mean?',
      'answer': 'Badges are earned by completing various activities in the app. Visit the Achievements section in your profile to see the requirements for each badge.'
    },
    {
      'question': 'How does WanderMood use my location?',
      'answer': 'WanderMood uses your location to provide personalized recommendations for places and activities nearby. You can adjust location permissions in the app settings.'
    },
    {
      'question': 'Can I use WanderMood offline?',
      'answer': 'Some features of WanderMood require an internet connection. However, saved places and activities can be viewed offline.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Help & Support',
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
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Support options
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'How can we help you?',
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
                          title: 'Contact Us',
                          onTap: _contactSupport,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSupportCard(
                          icon: Icons.feedback_outlined,
                          title: 'Send Feedback',
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
                          title: 'Tutorial',
                          onTap: _showTutorial,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSupportCard(
                          icon: Icons.report_problem_outlined,
                          title: 'Report Issue',
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
                    'Frequently Asked Questions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF12B347),
                    ),
                  ),
                ),
                
                // FAQ items
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _faqItems.length,
                  itemBuilder: (context, index) {
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
                          _faqItems[index]['question']!,
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
                          color: const Color(0xFF12B347),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              _faqItems[index]['answer']!,
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
                    'Additional Resources',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF12B347),
                    ),
                  ),
                ),
                
                _buildResourceItem(
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () => _openPrivacyPolicy(),
                ),
                
                _buildResourceItem(
                  title: 'Terms of Service',
                  icon: Icons.gavel_outlined,
                  onTap: () => _openTermsOfService(),
                ),
                
                _buildResourceItem(
                  title: 'App Version',
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
              color: const Color(0xFF12B347),
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
      leading: Icon(icon, color: const Color(0xFF12B347)),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Contact Support',
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
              'Email us at:',
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'support@wandermood.com',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF12B347),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Our support team is available Monday-Friday, 9am-5pm PST.',
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: const Color(0xFF12B347),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Send feedback action
  void _sendFeedback() {
    // Open feedback form or email
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening feedback form...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Show tutorial action
  void _showTutorial() {
    // Show app tutorial
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening app tutorial...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Report issue action
  void _reportIssue() {
    // Open issue reporting form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening issue report form...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Open Privacy Policy in external browser
  Future<void> _openPrivacyPolicy() async {
    try {
      final url = Uri.parse('https://wandermood.app/privacy-policy');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open Privacy Policy. Please check your internet connection.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Privacy Policy: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Open Terms of Service in external browser
  Future<void> _openTermsOfService() async {
    try {
      final url = Uri.parse('https://wandermood.app/terms-of-service');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open Terms of Service. Please check your internet connection.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Terms of Service: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 