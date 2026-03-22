import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
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

  late final AnimationController _envelopePulseController;
  late final Animation<double> _envelopeScale;

  late final AnimationController _lookController;
  late final Animation<double> _lookTurn;

  late final AnimationController _dotPulseController;

  bool _titleVisible = false;
  bool _subtitleVisible = false;
  bool _buttonVisible = false;
  bool _linksVisible = false;

  @override
  void initState() {
    super.initState();
    _moodyEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _moodySlideY = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _moodyEntryController, curve: Curves.easeOut),
    );
    _moodyFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moodyEntryController, curve: Curves.easeOut),
    );

    _envelopePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _envelopeScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _envelopePulseController,
        curve: Curves.easeInOut,
      ),
    );

    _lookController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _lookTurn = Tween<double>(begin: -3 * math.pi / 180, end: 3 * math.pi / 180)
        .animate(
      CurvedAnimation(parent: _lookController, curve: Curves.easeInOut),
    );

    _dotPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _moodyEntryController.forward();
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _titleVisible = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _subtitleVisible = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _buttonVisible = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _linksVisible = true);
    });

    _checkVerificationStatus();
    _listenForVerification();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _moodyEntryController.dispose();
    _envelopePulseController.dispose();
    _lookController.dispose();
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

  String? _emailProviderName(String email) {
    final parts = email.split('@');
    if (parts.length < 2) return null;
    final domain = parts.last.toLowerCase();
    if (domain.contains('gmail')) return 'Gmail';
    if (domain.contains('outlook') ||
        domain.contains('hotmail') ||
        domain.contains('live') ||
        domain.contains('msn')) {
      return 'Outlook';
    }
    if (domain.contains('yahoo')) return 'Yahoo Mail';
    if (domain.contains('icloud') || domain.contains('me.com') || domain.contains('mac.com')) {
      return 'Apple Mail';
    }
    return null;
  }

  String _openEmailButtonLabel(AppLocalizations l10n) {
    final p = _emailProviderName(widget.email);
    if (p == 'Gmail') return 'Open Gmail';
    if (p == 'Outlook') return 'Open Outlook';
    if (p == 'Yahoo Mail') return 'Open Yahoo Mail';
    if (p == 'Apple Mail') return 'Open Apple Mail';
    return 'Open email app';
  }

  Future<void> _openEmailApp() async {
    final p = _emailProviderName(widget.email);
    final mailto = Uri.parse('mailto:${widget.email}');
    Uri uri;
    switch (p) {
      case 'Gmail':
        uri = Uri.parse('googlegmail://');
        break;
      case 'Outlook':
        uri = Uri.parse('ms-outlook://');
        break;
      case 'Apple Mail':
        uri = Uri.parse('message://');
        break;
      case 'Yahoo Mail':
        uri = Uri.parse('ymail://');
        break;
      default:
        uri = mailto;
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

  String _wrongEmailLabel(BuildContext context) {
    final lc = Localizations.localeOf(context).languageCode;
    switch (lc) {
      case 'nl':
        return 'Verkeerd e-mailadres?';
      case 'de':
        return '← Falsche E-Mail?';
      case 'fr':
        return '← Mauvaise adresse e-mail ?';
      case 'es':
        return '← ¿Correo incorrecto?';
      default:
        return '← Wrong email address?';
    }
  }

  String _noEmailReceivedLabel(BuildContext context) {
    final lc = Localizations.localeOf(context).languageCode;
    if (lc == 'nl') return 'Geen e-mail ontvangen?';
    return 'Didn\'t get an email?';
  }

  Widget _typingDots() {
    return AnimatedBuilder(
      animation: _dotPulseController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = _dotPulseController.value * 2 * math.pi + (i * 2 * math.pi / 3);
            final s = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(t));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: s,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _wmStone,
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
    final l10n = AppLocalizations.of(context)!;

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
                    const SizedBox(height: 8),
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
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _moodyEntryController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _moodyFade.value,
                            child: Transform.translate(
                              offset: Offset(0, _moodySlideY.value),
                              child: AnimatedBuilder(
                                animation: _lookController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _lookTurn.value,
                                    child: Column(
                                      children: [
                                        const MoodyCharacter(
                                          size: 110,
                                          mood: 'idle',
                                          currentFeature: MoodyFeature.none,
                                        ),
                                        const SizedBox(height: 8),
                                        _typingDots(),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      ScaleTransition(
                        scale: _envelopeScale,
                        child: const Center(
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            size: 52,
                            color: _wmForest,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedOpacity(
                        opacity: _titleVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          '${l10n.signupCheckEmail} 📬',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: _wmCharcoal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedOpacity(
                        opacity: _subtitleVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            Text(
                              l10n.signupWeSentLinkTo,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                height: 1.5,
                                color: _wmDusk,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.email,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                height: 1.45,
                                fontWeight: FontWeight.bold,
                                color: _wmForest,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      AnimatedOpacity(
                        opacity: _buttonVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: SizedBox(
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
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              _openEmailButtonLabel(l10n),
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedOpacity(
                        opacity: _linksVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            TextButton(
                              onPressed:
                                  _isResending ? null : _resendVerificationEmail,
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
                                      _noEmailReceivedLabel(context),
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _wmForest,
                                      ),
                                    ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.go('/auth/magic-link'),
                              child: Text(
                                _wrongEmailLabel(context),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _wmForest,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
