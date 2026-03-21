import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

/// Development screen to reset local app state for testing onboarding as a new user.
/// Only available in debug mode — route `/dev/reset-onboarding`.
class ResetOnboardingScreen extends StatelessWidget {
  const ResetOnboardingScreen({super.key});

  static const List<String> _hiveBoxNames = [
    'locations',
    'weather',
    'forecasts',
    'alerts',
    'weather_alerts',
  ];

  static Future<void> _clearHiveBestEffort() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
      for (final name in _hiveBoxNames) {
        try {
          if (Hive.isBoxOpen(name)) {
            await Hive.box(name).close();
          }
        } catch (_) {}
        try {
          await Hive.deleteBoxFromDisk(name);
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Onboarding (Dev Only)'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Reset like a new install',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Signs out of Supabase, clears all SharedPreferences, and deletes '
              'local Hive weather cache. You need this so splash does not '
              'immediately mark onboarding as seen while a session exists.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client.auth.signOut();
                } catch (_) {}

                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                await _clearHiveBestEffort();

                if (context.mounted) {
                  showWanderMoodToast(
                    context,
                    message: 'Signed out and wiped local data. Going to splash…',
                    backgroundColor: Colors.green,
                  );

                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (context.mounted) {
                      context.go('/');
                    }
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Reset & Restart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

