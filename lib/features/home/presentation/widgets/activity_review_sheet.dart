import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:wandermood/features/mood/services/activity_rating_service.dart';

// WanderMood v2 — Quick Review sheet (Screen 14)
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmSunsetTint = Color(0xFFFDF0EE);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmTileBlij = Color(0xFFF9D878);
const Color _wmTileOntspannen = Color(0xFF78CCB8);
const Color _wmMehTint = Color(0xFFFDF0EE);

Future<void> showActivityReviewSheet(
  BuildContext context,
  EnhancedActivityData activity,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _ActivityReviewSheet(activity: activity),
      );
    },
  );
}

class _ActivityReviewSheet extends ConsumerStatefulWidget {
  final EnhancedActivityData activity;

  const _ActivityReviewSheet({required this.activity});

  @override
  ConsumerState<_ActivityReviewSheet> createState() =>
      _ActivityReviewSheetState();
}

class _ActivityReviewSheetState extends ConsumerState<_ActivityReviewSheet> {
  int _rating = 0;
  String? _selectedEmoji;
  final TextEditingController _noteController = TextEditingController();

  final List<_EmojiOption> _emojiOptions = const [
    _EmojiOption('🤩', 'Amazing'),
    _EmojiOption('😊', 'Good'),
    _EmojiOption('😐', 'Okay'),
    _EmojiOption('😞', 'Meh'),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.activity.rawData['title'] as String? ?? 'Activity';
    final timeStr =
        '${_formatTime(widget.activity.startTime)} - ${_formatTime(widget.activity.endTime)}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _wmParchment,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Review',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _wmSunsetTint,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _wmSunset, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _wmSunset, width: 1.5),
                          ),
                          child: const Center(
                            child: Text('🛍️', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeStr,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'How was it?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final isActive = star <= _rating;
                      return IconButton(
                        onPressed: () => setState(() => _rating = star),
                        iconSize: 36,
                        splashRadius: 24,
                        icon: Icon(
                          Icons.star_rounded,
                          color: isActive
                              ? const Color(0xFFFACC15)
                              : _wmParchment,
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        _rating == 5
                            ? '🌟 Amazing!'
                            : _rating == 4
                                ? '😊 Really good!'
                                : _rating == 3
                                    ? '👍 Pretty good!'
                                    : _rating == 2
                                        ? '😐 It was okay'
                                        : '😞 Not great',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Your vibe',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _emojiOptions.length,
                    itemBuilder: (context, index) {
                      final option = _emojiOptions[index];
                      final selected = option.emoji == _selectedEmoji;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmoji = selected ? null : option.emoji;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? _wmForest : _wmParchment,
                              width: 2,
                            ),
                            color: _vibeTileColor(option.label),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: _wmForest.withOpacity(0.18),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                option.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                option.label,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? _wmForest : _wmStone,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Any thoughts? (optional)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'What stood out? Any tips for others?',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: _wmForest,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '💡 This helps Moody learn what you actually loved.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _rating == 0 ? null : _saveReview,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      backgroundColor: _wmForest,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _wmParchment,
                      disabledForegroundColor: _wmStone,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded),
                        const SizedBox(width: 8),
                        Text(
                          'Save Review',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _rating == 0
                      ? 'Please add a star rating to continue'
                      : 'Your feedback helps Moody learn!',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveReview() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final raw = widget.activity.rawData;
    final activityId =
        (raw['id'] as String?) ?? (raw['title'] as String? ?? '');
    final activityName = raw['title'] as String? ?? 'Activity';
    final placeName = raw['placeName'] as String?;
    final moodRaw = raw['mood'] as String?;
    final mood = _selectedEmoji != null
        ? _mapEmojiToMood(_selectedEmoji!)
        : (moodRaw ?? 'unknown');

    final rating = ActivityRating(
      id: const Uuid().v4(),
      userId: userId,
      activityId: activityId,
      activityName: activityName,
      placeName: placeName,
      stars: _rating,
      tags: _selectedEmoji != null ? [_mapEmojiToLabel(_selectedEmoji!)] : [],
      wouldRecommend: _rating >= 4,
      notes: _noteController.text.isNotEmpty ? _noteController.text : null,
      completedAt: DateTime.now(),
      mood: mood,
    );

    await ref.read(activityRatingServiceProvider).saveRating(rating);
    ref.read(activityManagerProvider.notifier).updateActivityStatus(
          activityId,
          ActivityStatus.completed,
        );
    ref.invalidate(todayActivitiesProvider);
    ref.invalidate(timelineCategorizedActivitiesProvider);
    ref.invalidate(activityRatingForActivityProvider(activityId));

    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop();
    showWanderMoodToast(
      nav.context,
      message: 'Thanks for your review! 🚀',
      duration: const Duration(seconds: 3),
    );
  }

  String _mapEmojiToMood(String emoji) {
    switch (emoji) {
      case '🤩':
        return 'excited';
      case '😊':
        return 'happy';
      case '😐':
        return 'neutral';
      case '😞':
        return 'disappointed';
      default:
        return 'unknown';
    }
  }

  String _mapEmojiToLabel(String emoji) {
    switch (emoji) {
      case '🤩':
        return 'Amazing';
      case '😊':
        return 'Good';
      case '😐':
        return 'Okay';
      case '😞':
        return 'Meh';
      default:
        return 'Mood';
    }
  }

  Color _vibeTileColor(String label) {
    switch (label) {
      case 'Amazing':
        return _wmTileBlij;
      case 'Good':
        // Desaturated tint of wmTileOntspannen (Screen 14)
        return Color.lerp(_wmTileOntspannen, Colors.white, 0.5)!;
      case 'Okay':
        return _wmParchment;
      case 'Meh':
        return _wmMehTint;
      default:
        return Colors.white;
    }
  }
}

class _EmojiOption {
  final String emoji;
  final String label;

  const _EmojiOption(this.emoji, this.label);
}

String _formatTime(DateTime time) {
  final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
