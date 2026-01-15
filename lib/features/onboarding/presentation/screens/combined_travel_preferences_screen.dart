import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/providers/communication_style_provider.dart';

class CombinedTravelPreferencesScreen extends ConsumerStatefulWidget {
  const CombinedTravelPreferencesScreen({super.key});

  @override
  ConsumerState<CombinedTravelPreferencesScreen> createState() => _CombinedTravelPreferencesScreenState();
}

class _CombinedTravelPreferencesScreenState extends ConsumerState<CombinedTravelPreferencesScreen> 
    with TickerProviderStateMixin {
  late final AnimationController _moodyController;
  late final AnimationController _messageController;
  
  // Social Vibe state
  final Set<String> _selectedVibes = {};
  
  // Planning Pace state
  String? _selectedPace;
  
  // Travel Style state
  final Set<String> _selectedStyles = {};
  static const int maxStyleSelections = 3;

  // Social Vibes options
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

  // Planning Paces options
  final List<Map<String, dynamic>> _planningPaces = [
    {
      'name': 'Right Now Vibes',
      'emoji': '⚡',
      'description': 'What should I do right now?',
      'color': const Color(0xFFFFB74D), // Orange
    },
    {
      'name': 'Same Day Planner',
      'emoji': '🌅',
      'description': 'Plan in the morning for the day',
      'color': const Color(0xFF66BB6A), // Green
    },
    {
      'name': 'Weekend Prepper',
      'emoji': '📅',
      'description': 'Plan a few days ahead',
      'color': const Color(0xFF8D6E63), // Brown
    },
    {
      'name': 'Master Planner',
      'emoji': '📋',
      'description': 'Love planning weeks ahead',
      'color': const Color(0xFF78909C), // Blue Grey
    },
  ];

  // Travel Styles options
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
      'name': 'Luxury Seeker',
      'emoji': '✨',
      'description': 'Premium experiences, high-end spots',
      'color': const Color(0xFFEC407A), // Soft Pink
    },
    {
      'name': 'Budget Conscious',
      'emoji': '💰',
      'description': 'Great value, smart spending',
      'color': const Color(0xFF66BB6A), // Soft Green
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

  void _toggleSocialVibe(String vibe) {
    setState(() {
      if (_selectedVibes.contains(vibe)) {
        _selectedVibes.remove(vibe);
      } else {
        _selectedVibes.add(vibe);
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(preferencesProvider.notifier).updateSocialVibe(_selectedVibes.toList());
      }
    });
  }

  void _selectPlanningPace(String pace) {
    setState(() {
      _selectedPace = pace;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(preferencesProvider.notifier).updatePlanningPace(pace);
      }
    });
  }

  void _toggleStyle(String style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        _selectedStyles.remove(style);
      } else if (_selectedStyles.length < maxStyleSelections) {
        _selectedStyles.add(style);
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(preferencesProvider.notifier).updateTravelStyles(_selectedStyles.toList());
      }
    });
  }

  bool get _canContinue {
    return _selectedVibes.isNotEmpty && _selectedPace != null && _selectedStyles.isNotEmpty;
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
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _toggleSocialVibe(vibe['name']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                  ? color.withOpacity(0.12)
                  : const Color(0xFFE8E8E8).withOpacity(0.4),
                blurRadius: isSelected ? 8 : 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      vibe['emoji'],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vibe['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        vibe['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: color,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanningPaceCard(Map<String, dynamic> pace) {
    final bool isSelected = _selectedPace == pace['name'];
    final color = pace['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _selectPlanningPace(pace['name']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                  ? color.withOpacity(0.12)
                  : const Color(0xFFE8E8E8).withOpacity(0.4),
                blurRadius: isSelected ? 8 : 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      pace['emoji'],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pace['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        pace['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: color,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyleCard(Map<String, dynamic> style) {
    final bool isSelected = _selectedStyles.contains(style['name']);
    final color = style['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleStyle(style['name']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                  ? color.withOpacity(0.12)
                  : const Color(0xFFE8E8E8).withOpacity(0.4),
                blurRadius: isSelected ? 8 : 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      style['emoji'],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        style['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        style['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: color,
                      size: 14,
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
      body: SwirlBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Progress indicator (4 of 4)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(4, (index) => Container(
                      width: 35,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: index < 4 
                          ? const Color(0xFF4CAF50)
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
                      color: Color(0xFF4CAF50),
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
                    
                    // Title
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
                              final title = communicationState.texts['travel_preferences']?[styleKey] ?? 'Tell us about your travel style ✈️';
                              return Text(
                                title,
                                style: GoogleFonts.museoModerno(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4CAF50),
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
                              final subtitle = communicationState.texts['travel_preferences_subtitle']?[styleKey] ?? 'A few quick questions to personalize your experience';
                              return Text(
                                subtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section 1: Social Vibe
                            Text(
                              'Social Vibe 👥',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._socialVibes.map((vibe) => _buildSocialVibeCard(vibe)),
                            
                            const SizedBox(height: 32),
                            
                            // Section 2: Planning Pace
                            Text(
                              'Planning Pace ⏰',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._planningPaces.map((pace) => _buildPlanningPaceCard(pace)),
                            
                            const SizedBox(height: 32),
                            
                            // Section 3: Travel Style
                            Text(
                              'Travel Style 🎯',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select up to ${maxStyleSelections} styles',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._travelStyles.map((style) => _buildStyleCard(style)),
                            
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    
                    // Continue button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canContinue
                            ? () => context.go('/preferences/loading')
                            : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canContinue
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.withOpacity(0.3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
