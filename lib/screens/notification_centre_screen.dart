import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/notifications/notification_navigation.dart';
import 'package:wandermood/core/notifications/notification_sender_avatar.dart';
import 'package:wandermood/core/presentation/widgets/wm_notification_card.dart';
import 'package:wandermood/core/providers/supabase_provider.dart';
import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';
import 'package:wandermood/features/realtime/domain/models/realtime_event_from_supabase.dart';
import 'notification_centre_filters.dart';
import 'notification_centre_list_body.dart';
import 'notification_centre_pills.dart';

class NotificationCentreScreen extends ConsumerStatefulWidget {
  const NotificationCentreScreen({super.key});

  @override
  ConsumerState<NotificationCentreScreen> createState() => _NotificationCentreScreenState();
}

class _NotificationCentreScreenState extends ConsumerState<NotificationCentreScreen> {
  NotificationCentreFilter _filter = NotificationCentreFilter.all;
  final List<RealtimeEvent> _all = [];
  int _offset = 0;
  bool _loading = true;
  bool _more = true;
  final ScrollController _pillScroll = ScrollController();
  final Map<String, String> _senderAvatarByUserId = {};
  final Set<String> _senderProfilesLoaded = {};

  static const _page = 20;
  static const _bg = Color(0xFF0F0E0C);
  static const _sunset = Color(0xFFE8784A);
  static const _cream = Color(0xFFF5F0E8);

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _pillScroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    final client = ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    if (reset) {
      _offset = 0;
      _all.clear();
      _more = true;
      _senderAvatarByUserId.clear();
      _senderProfilesLoaded.clear();
    }
    if (!_more && !reset) return;
    setState(() => _loading = true);
    try {
      final rows = await client
          .from('realtime_events')
          .select()
          .eq('recipient_id', uid)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _page - 1);
      final list = (rows as List)
          .map((e) => realtimeEventFromSupabaseRow(Map<String, dynamic>.from(e as Map)))
          .toList();
      await _hydrateSenderProfiles(client, list);
      if (!mounted) return;
      setState(() {
        _all.addAll(list);
        _offset += _page;
        if ((rows as List).length < _page) _more = false;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _hydrateSenderProfiles(
    SupabaseClient client,
    List<RealtimeEvent> batch,
  ) async {
    final ids = <String>{};
    for (final e in batch) {
      final id = notificationSenderUserId(e);
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    final toFetch = ids.where((id) => !_senderProfilesLoaded.contains(id)).toList();
    if (toFetch.isEmpty) return;
    for (final id in toFetch) {
      _senderProfilesLoaded.add(id);
    }
    try {
      final rows = await client
          .from('profiles')
          .select('id, image_url, username, full_name')
          .inFilter('id', toFetch);
      for (final raw in rows as List<dynamic>) {
        final m = Map<String, dynamic>.from(raw as Map);
        final id = m['id']?.toString();
        if (id == null || id.isEmpty) continue;
        final img = (m['image_url'] ?? m['avatar_url'])?.toString().trim();
        if (img != null && img.isNotEmpty) {
          _senderAvatarByUserId[id] = img;
        }
      }
    } catch (_) {}
  }

  Future<void> _markRead(RealtimeEvent e) async {
    try {
      await ref.read(supabaseClientProvider).from('realtime_events').update(
        {'read_at': DateTime.now().toUtc().toIso8601String()},
      ).eq('id', e.id);
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (uid == null) return;
    try {
      await ref
          .read(supabaseClientProvider)
          .from('realtime_events')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('recipient_id', uid)
          .filter('read_at', 'is', null);
      if (mounted) await _load(reset: true);
    } catch (_) {}
  }

  void _selectFilter(NotificationCentreFilter f, int index) {
    if (_filter == f) return;
    setState(() => _filter = f);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pillScroll.hasClients) return;
      final p = _pillScroll.position;
      const w = 96.0;
      final target = (index * w - p.viewportDimension * 0.28).clamp(0.0, p.maxScrollExtent);
      _pillScroll.animateTo(target, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    });
  }

  Widget _tile(RealtimeEvent e) {
    final router = GoRouter.of(context);
    Future<void> onOpen() async {
      await _markRead(e);
      if (!mounted) return;
      applyWmFcmDataNavigation(router, ref, {
        ...e.data,
        'event': (e.data['event'] ?? e.data['kind'] ?? e.type.name).toString(),
        if (e.relatedPostId != null) 'post_id': e.relatedPostId,
      });
      if (mounted) setState(() {});
    }

    final sid = notificationSenderUserId(e);
    final payloadImg = e.imageUrl?.trim();
    if (sid == null && (payloadImg == null || payloadImg.isEmpty)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: WmNotificationCard(
          event: e,
          body: e.message,
          meta: e.timeAgo,
          categoryLabel: notificationCentreCategoryLabel(e.type),
          unread: !e.isRead,
          iconBg: notificationCentreIconBg(e.type, sunset: _sunset, cream: _cream),
          onTap: onOpen,
        ),
      );
    }
    final cached = sid != null ? _senderAvatarByUserId[sid] : null;
    final photo = (cached != null && cached.isNotEmpty)
        ? cached
        : (payloadImg != null && payloadImg.isNotEmpty ? payloadImg : null);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WmNotificationCard(
        event: e,
        body: e.message,
        meta: e.timeAgo,
        categoryLabel: notificationCentreCategoryLabel(e.type),
        unread: !e.isRead,
        iconBg: notificationCentreIconBg(e.type, sunset: _sunset, cream: _cream),
        showSenderAvatar: true,
        senderAvatarUrl: photo,
        onTap: onOpen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nl = Localizations.localeOf(context).languageCode == 'nl';
    final title = nl ? 'Meldingen' : 'Updates';
    final empty = nl
        ? 'Alles bijgewerkt — ik laat je weten als er iets is.'
        : 'Nothing new — you\'re all caught up. I\'ll let you know when something happens.';

    final vis = _all.where((e) => notificationCentrePasses(_filter, e)).toList();
    final unread = vis.where((e) => !e.isRead).toList();
    final read = vis.where((e) => e.isRead).toList();

    final listChild = NotificationCentreListBody(
      nl: nl,
      emptyText: empty,
      showLoading: _loading && _all.isEmpty,
      showEmpty: vis.isEmpty && !_loading,
      unread: unread,
      read: read,
      loadingMore: _loading,
      hasMore: _more,
      onNearEnd: () => _load(),
      itemBuilder: _tile,
      cream: _cream,
    );

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _cream, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _cream,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _markAllRead,
                    child: Text(
                      nl ? 'Alles gelezen' : 'Mark all read',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _sunset,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView(
                controller: _pillScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  for (var i = 0; i < NotificationCentreFilter.values.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: NotificationCentrePill(
                        label: notificationCentrePillLabel(NotificationCentreFilter.values[i], nl),
                        selected: _filter == NotificationCentreFilter.values[i],
                        onTap: () => _selectFilter(NotificationCentreFilter.values[i], i),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.03, 0.015), end: Offset.zero).animate(curved),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<NotificationCentreFilter>(_filter),
                  child: listChild,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
