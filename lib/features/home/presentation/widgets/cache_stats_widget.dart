import 'package:flutter/material.dart';
import 'package:wandermood/core/services/smart_api_cache.dart';
import 'package:google_fonts/google_fonts.dart';

class CacheStatsWidget extends StatefulWidget {
  const CacheStatsWidget({super.key});

  @override
  State<CacheStatsWidget> createState() => _CacheStatsWidgetState();
}

class _CacheStatsWidgetState extends State<CacheStatsWidget> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await SmartApiCache.getCacheStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_stats == null || _stats!.containsKey('error')) {
      return const SizedBox.shrink();
    }

    final cachedResponses = _stats!['cached_responses'] ?? 0;
    final todaySavings = _stats!['todays_savings'] ?? 0.0;
    final cacheSize = _stats!['total_cache_size_kb'] ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.savings, color: Color(0xFF2A6049)),
                const SizedBox(width: 8),
                Text(
                  'Smart Cache Stats',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A6049),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow('Cached API Responses', '$cachedResponses', Icons.storage),
            _buildStatRow('Today\'s Savings', '\$${todaySavings.toStringAsFixed(2)}', Icons.attach_money),
            _buildStatRow('Cache Size', '${cacheSize}KB', Icons.folder),
            const SizedBox(height: 8),
            Text(
              '💡 Smart caching saves you money by reusing API responses for 30 days',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2A6049),
            ),
          ),
        ],
      ),
    );
  }
} 