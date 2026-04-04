import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import '../../domain/models/achievement.dart';
import '../../domain/models/achievement_titles.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool showAnimation;

  const AchievementBadge({
    Key? key,
    required this.achievement,
    this.onTap,
    this.showProgress = true,
    this.showAnimation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final icon = achievement.icon;
    final IconData iconData = _getIconData(icon);
    
    Widget badge = Container(
      width: 100,
      height: 130,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: achievement.unlocked 
              ? achievement.color.withOpacity(0.3)
              : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: achievement.unlocked
            ? achievement.color
            : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: achievement.unlocked 
                ? achievement.color 
                : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          
          // Achievement name
          Text(
            achievementTitleForId(achievement.id, l10n),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Progress indicator
          if (showProgress && !achievement.unlocked)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                children: [
                  SizedBox(
                    width: 70,
                    height: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2.5),
                      child: LinearProgressIndicator(
                        value: achievement.progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          achievement.color.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.currentValue}/${achievement.requiredValue}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          
          // Unlocked icon or date
          if (achievement.unlocked)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 12,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Unlocked',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    // Add animations if specified
    if (showAnimation) {
      if (achievement.unlocked) {
        // Unlocked achievement animation
        badge = badge
          .animate()
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: 400.ms,
            curve: Curves.elasticOut,
          )
          .shimmer(
            duration: 1.5.seconds, 
            color: achievement.color.withOpacity(0.7),
          );
      } else {
        // Locked achievement subtle animation
        badge = badge
          .animate(onPlay: (controller) => controller.repeat())
          .fadeIn(duration: 300.ms)
          .then(delay: 2.seconds)
          .shimmer(
            duration: 1.seconds,
            color: Colors.white.withOpacity(0.3),
          );
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: badge,
    );
  }

  // Helper to convert string icon names to IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'explore':
        return Icons.explore;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'emoji_emotions':
        return Icons.emoji_emotions;
      case 'hiking':
        return Icons.hiking;
      default:
        return Icons.stars;
    }
  }
} 
 
 
 