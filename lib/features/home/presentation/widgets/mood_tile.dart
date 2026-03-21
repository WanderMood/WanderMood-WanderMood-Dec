import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MoodTile extends StatelessWidget {
  final String label;
  final String emoji;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSelectionEnabled;

  const MoodTile({
    Key? key,
    required this.label,
    required this.emoji,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
    this.isSelectionEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelectionEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 80,
        height: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : bgColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: bgColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Main content centered in tile
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Selection indicator with animation
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A6049),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ).animate()
                  .scale(duration: 200.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 200.ms),
              ),
          ],
        ),
      ).animate(target: isSelected ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
          curve: Curves.easeOut,
        )
        .then()
        .shimmer(
          duration: 500.ms,
          color: Colors.white.withOpacity(0.3),
          curve: Curves.easeOut,
        ),
    );
  }
} 