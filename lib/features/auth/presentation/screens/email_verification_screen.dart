import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  
  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isVerified = false;
  bool _isChecking = true;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
    _listenForVerification();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Check if user is already verified
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

  /// Listen for email verification completion
  void _listenForVerification() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      final user = session?.user;
      
      debugPrint('🔐 Auth state change: $event');
      debugPrint('🔐 User: ${user?.id}, Email confirmed: ${user?.emailConfirmedAt}');
      
      if (event == AuthChangeEvent.signedIn && session != null && user != null) {
        // Check if email is verified
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

  /// Proceed to onboarding after successful verification
  Future<void> _proceedToOnboarding() async {
    try {
      // CRITICAL: Don't refresh session here - it's already established from deep link
      // Refreshing immediately after email verification can cause rate limiting
      debugPrint('🔄 Checking Supabase session after email verification...');
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session == null) {
        debugPrint('⚠️ No session found after verification, waiting a moment...');
        // Wait a moment for session to be established
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check again
        final newSession = Supabase.instance.client.auth.currentSession;
        if (newSession == null) {
          debugPrint('❌ Still no session after wait, this is an error');
          throw Exception('Session not established after email verification');
        }
        debugPrint('✅ Session found after waiting');
      } else {
        debugPrint('✅ Session already established, no refresh needed');
      }
      
      // Verify user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not found after email verification');
      }
      
      if (user.emailConfirmedAt == null) {
        throw Exception('Email not confirmed after verification');
      }
      
      debugPrint('✅ User authenticated: ${user.id}, Email confirmed: ${user.emailConfirmedAt}');
      
      // Set preferences flag and track auth timestamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedPreferences', false);
      await prefs.setInt('last_auth_timestamp', DateTime.now().millisecondsSinceEpoch);
      debugPrint('✅ Auth flags set after email verification');
      
      // Small delay to ensure flags are persisted
      await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      context.go('/preferences/communication');
      }
    } catch (e) {
      debugPrint('❌ Error in _proceedToOnboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend email: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  size: 60,
                  color: Color(0xFF6C5CE7),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'We\'ve sent a verification link to\n${widget.email}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Click the link in your email to verify your account and continue setting up your travel preferences.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Show loading while checking verification status
              if (_isChecking)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                  ),
                )
              else if (_isVerified)
                // Show success message if already verified
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Email verified! Redirecting...',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Show instructions if not verified
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please verify your email to continue. Check your inbox and click the verification link.',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
              const SizedBox(height: 16),
              
              // SECONDARY ACTION: Resend email button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C5CE7),
                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isResending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                          ),
                        )
                      : const Text(
                          'Resend Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // TERTIARY ACTION: Back to login (text link)
              TextButton(
                onPressed: () => context.go('/auth/magic-link'),
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white60,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Didn\'t receive the email?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Check your spam folder or try resending the verification email.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 