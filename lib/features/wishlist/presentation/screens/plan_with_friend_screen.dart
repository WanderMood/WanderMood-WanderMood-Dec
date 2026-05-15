import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_with_friend_launcher.dart';

const _wmCream = Color(0xFFF5F0E8);
const _wmForest = Color(0xFF2A6049);
const _wmCharcoal = Color(0xFF1A1714);
const _wmMuted = Color(0x8C1A1714);

final _planFriendsProvider = FutureProvider.autoDispose<List<_PlanFriend>>((
  ref,
) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final follows = await Supabase.instance.client
      .from('user_follows')
      .select('followed_user_id')
      .eq('follower_user_id', userId);

  final ids = (follows as List)
      .map((r) => r['followed_user_id'] as String)
      .where((id) => id.isNotEmpty)
      .toList();
  if (ids.isEmpty) return [];

  final profiles = await Supabase.instance.client
      .from('profiles')
      .select('id, full_name, username, image_url')
      .inFilter('id', ids);

  return (profiles as List).map((p) {
    return _PlanFriend(
      id: p['id'] as String,
      displayName: (p['full_name'] as String?)?.trim().isNotEmpty == true
          ? p['full_name'] as String
          : (p['username'] as String?) ?? 'Wanderer',
      username: (p['username'] as String?) ?? '',
      avatarUrl: p['image_url'] as String?,
    );
  }).toList();
});

class _PlanFriend {
  const _PlanFriend({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;
}

class PlanWithFriendScreen extends ConsumerStatefulWidget {
  const PlanWithFriendScreen({super.key, required this.args});

  final PlanWithFriendArgs args;

  @override
  ConsumerState<PlanWithFriendScreen> createState() =>
      _PlanWithFriendScreenState();
}

class _PlanWithFriendScreenState extends ConsumerState<PlanWithFriendScreen> {
  _PlanFriend? _selected;

  Place? get _place => widget.args.place;

  String? get _photoUrl {
    final p = _place;
    if (p != null && p.photos.isNotEmpty) return p.photos.first;
    final data = widget.args.placeData;
    if (data == null) return null;
    final direct = data['photo_url'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final photos = data['photos'];
    if (photos is List && photos.isNotEmpty) return photos.first.toString();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(_planFriendsProvider);

    return Scaffold(
      backgroundColor: _wmCream,
      appBar: AppBar(
        backgroundColor: _wmCream,
        elevation: 0,
        iconTheme: const IconThemeData(color: _wmCharcoal),
        title: Text(
          'Plan met vriend',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _wmCharcoal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _placeHeader(),
          const SizedBox(height: 24),
          Text(
            'Kies een vriend om mee te plannen',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _wmCharcoal,
            ),
          ),
          const SizedBox(height: 12),
          friendsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: _wmForest),
              ),
            ),
            error: (_, __) => Text(
              'Kon vrienden niet laden',
              style: GoogleFonts.poppins(color: _wmMuted),
            ),
            data: (friends) {
              if (friends.isEmpty) return _emptyFriends();
              return Column(
                children: friends.map((f) => _friendTile(f)).toList(),
              );
            },
          ),
          if (_selected != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E2D8)),
              ),
              child: Column(
                children: [
                  Text(
                    'Binnenkort beschikbaar',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _wmForest,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Beschikbaarheid kiezen met ${_selected!.displayName} komt in een volgende update.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _wmMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _placeHeader() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 72,
            height: 72,
            child: _photoUrl != null
                ? WmPlacePhotoNetworkImage(_photoUrl!, fit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _wmForest.withValues(alpha: 0.9),
                          const Color(0xFF5DCAA5).withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.args.placeName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _wmCharcoal,
                ),
              ),
              if (_place != null && _place!.address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _place!.address,
                  style: GoogleFonts.poppins(fontSize: 13, color: _wmMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _friendTile(_PlanFriend friend) {
    final selected = _selected?.id == friend.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? const Color(0xFFEBF3EE) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? _wmForest : const Color(0xFFE8E2D8),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _wmForest.withValues(alpha: 0.15),
          backgroundImage:
              friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
          child: friend.avatarUrl == null
              ? Text(
                  friend.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: _wmForest,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          friend.displayName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: friend.username.isNotEmpty
            ? Text(
                '@${friend.username}',
                style: GoogleFonts.poppins(fontSize: 12, color: _wmMuted),
              )
            : null,
        onTap: () => setState(() => _selected = friend),
      ),
    );
  }

  Widget _emptyFriends() {
    return Column(
      children: [
        Text(
          'Nog geen vrienden op WanderMood',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: _wmMuted,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            SharePlus.instance.share(
              ShareParams(
                text: 'Doe mee met WanderMood — plan je dag op mood! '
                    'https://wandermood-landing.vercel.app',
              ),
            );
          },
          child: Text(
            'Nodig iemand uit →',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: _wmForest,
            ),
          ),
        ),
      ],
    );
  }
}
