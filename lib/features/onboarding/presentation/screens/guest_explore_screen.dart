import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

/// WanderMood design tokens — guest explore
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmSunsetTint = Color(0xFFFDF0E8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

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

/// USP filter ids (maps to tags / place fields without changing mock data).
const List<String> _uspFilterIds = [
  'halal',
  'vegan',
  'black_owned',
  'wheelchair',
  'lgbtq',
  'pets',
  'budget',
];

class _GuestExploreScreenState extends ConsumerState<GuestExploreScreen> {
  final List<_SamplePlace> _places = _getSamplePlaces();
  bool _showSignupBanner = false;
  final Set<String> _selectedUspFilters = {};

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
    final l10n = AppLocalizations.of(context)!;
    showWanderMoodToast(
      context,
      message: l10n.guestSignUpToSaveFavorites,
      duration: const Duration(seconds: 4),
      leading: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
      actionLabel: l10n.guestSignUp,
      onAction: _navigateToSignup,
    );
  }

  void _navigateToSignup() {
    // Mark guest explore as done
    ref.read(onboardingProgressProvider.notifier).markGuestExploreCompleted();
    ref.read(currentOnboardingStepProvider.notifier).state = OnboardingStep.signup;
    
    context.go('/auth/magic-link');
  }

  bool _placeMatchesFilters(_SamplePlace p) {
    if (_selectedUspFilters.isEmpty) return true;
    for (final id in _selectedUspFilters) {
      if (_uspMatchesPlace(p, id)) return true;
    }
    return false;
  }

  bool _uspMatchesPlace(_SamplePlace p, String id) {
    switch (id) {
      case 'halal':
        return p.tags.contains('halal');
      case 'vegan':
        return p.tags.contains('vegan');
      case 'black_owned':
        return p.tags.contains('black_owned');
      case 'wheelchair':
        return p.tags.contains('wheelchair_accessible');
      case 'lgbtq':
        return p.tags.contains('lgbtq_friendly');
      case 'pets':
        return p.tags.contains('pet_friendly');
      case 'budget':
        return p.isFree;
      default:
        return false;
    }
  }

  String _uspChipLabel(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;
    switch (id) {
      case 'halal':
        return '${l10n.guestFilterHalal} 🕌';
      case 'vegan':
        return '${l10n.guestFilterVegan} 🌱';
      case 'black_owned':
        return '${l10n.guestFilterBlackOwned} 🖤';
      case 'wheelchair':
        return '${l10n.guestFilterWheelchair} ♿';
      case 'lgbtq':
        return '${l10n.guestFilterLgbtq} 🏳️‍🌈';
      case 'pets':
        if (lc == 'nl') return 'Huisdieren welkom 🐾';
        if (lc == 'de') return 'Haustiere willkommen 🐾';
        if (lc == 'fr') return 'Animaux bienvenus 🐾';
        if (lc == 'es') return 'Mascotas bienvenidas 🐾';
        return 'Pet-friendly 🐾';
      case 'budget':
        if (lc == 'nl') return 'Budgetvriendelijk 💰';
        if (lc == 'de') return 'Budgetfreundlich 💰';
        if (lc == 'fr') return 'Économique 💰';
        if (lc == 'es') return 'Económico 💰';
        return 'Budget-friendly 💰';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _wmCream,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            if (_showSignupBanner) _buildSignupBanner(),
            _buildUspFilterRow(),
            Expanded(
              child: _buildPlacesGrid(),
            ),
            _buildBottomSignupCta(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSignupCta(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _navigateToSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: _wmForest,
              foregroundColor: _wmWhite,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: _wmWhite, size: 22),
                const SizedBox(width: 8),
                Text(
                  l10n.guestSignUpFree,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _wmWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => context.go('/demo'),
            icon: const Icon(Icons.arrow_back_rounded),
            color: _wmCharcoal,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.guestExplorePlaces,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: _wmCharcoal,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.guestPreviewMode,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _wmStone,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _wmForestTint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline_rounded, size: 18, color: _wmForest),
                  const SizedBox(width: 6),
                  Text(
                    l10n.guestGuest,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _wmForest,
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

  Widget _buildSignupBanner() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _wmSunsetTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _wmSunset.withValues(alpha: 0.2)),
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
                  l10n.guestLovingWhatYouSee,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _wmCharcoal,
                  ),
                ),
                Text(
                  l10n.guestSignUpSaveFavorites,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _wmStone,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _navigateToSignup,
            style: TextButton.styleFrom(
              backgroundColor: _wmWhite,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: _wmParchment),
              ),
            ),
            child: Text(
              l10n.guestSignUp,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _wmForest,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showSignupBanner = false;
              });
            },
            icon: Icon(Icons.close, size: 20, color: _wmStone.withValues(alpha: 0.9)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildUspFilterRow() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _uspFilterIds.length,
        itemBuilder: (context, index) {
          final id = _uspFilterIds[index];
          final selected = _selectedUspFilters.contains(id);
          return Padding(
            padding: EdgeInsets.only(right: index == _uspFilterIds.length - 1 ? 0 : 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (selected) {
                      _selectedUspFilters.remove(id);
                    } else {
                      _selectedUspFilters.add(id);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _wmForestTint : _wmWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? _wmForest : _wmParchment,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _uspChipLabel(context, id),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? _wmForest : _wmStone,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<_SamplePlace> _getFilteredPlaces() {
    return _places.where(_placeMatchesFilters).toList();
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.66,
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
          color: _wmWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _wmParchment, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 120,
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
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _wmWhite,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark_border,
                        size: 16,
                        color: _wmStone,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _guestPlaceName(context, place.nameKey),
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _wmCharcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _guestPlaceCategory(context, place.categoryKey),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _wmStone,
                        height: 1.4,
                      ),
                    ),
                    if (place.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _placeFilterBadges(context, place.tags, compact: true, maxCount: 2),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: _wmSunset),
                        const SizedBox(width: 4),
                        Text(
                          place.rating.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _wmCharcoal,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _guestDistanceLine(context, place.distanceKm),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _wmStone,
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
                        _guestDistanceLine(context, place.distanceKm),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (place.hoursStart != null &&
                      place.hoursEnd != null &&
                      place.hoursStart!.isNotEmpty &&
                      place.hoursEnd!.isNotEmpty) ...[
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
                          AppLocalizations.of(context)!.guestPlaceHoursRange(
                            place.hoursStart!,
                            place.hoursEnd!,
                          ),
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
    'black_owned': '🖤',
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
              horizontal: compact ? 6 : 8,
              vertical: compact ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: compact ? _wmForestTint : (colors[k] ?? Colors.grey[200]!).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(compact ? 8 : 12),
              border: compact
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 0.5,
                    ),
            ),
            child: Text(
              '${emojis[k]} ${labels[k]}',
              style: GoogleFonts.poppins(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w500,
                color: compact ? _wmForest : Colors.grey[800],
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
  final double distanceKm;
  final String emoji;
  final Color color;
  final String imageUrl;
  /// Filter tags: halal, black_owned, aesthetic_spaces, lgbtq_friendly, vegan, vegetarian, wheelchair_accessible
  final List<String> tags;
  /// Mock: whether the place is currently open
  final bool isOpenNow;
  /// Mock: opening hours (24h strings); both null if not shown
  final String? hoursStart;
  final String? hoursEnd;
  /// Mock: true for free entry (e.g. parks, some museums)
  final bool isFree;

  _SamplePlace({
    required this.nameKey,
    required this.categoryKey,
    required this.descriptionKey,
    required this.rating,
    required this.distanceKm,
    required this.emoji,
    required this.color,
    required this.imageUrl,
    this.tags = const [],
    this.isOpenNow = true,
    this.hoursStart,
    this.hoursEnd,
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

/// Localized distance line for sample cards (km + "away" phrasing).
String _guestDistanceLine(BuildContext context, double distanceKm) {
  final l10n = AppLocalizations.of(context)!;
  final kmStr = (distanceKm == distanceKm.roundToDouble())
      ? distanceKm.toStringAsFixed(0)
      : distanceKm.toStringAsFixed(1);
  return l10n.guestDistanceAway(l10n.guestPlaceDistanceKm(kmStr));
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
    _SamplePlace(nameKey: 'cozyCorner', categoryKey: 'Cafés', descriptionKey: 'cozyCorner', rating: 4.8, distanceKm: 0.5, emoji: '☕', color: Colors.brown, imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400', tags: ['aesthetic_spaces', 'vegetarian'], isOpenNow: true, hoursStart: '08:00', hoursEnd: '18:00', isFree: false),
    _SamplePlace(nameKey: 'sunsetTerrace', categoryKey: 'Restaurants', descriptionKey: 'sunsetTerrace', rating: 4.6, distanceKm: 1.2, emoji: '🍽️', color: Colors.orange, imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400', tags: ['halal', 'aesthetic_spaces'], isOpenNow: true, hoursStart: '12:00', hoursEnd: '23:00', isFree: false),
    _SamplePlace(nameKey: 'cityArtMuseum', categoryKey: 'Museums', descriptionKey: 'cityArtMuseum', rating: 4.9, distanceKm: 2.1, emoji: '🎨', color: Colors.purple, imageUrl: 'https://images.unsplash.com/photo-1561214115-f2f134cc4912?w=400', tags: ['aesthetic_spaces', 'wheelchair_accessible'], isOpenNow: true, hoursStart: '10:00', hoursEnd: '17:00', isFree: false),
    _SamplePlace(nameKey: 'greenPark', categoryKey: 'Parks', descriptionKey: 'greenPark', rating: 4.7, distanceKm: 0.8, emoji: '🌳', color: Colors.green, imageUrl: 'https://images.unsplash.com/photo-1511497584788-876760111969?w=400', tags: ['wheelchair_accessible'], isOpenNow: true, isFree: true),
    _SamplePlace(nameKey: 'jazzLounge', categoryKey: 'Nightlife', descriptionKey: 'jazzLounge', rating: 4.5, distanceKm: 1.5, emoji: '🎷', color: Colors.indigo, imageUrl: 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=400', tags: ['black_owned', 'aesthetic_spaces', 'lgbtq_friendly'], isOpenNow: false, hoursStart: '18:00', hoursEnd: '02:00', isFree: false),
    _SamplePlace(nameKey: 'rooftopBar', categoryKey: 'Nightlife', descriptionKey: 'rooftopBar', rating: 4.4, distanceKm: 1.8, emoji: '🍸', color: Colors.pink, imageUrl: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400', tags: ['aesthetic_spaces', 'lgbtq_friendly'], isOpenNow: true, hoursStart: '17:00', hoursEnd: '01:00', isFree: false),
    _SamplePlace(nameKey: 'freshKitchen', categoryKey: 'Restaurants', descriptionKey: 'freshKitchen', rating: 4.7, distanceKm: 0.9, emoji: '🥗', color: Colors.lightGreen, imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400', tags: ['halal', 'vegan'], isOpenNow: true, hoursStart: '11:00', hoursEnd: '21:00', isFree: false),
    _SamplePlace(nameKey: 'historyMuseum', categoryKey: 'Museums', descriptionKey: 'historyMuseum', rating: 4.8, distanceKm: 2.5, emoji: '🏛️', color: Colors.amber, imageUrl: 'https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?w=400', tags: ['wheelchair_accessible'], isOpenNow: false, hoursStart: '09:00', hoursEnd: '17:00', isFree: true),
    _SamplePlace(nameKey: 'spiceRoute', categoryKey: 'Restaurants', descriptionKey: 'spiceRoute', rating: 4.6, distanceKm: 1.0, emoji: '🍛', color: Colors.deepOrange, imageUrl: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=400', tags: ['halal', 'vegetarian'], isOpenNow: true, hoursStart: '12:00', hoursEnd: '22:00', isFree: false),
    _SamplePlace(nameKey: 'soulKitchen', categoryKey: 'Restaurants', descriptionKey: 'soulKitchen', rating: 4.7, distanceKm: 1.4, emoji: '🍖', color: Colors.brown, imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400', tags: ['black_owned', 'aesthetic_spaces', 'lgbtq_friendly'], isOpenNow: true, hoursStart: '18:00', hoursEnd: '00:00', isFree: false),
    _SamplePlace(nameKey: 'studioCafe', categoryKey: 'Cafés', descriptionKey: 'studioCafe', rating: 4.5, distanceKm: 0.7, emoji: '📷', color: Colors.blueGrey, imageUrl: 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=400', tags: ['aesthetic_spaces', 'vegan'], isOpenNow: true, hoursStart: '07:00', hoursEnd: '19:00', isFree: false),
  ];
}

