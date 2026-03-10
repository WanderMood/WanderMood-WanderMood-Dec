import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import '../../../../core/providers/traveler_count_provider.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../home/domain/enums/moody_feature.dart';
import '../../../location/providers/location_provider.dart';

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
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
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
        final dynamic decoded = e.message != null ? jsonDecode(e.message!) : null;
        if (decoded is Map<String, dynamic>) {
          final code = decoded['code'] as String?;
          final serverMessage = decoded['message'] as String?;

          if (code == 'unexpected_failure') {
            // Generic "we couldn't send the email" message
            friendlyMessage = AppLocalizations.of(context)!.signupErrorGeneric;
          } else if (serverMessage != null && serverMessage.isNotEmpty) {
            friendlyMessage = serverMessage;
          } else {
            friendlyMessage = AppLocalizations.of(context)!.signupErrorGeneric;
          }
        } else {
          friendlyMessage = AppLocalizations.of(context)!.signupErrorGeneric;
        }
      } catch (_) {
        // Fallback if message is not JSON
        friendlyMessage = e.message ?? AppLocalizations.of(context)!.signupErrorGeneric;
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
      body: SwirlBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _emailSent ? _buildSuccessState() : _buildFormState(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.grey[700],
            padding: EdgeInsets.zero,
          ),
          
          const SizedBox(height: 32),
          
          // Moody character
          Center(
            child: const MoodyCharacter(
              size: 120,
              mood: 'happy',
              currentFeature: MoodyFeature.none,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Center(
            child: Text(
              AppLocalizations.of(context)!.signupJoinWanderMood,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Center(
            child: Text(
              AppLocalizations.of(context)!.signupSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Form
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Email input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.signupEmailLabel,
                    hintText: AppLocalizations.of(context)!.signupEmailHint,
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.signupEmailRequired;
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return AppLocalizations.of(context)!.signupEmailInvalid;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _sendMagicLink(),
                ),
                
                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Send magic link button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendMagicLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF4CAF50).withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.signupSendMagicLink,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // What you'll unlock + rating & testimonial
          _buildWhatYouUnlock(context),
          
          const SizedBox(height: 24),
          
          // Terms
          Center(
            child: Text(
              AppLocalizations.of(context)!.signupTerms,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTravelersBanner(BuildContext context) {
    final locationAsync = ref.watch(locationNotifierProvider);
    final countAsync = ref.watch(travelerCountProvider);
    final l10n = AppLocalizations.of(context)!;
    final countStr = countAsync.when(
      data: (count) => formatTravelerCount(count),
      loading: () => kFallbackTravelerCountFormatted,
      error: (_, __) => kFallbackTravelerCountFormatted,
    );
    final String bannerText = locationAsync.when(
      data: (city) => city != null && city.isNotEmpty
          ? l10n.signupJoinTravelersInCity(countStr, city)
          : l10n.signupJoinTravelers(countStr),
      loading: () => l10n.signupJoinTravelers(countStr),
      error: (_, __) => l10n.signupJoinTravelers(countStr),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            children: [
              const TextSpan(text: '🧑 ✈️ '),
              TextSpan(text: bannerText),
            ],
          ),
        ),
      ),
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
                color: Color(0xFF4CAF50),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          // Instruction cards (three separate cards with colored left border, real emojis)
          _buildSuccessInstructionCard(
            context,
            emoji: '✅',
            iconColor: const Color(0xFF4CAF50),
            borderColor: const Color(0xFF4CAF50),
            text: l10n.signupClickLinkInEmail,
          ),
          const SizedBox(height: 10),
          _buildSuccessInstructionCard(
            context,
            emoji: '⏰',
            iconColor: Colors.amber[700]!,
            borderColor: Colors.amber[700]!,
            text: l10n.signupLinkExpires,
          ),
          const SizedBox(height: 10),
          _buildSuccessInstructionCard(
            context,
            emoji: '📁',
            iconColor: Colors.blue[600]!,
            borderColor: Colors.blue[600]!,
            text: l10n.signupCheckSpam,
          ),
          const SizedBox(height: 20),
          // "You're almost there!" card – gradient, title + body, pink star
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFF0F5), // light pink
                  Color(0xFFFFF8E7), // light peach / warm yellow
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFB6C1), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_outline, color: Colors.pink[400], size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.signupAlmostThereTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    l10n.signupAlmostThereBody(city),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w400,
                    ),
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
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4CAF50), size: 20),
            label: Text(
              l10n.signupTryAgain,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF4CAF50),
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
    required Color iconColor,
    required Color borderColor,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatYouUnlock(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationAsync = ref.watch(locationNotifierProvider);
    final defaultCity = l10n.signupDefaultCity;
    final testimonialCity = locationAsync.when(
      data: (c) => c ?? defaultCity,
      loading: () => defaultCity,
      error: (_, __) => defaultCity,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.signupWhatYouUnlock,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ),
        ),
        _buildUnlockCard(context, '🎯', const Color(0xFFFF9800), l10n.signupUnlockPersonalized),
        const SizedBox(height: 10),
        _buildUnlockCard(context, '📍', const Color(0xFFFFC107), l10n.signupUnlockFavorites),
        const SizedBox(height: 10),
        _buildUnlockCard(context, '📅', const Color(0xFF4CAF50), l10n.signupUnlockDayPlans),
        const SizedBox(height: 10),
        _buildUnlockCard(context, '✨', const Color(0xFF673AB7), l10n.signupUnlockMoodMatching),
        const SizedBox(height: 12),
        _buildRatingTestimonialCard(context, l10n, testimonialCity),
      ],
    );
  }

  Widget _buildUnlockCard(BuildContext context, String emoji, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 22),
        ],
      ),
    );
  }

  Widget _buildRatingTestimonialCard(BuildContext context, AppLocalizations l10n, String testimonialCity) {
    const green = Color(0xFF4CAF50);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber[700], size: 22),
                  const SizedBox(width: 6),
                  Text(
                    l10n.signupRating,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.favorite_rounded, color: Colors.red[400], size: 22),
                  const SizedBox(width: 6),
                  Text(
                    l10n.signupLoveIt,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${l10n.signupTestimonial}"',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.signupTestimonialBy(testimonialCity),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

