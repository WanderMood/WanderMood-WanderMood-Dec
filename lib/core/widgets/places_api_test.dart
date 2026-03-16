import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/places_service.dart';

class PlacesApiTest extends StatefulWidget {
  const PlacesApiTest({Key? key}) : super(key: key);

  @override
  State<PlacesApiTest> createState() => _PlacesApiTestState();
}

class _PlacesApiTestState extends State<PlacesApiTest> {
  final PlacesService _placesService = PlacesService();
  List<Map<String, dynamic>> _places = [];
  String _error = '';
  bool _isLoading = false;

  Future<void> _testPlacesApi() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _places = [];
    });

    try {
      // Test coordinates for Rotterdam
      const double lat = 51.9244;
      const double lng = 4.4777;

      final results = await _placesService.searchPlacesByMood(
        mood: 'happy',
        lat: lat,
        lng: lng,
        radius: 2000,
      );

      setState(() {
        _places = results;
        _isLoading = false;
      });

      if (kDebugMode) debugPrint('Fetched ${results.length} places');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (kDebugMode) debugPrint('Error testing Places API: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Places API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testPlacesApi,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Places API'),
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_places.isNotEmpty) ...[
              Text(
                'Found ${_places.length} places:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _places.length,
                  itemBuilder: (context, index) {
                    final place = _places[index];
                    return Card(
                      child: ListTile(
                        title: Text(place['name'] ?? 'Unknown'),
                        subtitle: Text(place['vicinity'] ?? 'No address'),
                        trailing: place['rating'] != null
                            ? Text('⭐ ${place['rating']}')
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 