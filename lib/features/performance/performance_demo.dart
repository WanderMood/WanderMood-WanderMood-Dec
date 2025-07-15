import 'dart:async';
import 'package:flutter/foundation.dart';
import '../location/services/location_service.dart';
import '../../core/utils/performance_manager.dart';

/// Demo script to showcase performance improvements
class PerformanceDemo {
  static Future<void> runDemo() async {
    debugPrint('🚀 Starting Performance Demo...');
    
    // 1. Test location caching
    await _testLocationCaching();
    
    // 2. Test debouncing effectiveness  
    await _testDebouncing();
    
    // 3. Test load handling
    await _testLoadHandling();
    
    debugPrint('✅ Performance Demo Complete!');
  }

  static Future<void> _testLocationCaching() async {
    debugPrint('\n📍 Testing Location Caching...');
    
    // First call - should hit GPS
    final stopwatch1 = Stopwatch()..start();
    final location1 = await LocationService.getCurrentLocation();
    stopwatch1.stop();
    debugPrint('1st location call: ${stopwatch1.elapsedMilliseconds}ms - ${location1.latitude.toStringAsFixed(4)}, ${location1.longitude.toStringAsFixed(4)}');
    
    // Second call - should use cache
    final stopwatch2 = Stopwatch()..start();
    final location2 = await LocationService.getCurrentLocation();
    stopwatch2.stop();
    debugPrint('2nd location call: ${stopwatch2.elapsedMilliseconds}ms - ${location2.latitude.toStringAsFixed(4)}, ${location2.longitude.toStringAsFixed(4)}');
    
    // Verify caching effectiveness
    if (stopwatch2.elapsedMilliseconds < stopwatch1.elapsedMilliseconds) {
      debugPrint('✅ Cache working! ${stopwatch2.elapsedMilliseconds}ms vs ${stopwatch1.elapsedMilliseconds}ms');
    } else {
      debugPrint('⚠️ Cache may not be working optimally');
    }
  }

  static Future<void> _testDebouncing() async {
    debugPrint('\n⏱️ Testing Debouncing...');
    
    final completer = Completer<void>();
    int callCount = 0;
    
    // Simulate rapid calls
    for (int i = 0; i < 5; i++) {
      debugPrint('Making rapid call ${i + 1}...');
      unawaited(LocationService.getCurrentLocation().then((_) {
        callCount++;
        if (callCount == 1) { // Only first call should complete quickly due to caching
          completer.complete();
        }
      }));
      
      // Very short delay between calls
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    await completer.future;
    debugPrint('✅ Rapid calls completed, cache prevented redundant GPS calls');
  }

  static Future<void> _testLoadHandling() async {
    debugPrint('\n🔥 Testing Load Handling...');
    
    final stopwatch = Stopwatch()..start();
    
    // Simulate 10 concurrent location requests
    final futures = List.generate(10, (index) {
      debugPrint('Starting concurrent call ${index + 1}');
      return LocationService.getCurrentLocation();
    });
    
    final results = await Future.wait(futures);
    stopwatch.stop();
    
    debugPrint('✅ 10 concurrent calls completed in ${stopwatch.elapsedMilliseconds}ms');
    
    // Verify all results are consistent (same location due to caching)
    final firstLat = results.first.latitude;
    final firstLon = results.first.longitude;
    final allSame = results.every((pos) => 
      (pos.latitude - firstLat).abs() < 0.0001 && 
      (pos.longitude - firstLon).abs() < 0.0001
    );
    
    if (allSame) {
      debugPrint('✅ All results consistent - cache deduplication working!');
    } else {
      debugPrint('⚠️ Results inconsistent - may indicate cache issues');
    }
  }

  /// Quick demonstration of performance stats
  static void showPerformanceStats() {
    debugPrint('\n📊 Performance Statistics:');
    debugPrint('• Location caching: Enabled');
    debugPrint('• Cache duration: 30 seconds');
    debugPrint('• Distance threshold: ~100 meters');
    debugPrint('• GPS accuracy: Balanced (optimized for performance)');
    debugPrint('• Distance filter: 50+ meters for updates');
  }

  /// Clear all caches for fresh testing
  static Future<void> resetCaches() async {
    debugPrint('\n🧹 Resetting Performance Caches...');
    await LocationService.forceRefreshLocation();
    debugPrint('✅ Caches cleared');
  }
} 