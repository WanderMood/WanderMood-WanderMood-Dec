import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/presentation/widgets/wm_toast.dart';

import '../../../home/domain/enums/moody_feature.dart';
import '../../../home/presentation/widgets/moody_character.dart';

/// Design tokens — email verification
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmSky = Color(0xFFA8C8DC);

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  bool _isResending = false;
  bool _isVerified = false;
  bool _isChecking = true;
  StreamSubscription<AuthState>? _authSubscription;

  late final AnimationController _moodyEntryController;
  late final Animation<double> _moodySlideY;
  late final Animation<double> _moodyFade;

  /// Horizontale sway −3px … +3px, elke 3s, ease-in-out.
  late final AnimationController _swayController;
  late final Animation<Offset> _swayOffset;

  /// Gestaggerde puls (2000ms cyclus); per dot 600ms golf 0.3→1.0→0.3.
  late final AnimationController _dotPulseController;

  @override
  void initState() {
    super.initState();
    _moodyEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _moodySlideY = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _moodyEntryController, curve: Curves.elasticOut),
    );
    _moodyFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moodyEntryController, curve: Curves.easeOut),
    );

    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _swayOffset = Tween<Offset>(
      begin: const Offset(-3, 0),
      end: const Offset(3, 0),
    ).animate(
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOut),
    );

    _dotPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _moodyEntryController.forward();

    _checkVerificationStatus();
    _listenForVerification();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _moodyEntryController.dispose();
    _swayController.dispose();
    _dotPulseController.dispose();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.emailConfirmedAt != null) {
        debugPrint('✅ User is already verified');
        setState(() {
          _isVerified = true;
          _isChecking = false;
        });
        await _proceedToOnboarding();
      } else {
        setState(() {
          _isChecking = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking verification status: $e');
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _listenForVerification() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      final user = session?.user;

      debugPrint('🔐 Auth state change: $event');
      debugPrint('🔐 User: ${user?.id}, Email confirmed: ${user?.emailConfirmedAt}');

      if (event == AuthChangeEvent.signedIn && session != null && user != null) {
        if (user.emailConfirmedAt != null) {
          debugPrint('✅ Email verified! Proceeding to onboarding...');
          setState(() {
            _isVerified = true;
          });
          await _proceedToOnboarding();
        }
      }
    });
  }

  Future<void> _proceedToOnboarding() async {
    try {
      debugPrint('🔄 Checking Supabase session after email verification...');
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        debugPrint('⚠️ No session found after verification, waiting a moment...');
        await Future<void>.delayed(const Duration(milliseconds: 500));

        final newSession = Supabase.instance.client.auth.currentSession;
        if (newSession == null) {
          debugPrint('❌ Still no session after wait, this is an error');
          throw Exception('Session not established after email verification');
        }
        debugPrint('✅ Session found after waiting');
      } else {
        debugPrint('✅ Session already established, no refresh needed');
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not found after email verification');
      }

      if (user.emailConfirmedAt == null) {
        throw Exception('Email not confirmed after verification');
      }

      debugPrint('✅ User authenticated: ${user.id}, Email confirmed: ${user.emailConfirmedAt}');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedPreferences', false);
      await prefs.setInt('last_auth_timestamp', DateTime.now().millisecondsSinceEpoch);
      debugPrint('✅ Auth flags set after email verification');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        context.go('/preferences/communication');
      }
    } catch (e) {
      debugPrint('❌ Error in _proceedToOnboarding: $e');
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Error: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
        emailRedirectTo: 'io.supabase.wandermood://auth-callback',
      );

      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Verification email sent! Please check your inbox.',
          duration: const Duration(seconds: 2),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Failed to resend email: ${e.message}',
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  /// Outlook: live.nl, hotmail, outlook, msn (and *.live.* e.g. live.nl)
  /// Gmail: gmail in domain
  /// Apple: icloud, me.com, mac.com
  /// Else: generic mail app (mailto)
  String? _emailLaunchKind(String email) {
    final parts = email.split('@');
    if (parts.length < 2) return null;
    final domain = parts.last.toLowerCase();

    if (domain.contains('gmail')) return 'gmail';
    if (domain.contains('outlook') ||
        domain.contains('hotmail') ||
        domain.contains('live') ||
        domain.contains('msn')) {
      return 'outlook';
    }
    if (domain.contains('icloud') || domain.contains('me.com') || domain.contains('mac.com')) {
      return 'apple';
    }
    return null;
  }

  String _openEmailButtonLabel() {
    switch (_emailLaunchKind(widget.email)) {
      case 'gmail':
        return 'Open Gmail';
      case 'outlook':
        return 'Open Outlook';
      case 'apple':
        return 'Open Apple Mail';
      default:
        return 'Open e-mail app';
    }
  }

  Future<void> _openEmailApp() async {
    final kind = _emailLaunchKind(widget.email);
    final mailto = Uri.parse('mailto:${widget.email}');
    final Uri uri;
    switch (kind) {
      case 'gmail':
        uri = Uri.parse('googlegmail://');
        break;
      case 'outlook':
        uri = Uri.parse('ms-outlook://');
        break;
      case 'apple':
        uri = Uri.parse('message://');
        break;
      default:
        await launchUrl(mailto, mode: LaunchMode.externalApplication);
        return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(mailto, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(mailto, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  /// Gestaggerde puls: elke 600ms één golf 0.3→1.0→0.3, 200ms verschil tussen dots.
  double _pulsingDotOpacity(int index, double controllerValue) {
    const cycleMs = 2000.0;
    const staggerMs = 200.0;
    const pulseMs = 600.0;
    var t = (controllerValue * cycleMs - index * staggerMs) % cycleMs;
    if (t < 0) t += cycleMs;
    if (t >= pulseMs) return 0.3;
    final x = t / pulseMs;
    return 0.3 + 0.7 * (0.5 - 0.5 * math.cos(x * 2 * math.pi));
  }

  Widget _pulsingDots() {
    return AnimatedBuilder(
      animation: _dotPulseController,
      builder: (context, child) {
        final v = _dotPulseController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: _pulsingDotOpacity(i, v),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _wmSky,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _wmCream,
      body: SafeArea(
        child: _isChecking
            ? const Center(
                child: CircularProgressIndicator(
                  color: _wmForest,
                  strokeWidth: 2,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    if (_isVerified)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _wmForest.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _wmForest.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: _wmForest),
                            const SizedBox(width: 8),
                            Text(
                              'Email verified! Redirecting...',
                              style: GoogleFonts.poppins(
                                color: _wmForest,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Center(
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _moodyEntryController,
                            _swayController,
                          ]),
                          builder: (context, child) {
                            final entryDone = _moodyEntryController.value >= 1.0;
                            return Opacity(
                              opacity: _moodyFade.value,
                              child: Transform.translate(
                                offset: Offset(
                                  entryDone ? _swayOffset.value.dx : 0,
                                  _moodySlideY.value,
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: const MoodyCharacter(
                            size: 120,
                            mood: 'idle',
                            currentFeature: MoodyFeature.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(child: _pulsingDots()),
                      const SizedBox(height: 28),
                      Text(
                        'Check je inbox! 📬',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _wmCharcoal,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'We stuurden een link naar',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.45,
                          color: _wmDusk,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.bold,
                          color: _wmForest,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _openEmailApp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _wmForest,
                            foregroundColor: _wmWhite,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          child: Text(
                            _openEmailButtonLabel(),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _wmWhite,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isResending ? null : _resendVerificationEmail,
                        style: TextButton.styleFrom(
                          foregroundColor: _wmStone,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: _isResending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _wmForest,
                                ),
                              )
                            : Text(
                                'Geen e-mail ontvangen?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _wmStone,
                                ),
                              ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/auth/magic-link');
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: _wmStone,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: Text(
                          'Verkeerd e-mailadres?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _wmStone,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
