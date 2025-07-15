import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../core/analytics/performance_analytics.dart';
import '../../../../core/services/smart_prefetch_manager.dart';
import '../../../../core/utils/performance_manager.dart';

class AdvancedPerformanceDashboard extends ConsumerStatefulWidget {
  const AdvancedPerformanceDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<AdvancedPerformanceDashboard> createState() => _AdvancedPerformanceDashboardState();
}

class _AdvancedPerformanceDashboardState extends ConsumerState<AdvancedPerformanceDashboard> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  
  final PerformanceAnalytics _analytics = PerformanceAnalytics();
  final SmartPrefetchManager _prefetchManager = SmartPrefetchManager();
  final PerformanceManager _performanceManager = PerformanceManager();

  Map<String, dynamic> _realTimeMetrics = {};
  Map<String, dynamic> _behaviorInsights = {};
  List<PerformanceInsight> _performanceInsights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeDashboard();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    try {
      await _analytics.initialize(_performanceManager);
      await _prefetchManager.initialize(_performanceManager);
      await _refreshData();
    } catch (e) {
      debugPrint('❌ Error initializing dashboard: $e');
    }
  }

  void _startRealTimeUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    try {
      final metrics = _analytics.getRealTimeMetrics();
      final insights = _analytics.getPerformanceInsights();
      final behaviorData = _prefetchManager.getBehaviorInsights();

      if (mounted) {
        setState(() {
          _realTimeMetrics = metrics;
          _performanceInsights = insights;
          _behaviorInsights = behaviorData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error refreshing dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 Advanced Performance Dashboard'),
        backgroundColor: Colors.indigo,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Real-time'),
            Tab(icon: Icon(Icons.psychology), text: 'Smart AI'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
            Tab(icon: Icon(Icons.settings), text: 'Controls'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRealTimeTab(),
                _buildSmartAITab(),
                _buildInsightsTab(),
                _buildControlsTab(),
              ],
            ),
    );
  }

  Widget _buildRealTimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsOverview(),
          const SizedBox(height: 20),
          _buildCachePerformanceCard(),
          const SizedBox(height: 20),
          _buildApiUsageCard(),
        ],
      ),
    );
  }

  Widget _buildSmartAITab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPrefetchingStatus(),
          const SizedBox(height: 20),
          _buildBehaviorInsights(),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceInsights(),
          const SizedBox(height: 20),
          _buildOptimizationRecommendations(),
        ],
      ),
    );
  }

  Widget _buildControlsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceControls(),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview() {
    final cacheData = _realTimeMetrics['cache_performance'] as Map<String, dynamic>? ?? {};
    final apiData = _realTimeMetrics['api_usage'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Real-time Performance Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Cache Hit Rate',
                    '${((cacheData['cache_hit_rate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                    '',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'API Calls',
                    '${apiData['total_api_calls'] ?? 0}',
                    '',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, String unit, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$value$unit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCachePerformanceCard() {
    final cacheData = _realTimeMetrics['cache_performance'] as Map<String, dynamic>? ?? {};
    final hitRate = (cacheData['cache_hit_rate'] ?? 0.0) * 100;
    final totalHits = cacheData['total_hits'] ?? 0;
    final totalMisses = cacheData['total_misses'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💾 Cache Performance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hit Rate: ${hitRate.toStringAsFixed(1)}%'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: hitRate / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          hitRate > 80 ? Colors.green : hitRate > 60 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('✅ Hits: $totalHits'),
                    Text('❌ Misses: $totalMisses'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiUsageCard() {
    final apiData = _realTimeMetrics['api_usage'] as Map<String, dynamic>? ?? {};
    final callsByEndpoint = apiData['calls_by_endpoint'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌐 API Usage',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (callsByEndpoint.isEmpty)
              const Text('No API calls recorded yet')
            else
              ...callsByEndpoint.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${entry.value}'),
                    ),
                  ],
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrefetchingStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧠 Smart Prefetching Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Smart Prefetching Active'),
              ],
            ),
            const SizedBox(height: 12),
            Text('Prefetch Cache Size: ${_behaviorInsights['prefetch_cache_size'] ?? 0} items'),
            Text('Tracked Screens: ${_behaviorInsights['total_tracked_screens'] ?? 0}'),
            Text('Navigation Patterns: ${_behaviorInsights['navigation_patterns_count'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 User Behavior Insights',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_behaviorInsights['most_visited_screen'] != null) ...[
              Text('Most Visited: ${_behaviorInsights['most_visited_screen']}'),
              Text('Visit Count: ${_behaviorInsights['most_visited_count']}'),
            ],
            Text('Avg Session: ${(_behaviorInsights['average_session_duration_seconds'] ?? 0.0).toStringAsFixed(1)}s'),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 Performance Insights',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_performanceInsights.isEmpty)
              const Text(
                '✅ All systems performing optimally!',
                style: TextStyle(color: Colors.green),
              )
            else
              ..._performanceInsights.map((insight) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getSeverityColor(insight.severity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getSeverityColor(insight.severity).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.message,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getSeverityColor(insight.severity),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.recommendation,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationRecommendations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 Optimization Recommendations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRecommendationItem(
              '💾 Enable Smart Caching',
              'Implement ML-based cache prediction for 95%+ hit rates',
              true,
            ),
            _buildRecommendationItem(
              '🧠 Enhanced Prefetching',
              'Use advanced behavioral analysis for content prediction',
              true,
            ),
            _buildRecommendationItem(
              '📱 Offline Support',
              'Add offline mode for critical functionality',
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String description, bool implemented) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            implemented ? Icons.check_circle : Icons.radio_button_unchecked,
            color: implemented ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Performance Controls',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _performanceManager.cleanup(),
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Clean Performance Cache'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _prefetchManager.cleanup(),
              icon: const Icon(Icons.memory),
              label: const Text('Clean Prefetch Cache'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
} 