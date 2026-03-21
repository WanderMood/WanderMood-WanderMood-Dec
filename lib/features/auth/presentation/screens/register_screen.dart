import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../domain/providers/auth_provider.dart';
import '../../application/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    debugPrint('🔥 NEW CODE: Sign up button pressed - LATEST VERSION');
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }
    
    if (!_acceptTerms) {
      debugPrint('Terms not accepted');
      showWanderMoodToast(
        context,
        message: 'Please accept the terms and conditions',
      );
      return;
    }

    if (!mounted) return;
    
    setState(() => _isLoading = true);
    debugPrint('Attempting signup with email: ${_emailController.text.trim()}');
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear any existing preferences to ensure fresh start
      await prefs.clear();
      
      // Set authentication state
      await prefs.setBool('isAuthenticated', true);
      
      // Perform proper Supabase signup with email verification
      debugPrint('🔐 NEW CODE: Starting REAL Supabase signup with email verification - NO BYPASS!');
      
      try {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
          emailRedirectTo: 'io.supabase.wandermood://auth-callback',
        );
        
        debugPrint('📧 Signup response: ${response.user?.id}');
        debugPrint('📧 Signup session: ${response.session?.user?.id}');
        
        if (response.user != null) {
          debugPrint('✅ Signup successful! User ID: ${response.user!.id}');
          debugPrint('📧 Email confirmed: ${response.user!.emailConfirmedAt}');
          debugPrint('📧 Session exists: ${response.session != null}');
          
          final user = response.user!;
          final isEmailVerified = user.emailConfirmedAt != null;
          
          if (mounted) {
            setState(() => _isLoading = false);
            
            if (isEmailVerified && response.session != null) {
              // Email already verified (auto-confirm enabled in Supabase)
              debugPrint('✅ Email already verified, proceeding to onboarding');
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasCompletedPreferences', false);
              
              showWanderMoodToast(
                context,
                message: 'Account created successfully!',
                duration: const Duration(seconds: 2),
              );
              
              // Navigate directly to onboarding
              context.go('/preferences/communication');
            } else {
              // Email verification required
              debugPrint('📧 Email verification required, showing verification screen');
              
              // Only sign out if we have a session but email isn't verified
              // This ensures proper verification flow
              if (response.session != null && !isEmailVerified) {
                debugPrint('🔒 Signing out to enforce email verification');
                await Supabase.instance.client.auth.signOut();
              }
              
              showWanderMoodToast(
                context,
                message: 'Account created! Please check your email at $email to verify your account.',
                duration: const Duration(seconds: 5),
              );
              
              // Navigate to email verification screen
              debugPrint('🚀 Navigating to email verification screen...');
              context.go('/auth/verify-email?email=${Uri.encodeComponent(email)}');
            }
          }
        } else {
          throw Exception('Signup failed: No user returned');
        }
      } on AuthException catch (e) {
        debugPrint('❌ Auth error: ${e.message}');
        if (mounted) {
          setState(() => _isLoading = false);
          
          // Handle "User already registered" case
          if (e.message.contains('User already registered')) {
            // Show more helpful message and redirect to login
            showWanderMoodToast(
              context,
              message: 'This email is already registered. Please sign in instead.',
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            );
            
            // Redirect to login screen after a short delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                context.go('/auth/magic-link');
              }
            });
          } else {
            showWanderMoodToast(
              context,
              message: 'Signup failed: ${e.message}',
              isError: true,
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Unexpected error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          showWanderMoodToast(
            context,
            message: 'Signup failed: $e',
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Exception during signup: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        showWanderMoodToast(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SwirlBackground(
        child: SingleChildScrollView(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF2A6049)),
                    onPressed: () => context.go('/login'),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'Create Account',
                    style: GoogleFonts.museoModerno(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A6049),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 8),
                  Text(
                    'Let\'s get you started on your journey!',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Form Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: const Color(0xFFE6F0FA),
                    shadowColor: Colors.black.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Form fields
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Terms and conditions
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    'I accept the Terms and Conditions',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Register button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2A6049),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.black87),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                  
                  // Add bottom padding to account for system navigation area
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