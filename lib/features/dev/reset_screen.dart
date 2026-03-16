import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/services/secure_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetScreen extends ConsumerStatefulWidget {
  const ResetScreen({super.key});

  @override
  ConsumerState<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends ConsumerState<ResetScreen> {
  bool _isResetting = false;
  String _status = '';
  
  Future<void> _resetApp() async {
    setState(() {
      _isResetting = true;
      _status = 'Resetting app data...';
    });
    
    try {
      final secure = SecureStorageService();
      await secure.clearAuthSensitive();
      await secure.setHasSeenOnboarding(false);
      await secure.setHasCompletedPreferences(false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      setState(() {
        _status = 'All preferences cleared successfully!';
      });
      
      // Wait a moment before navigating
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        // Navigate to onboarding to start the flow from the beginning
        context.go('/onboarding');
      }
    } catch (e) {
      setState(() {
        _status = 'Error during reset: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'App Flow Testing',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Use this screen to reset app preferences and test the full onboarding flow.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isResetting ? null : _resetApp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _isResetting ? 'Resetting...' : 'Reset & Start Flow',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              if (_status.isNotEmpty)
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _status.contains('Error') ? Colors.red : Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 