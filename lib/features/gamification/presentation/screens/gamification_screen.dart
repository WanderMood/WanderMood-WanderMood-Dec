import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import '../../domain/models/achievement.dart';
import '../../domain/models/achievement_titles.dart';
import '../../providers/gamification_provider.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/streak_card.dart';

// Fallback providers in case SharedPreferences is not available
final fallbackGamificationStateProvider = Provider<GamificationState>((ref) {
  return GamificationState();
});

class GamificationScreen extends ConsumerStatefulWidget {
  const GamificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends ConsumerState<GamificationScreen> {
  bool _isStreakExpanded = false;
  Achievement? _selectedAchievement;

  @override
  Widget build(BuildContext context) {
    // Try to use gamificationProvider, with fallback if it fails
    GamificationState gamificationState;
    try {
      gamificationState = ref.watch(gamificationProvider);
    } catch (e) {
      // If provider fails, use fallback
      print('Error accessing gamification provider: $e');
      gamificationState = ref.watch(fallbackGamificationStateProvider);
    }
    
    final achievements = gamificationState.achievements;
    
    // Group achievements by category
    final Map<AchievementCategory, List<Achievement>> groupedAchievements = {};
    
    for (final achievement in achievements) {
      if (!groupedAchievements.containsKey(achievement.category)) {
        groupedAchievements[achievement.category] = [];
      }
      groupedAchievements[achievement.category]!.add(achievement);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.gamificationTitle,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak Card
                StreakCard(
                  isExpanded: _isStreakExpanded,
                  onTap: () {
                    setState(() {
                      _isStreakExpanded = !_isStreakExpanded;
                    });
                  },
                ),
                
                // Progress Overview
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.gamificationYourProgress,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.gamificationCompleteToUnlock,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Progress Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildProgressStat(
                            achievements.where((a) => a.unlocked).length,
                            achievements.length,
                            AppLocalizations.of(context)!.gamificationUnlocked,
                            Colors.green,
                          ),
                          _buildProgressStat(
                            achievements.where((a) => a.progress > 0 && !a.unlocked).length,
                            achievements.length,
                            AppLocalizations.of(context)!.gamificationInProgress,
                            Colors.orange,
                          ),
                          _buildProgressStat(
                            achievements.where((a) => a.progress == 0).length,
                            achievements.length,
                            AppLocalizations.of(context)!.gamificationLocked,
                            Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Achievement Sections by Category
                ...groupedAchievements.entries.map((entry) {
                  return _buildAchievementCategory(
                    entry.key,
                    entry.value,
                  );
                }),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
          
          // Achievement Detail Modal
          if (_selectedAchievement != null)
            _buildAchievementDetailModal(_selectedAchievement!),
        ],
      ),
    );
  }
  
  Widget _buildProgressStat(int value, int total, String label, Color color) {
    final percentage = total > 0 ? (value / total * 100).round() : 0;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: total > 0 ? value / total : 0,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAchievementCategory(
    AchievementCategory category,
    List<Achievement> achievements,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            _getCategoryName(category),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AchievementBadge(
                  achievement: achievement,
                  showAnimation: achievement.unlocked,
                  onTap: () {
                    setState(() {
                      _selectedAchievement = achievement;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildAchievementDetailModal(Achievement achievement) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAchievement = null;
        });
      },
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {}, // Prevent tap through
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge
                AchievementBadge(
                  achievement: achievement,
                  showAnimation: achievement.unlocked,
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  achievementTitleForId(achievement.id, l10n),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  achievement.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Progress bar for locked achievements
                if (!achievement.unlocked)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: achievement.progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.color,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${achievement.currentValue} / ${achievement.requiredValue}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                
                // Unlock date for unlocked achievements
                if (achievement.unlocked && achievement.unlockedAt != null)
                  Text(
                    AppLocalizations.of(context)!.gamificationUnlockedOn(_formatDate(achievement.unlockedAt!)),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Close button
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedAchievement = null;
                    });
                  },
                  child: Text(
                    AppLocalizations.of(context)!.gamificationClose,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().scale(
            duration: 200.ms,
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );
  }
  
  String _getCategoryName(AchievementCategory category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case AchievementCategory.exploration:
        return l10n.gamificationCategoryExploration;
      case AchievementCategory.activity:
        return l10n.gamificationCategoryActivities;
      case AchievementCategory.social:
        return l10n.gamificationCategorySocial;
      case AchievementCategory.streak:
        return l10n.gamificationCategoryStreaks;
      case AchievementCategory.mood:
        return l10n.gamificationCategoryMood;
      case AchievementCategory.special:
        return l10n.gamificationCategorySpecial;
      default:
        return l10n.gamificationCategoryOther;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 
 
 
 