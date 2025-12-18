import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/social/domain/models/social_post.dart';
import 'package:wandermood/features/social/domain/providers/social_providers.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  bool _isBookmarked = false;
  int _likeCount = 0;
  
  @override
  void initState() {
    super.initState();
    // Random initial state for demo purposes
    _isLiked = widget.postId.hashCode % 2 == 0;
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  void _toggleLike(SocialPost post) {
    // WanderFeed coming soon - interactions disabled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WanderFeed is coming soon! Social interactions will be available then. 🧳✨'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _toggleBookmark() {
    // WanderFeed coming soon - interactions disabled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WanderFeed is coming soon! Bookmarking will be available then. 🧳✨'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    
    // WanderFeed coming soon - interactions disabled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WanderFeed is coming soon! Comments will be available then. 🧳✨'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }
  
  void _sharePost() async {
    try {
      final posts = ref.read(socialPostsProvider);
      final post = posts.firstWhere(
        (p) => p.id == widget.postId,
        orElse: () => posts.first,
      );
      
      final message = 'Check out this post from ${post.userName} on WanderMood! 🧳✨\n\n${post.caption ?? ''}';
      await Share.share(message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share post: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            // Social actions temporarily hidden - not yet implemented
            // ListTile(
            //   leading: const Icon(Icons.report_outlined, color: Colors.orange),
            //   title: Text(
            //     'Report Post',
            //     style: GoogleFonts.poppins(
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            //   onTap: () {
            //     Navigator.pop(context);
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(
            //         content: Text('Report feature coming soon!'),
            //         duration: Duration(seconds: 2),
            //       ),
            //     );
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.person_off_outlined, color: Colors.red),
            //   title: Text(
            //     'Block User',
            //     style: GoogleFonts.poppins(
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            //   onTap: () {
            //     Navigator.pop(context);
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(
            //         content: Text('Block feature coming soon!'),
            //         duration: Duration(seconds: 2),
            //       ),
            //     );
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.content_copy, color: Colors.blue),
              title: Text(
                'Copy Link',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
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
  
  @override
  Widget build(BuildContext context) {
    final allPosts = ref.watch(socialPostsProvider);
    final post = allPosts.firstWhere(
      (post) => post.id == widget.postId,
      orElse: () => allPosts.first, // Fallback to first post if not found
    );
    
    // Initialize like count from post data
    if (_likeCount == 0) {
      _likeCount = post.likes;
    }
    
    // Get comments for this post
    final comments = ref.watch(postCommentsProvider(post.id));
    
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Post',
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12B347),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF12B347)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF12B347)),
              onPressed: _showOptions,
            ),
          ],
        ),
        body: Column(
          children: [
            // Post Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info and location
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/social/profile/${post.userId}'),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(post.userAvatar),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push('/social/profile/${post.userId}'),
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
                          ),
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
                    
                    // Post images
                    if (post.images.isNotEmpty)
                      SizedBox(
                        height: 350,
                        child: PageView.builder(
                          itemCount: post.images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              post.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked ? Colors.red : Colors.black87,
                            ),
                            onPressed: () => _toggleLike(post),
                          ),
                          Text(
                            _likeCount.toString(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () {
                              // Focus on comment field
                              FocusScope.of(context).requestFocus(
                                FocusNode(),
                              );
                              // Delay to avoid keyboard animation issues
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () => FocusScope.of(context).requestFocus(
                                  FocusNode(),
                                ),
                              );
                            },
                          ),
                          Text(
                            post.comments.toString(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: _isBookmarked ? const Color(0xFF12B347) : Colors.black87,
                            ),
                            onPressed: _toggleBookmark,
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined),
                            onPressed: _sharePost,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Wrap(
                          spacing: 6,
                          children: post.tags.map((tag) => InkWell(
                            onTap: () {
                              // Filter posts by tag
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Viewing posts tagged with #$tag'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
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
                    
                    // Activity tag
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12B347).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
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
                    ),
                    
                    // Comments section header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Comments (${comments.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    // Comments list
                    ...comments.map((comment) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    )).toList(),
                    
                    // Bottom padding
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Comment input field
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
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
                        controller: _commentController,
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
                      onPressed: _addComment,
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
} 