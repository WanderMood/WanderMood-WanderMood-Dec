import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/home/domain/enums/moody_feature.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/utils/moody_clock.dart';

Future<void> showMyDayGetReadySheet({
  required BuildContext context,
  required WidgetRef ref,
  required EnhancedActivityData activity,
  required String Function(DateTime) formatTime,
}) async {
  double? destLat;
  double? destLng;
  final loc = activity.rawData['location'] as String?;
  if (loc != null && loc.contains(',')) {
    final parts = loc.split(',');
    if (parts.length == 2) {
      destLat = double.tryParse(parts[0]);
      destLng = double.tryParse(parts[1]);
    }
  }

  final userPosition = await ref.read(userLocationProvider.future);

  double? distanceKm;
  int tripMinutes;
  String transportMode;

  if (userPosition != null && destLat != null && destLng != null) {
    distanceKm = _distanceKm(
      userPosition.latitude,
      userPosition.longitude,
      destLat,
      destLng,
    );

    if (distanceKm <= 1.2) {
      transportMode = 'Walking';
      tripMinutes = (distanceKm / 4.5 * 60).round().clamp(5, 40);
    } else if (distanceKm <= 5) {
      transportMode = 'Public transport';
      tripMinutes = (distanceKm / 12 * 60).round() + 5;
    } else {
      transportMode = 'Public transport';
      tripMinutes = (distanceKm / 18 * 60).round() + 10;
    }
    tripMinutes = tripMinutes.clamp(5, 120);
  } else {
    distanceKm = null;
    transportMode = 'Walking';
    tripMinutes = 15;
  }

  final leaveByTime = activity.startTime.subtract(Duration(minutes: tripMinutes));
  final weather = await ref.read(weatherProvider.future);
  if (!context.mounted) return;

  final temp = weather?.temperature;
  final condition =
      weather?.condition ?? weather?.details['description'] as String? ?? '—';
  final l10n = AppLocalizations.of(context)!;

  String tip = l10n.getReadyWeatherTipDefault;
  if (temp != null && temp < 16) {
    tip = l10n.getReadyWeatherTipCool;
  } else if (condition.toLowerCase().contains('rain')) {
    tip = l10n.getReadyWeatherTipRain;
  }

  final checklist = _generateChecklist(activity.rawData, l10n);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _ExcitingGetReadySheetContent(
          activity: activity,
          leaveByTime: leaveByTime,
          tripMinutes: tripMinutes,
          transportMode: transportMode,
          weatherTemp: temp,
          weatherCondition: condition,
          weatherTip: tip,
          checklist: checklist,
          formatTime: formatTime,
          onOpenDirections: () => _openDirections(activity),
        ),
      );
    },
  );
}

