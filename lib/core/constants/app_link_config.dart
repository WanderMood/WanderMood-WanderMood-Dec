import 'package:flutter/foundation.dart';

/// Public **https** origin used for Mood Match join links shared in messages.
///
/// Override at build time: `--dart-define=WANDERMOOD_UNIVERSAL_LINK_BASE=https://wandermood.com`
/// (no trailing slash). When empty or invalid, callers fall back to the custom app scheme.
class AppLinkConfig {
  AppLinkConfig._();

  static const String _defineKey = 'WANDERMOOD_UNIVERSAL_LINK_BASE';

  /// Only use an https bridge when explicitly provided via dart-define.
  /// This avoids shipping broken fallback hosts in development builds.
  static String get universalLinkOrigin {
    const fromEnv = String.fromEnvironment(_defineKey, defaultValue: '');
    final raw = fromEnv.trim();
    return raw.replaceAll(RegExp(r'/$'), '');
  }

  /// `true` when [universalLinkOrigin] is a usable http(s) URL for universal join pages.
  static bool get hasHttpsJoinOrigin {
    try {
      final u = Uri.parse(universalLinkOrigin);
      return u.hasScheme &&
          (u.scheme == 'https' || u.scheme == 'http') &&
          u.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static void debugLogOrigin() {
    if (kDebugMode) {
      debugPrint('🔗 WANDERMOOD_UNIVERSAL_LINK_BASE → $universalLinkOrigin');
    }
  }
}
