import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import '../../../home/presentation/widgets/moody_character.dart';

/// Post–magic-link welcome (wmForest) — kort scherm vóór onboarding of hoofdapp.
const Color _wmForest = Color(0xFF2A6049);

/// Toont ~1800 ms na succesvolle magic-link verificatie, daarna router-consistente bestemming.
class AuthWelcomeScreen extends StatefulWidget {
  const AuthWelcomeScreen({super.key});

  @override
  State<AuthWelcomeScreen> createState() => _AuthWelcomeScreenState();
}

class _AuthWelcomeScreenState extends State<AuthWelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _entryScale;
  late final Animation<double> _entryOpacity;

  late final AnimationController _textController;
  late final Animation<double> _textOpacity;

  late final AnimationController _progressController;
  late final Animation<double> _progress;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _wmForest,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );
    _entryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _textOpacity = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _progress = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _entryController.forward();
    _progressController.forward();

    _entryController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _textController.forward();
      }
    });

    Future<void>.delayed(const Duration(milliseconds: 1800), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted || _navigated) return;
    _navigated = true;

    final prefs = await SharedPreferences.getInstance();
    var completed = prefs.getBool('hasCompletedPreferences') ?? false;
    final user = Supabase.instance.client.auth.currentUser;

    if (!completed && user != null) {
      try {
        final response = await Supabase.instance.client
            .from('user_preferences')
            .select('has_completed_preferences')
            .eq('user_id', user.id)
            .maybeSingle();
        if (response != null && response['has_completed_preferences'] == true) {
          completed = true;
          await prefs.setBool('hasCompletedPreferences', true);
        }
      } catch (_) {
        // Zelfde patroon als router: bij fout lokale cache gebruiken
      }
    }

    if (!mounted) return;
    if (completed) {
      context.go('/main');
    } else {
      context.go('/preferences/communication');
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _wmForest,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _wmForest,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _entryOpacity,
                    child: ScaleTransition(
                      alignment: Alignment.center,
                      scale: _entryScale,
                      child: const MoodyCharacter(
                        size: 120,
                        mood: 'idle',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Text(
                      l10n.authWelcomeTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (context, child) {
                      return SizedBox(
                        width: 160,
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Stack(
                            children: [
                              Container(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: _progress.value.clamp(0.0, 1.0),
                                  child: Container(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
