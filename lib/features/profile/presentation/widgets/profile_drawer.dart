import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/auth/providers/user_provider.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/features/profile/presentation/screens/language_settings_screen.dart';
import 'package:wandermood/features/profile/presentation/screens/help_support_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({Key? key}) : super(key: key);

  String _getTravellerLevel(int? moodStreak) {
    if (moodStreak == null) return 'New Explorer';
    if (moodStreak > 100) return 'Master Wanderer';
    if (moodStreak > 50) return 'Adventure Expert';
    if (moodStreak > 20) return 'Seasoned Explorer';
    if (moodStreak > 10) return 'Travel Enthusiast';
    return 'New Explorer';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileData = ref.watch(profileProvider);
    final mediaQuery = MediaQuery.of(context);

    return Drawer(
      backgroundColor: const Color(0xFFFDF6EC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      child: SafeArea(
        child: Column(
          children: [
            // Header section with reduced height
            SizedBox(
              height: 180, // Reduced from 200
              child: profileData.when(
                data: (profile) => Stack(
                  children: [
                    // Background gradient and pattern
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4CAF50).withOpacity(0.8),
                            const Color(0xFF2E7D32).withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                    // Overlay gradient for depth
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4CAF50).withOpacity(0.9),
                            const Color(0xFF2E7D32).withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                    // Content with reduced padding
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // Reduced padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  // Navigate to main profile screen (source of truth in bottom nav)
                                  context.push('/profile');
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 32, // Slightly reduced from 35
                                    backgroundColor: Colors.white,
                                    backgroundImage: profile?.imageUrl != null
                                        ? NetworkImage(profile!.imageUrl!)
                                        : null,
                                    child: profile?.imageUrl == null
                                        ? Text(
                                            profile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                            style: GoogleFonts.poppins(
                                              fontSize: 24, // Reduced from 28
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF12B347),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              // Edit icon overlay
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
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
                                    Icons.edit,
                                    size: 14, // Reduced from 16
                                    color: Color(0xFF12B347),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8), // Reduced from 12
                          Text(
                            profile?.fullName ?? 'User',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18, // Reduced from 20
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2), // Reduced from 4
                          Text(
                            profile?.email ?? '',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12, // Reduced from 14
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8), // Reduced from 12
                          // Travel badge and streak
                          Wrap(
                            spacing: 6, // Reduced from 8
                            runSpacing: 6, // Reduced from 8
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10), // Reduced from 12
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.stars,
                                      color: Colors.amber,
                                      size: 12, // Reduced from 14
                                    ),
                                    const SizedBox(width: 3), // Reduced from 4
                                    Text(
                                      _getTravellerLevel(profile?.moodStreak),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 10, // Reduced from 11
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10), // Reduced from 12
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department,
                                      color: Colors.orange,
                                      size: 12, // Reduced from 14
                                    ),
                                    const SizedBox(width: 3), // Reduced from 4
                                    Text(
                                      '${profile?.moodStreak ?? 0} Day Streak',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 10, // Reduced from 11
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                loading: () => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF12B347), Color(0xFF0F9A3F)],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
                error: (_, __) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF12B347), Color(0xFF0F9A3F)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 32, // Reduced from 40
                      ),
                      const SizedBox(height: 6), // Reduced from 8
                      Text(
                        'Error loading profile',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12, // Reduced from 14
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Menu items in a scrollable list
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    _buildSectionHeader('Your Journey'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.history,
                      title: 'Mood History',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/moods/history');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.favorite_border,
                      title: 'Saved Places',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/places/saved');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.map_outlined,
                      title: 'My Bookings',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/plans');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildSectionHeader('Settings'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'App Settings',
                      onTap: () {
                        Navigator.pop(context);
                        // Route to Profile settings (the main settings hub)
                        context.push('/profile');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/notifications');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.language,
                      title: 'Language',
                      onTap: () {
                        Navigator.pop(context);
                        // Route directly to Profile's Language Settings (the working one)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LanguageSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        // Route to Profile's Help & Support (the comprehensive one)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildSectionHeader('Account'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to main profile screen (source of truth in bottom nav)
                        context.push('/profile');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.logout,
                      title: 'Log Out',
                      onTap: () async {
                        try {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            context.go('/auth/magic-link');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error signing out: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF757575),
              letterSpacing: 0.5,
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.black12,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        icon,
        color: const Color(0xFF12B347),
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF2D2D2D),
        ),
      ),
      onTap: onTap,
    );
  }
} 