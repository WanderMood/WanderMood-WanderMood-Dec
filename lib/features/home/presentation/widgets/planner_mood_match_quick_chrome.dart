import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/moody_avatar_compact.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/group_planning/data/group_planning_repository.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

// ─── Mood-pair story template ────────────────────────────────────────────────

/// Returns a pair-aware Moody story sentence for the two normalised mood tags.
/// Falls back to the generic default if the pair is unmapped.
String moodMatchPairStory(
  AppLocalizations l10n,
  String? meMoodRaw,
  String? themMoodRaw,
  String placeName,
) {
  String norm(String? t) => (t?.trim().toLowerCase() ?? '');
  final a = norm(meMoodRaw);
  final b = norm(themMoodRaw);

  // Same mood
  if (a == b && a.isNotEmpty) {
    // ignore: prefer_interpolation_to_compose_strings
    return l10n.plannerMoodMatchPairStory_same_mood(placeName);
  }

  // Canonical pair key: sort alphabetically so order doesn't matter
  final sorted = [a, b]..sort();
  final pair = '${sorted[0]}_${sorted[1]}';

  switch (pair) {
    case 'adventurous_romantic':
      return l10n.plannerMoodMatchPairStory_romantic_adventurous(placeName);
    case 'adventurous_relaxed':
      return l10n.plannerMoodMatchPairStory_adventurous_relaxed(placeName);
    case 'cultural_social':
      return l10n.plannerMoodMatchPairStory_cultural_social(placeName);
    case 'relaxed_social':
      return l10n.plannerMoodMatchPairStory_relaxed_social(placeName);
    case 'energetic_relaxed':
      return l10n.plannerMoodMatchPairStory_energetic_relaxed(placeName);
    case 'cultural_romantic':
      return l10n.plannerMoodMatchPairStory_cultural_romantic(placeName);
    case 'adventurous_energetic':
      return l10n.plannerMoodMatchPairStory_energetic_adventurous(placeName);
    default:
      if (a == 'contemplative' || b == 'contemplative') {
        return l10n.plannerMoodMatchPairStory_contemplative_any(placeName);
      }
      return l10n.plannerMoodMatchPairStory_default(placeName);
  }
}

// ─── Widget ──────────────────────────────────────────────────────────────────

/// Mood Match header + pair story + partner notes — shown above place quick
/// view when the planner activity has a [groupSessionId].
class PlannerMoodMatchQuickChrome extends ConsumerStatefulWidget {
  const PlannerMoodMatchQuickChrome({
    super.key,
    required this.sessionId,
    this.activityTitle,
    this.placeId,
  });

  /// Partner read-back + “your message” composer in **this** sheet. Off by
  /// default: the block ate almost all flex under the hero so place details
  /// had no scroll room. Re-enable when that UX moves into the Mood Match
  /// flow (lobby / reveal / hub); note APIs below stay wired for a one-flag
  /// turn-on.
  static const bool showInlineNotesInPlannerQuickChrome = false;

  final String sessionId;
  final String? activityTitle;
  final String? placeId;

  @override
  ConsumerState<PlannerMoodMatchQuickChrome> createState() =>
      _PlannerMoodMatchQuickChromeState();
}

enum _NoteSaveState { idle, saving, saved, error }

