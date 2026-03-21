import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class PlanConfirmationScreen extends StatelessWidget {
  final List<Activity> activities;

  const PlanConfirmationScreen({
    super.key,
    required this.activities,
  });

  // Get lists of activities by type
  List<Activity> get freeActivities => activities.where((activity) => !activity.isPaid).toList();
  List<Activity> get paidActivities => activities.where((activity) => activity.isPaid).toList();

  // Handle Book Now - Proceed to payment and booking for all paid activities
  void _handleBookNow(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2A6049),
          ),
        ),
      );

      // Process paid activities booking
      for (final activity in paidActivities) {
        // TODO: Implement actual booking API calls here
        await Future.delayed(const Duration(seconds: 1)); // Simulated API call
      }

      // Close loading indicator
      Navigator.pop(context);

      showWanderMoodToast(
        context,
        message:
            'Booking successful! Check your email for confirmation.',
        backgroundColor: const Color(0xFF2A6049),
      );

      // Navigate to booking confirmation screen
      context.goNamed('home', extra: {'showNavigationBar': true, 'selectedIndex': 0});
    } catch (error) {
      // Close loading indicator
      Navigator.pop(context);

      showWanderMoodToast(
        context,
        message: 'Unable to complete booking. Please try again.',
        isError: true,
      );
    }
  }

  // Handle Book Later - Save plan to favorites/saved plans
  void _handleBookLater(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2A6049),
          ),
        ),
      );

      // TODO: Implement save to favorites/saved plans logic
      await Future.delayed(const Duration(seconds: 1)); // Simulated API call

      // Close loading indicator
      Navigator.pop(context);

      showWanderMoodToast(
        context,
        message: 'Plan saved! You can find it in your saved plans.',
        backgroundColor: const Color(0xFF2A6049),
      );

      // Navigate to saved plans screen
      context.goNamed('home', extra: {'showNavigationBar': true, 'selectedIndex': 0});
    } catch (error) {
      // Close loading indicator
      Navigator.pop(context);

      showWanderMoodToast(
        context,
        message: 'Unable to save plan. Please try again.',
        isError: true,
      );
    }
  }

  // Handle Start with Free Activities - Navigate to free activities view
  void _handleStartFreeActivities(BuildContext context) {
    if (freeActivities.isEmpty) {
      showWanderMoodToast(
        context,
        message: 'No free activities available in this plan.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    // Navigate to main screen
    context.goNamed('home', extra: {'showNavigationBar': true, 'selectedIndex': 0});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Confirm Your Plan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Ready to Go Activities Section
                  _buildSectionTitle('Ready to Go'),
                  ...activities
                      .where((activity) => !activity.isPaid)
                      .map((activity) => _buildActivityCard(activity))
                      .toList(),

                  const SizedBox(height: 24),

                  // Requires Booking Section
                  _buildSectionTitle('Requires Booking'),
                  ...activities
                      .where((activity) => activity.isPaid)
                      .map((activity) => _buildActivityCard(activity))
                      .toList(),

                  const SizedBox(height: 32),

                  // Security Features
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSecurityFeature(
                          Icons.security,
                          'Secure Payment',
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildSecurityFeature(
                          Icons.update,
                          '24h Free Cancellation',
                          Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildSecurityFeature(
                          Icons.verified_user,
                          'Verified Activities',
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Booking Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Book Now Button
                  ElevatedButton(
                    onPressed: () => _handleBookNow(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A6049),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Book Now',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Book Later Button
                  OutlinedButton(
                    onPressed: () => _handleBookLater(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2A6049),
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(
                        color: Color(0xFF2A6049),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Book Later',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Start with Free Activities Button
                  TextButton(
                    onPressed: () => _handleStartFreeActivities(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2A6049),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: Text(
                      'Start with Free Activities',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Activity Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              activity.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          
          // Activity Details
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
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${activity.startTime.hour}:${activity.startTime.minute.toString().padLeft(2, '0')} - ${activity.duration}min',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (activity.isPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Reservation Required',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF2196F3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeature(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 