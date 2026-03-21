import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_providers.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class PremiumUpgradeScreen extends ConsumerStatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  ConsumerState<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends ConsumerState<PremiumUpgradeScreen> {
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;
  
  // Card details
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'card' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // TODO: Integrate with Stripe or payment provider
      // For now, we'll simulate the payment and update subscription
      // In production, you would:
      // 1. Create a payment intent with Stripe
      // 2. Process the payment
      // 3. On success, update the subscription

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Update subscription in database
      final expiresAt = DateTime.now().add(const Duration(days: 30)); // 1 month subscription
      
      await supabase.from('subscriptions').upsert({
        'user_id': user.id,
        'plan_type': 'premium',
        'status': 'active',
        'started_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      });

      // Invalidate subscription provider
      ref.invalidate(subscriptionProvider);

      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Premium subscription activated!',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Payment failed: $e',
          isError: true,
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Upgrade to Premium',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: SwirlBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 24,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            children: [
            // Premium Benefits Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'Premium',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildPremiumFeature(Icons.check, 'Unlimited activity suggestions'),
                  _buildPremiumFeature(Icons.check, 'Advanced mood matching'),
                  _buildPremiumFeature(Icons.check, 'Priority support'),
                  _buildPremiumFeature(Icons.check, 'No ads'),
                  _buildPremiumFeature(Icons.check, 'Early access to new features'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pricing
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Plan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '€4.99/month',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Best Value',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method Selection
            Text(
              'Payment Method',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodOption('card', 'Credit/Debit Card', Icons.credit_card),
            const SizedBox(height: 8),
            _buildPaymentMethodOption('paypal', 'PayPal', Icons.payment),
            const SizedBox(height: 8),
            _buildPaymentMethodOption('apple', 'Apple Pay', Icons.phone_iphone),
            const SizedBox(height: 24),

            // Card Form (if card selected)
            if (_selectedPaymentMethod == 'card') ...[
              _buildCardForm(),
              const SizedBox(height: 24),
            ],

            // Payment Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Subscribe for €4.99/month',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Security Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment information is encrypted and secure',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.orange[400]! : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.orange[600] : Colors.grey[600]),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.orange[600])
            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
        onTap: () => setState(() => _selectedPaymentMethod = value),
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Card number is required';
              }
              if (value.replaceAll(' ', '').length < 13) {
                return 'Invalid card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    hintText: '12/25',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (value.length < 3) {
                      return 'Invalid CVV';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              hintText: 'John Doe',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

