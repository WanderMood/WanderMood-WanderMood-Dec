import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../application/mood_service.dart';
import '../../domain/models/mood_data.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/utils/moody_clock.dart';

class MoodInputCard extends ConsumerStatefulWidget {
  final Function(MoodData)? onMoodSaved;

  const MoodInputCard({
    super.key,
    this.onMoodSaved,
  });

  @override
  ConsumerState<MoodInputCard> createState() => _MoodInputCardState();
}

class _MoodInputCardState extends ConsumerState<MoodInputCard> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();
  
  double _selectedMoodScore = 5.0;
  String _selectedMoodType = 'happy';
  bool _isSubmitting = false;

  final List<String> _moodTypes = [
    'happy',
    'sad',
    'energetic',
    'tired',
    'anxious',
    'calm',
    'excited',
    'bored',
    'angry',
    'peaceful',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submitMood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final mood = MoodData(
        id: MoodyClock.now().millisecondsSinceEpoch.toString(),
        userId: Supabase.instance.client.auth.currentUser!.id,
        moodScore: _selectedMoodScore,
        moodType: _selectedMoodType,
        timestamp: MoodyClock.now(),
        description: _descriptionController.text,
        location: _locationController.text,
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
      );

      await ref.read(moodServiceProvider.notifier).saveMoodData(mood);
      
      if (widget.onMoodSaved != null) {
        widget.onMoodSaved!(mood);
      }

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _selectedMoodScore = 5.0;
        _selectedMoodType = 'happy';
      });

      showWanderMoodToast(
        context,
        message: 'Mood succesvol opgeslagen!',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      showWanderMoodToast(
        context,
        message: 'Fout bij het opslaan van mood: $e',
        isError: true,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hoe voel je je?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  10,
                  (index) => _buildMoodScoreButton((index + 1).toDouble()),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMoodType,
                decoration: const InputDecoration(
                  labelText: 'Type mood',
                  border: OutlineInputBorder(),
                ),
                items: _moodTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMoodType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschrijving (optioneel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Locatie (optioneel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (gescheiden door komma\'s)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMood,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Opslaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodScoreButton(double score) {
    final isSelected = score == _selectedMoodScore;
    return InkWell(
      onTap: () => setState(() => _selectedMoodScore = score),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            score.toStringAsFixed(0),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
} 