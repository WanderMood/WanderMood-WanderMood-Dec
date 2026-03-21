import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/activity_rating.dart';
import '../../services/activity_rating_service.dart';
import 'package:uuid/uuid.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class ActivityRatingSheet extends ConsumerStatefulWidget {
  final String activityId;
  final String activityName;
  final String? placeName;
  final String currentMood;
  final VoidCallback? onRated;

  const ActivityRatingSheet({
    super.key,
    required this.activityId,
    required this.activityName,
    this.placeName,
    required this.currentMood,
    this.onRated,
  });

  @override
  ConsumerState<ActivityRatingSheet> createState() => _ActivityRatingSheetState();
}

class _ActivityRatingSheetState extends ConsumerState<ActivityRatingSheet>
    with SingleTickerProviderStateMixin {
  int _stars = 0;
  final Set<String> _selectedTags = {};
  bool _wouldRecommend = false;
  final TextEditingController _notesController = TextEditingController();
  late AnimationController _animationController;

  final List<String> _availableTags = [
    '✨ The vibe',
    '🍽️ The food',
    '👥 The people',
    '📍 The location',
    '💰 The value',
    '🎯 The activity',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
            Colors.pink.shade50,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildStarRating(),
                if (_stars > 0) ...[
                  const SizedBox(height: 32),
                  _buildTagSelection(),
                  const SizedBox(height: 24),
                  _buildRecommendToggle(),
                  const SizedBox(height: 24),
                  _buildNotesInput(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'How was it?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.activityName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.purple.shade700,
          ),
        ),
        if (widget.placeName != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                widget.placeName!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStarRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rate your experience',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _stars = starNumber;
                });
                _animationController.forward(from: 0);
              },
              child: AnimatedScale(
                scale: _stars >= starNumber ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    _stars >= starNumber ? Icons.star : Icons.star_border,
                    size: 48,
                    color: _stars >= starNumber
                        ? Colors.amber.shade400
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }),
        ),
        if (_stars > 0) ...[
          const SizedBox(height: 12),
          Center(
            child: Text(
              _getStarLabel(_stars),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getStarLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Not great 😕';
      case 2:
        return 'Could be better 🤔';
      case 3:
        return 'It was okay 😊';
      case 4:
        return 'Really good! 😄';
      case 5:
        return 'Absolutely loved it! 🤩';
      default:
        return '';
    }
  }

  Widget _buildTagSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What did you love?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [Colors.purple.shade400, Colors.pink.shade400],
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.purple.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _wouldRecommend = !_wouldRecommend;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _wouldRecommend ? Colors.purple.shade300 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _wouldRecommend ? Icons.check_circle : Icons.circle_outlined,
              color: _wouldRecommend ? Colors.purple.shade600 : Colors.grey.shade400,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'I\'d recommend this to friends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _wouldRecommend ? Colors.purple.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Any thoughts? (optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Share your experience...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitRating,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ).copyWith(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.pink.shade500],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 56),
            child: const Text(
              'Submit Rating ✨',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitRating() async {
    if (_stars == 0) {
      showWanderMoodToast(
        context,
        message: 'Please select a star rating',
        isError: true,
      );
      return;
    }

    final ratingService = ref.read(activityRatingServiceProvider);
    final rating = ActivityRating(
      id: const Uuid().v4(),
      userId: 'current_user', // TODO: Get from auth
      activityId: widget.activityId,
      activityName: widget.activityName,
      placeName: widget.placeName,
      stars: _stars,
      tags: _selectedTags.toList(),
      wouldRecommend: _wouldRecommend,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      completedAt: DateTime.now(),
      mood: widget.currentMood,
    );

    await ratingService.saveRating(rating);

    if (!mounted) return;
    
    Navigator.pop(context);
    widget.onRated?.call();

    // Show success message
    showWanderMoodToast(
      context,
      message: 'Thanks for rating! 🎉',
      backgroundColor: Colors.purple.shade600,
    );
  }
}

