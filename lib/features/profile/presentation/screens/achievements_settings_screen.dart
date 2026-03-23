import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../gamification/providers/gamification_provider.dart';
import '../../../gamification/domain/models/achievement.dart';
import '../widgets/settings_screen_template.dart';

const Color _achWmForest = Color(0xFF2A6049);
const Color _achWmForestTint = Color(0xFFEBF3EE);
const Color _achWmParchment = Color(0xFFE8E2D8);

class AchievementsSettingsScreen extends ConsumerWidget {
  const AchievementsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationState = ref.watch(gamificationProvider);
    final achievements = gamificationState.achievements;
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final totalCount = achievements.length;
    final unlockedAchievements = achievements.where((a) => a.unlocked).toList();
    final lockedAchievements = achievements.where((a) => !a.unlocked).toList();
    
    return SettingsScreenTemplate(
      title: 'Achievements',
      onBack: () => context.pop(),
      wanderMoodV2Chrome: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_achWmForestTint, Color(0xFFD4E8DD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _achWmParchment,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: _achWmForest,
                ),
                const SizedBox(height: 12),
                Text(
                  '$unlockedCount / $totalCount',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Achievements Unlocked',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (unlockedAchievements.isNotEmpty) ...[
            Text(
              'Unlocked',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 12),
            ...unlockedAchievements.map((achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAchievementCard(
                    achievement: achievement,
                    unlocked: true,
                  ),
                )),
            const SizedBox(height: 24),
          ],
          if (lockedAchievements.isNotEmpty) ...[
            Text(
              'Locked',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: 0.5,
              child: Column(
                children: lockedAchievements
                    .map((achievement) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAchievementCard(
                            achievement: achievement,
                            unlocked: false,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required Achievement achievement,
    required bool unlocked,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? _achWmForest : _achWmParchment,
          width: unlocked ? 1.0 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: unlocked ? _achWmForestTint : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForAchievement(achievement),
                size: 24,
                color: unlocked ? _achWmForest : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (unlocked)
              const Icon(
                Icons.check,
                color: _achWmForest,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForAchievement(Achievement achievement) {
    final iconMap = {
      'map': Icons.map,
      'heart': Icons.favorite,
      'camera': Icons.camera_alt,
      'plane': Icons.flight,
      'coffee': Icons.local_cafe,
    };
    return iconMap[achievement.icon.toLowerCase()] ?? Icons.star;
  }
}
