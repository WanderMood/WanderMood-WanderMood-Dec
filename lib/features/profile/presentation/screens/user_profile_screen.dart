// =============================================================================
// User Profile Screen - uses CurrentUserProfileProvider (single source of truth)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../domain/models/current_user_profile.dart';
import '../../domain/providers/current_user_profile_provider.dart';
import '../../domain/providers/profile_provider.dart';
import '../widgets/edit_favorite_vibes.dart';
import '../widgets/travel_mode_toggle.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import '../widgets/profile_stats_cards.dart';
import '../utils/preference_chip_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wandermood/core/cache/wandermood_image_cache_manager.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/moody_explore_provider.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';

/// v2 profile — design tokens
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmSunsetTint = Color(0xFFFDF0E8);
const Color _wmSkyTint = Color(0xFFEDF5F9);
/// Matches My Day "PLANNED" chip (`my_day_timeline_section.dart` _kWmWarmBronze).
const Color _wmWarmBronze = Color(0xFF8F7355);
const Color _wmWarmBronzeDeep = Color(0xFF6B5A47);

List<BoxShadow> _profileCardShadow() {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Same elevation feel as My Day activity cards.
List<BoxShadow> _savedPlacesCarouselCardShadow() {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;
  bool _isLoadingPreferences = false;
  String? _communicationStyle;
  List<String> _travelInterests = [];
  List<String> _socialVibe = [];
  List<String> _travelStyles = [];
  List<String> _favoriteMoods = [];
  String? _planningPace;
  List<String> _selectedMoods = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;
    setState(() => _isLoadingPreferences = true);
    try {
      final prefs = await _supabase
          .from('user_preferences')
          .select('''
            communication_style,
            travel_interests,
            social_vibe,
            travel_styles,
            favorite_moods,
            planning_pace,
            selected_moods
          ''')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _communicationStyle = prefs?['communication_style'] as String?;
        _travelInterests =
            List<String>.from((prefs?['travel_interests'] as List?) ?? const []);
        _socialVibe =
            List<String>.from((prefs?['social_vibe'] as List?) ?? const []);
        _travelStyles =
            List<String>.from((prefs?['travel_styles'] as List?) ?? const []);
        _favoriteMoods =
            List<String>.from((prefs?['favorite_moods'] as List?) ?? const []);
        _planningPace = prefs?['planning_pace'] as String?;
        _selectedMoods =
            List<String>.from((prefs?['selected_moods'] as List?) ?? const []);
        _isLoadingPreferences = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPreferences = false);
    }
  }

  Future<void> _changeProfilePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) return;

      setState(() => _isUploadingImage = true);
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '$userId/avatar.$fileExt';
      await _supabase.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true, cacheControl: '3600'));
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      // Write only to `image_url` because some environments don't have `avatar_url`.
      await _supabase.from('profiles').update({
        'image_url': imageUrl,
      }).eq('id', userId);

      ref.invalidate(profileProvider);
      await ref.read(currentUserProfileProvider.notifier).refresh();
      if (mounted) {
        setState(() => _isUploadingImage = false);
        final l10n = AppLocalizations.of(context)!;
        showWanderMoodToast(context, message: l10n.profileSnackAvatarUpdated);
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      if (mounted) {
        setState(() => _isUploadingImage = false);
        final l10n = AppLocalizations.of(context)!;
        showWanderMoodToast(
          context,
          message: l10n.profileSnackAvatarFailed(e.toString()),
          isError: true,
        );
      }
    }
  }

  Future<void> _updateTravelMode(bool isLocal) async {
    await ref.read(currentUserProfileProvider.notifier).updateTravelMode(isLocal);
    // Invalidate explore cache so next visit fetches results for new mode
    ref.invalidate(moodyExploreAutoProvider);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showWanderMoodToast(
      context,
      message:
          isLocal ? l10n.profileSnackLocalModeSaved : l10n.profileSnackTravelingModeSaved,
    );
  }

  void _handleVibesUpdated(List<String> updatedVibes) {
    ref.read(currentUserProfileProvider.notifier).updateVibes(updatedVibes);
    ref.read(currentUserProfileProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => Scaffold(
        backgroundColor: _wmCream,
        body: Center(
          child: CircularProgressIndicator(color: _wmForest),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: _wmCream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFE05C5C)),
              const SizedBox(height: 16),
              Text(l10n.profileErrorLoad, style: GoogleFonts.poppins(color: _wmDusk)),
              TextButton(
                onPressed: () => ref.read(currentUserProfileProvider.notifier).refresh(),
                child: Text(l10n.profileRetry, style: const TextStyle(color: _wmForest)),
              ),
            ],
          ),
        ),
      ),
      data: (CurrentUserProfile? profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: _wmCream,
            body: Center(
              child: CircularProgressIndicator(color: _wmForest),
            ),
          );
        }
        return Scaffold(
          backgroundColor: _wmCream,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(context, profile),
                  const SizedBox(height: 18),
                  _buildSavedPlacesCarouselStrip(context),
                  const SizedBox(height: 20),
                  TravelModeToggle(
                    isLocal: profile.isLocalMode,
                    onModeChanged: _updateTravelMode,
                  ),
                  const SizedBox(height: 20),
                  const ProfileStatsCards(),
                  const SizedBox(height: 20),
                  FavoriteVibesCard(
                    selectedVibes: profile.selectedMoods,
                    onEditTap: () => _navigateToEditVibes(profile.selectedMoods),
                  ),
                  const SizedBox(height: 24),
                  _buildTravelGlobeCard(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    title: l10n.profilePreferencesTitle,
                    subtitle: l10n.profileSectionPreferencesSubtitle,
                  ),
                  const SizedBox(height: 14),
                  _buildPreferencesCard(context, profile),
                  const SizedBox(height: 12),
                  _buildBottomSettingsLink(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, CurrentUserProfile profile) {
    final l10n = AppLocalizations.of(context)!;
    final avatarUrl = profile.avatarUrl;
    final userName = profile.fullName ?? l10n.profileFallbackUser;
    final username = profile.username;
    final displayedVibes = profile.selectedMoods.take(3).toList();
    final hasChips = (profile.ageGroup != null && profile.ageGroup!.isNotEmpty) ||
        displayedVibes.isNotEmpty;
    final bioText = profile.bio?.trim();
    final hasBio = bioText != null && bioText.isNotEmpty;
    final String bioDisplay;
    if (hasBio) {
      bioDisplay = bioText;
    } else {
      bioDisplay = l10n.profileBioEmptyHint;
    }

    // Non-uniform border colors cannot use borderRadius (Flutter assert).
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: _profileCardShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _wmWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _wmParchment, width: 1),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _wmForest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/profile/edit'),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _wmForestTint,
                        border: Border.all(color: _wmForest, width: 1.5),
                      ),
                      child: ClipOval(
                        child: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? WmNetworkImage(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildAvatarPlaceholder(userName, username),
                              )
                            : _buildAvatarPlaceholder(userName, username),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: _changeProfilePicture,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _wmForest,
                          shape: BoxShape.circle,
                          border: Border.all(color: _wmWhite, width: 2),
                        ),
                        child: _isUploadingImage
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 15),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _wmSunsetTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _wmParchment, width: 1),
                        ),
                        child: const Text('✨', style: TextStyle(fontSize: 18, height: 1)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _wmCharcoal,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _wmSkyTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _wmParchment, width: 1),
                ),
                child: const Text('📝', style: TextStyle(fontSize: 16, height: 1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.bio,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _wmStone,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bioDisplay,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: hasBio ? _wmDusk : _wmStone,
                        height: 1.45,
                        fontStyle: hasBio ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasChips) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (profile.ageGroup != null && profile.ageGroup!.isNotEmpty)
                  _buildHeroChip(
                    icon: Icons.calendar_today_rounded,
                    label: _formatAgeGroup(profile.ageGroup!),
                    fillColor: _wmCream,
                    textColor: _wmDusk,
                  ),
                ...displayedVibes.map(
                  (vibe) => _buildHeroChip(
                    icon: Icons.auto_awesome_rounded,
                    label: vibe,
                    fillColor: _wmCream,
                    textColor: _wmForest,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/profile/edit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _wmForest,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Text('✏️', style: TextStyle(fontSize: 16)),
              label: Text(
                l10n.profileEditProfileButton,
                style: GoogleFonts.poppins(
                  fontSize: 15,
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
    );
  }

  Widget _buildAvatarPlaceholder(String? userName, String? username) {
    final initial = (userName?.isNotEmpty == true
        ? userName!.substring(0, 1).toUpperCase()
        : (username?.isNotEmpty == true ? username!.substring(0, 1).toUpperCase() : '?'));
    return Container(
      color: _wmForestTint,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _wmForest,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroChip({
    required IconData icon,
    required String label,
    required Color fillColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _wmParchment, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _wmCharcoal,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _wmStone,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  /// Frosted bronze tile — photo + blur + gradient; white type (profile carousel).
  Widget _buildSavedPlaceGlassCarouselTile(
    BuildContext context, {
    required Place place,
    required double width,
    required double height,
  }) {
    final img = place.photos.isNotEmpty ? place.photos.first : null;
    final hasPhoto = img != null && img.startsWith('http');
    final addressLine =
        place.address.isNotEmpty ? place.address.split(',').first.trim() : '';

    return GestureDetector(
      onTap: () => context.push('/place/${place.id}'),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: _savedPlacesCarouselCardShadow(),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.32),
            width: 1.25,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              CachedNetworkImage(
                cacheManager: WanderMoodImageCacheManager.instance,
                imageUrl: img,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: _wmWarmBronze,
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => _savedPlaceGlassFallbackFill(),
              )
            else
              _savedPlaceGlassFallbackFill(),
            // Photo stays sharp: only a bottom scrim (no full-card blur — that
            // hid the image behind brown mush).
            if (hasPhoto)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        _wmWarmBronze.withValues(alpha: 0.45),
                        _wmWarmBronzeDeep.withValues(alpha: 0.9),
                      ],
                      stops: const [0.0, 0.42, 0.72, 1.0],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                        shadows: const [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    if (addressLine.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        addressLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedPlaceGlassFallbackFill() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _wmWarmBronze,
            _wmWarmBronzeDeep,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.place_rounded,
          color: Colors.white.withValues(alpha: 0.45),
          size: 44,
        ),
      ),
    );
  }

  /// Horizontal saved places on cream background (no outer white card).
  Widget _buildSavedPlacesCarouselStrip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final savedAsync = ref.watch(savedPlacesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _wmForestTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _wmParchment, width: 1),
              ),
              child: const Text('📌', style: TextStyle(fontSize: 16, height: 1)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.profileSavedPlacesTitle,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _wmCharcoal,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/places/saved'),
              style: TextButton.styleFrom(
                foregroundColor: _wmForest,
                backgroundColor: _wmWhite,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: const BorderSide(color: _wmParchment),
                ),
              ),
              child: Text(
                l10n.profileSavedPlacesSeeAll,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        savedAsync.when(
          data: (places) {
            if (places.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _wmSunsetTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('💡', style: TextStyle(fontSize: 14, height: 1)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.profileSavedPlacesCarouselEmpty,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _wmDusk,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            final preview = places.take(12).toList();
            final trackW = MediaQuery.sizeOf(context).width - 40;
            const sepW = 14.0;
            final double cardW;
            if (preview.length <= 1) {
              cardW = trackW;
            } else {
              // Layout: [card][sep][card][sep][½ card] ≈ 2.5 tiles visible.
              cardW = ((trackW - 2 * sepW) / 2.5).clamp(108.0, 148.0);
            }
            final cardH = preview.length <= 1 ? 216.0 : (cardW * 1.28).clamp(150.0, 182.0);
            return SizedBox(
              height: cardH,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 6),
                physics: const BouncingScrollPhysics(),
                itemCount: preview.length,
                separatorBuilder: (_, __) => const SizedBox(width: sepW),
                itemBuilder: (context, i) {
                  return _buildSavedPlaceGlassCarouselTile(
                    context,
                    place: preview[i].place,
                    width: cardW,
                    height: cardH,
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 176,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: _wmForest),
              ),
            ),
          ),
          error: (_, __) => Text(
            l10n.profileSavedPlacesEmpty,
            style: GoogleFonts.poppins(fontSize: 14, color: _wmStone),
          ),
        ),
      ],
    );
  }

  Widget _buildTravelGlobeCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/profile/globe'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _wmWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _wmParchment, width: 1),
            boxShadow: _profileCardShadow(),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _wmForestTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _wmParchment, width: 1),
                ),
                child: const Icon(Icons.public_rounded, color: _wmForest, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileTravelGlobeTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _wmCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.profileTravelGlobeSubtitle,
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
              const Icon(Icons.chevron_right_rounded, color: _wmForest, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context, CurrentUserProfile profile) {
    final l10n = AppLocalizations.of(context)!;
    final chips = <String>[
      if (_communicationStyle != null && _communicationStyle!.trim().isNotEmpty)
        _communicationStyle!,
      ..._travelInterests,
      ..._socialVibe,
      ..._travelStyles,
      ..._favoriteMoods,
      if (_planningPace != null && _planningPace!.trim().isNotEmpty) _planningPace!,
      ..._selectedMoods,
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmWhite,
        border: Border.all(color: _wmParchment, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.profilePreferencesTitle,
                style: GoogleFonts.poppins(
                  color: _wmCharcoal,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await context.push('/preferences');
                  if (!mounted) return;
                  await _loadPreferences();
                  ref.read(currentUserProfileProvider.notifier).refresh();
                },
                child: Text(
                  l10n.profilePreferencesEditAll,
                  style: GoogleFonts.poppins(
                    color: _wmForest,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingPreferences)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: _wmForest),
              ),
            )
          else if (chips.isEmpty)
            Text(
              l10n.profilePreferencesNoneSet,
              style: GoogleFonts.poppins(color: _wmStone, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map(
                    (chip) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _wmForestTint,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _wmParchment, width: 0.8),
                      ),
                      child: Text(
                        localizedPreferenceChip(l10n, chip),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _wmForest,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSettingsLink(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: TextButton.icon(
        onPressed: () => context.push('/settings'),
        style: TextButton.styleFrom(
          foregroundColor: _wmStone,
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: const Icon(Icons.settings_outlined, size: 18),
        label: Text(
          l10n.profileAppSettingsLink,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _wmStone,
          ),
        ),
      ),
    );
  }

  void _navigateToEditVibes(List<String> initialVibes) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFavoriteVibesScreen(
          initialVibes: initialVibes,
          onSave: _handleVibesUpdated,
        ),
      ),
    );
    ref.read(currentUserProfileProvider.notifier).refresh();
  }

  String _formatAgeGroup(String? ageGroup) {
    final l10n = AppLocalizations.of(context)!;
    if (ageGroup == null || ageGroup.isEmpty) return '';
    
    // Format to localized "20s Adventurer" style
    if (ageGroup.contains('18-24') || ageGroup.contains('18') || ageGroup.contains('20')) {
      return l10n.profileAgeGroup20s;
    } else if (ageGroup.contains('25-34') || ageGroup.contains('25') || ageGroup.contains('30')) {
      return l10n.profileAgeGroup30s;
    } else if (ageGroup.contains('35-44') || ageGroup.contains('35') || ageGroup.contains('40')) {
      return l10n.profileAgeGroup40s;
    } else if (ageGroup.contains('45-54') || ageGroup.contains('45') || ageGroup.contains('50')) {
      return l10n.profileAgeGroup50s;
    } else if (ageGroup.contains('55+') || ageGroup.contains('55')) {
      return l10n.profileAgeGroup55Plus;
    }
    
    // If it already has "Adventurer" or similar, return as is
    if (ageGroup.toLowerCase().contains('adventurer') || 
        ageGroup.toLowerCase().contains('explorer') ||
        ageGroup.toLowerCase().contains('traveler')) {
      return ageGroup;
    }
    
    // Default: localized suffix for unknown age-group strings
    return l10n.profileAgeGroupGenericSuffix(ageGroup);
  }

  String _formatBudget(AppLocalizations l10n, String? budget) {
    if (budget == null || budget.isEmpty) return '';
    
    final budgetLower = budget.toLowerCase();
    if (budgetLower.contains('low') || budgetLower.contains('budget') || budget == '\$') {
      return l10n.profileBudgetLow;
    }
    if (budgetLower.contains('mid') || budgetLower.contains('moderate') || budget == '\$\$') {
      return l10n.profileBudgetMid;
    }
    if (budgetLower.contains('high') || budgetLower.contains('luxury') || budget == '\$\$\$' || budget == '\$\$\$\$') {
      return l10n.profileBudgetHigh;
    }
    return budget;
  }

  String _formatSocialVibe(AppLocalizations l10n, String? vibe) {
    if (vibe == null || vibe.isEmpty) return '';
    
    final vibeLower = vibe.toLowerCase();
    if (vibeLower == 'solo' || vibeLower == 'solo-friendly') return l10n.profileSocialSolo;
    if (vibeLower == 'couple') return l10n.profileSocialCouple;
    if (vibeLower == 'group' || vibeLower == 'small-group') return l10n.profileSocialGroup;
    if (vibeLower == 'mix' || vibeLower == 'mixed') return l10n.profileSocialMix;
    if (vibeLower == 'social' || vibeLower == 'social-scene') return l10n.profileSocialSocial;
    
    return vibe.split('-').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatFoodPreferences(List<String> restrictions) {
    if (restrictions.isEmpty) return '';
    
    if (restrictions.length == 1) {
      return restrictions.first;
    }
    return '${restrictions.first} +${restrictions.length - 1}';
  }

}
