import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_screen_template.dart';

const Color _subWmForest = Color(0xFF2A6049);
const Color _subWmForestDeep = Color(0xFF1E4A3A);
const Color _subWmForestTint = Color(0xFFEBF3EE);
const Color _subWmForestTint2 = Color(0xFFD4E8DD);

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return SettingsScreenTemplate(
      title: l10n.subscriptionScreenTitle,
      onBack: () => context.pop(),
      wanderMoodV2Chrome: true,
      child: subscriptionAsync.when(
        data: (subscription) => _buildContent(context, subscription, l10n),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildContent(context, null, l10n),
      ),
    );
  }

  Widget _buildContent(BuildContext context, subscription, AppLocalizations l10n) {
    final isPremium = subscription?.planType == 'premium';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_subWmForestTint, _subWmForestTint2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _subWmForest.withValues(alpha: 0.35),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.subscriptionCurrentPlanLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _subWmForest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPremium ? l10n.subscriptionPlanPremium : l10n.subscriptionPlanFree,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.star,
                size: 48,
                color: _subWmForest,
              ),
            ],
          ),
        ),
        if (!isPremium) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_subWmForest, _subWmForestDeep],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                          l10n.subscriptionUpgradeHeading,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            l10n.subscriptionUpgradeTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.bolt, size: 48, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.subscriptionUpgradeFootnote,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFeature(l10n.subscriptionFeatureUnlimitedSuggestions),
                _buildFeature(l10n.subscriptionFeatureAdvancedMoodMatching),
                _buildFeature(l10n.subscriptionFeaturePrioritySupport),
                _buildFeature(l10n.subscriptionFeatureNoAds),
                _buildFeature(l10n.subscriptionFeatureEarlyAccess),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/settings/premium-upgrade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _subWmForest,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.subscriptionUpgradeCta,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