void _openDirections(EnhancedActivityData activity) async {
  final loc = activity.rawData['location'] as String?;
  if (loc == null || !loc.contains(',')) return;

  final parts = loc.split(',');
  if (parts.length != 2) return;

  final lat = double.tryParse(parts[0]);
  final lng = double.tryParse(parts[1]);
  if (lat == null || lng == null) return;

  final url = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          (math.sin(dLon / 2) * math.sin(dLon / 2));
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * math.pi / 180.0;

List<String> _generateChecklist(
  Map<String, dynamic> raw,
  AppLocalizations l10n,
) {
  final title = (raw['title'] as String? ?? '').toLowerCase();
  final category = (raw['category'] as String? ?? '').toLowerCase();

  final isFood = category.contains('food') ||
      title.contains('restaurant') ||
      title.contains('dinner');
  final isOutdoor = category.contains('outdoor') ||
      title.contains('park') ||
      title.contains('walk');

  final items = <String>[
    l10n.getReadyItemWallet,
    l10n.getReadyItemPhoneCharged,
  ];

  if (isFood) {
    items.add(l10n.getReadyItemReusableBag);
  }
  if (isOutdoor) {
    items.add(l10n.getReadyItemShoes);
    items.add(l10n.getReadyItemWater);
  }

  items.add(l10n.getReadyItemId);
  return items;
}

class _ExcitingGetReadySheetContent extends StatefulWidget {
  final EnhancedActivityData activity;
  final DateTime leaveByTime;
  final int tripMinutes;
  final String transportMode;
  final double? weatherTemp;
  final String weatherCondition;
  final String weatherTip;
  final List<String> checklist;
  final String Function(DateTime) formatTime;
  final VoidCallback onOpenDirections;

  const _ExcitingGetReadySheetContent({
    required this.activity,
    required this.leaveByTime,
    required this.tripMinutes,
    required this.transportMode,
    required this.weatherTemp,
    required this.weatherCondition,
    required this.weatherTip,
    required this.checklist,
    required this.formatTime,
    required this.onOpenDirections,
  });

  @override
  State<_ExcitingGetReadySheetContent> createState() =>
      _ExcitingGetReadySheetContentState();
}

class _ExcitingGetReadySheetContentState
    extends State<_ExcitingGetReadySheetContent>
    with SingleTickerProviderStateMixin {
  final Set<int> _checkedIndices = {};
  bool _reminderOn = false;
  Duration? _countdown;
  Timer? _countdownTimer;
  late final String _activityId;

  static const List<String> _checklistEmojis = [
    '💳',
    '📱',
    '🛍️',
    '👟',
    '💧',
    '🪪',
  ];

  @override
  void initState() {
    super.initState();
    _activityId = (widget.activity.rawData['id'] as String?) ??
        (widget.activity.rawData['title'] as String? ?? '');
    _loadPersistedState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    if (!mounted) return;
    final d = widget.activity.startTime.difference(MoodyClock.now());
    setState(() => _countdown = d.isNegative ? Duration.zero : d);
  }

  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('get_ready_state_$_activityId');
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final indices = decoded['checkedIndices'] as List<dynamic>?;
      final reminder = decoded['reminderOn'] as bool? ?? false;
      setState(() {
        _checkedIndices
          ..clear()
          ..addAll(indices?.map((e) => e as int) ?? const <int>[]);
        _reminderOn = reminder;
      });
    } catch (_) {}
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{
        'checkedIndices': _checkedIndices.toList(),
        'reminderOn': _reminderOn,
      };
      await prefs.setString('get_ready_state_$_activityId', jsonEncode(data));
    } catch (_) {}
  }

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _forest = Color(0xFF2A6049);
  static const Color _forestTint = Color(0xFFEBF3EE);
  static const Color _cream = Color(0xFFF5F0E8);
  static const Color _parchment = Color(0xFFE8E2D8);
  static const Color _charcoal = Color(0xFF1E1C18);
  static const Color _stone = Color(0xFF8C8780);
  static const Color _skyTint = Color(0xFFEDF5F9);
  static const Color _sky = Color(0xFFA8C8DC);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = widget.checklist.length;
    final checked = _checkedIndices.length;
    final energyPercent = total > 0 ? (checked / total).clamp(0.0, 1.0) : 0.0;
    final rawMood = widget.activity.rawData['mood'] as String?;
    final moodTag =
        (rawMood != null && rawMood.trim().isNotEmpty) ? rawMood : 'adventure';
    final themeLabel = _playlistThemeFromActivity(widget.activity.rawData);
    final reminderTime = widget.leaveByTime.subtract(const Duration(minutes: 10));

    final hours = _countdown?.inHours ?? 0;
    final mins = _countdown != null ? (_countdown!.inMinutes % 60) : 0;

    return WillPopScope(
      onWillPop: () async {
        await _saveState();
        return true;
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _parchment,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _buildHero(l10n, hours, mins),
              const SizedBox(height: 16),
              _buildEnergyMeter(l10n, energyPercent),
              const SizedBox(height: 12),
              _buildWeatherCard(l10n),
              const SizedBox(height: 12),
              _buildChecklist(l10n),
              const SizedBox(height: 12),
              _buildVibePlaylist(l10n, moodTag, themeLabel),
              const SizedBox(height: 12),
              _buildQuickActions(l10n),
              const SizedBox(height: 12),
              _buildReminder(l10n, reminderTime),
              const SizedBox(height: 20),
              _buildPrimaryCta(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppLocalizations l10n, int hours, int mins) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9D878), Color(0xFFFFBC3B), Color(0xFFFFAA00)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFF1E1C18), size: 28),
                  const SizedBox(width: 8),
                  Text(
                    l10n.getReadyLetsGo,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E1C18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.getReadyAdventureStartsIn,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF4A4640),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _countdownBox('${hours.clamp(0, 99)}', l10n.getReadyHours),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      ':',
                      style: TextStyle(
                        color: Color(0xFF1E1C18),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _countdownBox('${mins.clamp(0, 59)}', l10n.getReadyMins),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.getReadyLeaveBy(
                          widget.formatTime(widget.leaveByTime),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1C18),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.getReadyTripSummary(
                          widget.transportMode,
                          widget.tripMinutes,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF4A4640),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: widget.onOpenDirections,
                    icon: const Icon(
                      Icons.route_rounded,
                      size: 18,
                      color: Color(0xFF1E1C18),
                    ),
                    label: Text(
                      '${l10n.getReadyRoute} →',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1C18),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.black12,
                      foregroundColor: const Color(0xFF1E1C18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            right: -4,
            child: SizedBox(
              width: 64,
              height: 64,
              child: MoodyCharacter(
                size: 64,
                mood: 'excited',
                currentFeature: MoodyFeature.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdownBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1C18),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFF4A4640),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyMeter(AppLocalizations l10n, double percent) {
    final percentageLabel = '${(percent * 100).round()}%';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _parchment, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.getReadyYourAdventureEnergy,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _charcoal,
                  ),
                ),
              ),
              Text(
                percentageLabel,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: _parchment,
              valueColor: const AlwaysStoppedAnimation<Color>(_forest),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.getReadyBoostEnergyHint,
            style: GoogleFonts.poppins(fontSize: 12, color: _stone),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(AppLocalizations l10n) {
    final tempStr = widget.weatherTemp != null
        ? '${widget.weatherTemp!.toStringAsFixed(0)}°C · ${widget.weatherCondition}'
        : '—';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _parchment, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _skyTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _sky.withValues(alpha: 0.4), width: 1),
            ),
            child: const Center(
              child: Text('🌤️', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.getReadyWeatherAt(
                    widget.formatTime(widget.activity.startTime),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _charcoal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tempStr,
                  style: GoogleFonts.poppins(fontSize: 13, color: _charcoal),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.weatherTip,
                  style: GoogleFonts.poppins(fontSize: 12, color: _stone),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _parchment, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                l10n.getReadyPackEssentials,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(widget.checklist.length, (i) {
            final isChecked = _checkedIndices.contains(i);
            final emoji = i < _checklistEmojis.length ? _checklistEmojis[i] : '✓';
            return Column(
              children: [
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: _parchment.withValues(alpha: 0.6)),
                InkWell(
                  onTap: () => setState(() {
                    if (isChecked) {
                      _checkedIndices.remove(i);
                    } else {
                      _checkedIndices.add(i);
                    }
                  }),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.checklist[i],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isChecked ? _stone : _charcoal,
                                  decoration: isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: _stone,
                                ),
                              ),
                              if (isChecked)
                                Text(
                                  'Ready to go!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: _forest,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          isChecked
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 22,
                          color: isChecked ? _forest : _parchment,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _playlistThemeFromActivity(Map<String, dynamic> raw) {
    final title = (raw['title'] as String? ?? '').toLowerCase();
    final cat = (raw['category'] as String? ?? '').toLowerCase();
    if (cat.contains('food') ||
        title.contains('restaurant') ||
        title.contains('dinner')) return 'Foodie';
    if (cat.contains('culture') || title.contains('museum')) return 'Cultural';
    if (cat.contains('shop') || title.contains('shopping')) return 'Shopping';
    if (cat.contains('outdoor') || title.contains('park')) return 'Outdoor';
    return 'Adventure';
  }

  Widget _buildVibePlaylist(AppLocalizations l10n, String mood, String themeLabel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _parchment, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _forestTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.music_note_rounded, color: _forest, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.getReadyVibePlaylist,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _stone,
                  ),
                ),
                Text(
                  l10n.getReadyPlaylistLabel(themeLabel),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _charcoal,
                  ),
                ),
                Text(
                  l10n.getReadyGetInMood(mood),
                  style: GoogleFonts.poppins(fontSize: 11, color: _stone),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _forest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _onPlaylistTap(themeLabel),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                child: Text(
                  l10n.getReadyPlay,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminder(AppLocalizations l10n, DateTime reminderTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _parchment, width: 1),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          l10n.getReadyNudgeMe,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _charcoal,
          ),
        ),
        subtitle: _reminderOn
            ? Text(
                l10n.getReadyReminderAt(widget.formatTime(reminderTime)),
                style: GoogleFonts.poppins(fontSize: 12, color: _forest),
              )
            : null,
        value: _reminderOn,
        activeColor: _forest,
        onChanged: (value) {
          setState(() => _reminderOn = value);
          if (value) {
            showWanderMoodToast(
              context,
              message: l10n.getReadyReminderAt(widget.formatTime(reminderTime)),
            );
          }
        },
      ),
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.getReadyQuickActions,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _stone,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                label: l10n.getReadyQuickShare,
                icon: Icons.ios_share_rounded,
                onTap: _onShareTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                label: l10n.getReadyQuickCalendar,
                icon: Icons.event_rounded,
                onTap: _onCalendarTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                label: l10n.getReadyQuickParking,
                icon: Icons.local_parking_rounded,
                onTap: _onParkingTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onShareTap() {
    final title = widget.activity.rawData['title'] as String? ?? 'this place';
    final time = widget.formatTime(widget.activity.startTime);
    Share.share('Join me at $title around $time – planned with WanderMood.');
  }

  Future<void> _onCalendarTap() async {
    final title =
        widget.activity.rawData['title'] as String? ?? 'WanderMood activity';
    final start = widget.activity.startTime.toUtc();
    final end = widget.activity.endTime.toUtc();
    final details = widget.activity.rawData['description'] as String? ??
        'Planned with WanderMood';
    final location = widget.activity.rawData['address'] as String? ??
        widget.activity.rawData['location'] as String? ??
        '';

    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(title)}'
      '&dates=${_formatIso8601Utc(start)}/${_formatIso8601Utc(end)}'
      '&details=${Uri.encodeComponent(details)}'
      '&location=${Uri.encodeComponent(location.toString())}',
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showCalendarSnackBar();
      }
    } catch (_) {
      if (mounted) _showCalendarSnackBar();
    }
  }

  String _formatIso8601Utc(DateTime utc) {
    final y = utc.year;
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final min = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  void _showCalendarSnackBar() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showWanderMoodToast(
      context,
      message: '${l10n.getReadyQuickCalendar} – open in browser or app',
    );
  }

  void _onParkingTap() async {
    final loc = widget.activity.rawData['location'] as String?;
    Uri url;
    if (loc != null && loc.contains(',')) {
      final parts = loc.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          url = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=parking%20near%20$lat,$lng',
          );
        } else {
          url = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=parking',
          );
        }
      } else {
        url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=parking',
        );
      }
    } else {
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=parking',
      );
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _onPlaylistTap(String themeLabel) async {
    final uri = Uri.parse(
      'https://open.spotify.com/search/${Uri.encodeComponent('Happy $themeLabel Beats')}',
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showPlaylistSnackBar();
      }
    } catch (_) {
      if (mounted) _showPlaylistSnackBar();
    }
  }

  void _showPlaylistSnackBar() {
    final l10n = AppLocalizations.of(context)!;
    showWanderMoodToast(context, message: l10n.getReadyVibePlaylist);
  }

  Widget _buildPrimaryCta(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await _saveState();
          if (!mounted) return;
          Navigator.pop(context);
        },
        icon: const Icon(Icons.check_rounded, size: 20),
        label: Text(
          l10n.getReadyPrimaryCta,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _forest,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _QuickActionTile({
    required this.label,
    required this.icon,
    this.onTap,
  });

  static const Color _forest = Color(0xFF2A6049);
  static const Color _forestTint = Color(0xFFEBF3EE);
  static const Color _parchment = Color(0xFFE8E2D8);
  static const Color _charcoal = Color(0xFF1E1C18);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _parchment, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _forestTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _forest, size: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _charcoal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
