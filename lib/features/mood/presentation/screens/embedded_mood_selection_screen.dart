import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/domain/enums/moody_feature.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_loading_screen.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_result_screen.dart';

/// Embedded version of the standalone mood selection screen
/// Uses the exact same logic and navigation flow that works in standalone
/// but optimized for use within the bottom navigation bar context
class EmbeddedMoodSelectionScreen extends ConsumerStatefulWidget {
  const EmbeddedMoodSelectionScreen({super.key});

  @override
  ConsumerState<EmbeddedMoodSelectionScreen> createState() => _EmbeddedMoodSelectionScreenState();
}

class _EmbeddedMoodSelectionScreenState extends ConsumerState<EmbeddedMoodSelectionScreen> {
  final Set<String> _selectedMoods = {};
  
  // EXACT same moods as standalone - this is what works!
  final List<MoodOption> _moods = [
    MoodOption(
      emoji: '⛰️',
      label: 'Adventurous',
      color: const Color(0xFFFFCC80),
    ),
    MoodOption(
      emoji: '😴',
      label: 'Relaxed',
      color: const Color(0xFFB3E5FC),
    ),
    MoodOption(
      emoji: '❤️',
      label: 'Romantic',
      color: const Color(0xFFF8BBD0),
    ),
    MoodOption(
      emoji: '⚡',
      label: 'Energetic',
      color: const Color(0xFFFFE082),
    ),
    MoodOption(
      emoji: '🎉',
      label: 'Excited',
      color: const Color(0xFFE1BEE7),
    ),
    MoodOption(
      emoji: '🍔',
      label: 'Surprise',
      color: const Color(0xFF80DEEA),
    ),
    MoodOption(
      emoji: '🎈',
      label: 'Foody',
      color: const Color(0xFFFFAB91),
    ),
    MoodOption(
      emoji: '🎈',
      label: 'Festive',
      color: const Color(0xFFA5D6A7),
    ),
    MoodOption(
      emoji: '🌱',
      label: 'Mindful',
      color: const Color(0xFF81C784),
    ),
    MoodOption(
      emoji: '👨‍👩‍👦',
      label: 'Family fun',
      color: const Color(0xFF9FA8DA),
    ),
    MoodOption(
      emoji: '💡',
      label: 'Creative',
      color: const Color(0xFFFFF59D),
    ),
    MoodOption(
      emoji: '💎',
      label: 'Luxurious',
      color: const Color(0xFFB39DDB),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Same design as standalone but adapted for embedded context
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDF5),  // Warm cream
            Color(0xFFFFF3E0),  // Warm yellow
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with location and weather
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF12B347),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'W',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.location_pin,
                    color: Color(0xFF12B347),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Rotterdam',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.wb_sunny,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '20°',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Greeting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _getTimeBasedGreeting(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // How are you feeling section with character
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'How are you feeling today?',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: MoodyCharacter(
                      size: 100,
                      mood: 'happy',
                      currentFeature: MoodyFeature.none,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selected moods
            if (_selectedMoods.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Selected moods: ${_selectedMoods.join(", ")}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF12B347),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Talk to me or select moods for your daily plan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Mood Grid - Adjusted height for embedded context (less space due to bottom nav)
            SizedBox(
              height: 280, // Reduced from 345 to fit with bottom nav
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _moods.length,
                itemBuilder: (context, index) {
                  final mood = _moods[index];
                  final isSelected = _selectedMoods.contains(mood.label);
                  return _buildMoodCard(mood, isSelected, index);
                },
              ),
            ),
            
            const SizedBox(height: 8), // Reduced spacing for embedded
            
            // CTA Button - Same as standalone
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: ElevatedButton(
                onPressed: _selectedMoods.isNotEmpty
                    ? () => _generatePlan()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12B347),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Let's create your perfect plan! 🎯",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCard(MoodOption mood, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMoods.remove(mood.label);
          } else {
            _selectedMoods.add(mood.label);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: mood.color,
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
              ? Border.all(color: const Color(0xFF12B347), width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: mood.color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mood.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              mood.label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning WanderMood 👋';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon WanderMood 👋';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening WanderMood 👋';
    } else {
      return 'Hi night owl WanderMood 🌙';
    }
  }

  // EXACT same navigation logic as standalone - this is what works!
  void _generatePlan() {
    if (_selectedMoods.isNotEmpty) {
      print('🎯 EMBEDDED: Generating plan for moods: $_selectedMoods');
      
      // Use the EXACT same navigation pattern as standalone
      if (context.mounted) {
        print('🧭 EMBEDDED: Navigating to plan loading screen');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanLoadingScreen(
              selectedMoods: _selectedMoods.toList(),
              onLoadingComplete: () {
                print('✅ EMBEDDED: Plan loading complete, navigating to result screen');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlanResultScreen(
                      selectedMoods: _selectedMoods.toList(),
                      moodString: _selectedMoods.join(" & "),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }
}

// Same MoodOption class as standalone
class MoodOption {
  final String emoji;
  final String label;
  final Color color;

  MoodOption({
    required this.emoji,
    required this.label,
    required this.color,
  });
} 