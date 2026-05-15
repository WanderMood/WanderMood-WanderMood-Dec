import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/wishlist/data/plan_met_vriend_service.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';
import 'package:wandermood/features/wishlist/presentation/screens/match_found_screen.dart';
import 'package:wandermood/features/wishlist/presentation/screens/no_overlap_screen.dart';
import 'package:wandermood/features/wishlist/presentation/widgets/calendar_picker_widget.dart';

const _wmCream = Color(0xFFF5F0E8);
const _wmForest = Color(0xFF2A6049);
const _wmCharcoal = Color(0xFF1A1714);
const _wmMuted = Color(0x8C1A1714);

class InviteResponseScreen extends ConsumerStatefulWidget {
  const InviteResponseScreen({super.key, required this.args});

  final PlanMetVriendInviteResponseArgs args;

  @override
  ConsumerState<InviteResponseScreen> createState() =>
      _InviteResponseScreenState();
}

class _InviteResponseScreenState extends ConsumerState<InviteResponseScreen> {
  final _selected = <DateTime>{};
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic>? _invite;
  PlanMetVriendPlace? _place;
  PlanMetVriendFriend? _inviter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(planMetVriendServiceProvider);
    final invite = await service.fetchInvite(widget.args.inviteId);
    if (!mounted) return;
    if (invite == null) {
      setState(() => _loading = false);
      return;
    }
    final status = invite['status']?.toString() ?? '';
    if (status == 'declined' || status == 'expired') {
      setState(() {
        _invite = invite;
        _loading = false;
      });
      return;
    }
    final inviterId = invite['inviter_user_id'] as String;
    final profile = await service.fetchProfile(inviterId);
    final place = PlanMetVriendPlace(
      placeId: invite['place_id'] as String,
      placeName: invite['place_name'] as String,
      placeData: Map<String, dynamic>.from(
        invite['place_data'] as Map? ?? {},
      ),
    );
    setState(() {
      _invite = invite;
      _place = place;
      _inviter = PlanMetVriendFriend(
        userId: inviterId,
        displayName: profile['displayName'] ?? 'Je vriend',
        username: profile['username'],
        avatarUrl: profile['avatarUrl'],
      );
      _loading = false;
    });
  }

  Future<void> _decline() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(planMetVriendServiceProvider)
          .declineInvite(
            inviteId: widget.args.inviteId,
            sessionId: widget.args.sessionId,
          );
      if (mounted) {
        showWanderMoodToast(context, message: 'Uitnodiging afgewezen.');
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _accept() async {
    if (_selected.isEmpty) {
      showWanderMoodToast(context, message: 'Kies minstens één dag.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ref.read(planMetVriendServiceProvider).acceptInviteAndMatch(
            sessionId: widget.args.sessionId,
            inviteId: widget.args.inviteId,
            friendDates: _selected.toList(),
          );
      if (!mounted || _place == null || _inviter == null) return;
      if (result.overlap.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => MatchFoundScreen(
              args: PlanMetVriendMatchArgs(
                sessionId: widget.args.sessionId,
                inviteId: widget.args.inviteId,
                friend: _inviter!,
                place: _place!,
                matchedDate: result.overlap.first,
              ),
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => NoOverlapScreen(
              args: PlanMetVriendNoOverlapArgs(
                sessionId: widget.args.sessionId,
                inviteId: widget.args.inviteId,
                friend: _inviter!,
                place: _place!,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Opslaan mislukt. Probeer het opnieuw.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toggle(DateTime d) {
    setState(() {
      final day = DateTime(d.year, d.month, d.day);
      final existing = _selected.where(
        (s) => s.year == day.year && s.month == day.month && s.day == day.day,
      );
      if (existing.isNotEmpty) {
        _selected.remove(existing.first);
      } else {
        _selected.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _wmCream,
        body: Center(
          child: CircularProgressIndicator(color: _wmForest),
        ),
      );
    }
    if (_invite == null || _place == null) {
      return Scaffold(
        backgroundColor: _wmCream,
        appBar: AppBar(backgroundColor: _wmCream),
        body: Center(
          child: Text(
            'Uitnodiging niet gevonden',
            style: GoogleFonts.poppins(color: _wmMuted),
          ),
        ),
      );
    }

    final message = _invite!['message'] as String?;
    final photo = _place!.photoUrl;

    return Scaffold(
      backgroundColor: _wmCream,
      appBar: AppBar(
        backgroundColor: _wmCream,
        elevation: 0,
        iconTheme: const IconThemeData(color: _wmCharcoal),
        title: Text(
          'Uitnodiging',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: _wmCharcoal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          if (_inviter != null) ...[
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: _inviter!.avatarUrl != null
                      ? NetworkImage(_inviter!.avatarUrl!)
                      : null,
                  child: _inviter!.avatarUrl == null
                      ? Text(_inviter!.displayName.substring(0, 1))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_inviter!.displayName} wil ${_place!.placeName} met jou bezoeken',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _wmCharcoal,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (photo != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: WmPlacePhotoNetworkImage(photo, fit: BoxFit.cover),
              ),
            ),
          ],
          if (message != null && message.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E2D8)),
              ),
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 14, color: _wmCharcoal),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Wanneer kun jij?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: _wmCharcoal,
            ),
          ),
          const SizedBox(height: 12),
          CalendarPickerWidget(
            selectedDates: _selected,
            onToggle: _toggle,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: _submitting ? null : _accept,
                style: FilledButton.styleFrom(
                  backgroundColor: _wmForest,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Deel mijn beschikbaarheid',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: _submitting ? null : _decline,
                child: Text(
                  'Afwijzen',
                  style: GoogleFonts.poppins(color: _wmMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
