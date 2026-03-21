import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens — My Day free-time section (v2 spec).
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

class MyDayFreeTimeCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final void Function(Map<String, dynamic>) onActivityTap;
  final void Function(Map<String, dynamic>) onSaveTap;
  final void Function(Map<String, dynamic>) onDirectionsTap;

  const MyDayFreeTimeCarousel({
    super.key,
    required this.activities,
    required this.onActivityTap,
    required this.onSaveTap,
    required this.onDirectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '✨ ',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _wmForest,
                      ),
                    ),
                    TextSpan(
                      text: 'Free Time Activities',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _wmCharcoal,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Near you',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _wmStone,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Discover what you can do right now',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _wmStone,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          // Card: 100 image + text block (2-line title + 2-line desc) + button row; 248 was too tight → overflow
          height: 308,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _FreeTimeCard(
                  activity: activity,
                  onTap: () => onActivityTap(activity),
                  onSaveTap: () => onSaveTap(activity),
                  onDirectionsTap: () => onDirectionsTap(activity),
                ).animate(delay: (index * 200).ms)
                    .slideX(begin: 0.3, duration: 600.ms)
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.9, 0.9), duration: 400.ms),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FreeTimeCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;
  final VoidCallback onSaveTap;
  final VoidCallback onDirectionsTap;

  const _FreeTimeCard({
    required this.activity,
    required this.onTap,
    required this.onSaveTap,
    required this.onDirectionsTap,
  });

  static String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return 'Food';
      case 'exercise':
        return 'Exercise';
      case 'culture':
        return 'Culture';
      case 'entertainment':
        return 'Entertainment';
      case 'shopping':
        return 'Shopping';
      case 'social':
        return 'Social';
      case 'nature':
        return 'Nature';
      default:
        return 'Place';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = activity['title'] as String? ?? 'Activity';
    final description = activity['description'] as String? ?? '';
    final distance = activity['distance'] as String? ?? '';
    final category = (activity['category'] as String?) ?? '';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: _wmWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _wmParchment, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: activity['imageUrl'] ??
                        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: _wmCream,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _wmForest,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: _wmCream,
                      child: Icon(Icons.image_outlined, color: _wmStone, size: 40),
                    ),
                  ),
                  if (distance.isNotEmpty)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _wmWhite.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _wmParchment, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place_outlined, color: _wmStone, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              distance,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _wmCharcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (category.isNotEmpty)
                    Text(
                      _categoryLabel(category).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _wmStone,
                        letterSpacing: 0.08,
                      ),
                    ),
                  if (category.isNotEmpty) const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _wmCharcoal,
                      height: 1.2,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _wmStone,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onSaveTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _wmForest,
                            side: const BorderSide(color: _wmForest, width: 1.5),
                            backgroundColor: _wmWhite,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            minimumSize: const Size(0, 34),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Save',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onDirectionsTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _wmForest,
                            foregroundColor: _wmWhite,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            minimumSize: const Size(0, 34),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Directions',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
