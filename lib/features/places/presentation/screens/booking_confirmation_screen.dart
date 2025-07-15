import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/core/theme/app_theme.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/bookings_provider.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final Place place;
  final String bookingType;
  final DateTime date;
  final String time;
  final int guests;
  final double totalPrice;

  const BookingConfirmationScreen({
    required this.place,
    required this.bookingType,
    required this.date,
    required this.time,
    required this.guests,
    required this.totalPrice,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _slideController;
  String? _bookingReference;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Start animations
    _confettiController.forward();
    _slideController.forward();
    
    // Show haptic feedback
    HapticFeedback.heavyImpact();
    
    // Save booking after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveBooking();
    });
  }

  Future<void> _saveBooking() async {
    try {
      print('📝 Attempting to save booking for ${widget.place.name}...');
      final bookingReference = await ref.read(bookingsProvider.notifier).addBooking(
        place: widget.place,
        bookingType: widget.bookingType,
        date: widget.date,
        time: widget.time,
        guests: widget.guests,
        totalPrice: widget.totalPrice,
      );
      
      print('✅ Booking saved successfully with reference: $bookingReference');
      
      setState(() {
        _bookingReference = bookingReference;
      });
      
      // Show a quick success toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking saved successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF12B347),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Handle error - could show a snackbar or retry
      print('❌ Error saving booking: $e');
      setState(() {
        _bookingReference = _generateBookingReference(); // Fallback
      });
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving booking: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  static String _generateBookingReference() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = 'WM';
    for (int i = 0; i < 6; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildSuccessIcon(),
                      const SizedBox(height: 24),
                      _buildConfirmationMessage(),
                      const SizedBox(height: 32),
                      _buildBookingCard(),
                      const SizedBox(height: 24),
                      _buildPlaceCard(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.goNamed('main', extra: {'tab': 0, 'bypass_preferences': true}),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Booking Confirmed',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            onPressed: _shareBooking,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.share,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.elasticOut,
      )),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF12B347),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF12B347).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.check,
          size: 60,
          color: Colors.white,
        ),
      ).animate().scale(
        duration: 600.ms,
        curve: Curves.elasticOut,
      ),
    );
  }

  Widget _buildConfirmationMessage() {
    return Column(
      children: [
        Text(
          'Booking Confirmed!',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 8),
        Text(
          'Your visit to ${widget.place.name} has been successfully booked.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF12B347).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF12B347).withOpacity(0.3),
            ),
          ),
          child: Text(
            'Reference: $_bookingReference',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF12B347),
            ),
          ),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }

  Widget _buildBookingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            Icons.confirmation_number,
            'Experience Type',
            widget.bookingType,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            DateFormat('EEEE, MMMM d, yyyy').format(widget.date),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.access_time,
            'Time',
            widget.time,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.people,
            'Guests',
            '${widget.guests} Guest${widget.guests > 1 ? 's' : ''}',
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF12B347).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '€${widget.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF12B347),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideX(
      begin: 0.3,
      duration: 600.ms,
      curve: Curves.easeOutCubic,
      delay: 400.ms,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF12B347).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF12B347),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destination',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: widget.place.photos.isNotEmpty
                      ? (widget.place.isAsset
                          ? Image.asset(
                              widget.place.photos.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildImageFallback(),
                            )
                          : Image.network(
                              widget.place.photos.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildImageFallback(),
                            ))
                      : _buildImageFallback(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.place.name,
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
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.place.address,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.place.rating > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.place.rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideX(
      begin: -0.3,
      duration: 600.ms,
      curve: Curves.easeOutCubic,
      delay: 600.ms,
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.image,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addToCalendar,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Add to Calendar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12B347),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25), // Pill-shaped button
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareBooking,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF12B347),
                  side: const BorderSide(color: Color(0xFF12B347)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25), // Pill-shaped button
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.goNamed('main', extra: {'tab': 0, 'bypass_preferences': true}),
                icon: const Icon(Icons.home),
                label: const Text('My Day'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25), // Pill-shaped button
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  void _shareBooking() {
    final message = '''
🎉 I just booked a visit to ${widget.place.name}!

📅 Date: ${DateFormat('EEEE, MMMM d, yyyy').format(widget.date)}
⏰ Time: ${widget.time}
👥 Guests: ${widget.guests}
🎫 Type: ${widget.bookingType}
📍 Location: ${widget.place.address}

Booking reference: ${_bookingReference ?? 'Generating...'}

Booked with WanderMood! 🌟
    '''.trim();

    Share.share(
      message,
      subject: 'My WanderMood Booking - ${widget.place.name}',
    );
  }

  void _addToCalendar() {
                // Show success message that booking has been saved to My Bookings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Booking saved! View in My Bookings',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF12B347),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
                          // Navigate to My Bookings screen
            context.go('/plans');
          },
        ),
      ),
    );
  }
} 