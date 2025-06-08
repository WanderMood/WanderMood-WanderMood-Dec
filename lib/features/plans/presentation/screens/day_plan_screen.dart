import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/features/plans/presentation/sheets/plan_summary_sheet.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/plans/widgets/activity_detail_screen.dart';
import 'package:wandermood/features/plans/providers/selected_activities_provider.dart';
import 'dart:math';

class DayPlanScreen extends ConsumerStatefulWidget {
  final List<Activity> activities;

  const DayPlanScreen({
    super.key,
    required this.activities,
  });

  @override
  ConsumerState<DayPlanScreen> createState() => _DayPlanScreenState();
}

class _DayPlanScreenState extends ConsumerState<DayPlanScreen> {
  String _selectedTimeSlot = 'Morning';

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning explorer 👋';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon explorer 👋';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening explorer 👋';
    } else {
      return 'Hi night owl explorer 🌙';
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, MMMM d, y');
    return formatter.format(now);
  }

  void _toggleActivity(Activity activity) {
    ref.read(selectedActivitiesProvider.notifier).toggleActivity(activity.id);
  }

  void _refreshActivity(Activity activity) {
    setState(() {
      // Increment refresh count on the activity
      final refreshedActivity = activity.copyWith(
        refreshCount: activity.refreshCount + 1,
      );
      
      // Replace the activity in the main list
      final index = widget.activities.indexOf(activity);
      if (index >= 0) {
        widget.activities[index] = refreshedActivity;
      }
    });
    
    // Show a snackbar to indicate refreshing action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Finding new options for ${activity.name}...',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Map<String, List<Activity>> _groupActivitiesByTimeSlot() {
    final result = <String, List<Activity>>{};
    
    for (final activity in widget.activities) {
      final timeSlot = activity.timeSlot;
      if (!result.containsKey(timeSlot)) {
        result[timeSlot] = [];
      }
      result[timeSlot]!.add(activity);
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final groupedActivities = _groupActivitiesByTimeSlot();
    final morningActivities = groupedActivities['morning'] ?? [];
    final afternoonActivities = groupedActivities['afternoon'] ?? [];
    final eveningActivities = groupedActivities['evening'] ?? [];

    return Scaffold(
      body: Stack(
        children: [
          // Base swirl background with beige color
          const SwirlBackground(
            child: SizedBox.expand(),
          ),
          
          // Green header background with curved bottom
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).padding.top + 140, // SafeArea top + header height
            child: Container(
                      decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                          ),
                        ),
                      ),
                    ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                      children: [
                        Row(
                          children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                        ],
                        ),
                      const SizedBox(height: 0),
                    Text(
                      'Your Day Plan',
                        style: GoogleFonts.museoModerno(
                        fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                    Text(
                      _getFormattedDate(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.95),
                          letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

                // Content area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ListView(
                      children: [
                        // Moody's greeting
              Container(
                          margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                              const MoodyCharacter(
                                size: 60,
                                mood: 'happy',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTimeBasedGreeting(),
                                      style: GoogleFonts.museoModerno(
                                        fontSize: 18,
                              fontWeight: FontWeight.w600,
                                        color: const Color(0xFF4CAF50),
                            ),
                          ),
                          Text(
                                      "I've cooked up a day full of surprises! 🎭",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                        ),

                        // Time section tabs
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                              _buildTimeTab('🌅 Morning', '(${morningActivities.length})', _selectedTimeSlot == 'Morning'),
                              _buildTimeTab('😊 Afternoon', '(${afternoonActivities.length})', _selectedTimeSlot == 'Afternoon'),
                              _buildTimeTab('🌙 Evening', '(${eveningActivities.length})', _selectedTimeSlot == 'Evening'),
                  ],
                ),
              ),

                        // Activities
                        ...widget.activities.map((activity) {
                          // Filter by selected time slot
                          if (activity.timeSlot.toLowerCase() != _selectedTimeSlot.toLowerCase()) {
                            return const SizedBox.shrink();
                          }
                          
                          return _buildActivityCard(activity);
                        }).toList(),
                        
                        // Add extra space at the bottom for the floating button
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Review button at bottom
          Consumer(
            builder: (context, ref, child) {
              final selectedActivityIds = ref.watch(selectedActivitiesProvider);
              if (selectedActivityIds.isEmpty) return const SizedBox();
              
              // Get the actual activities from the selected IDs
              final selectedActivities = widget.activities
                  .where((activity) => selectedActivityIds.contains(activity.id))
                  .toList();
              
              return Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        PlanSummarySheet.show(
                          context,
                          selectedActivities,
                        );
                    },
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                      ),
                      label: Text(
                        'Review selected (${selectedActivityIds.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTab(String emoji, String count, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeSlot = emoji.split(' ')[1];
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              count,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final isSelected = ref.watch(selectedActivitiesProvider).contains(activity.id);
    final startTime = activity.startTime;
    final endTime = startTime.add(Duration(minutes: activity.duration));
    final timeString = '${_formatTime(startTime)} - ${_formatTime(endTime)} (${activity.duration}min)';

    return GestureDetector(
      onTap: () => _openActivityDetail(activity),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Combined time header and card with proper rounded corners and floating effect
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
              // Softer shadow underneath for depth
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 2,
              ),
              // Sharper shadow on top for definition
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
                spreadRadius: 0,
              ),
              // Light shadow on the sides
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 3,
                offset: const Offset(2, 0),
                spreadRadius: 0,
              ),
          BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 3,
                offset: const Offset(-2, 0),
                spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Time header with rounded corners matching the card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                      Icons.access_time_rounded,
                              size: 16,
                      color: Color(0xFF4CAF50),
                            ),
                    const SizedBox(width: 8),
                            Text(
                      timeString,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _refreshActivity(activity),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: Color(0xFF4CAF50),
                              ),
                      label: const Text(
                        'Not feeling this?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              ),

              // Activity image with no top rounding
              ClipRRect(
                child: Image.network(
                  activity.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                        ),
                      ),
                    );
                  },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    // Activity title and rating
                Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                              color: Colors.black87,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                            const Icon(
                              Icons.star,
                              size: 18,
                              color: Colors.amber,
                            ),
                        const SizedBox(width: 4),
                        Text(
                              activity.rating.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                                fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                    
                const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      activity.description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),

                    // Start time indicator (smaller)
                    const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                          _formatTime(activity.startTime),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                            fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                    
                    const SizedBox(height: 12),
                    
                    // Tags with different colors
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildColorfulTags(activity.tags),
                    ),
                    
                const SizedBox(height: 16),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Directions functionality
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4CAF50)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Directions',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _toggleActivity(activity),
                            icon: Icon(
                              isSelected ? Icons.remove : Icons.add,
                              size: 18,
                            ),
                            label: Text(
                              isSelected ? 'Remove from Plan' : 'Add to Plan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                                fontWeight: FontWeight.w500,
                  ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? Colors.grey : const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
        ).animate()
         .fade(duration: 400.ms, delay: 100.ms, curve: Curves.easeOut)
         .moveY(begin: 10, duration: 400.ms, delay: 100.ms, curve: Curves.easeOutQuad),
      ],
    ),
    );
  }

  void _openActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activity: activity),
      ),
    );
  }

  // Dedicated colorful tag builder
  List<Widget> _buildColorfulTags(List<String> tags) {
    // Rich collection of tag styles with semantic meaning
    final Map<String, ({Color color, Color textColor, String icon})> tagStyles = {
      // Wellness & Health related
      'Wellness': (
        color: const Color(0xFFE1F5FE), 
        textColor: const Color(0xFF0288D1), 
        icon: '🧘‍♀️'
      ),
      'Yoga': (
        color: const Color(0xFFE8EAF6),
        textColor: const Color(0xFF3F51B5),
        icon: '🧘'
      ),
      'Spa': (
        color: const Color(0xFFE0F7FA),
        textColor: const Color(0xFF00ACC1),
        icon: '💆'
      ),
      'Meditation': (
        color: const Color(0xFFE0F2F1),
        textColor: const Color(0xFF009688),
        icon: '🧠'
      ),
      'Fitness': (
        color: const Color(0xFFEDE7F6),
        textColor: const Color(0xFF673AB7),
        icon: '🏋️'
      ),
      'Health': (
        color: const Color(0xFFE8F5E9),
        textColor: const Color(0xFF43A047),
        icon: '❤️‍🩹'
      ),

      // Outdoor related 
      'Outdoor': (
        color: const Color(0xFFE8F5E9), 
        textColor: const Color(0xFF388E3C), 
        icon: '🌿'
      ),
      'Nature': (
        color: const Color(0xFFDCEDC8),
        textColor: const Color(0xFF33691E),
        icon: '🌳'
      ),
      'Park': (
        color: const Color(0xFFF1F8E9),
        textColor: const Color(0xFF558B2F),
        icon: '🏞️'
      ),
      'Hiking': (
        color: const Color(0xFFF9FBE7),
        textColor: const Color(0xFF827717),
        icon: '🥾'
      ),
      'Beach': (
        color: const Color(0xFFE0F7FA),
        textColor: const Color(0xFF00838F),
        icon: '🏖️'
      ),

      // Active & Sports
      'Active': (
        color: const Color(0xFFFCE4EC), 
        textColor: const Color(0xFFD81B60), 
        icon: '💪'
      ),
      'Sports': (
        color: const Color(0xFFE8EAF6),
        textColor: const Color(0xFF1A237E),
        icon: '⚽'
      ),
      'Adventure': (
        color: const Color(0xFFEDE7F6),
        textColor: const Color(0xFF512DA8),
        icon: '🧗‍♂️'
      ),
      'Running': (
        color: const Color(0xFFFFEBEE),
        textColor: const Color(0xFFC62828),
        icon: '🏃'
      ),
      'Swimming': (
        color: const Color(0xFFE3F2FD),
        textColor: const Color(0xFF1565C0),
        icon: '🏊'
      ),

      // Food & Drinks
      'Food': (
        color: const Color(0xFFFFF3E0), 
        textColor: const Color(0xFFE65100), 
        icon: '🍽️'
      ),
      'Restaurant': (
        color: const Color(0xFFFFECB3),
        textColor: const Color(0xFFFF8F00),
        icon: '🍴'
      ),
      'Cooking': (
        color: const Color(0xFFFFCCBC),
        textColor: const Color(0xFFD84315),
        icon: '👨‍🍳'
      ),
      'Cafe': (
        color: const Color(0xFFEFEBE9),
        textColor: const Color(0xFF5D4037),
        icon: '☕'
      ),
      'Drinks': (
        color: const Color(0xFFE0F2F1),
        textColor: const Color(0xFF00796B),
        icon: '🍹'
      ),
      'Dinner': (
        color: const Color(0xFFFFEBEE),
        textColor: const Color(0xFFB71C1C),
        icon: '🍷'
      ),
      'Breakfast': (
        color: const Color(0xFFFFF8E1),
        textColor: const Color(0xFFF57F17),
        icon: '🍳'
      ),
      'Lunch': (
        color: const Color(0xFFF9FBE7),
        textColor: const Color(0xFF827717),
        icon: '🥪'
      ),

      // Relationship & Social
      'Romantic': (
        color: const Color(0xFFFFEBEE), 
        textColor: const Color(0xFFE53935), 
        icon: '❤️'
      ),
      'Dating': (
        color: const Color(0xFFFCE4EC),
        textColor: const Color(0xFFC2185B),
        icon: '💕'
      ),
      'Couple': (
        color: const Color(0xFFF8BBD0),
        textColor: const Color(0xFFAD1457),
        icon: '👫'
      ),
      'Social': (
        color: const Color(0xFFE3F2FD),
        textColor: const Color(0xFF1976D2),
        icon: '👥'
      ),
      'Friends': (
        color: const Color(0xFFE8EAF6),
        textColor: const Color(0xFF303F9F),
        icon: '🤝'
      ),

      // Relaxation & Comfort
      'Cozy': (
        color: const Color(0xFFEFEBE9), 
        textColor: const Color(0xFF795548), 
        icon: '☕'
      ),
      'Relaxing': (
        color: const Color(0xFFE0F7FA),
        textColor: const Color(0xFF00ACC1),
        icon: '🧖‍♀️'
      ),
      'Peaceful': (
        color: const Color(0xFFE0F2F1),
        textColor: const Color(0xFF004D40),
        icon: '🍃'
      ),
      'Calm': (
        color: const Color(0xFFE1F5FE),
        textColor: const Color(0xFF0277BD),
        icon: '🕊️'
      ),

      // Educational & Cultural
      'Learning': (
        color: const Color(0xFFE8EAF6), 
        textColor: const Color(0xFF3949AB), 
        icon: '📚'
      ),
      'Educational': (
        color: const Color(0xFFB3E5FC),
        textColor: const Color(0xFF0277BD),
        icon: '🔍'
      ),
      'Class': (
        color: const Color(0xFFD1C4E9),
        textColor: const Color(0xFF512DA8),
        icon: '📝'
      ),
      'Workshop': (
        color: const Color(0xFFE1BEE7),
        textColor: const Color(0xFF7B1FA2),
        icon: '🛠️'
      ),
      'Cultural': (
        color: const Color(0xFFF3E5F5),
        textColor: const Color(0xFF7B1FA2),
        icon: '🎭'
      ),
      'Museum': (
        color: const Color(0xFFD7CCC8),
        textColor: const Color(0xFF4E342E),
        icon: '🏛️'
      ),
      'Art': (
        color: const Color(0xFFE1F5FE),
        textColor: const Color(0xFF01579B),
        icon: '🎨'
      ),
      'History': (
        color: const Color(0xFFD7CCC8),
        textColor: const Color(0xFF5D4037),
        icon: '📜'
      ),

      // Indoor activities
      'Indoor': (
        color: const Color(0xFFE0F2F1), 
        textColor: const Color(0xFF00796B), 
        icon: '🏠'
      ),
      'Cinema': (
        color: const Color(0xFF263238),
        textColor: const Color(0xFFECEFF1),
        icon: '🎬'
      ),
      'Movie': (
        color: const Color(0xFF37474F),
        textColor: const Color(0xFFCFD8DC),
        icon: '🍿'
      ),
      'Theater': (
        color: const Color(0xFFBF360C),
        textColor: const Color(0xFFFFCCBC),
        icon: '🎭'
      ),
      'Music': (
        color: const Color(0xFFE1BEE7),
        textColor: const Color(0xFF6A1B9A),
        icon: '🎵'
      ),
      'Concert': (
        color: const Color(0xFF4A148C),
        textColor: const Color(0xFFEA80FC),
        icon: '🎸'
      ),
      'Shopping': (
        color: const Color(0xFFF9FBE7),
        textColor: const Color(0xFF827717),
        icon: '🛍️'
      ),

      // Time of day
      'Morning': (
        color: const Color(0xFFFFF8E1),
        textColor: const Color(0xFFF57F17),
        icon: '🌅'
      ),
      'Afternoon': (
        color: const Color(0xFFFFE0B2),
        textColor: const Color(0xFFE65100),
        icon: '☀️'
      ),
      'Evening': (
        color: const Color(0xFF3F51B5),
        textColor: const Color(0xFFE8EAF6),
        icon: '🌙'
      ),
      'Night': (
        color: const Color(0xFF1A237E),
        textColor: const Color(0xFFC5CAE9),
        icon: '✨'
      ),
    };

    // Dynamic color generation for tags not in our map
    Color generateColorFromString(String input) {
      // Generate a repeatable hash from the string
      int hash = 0;
      for (int i = 0; i < input.length; i++) {
        hash = input.codeUnitAt(i) + ((hash << 5) - hash);
      }
      
      // Convert to vibrant HSL color
      final hue = (hash % 360).abs(); // 0-359 degrees on color wheel
      
      // Use vibrant saturation and appropriate lightness
      return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.8, 0.85).toColor();
    }

    // Generate visually pleasing text color (dark for light backgrounds, light for dark backgrounds)
    Color getTextColor(Color backgroundColor) {
      // Calculate perceived brightness using standard formula
      final brightness = (backgroundColor.red * 299 + 
                         backgroundColor.green * 587 + 
                         backgroundColor.blue * 114) / 1000;
      
      // Use white text on dark backgrounds, dark text on light backgrounds
      return brightness > 165 
          ? const Color(0xFF212121) // Dark text for light background
          : const Color(0xFFFAFAFA); // Light text for dark background
    }

    return tags.map((tag) {
      // Try case-insensitive lookup in our tag map
      var style = tagStyles.entries
        .where((e) => e.key.toLowerCase() == tag.toLowerCase())
        .map((e) => e.value)
        .firstOrNull;
      
      // If not found, generate a color based on the tag's name
      if (style == null) {
        final color = generateColorFromString(tag);
        final textColor = getTextColor(color);
        
        // Pick an icon based on the tag if possible, or use default
        String icon = '✨';
        if (tag.toLowerCase().contains('food') || tag.toLowerCase().contains('eat')) {
          icon = '🍽️';
        } else if (tag.toLowerCase().contains('art') || tag.toLowerCase().contains('creative')) {
          icon = '🎨';
        } else if (tag.toLowerCase().contains('water') || tag.toLowerCase().contains('sea')) {
          icon = '🌊';
        } else if (tag.toLowerCase().contains('music') || tag.toLowerCase().contains('concert')) {
          icon = '🎵';
        } else if (tag.toLowerCase().contains('nature') || tag.toLowerCase().contains('tree')) {
          icon = '🌳';
        }
        
        style = (color: color, textColor: textColor, icon: icon);
      }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: style.color,
          borderRadius: BorderRadius.circular(16),
      ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${style.icon} ',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              tag,
        style: GoogleFonts.poppins(
          fontSize: 12,
                color: style.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Mock data for alternative activities (in a real app, this would come from a backend)
  final List<Map<String, dynamic>> _alternativeActivities = [
    {
      'name': 'Romantic Breakfast at Café Fleur',
      'description': 'Enjoy a delightful breakfast with fresh pastries and artisanal coffee.',
      'imageUrl': 'https://images.unsplash.com/photo-1579801238797-b9f470d7e120?q=80&w=2069&auto=format&fit=crop',
      'rating': 4.6,
      'tags': ['Food', 'Romantic', 'Cozy'],
      'duration': 60,
    },
    {
      'name': 'Beach Meditation Session',
      'description': 'Connect with nature and find your inner peace with a guided meditation by the ocean.',
      'imageUrl': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2073&auto=format&fit=crop',
      'rating': 4.9,
      'tags': ['Wellness', 'Outdoor', 'Relaxing'],
      'duration': 45,
    },
    {
      'name': 'Botanical Garden Tour',
      'description': 'Explore the city\'s hidden gem with exotic plants and beautiful landscaping.',
      'imageUrl': 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?q=80&w=2069&auto=format&fit=crop',
      'rating': 4.7,
      'tags': ['Outdoor', 'Educational', 'Peaceful'],
      'duration': 90,
    },
  ];
} 