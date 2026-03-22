import 'dart:convert';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/legal_urls.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../home/domain/enums/moody_feature.dart';

/// WanderMood design tokens — magic link signup
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmError = Color(0xFFE05C5C);

/// Magic Link Signup Screen
/// 
/// Simple one-step authentication using email magic links.
/// No password required - just enter email and click the link sent to inbox.
/// 
/// Flow: Splash → Intro → Demo → Guest Explore → **Signup** → Main
class MagicLinkSignupScreen extends ConsumerStatefulWidget {
  const MagicLinkSignupScreen({super.key});

  @override
  ConsumerState<MagicLinkSignupScreen> createState() => _MagicLinkSignupScreenState();
}

class _MagicLinkSignupScreenState extends ConsumerState<MagicLinkSignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  late final AnimationController _breathController;
  late final Animation<double> _breathScale;
  late final AnimationController _ctaPressController;
  late final Animation<double> _ctaScale;
  late final TapGestureRecognizer _privacyTapRecognizer;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _breathScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _ctaPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _ctaScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctaPressController, curve: Curves.easeInOut),
    );

    _privacyTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _openPrivacyPolicyExternal();
      };

    _emailController.addListener(() => setState(() {}));
  }

  Future<void> _openPrivacyPolicyExternal() async {
    try {
      if (await canLaunchUrl(LegalUrls.privacyPolicy)) {
        await launchUrl(LegalUrls.privacyPolicy, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _privacyTapRecognizer.dispose();
    _emailController.dispose();
    _breathController.dispose();
    _ctaPressController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final email = _emailController.text.trim();
      
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.wandermood://auth-callback',
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
        
        // Mark signup started
        ref.read(onboardingProgressProvider.notifier).markSignedUp();
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      // Supabase sometimes returns a JSON string like:
      // {"code":"unexpected_failure","message":"Error sending magic link email"}
      // Parse it and show a friendly, localized error instead of raw JSON.
      String friendlyMessage;
      try {
        final raw = e.message;
        if (raw.isEmpty) {
          friendlyMessage = AppLocalizations.of(context)!.signupErrorGeneric;
        } else {
          final dynamic decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            final code = decoded['code'] as String?;
            final serverMessage = decoded['message'] as String?;

            if (code == 'unexpected_failure') {
              friendlyMessage = AppLocalizations.of(context)!.signupErrorGeneric;
            } else if (serverMessage != null && serverMessage.isNotEmpty) {
              friendlyMessage = serverMessage;
            } else {
              friendlyMessage = AppLocalizations.of(context)!.signupErrorGeneric;
            }
          } else {
            friendlyMessage = AppLocalizations.of(context)!.signupErrorGeneric;
          }
        }
      } catch (_) {
        friendlyMessage = AppLocalizations.of(context)!.signupErrorGeneric;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = friendlyMessage;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)!.signupErrorGeneric;
        });
      }
    }
  }

  String _getEmailButtonLabel() {
    final domain = _emailController.text.trim().split('@').last.toLowerCase();
    if (domain.contains('gmail')) return 'Open Gmail';
    if (domain.contains('outlook') ||
        domain.contains('hotmail') ||
        domain.contains('live') ||
        domain.contains('msn')) {
      return 'Open Outlook';
    }
    if (domain.contains('icloud') ||
        domain.contains('me.com') ||
        domain.contains('mac.com')) {
      return 'Open Apple Mail';
    }
    return 'Open e-mail app';
  }

  Future<void> _openEmailApp() async {
    final email = _emailController.text.trim();
    final domain = email.contains('@')
        ? email.split('@').last.toLowerCase()
        : '';
    Uri uri;
    if (domain.contains('gmail')) {
      uri = Uri.parse('googlegmail://');
    } else if (domain.contains('outlook') ||
        domain.contains('hotmail') ||
        domain.contains('live') ||
        domain.contains('msn')) {
      uri = Uri.parse('ms-outlook://');
    } else if (domain.contains('icloud') ||
        domain.contains('me.com') ||
        domain.contains('mac.com')) {
      uri = Uri.parse('message://');
    } else {
      uri = Uri.parse('mailto:');
    }

    // iOS: canLaunchUrl is false for third-party schemes unless listed in
    // Info.plist; always try launchUrl, then fall back to system Mail.
    Future<bool> tryOpen(Uri u) async {
      try {
        return await launchUrl(u, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }

    if (!await tryOpen(uri)) {
      final fallback = email.isNotEmpty
          ? Uri.parse('mailto:$email')
          : Uri.parse('mailto:');
      await tryOpen(fallback);
    }
  }

  Future<void> _resendMagicLink() async {
    await _sendMagicLink();
  }

  void _goBack() {
    final useNewFlow = ref.read(useNewOnboardingFlowProvider);
    if (useNewFlow) {
      context.go('/guest-explore');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _wmCream,
      body: SafeArea(
        child: _emailSent ? _buildSuccessState() : _buildFormState(),
      ),
    );
  }

  Widget _buildFormState() {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: _wmCharcoal,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _wmCharcoal.withValues(alpha: 0.12),
                            blurRadius: 36,
                            offset: const Offset(0, 16),
                            spreadRadius: -6,
                          ),
                          BoxShadow(
                            color: _wmCharcoal.withValues(alpha: 0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: _wmForest.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            Center(
                              child: ScaleTransition(
                                alignment: Alignment.center,
                                scale: _breathScale,
                                child: const MoodyCharacter(
                                  size: 100,
                                  mood: 'happy',
                                  currentFeature: MoodyFeature.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Word lid van WanderMood',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: _wmCharcoal,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Geen wachtwoord nodig ✨',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: _wmForest,
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 54,
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textCapitalization: TextCapitalization.none,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.email],
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: _wmCharcoal,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'jouw@email.nl',
                                  hintStyle: GoogleFonts.poppins(color: _wmStone),
                                  prefixIcon: const Icon(
                                    Icons.mail_outline,
                                    color: _wmStone,
                                    size: 22,
                                  ),
                                  filled: true,
                                  fillColor: _wmWhite,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                  floatingLabelBehavior: FloatingLabelBehavior.never,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: _wmParchment,
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: _wmParchment,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: _wmForest,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: _wmError,
                                      width: 1,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: _wmError,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.signupEmailRequired;
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return l10n.signupEmailInvalid;
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  if (!_isLoading) _sendMagicLink();
                                },
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _wmError.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _wmError.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: _wmError,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: _wmError,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            ScaleTransition(
                              alignment: Alignment.center,
                              scale: _ctaScale,
                              child: SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          await _ctaPressController.forward();
                                          if (mounted) {
                                            await _ctaPressController.reverse();
                                          }
                                          _sendMagicLink();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _wmForest,
                                    foregroundColor: _wmWhite,
                                    disabledBackgroundColor: _wmForest,
                                    disabledForegroundColor: _wmWhite,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(27),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: _wmWhite,
                                          ),
                                        )
                                      : Text(
                                          '✨ ${l10n.signupSendMagicLink}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: _wmWhite,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '⭐ 4,9/5 • Gratis • Geen wachtwoord',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                height: 1.4,
                                color: _wmStone,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                    ),
                  ),
                    ),
                  ),
                );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _buildNlPrivacyFooter(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNlPrivacyFooter() {
    final base = GoogleFonts.poppins(
      fontSize: 12,
      height: 1.45,
      color: _wmStone,
    );
    final linkStyle = base.copyWith(
      color: _wmForest,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: _wmForest,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(
            text: 'Door verder te gaan ga je akkoord met ons ',
          ),
          TextSpan(
            text: 'privacybeleid',
            style: linkStyle,
            recognizer: _privacyTapRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSuccessState() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Center(
              child: MoodyCharacter(
                size: 120,
                mood: 'happy',
                currentFeature: MoodyFeature.none,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Check je inbox! 📬',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1C18),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'We stuurden een link naar',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4A4640),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _emailController.text.trim(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A6049),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _openEmailApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A6049),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: Text(
                  _getEmailButtonLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendMagicLink,
              child: const Text(
                'Geen e-mail ontvangen?',
                style: TextStyle(color: Color(0xFF8C8780)),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _emailSent = false),
              child: const Text(
                'Verkeerd e-mailadres?',
                style: TextStyle(color: Color(0xFF8C8780)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

