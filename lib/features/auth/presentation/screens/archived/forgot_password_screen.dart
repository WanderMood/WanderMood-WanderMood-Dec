import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Email validatie
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _validateEmail() {
    setState(() {
      if (_emailController.text.isEmpty) {
        _emailError = 'Please enter your email address';
      } else if (!_isValidEmail(_emailController.text)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }
    });
  }

  // Reset wachtwoord functie
  void _sendResetLink() {
    _validateEmail();
    
    if (_emailError == null) {
      setState(() {
        _isLoading = true;
      });
      
      ref.read(authStateProvider.notifier).resetPassword(
        email: _emailController.text,
        onError: (errorMessage) {
          setState(() {
            _isLoading = false;
          });
          
          showWanderMoodToast(context, message: errorMessage, isError: true);
        }, 
        onSuccess: (successMessage) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });
        },
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SwirlBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF2A6049)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Logo
                  Center(
                    child: Text(
                      'WanderMood.',
                      style: GoogleFonts.museoModerno(
                        color: const Color(0xFF2A6049),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Form card
                  _isSuccess ? _buildSuccessCard() : _buildPasswordResetForm(),
                  
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPasswordResetForm() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: const Color(0xFFE6F0FA),
      shadowColor: Colors.black.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Title
            Text(
              'Forgot Your Password?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            
            const SizedBox(height: 10),
            
            // Subtitle
            Text(
              'Enter your email address below and we\'ll send you a link to reset your password',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Email field
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: _emailError != null ? Colors.red.shade400 : Colors.grey.shade300),
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: const Icon(Icons.email, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) {
                  if (_emailError != null) {
                    setState(() {
                      _emailError = null;
                    });
                  }
                },
              ),
            ),
            
            if (_emailError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 12.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _emailError!,
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Send reset link button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendResetLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A6049),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Send Reset Link',
                      style: GoogleFonts.museoModerno(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0, duration: 500.ms);
  }
  
  Widget _buildSuccessCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: const Color(0xFFE6F0FA),
      shadowColor: Colors.black.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            // Success icon
            Icon(
              Icons.check_circle_outline,
              size: 70,
              color: Color(0xFF2A6049),
            ).animate().scale(duration: 400.ms),
            
            const SizedBox(height: 20),
            
            // Success message
            Text(
              'Password Reset Email Sent',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 10),
            
            // Description
            Text(
              'We\'ve sent a password reset link to:\n${_emailController.text}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Back to login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A6049),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Back to Login',
                  style: GoogleFonts.museoModerno(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
} 