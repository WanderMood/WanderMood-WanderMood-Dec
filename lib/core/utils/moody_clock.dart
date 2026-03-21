import 'package:flutter/foundation.dart';

/// Injectable clock for WanderMood “product time”: idle gates, hub greetings,
/// My Day / today filtering, chat timestamps, mood streaks, and Explore heuristics.
///
/// **Not** used for security-sensitive token expiry — those stay on real wall time.
///
/// Tests: [bind] a fixed instant; always [clearBinding] in `tearDown`.
class MoodyClock {
  MoodyClock._();

  static DateTime Function()? _binding;

  static DateTime now() => _binding?.call() ?? DateTime.now();

  @visibleForTesting
  static void bind(DateTime Function() now) {
    _binding = now;
  }

  @visibleForTesting
  static void clearBinding() {
    _binding = null;
  }
}
