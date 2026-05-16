import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Plan met vriend: inviter note (read-only) + optional invitee reply (one message each).
class PlanInviteNoteStrip extends StatefulWidget {
  const PlanInviteNoteStrip({
    super.key,
    required this.inviterName,
    this.inviterAvatarUrl,
    this.inviterMessage,
    this.inviteeName,
    this.inviteeReply,
    this.canReply = false,
    this.onSaveReply,
    this.compact = false,
  });

  final String inviterName;
  final String? inviterAvatarUrl;
  final String? inviterMessage;
  final String? inviteeName;
  final String? inviteeReply;
  final bool canReply;
  final Future<void> Function(String text)? onSaveReply;
  final bool compact;

  @override
  State<PlanInviteNoteStrip> createState() => _PlanInviteNoteStripState();
}

enum _ReplySaveState { idle, saving, saved, error }

class _PlanInviteNoteStripState extends State<PlanInviteNoteStrip> {
  final _replyCtrl = TextEditingController();
  _ReplySaveState _saveState = _ReplySaveState.idle;
  String? _sentReplyText;

  @override
  void initState() {
    super.initState();
    final existing = widget.inviteeReply?.trim();
    if (existing != null && existing.isNotEmpty) {
      _replyCtrl.text = existing;
    }
  }

  @override
  void didUpdateWidget(covariant PlanInviteNoteStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.inviteeReply?.trim() ?? '';
    if (next.isNotEmpty && _replyCtrl.text.trim() != next) {
      _replyCtrl.text = next;
    }
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  bool get _hasInviterNote {
    final m = widget.inviterMessage?.trim();
    return m != null && m.isNotEmpty;
  }

  bool get _hasInviteeReply {
    final r = _effectiveInviteeReply;
    return r != null && r.isNotEmpty;
  }

  String? get _effectiveInviteeReply {
    final saved = widget.inviteeReply?.trim();
    if (saved != null && saved.isNotEmpty) return saved;
    final sent = _sentReplyText?.trim();
    if (sent != null && sent.isNotEmpty) return sent;
    return null;
  }

  bool get _canWriteReply {
    return widget.canReply &&
        widget.onSaveReply != null &&
        !_hasInviteeReply &&
        _saveState != _ReplySaveState.saved;
  }

  Future<void> _saveReply() async {
    final onSave = widget.onSaveReply;
    if (onSave == null || !_canWriteReply) return;
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saveState = _ReplySaveState.saving);
    try {
      await onSave(text);
      if (!mounted) return;
      setState(() {
        _sentReplyText = text;
        _saveState = _ReplySaveState.saved;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveState = _ReplySaveState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInviterNote && !_hasInviteeReply && !_canWriteReply) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final inviterFirst = _firstName(widget.inviterName);
    final replyText = _effectiveInviteeReply;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasInviterNote) ...[
          Text(
            l10n.planMetVriendNoteFrom(inviterFirst),
            style: GoogleFonts.poppins(
              fontSize: widget.compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: GroupPlanningUi.stone,
            ),
          ),
          SizedBox(height: widget.compact ? 4 : 6),
          _NoteBubble(
            avatarUrl: widget.inviterAvatarUrl,
            fallbackInitial: inviterFirst,
            text: widget.inviterMessage!.trim(),
            compact: widget.compact,
          ),
        ],
        if (replyText != null && replyText.isNotEmpty) ...[
          SizedBox(height: widget.compact ? 8 : 10),
          Text(
            l10n.planMetVriendReplyFrom(
              _firstName(widget.inviteeName ?? l10n.moodMatchFriendThey),
            ),
            style: GoogleFonts.poppins(
              fontSize: widget.compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: GroupPlanningUi.stone,
            ),
          ),
          SizedBox(height: widget.compact ? 4 : 6),
          _NoteBubble(
            text: replyText,
            compact: widget.compact,
            tint: GroupPlanningUi.forestTint,
          ),
        ],
        if (_canWriteReply) ...[
          SizedBox(height: widget.compact ? 8 : 12),
          Text(
            l10n.planMetVriendReplyOptional,
            style: GoogleFonts.poppins(
              fontSize: widget.compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: GroupPlanningUi.stone,
            ),
          ),
          SizedBox(height: widget.compact ? 4 : 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  maxLength: 80,
                  maxLines: 2,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (_saveState != _ReplySaveState.idle) {
                      setState(() => _saveState = _ReplySaveState.idle);
                    }
                  },
                  style: GoogleFonts.poppins(
                    fontSize: widget.compact ? 12 : 13,
                    color: GroupPlanningUi.charcoal,
                    height: 1.35,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.planMetVriendReplyHint(inviterFirst),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: widget.compact ? 8 : 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: GroupPlanningUi.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: GroupPlanningUi.cardBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SendChip(
                l10n: l10n,
                state: _saveState,
                onTap: _saveReply,
                compact: widget.compact,
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _firstName(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t.split(RegExp(r'\s+')).first;
  }
}

class _NoteBubble extends StatelessWidget {
  const _NoteBubble({
    required this.text,
    this.avatarUrl,
    this.fallbackInitial,
    this.compact = false,
    this.tint,
  });

  final String text;
  final String? avatarUrl;
  final String? fallbackInitial;
  final bool compact;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final bg = tint ?? Colors.white;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GroupPlanningUi.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (avatarUrl != null || fallbackInitial != null) ...[
            CircleAvatar(
              radius: compact ? 12 : 14,
              backgroundColor: GroupPlanningUi.forestTint,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? Text(
                      (fallbackInitial ?? '?').substring(0, 1).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        color: GroupPlanningUi.forest,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: compact ? 8 : 10),
          ],
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: compact ? 12 : 13,
                color: GroupPlanningUi.charcoal,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendChip extends StatelessWidget {
  const _SendChip({
    required this.l10n,
    required this.state,
    required this.onTap,
    required this.compact,
  });

  final AppLocalizations l10n;
  final _ReplySaveState state;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String label;
    final bool enabled;
    switch (state) {
      case _ReplySaveState.saving:
        label = l10n.planMetVriendReplySaving;
        enabled = false;
      case _ReplySaveState.saved:
        label = l10n.planMetVriendReplySent;
        enabled = false;
      case _ReplySaveState.error:
        label = '↩';
        enabled = true;
      case _ReplySaveState.idle:
        label = l10n.planMetVriendReplySend;
        enabled = true;
    }

    return Material(
      color: enabled ? GroupPlanningUi.forest : GroupPlanningUi.stone,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 9 : 11,
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
