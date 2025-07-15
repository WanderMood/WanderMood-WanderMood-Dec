import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/auth/providers/user_provider.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:wandermood/features/social/application/providers/diary_provider.dart';
import 'package:wandermood/features/social/domain/models/diary_entry.dart';

class DiariesHubScreen extends ConsumerStatefulWidget {
  const DiariesHubScreen({super.key});

  @override
  ConsumerState<DiariesHubScreen> createState() => _DiariesHubScreenState();
}

class _DiariesHubScreenState extends ConsumerState<DiariesHubScreen> {
  int _selectedTabIndex = 0; // 0: Friends, 1: Discover
  
  @override
  Widget build(BuildContext context) {
    final profileData = ref.watch(profileProvider);
    
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const ProfileDrawer(),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header matching My Day and Explore screens
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Profile avatar/button that works as a hamburger menu
                              Builder(
                                builder: (context) => GestureDetector(
                                  onTap: () {
                                    // Open the drawer (hamburger menu)
                                    Scaffold.of(context).openDrawer();
                                  },
                                  child: profileData.when(
                                    data: (profile) => Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: profile?.imageUrl != null && profile!.imageUrl!.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(profile.imageUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                        color: profile?.imageUrl == null ? Colors.white : null,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: profile?.imageUrl == null
                                          ? Center(
                                              child: Text(
                                                profile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF12B347),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    loading: () => Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    error: (_, __) => Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'W',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF12B347),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Diaries',
                                style: GoogleFonts.museoModerno(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF12B347),
                                ),
                              ),
                            ],
                          ),
                          // Write button
                          Material(
                            color: const Color(0xFF12B347),
                            borderRadius: BorderRadius.circular(20),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                context.push('/diaries/create-entry');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '✍️',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Write',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Your Profile Section
                      Consumer(
                        builder: (context, ref, child) {
                          final userProfileAsync = ref.watch(currentUserProfileProvider);
                          return userProfileAsync.when(
                            data: (userProfile) {
                              if (userProfile == null) return const SizedBox.shrink();
                              return GestureDetector(
                                onTap: () {
                                  context.push('/diaries/profile/demo_user?username=${Uri.encodeComponent('wanderer_you')}');
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF12B347).withOpacity(0.1),
                                          border: Border.all(
                                            color: const Color(0xFF12B347),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'W',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF12B347),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userProfile.username,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF2D3748),
                                              ),
                                            ),
                                            Text(
                                              userProfile.bio ?? 'Exploring the Netherlands one mood at a time 🌍✨',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: const Color(0xFF718096),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${userProfile.totalDiaries}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF2D3748),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Entries',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: const Color(0xFF718096),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Color(0xFF718096),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),
                      // Tab buttons for Friends/Discover
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTabIndex = 0;
                                });
                              },
                              child: _buildTabButton('👥 Friends', _selectedTabIndex == 0),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTabIndex = 1;
                                });
                              },
                              child: _buildTabButton('🌍 Discover', _selectedTabIndex == 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Warm welcome message
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F1E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE8E2D4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B4513).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _selectedTabIndex == 0 ? '👥' : '🌍',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTabIndex == 0
                                ? 'Stories from your friends'
                                : 'Discover amazing places',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedTabIndex == 0
                            ? 'See what your travel buddies have been up to lately 🗺️'
                            : 'Real stories and hidden gems from fellow wanderers ✨',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF718096),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Real diary entries
              Consumer(
                builder: (context, ref, child) {
                  final entriesProvider = _selectedTabIndex == 0 
                      ? friendsDiariesProvider 
                      : discoverDiariesProvider;
                  
                  final entriesAsync = ref.watch(entriesProvider);
                  
                  return entriesAsync.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  _selectedTabIndex == 0 
                                      ? Icons.people_outline 
                                      : Icons.explore_outlined,
                                  size: 64,
                                  color: const Color(0xFF718096),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedTabIndex == 0 
                                      ? 'No friends entries yet'
                                      : 'No diary entries yet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedTabIndex == 0
                                      ? 'Follow some travelers to see their stories here'
                                      : 'Be the first to share your travel story!\nTap "Write" to create your first diary entry.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF718096),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildDiaryEntryCard(context, entries[index]);
                          },
                          childCount: entries.length,
                        ),
                      );
                    },
                    loading: () => SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(40),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
                          ),
                        ),
                      ),
                    ),
                    error: (error, stack) => SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: const Color(0xFFE55B4C),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading diary entries',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE55B4C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$error',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF718096),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF12B347) : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isActive ? const Color(0xFF12B347) : const Color(0xFFE2E8F0), 
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : const Color(0xFF718096),
        ),
      ),
    );
  }
  
  Widget _buildDiaryEntryCard(BuildContext context, DiaryEntry entry) {
    return GestureDetector(
      onTap: () {
        context.push('/diaries/entry/${entry.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and mood
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF12B347),
                        width: 2,
                      ),
                      color: const Color(0xFF12B347).withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.person,
                      color: const Color(0xFF12B347),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                context.push('/diaries/profile/${entry.userId}?username=${Uri.encodeComponent(entry.userName ?? 'Anonymous')}');
                              },
                              child: Text(
                                entry.userName ?? 'Anonymous',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF12B347),
                                  decoration: TextDecoration.underline,
                                  decorationColor: const Color(0xFF12B347),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getMoodColor(entry.mood).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.mood,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getMoodColor(entry.mood),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (entry.location != null) ...[
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: const Color(0xFF8B7355),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.location!,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF718096),
                                ),
                              ),
                              const Spacer(),
                            ],
                            Text(
                              _formatTime(entry.createdAt),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFFA0AEC0),
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
            
            // Story text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                entry.story,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF4A5568),
                  height: 1.6,
                ),
              ),
            ),
            
            // Photo placeholder
            Container(
              margin: const EdgeInsets.all(20),
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F1E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE8E2D4),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 40,
                      color: const Color(0xFF8B7355),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📸 Photos from this adventure',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF718096),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Discovery tags
            if (entry.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: entry.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12B347).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF12B347).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF12B347),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            
            // Soft actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildSoftAction(
                    icon: entry.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '💕 ${entry.likesCount}',
                    color: entry.isLiked ? const Color(0xFFE55B4C) : null,
                  ),
                  const SizedBox(width: 24),
                  _buildSoftAction(
                    icon: entry.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    label: '📱 Save',
                    color: entry.isSaved ? const Color(0xFF12B347) : null,
                  ),
                  const SizedBox(width: 24),
                  _buildSoftAction(
                    icon: Icons.chat_bubble_outline,
                    label: '💬 ${entry.commentsCount}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSoftAction({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? const Color(0xFF718096),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: color ?? const Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'excited':
        return const Color(0xFFE55B4C);
      case 'relaxed':
        return const Color(0xFF4A90E2);
      case 'adventurous':
        return const Color(0xFFE17B47);
      case 'peaceful':
        return const Color(0xFF52C41A);
      case 'romantic':
        return const Color(0xFFE91E63);
      case 'curious':
        return const Color(0xFF9C27B0);
      case 'grateful':
        return const Color(0xFFFF9800);
      case 'inspired':
        return const Color(0xFF8BC34A);
      default:
        return const Color(0xFF12B347);
    }
  }

  String _formatTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

}