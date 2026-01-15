import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';

/// Guest Explore Screen
/// 
/// This screen allows users to explore places without signing up.
/// Limited functionality - can browse but can't save favorites or create plans.
/// Shows soft signup prompts at strategic points.
/// 
/// Flow: Splash → Intro → Demo → **Guest Explore** → Signup → Main
class GuestExploreScreen extends ConsumerStatefulWidget {
  const GuestExploreScreen({super.key});

  @override
  ConsumerState<GuestExploreScreen> createState() => _GuestExploreScreenState();
}

class _GuestExploreScreenState extends ConsumerState<GuestExploreScreen> {
  final List<_SamplePlace> _places = _getSamplePlaces();
  bool _showSignupBanner = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    
    // Start guest session tracking - delay to avoid modifying provider during build
    Future(() {
      if (mounted) {
        ref.read(guestSessionProvider.notifier).startSession();
      }
    });
    
    // Show signup banner after a delay
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _showSignupBanner = true;
        });
      }
    });
  }

  void _onPlaceTap(_SamplePlace place) {
    // Track place view
    ref.read(guestSessionProvider.notifier).trackPlaceView();
    
    // Check if we should show signup prompt
    final session = ref.read(guestSessionProvider);
    if (session.shouldShowSignupPrompt) {
      _showSignupPrompt();
    } else {
      // Show place preview dialog
      _showPlacePreview(place);
    }
  }

  void _showPlacePreview(_SamplePlace place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlacePreviewSheet(
        place: place,
        onSignUp: _navigateToSignup,
      ),
    );
  }

  void _showSignupPrompt() {
    ref.read(guestSessionProvider.notifier).markSignupPromptShown();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _SignupPromptDialog(
        onSignUp: _navigateToSignup,
        onContinue: () => Navigator.pop(context),
      ),
    );
  }

  void _onSaveTap(_SamplePlace place) {
    // Can't save as guest - show signup prompt
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text('Sign up to save your favorites!'),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Sign Up',
          onPressed: _navigateToSignup,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _navigateToSignup() {
    // Mark guest explore as done
    ref.read(onboardingProgressProvider.notifier).markGuestExploreCompleted();
    ref.read(currentOnboardingStepProvider.notifier).state = OnboardingStep.signup;
    
    context.go('/auth/magic-link');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwirlBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Guest banner
              if (_showSignupBanner) _buildSignupBanner(),
              
              // Category filter
              _buildCategoryFilter(),
              
              // Places grid
              Expanded(
                child: _buildPlacesGrid(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToSignup,
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.star_rounded, color: Colors.white),
        label: const Text(
          'Sign Up Free',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => context.go('/demo'),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.grey[700],
          ),
          
          const SizedBox(width: 8),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore Places',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Preview mode • Limited features',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Guest badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Guest',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Loving what you see?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Sign up to save favorites & create plans',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _navigateToSignup,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showSignupBanner = false;
              });
            },
            icon: Icon(Icons.close, size: 20, color: Colors.white.withOpacity(0.8)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Restaurants', 'Cafés', 'Parks', 'Museums', 'Nightlife'];
    
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = (_selectedCategory ?? 'All') == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'All';
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.orange[100],
              checkmarkColor: Colors.orange[700],
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.orange[700] : Colors.grey[700],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.orange[300]! : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlacesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return _buildPlaceCard(place);
      },
    );
  }

  Widget _buildPlaceCard(_SamplePlace place) {
    return GestureDetector(
      onTap: () => _onPlaceTap(place),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: place.color.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      place.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  // Save button (locked for guests)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _onSaveTap(place),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bookmark_border,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          place.rating.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          place.distance,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
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

class _PlacePreviewSheet extends StatelessWidget {
  final _SamplePlace place;
  final VoidCallback onSignUp;

  const _PlacePreviewSheet({
    required this.place,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: place.color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(place.emoji, style: const TextStyle(fontSize: 32)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${place.rating} · ${place.category}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Moody says
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('🌟', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Moody says...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Great choice for your vibe today!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Locked features notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline, size: 32, color: Colors.grey[500]),
                        const SizedBox(height: 8),
                        Text(
                          'Sign up to unlock',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Save favorites, create plans, and get personalized recommendations',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onSignUp();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Sign Up Free ✨',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupPromptDialog extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onContinue;

  const _SignupPromptDialog({
    required this.onSignUp,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🎉', style: TextStyle(fontSize: 40)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'You\'re exploring like a pro!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Ready to save your favorites and create personalized day plans?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onSignUp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign Up Free ✨',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextButton(
              onPressed: onContinue,
              child: Text(
                'Maybe later',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SamplePlace {
  final String name;
  final String category;
  final double rating;
  final String distance;
  final String emoji;
  final Color color;

  _SamplePlace({
    required this.name,
    required this.category,
    required this.rating,
    required this.distance,
    required this.emoji,
    required this.color,
  });
}

List<_SamplePlace> _getSamplePlaces() {
  return [
    _SamplePlace(
      name: 'The Cozy Corner',
      category: 'Café',
      rating: 4.8,
      distance: '0.5 km',
      emoji: '☕',
      color: Colors.brown,
    ),
    _SamplePlace(
      name: 'Sunset Terrace',
      category: 'Restaurant',
      rating: 4.6,
      distance: '1.2 km',
      emoji: '🍽️',
      color: Colors.orange,
    ),
    _SamplePlace(
      name: 'City Art Museum',
      category: 'Museum',
      rating: 4.9,
      distance: '2.1 km',
      emoji: '🎨',
      color: Colors.purple,
    ),
    _SamplePlace(
      name: 'Green Park',
      category: 'Park',
      rating: 4.7,
      distance: '0.8 km',
      emoji: '🌳',
      color: Colors.green,
    ),
    _SamplePlace(
      name: 'Jazz Lounge',
      category: 'Nightlife',
      rating: 4.5,
      distance: '1.5 km',
      emoji: '🎷',
      color: Colors.indigo,
    ),
    _SamplePlace(
      name: 'Rooftop Bar',
      category: 'Nightlife',
      rating: 4.4,
      distance: '1.8 km',
      emoji: '🍸',
      color: Colors.pink,
    ),
    _SamplePlace(
      name: 'Fresh Kitchen',
      category: 'Restaurant',
      rating: 4.7,
      distance: '0.9 km',
      emoji: '🥗',
      color: Colors.lightGreen,
    ),
    _SamplePlace(
      name: 'History Museum',
      category: 'Museum',
      rating: 4.8,
      distance: '2.5 km',
      emoji: '🏛️',
      color: Colors.amber,
    ),
  ];
}

