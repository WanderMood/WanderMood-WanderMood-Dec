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

class TravelStyleScreen extends ConsumerStatefulWidget {
  const TravelStyleScreen({super.key});

  @override
  ConsumerState<TravelStyleScreen> createState() => _TravelStyleScreenState();
}

class _TravelStyleScreenState extends ConsumerState<TravelStyleScreen> with TickerProviderStateMixin {
  late final AnimationController _moodyController;
  late final AnimationController _messageController;
  final Set<String> _selectedStyles = {};
  static const int maxStyleSelections = 3;

  final List<Map<String, dynamic>> _travelStyles = [
    {
      'name': 'Spontaneous',
      'emoji': '🎯',
      'description': 'Go with the flow, embrace surprises',
      'color': const Color(0xFFFFB74D), // Soft Orange
    },
    {
      'name': 'Planned',
      'emoji': '📅',
      'description': 'Organized itineraries, scheduled visits',
      'color': const Color(0xFF64B5F6), // Soft Blue
    },
    {
      'name': 'Local Experience',
      'emoji': '🏡',
      'description': 'Live like a local, authentic spots',
      'color': const Color(0xFF7CB342), // Soft Green
    },
    {
      'name': 'Tourist Highlights',
      'emoji': '🗺️',
      'description': 'Must-see attractions, popular spots',
      'color': const Color(0xFFEC407A), // Soft Pink
    },
    {
      'name': 'Off the Beaten Path',
      'emoji': '⭐',
      'description': 'Hidden gems, unique experiences',
      'color': const Color(0xFF9575CD), // Soft Purple
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

  void _toggleStyle(String style) {
    if (_selectedStyles.contains(style)) {
      setState(() {
        _selectedStyles.remove(style);
      });
    } else if (_selectedStyles.length < maxStyleSelections) {
      setState(() {
        _selectedStyles.add(style);
      });
    }
    
    // Instead of immediately updating the provider, we'll do it after the build cycle is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(preferencesProvider.notifier).updateTravelStyles(_selectedStyles.toList());
      }
    });
    
  }

  @override
  void dispose() {
    _moodyController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildStyleCard(Map<String, dynamic> style) {
    final bool isSelected = _selectedStyles.contains(style['name']);
    final color = style['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _toggleStyle(style['name']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      style['emoji'],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                            ? Colors.white
                            : Colors.black87,
                        ),
                      ),
                      Text(
                        style['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: color,
                      size: 16,
                    ),
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
              // Background waves
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
                        color: index < 6 
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
                  onTap: () => context.go('/preferences/planning-pace'),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                                      final title = communicationState.texts['travel_style']?[styleKey] ?? 'Last but not least! ✨';
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
                                      final subtitle = communicationState.texts['travel_style_subtitle']?[styleKey] ?? 'What\'s your travel style?';
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
                            
                            ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: _travelStyles.map((style) => _buildStyleCard(style)).toList(),
                            ),
                            const SizedBox(height: 8),
                            // Continue button
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _selectedStyles.isNotEmpty
                                        ? () async {
                                            // Don't mark as complete yet - let the loading screen do that
                                            if (mounted) {
                                              context.go('/preferences/loading');
                                            }
                                          }
                                        : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _selectedStyles.isNotEmpty
                                          ? const Color(0xFF5BB32A)
                                          : Colors.grey.withOpacity(0.3),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: _selectedStyles.isNotEmpty ? 4 : 0,
                                        shadowColor: _selectedStyles.isNotEmpty 
                                          ? const Color(0xFF5BB32A).withOpacity(0.4)
                                          : Colors.transparent,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Start My Journey',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward_rounded),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Moody character - positioned just above subtitle, in front of everything
              Positioned(
                right: 20,
                bottom: MediaQuery.of(context).size.height * 0.15, // Positioned just above subtitle
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.5,
                    end: 1.0,
                  ).animate(_moodyController),
                  child: const MoodyCharacter(
                    size: 70, // Reduced from 100 to 70
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