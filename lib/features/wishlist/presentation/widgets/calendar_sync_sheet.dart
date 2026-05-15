import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;
import 'package:url_launcher/url_launcher.dart';

const _wmForest = Color(0xFF2A6049);
const _wmCharcoal = Color(0xFF1A1714);

class CalendarSyncSheet extends StatelessWidget {
  const CalendarSyncSheet({
    super.key,
    required this.title,
    required this.date,
    this.location,
    this.onSynced,
  });

  final String title;
  final DateTime date;
  final String? location;
  final VoidCallback? onSynced;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required DateTime date,
    String? location,
    VoidCallback? onSynced,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF5F0E8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CalendarSyncSheet(
        title: title,
        date: date,
        location: location,
        onSynced: onSynced,
      ),
    );
  }

  DateTime get _start => DateTime(date.year, date.month, date.day, 19, 0);
  DateTime get _end => _start.add(const Duration(hours: 2));

  String _formatUtc(DateTime d) {
    final raw = d.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '');
    return '${raw.split('.').first}Z';
  }

  String _icsContent() {
    final start = _formatUtc(_start);
    final end = _formatUtc(_end);
    final loc = location ?? '';
    return '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//WanderMood//Plan met vriend//NL
BEGIN:VEVENT
UID:wandermood-pmv-${date.millisecondsSinceEpoch}@wandermood.app
DTSTAMP:$start
DTSTART:$start
DTEND:$end
SUMMARY:${title.replaceAll('\n', ' ')}
${loc.isNotEmpty ? 'LOCATION:$loc' : ''}
DESCRIPTION:Gepland via WanderMood — Plan met vriend
END:VEVENT
END:VCALENDAR
'''.trim();
  }

  Uri _googleCalendarUrl() {
    final df = DateFormat('yyyyMMdd\'T\'HHmmss');
    final params = {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${df.format(_start.toUtc())}Z/${df.format(_end.toUtc())}Z',
      if (location != null && location!.isNotEmpty) 'location': location!,
      'details': 'Gepland via WanderMood',
    };
    return Uri.https('calendar.google.com', '/calendar/render', params);
  }

  Uri _outlookUrl() {
    final df = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
    final params = {
      'path': '/calendar/action/compose',
      'rru': 'addevent',
      'subject': title,
      'startdt': df.format(_start),
      'enddt': df.format(_end),
      if (location != null && location!.isNotEmpty) 'location': location!,
    };
    return Uri.https('outlook.live.com', '/calendar/0/deeplink/compose', params);
  }

  Future<void> _open(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _done(BuildContext context) {
    onSynced?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('EEEE d MMMM', 'nl').format(date);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E2D8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Zet in je agenda',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _wmCharcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$title · $dayLabel',
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0x8C1A1714)),
            ),
            const SizedBox(height: 20),
            _CalendarButton(
              icon: Icons.calendar_month,
              label: 'Google Agenda',
              onTap: () async {
                await _open(_googleCalendarUrl());
                if (context.mounted) _done(context);
              },
            ),
            const SizedBox(height: 10),
            _CalendarButton(
              icon: Icons.mail_outline,
              label: 'Outlook',
              onTap: () async {
                await _open(_outlookUrl());
                if (context.mounted) _done(context);
              },
            ),
            const SizedBox(height: 10),
            _CalendarButton(
              icon: Icons.ios_share,
              label: 'ICS-bestand delen',
              onTap: () async {
                await SharePlus.instance.share(
                  ShareParams(text: _icsContent(), subject: title),
                );
                if (context.mounted) _done(context);
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _done(context),
              child: Text(
                'Later',
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

class _CalendarButton extends StatelessWidget {
  const _CalendarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: _wmForest),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _wmCharcoal,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFE8E2D8)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
