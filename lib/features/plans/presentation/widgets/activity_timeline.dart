import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';

class ActivityTimeline extends StatelessWidget {
  final List<Activity> activities;
  final Function(Activity) onActivityTap;

  const ActivityTimeline({
    super.key,
    required this.activities,
    required this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sort activities by start time
    final sortedActivities = List<Activity>.from(activities)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomPaint(
        painter: TimelinePainter(),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: sortedActivities.length,
          itemBuilder: (context, index) {
            final activity = sortedActivities[index];
            final isFirst = index == 0;
            final isLast = index == sortedActivities.length - 1;
            
            return TimelineItem(
              activity: activity,
              onTap: () => onActivityTap(activity),
              isFirst: isFirst,
              isLast: isLast,
            );
          },
        ),
      ),
    );
  }
}

class TimelinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A6049).withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TimelineItem extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const TimelineItem({
    super.key,
    required this.activity,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  String _formatTime(DateTime time) {
    final String period = time.hour >= 12 ? 'PM' : 'AM';
    final int hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: EdgeInsets.only(
          left: isFirst ? 0 : 8,
          right: isLast ? 0 : 8,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
                children: [
                  if (activity.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: WmNetworkImage(
                        activity.imageUrl!,
                        width: double.infinity,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    activity.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatTime(activity.startTime),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 2,
              height: 20,
              color: const Color(0xFF2A6049).withOpacity(0.2),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2A6049),
                  width: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 