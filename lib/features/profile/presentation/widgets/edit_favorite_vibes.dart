// lib/features/profile/presentation/widgets/edit_favorite_vibes.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

const Color _fvWmForest = Color(0xFF2A6049);
const Color _fvWmForestDeep = Color(0xFF1E4A3A);
const Color _fvWmSunset = Color(0xFFE8784A);
const Color _fvWmSunsetDeep = Color(0xFFC45A3A);
const Color _fvWmCream = Color(0xFFF5F0E8);
const Color _fvWmParchment = Color(0xFFE8E2D8);
const Color _fvWmWhite = Color(0xFFFFFFFF);
const Color _fvWmCharcoal = Color(0xFF1E1C18);
const Color _fvWmDusk = Color(0xFF4A4640);
const Color _fvWmStone = Color(0xFF8C8780);
const Color _fvWmForestTint = Color(0xFFEBF3EE);
const Color _fvWmSunsetTint = Color(0xFFFDF0E8);

/// Vibe data model
class VibeData {
  final String id;
  final String name;
  final String emoji;
  final List<Color> gradient;
  final String description;

  const VibeData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.gradient,
    required this.description,
  });
}

/// All available vibes
const List<VibeData> allVibes = [
  VibeData(
    id: 'adventurous',
    name: 'Adventurous',
    emoji: '🏔️',
    gradient: [Color(0xFFFB923C), Color(0xFFEF4444)],
    description: 'Thrilling activities & outdoor adventures',
  ),
  VibeData(
    id: 'chill',
    name: 'Chill',
    emoji: '😌',
    gradient: [Color(0xFF60A5FA), Color(0xFF06B6D4)],
    description: 'Relaxed, laid-back experiences',
  ),
  VibeData(
    id: 'foodie',
    name: 'Foodie',
    emoji: '🍽️',
    gradient: [Color(0xFFF87171), Color(0xFFEC4899)],
    description: 'Culinary experiences & dining',
  ),
  VibeData(
    id: 'social',
    name: 'Social',
    emoji: '🎉',
    gradient: [Color(0xFFF472B6), Color(0xFFFB7185)],
    description: 'Meeting people & social events',
  ),
  VibeData(
    id: 'cultural',
    name: 'Cultural',
    emoji: '🏛️',
    gradient: [Color(0xFFA78BFA), Color(0xFF6366F1)],
    description: 'Museums, art & history',
  ),
  VibeData(
    id: 'nature',
    name: 'Nature',
    emoji: '🌿',
    gradient: [Color(0xFF4ADE80), Color(0xFF14B8A6)],
    description: 'Parks, gardens & outdoors',
  ),
  VibeData(
    id: 'romantic',
    name: 'Romantic',
    emoji: '💕',
    gradient: [Color(0xFFEC4899), Color(0xFFEF4444)],
    description: 'Date nights & romantic spots',
  ),
  VibeData(
    id: 'wellness',
    name: 'Wellness',
    emoji: '🧘',
    gradient: [Color(0xFF2DD4BF), Color(0xFF06B6D4)],
    description: 'Spas, yoga & self-care',
  ),
  VibeData(
    id: 'nightlife',
    name: 'Nightlife',
    emoji: '🌃',
    gradient: [Color(0xFF6366F1), Color(0xFF9333EA)],
    description: 'Bars, clubs & evening fun',
  ),
  VibeData(
    id: 'shopping',
    name: 'Shopping',
    emoji: '🛍️',
    gradient: [_fvWmSunset, _fvWmSunsetDeep],
    description: 'Markets, boutiques & malls',
  ),
  VibeData(
    id: 'creative',
    name: 'Creative',
    emoji: '🎨',
    gradient: [Color(0xFFA78BFA), Color(0xFFEC4899)],
    description: 'Art studios & creative spaces',
  ),
  VibeData(
    id: 'sporty',
    name: 'Sporty',
    emoji: '⚽',
    gradient: [Color(0xFF3B82F6), Color(0xFF22C55E)],
    description: 'Sports & fitness activities',
  ),
];

