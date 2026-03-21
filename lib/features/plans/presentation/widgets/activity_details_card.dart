import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';

class ActivityDetailsCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onBook;
  final VoidCallback onClose;
  final bool isVisible;

  const ActivityDetailsCard({
    super.key,
    required this.activity,
    required this.onBook,
    required this.onClose,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.asset(
                    activity.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activity.rating.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time and duration
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${TimeOfDay.fromDateTime(activity.startTime).format(context)} • ${activity.duration}min',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    activity.description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activity.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A6049).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF2A6049),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Booking status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: activity.isPaid
                          ? Colors.amber.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: activity.isPaid
                            ? Colors.amber.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          activity.isPaid
                              ? Icons.confirmation_number
                              : Icons.celebration,
                          color: activity.isPaid
                              ? Colors.amber.shade700
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.isPaid
                                    ? 'Secure Your Spot! 🎟️'
                                    : 'Free to Join! 🎉',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: activity.isPaid
                                      ? Colors.amber.shade900
                                      : Colors.green.shade900,
                                ),
                              ),
                              if (activity.isPaid && activity.price != null)
                                Text(
                                  '€${activity.price!.toStringAsFixed(2)} per person',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Book button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A6049),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        activity.isPaid ? 'Book Now - €${activity.price!.toStringAsFixed(2)}' : 'Add to My Day',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ).animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    ).scaleXY(
                      begin: 1.0,
                      end: 1.03,
                      duration: 1000.ms,
                      curve: Curves.easeInOut,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(
        target: isVisible ? 1 : 0,
      ).slideY(
        begin: 0.2,
        end: 0,
        duration: 500.ms,
        curve: Curves.easeOutQuad,
      ).scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1, 1),
        duration: 500.ms,
        curve: Curves.easeOutQuad,
      ),
    );
  }
} 