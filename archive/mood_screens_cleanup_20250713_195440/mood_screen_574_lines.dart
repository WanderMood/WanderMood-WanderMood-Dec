import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/mood/application/mood_service.dart';
import 'package:wandermood/features/mood/domain/mood.dart';
import 'package:wandermood/features/mood/presentation/screens/mood_history_screen.dart';
import 'package:wandermood/features/mood/domain/models/mood_data.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/features/weather/presentation/screens/weather_detail_screen.dart';

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
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                Row(
                  children: [
                    // Weather widget
                    GestureDetector(
                      onTap: () {
                        // First give visual feedback
                        Future.delayed(const Duration(milliseconds: 100), () {
                          // Show a centered dialog
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                height: MediaQuery.of(context).size.height * 0.75,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: const WeatherDetailScreen(isModal: true),
                                ),
                              ),
                            ),
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final locationData = ref.watch(locationNotifierProvider);
                            
                            return locationData.when(
                              data: (location) {
                                final weatherData = ref.watch(weatherProvider);
                                
                                return weatherData.when(
                                  data: (weather) {
                                    if (weather == null) {
                                      return Row(
                                        children: [
                                          const Icon(
                                            Icons.wb_sunny_rounded,
                                            color: Color(0xFFFFA000),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '--°',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    
                                    // Extract icon code from the iconUrl
                                    final iconCode = weather.iconUrl.split('/').last.replaceAll('@2x.png', '');
                                    
                                    return Row(
                                      children: [
                                        Image.network(
                                          weather.iconUrl,
                                          width: 24,
                                          height: 24,
                                          errorBuilder: (context, error, stackTrace) {
                                            // Select weather icon based on condition as fallback
                                            IconData weatherIcon;
                                            final condition = weather.condition.toLowerCase();
                                            if (condition.contains('cloud')) {
                                              weatherIcon = Icons.cloud;
                                            } else if (condition.contains('rain')) {
                                              weatherIcon = Icons.water_drop;
                                            } else if (condition.contains('snow')) {
                                              weatherIcon = Icons.ac_unit;
                                            } else if (condition.contains('storm') || condition.contains('thunder')) {
                                              weatherIcon = Icons.thunderstorm;
                                            } else {
                                              weatherIcon = Icons.wb_sunny_rounded;
                                            }
                                            
                                            return Icon(
                                              weatherIcon,
                                              color: weatherIcon == Icons.wb_sunny_rounded 
                                                ? const Color(0xFFFFA000) 
                                                : weatherIcon == Icons.cloud 
                                                  ? Colors.grey 
                                                  : Colors.blue,
                                              size: 20,
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${weather.temperature.round()}°',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                  loading: () => const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  error: (_, __) => Row(
                                    children: [
                                      const Icon(
                                        Icons.wb_sunny_rounded,
                                        color: Color(0xFFFFA000),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '--°',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                                  strokeWidth: 2,
                                ),
                              ),
                              error: (_, __) => Row(
                                children: [
                                  const Icon(
                                    Icons.wb_sunny_rounded,
                                    color: Color(0xFFFFA000),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '--°',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        color: Color(0xFF4CAF50),
                      ),
                      tooltip: 'Stemmingsgeschiedenis',
                    ),
                  ],
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
                      color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.2) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      mood,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
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
                      activeColor: const Color(0xFF4CAF50),
                      onChanged: (value) {
                        setState(() {
                          _energyLevel = value;
                        });
                      },
                    ),
                  ),
                ),
                const Icon(Icons.battery_full, color: Color(0xFF4CAF50)),
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
                      color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.2) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      activity,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
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
                  backgroundColor: const Color(0xFF4CAF50),
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
        color: Color(0xFF4CAF50),
      ),
    );
  }
  
  Future<void> _saveMood() async {
    if (_selectedMood == null || _selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecteer een stemming en activiteit'),
          backgroundColor: Colors.red,
        ),
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
        id: DateTime.now().toIso8601String(),
        userId: userId,
        moodScore: _energyLevel,
        moodType: _selectedMood!,
        timestamp: DateTime.now(),
        description: _notes.isNotEmpty ? _notes : null,
        tags: _selectedActivity != null ? [_selectedActivity!] : [],
      );

      await ref.read(moodServiceProvider.notifier).saveMoodData(mood);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stemming opgeslagen!'),
            backgroundColor: Colors.green,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij opslaan: $e'),
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
} 