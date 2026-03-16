import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';

/// Guest Explore Screen
/// 
/// This screen allows users to explore places without signing up.
/// Limited functionality - can browse but can't save favorites or create plans.
/// Shows soft signup prompts at strategic points.
/// 
/// Flow: Splash → Intro → Demo → **Guest Explore** → Signup → Main
const String _kFallbackDemoImageUrl =
    'https://images.unsplash.com/photo-1495474474567-4fe4e9a0c320?w=400';

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
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(AppLocalizations.of(context)!.guestSignUpToSaveFavorites),
            ),
          ],
        ),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.guestSignUp,
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
        foregroundColor: Colors.white,
        icon: const Icon(Icons.star_rounded, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.guestSignUpFree,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 4,
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
                  AppLocalizations.of(context)!.guestExplorePlaces,
                  style: GoogleFonts.museoModerno(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.guestPreviewMode,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Guest badge – modern pill with brand accent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline_rounded, size: 18, color: const Color(0xFF4CAF50)),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.guestGuest,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 0.2,
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
                Text(
                  AppLocalizations.of(context)!.guestLovingWhatYouSee,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.guestSignUpSaveFavorites,
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
              AppLocalizations.of(context)!.guestSignUp,
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
    final l10n = AppLocalizations.of(context)!;
    const categoryKeys = ['All', 'Restaurants', 'Cafés', 'Parks', 'Museums', 'Nightlife'];
    final categoryLabels = [
      l10n.guestCategoryAll,
      l10n.guestCategoryRestaurants,
      l10n.guestCategoryCafes,
      l10n.guestCategoryParks,
      l10n.guestCategoryMuseums,
      l10n.guestCategoryNightlife,
    ];
    
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoryKeys.length,
        itemBuilder: (context, index) {
          final key = categoryKeys[index];
          final label = categoryLabels[index];
          final isSelected = (_selectedCategory ?? 'All') == key;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? key : 'All';
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

  List<_SamplePlace> _getFilteredPlaces() {
    final category = _selectedCategory ?? 'All';
    if (category == 'All') return _places;
    return _places.where((p) => p.categoryKey == category).toList();
  }

  Widget _buildPlacesGrid() {
    final filtered = _getFilteredPlaces();
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.guestNoPlacesMatchFilters,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.guestTryDifferentCategory,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final place = filtered[index];
        return _buildPlaceCard(context, place);
      },
    );
  }

  Widget _buildPlaceCard(BuildContext context, _SamplePlace place) {
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
            // Cached image with bookmark overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: (place.imageUrl.trim().isEmpty
                              ? _kFallbackDemoImageUrl
                              : place.imageUrl),
                      cacheKey: 'guest_${place.nameKey}_img',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: place.color.withOpacity(0.2),
                        child: Center(
                          child: Text(place.emoji, style: const TextStyle(fontSize: 36)),
                        ),
                      ),
                      errorWidget: (context, url, error) => CachedNetworkImage(
                        imageUrl: _kFallbackDemoImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, u) => Container(
                          color: place.color.withOpacity(0.2),
                          child: Center(
                            child: Text(place.emoji, style: const TextStyle(fontSize: 36)),
                          ),
                        ),
                        errorWidget: (context, u, e) => Container(
                          color: place.color.withOpacity(0.3),
                          child: Center(
                            child: Text(place.emoji, style: const TextStyle(fontSize: 36)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
            // Content (name, category, filter badges, description, rating)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _guestPlaceName(context, place.nameKey),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _guestPlaceCategory(context, place.categoryKey),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (place.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        children: _placeFilterBadges(context, place.tags, compact: true, maxCount: 2),
                      ),
                    ],
                    if (_guestPlaceDesc(context, place.descriptionKey).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _guestPlaceDesc(context, place.descriptionKey),
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                  // Hero image (same as card; fallback to demo image if load fails)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: (place.imageUrl.trim().isEmpty
                                ? _kFallbackDemoImageUrl
                                : place.imageUrl),
                        cacheKey: 'guest_preview_${place.nameKey}_img',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: place.color.withOpacity(0.2),
                          child: Center(
                            child: Text(place.emoji, style: const TextStyle(fontSize: 48)),
                          ),
                        ),
                        errorWidget: (context, url, error) => CachedNetworkImage(
                          imageUrl: _kFallbackDemoImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, u) => Container(
                            color: place.color.withOpacity(0.2),
                            child: Center(
                              child: Text(place.emoji, style: const TextStyle(fontSize: 48)),
                            ),
                          ),
                          errorWidget: (context, u, e) => Container(
                            color: place.color.withOpacity(0.3),
                            child: Center(
                              child: Text(place.emoji, style: const TextStyle(fontSize: 48)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _guestPlaceName(context, place.nameKey),
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
                        '${place.rating} · ${_guestPlaceCategory(context, place.categoryKey)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: place.isOpenNow ? Colors.green[50] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          place.isOpenNow
                              ? AppLocalizations.of(context)!.guestOpenNow
                              : AppLocalizations.of(context)!.guestClosed,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: place.isOpenNow ? Colors.green[800] : Colors.grey[700],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          place.isFree
                              ? AppLocalizations.of(context)!.guestFree
                              : AppLocalizations.of(context)!.guestPaid,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.guestDistanceAway(place.distance),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (place.hoursSummary != null && place.hoursSummary!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.guestHours}: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          place.hoursSummary!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (place.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _placeFilterBadges(context, place.tags, compact: false),
                    ),
                  ],
                  if (_guestPlaceDesc(context, place.descriptionKey).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _guestPlaceDesc(context, place.descriptionKey),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
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
                                AppLocalizations.of(context)!.guestMoodySays,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.guestGreatChoice,
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
                          AppLocalizations.of(context)!.guestSignUpToUnlock,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.guestSignUpUnlockDescription,
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
                            child: Text(
                              AppLocalizations.of(context)!.guestSignUpFreeSparkle,
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
              AppLocalizations.of(context)!.guestExploringLikePro,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              AppLocalizations.of(context)!.guestReadyToSaveFavorites,
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
                child: Text(
                  AppLocalizations.of(context)!.guestSignUpFreeSparkle,
                  style: const TextStyle(
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
                AppLocalizations.of(context)!.guestMaybeLater,
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

/// Builds badge chips for lifestyle/accessibility tags on cards and preview.
/// [maxCount] limits how many pills show per card (e.g. 2 keeps it subtle).
List<Widget> _placeFilterBadges(BuildContext context, List<String> tags, {bool compact = false, int? maxCount}) {
  final l10n = AppLocalizations.of(context)!;
  final Map<String, String> labels = {
    'halal': l10n.guestFilterHalal,
    'black_owned': l10n.guestFilterBlackOwned,
    'aesthetic_spaces': l10n.guestFilterAesthetic,
    'lgbtq_friendly': l10n.guestFilterLgbtq,
    'vegan': l10n.guestFilterVegan,
    'vegetarian': l10n.guestFilterVegetarian,
    'wheelchair_accessible': l10n.guestFilterWheelchair,
  };
  const Map<String, String> emojis = {
    'halal': '🥗',
    'black_owned': '✊🏿',
    'aesthetic_spaces': '🧘‍♀️',
    'lgbtq_friendly': '🏳️‍🌈',
    'vegan': '🌱',
    'vegetarian': '🥬',
    'wheelchair_accessible': '♿',
  };
  const Map<String, Color> colors = {
    'halal': Color(0xFFE0F2F1),
    'black_owned': Color(0xFFEFEBE9),
    'aesthetic_spaces': Color(0xFFE8F5E8),
    'lgbtq_friendly': Color(0xFFF3E5F5),
    'vegan': Color(0xFFE8F5E9),
    'vegetarian': Color(0xFFF1F8E9),
    'wheelchair_accessible': Color(0xFFE3F2FD),
  };
  const order = ['halal', 'black_owned', 'aesthetic_spaces', 'lgbtq_friendly', 'vegan', 'vegetarian', 'wheelchair_accessible'];
  final matching = order.where((k) => tags.contains(k));
  final toShow = maxCount != null ? matching.take(maxCount).toList() : matching.toList();
  return toShow
      .map((k) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : 8,
              vertical: compact ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: (colors[k] ?? Colors.grey[200]!).withOpacity(0.95),
              borderRadius: BorderRadius.circular(compact ? 6 : 12),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 0.5,
              ),
            ),
            child: Text(
              '${emojis[k]} ${labels[k]}',
              style: TextStyle(
                fontSize: compact ? 8 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ))
      .toList();
}

class _SamplePlace {
  final String nameKey;
  final String categoryKey;
  final String descriptionKey;
  final double rating;
  final String distance;
  final String emoji;
  final Color color;
  final String imageUrl;
  /// Filter tags: halal, black_owned, aesthetic_spaces, lgbtq_friendly, vegan, vegetarian, wheelchair_accessible
  final List<String> tags;
  /// Mock: whether the place is currently open
  final bool isOpenNow;
  /// Mock: hours summary e.g. "10:00 – 23:00"
  final String? hoursSummary;
  /// Mock: true for free entry (e.g. parks, some museums)
  final bool isFree;

  _SamplePlace({
    required this.nameKey,
    required this.categoryKey,
    required this.descriptionKey,
    required this.rating,
    required this.distance,
    required this.emoji,
    required this.color,
    required this.imageUrl,
    this.tags = const [],
    this.isOpenNow = true,
    this.hoursSummary,
    this.isFree = false,
  });
}

String _guestPlaceName(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  switch (key) {
    case 'cozyCorner': return l10n.guestPlaceNameCozyCorner;
    case 'sunsetTerrace': return l10n.guestPlaceNameSunsetTerrace;
    case 'cityArtMuseum': return l10n.guestPlaceNameCityArtMuseum;
    case 'greenPark': return l10n.guestPlaceNameGreenPark;
    case 'jazzLounge': return l10n.guestPlaceNameJazzLounge;
    case 'rooftopBar': return l10n.guestPlaceNameRooftopBar;
    case 'freshKitchen': return l10n.guestPlaceNameFreshKitchen;
    case 'historyMuseum': return l10n.guestPlaceNameHistoryMuseum;
    case 'spiceRoute': return l10n.guestPlaceNameSpiceRoute;
    case 'soulKitchen': return l10n.guestPlaceNameSoulKitchen;
    case 'studioCafe': return l10n.guestPlaceNameStudioCafe;
    default: return key;
  }
}

String _guestPlaceCategory(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  switch (key) {
    case 'Cafés': return l10n.guestCategoryCafes;
    case 'Restaurants': return l10n.guestCategoryRestaurants;
    case 'Museums': return l10n.guestCategoryMuseums;
    case 'Parks': return l10n.guestCategoryParks;
    case 'Nightlife': return l10n.guestCategoryNightlife;
    default: return key;
  }
}

String _guestPlaceDesc(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  switch (key) {
    case 'cozyCorner': return l10n.guestPlaceDescCozyCorner;
    case 'sunsetTerrace': return l10n.guestPlaceDescSunsetTerrace;
    case 'cityArtMuseum': return l10n.guestPlaceDescCityArtMuseum;
    case 'greenPark': return l10n.guestPlaceDescGreenPark;
    case 'jazzLounge': return l10n.guestPlaceDescJazzLounge;
    case 'rooftopBar': return l10n.guestPlaceDescRooftopBar;
    case 'freshKitchen': return l10n.guestPlaceDescFreshKitchen;
    case 'historyMuseum': return l10n.guestPlaceDescHistoryMuseum;
    case 'spiceRoute': return l10n.guestPlaceDescSpiceRoute;
    case 'soulKitchen': return l10n.guestPlaceDescSoulKitchen;
    case 'studioCafe': return l10n.guestPlaceDescStudioCafe;
    default: return '';
  }
}

List<_SamplePlace> _getSamplePlaces() {
  return [
    _SamplePlace(nameKey: 'cozyCorner', categoryKey: 'Cafés', descriptionKey: 'cozyCorner', rating: 4.8, distance: '0.5 km', emoji: '☕', color: Colors.brown, imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400', tags: ['aesthetic_spaces', 'vegetarian'], isOpenNow: true, hoursSummary: '08:00 – 18:00', isFree: false),
    _SamplePlace(nameKey: 'sunsetTerrace', categoryKey: 'Restaurants', descriptionKey: 'sunsetTerrace', rating: 4.6, distance: '1.2 km', emoji: '🍽️', color: Colors.orange, imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400', tags: ['halal', 'aesthetic_spaces'], isOpenNow: true, hoursSummary: '12:00 – 23:00', isFree: false),
    _SamplePlace(nameKey: 'cityArtMuseum', categoryKey: 'Museums', descriptionKey: 'cityArtMuseum', rating: 4.9, distance: '2.1 km', emoji: '🎨', color: Colors.purple, imageUrl: 'https://images.unsplash.com/photo-1561214115-f2f134cc4912?w=400', tags: ['aesthetic_spaces', 'wheelchair_accessible'], isOpenNow: true, hoursSummary: '10:00 – 17:00', isFree: false),
    _SamplePlace(nameKey: 'greenPark', categoryKey: 'Parks', descriptionKey: 'greenPark', rating: 4.7, distance: '0.8 km', emoji: '🌳', color: Colors.green, imageUrl: 'https://images.unsplash.com/photo-1511497584788-876760111969?w=400', tags: ['wheelchair_accessible'], isOpenNow: true, hoursSummary: null, isFree: true),
    _SamplePlace(nameKey: 'jazzLounge', categoryKey: 'Nightlife', descriptionKey: 'jazzLounge', rating: 4.5, distance: '1.5 km', emoji: '🎷', color: Colors.indigo, imageUrl: 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=400', tags: ['black_owned', 'aesthetic_spaces', 'lgbtq_friendly'], isOpenNow: false, hoursSummary: '18:00 – 02:00', isFree: false),
    _SamplePlace(nameKey: 'rooftopBar', categoryKey: 'Nightlife', descriptionKey: 'rooftopBar', rating: 4.4, distance: '1.8 km', emoji: '🍸', color: Colors.pink, imageUrl: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400', tags: ['aesthetic_spaces', 'lgbtq_friendly'], isOpenNow: true, hoursSummary: '17:00 – 01:00', isFree: false),
    _SamplePlace(nameKey: 'freshKitchen', categoryKey: 'Restaurants', descriptionKey: 'freshKitchen', rating: 4.7, distance: '0.9 km', emoji: '🥗', color: Colors.lightGreen, imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400', tags: ['halal', 'vegan'], isOpenNow: true, hoursSummary: '11:00 – 21:00', isFree: false),
    _SamplePlace(nameKey: 'historyMuseum', categoryKey: 'Museums', descriptionKey: 'historyMuseum', rating: 4.8, distance: '2.5 km', emoji: '🏛️', color: Colors.amber, imageUrl: 'https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?w=400', tags: ['wheelchair_accessible'], isOpenNow: false, hoursSummary: '09:00 – 17:00', isFree: true),
    _SamplePlace(nameKey: 'spiceRoute', categoryKey: 'Restaurants', descriptionKey: 'spiceRoute', rating: 4.6, distance: '1.0 km', emoji: '🍛', color: Colors.deepOrange, imageUrl: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=400', tags: ['halal', 'vegetarian'], isOpenNow: true, hoursSummary: '12:00 – 22:00', isFree: false),
    _SamplePlace(nameKey: 'soulKitchen', categoryKey: 'Restaurants', descriptionKey: 'soulKitchen', rating: 4.7, distance: '1.4 km', emoji: '🍖', color: Colors.brown, imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400', tags: ['black_owned', 'aesthetic_spaces', 'lgbtq_friendly'], isOpenNow: true, hoursSummary: '18:00 – 00:00', isFree: false),
    _SamplePlace(nameKey: 'studioCafe', categoryKey: 'Cafés', descriptionKey: 'studioCafe', rating: 4.5, distance: '0.7 km', emoji: '📷', color: Colors.blueGrey, imageUrl: 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=400', tags: ['aesthetic_spaces', 'vegan'], isOpenNow: true, hoursSummary: '07:00 – 19:00', isFree: false),
  ];
}

