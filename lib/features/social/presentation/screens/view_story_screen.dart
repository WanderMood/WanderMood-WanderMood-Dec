import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/social/domain/models/social_post.dart';

class ViewStoryScreen extends ConsumerStatefulWidget {
  final List<SocialProfile> profiles;
  final int initialIndex;
  
  const ViewStoryScreen({
    super.key,
    required this.profiles,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<ViewStoryScreen> createState() => _ViewStoryScreenState();
}

class _ViewStoryScreenState extends ConsumerState<ViewStoryScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;
  
  // Mock story data (in a real app, this would come from a backend)
  final List<String> _mockStoryImages = [
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
    'https://images.unsplash.com/photo-1469474968028-56623f02e42e',
    'https://images.unsplash.com/photo-1539593395743-7da5ee10106a',
    'https://images.unsplash.com/photo-1495344517868-8ebaf0a2044a',
    'https://images.unsplash.com/photo-1573935592355-88112e8dc1b6',
  ];
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Animation controller for the progress indicator
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextPage();
      }
    });
    
    // Start the animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _nextPage() {
    if (_currentIndex < widget.profiles.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // Last story, close the screen
      Navigator.of(context).pop();
    }
  }
  
  void _previousPage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          // Determine if tap is on left or right side of screen
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            // Left side tap (go back)
            _previousPage();
          } else {
            // Right side tap (go forward)
            _nextPage();
          }
        },
        onLongPress: () {
          // Pause the animation
          _animationController.stop();
        },
        onLongPressUp: () {
          // Resume the animation
          _animationController.forward();
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Content
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swiping
                itemCount: widget.profiles.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                itemBuilder: (context, index) {
                  final profile = widget.profiles[index];
                  // Use a mock story image (in a real app, you'd get this from the profile or story object)
                  final storyImage = _mockStoryImages[index % _mockStoryImages.length];
                  
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Story image
                      Image.network(
                        storyImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Gradient overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      
                      // User info at top
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(profile.avatar),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.fullName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '2h ago', // Mock time
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      
                      // Caption (optional)
                      Positioned(
                        bottom: 70,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Enjoying a beautiful day in nature! #adventure #explore',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      
                      // Reply input at bottom
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Reply to story...',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.send,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.favorite_border,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              // Progress indicator
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: List.generate(
                    widget.profiles.length,
                    (index) => Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: index == _currentIndex
                            ? AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _animationController.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : index < _currentIndex
                                ? Container(color: Colors.white)
                                : const SizedBox(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 