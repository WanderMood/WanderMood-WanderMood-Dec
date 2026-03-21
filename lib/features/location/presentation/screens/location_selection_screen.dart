import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Prediction> _predictions = [];
  bool _isLoading = false;
  Prediction? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Where do you want to go?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A7BB3),
                    ),
                  ).animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Search for a destination to get personalized recommendations',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ).animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: _onSearchChanged,
              ).animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),
            ),
            const SizedBox(height: 16),
            // Predictions List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final prediction = _predictions[index];
                        return _buildPredictionTile(prediction, index);
                      },
                    ),
            ),
            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _selectedLocation != null
                    ? () => context.go('/recommendations')
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF5BB32A),
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
                child: Text(
                  'Continue',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.2, end: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionTile(Prediction prediction, int index) {
    final isSelected = _selectedLocation?.placeId == prediction.placeId;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF5BB32A) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.location_on,
          color: isSelected ? const Color(0xFF5BB32A) : Colors.grey[600],
        ),
        title: Text(
          prediction.description!,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF5BB32A) : Colors.black87,
          ),
        ),
        onTap: () => setState(() => _selectedLocation = prediction),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: Duration(milliseconds: index * 100))
      .slideX(begin: -0.2, end: 0, delay: Duration(milliseconds: index * 100));
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() {
        _predictions.clear();
        _selectedLocation = null;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final predictions = await GooglePlaces.getPlaceSuggestions(
        value,
        language: 'en',
        components: 'country:us',
      );

      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Error fetching locations. Please try again.',
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 