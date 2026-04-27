import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/core/services/wandermood_ai_service.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/services/connectivity_service.dart';
import 'package:wandermood/core/utils/offline_feedback.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_suggested_places_row.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/settings/presentation/providers/user_preferences_provider.dart';
import 'package:wandermood/features/home/presentation/providers/main_navigation_provider.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_action_sheet.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/core/services/notification_service.dart';
import 'package:wandermood/core/notifications/moody_chat_reminder_in_app_mirror.dart';
import 'package:wandermood/core/notifications/notification_copy.dart';

// WanderMood v2 — Moody chat (Screen 9)
const Color _wmSkyTint = Color(0xFFF1F7FB);
/// Slightly warmer than legacy cream so the composer separates from the field.
const Color _wmCream = Color(0xFFF1E9DD);
const Color _wmSky = Color(0xFFC5DCEB);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

/// Below 1.0 leaves a strip of scrim above the sheet so it feels slightly shorter.
const double _kMoodyChatSheetHeightFactor = 0.93;

/// POSIX locale tag for [stt.SpeechToText.listen]. Falls back to US English.
String _moodyChatSttLocale(String languageCode) {
  const m = {'nl': 'nl_NL', 'de': 'de_DE', 'fr': 'fr_FR', 'es': 'es_ES'};
  return m[languageCode] ?? 'en_US';
}

String _calendarDateOnlyIso(DateTime d) {
  final x = DateTime(d.year, d.month, d.day);
  return '${x.year.toString().padLeft(4, '0')}-'
      '${x.month.toString().padLeft(2, '0')}-'
      '${x.day.toString().padLeft(2, '0')}';
}

/// Facts from a My Day "free time" carousel map for [WanderMoodAIService.chat] / moody `shared_place`.
Map<String, dynamic> moodySharedPlacePayloadForFreeTimeActivity(
  Map<String, dynamic> activity,
) {
  final title = (activity['title'] as String?)?.trim() ?? '';
  final category = (activity['category'] as String?)?.trim() ?? '';
  final out = <String, dynamic>{
    'source': 'my_day_free_time',
    'title': title,
    'category': category,
  };
  final desc = activity['description'] as String?;
  if (desc != null && desc.trim().isNotEmpty) {
    final t = desc.trim();
    out['description'] = t.length > 600 ? '${t.substring(0, 600)}…' : t;
  }
  final p = activity['place'];
  if (p is Place) {
    out['placeId'] = p.id;
    if (p.types.isNotEmpty) {
      out['types'] = p.types.take(12).toList();
    }
    final addr = p.address.trim();
    if (addr.isNotEmpty) out['address'] = addr;
    if (p.photos.isNotEmpty) {
      final u = p.photos.first.trim();
      if (u.isNotEmpty) out['primaryPhotoUrl'] = u;
    }
    final ed = p.editorialSummary?.trim();
    if (ed != null && ed.isNotEmpty) {
      out['editorialSummary'] =
          ed.length > 400 ? '${ed.substring(0, 400)}…' : ed;
    }
  } else {
    final pid = activity['placeId']?.toString().trim();
    if (pid != null && pid.isNotEmpty) out['placeId'] = pid;
  }
  return out;
}

/// Explore list/grid card → `shared_place` for Moody chat (same API as free-time).
Map<String, dynamic> moodySharedPlacePayloadForExplorePlace(Place p) {
  final out = <String, dynamic>{
    'source': 'explore_place_card',
    'placeId': p.id,
    'title': p.name.trim(),
    'address': p.address.trim(),
  };
  if (p.types.isNotEmpty) {
    out['types'] = p.types.take(12).toList();
  }
  final ed = p.editorialSummary?.trim();
  if (ed != null && ed.isNotEmpty) {
    out['editorialSummary'] =
        ed.length > 400 ? '${ed.substring(0, 400)}…' : ed;
  }
  if (p.photos.isNotEmpty) {
    final u = p.photos.first.trim();
    if (u.isNotEmpty) out['primaryPhotoUrl'] = u;
  }
  return out;
}

/// Host status bar / in-app browser chrome often overlaps when only [MediaQuery.padding]
/// is used, or when horizontal safe area is omitted. [viewPadding] is the physical inset.
({double top, double left, double right, double bottom})
    _moodyChatSheetSafeInsets(MediaQueryData mq) {
  var top = math.max(mq.viewPadding.top, mq.padding.top);
  var left = math.max(mq.viewPadding.left, mq.padding.left);
  var right = math.max(mq.viewPadding.right, mq.padding.right);
  var bottom = math.max(mq.viewPadding.bottom, mq.padding.bottom);

  // Phone-sized webviews (e.g. Instagram in-app browser) may report tiny insets while
  // still painting host UI over the page; avoid only on wide desktop tabs.
  final narrowWeb = kIsWeb && mq.size.width < 600;
  if (narrowWeb) {
    if (mq.viewPadding.top < 16) top = math.max(top, 48);
    if (mq.viewPadding.left < 8) left = math.max(left, 52);
  }

  return (top: top, left: left, right: right, bottom: bottom);
}

class _ChatMsg {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final List<Place>? suggestedPlaces;
  /// Quoted earlier message when this bubble is a thread reply (user only).
  final String? replyToText;
  final bool? replyToIsUser;
  /// First Moody line in Explore / My Day place threads — uses opener layout, not the default bubble.
  final bool moodyThreadOpener;

  _ChatMsg({
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.suggestedPlaces,
    this.replyToText,
    this.replyToIsUser,
    this.moodyThreadOpener = false,
  });

  /// Text used when the user chooses Copy (includes quote block if present).
  String get copyableText {
    final q = replyToText?.trim();
    if (q == null || q.isEmpty) return message;
    return '> $q\n\n$message';
  }
}

/// Composer-only: which bubble the next outgoing message replies to.
class _ReplyDraft {
  const _ReplyDraft({required this.quotedText, required this.quotedIsUser});
  final String quotedText;
  final bool quotedIsUser;
}

String _userMessageForAiApi(
  String userText,
  String? replyToText,
  bool? replyToIsUser,
) {
  final body = userText.trim();
  final q = replyToText?.trim();
  if (q == null || q.isEmpty) return body;
  final safeQuote = q.length > 600 ? '${q.substring(0, 600)}…' : q;
  final replyingToSelf = replyToIsUser == true;
  final header = replyingToSelf
      ? '(The user is replying to their own earlier message: """$safeQuote""")'
      : '(The user is replying to this earlier Moody message: """$safeQuote""")';
  return '$header\n\n$body';
}

String _historyContentForAi(_ChatMsg m) {
  if (!m.isUser) return m.message;
  return _userMessageForAiApi(m.message, m.replyToText, m.replyToIsUser);
}

class _DailyMoodyChatCache {
  static String? _dateKey;
  static String? _conversationId;
  static final List<_ChatMsg> _messages = [];

