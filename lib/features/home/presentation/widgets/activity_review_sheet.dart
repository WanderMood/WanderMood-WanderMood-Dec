import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/home/presentation/utils/my_day_activity_id.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:wandermood/features/mood/services/activity_rating_service.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/home/presentation/utils/activity_image_fallback.dart';
import 'package:wandermood/features/profile/presentation/providers/visit_rating_photo_provider.dart';
import 'package:wandermood/features/profile/presentation/utils/visit_place_photo_policy.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';

/// Dark sheet tokens — aligned with My Day / notification centre.
const Color _kBg = Color(0xFF1E1C18);
const Color _kSurface = Color(0xFF252320);
const Color _kCream = Color(0xFFF5F0E8);
const Color _kSunset = Color(0xFFE8784A);
const Color _kForest = Color(0xFF2A6049);
const Color _kStone = Color(0xFF8C8780);
const Color _kTileBlij = Color(0xFFF9D878);
const Color _kTileOntspannen = Color(0xFF78CCB8);
const Color _kParchment = Color(0xFFE8E2D8);
const Color _kMehTint = Color(0xFFFDF0EE);
/// High-contrast labels on pastel vibe tiles (never forest-on-gold).
const Color _kVibeLabelDark = Color(0xFF141210);

bool _isGooglePlacePhotoUrl(String url) {
  final u = url.toLowerCase();
  return (u.contains('maps.googleapis.com') && u.contains('photo')) ||
      u.contains('places.googleapis.com');
}

/// Build a minimal [EnhancedActivityData] when editing from Profile (moments list).
EnhancedActivityData enhancedActivityDataFromRating(ActivityRating r) {
  final start = r.completedAt;
  return EnhancedActivityData(
    rawData: {
      'id': r.activityId,
      'title': r.activityName,
      if (r.placeName != null) 'placeName': r.placeName,
      if (r.googlePlaceId != null) 'placeId': r.googlePlaceId,
      if (r.heroImageUrl != null && r.heroImageUrl!.trim().isNotEmpty)
        'imageUrl': r.heroImageUrl,
      'mood': r.mood,
      'startTime': start.toIso8601String(),
      'duration': 60,
    },
    status: ActivityStatus.completed,
    startTime: start,
    endTime: start.add(const Duration(minutes: 60)),
  );
}

Future<void> showActivityReviewSheet(
  BuildContext context,
  EnhancedActivityData activity, {
  ActivityRating? existingRating,
  bool readOnly = false,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _ActivityReviewSheet(
          activity: activity,
          existingRating: existingRating,
          readOnly: readOnly,
        ),
      );
    },
  );
}

/// Opens the same sheet pre-filled from a saved [ActivityRating] (Profile → moments).
///
/// Read-only: ratings are fixed after My Day save (partner / B2B analytics).
Future<void> showActivityReviewSheetForRating(
  BuildContext context,
  ActivityRating rating,
) {
  return showActivityReviewSheet(
    context,
    enhancedActivityDataFromRating(rating),
    existingRating: rating,
    readOnly: true,
  );
}

class _ActivityReviewSheet extends ConsumerStatefulWidget {
  const _ActivityReviewSheet({
    required this.activity,
    this.existingRating,
    this.readOnly = false,
  });

  final EnhancedActivityData activity;
  final ActivityRating? existingRating;
  final bool readOnly;

  @override
  ConsumerState<_ActivityReviewSheet> createState() =>
      _ActivityReviewSheetState();
}

class _ActivityReviewSheetState extends ConsumerState<_ActivityReviewSheet> {
  late int _rating;
  String? _selectedEmoji;
  final TextEditingController _noteController = TextEditingController();

  /// Left → right: rough → great (like 0 → 10).
  static const List<String> _emojiOrder = ['😞', '😐', '😊', '🤩'];

