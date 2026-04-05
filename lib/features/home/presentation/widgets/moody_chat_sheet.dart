import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/core/services/wandermood_ai_service.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/providers/communication_style_provider.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_chat_header_subtitle.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/services/connectivity_service.dart';
import 'package:wandermood/core/utils/offline_feedback.dart';

// WanderMood v2 — Moody chat (Screen 9)
const Color _wmSkyTint = Color(0xFFF1F7FB);
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmSky = Color(0xFFC5DCEB);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);

/// Below 1.0 leaves a strip of scrim above the sheet so it feels slightly shorter.
const double _kMoodyChatSheetHeightFactor = 0.93;

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
  _ChatMsg(
      {required this.message, required this.isUser, required this.timestamp});
}

class _DailyMoodyChatCache {
  static String? _dateKey;
  static String? _conversationId;
  static final List<_ChatMsg> _messages = [];

  static String _keyFor(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

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

  static List<_ChatMsg> getMessages(DateTime now) {
    _resetIfNeeded(now);
    return _messages;
  }
}

void _scheduleMoodyChatScroll(
  ScrollController controller, {
  bool animate = true,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      if (!controller.hasClients) return;
      final target = controller.position.maxScrollExtent;
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
  });
}

/// Opens the Moody chat bottom sheet — the same UI from the original MoodHomeScreen.
/// Can be called from any screen that has access to a [BuildContext] and a [WidgetRef].
void showMoodyChatSheet(BuildContext context, WidgetRef ref) {
  final moods = ref.read(dailyMoodStateNotifierProvider).selectedMoods;
  final now = MoodyClock.now();
  final conversationId = _DailyMoodyChatCache.getConversationId(now);
  final chatMessages = _DailyMoodyChatCache.getMessages(now);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.75),
    // Root route gets reliable viewInsets on iOS when the keyboard opens.
    useRootNavigator: true,
    useSafeArea: false,
    builder: (context) => _MoodyChatSheetContent(
      chatMessages: chatMessages,
      conversationId: conversationId,
      moods: moods,
    ),
  );
}

/// Owns text/scroll controllers so they are disposed with the sheet widget tree.
/// Disposing them in [showModalBottomSheet]'s future caused framework assertions
/// when the route was still tearing down.
class _MoodyChatSheetContent extends ConsumerStatefulWidget {
  const _MoodyChatSheetContent({
    required this.chatMessages,
    required this.conversationId,
    required this.moods,
  });

  final List<_ChatMsg> chatMessages;
  final String conversationId;
  final List<String> moods;

  @override
  ConsumerState<_MoodyChatSheetContent> createState() =>
      _MoodyChatSheetContentState();
}

class _MoodyChatSheetContentState extends ConsumerState<_MoodyChatSheetContent> {
  late final TextEditingController _chatController;
  late final ScrollController _scrollController;
  bool _isAILoading = false;

