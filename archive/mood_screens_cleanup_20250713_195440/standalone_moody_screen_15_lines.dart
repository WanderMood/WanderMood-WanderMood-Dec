import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/screens/mood_home_screen.dart';

class StandaloneMoodyScreen extends ConsumerWidget {
  const StandaloneMoodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: MoodHomeScreen(),
    );
  }
} 