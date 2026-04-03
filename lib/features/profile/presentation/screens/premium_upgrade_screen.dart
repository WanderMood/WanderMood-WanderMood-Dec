import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// App Store–safe screen: no simulated payments, no Stripe/card/Apple Pay flows.
/// Premium will ship later with real In-App Purchase + restore.
const Color _puWmCream = Color(0xFFF5F0E8);
const Color _puWmParchment = Color(0xFFE8E2D8);
const Color _puWmCharcoal = Color(0xFF1E1C18);
const Color _puWmForest = Color(0xFF2A6049);
const Color _puWmForestDeep = Color(0xFF1E4A3A);
const Color _puWmForestTint = Color(0xFFEBF3EE);

class PremiumUpgradeScreen extends StatelessWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _puWmCream,
      appBar: AppBar(
        backgroundColor: _puWmCream,
        elevation: 0,
        foregroundColor: _puWmCharcoal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.premiumUpgradeScreenTitle,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _puWmCharcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_puWmForest, _puWmForestDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _puWmParchment, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.premiumComingSoonTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.premiumComingSoonBody,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _puWmForestTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _puWmForest.withValues(alpha: 0.28)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: _puWmForest, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.premiumComingSoonFootnote,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.4,
                      color: _puWmForest,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _puWmForest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.premiumComingSoonCta,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
