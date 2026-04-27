part of 'explore_screen.dart';

/// Suggestion / outline chip rows (advanced filters).
extension _ExploreAfSuggestionOutline on _ExploreScreenState {
  Widget _buildSuggestionChip(
      String emoji, String label, bool value, Function(bool)? onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged != null
            ? () {
                HapticFeedback.lightImpact();
                onChanged(!value);
              }
            : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF2A6049) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: value ? const Color(0xFF2A6049) : Colors.grey[300]!,
              width: value ? 2 : 1,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 3,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                    color: value ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChipWithCallback(
      String emoji, String label, bool value, VoidCallback? onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF2A6049) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: value ? const Color(0xFF2A6049) : Colors.grey[300]!,
              width: value ? 2 : 1,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 3,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                    color: value ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(
      String emoji, String label, bool value, Function(bool) onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(!value);
        },
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF2A6049) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: value ? const Color(0xFF2A6049) : Colors.grey[300]!,
              width: value ? 2.5 : 1.5,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 2,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                  color: value ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButtonWithCallback(
      String emoji, String label, bool value, VoidCallback? onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF2A6049) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: value ? const Color(0xFF2A6049) : Colors.grey[300]!,
              width: value ? 2.5 : 1.5,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 2,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                  color: value ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
