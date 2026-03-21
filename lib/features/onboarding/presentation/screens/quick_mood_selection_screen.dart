import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Quick Mood Selection Screen
/// 
/// Simplified, faster version of mood selection for quick onboarding
class QuickMoodSelectionScreen extends ConsumerStatefulWidget {
  const QuickMoodSelectionScreen({super.key});

  @override
  ConsumerState<QuickMoodSelectionScreen> createState() => _QuickMoodSelectionScreenState();
}

class _QuickMoodSelectionScreenState extends ConsumerState<QuickMoodSelectionScreen> {
  final Set<String> _selectedMoods = {};
  static const int maxMoodSelections = 5; // Allow more selections for quick flow

  final List<Map<String, dynamic>> _moods = [
    {
      'name': 'Adventurous',
      'key': 'adventurous',
      'emoji': '🏃‍♂️',
      'color': const Color(0xFF7CB342),
    },
    {
      'name': 'Peaceful',
      'key': 'peaceful',
      'emoji': '🧘‍♀️',
      'color': const Color(0xFF64B5F6),
    },
    {
      'name': 'Social',
      'key': 'social',
      'emoji': '🎉',
      'color': const Color(0xFFFFB74D),
    },
    {
      'name': 'Cultural',
      'key': 'cultural',
      'emoji': '🎭',
      'color': const Color(0xFFEC407A),
    },
    {
      'name': 'Foody',
      'key': 'foody',
      'emoji': '🍽️',
      'color': const Color(0xFF98D95A),
    },
    {
      'name': 'Spontaneous',
      'key': 'spontaneous',
      'emoji': '✨',
      'color': const Color(0xFF70D7FF),
    },
  ];

  void _toggleMoodSelection(String moodName) {
    setState(() {
      if (_selectedMoods.contains(moodName)) {
        _selectedMoods.remove(moodName);
      } else {
        if (_selectedMoods.length < maxMoodSelections) {
          _selectedMoods.add(moodName);
        }
      }
    });
    
    // Update provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(preferencesProvider.notifier).updateSelectedMoods(_selectedMoods.toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "What's your travel mood? 😊",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A6049),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "What inspires you to get out and explore?",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: _moods.length,
                    itemBuilder: (context, index) {
                      final mood = _moods[index];
                      final isSelected = _selectedMoods.contains(mood['name']);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMoodCard(mood, isSelected),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedMoods.isNotEmpty
                        ? () => context.go('/onboarding/quick-interests')
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMoods.isNotEmpty
                          ? const Color(0xFF2A6049)
                          : Colors.grey.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      l10n.continueButton,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Select at least 1 mood to continue ✨",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodCard(Map<String, dynamic> mood, bool isSelected) {
    final baseColor = mood['color'] as Color;
    
    return GestureDetector(
      onTap: () => _toggleMoodSelection(mood['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? baseColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? baseColor : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? baseColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : baseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    mood['emoji'],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  mood['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: baseColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
