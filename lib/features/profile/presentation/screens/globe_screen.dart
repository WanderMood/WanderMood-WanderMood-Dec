import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/profile/data/providers/visited_places_provider.dart';
import 'package:wandermood/features/profile/domain/models/visited_place.dart';
import 'package:wandermood/features/profile/presentation/widgets/threejs_globe_widget.dart';
import 'package:wandermood/l10n/app_localizations.dart';

// ── Demo data shown when the user has no real visited places yet ──────────────
const _demoUserId = 'demo';
final _demoPlaces = [
  VisitedPlace(
    id: 'd1', userId: _demoUserId,
    placeName: 'Tokyo', city: 'Tokyo', country: 'Japan',
    lat: 35.6762, lng: 139.6503,
    mood: 'excited', moodEmoji: '🤩', energyLevel: 9,
    notes: 'The neon lights of Shinjuku at night were absolutely electric! Found a tiny jazz bar.',
    visitedAt: DateTime(2024, 3, 15),
  ),
  VisitedPlace(
    id: 'd2', userId: _demoUserId,
    placeName: 'Santorini', city: 'Oia', country: 'Greece',
    lat: 36.4618, lng: 25.3753,
    mood: 'romantic', moodEmoji: '💕', energyLevel: 7,
    notes: 'Watching the sunset with a glass of wine. Pure magic.',
    visitedAt: DateTime(2024, 7, 20),
  ),
  VisitedPlace(
    id: 'd3', userId: _demoUserId,
    placeName: 'New York City', city: 'New York', country: 'USA',
    lat: 40.7128, lng: -74.0060,
    mood: 'adventurous', moodEmoji: '🚀', energyLevel: 10,
    notes: 'Explored every corner of Manhattan. My feet hurt but my heart is full.',
    visitedAt: DateTime(2023, 12, 31),
  ),
  VisitedPlace(
    id: 'd4', userId: _demoUserId,
    placeName: 'Bali', city: 'Ubud', country: 'Indonesia',
    lat: -8.5069, lng: 115.2625,
    mood: 'relaxed', moodEmoji: '😌', energyLevel: 4,
    notes: 'Yoga in the jungle and fresh coconut water. Zen mode activated.',
    visitedAt: DateTime(2024, 1, 8),
  ),
  VisitedPlace(
    id: 'd5', userId: _demoUserId,
    placeName: 'Rome', city: 'Rome', country: 'Italy',
    lat: 41.9028, lng: 12.4964,
    mood: 'foody', moodEmoji: '🍽️', energyLevel: 8,
    notes: 'The carbonara here changed my life. I need the recipe ASAP.',
    visitedAt: DateTime(2023, 9, 5),
  ),
  VisitedPlace(
    id: 'd6', userId: _demoUserId,
    placeName: 'Paris', city: 'Paris', country: 'France',
    lat: 48.8566, lng: 2.3522,
    mood: 'cultural', moodEmoji: '🎭', energyLevel: 6,
    notes: 'Spent hours in the Louvre. The history is overwhelming in the best way.',
    visitedAt: DateTime(2023, 5, 12),
  ),
];

class GlobeScreen extends ConsumerStatefulWidget {
  const GlobeScreen({super.key});

