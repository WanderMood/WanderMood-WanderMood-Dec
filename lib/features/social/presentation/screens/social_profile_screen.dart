import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/social/domain/models/social_post.dart';
import 'package:wandermood/features/social/domain/providers/social_providers.dart';

class SocialProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  
  const SocialProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<SocialProfileScreen> createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends ConsumerState<SocialProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Random initial state for demo
    _isFollowing = widget.userId.hashCode % 2 == 0;
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
    
    showWanderMoodToast(
      context,
      message: _isFollowing ? 'Started following user' : 'Unfollowed user',
      duration: const Duration(seconds: 1),
    );
  }
  
  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.orange),
              title: Text(
                'Report User',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                showWanderMoodToast(
                  context,
                  message: 'Report feature coming soon!',
                  duration: const Duration(seconds: 2),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text(
                'Block User',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                showWanderMoodToast(
                  context,
                  message: 'Block feature coming soon!',
                  duration: const Duration(seconds: 2),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: Text(
                'Share Profile',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                showWanderMoodToast(
                  context,
                  message: 'Share feature coming soon!',
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _openDirectMessage(SocialProfile profile) {
    showWanderMoodToast(
      context,
      message: 'Messaging feature coming soon!',
      duration: const Duration(seconds: 2),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final profileData = ref.watch(profileByIdProvider(widget.userId));
    if (profileData == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not found'),
        ),
      );
    }
    
    final userPosts = ref.watch(socialPostsProvider)
        .where((post) => post.userId == widget.userId)
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
                background: Column(
                  children: [
                    const SizedBox(height: 70), // Offset for app bar
                    // Profile Image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(profileData.avatar),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Name
                    Text(
                      profileData.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    
                    // Username
                    Text(
                      '@${profileData.username}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Bio
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        profileData.bio,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Follow stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatColumn(profileData.posts, 'Posts'),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        _buildStatColumn(profileData.followers, 'Followers'),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        _buildStatColumn(profileData.following, 'Following'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Buttons row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing 
                              ? Colors.white 
                              : const Color(0xFF2A6049),
                          foregroundColor: _isFollowing 
                              ? const Color(0xFF2A6049)
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: const Color(0xFF2A6049),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => _openDirectMessage(profileData),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2A6049),
                        side: const BorderSide(
                          color: Color(0xFF2A6049),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Message',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Interests
            if (profileData.interests.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interests',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profileData.interests.map((interest) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A6049).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            interest,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF2A6049),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2A6049),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF2A6049),
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.bookmark_border)),
                    Tab(icon: Icon(Icons.location_on_outlined)),
                  ],
                ),
              ),
            ),
            
            // Tab View Content (Grid of posts)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 500,  // Fixed height for demo
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Posts Tab
                    userPosts.isEmpty
                        ? Center(
                            child: Text(
                              'No posts yet',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(4),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: userPosts.length,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final post = userPosts[index];
                              return GestureDetector(
                                onTap: () {
                                  // Navigate to post detail
                                  context.push('/social/post/${post.id}');
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(post.images.first),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: post.images.length > 1
                                      ? const Align(
                                          alignment: Alignment.topRight,
                                          child: Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.layers,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                    
                    // Saved Tab
                    Center(
                      child: Text(
                        'No saved posts',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    
                    // Map/Location Tab
                    Center(
                      child: Text(
                        'No locations to show',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
} 