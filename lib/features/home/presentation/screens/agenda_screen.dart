import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import '../utils/activity_image_fallback.dart';
import 'package:go_router/go_router.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/presentation/widgets/planner_activity_detail_sheet.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'dynamic_my_day_provider.dart';
// WanderMood v2 — Agenda / calendar (Screen 10)
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForestTint = Color(0xFFEBF3EE);
/// Timeline / agenda status chip (UPCOMING) — matches My Day timeline.
const Color _wmSkyDeep = Color(0xFF5B7F92);
const Color _wmTimelineLine = Color(0xFFD5CFC6);
/// Fixed row height avoids [IntrinsicHeight] inside [SliverList], which can
/// trigger semantics / parentDataDirty assertion cascades on My Plans.
const double _kAgendaTimelineRowHeight = 232;

class _AgendaCardStatus {
  final Color color;
  final String label;
  final IconData icon;
  const _AgendaCardStatus(this.color, this.label, this.icon);
}

_AgendaCardStatus _agendaCardStatusFor(String? status, AppLocalizations l10n) {
  switch (status) {
    case 'completed':
      return _AgendaCardStatus(_wmForest, l10n.agendaStatusDone, Icons.check_circle_rounded);
    case 'cancelled':
      return _AgendaCardStatus(const Color(0xFFC62828), l10n.agendaStatusCancelled, Icons.cancel_outlined);
    case 'active':
      return _AgendaCardStatus(_wmSunset, l10n.agendaStatusNow, Icons.play_circle_filled_rounded);
    default:
      return _AgendaCardStatus(_wmSkyDeep, l10n.agendaStatusUpcoming, Icons.schedule_rounded);
  }
}

