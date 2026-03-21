import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/places/providers/bookings_provider.dart';
import 'package:wandermood/features/places/providers/moody_explore_provider.dart';
import 'package:wandermood/features/places/models/booking.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/home/presentation/screens/main_screen.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class TravelPlansScreen extends ConsumerStatefulWidget {
  const TravelPlansScreen({super.key});

  @override
  ConsumerState<TravelPlansScreen> createState() => _TravelPlansScreenState();
}

class _TravelPlansScreenState extends ConsumerState<TravelPlansScreen> {

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'My Bookings',
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2A6049),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              // Check if we can pop, otherwise go to main screen
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/main');
              }
            },
          ),
        ),
        body: _buildBookingsContent(),
      ),
    );
  }
  
  Widget _buildBookingsContent() {
    final bookingsAsync = ref.watch(bookingsProvider);
    
    return bookingsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load your bookings',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(bookingsProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A6049),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
      data: (bookings) {
        print('🔍 Loaded ${bookings.length} bookings from provider');
        
        if (bookings.isEmpty) {
          print('🔍 No bookings found, showing empty state');
          return _buildEnhancedEmptyState(context, ref);
        } else {
          return _buildBookingsList(bookings);
        }
      },
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    // Group bookings by status
    final upcomingBookings = bookings.where((booking) => 
      booking.status == BookingStatus.confirmed && 
      booking.date.isAfter(DateTime.now())
    ).toList();
    
    final pastBookings = bookings.where((booking) => 
      booking.date.isBefore(DateTime.now()) ||
      booking.status == BookingStatus.completed
    ).toList();
    
    final cancelledBookings = bookings.where((booking) => 
      booking.status == BookingStatus.cancelled || 
      booking.status == BookingStatus.noShow
    ).toList();

    // Sort by date
    upcomingBookings.sort((a, b) => a.date.compareTo(b.date));
    pastBookings.sort((a, b) => b.date.compareTo(a.date));
    cancelledBookings.sort((a, b) => a.date.compareTo(b.date));

         return ListView(
       padding: const EdgeInsets.all(16),
       children: [
         // Cancelled Bookings
         if (cancelledBookings.isNotEmpty) ...[
           _buildSectionHeader('Cancelled', cancelledBookings.length, Colors.red),
           const SizedBox(height: 12),
           ...cancelledBookings.map((booking) => _buildBookingCard(booking)),
           const SizedBox(height: 24),
         ],
        
        // Upcoming Bookings
        if (upcomingBookings.isNotEmpty) ...[
          _buildSectionHeader('Upcoming', upcomingBookings.length, const Color(0xFF2A6049)),
          const SizedBox(height: 12),
          ...upcomingBookings.map((booking) => _buildBookingCard(booking)),
          const SizedBox(height: 24),
        ],
        
        // Past Bookings
        if (pastBookings.isNotEmpty) ...[
          _buildSectionHeader('Past Experiences', pastBookings.length, Colors.grey),
          const SizedBox(height: 12),
          ...pastBookings.map((booking) => _buildBookingCard(booking)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final place = booking.place;
    final bookedDate = DateFormat('MMM d, yyyy').format(booking.date);
    final timeString = booking.time;
    
    // Status styling
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (booking.status) {
      case BookingStatus.confirmed:
        statusColor = const Color(0xFF2A6049);
        statusText = 'Confirmed';
        statusIcon = Icons.check_circle;
        break;
      case BookingStatus.completed:
        statusColor = Colors.blue;
        statusText = 'Completed';
        statusIcon = Icons.done_all;
        break;
      case BookingStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        statusIcon = Icons.cancel;
        break;
      case BookingStatus.noShow:
        statusColor = Colors.orange;
        statusText = 'No Show';
        statusIcon = Icons.warning;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with place name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Date and location
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$bookedDate at $timeString',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            
            if (place.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      place.address,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Booking details
            if (booking.guests > 1) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.guests} ${booking.guests == 1 ? 'person' : 'people'}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
            
            // Action buttons for upcoming bookings
            if (booking.status == BookingStatus.confirmed && booking.date.isAfter(DateTime.now())) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Add to calendar
                        showWanderMoodToast(
                          context,
                          message: 'Added to calendar',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2A6049),
                        side: const BorderSide(color: Color(0xFF2A6049)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Add to Calendar',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // View details
                        showWanderMoodToast(
                          context,
                          message: 'Viewing booking details',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Details',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedEmptyState(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(moodyHubExploreCacheOnlyProvider);
    
    return placesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
        ),
      ),
      error: (error, stackTrace) => _buildBasicEmptyState(),
      data: (places) {
        // Get top 3 most interesting places for preview
        final previewPlaces = places.take(3).toList();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Hero Section with Moody and Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF667eea).withOpacity(0.1),
                      const Color(0xFF764ba2).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF667eea).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Animated Floating Moody Character
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: const MoodyCharacter(
                            size: 120,
                            mood: 'happy',
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Main Headline
                    Text(
                      'Ready to book your first experience?',
                      style: GoogleFonts.museoModerno(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Subheadline with dynamic count
                    Text(
                      'I\'ve found ${places.length} amazing places in Rotterdam waiting for you! 🇳🇱',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF4A5568),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Preview Cards Section
              if (previewPlaces.isNotEmpty) ...[
                Text(
                  'Popular places to book',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Preview Cards
                ...previewPlaces.map((place) => _buildPreviewCard(place)),
                
                const SizedBox(height: 24),
              ],
              
              // Action Buttons
              Column(
                children: [
                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to Explore tab
                        ref.read(mainTabProvider.notifier).state = 1;
                        if (context.mounted) {
                          context.goNamed('main', extra: {'tab': 1});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A6049),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.explore, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Explore & Book Places',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Secondary CTA
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to Moody chat
                        ref.read(mainTabProvider.notifier).state = 2;
                        if (context.mounted) {
                          context.goNamed('main', extra: {'tab': 2});
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF667eea),
                        side: const BorderSide(color: Color(0xFF667eea)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.psychology, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ask Moody for recommendations',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Bottom padding to ensure content doesn't get cut off
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewCard(Place place) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon based on place type
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2A6049).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getPlaceIcon(place),
              color: const Color(0xFF2A6049),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Place details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Rating and review count
                Row(
                  children: [
                    if (place.rating > 0) ...[
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (place.reviewCount > 0) ...[
                        const SizedBox(width: 2),
                        Text(
                          '(${place.reviewCount})',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        'Rotterdam',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Arrow icon
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  IconData _getPlaceIcon(Place place) {
    final types = place.types.map((t) => t.toLowerCase()).toList();
    final typesString = types.join(' ');
    
    if (typesString.contains('restaurant') || typesString.contains('food')) {
      return Icons.restaurant;
    } else if (typesString.contains('bar') || typesString.contains('night')) {
      return Icons.local_bar;
    } else if (typesString.contains('museum') || typesString.contains('tourist')) {
      return Icons.camera_alt;
    } else if (typesString.contains('park') || typesString.contains('outdoor')) {
      return Icons.park;
    } else if (typesString.contains('lodging') || typesString.contains('hotel')) {
      return Icons.hotel;
    } else {
      return Icons.place;
    }
  }

  Widget _buildBasicEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings yet',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your booked experiences will appear here',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate to Explore
              ref.read(mainTabProvider.notifier).state = 1;
              context.goNamed('main', extra: {'tab': 1});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A6049),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Explore Places',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 