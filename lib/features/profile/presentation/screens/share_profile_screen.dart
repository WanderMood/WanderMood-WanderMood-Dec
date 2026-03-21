import 'package:flutter/material.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

// WanderMood v2 — Share Profile (Screen 13)
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmSkyTint = Color(0xFFEDF5F9);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

enum ShareProfileScreenType { main, qr, link }

class ShareProfileScreen extends ConsumerStatefulWidget {
  const ShareProfileScreen({super.key});

  @override
  ConsumerState<ShareProfileScreen> createState() => _ShareProfileScreenState();
}

class _ShareProfileScreenState extends ConsumerState<ShareProfileScreen> {
  ShareProfileScreenType _currentScreen = ShareProfileScreenType.main;
  bool _copied = false;
  bool _qrDownloaded = false;

  String get _profileUrl {
    final profile = ref.read(profileProvider).valueOrNull;
    final username = profile?.username ?? profile?.id ?? 'user';
    return 'wandermood.app/u/$username';
  }

  Future<void> _handleCopyLink() async {
    await Clipboard.setData(ClipboardData(text: 'https://$_profileUrl'));
    setState(() {
      _copied = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  Future<void> _handleDownloadQR() async {
    // For now, just simulate download
    setState(() {
      _qrDownloaded = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _qrDownloaded = false;
        });
      }
    });
  }

