import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> bookingResult;
  final List<Activity> activities;

  const BookingConfirmationScreen({
    Key? key,
    required this.bookingResult,
    required this.activities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Confirmed',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Icon
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2A6049),
                size: 64,
              ),
              const SizedBox(height: 16),
              
              // Success Message
              Text(
                'Your activities have been booked!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your email for confirmation details',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              // Booking Details
              Text(
                'Booking Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              
              // List of booked activities
              ...activities.map((activity) => _buildActivityCard(activity)),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              ElevatedButton(
                onPressed: () {
                  // Navigate to schedule/calendar
                  Navigator.of(context).pushReplacementNamed('/schedule');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A6049),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'View Schedule',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Navigate back to home
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2A6049),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: activity.isPaid ? const Color(0xFF2A6049) : Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
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
                  Text(
                    '${activity.startTime.hour}:${activity.startTime.minute.toString().padLeft(2, '0')} - ${activity.duration} min',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              activity.isPaid ? Icons.confirmation_number : Icons.check_circle,
              color: activity.isPaid ? const Color(0xFF2A6049) : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
} 