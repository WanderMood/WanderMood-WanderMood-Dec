import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../social/domain/models/diary_entry.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';

class DiaryEntryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;

  const DiaryEntryDetailScreen({
    Key? key,
    required this.entry,
  }) : super(key: key);

  @override
  State<DiaryEntryDetailScreen> createState() => _DiaryEntryDetailScreenState();
}

class _DiaryEntryDetailScreenState extends State<DiaryEntryDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // Hero Image Section
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              backgroundColor: Colors.black.withOpacity(0.5),
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => _shareEntry(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.bookmark_border, color: Colors.white),
                    onPressed: () => _saveEntry(),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    widget.entry.photos.isNotEmpty
                        ? Image.network(
                            widget.entry.photos.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackHeroImage(),
                          )
                        : _buildFallbackHeroImage(),
                    
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    
                    // Mood Tag
                    Positioned(
                      bottom: 80,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getMoodTagColor(widget.entry.mood),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getMoodEmoji(widget.entry.mood),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.entry.mood,
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
                  ],
                ),
              ),
            ),
            
            // Content Section
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle Bar
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Title
                          Text(
                            widget.entry.title ?? _generateTitle(),
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Location and Date
                          Row(
                            children: [
                              if (widget.entry.location?.isNotEmpty == true) ...[
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.entry.location!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(widget.entry.createdAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Content
                          if (widget.entry.story.isNotEmpty) ...[
                            Text(
                              widget.entry.story,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: const Color(0xFF2D3748),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Photo Gallery
                          if (widget.entry.photos.length > 1) ...[
                            Text(
                              'Photos',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.entry.photos.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.entry.photos[index],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.photo,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _likeEntry(),
                                  icon: const Icon(Icons.favorite_border),
                                  label: const Text('Like'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF12B347),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _commentOnEntry(),
                                  icon: const Icon(Icons.comment_outlined),
                                  label: const Text('Comment'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF12B347),
                                    side: const BorderSide(color: Color(0xFF12B347)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackHeroImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getMoodTagColor(widget.entry.mood).withOpacity(0.7),
            _getMoodTagColor(widget.entry.mood),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getMoodEmoji(widget.entry.mood),
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 16),
            Text(
              widget.entry.mood,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateTitle() {
    final mood = widget.entry.mood.toLowerCase();
    final location = widget.entry.location ?? 'My Journey';
    
    switch (mood) {
      case 'adventurous':
        return 'Adventure in $location';
      case 'romantic':
        return 'Romantic moments in $location';
      case 'wonder':
        return 'Wonder and magic in $location';
      case 'peaceful':
        return 'Peaceful escape to $location';
      case 'excited':
        return 'Exciting times in $location';
      case 'grateful':
        return 'Grateful for $location';
      default:
        return 'My journey to $location';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Color _getMoodTagColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'adventurous':
        return const Color(0xFFFF6B35);
      case 'romantic':
        return const Color(0xFFE91E63);
      case 'wonder':
        return const Color(0xFF9C27B0);
      case 'peaceful':
        return const Color(0xFF4CAF50);
      case 'excited':
        return const Color(0xFFFF9800);
      case 'grateful':
        return const Color(0xFF2196F3);
      case 'happy':
        return const Color(0xFFFFC107);
      case 'relaxed':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFF607D8B);
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'adventurous':
        return '🏞️';
      case 'romantic':
        return '💕';
      case 'wonder':
        return '🤩';
      case 'peaceful':
        return '🧘';
      case 'excited':
        return '🎉';
      case 'grateful':
        return '🙏';
      case 'happy':
        return '😊';
      case 'relaxed':
        return '😌';
      default:
        return '✨';
    }
  }

  void _shareEntry() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared "${widget.entry.title ?? 'Travel story'}"!'),
        backgroundColor: const Color(0xFF12B347),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveEntry() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "${widget.entry.title ?? 'Travel story'}" to your collection!'),
        backgroundColor: const Color(0xFF12B347),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _likeEntry() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Liked "${widget.entry.title ?? 'Travel story'}"! ❤️'),
        backgroundColor: const Color(0xFF12B347),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _commentOnEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add a comment',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts about this journey...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF12B347)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comment posted! 💬'),
                        backgroundColor: Color(0xFF12B347),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12B347),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Post Comment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 