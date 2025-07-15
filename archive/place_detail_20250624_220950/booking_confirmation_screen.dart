import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wandermood/core/theme/app_theme.dart';
import '../../models/place.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Place place;
  final String bookingOption;
  final int quantity;
  final String date;
  final double price;

  const BookingConfirmationScreen({
    required this.place,
    required this.bookingOption,
    required this.quantity,
    required this.date,
    required this.price,
    Key? key,
  }) : super(key: key);

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final String _bookingNumber = _generateBookingNumber();
  bool _isTicketSaved = false;

  static String _generateBookingNumber() {
    // Generate a pseudo-random booking number
    final now = DateTime.now();
    final datePart = DateFormat('yyMMdd').format(now);
    final randomPart = (10000 + now.millisecondsSinceEpoch % 90000).toString();
    return 'WM$datePart-$randomPart';
  }

  void _shareTicket() {
    HapticFeedback.mediumImpact();
    Share.share(
      'I\'m visiting ${widget.place.name} on ${widget.date}! ' 
      'Booking details: ${widget.bookingOption}, ${widget.quantity} ticket(s). '
      'Booking reference: $_bookingNumber',
      subject: 'My WanderMood Booking',
    );
  }

  void _addToCalendar() async {
    HapticFeedback.mediumImpact();
    // Show a confirmation message for this demo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Event added to your calendar!',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: const Color(0xFF12B347),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveTicket() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isTicketSaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Ticket saved to your device!',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: const Color(0xFF12B347),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.close,
              color: Colors.black,
              size: 20,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Booking Confirmed',
          style: GoogleFonts.poppins(
            color: AppTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Success Animation
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF12B347).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF12B347),
                        size: 80,
                      ),
                    ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                    ),
                    const SizedBox(height: 24),
                    
                    // Confirmation Text
                    Text(
                      'Your booking is confirmed!',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                    const SizedBox(height: 8),
                    
                    Text(
                      'Your e-ticket has been sent to your email.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                    const SizedBox(height: 36),
                    
                    // Ticket Card
                    Container(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top section with image and place details
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: Stack(
                              children: [
                                Image.asset(
                                  widget.place.photos.first,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                        stops: const [0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.place.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.place.address,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Middle section with dashed line separator
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: List.generate(
                                30,
                                (index) => Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    height: 2,
                                    color: index % 2 == 0
                                        ? Colors.grey.shade300
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Ticket details
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // QR Code placeholder
                                Container(
                                  alignment: Alignment.center,
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 150,
                                        height: 150,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300, width: 1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.qr_code_2,
                                              size: 80,
                                              color: Color(0xFF12B347),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Ticket QR Code',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Booking #: $_bookingNumber',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppTheme.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Booking details as rows
                                _buildDetailRow('Date', widget.date),
                                _buildDetailRow('Time', 'Any time (open entry)'),
                                _buildDetailRow('Type', widget.bookingOption),
                                _buildDetailRow('Quantity', '${widget.quantity} ticket(s)'),
                                _buildDetailRow('Total Price', '€${widget.price.toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
                    
                    const SizedBox(height: 36),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.save_alt,
                          label: _isTicketSaved ? 'Saved' : 'Save',
                          onPressed: _isTicketSaved ? null : _saveTicket,
                          isActive: _isTicketSaved,
                        ),
                        _buildActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          onPressed: _shareTicket,
                        ),
                        _buildActionButton(
                          icon: Icons.calendar_today,
                          label: 'Calendar',
                          onPressed: _addToCalendar,
                        ),
                      ],
                    ).animate().fadeIn(delay: 1200.ms, duration: 500.ms),
                  ],
                ),
              ),
            ),
            
            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12B347),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "We did it, Joe! 🎉",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ).animate()
              .fadeIn(delay: 1500.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0)
              .then()
              .shimmer(duration: 1200.ms, curve: Curves.easeInOut)
              .then()
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.05, 1.05), 
                duration: 700.ms,
              ).then(delay: 200.ms)
              .scale(
                begin: const Offset(1.05, 1.05),
                end: const Offset(1.0, 1.0),
                duration: 700.ms,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFF12B347).withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive 
                ? const Color(0xFF12B347) 
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive 
                  ? const Color(0xFF12B347) 
                  : Colors.grey.shade700,
              size: 24,
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 800.ms,
                curve: Curves.easeInOut, 
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.2, 1.2),
              ).then()
              .rotate(duration: 400.ms, begin: -0.05, end: 0.05),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive 
                    ? const Color(0xFF12B347) 
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: 100.ms, duration: 400.ms)
      .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }
} 