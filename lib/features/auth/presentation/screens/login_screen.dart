import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/auth/application/social_auth_service.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  static const String _demoEmail = 'demo@wandermood.com';
  static const String _demoPassword = 'WanderMood2025!';

  @override
  void initState() {
    super.initState();
    _loadRememberMeState();
  }

  Future<void> _loadRememberMeState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  Future<void> _saveRememberMeState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
    if (kDebugMode) {
      debugPrint('💾 Remember Me state saved: $value');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _validateInputs(AppLocalizations l10n) {
    setState(() {
      if (_emailController.text.isEmpty) {
        _emailError = l10n.authEmailRequired;
      } else if (!_isValidEmail(_emailController.text)) {
        _emailError = l10n.authEmailInvalid;
      } else {
        _emailError = null;
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = l10n.authPasswordRequired;
      } else {
        _passwordError = null;
      }
    });
  }

  Future<void> _postLoginSuccess() async {
    if (!mounted) return;

    // Track auth timestamp for router cache clearing logic
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_auth_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
    debugPrint('✅ Login successful');

    // CRITICAL: Check database for completed preferences to avoid re-onboarding
    // When user logs out, local SharedPreferences is cleared, but database isn't
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('user_preferences')
            .select('has_completed_preferences')
            .eq('user_id', user.id)
            .maybeSingle();

        if (response != null && response['has_completed_preferences'] == true) {
          // User has completed preferences in database - sync to local
          await prefs.setBool('hasCompletedPreferences', true);
          debugPrint('✅ Synced preferences completion from database');
        } else {
          debugPrint('ℹ️ User has not completed preferences');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Could not check preferences: $e');
      // Non-critical - router will handle redirect
    }

    // Let the router handle redirect logic
    // Router will check both local flag and database
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _handleDemoLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _demoEmail,
        password: _demoPassword,
      );
      await _postLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.authDemoSignInFailed,
        isError: true,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    final l10n = AppLocalizations.of(context)!;
    _validateInputs(l10n);
    if (_emailError != null || _passwordError != null) {
      return;
    }
    setState(() => _isLoading = true);
    try {
        await ref.read(authStateProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          onSuccess: () async {
            await _postLoginSuccess();
          },
          onError: (error) {
            if (mounted) {
              showWanderMoodToast(
                context,
                message: error,
                isError: true,
              );
            }
          },
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialSignIn(Future<AuthResponse?> Function() signInMethod) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      print('🔍 Social Sign-In: Starting authentication...');
      final result = await signInMethod();
      
      if (result != null && result.user != null) {
        print('✅ Social Sign-In: Authentication successful');
        if (mounted) {
          // Track auth timestamp for router cache clearing logic
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('last_auth_timestamp', DateTime.now().millisecondsSinceEpoch);
          debugPrint('✅ Social login successful');
          
          // Let the router handle redirect logic instead of directly going to home
          context.go('/');
        }
      } else {
        print('❌ Social Sign-In: Authentication failed - no user returned');
        if (mounted) {
          showWanderMoodToast(
            context,
            message: l10n.authSignInCancelledOrFailed,
            backgroundColor: Colors.orange.shade400,
          );
        }
      }
    } catch (e) {
      print('❌ Social Sign-In Error: $e');
      if (mounted) {
        var errorMessage = l10n.authSignInFailedGeneric;
        if (e.toString().contains('not configured')) {
          errorMessage = l10n.authSocialLoginNotConfigured;
        } else if (e.toString().contains('cancelled')) {
          errorMessage = l10n.authSignInCancelledShort;
        } else if (e.toString().contains('network')) {
          errorMessage = l10n.authNetworkErrorCheckConnection;
        } else if (e.toString().contains('GoogleService-Info.plist')) {
          errorMessage = l10n.authGoogleSignInIncomplete;
        } else if (e.toString().contains('Facebook App ID')) {
          errorMessage = l10n.authFacebookSignInIncomplete;
        }
        
        showWanderMoodToast(
          context,
          message: errorMessage,
          isError: true,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 54,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: FaIcon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: 600.ms, duration: 300.ms)
      .slideY(begin: 0.2, end: 0, delay: 600.ms, duration: 300.ms);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SwirlBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  // App name
                  Center(
                    child: Text(
                      'WanderMood.',
                      style: GoogleFonts.museoModerno(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2A6049),
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Floating form card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: const Color(0xFFE6F0FA),
                    shadowColor: Colors.black.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sign in text
                            Center(
                              child: Text(
                                l10n.authSignInHeadline,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: l10n.signupEmailLabel,
                                prefixIcon: const Icon(Icons.email_outlined),
                                errorText: _emailError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: l10n.authPasswordLabel,
                                prefixIcon: const Icon(Icons.lock_outline),
                                errorText: _passwordError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Remember me & Forgot password
                            Row(
                              children: [
                                // Remember me
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) async {
                                        final newValue = value ?? false;
                                        setState(() {
                                          _rememberMe = newValue;
                                        });
                                        await _saveRememberMeState(newValue);
                                      },
                                    ),
                                    Text(l10n.authRememberMe),
                                  ],
                                ),
                                
                                const Spacer(),
                                
                                // Forgot password
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(l10n.authForgotPassword),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2A6049),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        l10n.authLoginCta,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.authOrContinueWith,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(
                                  icon: FontAwesomeIcons.google,
                                  iconColor: Colors.red,
                                  onPressed: () => _handleSocialSignIn(
                                    () => ref.read(socialAuthServiceProvider).signInWithGoogle(),
                                  ),
                                ),
                                _buildSocialButton(
                                  icon: FontAwesomeIcons.apple,
                                  iconColor: Colors.black,
                                  onPressed: () => _handleSocialSignIn(
                                    () => ref.read(socialAuthServiceProvider).signInWithApple(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.authNoAccount,
                        style: GoogleFonts.poppins(color: Colors.black87),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          l10n.authRegisterCta,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF2A6049),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // App Store review helper (subtle)
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleDemoLogin,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.authReviewerHint,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 