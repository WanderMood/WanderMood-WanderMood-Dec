import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class MoodSelectionWidget extends StatefulWidget {
  final Function(List<String>) onMoodsSelected;
  final int maxSelections;

  const MoodSelectionWidget({
    super.key, 
    required this.onMoodsSelected,
    this.maxSelections = 3,
  });

  @override
  State<MoodSelectionWidget> createState() => _MoodSelectionWidgetState();
}

class _MoodSelectionWidgetState extends State<MoodSelectionWidget> {
  // List of moods with their icons and colors
  final List<Mood> moods = [
    Mood(icon: Icons.landscape, label: 'Adventurous', color: Colors.blue.shade100),
    Mood(icon: Icons.self_improvement, label: 'Relaxed', color: Colors.purple.shade100),
    Mood(icon: Icons.favorite, label: 'Romantic', color: Colors.pink.shade100),
    Mood(icon: Icons.public, label: 'Energetic', color: Colors.yellow.shade100),
    Mood(icon: Icons.celebration, label: 'Excited', color: Colors.green.shade100),
    Mood(icon: Icons.coffee, label: 'Cozy', color: Colors.brown.shade100),
    Mood(icon: Icons.emoji_emotions, label: 'Surprised', color: Colors.teal.shade100),
    Mood(icon: Icons.restaurant, label: 'Hungry', color: Colors.orange.shade100),
    Mood(icon: Icons.festival, label: 'Festive', color: Colors.red.shade100),
    Mood(icon: Icons.psychology, label: 'Curious', color: Colors.indigo.shade100),
    Mood(icon: Icons.family_restroom, label: 'Family', color: Colors.lime.shade100),
    Mood(icon: Icons.language, label: 'Cultural', color: Colors.cyan.shade100),
  ];

  Set<String> _selectedMoods = {};

  void _toggleMood(String mood) {
    setState(() {
      if (_selectedMoods.contains(mood)) {
        _selectedMoods.remove(mood);
      } else {
        // Limit to maximum number of selections
        if (_selectedMoods.length < widget.maxSelections) {
          _selectedMoods.add(mood);
        } else {
          // Show notification about the limit
          showWanderMoodToast(
            context,
            message: 'You can select up to ${widget.maxSelections} moods',
            backgroundColor: const Color(0xFF2A6049),
          );
        }
      }
    });
    
    // Move callback outside setState to avoid rebuilding while updating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onMoodsSelected(_selectedMoods.toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'How are you feeling today?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A6049),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: moods.length,
          itemBuilder: (context, index) {
            final mood = moods[index];
            final isSelected = _selectedMoods.contains(mood.label);
            
            return GestureDetector(
              onTap: () => _toggleMood(mood.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? mood.color.withOpacity(0.7) 
                    : mood.color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected 
                    ? Border.all(color: mood.color.withOpacity(0.8), width: 2)
                    : null,
                  boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: mood.color.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ]
                    : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mood.icon,
                      color: isSelected ? Colors.white : Colors.black54,
                      size: 30,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mood.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (100 * index).ms, duration: 300.ms),
            );
          },
        ),
        if (_selectedMoods.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected moods:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A6049),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _selectedMoods.map((mood) => Chip(
                    label: Text(
                      mood,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF2A6049),
                    deleteIconColor: Colors.white,
                    onDeleted: () => _toggleMood(mood),
                  )).toList(),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),
          ),
      ],
    );
  }
}

class Mood {
  final IconData icon;
  final String label;
  final Color color;

  Mood({
    required this.icon,
    required this.label,
    required this.color,
  });
} 