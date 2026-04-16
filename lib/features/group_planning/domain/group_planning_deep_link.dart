import 'package:flutter/foundation.dart';

import 'package:wandermood/core/constants/app_link_config.dart';

/// Custom app scheme for group-planning join (registered in iOS Info.plist + Android manifest).
const String kWanderMoodAppScheme = 'wandermood';

/// **Primary** shareable join URL: `https://…/group-planning/join?code=…` when
/// [AppLinkConfig.hasHttpsJoinOrigin], else custom scheme (in-app / deferred only).
Uri groupPlanningJoinShareLink(String joinCode) {
  final code = joinCode.trim().toUpperCase();
  if (!AppLinkConfig.hasHttpsJoinOrigin) {
    return groupPlanningJoinDeepLink(code);
  }
  final origin = Uri.parse(AppLinkConfig.universalLinkOrigin);
  return Uri(
    scheme: origin.scheme,
    host: origin.host,
    port: origin.hasPort ? origin.port : null,
    path: '/group-planning/join',
    queryParameters: {'code': code},
  );
}

/// Deep link used in **QR codes** — same as [groupPlanningJoinShareLink] so camera scans
/// open the https bridge when configured, otherwise `wandermood://group/{joinCode}`.
Uri groupPlanningQrDeepLink(String joinCode) {
  if (AppLinkConfig.hasHttpsJoinOrigin) {
    return groupPlanningJoinShareLink(joinCode);
  }
  final code = joinCode.trim().toUpperCase();
  return Uri(scheme: kWanderMoodAppScheme, host: 'group', path: '/$code');
}

/// Custom-scheme link (always opens the app when the OS routes it here).
Uri groupPlanningJoinDeepLink(String joinCode) {
  final code = joinCode.trim().toUpperCase();
  return Uri(
    scheme: kWanderMoodAppScheme,
    path: '/group-planning/join',
    queryParameters: {'code': code},
  );
}

/// Extracts a join code from a scanned QR string or URL, or `null`.
String? groupPlanningJoinCodeFromScan(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    final fromUri = groupPlanningJoinCodeFromUri(uri);
    if (fromUri != null) return fromUri;
  }

  // Some cameras return the payload without a scheme.
  if (trimmed.startsWith('wandermood:')) {
    final u = Uri.tryParse(trimmed);
    if (u != null) {
      final fromUri = groupPlanningJoinCodeFromUri(u);
      if (fromUri != null) return fromUri;
    }
  }

  final compact = trimmed.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (compact.length >= 4 && compact.length <= 16) return compact;
  return null;
}

/// Join code from a parsed [Uri] (QR short link or full join URL).
String? groupPlanningJoinCodeFromUri(Uri uri) {
  if (uri.scheme == kWanderMoodAppScheme && uri.host.toLowerCase() == 'group') {
    for (final seg in uri.pathSegments) {
      if (seg.isEmpty) continue;
      final c = seg.trim().toUpperCase();
      if (c.length >= 4) return c;
    }
    return null;
  }

  final loc = groupPlanningJoinLocationFromUri(uri);
  if (loc == null) return null;
  final qIdx = loc.indexOf('?');
  if (qIdx < 0) return null;
  final params = Uri.splitQueryString(loc.substring(qIdx + 1));
  final code = params['code']?.trim();
  if (code != null && code.length >= 4) return code.toUpperCase();
  return null;
}

/// Maps an incoming [Uri] to a `go_router` location, or `null` if unrelated.
///
/// Supports:
/// - `wandermood://group/ABC123` (QR in person)
/// - `wandermood:/group-planning/join?code=ABC123`
/// - `wandermood://group-planning/join?code=ABC123` (host + path variants)
/// - `https://…/group-planning/join?code=…` when the path ends with `/group-planning/join`
String? groupPlanningJoinLocationFromUri(Uri uri) {
  if (uri.scheme == 'io.supabase.wandermood' ||
      uri.scheme == 'mailto' ||
      uri.scheme == 'tel' ||
      uri.scheme == 'sms') {
    return null;
  }

  final rawCode = uri.queryParameters['code'] ?? uri.queryParameters['join'];
  final code = rawCode?.trim();
  final encoded =
      code != null && code.length >= 4 ? Uri.encodeQueryComponent(code) : null;

  if (uri.scheme == kWanderMoodAppScheme) {
    // QR short link: wandermood://group/JOINCODE
    if (uri.host.toLowerCase() == 'group') {
      for (final seg in uri.pathSegments) {
        if (seg.isEmpty) continue;
        final c = seg.trim();
        if (c.length >= 4) {
          return '/group-planning/join?code=${Uri.encodeQueryComponent(c.toUpperCase())}';
        }
      }
      return null;
    }

    final path = uri.path.isEmpty ? '/' : uri.path;
    final host = uri.host.toLowerCase();
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final isJoin = normalizedPath == '/group-planning/join' ||
        normalizedPath == '/join' ||
        (host == 'group-planning' &&
            (normalizedPath == '/join' || normalizedPath.startsWith('/join')));
    if (isJoin && encoded != null) {
      return '/group-planning/join?code=$encoded';
    }
    if (kDebugMode) {
      debugPrint(
          '🔗 wandermood deep link ignored (path=$normalizedPath host=$host)');
    }
    return null;
  }

  if (uri.scheme == 'https' || uri.scheme == 'http') {
    final p = uri.path;
    if (p.endsWith('/group-planning/join') || p == '/group-planning/join') {
      if (encoded == null) return null;
      return '/group-planning/join?code=$encoded';
    }
  }

  return null;
}
