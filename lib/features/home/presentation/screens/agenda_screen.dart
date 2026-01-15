import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dynamic_my_day_provider.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../../plans/data/services/scheduled_activity_service.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _viewMode = 'calendar'; // 'calendar' or 'list'
  bool _hasInitialized = false; // ✅ Prevent infinite loop
  
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    
    // ✅ FIXED: Only refresh once, not on every hot reload
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('🔄 Agenda: Screen opened ONCE, refreshing activities...');
          ref.invalidate(cachedActivitySuggestionsProvider);
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Watch provider ONCE at top level of build
    final activitiesAsyncValue = ref.watch(cachedActivitySuggestionsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SwirlBackground(
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              snap: true,
              leading: IconButton(
                onPressed: () {
                  print('🔙 Back button pressed on agenda screen');
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/home');
                  }
                },
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF12B347),
                    size: 20,
                  ),
                ),
              ),
              title: Text(
                'My Agenda',
                style: GoogleFonts.museoModerno(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF12B347),
                  letterSpacing: 0.5,
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _viewMode == 'calendar' ? Icons.view_list : Icons.calendar_view_month,
                      color: const Color(0xFF12B347),
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
        ),
      ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TableCalendar<Map<String, dynamic>>(
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
              weekendTextStyle: GoogleFonts.poppins(
                color: const Color(0xFF12B347),
                fontWeight: FontWeight.w600,
              ),
              holidayTextStyle: GoogleFonts.poppins(
                color: const Color(0xFF12B347),
                fontWeight: FontWeight.w600,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF12B347),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF12B347).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.museoModerno(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF12B347),
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Color(0xFF12B347),
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Color(0xFF12B347),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              weekendStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF12B347),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
      ),
    );
  }
  
  Widget _buildSelectedDayActivities(AsyncValue<List<Map<String, dynamic>>> activitiesAsyncValue) {
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
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF12B347).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No activities planned',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add activities for this day',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
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
              final activity = events[index];
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  24, 
                  index == 0 ? 24 : 8, 
                  24, 
                  index == events.length - 1 ? 24 : 8
                ),
                child: _buildAgendaActivityCard(activity),
              );
            },
            childCount: events.length,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading activities...',
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
                  'Error loading activities',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
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
                    color: const Color(0xFF12B347).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No upcoming activities',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Schedule some activities to see them here',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
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
                        color: const Color(0xFF12B347).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF12B347).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _formatDateHeader(date),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF12B347),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading activities...',
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
                  'Error loading activities',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
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
  
  Widget _buildAgendaActivityCard(Map<String, dynamic> activity) {
    final status = activity['status'] ?? 'upcoming';
    final paymentStatus = activity['paymentStatus'] ?? 'free';
    final price = activity['price'] ?? 0.0;
    
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusText = 'COMPLETED';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'CANCELLED';
        break;
      case 'active':
        statusColor = Colors.red;
        statusText = 'RIGHT NOW';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'UPCOMING';
    }
    
    // Payment status styling
    Color paymentColor;
    String paymentText;
    IconData paymentIcon;
    
    switch (paymentStatus) {
      case 'free':
        paymentColor = Colors.green;
        paymentText = 'FREE';
        paymentIcon = Icons.park;
        break;
      case 'paid':
        paymentColor = Colors.blue;
        paymentText = 'PAID';
        paymentIcon = Icons.check_circle;
        break;
      case 'reserved':
        paymentColor = Colors.orange;
        paymentText = 'RESERVED';
        paymentIcon = Icons.schedule;
        break;
      case 'pending':
        paymentColor = Colors.purple;
        paymentText = 'PENDING';
        paymentIcon = Icons.hourglass_empty;
        break;
      default:
        paymentColor = Colors.grey;
        paymentText = 'TBD';
        paymentIcon = Icons.help_outline;
    }
    
    return GestureDetector(
      onTap: () => _showActivityDetails(activity),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Time and image
              Column(
                children: [
                  Text(
                    activity['time'] ?? '10:00 AM',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF12B347),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: activity['imageUrl'] ?? _getDefaultImageUrl(activity),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF12B347).withOpacity(0.2),
                          child: const Icon(
                            Icons.image,
                            color: Color(0xFF12B347),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Activity details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            activity['title'] ?? 'Activity',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            // Payment status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: paymentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: paymentColor, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    paymentIcon,
                                    size: 10,
                                    color: paymentColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    paymentText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: paymentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Activity status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['description'] ?? 'No description available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity['duration'] ?? 60} minutes',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity['location'] ?? 'Location TBD',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (price > 0 || paymentStatus != 'free') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            paymentStatus == 'free' ? Icons.money_off : Icons.euro,
                            size: 14,
                            color: paymentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            paymentStatus == 'free' 
                              ? 'Free Activity' 
                              : price > 0 
                                ? '€${price.toStringAsFixed(2)}'
                                : 'Price TBD',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: paymentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (paymentStatus == 'paid') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CONFIRMED',
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
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
    final activityManager = ref.watch(activityManagerProvider);
    final activityId = activity['id'] as String? ?? activity['title'] as String? ?? '';
    
    // Transform the data structure to match UI expectations
    final startTimeStr = activity['startTime'] as String?;
    final startTime = startTimeStr != null ? DateTime.parse(startTimeStr) : DateTime.now();
    
    final transformed = {
      'id': activityId,
      'title': activity['title'] ?? activity['name'] ?? 'Untitled Activity',
      'description': activity['description'] ?? 'No description available',
      'date': startTime.toIso8601String(),
      'time': _formatTime(startTime),
      'duration': activity['duration'] ?? 60,
      'status': _getActivityStatus(activity, activityManager),
      'location': activity['location'] ?? 'Location TBD',
      'imageUrl': activity['imageUrl'] ?? _getDefaultImageUrl(activity),
      'paymentStatus': _getPaymentStatus(activity),
      'price': activity['price'] ?? 0.0,
      'category': activity['category'] ?? 'general',
      'mood': activity['mood'] ?? 'neutral',
    };
    
    return transformed;
  }
  
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
  
  String _getActivityStatus(Map<String, dynamic> activity, ActivityManagerState activityManager) {
    final activityId = activity['id'] as String? ?? activity['title'] as String? ?? '';
    final managerStatus = activityManager.statusUpdates[activityId];
    
    if (managerStatus == ActivityStatus.cancelled) {
      return 'cancelled';
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
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (isSameDay(date, now)) {
      return 'Today';
    } else if (isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    } else if (isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
  
  IconData _getEditButtonIcon(String? paymentStatus) {
    switch (paymentStatus) {
      case 'free':
        return Icons.edit;
      case 'paid':
        return Icons.receipt;
      case 'reserved':
        return Icons.payment;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.edit;
    }
  }
  
  String _getEditButtonText(String? paymentStatus) {
    switch (paymentStatus) {
      case 'free':
        return 'Edit Activity';
      case 'paid':
        return 'View Receipt';
      case 'reserved':
        return 'Complete Payment';
      case 'pending':
        return 'Check Status';
      default:
        return 'Edit Activity';
    }
  }
  
  Color _getEditButtonColor(String? paymentStatus) {
    switch (paymentStatus) {
      case 'free':
        return const Color(0xFF12B347);
      case 'paid':
        return Colors.blue;
      case 'reserved':
        return Colors.orange;
      case 'pending':
        return Colors.purple;
      default:
        return const Color(0xFF12B347);
    }
  }
  
  String _getFormattedPrice(Map<String, dynamic> activity) {
    final paymentStatus = activity['paymentStatus'] ?? 'free';
    final price = activity['price'] ?? 0.0;
    
    if (paymentStatus == 'free') {
      return 'Free Activity';
    } else if (price > 0) {
      return '€${price.toStringAsFixed(2)}';
    } else {
      return 'Price TBD';
    }
  }
  
  String _getPaymentStatusText(String? paymentStatus) {
    switch (paymentStatus) {
      case 'free':
        return 'No payment required';
      case 'paid':
        return 'Payment confirmed';
      case 'reserved':
        return 'Reserved - Payment due';
      case 'pending':
        return 'Payment processing';
      default:
        return 'Status unknown';
    }
  }
  
  void _handleMainAction(Map<String, dynamic> activity) {
    final paymentStatus = activity['paymentStatus'] ?? 'free';
    
    switch (paymentStatus) {
      case 'free':
        _editActivity(activity);
        break;
      case 'paid':
        _viewReceipt(activity);
        break;
      case 'reserved':
        _completePayment(activity);
        break;
      case 'pending':
        _checkPaymentStatus(activity);
        break;
      default:
        _editActivity(activity);
    }
  }
  
  void _viewReceipt(Map<String, dynamic> activity) {
    context.go('/view-receipt', extra: activity);
  }
  
  void _editActivity(Map<String, dynamic> activity) {
    context.go('/edit-activity', extra: activity);
  }
  
  void _getDirections(Map<String, dynamic> activity) {
    // In a real app, this would open maps with directions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening directions to ${activity['location']}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF12B347),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  void _completePayment(Map<String, dynamic> activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Redirecting to payment for ${activity['title']}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  void _checkPaymentStatus(Map<String, dynamic> activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Checking payment status for ${activity['title']}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  void _cancelActivity(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Activity',
          style: GoogleFonts.museoModerno(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel "${activity['title']}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Keep Activity',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // Cancel the activity using the activity manager
              final activityId = activity['id'] as String? ?? activity['title'] as String? ?? '';
              if (activityId.isNotEmpty) {
                ref.read(activityManagerProvider.notifier).cancelActivity(activityId);
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Activity cancelled successfully',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel Activity',
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
    final shareText = '''
Check out this activity I have planned!

${activity['title']}
📅 ${_formatDateHeader(DateTime.parse(activity['date']))} at ${activity['time']}
📍 ${activity['location']}
⏱️ ${activity['duration']} minutes

${activity['description']}
''';

    // In a real app, this would use the share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Activity details copied to share',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF12B347),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  'Share Content',
                  style: GoogleFonts.museoModerno(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  shareText,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(color: const Color(0xFF12B347)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  void _showActivityDetails(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and actions
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                activity['title'] ?? 'Activity',
                                style: GoogleFonts.museoModerno(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                Navigator.pop(context);
                                switch (value) {
                                  case 'edit':
                                    _editActivity(activity);
                                    break;
                                  case 'cancel':
                                    _cancelActivity(activity);
                                    break;
                                  case 'share':
                                    _shareActivity(activity);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'cancel',
                                  child: Row(
                                    children: [
                                      Icon(Icons.cancel, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Cancel', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share, size: 18),
                                      SizedBox(width: 8),
                                      Text('Share'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Activity image
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: activity['imageUrl'] ?? _getDefaultImageUrl(activity),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF12B347).withOpacity(0.8),
                                      const Color(0xFF4CAF50).withOpacity(0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image, color: Colors.white, size: 60),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Activity details
                        _buildDetailRow('📅 Date', _formatDateHeader(DateTime.parse(activity['date']))),
                        _buildDetailRow('⏰ Time', activity['time'] ?? 'TBD'),
                        _buildDetailRow('⏱️ Duration', '${activity['duration'] ?? 60} minutes'),
                        _buildDetailRow('📍 Location', activity['location'] ?? 'TBD'),
                        _buildDetailRow('💰 Price', _getFormattedPrice(activity)),
                        _buildDetailRow('💳 Payment', _getPaymentStatusText(activity['paymentStatus'])),
                        
                        const SizedBox(height: 24),
                        
                        // Description
                        Text(
                          'Description',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activity['description'] ?? 'No description available',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Moody Advice Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF12B347).withOpacity(0.1),
                                const Color(0xFF12B347).withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF12B347).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF12B347),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.lightbulb,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Moody advises to:',
                                    style: GoogleFonts.museoModerno(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF12B347),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _getMoodyAdvice(activity),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF12B347),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _getDirections(activity),
                                icon: const Icon(Icons.directions),
                                label: const Text('Get Directions'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF12B347),
                                  side: const BorderSide(color: Color(0xFF12B347)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleMainAction(activity),
                                icon: Icon(_getEditButtonIcon(activity['paymentStatus'])),
                                label: Text(_getEditButtonText(activity['paymentStatus'])),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getEditButtonColor(activity['paymentStatus']),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getMoodyAdvice(Map<String, dynamic> activity) {
    final title = activity['title']?.toString().toLowerCase() ?? '';
    final category = activity['category']?.toString().toLowerCase() ?? '';
    final duration = activity['duration'] ?? 60;
    final paymentStatus = activity['paymentStatus'] ?? 'free';
    final startTime = DateTime.parse(activity['date'] ?? DateTime.now().toIso8601String());
    
    List<String> advice = [];
    
    // Time-based advice
    if (startTime.hour < 12) {
      advice.add('🌅 Perfect morning timing - enjoy the fresh start');
    } else if (startTime.hour >= 18) {
      advice.add('🌆 Great evening activity - perfect for unwinding');
    }
    
    // Duration-based advice
    if (duration >= 120) {
      advice.add('⏰ Longer experience - bring water and snacks');
    } else if (duration <= 45) {
      advice.add('⚡ Quick and energizing - perfect mood boost');
    }
    
    // Category-based advice
    switch (category) {
      case 'outdoor':
        advice.addAll([
          '🌿 Check the weather before heading out',
          '👟 Comfortable walking shoes recommended',
          '📱 Download offline maps for the area'
        ]);
        break;
      case 'cultural':
        advice.addAll([
          '🎨 Take your time to appreciate the experience',
          '📖 Look for guided tours or information',
          '🔇 Be respectful of others enjoying the space'
        ]);
        break;
      case 'food':
        advice.addAll([
          '🍽️ Come with an appetite for new flavors',
          '💰 Bring cash - some vendors prefer it',
          '📸 Great photo opportunities for food memories'
        ]);
        break;
      case 'nature':
        advice.addAll([
          '🌳 Perfect for connecting with nature',
          '📸 Bring a camera for beautiful moments',
          '🧴 Sunscreen and water are essentials'
        ]);
        break;
      default:
        advice.addAll([
          '💚 Be present and enjoy every moment',
          '📍 Arrive a few minutes early to settle in',
          '🌟 Open mind leads to the best experiences'
        ]);
    }
    
    // Payment-based advice
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
    
    // Always include a motivational closing
    advice.add('✨ This activity was chosen to match your mood perfectly');
    
    // Limit to 4-5 pieces of advice to keep it readable
    return advice.take(5).map((tip) => '• $tip').join('\n');
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 