  @override
  void initState() {
    super.initState();
    final e = widget.existingRating;
    if (e != null) {
      _rating = e.stars.clamp(1, 5);
      _noteController.text = e.notes ?? '';
      if (e.tags.isNotEmpty) {
        _selectedEmoji = _emojiFromSavedTag(e.tags.first);
      }
    } else {
      _rating = 0;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String? _emojiFromSavedTag(String tag) {
    switch (tag) {
      case 'Amazing':
        return '🤩';
      case 'Good':
        return '😊';
      case 'Okay':
        return '😐';
      case 'Meh':
        return '😞';
      default:
        return null;
    }
  }

  String _vibeLabel(AppLocalizations l10n, String emoji) {
    switch (emoji) {
      case '🤩':
        return l10n.moodyReviewVibeAmazing;
      case '😊':
        return l10n.moodyReviewVibeGood;
      case '😐':
        return l10n.moodyReviewVibeOkay;
      case '😞':
        return l10n.moodyReviewVibeMeh;
      default:
        return '';
    }
  }

  String _starFeedback(AppLocalizations l10n) {
    switch (_rating) {
      case 5:
        return l10n.moodyReviewStarsFeedback5;
      case 4:
        return l10n.moodyReviewStarsFeedback4;
      case 3:
        return l10n.moodyReviewStarsFeedback3;
      case 2:
        return l10n.moodyReviewStarsFeedback2;
      case 1:
        return l10n.moodyReviewStarsFeedback1;
      default:
        return '';
    }
  }

  String _formatTimeRange(BuildContext context) {
    final loc = Localizations.localeOf(context).toString();
    final a = DateFormat.jm(loc).format(widget.activity.startTime);
    final b = DateFormat.jm(loc).format(widget.activity.endTime);
    return '$a – $b';
  }

  Color _vibeTileColor(String emoji) {
    switch (emoji) {
      case '🤩':
        return _kTileBlij;
      case '😊':
        return Color.lerp(_kTileOntspannen, const Color(0xFFE8F5F1), 0.35)!;
      case '😐':
        return Color.lerp(_kParchment, Colors.white, 0.25)!;
      case '😞':
        return Color.lerp(_kMehTint, const Color(0xFFF5E8E4), 0.2)!;
      default:
        return _kSurface;
    }
  }

  Widget _buildHero(
    BuildContext context,
    String title,
    String timeStr,
  ) {
    String? url = activityHeroDirectUrlFromRaw(widget.activity.rawData);
    if (url != null && isStockOrDecorativeImageUrl(url)) url = null;

    if ((url == null || url.isEmpty) && widget.existingRating != null) {
      final snap = ref.watch(
        visitRatingPhotoUrlProvider(VisitRatingPhotoKey.from(widget.existingRating!)),
      );
      url = snap.maybeWhen(data: (u) => u, orElse: () => null);
      if (url != null && isStockOrDecorativeImageUrl(url)) url = null;
    }

    const heroH = 152.0;

    final Widget imageLayer;
    if (url != null && url.isNotEmpty) {
      if (_isGooglePlacePhotoUrl(url)) {
        imageLayer = WmPlacePhotoNetworkImage(
          url,
          height: heroH,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _heroPlaceholder(heroH),
        );
      } else {
        imageLayer = WmNetworkImage(
          url,
          height: heroH,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _heroPlaceholder(heroH),
        );
      }
    } else {
      imageLayer = _heroPlaceholder(heroH);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          SizedBox(height: heroH, width: double.infinity, child: imageLayer),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.68),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kCream.withValues(alpha: 0.98),
                    height: 1.2,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kCream.withValues(alpha: 0.88),
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kForest.withValues(alpha: 0.85),
            _kBg,
            _kSurface,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 44,
          color: _kCream.withValues(alpha: 0.22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ro = widget.readOnly;
    final title =
        widget.activity.rawData['title'] as String? ?? l10n.moodyHubActivitySingular;
    final timeStr = _formatTimeRange(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _kCream.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ro ? l10n.moodyReviewReadOnlyTitle : l10n.moodyReviewTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: _kCream.withValues(alpha: 0.96),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: _kCream.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(context, title, timeStr),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MoodyCharacter(
                        size: 58,
                        mood: 'happy',
                        glowOpacityScale: 0.4,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            ro
                                ? l10n.moodyReviewReadOnlyHeroSubtitle
                                : l10n.moodyReviewHeroSubtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: _kCream.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.moodyReviewHowWasIt,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kCream.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final isActive = star <= _rating;
                      final icon = Icon(
                        Icons.star_rounded,
                        size: 38,
                        color: isActive
                            ? const Color(0xFFFACC15)
                            : _kCream.withValues(alpha: 0.14),
                      );
                      if (ro) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: icon,
                        );
                      }
                      return IconButton(
                        onPressed: () => setState(() => _rating = star),
                        iconSize: 38,
                        splashRadius: 26,
                        icon: icon,
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _starFeedback(l10n),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kCream.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    l10n.moodyReviewYourVibe,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kCream.withValues(alpha: 0.9),
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
                      childAspectRatio: 0.68,
                    ),
                    itemCount: _emojiOrder.length,
                    itemBuilder: (context, index) {
                      final emoji = _emojiOrder[index];
                      final selected = emoji == _selectedEmoji;
                      final label = _vibeLabel(l10n, emoji);
                      final bg = _vibeTileColor(emoji);
                      return GestureDetector(
                        onTap: ro
                            ? null
                            : () {
                                setState(() {
                                  _selectedEmoji = selected ? null : emoji;
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? _kSunset.withValues(alpha: 0.95)
                                  : _kCream.withValues(alpha: 0.14),
                              width: selected ? 2.5 : 1,
                            ),
                            color: bg,
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: _kSunset.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 6),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  letterSpacing: -0.1,
                                  color: _kVibeLabelDark,
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
                    l10n.moodyReviewOptionalNote,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kCream.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    readOnly: ro,
                    maxLines: 4,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _kCream.withValues(alpha: 0.92),
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.moodyReviewNoteHint,
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _kCream.withValues(alpha: 0.35),
                      ),
                      filled: true,
                      fillColor: _kSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: _kCream.withValues(alpha: 0.12),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: _kCream.withValues(alpha: 0.12),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: _kSunset.withValues(alpha: 0.65),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.moodyReviewNoteHelper,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      height: 1.35,
                      color: _kCream.withValues(alpha: 0.42),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (ro)
            SizedBox(height: 12 + MediaQuery.of(context).padding.bottom)
          else
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
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
                        backgroundColor: _kForest,
                        foregroundColor: _kCream,
                        disabledBackgroundColor: _kSurface,
                        disabledForegroundColor: _kStone,
                      ),
                      child: Text(
                        l10n.moodyReviewSave,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rating == 0
                        ? l10n.moodyReviewNeedStars
                        : l10n.moodyReviewHelpsMoody,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _kCream.withValues(alpha: 0.4),
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
    final activityId = myDayStableActivityId(raw);
    if (activityId.isEmpty) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.myDayDeleteMissingId,
          isError: true,
        );
      }
      return;
    }
    final activityName = raw['title'] as String? ?? 'Activity';
    final placeName = raw['placeName'] as String?;
    final moodRaw = raw['mood'] as String?;
    final mood = _selectedEmoji != null
        ? _mapEmojiToMood(_selectedEmoji!)
        : (moodRaw ?? 'unknown');

    final existing = widget.existingRating;
    final rating = ActivityRating(
      id: existing?.id ?? const Uuid().v4(),
      userId: userId,
      activityId: activityId,
      activityName: activityName,
      placeName: placeName,
      stars: _rating,
      tags: _selectedEmoji != null ? [_mapEmojiToLabel(_selectedEmoji!)] : [],
      wouldRecommend: _rating >= 4,
      notes: _noteController.text.isNotEmpty ? _noteController.text : null,
      completedAt: existing?.completedAt ?? MoodyClock.now(),
      mood: mood,
      googlePlaceId: raw['placeId'] as String?,
      heroImageUrl:
          activityHeroDirectUrlFromRaw(raw) ?? existing?.heroImageUrl,
    );

    await ref.read(activityRatingServiceProvider).saveRating(rating);
    ref.read(activityManagerProvider.notifier).updateActivityStatusForDay(
          activityId,
          ActivityStatus.completed,
          myDayDateOnly(widget.activity.startTime),
        );
    ref.invalidate(todayActivitiesProvider);
    ref.invalidate(timelineCategorizedActivitiesProvider);
    ref.invalidate(activityRatingForActivityProvider(activityId));
    ref.invalidate(userActivityMomentsProvider);

    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop();
    showWanderMoodToast(
      nav.context,
      message: AppLocalizations.of(nav.context)!.moodyReviewThanksToast,
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

  /// Stored in English for stable tags / analytics (same as before).
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
}
