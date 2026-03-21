import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/plans/data/services/places_cache_service.dart';
import '../features/location/services/location_service.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  String _status = 'Ready';
  bool _isLoading = false;

  void _setStatus(String status) {
    setState(() {
      _status = status;
    });
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  Future<void> _clearAllCache() async {
    _setLoading(true);
    _setStatus('Clearing all cache...');
    
    try {
      await PlacesCacheService.clearAllCache();
      _setStatus('✅ All cache cleared successfully');
    } catch (e) {
      _setStatus('❌ Error clearing cache: $e');
    }
    
    _setLoading(false);
  }

  Future<void> _clearLocationCache() async {
    _setLoading(true);
    _setStatus('Getting current location...');
    
    try {
      final position = await LocationService.getCurrentLocation();
      _setStatus('Clearing cache for location (${position.latitude}, ${position.longitude})...');
      
      await PlacesCacheService.clearCacheForLocation(
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: 100.0, // Clear within 100km radius
      );
      
      _setStatus('✅ Location cache cleared successfully');
    } catch (e) {
      _setStatus('❌ Error clearing location cache: $e');
    }
    
    _setLoading(false);
  }

  Future<void> _getCacheStats() async {
    _setLoading(true);
    _setStatus('Getting cache statistics...');
    
    try {
      final stats = await PlacesCacheService.getCacheStats();
      _setStatus('Cache stats: ${stats.toString()}');
    } catch (e) {
      _setStatus('❌ Error getting cache stats: $e');
    }
    
    _setLoading(false);
  }

  Future<void> _getCurrentLocation() async {
    _setLoading(true);
    _setStatus('Getting current location...');
    
    try {
      final position = await LocationService.getCurrentLocation();
      final city = await LocationService.getCurrentCity();
      
      _setStatus('📍 Current location: $city (${position.latitude}, ${position.longitude})');
    } catch (e) {
      _setStatus('❌ Error getting location: $e');
    }
    
    _setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2A6049),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status display
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _status.startsWith('❌') ? Colors.red : 
                             _status.startsWith('✅') ? Colors.green : Colors.black,
                    ),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Cache Management
            Text(
              'Cache Management',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _clearAllCache,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Cache'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _clearLocationCache,
              icon: const Icon(Icons.location_off),
              label: const Text('Clear Location Cache'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _getCacheStats,
              icon: const Icon(Icons.info),
              label: const Text('Get Cache Stats'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A6049),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Location Management
            Text(
              'Location Management',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _getCurrentLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Get Current Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const Spacer(),
            
            // Warning
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.yellow[700]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.yellow[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a temporary admin screen for debugging cache issues. Use with caution.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.yellow[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 