import 'dart:convert';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/legal_urls.dart';
import '../../../../core/services/cached_magic_link_email_service.dart';
import '../../../../features/settings/presentation/providers/user_preferences_provider.dart';
import '../../../../core/utils/legal_url_launcher.dart';
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
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmError = Color(0xFFE05C5C);

/// Pragmatic email check: allows +tags, subdomains, and long TLDs; rejects obvious junk.
bool _looksLikeValidEmail(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value.length > 254) return false;
  if (value.contains(RegExp(r'\s'))) return false;
  final at = value.indexOf('@');
  final lastAt = value.lastIndexOf('@');
  if (at <= 0 || at != lastAt) return false;
  final local = value.substring(0, at);
  final domain = value.substring(at + 1);
  if (local.isEmpty || domain.isEmpty) return false;
  if (!domain.contains('.')) return false;
  if (domain.startsWith('.') || domain.endsWith('.')) return false;
  if (domain.contains('..')) return false;
  return true;
}

List<BoxShadow> _magicLinkCardOuterShadows() => [
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

  static const String _demoEmail = 'demo@wandermood.com';
  static const String _demoPassword = 'WanderMood2025!';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      final cached = CachedMagicLinkEmailService(prefs).getValidEmail();
      if (cached != null && mounted) {
        _emailController.text = cached;
      }
    });
  }

  Future<void> _openPrivacyPolicyExternal() async {
    try {
      final code = Localizations.localeOf(context).languageCode;
      final uri = LegalUrls.privacyForLanguageCode(code);
      await launchExternalLegalUrl(uri);
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
    final form = _formKey.currentState;
    if (form != null) {
      if (!form.validate()) return;
    } else {
      final email = _emailController.text.trim();
      if (!_looksLikeValidEmail(email)) {
        if (mounted && _emailSent) {
          setState(() {
            _emailSent = false;
            _errorMessage = AppLocalizations.of(context)!.signupEmailInvalid;
          });
        }
        return;
      }
    }

    final isResendFromSuccessUi = _emailSent;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final email = _emailController.text.trim();
      // Same language as the app UI (`flutter gen-l10n` / ARB). Supabase Magic Link
      // templates read this as `{{ .Data.language }}` / `{{ .Data.locale }}` (user_metadata).
      final uiLocale = Localizations.localeOf(context);

      // `emailRedirectTo` must appear under Supabase Dashboard → Authentication →
      // URL Configuration (Redirect URLs) together with the app Site URL.
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.wandermood://auth-callback',
        data: {
          'language': uiLocale.languageCode,
          'locale': uiLocale.toLanguageTag(),
        },
      );

      await CachedMagicLinkEmailService(ref.read(sharedPreferencesProvider))
          .remember(email);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
          if (!isResendFromSuccessUi) {
            _emailSent = true;
          }
        });
        if (!isResendFromSuccessUi) {
          ref.read(onboardingProgressProvider.notifier).markSignedUp();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.signupResendLinkSent),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      // Supabase may return JSON in [message] or plain text (rate limits, redirect URL, etc.).
      String friendlyMessage = e.message.trim();
      if (friendlyMessage.isEmpty) {
        friendlyMessage = AppLocalizations.of(context)!.signupErrorGeneric;
      } else {
        final lower = friendlyMessage.toLowerCase();
        if (lower.contains('rate limit') ||
            lower.contains('too many') ||
            lower.contains('email rate limit')) {
          friendlyMessage =
              '${friendlyMessage}\n\nTip: wait a few minutes before requesting another link.';
        }
        try {
          final dynamic decoded = jsonDecode(friendlyMessage);
          if (decoded is Map<String, dynamic>) {
            final serverMessage = (decoded['message'] as String?)?.trim();
            final code = decoded['code'] as String?;
            if (serverMessage != null && serverMessage.isNotEmpty) {
              friendlyMessage = serverMessage;
            } else if (code != null && code.isNotEmpty) {
              friendlyMessage = '$code: ${friendlyMessage}';
            }
          }
        } catch (_) {
          // Keep plain-text [e.message] (e.g. "Invalid Redirect URL").
        }
      }

      setState(() {
        _isLoading = false;
        _errorMessage = friendlyMessage;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Detect email provider from domain for deep linking.
  String? _emailProvider(String email) {
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
    if (domain.contains('icloud') ||
        domain.contains('me.com') ||
        domain.contains('mac.com')) {
      return 'apple';
    }
    return null;
  }

  String _openEmailButtonLabel() {
    final l10n = AppLocalizations.of(context)!;
    switch (_emailProvider(_emailController.text.trim())) {
      case 'gmail':
        return l10n.signupOpenGmail;
      case 'outlook':
        return l10n.signupOpenOutlook;
      case 'apple':
        return l10n.signupOpenAppleMail;
      default:
        return l10n.signupOpenEmailApp;
    }
  }

  Future<void> _openEmailApp() async {
    final email = _emailController.text.trim();
    final provider = _emailProvider(email);
    final mailto = Uri.parse('mailto:$email');

    final Uri uri;
    switch (provider) {
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

  Future<void> _resendMagicLink() async {
    if (_isLoading) return;
    await _sendMagicLink();
  }

  Future<void> _handleDemoLogin() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _demoEmail,
        password: _demoPassword,
      );
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('has_seen_onboarding', true);
      await prefs.setBool('hasCompletedPreferences', true);
      await prefs.setBool('has_completed_first_plan', true);
      if (!mounted) return;
      context.go('/');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.authDemoSignInFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goBack() {
    final useNewFlow = ref.read(useNewOnboardingFlowProvider);
    if (useNewFlow) {
      final mood = ref.read(guestDemoMoodProvider);
      if (mood != null && mood.isNotEmpty) {
        context.go('/guest-day-plan');
      } else {
        context.go('/demo');
      }
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
                        boxShadow: _magicLinkCardOuterShadows(),
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
                              l10n.signupJoinWanderMood,
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
                              l10n.signupNoPasswordNeeded,
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
                                  if (!_looksLikeValidEmail(value)) {
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
                              _magicLinkErrorCard(_errorMessage!),
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
                                          l10n.signupSendMagicLink,
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
                              l10n.signupRatingBadge,
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _handleDemoLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: _wmStone,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'App Store reviewer? Tap here',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _wmStone,
                    ),
                  ),
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

  Widget _magicLinkErrorCard(String message) {
    return Container(
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
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _wmError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNlPrivacyFooter() {
    final l10n = AppLocalizations.of(context)!;
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
          TextSpan(text: l10n.signupPrivacyPrefix),
          TextSpan(
            text: l10n.signupPrivacyLinkLabel,
            style: linkStyle,
            recognizer: _privacyTapRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _inboxFooterActionLink({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _wmForest,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _wmForest,
          decoration: TextDecoration.underline,
          decorationColor: _wmForest,
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final muted = GoogleFonts.poppins(
      fontSize: 14,
      height: 1.4,
      color: _wmStone,
    );

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: _magicLinkCardOuterShadows(),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _wmWhite,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _wmParchment.withValues(alpha: 0.65),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                              l10n.signupSuccessCheckInbox,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: _wmCharcoal,
                                height: 1.25,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.signupSuccessTapLinkSubtitle,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _wmForest,
                                height: 1.35,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _wmForestTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.signupSuccessSentToLine(email),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _wmForest,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 18),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(27),
                                boxShadow: [
                                  BoxShadow(
                                    color: _wmForest.withValues(alpha: 0.32),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: _wmCharcoal.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    _openEmailApp();
                                  },
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
                                    '${_openEmailButtonLabel()} ➡️',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (_errorMessage != null) ...[
                              _magicLinkErrorCard(_errorMessage!),
                              const SizedBox(height: 12),
                            ],
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              alignment: WrapAlignment.center,
                              spacing: 0,
                              runSpacing: 4,
                              children: [
                                Text(l10n.signupInboxFooterPrefix, style: muted),
                                _inboxFooterActionLink(
                                  label: l10n.signupInboxFooterResend,
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          HapticFeedback.lightImpact();
                                          _resendMagicLink();
                                        },
                                ),
                                Text(l10n.signupInboxFooterOr, style: muted),
                                _inboxFooterActionLink(
                                  label: l10n.signupInboxFooterChangeEmail,
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          HapticFeedback.lightImpact();
                                          setState(() {
                                            _emailSent = false;
                                            _errorMessage = null;
                                          });
                                        },
                                ),
                              ],
                            ),
                            if (_isLoading) ...[
                              const SizedBox(height: 10),
                              const Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: _wmForest,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
    );
  }
}