class _PlannerMoodMatchQuickChromeState
    extends ConsumerState<PlannerMoodMatchQuickChrome> {
  List<GroupMemberView>? _members;
  bool _loading = true;

  // Notes state
  Map<String, String> _notes = {};
  final TextEditingController _noteCtrl = TextEditingController();
  _NoteSaveState _saveState = _NoteSaveState.idle;
  RealtimeChannel? _notesChannel;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    final repo = ref.read(groupPlanningRepositoryProvider);
    try {
      final list = await repo.fetchMembersWithProfiles(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _members = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _members = null;
        _loading = false;
      });
    }

    if (!PlannerMoodMatchQuickChrome.showInlineNotesInPlannerQuickChrome) {
      return;
    }
    // Load notes after members (needs noteKey)
    final noteKey = GroupPlanningRepository.activityNoteKey(
      placeId: widget.placeId,
      activityTitle: widget.activityTitle,
    );
    try {
      final notes = await repo.loadActivityNotes(
        sessionId: widget.sessionId,
        noteKey: noteKey,
      );
      if (!mounted) return;
      final myUid = Supabase.instance.client.auth.currentUser?.id ?? '';
      setState(() {
        _notes = notes;
        _noteCtrl.text = notes[myUid] ?? '';
      });
      _subscribeNotesChannel();
    } catch (_) {
      if (!mounted) return;
    }
  }

  void _subscribeNotesChannel() {
    if (_notesChannel != null) return;
    try {
      _notesChannel = Supabase.instance.client
          .channel('wm_group_activity_notes_${widget.sessionId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'group_activity_notes',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'session_id',
              value: widget.sessionId,
            ),
            callback: (_) {
              if (!mounted) return;
              Future<void>.microtask(() async {
                await _reloadNotesFromServer();
              });
            },
          )
          .subscribe();
    } catch (_) {}
  }

  Future<void> _reloadNotesFromServer() async {
    final noteKey = GroupPlanningRepository.activityNoteKey(
      placeId: widget.placeId,
      activityTitle: widget.activityTitle,
    );
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final notes = await repo.loadActivityNotes(
        sessionId: widget.sessionId,
        noteKey: noteKey,
      );
      if (!mounted) return;
      setState(() => _notes = notes);
    } catch (_) {}
  }

  Future<void> _saveNote() async {
    if (_saveState == _NoteSaveState.saving) return;
    setState(() => _saveState = _NoteSaveState.saving);
    final noteKey = GroupPlanningRepository.activityNoteKey(
      placeId: widget.placeId,
      activityTitle: widget.activityTitle,
    );
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      await repo.saveActivityNote(
        sessionId: widget.sessionId,
        noteKey: noteKey,
        noteText: _noteCtrl.text,
      );
      final myUid = Supabase.instance.client.auth.currentUser?.id ?? '';
      if (!mounted) return;
      setState(() {
        _notes = {..._notes, myUid: _noteCtrl.text.trim()};
        _saveState = _NoteSaveState.saved;
      });
      final l10n = AppLocalizations.of(context)!;
      final members = _members;
      if (members != null && members.isNotEmpty) {
        final partnerFirst = _firstName(_other(members), l10n);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(l10n.plannerMoodMatchNoteSavedSnackbar(partnerFirst)),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      await Future<void>.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _saveState = _NoteSaveState.idle);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveState = _NoteSaveState.error);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _saveState = _NoteSaveState.idle);
    }
  }

  @override
  void dispose() {
    try {
      _notesChannel?.unsubscribe();
    } catch (_) {}
    _notesChannel = null;
    _noteCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String _firstName(GroupMemberView? m, AppLocalizations l10n) {
    if (m == null) return l10n.moodMatchFriendThey;
    final s = m.displayName.trim();
    if (s.isEmpty) return l10n.moodMatchFriendThey;
    if (s.startsWith('@')) {
      final u = s.substring(1).trim();
      if (u.isNotEmpty) {
        final parts = u.split(RegExp(r'\s+'));
        if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first;
      }
    }
    final beforeAt = s.split('@').first.trim();
    final parts = beforeAt.split(RegExp(r'\s+'));
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : '?';
  }

  static GroupMemberView? _me(List<GroupMemberView> list) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return list.isNotEmpty ? list.first : null;
    for (final m in list) {
      if (m.member.userId == uid) return m;
    }
    return null;
  }

  static GroupMemberView? _other(List<GroupMemberView> list) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return list.length >= 2 ? list[1] : null;
    for (final m in list) {
      if (m.member.userId != uid) return m;
    }
    return null;
  }

  static String _moodLabel(String? tag) {
    final t = tag?.trim() ?? '';
    if (t.isEmpty) return '—';
    return '${t[0].toUpperCase()}${t.substring(1)}';
  }

  Widget _face(GroupMemberView? m, double size) {
    final initial = () {
      final n = m?.displayName.trim() ?? '';
      if (n.isEmpty) return '?';
      return n[0].toUpperCase();
    }();
    final url = m?.avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: WmNetworkImage(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initCircle(initial, size),
        ),
      );
    }
    return _initCircle(initial, size);
  }

  Widget _initCircle(String initial, double size) => CircleAvatar(
        radius: size / 2,
        backgroundColor:
            GroupPlanningUi.moodMatchTabActiveOrange.withValues(alpha: 0.38),
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );

  Widget _moodPill(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                GroupPlanningUi.moodMatchTabActiveOrange.withValues(alpha: 0.45),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      );

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final placeTitle = widget.activityTitle?.trim().isNotEmpty == true
        ? widget.activityTitle!.trim()
        : l10n.plannerMoodMatchQuickPlaceFallback;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: SizedBox(
          height: 44,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: GroupPlanningUi.moodMatchTabActiveOrange
                    .withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      );
    }

    final members = _members;
    if (members == null || members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: _shell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.moodMatchTitle,
                  style: GoogleFonts.museoModerno(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(l10n.moodMatchTagline,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.25)),
            ],
          ),
        ),
      );
    }

    final me = _me(members);
    final other = _other(members);
    final partnerFirst = _firstName(other, l10n);
    final meMood = _moodLabel(me?.member.moodTag);
    final themMood = _moodLabel(other?.member.moodTag);
    final story = moodMatchPairStory(
        l10n, me?.member.moodTag, other?.member.moodTag, placeTitle);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: _shell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar: badge + "You + partner" ──
            Row(
              children: [
                _badge(l10n.moodMatchTitle),
                const Spacer(),
                Text(
                  l10n.plannerMoodMatchQuickTogether(partnerFirst),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Two faces + mood pills ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _personCol(me, l10n.plannerMoodMatchQuickYouLabel, meMood)),
                const SizedBox(width: 10),
                Expanded(child: _personCol(other, partnerFirst, themMood)),
              ],
            ),
            const SizedBox(height: 12),

            // ── Pair story (A) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MoodyAvatarCompact(size: 26, glowOpacityScale: 0.2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    story,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            // ── Notes section (B) — gated; see [showInlineNotesInPlannerQuickChrome].
            if (PlannerMoodMatchQuickChrome.showInlineNotesInPlannerQuickChrome) ...[
              const SizedBox(height: 14),
              _notesDivider(),
              const SizedBox(height: 10),
              _notesSection(
                l10n,
                partnerFirst,
                _notes[other?.member.userId ?? '']?.trim() ?? '',
                Supabase.instance.client.auth.currentUser?.id ?? '',
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _personCol(GroupMemberView? m, String label, String mood) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _face(m, 36),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 4),
                _moodPill(mood),
              ],
            ),
          ),
        ],
      );

  Widget _badge(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:
              GroupPlanningUi.moodMatchTabActiveOrange.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: GroupPlanningUi.moodMatchTabActiveOrange
                .withValues(alpha: 0.55),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
      );

  Widget _notesDivider() => Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.white.withValues(alpha: 0.18),
              thickness: 1,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '✏️',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.white.withValues(alpha: 0.18),
              thickness: 1,
              height: 1,
            ),
          ),
        ],
      );

  Widget _notesSection(
    AppLocalizations l10n,
    String partnerFirst,
    String partnerNote,
    String myUid,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Partner's note (read-only) — only if they wrote one
        if (partnerNote.isNotEmpty) ...[
          Text(
            l10n.plannerMoodMatchNotePartnerLabel(partnerFirst),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              partnerNote,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // My note input
        Text(
          l10n.plannerMoodMatchNoteYourLabel,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: TextField(
                  controller: _noteCtrl,
                  maxLength: 120,
                  maxLines: 2,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (_saveState != _NoteSaveState.idle) {
                      setState(() => _saveState = _NoteSaveState.idle);
                    }
                  },
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.plannerMoodMatchNoteHint(partnerFirst),
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _sendButton(l10n),
          ],
        ),
      ],
    );
  }

  Widget _sendButton(AppLocalizations l10n) {
    final String label;
    final bool enabled;
    switch (_saveState) {
      case _NoteSaveState.saving:
        label = l10n.plannerMoodMatchNoteSaving;
        enabled = false;
      case _NoteSaveState.saved:
        label = l10n.plannerMoodMatchNoteSaved;
        enabled = false;
      case _NoteSaveState.error:
        label = '↩';
        enabled = true;
      case _NoteSaveState.idle:
        label = l10n.plannerMoodMatchNoteSave;
        enabled = true;
    }

    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              _saveNote();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _saveState == _NoteSaveState.saved
              ? const Color(0xFF2A6049).withValues(alpha: 0.85)
              : GroupPlanningUi.moodMatchTabActiveOrange
                  .withValues(alpha: enabled ? 0.9 : 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _saveState == _NoteSaveState.saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _shell({required Widget child}) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              GroupPlanningUi.moodMatchDeepSurface,
              GroupPlanningUi.moodMatchDeepMuted,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color:
                GroupPlanningUi.moodMatchTabActiveOrange.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: GroupPlanningUi.moodMatchShadow(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: child,
        ),
      );
}
