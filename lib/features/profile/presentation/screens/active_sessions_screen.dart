import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_providers.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sessionsAsync = ref.watch(activeSessionsProvider);

    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.settingsActiveSessionsTitle,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: SwirlBackground(
        child: sessionsAsync.when(
          data: (sessions) => _buildSessionsList(context, sessions),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildErrorState(context),
        ),
      ),
    );
  }

  Widget _buildSessionsList(BuildContext context, List<ActiveSession> sessions) {
    final l10n = AppLocalizations.of(context)!;
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 24,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.device_unknown, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.activeSessionsNoActiveTitle,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.activeSessionsNoActiveBody,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.activeSessionsCountLabel(sessions.length),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ...sessions.map((session) => _buildSessionCard(context, session)),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => _signOutAllOtherDevices(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Colors.red[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            l10n.activeSessionsSignOutAllOther,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.red[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(BuildContext context, ActiveSession session) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: session.isCurrent
            ? Border.all(color: Colors.green[300]!, width: 2)
            : Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: session.isCurrent ? Colors.green[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getDeviceIcon(session.deviceType),
              color: session.isCurrent ? Colors.green[600] : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.deviceName ?? l10n.activeSessionsUnknownDevice,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    if (session.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.activeSessionsCurrentBadge,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.location ?? l10n.activeSessionsUnknownLocation} • ${_formatDate(context, session.lastActiveAt)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (session.ipAddress != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'IP: ${session.ipAddress}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!session.isCurrent)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () => _signOutSession(context, session),
              tooltip: l10n.activeSessionsSignOutThisDevice,
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              l10n.activeSessionsErrorLoading,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String? deviceType) {
    switch (deviceType) {
      case 'ios':
        return Icons.phone_iphone;
      case 'android':
        return Icons.phone_android;
      case 'web':
        return Icons.computer;
      default:
        return Icons.device_unknown;
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return l10n.activeSessionsTimeJustNow;
      }
      return l10n.activeSessionsTimeHoursAgo(difference.inHours);
    } else if (difference.inDays == 1) {
      return l10n.activeSessionsTimeYesterday;
    } else if (difference.inDays < 7) {
      return l10n.activeSessionsTimeDaysAgo(difference.inDays);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return l10n.activeSessionsTimeWeeksAgo(weeks);
    } else {
      return DateFormat.yMd(Localizations.localeOf(context).toString()).format(date);
    }
  }

  Future<void> _signOutSession(BuildContext context, ActiveSession session) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.activeSessionsDialogSignOutDeviceTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.activeSessionsDialogSignOutDeviceBody(
            session.deviceName ?? l10n.activeSessionsUnknownDevice,
          ),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.activeSessionsDialogCancel, style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.activeSessionsDialogSignOut, style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('active_sessions').delete().eq('id', session.id);

      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: l10n.activeSessionsToastSignedOutDevice,
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: l10n.activeSessionsToastSignOutDeviceError(e.toString()),
          isError: true,
        );
      }
    }
  }

  Future<void> _signOutAllOtherDevices(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.activeSessionsDialogSignOutAllTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.activeSessionsDialogSignOutAllBody,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.activeSessionsDialogCancel, style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.activeSessionsDialogSignOutAllCta, style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('active_sessions')
          .delete()
          .eq('user_id', user.id)
          .eq('is_current', false);

      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: l10n.activeSessionsToastSignedOutAll,
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: l10n.activeSessionsToastSignOutAllError(e.toString()),
          isError: true,
        );
      }
    }
  }
}

