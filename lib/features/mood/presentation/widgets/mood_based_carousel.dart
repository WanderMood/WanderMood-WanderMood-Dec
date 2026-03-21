import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../places/models/place.dart';
import '../../../../core/extensions/string_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../plans/data/services/scheduled_activity_service.dart';
import '../../../plans/domain/models/activity.dart';
import '../../../plans/domain/enums/time_slot.dart';
import '../../../plans/domain/enums/payment_type.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../home/presentation/screens/dynamic_my_day_provider.dart';
import '../../../home/presentation/screens/main_screen.dart';
import '../../../places/services/saved_places_service.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class MoodBasedCarousel extends ConsumerWidget {
  final List<Place> places;
  final String mood;
  final VoidCallback? onPlaceSelected;

  const MoodBasedCarousel({
    super.key,
    required this.places,
    required this.mood,
    this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (places.isEmpty) {
      return const SizedBox.shrink();
    }

    // Take only top 5 places
    final displayPlaces = places.take(5).toList();

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: displayPlaces.length,
        itemBuilder: (context, index) {
          final place = displayPlaces[index];
          return _buildPlaceCard(context, place, index);
        },
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, Place place, int index) {
    // Color variations for different cards
    final gradientColors = [
      [const Color(0xFFFFE5B4), const Color(0xFFFFD6A5)], // Warm peach
      [const Color(0xFFB4E5FF), const Color(0xFFA5D8FF)], // Sky blue
      [const Color(0xFFFFB4D5), const Color(0xFFFFA5C8)], // Soft pink
      [const Color(0xFFB4FFD5), const Color(0xFFA5FFBB)], // Mint green
      [const Color(0xFFD4B4FF), const Color(0xFFC8A5FF)], // Lavender
    ];
    
    final colors = gradientColors[index % gradientColors.length];

    return GestureDetector(
      onTap: () {
        // Navigate to place details
        context.push('/place/${place.id}');
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        child: Stack(
          children: [
            // Card with shadow for floating effect
            Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  blurRadius: 10,
                  spreadRadius: -5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section
                  Expanded(
                    flex: 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Place image or gradient placeholder
                        place.photos.isNotEmpty
                            ? Image.network(
                                place.photos.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(colors),
                              )
                            : _buildPlaceholder(colors),
                        
                        // Gradient overlay
                        Container(
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
                        
                        // Distance badge
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Color(0xFF2A6049),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Nearby',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A202C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Mood fit indicator (optional)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A6049).withOpacity(0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2A6049).withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        // Place name at bottom
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Text(
                            place.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Info and actions section
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description or types
                          if (place.types.isNotEmpty)
                            Text(
                              place.types.first.capitalize(),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF4A5568),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          
                          const Spacer(),
                          
                          // Time-aware action buttons
                          _buildTimeAwareActions(place, context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTimeAwareActions(Place place, BuildContext context) {
    final hour = DateTime.now().hour;
    String primaryLabel;
    IconData primaryIcon;
    String timePeriod;
    
    // Determine primary action based on time of day
    if (hour >= 6 && hour < 12) {
      primaryLabel = 'Add to morning';
      primaryIcon = Icons.wb_sunny;
      timePeriod = 'morning';
    } else if (hour >= 12 && hour < 17) {
      primaryLabel = 'Add to afternoon';
      primaryIcon = Icons.wb_cloudy;
      timePeriod = 'afternoon';
    } else {
      primaryLabel = 'Add to evening';
      primaryIcon = Icons.nightlight;
      timePeriod = 'evening';
    }
    
    return Consumer(
      builder: (context, ref, child) {
        return Row(
          children: [
            // Save button
            Expanded(
              child: _buildActionButton(
                label: 'Save',
                icon: Icons.bookmark_outline,
                isPrimary: false,
                onTap: () => _savePlace(context, ref, place),
              ),
            ),
            const SizedBox(width: 12),
            // Time-aware primary button
            Expanded(
              child: _buildActionButton(
                label: primaryLabel,
                icon: primaryIcon,
                isPrimary: true,
                onTap: () => _addPlaceToSchedule(context, ref, place, timePeriod),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePlace(BuildContext context, WidgetRef ref, Place place) async {
    try {
      final savedPlacesService = ref.read(savedPlacesServiceProvider);
      await savedPlacesService.savePlace(place);
      
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: '${place.name} saved!',
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2A6049),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: 'Failed to save ${place.name}',
          isError: true,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _addPlaceToSchedule(
    BuildContext context,
    WidgetRef ref,
    Place place,
    String timePeriod,
  ) async {
    try {
      final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
      
      // Convert time period to TimeSlot enum and calculate start time
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      TimeSlot timeSlotEnum;
      DateTime startTime;
      int defaultHour;
      
      switch (timePeriod.toLowerCase()) {
        case 'morning':
          timeSlotEnum = TimeSlot.morning;
          defaultHour = 9;
          startTime = today.add(Duration(hours: defaultHour));
          break;
        case 'afternoon':
          timeSlotEnum = TimeSlot.afternoon;
          defaultHour = 14;
          startTime = today.add(Duration(hours: defaultHour));
          break;
        case 'evening':
          timeSlotEnum = TimeSlot.evening;
          defaultHour = 18;
          startTime = today.add(Duration(hours: defaultHour));
          break;
        default:
          timeSlotEnum = TimeSlot.afternoon;
          defaultHour = 14;
          startTime = today.add(Duration(hours: defaultHour));
      }
      
      // Determine payment type
      PaymentType paymentType = PaymentType.free;
      if (place.types.contains('restaurant') || 
          place.types.contains('spa') || 
          place.types.contains('museum') ||
          place.types.contains('tourist_attraction')) {
        paymentType = PaymentType.reservation;
      }
      
      // Get image URL - use first photo if available, otherwise empty (will show emoji fallback in UI)
      final imageUrl = place.photos.isNotEmpty ? place.photos.first : '';
      
      // Create Activity from Place
      final activity = Activity(
        id: 'place_${place.id}_${DateTime.now().millisecondsSinceEpoch}',
        name: place.name,
        description: place.address ?? 'Visit ${place.name}',
        imageUrl: imageUrl,
        rating: place.rating > 0 ? place.rating : 4.5,
        startTime: startTime,
        duration: 120, // Default 2 hours
        timeSlot: timePeriod.toLowerCase(),
        timeSlotEnum: timeSlotEnum,
        tags: place.types.isNotEmpty ? place.types : ['explore'],
        location: LatLng(place.location.lat, place.location.lng),
        paymentType: paymentType,
        priceLevel: place.priceLevel != null ? '€${place.priceLevel}' : null,
      );
      
      // Save to database
      await scheduledActivityService.saveScheduledActivities([activity], isConfirmed: false);
      
      // Invalidate providers to refresh My Day screen
      ref.invalidate(scheduledActivityServiceProvider);
      ref.invalidate(scheduledActivitiesForTodayProvider);
      ref.invalidate(todayActivitiesProvider);
      
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: '${place.name} added to your $timePeriod!',
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF2A6049),
          leading: const Icon(Icons.check_circle, color: Colors.white, size: 20),
          actionLabel: 'View',
          onAction: () {
            ref.read(mainTabProvider.notifier).state = 0;
          },
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error adding place to schedule: $e');
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: 'Failed to add ${place.name}. Please try again.',
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Widget _buildPlaceholder(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 80,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isPrimary
                ? const Color(0xFF2A6049)
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary ? Colors.white : const Color(0xFF1A202C),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : const Color(0xFF1A202C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDirections(Place place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.location.lat},${place.location.lng}',
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