String _normalizeVibeToken(String input) {
  return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

VibeData? _resolveVibe(String raw) {
  final key = _normalizeVibeToken(raw);
  if (key.isEmpty) return null;

  for (final vibe in allVibes) {
    final byName = _normalizeVibeToken(vibe.name);
    final byId = _normalizeVibeToken(vibe.id);
    if (key == byName || key == byId || key.contains(byName) || key.contains(byId)) {
      return vibe;
    }
  }
  return null;
}

/// Favorite Vibes Card for Profile Screen
class FavoriteVibesCard extends StatelessWidget {
  final List<String> selectedVibes;
  final VoidCallback onEditTap;

  const FavoriteVibesCard({
    Key? key,
    required this.selectedVibes,
    required this.onEditTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const wmWhite = Color(0xFFFFFFFF);
    const wmParchment = Color(0xFFE8E2D8);
    const wmCharcoal = Color(0xFF1E1C18);
    const wmForest = Color(0xFF2A6049);
    const wmForestTint = Color(0xFFEBF3EE);
    const wmStone = Color(0xFF8C8780);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: wmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: wmParchment, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.profileFavoriteVibesTitle,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: wmCharcoal,
                ),
              ),
              GestureDetector(
                onTap: onEditTap,
                child: Row(
                  children: [
                    Text(
                      l10n.profileFavoriteVibesEdit,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: wmForest,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right,
                      color: wmForest,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...selectedVibes
                  .map(_resolveVibe)
                  .whereType<VibeData>()
                  .fold<List<VibeData>>([], (acc, vibe) {
                    if (!acc.any((v) => v.id == vibe.id)) acc.add(vibe);
                    return acc;
                  })
                  .map((vibeData) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: wmForestTint,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: wmParchment, width: 0.5),
                  ),
                  child: Text(
                    '${vibeData.emoji} ${vibeData.name}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: wmForest,
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: onEditTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Text(
                    l10n.profileFavoriteVibesAdd,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: wmStone,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Edit Favorite Vibes Screen
class EditFavoriteVibesScreen extends StatefulWidget {
  final List<String> initialVibes;
  final Function(List<String>) onSave;

  const EditFavoriteVibesScreen({
    Key? key,
    required this.initialVibes,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditFavoriteVibesScreen> createState() => _EditFavoriteVibesScreenState();
}

class _EditFavoriteVibesScreenState extends State<EditFavoriteVibesScreen> {
  late List<String> _selectedVibes;
  late List<String> _originalVibes;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedVibes = _normalizeVibes(widget.initialVibes);
    _originalVibes = List.from(_selectedVibes);
  }

  List<String> _normalizeVibes(List<String> vibes) {
    final unique = <String>{};
    final normalized = <String>[];
    for (final raw in vibes) {
      final resolved = _resolveVibe(raw);
      if (resolved == null) continue;
      final canonical = resolved.name;
      final key = canonical.toLowerCase();
      if (unique.contains(key)) continue;
      unique.add(key);
      normalized.add(canonical);
      if (normalized.length == 5) break;
    }
    return normalized;
  }

  void _toggleVibe(String vibeName) {
    setState(() {
      if (_selectedVibes.contains(vibeName)) {
        _selectedVibes.removeWhere(
          (v) => v.trim().toLowerCase() == vibeName.trim().toLowerCase(),
        );
      } else {
        if (_selectedVibes.length < 5) {
          _selectedVibes.add(vibeName);
        }
      }
      _selectedVibes = _normalizeVibes(_selectedVibes);
      _hasChanges = !_listEquals(_selectedVibes, _originalVibes);
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!b.contains(a[i])) return false;
    }
    return true;
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _selectedVibes.isEmpty) return;

    setState(() => _isSaving = true);
    final cleanedVibes = _normalizeVibes(_selectedVibes);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Update profiles table
        await Supabase.instance.client
            .from('profiles')
            .update({
              'travel_vibes': cleanedVibes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);

        // Also update user_preferences for consistency (profile screen reads from here)
        await Supabase.instance.client
            .from('user_preferences')
            .upsert({
              'user_id': user.id,
              'selected_moods': cleanedVibes,
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id');
      }

      widget.onSave(cleanedVibes);
      
      // Wait a moment for the database to update
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        Navigator.pop(context);
        final l10n = AppLocalizations.of(context)!;
        showWanderMoodToast(context, message: l10n.profileVibesUpdated);
      }
    } catch (e) {
      debugPrint('Error saving vibes: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showWanderMoodToast(
          context,
          message: l10n.profileVibesSaveFailed(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancelChanges() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _fvWmCream,
      body: Column(
        children: [
          // Header
          Container(
            color: _fvWmCream,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 16,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: _fvWmDusk),
                    onPressed: _cancelChanges,
                  ),
                  Expanded(
                    child: Text(
                      l10n.profileVibesEditTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _fvWmCharcoal,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: _hasChanges && _selectedVibes.isNotEmpty ? _saveChanges : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Container(
                        decoration: _hasChanges && _selectedVibes.isNotEmpty
                            ? BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_fvWmForest, _fvWmForestDeep],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              )
                            : BoxDecoration(
                              color: _fvWmParchment,
                                borderRadius: BorderRadius.circular(20),
                              ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          l10n.profileVibesSave,
                          style: GoogleFonts.poppins(
                            color: _hasChanges && _selectedVibes.isNotEmpty
                                ? Colors.white
                              : _fvWmStone,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: _fvWmParchment),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  _buildInfoCard(context),
                  const SizedBox(height: 24),
                  
                  // Selected Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.profileVibesSelectedCount(_selectedVibes.length.toString()),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _fvWmCharcoal,
                        ),
                      ),
                      if (_selectedVibes.length == 5)
                        Text(
                          l10n.profileVibesMaxReached,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _fvWmSunset,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Current Vibes (removable)
                  if (_selectedVibes.isNotEmpty) ...[
                    _buildCurrentVibes(context),
                    const SizedBox(height: 24),
                  ],
                  
                  // Available Vibes Grid
                  Text(
                    _selectedVibes.isEmpty ? l10n.profileVibesChooseTitle : l10n.profileVibesAddMore,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _fvWmStone,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAvailableVibesGrid(),
                  const SizedBox(height: 24),
                  
                  // Tips Section
                  _buildTipsCard(),
                  const SizedBox(height: 32), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_fvWmForestTint, _fvWmSunsetTint],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _fvWmParchment, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _fvWmSunsetTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, color: _fvWmSunset, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileVibesChooseTitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: _fvWmCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.profileVibesSubtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _fvWmStone,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentVibes(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _fvWmWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _fvWmParchment, width: 0.5),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.profileVibesCurrentTitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _fvWmStone,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _selectedVibes.map((vibeName) {
              final vibe = _resolveVibe(vibeName);
              if (vibe == null) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => _toggleVibe(vibe.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _fvWmForestTint,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _fvWmParchment, width: 0.5),
                    boxShadow: const [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vibe.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        vibe.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: _fvWmForest,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.delete_outline, color: _fvWmSunset, size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableVibesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: allVibes.length,
      itemBuilder: (context, index) {
        final vibe = allVibes[index];
        final isSelected = _selectedVibes.any(
          (v) => v.toLowerCase() == vibe.name.toLowerCase(),
        );
        final isMaxed = _selectedVibes.length >= 5 && !isSelected;
        
        return GestureDetector(
          onTap: isMaxed ? null : () => _toggleVibe(vibe.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? _fvWmForestTint
                  : (isMaxed ? _fvWmCream : _fvWmWhite),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? _fvWmForest : _fvWmParchment,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _fvWmForest.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji with bounce animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, -10 * value),
                          child: Text(
                            vibe.emoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vibe.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? _fvWmForest : _fvWmCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        vibe.description,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isSelected
                              ? _fvWmDusk
                              : _fvWmStone,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Selection indicator
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _fvWmWhite,
                        shape: BoxShape.circle,
                        boxShadow: const [],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: _fvWmForest,
                        size: 20,
                      ),
                    ),
                  ),
                // Add icon (for hover effect on web)
                if (!isSelected && !isMaxed)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Opacity(
                      opacity: 0.0, // Hidden on mobile, can be shown on hover for web
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                        color: _fvWmCream,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: _fvWmSunset,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_fvWmCream, _fvWmForestTint],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _fvWmParchment, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: _fvWmSunset,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Pro Tips',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: _fvWmCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Be honest about what you enjoy - better recommendations!\n'
                  '• You can change these anytime\n'
                  '• Mix different vibes for varied suggestions',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _fvWmStone,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
