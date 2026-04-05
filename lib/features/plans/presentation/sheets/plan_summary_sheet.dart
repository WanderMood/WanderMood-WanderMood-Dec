import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';

class PlanSummarySheet extends StatelessWidget {
  final List<Activity> selectedActivities;

  const PlanSummarySheet({
    super.key,
    required this.selectedActivities,
  });

  static Future<void> show(BuildContext context, List<Activity> activities) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlanSummarySheet(selectedActivities: activities),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group activities by time slot
    final morningActivities = selectedActivities.where((a) => a.timeSlot == 'morning').toList();
    final afternoonActivities = selectedActivities.where((a) => a.timeSlot == 'afternoon').toList();
    final eveningActivities = selectedActivities.where((a) => a.timeSlot == 'evening').toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                Text(
                  'Your Day Plan Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                if (morningActivities.isNotEmpty) ...[
                  _buildTimeSection('🌅 Morning', morningActivities),
                  if (afternoonActivities.isNotEmpty || eveningActivities.isNotEmpty)
                    const Divider(height: 32),
                ],
                
                if (afternoonActivities.isNotEmpty) ...[
                  _buildTimeSection('☀️ Afternoon', afternoonActivities),
                  if (eveningActivities.isNotEmpty)
                    const Divider(height: 32),
                ],
                
                if (eveningActivities.isNotEmpty)
                  _buildTimeSection('🌙 Evening', eveningActivities),
              ],
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A6049),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.3),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(String title, List<Activity> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...activities.map((activity) => _buildActivityCard(activity)).toList(),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final startTime = activity.startTime;
    final endTime = startTime.add(Duration(minutes: activity.duration));
    final timeString = '${_formatTime(startTime)} - ${_formatTime(endTime)}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5EE),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF2A6049).withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Activity image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: WmPlacePhotoNetworkImage(
              activity.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          
          // Activity details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          
          // Payment type tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: activity.paymentType == PaymentType.free 
                ? const Color(0xFFDCF3DC)
                : const Color(0xFFFFECCC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              activity.paymentType == PaymentType.free
                ? 'Free Activity'
                : 'Ticket Required',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: activity.paymentType == PaymentType.free
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final formattedHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$formattedHour:$minute $period';
  }
} 