import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/profile/domain/providers/current_user_profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// WanderMood v2 design tokens — side drawer
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmError = Color(0xFFE05C5C);

class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({super.key});

  String _getTravellerLevel(BuildContext context, int? moodStreak) {
    final l10n = AppLocalizations.of(context)!;
    if (moodStreak == null) return l10n.drawerNewExplorer;
    if (moodStreak > 100) return l10n.drawerMasterWanderer;
    if (moodStreak > 50) return l10n.drawerAdventureExpert;
    if (moodStreak > 20) return l10n.drawerSeasonedExplorer;
    if (moodStreak > 10) return l10n.drawerTravelEnthusiast;
    return l10n.drawerNewExplorer;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileData = ref.watch(currentUserProfileProvider);
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.8,
      backgroundColor: _wmWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          profileData.when(
            data: (currentProfile) => _DrawerForestHeader(
              fullName: currentProfile?.fullName ??
                  currentProfile?.username ??
                  l10n.profileFallbackUser,
              email: email.isNotEmpty
                  ? email
                  : (currentProfile?.username != null
                      ? '@${currentProfile!.username}'
                      : ''),
              avatarUrl: currentProfile?.avatarUrl,
              travellerLevel: _getTravellerLevel(context, currentProfile?.moodStreak),
              streakLabel: l10n.drawerDayStreak('${currentProfile?.moodStreak ?? 0}'),
              onAvatarTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            loading: () => ColoredBox(
              color: _wmForest,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _wmWhite.withValues(alpha: 0.9),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
            error: (_, __) => ColoredBox(
              color: _wmForest,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: _wmWhite.withValues(alpha: 0.9), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        l10n.drawerErrorLoadingProfile,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: _wmWhite.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader(l10n.drawerNavigation),
                  _DrawerMenuItem(
                    icon: Icons.favorite_border,
                    label: l10n.drawerSavedPlaces,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/places/saved');
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.calendar_month_outlined,
                    label: l10n.drawerMyAgenda,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/agenda');
                    },
                  ),
                  _sectionHeader(l10n.drawerSettings),
                  _DrawerMenuItem(
                    icon: Icons.settings_outlined,
                    label: l10n.drawerAppSettings,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.notifications_outlined,
                    label: l10n.drawerNotifications,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/notifications');
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.language,
                    label: l10n.drawerLanguage,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings/language');
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.help_outline,
                    label: l10n.drawerHelpSupport,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings/help');
                    },
                  ),
                  _sectionHeader(l10n.drawerAccount),
                  _DrawerMenuItem(
                    icon: Icons.person_outline,
                    label: l10n.drawerProfile,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.logout,
                    label: l10n.drawerLogOut,
                    isDestructive: true,
                    showChevron: false,
                    onTap: () async {
                      try {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          context.go('/auth/magic-link');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showWanderMoodToast(
                            context,
                            message: AppLocalizations.of(context)!.drawerErrorSigningOut(e.toString()),
                            isError: true,
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, thickness: 0.5, color: _wmParchment),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: _wmStone,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerForestHeader extends StatelessWidget {
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String travellerLevel;
  final String streakLabel;
  final VoidCallback onAvatarTap;

  const _DrawerForestHeader({
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.travellerLevel,
    required this.streakLabel,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : '?';

    return ColoredBox(
      color: _wmForest,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _wmWhite, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: _wmWhite,
                    backgroundImage: (avatarUrl ?? '').isNotEmpty
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: (avatarUrl ?? '').isEmpty
                        ? Text(
                            initial,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _wmForest,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                fullName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _wmWhite,
                  letterSpacing: 0.3,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: _wmWhite.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeaderBadge(text: travellerLevel),
                  _HeaderBadge(text: streakLabel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String text;

  const _HeaderBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _wmForestTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _wmForest,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showChevron;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.showChevron = true,
  });

  @override
  State<_DrawerMenuItem> createState() => _DrawerMenuItemState();
}

class _DrawerMenuItemState extends State<_DrawerMenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isDestructive ? _wmError : _wmForest;
    final textColor = widget.isDestructive ? _wmError : _wmCharcoal;

    return Material(
      color: _pressed ? _wmForestTint : Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Icon(widget.icon, size: 20, color: iconColor),
                ),
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                ),
                if (widget.showChevron)
                  Icon(Icons.chevron_right, size: 22, color: _wmStone),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
