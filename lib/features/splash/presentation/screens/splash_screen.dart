import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../auth/providers/auth_state_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SwirlingGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create flowing wave gradients with maximum opacity
    final Paint wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFFDF5).withOpacity(0.95),  // Warm cream yellow
          const Color(0xFFFFF3E0).withOpacity(0.85),  // Warm yellow
          const Color(0xFFFFF9E8).withOpacity(0.75),  // Light warm yellow
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

    // Create flowing curves
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

    // Add dots along the waves
    for (int i = 0; i < 15; i++) {
      double x = size.width * (i / 15);
      double y = size.height * (0.3 + math.sin(i * 0.8) * 0.25);
      
      canvas.drawCircle(
        Offset(x, y),
        5,
        wavePaint
      );
    }

    // Draw all elements with blur effect
    canvas.drawPath(mainWavePath, wavePaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawPath(accentWavePath, accentPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for the splash screen animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check current authentication and onboarding status
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final hasCompletedAuth = prefs.getBool('hasCompletedAuth') ?? false;
    final hasCompletedPreferences = prefs.getBool('hasCompletedPreferences') ?? false;
    final currentUser = Supabase.instance.client.auth.currentUser;
    
    debugPrint('🔍 App initialization state:');
    debugPrint('   hasSeenOnboarding: $hasSeenOnboarding');
    debugPrint('   hasCompletedAuth: $hasCompletedAuth');
    debugPrint('   hasCompletedPreferences: $hasCompletedPreferences');
    debugPrint('   currentUser: ${currentUser?.id}');
    
    // Wait for auth state to be available
    final authState = ref.read(authStateProvider);
    
    // If auth state is still loading, wait a bit more
    if (authState.isLoading) {
      debugPrint('⏳ Waiting for auth state to load...');
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    if (!mounted) return;
    
    // Navigate based on current state
    if (!hasSeenOnboarding) {
      debugPrint('🚀 First time user - navigating to onboarding');
      context.go('/onboarding');
    } else if (!hasCompletedAuth || currentUser == null) {
      debugPrint('🚀 User needs authentication - navigating to login');
      context.go('/login');
    } else if (!hasCompletedPreferences) {
      debugPrint('🚀 User needs to complete preferences - navigating to preferences');
      context.go('/preferences/communication');
    } else {
      debugPrint('🚀 User is ready - navigating to standalone mood selection');
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Logo and title
                    Text(
                      'WanderMood',
                      style: GoogleFonts.museoModerno(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5BB32A),
                      ),
                    ).animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),

                    const SizedBox(height: 8),

                    Text(
                      'Your AI Travel Companion',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ).animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),

                    const Spacer(),

                    // Moody character
                    const MoodyCharacter(size: 200)
                      .animate(
                        onPlay: (controller) => controller.repeat(),
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 2000.ms,
                        curve: Curves.easeInOut,
                      ),

                    const Spacer(flex: 2),

                    // Progress indicator
                    Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: const Color(0xFF5BB32A).withOpacity(0.2),
                      ),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BB32A)),
                      ),
                    ).animate()
                      .fadeIn(delay: 600.ms, duration: 600.ms)
                      .slideX(
                        begin: -0.2,
                        end: 0,
                        delay: 600.ms,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      ),

                    const SizedBox(height: 40),
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