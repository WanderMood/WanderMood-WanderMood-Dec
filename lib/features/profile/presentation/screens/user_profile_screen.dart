// =============================================================================
// Enhanced User Profile Screen - Redesigned to match design
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/edit_favorite_vibes.dart';
import '../widgets/travel_mode_toggle.dart';
import '../widgets/profile_stats_cards.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  
  // User data
  String? _userName;
  String? _username;
  String? _bio;
  String? _avatarUrl;
  String? _ageGroup;
  bool _isLocalMode = true;
  List<String> _selectedVibes = [];
  
  // Preferences
  String? _budgetLevel;
  String? _socialVibe;
  List<String> _dietaryRestrictions = [];
  
  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final profileResponse = await supabase
          .from('profiles')
          .select('full_name, username, bio, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      final prefsResponse = await supabase
          .from('user_preferences')
          .select('home_base, age_group, selected_moods, budget_level, social_vibe, dietary_restrictions, activity_pace, time_available, interests')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _userName = profileResponse?['full_name'] as String?;
          _username = profileResponse?['username'] as String?;
          _bio = profileResponse?['bio'] as String?;
          _avatarUrl = profileResponse?['avatar_url'] as String?;
          
          // Load age_group from preferences
          _ageGroup = prefsResponse?['age_group'] as String?;
          
          // Load travel mode
          final homeBase = prefsResponse?['home_base'] as String?;
          _isLocalMode = homeBase == null ? true : (homeBase == 'Local Explorer');
          
          // Load selected moods
          _selectedVibes = prefsResponse?['selected_moods'] != null
              ? List<String>.from(prefsResponse!['selected_moods'] as List)
              : <String>[];
          
          // Load preferences
          _budgetLevel = prefsResponse?['budget_level'] as String?;
          
          // Handle social_vibe
          final socialVibeData = prefsResponse?['social_vibe'];
          if (socialVibeData is List && socialVibeData.isNotEmpty) {
            _socialVibe = socialVibeData.first.toString();
          } else if (socialVibeData is String && socialVibeData.isNotEmpty) {
            _socialVibe = socialVibeData;
          } else {
            _socialVibe = null;
          }
          
          _dietaryRestrictions = prefsResponse?['dietary_restrictions'] != null
              ? List<String>.from(prefsResponse!['dietary_restrictions'] as List)
              : <String>[];

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) setState(() => _isLoading = false);
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

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Upload to Supabase Storage
      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '$userId/avatar.$fileExt';
      
      await supabase.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(
            upsert: true,
            cacheControl: '3600',
          ));

      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // Update profile
      await supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);

      setState(() {
        _avatarUrl = imageUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: Color(0xFF5BB32A),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateTravelMode(bool isLocal) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('user_preferences').update({
        'home_base': isLocal ? 'Local Explorer' : 'Traveler',
      }).eq('user_id', userId);

      setState(() => _isLocalMode = isLocal);
    } catch (e) {
      debugPrint('Error updating travel mode: $e');
    }
  }

  void _handleVibesUpdated(List<String> updatedVibes) {
    setState(() {
      _selectedVibes = updatedVibes;
    });
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                // Header with profile picture, name, handle, settings
                _buildProfileHeader(),
                const SizedBox(height: 24),
                
                // Age group tag (if available)
                if (_ageGroup != null && _ageGroup!.isNotEmpty) ...[
                  _buildAgeGroupTag(),
                  const SizedBox(height: 12),
                ],
                
                // Bio (if available)
                if (_bio != null && _bio!.isNotEmpty) ...[
                  _buildBio(),
                  const SizedBox(height: 24),
                ],
                
                // Travel Mode Toggle
                TravelModeToggle(
                  isLocal: _isLocalMode,
                  onModeChanged: _updateTravelMode,
                ),
                const SizedBox(height: 24),
                
                // Stats Cards
                const ProfileStatsCards(),
                const SizedBox(height: 24),
                
                // Favorite Vibes
                FavoriteVibesCard(
                  selectedVibes: _selectedVibes,
                  onEditTap: () => _navigateToEditVibes(),
                ),
                const SizedBox(height: 24),
                
                // Mood Journey
                _buildMoodJourneyCard(),
                const SizedBox(height: 24),
                
                // Travel Globe
                _buildTravelGlobeCard(),
                const SizedBox(height: 24),
                
                // Preferences
                _buildPreferencesCard(),
                const SizedBox(height: 24),
                
                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Picture with edit button
        GestureDetector(
          onTap: _changeProfilePicture,
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF5BB32A), // Green border
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildAvatarPlaceholder(),
                        )
                      : _buildAvatarPlaceholder(),
                ),
              ),
              // Camera icon overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5BB32A),
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
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Name and Handle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName ?? 'User',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              if (_username != null) ...[
                const SizedBox(height: 4),
                Text(
                  '@$_username',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Settings Icon (only one)
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings,
              color: Colors.grey[700],
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    final initial = (_userName?.isNotEmpty == true 
        ? _userName!.substring(0, 1).toUpperCase()
        : (_username?.isNotEmpty == true 
            ? _username!.substring(0, 1).toUpperCase()
            : '?'));
    
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeGroupTag() {
    final formattedAge = _formatAgeGroup(_ageGroup);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5BB32A), // Green background
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

  Widget _buildBio() {
    return Text(
      _bio!,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: Colors.grey[700],
        height: 1.4,
      ),
    );
  }

  Widget _buildMoodJourneyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Mood Journey',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start checking in to see your mood history!',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelGlobeCard() {
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
                    'Your Travel Globe',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore your travel journey',
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

  Widget _buildPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Preferences',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await context.push('/preferences');
                  if (mounted) {
                    _loadUserData();
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 16, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 4),
                    Text(
                      'Edit All',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_ageGroup != null && _ageGroup!.isNotEmpty) ...[
            _buildPrefButton('Age Group', _formatAgeGroup(_ageGroup), const Color(0xFF4CAF50)),
            const SizedBox(height: 12),
          ],
          if (_budgetLevel != null && _budgetLevel!.isNotEmpty) ...[
            _buildPrefButton('Budget Style', _formatBudget(_budgetLevel), const Color(0xFFFFB74D)),
            const SizedBox(height: 12),
          ],
          if (_socialVibe != null && _socialVibe!.isNotEmpty) ...[
            _buildPrefButton('Social Vibe', _formatSocialVibe(_socialVibe), const Color(0xFFEF5350)),
            const SizedBox(height: 12),
          ],
          if (_dietaryRestrictions.isNotEmpty) ...[
            _buildPrefButton(
              'Food Preferences',
              _formatFoodPreferences(_dietaryRestrictions),
              const Color(0xFFF97316),
              endColor: const Color(0xFFEC4899),
            ),
            const SizedBox(height: 12),
          ],
          if ((_ageGroup == null || _ageGroup!.isEmpty) &&
              (_budgetLevel == null || _budgetLevel!.isEmpty) &&
              (_socialVibe == null || _socialVibe!.isEmpty) &&
              _dietaryRestrictions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Tap "Edit All" to set your preferences',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
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

  void _navigateToEditVibes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFavoriteVibesScreen(
          initialVibes: _selectedVibes,
          onSave: _handleVibesUpdated,
        ),
      ),
    );
    _loadUserData();
  }

  String _formatAgeGroup(String? ageGroup) {
    if (ageGroup == null || ageGroup.isEmpty) return '';
    
    // Format to "20s Adventurer" style
    if (ageGroup.contains('18-24') || ageGroup.contains('18') || ageGroup.contains('20')) {
      return '20s Adventurer';
    } else if (ageGroup.contains('25-34') || ageGroup.contains('25') || ageGroup.contains('30')) {
      return '30s Adventurer';
    } else if (ageGroup.contains('35-44') || ageGroup.contains('35') || ageGroup.contains('40')) {
      return '40s Adventurer';
    } else if (ageGroup.contains('45-54') || ageGroup.contains('45') || ageGroup.contains('50')) {
      return '50s Adventurer';
    } else if (ageGroup.contains('55+') || ageGroup.contains('55')) {
      return '55+ Adventurer';
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

  String _formatBudget(String? budget) {
    if (budget == null || budget.isEmpty) return '';
    
    final budgetLower = budget.toLowerCase();
    if (budgetLower.contains('low') || budgetLower.contains('budget') || budget == '\$') {
      return '\$ Budget';
    }
    if (budgetLower.contains('mid') || budgetLower.contains('moderate') || budget == '\$\$') {
      return '\$\$ Moderate';
    }
    if (budgetLower.contains('high') || budgetLower.contains('luxury') || budget == '\$\$\$' || budget == '\$\$\$\$') {
      return '\$\$\$ Luxury';
    }
    return budget;
  }

  String _formatSocialVibe(String? vibe) {
    if (vibe == null || vibe.isEmpty) return '';
    
    final vibeLower = vibe.toLowerCase();
    if (vibeLower == 'solo' || vibeLower == 'solo-friendly') return 'Solo';
    if (vibeLower == 'couple') return 'Couple';
    if (vibeLower == 'group' || vibeLower == 'small-group') return 'Group';
    if (vibeLower == 'mix' || vibeLower == 'mixed') return 'Mix';
    if (vibeLower == 'social' || vibeLower == 'social-scene') return 'Social';
    
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

  Widget _buildActionButtons() {
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
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              label: Text(
                'Edit',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/share-profile'),
              icon: const Icon(Icons.share, color: Colors.white, size: 20),
              label: Text(
                'Share',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
