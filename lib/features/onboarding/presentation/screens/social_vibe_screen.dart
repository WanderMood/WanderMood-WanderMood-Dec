import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
          const Color(0xFFFFFDF5).withOpacity(0.95),
          const Color(0xFFFFF3E0).withOpacity(0.85),
          const Color(0xFFFFF9E8).withOpacity(0.75),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Create accent wave paint with higher opacity
    final Paint accentPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFFFFF3E0).withOpacity(0.85),
          const Color(0xFFFFF9E8).withOpacity(0.75),
          const Color(0xFFFFFDF5).withOpacity(0.65),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final Path mainWavePath = Path();
    final Path accentWavePath = Path();

    // Create multiple flowing wave layers with larger amplitude
    for (int i = 0; i < 3; i++) {
      double amplitude = size.height * 0.12;
      double frequency = math.pi / (size.width * 0.4);
      double verticalOffset = size.height * (0.2 + i * 0.3);

      mainWavePath.moveTo(0, verticalOffset);
      
      // Create more pronounced flowing wave
      for (double x = 0; x <= size.width; x += 4) {
        double y = verticalOffset + 
                   math.sin(x * frequency + i) * amplitude +
                   math.cos(x * frequency * 0.5) * amplitude * 0.9;
        
        if (x == 0) {
          mainWavePath.moveTo(x, y);
        } else {
          mainWavePath.lineTo(x, y);
        }
      }

      // Create accent waves with larger amplitude
      amplitude = size.height * 0.09;
      verticalOffset = size.height * (0.1 + i * 0.3);
      
      for (double x = 0; x <= size.width; x += 4) {
        double y = verticalOffset + 
                   math.sin(x * frequency * 1.5 + i + math.pi) * amplitude +
                   math.cos(x * frequency * 0.7) * amplitude * 1.2;
        
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
      double controlY = size.height * (0.1 + i * 0.4);
      
      mainWavePath.moveTo(0, startY);
      mainWavePath.quadraticBezierTo(
        size.width * 0.5,
        controlY,
        size.width,
        startY
      );
    }

    // Add larger dots along the waves
    for (int i = 0; i < 15; i++) {
      double x = size.width * (i / 15);
      double y = size.height * (0.3 + math.sin(i * 0.8) * 0.25);
      
      canvas.drawCircle(
        Offset(x, y),
        5,
        wavePaint
      );
    }

    // Draw all elements with stronger blur effect
    canvas.drawPath(mainWavePath, wavePaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawPath(accentWavePath, accentPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SocialVibeScreen extends ConsumerStatefulWidget {
  const SocialVibeScreen({super.key});

  @override
  ConsumerState<SocialVibeScreen> createState() => _SocialVibeScreenState();
}

class _SocialVibeScreenState extends ConsumerState<SocialVibeScreen> with TickerProviderStateMixin {
  late final AnimationController _moodyController;
  late final AnimationController _messageController;
  final Set<String> _selectedVibes = {};

  final List<Map<String, dynamic>> _socialVibes = [
    {
      'name': 'Solo Adventures',
      'emoji': '🧘‍♀️',
      'description': 'Me time is the best time',
      'color': const Color(0xFFFFB74D), // Orange
    },
    {
      'name': 'Small Groups',
      'emoji': '👥',
      'description': 'Close friends, intimate vibes',
      'color': const Color(0xFF66BB6A), // Green
    },
    {
      'name': 'Social Butterfly',
      'emoji': '🦋',
      'description': 'Love meeting new people',
      'color': const Color(0xFF42A5F5), // Blue
    },
    {
      'name': 'Mood Dependent',
      'emoji': '🎭',
      'description': 'Sometimes solo, sometimes social',
      'color': const Color(0xFFAB47BC), // Purple
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

  void _toggleSocialVibe(String vibe) {
    if (_selectedVibes.contains(vibe)) {
      setState(() {
        _selectedVibes.remove(vibe);
      });
    } else {
      setState(() {
        _selectedVibes.add(vibe);
      });
    }
    
    // Update the preferences provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(preferencesProvider.notifier).updateTravelStyles(_selectedVibes.toList());
      }
    });
  }

  @override
  void dispose() {
    _moodyController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildSocialVibeCard(Map<String, dynamic> vibe) {
    final bool isSelected = _selectedVibes.contains(vibe['name']);
    final color = vibe['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _toggleSocialVibe(vibe['name']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 100,
          decoration: BoxDecoration(
            color: isSelected 
              ? color
              : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                ? color
                : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              // Main floating shadow - subtle per card
              BoxShadow(
                color: isSelected
                  ? color.withOpacity(0.12)
                  : const Color(0xFFE8E8E8).withOpacity(0.4),
                blurRadius: isSelected ? 8 : 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
              // Secondary depth shadow - very subtle
              BoxShadow(
                color: isSelected
                  ? color.withOpacity(0.08)
                  : const Color(0xFFD0D0D0).withOpacity(0.2),
                blurRadius: isSelected ? 12 : 10,
                spreadRadius: -1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      vibe['emoji'],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vibe['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                            ? Colors.white
                            : Colors.black87,
                        ),
                      ),
                      Text(
                        vibe['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: isSelected
                      ? Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: color,
                            size: 16,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        color: index < 4 
                          ? const Color(0xFF5BB32A)
                          : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
                  ],
                ),
              ),

              // Back button
              Positioned(
                top: 20,
                left: 20,
                child: GestureDetector(
                  onTap: () => context.go('/preferences/interests'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
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
                               final title = communicationState.texts['social_vibe']?[styleKey] ?? 'What\'s your social vibe? 👥';
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
                               final subtitle = communicationState.texts['social_vibe_subtitle']?[styleKey] ?? 'How do you like to experience things?';
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
                        itemCount: _socialVibes.length,
                        itemBuilder: (context, index) {
                          return _buildSocialVibeCard(_socialVibes[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedVibes.isNotEmpty
                          ? () => context.go('/preferences/planning-pace')
                          : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedVibes.isNotEmpty
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
                      child: Text(
                        'You can select multiple options ✨',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
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
          size: 70, // Reduced size
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 