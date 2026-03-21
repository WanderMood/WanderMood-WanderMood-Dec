import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/screens/booking_confirmation_screen.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class PaymentScreen extends StatefulWidget {
  final Place place;
  final String bookingType;
  final DateTime date;
  final String time;
  final int guests;
  final double totalPrice;

  const PaymentScreen({
    Key? key,
    required this.place,
    required this.bookingType,
    required this.date,
    required this.time,
    required this.guests,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedPaymentMethod = 'card';
  String? _selectedBank;
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isProcessing = false;
  bool _saveCard = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
        ),
        title: Text(
          'Payment',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBookingSummary(),
                  const SizedBox(height: 32),
                  _buildPaymentMethods(),
                  const SizedBox(height: 24),
                  if (_selectedPaymentMethod == 'card') ...[
                    _buildCardForm(),
                    const SizedBox(height: 24),
                  ],
                  if (_selectedPaymentMethod == 'ideal') ...[
                    _buildIDealBankSelection(),
                    const SizedBox(height: 24),
                  ],
                  _buildSecurityNotice(),
                  const SizedBox(height: 32),
                  _buildPayButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: const Color(0xFF2A6049),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Booking Summary',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Location', widget.place.name),
          _buildSummaryRow('Date', DateFormat('EEEE, MMMM d, yyyy').format(widget.date)),
          _buildSummaryRow('Time', widget.time),
          _buildSummaryRow('Guests', '${widget.guests} guest${widget.guests > 1 ? 's' : ''}'),
          _buildSummaryRow('Experience', widget.bookingType),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '€${widget.totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2A6049),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          'card',
          'Credit/Debit Card',
          Icons.credit_card,
          'Visa, Mastercard, American Express',
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'apple_pay',
          'Apple Pay',
          Icons.apple,
          'Touch ID or Face ID',
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'google_pay',
          'Google Pay',
          Icons.account_balance_wallet,
          'Quick and secure',
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'paypal',
          'PayPal',
          Icons.payment,
          'Pay with your PayPal account',
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'ideal',
          'iDEAL',
          Icons.account_balance,
          'Dutch online banking',
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String value, String title, IconData icon, String subtitle) {
    final isSelected = _selectedPaymentMethod == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
          // Reset bank selection when switching away from iDEAL
          if (value != 'ideal') {
            _selectedBank = null;
          }
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A6049).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A6049) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2A6049) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2A6049),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💳 Card Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Card Number
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
              LengthLimitingTextInputFormatter(19),
            ],
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.credit_card),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter card number';
              }
              if (value.replaceAll(' ', '').length < 16) {
                return 'Invalid card number';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Expiry Date
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryDateFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'MM/YY',
                    hintText: '12/25',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (value.length < 5) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // CVV
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.help_outline),
                      onPressed: () {
                        _showCVVHelp();
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (value.length < 3) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Cardholder Name
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              hintText: 'John Doe',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter cardholder name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Save Card Option
          Row(
            children: [
              Checkbox(
                value: _saveCard,
                onChanged: (value) {
                  setState(() {
                    _saveCard = value ?? false;
                  });
                },
                activeColor: const Color(0xFF2A6049),
              ),
              Expanded(
                child: Text(
                  'Save this card for future bookings',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIDealBankSelection() {
    final banks = [
      {'name': 'ABN AMRO', 'icon': Icons.account_balance},
      {'name': 'ING', 'icon': Icons.account_balance},
      {'name': 'Rabobank', 'icon': Icons.account_balance},
      {'name': 'SNS Bank', 'icon': Icons.account_balance},
      {'name': 'ASN Bank', 'icon': Icons.account_balance},
      {'name': 'Bunq', 'icon': Icons.account_balance},
      {'name': 'Triodos Bank', 'icon': Icons.account_balance},
      {'name': 'Van Lanschot', 'icon': Icons.account_balance},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance,
                color: Colors.orange[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '🏦 Select Your Bank',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Choose your bank to continue with iDEAL payment',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: banks.length,
            itemBuilder: (context, index) {
              final bank = banks[index];
              final isSelected = _selectedBank == bank['name'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBank = bank['name'] as String;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.orange[400]! : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        bank['icon'] as IconData,
                        color: isSelected ? Colors.orange[700] : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bank['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.orange[800] : Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Colors.orange[600],
                          size: 16,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.blue[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔒 Secure Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
                Text(
                  'Your payment information is encrypted and secure. We never store your card details.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A6049),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // Pill-shaped button
          ),
          elevation: 2,
        ),
        child: _isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing Payment...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pay €${widget.totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showCVVHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'What is CVV?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'CVV (Card Verification Value) is a 3 or 4 digit number on your card. For Visa and Mastercard, it\'s on the back. For American Express, it\'s on the front.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(color: const Color(0xFF2A6049)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'card' && !_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedPaymentMethod == 'ideal' && _selectedBank == null) {
      showWanderMoodToast(
        context,
        message: 'Please select your bank to continue with iDEAL',
        isError: true,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();

         // Simulate payment processing with different times for different methods
     int processingTime = 3;
     if (_selectedPaymentMethod == 'apple_pay' || _selectedPaymentMethod == 'google_pay') {
       processingTime = 2;
     } else if (_selectedPaymentMethod == 'paypal') {
       processingTime = 4;
     } else if (_selectedPaymentMethod == 'ideal') {
       processingTime = 3; // iDEAL typically takes a few seconds to redirect and confirm
     }

    await Future.delayed(Duration(seconds: processingTime));

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      // Navigate to confirmation screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            place: widget.place,
            bookingType: widget.bookingType,
            date: widget.date,
            time: widget.time,
            guests: widget.guests,
            totalPrice: widget.totalPrice,
          ),
        ),
      );
    }
  }
}

// Custom formatters for card input
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.length <= 2) {
      return newValue;
    }
    
    final buffer = StringBuffer();
    buffer.write(text.substring(0, 2));
    buffer.write('/');
    buffer.write(text.substring(2));
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
} 