import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/auth/application/auth_service.dart';
import 'package:wandermood/features/home/presentation/screens/mood_home_screen.dart';
import 'package:wandermood/features/home/presentation/screens/main_home_screen.dart';

class WanderMoodApp extends ConsumerStatefulWidget {
  const WanderMoodApp({super.key});

  @override
  ConsumerState<WanderMoodApp> createState() => _WanderMoodAppState();
}

class _WanderMoodAppState extends ConsumerState<WanderMoodApp> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authService = ref.read(authServiceProvider);
    await authService.ensureDemoAccount();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WanderMood',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A6049),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      initialRoute: '/moodHome',
      routes: {
        '/moodHome': (context) => const MoodHomeScreen(),
        '/mainHome': (context) => const MainHomeScreen(),
      },
    );
  }
} 