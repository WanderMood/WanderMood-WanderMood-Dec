import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/gyg_link.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/l10n/app_localizations.dart';

const String _appLink = 'https://gyg.me/edviennemerencia-app';
const String _promoCode = 'EDVIENNEMERENCIA5';

/// Background image for Edvienne's Picks card (My Day style).
/// Falls back to asset if network fails.
const String _cardBackgroundImageUrl =
    'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&h=600&fit=crop&auto=format'; // Rotterdam / travel
const String _cardBackgroundImage = 'assets/images/fallbacks/park.jpg';

/// Allowed category types for dynamic chips (only render if present in links).
const Set<String> _allowedCategoryTypes = {
  'food',
  'boat',
  'culture',
  'luxury',
  'adventure',
};

/// Type-to-display mapping for GYG link pills.
const Map<String, String> _typeLabels = {
  'food': '🍴 Food & drink',
  'boat': '⛵ Boat tours',
  'culture': '🎭 Culture',
  'adventure': '🧗 Adventure',
  'luxury': '✨ Luxury',
};

/// Curated "Edvienne's Picks" section with GetYourGuide links for booking activities.
/// Renders below category chips on the Explore screen.
class BookWithGygSection extends StatelessWidget {
  const BookWithGygSection({
    super.key,
    required this.cityName,
    required this.links,
    this.compactForMap = false,
  });

  final String cityName;
  final List<GygLink> links;

  /// On Explore map: slim CTA above the floating nav; full card opens in a sheet.
  final bool compactForMap;

  @override
  Widget build(BuildContext context) {
    final displayCity = _capitalizeCity(cityName);
    final allLink = links.where((l) => l.type == 'all').firstOrNull;
    final categoryLinks =
        links.where((l) => _allowedCategoryTypes.contains(l.type)).toList();

    if (compactForMap) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _buildMapCompactBar(context, displayCity),
      );
    }

    return Padding(
      // 16 matches Explore list / day plan horizontal insets
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (links.isEmpty) ...[
            _buildComingSoonCard(context, displayCity),
          ] else ...[
            if (allLink != null)
              _buildPrimaryCard(context, displayCity, allLink),
            if (categoryLinks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCategoryChips(context, categoryLinks),
            ],
          ],
          const SizedBox(height: 8),
          _buildPoweredByLabel(context),
        ],
      ),
    );
  }

  Widget _buildMapCompactBar(BuildContext context, String displayCity) {
    void openSheet() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.58,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) {
              return DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F0E8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          BookWithGygSection(
                            cityName: cityName,
                            links: links,
                            compactForMap: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    if (links.isEmpty) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: openSheet,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.explore_outlined, color: Colors.grey[700], size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Edvienne\'s Picks — $displayCity',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_up, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: openSheet,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E1C18),
                const Color(0xFF2A6049).withOpacity(0.92),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.local_activity_outlined,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edvienne\'s Picks in $displayCity',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tik om GYG & korting te openen',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.unfold_more,
                  color: Colors.white.withOpacity(0.9), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalizeCity(String city) {
    if (city.isEmpty) return city;
    return city[0].toUpperCase() + city.substring(1).toLowerCase();
  }

  Widget _buildComingSoonCard(BuildContext context, String displayCity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Edvienne\'s Picks in $displayCity',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ik ben nog aan het ontdekken wat hier moet 🤍',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCard(
    BuildContext context,
    String displayCity,
    GygLink allLink,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFF2A6049).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background image (My Day style)
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.1),
                  BlendMode.multiply,
                ),
                child: CachedNetworkImage(
                  imageUrl: _cardBackgroundImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Image.asset(
                    _cardBackgroundImage,
                    fit: BoxFit.cover,
                  ),
                  errorWidget: (_, __, ___) => Image.asset(
                    _cardBackgroundImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Dark gradient overlay (like Free Time Activities cards)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.2, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ Edvienne\'s Picks in $displayCity',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dit zou ik zelf boeken als ik hier 48 uur was 🤍',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Primary: Open in app (met korting)
                  GestureDetector(
                    onTap: () => _launchUrl(_appLink),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A6049),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Open in GYG app (met korting)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Secondary: Open in web
                  GestureDetector(
                    onTap: () => _launchUrl(allLink.url),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        'Open in web',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Discount row (dark pill for contrast)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🎁 Klein extraatje van mij: $_promoCode',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Alleen geldig in de GetYourGuide app.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                const ClipboardData(text: _promoCode));
                            showWanderMoodToast(
                              context,
                              message: AppLocalizations.of(context)!.gygCodeCopied,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A6049).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Kopieer',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildCategoryChips(BuildContext context, List<GygLink> links) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: links.map((link) {
        final label = _typeLabels[link.type] ?? link.type;
        return GestureDetector(
          onTap: () => _launchUrl(link.url),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFF2A6049).withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPoweredByLabel(BuildContext context) {
    // v2: discrete caption footer (Explore SCREEN 6)
    const wmStone = Color(0xFF8C8780);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Powered by GetYourGuide',
        style: GoogleFonts.poppins(
          fontSize: 11,
          height: 1.3,
          color: wmStone,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (url.isEmpty) return;
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('GYG: Could not launch URL: $url');
      }
    } catch (e) {
      debugPrint('GYG: Error launching URL: $e');
    }
  }
}
