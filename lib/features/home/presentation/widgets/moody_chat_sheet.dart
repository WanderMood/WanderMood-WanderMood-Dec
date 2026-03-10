import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/core/services/wandermood_ai_service.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_loading_screen.dart';

class _ChatMsg {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  _ChatMsg({required this.message, required this.isUser, required this.timestamp});
}

/// Opens the Moody chat bottom sheet — the same UI from the original MoodHomeScreen.
/// Can be called from any screen that has access to a [BuildContext] and a [WidgetRef].
void showMoodyChatSheet(BuildContext context, WidgetRef ref) {
  final moods = ref.read(dailyMoodStateNotifierProvider).selectedMoods;
  final conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
  final chatMessages = <_ChatMsg>[];
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
      chatMessages.add(_ChatMsg(message: text.trim(), isUser: true, timestamp: DateTime.now()));
      isAILoading = true;
    });
    chatController.clear();

    try {
      final loc = await getLocation();
      final response = await WanderMoodAIService.chat(
        message: text.trim(),
        conversationId: conversationId,
        moods: moods,
        latitude: loc.lat,
        longitude: loc.lng,
        city: loc.city,
      );

      setModalState(() {
        chatMessages.add(_ChatMsg(message: response.message, isUser: false, timestamp: DateTime.now()));
        isAILoading = false;
      });
    } catch (e) {
      setModalState(() {
        chatMessages.add(_ChatMsg(
          message: "Oops! I'm having trouble connecting right now. Can you try again? 🤔",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        isAILoading = false;
      });
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFAFCFA), Color(0xFFF8FAF9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    _MoodyChatHeader(),

                    // Chat area
                    Expanded(
                      child: chatMessages.isEmpty
                          ? _MoodyChatEmptyState()
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    itemCount: chatMessages.length,
                                    itemBuilder: (context, index) {
                                      return _MessageBubble(msg: chatMessages[index]);
                                    },
                                  ),
                                ),
                                if (isAILoading) _MoodyTypingIndicator(),
                              ],
                            ),
                    ),

                    // "Create My Perfect Plan" button
                    if (chatMessages.isNotEmpty)
                      _CreatePlanFromChat(
                        chatMessages: chatMessages,
                        onCreatePlan: () {
                          final suggestedMoods = _suggestMoodsFromMessages(chatMessages);
                          final planMoods = suggestedMoods.isNotEmpty ? suggestedMoods : (moods.isNotEmpty ? moods : ['adventurous']);

                          ref.read(dailyMoodStateNotifierProvider.notifier).setMoodSelection(
                            mood: planMoods.first,
                            selectedMoods: planMoods,
                          );

                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlanLoadingScreen(selectedMoods: planMoods),
                            ),
                          );
                        },
                      ),

                    // Input
                    _MoodyChatInput(
                      controller: chatController,
                      isLoading: isAILoading,
                      onSend: (text) => sendMessage(text, setModalState),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _MoodyChatHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF12B347).withOpacity(0.03), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF12B347), Color(0xFF0EA33F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF12B347).withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
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
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFF10B149),
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(width: 8, height: 8),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Your Rotterdam travel companion',
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
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
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF12B347).withOpacity(0.08),
                  const Color(0xFF12B347).withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF12B347).withOpacity(0.15),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF12B347).withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(child: MoodyCharacter(size: 70)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF12B347).withOpacity(0.1)),
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
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF12B347), Color(0xFF0EA33F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF12B347).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
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
                        colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFE8F5E8), Color(0xFFF5FBF5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: msg.isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (msg.isUser ? const Color(0xFF007AFF) : const Color(0xFF12B347)).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                msg.message,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: msg.isUser ? Colors.white : const Color(0xFF2D3748),
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF12B347), Color(0xFF0EA33F)]),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF12B347).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(child: MoodyCharacter(size: 22)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F0),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF12B347).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF12B347).withOpacity(0.7)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Moody is crafting something special...',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: const Color(0xFF2D3748),
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
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
// Create Plan Button
// ---------------------------------------------------------------------------
class _CreatePlanFromChat extends StatelessWidget {
  final List<_ChatMsg> chatMessages;
  final VoidCallback onCreatePlan;
  const _CreatePlanFromChat({required this.chatMessages, required this.onCreatePlan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF12B347).withOpacity(0.05),
              const Color(0xFF12B347).withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF12B347).withOpacity(0.2)),
        ),
        child: OutlinedButton.icon(
          onPressed: onCreatePlan,
          icon: const Icon(Icons.auto_awesome, size: 20),
          label: Text(
            '✨ Create My Perfect Plan',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF12B347),
            backgroundColor: Colors.transparent,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
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
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF12B347).withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF12B347).withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "What's your mood today?",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.psychology_outlined,
                      color: const Color(0xFF12B347).withOpacity(0.6),
                      size: 22,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF1A202C)),
                onSubmitted: onSend,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF12B347), Color(0xFF0EA33F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF12B347).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
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
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
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
// Mood suggestion from chat messages
// ---------------------------------------------------------------------------
List<String> _suggestMoodsFromMessages(List<_ChatMsg> messages) {
  final chatText = messages
      .where((msg) => msg.isUser)
      .map((msg) => msg.message.toLowerCase())
      .join(' ');

  final suggestedMoods = <String>[];

  if (chatText.contains(RegExp(r'\b(food|eat|hungry|restaurant|dinner|lunch|asian|cuisine|tasty|sushi)\b'))) {
    suggestedMoods.add('Foody');
  }
  if (chatText.contains(RegExp(r'\b(romantic|date|love|couple|intimate)\b'))) {
    suggestedMoods.add('Romantic');
  }
  if (chatText.contains(RegExp(r'\b(adventure|explore|active|exciting|outdoor)\b'))) {
    suggestedMoods.add('Adventure');
  }
  if (chatText.contains(RegExp(r'\b(chill|relax|calm|peaceful|tired|nothing much)\b'))) {
    suggestedMoods.add('Relaxed');
  }
  if (chatText.contains(RegExp(r'\b(energy|energetic|party|parties|dance|active|lively|bar|club|going out)\b'))) {
    suggestedMoods.add('Energetic');
  }
  if (chatText.contains(RegExp(r'\b(surprise|different|new|unique|creative)\b'))) {
    suggestedMoods.add('Surprise');
  }

  return suggestedMoods;
}
