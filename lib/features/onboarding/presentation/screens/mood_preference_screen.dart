import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/providers/communication_style_provider.dart';


class SwirlingGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create flowing wave gradients with maximum opacity
    final Paint wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFFDF5).withOpacity(0.95),  // Increased from 0.8
          const Color(0xFFFFF3E0).withOpacity(0.85),  // Increased from 0.7
          const Color(0xFFFFF9E8).withOpacity(0.75),  // Increased from 0.6
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Create accent wave paint with higher opacity
    final Paint accentPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFFFFF3E0).withOpacity(0.85),  // Increased from 0.7
          const Color(0xFFFFF9E8).withOpacity(0.75),  // Increased from 0.6
          const Color(0xFFFFFDF5).withOpacity(0.65),  // Increased from 0.5
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final Path mainWavePath = Path();
    final Path accentWavePath = Path();

    // Create multiple flowing wave layers with larger amplitude
    for (int i = 0; i < 3; i++) {
      double amplitude = size.height * 0.12;  // Increased from 0.08
      double frequency = math.pi / (size.width * 0.4);  // Adjusted for wider waves
      double verticalOffset = size.height * (0.2 + i * 0.3);

      mainWavePath.moveTo(0, verticalOffset);
      
      // Create more pronounced flowing wave
      for (double x = 0; x <= size.width; x += 4) {  // Decreased step for smoother waves
        double y = verticalOffset + 
                   math.sin(x * frequency + i) * amplitude +
                   math.cos(x * frequency * 0.5) * amplitude * 0.9;  // Increased from 0.7
        
        if (x == 0) {
          mainWavePath.moveTo(x, y);
        } else {
          mainWavePath.lineTo(x, y);
        }
      }

      // Create accent waves with larger amplitude
      amplitude = size.height * 0.09;  // Increased from 0.06
      verticalOffset = size.height * (0.1 + i * 0.3);
      
      for (double x = 0; x <= size.width; x += 4) {  // Decreased step for smoother waves
        double y = verticalOffset + 
                   math.sin(x * frequency * 1.5 + i + math.pi) * amplitude +
                   math.cos(x * frequency * 0.7) * amplitude * 1.2;  // Increased multiplier
        
        if (x == 0) {
          accentWavePath.moveTo(x, y);
        } else {
          accentWavePath.lineTo(x, y);
        }
      }
    }

    // Create more pronounced flowing curves
    for (int i = 0; i < 2; i++) {
      double startY = size.height * (0.3 + i * 0.4);
      double controlY = size.height * (0.1 + i * 0.4);  // Lower control point for more curve
      
      mainWavePath.moveTo(0, startY);
      mainWavePath.quadraticBezierTo(
        size.width * 0.5,
        controlY,
        size.width,
        startY
      );
    }

    // Add larger dots along the waves
    for (int i = 0; i < 15; i++) {  // Increased number of dots
      double x = size.width * (i / 15);
      double y = size.height * (0.3 + math.sin(i * 0.8) * 0.25);  // Increased amplitude
      
      canvas.drawCircle(
        Offset(x, y),
        5,  // Increased from 4
        wavePaint
      );
    }

    // Draw all elements with stronger blur effect
    canvas.drawPath(mainWavePath, wavePaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));  // Increased from 4
    canvas.drawPath(accentWavePath, accentPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));  // Increased from 3
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MoodPreferenceScreen extends ConsumerStatefulWidget {
  const MoodPreferenceScreen({super.key});

  @override
  ConsumerState<MoodPreferenceScreen> createState() => _MoodPreferenceScreenState();
}

class _MoodPreferenceScreenState extends ConsumerState<MoodPreferenceScreen> with TickerProviderStateMixin {
  late final AnimationController _moodyController;
  late final AnimationController _messageController;
  final Set<String> _selectedMoods = {};
  static const int maxMoodSelections = 3;



  final List<Map<String, dynamic>> _moods = [
    {
      'name': 'Adventurous',
      'emoji': '🏃‍♂️',
      'color': const Color(0xFF7CB342), // Softer Green
    },
    {
      'name': 'Peaceful',
      'emoji': '🧘‍♀️',
      'color': const Color(0xFF64B5F6), // Softer Blue
    },
    {
      'name': 'Social',
      'emoji': '🎉',
      'color': const Color(0xFFFFB74D), // Softer Orange
    },
    {
      'name': 'Cultural',
      'emoji': '🎭',
      'color': const Color(0xFFEC407A), // Softer Pink
    },
    {
      'name': 'Foody',
      'emoji': '🍽️',
      'color': const Color(0xFF98D95A),  // Softer green
      'selectedColor': const Color(0xFF7CB518),
    },
    {
      'name': 'Spontaneous',
      'emoji': '✨',
      'color': const Color(0xFF70D7FF),  // Softer blue
      'selectedColor': const Color(0xFF00B4D8),
    },
  ];

