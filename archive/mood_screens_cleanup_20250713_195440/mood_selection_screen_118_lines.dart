import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/mood_option.dart';
import '../../providers/mood_options_provider.dart';

class MoodSelectionScreen extends ConsumerStatefulWidget {
  const MoodSelectionScreen({super.key});

  @override
  ConsumerState<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends ConsumerState<MoodSelectionScreen> {
  String? _selectedMoodId;

  @override
  Widget build(BuildContext context) {
    final moodOptionsAsync = ref.watch(moodOptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('How are you feeling?'),
        centerTitle: true,
      ),
      body: moodOptionsAsync.when(
        data: (moods) => _buildMoodGrid(moods),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading moods: $error'),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildMoodGrid(List<MoodOption> moods) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: moods.length,
      itemBuilder: (context, index) {
        final mood = moods[index];
        final isSelected = mood.id == _selectedMoodId;

        return Card(
          elevation: isSelected ? 8 : 2,
          color: isSelected ? mood.color.withOpacity(0.3) : null,
          child: InkWell(
            onTap: () => setState(() => _selectedMoodId = mood.id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mood.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mood.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mood.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate(delay: Duration(milliseconds: index * 100))
         .fadeIn()
         .slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _selectedMoodId != null
              ? () => _onContinue()
              : null,
          child: const Text('Continue'),
        ),
      ),
    );
  }

  void _onContinue() {
    if (_selectedMoodId != null) {
      // Update the selected mood in the provider
      ref.read(selectedMoodOptionsProvider.notifier).state = {_selectedMoodId!};
      
      // Navigate to the next screen
      context.go('/home');
    }
  }
} 