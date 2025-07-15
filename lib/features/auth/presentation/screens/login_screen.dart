import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/auth/application/social_auth_service.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/auth/application/auth_service.dart';
import 'package:wandermood/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:wandermood/features/auth/presentation/screens/register_screen.dart' as register;
import 'package:wandermood/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _validateInputs() {
    setState(() {
      // Email validation
      if (_emailController.text.isEmpty) {
        _emailError = 'Please enter your email address';
      } else if (!_isValidEmail(_emailController.text)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }

      // Password validation
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Please enter your password';
      } else {
        _passwordError = null;
      }
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authStateProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          onSuccess: () async {
            if (mounted) {
              // Set auth completion flag
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasCompletedAuth', true);
              debugPrint('✅ Login successful, hasCompletedAuth flag set');
              
              // Let the router handle redirect logic instead of directly going to home
              // The router will check preferences completion and redirect accordingly
              context.go('/');
            }
          },
          onError: (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error)),
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
  }

  Future<void> _handleSocialSignIn(Future<AuthResponse?> Function() signInMethod) async {
    setState(() => _isLoading = true);
    try {
      print('🔍 Social Sign-In: Starting authentication...');
      final result = await signInMethod();
      
      if (result != null && result.user != null) {
        print('✅ Social Sign-In: Authentication successful');
        if (mounted) {
          // Set auth completion flag for social sign-in
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasCompletedAuth', true);
          debugPrint('✅ Social login successful, hasCompletedAuth flag set');
          
          // Let the router handle redirect logic instead of directly going to home
          context.go('/');
        }
      } else {
        print('❌ Social Sign-In: Authentication failed - no user returned');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign-in was cancelled or failed. Please try again.'),
              backgroundColor: Colors.orange.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Social Sign-In Error: $e');
      if (mounted) {
        String errorMessage = 'Sign-in failed. Please try again.';
        
        // Customize error message based on error type
        if (e.toString().contains('not configured')) {
          errorMessage = 'Social login is not configured yet. Please use email/password for now.';
        } else if (e.toString().contains('cancelled')) {
          errorMessage = 'Sign-in was cancelled.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('GoogleService-Info.plist')) {
          errorMessage = 'Google Sign-In setup incomplete. Please use email/password for now.';
        } else if (e.toString().contains('Facebook App ID')) {
          errorMessage = 'Facebook Sign-In setup incomplete. Please use email/password for now.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
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
                        color: const Color(0xFF4CAF50),
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
                                'Sign in to your account',
                                style: TextStyle(
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
                                labelText: 'Email',
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
                                labelText: 'Password',
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
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                    const Text('Remember me'),
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
                                  child: const Text('Forgot Password?'),
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
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
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
                                const Text(
                                  'or continue with',
                                  style: TextStyle(
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
                                  icon: FontAwesomeIcons.facebook,
                                  iconColor: const Color(0xFF1877F2),
                                  onPressed: () => _handleSocialSignIn(
                                    () => ref.read(socialAuthServiceProvider).signInWithFacebook(),
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
                        "Don't have an account? ",
                        style: GoogleFonts.poppins(color: Colors.black87),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'Register',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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