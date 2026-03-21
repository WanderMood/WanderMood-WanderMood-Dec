import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/mood/application/mood_service.dart';
import 'package:wandermood/features/mood/domain/mood.dart';
import 'package:wandermood/features/mood/presentation/screens/mood_history_screen.dart';
import 'package:wandermood/features/mood/domain/models/mood_data.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/utils/moody_clock.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  String? _selectedMood;
  String? _selectedActivity;
  String _notes = '';
  double _energyLevel = 5.0;
  bool _isSaving = false;
  
  final List<String> _moods = [
    'Blij 😊',
    'Ontspannen 😌',
    'Energiek 🤩',
    'Avontuurlijk 🧗',
    'Romantisch 💕',
    'Nieuwsgierig 🧐',
    'Vermoeid 😴',
    'Gestrest 😓',
    'Verveeld 😑',
  ];
  
  final List<String> _activities = [
    'Natuur',
    'Eten',
    'Cultuur',
    'Shoppen',
    'Strand',
    'Stad',
    'Actief',
    'Ontspanning',
    'Uitgaan',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titel en Geschiedenis knop
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hoe voel je je vandaag?',
                  style: GoogleFonts.museoModerno(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A6049),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MoodHistoryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.history,
                    color: Color(0xFF2A6049),
                  ),
                  tooltip: 'Stemmingsgeschiedenis',
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
            
            const SizedBox(height: 8),
            
            Text(
              'Deel je stemming om gepersonaliseerde reis aanbevelingen te krijgen',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            
            const SizedBox(height: 24),
            
            // Mood Selection
            _buildSectionTitle('Kies je stemming:'),
            
            const SizedBox(height: 8),
            
            // Mood Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _moods.length,
              itemBuilder: (context, index) {
                final mood = _moods[index];
                final isSelected = mood == _selectedMood;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMood = mood;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2A6049).withOpacity(0.2) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2A6049) : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      mood,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF2A6049) : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
            
            const SizedBox(height: 24),
            
            // Energy Level Slider
            _buildSectionTitle('Energieniveau:'),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.battery_0_bar, color: Colors.grey),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _energyLevel,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: const Color(0xFF2A6049),
                      onChanged: (value) {
                        setState(() {
                          _energyLevel = value;
                        });
                      },
                    ),
                  ),
                ),
                const Icon(Icons.battery_full, color: Color(0xFF2A6049)),
              ],
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
            
            const SizedBox(height: 24),
            
            // Activity Interests
            _buildSectionTitle('Waar heb je interesse in?'),
            
            const SizedBox(height: 8),
            
            // Activities Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                final isSelected = activity == _selectedActivity;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedActivity = activity;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2A6049).withOpacity(0.2) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2A6049) : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      activity,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF2A6049) : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
            
            const SizedBox(height: 24),
            
            // Notes
            _buildSectionTitle('Extra notities:'),
            
            const SizedBox(height: 8),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText: 'Optioneel: Deel meer over wat je zoekt...',
                ),
                onChanged: (value) {
                  setState(() {
                    _notes = value;
                  });
                },
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
            
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveMood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A6049),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Opslaan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2A6049),
      ),
    );
  }
  
  Future<void> _saveMood() async {
    if (_selectedMood == null || _selectedActivity == null) {
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.selectMoodAndActivity,
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = ref.read(authStateProvider)?.id;
      if (userId == null) {
        throw Exception('Gebruiker niet ingelogd');
      }

      final mood = MoodData(
        id: MoodyClock.now().toIso8601String(),
        userId: userId,
        moodScore: _energyLevel,
        moodType: _selectedMood!,
        timestamp: MoodyClock.now(),
        description: _notes.isNotEmpty ? _notes : null,
        tags: _selectedActivity != null ? [_selectedActivity!] : [],
      );

      await ref.read(moodServiceProvider.notifier).saveMoodData(mood);

      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Stemming opgeslagen!',
          backgroundColor: Colors.green,
        );

        setState(() {
          _selectedMood = null;
          _selectedActivity = null;
          _notes = '';
          _energyLevel = 5.0;
        });
      }
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Fout bij opslaan: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
} 