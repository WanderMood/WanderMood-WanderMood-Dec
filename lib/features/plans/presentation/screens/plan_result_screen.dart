import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/domain/enums/moody_feature.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/features/plans/presentation/screens/confirm_plan_screen.dart';

class PlanResultScreen extends ConsumerStatefulWidget {
  final List<String> selectedMoods;
  final String moodString;

  const PlanResultScreen({
    super.key,
    required this.selectedMoods,
    required this.moodString,
  });

  @override
  ConsumerState<PlanResultScreen> createState() => _PlanResultScreenState();
}

class _PlanResultScreenState extends ConsumerState<PlanResultScreen> {
  final List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }
  
  Future<void> _fetchActivities() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _activities.addAll([
        {
          'name': 'Morning Yoga in the Park',
          'description': 'Start your day with a refreshing yoga session in the beautiful city park. Perfect for all skill levels.',
          'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b',
          'rating': 4.8,
          'startTime': '8:30 AM',
          'endTime': '9:30 AM',
          'duration': '60min',
          'section': 'Morning',
          'tags': ['✨ Wellness 🧘‍♀️', '✨ Outdoor 🌿', '✨ Active 💪'],
        },
        {
          'name': 'Rooftop Brunch Spot',
          'description': 'Enjoy a delicious brunch with panoramic city views.',
          'image': 'https://images.unsplash.com/photo-1593696954577-ab3d39317b97',
          'rating': 4.7,
          'startTime': '10:30 AM',
          'endTime': '12:00 PM',
          'duration': '90min',
          'section': 'Morning',
          'tags': ['✨ Food 🍳', '✨ Views 🌆', '✨ Social 👥'],
        },
        // Add more activities for afternoon and evening
      ]);
      _isLoading = false;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening';
    } else {
      return 'Hi night owl';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "confirm_plan_fab",
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ConfirmPlanScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF12B347),
        label: Text(
          'Confirm Plan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: const Icon(Icons.check_circle_outline),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
                  children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Your Day Plan',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                            child: Text(
                      dateFormat.format(today),
                              style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ),
                  ],
                ),
          ),
          
            // Moody's greeting
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDE7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const MoodyCharacter(
                    size: 40,
                          mood: 'happy',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                          '${_getGreeting()} explorer 🌙',
                              style: GoogleFonts.poppins(
                            fontSize: 16,
                                fontWeight: FontWeight.w600,
                            color: Colors.black87,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTimeTab('📅 Morning (3)', const Color(0xFFFFE0B2)),
                  _buildTimeTab('😊 Afternoon (3)', const Color(0xFFFFCCBC)),
                  _buildTimeTab('🌙 Evening (3)', const Color(0xFFE1BEE7)),
                ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
            // Activities list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final activity = _activities[index];
                  return _buildActivityCard(activity);
                },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeTab(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
            style: GoogleFonts.poppins(
          fontSize: 14,
              fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
  
  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time and duration
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      '${activity['startTime']} - ${activity['endTime']}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      ' (${activity['duration']})',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black38,
                      ),
                ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, size: 16, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 4),
                Text(
                        'Not feeling this?',
                  style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Activity image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
              child: Image.network(
              activity['image'],
              height: 200,
              width: double.infinity,
                fit: BoxFit.cover,
            ),
          ),
          
          // Activity details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity['name'],
                        style: GoogleFonts.poppins(
                        fontSize: 18,
                          fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Color(0xFFFFB300)),
                        const SizedBox(width: 4),
                        Text(
                          activity['rating'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activity['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (activity['tags'] as List<String>).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF50),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                          child: Text(
                            'Directions',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Add to Plan',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ],
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
    );
  }
} 