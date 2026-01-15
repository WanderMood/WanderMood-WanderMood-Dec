import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';

class SettingsScreenTemplate extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;
  final bool danger;

  const SettingsScreenTemplate({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
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
