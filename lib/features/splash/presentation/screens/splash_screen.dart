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
    
    // Wait for Supabase to restore session from secure storage
    // This is critical on hot restart - Supabase needs time to restore the session
    // CRITICAL: After email verification, app restarts and session needs more time to restore
    debugPrint('🔄 Waiting for Supabase session restoration...');
    for (int i = 0; i < 20; i++) { // Increased from 10 to 20 (4 seconds total)
      await Future.delayed(const Duration(milliseconds: 200));
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;
      
      if (session != null && user != null) {
        debugPrint('✅ Session restored: ${user.id}');
        // CRITICAL: Don't refresh session here - causes rate limiting during onboarding
        // Session is already valid if we found it, no need to refresh constantly
        debugPrint('✅ Session found and valid, skipping refresh to avoid rate limiting');
        break;
      }
    }
    
    if (!mounted) return;
    
    // Check current authentication and onboarding status
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final hasCompletedPreferences = prefs.getBool('hasCompletedPreferences') ?? false;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentSession = Supabase.instance.client.auth.currentSession;
    
    debugPrint('🔍 App initialization state:');
    debugPrint('   hasSeenOnboarding: $hasSeenOnboarding');
    debugPrint('   hasCompletedPreferences: $hasCompletedPreferences');
    debugPrint('   currentUser: ${currentUser?.id}');
    debugPrint('   currentSession: ${currentSession != null}');
    
    // If we have a session, mark onboarding as seen
    if (currentUser != null && currentSession != null && !hasSeenOnboarding) {
      debugPrint('🔧 User has session, marking onboarding as seen');
      await prefs.setBool('has_seen_onboarding', true);
      
      // CRITICAL: Don't auto-mark preferences as completed just because they exist in DB
      // Preferences are saved during email verification (basic communication prefs),
      // but onboarding completion should only be set after the full onboarding flow
      try {
        final response = await Supabase.instance.client
            .from('user_preferences')
            .select('*')
            .eq('user_id', currentUser.id)
            .maybeSingle();
        
        if (response != null && response.isNotEmpty) {
          debugPrint('📋 User has preferences in database (may be partial from email verification)');
          // Don't set hasCompletedPreferences here - let onboarding_loading_screen.dart handle it
        }
      } catch (e) {
        debugPrint('📋 Could not check preferences: $e');
      }
    }
    
    // Wait for auth state to be available
    final authState = ref.read(authStateProvider);
    
    // If auth state is still loading, wait a bit more
    if (authState.isLoading) {
      debugPrint('⏳ Waiting for auth state to load...');
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    if (!mounted) return;
    
    // Re-check after sync
    final finalCurrentUser = Supabase.instance.client.auth.currentUser;
    final finalHasCompletedPreferences = prefs.getBool('hasCompletedPreferences') ?? false;
    
    // Navigate based on current state
    // SIMPLIFIED: Only check Supabase auth + preferences flag
    if (!hasSeenOnboarding) {
      debugPrint('🚀 First time user - navigating to onboarding');
      context.go('/onboarding');
    } else if (finalCurrentUser == null) {
      debugPrint('🚀 User not authenticated - navigating to login');
      context.go('/login');
    } else if (!finalHasCompletedPreferences) {
      debugPrint('🚀 User needs to complete preferences - navigating to preferences');
      context.go('/preferences/communication');
    } else {
      // User has completed preferences - check if first-time user
      final hasCompletedFirstPlan = prefs.getBool('has_completed_first_plan') ?? false;
      final tabIndex = hasCompletedFirstPlan ? 0 : 2; // My Day (0) or Moody Hub (2)
      
      debugPrint('🚀 User is ready - navigating to main app');
      debugPrint('📍 First-time user: ${!hasCompletedFirstPlan}, routing to tab: $tabIndex');
      context.goNamed('main', extra: {'tab': tabIndex});
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