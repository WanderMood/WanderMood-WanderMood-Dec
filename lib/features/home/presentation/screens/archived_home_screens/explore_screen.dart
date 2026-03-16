import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/domain/entities/location.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  void _handleLocationSelected(WidgetRef ref, Location location) {
    ref.read(locationNotifierProvider.notifier).getCurrentLocation();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'Explore',
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5BB32A),
            ),
          ),
        ),
      ),
    );
  }
} 