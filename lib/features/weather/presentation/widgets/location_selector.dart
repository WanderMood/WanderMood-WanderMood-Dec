import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/location.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class LocationSelector extends ConsumerStatefulWidget {
  final Location? selectedLocation;
  final Function(Location) onLocationSelected;

  const LocationSelector({
    super.key,
    this.selectedLocation,
    required this.onLocationSelected,
  });

  @override
  ConsumerState<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends ConsumerState<LocationSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      final location = Location(
        id: 'current',
        latitude: position.latitude,
        longitude: position.longitude,
        name: 'Huidige locatie',
      );
      widget.onLocationSelected(location);
    } catch (e) {
      // Default to Rotterdam when location access fails
      final rotterdamLocation = Location(
        id: 'rotterdam',
        latitude: 51.9244,
        longitude: 4.4777,
        name: 'Rotterdam',
      );
      widget.onLocationSelected(rotterdamLocation);
      showWanderMoodToast(
        context,
        message: 'Locatie ingesteld op Rotterdam',
        backgroundColor: Colors.blue,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Hier zou je normaal gesproken een geocoding service gebruiken
      // Voor nu simuleren we resultaten
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _searchResults = [
          Location(
            id: 'rotterdam',
            latitude: 51.9244,
            longitude: 4.4777,
            name: 'Rotterdam',
          ),
          Location(
            id: 'amsterdam',
            latitude: 52.3676,
            longitude: 4.9041,
            name: 'Amsterdam',
          ),
          Location(
            id: 'utrecht',
            latitude: 52.0907,
            longitude: 5.1214,
            name: 'Utrecht',
          ),
        ].where((loc) => 
          loc.name.toLowerCase().contains(query.toLowerCase())
        ).toList();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        backgroundColor: Colors.white,
      ),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search bar with location button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Zoek een locatie...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: _searchLocations,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A6049),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location, color: Colors.white),
                        tooltip: 'Gebruik huidige locatie',
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
                
              // Search results
              if (_searchResults.isNotEmpty)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final location = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFF2A6049)),
                          title: Text(
                            location.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            widget.onLocationSelected(location);
                            _searchController.clear();
                            setState(() => _searchResults = []);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                )
              else if (_searchController.text.isNotEmpty && !_isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No locations found',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                
              // Popular locations section
              if (_searchResults.isEmpty && _searchController.text.isEmpty && !_isLoading)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Popular Locations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView(
                            children: [
                              _buildPopularLocationTile(
                                'Rotterdam',
                                'Netherlands',
                                51.9244,
                                4.4777,
                              ),
                              const Divider(height: 1),
                              _buildPopularLocationTile(
                                'Amsterdam',
                                'Netherlands',
                                52.3676,
                                4.9041,
                              ),
                              const Divider(height: 1),
                              _buildPopularLocationTile(
                                'Utrecht',
                                'Netherlands',
                                52.0907,
                                5.1214,
                              ),
                              const Divider(height: 1),
                              _buildPopularLocationTile(
                                'The Hague',
                                'Netherlands',
                                52.0705,
                                4.3007,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPopularLocationTile(String name, String country, double lat, double lng) {
    return ListTile(
      leading: const Icon(Icons.location_city, color: Color(0xFF2A6049)),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(country),
      onTap: () {
        final location = Location(
          id: name.toLowerCase(),
          name: name,
          latitude: lat,
          longitude: lng,
          country: country,
        );
        widget.onLocationSelected(location);
        Navigator.pop(context);
      },
    );
  }
} 