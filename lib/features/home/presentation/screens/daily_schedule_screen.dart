import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/widgets/activity_detail_screen.dart';

class DailyScheduleScreen extends ConsumerStatefulWidget {
  const DailyScheduleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyScheduleScreen> createState() => _DailyScheduleScreenState();
}

class _DailyScheduleScreenState extends ConsumerState<DailyScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Activity>? _scheduledActivities;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledActivities();
  }

  Future<void> _loadScheduledActivities() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
      final activities = await scheduledActivityService.getScheduledActivities();
      
      setState(() {
        _scheduledActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading scheduled activities: $e');
      setState(() {
        _scheduledActivities = [];
        _isLoading = false;
      });
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A6049),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      // Reload activities for the selected date
      _loadScheduledActivities();
    }
  }

  String _getFormattedDate() {
    if (_isToday(_selectedDate)) {
      return 'Today, ${DateFormat('d MMMM').format(_selectedDate)}';
    } else if (_isTomorrow(_selectedDate)) {
      return 'Tomorrow, ${DateFormat('d MMMM').format(_selectedDate)}';
    } else {
      return DateFormat('EEEE, d MMMM').format(_selectedDate);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Light beige background
      body: Stack(
        children: [
          // Brown-beige gradient covering ENTIRE top area
          Container(
            height: 200, // Fixed height to cover top area
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B7355), Color(0xFFA0956B)], // Elegant brown-to-beige
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
          
          // 🎨 Add beautiful beige swirl background for content area only
          Positioned(
            top: 250, // Position much lower to avoid header interference
            left: 0,
            right: 0,
            bottom: 0,
            child: const SwirlBackground(
              child: SizedBox.expand(),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header content (over the gradient)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
                      Expanded(
                        child: Text(
          'Daily Schedule',
          style: GoogleFonts.museoModerno(
            fontSize: 24,
            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
          ),
        ),
          IconButton(
                        icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
                ),
                
                const SizedBox(height: 16),
          // Date selector
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _selectDate(context),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF2A6049),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getFormattedDate(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
                    ),
                  )
                : _scheduledActivities == null || _scheduledActivities!.isEmpty
                    ? _buildEmptyState()
                    : _buildScheduleList(),
          ),
                ],
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No activities scheduled',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to explore activities',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to explore page
                Navigator.pop(context);
                // To be implemented: navigate to explore tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A6049),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.explore),
              label: Text(
                'Explore Activities',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    final now = DateTime.now();
    
    // Separate upcoming and past activities
    final upcomingActivities = <Activity>[];
    final pastActivities = <Activity>[];
    
    for (final activity in _scheduledActivities!) {
      final activityEnd = activity.startTime.add(Duration(minutes: activity.duration));
      if (activityEnd.isBefore(now)) {
        pastActivities.add(activity);
      } else {
        upcomingActivities.add(activity);
      }
    }
    
    // Sort activities
    upcomingActivities.sort((a, b) => a.startTime.compareTo(b.startTime));
    pastActivities.sort((a, b) => b.startTime.compareTo(a.startTime)); // Most recent first

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Upcoming Activities Section
        if (upcomingActivities.isNotEmpty) ...[
          _buildSectionHeader('📅 Upcoming Activities', subtitle: '${upcomingActivities.length} activities planned'),
          const SizedBox(height: 8),
          ...upcomingActivities.map((activity) => _buildActivityCard(activity, isPast: false)).toList(),
          const SizedBox(height: 24),
        ],
        
        // Past Activities Section
        if (pastActivities.isNotEmpty) ...[
          _buildSectionHeader('✅ Completed Activities', subtitle: '${pastActivities.length} activities completed'),
          const SizedBox(height: 8),
          ...pastActivities.take(10).map((activity) => _buildActivityCard(activity, isPast: true)).toList(), // Limit to 10 past activities
          const SizedBox(height: 24),
        ],
        
        // Empty state for specific sections
        if (upcomingActivities.isEmpty && pastActivities.isEmpty)
          _buildEmptyScheduleState(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.museoModerno(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2A6049),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyScheduleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No activities scheduled for this date',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection(String title, List<Activity> activities) {
    String emoji;
    switch (title) {
      case 'Morning':
        emoji = '🌅';
        break;
      case 'Afternoon':
        emoji = '☀️';
        break;
      case 'Evening':
        emoji = '🌙';
        break;
      default:
        emoji = '⏰';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              Text(
                '$emoji ',
                style: const TextStyle(fontSize: 22),
              ),
              Text(
                title,
                style: GoogleFonts.museoModerno(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2A6049),
                ),
              ),
            ],
          ),
        ),
        ...activities.map((activity) => _buildActivityCard(activity)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity, {bool isPast = false}) {
    final formattedTime = DateFormat('h:mm a').format(activity.startTime);
    final formattedDate = DateFormat('MMM d').format(activity.startTime);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isPast ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isPast ? 0.03 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openActivityDetail(activity),
        borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          // Activity image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Image.network(
              activity.imageUrl,
              width: 100,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100,
                height: 120,
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.image,
                  color: Colors.grey.shade400,
                  size: 40,
                ),
              ),
            ),
          ),
          
          // Activity details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPast 
                            ? Colors.grey.withOpacity(0.2)
                            : const Color(0xFF2A6049).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isPast ? 'Completed' : 'Confirmed',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isPast ? Colors.grey[600] : const Color(0xFF2A6049),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isPast ? '$formattedDate • $formattedTime' : formattedTime,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isPast ? Colors.grey[500] : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.black45, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.black45, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.duration} minutes',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
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
    );
  }

  // Method to open activity detail screen
  void _openActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activity: activity),
      ),
    );
  }
} 