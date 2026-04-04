import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wandermood/core/cache/wandermood_image_cache_manager.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/mood/presentation/widgets/activity_rating_sheet.dart';
import 'dart:math' as math;
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class PeriodActivitiesBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> period;
  final List<EnhancedActivityData> activities;
  final String currentMood;
  final Function(BuildContext, {String? contextualGreeting}) showChatCallback;

  const PeriodActivitiesBottomSheet({
    super.key,
    required this.period,
    required this.activities,
    required this.currentMood,
    required this.showChatCallback,
  });

  @override
  ConsumerState<PeriodActivitiesBottomSheet> createState() => _PeriodActivitiesBottomSheetState();
}

class _PeriodActivitiesBottomSheetState extends ConsumerState<PeriodActivitiesBottomSheet> 
    with SingleTickerProviderStateMixin {
  bool _showingSuggestions = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // Complete activity and show rating sheet
  Future<void> _completeAndRateActivity(EnhancedActivityData activity) async {
    final activityName = activity.rawData['name'] as String? ?? 
                        activity.rawData['title'] as String? ?? 
                        'Activity';
    final location = activity.rawData['location'] as String?;
    final activityId = activity.rawData['id']?.toString() ?? MoodyClock.now().toString();

    // Show rating sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityRatingSheet(
        activityId: activityId,
        activityName: activityName,
        placeName: location,
        currentMood: widget.currentMood,
        onRated: () {
          showWanderMoodToast(
            context,
            message: '$activityName completed! 🎉',
            backgroundColor: const Color(0xFF2A6049),
          );
        },
      ),
    );
  }

  // Get time-based gradient colors
  List<Color> _getPeriodGradient() {
    final periodLabel = widget.period['label'] as String;
    if (periodLabel.contains('Morning')) {
      return [
        const Color(0xFFFFF3E0), // Warm sunrise orange
        const Color(0xFFFFE0B2),
      ];
    } else if (periodLabel.contains('Afternoon')) {
      return [
        const Color(0xFFF3E5F5), // Soft purple
        const Color(0xFFE1BEE7),
      ];
    } else if (periodLabel.contains('Evening')) {
      return [
        const Color(0xFFE3F2FD), // Twilight blue
        const Color(0xFFBBDEFB),
      ];
    } else {
      return [
        const Color(0xFFE8EAF6), // Night indigo
        const Color(0xFFC5CAE9),
      ];
    }
  }

  // Get Moody's commentary based on the schedule
  String _getMoodyCommentary() {
    final periodLabel = widget.period['label'] as String;
    final count = widget.activities.length;

    if (count == 0) {
      final random = math.Random();
      final emptyMessages = [
        "Your $periodLabel is a blank canvas! 🎨 What adventure should we paint?",
        "Nothing planned yet? Perfect time for spontaneity! ✨",
        "An open $periodLabel means endless possibilities! 🌟",
        "Let's fill this time with something amazing! 🚀",
      ];
      return emptyMessages[random.nextInt(emptyMessages.length)];
    } else if (count == 1) {
      return "You've got one great thing lined up! Want to add more? 🌈";
    } else if (count == 2) {
      return "Two activities - nice balance! You've got room for more if you want 😊";
    } else if (count >= 3) {
      return "Your $periodLabel is packed! Make sure to leave breathing room 🌺";
    }
    return "Looking good! Let's make this $periodLabel unforgettable 💫";
  }

  // Get activity accent color based on time
  Color _getActivityAccentColor() {
    final periodLabel = widget.period['label'] as String;
    if (periodLabel.contains('Morning')) {
      return const Color(0xFFFF9800); // Orange
    } else if (periodLabel.contains('Afternoon')) {
      return const Color(0xFF9C27B0); // Purple
    } else if (periodLabel.contains('Evening')) {
      return const Color(0xFF2196F3); // Blue
    } else {
      return const Color(0xFF3F51B5); // Indigo
    }
  }

  void _toggleSuggestions() {
    setState(() {
      _showingSuggestions = !_showingSuggestions;
      if (_showingSuggestions) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.period['label'] as String;
    final activityCount = widget.activities.length;
    final gradientColors = _getPeriodGradient();
    final accentColor = _getActivityAccentColor();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gradientColors[0],
            gradientColors[1],
            Colors.white,
          ],
          stops: const [0.0, 0.3, 0.6],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header with Moody's commentary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: accentColor.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.period['emoji'] as String,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A202C),
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                '$activityCount ${activityCount == 1 ? 'activity' : 'activities'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: accentColor.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: accentColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Moody's commentary card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentColor.withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text('💭', style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getMoodyCommentary(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF4A5568),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Activities list
              Expanded(
                child: widget.activities.isEmpty
                    ? _buildEmptyState(label, accentColor)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: widget.activities.length,
                        itemBuilder: (context, index) {
                          return _buildActivityCard(
                            widget.activities[index],
                            accentColor,
                          );
                        },
                      ),
              ),
              
              // Action buttons
              _buildActionButtons(label, accentColor),
            ],
          ),
          
          // Suggestions overlay (slides from right)
          if (_showingSuggestions)
            SlideTransition(
              position: _slideAnimation,
              child: _buildSuggestionsPanel(label, accentColor),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String label, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  '✨',
                  style: const TextStyle(fontSize: 56),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your $label awaits!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Nothing planned yet, but that's okay!\nLet's find something perfect for your vibe",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF718096),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEmptyStateAction(
                  icon: Icons.explore,
                  label: 'Explore',
                  color: const Color(0xFF2A6049),
                  onTap: () {
                    // TODO: Navigate to explore
                  },
                ),
                const SizedBox(width: 16),
                _buildEmptyStateAction(
                  icon: Icons.auto_awesome,
                  label: 'Surprise me',
                  color: accentColor,
                  onTap: _toggleSuggestions,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(EnhancedActivityData activity, Color accentColor) {
    final l10n = AppLocalizations.of(context)!;
    final activityName = activity.rawData['name'] as String? ?? activity.rawData['title'] as String? ?? 'Activity';
    final location = activity.rawData['location'] as String?;
    final imageUrl = activity.rawData['imageUrl'] as String? ?? activity.rawData['image'] as String?;
    final isCompleted = activity.status == ActivityStatus.completed;

    return Dismissible(
      key: Key(activity.rawData['id']?.toString() ?? MoodyClock.now().toString()),
      background: _buildSwipeBackground(
        color: const Color(0xFF2A6049),
        icon: Icons.check_circle,
        label: l10n.periodActivitiesSwipeComplete,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: const Color(0xFFE53E3E),
        icon: Icons.delete,
        label: l10n.periodActivitiesSwipeDelete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mark as complete and show rating sheet
          await _completeAndRateActivity(activity);
          return false;
        } else {
          // Delete
          return await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              final dlg = AppLocalizations.of(dialogContext)!;
              return AlertDialog(
                title: Text(dlg.periodActivitiesRemoveTitle, style: GoogleFonts.poppins()),
                content: Text(
                  dlg.periodActivitiesRemoveBody(activityName),
                  style: GoogleFonts.poppins(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(dlg.cancel, style: GoogleFonts.poppins()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(
                      dlg.periodActivitiesRemoveCta,
                      style: GoogleFonts.poppins(color: const Color(0xFFE53E3E)),
                    ),
                  ),
                ],
              );
            },
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              blurRadius: 10,
              spreadRadius: -5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              // Image or time badge
              if (imageUrl != null)
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        cacheManager: WanderMoodImageCacheManager.instance,
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: accentColor.withOpacity(0.1),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: accentColor.withOpacity(0.1),
                          child: Icon(Icons.image, color: accentColor.withOpacity(0.3)),
                        ),
                      ),
                      // Time overlay
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activity.startTime != null
                                ? '${activity.startTime!.hour.toString().padLeft(2, '0')}:${activity.startTime!.minute.toString().padLeft(2, '0')}'
                                : '—',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 100,
                  color: accentColor.withOpacity(0.1),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, color: accentColor, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          activity.startTime != null
                              ? '${activity.startTime!.hour.toString().padLeft(2, '0')}:${activity.startTime!.minute.toString().padLeft(2, '0')}'
                              : '—',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Activity details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activityName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A202C),
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (location != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: const Color(0xFF718096),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF718096),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Swipe hint
                      Text(
                        '← Swipe to complete or delete →',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: accentColor.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Status indicator
              Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: isCompleted ? const Color(0xFF2A6049) : const Color(0xFFCBD5E0),
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ] else ...[
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 28),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary action - Show suggestions
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleSuggestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showingSuggestions ? Icons.close : Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _showingSuggestions ? 'Close suggestions' : 'Show me suggestions',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary action - Chat with Moody
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.showChatCallback(
                  context,
                  contextualGreeting: "Help me plan my $label! I'm feeling ${widget.currentMood} 🌟",
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accentColor.withOpacity(0.5), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, color: accentColor, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.myDayChatWithMoodyTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsPanel(String label, Color accentColor) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withOpacity(0.1), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: accentColor),
                  onPressed: _toggleSuggestions,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perfect for your $label',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A202C),
                        ),
                      ),
                      Text(
                        'Based on your ${widget.currentMood} mood',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Suggestions content - placeholder for now
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_awesome,
                          size: 56,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Let\'s chat with Moody!',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A202C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Moody knows exactly what you need for\nyour ${widget.currentMood} vibe! 🌟",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF718096),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.showChatCallback(
                          context,
                          contextualGreeting: "Help me find the perfect activities for my $label! I'm feeling ${widget.currentMood} today 🌟",
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.chat_bubble, color: Colors.white),
                      label: Text(
                        'Start chatting',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

