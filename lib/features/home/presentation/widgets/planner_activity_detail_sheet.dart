import 'package:cached_network_image/cached_network_image.dart';
import 'package:wandermood/core/cache/wandermood_image_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:wandermood/core/presentation/widgets/moody_avatar_compact.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/l10n/app_localizations.dart';

const Color _wmForest = Color(0xFF2A6049);
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

/// Builds the route param for [GoRoute] `place-detail` from scheduled activity data.
String? resolvePlannerPlaceDetailRouteId(Map<String, dynamic> activity) {
  final raw = activity['placeId'] as String?;
  if (raw == null || raw.trim().isEmpty) return null;
  final t = raw.trim();
  if (t.startsWith('google_')) return t;
  return 'google_$t';
}

String _capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Shared “Moody says” copy for planner detail sheet (My Day + Agenda).
/// Uses the same rules everywhere so the two entry points never diverge.
String plannerMoodyAdviceForActivity(Map<String, dynamic> activity) {
  DateTime startTime;
  final startTimeStr = activity['startTime'] as String?;
  if (startTimeStr != null && startTimeStr.trim().isNotEmpty) {
    try {
      startTime = DateTime.parse(startTimeStr);
    } catch (_) {
      startTime = _parseActivityDate(activity);
    }
  } else {
    startTime = _parseActivityDate(activity);
  }

  final category = activity['category']?.toString().toLowerCase() ?? '';
  final duration = activity['duration'] as int? ?? 60;
  final paymentStatus = _paymentStatusForMoodyAdvice(activity);

  final advice = <String>[];

  if (startTime.hour < 12) {
    advice.add('🌅 Perfect morning timing - enjoy the fresh start');
  } else if (startTime.hour >= 18) {
    advice.add('🌆 Great evening activity - perfect for unwinding');
  }

  if (duration >= 120) {
    advice.add('⏰ Longer experience - bring water and snacks');
  } else if (duration <= 45) {
    advice.add('⚡ Quick and energizing - perfect mood boost');
  }

  switch (category) {
    case 'outdoor':
      advice.addAll([
        '🌿 Check the weather before heading out',
        '👟 Comfortable walking shoes recommended',
        '📱 Download offline maps for the area',
      ]);
      break;
    case 'cultural':
      advice.addAll([
        '🎨 Take your time to appreciate the experience',
        '📖 Look for guided tours or information',
        '🔇 Be respectful of others enjoying the space',
      ]);
      break;
    case 'food':
      advice.addAll([
        '🍽️ Come with an appetite for new flavors',
        '💰 Bring cash - some vendors prefer it',
        '📸 Great photo opportunities for food memories',
      ]);
      break;
    case 'nature':
      advice.addAll([
        '🌳 Perfect for connecting with nature',
        '📸 Bring a camera for beautiful moments',
        '🧴 Sunscreen and water are essentials',
      ]);
      break;
    default:
      advice.addAll([
        '💚 Be present and enjoy every moment',
        '📍 Arrive a few minutes early to settle in',
        '🌟 Open mind leads to the best experiences',
      ]);
  }

  switch (paymentStatus) {
    case 'paid':
      advice.add('🎫 All set - your experience is confirmed');
      break;
    case 'reserved':
      advice.add('⏱️ Complete payment to secure your spot');
      break;
    case 'free':
      advice.add('🆓 Free doesn\'t mean less valuable - enjoy fully');
      break;
  }

  advice.add('✨ This activity was chosen to match your mood perfectly');

  return advice.take(5).map((tip) => '• $tip').join('\n');
}

DateTime _parseActivityDate(Map<String, dynamic> activity) {
  final dateStr = activity['date'] as String?;
  if (dateStr != null && dateStr.trim().isNotEmpty) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}
  }
  return DateTime.now();
}

/// Agenda uses [paymentStatus]; My Day scheduled maps use [paymentType] (e.g. PaymentType.free).
String _paymentStatusForMoodyAdvice(Map<String, dynamic> activity) {
  final explicit = activity['paymentStatus'];
  if (explicit != null && explicit.toString().trim().isNotEmpty) {
    return explicit.toString();
  }
  final pt = activity['paymentType']?.toString().toLowerCase() ?? '';
  if (pt.contains('paid')) return 'paid';
  if (pt.contains('reserved')) return 'reserved';
  if (pt.contains('pending')) return 'pending';
  return 'free';
}

List<String> _photoUrlsForActivity(Map<String, dynamic> activity) {
  final urls = <String>[];
  final main = activity['imageUrl']?.toString().trim();
  if (main != null && main.isNotEmpty) urls.add(main);
  final extra = activity['imageUrls'];
  if (extra is List) {
    for (final e in extra) {
      final s = e?.toString().trim();
      if (s != null && s.isNotEmpty && !urls.contains(s)) urls.add(s);
    }
  }
  return urls;
}

