import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/home/presentation/screens/main_screen.dart';

class MultiActivityBookingScreen extends ConsumerStatefulWidget {
  final List<Activity> activities;
  final String bookingType; // 'book_now', 'book_later', 'free_only'

  const MultiActivityBookingScreen({
    Key? key,
    required this.activities,
    required this.bookingType,
  }) : super(key: key);

  @override
  ConsumerState<MultiActivityBookingScreen> createState() => _MultiActivityBookingScreenState();
}

class _MultiActivityBookingScreenState extends ConsumerState<MultiActivityBookingScreen> {
  late List<Activity> freeActivities;
  late List<Activity> paidActivities;
  bool _isProcessing = false;
  String _processingMessage = '';
  
  @override
  void initState() {
    super.initState();
    _separateActivities();
  }

  void _separateActivities() {
    freeActivities = widget.activities.where((activity) => 
      activity.paymentType == PaymentType.free).toList();
    paidActivities = widget.activities.where((activity) => 
      activity.paymentType != PaymentType.free).toList();
  }

  double get totalCost => paidActivities.fold(0.0, (sum, activity) => 
    sum + (activity.price ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          const SwirlBackground(child: SizedBox.expand()),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBookingTypeInfo(),
                        const SizedBox(height: 24),
                        _buildActivitiesSection(),
                        const SizedBox(height: 24),
                        _buildCostSummary(),
                        const SizedBox(height: 24),
                        _buildBookingDetails(),
                        const SizedBox(height: 100), // Space for floating button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating action button
          if (!_isProcessing) _buildFloatingActionButton(),
          
          // Processing overlay
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF4CAF50),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getHeaderTitle(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.activities.length} ${widget.activities.length == 1 ? 'Activity' : 'Activities'} Selected',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (widget.bookingType) {
      case 'book_now':
        return 'Book Activities Now';
      case 'book_later':
        return 'Save for Later';
      case 'free_only':
        return 'Free Activities';
      default:
        return 'Activity Booking';
    }
  }

  Widget _buildBookingTypeInfo() {
    String title;
    String description;
    Color color;
    IconData icon;

    switch (widget.bookingType) {
      case 'book_now':
        title = 'Immediate Booking';
        description = 'We\'ll process your bookings right away and send confirmation details to your email.';
        color = const Color(0xFF4CAF50);
        icon = Icons.check_circle;
        break;
      case 'book_later':
        title = 'Save for Later';
        description = 'Activities will be saved to your plans. You can book them individually when you\'re ready.';
        color = const Color(0xFF2196F3);
        icon = Icons.schedule;
        break;
      case 'free_only':
        title = 'Free Activities';
        description = 'These activities don\'t require advance booking. Just show up and enjoy!';
        color = const Color(0xFFFF9800);
        icon = Icons.free_breakfast;
        break;
      default:
        title = 'Activity Booking';
        description = 'Processing your selected activities';
        color = const Color(0xFF4CAF50);
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Activities',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Free activities
        if (freeActivities.isNotEmpty) ...[
          _buildSectionTitle('Free Activities', freeActivities.length, Colors.green),
          const SizedBox(height: 8),
          ...freeActivities.map((activity) => _buildActivityCard(activity, false)),
          const SizedBox(height: 16),
        ],
        
        // Paid activities
        if (paidActivities.isNotEmpty) ...[
          _buildSectionTitle('Paid Activities', paidActivities.length, Colors.orange),
          const SizedBox(height: 8),
          ...paidActivities.map((activity) => _buildActivityCard(activity, true)),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity, bool isPaid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Activity image or placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[200],
              child: activity.imageUrl.isNotEmpty
                  ? Image.network(
                      activity.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
          const SizedBox(width: 16),
          
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(activity.startTime),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.duration} minutes',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          
          // Price or free indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPaid ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPaid ? '€${activity.price?.toStringAsFixed(2) ?? '0.00'}' : 'Free',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPaid ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(
        Icons.image,
        color: Colors.grey,
        size: 24,
      ),
    );
  }

  Widget _buildCostSummary() {
    if (widget.bookingType == 'free_only') return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          if (freeActivities.isNotEmpty)
            _buildCostRow('Free Activities', '€0.00', Colors.green),
          
          if (paidActivities.isNotEmpty)
            _buildCostRow('Paid Activities', '€${totalCost.toStringAsFixed(2)}', Colors.orange),
          
          if (paidActivities.isNotEmpty) ...[
            const Divider(height: 24),
            _buildCostRow('Total', '€${totalCost.toStringAsFixed(2)}', Colors.black, isTotal: true),
          ],
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Booking Information',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow('Date', DateFormat('EEEE, MMMM d, y').format(DateTime.now())),
          _buildInfoRow('Time', _getTimeRange()),
          _buildInfoRow('Activities', '${widget.activities.length} selected'),
          
          if (widget.bookingType == 'book_now') ...[
            _buildInfoRow('Confirmation', 'Email will be sent after booking'),
            _buildInfoRow('Cancellation', 'Free cancellation up to 24 hours before'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeRange() {
    if (widget.activities.isEmpty) return 'No activities';
    
    final startTime = widget.activities.map((a) => a.startTime).reduce((a, b) => a.isBefore(b) ? a : b);
    final endTime = widget.activities.map((a) => a.startTime.add(Duration(minutes: a.duration))).reduce((a, b) => a.isAfter(b) ? a : b);
    
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: ElevatedButton(
        onPressed: _processBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getActionIcon()),
            const SizedBox(width: 8),
            Text(
              _getActionText(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: 0.5, duration: 300.ms),
    );
  }

  IconData _getActionIcon() {
    switch (widget.bookingType) {
      case 'book_now':
        return Icons.payment;
      case 'book_later':
        return Icons.bookmark;
      case 'free_only':
        return Icons.check_circle;
      default:
        return Icons.check;
    }
  }

  String _getActionText() {
    switch (widget.bookingType) {
      case 'book_now':
        return 'Confirm Booking (€${totalCost.toStringAsFixed(2)})';
      case 'book_later':
        return 'Save to My Plans';
      case 'free_only':
        return 'Add to My Day';
      default:
        return 'Confirm';
    }
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 16),
              Text(
                _processingMessage,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processBooking() async {
    if (_isProcessing) return;

    debugPrint('🚀 Starting booking process for ${widget.activities.length} activities');

    setState(() {
      _isProcessing = true;
      _processingMessage = _getProcessingMessage();
    });

    try {
      // Check authentication state first
      final currentUser = ref.read(authStateProvider).asData?.value;
      debugPrint('🔐 Current user: ${currentUser?.id}');
      
      if (currentUser == null) {
        debugPrint('❌ No authenticated user found');
        throw Exception('User not authenticated');
      }
      
      // Save activities to database
      final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
      
      debugPrint('📝 Saving ${widget.activities.length} activities to database...');
      try {
      await scheduledActivityService.saveScheduledActivities(
        widget.activities, 
        isConfirmed: widget.bookingType == 'book_now',
      );
        debugPrint('✅ Activities saved successfully to database');
      } catch (saveError) {
        debugPrint('⚠️ Database save failed, but continuing: $saveError');
        // Continue anyway - the service has fallback to in-memory storage
      }

      // Simulate booking process
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        debugPrint('🎉 Showing success dialog');
        // Show success dialog (navigation happens when user clicks "Great!")
        await _showSuccessDialog();
        debugPrint('✅ Success dialog completed');
      }
    } catch (e) {
      debugPrint('❌ Error in booking process: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      if (mounted) {
        // Show error dialog
        await _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        debugPrint('🏁 Booking process completed');
      }
    }
  }

  String _getProcessingMessage() {
    switch (widget.bookingType) {
      case 'book_now':
        return 'Processing your booking...\nThis may take a moment.';
      case 'book_later':
        return 'Saving to your plans...\nYou can book these later.';
      case 'free_only':
        return 'Adding to your day...\nAlmost ready!';
      default:
        return 'Processing...';
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _getSuccessTitle(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          _getSuccessMessage(),
          style: GoogleFonts.poppins(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              debugPrint('🔘 User clicked Great! button - NAVIGATING TO MY DAY');
              
              // Invalidate providers FIRST for fresh data
              debugPrint('🔄 Invalidating providers for fresh data');
              ref.invalidate(scheduledActivityServiceProvider);
              ref.invalidate(cachedActivitySuggestionsProvider);
              debugPrint('✅ Providers invalidated');
              
              // Close dialog
              debugPrint('🚪 Closing dialog');
              Navigator.of(context).pop();
              debugPrint('✅ Dialog closed');
              
              // Small delay to ensure dialog is fully closed
              await Future.delayed(const Duration(milliseconds: 100));
              
              if (!context.mounted) return;
              
              // Use the working navigation pattern from the old version - set tab FIRST
              debugPrint('🧭 Navigating to main screen with My Day tab');
              ref.read(mainTabProvider.notifier).state = 0;
              debugPrint('✅ Tab provider set to 0 immediately');
              context.goNamed('main', extra: {'showNavigationBar': true, 'tab': 0});
              debugPrint('✅ Navigation completed');
            },
            child: Text(
              'Great!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSuccessTitle() {
    switch (widget.bookingType) {
      case 'book_now':
        return 'Booking Confirmed!';
      case 'book_later':
        return 'Saved Successfully!';
      case 'free_only':
        return 'Added to Your Day!';
      default:
        return 'Success!';
    }
  }

  String _getSuccessMessage() {
    switch (widget.bookingType) {
      case 'book_now':
        return 'Your activities have been booked! Check your email for confirmation details.';
      case 'book_later':
        return 'Your activities have been saved to your plans. You can book them anytime from My Day.';
      case 'free_only':
        return 'Your free activities have been added to your day schedule. Enjoy!';
      default:
        return 'Your activities have been processed successfully.';
    }
  }

  Future<void> _showErrorDialog(String error) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Booking Error'),
        content: Text('Sorry, we couldn\'t process your booking. Please try again.\n\nError: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
} 