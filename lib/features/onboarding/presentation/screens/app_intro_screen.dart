import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/feature_flags_provider.dart';

/// Three-Word Intro Screen
/// 
/// This is the first screen in the new onboarding flow.
/// It displays a quick value proposition in three words with beautiful animation.
/// 
/// Flow: Splash → **Intro** → Demo → Guest Explore → Signup → Main
class AppIntroScreen extends ConsumerStatefulWidget {
  const AppIntroScreen({super.key});

  @override
  ConsumerState<AppIntroScreen> createState() => _AppIntroScreenState();
}

class _AppIntroScreenState extends ConsumerState<AppIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation1;
  late Animation<Offset> _slideAnimation2;
  late Animation<Offset> _slideAnimation3;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    // Slide animations for each word (staggered)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideAnimation1 = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));
    
    _slideAnimation2 = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));
    
    _slideAnimation3 = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    ));
    
    // Subtle pulse for the Moody character
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onContinue() {
    // Mark intro as seen
    ref.read(onboardingProgressProvider.notifier).markIntroSeen();
    ref.read(currentOnboardingStepProvider.notifier).state = OnboardingStep.demo;
    
    // Navigate to demo screen
    context.go('/demo');
  }

  void _onSkip() {
    // Skip to signup directly
    context.go('/auth/magic-link');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Warm gradient background matching app theme
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8E1), // Warm cream
              Color(0xFFFFE0B2), // Soft orange
              Color(0xFFFFF3E0), // Light peach
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Skip button at top right
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: _onSkip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Moody character with pulse animation
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🌟',
                        style: TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Three words - staggered animation
                SlideTransition(
                  position: _slideAnimation1,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Mood-Based',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        color: Colors.grey[800],
                        letterSpacing: 2,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                SlideTransition(
                  position: _slideAnimation2,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Travel',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                        letterSpacing: 3,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                SlideTransition(
                  position: _slideAnimation3,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Buddy',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        color: Colors.grey[800],
                        letterSpacing: 2,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Subtle tagline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Your vibe. Your day. Your adventure.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // Continue button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'See How It Works',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Page indicator dots (showing we're on step 1 of 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(isActive: true),
                    const SizedBox(width: 8),
                    _buildDot(isActive: false),
                    const SizedBox(width: 8),
                    _buildDot(isActive: false),
                  ],
                ),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.orange[600] : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

