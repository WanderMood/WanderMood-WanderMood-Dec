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
      setModalState(() {
        chatMessages.add(_ChatMsg(
          message:
              "Oops! I'm having trouble connecting right now. Can you try again? 🤔",
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
    // We size the sheet manually so it uses the full area above the keyboard.
    useSafeArea: false,
    builder: (context) {
      final mq = MediaQuery.of(context);
      final topInset = mq.padding.top;
      // Keyboard uses viewInsets; when it's closed, keep space for the home indicator.
      final bottomObstruction = mq.viewInsets.bottom > 0
          ? mq.viewInsets.bottom
          : mq.padding.bottom;
      final sheetHeight = (mq.size.height - topInset - bottomObstruction)
          .clamp(280.0, mq.size.height);

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
                                flex: 5, child: ColoredBox(color: _wmSkyTint)),
                            Expanded(
                                flex: 5, child: ColoredBox(color: _wmCream)),
                          ],
                        ),
                        Column(
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
                                    city: city,
                                    style: style,
                                  ),
                                );
                              },
                            ),
                            Expanded(
                              child: chatMessages.isEmpty
                                  ? const _MoodyChatEmptyState()
                                  : Column(
                                      children: [
                                        Expanded(
                                          child: ListView.builder(
                                            padding: const EdgeInsets.symmetric(
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
                            _MoodyChatInput(
                              controller: chatController,
                              isLoading: isAILoading,
                              onSend: (text) =>
                                  sendMessage(text, setModalState),
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
                        'Moody',
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
  const _MoodyChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _wmSky.withOpacity(0.35),
              border: Border.all(
                color: _wmSky.withOpacity(0.65),
                width: 2,
              ),
              boxShadow: const [],
            ),
            child: const Center(child: MoodyCharacter(size: 70)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _wmParchment.withOpacity(0.9)),
            ),
            child: Text(
              "I know Rotterdam like the back of my hand! Tell me your mood, and I'll craft the perfect day just for you. Whether you're feeling adventurous, romantic, or need some chill vibes - I've got you covered! 🎯",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF2D3748),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
        ],
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
                      'Moody is crafting something special...',
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
    return Container(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24,
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
              decoration: InputDecoration(
                hintText: "What's your mood today?",
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

