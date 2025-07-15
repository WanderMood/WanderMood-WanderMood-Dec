import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../application/places_service.dart';
import '../../domain/models/place.dart';

class PlacesTestScreen extends ConsumerStatefulWidget {
  const PlacesTestScreen({super.key});

  @override
  ConsumerState<PlacesTestScreen> createState() => _PlacesTestScreenState();
}

class _PlacesTestScreenState extends ConsumerState<PlacesTestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search tab state
  final _searchController = TextEditingController();
  List<Place> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  // Autocomplete tab state
  final _autocompleteController = TextEditingController();
  List<PlaceAutocomplete> _autocompleteResults = [];
  bool _isAutocompleting = false;

  // Details tab state
  final _placeIdController = TextEditingController();
  Place? _selectedPlace;
  bool _isLoadingDetails = false;
  String? _detailsError;

  // Nearby tab state
  final _latController = TextEditingController(text: '48.8566');
  final _lngController = TextEditingController(text: '2.3522');
  PlaceType? _selectedPlaceType;
  List<Place> _nearbyPlaces = [];
  bool _isLoadingNearby = false;
  String? _nearbyError;

  // Recommendations tab state
  List<Place> _recommendations = [];
  bool _isLoadingRecommendations = false;
  String? _recommendationsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _autocompleteController.dispose();
    _placeIdController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Places API Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Search', icon: Icon(Icons.search)),
            Tab(text: 'Autocomplete', icon: Icon(Icons.auto_complete)),
            Tab(text: 'Details', icon: Icon(Icons.info)),
            Tab(text: 'Nearby', icon: Icon(Icons.near_me)),
            Tab(text: 'Recommendations', icon: Icon(Icons.stars)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildAutocompleteTab(),
          _buildDetailsTab(),
          _buildNearbyTab(),
          _buildRecommendationsTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Search Places',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Query',
                      hintText: 'e.g., restaurants in Paris',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _searchPlaces,
                    child: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Search Places'),
                  ),
                  if (_searchError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _searchError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildPlacesList(_searchResults, 'No search results found'),
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Autocomplete Places',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _autocompleteController,
                    decoration: const InputDecoration(
                      labelText: 'Start typing...',
                      hintText: 'e.g., Eiffel To...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_location),
                    ),
                    onChanged: _onAutocompleteChanged,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Type to see autocomplete suggestions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildAutocompleteList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Place Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _placeIdController,
                    decoration: const InputDecoration(
                      labelText: 'Place ID',
                      hintText: 'e.g., ChIJD7fiBh9u5kcRYJSMaMOCCwQ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isLoadingDetails ? null : _getPlaceDetails,
                    child: _isLoadingDetails
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Get Place Details'),
                  ),
                  if (_detailsError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _detailsError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedPlace != null
                ? _buildPlaceDetailCard(_selectedPlace!)
                : const Center(
                    child: Text('Enter a Place ID to get details'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nearby Places',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latController,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lngController,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PlaceType>(
                    value: _selectedPlaceType,
                    decoration: const InputDecoration(
                      labelText: 'Place Type (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: PlaceType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPlaceType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isLoadingNearby ? null : _getNearbyPlaces,
                    child: _isLoadingNearby
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Find Nearby Places'),
                  ),
                  if (_nearbyError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _nearbyError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildPlacesList(_nearbyPlaces, 'No nearby places found'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Travel Recommendations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Get personalized travel recommendations for a location',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isLoadingRecommendations ? null : _getTravelRecommendations,
                    child: _isLoadingRecommendations
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Get Recommendations for Paris'),
                  ),
                  if (_recommendationsError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _recommendationsError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildPlacesList(_recommendations, 'No recommendations found'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesList(List<Place> places, String emptyMessage) {
    if (places.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _getPlaceIcon(place.primaryType),
              color: Theme.of(context).primaryColor,
            ),
            title: Text(place.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.formattedAddress),
                if (place.rating != null)
                  Text(place.formattedRating),
                Text(place.primaryType),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info),
              onPressed: () => _showPlaceDetails(place),
            ),
            onTap: () => _showPlaceDetails(place),
          ),
        );
      },
    );
  }

  Widget _buildAutocompleteList() {
    if (_autocompleteResults.isEmpty) {
      return const Center(
        child: Text('Type in the text field above to see suggestions'),
      );
    }

    return ListView.builder(
      itemCount: _autocompleteResults.length,
      itemBuilder: (context, index) {
        final autocomplete = _autocompleteResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(autocomplete.structuredFormatting?.mainText ?? autocomplete.description),
            subtitle: Text(autocomplete.structuredFormatting?.secondaryText ?? ''),
            onTap: () {
              _placeIdController.text = autocomplete.placeId;
              _tabController.animateTo(2); // Switch to details tab
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceDetailCard(Place place) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Address', place.formattedAddress),
              if (place.rating != null)
                _buildDetailRow('Rating', place.formattedRating),
              if (place.priceLevel != null)
                _buildDetailRow('Price Level', place.formattedPriceLevel),
              _buildDetailRow('Type', place.primaryType),
              _buildDetailRow('Open Now', place.isOpen ? 'Yes' : 'No'),
              if (place.phoneNumber != null)
                _buildDetailRow('Phone', place.phoneNumber!),
              if (place.website != null)
                _buildDetailRow('Website', place.website!),
              const SizedBox(height: 16),
              Text(
                'Raw JSON Data',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _formatJson(place.toJson()),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  IconData _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'tourist attraction':
        return Icons.attractions;
      case 'hotel':
        return Icons.hotel;
      case 'gas station':
        return Icons.local_gas_station;
      case 'hospital':
        return Icons.local_hospital;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'bank':
        return Icons.account_balance;
      case 'atm':
        return Icons.atm;
      case 'shopping mall':
        return Icons.shopping_mall;
      case 'park':
        return Icons.park;
      case 'museum':
        return Icons.museum;
      case 'church':
        return Icons.church;
      case 'airport':
        return Icons.flight;
      case 'subway station':
        return Icons.subway;
      case 'bus station':
        return Icons.directions_bus;
      default:
        return Icons.place;
    }
  }

  String _formatJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  Future<void> _searchPlaces() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final placesService = PlacesService();
      final results = await placesService.searchPlaces(_searchController.text.trim());
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _onAutocompleteChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _autocompleteResults = [];
      });
      return;
    }

    if (value.length < 3) return; // Wait for at least 3 characters

    setState(() {
      _isAutocompleting = true;
    });

    try {
      final placesService = PlacesService();
      final results = await placesService.getAutocomplete(value.trim());
      
      setState(() {
        _autocompleteResults = results;
        _isAutocompleting = false;
      });
    } catch (e) {
      setState(() {
        _autocompleteResults = [];
        _isAutocompleting = false;
      });
    }
  }

  Future<void> _getPlaceDetails() async {
    if (_placeIdController.text.trim().isEmpty) return;

    setState(() {
      _isLoadingDetails = true;
      _detailsError = null;
    });

    try {
      final placesService = PlacesService();
      final place = await placesService.getPlaceDetails(_placeIdController.text.trim());
      
      setState(() {
        _selectedPlace = place;
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _detailsError = e.toString();
        _isLoadingDetails = false;
      });
    }
  }

  Future<void> _getNearbyPlaces() async {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    
    if (lat == null || lng == null) {
      setState(() {
        _nearbyError = 'Please enter valid latitude and longitude';
      });
      return;
    }

    setState(() {
      _isLoadingNearby = true;
      _nearbyError = null;
    });

    try {
      final placesService = PlacesService();
      final results = await placesService.getNearbyPlaces(
        lat, 
        lng,
        type: _selectedPlaceType,
      );
      
      setState(() {
        _nearbyPlaces = results;
        _isLoadingNearby = false;
      });
    } catch (e) {
      setState(() {
        _nearbyError = e.toString();
        _isLoadingNearby = false;
      });
    }
  }

  Future<void> _getTravelRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
      _recommendationsError = null;
    });

    try {
      final placesService = PlacesService();
      final results = await placesService.getTravelRecommendations(
        48.8566, // Paris latitude
        2.3522,  // Paris longitude
      );
      
      setState(() {
        _recommendations = results;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _recommendationsError = e.toString();
        _isLoadingRecommendations = false;
      });
    }
  }

  void _showPlaceDetails(Place place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place.name),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Address: ${place.formattedAddress}'),
                if (place.rating != null) Text('Rating: ${place.formattedRating}'),
                Text('Type: ${place.primaryType}'),
                if (place.phoneNumber != null) Text('Phone: ${place.phoneNumber}'),
                const SizedBox(height: 16),
                Text('Place ID: ${place.placeId}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 