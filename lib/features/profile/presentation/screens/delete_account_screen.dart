import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/settings_screen_template.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/services/notification_service.dart';
import 'package:wandermood/core/services/push_notification_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    if (_confirmController.text != l10n.deleteAccountConfirmKeyword) {
      showWanderMoodToast(
        context,
        message: l10n.deleteAccountTypeIncorrect,
        backgroundColor: Colors.orange,
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.deleteAccountFinalTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteAccountFinalContent,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.deleteAccountCancel, style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.deleteAccountDeleteForever, style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _isDeleting = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final userId = user.id;

      // Delete all user data (best effort; some tables may not exist in every env).
      try { await supabase.from('post_likes').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('post_comments').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('diary_entries').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('friendships').delete().eq('requester_id', userId); } catch (_) {}
      try { await supabase.from('friendships').delete().eq('addressee_id', userId); } catch (_) {}
      try { await supabase.from('social_posts').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('travel_plans').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('saved_places').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('visited_places').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('scheduled_activities').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('user_check_ins').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('moods').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('mood_entries').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('notification_settings').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('account_security').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('active_sessions').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('push_tokens').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('data_exports').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('subscriptions').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('user_preferences').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('realtime_events').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('user_presence').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('profiles').delete().eq('id', userId); } catch (_) {}

      // Delete the auth user from Supabase (removes from Authentication → Users).
      // Requires Edge Function with service_role; anon client cannot delete users.
      final deleteUserResponse = await supabase.functions.invoke('delete-user');
      final data = deleteUserResponse.data;
      final hasError = deleteUserResponse.status != 200 ||
          data == null ||
          (data is Map && (data['error'] != null || data['success'] != true));
      if (hasError) {
        final errMsg = data is Map
            ? (data['detail'] ?? data['error'] ?? 'Failed to delete account') as String?
            : 'Failed to delete account';
        throw Exception(errMsg ?? 'Failed to delete account');
      }

      // OS-scheduled local reminders (Moody check-ins, re-engagement, etc.) survive
      // prefs/auth deletion unless we cancel them. Remote FCM also needs token revoke.
      try {
        await NotificationService.instance.cancelAll();
      } catch (_) {}
      try {
        await PushNotificationService.instance.revokeDevicePushRegistration();
      } catch (_) {}

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (_) {}

      await supabase.auth.signOut();

      if (mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.deleteAccountSuccess,
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.deleteAccountError,
          isError: true,
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsScreenTemplate(
      title: l10n.deleteAccountTitle,
      onBack: () => context.pop(),
      danger: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFECACA),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.delete_outline,
                  size: 48,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.deleteAccountAreYouSure,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.deleteAccountWarning,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF374151),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.deleteAccountWhatWillBeDeleted,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          _buildDeleteItem(l10n.deleteAccountProfile),
          _buildDeleteItem(l10n.deleteAccountActivities),
          _buildDeleteItem(l10n.deleteAccountAchievements),
          _buildDeleteItem(l10n.deleteAccountPhotos),
          const SizedBox(height: 24),
          Text(
            l10n.deleteAccountTypeToConfirm,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: l10n.deleteAccountConfirmKeyword,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFFCA5A5),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFFCA5A5),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isDeleting ? null : _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.deleteAccountDeleteButton,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isDeleting ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.deleteAccountCancel,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.close,
            size: 16,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
