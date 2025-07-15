import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../widgets/swirling_gradient_painter.dart';
import '../../../../core/providers/preferences_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/communication_style_provider.dart';

class CommunicationPreferenceScreen extends ConsumerStatefulWidget {
  const CommunicationPreferenceScreen({super.key});

  @override
  ConsumerState<CommunicationPreferenceScreen> createState() => _CommunicationPreferenceScreenState();
}

class _CommunicationPreferenceScreenState extends ConsumerState<CommunicationPreferenceScreen> {
  String? _selectedStyle;

  final List<Map<String, dynamic>> _communicationStyles = [
    {
      'name': 'Friendly',
      'emoji': '😊',
      'description': 'Casual and warm communication',
      'color': const Color(0xFFFFB74D), // Soft Orange
    },
    {
      'name': 'Professional',
      'emoji': '👔',
      'description': 'Clear and formal communication',
      'color': const Color(0xFF64B5F6), // Soft Blue
    },
    {
      'name': 'Energetic',
      'emoji': '⚡',
      'description': 'Fun and enthusiastic communication',
      'color': const Color(0xFF7CB342), // Soft Green
    },
    {
      'name': 'Direct',
      'emoji': '🎯',
      'description': 'Straight to the point',
      'color': const Color(0xFFEC407A), // Soft Pink
    },
  ];

  Widget _buildStyleCard(Map<String, dynamic> style) {
    final bool isSelected = _selectedStyle == style['name'].toLowerCase();
    final color = style['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStyle = style['name'].toLowerCase();
          });
          ref.read(communicationStyleProvider.notifier).setCommunicationStyle(_selectedStyle!);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 70, // Fixed height
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        style['description'],
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
                      color: color,
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
              // Main content column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(6, (index) => Container(
                          width: 35,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: index < 1
                              ? const Color(0xFF5BB32A)
                              : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  
                  // Title and introduction section with reduced spacing
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'How should I talk to you? 💬',
                          style: GoogleFonts.museoModerno(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5BB32A),
                          ),
                        ).animate()
                         .fadeIn(duration: 600.ms)
                         .slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        // Introduction text full width
                        Text(
                          'To make our journey together more enjoyable, I\'d love to know how you prefer me to communicate with you.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ).animate()
                         .fadeIn(duration: 600.ms, delay: 200.ms)
                         .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 8),
                        
                        // Moody and text in a row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                'This helps me adjust my tone and style to match your preferences perfectly! 🎯',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ).animate()
                               .fadeIn(duration: 600.ms, delay: 400.ms)
                               .slideY(begin: 0.2, end: 0),
                            ),
                            const SizedBox(width: 8),
                            const MoodyCharacter(
                              size: 80,
                              mood: 'happy',
                            ).animate()
                             .scale(duration: 600.ms, curve: Curves.easeOutBack)
                             .fadeIn(duration: 400.ms),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Communication style options
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ListView(
                        children: _communicationStyles.map((style) => _buildStyleCard(style)).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedStyle != null
                          ? () => context.go('/preferences/mood')
                          : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedStyle != null
                            ? const Color(0xFF5BB32A)
                            : Colors.grey.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _selectedStyle != null ? 4 : 0,
                          shadowColor: _selectedStyle != null
                            ? const Color(0xFF5BB32A).withOpacity(0.4)
                            : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
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
                  ),
                ],
              ),
              
              // Debug: Sign In Again button for users who get stuck
              Positioned(
                bottom: 120,
                left: 24,
                child: TextButton(
                  onPressed: () async {
                    // Clear authentication state and start fresh
                    await ref.read(clearAuthProvider)();
                    if (mounted) {
                      context.go('/auth/signup');
                    }
                  },
                  child: Text(
                    'Sign In Again',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
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