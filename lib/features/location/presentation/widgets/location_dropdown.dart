import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/location/providers/location_provider.dart';
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationDropdown extends ConsumerWidget {
  const LocationDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationNotifierProvider);

    // Set Barendrecht as default location after build cycle completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        if (locationAsync.valueOrNull == null || locationAsync.value != 'Barendrecht') {
          ref.read(locationNotifierProvider.notifier).setCity('Barendrecht');
        }
      });
    });

    return locationAsync.when(
      data: (location) => PopupMenuButton<String>(
        position: PopupMenuPosition.under,
        offset: const Offset(0, 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onSelected: (String cityName) {
          // If user selects "Current Location", get the actual location
          if (cityName == 'Current Location') {
            ref.read(locationNotifierProvider.notifier).getCurrentLocation();
          } else {
            // Otherwise, set the manually selected city
            ref.read(locationNotifierProvider.notifier).setCity(cityName);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'Current Location',
            child: Row(
              children: [
                const Icon(Icons.my_location, size: 18),
                const SizedBox(width: 8),
                Text('Current Location', style: GoogleFonts.poppins()),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'Barendrecht',
            child: Row(
              children: [
                const Icon(Icons.location_city, size: 18),
                const SizedBox(width: 8),
                Text('Barendrecht', style: GoogleFonts.poppins()),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'Rotterdam',
            child: Row(
              children: [
                const Icon(Icons.location_city, size: 18),
                const SizedBox(width: 8),
                Text('Rotterdam', style: GoogleFonts.poppins()),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'Amsterdam',
            child: Row(
              children: [
                const Icon(Icons.location_city, size: 18),
                const SizedBox(width: 8),
                Text('Amsterdam', style: GoogleFonts.poppins()),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'Utrecht',
            child: Row(
              children: [
                const Icon(Icons.location_city, size: 18),
                const SizedBox(width: 8),
                Text('Utrecht', style: GoogleFonts.poppins()),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'The Hague',
            child: Row(
              children: [
                const Icon(Icons.location_city, size: 18),
                const SizedBox(width: 8),
                Text('The Hague', style: GoogleFonts.poppins()),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'San Francisco',
            child: Row(
              children: [
                const Icon(Icons.location_city, size: 18),
                const SizedBox(width: 8),
                Text('San Francisco', style: GoogleFonts.poppins()),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 4),
              Text(
                location ?? 'Barendrecht',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 16),
            ],
          ),
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Getting location...',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
      ),
      error: (error, stack) => InkWell(
        onTap: () async {
          try {
            await Geolocator.openLocationSettings();
          } catch (_) {
            // Fallback if settings can't be opened
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enable location services in your device settings.'),
                ),
              );
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                'Enable Location',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 