import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/auth/presentation/screens/login_screen.dart';
import 'package:wandermood/features/splash/application/splash_service.dart';
import 'package:go_router/go_router.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/preferences_provider.dart';

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final Color backgroundColor;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.backgroundColor,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Meet Moody 😄',
      subtitle: 'Your travel BFF 💬🌍',
      description: 'Moody gets to know your vibe, your energy, and the kind of day you\'re having. With all that, I create personalized plans — made just for you. Think of me as your fun, curious bestie who\'s always down to explore 🌆🎈',
      backgroundColor: const Color(0xFFFFF4E0), // Cream color from image
    ),
    OnboardingPage(
      title: 'Travel by Mood 🌈',
      subtitle: 'Your Feelings, Your Journey 💭',
      description: 'Whether you\'re in a peaceful, romantic, or adventurous mood... just tell me how you feel, and I\'ll create personalized plans 🌸🏞️\nFrom hidden gems to sunset strolls—mood first, always.',
      backgroundColor: const Color(0xFFFDE5F0), // Light pink from image
    ),
    OnboardingPage(
      title: 'Your Day, Your Way 🫶🏾',
      subtitle: 'Sunrise to sunset, I\'ve got you ☀️🌙',
      description: 'Your plan is broken into moments—morning, afternoon, evening, and night. Choose your vibe, pick your favorites, and I\'ll handle the magic. 🧭🎯 All based on location, time, weather & mood.',
      backgroundColor: const Color(0xFFE7F0FF), // Light blue from image
    ),
    OnboardingPage(
      title: 'Every Day\'s a Mood 🎨',
      subtitle: 'Discover new places - every day🌍',
      description: 'WanderMood makes every day feel like a new adventure. Wake up, check your vibe, explore hand-picked activities 💡📍 Let your mood lead the way—again and again.',
      backgroundColor: const Color(0xFFFFF4E0), // Cream color from image
    ),
  ];

  void _nextPage() async {
    if (_currentPage < pages.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _isLoading = true);
      
      // Only save to SharedPreferences during "Meet Moody" screens
      // Don't save to database yet - user isn't authenticated
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go('/auth/signup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return _buildOnboardingPage(pages[index]);
            },
          ),
          Positioned(
            top: 48,
            right: 16,
            child: TextButton(
              onPressed: () => context.go('/auth/signup'),
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: page.backgroundColor,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Add image for the first onboarding page
            if (page.title == 'Meet Moody 😄') ...[
              const Spacer(flex: 1),
              Center(
                child: Image.asset(
                  'images/Onboarding_meetmoody.png',
                  width: 320,
                  height: 320,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(flex: 1),
            ] else if (page.title == 'Travel by Mood 🌈') ...[
              const Spacer(flex: 1),
              Center(
                child: Image.asset(
                  'images/Onboarding_travelbymood.png',
                  width: 320,
                  height: 320,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(flex: 1),
            ] else if (page.title == 'Your Day, Your Way 🫶🏾') ...[
              const Spacer(flex: 1),
              Center(
                child: Image.asset(
                  'images/Onboarding_yourdayyourway.png',
                  width: 320,
                  height: 320,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(flex: 1),
            ] else if (page.title == 'Every Day\'s a Mood 🎨') ...[
              const Spacer(flex: 1),
              Center(
                child: Image.asset(
                  'images/Onboarding_everydayisamood.png',
                  width: 320,
                  height: 320,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(flex: 1),
            ] else ...[
              // Future image area
              const Spacer(),
            ],
            // Bottom content area with padding
            Container(
              width: double.infinity,
              color: page.backgroundColor,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(left: 32.0, right: 32.0, bottom: 48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        page.title,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ).animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.2, end: 0),
                      const SizedBox(height: 12),
                      Text(
                        page.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ).animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.1, end: 0),
                      const SizedBox(height: 24),
                      Text(
                        page.description,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.black87.withOpacity(0.7),
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                      ).animate()
                        .fadeIn(duration: 600.ms),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(
                              pages.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == index 
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.black.withOpacity(0.2),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFFF9800), // Orange color
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _nextPage,
                              icon: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getButtonColor(Color backgroundColor) {
    // Calculate a contrasting color based on the background
    final brightness = backgroundColor.computeLuminance();
    if (brightness > 0.5) {
      return Colors.black.withOpacity(0.8);
    } else {
      return Colors.white.withOpacity(0.8);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getBackgroundColorForPage(String headerText) {
    switch (headerText) {
      case 'Express mood':
        return const Color(0xFF80DEEA); // Blauw voor Mood
      case 'Plan travel':
        return const Color(0xFF455A64); // Donkergrijs voor Journey
      case 'Explore events':
        // Dit is een speciale case omdat we twee pagina's met dezelfde header hebben
        // We controleren de huidige pagina index
        return _currentPage == 3 
            ? const Color(0xFF000000) // Zwart voor Story (laatste pagina)
            : const Color(0xFF7E57C2); // Paars voor Explore (derde pagina)
      default:
        return Colors.black; // Default fallback
    }
  }
} 