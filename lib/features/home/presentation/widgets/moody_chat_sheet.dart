import 'dart:ui';

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

// WanderMood v2 — Moody chat (Screen 9)
const Color _wmSkyTint = Color(0xFFEDF5F9);
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);

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

/// Opens the Moody chat bottom sheet — the same UI from the original MoodHomeScreen.
/// Can be called from any screen that has access to a [BuildContext] and a [WidgetRef].
void showMoodyChatSheet(BuildContext context, WidgetRef ref) {
  final moods = ref.read(dailyMoodStateNotifierProvider).selectedMoods;
  final now = MoodyClock.now();
  final conversationId = _DailyMoodyChatCache.getConversationId(now);
  final chatMessages = _DailyMoodyChatCache.getMessages(now);
  final chatController = TextEditingController();
  var isAILoading = false;

  Future<({double lat, double lng, String city})> getLocation() async {
    final position = await ref.read(userLocationProvider.future);
    final city = ref.read(locationNotifierProvider).value ?? 'Rotterdam';
    return (
      lat: position?.latitude ?? 51.9225,
      lng: position?.longitude ?? 4.4792,
      city: city,
    );
  }

  Future<void> sendMessage(String text, StateSetter setModalState) async {
    if (text.trim().isEmpty || isAILoading) return;

    setModalState(() {
      chatMessages.add(_ChatMsg(
          message: text.trim(), isUser: true, timestamp: MoodyClock.now()));
      isAILoading = true;
    });
    chatController.clear();

    try {
      final loc = await getLocation();
      final priorTurns = chatMessages.length > 1
          ? chatMessages
              .sublist(0, chatMessages.length - 1)
              .map((m) => {
                    'role': m.isUser ? 'user' : 'assistant',
                    'content': m.message,
                  })
              .toList()
          : null;
      final response = await WanderMoodAIService.chat(
        message: text.trim(),
        conversationId: conversationId,
        moods: moods,
        latitude: loc.lat,
        longitude: loc.lng,
        city: loc.city,
        clientTurns: priorTurns,
      );

      setModalState(() {
        chatMessages.add(_ChatMsg(
            message: response.message,
            isUser: false,
            timestamp: MoodyClock.now()));
        isAILoading = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setModalState(() {
        chatMessages.add(_ChatMsg(
          message: l10n.chatSheetErrorMessage,
          isUser: false,
          timestamp: MoodyClock.now(),
        ));
        isAILoading = false;
      });
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.75),
    // Root route gets reliable viewInsets on iOS when the keyboard opens.
    useRootNavigator: true,
    useSafeArea: false,
    builder: (context) {
      return _RepaintWhenKeyboardMetricsChange(
        builder: (context) {
          final mq = MediaQuery.of(context);
          final topInset = mq.padding.top;
          final keyboardBottom = mq.viewInsets.bottom;
          // Keep sheet at full height; push input above keyboard with padding.
          // This is more reliable than shrinking the sheet because the sheet is
          // anchored at the screen bottom — shrinking it just hides content
          // behind the keyboard rather than moving it.
          final inputBottomPad =
              keyboardBottom > 0 ? keyboardBottom : mq.padding.bottom;
          final sheetHeight = mq.size.height - topInset;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: EdgeInsets.only(top: topInset),
                child: SizedBox(
                  height: sheetHeight,
                  child: StatefulBuilder(
                    builder: (context, setModalState) {
                      return ClipRRect(
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
                                    flex: 5,
                                    child: ColoredBox(color: _wmSkyTint)),
                                Expanded(
                                    flex: 5, child: ColoredBox(color: _wmCream)),
                              ],
                            ),
                            Column(
                              children: [
                                Consumer(
                                  builder: (context, ref, _) {
                                    final city = ref
                                        .watch(locationNotifierProvider)
                                        .value;
                                    final style = ref
                                        .watch(communicationStyleProvider)
                                        .style;
                                    return _MoodyChatHeader(
                                      subtitle: moodyChatTravelBestieSubtitle(
                                        city: city,
                                        style: style,
                                      ),
                                    );
                                  },
                                ),
                                Expanded(
                                  child: chatMessages.isEmpty
                                      ? _MoodyChatEmptyState(
                                          keyboardOpen: keyboardBottom > 0,
                                        )
                                      : Column(
                                          children: [
                                            Expanded(
                                              child: ListView.builder(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                                itemCount: chatMessages.length,
                                                itemBuilder: (context, index) {
                                                  return _MessageBubble(
                                                      msg: chatMessages[index]);
                                                },
                                              ),
                                            ),
                                            if (isAILoading)
                                              const _MoodyTypingIndicator(),
                                          ],
                                        ),
                                ),
                                // Padding pushes the input above the keyboard.
                                // AnimatedPadding gives a smooth slide as the
                                // keyboard animates in/out.
                                AnimatedPadding(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  padding: EdgeInsets.only(
                                      bottom: inputBottomPad),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: _MoodyChatInput(
                                      controller: chatController,
                                      isLoading: isAILoading,
                                      onSend: (text) =>
                                          sendMessage(text, setModalState),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: _wmSkyTint,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _wmSky,
                    boxShadow: [],
                  ),
                  child: const Center(child: MoodyCharacter(size: 32)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.chatSheetMoodyName,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: _wmSky,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: _wmParchment, width: 0.5),
                            ),
                            child: const SizedBox(width: 8, height: 8),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF4A5568),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    boxShadow: const [],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.grey, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        left: 24,
        right: 24,
        top: 24,
        bottom: kb > 0 ? 12 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
        boxShadow: const [],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              keyboardType: TextInputType.text,
              scrollPadding: const EdgeInsets.only(bottom: 120, top: 80),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.chatSheetInputHint,
                hintStyle:
                    GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(
                    color: _wmParchment,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: _wmForest,
                    width: 2,
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
                  fontSize: 16, color: const Color(0xFF1A202C)),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_wmForest, _wmForest],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: isLoading ? null : () => onSend(controller.text),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

