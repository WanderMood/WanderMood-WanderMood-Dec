import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';

class WanderFeedComingSoonScreen extends StatelessWidget {
  const WanderFeedComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'WanderFeed',
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2A6049),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A6049).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Color(0xFF2A6049),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'WanderFeed',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A202C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'A social space for travelers — share your adventures, discover hidden gems, and connect with fellow wanderers.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Features
                _buildFeatureItem(
                  icon: Icons.camera_alt_outlined,
                  title: 'Share Your Journey',
                  description: 'Post photos and stories from your travels',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  icon: Icons.explore_outlined,
                  title: 'Discover Places',
                  description: 'Find hidden gems shared by the community',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  icon: Icons.favorite_outline,
                  title: 'Connect & Engage',
                  description: 'Like, comment, and follow fellow travelers',
                ),
                const SizedBox(height: 48),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A6049).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'Be among the first to explore WanderFeed 🧳✨',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2A6049),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A6049).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2A6049),
            size: 24,
          ),
        ),
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
                  color: const Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}



