import 'dart:convert';

/// Shared parser for `public.realtime_events` rows.
///
/// Current production shape:
/// - `event_type`
/// - `recipient_id`
/// - `sender_id`
/// - `payload` jsonb
///   - `title`
///   - `message`
///   - `data` (domain event object)
///
/// Legacy rows may still expose `event_data` / `data` directly.
abstract final class MoodMatchRealtimeEventAdapter {
  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static Map<String, dynamic>? _decodeMapString(dynamic value) {
    if (value is! String) return null;
    try {
      final decoded = jsonDecode(value);
      return _asMap(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Extracts raw payload map (`title`, `message`, `data`, ...).
  static Map<String, dynamic>? payloadFromRow(Map<String, dynamic> row) {
    final payload = _asMap(row['payload']);
    if (payload != null) return payload;
    return _decodeMapString(row['payload']);
  }

  /// Extracts the domain event payload object.
  ///
  /// Preferred path: `payload.data`.
  /// Fallback paths: `payload`, then legacy `event_data` / `data`.
  static Map<String, dynamic>? eventDataFromRow(Map<String, dynamic> row) {
    final payload = payloadFromRow(row);
    if (payload != null) {
      final nested = _asMap(payload['data']) ?? _decodeMapString(payload['data']);
      if (nested != null) return nested;
      return payload;
    }

    final legacy =
        _asMap(row['event_data']) ?? _asMap(row['data']) ?? _decodeMapString(row['event_data']) ?? _decodeMapString(row['data']);
    return legacy;
  }

  /// Returns normalized event type from row.
  static String? eventTypeFromRow(Map<String, dynamic> row) {
    final t = row['event_type'] ?? row['type'];
    final s = t?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}
