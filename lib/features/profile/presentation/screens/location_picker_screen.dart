import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../places/application/places_service.dart';
import '../../../places/domain/models/place.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  final String? currentLocation;

  const LocationPickerScreen({
    super.key,
    this.currentLocation,
  });

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PlaceAutocomplete> _suggestions = [];
  bool _isLoading = false;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.currentLocation ?? '';
    _selectedLocation = widget.currentLocation;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    if (query.length < 2) return;

    setState(() => _isLoading = true);

    try {
      final placesService = ref.read(placesServiceProvider.notifier);
      
      // Get user's current location for better suggestions
      double? lat;
      double? lng;
      final locationAsync = ref.read(userLocationProvider);
      locationAsync.whenData((position) {
        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
        }
      });

      final suggestions = await placesService.getAutocomplete(
        query,
        latitude: lat,
        longitude: lng,
        radius: 50000, // 50km radius
      );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectLocation(PlaceAutocomplete suggestion) async {
    setState(() => _selectedLocation = suggestion.description);
    _searchController.text = suggestion.description;

    // Save to user preferences
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get place details to extract coordinates
      final placesService = ref.read(placesServiceProvider.notifier);
      final places = await placesService.searchPlaces(
        suggestion.description,
        language: 'en',
      );
      
      if (places.isNotEmpty) {
        final place = places.first;
        await supabase.from('user_preferences').update({
          'default_location': suggestion.description,
          'default_latitude': place.geometry.location.lat,
          'default_longitude': place.geometry.location.lng,
        }).eq('user_id', user.id);
      } else {
        // Just save the location name if we can't get coordinates
        await supabase.from('user_preferences').update({
          'default_location': suggestion.description,
        }).eq('user_id', user.id);
      }

      // Invalidate preferences provider
      ref.invalidate(preferencesProvider);

      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Location updated to ${suggestion.description}',
        );
        context.pop(suggestion.description);
      }
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Error saving location: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Select Location',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: SwirlBackground(
        child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a city or location...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _suggestions = []);
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Suggestions List
          Expanded(
            child: _suggestions.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Start typing to search for a location'
                              : 'No locations found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      final isSelected = _selectedLocation == suggestion.description;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.orange[400]! : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: isSelected ? Colors.orange[600] : Colors.grey[600],
                          ),
                          title: Text(
                            suggestion.structuredFormatting?.mainText ?? suggestion.description,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                          subtitle: suggestion.structuredFormatting?.secondaryText != null
                              ? Text(
                                  suggestion.structuredFormatting!.secondaryText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Colors.orange[600])
                              : const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () => _selectLocation(suggestion),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