  @override
  void initState() {
    super.initState();
    _chatController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _chatController.dispose();
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
    });
    _scheduleMoodyChatScroll(_scrollController);
    _chatController.clear();

    try {
      final loc = await _getLocation();
      if (!mounted) return;
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
        conversationId: widget.conversationId,
        moods: widget.moods,
        latitude: loc.lat,
        longitude: loc.lng,
        city: loc.city,
        clientTurns: priorTurns,
        languageCode: Localizations.localeOf(context).languageCode,
      );

      if (!mounted) return;
      setState(() {
        widget.chatMessages.add(_ChatMsg(
            message: response.message,
            isUser: false,
            timestamp: MoodyClock.now()));
        _isAILoading = false;
      });
      _scheduleMoodyChatScroll(_scrollController);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        widget.chatMessages.add(_ChatMsg(
          message: l10n.chatSheetErrorMessage,
          isUser: false,
          timestamp: MoodyClock.now(),
        ));
        _isAILoading = false;
      });
      _scheduleMoodyChatScroll(_scrollController);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RepaintWhenKeyboardMetricsChange(
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
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.only(top: topInset + sheetTopGap),
              child: SizedBox(
                height: sheetHeight,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
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
                            Consumer(
                              builder: (context, ref, _) {
                                final city =
                                    ref.watch(locationNotifierProvider).value;
                                final style = ref
                                    .watch(communicationStyleProvider)
                                    .style;
                                return _MoodyChatHeader(
                                  subtitle: moodyChatTravelBestieSubtitle(
                                    l10n: AppLocalizations.of(context)!,
                                    city: city,
                                    style: style,
                                  ),
                                );
                              },
                            ),
                            Expanded(
                              child: widget.chatMessages.isEmpty
                                  ? _MoodyChatEmptyState(
                                      keyboardOpen: keyboardBottom > 0,
                                    )
                                  : _ScrollChatWhenMetricsChange(
                                      scrollController: _scrollController,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: ListView.builder(
                                              controller: _scrollController,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              itemCount:
                                                  widget.chatMessages.length,
                                              itemBuilder: (context, index) {
                                                return _MessageBubble(
                                                  msg: widget
                                                      .chatMessages[index],
                                                );
                                              },
                                            ),
                                          ),
                                          if (_isAILoading)
                                            const _MoodyTypingIndicator(),
                                        ],
                                      ),
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
                                      isLoading: _isAILoading,
                                      onSend: _sendMessage,
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
  });

  final ScrollController scrollController;
  final Widget child;

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
    _scheduleMoodyChatScroll(widget.scrollController, animate: false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// iOS often does not rebuild modal bottom sheets when the keyboard opens;
/// this forces a rebuild when [WidgetsBindingObserver.didChangeMetrics] fires.
class _RepaintWhenKeyboardMetricsChange extends StatefulWidget {
  const _RepaintWhenKeyboardMetricsChange({required this.builder});

  final WidgetBuilder builder;

  @override
  State<_RepaintWhenKeyboardMetricsChange> createState() =>
      _RepaintWhenKeyboardMetricsChangeState();
}

class _RepaintWhenKeyboardMetricsChangeState
    extends State<_RepaintWhenKeyboardMetricsChange> with WidgetsBindingObserver {
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _MoodyChatHeader extends StatelessWidget {
  const _MoodyChatHeader({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.78),
                Colors.white.withValues(alpha: 0.38),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.45),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _wmSky.withValues(alpha: 0.55),
                          boxShadow: [
                            BoxShadow(
                              color: _wmSky.withValues(alpha: 0.35),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const Center(child: MoodyCharacter(size: 30)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.chatSheetMoodyName,
                              style: GoogleFonts.poppins(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A202C),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '• $subtitle',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF5A6B7A),
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.white.withValues(alpha: 0.55),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.grey.shade700,
                              size: 20,
                            ),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------
class _MoodyChatEmptyState extends StatelessWidget {
  const _MoodyChatEmptyState({this.keyboardOpen = false});

  /// When true, compress hero + copy so the composer stays on screen with the keyboard.
  final bool keyboardOpen;

  @override
  Widget build(BuildContext context) {
    final avatar = keyboardOpen ? 72.0 : 140.0;
    final moodySize = keyboardOpen ? 36.0 : 70.0;
    final verticalPad = keyboardOpen ? 12.0 : 32.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: verticalPad),
      child: Column(
        children: [
          if (!keyboardOpen) const Spacer(),
          if (keyboardOpen) const SizedBox(height: 4),
          Container(
            width: avatar,
            height: avatar,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _wmSky.withOpacity(0.35),
              border: Border.all(
                color: _wmSky.withOpacity(0.65),
                width: 2,
              ),
              boxShadow: const [],
            ),
            child: Center(child: MoodyCharacter(size: moodySize)),
          ),
          SizedBox(height: keyboardOpen ? 12 : 32),
          if (keyboardOpen)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _messageCard(context, compact: true),
              ),
            )
          else ...[
            _messageCard(context, compact: false),
            const Spacer(),
          ],
        ],
      ),
    );
  }

  Widget _messageCard(BuildContext context, {required bool compact}) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: compact ? 12 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmParchment.withOpacity(0.9)),
      ),
      child: Text(
        l10n.chatSheetEmptyStateBody,
        style: GoogleFonts.poppins(
          fontSize: compact ? 13 : 16,
          color: const Color(0xFF2D3748),
          height: 1.45,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message Bubble
// ---------------------------------------------------------------------------
class _MessageBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
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
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
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
            ),
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
                      AppLocalizations.of(context)!.chatSheetCraftingMessage,
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
  final bool isLoading;
  final ValueChanged<String> onSend;

  const _MoodyChatInput({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
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
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              keyboardType: TextInputType.text,
              scrollPadding: const EdgeInsets.only(bottom: 80, top: 48),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.chatSheetInputHint,
                hintStyle:
                    GoogleFonts.poppins(color: Colors.grey[500], fontSize: 15),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                isDense: true,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.82),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
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
                    color: _wmForest.withOpacity(0.75),
                    size: 22,
                  ),
                ),
              ),
              style: GoogleFonts.poppins(
                  fontSize: 15, color: const Color(0xFF1A202C)),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_wmForest, _wmForest],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(23),
              boxShadow: const [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(23),
                onTap: isLoading ? null : () => onSend(controller.text),
                child: Center(
                  child: isLoading
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
        ],
      ),
    );
  }
}
