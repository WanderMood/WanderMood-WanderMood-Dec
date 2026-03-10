import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/plans/providers/selected_activities_provider.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  final Activity activity;
  /// Optional distance string (e.g. "1.2 km") when opened from Day Plan.
  final String? distanceKm;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    this.distanceKm,
  });

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentImageIndex = 0;
  static const double _imageHeight = 380;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildImageGalleryHeader(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTitleAndRating(),
                    _buildQuickInfoCards(),
                    _buildAboutSection(),
                    _buildHighlightsSection(),
                    _buildLocationSection(),
                  ]),
                ),
              ),
            ],
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// React-style image gallery header: image, gradient, back/save/share, mood match & category badges, photo count.
  Widget _buildImageGalleryHeader() {
    return SliverAppBar(
      expandedHeight: _imageHeight,
      pinned: true,
      backgroundColor: Colors.grey[200],
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: const Icon(Icons.chevron_left, color: Colors.black87, size: 28),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.favorite_border, color: Colors.black87, size: 22),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.share, color: Colors.black87, size: 22),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.activity.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.place, size: 80, color: Colors.grey)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF10B981)]),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      '${85 + (widget.activity.id.hashCode % 15)}% Match',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Text(
                  (widget.activity.tags.isNotEmpty ? widget.activity.tags.first : 'Activity').toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_camera, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('1 photo', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.activity.name,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF111827)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 20, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 4),
                  Text(
                    widget.activity.rating.toStringAsFixed(1),
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Exceptional',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF059669)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.activity.tags.take(4).map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuickInfoCards() {
    final durationText = widget.activity.duration >= 60
        ? '${widget.activity.duration ~/ 60}h'
        : '${widget.activity.duration} min';
    return Row(
      children: [
        Expanded(
          child: _quickInfoCard(
            icon: Icons.schedule,
            label: 'Duration',
            value: durationText,
            color: const Color(0xFFEA580C),
            bgColor: const Color(0xFFFFF7ED),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickInfoCard(
            icon: Icons.euro,
            label: 'Price',
            value: widget.activity.priceLevel ?? '—',
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickInfoCard(
            icon: Icons.location_on,
            label: 'Distance',
            value: widget.distanceKm ?? '—',
            color: const Color(0xFF0284C7),
            bgColor: const Color(0xFFEFF6FF),
          ),
        ),
      ],
    );
  }

  Widget _quickInfoCard({required IconData icon, required String label, required String value, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700])),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        const SizedBox(height: 12),
        Text(
          widget.activity.description,
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF374151), height: 1.5),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildHighlightsSection() {
    final highlights = widget.activity.tags.take(6).map((t) => '• $t').toList();
    if (highlights.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Highlights', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: highlights.map((h) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.3)),
            ),
            child: Text(h, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF374151))),
          )).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFFBFDBFE), Color(0xFFE9D5FF)]),
          ),
          child: const Center(child: Icon(Icons.map, size: 48, color: Colors.white54)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 22, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFormattedAddress(),
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _openDirections(context),
                      child: Text('Get Directions →', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  void _openDirections(BuildContext context) {
    final lat = widget.activity.location.latitude;
    final lng = widget.activity.location.longitude;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('From', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                Text(
                  widget.activity.priceLevel ?? '—',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF111827)),
                ),
                Text('per person', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _openDirections(context),
              icon: const Icon(Icons.directions, size: 20),
              label: const Text('Directions'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF374151),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF6366F1)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🗓️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text('Book Now', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    if (widget.activity.priceLevel == null) {
      return const SizedBox(); // Don't show anything if no price info
    }
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDF5),
            Color(0xFFFFF8E1),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildInfoChip(Icons.euro, widget.activity.priceLevel!, '💰'),
        ],
      ),
    );
  }



  Widget _buildInfoChip(IconData icon, String text, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeIcon() {
    switch (widget.activity.timeSlot.toLowerCase()) {
      case 'morning':
        return '🌅';
      case 'afternoon':
        return '☀️';
      case 'evening':
        return '🌙';
      default:
        return '⏰';
    }
  }

  Widget _buildActivityNameOverlay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        widget.activity.name,
        style: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            const Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTagOverlays() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: widget.activity.tags.take(2).map((tag) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getTagEmoji(tag),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                tag,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlaceDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 About This Place',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5C6BC0),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getFunDescription(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Experience Highlights',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5C6BC0),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailItem('⭐', 'Rating', '${widget.activity.rating}/5.0 (${_getReviewCount()} reviews)'),
          const SizedBox(height: 8),
          _buildDetailItem('⏰', 'Duration', '${widget.activity.duration} minutes'),
          const SizedBox(height: 8),
          _buildDetailItem('📅', 'Best Time', _getTimeSlotDescription()),
          if (widget.activity.priceLevel != null) ...[
            const SizedBox(height: 8),
            _buildDetailItem('💰', 'Price Level', widget.activity.priceLevel!),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String emoji, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeSlotDescription() {
    switch (widget.activity.timeSlot.toLowerCase()) {
      case 'morning':
        return 'Perfect for starting your day with positive energy! 🌅';
      case 'afternoon':
        return 'Great for a midday adventure and energy boost! ☀️';
      case 'evening':
        return 'Ideal for unwinding and ending the day beautifully! 🌙';
      default:
        return 'Flexible timing - enjoy whenever you feel like it! ⏰';
    }
  }

  String _getReviewCount() {
    // Activity model doesn't have reviewCount field
    // Review count should come from Google Places API when activity is created
    // For now, return "N/A" to avoid showing fake data
    return 'N/A';
  }

  Widget _buildRatingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C6BC0).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            widget.activity.rating.toString(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: '🏠 Overview'),
          Tab(text: '⭐ Reviews'),
          Tab(text: '📸 Gallery'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlaceDescription(),
          const SizedBox(height: 20),
          _buildLocationInfo(),
          const SizedBox(height: 20),
          _buildPlaceDetails(),
          if (_isRestaurantActivity()) ...[
            const SizedBox(height: 20),
            _buildRestaurantMenu(),
          ],
          const SizedBox(height: 20),
          _buildMoodyTips(),
          const SizedBox(height: 150), // Increased space for floating buttons
        ],
      ),
    );
  }

  Widget _buildMoodyTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MoodyCharacter(size: 40, mood: 'happy'),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '💡 Moody\'s Smart Tips',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5C6BC0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildTipItem('🌤️', 'Weather Perfect!', _getWeatherTip()),
                const SizedBox(height: 8),
                _buildTipItem('👕', 'What to Wear', _getOutfitTip()),
                const SizedBox(height: 8),
                _buildTipItem('🎒', 'Don\'t Forget', _getBringTip()),
                const SizedBox(height: 8),
                _buildTipItem('💫', 'Moody Bonus', _getMoodyBonus()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String title, String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5C6BC0),
                ),
              ),
              Text(
                tip,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getWeatherTip() {
    final activityName = widget.activity.name.toLowerCase();
    final timeSlot = widget.activity.timeSlot.toLowerCase();
    final isOutdoor = widget.activity.tags.any((tag) => 
      ['outdoor', 'adventure', 'nature', 'walking', 'cycling'].contains(tag.toLowerCase()));
    
    // Generate weather tip based on activity type and timing
    if (activityName.contains('spa') || activityName.contains('wellness')) {
      return timeSlot == 'morning' 
        ? 'Perfect morning weather for starting your wellness journey with fresh energy! 🌅'
        : 'Great ${timeSlot} weather - perfect for winding down and relaxing indoors! ☁️';
    } else if (activityName.contains('museum') || activityName.contains('gallery')) {
      return 'Any weather is perfect for diving into art and culture! Plus you\'ll stay cozy inside 🎨';
    } else if (activityName.contains('restaurant') || activityName.contains('food') || activityName.contains('café')) {
      return timeSlot == 'evening' 
        ? 'Perfect evening for a delicious dining experience! 🌙🍽️'
        : 'Great weather for enjoying amazing food and good company! ☀️';
    } else if (isOutdoor) {
      return timeSlot == 'morning' 
        ? 'Fresh morning air perfect for outdoor adventures! Crisp and energizing 🌿'
        : 'Beautiful ${timeSlot} weather - ideal for exploring the great outdoors! 🌳';
    } else {
      return 'Weather looks fantastic for this ${widget.activity.name} experience! 🌈';
    }
  }

  String _getOutfitTip() {
    final activityName = widget.activity.name.toLowerCase();
    final timeSlot = widget.activity.timeSlot.toLowerCase();
    final tags = widget.activity.tags.map((tag) => tag.toLowerCase()).toList();
    
    // Specific outfit advice based on activity type and timing
    if (activityName.contains('spa') || activityName.contains('wellness') || tags.contains('wellness')) {
      return timeSlot == 'morning' 
        ? 'Comfortable loose clothing for easy movement. Morning spa calls for zen vibes! 🧘‍♀️'
        : 'Soft, relaxing clothes that make you feel pampered and peaceful 💆‍♀️';
    } else if (activityName.contains('museum') || activityName.contains('gallery') || tags.contains('art')) {
      return timeSlot == 'evening' 
        ? 'Smart casual with comfortable walking shoes - you\'ll want to explore every corner! 👗'
        : 'Comfy chic style perfect for a cultured ${timeSlot} of art appreciation 🎨';
    } else if (activityName.contains('restaurant') || activityName.contains('food') || tags.contains('food')) {
      return timeSlot == 'evening' 
        ? 'Dress up a little - evening dining deserves your favorite outfit! 🌙✨'
        : 'Smart casual that\'s Instagram-ready but still comfortable for eating 📸';
    } else if (activityName.contains('tour') || activityName.contains('walk')) {
      return 'Comfortable walking shoes are ESSENTIAL! Layer up and bring a small backpack 🚶‍♀️';
    } else if (tags.contains('outdoor') || tags.contains('adventure')) {
      return timeSlot == 'morning' 
        ? 'Layer up for morning freshness! Sturdy shoes and weather-ready clothes 🌅'
        : 'Comfortable adventure gear - you might get a little messy and that\'s okay! 🥾';
    } else {
      return timeSlot == 'evening' 
        ? 'Evening elegance meets comfort - dress to feel confident and relaxed! 🌙'
        : 'Casual and comfy ${timeSlot} vibes - dress for maximum enjoyment! 😎';
    }
  }

  String _getBringTip() {
    final activityName = widget.activity.name.toLowerCase();
    final timeSlot = widget.activity.timeSlot.toLowerCase();
    final tags = widget.activity.tags.map((tag) => tag.toLowerCase()).toList();
    final essentials = <String>[];
    
    // Activity-specific essentials
    if (activityName.contains('spa') || activityName.contains('wellness') || tags.contains('wellness')) {
      essentials.addAll(['Hair tie/headband 💇‍♀️', 'Water bottle 💧', 'Phone for relaxation timer ⏰', 'Positive mindset! ✨']);
    } else if (activityName.contains('museum') || activityName.contains('gallery') || tags.contains('art')) {
      essentials.addAll(['Comfortable walking shoes 👟', 'Phone/camera for art pics 📱', 'Curiosity & wonder 🎨', 'Maybe a small notebook 📝']);
    } else if (activityName.contains('restaurant') || activityName.contains('food') || tags.contains('food')) {
      essentials.addAll(['Your biggest appetite! 🍽️', 'Phone for foodie pics 📸', 'Napkins (just in case) 🧻', 'Empty stomach strategy 😋']);
    } else if (activityName.contains('tour') || activityName.contains('walk')) {
      essentials.addAll(['Comfortable walking shoes 👟', 'Water bottle 💧', 'Small snack 🥨', 'Sense of adventure! 🗺️']);
    } else if (tags.contains('outdoor') || tags.contains('adventure')) {
      if (timeSlot == 'morning') {
        essentials.addAll(['Light jacket for morning chill 🧥', 'Water 💧', 'Sunscreen ☀️', 'Energy & excitement! ⚡']);
      } else {
        essentials.addAll(['Sunscreen ☀️', 'Water 💧', 'Hat or cap 🧢', 'Adventure spirit! 🎒']);
      }
    } else {
      // Generic based on time
      if (timeSlot == 'evening') {
        essentials.addAll(['Phone charger 🔌', 'Light jacket 🧥', 'Good vibes only! ✨', 'Ready-for-anything attitude 🌙']);
      } else {
        essentials.addAll(['Your best smile 😊', 'Open mind 🧠', 'Phone for memories 📱', 'Ready-to-explore attitude! 🚀']);
      }
    }
    
    return essentials.join(', ');
  }

  String _getMoodyBonus() {
    final activityName = widget.activity.name.toLowerCase();
    final timeSlot = widget.activity.timeSlot.toLowerCase();
    final tags = widget.activity.tags.map((tag) => tag.toLowerCase()).toList();
    
    // Activity and time-specific bonus tips
    if (activityName.contains('spa') || activityName.contains('wellness') || tags.contains('wellness')) {
      return timeSlot == 'morning' 
        ? 'Morning wellness secret: Set an intention before you begin - watch the magic unfold! 🧘‍♀️✨'
        : 'Spa insider tip: Close your eyes and truly feel every moment of relaxation. You deserve this! 💆‍♀️💫';
    } else if (activityName.contains('museum') || activityName.contains('gallery') || tags.contains('art')) {
      return 'Art lover\'s secret: Talk to a piece that speaks to you - what story does it tell? 🎨💭';
    } else if (activityName.contains('restaurant') || activityName.contains('food') || tags.contains('food')) {
      return timeSlot == 'evening' 
        ? 'Foodie evening magic: Savor the first bite with your eyes closed - taste buds on fire! 🍽️🔥'
        : 'Chef\'s secret: Ask about the story behind your dish - food always tastes better with a story! 👨‍🍳✨';
    } else if (activityName.contains('tour') || activityName.contains('walk')) {
      return 'Explorer\'s tip: Take a moment to look up and around - you\'ll discover hidden gems! 🗺️👀';
    } else if (tags.contains('outdoor') || tags.contains('adventure')) {
      return timeSlot == 'morning' 
        ? 'Morning adventure hack: Take 3 deep breaths of fresh air - instant energy boost! 🌅⚡'
        : 'Adventure secret: The best views come after the challenging moments. Keep going! 🏔️💪';
    } else {
      final genericBonuses = [
        'Moody magic: This ${activityName} experience is 87% more amazing when you\'re fully present! ✨',
        'Pro tip: Take a mental photo of your favorite moment - some memories are too precious for cameras! 📸💭',
        'Secret ingredient: Your curiosity will unlock hidden surprises during this experience! 🔍✨',
        'Insider knowledge: Smile genuinely - it\'s contagious and makes everything better! 😊💫',
        'Fun fact: You\'re creating a story you\'ll love telling later. Make it a good one! 📖🌟',
      ];
      return genericBonuses[widget.activity.name.hashCode.abs() % genericBonuses.length];
    }
  }

  Widget _buildReviewsTab() {
    final reviews = _getRealReviews(); // No mock data - only real reviews
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDF5),
            Color(0xFFFFF8E1),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE0B2), Color(0xFFFFF3E0)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('🗣️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'What Fellow Adventurers Say (${reviews.length} reviews)',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...reviews.map((review) => _buildReviewCard(review)).toList(),
            const SizedBox(height: 150), // Increased space for floating buttons
          ],
        ),
      ),
    );
  }

  Widget _buildImagesTab() {
    // Only return real images - no mock/placeholder images
    final images = [widget.activity.imageUrl].where((url) => url.isNotEmpty).toList();
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDF5),
            Color(0xFFFFF8E1),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE1F5FE), Color(0xFFF3E5F5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('📷', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Instagram-Worthy Moments ✨',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return _buildImageCard(images[index], index);
              },
            ),
            const SizedBox(height: 150), // Increased space for floating buttons
          ],
        ),
      ),
    );
  }

  String _getTagEmoji(String tag) {
    final emojiMap = {
      'Yoga': '🧘‍♀️',
      'Wellness': '💆',
      'Food': '🍽️',
      'Restaurant': '🍴',
      'Spa': '🛁',
      'Outdoor': '🌿',
      'Adventure': '🎢',
      'Relaxing': '😌',
      'Active': '💪',
      'Culture': '🎨',
      'Music': '🎵',
      'Art': '🖼️',
      'Shopping': '🛍️',
      'Nature': '🌳',
    };
    return emojiMap[tag] ?? '✨';
  }



  String _getFunDescription() {
    final originalDesc = widget.activity.description;
    
    if (widget.activity.tags.contains('Yoga') || widget.activity.tags.contains('Wellness')) {
      return '🧘‍♀️ Ready to zen out and find your inner peace? $originalDesc This isn\'t just any yoga class - it\'s your personal journey to feeling absolutely amazing. Expect to stretch those worries away and leave feeling like you can conquer the world! ✨';
    } else if (widget.activity.tags.contains('Food') || widget.activity.tags.contains('Restaurant')) {
      return '🍽️ Calling all food lovers! $originalDesc Get ready for a flavor adventure that\'ll make your taste buds do a happy dance. This place knows how to turn a simple meal into an unforgettable experience. Pro tip: Come hungry, leave happy! 😋';
    } else if (widget.activity.tags.contains('Adventure') || widget.activity.tags.contains('Outdoor')) {
      return '🎢 Adventure seekers, this one\'s for you! $originalDesc Whether you\'re an adrenaline junkie or just want to try something new, this experience promises thrills, laughs, and stories you\'ll be telling for years. Ready to step out of your comfort zone? 🚀';
    } else {
      return '✨ $originalDesc This isn\'t just another activity - it\'s your chance to create those perfect "I can\'t believe I did that!" moments. Come with an open mind and leave with a full heart and probably some great photos too! 📸';
    }
  }

  Widget _buildLocationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📍', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Find Your Adventure',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🗺️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.activity.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '📍 ${_getFormattedAddress()}\n🧭 Perfect for navigation apps!',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color((review['author'].hashCode & 0xFFFFFF) | 0xFF000000),
                      Color((review['author'].hashCode & 0xFFFFFF) | 0xFF000000).withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review['author'][0],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['author'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) => Text(
                          index < review['rating'] ? '⭐' : '☆',
                          style: const TextStyle(fontSize: 14),
                        )),
                        const SizedBox(width: 8),
                        Text(
                          review['date'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['text'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String imageUrl, int index) {
    return GestureDetector(
      onTap: () => _showImageViewer(imageUrl, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📷', style: TextStyle(fontSize: 30)),
                          SizedBox(height: 4),
                          Text('Tap to view', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C6BC0)),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '📱',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageViewer(String imageUrl, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📷', style: TextStyle(fontSize: 50, color: Colors.white)),
                      SizedBox(height: 16),
                      Text(
                        'Oops! Image not available',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fetch real reviews from Google Places API
  // Returns empty list if no reviews available (no mock data)
  List<Map<String, dynamic>> _getRealReviews() {
    // Reviews should come from the Activity's place data
    // If activity has a placeId, fetch reviews from Google Places API
    // For now, return empty - reviews will be fetched when place detail is available
    return [];
  }

  // Removed _generateMockImages() - no mock images
  // Only real images from activity data

  Widget _buildFloatingButtons() {
    final isAddedToPlan = ref.watch(selectedActivitiesProvider).contains(widget.activity.id);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton.extended(
          heroTag: "directions_${widget.activity.id}",
          onPressed: () => _openDirections(context),
          backgroundColor: const Color(0xFF5C6BC0),
          foregroundColor: Colors.white,
          icon: const Text('🧭', style: TextStyle(fontSize: 18)),
          label: Text(
            'Get Directions',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
        FloatingActionButton.extended(
          heroTag: "add_to_plan_${widget.activity.id}",
          onPressed: _addToPlan,
          backgroundColor: isAddedToPlan ? Colors.orange[600] : Colors.green[600],
          foregroundColor: Colors.white,
          icon: Text(
            isAddedToPlan ? '✓' : '➕', 
            style: const TextStyle(fontSize: 18)
          ),
          label: Text(
            isAddedToPlan ? 'Added to Plan' : 'Add to Plan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _addToPlan() {
    final selectedActivities = ref.read(selectedActivitiesProvider.notifier);
    selectedActivities.toggleActivity(widget.activity.id);
    
    final isAdded = ref.read(selectedActivitiesProvider).contains(widget.activity.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(isAdded ? '🎉' : '➖', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAdded 
                  ? '${widget.activity.name} added to your epic adventure plan!'
                  : '${widget.activity.name} removed from your plan',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        backgroundColor: isAdded ? Colors.green[600] : Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('😅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _getFormattedAddress() {
    // Address should come from Google Places API when activity is created
    // If no address available, show coordinates instead of fake address
    final lat = widget.activity.location.latitude;
    final lng = widget.activity.location.longitude;
    
    // Return coordinates if address not available (no mock addresses)
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  // Removed _getStreetName() - no mock street names
  // Address should come from Google Places API

  bool _isRestaurantActivity() {
    final activityName = widget.activity.name.toLowerCase();
    final tags = widget.activity.tags.map((tag) => tag.toLowerCase()).toList();
    
    return activityName.contains('restaurant') || 
           activityName.contains('café') || 
           activityName.contains('bistro') || 
           activityName.contains('diner') || 
           activityName.contains('eatery') ||
           activityName.contains('kitchen') ||
           activityName.contains('grill') ||
           tags.contains('food') || 
           tags.contains('restaurant') ||
           tags.contains('dining') ||
           tags.contains('cuisine');
  }

  Widget _buildRestaurantMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFE0B2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_getCuisineType()} Menu Highlights',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5C6BC0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCuisineInfo(),
          const SizedBox(height: 12),
          _buildMenuItems(),
          const SizedBox(height: 12),
          _buildDietaryInfo(),
        ],
      ),
    );
  }

  String _getCuisineType() {
    final activityName = widget.activity.name.toLowerCase();
    
    if (activityName.contains('pizza') || activityName.contains('italian')) {
      return 'Italian 🇮🇹';
    } else if (activityName.contains('sushi') || activityName.contains('japanese') || activityName.contains('ramen')) {
      return 'Japanese 🇯🇵';
    } else if (activityName.contains('chinese') || activityName.contains('dim sum')) {
      return 'Chinese 🇨🇳';
    } else if (activityName.contains('indian') || activityName.contains('curry')) {
      return 'Indian 🇮🇳';
    } else if (activityName.contains('mexican') || activityName.contains('taco')) {
      return 'Mexican 🇲🇽';
    } else if (activityName.contains('french') || activityName.contains('bistro')) {
      return 'French 🇫🇷';
    } else if (activityName.contains('thai')) {
      return 'Thai 🇹🇭';
    } else if (activityName.contains('mediterranean') || activityName.contains('greek')) {
      return 'Mediterranean 🇬🇷';
    } else if (activityName.contains('american') || activityName.contains('burger') || activityName.contains('bbq')) {
      return 'American 🇺🇸';
    } else if (activityName.contains('café') || activityName.contains('coffee')) {
      return 'Café ☕';
    } else {
      return 'International 🌍';
    }
  }

  Widget _buildCuisineInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('👨‍🍳', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getCuisineDescription(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCuisineDescription() {
    final cuisineType = _getCuisineType().toLowerCase();
    
    if (cuisineType.contains('italian')) {
      return 'Authentic Italian flavors with fresh ingredients, handmade pastas, and traditional recipes passed down through generations.';
    } else if (cuisineType.contains('japanese')) {
      return 'Fresh, delicate Japanese cuisine featuring seasonal ingredients, expertly prepared sushi, and umami-rich broths.';
    } else if (cuisineType.contains('chinese')) {
      return 'Bold Chinese flavors with aromatic spices, fresh vegetables, and time-honored cooking techniques from various regions.';
    } else if (cuisineType.contains('indian')) {
      return 'Vibrant Indian spices and aromatic curries, featuring authentic recipes with complex flavor profiles and fresh herbs.';
    } else if (cuisineType.contains('mexican')) {
      return 'Vibrant Mexican cuisine with fresh salsas, authentic spices, and traditional cooking methods bursting with flavor.';
    } else if (cuisineType.contains('french')) {
      return 'Elegant French cuisine with classic techniques, rich sauces, and the finest ingredients prepared with artistic flair.';
    } else if (cuisineType.contains('thai')) {
      return 'Balanced Thai flavors combining sweet, sour, salty, and spicy elements with fresh herbs and aromatic ingredients.';
    } else if (cuisineType.contains('mediterranean')) {
      return 'Fresh Mediterranean cuisine featuring olive oil, herbs, fresh vegetables, and wholesome ingredients from the region.';
    } else if (cuisineType.contains('american')) {
      return 'Hearty American comfort food with generous portions, classic favorites, and innovative twists on traditional dishes.';
    } else if (cuisineType.contains('café')) {
      return 'Cozy café atmosphere with expertly crafted coffee, fresh pastries, and light meals perfect for any time of day.';
    } else {
      return 'Diverse international cuisine bringing together flavors from around the world in creative and delicious combinations.';
    }
  }

  Widget _buildMenuItems() {
    final menuItems = _getMenuHighlights();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Must-Try Dishes:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5C6BC0),
          ),
        ),
        const SizedBox(height: 8),
        ...menuItems.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(item['emoji'] as String, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (item['price'] != null)
                Text(
                  item['price'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  List<Map<String, String?>> _getMenuHighlights() {
    final cuisineType = _getCuisineType().toLowerCase();
    
    if (cuisineType.contains('italian')) {
      return [
        {'emoji': '🍝', 'name': 'Truffle Pasta', 'price': '€24'},
        {'emoji': '🍕', 'name': 'Margherita Pizza', 'price': '€18'},
        {'emoji': '🥗', 'name': 'Burrata Caprese', 'price': '€16'},
      ];
    } else if (cuisineType.contains('japanese')) {
      return [
        {'emoji': '🍣', 'name': 'Chef\'s Sushi Selection', 'price': '€32'},
        {'emoji': '🍜', 'name': 'Tonkotsu Ramen', 'price': '€19'},
        {'emoji': '🍱', 'name': 'Bento Box', 'price': '€22'},
      ];
    } else if (cuisineType.contains('chinese')) {
      return [
        {'emoji': '🥟', 'name': 'Handmade Dumplings', 'price': '€14'},
        {'emoji': '🍛', 'name': 'Kung Pao Chicken', 'price': '€18'},
        {'emoji': '🥠', 'name': 'Peking Duck', 'price': '€28'},
      ];
    } else if (cuisineType.contains('indian')) {
      return [
        {'emoji': '🍛', 'name': 'Butter Chicken', 'price': '€20'},
        {'emoji': '🫓', 'name': 'Garlic Naan', 'price': '€5'},
        {'emoji': '🍘', 'name': 'Biryani', 'price': '€22'},
      ];
    } else if (cuisineType.contains('mexican')) {
      return [
        {'emoji': '🌮', 'name': 'Fish Tacos', 'price': '€16'},
        {'emoji': '🫔', 'name': 'Chicken Burrito', 'price': '€14'},
        {'emoji': '🥑', 'name': 'Fresh Guacamole', 'price': '€8'},
      ];
    } else if (cuisineType.contains('french')) {
      return [
        {'emoji': '🥩', 'name': 'Beef Bourguignon', 'price': '€32'},
        {'emoji': '🐌', 'name': 'Escargot', 'price': '€18'},
        {'emoji': '🧀', 'name': 'Cheese Board', 'price': '€22'},
      ];
    } else if (cuisineType.contains('thai')) {
      return [
        {'emoji': '🍜', 'name': 'Pad Thai', 'price': '€16'},
        {'emoji': '🥥', 'name': 'Green Curry', 'price': '€18'},
        {'emoji': '🥭', 'name': 'Mango Sticky Rice', 'price': '€9'},
      ];
    } else if (cuisineType.contains('mediterranean')) {
      return [
        {'emoji': '🫒', 'name': 'Greek Salad', 'price': '€14'},
        {'emoji': '🥙', 'name': 'Lamb Gyros', 'price': '€18'},
        {'emoji': '🧄', 'name': 'Hummus Platter', 'price': '€12'},
      ];
    } else if (cuisineType.contains('american')) {
      return [
        {'emoji': '🍔', 'name': 'Signature Burger', 'price': '€19'},
        {'emoji': '🍟', 'name': 'Truffle Fries', 'price': '€8'},
        {'emoji': '🥧', 'name': 'Apple Pie', 'price': '€7'},
      ];
    } else if (cuisineType.contains('café')) {
      return [
        {'emoji': '☕', 'name': 'Specialty Coffee', 'price': '€4'},
        {'emoji': '🥐', 'name': 'Fresh Croissant', 'price': '€3'},
        {'emoji': '🍰', 'name': 'Daily Cake', 'price': '€6'},
      ];
    } else {
      return [
        {'emoji': '🍽️', 'name': 'Chef\'s Special', 'price': '€24'},
        {'emoji': '🥗', 'name': 'Seasonal Salad', 'price': '€16'},
        {'emoji': '🍮', 'name': 'House Dessert', 'price': '€8'},
      ];
    }
  }

  Widget _buildDietaryInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Row(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getDietaryOptions(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDietaryOptions() {
    final cuisineType = _getCuisineType().toLowerCase();
    
    if (cuisineType.contains('indian') || cuisineType.contains('mediterranean')) {
      return 'Vegetarian & Vegan options available • Gluten-free dishes • Halal options';
    } else if (cuisineType.contains('japanese') || cuisineType.contains('thai')) {
      return 'Fresh seafood • Vegetarian options • Gluten-free soy sauce available';
    } else if (cuisineType.contains('italian')) {
      return 'Gluten-free pasta available • Vegetarian options • Fresh local ingredients';
    } else if (cuisineType.contains('café')) {
      return 'Oat milk available • Vegan pastries • Gluten-free options • Organic coffee';
    } else {
      return 'Dietary accommodations available • Ask staff about allergens • Vegetarian options';
    }
  }
} 