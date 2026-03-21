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
import 'package:cached_network_image/cached_network_image.dart';
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

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

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
                  const SizedBox(height: 20),
                  if (profile.ageGroup != null && profile.ageGroup!.isNotEmpty) ...[
                    _buildAgeGroupTag(profile.ageGroup!),
                    const SizedBox(height: 12),
                  ],
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    _buildBio(profile.bio!),
                    const SizedBox(height: 20),
                  ],
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
                  const SizedBox(height: 20),
                  _buildSavedPlacesPreview(context),
                  const SizedBox(height: 20),
                  _buildMoodJourneyCard(context),
                  const SizedBox(height: 20),
                  _buildTravelGlobeCard(context),
                  const SizedBox(height: 20),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => context.push('/profile/edit'),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _wmForest, width: 2),
                ),
                child: ClipOval(
                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(userName, username),
                        )
                      : _buildAvatarPlaceholder(userName, username),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: GestureDetector(
                onTap: _changeProfilePicture,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _wmForest,
                    shape: BoxShape.circle,
                  ),
                  child: _isUploadingImage
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userName,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _wmCharcoal,
            letterSpacing: -0.5,
          ),
        ),
        if (username != null && username.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '@$username',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _wmStone,
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push('/profile/edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _wmForest,
              side: const BorderSide(color: _wmForest, width: 1.5),
              backgroundColor: _wmWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              l10n.profileEditProfileButton,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildAgeGroupTag(String ageGroup) {
    final formattedAge = _formatAgeGroup(ageGroup);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _wmForest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            formattedAge,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio(String bio) {
    return Text(
      bio,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: _wmDusk,
        height: 1.5,
      ),
    );
  }

  Widget _buildSavedPlacesPreview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final savedAsync = ref.watch(savedPlacesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.profileSavedPlacesTitle,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _wmCharcoal,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/places/saved'),
              style: TextButton.styleFrom(
                foregroundColor: _wmForest,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.profileSavedPlacesSeeAll,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
              return Text(
                l10n.profileSavedPlacesEmpty,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _wmStone,
                  height: 1.5,
                ),
              );
            }
            final preview = places.take(8).toList();
            final cardW = (MediaQuery.sizeOf(context).width - 40 - 24) / 3.2;
            // Image 80 + gap 6 + title (2 lines ~34px) + address (~15px) ≈ 135; extra for font metrics.
            return SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: preview.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final sp = preview[i];
                  final p = sp.place;
                  final img = p.photos.isNotEmpty ? p.photos.first : null;
                  return GestureDetector(
                    onTap: () => context.push('/place/${p.id}'),
                    child: SizedBox(
                      width: cardW.clamp(108.0, 140.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 80,
                              width: double.infinity,
                              child: img != null && img.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: img,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: _wmForestTint),
                                      errorWidget: (_, __, ___) => Container(
                                        color: _wmForestTint,
                                        child: const Icon(Icons.place_outlined, color: _wmStone),
                                      ),
                                    )
                                  : Container(
                                      color: _wmForestTint,
                                      child: const Icon(Icons.place_outlined, color: _wmStone, size: 32),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _wmCharcoal,
                              height: 1.2,
                            ),
                          ),
                          if (p.address.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              p.address.split(',').first.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                height: 1.2,
                                color: _wmStone,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 80,
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
            style: GoogleFonts.poppins(fontSize: 15, color: _wmStone),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodJourneyCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/moods/history'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _wmForestTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _wmForest, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileMoodJourneyTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _wmCharcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.profileMoodJourneySubtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: _wmDusk,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 22, color: _wmForest),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTravelGlobeCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/profile/globe'),
        child: Container(
          decoration: BoxDecoration(
            color: _wmWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _wmParchment, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.public,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileTravelGlobeTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.profileTravelGlobeSubtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context, CurrentUserProfile profile) {
    final l10n = AppLocalizations.of(context)!;
    final hasAny = (profile.budgetLevel != null && profile.budgetLevel!.isNotEmpty) ||
        (profile.socialVibe != null && profile.socialVibe!.isNotEmpty) ||
        profile.dietaryRestrictions.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmParchment, width: 0.5),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _wmCharcoal,
                ),
              ),
              TextButton(
                onPressed: () async {
                  await context.push('/preferences');
                  if (mounted) ref.read(currentUserProfileProvider.notifier).refresh();
                },
                style: TextButton.styleFrom(
                  foregroundColor: _wmForest,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.profilePreferencesEditAll,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (profile.budgetLevel != null && profile.budgetLevel!.isNotEmpty) ...[
            _buildPrefRow(l10n.profilePreferencesBudgetStyle, _formatBudget(l10n, profile.budgetLevel)),
            const SizedBox(height: 10),
          ],
          if (profile.socialVibe != null && profile.socialVibe!.isNotEmpty) ...[
            _buildPrefRow(l10n.profilePreferencesSocialVibe, _formatSocialVibe(l10n, profile.socialVibe)),
            const SizedBox(height: 10),
          ],
          if (profile.dietaryRestrictions.isNotEmpty) ...[
            _buildPrefRow(l10n.profilePreferencesFoodPreferences, _formatFoodPreferences(profile.dietaryRestrictions)),
            const SizedBox(height: 10),
          ],
          if (!hasAny)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.profilePreferencesEmptyHint,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: _wmStone,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrefRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _wmCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _wmParchment, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _wmStone,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _wmCharcoal,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSettingsLink(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/settings'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_outlined, color: _wmStone, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.profileAppSettingsLink,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _wmStone,
              ),
            ),
          ],
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
    
    // Default: add "Adventurer" suffix
    return '$ageGroup Adventurer';
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
