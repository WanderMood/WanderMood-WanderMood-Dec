import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({Key? key}) : super(key: key);

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Activity Feed',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2A6049),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFF2A6049),
                              size: 28,
                            ),
                            onPressed: () => _showNotifications(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'See what your travel community is up to',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),

              // Stories Section
              SliverToBoxAdapter(
                child: _buildStoriesSection(),
              ),

              // Activity Filter Tabs
              SliverToBoxAdapter(
                child: _buildFilterTabs(),
              ),

              // Activity Feed
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final activities = _getActivityFeed();
                    if (index >= activities.length) return null;
                    
                    return _buildActivityCard(activities[index], index);
                  },
                  childCount: _getActivityFeed().length,
                ),
              ),

              // Loading indicator
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2A6049),
                      ),
                    ),
                  ),
                ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories,
                    color: const Color(0xFF2A6049),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Travel Stories',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _viewAllStories(),
                    child: Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF2A6049),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _getStories().length,
                  itemBuilder: (context, index) {
                    final story = _getStories()[index];
                    return _buildStoryItem(story);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStoryItem(Map<String, dynamic> story) {
    return GestureDetector(
      onTap: () => _viewStory(story),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2A6049),
                    const Color(0xFF81C784),
                  ],
                ),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  story['author'][0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story['author'].split(' ')[0],
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', true),
          const SizedBox(width: 8),
          _buildFilterChip('Following', false),
          const SizedBox(width: 8),
          _buildFilterChip('Nearby', false),
          const SizedBox(width: 8),
          _buildFilterChip('Trending', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF2A6049) 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF2A6049) 
                : Colors.grey[300]!,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF2A6049).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _navigateToUserProfile(activity),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getUserColor(activity['user']),
                    child: Text(
                      activity['user'][0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              activity['user'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            if (activity['isVerified'] == true) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: const Color(0xFF2A6049),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              activity['location'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${activity['time']}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => _showPostOptions(activity),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                activity['content'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF2D3748),
                  height: 1.5,
                ),
              ),
            ),

            // Image if available
            if (activity['hasImage'] == true)
              Container(
                margin: const EdgeInsets.all(16),
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.photo_library,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                ),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildActionButton(
                    Icons.favorite_border,
                    '${activity['likes']}',
                    () => _likePost(activity),
                  ),
                  const SizedBox(width: 20),
                  _buildActionButton(
                    Icons.comment_outlined,
                    '${activity['comments']}',
                    () => _commentOnPost(activity),
                  ),
                  const SizedBox(width: 20),
                  _buildActionButton(
                    Icons.share_outlined,
                    'Share',
                    () => _sharePost(activity),
                  ),
                  const Spacer(),
                  _buildActionButton(
                    Icons.bookmark_border,
                    '',
                    () => _savePost(activity),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        // Stop propagation to parent GestureDetector
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Add more tappable area
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getUserColor(String name) {
    final colors = [
      const Color(0xFF2A6049),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
    ];
    return colors[name.hashCode % colors.length];
  }

  List<Map<String, dynamic>> _getStories() {
    return [
      {
        'author': 'Sarah Miller',
        'preview': 'Amsterdam Adventure',
        'timestamp': '2h ago',
      },
      {
        'author': 'Marco Silva',
        'preview': 'Barcelona Vibes',
        'timestamp': '4h ago',
      },
      {
        'author': 'Luna Chen',
        'preview': 'Beach Day',
        'timestamp': '6h ago',
      },
      {
        'author': 'Alex Turner',
        'preview': 'Mountain Hike',
        'timestamp': '8h ago',
      },
      {
        'author': 'Emma Wilson',
        'preview': 'Food Tour',
        'timestamp': '12h ago',
      },
    ];
  }

  List<Map<String, dynamic>> _getActivityFeed() {
    return [
      {
        'user': 'Sarah Miller',
        'userId': 'user1',
        'location': 'Amsterdam, Netherlands',
        'time': '2h ago',
        'content': 'Just discovered the most amazing hidden café in the Jordaan district! The coffee here is absolutely incredible and the atmosphere is so cozy. Perfect spot for digital nomads ☕✨',
        'likes': 24,
        'comments': 8,
        'hasImage': true,
        'isVerified': true,
      },
      {
        'user': 'Marco Silva',
        'userId': 'user2',
        'location': 'Barcelona, Spain',
        'time': '4h ago',
        'content': 'Sunset from Park Güell never gets old 🌅 Gaudí really knew how to pick the perfect spots. The city looks magical from up here!',
        'likes': 45,
        'comments': 12,
        'hasImage': true,
        'isVerified': false,
      },
      {
        'user': 'Luna Chen',
        'userId': 'user3',
        'location': 'Scheveningen, Netherlands',
        'time': '6h ago',
        'content': 'Beach volleyball session complete! 🏐 Nothing beats the feeling of sand between your toes and the North Sea breeze. Who\'s joining me tomorrow?',
        'likes': 18,
        'comments': 5,
        'hasImage': false,
        'isVerified': true,
      },
      {
        'user': 'Alex Turner',
        'userId': 'user4',
        'location': 'Swiss Alps',
        'time': '8h ago',
        'content': 'Reached the summit after 6 hours of hiking! The view from 3,000m is absolutely breathtaking. Every step was worth it 🏔️',
        'likes': 67,
        'comments': 23,
        'hasImage': true,
        'isVerified': false,
      },
      {
        'user': 'Emma Wilson',
        'userId': 'user5',
        'location': 'Rome, Italy',
        'time': '12h ago',
        'content': 'Food tour day 3: tried the most authentic carbonara at this tiny family restaurant. The owner taught me the secret recipe! 🍝',
        'likes': 31,
        'comments': 9,
        'hasImage': true,
        'isVerified': true,
      },
      {
        'user': 'David Kim',
        'userId': 'user6',
        'location': 'Tokyo, Japan',
        'time': '1d ago',
        'content': 'Cherry blossom season is here! Spent the entire day in Ueno Park capturing the perfect shots. Nature\'s artistry at its finest 🌸📸',
        'likes': 89,
        'comments': 34,
        'hasImage': true,
        'isVerified': false,
      },
    ];
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.notifications,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.socialYouHaveNewNotifications('3')),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.socialSampleNotificationLiked),
            Text(AppLocalizations.of(context)!.socialSampleNotificationFollowed),
            Text(AppLocalizations.of(context)!.socialSampleNotificationStory),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.socialClose),
          ),
        ],
      ),
    );
  }

  void _viewAllStories() {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.socialOpeningAllTravelStories,
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _viewStory(Map<String, dynamic> story) {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!
          .socialOpeningUserStory((story['author'] ?? '').toString()),
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _onFilterChanged(String filter) {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.socialFilteringBy(filter),
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _navigateToUserProfile(Map<String, dynamic> activity) {
    final userId = activity['userId'];
    if (userId != null) {
      context.push('/social/profile/$userId');
    } else {
      // Fallback: show a snackbar if userId is not available
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!
            .socialOpeningUserProfile((activity['user'] ?? '').toString()),
        backgroundColor: const Color(0xFF2A6049),
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showPostOptions(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text(AppLocalizations.of(context)!.socialSavePost),
              onTap: () {
                Navigator.pop(context);
                _savePost(activity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: Text(AppLocalizations.of(context)!
                  .socialFollowUser((activity['user'] ?? '').toString())),
              onTap: () {
                Navigator.pop(context);
                _followUser(activity['user']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: Text(AppLocalizations.of(context)!.socialReportPost),
              onTap: () {
                Navigator.pop(context);
                _reportPost(activity);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _likePost(Map<String, dynamic> activity) {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!
          .socialLikedUserPost((activity['user'] ?? '').toString()),
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _commentOnPost(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!
            .socialCommentOnUserPost((activity['user'] ?? '').toString())),
        content: TextField(
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.socialWriteCommentHint,
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showWanderMoodToast(
                context,
                message: AppLocalizations.of(context)!.socialCommentPosted,
                backgroundColor: const Color(0xFF2A6049),
              );
            },
            child: Text(AppLocalizations.of(context)!.socialPost),
          ),
        ],
      ),
    );
  }

  void _sharePost(Map<String, dynamic> activity) {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!
          .socialSharedUserPost((activity['user'] ?? '').toString()),
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _savePost(Map<String, dynamic> activity) {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!
          .socialSavedUserPost((activity['user'] ?? '').toString()),
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _followUser(String username) {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.socialFollowingUser(username),
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _reportPost(Map<String, dynamic> activity) {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!
          .socialReportedUserPost((activity['user'] ?? '').toString()),
      backgroundColor: const Color(0xFFFF6B6B),
    );
  }
} 