  @override
  void initState() {
    super.initState();
    _moodyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _moodyController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _messageController.forward();
  }

  void _toggleMoodSelection(String mood) {
    if (_selectedMoods.contains(mood)) {
      setState(() {
        _selectedMoods.remove(mood);
      });
      // Update provider after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(preferencesProvider.notifier).updateSelectedMoods(_selectedMoods.toList());
        }
      });
    } else {
      if (_selectedMoods.length < maxMoodSelections) {
        setState(() {
          _selectedMoods.add(mood);
        });
        // Update provider after the build is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(preferencesProvider.notifier).updateSelectedMoods(_selectedMoods.toList());
          }
        });
        

      }
    }
  }

  @override
  void dispose() {
    _moodyController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the preferences to rebuild when they change
    final preferences = ref.watch(preferencesProvider);
    debugPrint('Current moods: ${preferences.selectedMoods}');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDF5), // Warm cream yellow
              Color(0xFFFFF3E0), // Slightly darker warm yellow
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Swirl effect
              Positioned.fill(
                child: CustomPaint(
                  painter: SwirlingGradientPainter(),
                ),
              ),
              
              // Progress indicator
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(6, (index) => Container(
                      width: 35,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: index < 2 
                          ? const Color(0xFF5BB32A)
                          : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
                  ],
                ),
              ),

              // Back button - positioned last to be on top
              Positioned(
                top: 20,
                left: 20,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    debugPrint('🔙 Back button tapped - navigating to communication preferences');
                    context.go('/preferences/communication');
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF5BB32A),
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.2),
                        end: Offset.zero,
                      ).animate(_messageController),
                      child: FadeTransition(
                        opacity: _messageController,
                        child: Center(
                                                     child: Consumer(
                             builder: (context, ref, child) {
                               final communicationState = ref.watch(communicationStyleProvider);
                               final styleKey = communicationState.style.toString().split('.').last;
                               final title = communicationState.texts['mood']?[styleKey] ?? 'Let\'s sync our vibes! ✨';
                               return Text(
                                 title,
                                 style: GoogleFonts.museoModerno(
                                   fontSize: 32,
                                   fontWeight: FontWeight.bold,
                                   color: const Color(0xFF5BB32A),
                                 ),
                                 textAlign: TextAlign.center,
                               );
                             },
                           ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.2),
                        end: Offset.zero,
                      ).animate(_messageController),
                      child: FadeTransition(
                        opacity: _messageController,
                        child: Center(
                                                     child: Consumer(
                             builder: (context, ref, child) {
                               final communicationState = ref.watch(communicationStyleProvider);
                               final styleKey = communicationState.style.toString().split('.').last;
                               final subtitle = communicationState.texts['mood_subtitle']?[styleKey] ?? 'What moods inspire you to explore?';
                               return Text(
                                 subtitle,
                                 style: GoogleFonts.poppins(
                                   fontSize: 16,
                                   color: Colors.black87,
                                 ),
                                 textAlign: TextAlign.center,
                               );
                             },
                           ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _moods.length,
                        itemBuilder: (context, index) {
                          final mood = _moods[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildMoodListItem(mood),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedMoods.isNotEmpty
                          ? () => context.go('/preferences/interests')
                          : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedMoods.isNotEmpty
                            ? const Color(0xFF5BB32A)
                            : Colors.grey.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child:                       Consumer(
                        builder: (context, ref, child) {
                          final communicationState = ref.watch(communicationStyleProvider);
                          final styleKey = communicationState.style.toString().split('.').last;
                          final hintText = communicationState.texts['multiple_selection_hint']?[styleKey] ?? 'You can select multiple options ✨';
                          return Text(
                            hintText,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Moody character - reduced size
              Positioned(
                right: 20,
                bottom: MediaQuery.of(context).size.height * 0.12,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.5,
                    end: 1.0,
                  ).animate(_moodyController),
                          child: const MoodyCharacter(
          size: 70, // Reduced from 150
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodListItem(Map<String, dynamic> mood) {
    final bool isSelected = _selectedMoods.contains(mood['name']);
    final baseColor = mood['color'];
    
    return GestureDetector(
      onTap: () => _toggleMoodSelection(mood['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 70,
        decoration: BoxDecoration(
          color: isSelected 
            ? baseColor
            : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
              ? baseColor
              : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            // Main floating shadow - subtle per card
            BoxShadow(
              color: isSelected
                ? baseColor.withOpacity(0.12)
                : const Color(0xFFE8E8E8).withOpacity(0.4),
              blurRadius: isSelected ? 8 : 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
            // Secondary depth shadow - very subtle
            BoxShadow(
              color: isSelected
                ? baseColor.withOpacity(0.08)
                : const Color(0xFFD0D0D0).withOpacity(0.2),
              blurRadius: isSelected ? 12 : 10,
              spreadRadius: -1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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