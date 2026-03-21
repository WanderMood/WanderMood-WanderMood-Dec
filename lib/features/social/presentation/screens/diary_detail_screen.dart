import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class DiaryDetailScreen extends ConsumerStatefulWidget {
  final String entryId;

  const DiaryDetailScreen({
    super.key,
    required this.entryId,
  });

  @override
  ConsumerState<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends ConsumerState<DiaryDetailScreen> {
  final _commentController = TextEditingController();
  bool _hasLiked = false;
  bool _hasSaved = false;

  // Demo data for the diary entry
  final Map<String, dynamic> _demoEntry = {
    'id': '1',
    'username': 'Emma',
    'mood': 'Excited',
    'location': 'Rotterdam Central',
    'time': '2h ago',
    'story': 'OMG found this INCREDIBLE hidden café behind the library! 🤯 The owner says it\'s been a local secret for 20+ years. Amazing coffee + walls covered in traveler notes from around the world ✨\n\nThe atmosphere is so cozy and authentic. Met this couple from Japan who recommended the best ramen place nearby. Sometimes the best travel moments happen when you least expect them!',
    'tags': ['hiddenGem', 'coffee', 'localSecret'],
    'thanks': 12,
    'comments': 3,
    'photos': ['assets/images/cafe1.jpg', 'assets/images/cafe2.jpg'],
  };

  // Demo comments
  final List<Map<String, dynamic>> _demoComments = [
    {
      'username': 'Alex',
      'time': '1h ago',
      'comment': 'This place looks amazing! Definitely adding to my Rotterdam list 📝',
      'avatar': '🧑‍🦱',
    },
    {
      'username': 'Sophie',
      'time': '45m ago',
      'comment': 'I walked past this café so many times and never noticed! Thanks for sharing 🙏',
      'avatar': '👩‍🦰',
    },
    {
      'username': 'Max',
      'time': '30m ago',
      'comment': 'The coffee there is genuinely incredible. Try their stroopwafel latte! ☕',
      'avatar': '🧔',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _hasSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _hasSaved ? const Color(0xFF2A6049) : const Color(0xFF718096),
                  ),
                  onPressed: () {
                    setState(() {
                      _hasSaved = !_hasSaved;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Color(0xFF718096)),
                  onPressed: () {
                    // Share functionality
                  },
                ),
              ],
            ),

            // Main Content
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Diary Entry Card
                  _buildDiaryEntryCard(),
                  
                  // Action Bar
                  _buildActionBar(),
                  
                  // Comments Section
                  _buildCommentsSection(),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
        
        // Comment Input (floating at bottom)
        bottomNavigationBar: _buildCommentInput(),
      ),
    );
  }

  Widget _buildDiaryEntryCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2A6049).withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFF2A6049),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF2A6049),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _demoEntry['username'],
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getMoodColor(_demoEntry['mood']).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _demoEntry['mood'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getMoodColor(_demoEntry['mood']),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Color(0xFF718096),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _demoEntry['location'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF718096),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _demoEntry['time'],
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
          
          // Story
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _demoEntry['story'],
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF4A5568),
                height: 1.6,
              ),
            ),
          ),
          
          // Photos
          _buildPhotoSection(),
          
          // Tags
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: (_demoEntry['tags'] as List<String>).map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A6049).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2A6049).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A6049),
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(20),
      child: PageView(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A6049).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF2A6049),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '📸 3 photos from this adventure',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Swipe to view →',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFA0AEC0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _hasLiked = !_hasLiked;
              });
            },
            child: Row(
              children: [
                Icon(
                  _hasLiked ? Icons.favorite : Icons.favorite_border,
                  color: _hasLiked ? const Color(0xFFE55B4C) : const Color(0xFF718096),
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  '💕 ${_demoEntry['thanks'] + (_hasLiked ? 1 : 0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF718096),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '💬 ${_demoComments.length}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF718096),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2A6049).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Thanks for sharing! 🙏',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2A6049),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          ..._demoComments.map((comment) => _buildCommentCard(comment)),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment['avatar'],
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['username'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      comment['time'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFA0AEC0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment['comment'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF4A5568),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Share your thoughts...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFFA0AEC0),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF2A6049)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF2A6049),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                if (_commentController.text.trim().isNotEmpty) {
                  // Add comment logic here
                  _commentController.clear();
                  showWanderMoodToast(
                    context,
                    message: 'Comment added! 💬',
                    backgroundColor: const Color(0xFF2A6049),
                  );
                }
              },
            ),
          ),
        ],
      ),
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
      default:
        return const Color(0xFF2A6049);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
} 