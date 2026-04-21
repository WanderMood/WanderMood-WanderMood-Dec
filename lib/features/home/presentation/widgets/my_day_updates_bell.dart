import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/providers/supabase_provider.dart';

/// Header bell for My Day → [NotificationCentreScreen] with unread badge.
class MyDayUpdatesBell extends ConsumerStatefulWidget {
  const MyDayUpdatesBell({super.key, required this.isImmersive});

  final bool isImmersive;

  @override
  ConsumerState<MyDayUpdatesBell> createState() => _MyDayUpdatesBellState();
}

class _MyDayUpdatesBellState extends ConsumerState<MyDayUpdatesBell> {
  int _unread = 0;
  Timer? _timer;
  RealtimeChannel? _ch;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final insert = PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_id',
          value: uid,
        );
        _ch = Supabase.instance.client
            .channel('wm_myday_bell_$uid')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'realtime_events',
              filter: insert,
              callback: (_) => _refresh(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'realtime_events',
              filter: insert,
              callback: (_) => _refresh(),
            )
            .subscribe();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      _ch?.unsubscribe();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final client = ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      // Prod schema: recipient_id + read_at (null = unread). Legacy is_read/user_id ignored.
      final rows = await client
          .from('realtime_events')
          .select('id')
          .eq('recipient_id', uid)
          .filter('read_at', 'is', null)
          .limit(99);
      final n = (rows as List).length;
      if (mounted) setState(() => _unread = n);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isImmersive ? Colors.white : const Color(0xFF1E1C18);
    final bg = widget.isImmersive
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white;
    final badge = _unread > 99 ? '99+' : '$_unread';
    final nl = Localizations.localeOf(context).languageCode == 'nl';
    final hint = nl
        ? (_unread > 0 ? 'Meldingen, $_unread ongelezen' : 'Meldingen, alles gelezen')
        : (_unread > 0 ? 'Notifications, $_unread unread' : 'Notifications, all caught up');

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Semantics(
        label: hint,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await context.push('/notifications');
              if (mounted) await _refresh();
            },
            customBorder: const CircleBorder(),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                border: Border.all(
                  color: widget.isImmersive
                      ? Colors.white.withValues(alpha: 0.35)
                      : const Color(0xFFE8E2D8),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 24,
                      color: fg,
                    ),
                  ),
                  if (_unread > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _unread > 9 ? 5 : 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8784A),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        constraints: BoxConstraints(
                          minWidth: _unread > 9 ? 22 : 20,
                          minHeight: 20,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
