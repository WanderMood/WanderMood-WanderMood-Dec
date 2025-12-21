import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/profile/presentation/screens/language_settings_screen.dart';
import 'package:wandermood/features/profile/presentation/screens/privacy_settings_screen.dart';
import 'package:wandermood/features/profile/presentation/screens/theme_settings_screen.dart';
import 'package:wandermood/features/profile/presentation/screens/notifications_screen.dart';
import 'package:wandermood/features/profile/presentation/screens/help_support_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/extensions/string_extensions.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authStateProvider);
    final profileState = ref.watch(profileProvider);
    
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: userState.when(
            data: (user) => profileState.when(
              data: (profile) => SingleChildScrollView(
                child: Column(
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Back button
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          // Title (centered)
                          Expanded(
                            child: Text(
                              'Your Profile',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                          // Spacer to balance the back button
                          const SizedBox(width: 48),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    
                    const SizedBox(height: 20),
                    
                    // Profile Info Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Avatar with Edit Button
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
                                    backgroundImage: profile?.imageUrl != null
                                        ? NetworkImage(profile!.imageUrl!)
                                        : null,
                                    child: profile?.imageUrl == null
                                        ? Text(
                                            profile?.fullName?.substring(0, 1).toUpperCase() ?? 
                                            profile?.email.substring(0, 1).toUpperCase() ?? 'U',
                                            style: GoogleFonts.poppins(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF4CAF50),
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    right: -8,
                                    bottom: -8,
                                    child: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4CAF50),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ProfileEditScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Username and Display Name
                              Text(
                                profile?.fullName ?? 'Add your name',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '@${profile?.username ?? 'username'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Bio
                              Text(
                                profile?.bio ?? 'Add a bio to tell your story',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Mood Streak and Favorite Mood
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '${profile?.moodStreak ?? 0}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF4CAF50),
                                        ),
                                      ),
                                      Text(
                                        'Day Streak',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 32),
                                  Column(
                                    children: [
                                      Text(
                                        profile?.favoriteMood ?? '😊',
                                        style: const TextStyle(
                                          fontSize: 24,
                                        ),
                                      ),
                                      Text(
                                        'Favorite Mood',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    // Social Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Followers/Following
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '${profile?.followersCount ?? 0}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Followers',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: 40,
                                    width: 1,
                                    color: Colors.grey[300],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '${profile?.followingCount ?? 0}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Following',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Share Profile Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Share Profile',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              QrImageView(
                                                data: 'wandermood://profile/${profile?.username ?? profile?.id}',
                                                version: QrVersions.auto,
                                                size: 200.0,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Scan to connect',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.share),
                                  label: Text(
                                    'Share Profile',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Achievements
                              if (profile?.achievements.isNotEmpty ?? false) ...[
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  'Achievements',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (profile?.achievements ?? []).map((achievement) => Chip(
                                    label: Text(
                                      achievement,
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                                  )).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    // Settings Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.emoji_events, color: Color(0xFF4CAF50)),
                              title: Text(
                                'Achievements',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.push('/gamification'),
                            ),
                            const Divider(height: 1),
                            _buildSettingItem(
                              icon: Icons.notifications_outlined,
                              title: 'Notifications',
                              subtitle: 'Manage your notifications',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _buildSettingItem(
                              icon: Icons.language_outlined,
                              title: 'Language',
                              subtitle: profile?.languagePreference.toUpperCase() ?? 'EN',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LanguageSettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _buildSettingItem(
                              icon: Icons.lock_outline,
                              title: 'Privacy',
                              subtitle: profile?.isPublic == true ? 'Public Profile' : 'Private Profile',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacySettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _buildSettingItem(
                              icon: Icons.palette_outlined,
                              title: 'Theme',
                              subtitle: profile?.themePreference.capitalize() ?? 'System',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ThemeSettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _buildSettingItem(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              subtitle: 'Get assistance',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HelpSupportScreen(),
                                  ),
                                );
                              },
                            ),

                            const Divider(height: 1),
                            _buildSettingItem(
                              icon: Icons.logout,
                              title: 'Sign Out',
                              subtitle: 'Log out of your account',
                              onTap: () => _handleSignOut(context, ref),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 1000.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading profile',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Error: $error',
                style: GoogleFonts.poppins(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    
    // If user confirms, sign out
    if (shouldSignOut == true) {
      try {
        // Show loading indicator
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Clear all relevant providers
        ref.invalidate(profileProvider);
        
        // Sign out from Supabase
        final supabase = Supabase.instance.client;
        await supabase.auth.signOut();
        
        // Clear any cached data or local storage if needed
        // TODO: Add any additional cleanup here
        
        // Navigate to login screen and remove all previous routes
        if (context.mounted) {
          // First pop the loading dialog
          Navigator.of(context).pop();
          // Then navigate to login
          context.go('/login');
        }
      } catch (e) {
        // Pop loading dialog if there's an error
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error signing out: ${e.toString()}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _handleSignOut(context, ref),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(
        title,
        style: GoogleFonts.poppins(),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF4CAF50)),
      onTap: onTap,
    );
  }
}

 