import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/settings_screen_template.dart';

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
    if (_confirmController.text != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please type DELETE to confirm'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Final Confirmation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete Forever', style: GoogleFonts.poppins(color: Colors.white)),
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

      // Delete all user data
      try { await supabase.from('post_likes').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('post_comments').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('diary_entries').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('friendships').delete().eq('requester_id', userId); } catch (_) {}
      try { await supabase.from('friendships').delete().eq('addressee_id', userId); } catch (_) {}
      try { await supabase.from('travel_plans').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('saved_places').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('mood_entries').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('notification_settings').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('account_security').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('active_sessions').delete().eq('user_id', userId); } catch (_) {}
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

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (_) {}

      await supabase.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenTemplate(
      title: 'Delete Account',
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
                  'Are you sure?',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone. All your data, activities, and preferences will be permanently deleted.',
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
            'What will be deleted:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          _buildDeleteItem('Your profile and preferences'),
          _buildDeleteItem('All saved activities'),
          _buildDeleteItem('Your achievements and progress'),
          _buildDeleteItem('All photos and memories'),
          const SizedBox(height: 24),
          Text(
            'Type "DELETE" to confirm',
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
              hintText: 'DELETE',
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
                      'Delete My Account Forever',
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
                'Cancel',
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
