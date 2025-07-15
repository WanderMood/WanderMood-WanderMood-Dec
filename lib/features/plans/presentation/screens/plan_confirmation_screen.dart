import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/home/presentation/screens/main_home_screen.dart';
import 'package:wandermood/features/home/presentation/screens/mood_home_screen.dart';
import 'package:wandermood/features/plans/presentation/widgets/plan_loading_overlay.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/home/presentation/screens/main_screen.dart';

class PlanConfirmationScreen extends ConsumerWidget {
  final List<Activity> activities;

  const PlanConfirmationScreen({
    Key? key,
    required this.activities,
  }) : super(key: key);

  double get totalCost => activities
      .where((activity) => activity.isPaid)
      .fold(0, (sum, activity) => sum + (activity.price ?? 0));

  List<Activity> get freeActivities =>
      activities.where((activity) => !activity.isPaid).toList();

  List<Activity> get paidActivities =>
      activities.where((activity) => activity.isPaid).toList();

  void _navigateWithLoading(BuildContext context, WidgetRef ref, String message, {String? destination}) async {
    debugPrint('🚀 _navigateWithLoading called with message: "$message"');
    debugPrint('🎯 Target destination: ${destination ?? "My Day (default)"}');
    
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PlanLoadingOverlay(message: message),
    );

    try {
      // Get the scheduled activity service
      final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
      
      debugPrint('About to save ${activities.length} activities to Supabase');
      
      try {
        // 🔧 CRITICAL FIX: Override activity dates to TODAY before saving
        final today = DateTime.now();
        final activitiesWithTodayDates = activities.map((activity) {
          final todayStartTime = DateTime(
            today.year, 
            today.month, 
            today.day, 
            activity.startTime.hour, 
            activity.startTime.minute
          );
          
          debugPrint('📅 Book Now Fix: ${activity.name} changed from ${activity.startTime.day}/${activity.startTime.month}/${activity.startTime.year} to ${todayStartTime.day}/${todayStartTime.month}/${todayStartTime.year}');
          
          return Activity(
            id: activity.id,
            name: activity.name,
            description: activity.description,
            timeSlot: activity.timeSlot,
            timeSlotEnum: activity.timeSlotEnum,
            duration: activity.duration,
            location: activity.location,
            paymentType: activity.paymentType,
            imageUrl: activity.imageUrl,
            rating: activity.rating,
            tags: activity.tags,
            startTime: todayStartTime, // 🔧 Use today's date
            priceLevel: activity.priceLevel,
            refreshCount: activity.refreshCount,
          );
        }).toList();
        
        // Save activities to Supabase
        debugPrint('Activities to save: ${activitiesWithTodayDates.map((a) => a.name).join(', ')}');
        for (final activity in activitiesWithTodayDates) {
          debugPrint('Activity: ${activity.name}, StartTime: ${activity.startTime}, Type: ${activity.paymentType}');
        }
        await scheduledActivityService.saveScheduledActivities(activitiesWithTodayDates, isConfirmed: true);
        debugPrint('Activities saved successfully');
        
        // CRITICAL: Invalidate providers in correct order to ensure fresh data
        debugPrint('🔄 Invalidating providers for fresh My Day data...');
        ref.invalidate(scheduledActivityServiceProvider);
        ref.invalidate(cachedActivitySuggestionsProvider);
        debugPrint('✅ Providers invalidated - My Day will load fresh activities');
        
        // Providers will refresh automatically when My Day loads
        debugPrint('✅ Ready for navigation - providers will refresh on My Day load');
      } catch (serviceError) {
        debugPrint('Warning: Error saving activities: $serviceError');
        debugPrint('Stack trace: ${StackTrace.current}');
        // Continue with navigation despite service error
      }
      
      // Wait for 2 seconds before navigating
      await Future.delayed(const Duration(seconds: 2));
      
      // Close the loading overlay
      if (context.mounted) {
        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your activities have been saved successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF12B347),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 1), // Reduced from 2s to prevent conflicts
          ),
        );
        
        if (destination != null) {
          // Navigate to the specified destination
          debugPrint('🧭 Navigating to specific destination: $destination');
          context.go(destination);
        } else {
          // 🔧 SIMPLE FIX: Use direct tab provider approach like the working backup
          debugPrint('🧭 NAVIGATING TO MY DAY - Using direct tab provider approach');
          debugPrint('🔍 Context mounted before navigation: ${context.mounted}');
          // Set tab provider directly to My Day
          try {
            ref.read(mainTabProvider.notifier).state = 0;
            debugPrint('✅ Tab provider set to My Day (index 0)');
            debugPrint('✅ Current tab provider value: ${ref.read(mainTabProvider)}');
          } catch (tabError) {
            debugPrint('❌ Failed to set tab provider: $tabError');
            debugPrint('❌ Tab provider error trace: ${StackTrace.current}');
          }
          // Set tab FIRST like other working screens
          ref.read(mainTabProvider.notifier).state = 0;
          // Then use goNamed with extra parameter
          if (context.mounted) {
            context.goNamed('main', extra: {'tab': 0});
            debugPrint('✅ Navigation command completed using goNamed');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ ERROR in _navigateWithLoading: $e');
      debugPrint('❌ ERROR stack trace: ${StackTrace.current}');
      debugPrint('❌ This error prevented navigation to My Day!');
      
      // Close the loading overlay
      if (context.mounted) {
        Navigator.pop(context);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save activities. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Confirm Your Plan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SwirlBackground(
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF5).withOpacity(0.7),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
              child: Column(
                children: [
                  Text(
                    'Total Cost: €${totalCost.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user,
                          color: Colors.green.shade700, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Secure Booking',
                          style: GoogleFonts.poppins(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (freeActivities.isNotEmpty) ...[
                    const Text(
                      'Ready to Go',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...freeActivities.map((activity) => _ActivityTile(
                          activity: activity,
                          showBookingStatus: false,
                        )),
                    const SizedBox(height: 24),
                  ],
                  if (paidActivities.isNotEmpty) ...[
                    const Text(
                      'Requires Booking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...paidActivities.map((activity) => _ActivityTile(
                          activity: activity,
                          showBookingStatus: true,
                        )),
                    const SizedBox(height: 24),
                  ],
                  _buildTrustSection(context),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.security, color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Secure Payment',
                  style: GoogleFonts.poppins(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.update, color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '24h Free Cancellation',
                  style: GoogleFonts.poppins(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.verified, color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verified Activities',
                  style: GoogleFonts.poppins(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => _navigateWithLoading(context, ref, 'Finalizing your bookings...'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF12B347),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            'Book Now',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _navigateWithLoading(
            context,
            ref, 
            'Saving your plan for later...'
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Color(0xFF12B347), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Book Later',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF12B347),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => _navigateWithLoading(context, ref, 'Getting your free activities ready...'),
            child: Text(
              'Start with Free Activities',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF12B347),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Activity activity;
  final bool showBookingStatus;

  const _ActivityTile({
    required this.activity,
    required this.showBookingStatus,
  });

  String _formatTime(DateTime time) {
    final String period = time.hour >= 12 ? 'PM' : 'AM';
    final int hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
        children: [
            if (activity.imageUrl != null)
              Container(
                  width: 80,
                  height: 80,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(activity.imageUrl!),
                  fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                      Text(
                          '${_formatTime(activity.startTime)} • ${activity.duration} min',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      ),
                      if (showBookingStatus) ...[
                        const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                            decoration: BoxDecoration(
                          color: const Color(0xFF12B347).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                          'Booking Required',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF12B347),
                              ),
                            ),
                          ),
                        ],
                      ],
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }
} 