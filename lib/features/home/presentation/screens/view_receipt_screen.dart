import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';

class ViewReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> activity;
  
  const ViewReceiptScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SwirlBackground(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              snap: true,
              leading: IconButton(
                onPressed: () {
                  if (kDebugMode) debugPrint('Back from receipt screen');
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/agenda');
                  }
                },
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF12B347),
                    size: 20,
                  ),
                ),
              ),
              title: Text(
                'Receipt',
                style: GoogleFonts.museoModerno(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF12B347),
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
              actions: [
                IconButton(
                  onPressed: () => _copyReceiptDetails(context),
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.copy,
                      color: Color(0xFF12B347),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            
            // Receipt Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Receipt Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header with payment confirmed
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF12B347), Color(0xFF4CAF50)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 60,
                                ).animate().scale(delay: 200.ms, duration: 600.ms),
                                const SizedBox(height: 16),
                                Text(
                                  'Payment Confirmed',
                                  style: GoogleFonts.museoModerno(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ).animate().fadeIn(delay: 400.ms),
                                const SizedBox(height: 8),
                                Text(
                                  'Your booking is confirmed',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ).animate().fadeIn(delay: 600.ms),
                              ],
                            ),
                          ),
                          
                          // Activity Details
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Activity Image and Title
                                Row(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: CachedNetworkImage(
                                          imageUrl: activity['imageUrl'] ?? '',
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: const Color(0xFF12B347).withOpacity(0.2),
                                            child: const Icon(
                                              Icons.image,
                                              color: Color(0xFF12B347),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activity['title'] ?? 'Activity',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            activity['location'] ?? 'Location TBD',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.blue),
                                            ),
                                            child: Text(
                                              'PAID',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Receipt Details
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildReceiptRow('Booking ID', _generateBookingId()),
                                      _buildReceiptRow('Date', _formatDate(activity['date'])),
                                      _buildReceiptRow('Time', activity['time'] ?? 'TBD'),
                                      _buildReceiptRow('Duration', '${activity['duration'] ?? 60} minutes'),
                                      _buildReceiptRow('Guests', '1 Adult'),
                                      
                                      const Divider(height: 32),
                                      
                                      _buildReceiptRow('Subtotal', '€${(activity['price'] ?? 0.0).toStringAsFixed(2)}'),
                                      _buildReceiptRow('Service Fee', '€2.50'),
                                      _buildReceiptRow('Tax', '€${((activity['price'] ?? 0.0) * 0.21).toStringAsFixed(2)}'),
                                      
                                      const Divider(height: 32),
                                      
                                      _buildReceiptRow(
                                        'Total',
                                        '€${((activity['price'] ?? 0.0) + 2.50 + ((activity['price'] ?? 0.0) * 0.21)).toStringAsFixed(2)}',
                                        isTotal: true,
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      _buildReceiptRow('Payment Method', 'Credit Card •••• 4242'),
                                      _buildReceiptRow('Payment Date', _formatPaymentDate()),
                                      _buildReceiptRow('Transaction ID', _generateTransactionId()),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Important Notes
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.amber[800],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Important Information',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.amber[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '• Please arrive 15 minutes before your scheduled time\n• Bring a valid ID for verification\n• Cancellation possible up to 24 hours before\n• Full refund available for cancellations',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.amber[800],
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
                    
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _downloadReceipt(context),
                            icon: const Icon(Icons.download),
                            label: const Text('Download PDF'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF12B347),
                              side: const BorderSide(color: Color(0xFF12B347)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareReceipt(context),
                            icon: const Icon(Icons.share),
                            label: const Text('Share Receipt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF12B347),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 800.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReceiptRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: isTotal ? Colors.black87 : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? const Color(0xFF12B347) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  String _formatPaymentDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
  
  String _generateBookingId() {
    return 'WM${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }
  
  String _generateTransactionId() {
    return 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
  }
  
  void _copyReceiptDetails(BuildContext context) {
    final receiptText = '''
Receipt - ${activity['title']}
Booking ID: ${_generateBookingId()}
Date: ${_formatDate(activity['date'])}
Time: ${activity['time']}
Location: ${activity['location']}
Amount: €${activity['price']}
Payment: Confirmed
''';
    
    Clipboard.setData(ClipboardData(text: receiptText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Receipt details copied to clipboard',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF12B347),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  void _downloadReceipt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Receipt download started',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF12B347),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  void _shareReceipt(BuildContext context) {
    final receiptText = '''
🎯 WanderMood Receipt

📍 Activity: ${activity['title']}
📅 Date: ${_formatDate(activity['date'])}
🕐 Time: ${activity['time']}
📍 Location: ${activity['location']}
💰 Total: €${activity['price']}
🎫 Booking ID: ${_generateBookingId()}
✅ Status: Confirmed

Thank you for booking with WanderMood! 🌟
''';
    
    Clipboard.setData(ClipboardData(text: receiptText));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.share,
              color: const Color(0xFF12B347),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Share Receipt',
              style: GoogleFonts.museoModerno(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF12B347),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt details copied to clipboard!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                receiptText,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can now paste this in any app to share your receipt!',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Could integrate with share_plus package here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Receipt ready to share! 📱',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: const Color(0xFF12B347),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12B347),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 