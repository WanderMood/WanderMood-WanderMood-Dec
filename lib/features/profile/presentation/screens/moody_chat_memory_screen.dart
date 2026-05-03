import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/l10n/app_localizations.dart';

const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);

/// Shows [user_preference_patterns.moody_chat_memory] and allows clearing it.
class MoodyChatMemoryScreen extends StatefulWidget {
  const MoodyChatMemoryScreen({super.key});

  @override
  State<MoodyChatMemoryScreen> createState() => _MoodyChatMemoryScreenState();
}

class _MoodyChatMemoryScreenState extends State<MoodyChatMemoryScreen> {
  bool _loading = true;
  Map<String, dynamic> _memory = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final row = await Supabase.instance.client
          .from('user_preference_patterns')
          .select('moody_chat_memory')
          .eq('user_id', user.id)
          .maybeSingle();
      final raw = row?['moody_chat_memory'];
      if (!mounted) return;
      setState(() {
        _memory = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : {};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _hasContent {
    final nick = (_memory['nickname_for_user'] as String?)?.trim() ?? '';
    final em = _list(_memory['emoji_hints']);
    final tone = _list(_memory['tone_notes']);
    final facts = _list(_memory['sticky_facts']);
    return nick.isNotEmpty || em.isNotEmpty || tone.isNotEmpty || facts.isNotEmpty;
  }

  List<String> _list(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
  }

  Future<void> _confirmClear() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.moodyMemoryClearConfirmTitle),
        content: Text(l10n.moodyMemoryClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.moodyMemoryClearConfirmAction,
              style: const TextStyle(color: _wmForest, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('user_preference_patterns').update({
        'moody_chat_memory': <String, dynamic>{
          'version': 1,
          'nickname_for_user': null,
          'emoji_hints': <String>[],
          'tone_notes': <String>[],
          'sticky_facts': <String>[],
        },
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', user.id);
      if (!mounted) return;
      showWanderMoodToast(context, message: l10n.moodyMemoryClearedToast);
      await _load();
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _wmCream,
      appBar: AppBar(
        backgroundColor: _wmWhite,
        elevation: 0,
        foregroundColor: _wmCharcoal,
        title: Text(
          l10n.moodyMemoryTitle,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _wmCharcoal,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _wmForest))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.moodyMemoryLoadError,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: _wmForest,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        l10n.moodyMemorySubtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.4,
                          color: _wmStone,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_hasContent)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _wmWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _wmParchment),
                          ),
                          child: Text(
                            l10n.moodyMemoryEmpty,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              height: 1.45,
                              color: _wmStone,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _wmWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _wmParchment),
                            boxShadow: [
                              BoxShadow(
                                color: _wmCharcoal.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._section(
                                l10n.moodyMemorySectionNickname,
                                (_memory['nickname_for_user'] as String?)?.trim().isNotEmpty == true
                                    ? [(_memory['nickname_for_user'] as String).trim()]
                                    : const <String>[],
                              ),
                              ..._section(l10n.moodyMemorySectionEmoji, _list(_memory['emoji_hints'])),
                              ..._section(l10n.moodyMemorySectionTone, _list(_memory['tone_notes'])),
                              ..._section(l10n.moodyMemorySectionFacts, _list(_memory['sticky_facts'])),
                            ],
                          ),
                        ),
                      const SizedBox(height: 28),
                      if (_hasContent)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _confirmClear,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _wmForest,
                              side: const BorderSide(color: _wmForest, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              l10n.moodyMemoryClear,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _section(String title, List<String> items) {
    if (items.isEmpty) return [];
    return [
      Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _wmForest,
        ),
      ),
      const SizedBox(height: 8),
      ...items.map(
        (s) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _wmForest,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.4,
                    color: _wmCharcoal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }
}
