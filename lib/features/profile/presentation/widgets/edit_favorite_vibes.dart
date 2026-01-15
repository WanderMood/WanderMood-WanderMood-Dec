// lib/features/profile/presentation/widgets/edit_favorite_vibes.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    gradient: [Color(0xFFFBBF24), Color(0xFFF97316)],
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
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Favorite Vibes',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              GestureDetector(
                onTap: onEditTap,
                child: Row(
                  children: [
                    Text(
                      'Edit',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF97316),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFF97316),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...selectedVibes.map((vibeName) {
                final vibeData = allVibes.firstWhere(
                  (v) => v.name.toLowerCase() == vibeName.toLowerCase(),
                  orElse: () => allVibes.first,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: vibeData.gradient),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: vibeData.gradient[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${vibeData.emoji} ${vibeData.name}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '+ Add Vibe',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
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
    _selectedVibes = List.from(widget.initialVibes);
    _originalVibes = List.from(widget.initialVibes);
  }

  void _toggleVibe(String vibeName) {
    setState(() {
      if (_selectedVibes.contains(vibeName)) {
        _selectedVibes.remove(vibeName);
      } else {
        if (_selectedVibes.length < 5) {
          _selectedVibes.add(vibeName);
        }
      }
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

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Update profiles table
        await Supabase.instance.client
            .from('profiles')
            .update({
              'travel_vibes': _selectedVibes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);

        // Also update user_preferences for consistency (profile screen reads from here)
        await Supabase.instance.client
            .from('user_preferences')
            .upsert({
              'user_id': user.id,
              'selected_moods': _selectedVibes,
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id');
      }

      widget.onSave(_selectedVibes);
      
      // Wait a moment for the database to update
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vibes updated! 🎉',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFF97316),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving vibes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save vibes: $e'),
            backgroundColor: Colors.red,
          ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 16,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF374151)),
                    onPressed: _cancelChanges,
                  ),
                  Expanded(
                    child: Text(
                      'Edit Favorite Vibes',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
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
                                  colors: [Color(0xFFF97316), Color(0xFFEC4899)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              )
                            : BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            color: _hasChanges && _selectedVibes.isNotEmpty
                                ? Colors.white
                                : Colors.grey[400],
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
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  
                  // Selected Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected (${_selectedVibes.length}/5)',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (_selectedVibes.length == 5)
                        Text(
                          'Maximum reached',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF97316),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Current Vibes (removable)
                  if (_selectedVibes.isNotEmpty) ...[
                    _buildCurrentVibes(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Available Vibes Grid
                  Text(
                    _selectedVibes.isEmpty ? 'Choose Your Vibes' : 'Add More Vibes',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDBEAFE), Color(0xFFE9D5FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF93C5FD), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Vibes',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select up to 5 vibes that match your personality. We\'ll use these to personalize your recommendations!',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
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

  Widget _buildCurrentVibes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Text(
            'YOUR CURRENT VIBES',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _selectedVibes.map((vibeName) {
              final vibe = allVibes.firstWhere(
                (v) => v.name.toLowerCase() == vibeName.toLowerCase(),
                orElse: () => allVibes.first,
              );
              return GestureDetector(
                onTap: () => _toggleVibe(vibe.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: vibe.gradient),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: vibe.gradient[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.delete_outline, color: Colors.white, size: 18),
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
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: vibe.gradient,
                    )
                  : null,
              color: isSelected ? null : (isMaxed ? Colors.grey[100] : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFF97316)
                    : (isMaxed ? Colors.grey[200]! : Colors.grey[200]!),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: vibe.gradient[0].withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                        color: isSelected ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        vibe.description,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[600],
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF10B981),
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
                          color: const Color(0xFFFFF7ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFFF97316),
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
          colors: [Color(0xFFFFF7ED), Color(0xFFFCE7F3)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF97316),
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
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Be honest about what you enjoy - better recommendations!\n'
                  '• You can change these anytime\n'
                  '• Mix different vibes for varied suggestions',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
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
