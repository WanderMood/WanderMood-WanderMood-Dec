import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../features/plans/data/services/places_cache_service.dart';

class CacheMonitorScreen extends StatefulWidget {
  const CacheMonitorScreen({Key? key}) : super(key: key);

  @override
  State<CacheMonitorScreen> createState() => _CacheMonitorScreenState();
}

class _CacheMonitorScreenState extends State<CacheMonitorScreen> {
  Map<String, dynamic>? cacheStats;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final stats = await PlacesCacheService.getCacheStats();
      setState(() {
        cacheStats = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _clearOldCache() async {
    try {
      await PlacesCacheService.clearOldCache();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Old cache entries cleared!')),
      );
      _loadCacheStats(); // Reload stats
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing cache: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Places Cache Monitor'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheStats,
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorView()
              : _buildStatsView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading cache stats',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCacheStats,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsView() {
    if (cacheStats == null) {
      return const Center(child: Text('No cache stats available'));
    }

    final totalPlaces = cacheStats!['total_places'] ?? 0;
    final freshPlaces = cacheStats!['fresh_places'] ?? 0;
    final stalePlaces = cacheStats!['stale_places'] ?? 0;
    final cacheDurationDays = cacheStats!['cache_duration_days'] ?? 7;

    final cacheHitRate = totalPlaces > 0 ? (freshPlaces / totalPlaces * 100) : 0;

    return RefreshIndicator(
      onRefresh: _loadCacheStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storage, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Places Cache Overview',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cache Duration: $cacheDurationDays days',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Places',
                    totalPlaces.toString(),
                    Icons.place,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Fresh Places',
                    freshPlaces.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Stale Places',
                    stalePlaces.toString(),
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Cache Hit Rate',
                    '${cacheHitRate.toStringAsFixed(1)}%',
                    Icons.speed,
                    cacheHitRate > 70 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Performance Indicators
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.purple[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Performance Indicators',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPerformanceIndicator(
                      'API Cost Savings',
                      cacheHitRate > 50 ? 'Excellent' : 'Needs Improvement',
                      cacheHitRate > 50 ? Colors.green : Colors.red,
                      Icons.savings,
                    ),
                    _buildPerformanceIndicator(
                      'Response Speed',
                      freshPlaces > 0 ? 'Fast' : 'Slow (No Cache)',
                      freshPlaces > 0 ? Colors.green : Colors.red,
                      Icons.flash_on,
                    ),
                    _buildPerformanceIndicator(
                      'Data Freshness',
                      stalePlaces < totalPlaces * 0.3 ? 'Good' : 'Needs Cleanup',
                      stalePlaces < totalPlaces * 0.3 ? Colors.green : Colors.orange,
                      Icons.update,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Cache Management',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _clearOldCache,
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text('Clear Old Cache Entries'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loadCacheStats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Statistics'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tips
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Optimization Tips',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip('Cache hit rate above 70% indicates good API cost savings'),
                    _buildTip('Clear old cache entries regularly to maintain performance'),
                    _buildTip('Fresh places provide faster response times for users'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicator(
    String title,
    String status,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.blue[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 