  static String _keyFor(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _prefsKey(DateTime now) {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return 'wm_moody_chat_sheet_v1_${uid}_${_keyFor(now)}';
  }

  static void _resetIfNeeded(DateTime now) {
    final key = _keyFor(now);
    if (_dateKey != key) {
      _dateKey = key;
      _conversationId = null;
      _messages.clear();
    }
  }

  static String getConversationId(DateTime now) {
    _resetIfNeeded(now);
    _conversationId ??= 'conv_${now.millisecondsSinceEpoch}';
    return _conversationId!;
  }

  static void setConversationIdFromServer(String? id) {
    final t = id?.trim();
    if (t == null || t.isEmpty) return;
    _conversationId = t;
  }

  static List<_ChatMsg> getMessages(DateTime now) {
    _resetIfNeeded(now);
    return _messages;
  }

  /// Loads today’s thread from [SharedPreferences] synchronously so the Moody tab
  /// and modal sheet can paint immediately without a loading flash.
  static void hydrateFromPrefsSync(SharedPreferences prefs, DateTime now) {
    _resetIfNeeded(now);
    if (_messages.isNotEmpty) return;

    final raw = prefs.getString(_prefsKey(now));
    if (raw == null || raw.isEmpty) return;

    try {
      final o = jsonDecode(raw) as Map<String, dynamic>;
      final cid = o['conversationId']?.toString().trim();
      if (cid != null && cid.isNotEmpty) {
        _conversationId = cid;
      }
      final arr = o['messages'] as List<dynamic>?;
      if (arr == null) return;
      for (final e in arr) {
        if (e is! Map) continue;
        _messages.add(_chatMsgFromJson(Map<String, dynamic>.from(e)));
      }
    } catch (_) {}
  }

  /// Wipes the in-memory + persisted conversation for today so the chat
  /// returns to its empty (hero) state. Used by the "+ New chat" action.
  static Future<void> clearAll(
    SharedPreferences prefs,
    DateTime now,
  ) async {
    _resetIfNeeded(now);
    _messages.clear();
    _conversationId = null;
    try {
      await prefs.remove(_prefsKey(now));
    } catch (_) {}
  }

  static Future<void> persistToPrefs(
    SharedPreferences prefs,
    DateTime now,
  ) async {
    _resetIfNeeded(now);
    if (_messages.isNotEmpty) {
      _conversationId ??= 'conv_${now.millisecondsSinceEpoch}';
    }
    const maxMessages = 100;
    final slice = _messages.length > maxMessages
        ? _messages.sublist(_messages.length - maxMessages)
        : List<_ChatMsg>.from(_messages);

    final payload = <String, dynamic>{
      'conversationId': _conversationId ?? '',
      'messages': slice.map(_chatMsgToJson).toList(),
    };
    await prefs.setString(_prefsKey(now), jsonEncode(payload));
  }

  static DateTime _startOfLocalDay(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static String _prefsKeyForDay(DateTime dayLocal) {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    final d = _startOfLocalDay(dayLocal);
    return 'wm_moody_chat_sheet_v1_${uid}_${_keyFor(d)}';
  }

  /// True if that calendar day has more than the auto-starter alone (user
  /// messages or a multi-turn thread persisted on device).
  static bool dayHasMeaningfulHistory(
    SharedPreferences prefs,
    DateTime dayLocal,
  ) {
    final raw = prefs.getString(_prefsKeyForDay(dayLocal));
    if (raw == null || raw.isEmpty) return false;
    try {
      final o = jsonDecode(raw) as Map<String, dynamic>;
      final arr = o['messages'] as List<dynamic>?;
      if (arr == null || arr.isEmpty) return false;
      if (arr.length >= 2) return true;
      for (final e in arr) {
        if (e is! Map) continue;
        if (e['isUser'] == true) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static List<_ChatMsg> readDayMessages(
    SharedPreferences prefs,
    DateTime dayLocal,
  ) {
    final out = <_ChatMsg>[];
    final raw = prefs.getString(_prefsKeyForDay(dayLocal));
    if (raw == null || raw.isEmpty) return out;
    try {
      final o = jsonDecode(raw) as Map<String, dynamic>;
      final arr = o['messages'] as List<dynamic>?;
      if (arr == null) return out;
      for (final e in arr) {
        if (e is! Map) continue;
        out.add(_chatMsgFromJson(Map<String, dynamic>.from(e)));
      }
    } catch (_) {}
    return out;
  }
}

Map<String, dynamic> _chatMsgToJson(_ChatMsg m) {
  final o = <String, dynamic>{
    'message': m.message,
    'isUser': m.isUser,
    'timestamp': m.timestamp.toIso8601String(),
    'suggestedPlaces': m.suggestedPlaces?.map((e) => e.toJson()).toList(),
  };
  if (m.moodyThreadOpener) o['threadOpener'] = true;
  final rt = m.replyToText?.trim();
  if (rt != null && rt.isNotEmpty) {
    o['replyToText'] = rt;
    o['replyToIsUser'] = m.replyToIsUser ?? false;
  }
  return o;
}

_ChatMsg _chatMsgFromJson(Map<String, dynamic> j) {
  List<Place>? suggested;
  final raw = j['suggestedPlaces'];
  if (raw is List && raw.isNotEmpty) {
    final out = <Place>[];
    for (final e in raw) {
      if (e is Map) {
        try {
          out.add(Place.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
    }
    if (out.isNotEmpty) suggested = out;
  }
  final rtRaw = j['replyToText'] as String?;
  final rt = rtRaw?.trim();
  final ri = j['replyToIsUser'] as bool?;
  return _ChatMsg(
    message: j['message'] as String? ?? '',
    isUser: j['isUser'] as bool? ?? false,
    timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
        MoodyClock.now(),
    suggestedPlaces: suggested,
    replyToText: (rt != null && rt.isNotEmpty) ? rt : null,
    replyToIsUser: (rt != null && rt.isNotEmpty) ? (ri ?? false) : null,
    moodyThreadOpener: j['threadOpener'] == true,
  );
}

String _dailyStarterMessage({
  required String languageCode,
  required DateTime now,
  required bool hasSelectedMood,
}) {
  final isDutch = languageCode == 'nl';
  final hour = now.hour;
  if (isDutch) {
    if (hour < 12) {
      return hasSelectedMood
          ? 'Goedemorgen! Zin om je dag nog verder af te stemmen?'
          : 'Goedemorgen! Hoe voel je je vandaag?';
    }
    if (hour < 18) {
      return hasSelectedMood
          ? 'Hoi! Hoe gaat je dag tot nu toe? Wil je iets aanpassen?'
          : 'Hoi! Hoe voel je je nu?';
    }
    return hasSelectedMood
        ? 'Goedenavond! Hoe was je dag?'
        : 'Goedenavond! Hoe voel je je vanavond?';
  }
  if (hour < 12) {
    return hasSelectedMood
        ? 'Good morning! Want to fine-tune your day?'
        : 'Good morning! How are you feeling today?';
  }
  if (hour < 18) {
    return hasSelectedMood
        ? 'Hey! How is your day going so far? Want to tweak anything?'
        : 'Hey! How are you feeling right now?';
  }
  return hasSelectedMood
      ? 'Good evening! How was your day?'
      : 'Good evening! How are you feeling tonight?';
}

void _seedDailyStarterIfNeeded({
  required BuildContext context,
  required SharedPreferences prefs,
  required DateTime now,
  required List<_ChatMsg> chatMessages,
  required List<String> moods,
}) {
  if (chatMessages.isNotEmpty) return;
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return;
  chatMessages.add(
    _ChatMsg(
      message: _dailyStarterMessage(
        languageCode: Localizations.localeOf(context).languageCode,
        now: now,
        hasSelectedMood: moods.isNotEmpty,
      ),
      isUser: false,
      timestamp: now,
    ),
  );
  unawaited(_DailyMoodyChatCache.persistToPrefs(prefs, now));
}

/// Rotates opener copy + tone so place threads do not read like a generic assistant.
String _moodyPlaceThreadOpenerLine({
  required bool dutch,
  required String source,
  required String title,
  required String placeKey,
  required int hour,
}) {
  final t = title.trim();
  final label = t.isEmpty ? (dutch ? 'deze plek' : 'this spot') : t;
  final salt = '$placeKey|$source|$hour'.hashCode;
  final v = salt.abs() % 6;

  if (source == 'explore_place_card') {
    if (dutch) {
      switch (v) {
        case 0:
          return 'Oeh — $label. Ik zit erbij. Schiet: drukte, licht, beste moment… wat wil je weten?';
        case 1:
          return '$label… nice. Waar twijfel je — tijd, sfeer, of een plan B dichtbij?';
        case 2:
          return 'Oké, ik focus op $label. Geen folder-tekst — gewoon je vraag.';
        case 3:
          return 'Als je $label wilt uitspitten: wat heb je nú nodig — rust, energie, of iets anders in de buurt?';
        case 4:
          return '$label staat vast. Ik lees mee — wat wil je weten voordat je \'m in je dag smijt?';
        default:
          return 'Zeg het hardop over $label — kindproof? date? "ben ik hier dom aan begonnen?" Mag allemaal.';
      }
    }
    switch (v) {
      case 0:
        return 'Ooh—$label. I\'m here with you. Crowd, light, best time… what do you want to know?';
      case 1:
        return '$label… nice. Where are you stuck—timing, vibe, or a backup nearby?';
      case 2:
        return 'Ok I\'m zoomed in on $label. No brochure voice—just ask.';
      case 3:
        return 'If you\'re stress-testing $label: what do you need right now—quiet, energy, plan B?';
      case 4:
        return '$label\'s pinned. What do you want to know before you drop it in your day?';
      default:
        return 'Say the awkward part about $label—kid chaos? date night? "is this dumb right now?" All fine.';
    }
  }

  // my_day_free_time (and any future place-thread sources)
  if (dutch) {
    switch (v) {
      case 0:
        return t.isEmpty
            ? 'Dit stukje vrije tijd — waar wil je scherp op: alternatief, timing, of gewoon "klopt dit"?'
            : 'Je blok rond $label — zeg wat je wringt: alternatief, timing, sfeer…';
      case 1:
        return t.isEmpty
            ? 'Ik kijk mee met je lege slot. Wat zou je vandaag wél willen voelen?'
            : '$label in je schema — wil je het schaven of ruilen?';
      case 2:
        return t.isEmpty
            ? 'Vrij moment. Geen stress-vraag is te klein.'
            : 'Over $label: eerlijk — twijfel je of dit slim past vandaag?';
      case 3:
        return t.isEmpty
            ? 'Laten we dit slot normaal houden: wat is je echte vraag?'
            : '$label… vertel: backup, beter moment, of gewoon zekerheid?';
      case 4:
        return t.isEmpty
            ? 'Ik ben er. Wat wil je weten over dit stuk van je dag?'
            : 'Ik zit op $label. Waar krijg je hoofdpijn van in je planning?';
      default:
        return t.isEmpty
            ? 'Schiet — ik fix context, jij fix je vibe.'
            : '$label: zeg wat je nodig hebt. Ik werk mee.';
    }
  }
  switch (v) {
    case 0:
      return t.isEmpty
          ? 'This free slice—what do you want sharp on: swap, timing, or "does this even fit"?'
          : 'That $label block—say what\'s bugging you: swap, timing, vibe…';
    case 1:
      return t.isEmpty
          ? 'I\'m watching this empty slot with you. What would you *want* to feel today?'
          : '$label on your day—tweak it or trade it?';
    case 2:
      return t.isEmpty
          ? 'Free time. No question is too small.'
          : 'About $label—real talk: are you unsure it fits today?';
    case 3:
      return t.isEmpty
          ? 'Let\'s keep this slot human: what\'s the actual question?'
          : '$label… backup, better timing, or just certainty?';
    case 4:
      return t.isEmpty
          ? 'I\'m here. What do you want to know about this part of your day?'
          : 'I\'m on $label. What part of the plan is giving you friction?';
    default:
      return t.isEmpty
          ? "Go—I'll add context, you steer the vibe."
          : '$label: say what you need. I\'ll match it.';
  }
}

void _seedModalSharedPlaceStarterIfNeeded({
  required BuildContext context,
  required SharedPreferences prefs,
  required DateTime now,
  required List<_ChatMsg> chatMessages,
  required Map<String, dynamic> sharedPlace,
}) {
  if (chatMessages.isNotEmpty) return;
  if (!context.mounted) return;
  final dutch = Localizations.localeOf(context).languageCode == 'nl';
  final title = (sharedPlace['title'] as String?)?.trim() ?? '';
  final source = sharedPlace['source'] as String? ?? '';
  final pid = (sharedPlace['placeId'] as String?)?.trim() ?? '';
  final placeKey = pid.isNotEmpty ? pid : title;
  final msg = _moodyPlaceThreadOpenerLine(
    dutch: dutch,
    source: source,
    title: title,
    placeKey: placeKey,
    hour: now.hour,
  );
  chatMessages.add(
    _ChatMsg(
      message: msg,
      isUser: false,
      timestamp: now,
      moodyThreadOpener: true,
    ),
  );
}

String _placeThreadPrefsKey(DateTime now, String placeId, String source) {
  final uid = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
  final d = _calendarDateOnlyIso(now);
  final pid = placeId.trim().isEmpty ? 'noid' : placeId.trim();
  final src = source
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return 'wm_moody_place_thread_v1_${uid}_${d}_${src}_$pid';
}

String _makePlaceThreadConversationId(DateTime now, String placeId) {
  final uid = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
  final d = _calendarDateOnlyIso(now);
  final pid = placeId.trim().isEmpty ? 'noid' : placeId.trim();
  return 'conv_sp_${uid}_${d}_$pid';
}

/// Device-local thread for "Ask Moody" from Explore / My Day free time (not the hub daily list).
void _hydratePlaceThreadFromPrefsSync({
  required SharedPreferences prefs,
  required DateTime now,
  required String placeId,
  required String source,
  required List<_ChatMsg> outMessages,
  required void Function(String conversationId) onConversationId,
}) {
  outMessages.clear();
  final raw = prefs.getString(_placeThreadPrefsKey(now, placeId, source));
  if (raw == null || raw.isEmpty) {
    onConversationId('');
    return;
  }
  try {
    final o = jsonDecode(raw) as Map<String, dynamic>;
    final cid = o['conversationId']?.toString().trim();
    if (cid != null && cid.isNotEmpty) {
      onConversationId(cid);
    } else {
      onConversationId('');
    }
    final arr = o['messages'] as List<dynamic>?;
    if (arr == null) return;
    for (final e in arr) {
      if (e is! Map) continue;
      outMessages.add(_chatMsgFromJson(Map<String, dynamic>.from(e)));
    }
  } catch (_) {
    onConversationId('');
  }
}

Future<void> _persistPlaceThreadToPrefs({
  required SharedPreferences prefs,
  required DateTime now,
  required String placeId,
  required String source,
  required List<_ChatMsg> messages,
  required String conversationId,
}) async {
  const maxMessages = 100;
  final slice = messages.length > maxMessages
      ? messages.sublist(messages.length - maxMessages)
      : List<_ChatMsg>.from(messages);
  final payload = <String, dynamic>{
    'conversationId': conversationId,
    'messages': slice.map(_chatMsgToJson).toList(),
  };
  await prefs.setString(
    _placeThreadPrefsKey(now, placeId, source),
    jsonEncode(payload),
  );
}

/// Fixes chat scroll getting "stuck" after relayout when [pixels] drifts past
/// [maxScrollExtent] (common with nested horizontal lists + dynamic height).
void _clampMoodyChatScrollPastEnd(ScrollController c) {
  if (!c.hasClients) return;
  final p = c.position;
  if (!p.hasContentDimensions || !p.maxScrollExtent.isFinite) return;
  if (p.pixels > p.maxScrollExtent + 0.5) {
    c.jumpTo(p.maxScrollExtent);
  }
}

void _scheduleMoodyChatScroll(
  ScrollController controller, {
  bool animate = true,
}) {
  void run() {
    try {
      if (!controller.hasClients) return;
      _clampMoodyChatScrollPastEnd(controller);
      if (!controller.hasClients) return;
      final p = controller.position;
      if (!p.hasContentDimensions) return;
      final target = p.maxScrollExtent;
      if (animate) {
        controller.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        controller.jumpTo(target);
      }
    } catch (_) {
      // Sheet closed; controller may already be disposed.
    }
  }

  // Two frames: clamp once after layout settles, then scroll so [maxScrollExtent]
  // is stable (avoids invalid offset + double animation to bottom).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      if (controller.hasClients) {
        _clampMoodyChatScrollPastEnd(controller);
      }
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) => run());
  });
}

/// Subtle fade + upward settle tied to [ModalRoute.animation], matching the eased
/// feel used elsewhere (e.g. Explore’s `showGeneralDialog` transitions).
class _MoodyChatSheetModalEntrance extends StatelessWidget {
  const _MoodyChatSheetModalEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) return child;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t =
            Curves.easeOutCubic.transform(animation.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: 0.88 + 0.12 * t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1.0 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Opens the Moody chat bottom sheet — the same UI from the original MoodHomeScreen.
/// Can be called from any screen that has access to a [BuildContext] and a [WidgetRef].
Future<void> showMoodyChatSheet(BuildContext context, WidgetRef ref) {
  HapticFeedback.lightImpact();
  final moods = ref.read(dailyMoodStateNotifierProvider).selectedMoods;
  final now = MoodyClock.now();
  final prefs = ref.read(sharedPreferencesProvider);
  // Same as the Moody tab: sync hydrate so the sheet can open immediately with content.
  _DailyMoodyChatCache.hydrateFromPrefsSync(prefs, now);
  if (!context.mounted) {
    return Future<void>.value();
  }

  final conversationId = _DailyMoodyChatCache.getConversationId(now);
  final chatMessages = _DailyMoodyChatCache.getMessages(now);
  _seedDailyStarterIfNeeded(
    context: context,
    prefs: prefs,
    now: now,
    chatMessages: chatMessages,
    moods: moods,
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 320),
      reverseDuration: Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    // Root route gets reliable viewInsets on iOS when the keyboard opens.
    useRootNavigator: true,
    useSafeArea: false,
    enableDrag: true,
    builder: (sheetContext) => _MoodyChatSheetModalEntrance(
      child: _MoodyChatSheetContent(
        chatMessages: chatMessages,
        conversationId: conversationId,
        moods: moods,
        embedded: false,
      ),
    ),
  );
}

/// Opens the Moody chat sheet with [sharedPlace] sent on each message (`shared_place` on moody).
Future<void> showMoodyChatSheetWithSharedPlace(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, dynamic> sharedPlace,
}) {
  HapticFeedback.lightImpact();
  final moods = ref.read(dailyMoodStateNotifierProvider).selectedMoods;
  final now = MoodyClock.now();
  final prefs = ref.read(sharedPreferencesProvider);
  if (!context.mounted) {
    return Future<void>.value();
  }

  final placeId = (sharedPlace['placeId'] as String?)?.trim() ??
      't${sharedPlace['title'].hashCode}';
  final source = (sharedPlace['source'] as String?)?.trim() ?? 'ctx';
  final chatMessages = <_ChatMsg>[];
  var conversationId = '';
  _hydratePlaceThreadFromPrefsSync(
    prefs: prefs,
    now: now,
    placeId: placeId,
    source: source,
    outMessages: chatMessages,
    onConversationId: (id) => conversationId = id,
  );
  if (conversationId.isEmpty) {
    conversationId = _makePlaceThreadConversationId(now, placeId);
  }
  _seedModalSharedPlaceStarterIfNeeded(
    context: context,
    prefs: prefs,
    now: now,
    chatMessages: chatMessages,
    sharedPlace: sharedPlace,
  );
  unawaited(
    _persistPlaceThreadToPrefs(
      prefs: prefs,
      now: now,
      placeId: placeId,
      source: source,
      messages: chatMessages,
      conversationId: conversationId,
    ),
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 320),
      reverseDuration: Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    useRootNavigator: true,
    useSafeArea: false,
    enableDrag: true,
    builder: (sheetContext) {
      final mq = MediaQuery.of(sheetContext);
      final topInset = _moodyChatSheetSafeInsets(mq).top;
      return SizedBox(
        height: mq.size.height,
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: DraggableScrollableSheet(
            initialChildSize: 0.56,
            minChildSize: 0.34,
            maxChildSize: 0.94,
            snap: true,
            snapSizes: const [0.56, 0.94],
            expand: false,
            builder: (ctx, scrollController) {
              return _MoodyChatSheetModalEntrance(
                child: _MoodyChatSheetContent(
                  chatMessages: chatMessages,
                  conversationId: conversationId,
                  moods: moods,
                  embedded: false,
                  sharedPlaceContext: sharedPlace,
                  placeThreadPlaceId: placeId,
                  placeThreadSource: source,
                  modalListScrollController: scrollController,
                  modalDraggableLayout: true,
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

/// Full chat-first Moody tab surface (non-modal).
///
/// **Related:** [MoodyConversationScreen] (mood home overlay) and
/// [MoodyIdleScreen] (time-bucket idle welcome) are separate entry points;
/// when changing composer behavior, check those surfaces too.
class MoodyChatTabView extends ConsumerStatefulWidget {
  const MoodyChatTabView({super.key});

  @override
  ConsumerState<MoodyChatTabView> createState() => _MoodyChatTabViewState();
}

class _MoodyChatTabViewState extends ConsumerState<MoodyChatTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final moods = ref.watch(dailyMoodStateNotifierProvider).selectedMoods;
    final now = MoodyClock.now();
    final prefs = ref.read(sharedPreferencesProvider);
    _DailyMoodyChatCache.hydrateFromPrefsSync(prefs, now);
    final conversationId = _DailyMoodyChatCache.getConversationId(now);
    final chatMessages = _DailyMoodyChatCache.getMessages(now);
    _seedDailyStarterIfNeeded(
      context: context,
      prefs: prefs,
      now: now,
      chatMessages: chatMessages,
      moods: moods,
    );

    return _MoodyChatSheetContent(
      chatMessages: chatMessages,
      conversationId: conversationId,
      moods: moods,
      embedded: true,
    );
  }
}

/// Owns text/scroll controllers so they are disposed with the sheet widget tree.
/// Disposing them in [showModalBottomSheet]'s future caused framework assertions
/// when the route was still tearing down.
class _MoodyChatSheetContent extends ConsumerStatefulWidget {
  const _MoodyChatSheetContent({
    required this.chatMessages,
    required this.conversationId,
    required this.moods,
    required this.embedded,
    this.sharedPlaceContext,
    this.placeThreadPlaceId,
    this.placeThreadSource,
    this.modalListScrollController,
    this.modalDraggableLayout = false,
  });

  final List<_ChatMsg> chatMessages;
  final String conversationId;
  final List<String> moods;
  final bool embedded;
  /// When non-null (e.g. My Day free time), sent as `shared_place` on every [WanderMoodAIService.chat] call.
  final Map<String, dynamic>? sharedPlaceContext;
  /// When set with [placeThreadSource], [chatMessages] are persisted in a separate prefs bucket from the hub.
  final String? placeThreadPlaceId;
  final String? placeThreadSource;
  /// Draggable modal: list scroll is wired to the sheet controller.
  final ScrollController? modalListScrollController;
  final bool modalDraggableLayout;

  @override
  ConsumerState<_MoodyChatSheetContent> createState() =>
      _MoodyChatSheetContentState();
}

enum _MicSetupOutcome { ready, denied, permanentlyDenied, speechInitFailed }

class _MoodyChatSheetContentState extends ConsumerState<_MoodyChatSheetContent> {
  late final TextEditingController _chatController;
  ScrollController? _ownedScrollController;
  late String _conversationIdForApi;
  late final FocusNode _composerFocusNode;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAILoading = false;
  _ReplyDraft? _replyDraft;
  bool _isListening = false;
  bool _sttInitialized = false;
  bool _sttAvailable = false;
  Timer? _sttSilenceTimer;
  String _composerTextBeforeListen = '';

  /// Hub open = hero/actions; closed = chat focus. Default open; closes on send;
  /// re-opens when returning to the Moody tab from another bottom-nav tab.
  bool _hubPeekOpen = true;

  /// Past days have a persisted Moody thread on device (SharedPreferences).
  bool _hasEarlierChats = false;

  static const int _moodyTabIndex = 2;
  ProviderSubscription<int>? _mainTabSubscription;

  /// Embedded Moody stays mounted [Offstage] while other tabs show. Keyboard /
  /// safe-area [didChangeMetrics] still fires globally; skip metrics-driven
  /// rebuilds when this surface is not visible to avoid fighting Explore layout
  /// (`!semantics.parentDataDirty`).
  bool _metricsDrivenUpdatesAllowed() {
    if (!widget.embedded) return true;
    return ref.read(mainTabProvider) == _moodyTabIndex;
  }

  ScrollController get _effectiveScroll =>
      widget.modalListScrollController ?? _ownedScrollController!;

  bool get _usesPlaceThreadBucket =>
      widget.placeThreadPlaceId != null &&
      widget.placeThreadPlaceId!.trim().isNotEmpty &&
      (widget.placeThreadSource?.trim().isNotEmpty ?? false);

  Future<void> _persistChat({bool refreshEarlierChats = true}) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final now = MoodyClock.now();
      if (_usesPlaceThreadBucket) {
        await _persistPlaceThreadToPrefs(
          prefs: prefs,
          now: now,
          placeId: widget.placeThreadPlaceId!,
          source: widget.placeThreadSource!,
          messages: widget.chatMessages,
          conversationId: _conversationIdForApi,
        );
      } else {
        await _DailyMoodyChatCache.persistToPrefs(prefs, now);
      }
    } catch (_) {}
    // After an `await`, [mounted]/[ref] may be invalid (e.g. [dispose] used [unawaited]).
    if (!refreshEarlierChats) return;
    try {
      if (!mounted) return;
      _refreshEarlierChatsAvailability();
    } catch (_) {}
  }

  void _refreshEarlierChatsAvailability() {
    if (!mounted) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final now = MoodyClock.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    var any = false;
    for (var i = 1; i <= 21; i++) {
      final d = todayStart.subtract(Duration(days: i));
      if (_DailyMoodyChatCache.dayHasMeaningfulHistory(prefs, d)) {
        any = true;
        break;
      }
    }
    if (!mounted) return;
    if (any != _hasEarlierChats) {
      setState(() => _hasEarlierChats = any);
    }
  }

  void _onChatScrollControllerTick() {
    _clampMoodyChatScrollPastEnd(_effectiveScroll);
  }

  @override
  void initState() {
    super.initState();
    _conversationIdForApi = widget.conversationId;
    if (!widget.embedded) {
      _hubPeekOpen = false;
    }
    _chatController = TextEditingController();
    if (widget.modalListScrollController != null) {
      widget.modalListScrollController!
          .addListener(_onChatScrollControllerTick);
    } else {
      _ownedScrollController = ScrollController();
      _ownedScrollController!.addListener(_onChatScrollControllerTick);
    }
    _composerFocusNode = FocusNode();
    _composerFocusNode.addListener(_onComposerFocusForHubCollapse);
  }

  /// Collapse expanded hub so the chat thread is visible. Called from composer
  /// focus and from every tap on the field (tap does not refocus if already
  /// focused, so [onTap] is required).
  void _collapseHubForChat() {
    final hasThread = widget.chatMessages.isNotEmpty;
    if (_composerFocusNode.canRequestFocus) {
      _composerFocusNode.requestFocus();
    }
    if (!hasThread || !_hubPeekOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hubPeekOpen) return;
      setState(() => _hubPeekOpen = false);
    });
  }

  /// Collapse when the composer gains focus (keyboard metrics safe path).
  void _onComposerFocusForHubCollapse() {
    if (!_composerFocusNode.hasFocus) return;
    _collapseHubForChat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ref is not safe to use in initState for ConsumerStatefulWidget — listen here once.
    _mainTabSubscription ??= ref.listenManual<int>(mainTabProvider, (previous, next) {
      if (!widget.embedded) return;
      if (next == _moodyTabIndex &&
          previous != null &&
          previous != _moodyTabIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _hubPeekOpen = true);
        });
      }
    });
    _refreshEarlierChatsAvailability();
  }

