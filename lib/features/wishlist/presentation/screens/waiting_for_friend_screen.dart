import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/wishlist/data/plan_met_vriend_service.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';
import 'package:wandermood/features/wishlist/presentation/screens/match_found_screen.dart';
import 'package:wandermood/features/wishlist/presentation/screens/no_overlap_screen.dart';

const _wmCream = Color(0xFFF5F0E8);
const _wmForest = Color(0xFF2A6049);
const _wmMint = Color(0xFF5DCAA5);
const _wmCharcoal = Color(0xFF1A1714);
const _wmMuted = Color(0x8C1A1714);

class WaitingForFriendScreen extends ConsumerStatefulWidget {
  const WaitingForFriendScreen({super.key, required this.args});

  final PlanMetVriendWaitingArgs args;

  @override
  ConsumerState<WaitingForFriendScreen> createState() =>
      _WaitingForFriendScreenState();
}

class _WaitingForFriendScreenState extends ConsumerState<WaitingForFriendScreen> {
  RealtimeChannel? _channel;
  bool _reminding = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    final client = Supabase.instance.client;
    _channel = client
        .channel('pmv-wait-${widget.args.sessionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'group_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.args.sessionId,
          ),
          callback: (payload) {
            final status = payload.newRecord['status']?.toString() ?? '';
            _handleSessionStatus(status);
          },
        )
        .subscribe();
  }

  Future<void> _handleSessionStatus(String status) async {
    if (!mounted) return;
    if (status == 'match_found') {
      final session = await ref
          .read(planMetVriendServiceProvider)
          .fetchSession(widget.args.sessionId);
      final planned = session?['planned_date']?.toString();
      if (planned == null || planned.isEmpty) return;
      final d = DateTime.tryParse(planned);
      if (d == null || !mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MatchFoundScreen(
            args: PlanMetVriendMatchArgs(
              sessionId: widget.args.sessionId,
              inviteId: widget.args.inviteId,
              friend: widget.args.friend,
              place: widget.args.place,
              matchedDate: DateTime(d.year, d.month, d.day),
            ),
          ),
        ),
      );
    } else if (status == 'no_overlap') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => NoOverlapScreen(
            args: PlanMetVriendNoOverlapArgs(
              sessionId: widget.args.sessionId,
              inviteId: widget.args.inviteId,
              friend: widget.args.friend,
              place: widget.args.place,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _remind() async {
    if (_reminding) return;
    setState(() => _reminding = true);
    try {
      final name = widget.args.inviterDisplayName ?? 'Je vriend';
      await ref.read(planMetVriendServiceProvider).resendInviteReminder(
            friendUserId: widget.args.friend.userId,
            inviterName: name,
            placeName: widget.args.place.placeName,
            sessionId: widget.args.sessionId,
            inviteId: widget.args.inviteId,
          );
      if (mounted) {
        showWanderMoodToast(context, message: 'Herinnering verstuurd.');
      }
    } finally {
      if (mounted) setState(() => _reminding = false);
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _wmCream,
      appBar: AppBar(
        backgroundColor: _wmCream,
        elevation: 0,
        iconTheme: const IconThemeData(color: _wmCharcoal),
        title: Text(
          'Wachten op ${widget.args.friend.displayName}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: _wmCharcoal,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const _PulseIcon(),
            const SizedBox(height: 24),
            Text(
              widget.args.place.placeName,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _wmCharcoal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We wachten tot ${widget.args.friend.displayName} '
              'zijn of haar beschikbaarheid deelt.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: _wmMuted,
                height: 1.45,
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: _reminding ? null : _remind,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: _wmForest),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _reminding ? 'Versturen…' : 'Stuur een herinnering',
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

class _PulseIcon extends StatefulWidget {
  const _PulseIcon();

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 88 + _controller.value * 12,
          height: 88 + _controller.value * 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _wmMint.withValues(alpha: 0.2 + _controller.value * 0.15),
          ),
          child: child,
        );
      },
      child: const Center(
        child: Icon(Icons.hourglass_top, size: 40, color: _wmForest),
      ),
    );
  }
}
