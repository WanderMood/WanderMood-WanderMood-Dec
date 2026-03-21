import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/activity.dart';
import '../../../../features/places/widgets/place_image.dart';

class FreeActivitiesScreen extends StatelessWidget {
  final List<Activity> activities;

  const FreeActivitiesScreen({
    Key? key,
    required this.activities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final freeActivities = activities.where((activity) => !activity.isPaid).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Free Activities',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: freeActivities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No free activities available',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new activities',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: freeActivities.length,
              itemBuilder: (context, index) {
                final activity = freeActivities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () => context.pushNamed(
                      'activity-details',
                      extra: activity,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: PlaceImage(
                              photoReference: activity.imageUrl,
                              placeType: activity.tags.isNotEmpty ? activity.tags.first : 'default',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        activity.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A6049).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'FREE',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2A6049),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  activity.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${TimeOfDay.fromDateTime(activity.startTime).format(context)} • ${activity.duration} min',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
} 