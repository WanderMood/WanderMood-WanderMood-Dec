import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:wandermood/features/home/presentation/screens/main_screen.dart'
    show mainTabProvider;
import 'package:wandermood/features/home/presentation/widgets/moody_action_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';

// WanderMood v2 — Moody chat (Screen 9)
const Color _wmSkyTint = Color(0xFFF1F7FB);
/// Slightly warmer than legacy cream so the composer separates from the field.
const Color _wmCream = Color(0xFFF1E9DD);
const Color _wmSky = Color(0xFFC5DCEB);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);

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
  _ChatMsg(
      {required this.message,
      required this.isUser,
      required this.timestamp,
      this.suggestedPlaces});
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
}

Map<String, dynamic> _chatMsgToJson(_ChatMsg m) {
  return {
    'message': m.message,
    'isUser': m.isUser,
    'timestamp': m.timestamp.toIso8601String(),
    'suggestedPlaces': m.suggestedPlaces?.map((e) => e.toJson()).toList(),
  };
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
  return _ChatMsg(
    message: j['message'] as String? ?? '',
    isUser: j['isUser'] as bool? ?? false,
    timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
        MoodyClock.now(),
    suggestedPlaces: suggested,
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
    enableDrag: false,
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

/// Full chat-first Moody tab surface (non-modal).
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
  });

  final List<_ChatMsg> chatMessages;
  final String conversationId;
  final List<String> moods;
  final bool embedded;

  @override
  ConsumerState<_MoodyChatSheetContent> createState() =>
      _MoodyChatSheetContentState();
}

class _MoodyChatSheetContentState extends ConsumerState<_MoodyChatSheetContent> {
  late final TextEditingController _chatController;
  late final ScrollController _scrollController;
  late final FocusNode _composerFocusNode;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAILoading = false;
  bool _isListening = false;
  bool _sttInitialized = false;
  bool _sttAvailable = false;
  Timer? _sttSilenceTimer;
  String _composerTextBeforeListen = '';

  /// Hub open = hero/actions; closed = chat focus. Default open; closes on send;
  /// re-opens when returning to the Moody tab from another bottom-nav tab.
  bool _hubPeekOpen = true;

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

  Future<void> _persistChat() async {
    try {
      await _DailyMoodyChatCache.persistToPrefs(
        ref.read(sharedPreferencesProvider),
        MoodyClock.now(),
      );
    } catch (_) {}
  }

  void _onChatScrollControllerTick() {
    _clampMoodyChatScrollPastEnd(_scrollController);
  }

