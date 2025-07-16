import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReservationDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback? onEdit;
  final VoidCallback? onDirections;
  final VoidCallback? onCancel;
  final VoidCallback? onShare;

  const ReservationDetailsSheet({
    Key? key,
    required this.activity,
    this.onEdit,
    this.onDirections,
    this.onCancel,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and actions
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity['title'] ?? 'Activity',
                              style: GoogleFonts.museoModerno(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit' && onEdit != null) onEdit!();
                              if (value == 'cancel' && onCancel != null) onCancel!();
                              if (value == 'share' && onShare != null) onShare!();
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'cancel',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Cancel', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share, size: 18),
                                    SizedBox(width: 8),
                                    Text('Share'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Activity image
                      Container(
                        height: 200,
                        width: double.infinity,
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
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF12B347).withOpacity(0.8),
                                    const Color(0xFF4CAF50).withOpacity(0.6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.image, color: Colors.white, size: 60),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Details
                      _buildDetailRow('📅 Date', activity['date'] ?? ''),
                      _buildDetailRow('⏰ Time', activity['time'] ?? 'TBD'),
                      _buildDetailRow('⏱️ Duration', '${activity['duration'] ?? 60} minutes'),
                      _buildDetailRow('📍 Location', activity['location'] ?? 'TBD'),
                      _buildDetailRow('💰 Price', activity['price'] != null ? '€${activity['price']}' : 'Free Activity'),
                      _buildDetailRow('💳 Payment', activity['paymentStatus'] ?? 'No payment required'),
                      const SizedBox(height: 24),
                      Text('Description', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text(activity['description'] ?? 'No description available', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                      const SizedBox(height: 24),
                      // Moody Advice
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF12B347).withOpacity(0.1),
                              const Color(0xFF12B347).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF12B347).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF12B347),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.lightbulb, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text('Moody advises to:', style: GoogleFonts.museoModerno(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF12B347))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(_getMoodyAdvice(activity), style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF12B347), height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDirections,
                              icon: const Icon(Icons.directions),
                              label: const Text('Get Directions'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF12B347),
                                side: const BorderSide(color: Color(0xFF12B347)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.receipt),
                              label: const Text('View Receipt'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodyAdvice(Map<String, dynamic> activity) {
    // You can copy the advice logic from agenda_screen.dart
    return '• 💚 Be present and enjoy every moment\n• 📍 Arrive a few minutes early to settle in\n• 🌟 Open mind leads to the best experiences\n• 🆓 Free doesn\'t mean less valuable - enjoy fully\n• ✨ This activity was chosen to match your mood perfectly';
  }
} 