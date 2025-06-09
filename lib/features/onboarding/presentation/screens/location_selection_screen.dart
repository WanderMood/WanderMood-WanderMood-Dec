import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../../shared/widgets/moody_character.dart';
import '../../providers/preferences_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationSelectionScreen extends ConsumerStatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  ConsumerState<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends ConsumerState<LocationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? selectedLocation;
  bool isAnimating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onLocationSelected(Prediction prediction) {
    setState(() {
      selectedLocation = prediction.description;
      _searchController.text = prediction.description ?? '';
      isAnimating = true;
    });

    // Save the selected location
    ref.read(preferencesProvider.notifier).setLocation(prediction.description ?? '');

    // Navigate to next screen with animation delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDF5), // Warm cream yellow
              Color(0xFFFFF3E0), // Slightly darker warm yellow
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Color(0xFF5BB32A),
                  ),
                  onPressed: () => context.go('/preferences/interests'),
                ),
              ),
              
              // Title and Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where would you like\nto explore? 🗺️',
                      style: GoogleFonts.museoModerno(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5BB32A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Search for a city or place you want to discover!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GooglePlaceAutoCompleteTextField(
                    textEditingController: _searchController,
                    googleAPIKey: '', // Google Places API disabled
                    inputDecoration: InputDecoration(
                      hintText: 'Search location...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.black38,
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF5BB32A),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    debounceTime: 800,
                    countries: const ["us", "ca", "gb", "fr", "de", "it", "es"],
                    isLatLngRequired: true,
                    getPlaceDetailWithLatLng: (Prediction prediction) {
                      _onLocationSelected(prediction);
                    },
                    itemClick: (Prediction prediction) {
                      _onLocationSelected(prediction);
                    },
                    seperatedBuilder: const Divider(),
                    containerHorizontalPadding: 10,
                    itemBuilder: (context, prediction) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF5BB32A),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                prediction.description ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Moody Character
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24.0, bottom: 24.0),
                  child: MoodyCharacter(
                    size: 120,
                    mood: selectedLocation != null ? 'excited' : 'default',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 