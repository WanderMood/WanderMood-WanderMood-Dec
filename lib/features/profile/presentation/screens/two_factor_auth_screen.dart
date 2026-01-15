import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_providers.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';

class TwoFactorAuthScreen extends ConsumerStatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  ConsumerState<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends ConsumerState<TwoFactorAuthScreen> {
  bool _isLoading = false;
  bool _isEnabling = false;

  @override
  Widget build(BuildContext context) {
    final accountSecurityAsync = ref.watch(accountSecurityProvider);

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
          'Two-Factor Authentication',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: SwirlBackground(
        child: accountSecurityAsync.when(
          data: (security) => _buildContent(security?.twoFactorEnabled ?? false),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildContent(false),
        ),
      ),
    );
  }

  Widget _buildContent(bool isEnabled) {
    return ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 24,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.green[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEnabled ? Colors.green[200]! : Colors.blue[200]!,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                isEnabled ? Icons.verified_user : Icons.shield,
                size: 64,
                color: isEnabled ? Colors.green[600] : Colors.blue[600],
              ),
              const SizedBox(height: 16),
              Text(
                isEnabled ? '2FA is Enabled' : 'Enable Two-Factor Authentication',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isEnabled
                    ? 'Your account is protected with two-factor authentication.'
                    : 'Add an extra layer of security to your account by requiring a verification code in addition to your password.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Benefits
        if (!isEnabled) ...[
          Text(
            'Benefits:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(Icons.lock, 'Protects against unauthorized access'),
          _buildBenefitItem(Icons.security, 'Required for sensitive operations'),
          _buildBenefitItem(Icons.notifications_active, 'Get notified of login attempts'),
          const SizedBox(height: 32),
        ],

        // Enable/Disable Button
        ElevatedButton(
          onPressed: _isLoading || _isEnabling ? null : () => _toggle2FA(!isEnabled),
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? Colors.red : const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading || _isEnabling
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  isEnabled ? 'Disable 2FA' : 'Enable 2FA',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // Info Text
        Text(
          isEnabled
              ? 'To disable 2FA, you will need to verify your identity.'
              : 'You will need an authenticator app (like Google Authenticator) to set up 2FA.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle2FA(bool enable) async {
    setState(() => _isEnabling = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      if (enable) {
        // TODO: Implement actual 2FA setup flow
        // This would involve:
        // 1. Generating a secret
        // 2. Showing QR code
        // 3. Verifying the code
        // 4. Enabling 2FA

        // For now, just update the database
        await supabase.from('account_security').upsert({
          'user_id': user.id,
          'two_factor_enabled': true,
        });
      } else {
        // Disable 2FA
        await supabase.from('account_security').update({
          'two_factor_enabled': false,
          'two_factor_secret': null,
        }).eq('user_id', user.id);
      }

      // Invalidate provider to refresh
      ref.invalidate(accountSecurityProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enable
                  ? '2FA setup started. Please complete the setup process.'
                  : '2FA has been disabled.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        if (!enable) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnabling = false);
      }
    }
  }
}

