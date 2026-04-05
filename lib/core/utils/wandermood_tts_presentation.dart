import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

/// Tunes [tts] for Moody: slightly faster than default rate, subtle pitch lift,
/// and the best-matching installed voice for [bcp47Locale] when [getVoices] lists any.
///
/// Safe to call from UI after the engine is constructed; failures are swallowed
/// so the platform default voice still applies.
Future<void> applyWanderMoodTtsPresentation({
  required FlutterTts tts,
  required String bcp47Locale,
}) async {
  if (kIsWeb) return;

  try {
    await tts.setLanguage(bcp47Locale);
  } catch (_) {
    return;
  }

  try {
    final range = await tts.getSpeechRateValidRange;
    final span = range.max - range.normal;
    final nudged = range.normal + span * 0.14;
    final clamped = nudged.clamp(range.min, range.max);
    await tts.setSpeechRate(clamped);
  } catch (_) {
    try {
      await tts.setSpeechRate(0.54);
    } catch (_) {}
  }

  try {
    await tts.setVolume(1.0);
    await tts.setPitch(1.07);
  } catch (_) {}

  try {
    final raw = await tts.getVoices;
    if (raw == null) return;
    final voices = _parseVoiceList(raw);
    final best = _pickBestVoiceForLocale(voices, bcp47Locale);
    if (best == null) return;

    if (_isAppleDesktopOrMobile) {
      final id = best['identifier']?.trim();
      if (id != null && id.isNotEmpty) {
        await tts.setVoice({
          'identifier': id,
          'name': best['name'] ?? '',
          'locale': best['locale'] ?? bcp47Locale,
        });
      }
    } else if (_isAndroid) {
      final name = best['name'];
      final loc = best['locale'];
      if (name != null &&
          name.isNotEmpty &&
          loc != null &&
          loc.isNotEmpty) {
        await tts.setVoice({'name': name, 'locale': loc});
      }
    }
  } catch (_) {}
}

bool get _isAppleDesktopOrMobile {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

bool get _isAndroid {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android;
}

List<Map<String, String>> _parseVoiceList(dynamic raw) {
  if (raw is! List) return [];
  final out = <Map<String, String>>[];
  for (final e in raw) {
    if (e is Map) {
      out.add(e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')));
    }
  }
  return out;
}

/// iOS: premium > enhanced > default. Android: very high > high > …
int _voiceQualityScore(String? q) {
  if (q == null || q.isEmpty) return 0;
  final s = q.toLowerCase();
  if (s.contains('premium')) return 5;
  if (s.contains('enhanced')) return 4;
  if (s.contains('very high')) return 4;
  if (s.contains('high') && !s.contains('very')) return 3;
  if (s.contains('default')) return 2;
  if (s.contains('normal')) return 1;
  return 0;
}

Map<String, String>? _pickBestVoiceForLocale(
  List<Map<String, String>> voices,
  String bcp47Locale,
) {
  if (voices.isEmpty) return null;

  final want = bcp47Locale.replaceAll('_', '-').toLowerCase();
  final lang = want.split('-').first;

  bool localeMatches(Map<String, String> v) {
    final loc = v['locale']?.replaceAll('_', '-').toLowerCase() ?? '';
    if (loc.isEmpty) return false;
    if (loc == want) return true;
    if (loc == lang) return true;
    if (want.contains('-') && loc.startsWith('$lang-')) return true;
    return false;
  }

  var pool = voices.where(localeMatches).toList();
  if (pool.isEmpty) {
    pool = voices
        .where((v) =>
            (v['locale'] ?? '').replaceAll('_', '-').toLowerCase().startsWith(
                  '$lang-',
                ) ||
            (v['locale'] ?? '').toLowerCase() == lang)
        .toList();
  }
  if (pool.isEmpty) return null;

  pool.sort((a, b) {
    final q = _voiceQualityScore(b['quality'])
        .compareTo(_voiceQualityScore(a['quality']));
    if (q != 0) return q;
    final an = a['network_required'] == '1' ? 1 : 0;
    final bn = b['network_required'] == '1' ? 1 : 0;
    return an.compareTo(bn);
  });

  return pool.first;
}
