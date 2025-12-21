import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/mood/application/mood_service.dart';
import 'package:wandermood/features/mood/domain/models/mood_data.dart';

class MoodHistoryWidget extends ConsumerWidget {
  const MoodHistoryWidget({
    super.key,
    this.daysToShow = 7,
  });

  final int daysToShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(authStateProvider);
    
    return userAsyncValue.when(
      data: (user) {
        if (user == null) {
          return Center(
            child: Text(
              'You must be logged in to view your mood history',
              style: GoogleFonts.poppins(),
            ),
          );
        }
        
        final moodsAsyncValue = ref.watch(userMoodsProvider(user.id));
        return _buildMoodHistory(context, moodsAsyncValue);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error loading user: $error',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
      ),
    );
  }
  
  Widget _buildMoodHistory(BuildContext context, AsyncValue<List<MoodData>> moodsAsyncValue) {
    return moodsAsyncValue.when(
      data: (moods) {
        // Sort moods by timestamp (newest first)
        final sortedMoods = List<MoodData>.from(moods)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Moods',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here you\'ll find an overview of your registered moods',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Carousel section - always visible
            SizedBox(
              height: 200,
              child: _buildMoodCarousel(context, sortedMoods),
            ),
            
            const SizedBox(height: 24),
            
            // Timeline section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Full History',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Timeline - shows full history
            Expanded(
              child: sortedMoods.isEmpty
                  ? _buildEmptyTimeline(context)
                  : _buildTimeline(context, sortedMoods),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error loading moods: $error',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
      ),
    );
  }
  
  Widget _buildMoodCarousel(BuildContext context, List<MoodData> moods) {
    // Get recent moods (last 7) or use placeholders
    final recentMoods = moods.take(7).toList();
    final hasMoods = recentMoods.isNotEmpty;
    
    // Create placeholder cards if no moods
    final itemsToShow = hasMoods 
        ? recentMoods 
        : _buildPlaceholderMoods();
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemsToShow.length,
      itemBuilder: (context, index) {
        if (hasMoods) {
          return _buildMoodCarouselCard(context, itemsToShow[index] as MoodData);
        } else {
          return itemsToShow[index] as Widget;
        }
      },
    );
  }
  
  List<dynamic> _buildPlaceholderMoods() {
    return [
      _buildPlaceholderCard(
        emoji: '😊',
        title: 'Start tracking',
        subtitle: 'Your first mood check-in',
        color: const Color(0xFF4CAF50).withOpacity(0.1),
      ),
      _buildPlaceholderCard(
        emoji: '📊',
        title: 'See patterns',
        subtitle: 'Track your daily mood',
        color: Colors.blue.withOpacity(0.1),
      ),
      _buildPlaceholderCard(
        emoji: '🎯',
        title: 'Build history',
        subtitle: 'Create your mood journey',
        color: Colors.orange.withOpacity(0.1),
      ),
    ];
  }
  
  Widget _buildPlaceholderCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMoodCarouselCard(BuildContext context, MoodData mood) {
    final isToday = DateFormat('yyyy-MM-dd').format(mood.timestamp) == 
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday 
              ? const Color(0xFF4CAF50) 
              : Colors.grey[300]!,
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getMoodEmoji(mood.moodType),
                  style: const TextStyle(fontSize: 32),
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Today',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mood.moodType,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateShort(mood.timestamp),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (mood.description != null && mood.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                mood.description!,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeline(BuildContext context, List<MoodData> moods) {
    // Group moods by day
    final Map<String, List<MoodData>> moodsByDay = {};
    for (final mood in moods) {
      final dayKey = DateFormat('yyyy-MM-dd').format(mood.timestamp);
      moodsByDay.putIfAbsent(dayKey, () => []).add(mood);
    }
    
    // Sort days in descending order (newest first)
    final sortedDays = moodsByDay.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: sortedDays.length,
      itemBuilder: (context, dayIndex) {
        final dayKey = sortedDays[dayIndex];
        final dayMoods = moodsByDay[dayKey]!;
        final dayDate = DateTime.parse(dayKey);
        
        // Sort moods within day by time (newest first)
        dayMoods.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        return _buildDaySection(context, dayDate, dayMoods, dayIndex == sortedDays.length - 1);
      },
    );
  }
  
  Widget _buildEmptyTimeline(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Your mood timeline will appear here',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDateShort(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MMM d, HH:mm').format(date);
    }
  }
  
  Widget _buildDaySection(BuildContext context, DateTime day, List<MoodData> moods, bool isLast) {
    final isToday = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isYesterday = DateFormat('yyyy-MM-dd').format(day) == 
        DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    
    String dayLabel;
    if (isToday) {
      dayLabel = 'Today';
    } else if (isYesterday) {
      dayLabel = 'Yesterday';
    } else {
      dayLabel = DateFormat('EEEE, MMMM d').format(day);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            dayLabel,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ),
        
        // Timeline with moods
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            children: [
              // Vertical line
              if (!isLast || moods.length > 1)
                Container(
                  width: 2,
                  height: (moods.length - 1) * 80.0,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(left: 20),
                ),
              
              // Mood entries
              ...moods.asMap().entries.map((entry) {
                final index = entry.key;
                final mood = entry.value;
                final isLastMood = index == moods.length - 1;
                
                return _buildMoodTimelineItem(context, mood, isLastMood && isLast);
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMoodTimelineItem(BuildContext context, MoodData mood, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF4CAF50),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getMoodEmoji(mood.moodType),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Mood card
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mood.moodType,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(mood.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (mood.description != null && mood.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      mood.description!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  if (mood.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: mood.tags
                          .map((tag) => Chip(
                                label: Text(
                                  tag,
                                  style: GoogleFonts.poppins(fontSize: 11),
                                ),
                                backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  String _getMoodEmoji(String moodType) {
    final lowerMood = moodType.toLowerCase();
    
    // Handle English moods
    if (lowerMood.contains('happy') || lowerMood.contains('joy') || lowerMood == 'blij') {
      return '😊';
    } else if (lowerMood.contains('energetic') || lowerMood == 'energiek') {
      return '⚡';
    } else if (lowerMood.contains('relaxed') || lowerMood.contains('calm') || lowerMood == 'rustig') {
      return '😌';
    } else if (lowerMood.contains('sad') || lowerMood.contains('sorrow') || lowerMood == 'verdrietig') {
      return '😢';
    } else if (lowerMood.contains('angry') || lowerMood.contains('mad') || lowerMood == 'boos') {
      return '😠';
    } else if (lowerMood.contains('adventurous')) {
      return '🏔️';
    } else if (lowerMood.contains('romantic')) {
      return '💕';
    } else if (lowerMood.contains('cultural')) {
      return '🎭';
    } else if (lowerMood.contains('social')) {
      return '👥';
    } else if (lowerMood.contains('contemplative')) {
      return '🧘';
    } else if (lowerMood.contains('creative')) {
      return '🎨';
    }
    
    return '😐';
  }
} 