  @override
  void initState() {
    super.initState();
    _chatController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onChatScrollControllerTick);
    _composerFocusNode = FocusNode();
    _composerFocusNode.addListener(_onComposerFocusForHubCollapse);
  }

  /// Collapse expanded hub so the chat thread is visible. Called from composer
  /// focus and from every tap on the field (tap does not refocus if already
  /// focused, so [onTap] is required).
  void _collapseHubForChat() {
    final hasThread = widget.chatMessages.isNotEmpty;
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
  }

  /// Lazily initialize speech recognition the first time the user taps the mic.
  /// Defers the microphone permission prompt until the feature is actually used.
  Future<bool> _ensureSpeechInitialized() async {
    if (_sttInitialized) return _sttAvailable;
    _sttInitialized = true;

    if (kIsWeb) {
      _sttAvailable = false;
      return false;
    }

    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        _sttAvailable = false;
        return false;
      }
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
    } catch (e) {
      if (kDebugMode) debugPrint('Moody STT init failed: $e');
      _sttAvailable = false;
    }
    return _sttAvailable;
  }

  Future<void> _toggleListening() async {
    if (_isAILoading) return;
    if (_isListening) {
      await _stopListening();
      return;
    }

    final ready = await _ensureSpeechInitialized();
    if (!ready || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone access is needed for voice input.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _composerTextBeforeListen = _chatController.text;
    setState(() => _isListening = true);

    final locale = _moodyChatSttLocale(
      Localizations.localeOf(context).languageCode,
    );

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
    unawaited(_persistChat());
    _sttSilenceTimer?.cancel();
    if (!kIsWeb) {
      try {
        _speech.cancel();
      } catch (_) {}
    }
    _composerFocusNode.removeListener(_onComposerFocusForHubCollapse);
    _composerFocusNode.dispose();
    _chatController.dispose();
    _scrollController.removeListener(_onChatScrollControllerTick);
    _scrollController.dispose();
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

  /// Chat list when the hub is collapsed. (When expanded, chat is shown
  /// after the user taps the strip below the hub or collapses the handle.)
  Widget _hubBelowPanel() {
    return _ScrollChatWhenMetricsChange(
      scrollController: _scrollController,
      shouldAdjustScrollOnMetrics: _metricsDrivenUpdatesAllowed,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              itemCount: widget.chatMessages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(msg: widget.chatMessages[index]);
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

    final online = await ref.read(connectivityServiceProvider).isConnected;
    if (!mounted) return;
    if (!online) {
      showOfflineSnackBar(context);
      return;
    }

    setState(() {
      widget.chatMessages.add(_ChatMsg(
          message: text.trim(), isUser: true, timestamp: MoodyClock.now()));
      _isAILoading = true;
      if (_hubPeekOpen) _hubPeekOpen = false;
    });
    await _persistChat();
    _scheduleMoodyChatScroll(_scrollController);
    _chatController.clear();

    try {
      final loc = await _getLocation();
      if (!mounted) return;
      final convId = _DailyMoodyChatCache.getConversationId(MoodyClock.now());
      final msgs = widget.chatMessages;
      final priorTurns = msgs.length > 1
          ? msgs
              .sublist(0, msgs.length - 1)
              .map((m) => {
                    'role': m.isUser ? 'user' : 'assistant',
                    'content': m.message,
                  })
              .toList()
          : null;
      final response = await WanderMoodAIService.chat(
        message: text.trim(),
        conversationId: convId,
        moods: widget.moods,
        latitude: loc.lat,
        longitude: loc.lng,
        city: loc.city,
        planningCalendarDateIso:
            _calendarDateOnlyIso(ref.read(selectedMyDayDateProvider)),
        clientTurns: priorTurns,
        languageCode: Localizations.localeOf(context).languageCode,
      );

      if (!mounted) return;
      _DailyMoodyChatCache.setConversationIdFromServer(response.conversationId);
      setState(() {
        widget.chatMessages.add(_ChatMsg(
          message: response.message,
          isUser: false,
          timestamp: MoodyClock.now(),
          suggestedPlaces: response.suggestedPlaces,
        ));
        _isAILoading = false;
      });
      await _persistChat();
      _scheduleMoodyChatScroll(_scrollController);
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
      _scheduleMoodyChatScroll(_scrollController);
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
        final sheetHeight = maxSheetHeight * _kMoodyChatSheetHeightFactor;
        final sheetTopGap = maxSheetHeight - sheetHeight;

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.embedded ? 0 : 10,
              sigmaY: widget.embedded ? 0 : 10,
            ),
            child: Padding(
              padding: widget.embedded
                  ? EdgeInsets.only(top: topInset)
                  : EdgeInsets.only(top: topInset + sheetTopGap),
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
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxH = constraints.maxHeight;
                                  if (!maxH.isFinite || maxH <= 0) {
                                    return const SizedBox.shrink();
                                  }

                                  // Collapsed: narrow hub strip + chat fills the rest.
                                  if (hasThread && !sheetExpanded) {
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
                                              onToggle: _toggleHubPeekNextFrame,
                                              onChat: (msg) {
                                                _collapseHubForChat();
                                                _sendMessage(msg);
                                              },
                                            ),
                                          ),
                                        ),
                                        Expanded(child: _hubBelowPanel()),
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
                                              _setHubPeekOpenNextFrame(false),
                                          behavior:
                                              HitTestBehavior.translucent,
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
                                    return _MoodyChatInput(
                                      controller: _chatController,
                                      focusNode: _composerFocusNode,
                                      isLoading: _isAILoading,
                                      onSend: _sendMessage,
                                      onMicTap: _toggleListening,
                                      isListening: _isListening,
                                      onComposerTap: _collapseHubForChat,
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
  const _MessageBubble({required this.msg});

  static const double _avatarBlockWidth = 36 + 10;

  @override
  Widget build(BuildContext context) {
    final places = msg.suggestedPlaces;
    final showPlaces =
        !msg.isUser && places != null && places.isNotEmpty;

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
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
          bottomLeft:
              msg.isUser ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight:
              msg.isUser ? const Radius.circular(4) : const Radius.circular(20),
        ),
        boxShadow: const [],
      ),
      child: Text(
        msg.message,
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: msg.isUser ? Colors.white : _wmCharcoal,
          height: 1.4,
        ),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _wmSky,
                    boxShadow: [],
                  ),
                  child: const Center(child: MoodyCharacter(size: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: bubble,
                  ),
                ),
              ],
            ),
          if (showPlaces)
            MoodySuggestedPlacesRow(
              places: places,
              leftInset: 20 + _avatarBlockWidth,
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
  final ValueChanged<String> onSend;
  final VoidCallback onMicTap;
  final bool isListening;
  final VoidCallback onComposerTap;

  const _MoodyChatInput({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.onMicTap,
    required this.isListening,
    required this.onComposerTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.send,
                  keyboardType: TextInputType.text,
                  scrollPadding: const EdgeInsets.only(bottom: 80, top: 48),
                  onTap: onComposerTap,
                  decoration: InputDecoration(
                    hintText: isListening
                        ? 'Listening…'
                        : (l10n?.chatSheetInputHint ?? "What's your mood today?"),
                    hintStyle: GoogleFonts.poppins(
                      color: isListening
                          ? const Color(0xFFDC2626)
                          : Colors.grey[500],
                      fontSize: 15,
                      fontWeight:
                          isListening ? FontWeight.w600 : FontWeight.w400,
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
                    suffixIcon: _MicButton(
                      isListening: isListening,
                      onTap: onMicTap,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                      fontSize: 15, color: const Color(0xFF1A202C)),
                  onSubmitted: onSend,
                );
              },
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
      ),
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
