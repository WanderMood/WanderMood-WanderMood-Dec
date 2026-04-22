import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/social/domain/models/social_post.dart';
import 'package:wandermood/features/social/domain/providers/social_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/presentation/widgets/moody_settings_glyph.dart';

class UnifiedProfileScreen extends ConsumerStatefulWidget {
  final String? userId;
  
  const UnifiedProfileScreen({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  ConsumerState<UnifiedProfileScreen> createState() => _UnifiedProfileScreenState();
}

class _UnifiedProfileScreenState extends ConsumerState<UnifiedProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Random initial state for demo
    _isFollowing = widget.userId != null ? widget.userId!.hashCode % 2 == 0 : false;
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  bool get _isOwnProfile {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) => user?.id == widget.userId || widget.userId == null,
      loading: () => false,
      error: (_, __) => false,
    );
  }
  
  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
    
    showWanderMoodToast(
      context,
      message:
          _isFollowing ? 'Started following user' : 'Unfollowed user',
      backgroundColor: const Color(0xFF2A6049),
      duration: const Duration(seconds: 2),
    );
  }
  
  void _editProfile() {
    context.push('/profile/edit');
  }
  
  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (_isOwnProfile) ...[
              ListTile(
                leading: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(child: MoodySettingsGlyph(size: 26)),
                ),
                title: Text(
                  'Settings',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
              // QR code sharing temporarily hidden - not yet implemented
              // ListTile(
              //   leading: const Icon(Icons.qr_code, color: Color(0xFF2A6049)),
              //   title: Text(
              //     'Share Profile',
              //     style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              //   ),
              //   onTap: () {
              //     Navigator.pop(context);
              //     _showQRCode();
              //   },
              // ),
            ] else ...[
              // Social actions temporarily hidden - not yet implemented
              // ListTile(
              //   leading: const Icon(Icons.report_outlined, color: Colors.orange),
              //   title: Text(
              //     'Report User',
              //     style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              //   ),
              //   onTap: () {
              //     Navigator.pop(context);
              //     _reportUser();
              //   },
              // ),
              // ListTile(
              //   leading: const Icon(Icons.block, color: Colors.red),
              //   title: Text(
              //     'Block User',
              //     style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              //   ),
              //   onTap: () {
              //     Navigator.pop(context);
              //     _blockUser();
              //   },
              // ),
              // ListTile(
              //   leading: const Icon(Icons.share, color: Colors.blue),
              //   title: Text(
              //     'Share Profile',
              //     style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              //   ),
              //   onTap: () {
              //     Navigator.pop(context);
              //     _shareProfile();
              //   },
              // ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _sendMessage() {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.socialMessagingComingSoon,
      backgroundColor: const Color(0xFF2A6049),
      duration: const Duration(seconds: 2),
    );
  }
  
  void _showQRCode() {
    // QR code functionality for own profile
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.socialQrSharingComingSoon,
      backgroundColor: const Color(0xFF2A6049),
    );
  }
  
  void _reportUser() {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.socialReportComingSoon,
      backgroundColor: Colors.orange,
    );
  }
  
  void _blockUser() {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.socialBlockComingSoon,
      isError: true,
    );
  }
  
  void _shareProfile() {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.socialShareComingSoon,
      backgroundColor: Colors.blue,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Handle null userId case (own profile)
    final userId = widget.userId ?? 'current_user'; // Use a default or get current user ID
    final profileData = ref.watch(profileByIdProvider(userId));
    if (profileData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2A6049)),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.loading,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    
    final userPosts = ref.watch(socialPostsProvider)
        .where((post) => post.userId == userId)
        .toList();
    
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 300,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2A6049)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF2A6049)),
                  onPressed: _showOptions,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(profileData),
              ),
            ),
            
            // Action Buttons
            SliverToBoxAdapter(
              child: _buildActionButtons(),
            ),
            
            // Stats Section
            SliverToBoxAdapter(
              child: _buildStatsSection(profileData, userPosts),
            ),
            
            // Travel Vibes / Interests Section
            SliverToBoxAdapter(
              child: _buildInterestsSection(profileData),
            ),
            
            // Content Tabs
            SliverToBoxAdapter(
              child: _buildContentTabs(),
            ),
            
            // Content Grid
            SliverToBoxAdapter(
              child: _buildContentGrid(userPosts),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader(SocialProfile profileData) {
    return Column(
      children: [
        const SizedBox(height: 80), // Offset for app bar
        
        // Profile Image with Edit Indicator
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                image: DecorationImage(
                  image: wmCachedNetworkImageProvider(profileData.avatar),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (_isOwnProfile)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A6049),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Name and Username
        Text(
          profileData.fullName,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          '@${profileData.username}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Bio
        if (profileData.bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              profileData.bio,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Location
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Currently exploring Rotterdam',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
  
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_isOwnProfile) ...[
            // Edit Profile Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit, color: Colors.white),
                label: Text(
                  'Edit Profile',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A6049),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Follow Button
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey[300] : const Color(0xFF2A6049),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  _isFollowing ? 'Following' : 'Follow',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: _isFollowing ? Colors.grey[700] : Colors.white,
                  ),
                ),
              ),
            ),
            // Message Button temporarily hidden - not yet implemented
            // const SizedBox(width: 12),
            // Expanded(
            //   child: OutlinedButton.icon(
            //     onPressed: _sendMessage,
            //     icon: Icon(
            //       Icons.message,
            //       color: const Color(0xFF2A6049),
            //     ),
            //     label: Text(
            //       'Message',
            //       style: GoogleFonts.poppins(
            //         fontWeight: FontWeight.w600,
            //         color: const Color(0xFF2A6049),
            //       ),
            //     ),
            //     style: OutlinedButton.styleFrom(
            //       side: const BorderSide(color: Color(0xFF2A6049)),
            //       padding: const EdgeInsets.symmetric(vertical: 12),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(25),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }
  
  Widget _buildStatsSection(SocialProfile profileData, List<SocialPost> userPosts) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
                     // Stats Row
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
             children: [
               _buildStatItem('Posts', '${userPosts.length}'),
               _buildStatItem('Followers', '${profileData.followers}'),
               _buildStatItem('Following', '${profileData.following}'),
             ],
           ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }
  
  Widget _buildStatItem(String label, String number) {
    return Column(
      children: [
        Text(
          number,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildInterestsSection(SocialProfile profileData) {
    final interests = ['hiking', 'photography', 'cycling', 'museums', 'coffee'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isOwnProfile ? 'Travel Vibes' : 'Interests',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A6049).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2A6049).withOpacity(0.3),
                ),
              ),
              child: Text(
                interest,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2A6049),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }
  
  Widget _buildContentTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF2A6049),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: [
          Tab(
            icon: Icon(Icons.grid_on, size: 20),
            text: 'Posts',
          ),
          Tab(
            icon: Icon(Icons.bookmark_border, size: 20),
            text: 'Saved',
          ),
          Tab(
            icon: Icon(Icons.map, size: 20),
            text: 'Places',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 600.ms);
  }
  
  Widget _buildContentGrid(List<SocialPost> userPosts) {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      child: TabBarView(
        controller: _tabController,
        children: [
          // Posts Grid
          userPosts.isEmpty
              ? _buildEmptyState('No posts yet', Icons.photo_camera)
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: userPosts.length,
                  itemBuilder: (context, index) {
                    final post = userPosts[index];
                    return GestureDetector(
                      onTap: () => context.push('/social/post/${post.id}'),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: wmCachedNetworkImageProvider(post.images.isNotEmpty
                                ? post.images.first
                                : 'https://via.placeholder.com/300'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          
          // Saved Content
          _buildEmptyState('No saved posts', Icons.bookmark_border),
          
          // Places Map/Grid
          _buildEmptyState('Places coming soon', Icons.map),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 