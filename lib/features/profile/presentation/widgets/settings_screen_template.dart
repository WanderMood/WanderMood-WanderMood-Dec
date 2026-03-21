import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';

/// WanderMood v2 settings chrome (cream canvas, white header, parchment hairline).
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);

class SettingsScreenTemplate extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;
  final bool danger;

  /// When true, uses v2 cream background and header (no swirl). Other settings
  /// screens keep the legacy swirl template until migrated.
  final bool wanderMoodV2Chrome;

  const SettingsScreenTemplate({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    this.danger = false,
    this.wanderMoodV2Chrome = false,
  });

  @override
  Widget build(BuildContext context) {
    if (wanderMoodV2Chrome) {
      return Scaffold(
        backgroundColor: _wmCream,
        body: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: _wmWhite,
                border: Border(
                  bottom: BorderSide(color: _wmParchment, width: 0.5),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 4,
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: _wmDusk, size: 20),
                        onPressed: onBack,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: danger ? const Color(0xFFDC2626) : _wmCharcoal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SwirlBackground(
        child: Column(
          children: [
            // Header - white background, border-bottom, sticky
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 4,
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF374151), size: 20), // gray-600
                        onPressed: onBack,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: danger
                                ? const Color(0xFFDC2626) // red-600
                                : const Color(0xFF1F2937), // gray-800
                          ),
                        ),
                      ),
                      const SizedBox(width: 44), // Empty space on right
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)), // border-gray-200
            
            // Body
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