  Future<void> _shareToSocial(String platform) async {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.read(profileProvider).valueOrNull;
    final url = 'https://$_profileUrl';
    final shareText = profile?.fullName != null && profile!.fullName!.isNotEmpty
        ? l10n.shareProfileShareTextNamed(profile.fullName!, url)
        : l10n.shareProfileShareTextMy(url);
    try {
      if (platform == 'email') {
        final uri = Uri.parse('mailto:?subject=${Uri.encodeComponent(l10n.shareProfileEmailSubject)}&body=${Uri.encodeComponent(shareText)}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } else {
        await Share.share(shareText);
      }
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.shareProfileFailedToShare(e.toString()),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (profile) => _buildScreen(profile),
      loading: () => Scaffold(
        backgroundColor: _wmCream,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: _wmCream,
        body: Center(
          child: Text(AppLocalizations.of(context)!.profileErrorLoad),
        ),
      ),
    );
  }

  Widget _buildScreen(profile) {
    switch (_currentScreen) {
      case ShareProfileScreenType.main:
        return _buildMainScreen(profile);
      case ShareProfileScreenType.qr:
        return _buildQRScreen(profile);
      case ShareProfileScreenType.link:
        return _buildLinkScreen(profile);
    }
  }

  Widget _buildMainScreen(profile) {
    final l10n = AppLocalizations.of(context)!;
    final userName = profile?.fullName ?? l10n.profileFallbackUser;
    final username = profile?.username ?? l10n.shareProfileDefaultUsername;
    final bio = profile?.bio ?? l10n.shareProfileDefaultBio;
    final streak = profile?.moodStreak ?? 0;
    final isPublic = profile?.isPublic ?? true;
    
    // Get places count (placeholder for now)
    final placesCount = 0; // TODO: Get from saved places
    
    // Get top mood - ensure it's always a non-null string
    final topMood = (profile?.favoriteMood != null && profile!.favoriteMood!.isNotEmpty) 
        ? profile.favoriteMood! 
        : 'adventurous';

    return Scaffold(
      backgroundColor: _wmCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _wmStone),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.shareProfileTitle,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _wmCharcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Preview Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _wmForest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [],
                        ),
                        child: Center(
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _wmForest,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '@$username',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    bio,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mini Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat(streak.toString(), l10n.shareProfileDayStreak),
                        _buildMiniStat(placesCount.toString(), l10n.profileStatsPlacesTitle),
                        _buildMiniStat(_capitalizeString(topMood), l10n.profileStatsTopMoodTitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.qr_code,
                    label: l10n.shareProfileQRCode,
                    subtitle: l10n.shareProfileScanToConnect,
                    badgeBackground: _wmForestTint,
                    iconColor: _wmForest,
                    onTap: () => setState(() => _currentScreen = ShareProfileScreenType.qr),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.link,
                    label: l10n.shareProfileCopyLink,
                    subtitle: l10n.shareProfileShareAnywhere,
                    badgeBackground: _wmSkyTint,
                    iconColor: _wmSky,
                    onTap: () => setState(() => _currentScreen = ShareProfileScreenType.link),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Share Via
            Text(
              l10n.shareProfileShareVia,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _wmCharcoal,
              ),
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              icon: Icons.camera_alt,
              label: l10n.shareProfileInstagram,
              gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF97316)],
              onTap: () => _shareToSocial('instagram'),
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              icon: Icons.message,
              label: l10n.shareProfileWhatsApp,
              gradient: const [Color(0xFF10B981), Color(0xFF059669)],
              onTap: () => _shareToSocial('whatsapp'),
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              icon: Icons.alternate_email,
              label: l10n.shareProfileTwitter,
              gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
              onTap: () => _shareToSocial('twitter'),
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              icon: Icons.email,
              label: l10n.shareProfileEmail,
              gradient: const [Color(0xFF6B7280), Color(0xFF374151)],
              onTap: () => _shareToSocial('email'),
            ),
            const SizedBox(height: 24),
            // Public Profile Toggle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [],
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: _wmStone, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.shareProfilePublicProfile,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _wmCharcoal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.shareProfileAnyoneCanView,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _wmStone,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isPublic,
                    onChanged: (value) async {
                      try {
                        await ref.read(profileProvider.notifier).updateProfile(isPublic: value);
                        if (mounted) {
                          showWanderMoodToast(
                            context,
                            message: l10n.profileVisibilityUpdated,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          showWanderMoodToast(
                            context,
                            message: l10n.shareProfileUpdateFailed(e.toString()),
                            isError: true,
                          );
                        }
                      }
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: _wmForest.withOpacity(0.45),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: _wmParchment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color badgeBackground,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _wmParchment),
          boxShadow: const [],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: badgeBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [],
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _wmCharcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _wmStone,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.share, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScreen(profile) {
    final l10n = AppLocalizations.of(context)!;
    final userName = profile?.fullName ?? l10n.profileFallbackUser;
    final username = profile?.username ?? l10n.shareProfileDefaultUsername;
    final qrData = 'https://$_profileUrl';

    return Scaffold(
      backgroundColor: _wmCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _wmStone),
          onPressed: () => setState(() => _currentScreen = ShareProfileScreenType.main),
        ),
        title: Text(
          l10n.shareProfileMyQRCode,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _wmCharcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // QR Code Container
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _wmParchment),
                boxShadow: const [],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 256,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _wmCharcoal,
                    ),
                  ),
                  Text(
                    '@$username',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _wmStone,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _wmParchment),
                boxShadow: const [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _wmForestTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: _wmForest, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.shareProfileHowItWorks,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _wmCharcoal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.shareProfileQRInstructions,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _wmStone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleDownloadQR,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _qrDownloaded ? _wmForest.withOpacity(0.85) : _wmForest,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _qrDownloaded ? Icons.check : Icons.download,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _qrDownloaded ? l10n.shareProfileDownloaded : l10n.shareProfileSaveQRCode,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await Share.share(l10n.shareProfileShareMessage('https://$_profileUrl'));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _wmCharcoal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: _wmParchment, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share, color: _wmForest),
                    const SizedBox(width: 8),
                    Text(
                      l10n.shareProfileShareQRImage,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _wmCharcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkScreen(profile) {
    final l10n = AppLocalizations.of(context)!;
    final userName = profile?.fullName ?? l10n.profileFallbackUser;
    final username = profile?.username ?? l10n.shareProfileDefaultUsername;
    final bio = profile?.bio ?? l10n.shareProfileDefaultBio;

    return Scaffold(
      backgroundColor: _wmCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _wmStone),
          onPressed: () => setState(() => _currentScreen = ShareProfileScreenType.main),
        ),
        title: Text(
          l10n.shareProfileShareLinkTitle,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _wmCharcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _wmParchment),
                boxShadow: const [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _wmParchment, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _wmForest,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _wmCharcoal,
                          ),
                        ),
                        Text(
                          '@$username',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _wmStone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              bio,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _wmStone,
              ),
            ),
            const SizedBox(height: 24),
            // Link Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _wmSkyTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _wmParchment),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.shareProfileYourProfileLink,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _wmStone,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _wmParchment),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link, color: _wmSky, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _profileUrl,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'monospace',
                              color: _wmCharcoal.withOpacity(0.75),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Copy Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleCopyLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _copied ? _wmForest.withOpacity(0.85) : _wmForest,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _copied ? Icons.check : Icons.link,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _copied ? l10n.shareProfileLinkCopied : l10n.shareProfileCopyLink,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Quick Share
            Text(
              l10n.shareProfileQuickShare,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _wmStone,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickShareButton(
                    icon: Icons.camera_alt,
                    label: l10n.shareProfileInstagram,
                    gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    onTap: () => _shareToSocial('instagram'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickShareButton(
                    icon: Icons.message,
                    label: l10n.shareProfileWhatsApp,
                    gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                    onTap: () => _shareToSocial('whatsapp'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickShareButton(
                    icon: Icons.alternate_email,
                    label: l10n.shareProfileTwitter,
                    gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    onTap: () => _shareToSocial('twitter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickShareButton(
                    icon: Icons.email,
                    label: l10n.shareProfileEmail,
                    gradient: const [Color(0xFF6B7280), Color(0xFF374151)],
                    onTap: () => _shareToSocial('email'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _wmSkyTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _wmParchment),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: _wmSky,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.shareProfileLinkInfo,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _wmCharcoal,
                      ),
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

  String _capitalizeString(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  Widget _buildQuickShareButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _wmParchment),
          boxShadow: const [],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _wmCharcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
