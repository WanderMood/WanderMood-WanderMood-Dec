import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/home/presentation/widgets/compact_weather_widget.dart';
import 'package:wandermood/features/home/presentation/widgets/hourly_weather_widget.dart';
import 'package:wandermood/features/home/presentation/widgets/interactive_weather_widget.dart';
import 'package:wandermood/features/explore/presentation/widgets/mood_selection_widget.dart';
import 'package:wandermood/features/mood/presentation/screens/mood_screen.dart';
import 'package:wandermood/features/profile/presentation/screens/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  bool _isWeatherExpanded = false;
  final Set<String> _selectedMoods = {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFAFF4), Color(0xFFFFF5AF)],
            ),
          ),
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFF12B347),
                          child: Icon(Icons.person, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Color(0xFF12B347), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Washington DC',
                              style: GoogleFonts.openSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF12B347),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.wb_sunny, color: Color(0xFF12B347), size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '32°',
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF12B347),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.notifications_none, color: Color(0xFF12B347), size: 24),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        
                        // Greeting
                        Text(
                          'Hello, John!',
                          style: GoogleFonts.openSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12B347),
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                        const SizedBox(height: 24),

                        // Weather Widget
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isWeatherExpanded = !_isWeatherExpanded;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFB8F2FC),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
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
                                      'Washington DC',
                                      style: GoogleFonts.openSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A4A24),
                                      ),
                                    ),
                                    Icon(
                                      Icons.wb_sunny,
                                      color: Color(0xFFF9C21B),
                                      size: 24,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      _buildWeatherHourItem('Nu', '29°', true),
                                      _buildWeatherHourItem('15:00', '28°', true),
                                      _buildWeatherHourItem('16:00', '28°', true),
                                      _buildWeatherHourItem('17:00', '27°', true),
                                      _buildWeatherHourItem('18:00', '26°', true),
                                      _buildWeatherHourItem('19:00', '26°', true),
                                      _buildWeatherHourItem('20:00', '25°', true),
                                      _buildWeatherHourItem('21:00', '25°', true),
                                      _buildWeatherHourItem('22:00', '26°', true),
                                      _buildWeatherHourItem('23:00', '27°', true),
                                      _buildWeatherHourItem('00:00', '28°', true),
                                      _buildWeatherHourItem('01:00', '29°', true),
                                      _buildWeatherHourItem('02:00', '30°', true),
                                      _buildWeatherHourItem('03:00', '31°', true),
                                      _buildWeatherHourItem('04:00', '31°', true),
                                      _buildWeatherHourItem('05:00', '32°', true),
                                      _buildWeatherHourItem('06:00', '32°', true),
                                      _buildWeatherHourItem('07:00', '31°', true),
                                      _buildWeatherHourItem('08:00', '30°', true),
                                      _buildWeatherHourItem('09:00', '29°', true),
                                      _buildWeatherHourItem('10:00', '28°', true),
                                      _buildWeatherHourItem('11:00', '27°', true),
                                      _buildWeatherHourItem('12:00', '26°', true),
                                      _buildWeatherHourItem('13:00', '25°', true),
                                    ],
                                  ),
                                ),
                                if (_isWeatherExpanded) ...[
                                  const SizedBox(height: 20),
                                  Divider(height: 1, color: Colors.black.withOpacity(0.1)),
                                  const SizedBox(height: 20),
                                  Text(
                                    '3-Daagse Voorspelling',
                                    style: GoogleFonts.openSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A4A24),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildDayForecast('Vandaag', '32°/26°', Icons.wb_sunny),
                                      _buildDayForecast('Morgen', '30°/25°', Icons.wb_sunny),
                                      _buildDayForecast('Overmorgen', '29°/24°', Icons.cloud_queue),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Center(
                                  child: Icon(
                                    _isWeatherExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    color: Color(0xFF1A4A24),
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                        const SizedBox(height: 32),

                        // Mood Selection Title
                        Center(
                          child: Text(
                            'How are you feeling today?',
                            style: GoogleFonts.openSans(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A4A24),
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                        const SizedBox(height: 24),

                        // First row of moods
                        SizedBox(
                          height: 85,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 6,
                            itemBuilder: (context, index) {
                              final moods = [
                                {'label': 'Adventurous', 'emoji': '🏕️', 'color': Color(0xFFCAE5FC)},
                                {'label': 'Relaxed', 'emoji': '🧖🏾‍♀️', 'color': Color(0xFFE7CCEB)},
                                {'label': 'Romantic', 'emoji': '💖', 'color': Color(0xFFFFD5DC)},
                                {'label': 'Energetic', 'emoji': '⚡', 'color': Color(0xFFFFEED4)},
                                {'label': 'Excited', 'emoji': '🤩', 'color': Color(0xFFD0EBD1)},
                                {'label': 'Cozy', 'emoji': '☕', 'color': Color(0xFFD2F3F8)},
                              ];
                              return _buildMoodTile(
                                moods[index]['label'] as String,
                                moods[index]['color'] as Color,
                                moods[index]['emoji'] as String,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Second row of moods
                        SizedBox(
                          height: 85,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 6,
                            itemBuilder: (context, index) {
                              final moods = [
                                {'label': 'Surprise', 'emoji': '😲', 'color': Color(0xFFFFE0B2)},
                                {'label': 'Foody', 'emoji': '🍽️', 'color': Color(0xFFFFCDD2)},
                                {'label': 'Festive', 'emoji': '🎉', 'color': Color(0xFFE8EAF6)},
                                {'label': 'Mind full', 'emoji': '🧠', 'color': Color(0xFFB2DFDB)},
                                {'label': 'Family fun', 'emoji': '👨‍👩‍👧‍👦', 'color': Color(0xFFD1C4E9)},
                                {'label': 'Cultural', 'emoji': '🌍', 'color': Color(0xFFB2EBF2)},
                              ];
                              return _buildMoodTile(
                                moods[index]['label'] as String,
                                moods[index]['color'] as Color,
                                moods[index]['emoji'] as String,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        // Unlock the Fun button
                        if (_selectedMoods.isNotEmpty) ...[
                          Center(
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              child: ElevatedButton(
                                onPressed: () {
                                  // Hier komt de navigatie logica
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF12B347),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 4,
                                ).copyWith(
                                  overlayColor: MaterialStateProperty.all(
                                    Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Unlock the Fun',
                                      style: GoogleFonts.openSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '🎯',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().slideY(
                            begin: 0.3,
                            end: 0,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeOutQuad,
                          ).fadeIn(
                            duration: Duration(milliseconds: 400),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, 'Home', true),
                _buildNavItem(1, Icons.explore_outlined, 'Explore', false),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFF12B347).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.grid_view,
                    size: 24,
                    color: Color(0xFF12B347),
                  ),
                ),
                _buildNavItem(3, Icons.calendar_today_outlined, 'Agenda', false),
                _buildNavItem(4, Icons.person_outline, 'Profile', false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherHourItem(String hour, String temp, bool isDaytime) {
    // Bepaal het uur van de dag
    int currentHour;
    if (hour == 'Nu') {
      currentHour = 14; // Stel de huidige tijd in op 14:00
    } else {
      currentHour = int.parse(hour.split(':')[0]);
    }

    // Bepaal of het dag of nacht is (dag tussen 6:00 en 20:00)
    bool isDay = currentHour >= 6 && currentHour < 20;
    
    // Kies het juiste emoji op basis van tijd
    String weatherEmoji;
    if (isDay) {
      weatherEmoji = '☀️';
    } else {
      weatherEmoji = '🌕'; // Witte maan emoji
    }

    return Container(
      margin: EdgeInsets.only(right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hour,
            style: GoogleFonts.openSans(
              fontSize: 16,
              color: Color(0xFF1A4A24),
            ),
          ),
          SizedBox(height: 4),
          Text(
            weatherEmoji,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 4),
          Text(
            temp,
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A4A24),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDayForecast(String day, String temp, IconData icon) {
    return Column(
        children: [
        Text(
          day,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: Color(0xFF1A4A24),
          ),
        ),
        SizedBox(height: 8),
        Icon(icon, color: Color(0xFFF9C21B), size: 24),
        SizedBox(height: 8),
          Text(
          temp,
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A4A24),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF1A4A24), size: 20),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: Color(0xFF1A4A24).withOpacity(0.8),
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A4A24),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodTile(String label, Color bgColor, String emoji) {
    final isSelected = _selectedMoods.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMoods.remove(label);
          } else if (_selectedMoods.length < 3) {
            _selectedMoods.add(label);
          }
        });
      },
      child: Container(
        width: 80,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgColor.withOpacity(0.7) : bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Color(0xFF12B347) : bgColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: bgColor.withOpacity(0.5),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Color(0xFF12B347),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(fontSize: 28),
                  ),
                  SizedBox(height: 2),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      label,
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Color(0xFF12B347) : Color(0xFF1A4A24),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: Duration(seconds: 2),
      color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Color(0xFF12B347) : Color(0xFF9D9DA5),
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: isActive ? Color(0xFF12B347) : Color(0xFF9D9DA5),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isWeatherExpanded = false;
  final List<Map<String, dynamic>> _firstRowMoods = [
    {
      'icon': '🏕️',
      'label': 'Adventurous',
      'color': Colors.blue.shade50,
      'borderColor': Colors.blue.shade200,
    },
    {
      'icon': '🍃',
      'label': 'Relaxed',
      'color': Colors.green.shade50,
      'borderColor': Colors.green.shade200,
    },
    {
      'icon': '💖',
      'label': 'Romantic',
      'color': Colors.pink.shade50,
      'borderColor': Colors.pink.shade200,
    },
    {
      'icon': '⚡',
      'label': 'Energetic',
      'color': Colors.yellow.shade50,
      'borderColor': Colors.yellow.shade200,
    },
    {
      'icon': '🤩',
      'label': 'Excited',
      'color': Colors.purple.shade50,
      'borderColor': Colors.purple.shade200,
    },
    {
      'icon': '☕',
      'label': 'Cozy',
      'color': Colors.brown.shade50,
      'borderColor': Colors.brown.shade200,
    },
  ];

  final List<Map<String, dynamic>> _secondRowMoods = [
    {
      'icon': '😲',
      'label': 'Surprise',
      'color': Colors.orange.shade50,
      'borderColor': Colors.orange.shade200,
    },
    {
      'icon': '🍽️',
      'label': 'Foody',
      'color': Colors.red.shade50,
      'borderColor': Colors.red.shade200,
    },
    {
      'icon': '🎉',
      'label': 'Festive',
      'color': Colors.indigo.shade50,
      'borderColor': Colors.indigo.shade200,
    },
    {
      'icon': '🧠',
      'label': 'Mind',
      'color': Colors.teal.shade50,
      'borderColor': Colors.teal.shade200,
    },
    {
      'icon': '👨‍👩‍👧‍👦',
      'label': 'Family fun',
      'color': Colors.deepPurple.shade50,
      'borderColor': Colors.deepPurple.shade200,
    },
    {
      'icon': '🌍',
      'label': 'Cultural',
      'color': Colors.cyan.shade50,
      'borderColor': Colors.cyan.shade200,
    },
  ];

  Set<String> _selectedMoods = {};

  void _handleMoodSelect(String mood) {
    setState(() {
      if (_selectedMoods.contains(mood)) {
        _selectedMoods.remove(mood);
      } else if (_selectedMoods.length < 3) {
        _selectedMoods.add(mood);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const SizedBox(height: 12),
            
            // Header with profile and weather
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green, size: 12),
                        const SizedBox(width: 2),
          Text(
                          'Washington DC',
            style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wb_sunny, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
          Text(
                            '32°',
            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.notifications_none, color: Colors.green, size: 18),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 16),
          
            // Greeting
            Text(
              'Hello, John!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          
          const SizedBox(height: 16),
          
            // Weather widget
            GestureDetector(
              onTap: () {
                setState(() {
                  _isWeatherExpanded = !_isWeatherExpanded;
                });
              },
        child: Container(
          padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sunny for the rest of the day. Wind speeds up to 19 km/h.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _isWeatherExpanded ? 0.5 : 0,
                          child: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (index) {
                          final hour = (DateTime.now().hour + index) % 24;
                          final temp = 29 - index;
                          final isNight = hour < 6 || hour > 18;
                          
                          return Container(
                            margin: const EdgeInsets.only(right: 24),
                            child: Column(
                              children: [
                                Text(
                                  index == 0 ? 'Now' : '$hour:00',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Icon(
                                  isNight ? Icons.nightlight_round : Icons.wb_sunny,
                                  color: isNight ? Colors.blueGrey : Colors.amber,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                    Text(
                                  '$temp°',
                      style: const TextStyle(
                                    fontSize: 16,
                        fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    if (_isWeatherExpanded) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Colors.black12),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWeatherDetail(
                            icon: Icons.air,
                            label: 'Wind',
                            value: '19 km/h',
                          ),
                          _buildWeatherDetail(
                            icon: Icons.water_drop,
                            label: 'Humidity',
                            value: '65%',
                          ),
                          _buildWeatherDetail(
                            icon: Icons.wb_twilight,
                            label: 'UV Index',
                            value: '6 of 10',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWeatherDetail(
                            icon: Icons.wb_sunny,
                            label: 'Sunrise',
                            value: '6:24 AM',
                          ),
                          _buildWeatherDetail(
                            icon: Icons.nightlight,
                            label: 'Sunset',
                            value: '8:16 PM',
                          ),
                          _buildWeatherDetail(
                            icon: Icons.visibility,
                            label: 'Visibility',
                            value: '16.1 km',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

            const SizedBox(height: 32),

            // Mood selection title
            Text(
              'How are you feeling today?',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

            const SizedBox(height: 24),

            // First row of moods
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _firstRowMoods.length,
                itemBuilder: (context, index) {
                  final mood = _firstRowMoods[index];
                  final isSelected = _selectedMoods.contains(mood['label']);
                  return Container(
                    width: 80,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? (mood['color'] as Color).withOpacity(0.7)
                        : mood['color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                          ? mood['borderColor'] as Color
                          : (mood['borderColor'] as Color).withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (mood['color'] as Color).withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                    ),
                    child: Stack(
                      children: [
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: mood['borderColor'] as Color,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mood['icon'],
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mood['label'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected 
                                  ? mood['borderColor'] as Color
                                  : Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate(
                    onPlay: (controller) => controller.repeat(),
                  ).shimmer(
                    duration: const Duration(seconds: 2),
                    color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  );
                },
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 400.ms),

            const SizedBox(height: 16),

            // Second row of moods
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _secondRowMoods.length,
                itemBuilder: (context, index) {
                  final mood = _secondRowMoods[index];
                  final isSelected = _selectedMoods.contains(mood['label']);
                  return Container(
                    width: 80,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? (mood['color'] as Color).withOpacity(0.7)
                        : mood['color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                          ? mood['borderColor'] as Color
                          : (mood['borderColor'] as Color).withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (mood['color'] as Color).withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                    ),
                    child: Stack(
                      children: [
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: mood['borderColor'] as Color,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mood['icon'],
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mood['label'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected 
                                  ? mood['borderColor'] as Color
                                  : Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate(
                    onPlay: (controller) => controller.repeat(),
                  ).shimmer(
                    duration: const Duration(seconds: 2),
                    color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  );
                },
              ),
            ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class PlannerTab extends StatelessWidget {
  const PlannerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

// Dashboard tab volgens ontwerp
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isWeatherExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Top row with profile, location, weather and notification
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white),
              ).animate().fadeIn(duration: 400.ms),
              
              const SizedBox(width: 8),
              
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Washington DC',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              
              const Spacer(),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '32°',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              
              const SizedBox(width: 8),
              
              const Icon(Icons.notifications, color: Color(0xFF4CAF50), size: 20)
                  .animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Hello, John!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4CAF50),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 12),
          
          // Weather widget with expandable view
          Flexible(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isWeatherExpanded = !_isWeatherExpanded;
                });
              },
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isWeatherExpanded 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
                firstChild: HourlyWeatherWidget(
                  onViewChanged: (_) {
                    setState(() {
                      _isWeatherExpanded = true;
                    });
                  },
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                secondChild: CompactWeatherWidget(
                  onViewChanged: (_) {
                    setState(() {
                      _isWeatherExpanded = false;
                    });
                  },
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: MoodSelectionWidget(
              onMoodsSelected: (selectedMoods) {
                print('Selected moods: $selectedMoods');
              },
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }
} 