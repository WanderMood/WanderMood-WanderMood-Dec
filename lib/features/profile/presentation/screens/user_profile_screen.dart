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
import '../../../../core/presentation/widgets/swirl_background.dart';

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
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFFFF7ED),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: const Color(0xFFFFF7ED),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(l10n.profileErrorLoad, style: GoogleFonts.poppins()),
              TextButton(
                onPressed: () => ref.read(currentUserProfileProvider.notifier).refresh(),
                child: Text(l10n.profileRetry),
              ),
            ],
          ),
        ),
      ),
      data: (CurrentUserProfile? profile) {
        if (profile == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFF7ED),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: const Color(0xFFFFF7ED),
          body: SwirlBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(context, profile),
                    const SizedBox(height: 24),
                    if (profile.ageGroup != null && profile.ageGroup!.isNotEmpty) ...[
                      _buildAgeGroupTag(profile.ageGroup!),
                      const SizedBox(height: 12),
                    ],
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      _buildBio(profile.bio!),
                      const SizedBox(height: 24),
                    ],
                    TravelModeToggle(
                      isLocal: profile.isLocalMode,
                      onModeChanged: _updateTravelMode,
                    ),
                    const SizedBox(height: 24),
                    const ProfileStatsCards(),
                    const SizedBox(height: 24),
                    FavoriteVibesCard(
                      selectedVibes: profile.selectedMoods,
                      onEditTap: () => _navigateToEditVibes(profile.selectedMoods),
                    ),
                    const SizedBox(height: 24),
                    _buildMoodJourneyCard(context),
                    const SizedBox(height: 24),
                    _buildTravelGlobeCard(context),
                    const SizedBox(height: 24),
                    _buildPreferencesCard(context, profile),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                  ],
                ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.push('/profile/edit'),
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2A6049), width: 3),
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
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: Color(0xFF2A6049), shape: BoxShape.circle),
                  child: _isUploadingImage
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              if (username != null && username.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('@$username', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
              ],
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
            child: Icon(Icons.settings, color: Colors.grey[700], size: 22),
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
      color: Colors.grey[200],
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildAgeGroupTag(String ageGroup) {
    final formattedAge = _formatAgeGroup(ageGroup);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A6049), // Green background
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
      style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700], height: 1.4),
    );
  }

  Widget _buildMoodJourneyCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => context.push('/moods/history'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8), spreadRadius: 0),
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: -2),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.profileMoodJourneyTitle, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(l10n.profileMoodJourneySubtitle, style: GoogleFonts.poppins(fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelGlobeCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => context.push('/profile/globe'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0F172A), // slate-900
              Color(0xFF1E293B), // slate-800
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.public,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileTravelGlobeTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.profileTravelGlobeSubtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 20,
            ),
          ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.profilePreferencesTitle, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () async {
                  await context.push('/preferences');
                  if (mounted) ref.read(currentUserProfileProvider.notifier).refresh();
                },
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 16, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 4),
                    Text(l10n.profilePreferencesEditAll, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF4CAF50))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (profile.budgetLevel != null && profile.budgetLevel!.isNotEmpty) ...[
            _buildPrefButton(l10n.profilePreferencesBudgetStyle, _formatBudget(l10n, profile.budgetLevel), const Color(0xFFFFB74D)),
            const SizedBox(height: 12),
          ],
          if (profile.socialVibe != null && profile.socialVibe!.isNotEmpty) ...[
            _buildPrefButton(l10n.profilePreferencesSocialVibe, _formatSocialVibe(l10n, profile.socialVibe), const Color(0xFFEF5350)),
            const SizedBox(height: 12),
          ],
          if (profile.dietaryRestrictions.isNotEmpty) ...[
            _buildPrefButton(l10n.profilePreferencesFoodPreferences, _formatFoodPreferences(profile.dietaryRestrictions), const Color(0xFFF97316), endColor: const Color(0xFFEC4899)),
            const SizedBox(height: 12),
          ],
          if (!hasAny)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                l10n.profilePreferencesEmptyHint,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrefButton(String label, String value, Color color, {Color? endColor}) {
    final gradient = endColor != null 
        ? LinearGradient(colors: [color, endColor])
        : null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
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

  Widget _buildActionButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF97316), // orange-500
                  Color(0xFFEC4899), // pink-500
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: const [],
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              label: Text(
                l10n.profileActionEdit,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B82F6), // blue-500
                  Color(0xFF9333EA), // purple-600
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: const [],
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/share-profile'),
              icon: const Icon(Icons.share, color: Colors.white, size: 20),
              label: Text(
                l10n.profileActionShare,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
