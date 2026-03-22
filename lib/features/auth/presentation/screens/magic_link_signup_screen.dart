import 'dart:convert';

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
import '../../../location/providers/location_provider.dart';

/// WanderMood design tokens — magic link signup
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmSunsetTint = Color(0xFFFDF0E8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmError = Color(0xFFE05C5C);

const List<String> _privacyPhrasePatterns = [
  'politique de confidentialité',
  'política de privacidad',
  'privacy policy',
  'privacybeleid',
  'datenschutz',
];

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

  bool get _hasEmail => _emailController.text.trim().isNotEmpty;

  Widget _buildTermsFooter(AppLocalizations l10n) {
    final base = GoogleFonts.poppins(
      fontSize: 13,
      height: 1.45,
      color: _wmStone,
    );
    final linkStyle = base.copyWith(
      color: _wmForest,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: _wmForest,
    );
    final full = l10n.signupTerms;
    final lower = full.toLowerCase();
    int? idx;
    int len = 0;
    for (final p in _privacyPhrasePatterns) {
      final i = lower.indexOf(p);
      if (i >= 0) {
        idx = i;
        len = p.length;
        break;
      }
    }
    if (idx != null) {
      final start = idx;
      return Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(text: full.substring(0, start)),
            TextSpan(
              text: full.substring(start, start + len),
              style: linkStyle,
              recognizer: _privacyTapRecognizer,
            ),
            if (start + len < full.length) TextSpan(text: full.substring(start + len)),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      full,
      textAlign: TextAlign.center,
      style: base,
    );
  }

  String _signupMetaLine(BuildContext context) {
    final lc = Localizations.localeOf(context).languageCode;
    if (lc == 'nl') return 'Gratis • Geen wachtwoord nodig';
    return 'Free • No password needed';
  }

  Widget _buildFormState() {
    final l10n = AppLocalizations.of(context)!;
    final canSubmit = _hasEmail && !_isLoading;
    final h = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: _wmCharcoal,
                    padding: EdgeInsets.zero,
                  ),
                ),
                SizedBox(
                  height: h * 0.35,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        alignment: Alignment.center,
                        scale: _breathScale,
                        child: const MoodyCharacter(
                          size: 100,
                          mood: 'happy',
                          currentFeature: MoodyFeature.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.signupJoinWanderMood,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _wmCharcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.signupSubtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.45,
                          color: _wmStone,
                        ),
                      ),
                    ],
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                            hintText: l10n.signupEmailHint,
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
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _wmParchment,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _wmParchment,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _wmForest,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _wmError,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
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
                            if (canSubmit) _sendMagicLink();
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
                      const SizedBox(height: 16),
                      ScaleTransition(
                        alignment: Alignment.center,
                        scale: _ctaScale,
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: (_isLoading || !canSubmit)
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
                              disabledBackgroundColor: _wmParchment,
                              disabledForegroundColor: _wmStone,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _wmWhite,
                                    ),
                                  )
                                : Text(
                                    '✨ ${l10n.signupSendMagicLink}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _signupMetaLine(context),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _wmStone,
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildTermsFooter(l10n),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessState() {
    final l10n = AppLocalizations.of(context)!;
    final city = ref.watch(locationNotifierProvider).valueOrNull ?? l10n.signupDefaultCity;
    final minHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        48;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          // Moody character (replaces envelope)
          const Center(
            child: MoodyCharacter(
              size: 100,
              mood: 'happy',
              currentFeature: MoodyFeature.none,
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.signupCheckEmail,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 8),
              Text('📬', style: TextStyle(fontSize: 26, color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.signupWeSentLinkTo,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _emailController.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A6049),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          // Instruction cards (three separate cards with colored left border, real emojis)
          _buildSuccessInstructionCard(
            context,
            emoji: '✅',
            borderColor: _wmForest,
            text: l10n.signupClickLinkInEmail,
          ),
          const SizedBox(height: 10),
          _buildSuccessInstructionCard(
            context,
            emoji: '⏰',
            borderColor: _wmSunset,
            text: l10n.signupLinkExpires,
          ),
          const SizedBox(height: 10),
          _buildSuccessInstructionCard(
            context,
            emoji: '📋',
            borderColor: _wmSky,
            text: l10n.signupCheckSpam,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _wmSunsetTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _wmSunset.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.signupAlmostThereTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _wmCharcoal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.signupAlmostThereBody(city),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.5,
                    color: _wmDusk,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Try again
          TextButton.icon(
            onPressed: () {
              setState(() {
                _emailSent = false;
              });
            },
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2A6049), size: 20),
            label: Text(
              l10n.signupTryAgain,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2A6049),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSuccessInstructionCard(
    BuildContext context, {
    required String emoji,
    required Color borderColor,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: _wmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _wmParchment, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: borderColor),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          height: 1.5,
                          color: _wmCharcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