  Future<void> _openArchiveCopyOnly(_ChatMsg msg) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.copy_rounded, color: _wmForest),
          title: Text(
            l10n?.chatSheetMessageCopy ?? 'Copy',
            style: GoogleFonts.poppins(fontSize: 16, color: _wmCharcoal),
          ),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: msg.copyableText));
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n?.chatSheetCopied ?? 'Copied'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showArchivedDaySheet(DateTime day) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final msgs = _DailyMoodyChatCache.readDayMessages(prefs, day);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toString();
    final title = DateFormat.yMMMEd(localeTag).format(day);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _wmSkyTint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (ctx, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _wmCharcoal,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: _wmCharcoal,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    Localizations.localeOf(context).languageCode == 'nl'
                        ? 'Alleen lezen — dit is je opgeslagen chat van die dag op dit apparaat.'
                        : 'Read-only — saved chat from that day on this device.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: _wmStone,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: msgs.isEmpty
                      ? Center(
                          child: Text(
                            l10n?.chatSheetErrorMessage ??
                                'Nothing saved for that day.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: _wmCharcoal,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: msgs.length,
                          itemBuilder: (context, i) {
                            final m = msgs[i];
                            return _MessageBubble(
                              msg: m,
                              moodyName:
                                  l10n?.chatSheetMoodyName ?? 'Moody',
                              youLabel: l10n?.chatSheetReplyLabelYou ?? 'You',
                              onLongPress: () => _openArchiveCopyOnly(m),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openEarlierChatsPicker() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final now = MoodyClock.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final days = <DateTime>[];
    for (var i = 1; i <= 21; i++) {
      final d = todayStart.subtract(Duration(days: i));
      if (_DailyMoodyChatCache.dayHasMeaningfulHistory(prefs, d)) {
        days.add(d);
      }
    }
    if (!mounted) return;
    final nl = Localizations.localeOf(context).languageCode == 'nl';
    final localeTag = Localizations.localeOf(context).toString();
    final df = DateFormat.yMMMEd(localeTag);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxListH = MediaQuery.of(ctx).size.height * 0.5;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  nl ? 'Kies een dag' : 'Pick a day',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _wmCharcoal,
                  ),
                ),
              ),
              if (days.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Text(
                    nl
                        ? 'Geen opgeslagen chats van de afgelopen weken.'
                        : 'No saved chats from the past few weeks.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _wmStone,
                      height: 1.35,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListH),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: days.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 20, endIndent: 20),
                    itemBuilder: (context, index) {
                      final d = days[index];
                      return ListTile(
                        title: Text(
                          df.format(d),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: _wmCharcoal,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          unawaited(_showArchivedDaySheet(d));
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Lazily initialize speech recognition the first time the user taps the mic.
  /// Defers the microphone permission prompt until the feature is actually used.
  Future<_MicSetupOutcome> _ensureSpeechInitialized() async {
    if (kIsWeb) {
      return _MicSetupOutcome.speechInitFailed;
    }
    if (_sttAvailable) {
      return _MicSetupOutcome.ready;
    }

    try {
      var micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        micStatus = await Permission.microphone.request();
      }
      if (micStatus.isPermanentlyDenied) {
        return _MicSetupOutcome.permanentlyDenied;
      }
      if (!micStatus.isGranted) {
        return _MicSetupOutcome.denied;
      }

      if (!_sttInitialized) {
        _sttInitialized = true;
        _sttAvailable = await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            if (status == 'done' || status == 'notListening') {
              setState(() => _isListening = false);
            }
          },
          onError: (err) {
            if (kDebugMode) debugPrint('Moody STT error: ${err.errorMsg}');
            if (!mounted) return;
            setState(() => _isListening = false);
          },
        );
        if (!_sttAvailable) {
          _sttInitialized = false;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Moody STT init failed: $e');
      _sttAvailable = false;
      _sttInitialized = false;
    }

    return _sttAvailable ? _MicSetupOutcome.ready : _MicSetupOutcome.speechInitFailed;
  }

  void _showMicSetupSnackBar(_MicSetupOutcome outcome) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.moodyChatMicrophoneRequired),
        behavior: SnackBarBehavior.floating,
        action: outcome == _MicSetupOutcome.permanentlyDenied
            ? SnackBarAction(
                label: l10n.chatSheetMicrophoneOpenSettings,
                onPressed: () {
                  unawaited(openAppSettings());
                },
              )
            : null,
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (_isAILoading) return;
    if (_isListening) {
      await _stopListening();
      return;
    }

    final localeCode = Localizations.localeOf(context).languageCode;
    final micOutcome = await _ensureSpeechInitialized();
    if (micOutcome != _MicSetupOutcome.ready) {
      if (mounted) {
        _showMicSetupSnackBar(micOutcome);
      }
      return;
    }

    if (!mounted) return;
    _composerTextBeforeListen = _chatController.text;
    setState(() => _isListening = true);

    final locale = _moodyChatSttLocale(localeCode);

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords;
          final joined = _composerTextBeforeListen.isEmpty
              ? words
              : '${_composerTextBeforeListen.trim()} $words';
          _chatController.value = TextEditingValue(
            text: joined,
            selection: TextSelection.collapsed(offset: joined.length),
          );

          _sttSilenceTimer?.cancel();
          _sttSilenceTimer = Timer(const Duration(seconds: 2), () {
            if (_isListening) _stopListening();
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: locale,
        listenOptions: stt.SpeechListenOptions(partialResults: true),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Moody STT listen failed: $e');
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _stopListening() async {
    _sttSilenceTimer?.cancel();
    try {
      await _speech.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _mainTabSubscription?.close();
    unawaited(_persistChat(refreshEarlierChats: false));
    _sttSilenceTimer?.cancel();
    if (!kIsWeb) {
      try {
        _speech.cancel();
      } catch (_) {}
    }
    _composerFocusNode.removeListener(_onComposerFocusForHubCollapse);
    _composerFocusNode.dispose();
    _chatController.dispose();
    if (widget.modalListScrollController != null) {
      widget.modalListScrollController!
          .removeListener(_onChatScrollControllerTick);
    } else {
      _ownedScrollController?.removeListener(_onChatScrollControllerTick);
      _ownedScrollController?.dispose();
    }
    super.dispose();
  }

  Future<({double lat, double lng, String city})> _getLocation() async {
    final position = await ref.read(userLocationProvider.future);
    final city = ref.read(locationNotifierProvider).value ?? 'Rotterdam';
    return (
      lat: position?.latitude ?? 51.9225,
      lng: position?.longitude ?? 4.4792,
      city: city,
    );
  }

  void _setHubPeekOpenNextFrame(bool open) {
    if (_hubPeekOpen == open) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _hubPeekOpen = open);
    });
  }

  void _toggleHubPeekNextFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _hubPeekOpen = !_hubPeekOpen);
    });
  }

  ({DateTime fireAt, String summary})? _extractReminderIntent(
    String input,
    String languageCode,
  ) {
    final t = input.toLowerCase().trim();
    final asksReminder = t.contains('herinner') ||
        t.contains('remind me') ||
        t.contains('remember me') ||
        t.contains('reminder');
    if (!asksReminder) return null;

    // Match Moody's reply language to the message, not only app locale.
    final useNl = languageCode == 'nl' || t.contains('herinner');

    final minuteMatch = RegExp(
      r'(\d+)\s*(min|mins|minute|minutes|minuut|minuten)\b',
    ).firstMatch(t);
    if (minuteMatch != null) {
      final m = int.tryParse(minuteMatch.group(1) ?? '');
      if (m != null && m > 0) {
        return (
          fireAt: MoodyClock.now().add(Duration(minutes: m)),
          summary: useNl
              ? 'Ik herinner je eraan over $m minuten.'
              : 'I will remind you in $m minutes.',
        );
      }
    }

    if (t.contains('morgen') || t.contains('tomorrow')) {
      final now = MoodyClock.now();
      final tomorrow = DateTime(now.year, now.month, now.day).add(
        const Duration(days: 1),
      );
      return (
        fireAt: tomorrow.add(const Duration(hours: 9)),
        summary: useNl
            ? 'Ik herinner je hier morgen om 09:00 aan.'
            : 'I will remind you about this tomorrow at 09:00.',
      );
    }

    return null;
  }

  void _openMessageActions(_ChatMsg msg) {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.copy_rounded, color: _wmForest),
                    title: Text(
                      l10n.chatSheetMessageCopy,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: _wmCharcoal,
                      ),
                    ),
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: msg.copyableText),
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.chatSheetCopied),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.reply_rounded, color: _wmForest),
                    title: Text(
                      l10n.chatSheetMessageReply,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: _wmCharcoal,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      if (!mounted) return;
                      setState(() {
                        _replyDraft = _ReplyDraft(
                          quotedText: msg.message,
                          quotedIsUser: msg.isUser,
                        );
                      });
                      _composerFocusNode.requestFocus();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _exitModalToMoodyHub() {
    HapticFeedback.lightImpact();
    Navigator.of(context).maybePop();
    ref.read(mainTabProvider.notifier).state = _moodyTabIndex;
  }

  /// Moody tab: back expands the hub hero (MoodyActionSheet) when chat has focus.
  void _embeddedBackToHubOverview() {
    HapticFeedback.lightImpact();
    if (!widget.embedded) return;
    if (widget.chatMessages.isEmpty || _hubPeekOpen) return;
    _setHubPeekOpenNextFrame(true);
  }

  /// Shared chrome: back, Moody + online, menu (Explore sheet + Moody Hub tab).
  Widget _moodyChatChromeAppBar({
    VoidCallback? onBack,
    required String backTooltip,
  }) {
    final l10n = AppLocalizations.of(context);
    final nl = Localizations.localeOf(context).languageCode == 'nl';
    final online = ref.watch(isConnectedProvider).valueOrNull ?? true;
    final onlineLabel = online
        ? (nl ? 'Online' : 'Online')
        : (nl ? 'Offline' : 'Offline');
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: _wmCharcoal,
              tooltip: backTooltip,
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MoodyCharacter(size: 32),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n?.chatSheetMoodyName ?? 'Moody',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _wmCharcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: online
                                    ? const Color(0xFF3CB371)
                                    : _wmStone,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              onlineLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: _wmStone,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _openEarlierChatsPicker,
              icon: const Icon(Icons.menu_rounded),
              color: _wmCharcoal,
              tooltip: nl ? 'Chats van eerdere dagen' : 'Chats from previous days',
            ),
          ],
        ),
      ),
    );
  }

  Widget _modalChatAppBar() {
    final nl = Localizations.localeOf(context).languageCode == 'nl';
    return _moodyChatChromeAppBar(
      onBack: _exitModalToMoodyHub,
      backTooltip: nl ? 'Terug naar Moody Hub' : 'Back to Moody Hub',
    );
  }

  Widget _embeddedMoodyChatChromeAppBar() {
    final nl = Localizations.localeOf(context).languageCode == 'nl';
    final hasThread = widget.chatMessages.isNotEmpty;
    return _moodyChatChromeAppBar(
      onBack: (hasThread && !_hubPeekOpen) ? _embeddedBackToHubOverview : null,
      backTooltip: nl
          ? 'Terug naar Moody Hub-overzicht'
          : 'Back to Moody Hub overview',
    );
  }

  /// Rich context row for Explore / place-thread modal (photo + copy).
  Widget _sharedPlaceAnchorCard(AppLocalizations? l10n) {
    final sp = widget.sharedPlaceContext!;
    final title = (sp['title'] as String?)?.trim() ?? '';
    final address = (sp['address'] as String?)?.trim() ?? '';
    final ed = (sp['editorialSummary'] as String?)?.trim() ?? '';
    final photo = (sp['primaryPhotoUrl'] as String?)?.trim();
    final types = sp['types'];
    String? typeLine;
    if (types is List && types.isNotEmpty) {
      typeLine = types.take(3).map((e) => e.toString()).join(' · ');
    }
    final chip = l10n?.myDayAskMoodyButton ?? 'Ask Moody';

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _wmForest.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: photo != null && photo.isNotEmpty
                    ? WmPlacePhotoNetworkImage(
                        photo,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: _wmForestTint,
                        child: Icon(Icons.place_rounded,
                            color: _wmForest.withValues(alpha: 0.65), size: 36),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chip,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _wmForest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title.isEmpty ? '—' : title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _wmCharcoal,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: _wmStone,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (typeLine != null && typeLine.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      typeLine,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: _wmStone,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (ed.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      ed.length > 220 ? '${ed.substring(0, 220)}…' : ed,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.35,
                        color: _wmCharcoal.withValues(alpha: 0.88),
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chat list when the hub is collapsed. (When expanded, chat is shown
  /// after the user taps the strip below the hub or collapses the handle.)
  Widget _hubBelowPanel({bool skipInlineMoodyHeader = false}) {
    final l10n = AppLocalizations.of(context);
    return _ScrollChatWhenMetricsChange(
      scrollController: _effectiveScroll,
      shouldAdjustScrollOnMetrics: _metricsDrivenUpdatesAllowed,
      child: Column(
        children: [
          if (widget.sharedPlaceContext != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: skipInlineMoodyHeader
                  ? _sharedPlaceAnchorCard(l10n)
                  : Material(
                      color: _wmForestTint,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 18, color: _wmForest),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${l10n?.myDayAskMoodyButton ?? 'Ask Moody'} · ${widget.sharedPlaceContext!['title'] ?? ''}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _wmCharcoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
          if (!skipInlineMoodyHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const MoodyCharacter(size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n?.chatSheetMoodyName ?? 'Moody',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _wmCharcoal,
                      ),
                    ),
                  ),
                  if (_hasEarlierChats)
                    TextButton.icon(
                      onPressed: _openEarlierChatsPicker,
                      icon: const Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: _wmForest,
                      ),
                      label: Text(
                        Localizations.localeOf(context).languageCode == 'nl'
                            ? 'Eerder'
                            : 'History',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _wmForest,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: _wmForest.withValues(alpha: 0.2),
                          ),
                        ),
                        foregroundColor: _wmForest,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _effectiveScroll,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              itemCount: widget.chatMessages.length,
              itemBuilder: (context, index) {
                final m = widget.chatMessages[index];
                return _MessageBubble(
                  msg: m,
                  moodyName: l10n?.chatSheetMoodyName ?? 'Moody',
                  youLabel: l10n?.chatSheetReplyLabelYou ?? 'You',
                  onLongPress: () => _openMessageActions(m),
                );
              },
            ),
          ),
          if (_isAILoading) const _MoodyTypingIndicator(),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isAILoading) return;

    final trimmed = text.trim();
    final languageCode = Localizations.localeOf(context).languageCode;
    final reminderIntent = _extractReminderIntent(trimmed, languageCode);

    if (reminderIntent != null) {
      final online = await ref.read(connectivityServiceProvider).isConnected;
      if (!mounted) return;
      if (!online) {
        showOfflineSnackBar(context);
        return;
      }

      // Same UX as AI path: user bubble first, then typing, then reply.
      final replySnap = _replyDraft;
      setState(() {
        widget.chatMessages.add(
          _ChatMsg(
            message: trimmed,
            isUser: true,
            timestamp: MoodyClock.now(),
            replyToText: replySnap?.quotedText,
            replyToIsUser: replySnap?.quotedIsUser,
          ),
        );
        _replyDraft = null;
        _isAILoading = true;
        if (_hubPeekOpen) _hubPeekOpen = false;
      });
      await _persistChat();
      _scheduleMoodyChatScroll(_effectiveScroll);
      _chatController.clear();
      FocusManager.instance.primaryFocus?.unfocus();

      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      final reminderId =
          reminderIntent.fireAt.millisecondsSinceEpoch.remainder(1 << 30);
      final notificationNl =
          languageCode == 'nl' || trimmed.toLowerCase().contains('herinner');
      try {
        await NotificationService.instance.scheduleAt(
          reminderId,
          NotificationCopy(
            title: 'Moody',
            body: notificationNl
                ? 'Herinnering: denk aan wat je net met mij besprak.'
                : 'Reminder: remember what you just discussed with me.',
          ),
          reminderIntent.fireAt,
        );
        mirrorMoodyChatReminderToInAppNotification(
          fireAt: reminderIntent.fireAt,
          localNotificationId: reminderId,
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        widget.chatMessages.add(
          _ChatMsg(
            message: reminderIntent.summary,
            isUser: false,
            timestamp: MoodyClock.now(),
          ),
        );
        _isAILoading = false;
      });
      await _persistChat();
      _scheduleMoodyChatScroll(_effectiveScroll);
      return;
    }

    final online = await ref.read(connectivityServiceProvider).isConnected;
    if (!mounted) return;
    if (!online) {
      showOfflineSnackBar(context);
      return;
    }

    final replySnap = _replyDraft;
    setState(() {
      widget.chatMessages.add(_ChatMsg(
        message: trimmed,
        isUser: true,
        timestamp: MoodyClock.now(),
        replyToText: replySnap?.quotedText,
        replyToIsUser: replySnap?.quotedIsUser,
      ));
      _replyDraft = null;
      _isAILoading = true;
      if (_hubPeekOpen) _hubPeekOpen = false;
    });
    await _persistChat();
    _scheduleMoodyChatScroll(_effectiveScroll);
    _chatController.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final loc = await _getLocation();
      if (!mounted) return;
      final convId = _conversationIdForApi;
      final msgs = widget.chatMessages;
      final priorTurns = msgs.length > 1
          ? msgs
              .sublist(0, msgs.length - 1)
              .map((m) => {
                    'role': m.isUser ? 'user' : 'assistant',
                    'content': _historyContentForAi(m),
                  })
              .toList()
          : null;
      final response = await WanderMoodAIService.chat(
        message: _userMessageForAiApi(
          trimmed,
          replySnap?.quotedText,
          replySnap?.quotedIsUser,
        ),
        conversationId: convId,
        moods: widget.moods,
        latitude: loc.lat,
        longitude: loc.lng,
        city: loc.city,
        planningCalendarDateIso:
            _calendarDateOnlyIso(ref.read(selectedMyDayDateProvider)),
        clientTurns: priorTurns,
        languageCode: Localizations.localeOf(context).languageCode,
        sharedPlace: widget.sharedPlaceContext,
      );

      if (!mounted) return;
      if (!_usesPlaceThreadBucket) {
        _DailyMoodyChatCache.setConversationIdFromServer(response.conversationId);
      }
      final sid = response.conversationId?.trim();
      setState(() {
        if (sid != null && sid.isNotEmpty) {
          _conversationIdForApi = sid;
        }
        widget.chatMessages.add(_ChatMsg(
          message: response.message,
          isUser: false,
          timestamp: MoodyClock.now(),
          suggestedPlaces: response.suggestedPlaces,
        ));
        _isAILoading = false;
      });
      await _persistChat();
      _scheduleMoodyChatScroll(_effectiveScroll);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        widget.chatMessages.add(_ChatMsg(
          message: l10n?.chatSheetErrorMessage ??
              'Sorry, I hit a snag. Try again in a moment.',
          isUser: false,
          timestamp: MoodyClock.now(),
        ));
        _isAILoading = false;
      });
      await _persistChat();
      _scheduleMoodyChatScroll(_effectiveScroll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasThread = widget.chatMessages.isNotEmpty;
    final sheetExpanded = !hasThread || _hubPeekOpen;

    return _RepaintWhenKeyboardMetricsChange(
      shouldRepaintOnMetrics: _metricsDrivenUpdatesAllowed,
      builder: (context) {
        final mq = MediaQuery.of(context);
        final insets = _moodyChatSheetSafeInsets(mq);
        final topInset = insets.top;
        final keyboardBottom = mq.viewInsets.bottom;
        final inputBottomPad = keyboardBottom > 0
            ? keyboardBottom
            : math.max(insets.bottom, mq.padding.bottom);
        final maxSheetHeight = mq.size.height - topInset;
        final isDraggableModal =
            widget.modalDraggableLayout && !widget.embedded;

        return LayoutBuilder(
          builder: (context, constraints) {
            var sheetHeight = maxSheetHeight * _kMoodyChatSheetHeightFactor;
            var sheetTopGap = maxSheetHeight - sheetHeight;
            if (isDraggableModal &&
                constraints.hasBoundedHeight &&
                constraints.maxHeight.isFinite &&
                constraints.maxHeight > 0) {
              sheetHeight = constraints.maxHeight;
              sheetTopGap = 0;
            }

            return ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.embedded ? 0 : 10,
                  sigmaY: widget.embedded ? 0 : 10,
                ),
                child: Padding(
                  padding: widget.embedded
                      ? EdgeInsets.only(top: topInset)
                      : (isDraggableModal
                          ? EdgeInsets.zero
                          : EdgeInsets.only(top: topInset + sheetTopGap)),
                  child: SizedBox(
                    height: widget.embedded
                        ? mq.size.height - topInset
                        : sheetHeight,
                    child: ClipRRect(
                  borderRadius: widget.embedded
                      ? BorderRadius.zero
                      : const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Column(
                        children: const [
                          Expanded(
                              flex: 5, child: ColoredBox(color: _wmSkyTint)),
                          Expanded(flex: 5, child: ColoredBox(color: _wmCream)),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: insets.left,
                          right: insets.right,
                        ),
                        child: Column(
                          children: [
                            if (widget.embedded)
                              _embeddedMoodyChatChromeAppBar(),
                            Expanded(
                              child: widget.embedded
                                  ? LayoutBuilder(
                                      builder: (context, constraints) {
                                        final maxH = constraints.maxHeight;
                                        if (!maxH.isFinite || maxH <= 0) {
                                          return const SizedBox.shrink();
                                        }

                                        // Collapsed: hub strip + chat (modal only). Embedded
                                        // Moody tab uses chrome back for hub — no ^ pill strip.
                                        if (hasThread && !sheetExpanded) {
                                          if (widget.embedded) {
                                            return _hubBelowPanel(
                                              skipInlineMoodyHeader: true,
                                            );
                                          }
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              ClipRect(
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 320),
                                                  curve: Curves.easeOutCubic,
                                                  height: MoodyActionSheet
                                                      .collapsedHeightTappable,
                                                  child: MoodyActionSheet(
                                                    expanded: false,
                                                    onToggle:
                                                        _toggleHubPeekNextFrame,
                                                    onChat: (msg) {
                                                      _collapseHubForChat();
                                                      _sendMessage(msg);
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: _hubBelowPanel(
                                                  skipInlineMoodyHeader: true,
                                                ),
                                              ),
                                            ],
                                          );
                                        }

                                        // Expanded hub: full width minus a tap strip for
                                        // “show chat” / dismiss peek (when there is a thread).
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: ClipRect(
                                                child: MoodyActionSheet(
                                                  expanded: true,
                                                  onToggle: hasThread
                                                      ? _toggleHubPeekNextFrame
                                                      : null,
                                                  onChat: (msg) {
                                                    _collapseHubForChat();
                                                    _sendMessage(msg);
                                                  },
                                                ),
                                              ),
                                            ),
                                            if (hasThread &&
                                                sheetExpanded &&
                                                _hubPeekOpen)
                                              GestureDetector(
                                                onTap: () =>
                                                    _setHubPeekOpenNextFrame(
                                                        false),
                                                behavior: HitTestBehavior
                                                    .translucent,
                                                child: Semantics(
                                                  button: true,
                                                  label: 'Show chat',
                                                  child: const SizedBox(
                                                    height: 56,
                                                    width: double.infinity,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 6, bottom: 2),
                                          child: Center(
                                            child: Container(
                                              width: 40,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: _wmStone.withValues(
                                                    alpha: 0.35),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                          ),
                                        ),
                                        _modalChatAppBar(),
                                        Expanded(
                                          child: _hubBelowPanel(
                                              skipInlineMoodyHeader: true),
                                        ),
                                      ],
                                    ),
                            ),
                            AnimatedPadding(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              padding: EdgeInsets.only(bottom: inputBottomPad),
                              child: Material(
                                color: Colors.transparent,
                                child: Consumer(
                                  builder: (context, ref, _) {
                                    final async = ref.watch(isConnectedProvider);
                                    final online = async.valueOrNull ?? true;
                                    if (!online) {
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        child: const Text(
                                          'Moody needs internet to chat — connect and try again',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF8C8780),
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    }
                                    final l10n = AppLocalizations.of(context);
                                    final draft = _replyDraft;
                                    return _MoodyChatInput(
                                      controller: _chatController,
                                      focusNode: _composerFocusNode,
                                      isLoading: _isAILoading,
                                      hasSelectedMood: widget.moods.isNotEmpty,
                                      onSend: _sendMessage,
                                      onComposerTap: _collapseHubForChat,
                                      showMic: !kIsWeb,
                                      isListening: _isListening,
                                      onMicTap:
                                          kIsWeb ? null : _toggleListening,
                                      replyQuotedLabel: draft == null
                                          ? null
                                          : (draft.quotedIsUser
                                              ? (l10n?.chatSheetReplyLabelYou ??
                                                  'You')
                                              : (l10n?.chatSheetMoodyName ??
                                                  'Moody')),
                                      replyQuotedSnippet: draft?.quotedText,
                                      onCancelReply: draft == null
                                          ? null
                                          : () => setState(
                                                () => _replyDraft = null,
                                              ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }
}

/// Keeps the latest messages in view when the keyboard opens or safe area changes.
class _ScrollChatWhenMetricsChange extends StatefulWidget {
  const _ScrollChatWhenMetricsChange({
    required this.scrollController,
    required this.child,
    this.shouldAdjustScrollOnMetrics,
  });

  final ScrollController scrollController;
  final Widget child;

  /// When this returns false, [didChangeMetrics] does not scroll (offstage tab).
  final bool Function()? shouldAdjustScrollOnMetrics;

  @override
  State<_ScrollChatWhenMetricsChange> createState() =>
      _ScrollChatWhenMetricsChangeState();
}

class _ScrollChatWhenMetricsChangeState extends State<_ScrollChatWhenMetricsChange>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMoodyChatScroll(widget.scrollController);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final allow = widget.shouldAdjustScrollOnMetrics?.call() ?? true;
    if (!allow) return;
    final c = widget.scrollController;
    if (!c.hasClients) return;
    _clampMoodyChatScrollPastEnd(c);
    if (!c.hasClients) return;
    final pos = c.position;
    const stickiness = 120.0;
    final nearBottom = pos.maxScrollExtent - pos.pixels <= stickiness;
    if (nearBottom) {
      _scheduleMoodyChatScroll(c, animate: false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// iOS often does not rebuild modal bottom sheets when the keyboard opens;
/// this forces a rebuild when [WidgetsBindingObserver.didChangeMetrics] fires.
///
/// For the embedded Moody tab, [shouldRepaintOnMetrics] must be false while the
/// tab is [Offstage] so we do not [setState] during Explore (or other tabs).
class _RepaintWhenKeyboardMetricsChange extends StatefulWidget {
  const _RepaintWhenKeyboardMetricsChange({
    required this.builder,
    required this.shouldRepaintOnMetrics,
  });

  final WidgetBuilder builder;
  final bool Function() shouldRepaintOnMetrics;

  @override
  State<_RepaintWhenKeyboardMetricsChange> createState() =>
      _RepaintWhenKeyboardMetricsChangeState();
}

class _RepaintWhenKeyboardMetricsChangeState
    extends State<_RepaintWhenKeyboardMetricsChange> with WidgetsBindingObserver {
  bool _metricsRebuildScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Must not call setState synchronously here: this can fire during layout /
    // semantics and triggers cascading assertions (`!semantics.parentDataDirty`,
    // sliver child.hasSize, etc.) especially with Offstage tabs + animated chrome.
    if (!mounted || _metricsRebuildScheduled) return;
    _metricsRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metricsRebuildScheduled = false;
      if (!mounted) return;
      if (!widget.shouldRepaintOnMetrics()) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// Header + hero actions now live together inside `MoodyActionSheet`.

// ---------------------------------------------------------------------------
// Message Bubble
// ---------------------------------------------------------------------------
class _MessageBubble extends StatelessWidget {
  final _ChatMsg msg;
  final String moodyName;
  final String youLabel;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.msg,
    required this.moodyName,
    required this.youLabel,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final places = msg.suggestedPlaces;
    final showPlaces =
        !msg.isUser && places != null && places.isNotEmpty;

    final quote = msg.replyToText?.trim();
    final showQuote = quote != null && quote.isNotEmpty;
    final quoteAuthor =
        msg.replyToIsUser == true ? youLabel : moodyName;

    final bubbleBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showQuote) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                constraints: const BoxConstraints(minHeight: 32),
                decoration: BoxDecoration(
                  color: msg.isUser
                      ? Colors.white.withValues(alpha: 0.55)
                      : _wmForest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quoteAuthor,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: msg.isUser
                            ? Colors.white.withValues(alpha: 0.9)
                            : _wmForest,
                      ),
                    ),
                    Text(
                      quote,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.35,
                        color: msg.isUser
                            ? Colors.white.withValues(alpha: 0.88)
                            : const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (!msg.isUser && msg.moodyThreadOpener)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _wmForestTint,
                  border: Border.all(
                    color: _wmForest.withValues(alpha: 0.14),
                  ),
                ),
                child: const Center(child: MoodyCharacter(size: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg.message,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
                    color: _wmCharcoal,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            msg.message,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: msg.isUser ? Colors.white : _wmCharcoal,
              height: 1.4,
            ),
          ),
      ],
    );

    final bubble = GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          minWidth: 80,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: msg.isUser
              ? const LinearGradient(
                  colors: [_wmForest, Color(0xFF347558)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [_wmForestTint, _wmSkyTint],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: msg.isUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: msg.isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          border: Border.all(
            color: msg.isUser
                ? Colors.white.withValues(alpha: 0.22)
                : _wmForest.withValues(alpha: 0.16),
            width: 1,
          ),
          boxShadow: const [],
        ),
        child: bubbleBody,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Column(
        crossAxisAlignment: msg.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (msg.isUser)
            Align(
              alignment: Alignment.centerRight,
              child: bubble,
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: bubble,
            ),
          if (showPlaces)
            MoodySuggestedPlacesRow(
              places: places,
              leftInset: 20,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing Indicator
// ---------------------------------------------------------------------------
class _MoodyTypingIndicator extends StatelessWidget {
  const _MoodyTypingIndicator();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _wmSky,
              boxShadow: [],
            ),
            child: const Center(child: MoodyCharacter(size: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _wmSkyTint.withOpacity(0.95),
                border: Border.all(color: _wmParchment.withOpacity(0.6)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: const [],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _wmForest.withOpacity(0.75)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n?.chatSheetCraftingMessage ?? 'Crafting your response…',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF2D3748),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat Input
// ---------------------------------------------------------------------------
class _MoodyChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool hasSelectedMood;
  final ValueChanged<String> onSend;
  final VoidCallback onComposerTap;
  /// Voice input (native only; hidden on web where STT is unavailable).
  final bool showMic;
  final bool isListening;
  final VoidCallback? onMicTap;
  /// When set, shows a WhatsApp-style reply strip above the composer.
  final String? replyQuotedLabel;
  final String? replyQuotedSnippet;
  final VoidCallback? onCancelReply;

  const _MoodyChatInput({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.hasSelectedMood,
    required this.onSend,
    required this.onComposerTap,
    required this.showMic,
    required this.isListening,
    this.onMicTap,
    this.replyQuotedLabel,
    this.replyQuotedSnippet,
    this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDutch = Localizations.localeOf(context).languageCode == 'nl';
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final replySnippet = replyQuotedSnippet?.trim() ?? '';
    final showReply = replySnippet.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showReply)
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: kb > 0 ? 6 : 8,
            ),
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _wmForest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            replyQuotedLabel ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _wmForest,
                            ),
                          ),
                          Text(
                            replySnippet,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              height: 1.3,
                              color: const Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: _wmCharcoal.withValues(alpha: 0.55),
                      ),
                      onPressed: onCancelReply,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 6,
            bottom: kb > 0 ? 6 : 10,
          ),
          decoration: const BoxDecoration(
            color: Colors.transparent,
            boxShadow: [],
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final hasTyped = controller.text.trim().isNotEmpty;
              final collapseMic = hasTyped && !isListening;
              final showMicSlot =
                  showMic && onMicTap != null && !collapseMic;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.send,
                      keyboardType: TextInputType.text,
                      scrollPadding:
                          const EdgeInsets.only(bottom: 80, top: 48),
                      onTap: onComposerTap,
                      decoration: InputDecoration(
                        hintText: hasSelectedMood
                            ? (isDutch
                                ? 'Praat met Moody over je dag...'
                                : 'Talk to Moody about your day...')
                            : (l10n?.chatSheetInputHint ??
                                "What's your mood today?"),
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.82),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(
                            color: _wmParchment.withValues(alpha: 0.95),
                            width: 1.1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(
                            color: _wmForest.withValues(alpha: 0.5),
                            width: 1.25,
                          ),
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.psychology_outlined,
                            color: _wmForest.withValues(alpha: 0.75),
                            size: 22,
                          ),
                        ),
                      ),
                      style: GoogleFonts.poppins(
                          fontSize: 15, color: const Color(0xFF1A202C)),
                      enabled: !isLoading && !isListening,
                      onSubmitted: onSend,
                    ),
                  ),
                  if (showMic && onMicTap != null)
                    ClipRect(
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.centerLeft,
                        widthFactor: showMicSlot ? 1 : 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: showMicSlot ? 1 : 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 6),
                              _MicButton(
                                isListening: isListening,
                                onTap: isLoading ? () {} : onMicTap!,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  _SendButton(
                    isLoading: isLoading,
                    enabled: controller.text.trim().isNotEmpty,
                    onTap: () => onSend(controller.text),
                    controllerRef: controller,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// In-line microphone toggle rendered inside the composer's suffix. Shows a
/// breathing red halo while Moody is actively listening.
class _MicButton extends StatelessWidget {
  const _MicButton({required this.isListening, required this.onTap});

  final bool isListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = isListening ? const Color(0xFFDC2626) : _wmForest;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening
                  ? tint.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: Border.all(
                color: tint.withValues(alpha: isListening ? 0.55 : 0.25),
                width: 1,
              ),
            ),
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: tint,
              size: 18,
            ),
          ),
        ),
      ),
    )
        .animate(target: isListening ? 1 : 0)
        .scaleXY(end: 1.06, duration: 600.ms, curve: Curves.easeInOut)
        .then()
        .scaleXY(end: 1 / 1.06, duration: 600.ms, curve: Curves.easeInOut);
  }
}

/// Send button that reacts to composer emptiness so users get a clear
/// affordance when dictation has not yet produced content.
class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.isLoading,
    required this.enabled,
    required this.onTap,
    required this.controllerRef,
  });

  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;
  final TextEditingController controllerRef;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  @override
  void initState() {
    super.initState();
    widget.controllerRef.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controllerRef.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        !widget.isLoading && widget.controllerRef.text.trim().isNotEmpty;
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 180),
      child: Container(
        width: 46,
        height: 46,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: _wmForest,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(23),
            onTap: enabled ? widget.onTap : null,
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