  @override
  ConsumerState<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends ConsumerState<GlobeScreen> {
  final GlobalKey<ThreeJsGlobeWidgetState> _globeKey =
      GlobalKey<ThreeJsGlobeWidgetState>();
  bool _isRotating = false;

  void _onMarkerTap(VisitedPlace place) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: true,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => Stack(
        children: [
          // Full-screen tap target — tap anywhere outside card to close
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // Block — card taps must not close
              child: _MoodMemoryCard(place: place),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationAsync = ref.watch(userLocationProvider);
    final position = locationAsync.valueOrNull;

    final placesAsync = ref.watch(visitedPlacesProvider);
    final realPlaces = placesAsync.valueOrNull ?? [];
    final isDemo = realPlaces.isEmpty;
    final places = isDemo ? _demoPlaces : realPlaces;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.profileGlobeYourJourney,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isDemo
                  ? l10n.profileGlobeDemoHint
                  : l10n.profileGlobePlacesVisitedCount('${places.length}'),
              style: TextStyle(
                color: isDemo
                    ? const Color(0xFFFFD600).withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDemo ? const Color(0xFFEBF3EE) : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isDemo ? l10n.profileGlobeBadgeDemo : '${places.length}',
                  style: TextStyle(
                    color: isDemo ? const Color(0xFF2A6049) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ThreeJsGlobeWidget(
            key: _globeKey,
            visitedPlaces: places,
            autoRotate: false,
            initialLat: position?.latitude,
            initialLng: position?.longitude,
            onMarkerTap: _onMarkerTap,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlButton(
                  icon: _isRotating ? Icons.pause : Icons.play_arrow,
                  label: _isRotating
                      ? l10n.profileGlobeControlPause
                      : l10n.profileGlobeControlRotate,
                  onPressed: () {
                    setState(() => _isRotating = !_isRotating);
                    _globeKey.currentState?.setAutoRotate(_isRotating);
                  },
                ),
                _ControlButton(
                  icon: Icons.refresh_rounded,
                  label: l10n.profileGlobeControlReset,
                  onPressed: () {
                    _globeKey.currentState?.resetCamera();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mood Memory Card (Light Glassmorphism) ────────────────────────────────────

class _MoodMemoryCard extends StatelessWidget {
  final VisitedPlace place;
  const _MoodMemoryCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = place.moodColor;
    final localeName = Localizations.localeOf(context).toString();
    final dateStr = place.visitedAt != null
        ? DateFormat.yMMMMd(localeName).format(place.visitedAt!.toLocal())
        : null;

    // We use a light frosted glass theme now
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.85),
                  Colors.white.withValues(alpha: 0.65),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                // Subtle colored ambient glow matching the mood
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 50,
                  spreadRadius: -10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top accent line
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.8),
                        color.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Emoji & Drag Handle
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              place.moodEmoji ?? _defaultEmoji(place.mood),
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title & Location
                      Text(
                        place.placeName,
                        style: const TextStyle(
                          color: Color(0xFF1E293B), // Dark slate for contrast
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      if (place.city != null || place.country != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                [place.city, place.country]
                                    .whereType<String>()
                                    .join(', '),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Mood Pill & Energy
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _capitalize(
                                    place.mood ??
                                        l10n.profileGlobeUnknownMood,
                                  ),
                                  style: TextStyle(
                                    color: color.withValues(alpha: 1.0)
                                                .computeLuminance() >
                                            0.6
                                        ? Colors.black87
                                        : color, // Ensure contrast
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (place.energyLevel != null) ...[
                            Icon(Icons.bolt_rounded,
                                color: const Color(0xFFF59E0B), size: 18),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: place.energyLevel! / 10,
                                  backgroundColor:
                                      Colors.grey.withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFFF59E0B)),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Notes Area
                      if (place.notes != null && place.notes!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.format_quote_rounded,
                                  color: const Color(0xFF94A3B8), size: 24),
                              const SizedBox(height: 8),
                              Text(
                                place.notes!,
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 16,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Date Footer
                      if (dateStr != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _defaultEmoji(String? mood) {
    switch ((mood ?? '').toLowerCase()) {
      case 'happy':
        return '😊';
      case 'adventurous':
        return '🚀';
      case 'relaxed':
        return '😌';
      case 'energetic':
        return '⚡';
      case 'romantic':
        return '💕';
      case 'social':
        return '👥';
      case 'cultural':
        return '🎭';
      case 'curious':
        return '🔎';
      case 'cozy':
        return '☕';
      case 'excited':
        return '🤩';
      case 'foody':
        return '🍽️';
      case 'surprise':
        return '😲';
      default:
        return '📍';
    }
  }
}

// ── Control Button ────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              // Lighter on dark globe UI (SCREEN 17) — reads better than slate-400
              color: const Color(0xFFB8C0CC).withValues(alpha: 0.95),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
