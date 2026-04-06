import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../auth/providers/auth_state_provider.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/l10n/app_localizations.dart';
/// Design system — splash (wmForest background)
const Color _wmForest = Color(0xFF2A6049);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathScale;
  late final AnimationController _fadeOutController;
  late final Animation<double> _fadeOpacity;

  @override
  void initState() {
    super.initState();
    // Light status/nav icons on dark Forest background (use .dark — not .light)
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _wmForest,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _breathScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInOut),
    );

    _initializeApp();
  }

  Future<void> _exitWithFade(VoidCallback navigate) async {
    try {
      await _fadeOutController.forward();
      if (!mounted) return;
      navigate();
    } catch (e, st) {
      debugPrint('⚠️ Splash fade/navigation failed: $e\n$st');
      if (mounted) {
        await _fadeOutController.reverse();
      }
    }
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    debugPrint('🔄 Waiting for Supabase session restoration...');
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;

      if (session != null && user != null) {
        debugPrint('✅ Session restored: ${user.id}');
        debugPrint('✅ Session found and valid, skipping refresh to avoid rate limiting');
        break;
      }
    }

    if (!mounted) return;

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

    if (currentUser != null && currentSession != null && !hasSeenOnboarding) {
      debugPrint('🔧 User has session, marking onboarding as seen');
      await prefs.setBool('has_seen_onboarding', true);

      try {
        final response = await Supabase.instance.client
            .from('user_preferences')
            .select('*')
            .eq('user_id', currentUser.id)
            .maybeSingle();

        if (response != null && response.isNotEmpty) {
          debugPrint('📋 User has preferences in database (may be partial from email verification)');
        }
      } catch (e) {
        debugPrint('📋 Could not check preferences: $e');
      }
    }

    final authState = ref.read(authStateProvider);

    if (authState.isLoading) {
      debugPrint('⏳ Waiting for auth state to load...');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;

    final finalCurrentUser = Supabase.instance.client.auth.currentUser;

    bool finalHasCompletedPreferences = prefs.getBool('hasCompletedPreferences') ?? false;

    if (finalCurrentUser != null && !finalHasCompletedPreferences) {
      try {
        final response = await Supabase.instance.client
            .from('user_preferences')
            .select('has_completed_preferences')
            .eq('user_id', finalCurrentUser.id)
            .maybeSingle();

        if (response != null && response['has_completed_preferences'] == true) {
          finalHasCompletedPreferences = true;
          await prefs.setBool('hasCompletedPreferences', true);
          debugPrint('✅ User has completed preferences in database - synced to local');
        } else {
          finalHasCompletedPreferences = false;
          await prefs.setBool('hasCompletedPreferences', false);
          debugPrint('🆕 User has NOT completed preferences in database - forcing preferences flow');
        }
      } catch (e) {
        debugPrint('⚠️ Could not check preferences from database: $e');
        debugPrint('   Using cached value: $finalHasCompletedPreferences');
      }
    } else if (finalHasCompletedPreferences) {
      debugPrint('⚡ Using cached preferences flag (fast path)');
    }

    final useNewOnboarding = ref.read(useNewOnboardingFlowProvider);
    debugPrint('🚩 Feature flag - useNewOnboarding: $useNewOnboarding');
    debugPrint('🚩 hasSeenOnboarding: $hasSeenOnboarding');
    debugPrint('🚩 finalCurrentUser: ${finalCurrentUser?.id}');
    debugPrint('🚩 finalHasCompletedPreferences: $finalHasCompletedPreferences');

    if (useNewOnboarding && !hasSeenOnboarding) {
      debugPrint('🚀 First time user (NEW FLOW) - navigating to intro');
      await _exitWithFade(() => context.go('/intro'));
      return;
    }

    if (!hasSeenOnboarding) {
      if (useNewOnboarding) {
        debugPrint('🚀 First time user (NEW FLOW) - navigating to intro');
        await _exitWithFade(() => context.go('/intro'));
      } else {
        debugPrint('🚀 First time user (OLD FLOW) - navigating to onboarding');
        await _exitWithFade(() => context.go('/onboarding'));
      }
    } else if (finalCurrentUser == null) {
      if (finalHasCompletedPreferences) {
        debugPrint('🚀 Returning user without session - navigating to magic link');
        await _exitWithFade(() => context.go('/auth/magic-link'));
      } else if (useNewOnboarding) {
        debugPrint('🚀 User not authenticated (NEW FLOW, no preferences yet) - showing new onboarding flow');
        await _exitWithFade(() => context.go('/intro'));
      } else {
        debugPrint('🚀 User not authenticated (OLD FLOW, no preferences yet) - navigating to magic link');
        await _exitWithFade(() => context.go('/auth/magic-link'));
      }
    } else if (!finalHasCompletedPreferences) {
      debugPrint('🚀 User needs to complete preferences - navigating to preferences');
      await _exitWithFade(() => context.go('/preferences/communication'));
    } else {
      final hasCompletedFirstPlan = prefs.getBool('has_completed_first_plan') ?? false;
      final tabIndex = hasCompletedFirstPlan ? 0 : 2;

      debugPrint('🚀 User is ready - navigating to main app');
      debugPrint('📍 First-time user: ${!hasCompletedFirstPlan}, routing to tab: $tabIndex');
      await _exitWithFade(() => context.goNamed('main', extra: {'tab': tabIndex}));
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _wmForest,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _wmForest,
        body: FadeTransition(
          opacity: _fadeOpacity,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Center(
                    child: ScaleTransition(
                      alignment: Alignment.center,
                      scale: _breathScale,
                      child: const MoodyCharacter(
                        size: 140,
                        mood: 'idle',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.appTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.splashPlanYourDayByFeeling,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
