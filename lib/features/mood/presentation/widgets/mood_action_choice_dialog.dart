import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dialog that appears after mood selection
/// Lets user choose between updating their plan or just changing their mood
class MoodActionChoiceDialog extends StatefulWidget {
  final VoidCallback onUpdatePlan;
  final VoidCallback onJustChangeMood;

  const MoodActionChoiceDialog({
    super.key,
    required this.onUpdatePlan,
    required this.onJustChangeMood,
  });

  @override
  State<MoodActionChoiceDialog> createState() => _MoodActionChoiceDialogState();
}

class _MoodActionChoiceDialogState extends State<MoodActionChoiceDialog> {
  String _selectedOption = 'update'; // 'update' or 'mood'

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Text(
                  '✨',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'What would you like to do?',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A202C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Option 1: Update plan
            _buildOptionCard(
              isSelected: _selectedOption == 'update',
              emoji: '📅',
              title: 'Update today\'s plan',
              subtitle: 'Get new activity suggestions based on your mood',
              value: 'update',
            ),
            const SizedBox(height: 12),

            // Option 2: Just change mood
            _buildOptionCard(
              isSelected: _selectedOption == 'mood',
              emoji: '🎭',
              title: 'Just change my mood',
              subtitle: 'Update your vibe without changing activities',
              value: 'mood',
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (_selectedOption == 'update') {
                        widget.onUpdatePlan();
                      } else {
                        widget.onJustChangeMood();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12B347),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
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
    );
  }

  Widget _buildOptionCard({
    required bool isSelected,
    required String emoji,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF12B347).withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF12B347) : Colors.grey[200]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF12B347) : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF12B347) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Emoji
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            // Text content
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
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF4A5568),
                    ),
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

