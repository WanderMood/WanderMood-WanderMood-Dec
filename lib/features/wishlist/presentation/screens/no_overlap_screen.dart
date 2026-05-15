import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_met_vriend_navigation.dart';

const _wmCream = Color(0xFFF5F0E8);
const _wmForest = Color(0xFF2A6049);
const _wmCharcoal = Color(0xFF1A1714);
const _wmMuted = Color(0x8C1A1714);

class NoOverlapScreen extends StatelessWidget {
  const NoOverlapScreen({super.key, required this.args});

  final PlanMetVriendNoOverlapArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _wmCream,
      appBar: AppBar(
        backgroundColor: _wmCream,
        elevation: 0,
        iconTheme: const IconThemeData(color: _wmCharcoal),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.event_busy, size: 56, color: _wmForest),
            const SizedBox(height: 20),
            Text(
              'Geen overlap',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _wmCharcoal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Jullie beschikbaarheid overlapt niet voor ${args.place.placeName}. '
              'Kies nieuwe data of plan met iemand anders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: _wmMuted,
                height: 1.45,
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
                openAvailabilityPicker(
                  context,
                  friend: args.friend,
                  place: args.place,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _wmForest,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Probeer andere data',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: Text(
                'Kies andere vriend',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _wmForest,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
