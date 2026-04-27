// lib/features/profile/presentation/widgets/edit_favorite_vibes.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/domain/enums/moody_feature.dart';

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

List<BoxShadow> _favoriteVibesShadow() {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

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

/// Localized display name (DB still stores English [VibeData.name]).
String localizedVibeName(AppLocalizations l10n, String id) {
  switch (id) {
    case 'adventurous':
      return l10n.profileVibeAdventurousName;
    case 'chill':
      return l10n.profileVibeChillName;
    case 'foodie':
      return l10n.profileVibeFoodieName;
    case 'social':
      return l10n.profileVibeSocialName;
    case 'cultural':
      return l10n.profileVibeCulturalName;
    case 'nature':
      return l10n.profileVibeNatureName;
    case 'romantic':
      return l10n.profileVibeRomanticName;
    case 'wellness':
      return l10n.profileVibeWellnessName;
    case 'nightlife':
      return l10n.profileVibeNightlifeName;
    case 'shopping':
      return l10n.profileVibeShoppingName;
    case 'creative':
      return l10n.profileVibeCreativeName;
    case 'sporty':
      return l10n.profileVibeSportyName;
    default:
      return id;
  }
}

String localizedVibeDescription(AppLocalizations l10n, String id) {
  switch (id) {
    case 'adventurous':
      return l10n.profileVibeAdventurousDesc;
    case 'chill':
      return l10n.profileVibeChillDesc;
    case 'foodie':
      return l10n.profileVibeFoodieDesc;
    case 'social':
      return l10n.profileVibeSocialDesc;
    case 'cultural':
      return l10n.profileVibeCulturalDesc;
    case 'nature':
      return l10n.profileVibeNatureDesc;
    case 'romantic':
      return l10n.profileVibeRomanticDesc;
    case 'wellness':
      return l10n.profileVibeWellnessDesc;
    case 'nightlife':
      return l10n.profileVibeNightlifeDesc;
    case 'shopping':
      return l10n.profileVibeShoppingDesc;
    case 'creative':
      return l10n.profileVibeCreativeDesc;
    case 'sporty':
      return l10n.profileVibeSportyDesc;
    default:
      return '';
  }
}

/// English stored value from profile → localized chip title.
String localizedVibeLabelForStored(AppLocalizations l10n, String storedEnglish) {
  final v = _resolveVibe(storedEnglish);
  if (v == null) return storedEnglish;
  return localizedVibeName(l10n, v.id);
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
    final resolvedVibes = selectedVibes
        .map(_resolveVibe)
        .whereType<VibeData>()
        .fold<List<VibeData>>([], (acc, vibe) {
      if (!acc.any((v) => v.id == vibe.id)) acc.add(vibe);
      return acc;
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: wmWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: wmParchment, width: 1),
        boxShadow: _favoriteVibesShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileFavoriteVibesTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: wmCharcoal,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.profileFavoriteVibesSubtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8C8780),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onEditTap,
                style: TextButton.styleFrom(
                  foregroundColor: wmForest,
                  backgroundColor: wmForestTint,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  l10n.profileFavoriteVibesEdit,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (resolvedVibes.isEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEditTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: wmForest,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: wmForest.withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.profileFavoriteVibesEmptyHint,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...resolvedVibes.map((vibeData) {
                  final accent = vibeData.gradient.first;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.28),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              vibeData.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          localizedVibeName(l10n, vibeData.id),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: wmCharcoal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                InkWell(
                  onTap: onEditTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: wmForestTint,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: wmParchment, width: 1),
                    ),
                    child: Text(
                      l10n.profileFavoriteVibesAdd,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: wmForest,
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _fvWmCharcoal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            const Divider(height: 1, color: _fvWmParchment),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(context),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.profileVibesSelectedCount(_selectedVibes.length.toString()),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _fvWmCharcoal,
                          ),
                        ),
                        if (_selectedVibes.length == 5)
                          Text(
                            l10n.profileVibesMaxReached,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _fvWmSunset,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAvailableVibesGrid(),
                    const SizedBox(height: 84),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: _hasChanges && _selectedVibes.isNotEmpty && !_isSaving
              ? _saveChanges
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: _fvWmForest,
            disabledBackgroundColor: _fvWmParchment,
            foregroundColor: Colors.white,
            disabledForegroundColor: _fvWmStone,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  l10n.profileVibesSave,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
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
          const SizedBox(
            width: 42,
            height: 42,
            child: MoodyCharacter(
              size: 42,
              mood: 'happy',
              currentFeature: MoodyFeature.none,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileVibesChooseTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _fvWmCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.profileVibesSubtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _fvWmStone,
                    height: 1.35,
                  ),
                ),
              ],
            ),
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.22,
      ),
      itemCount: allVibes.length,
      itemBuilder: (context, index) {
        final vibe = allVibes[index];
        final l10nGrid = AppLocalizations.of(context)!;
        final isSelected = _selectedVibes.any(
          (v) => v.toLowerCase() == vibe.name.toLowerCase(),
        );
        final isMaxed = _selectedVibes.length >= 5 && !isSelected;
        
        return GestureDetector(
          onTap: isMaxed ? null : () => _toggleVibe(vibe.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _fvWmForest
                  : (isMaxed ? _fvWmCream : _fvWmWhite),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? _fvWmForest : _fvWmParchment,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _fvWmForest.withValues(alpha: 0.22),
                        blurRadius: 10,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vibe.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  localizedVibeName(l10nGrid, vibe.id),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : _fvWmCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    localizedVibeDescription(l10nGrid, vibe.id),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.88)
                          : _fvWmStone,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
