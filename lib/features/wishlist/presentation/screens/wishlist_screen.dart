import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/places/presentation/screens/place_detail_screen.dart';
import 'package:wandermood/features/wishlist/data/wishlist_service.dart';
import 'package:wandermood/features/wishlist/domain/wishlist_entry.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_with_friend_launcher.dart';
import 'package:wandermood/l10n/app_localizations.dart';

const _wmCream = Color(0xFFF5F0E8);
const _wmForest = Color(0xFF2A6049);
const _wmCharcoal = Color(0xFF1A1714);
const _wmMuted = Color(0x8C1A1714);
const _wmAccent = Color(0xFF5DCAA5);

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(wishlistEntriesProvider);

    return Scaffold(
      backgroundColor: _wmCream,
      appBar: AppBar(
        backgroundColor: _wmCream,
        elevation: 0,
        iconTheme: const IconThemeData(color: _wmCharcoal),
        title: Text(
          'Mijn Wishlist',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: _wmCharcoal,
          ),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _wmForest),
        ),
        error: (_, __) => Center(
          child: Text(
            'Kon wishlist niet laden',
            style: GoogleFonts.poppins(color: _wmMuted),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) return const _WishlistEmptyState();
          final social = entries.where((e) => e.isSocialSource).toList();
          final manual = entries.where((e) => !e.isSocialSource).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Text(
                '${entries.length} plekken bewaard',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _wmMuted,
                ),
              ),
              const SizedBox(height: 16),
              if (social.isNotEmpty) ...[
                _sectionTitle('Van TikTok & Instagram'),
                ...social.map((e) => _WishlistCard(entry: e)),
              ],
              if (manual.isNotEmpty) ...[
                _sectionTitle('Handmatig bewaard'),
                ...manual.map((e) => _WishlistCard(entry: e)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _wmMuted,
        ),
      ),
    );
  }
}

class _WishlistEmptyState extends StatelessWidget {
  const _WishlistEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: _wmForest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'M',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _wmAccent,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nog niets bewaard',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _wmCharcoal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Deel een TikTok of Instagram post naar WanderMood om plekken op te slaan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.45,
                color: _wmMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistCard extends ConsumerWidget {
  const _WishlistCard({required this.entry});

  final WishlistEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo =
        entry.place.photos.isNotEmpty ? entry.place.photos.first : null;
    final dateLabel =
        DateFormat('d MMM', 'nl').format(entry.savedAt.toLocal());

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE05C5C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final action = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: _wmCream,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.groups_outlined, color: _wmForest),
                  title: Text(AppLocalizations.of(ctx)!.planMetVriendCta),
                  onTap: () => Navigator.pop(ctx, 'plan'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Verwijderen'),
                  onTap: () => Navigator.pop(ctx, 'delete'),
                ),
              ],
            ),
          ),
        );
        if (action == 'plan') {
          if (context.mounted) {
            openPlanWithFriend(
              context,
              PlanWithFriendArgs.fromPlace(
                entry.place,
                sourceUrl: entry.sourceUrl,
              ),
            );
          }
          return false;
        }
        if (action == 'delete') {
          await ref.read(wishlistServiceProvider).deleteEntry(entry.placeId);
          return true;
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE8E2D8)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlaceDetailScreen(placeId: entry.placeId),
              ),
            );
          },
          onLongPress: () async {
            final action = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: _wmCream,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.groups_outlined, color: _wmForest),
                      title: Text(AppLocalizations.of(ctx)!.planMetVriendCta),
                      onTap: () => Navigator.pop(ctx, 'plan'),
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text('Verwijderen'),
                      onTap: () => Navigator.pop(ctx, 'delete'),
                    ),
                  ],
                ),
              ),
            );
            if (!context.mounted) return;
            if (action == 'plan') {
              openPlanWithFriend(
                context,
                PlanWithFriendArgs.fromPlace(
                  entry.place,
                  sourceUrl: entry.sourceUrl,
                ),
              );
            } else if (action == 'delete') {
              await ref
                  .read(wishlistServiceProvider)
                  .deleteEntry(entry.placeId);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: photo != null && photo.isNotEmpty
                        ? WmPlacePhotoNetworkImage(photo, fit: BoxFit.cover)
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _wmForest.withValues(alpha: 0.9),
                                  _wmAccent.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.placeName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _wmCharcoal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_sourceBadge(entry.source) != null)
                            _sourceBadge(entry.source)!,
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (entry.place.types.isNotEmpty)
                            entry.place.types.first,
                          entry.place.address,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _wmMuted,
                        ),
                      ),
                      Text(
                        dateLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _wmMuted.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.groups_outlined,
                      color: _wmForest, size: 22),
                  onPressed: () => openPlanWithFriend(
                    context,
                    PlanWithFriendArgs.fromPlace(
                      entry.place,
                      sourceUrl: entry.sourceUrl,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: _wmMuted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _sourceBadge(String? source) {
    final s = source?.toLowerCase() ?? '';
    if (s == 'tiktok') {
      return Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _wmCharcoal,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'TikTok',
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }
    if (s == 'instagram') {
      return Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF833AB4), Color(0xFFE1306C)],
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'IG',
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }
    return null;
  }
}
