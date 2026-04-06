import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';

class OnboardingPage {
  final int pageIndex;
  final String title;
  final String subtitle;
  final String description;
  final Color backgroundColor;

  OnboardingPage({
    required this.pageIndex,
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

  List<OnboardingPage> _pages(AppLocalizations l10n) => [
    OnboardingPage(
      pageIndex: 0,
      title: l10n.onboardingPagerSlide1Title,
      subtitle: l10n.onboardingPagerSlide1Subtitle,
      description: l10n.onboardingPagerSlide1Description,
      backgroundColor: const Color(0xFFFFF4E0),
    ),
    OnboardingPage(
      pageIndex: 1,
      title: l10n.onboardingPagerSlide2Title,
      subtitle: l10n.onboardingPagerSlide2Subtitle,
      description: l10n.onboardingPagerSlide2Description,
      backgroundColor: const Color(0xFFFDE5F0),
    ),
    OnboardingPage(
      pageIndex: 2,
      title: l10n.onboardingPagerSlide3Title,
      subtitle: l10n.onboardingPagerSlide3Subtitle,
      description: l10n.onboardingPagerSlide3Description,
      backgroundColor: const Color(0xFFE7F0FF),
    ),
    OnboardingPage(
      pageIndex: 3,
      title: l10n.onboardingPagerSlide4Title,
      subtitle: l10n.onboardingPagerSlide4Subtitle,
      description: l10n.onboardingPagerSlide4Description,
      backgroundColor: const Color(0xFFFFF4E0),
    ),
  ];

  void _nextPage() async {
    final pages = _pages(AppLocalizations.of(context)!);
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
    final pages = _pages(AppLocalizations.of(context)!);
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
              return _buildOnboardingPage(pages[index], pages.length);
            },
          ),
          Positioned(
            top: 48,
            right: 16,
            child: TextButton(
              onPressed: () async {
                // Set onboarding completion flag before navigating
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('has_seen_onboarding', true);
                if (kDebugMode) {
                  debugPrint('✅ Skip clicked - has_seen_onboarding set to true');
                }
                if (mounted) {
                  context.go('/auth/signup');
                }
              },
              child: Text(
                AppLocalizations.of(context)!.introSkip,
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

  Widget _buildOnboardingPage(OnboardingPage page, int pageCount) {
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
            // Illustration (PNG assets removed from repo — use Moody like app intro).
            if (page.pageIndex >= 0 && page.pageIndex <= 3) ...[
              const Spacer(flex: 1),
              Center(
                child: MoodyCharacter(
                  size: 240,
                  mood: switch (page.pageIndex) {
                    0 => 'idle',
                    1 => 'happy',
                    2 => 'excited',
                    _ => 'relaxed',
                  },
                ),
              ),
              const Spacer(flex: 1),
            ] else ...[
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
                              pageCount,
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