TextStyle _wmBodyAgendaTextStyle() => GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: _wmDusk,
      height: 1.5,
    );

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key, this.mainAppTourContentKey});

  final GlobalKey? mainAppTourContentKey;

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _viewMode = 'calendar'; // 'calendar' or 'list'
  bool _hasInitialized = false; // ✅ Prevent infinite loop
  final Map<String, Future<List<GroupMemberView>>> _sessionMembersCache = {};
  
  @override
  void initState() {
    super.initState();
    // Pick up a targetDate passed via MainScreen extra (e.g. from Mood Match
    // "Add to My Plans") so the calendar opens on the scheduled day, not today.
    final selectedFromProvider = ref.read(selectedMyDayDateProvider);
    _selectedDay = DateTime(
      selectedFromProvider.year,
      selectedFromProvider.month,
      selectedFromProvider.day,
    );
    _focusedDay = _selectedDay!;

    // ✅ FIXED: Only refresh once, not on every hot reload
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('🔄 Agenda: Screen opened ONCE, refreshing activities...');
          ref.invalidate(scheduledActivitiesForTodayProvider);
          ref.invalidate(cachedActivitySuggestionsProvider);
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Watch provider ONCE at top level of build
    final activitiesAsyncValue = ref.watch(cachedActivitySuggestionsProvider);
    // Re-sync the calendar when the shared date provider changes — e.g. the
    // user just added a Mood Match plan to a future date and landed here.
    ref.listen<DateTime>(selectedMyDayDateProvider, (prev, next) {
      if (!mounted) return;
      final nextDay = DateTime(next.year, next.month, next.day);
      if (_selectedDay != nextDay) {
        setState(() {
          _selectedDay = nextDay;
          _focusedDay = nextDay;
        });
      }
    });
    final scrollBody = CustomScrollView(
          slivers: [
            // Header Section
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: Text(
                AppLocalizations.of(context)!.agendaTitle,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _wmCharcoal,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
              actions: [
                // View mode toggle
                IconButton(
                  onPressed: () {
                    setState(() {
                      _viewMode = _viewMode == 'calendar' ? 'list' : 'calendar';
                    });
                  },
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [],
                    ),
                    child: Icon(
                      _viewMode == 'calendar' ? Icons.view_list : Icons.calendar_view_month,
                      color: const Color(0xFF2A6049),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            
            // Content based on view mode
            if (_viewMode == 'calendar') ...[
              _buildCalendarView(activitiesAsyncValue),
              _buildSelectedDayActivities(activitiesAsyncValue),
            ] else ...[
              _buildListView(activitiesAsyncValue),
            ],
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );

    final wrappedBody = widget.mainAppTourContentKey != null
        ? KeyedSubtree(
            key: widget.mainAppTourContentKey!,
            child: scrollBody,
          )
        : scrollBody;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8), // wmCream — no gradient (redesign QA)
      body: wrappedBody,
    );
  }
  
  Widget _buildCalendarView(AsyncValue<List<Map<String, dynamic>>> activitiesAsyncValue) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [],
          ),
          child: TableCalendar<Map<String, dynamic>>(
            locale: Localizations.localeOf(context).toString(),
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: (day) => _getEventsForDay(day, activitiesAsyncValue),
            calendarFormat: CalendarFormat.month,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: GoogleFonts.poppins(
                color: _wmCharcoal,
                fontWeight: FontWeight.w600,
              ),
              weekendTextStyle: GoogleFonts.poppins(
                color: _wmStone,
                fontWeight: FontWeight.w600,
              ),
              holidayTextStyle: GoogleFonts.poppins(
                color: _wmStone,
                fontWeight: FontWeight.w600,
              ),
              selectedTextStyle: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              todayTextStyle: GoogleFonts.poppins(
                color: _wmCharcoal,
                fontWeight: FontWeight.w600,
              ),
              selectedDecoration: const BoxDecoration(
                color: _wmForest,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: _wmForest.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                final visibleEvents = events.take(3).cast<Map<String, dynamic>>().toList();
                return Positioned(
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: visibleEvents.map((event) {
                      final color = _isMoodyGeneratedEvent(event)
                          ? _wmSunset
                          : _wmForest;
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _wmCharcoal,
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: _wmForest,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: _wmForest,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _wmCharcoal,
              ),
              weekendStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _wmStone,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
      ),
    );
  }
  
  Widget _buildSelectedDayActivities(AsyncValue<List<Map<String, dynamic>>> activitiesAsyncValue) {
    final l10n = AppLocalizations.of(context)!;
    // ✅ FIXED: Receive data as parameter instead of calling ref.watch
    return activitiesAsyncValue.when(
      data: (activities) {
        final selectedDate = _selectedDay ?? DateTime.now();
        print('📅 Agenda: Looking for activities on ${selectedDate.toString()}');
        print('📅 Agenda: Total activities loaded: ${activities.length}');
        
        final events = activities.where((activity) {
          final startTimeStr = activity['startTime'] as String?;
          if (startTimeStr == null) {
            print('⚠️ Agenda: Activity ${activity['title']} has no startTime');
            return false;
          }
          
          try {
            final activityDate = DateTime.parse(startTimeStr);
            final matches = isSameDay(activityDate, selectedDate);
            if (matches) {
              print('✅ Agenda: Found matching activity: ${activity['title']} on ${activityDate.toString()}');
            }
            return matches;
          } catch (e) {
            print('❌ Agenda: Error parsing startTime for ${activity['title']}: $e');
            return false;
          }
        }).map((activity) => _transformActivityData(activity)).toList();
        
        print('📅 Agenda: Found ${events.length} events for selected day');
        
        if (events.isEmpty) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
          final diff = selected.difference(today).inDays;

          String emoji;
          String title;
          String subtitle;

          if (diff == 0) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  decoration: BoxDecoration(
                    color: _wmWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _wmParchment,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const MoodyCharacter(
                        size: 88,
                        mood: 'happy',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.agendaEmptyPlansTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _wmForest,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.agendaEmptyPlansSubtitle,
                        style: _wmBodyAgendaTextStyle(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => _openMoodyPlannerForDate(selectedDate),
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: _wmForest,
                            borderRadius: BorderRadius.circular(27),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                l10n.agendaPlanWithMoody,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _openManualAddForDate(selectedDate),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: _wmWhite,
                            border: Border.all(color: _wmParchment),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, color: _wmForest, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                l10n.agendaAddActivity,
                                style: GoogleFonts.poppins(
                                  color: _wmForest,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
              ),
            );
          }

          if (diff == 1) {
            emoji = '🌙';
            title = l10n.agendaTomorrowEmpty;
            subtitle = l10n.agendaTomorrowSubtitle;
          } else if (diff <= 7) {
            final dayName = _getDayName(selectedDate);
            emoji = '📅';
            title = l10n.agendaDayEmpty(dayName);
            subtitle = l10n.agendaDaySubtitle(dayName);
          } else {
            emoji = '✈️';
            title = l10n.agendaFarFutureEmpty;
            subtitle = l10n.agendaFarFutureSubtitle;
          }

          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _wmWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _wmParchment,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _wmCharcoal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: _wmBodyAgendaTextStyle(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => _openMoodyPlannerForDate(selectedDate),
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: _wmForest,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              l10n.agendaPlanWithMoody,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _openManualAddForDate(selectedDate),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: _wmWhite,
                          border: Border.all(color: _wmParchment),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, color: _wmForest, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              l10n.agendaAddActivity,
                              style: GoogleFonts.poppins(
                                color: _wmForest,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
            ),
          );
        }
        
        final sorted = List<Map<String, dynamic>>.from(events)
          ..sort((a, b) => _agendaActivitySortKey(a).compareTo(_agendaActivitySortKey(b)));
        final nextUp = _agendaNextUpIndex(sorted, selectedDate);

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final activity = sorted[index];
              return _buildAgendaTimelineRow(
                index: index,
                total: sorted.length,
                activity: activity,
                showNextUp: nextUp == index,
              );
            },
            childCount: sorted.length,
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.agendaLoadingActivities,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.agendaErrorLoadingActivities,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.agendaPleaseTryAgainLater,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openMoodyPlannerForDate(DateTime targetDate) {
    context.push(
      '/moody',
      extra: {'targetDate': targetDate.toIso8601String()},
    );
  }

  void _openManualAddForDate(DateTime selectedDate) {
    context.push('/main?tab=1', extra: {
      'targetDate': selectedDate.toIso8601String(),
      'source': 'agenda_manual_add',
    });
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.agendaChooseActivityForDay(
        _getDayName(selectedDate).toLowerCase(),
      ),
    );
  }

  String _getDayName(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final days = [l10n.dayMon, l10n.dayTue, l10n.dayWed, l10n.dayThu, l10n.dayFri, l10n.daySat, l10n.daySun];
    return days[date.weekday - 1];
  }
  
  Widget _buildListView(AsyncValue<List<Map<String, dynamic>>> activitiesAsyncValue) {
    // ✅ FIXED: Receive data as parameter instead of calling ref.watch
    return activitiesAsyncValue.when(
      data: (activities) {
        final upcomingActivities = _getUpcomingActivities(activities);
        
        if (upcomingActivities.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2A6049).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: MoodyCharacter(
                        size: 48,
                        mood: 'happy',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.agendaNoActivitiesScheduled,
                      style: _wmBodyAgendaTextStyle(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.agendaNoActivitiesPlannedYet,
                      style: _wmBodyAgendaTextStyle(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
            ),
          );
        }
        
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = upcomingActivities.entries.elementAt(index);
              final date = entry.key;
              final activities = entry.value;
              
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A6049).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2A6049).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _formatDateHeader(date),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2A6049),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Activities for this date
                    ...activities.map((activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAgendaActivityCard(activity),
                    )),
                  ],
                ),
              ).animate(delay: (index * 100).ms)
                .slideX(begin: 0.3, duration: 600.ms)
                .fadeIn(duration: 600.ms);
            },
            childCount: upcomingActivities.length,
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.agendaLoadingActivities,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.agendaErrorLoadingActivities,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.agendaPleaseTryAgainLater,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _agendaCategoryLabel(Map<String, dynamic> activity) {
    final raw = (activity['category'] ?? 'Activity').toString().trim();
    if (raw.isEmpty) return 'Activity';
    return '${raw[0].toUpperCase()}${raw.length > 1 ? raw.substring(1) : ''}';
  }

  Future<List<GroupMemberView>> _membersForSession(String sessionId) {
    return _sessionMembersCache.putIfAbsent(sessionId, () {
      final repo = ref.read(groupPlanningRepositoryProvider);
      return repo.fetchMembersWithProfiles(sessionId);
    });
  }

  Widget _agendaMiniAvatar(String? url, String fallback) {
    final u = url?.trim();
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: CircleAvatar(
        radius: 11,
        backgroundColor: _wmForest,
        backgroundImage: u != null && u.isNotEmpty ? NetworkImage(u) : null,
        child: u == null || u.isEmpty
            ? Text(
                fallback,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _agendaSessionAvatarPill(String sessionId) {
    return FutureBuilder<List<GroupMemberView>>(
      future: _membersForSession(sessionId),
      builder: (context, snap) {
        final members = snap.data ?? const <GroupMemberView>[];
        final me = Supabase.instance.client.auth.currentUser?.id;
        GroupMemberView? first;
        GroupMemberView? second;
        if (members.isNotEmpty) {
          first = members.firstWhere(
            (m) => m.member.userId == me,
            orElse: () => members.first,
          );
          second = members.firstWhere(
            (m) => m.member.userId != first?.member.userId,
            orElse: () => members.length > 1 ? members[1] : members.first,
          );
        }
        final firstInitial = first?.displayName.trim().isNotEmpty == true
            ? first!.displayName.trim()[0].toUpperCase()
            : 'Y';
        final secondInitial = second?.displayName.trim().isNotEmpty == true
            ? second!.displayName.trim()[0].toUpperCase()
            : '?';
        return Container(
          padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _wmParchment, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _agendaMiniAvatar(first?.avatarUrl, firstInitial),
              Transform.translate(
                offset: const Offset(-6, 0),
                child: _agendaMiniAvatar(second?.avatarUrl, secondInitial),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgendaPaymentBadge(String paymentStatus) {
    switch (paymentStatus) {
      case 'free':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _wmForest.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco_rounded, size: 12, color: _wmForest),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.agendaPaymentBadgeFree,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _wmForest,
                ),
              ),
            ],
          ),
        );
      case 'paid':
        const paidColor = Color(0xFF1976D2);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: paidColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: paidColor.withValues(alpha: 0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 12, color: paidColor),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.agendaPaymentBadgePaid,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: paidColor,
                ),
              ),
            ],
          ),
        );
      case 'reserved':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _wmSunset.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _wmSunset.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 12, color: _wmSunset),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.agendaPaymentBadgeReserved,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _wmSunset,
                ),
              ),
            ],
          ),
        );
      case 'pending':
        const pendColor = Color(0xFF7E57C2);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: pendColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pendColor.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty_rounded, size: 12, color: pendColor),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.agendaPaymentBadgePending,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: pendColor,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  int? _agendaNextUpIndex(List<Map<String, dynamic>> sorted, DateTime selectedDay) {
    if (sorted.isEmpty) return null;
    final now = DateTime.now();
    final sel = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final t0 = DateTime(now.year, now.month, now.day);
    if (sel.isBefore(t0)) return null;
    if (sel.isAfter(t0)) return 0;
    for (var i = 0; i < sorted.length; i++) {
      final s = sorted[i]['status']?.toString() ?? '';
      if (s == 'upcoming' || s == 'active') return i;
    }
    return null;
  }

  DateTime _agendaActivitySortKey(Map<String, dynamic> a) {
    final s = a['startTime'] as String?;
    if (s != null) {
      return DateTime.tryParse(s) ?? DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime.now();
    }
    return DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime.now();
  }

  Widget _buildAgendaTimelineLeading(int index, int total, bool highlight) {
    const line = _wmTimelineLine;
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final mid = h * 0.5;
        const nodeR = 10.0;
        return SizedBox(
          width: 26,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (index > 0)
                Positioned(
                  left: 11,
                  top: 0,
                  width: 2,
                  height: (mid - nodeR).clamp(0.0, 999.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              if (index < total - 1)
                Positioned(
                  left: 11,
                  top: mid + nodeR,
                  width: 2,
                  height: (h - mid - nodeR).clamp(0.0, 999.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: nodeR * 2,
                  height: nodeR * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlight ? _wmForest : Colors.white,
                    border: Border.all(
                      color: highlight ? _wmForest : line,
                      width: highlight ? 1 : 2,
                    ),
                  ),
                  child: highlight
                      ? Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgendaTimelineRow({
    required int index,
    required int total,
    required Map<String, dynamic> activity,
    required bool showNextUp,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final durationM = activity['duration'] as int? ?? 60;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, index == 0 ? 20 : 0, 12, index == total - 1 ? 24 : 14),
      child: SizedBox(
        height: _kAgendaTimelineRowHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAgendaTimelineLeading(index, total, showNextUp),
            const SizedBox(width: 6),
            SizedBox(
              width: 78,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['time']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _wmCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.agendaDurationShort('$durationM'),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _wmStone,
                      ),
                    ),
                    if (showNextUp) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _wmForestTint,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _wmForest.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          l10n.myDayStatusTitleUpNext,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _wmForest,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _buildAgendaActivityCard(activity, timelineMode: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaActivityCard(Map<String, dynamic> activity, {bool timelineMode = false}) {
    final l10n = AppLocalizations.of(context)!;
    final statusStr = (activity['status'] ?? 'upcoming').toString();
    final paymentStatus = activity['paymentStatus'] ?? 'free';
    final price = (activity['price'] as num?)?.toDouble() ?? 0.0;
    final cardStatus = _agendaCardStatusFor(statusStr, l10n);
    final durationM = activity['duration'] as int? ?? 60;
    final timeLabel = activity['time'] ?? '10:00 AM';
    final groupSessionId = activity['groupSessionId']?.toString();

    final footerBits = <String>[];
    if (!timelineMode) {
      footerBits.add(l10n.agendaDurationShort('$durationM'));
    }
    if (paymentStatus != 'free' && price > 0) {
      footerBits.add('€${price.toStringAsFixed(2)}');
    } else if (paymentStatus != 'free') {
      footerBits.add(paymentStatus.toUpperCase());
    }
    final footerSubtitle = footerBits.isEmpty ? '' : footerBits.join(' · ');
    final heroUrlRaw = activity['imageUrl']?.toString().trim() ?? '';
    final placeIdForPhoto =
        (activity['placeId'] ?? activity['place_id'])?.toString();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        unawaited(_showActivityDetails(activity));
      },
      child: Container(
        height: 216,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _wmParchment, width: 0.5),
          boxShadow: const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ActivityPhoto(
                        directUrl: heroUrlRaw,
                        placeId: placeIdForPhoto,
                        category: activity['category']?.toString(),
                        title: (activity['title'] ?? activity['name'])
                            ?.toString(),
                        mood: activity['mood']?.toString(),
                        progressIndicatorBuilder: (context, url, progress) =>
                            Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.progress,
                            ),
                          ),
                        ),
                        placeholderBuilder: (context) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cardStatus.color.withValues(alpha: 0.85),
                                cardStatus.color.withValues(alpha: 0.55),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child:
                                Icon(Icons.image, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.62),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (!timelineMode)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.schedule, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$timeLabel • ${durationM}m',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (timelineMode) const Spacer(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (paymentStatus == 'free' ||
                                        paymentStatus == 'paid' ||
                                        paymentStatus == 'reserved' ||
                                        paymentStatus == 'pending') ...[
                                      _buildAgendaPaymentBadge(paymentStatus),
                                      const SizedBox(width: 6),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: cardStatus.color,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(cardStatus.icon, color: Colors.white, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            cardStatus.label,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (!timelineMode)
                              Text(
                                activity['title'] ?? 'Activity',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ColoredBox(
                color: _wmWhite,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (timelineMode) ...[
                              Text(
                                activity['title']?.toString() ?? l10n.agendaUntitledActivity,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _wmForest,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              _agendaCategoryLabel(activity),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _wmCharcoal,
                              ),
                            ),
                            if (footerSubtitle.isNotEmpty)
                              Text(
                                footerSubtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _wmStone,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (groupSessionId != null &&
                                groupSessionId.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0F5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFE8B4C4),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.moodMatchWithBadge(
                                        l10n.moodMatchFriendThey,
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFB5375E),
                                      ),
                                    ),
                                  ),
                                  _agendaSessionAvatarPill(groupSessionId),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: _wmForest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _openAgendaDirections(activity);
                                },
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.socialGetDirections,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            offset: const Offset(0, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _wmForestTint,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _wmParchment, width: 0.5),
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.more_vert, size: 16, color: _wmStone),
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'details':
                                  unawaited(_showActivityDetails(activity));
                                  break;
                                case 'directions':
                                  _openAgendaDirections(activity);
                                  break;
                                case 'delete':
                                  _deleteScheduledActivity(activity);
                                  break;
                                case 'share':
                                  _shareActivity(activity);
                                  break;
                              }
                            },
                            itemBuilder: (context) {
                              return [
                                PopupMenuItem(
                                  value: 'details',
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 18, color: _wmForest),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.myDayViewDetails, style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'directions',
                                  child: Row(
                                    children: [
                                      Icon(Icons.directions_rounded, size: 18, color: _wmForest),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.socialGetDirections, style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(context)!.periodActivitiesRemoveCta,
                                        style: GoogleFonts.poppins(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.share, size: 18),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.socialShare, style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Map<String, dynamic>> _getEventsForDay(DateTime day, AsyncValue<List<Map<String, dynamic>>> activitiesAsyncValue) {
    // ✅ FIXED: Receive data as parameter instead of calling ref.watch
    return activitiesAsyncValue.when(
      data: (activities) {
        return activities.where((activity) {
          final startTimeStr = activity['startTime'] as String?;
          if (startTimeStr == null) return false;
          
          final activityDate = DateTime.parse(startTimeStr);
          return isSameDay(activityDate, day);
        }).map((activity) => _transformActivityData(activity)).toList();
      },
      loading: () => [],
      error: (error, stack) => [],
    );
  }
  
  Map<DateTime, List<Map<String, dynamic>>> _getUpcomingActivities(List<Map<String, dynamic>> activities) {
    // ✅ FIXED: Receive data as parameter instead of calling ref.watch
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
    
    for (final activity in activities) {
      final startTimeStr = activity['startTime'] as String?;
      if (startTimeStr == null) continue;
      
      final activityDate = DateTime.parse(startTimeStr);
      final dateKey = DateTime(activityDate.year, activityDate.month, activityDate.day);
      
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(_transformActivityData(activity));
    }
    
    // Sort by date
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return Map.fromEntries(sortedEntries);
  }
  
  Map<String, dynamic> _transformActivityData(Map<String, dynamic> activity) {
    final l10n = AppLocalizations.of(context)!;
    final activityManager = ref.watch(activityManagerProvider);
    final activityId = activity['id'] as String? ?? activity['title'] as String? ?? '';
    
    // Transform the data structure to match UI expectations
    final startTimeStr = activity['startTime'] as String?;
    final startTime = startTimeStr != null ? DateTime.parse(startTimeStr) : DateTime.now();
    
    final transformed = {
      'id': activityId,
      'title': activity['title'] ?? activity['name'] ?? l10n.agendaUntitledActivity,
      'description': activity['description'] ?? l10n.agendaNoDescription,
      'date': startTime.toIso8601String(),
      'time': _formatTime(context, startTime),
      'duration': activity['duration'] ?? 60,
      'status': _getActivityStatus(activity, activityManager),
      'location': activity['location'] ?? l10n.agendaLocationTBD,
      'imageUrl': () {
        final u = activity['imageUrl']?.toString().trim() ?? '';
        return u.isNotEmpty ? u : _getDefaultImageUrl(activity);
      }(),
      'paymentStatus': _getPaymentStatus(activity),
      'price': activity['price'] ?? 0.0,
      'category': activity['category'] ?? 'general',
      'mood': activity['mood'] ?? 'neutral',
      'placeId': activity['placeId'] ?? activity['place_id'],
      'place_id': activity['place_id'] ?? activity['placeId'],
      'rating': activity['rating'] ?? 0.0,
      'timeOfDay': activity['timeOfDay'] ?? 'any',
      'startTime': activity['startTime'],
      'groupSessionId': activity['groupSessionId'] ?? activity['group_session_id'],
    };
    
    return transformed;
  }
  
  String _formatTime(BuildContext context, DateTime dateTime) {
    final loc = Localizations.localeOf(context).toString();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'nl' || lang == 'de' || lang == 'fr' || lang == 'es') {
      return DateFormat.Hm(loc).format(dateTime);
    }
    return DateFormat.jm(loc).format(dateTime);
  }
  
  String _getActivityStatus(Map<String, dynamic> activity, ActivityManagerState activityManager) {
    final activityId = activity['id'] as String? ?? activity['title'] as String? ?? '';
    final startTimeStr0 = activity['startTime'] as String?;
    final startTime0 =
        startTimeStr0 != null ? DateTime.parse(startTimeStr0) : DateTime.now();
    final managerStatus = activityStatusForScheduledDay(
      manager: activityManager,
      activityStartTime: startTime0,
      activityId: activityId,
    );
    
    if (managerStatus == ActivityStatus.cancelled) {
      // Unbooked items were incorrectly "cancelled" in memory only; keep showing real time state.
      if (_getPaymentStatus(activity) != 'free') {
        return 'cancelled';
      }
    }
    
    final startTimeStr = activity['startTime'] as String?;
    if (startTimeStr == null) return 'upcoming';
    
    final startTime = DateTime.parse(startTimeStr);
    final duration = activity['duration'] as int? ?? 60;
    final endTime = startTime.add(Duration(minutes: duration));
    final now = DateTime.now();
    
    if (now.isAfter(endTime)) {
      return 'completed';
    } else if (now.isAfter(startTime)) {
      return 'active';
    } else {
      return 'upcoming';
    }
  }
  
  String _getPaymentStatus(Map<String, dynamic> activity) {
    final paymentType = activity['paymentType'] as String?;
    final price = activity['price'] as double? ?? 0.0;
    
    if (price == 0.0) {
      return 'free';
    }
    
    // Map payment types to UI payment statuses
    switch (paymentType?.toLowerCase()) {
      case 'paid':
        return 'paid';
      case 'reserved':
        return 'reserved';
      case 'pending':
        return 'pending';
      default:
        return 'free';
    }
  }
  
  String _getDefaultImageUrl(Map<String, dynamic> activity) {
    final category = activity['category']?.toString().toLowerCase() ?? '';
    final title = activity['title']?.toString().toLowerCase() ?? '';
    
    // Return category-based default images
    if (category.contains('nature') || title.contains('garden') || title.contains('park')) {
      return 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80';
    } else if (category.contains('cultural') || title.contains('museum') || title.contains('gallery')) {
      return 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&q=80';
    } else if (category.contains('food') || title.contains('market') || title.contains('restaurant')) {
      return 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=400&q=80';
    } else if (category.contains('outdoor') || title.contains('walk') || title.contains('beach')) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&q=80';
    } else {
      // Generic activity image
      return 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&q=80';
    }
  }
  
  String _formatDateHeader(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (isSameDay(date, now)) {
      return l10n.agendaHeaderToday;
    } else if (isSameDay(date, tomorrow)) {
      return l10n.agendaHeaderTomorrow;
    } else if (isSameDay(date, yesterday)) {
      return l10n.agendaHeaderYesterday;
    } else {
      final shortMonths = [
        l10n.monthJan,
        l10n.monthFeb,
        l10n.monthMar,
        l10n.monthApr,
        l10n.monthMay,
        l10n.monthJun,
        l10n.monthJul,
        l10n.monthAug,
        l10n.monthSep,
        l10n.monthOct,
        l10n.monthNov,
        l10n.monthDec,
      ];
      return '${shortMonths[date.month - 1]} ${date.day}';
    }
  }

  bool _isMoodyGeneratedEvent(Map<String, dynamic> event) {
    final source = (event['source'] ?? event['createdBy'] ?? '').toString().toLowerCase();
    if (source.contains('manual') || source.contains('user')) return false;
    if (source.contains('moody') || source.contains('ai')) return true;
    // Default to Moody-generated for older rows that don't store source metadata.
    return true;
  }
  
  Future<void> _openAgendaDirections(Map<String, dynamic> activity) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;
      var lat = (activity['lat'] as num?)?.toDouble();
      var lng = (activity['lng'] as num?)?.toDouble();
      if (lat == null || lng == null || lat == 0 || lng == 0) {
        final loc = activity['location']?.toString() ?? '';
        final parts = loc.split(',');
        if (parts.length == 2) {
          lat = double.tryParse(parts[0].trim());
          lng = double.tryParse(parts[1].trim());
        }
      }
      final hasCoords = lat != null && lng != null && lat != 0 && lng != 0;

      if (availableMaps.isNotEmpty && hasCoords) {
        await availableMaps.first.showMarker(
          coords: Coords(lat, lng),
          title: activity['title']?.toString() ?? AppLocalizations.of(context)!.agendaUntitledActivity,
          description: activity['description']?.toString() ?? '',
        );
        return;
      }

      final query = hasCoords
          ? '$lat,$lng'
          : (activity['title'] ?? AppLocalizations.of(context)!.agendaUntitledActivity).toString();
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception(AppLocalizations.of(context)!.socialOpenDirectionsFailed);
      }
    } catch (_) {
      if (!mounted) return;
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.socialOpenDirectionsFailed,
        isError: true,
      );
    }
  }

  /// Remove a planner activity from Supabase and refresh agenda state.
  Future<void> _deleteScheduledActivity(Map<String, dynamic> activity) async {
    final title = activity['title'] as String? ?? 'Activiteit';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.socialDeleteActivityConfirmTitle,
          style: GoogleFonts.museoModerno(
            fontWeight: FontWeight.bold,
            color: _wmCharcoal,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.agendaDeleteDialogBody(title),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              AppLocalizations.of(context)!.agendaDeleteDialogBack,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final activityId =
                  activity['id'] as String? ?? activity['title'] as String? ?? '';
              if (activityId.isEmpty) {
                if (mounted) {
                  showWanderMoodToast(
                    context,
                    message: AppLocalizations.of(context)!.agendaDeleteMissingId,
                    isError: true,
                  );
                }
                return;
              }
              try {
                await ref
                    .read(scheduledActivityServiceProvider)
                    .deleteScheduledActivity(activityId);
                ref
                    .read(activityManagerProvider.notifier)
                    .clearLocalStatusForActivity(activityId);
                ref.invalidate(scheduledActivityServiceProvider);
                ref.invalidate(cachedActivitySuggestionsProvider);
                ref.invalidate(scheduledActivitiesForTodayProvider);
                ref.invalidate(todayActivitiesProvider);
                await ref.read(scheduledActivitiesForTodayProvider.future);
                await ref.read(todayActivitiesProvider.future);
                if (mounted) {
                  showWanderMoodToast(
                    context,
                    message:
                        AppLocalizations.of(context)!.agendaRemovedFromPlanner(title),
                  );
                }
              } catch (e) {
                if (mounted) {
                  showWanderMoodToast(
                    context,
                    message: AppLocalizations.of(context)!.socialDeleteFailedTryAgain,
                    isError: true,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.agendaDeleteDialogConfirm,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareActivity(Map<String, dynamic> activity) {
    // In a real app, this would use the share_plus package
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.socialShareActivityDetailsCopied,
    );
  }
  
  Future<void> _showActivityDetails(Map<String, dynamic> activity) async {
    final routePlaceId = resolvePlannerPlaceDetailRouteId(activity);
    final moodMatchSessionId = resolvePlannerGroupSessionId(activity);
    // Mood Match + place: same quick sheet as My Day (pair chrome + embedded place).
    // Other place-linked rows: keep full-screen place detail.
    if (routePlaceId != null && moodMatchSessionId == null) {
      context.pushNamed('place-detail', pathParameters: {'id': routePlaceId});
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    await showPlannerActivityDetailSheet(
      context,
      activity: activity,
      scheduledTimeLabel: activity['time']?.toString(),
      footerBuilder: (pop) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      pop();
                      _openAgendaDirections(activity);
                    },
                    icon: const Icon(Icons.directions),
                    label: Text(l10n.socialGetDirections),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2A6049),
                      side: const BorderSide(color: Color(0xFF2A6049)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      pop();
                      _deleteScheduledActivity(activity);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.myDayDeleteActivityCta),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (routePlaceId != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  pop();
                  if (!context.mounted) return;
                  context.pushNamed(
                    'place-detail',
                    pathParameters: {'id': routePlaceId},
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: Text(l10n.myDayOpenFullPlaceDetails),
                style: placeQuickSheetOutlinedButtonStyle(),
              ),
            ],
          ],
        );
      },
    );
  }
}
