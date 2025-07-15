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

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      
      debugPrint('🔐 Auth state change: $event');
      debugPrint('🔐 Session: ${session?.user?.id}');
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        debugPrint('✅ Email verified! Setting auth completion flag...');
        
        // Set auth completion flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasCompletedAuth', true);
        debugPrint('✅ hasCompletedAuth flag set after email verification');
        
        if (mounted) {
          context.go('/preferences/communication');
        }
      }
    });
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
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend email: ${e.message}'),
            backgroundColor: Colors.red,
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
              
              // Resend button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isResending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Resend Verification Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue button (since email confirmation might be disabled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    debugPrint('🚀 Manual continue - checking if user can proceed to preferences');
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('hasCompletedAuth', true);
                    await prefs.setBool('hasCompletedOnboarding', false);
                    await prefs.setBool('hasCompletedPreferences', false);
                    debugPrint('✅ hasCompletedAuth flag set manually');
                    
                    if (mounted) {
                      context.go('/preferences/communication');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C5CE7),
                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue to App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Back to login
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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