/// Planner-style bottom sheet with Details / Photos / Reviews when no linked Google place.
Future<void> showPlannerActivityDetailSheet(
  BuildContext context, {
  required Map<String, dynamic> activity,
  required Widget Function(void Function() popSheet) footerBuilder,
  String? scheduledTimeLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      void popSheet() => Navigator.of(sheetContext).pop();
      final height = MediaQuery.sizeOf(sheetContext).height * 0.92;

      return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: height,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    labelColor: _wmForest,
                    unselectedLabelColor: _wmStone,
                    indicatorColor: _wmForest,
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 16),
                            SizedBox(width: 6),
                            Text('Details'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('Photos'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_outline, size: 16),
                            SizedBox(width: 6),
                            Text('Reviews'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1, thickness: 1, color: _wmParchment),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _DetailsPane(
                          activity: activity,
                          scheduledTimeLabel: scheduledTimeLabel,
                          moodyTip: plannerMoodyAdviceForActivity(activity),
                        ),
                        _PhotosPane(urls: _photoUrlsForActivity(activity)),
                        _ReviewsPane(activity: activity),
                      ],
                    ),
                  ),
                  ColoredBox(
                    color: _wmCream,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: footerBuilder(popSheet),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DetailsPane extends StatelessWidget {
  final Map<String, dynamic> activity;
  final String? scheduledTimeLabel;
  final String moodyTip;

  const _DetailsPane({
    required this.activity,
    required this.scheduledTimeLabel,
    required this.moodyTip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = activity['duration'] as int? ?? 60;
    final category = _capitalizeFirst(
      (activity['category'] ?? l10n.dayPlanCardActivity).toString(),
    );
    final price = (activity['price'] as num?)?.toDouble() ?? 0.0;
    final payment = (activity['paymentStatus'] ?? 'free').toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: CachedNetworkImage(
              cacheManager: WanderMoodImageCacheManager.instance,
              imageUrl: activity['imageUrl']?.toString() ??
                  'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey[200]),
              errorWidget: (_, __, ___) => Container(
                color: _wmForest.withValues(alpha: 0.15),
                child: const Icon(Icons.image, color: _wmForest, size: 48),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          activity['title']?.toString() ?? l10n.dayPlanCardActivity,
          style: GoogleFonts.museoModerno(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _wmCharcoal,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickChip(
                icon: Icons.schedule_rounded,
                label: l10n.dayPlanDurationMinutesOnly(duration),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickChip(
                icon: Icons.payments_outlined,
                label: price <= 0 || payment == 'free'
                    ? l10n.dayPlanCardFree
                    : '€${price.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickChip(
                icon: Icons.category_outlined,
                label: category.length > 12
                    ? '${category.substring(0, 12)}…'
                    : category,
              ),
            ),
          ],
        ),
        if (scheduledTimeLabel != null) ...[
          const SizedBox(height: 12),
          _InfoLine(
            icon: Icons.event_available_outlined,
            text: l10n.plannerSheetScheduledPrefix(scheduledTimeLabel!),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _wmForest.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _wmForest.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const MoodyAvatarCompact(size: 26, glowOpacityScale: 0.2),
                  const SizedBox(width: 8),
                  Text(
                    l10n.placeDetailMoodyName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _wmForest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _wmParchment),
                ),
                child: Text(
                  moodyTip,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.45,
                    color: _wmCharcoal,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.plannerSheetAbout,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _wmCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          activity['description']?.toString() ?? l10n.plannerSheetNoDescription,
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.5,
            color: _wmStone,
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _wmParchment),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: _wmForest),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _wmCharcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _wmForest),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _wmCharcoal,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotosPane extends StatelessWidget {
  final List<String> urls;

  const _PhotosPane({required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No extra photos on this plan yet.\n'
            'When the activity is linked to a place, you’ll see a full gallery in Explore.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.45,
              color: _wmStone,
            ),
          ),
        ),
      );
    }

    return PageView.builder(
      itemCount: urls.length,
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              cacheManager: WanderMoodImageCacheManager.instance,
              imageUrl: urls[i],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => Container(color: Colors.grey[200]),
              errorWidget: (_, __, ___) => Container(
                color: _wmForest.withValues(alpha: 0.12),
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReviewsPane extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ReviewsPane({required this.activity});

  @override
  Widget build(BuildContext context) {
    final rating = (activity['rating'] as num?)?.toDouble() ?? 0.0;
    final hasNumeric = rating > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (hasNumeric) ...[
          Text(
            'Rating on your plan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _wmCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < rating.round().clamp(1, 5)
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _wmCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'Written reviews',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _wmCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasNumeric
              ? 'Star ratings from your plan are shown above. Full Google reviews and more photos appear when this activity is linked to a place — open it from Explore, or schedule it from a place card so WanderMood can attach a place id.'
              : 'There’s no review data on this scheduled item yet. Link it to a Google place (e.g. add it from Explore) to read real visitor reviews in the full place view.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.5,
            color: _wmStone,
          ),
        ),
      ],
    );
  }
}
