import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/gamification/providers/gamification_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StreakCard extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback? onTap;
  
  const StreakCard({
    Key? key,
    this.isExpanded = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationState = ref.watch(gamificationProvider);
    final streak = gamificationState.streak;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2A6049).withOpacity(0.9),
              const Color(0xFF0F9D3E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A6049).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 24,
                      ).animate(
                        onPlay: (controller) => controller.repeat(),
                      ).shimmer(
                        duration: 2.seconds,
                        color: Colors.orange.shade300,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Current Streak',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${streak.currentStreak} days',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ).animate().fadeIn(duration: 600.ms),
                ],
              ),
              
              if (isExpanded) ...[
                const SizedBox(height: 16),
                
                // Streak progress to next milestone
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Next milestone',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${streak.daysToNextMilestone} days left',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 1 - (streak.daysToNextMilestone / streak.daysToNextMilestone.ceil()),
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal best',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${streak.bestStreak} days',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        if (streak.hasActivityToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Today',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms).slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 400.ms,
                ),
              ],
              
              // Down arrow indicator when collapsed
              if (!isExpanded)
                Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 
 
 
 