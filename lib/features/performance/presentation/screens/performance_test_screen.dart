import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/performance_manager.dart';
import '../../../places/application/places_service.dart';
import '../../../places/providers/moody_explore_provider.dart';
import '../../../location/services/location_service.dart';
import '../../../weather/application/enhanced_weather_service.dart';
import '../../../weather/domain/models/weather_location.dart';

/// Rotterdam — used only for manual API tests on this screen.
const _kPerfTestWeatherLocation = WeatherLocation(
  id: 'rotterdam_perf',
  name: 'Rotterdam',
  latitude: 51.9244,
  longitude: 4.4777,
);

class PerformanceTestScreen extends ConsumerStatefulWidget {
  const PerformanceTestScreen({super.key});

  @override
  ConsumerState<PerformanceTestScreen> createState() => _PerformanceTestScreenState();
}

class _PerformanceTestScreenState extends ConsumerState<PerformanceTestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  PerformanceStats? _stats;
  
  // Test counters
  int _locationCallCount = 0;
  int _placesCallCount = 0;
  int _weatherCallCount = 0;
  
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _updateStats();
    
    // Update stats every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _updateStats();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateStats() {
    final performanceManager = ref.read(performanceManagerProvider.notifier);
    setState(() {
      _stats = performanceManager.getPerformanceStats();
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toLocal().toString().substring(11, 19)}: $message');
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 Performance Monitor'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: 'Overview'),
            Tab(icon: Icon(Icons.api), text: 'API Tests'),
            Tab(icon: Icon(Icons.cached), text: 'Cache Info'),
            Tab(icon: Icon(Icons.list), text: 'Live Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildApiTestsTab(),
          _buildCacheInfoTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 16),
          _buildPerformanceIndicators(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_stats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Total API Calls', '${_stats!.totalApiCalls}'),
            _buildStatRow('Cache Hit Rate', '${(_stats!.cacheHitRate * 100).toStringAsFixed(1)}%'),
            _buildStatRow('Error Rate', '${(_stats!.errorRate * 100).toStringAsFixed(1)}%'),
            _buildStatRow('Active Requests', '${_stats!.activeRequests}'),
            _buildStatRow('Rate Limited', '${_stats!.rateLimitedRequests}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final performanceManager = ref.read(performanceManagerProvider.notifier);
                      performanceManager.cleanup();
                      _addLog('🧹 Performance cache cleared');
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Cache'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _updateStats,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Stats'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicators() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Performance Indicators',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildIndicator(
              'API Efficiency',
              _stats?.cacheHitRate ?? 0,
              Colors.green,
            ),
            _buildIndicator(
              'Error Rate',
              1 - (_stats?.errorRate ?? 0),
              Colors.orange,
            ),
            _buildIndicator(
              'System Health',
              _stats?.activeRequests == 0 ? 1.0 : 0.8,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${(value * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildApiTestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLocationTestCard(),
          const SizedBox(height: 16),
          _buildPlacesTestCard(),
          const SizedBox(height: 16),
          _buildWeatherTestCard(),
          const SizedBox(height: 16),
          _buildLoadTestCard(),
        ],
      ),
    );
  }

  Widget _buildLocationTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📍 Location Service Tests (Called: $_locationCallCount)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      _addLog('🌍 Getting current location...');
                      setState(() => _locationCallCount++);
                      
                      final stopwatch = Stopwatch()..start();
                      try {
                        final location = await LocationService.getCurrentLocation();
                        stopwatch.stop();
                        _addLog('✅ Location received in ${stopwatch.elapsedMilliseconds}ms: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}');
                      } catch (e) {
                        stopwatch.stop();
                        _addLog('❌ Location failed in ${stopwatch.elapsedMilliseconds}ms: $e');
                      }
                    },
                    child: const Text('Get Location'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      _addLog('🔄 Force refresh location...');
                      setState(() => _locationCallCount++);
                      
                      final stopwatch = Stopwatch()..start();
                      try {
                        final location = await LocationService.forceRefreshLocation();
                        stopwatch.stop();
                        _addLog('✅ Fresh location in ${stopwatch.elapsedMilliseconds}ms: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}');
                      } catch (e) {
                        stopwatch.stop();
                        _addLog('❌ Force refresh failed in ${stopwatch.elapsedMilliseconds}ms: $e');
                      }
                    },
                    child: const Text('Force Refresh'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏪 Places Service Tests (Called: $_placesCallCount)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      _addLog('🏪 Getting nearby places...');
                      setState(() => _placesCallCount++);
                      
                      final stopwatch = Stopwatch()..start();
                      try {
                        final placesService = ref.read(placesServiceProvider.notifier);
                        final places = await placesService.getNearbyPlaces(51.9244, 4.4777);
                        stopwatch.stop();
                        _addLog('✅ Found ${places.length} places in ${stopwatch.elapsedMilliseconds}ms');
                      } catch (e) {
                        stopwatch.stop();
                        _addLog('❌ Places search failed in ${stopwatch.elapsedMilliseconds}ms: $e');
                      }
                    },
                    child: const Text('Nearby Places'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      _addLog('🔍 Searching "restaurant"...');
                      setState(() => _placesCallCount++);
                      
                      final stopwatch = Stopwatch()..start();
                      try {
                        final placesService = ref.read(placesServiceProvider.notifier);
                        final places = await placesService.searchPlaces('restaurant');
                        stopwatch.stop();
                        _addLog('✅ Found ${places.length} restaurants in ${stopwatch.elapsedMilliseconds}ms');
                      } catch (e) {
                        stopwatch.stop();
                        _addLog('❌ Restaurant search failed in ${stopwatch.elapsedMilliseconds}ms: $e');
                      }
                    },
                    child: const Text('Search Places'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                _addLog('🌟 Getting explore places...');
                setState(() => _placesCallCount++);
                
                final stopwatch = Stopwatch()..start();
                try {
                  final places = await ref.read(moodyExploreAutoProvider.future);
                  stopwatch.stop();
                  _addLog('✅ Explore places: ${places.length} results in ${stopwatch.elapsedMilliseconds}ms');
                } catch (e) {
                  stopwatch.stop();
                  _addLog('❌ Explore places failed in ${stopwatch.elapsedMilliseconds}ms: $e');
                }
              },
              child: const Text('Explore (moody Edge)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌤️ Weather Service Tests (Called: $_weatherCallCount)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      _addLog('🌤️ Getting current weather...');
                      setState(() => _weatherCallCount++);
                      
                      final stopwatch = Stopwatch()..start();
                      try {
                        final weatherService = ref.read(enhancedWeatherServiceProvider.notifier);
                        final weather =
                            await weatherService.getCurrentWeather(_kPerfTestWeatherLocation);
                        stopwatch.stop();
                        final desc = weather.description ?? weather.condition;
                        _addLog('✅ Weather: $desc (${weather.temperature}°C) in ${stopwatch.elapsedMilliseconds}ms');
                      } catch (e) {
                        stopwatch.stop();
                        _addLog('❌ Weather failed in ${stopwatch.elapsedMilliseconds}ms: $e');
                      }
                    },
                    child: const Text('Current Weather'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      _addLog('📊 Getting weather forecast...');
                      setState(() => _weatherCallCount++);
                      
                      final stopwatch = Stopwatch()..start();
                      try {
                        final weatherService = ref.read(enhancedWeatherServiceProvider.notifier);
                        final forecast = await weatherService
                            .getHourlyForecast(_kPerfTestWeatherLocation);
                        stopwatch.stop();
                        _addLog('✅ Forecast: ${forecast.length} hours in ${stopwatch.elapsedMilliseconds}ms');
                      } catch (e) {
                        stopwatch.stop();
                        _addLog('❌ Forecast failed in ${stopwatch.elapsedMilliseconds}ms: $e');
                      }
                    },
                    child: const Text('Forecast'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔥 Load Testing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                _addLog('🔥 Starting load test: 10 rapid API calls...');
                
                for (int i = 0; i < 10; i++) {
                  _addLog('🔄 Load test call ${i + 1}/10');
                  
                  // Rapid fire API calls to test deduplication
                  final futures = [
                    LocationService.getCurrentLocation(),
                    ref.read(placesServiceProvider.notifier).getNearbyPlaces(51.9244, 4.4777),
                    ref
                        .read(enhancedWeatherServiceProvider.notifier)
                        .getCurrentWeather(_kPerfTestWeatherLocation),
                  ];
                  
                  await Future.wait(futures);
                  await Future.delayed(const Duration(milliseconds: 100));
                }
                
                _addLog('✅ Load test completed!');
                _updateStats();
              },
              child: const Text('Run Load Test'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCacheStatsCard(),
          const SizedBox(height: 16),
          _buildCacheActionsCard(),
        ],
      ),
    );
  }

  Widget _buildCacheStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💾 Cache Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Performance Manager Cache:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Active requests: ${_stats?.activeRequests ?? 0}'),
            Text('• Rate limited calls: ${_stats?.rateLimitedRequests ?? 0}'),
            Text('• Cache hit rate: ${((_stats?.cacheHitRate ?? 0) * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            const Text(
              'Location Cache:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Consumer(
              builder: (context, ref, child) {
                final lastLocation = LocationService.getLastKnownLocation();
                if (lastLocation != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Cached location: ${lastLocation.latitude.toStringAsFixed(4)}, ${lastLocation.longitude.toStringAsFixed(4)}'),
                      Text('• Accuracy: ${lastLocation.accuracy.toStringAsFixed(1)}m'),
                      Text('• Timestamp: ${lastLocation.timestamp}'),
                    ],
                  );
                } else {
                  return const Text('• No cached location available');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🛠️ Cache Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final performanceManager = ref.read(performanceManagerProvider.notifier);
                      performanceManager.cleanup();
                      _addLog('🧹 Performance cache cleared');
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Performance Cache'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await LocationService.forceRefreshLocation();
                      _addLog('🔄 Location cache refreshed');
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Location'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                '📝 Live Performance Logs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() => _logs.clear());
                },
                icon: const Icon(Icons.clear),
                tooltip: 'Clear logs',
              ),
            ],
          ),
        ),
        Expanded(
          child: _logs.isEmpty
              ? const Center(
                  child: Text(
                    'No logs yet.\nStart making API calls to see performance data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return ListTile(
                      dense: true,
                      leading: _getLogIcon(log),
                      title: Text(
                        log,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Icon _getLogIcon(String log) {
    if (log.contains('✅')) return const Icon(Icons.check_circle, color: Colors.green, size: 16);
    if (log.contains('❌')) return const Icon(Icons.error, color: Colors.red, size: 16);
    if (log.contains('⚡')) return const Icon(Icons.flash_on, color: Colors.orange, size: 16);
    if (log.contains('📍')) return const Icon(Icons.location_on, color: Colors.blue, size: 16);
    if (log.contains('🌤️')) return const Icon(Icons.wb_sunny, color: Colors.amber, size: 16);
    if (log.contains('🏪')) return const Icon(Icons.store, color: Colors.purple, size: 16);
    return const Icon(Icons.info, color: Colors.grey, size: 16);
  }
} 