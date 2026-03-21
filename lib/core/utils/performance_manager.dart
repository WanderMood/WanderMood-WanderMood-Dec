import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dev / diagnostics snapshot for the performance test screen.
class PerformanceStats {
  final int totalApiCalls;
  final double cacheHitRate;
  final double errorRate;
  final int activeRequests;
  final int rateLimitedRequests;

  const PerformanceStats({
    this.totalApiCalls = 0,
    this.cacheHitRate = 0,
    this.errorRate = 0,
    this.activeRequests = 0,
    this.rateLimitedRequests = 0,
  });
}

/// Lightweight stub — extend when wiring real API instrumentation.
class PerformanceManager extends StateNotifier<int> {
  PerformanceManager() : super(0);

  PerformanceStats getPerformanceStats() => const PerformanceStats();

  void cleanup() {
    state = state + 1;
  }
}

final performanceManagerProvider =
    StateNotifierProvider<PerformanceManager, int>((ref) {
  return PerformanceManager();
});
