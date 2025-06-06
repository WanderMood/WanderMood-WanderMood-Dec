import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/social/domain/models/social_post.dart';
import 'package:wandermood/features/social/domain/providers/social_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/social/presentation/screens/create_post_screen.dart';
import 'package:wandermood/features/social/presentation/screens/create_story_screen.dart';
import 'package:wandermood/features/social/presentation/screens/message_hub_screen.dart';
import 'package:wandermood/features/social/presentation/screens/post_detail_screen.dart';
import 'package:wandermood/features/social/presentation/screens/view_story_screen.dart';

class SocialHubScreen extends ConsumerStatefulWidget {
  const SocialHubScreen({super.key});

  @override
  ConsumerState<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends ConsumerState<SocialHubScreen> with SingleTickerProviderStateMixin {
  bool _isFollowingSelected = true;
  
  @override
  Widget build(BuildContext context) {
    // Use the appropriate provider based on the selected tab
    final posts = _isFollowingSelected 
        ? ref.watch(followingFeedProvider) 
        : ref.watch(forYouFeedProvider);
    
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar with Tabs
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                pinned: true,
                title: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Social',
                    style: GoogleFonts.museoModerno(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF12B347),
                    ),
                  ),
                ),
                actions: [
                  // New post button
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF12B347),
                      size: 28,
                    ),
                    onPressed: () {
                      // Navigate to CreatePostScreen
                      context.push('/social/create-post');
                    },
                  ),
                  // Messages button
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF12B347),
                      size: 24,
                    ),
                    onPressed: () {
                      // Navigate to MessageHubScreen
                      context.push('/social/messages');
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isFollowingSelected = true;
                            });
                          },
                          child: _buildTabButton('Following', _isFollowingSelected),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isFollowingSelected = false;
                            });
                          },
                          child: _buildTabButton('For You', !_isFollowingSelected),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Stories row (horizontal scrollable)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: SizedBox(
                    height: 100,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final profiles = ref.watch(socialProfilesProvider);
                        
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // Add your story
                            _buildStoryItem(
                              imageUrl: '',
                              username: 'Add Yours',
                              isAdd: true,
                            ),
                            // Map through profiles to build story items
                            ...profiles.map((profile) => _buildStoryItem(
                              imageUrl: profile.avatar,
                              username: profile.username.split('_')[0],
                              isNew: profile.id == 'user1' || profile.id == 'user2' || profile.id == 'user5',
                            )).toList(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Feed of posts
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= posts.length) return null;
                    final post = posts[index];
                    return _buildPostItem(context, post);
                  },
                  childCount: posts.length,
                ),
              ),
              
              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF12B347).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isActive 
            ? Border.all(color: const Color(0xFF12B347), width: 1)
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive ? const Color(0xFF12B347) : Colors.black54,
        ),
      ),
    );
  }
  
  Widget _buildStoryItem({
    required String imageUrl,
    required String username,
    bool isNew = false,
    bool isAdd = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isAdd) {
          // Navigate to CreateStoryScreen
          context.push('/social/create-story');
        } else {
          // Get the index of this profile in the list
          final profiles = ref.read(socialProfilesProvider);
          final index = profiles.indexWhere((profile) => 
            profile.username.split('_')[0] == username ||
            profile.username.contains(username)
          );
          
          if (index != -1) {
            // Navigate to ViewStoryScreen
            context.push('/social/stories?index=$index');
          }
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isNew 
                    ? const LinearGradient(
                        colors: [Color(0xFF12B347), Color(0xFF4CAF50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: isNew 
                    ? Border.all(color: Colors.white, width: 2)
                    : Border.all(color: Colors.grey.shade300, width: 1),
              ),
              padding: isNew ? const EdgeInsets.all(2) : null,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAdd ? Colors.grey.shade100 : null,
                  border: Border.all(color: Colors.white, width: 2),
                  image: isAdd || imageUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                child: isAdd
                    ? const Icon(
                        Icons.add,
                        color: Color(0xFF12B347),
                        size: 30,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              username,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPostItem(BuildContext context, SocialPost post) {
    return InkWell(
      onTap: () {
        // Navigate to post detail screen
        context.push('/social/post/${post.id}');
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header
            InkWell(
              onTap: () {
                // Navigate to user profile
                context.push('/social/profile/${post.userId}');
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(post.userAvatar),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.userName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                post.location,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        // Show post options menu
                        _showPostOptionsMenu(context, post);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Post image
            if (post.images.isNotEmpty)
              post.images.length == 1
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: Image.network(
                        post.images[0],
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : SizedBox(
                      height: 240,
                      child: PageView.builder(
                        itemCount: post.images.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            post.images[index],
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _LikeButton(postId: post.id, initialLikes: post.likes),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                      // Show comments sheet
                      _showCommentsSheet(context, post);
                    },
                  ),
                  Text(
                    post.comments.toString(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  _BookmarkButton(postId: post.id),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      // Share post
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share feature coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Caption
            if (post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  post.caption,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                  ),
                ),
              ),
            
            // Tags
            if (post.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 6,
                  children: post.tags.map((tag) => InkWell(
                    onTap: () {
                      // Filter posts by tag
                      _filterByTag(tag);
                    },
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF12B347),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
              ),
            
            // Activity tag and timestamp
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12B347).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.activity,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF12B347),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _getTimeAgo(post.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _filterByTag(String tag) {
    // Show posts filtered by tag
    final filteredPosts = ref.read(postsByTagProvider(tag));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Found ${filteredPosts.length} posts with #$tag'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // In a real app, this would navigate to a filtered results screen
  }
  
  void _showPostOptionsMenu(BuildContext context, SocialPost post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.orange),
              title: Text(
                'Report Post',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report feature coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined, color: Colors.red),
              title: Text(
                'Block User',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Block feature coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy, color: Colors.blue),
              title: Text(
                'Copy Link',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCommentsSheet(BuildContext context, SocialPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final comments = ref.watch(postCommentsProvider(post.id));
                
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Text(
                            'Comments',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${comments.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(),
                    
                    // Comment list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: NetworkImage(comment.userAvatar),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            comment.userName,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _getTimeAgo(comment.timestamp),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.text,
                                        style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.favorite_border,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Like',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(
                                            Icons.reply,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Reply',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Comment input field
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Consumer(
                            builder: (context, ref, child) {
                              // This would normally get the current user avatar
                              return const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFF12B347),
                                child: Text(
                                  'U',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: GoogleFonts.poppins(fontSize: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFF12B347),
                            ),
                            onPressed: () {
                              // Handle send comment
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Comment feature coming soon!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
  
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _LikeButton extends StatefulWidget {
  final String postId;
  final int initialLikes;
  
  const _LikeButton({
    required this.postId,
    required this.initialLikes,
  });

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  late bool _isLiked;
  late int _likeCount;
  
  @override
  void initState() {
    super.initState();
    // Random initial state for demo purposes
    _isLiked = widget.postId.hashCode % 3 == 0;
    _likeCount = widget.initialLikes;
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : null,
          ),
          onPressed: () {
            setState(() {
              _isLiked = !_isLiked;
              _likeCount += _isLiked ? 1 : -1;
            });
          },
        ),
        Text(
          _likeCount.toString(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BookmarkButton extends StatefulWidget {
  final String postId;
  
  const _BookmarkButton({required this.postId});

  @override
  _BookmarkButtonState createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton> {
  late bool _isBookmarked;
  
  @override
  void initState() {
    super.initState();
    // Random initial state for demo purposes
    _isBookmarked = widget.postId.hashCode % 5 == 0;
  }
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        color: _isBookmarked ? const Color(0xFF12B347) : null,
      ),
      onPressed: () {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBookmarked ? 'Post saved' : 'Post unsaved'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
} 