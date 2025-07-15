import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class EditActivityScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> activity;

  const EditActivityScreen({
    super.key,
    required this.activity,
  });

  @override
  ConsumerState<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends ConsumerState<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Editable booking details
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _partyController;
  late TextEditingController _notesController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize editable booking details
    _selectedDate = DateTime.parse(widget.activity['date'] ?? DateTime.now().toIso8601String());
    _selectedTime = _parseTime(widget.activity['time'] ?? '10:00 AM');
    _partyController = TextEditingController(text: widget.activity['partySize']?.toString() ?? '2');
    _notesController = TextEditingController(text: widget.activity['personalNotes'] ?? '');
  }

  @override
  void dispose() {
    _partyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timePart = parts[0].split(':');
      final hour = int.parse(timePart[0]);
      final minute = int.parse(timePart[1]);
      final isPM = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      
      int adjustedHour = hour;
      if (isPM && hour != 12) {
        adjustedHour = hour + 12;
      } else if (!isPM && hour == 12) {
        adjustedHour = 0;
      }
      
      return TimeOfDay(hour: adjustedHour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF12B347).withOpacity(0.1),
              const Color(0xFF12B347).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        print('🔙 Back button pressed on manage booking screen');
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Manage Booking',
                        style: GoogleFonts.museoModerno(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF12B347),
                        ),
                      ),
                    ),
                    Container(
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
                        Icons.bookmark,
                        color: Color(0xFF12B347),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Activity Image
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: widget.activity['imageUrl'] ?? 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF12B347),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFF12B347).withOpacity(0.2),
                                child: const Icon(
                                  Icons.image,
                                  color: Color(0xFF12B347),
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),

                        const SizedBox(height: 24),

                        // Fixed Activity Information (Read-Only)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
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
                                    Icons.info_outline,
                                    color: const Color(0xFF12B347),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Activity Information',
                                    style: GoogleFonts.museoModerno(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              _buildReadOnlyField(
                                label: 'Activity Name',
                                value: widget.activity['title'] ?? 'Activity',
                                icon: Icons.event,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              _buildReadOnlyField(
                                label: 'Description',
                                value: widget.activity['description'] ?? 'No description available',
                                icon: Icons.description,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              _buildReadOnlyField(
                                label: 'Location',
                                value: widget.activity['location'] ?? 'Location TBD',
                                icon: Icons.location_on,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildReadOnlyField(
                                      label: 'Duration',
                                      value: '${widget.activity['duration'] ?? 60} minutes',
                                      icon: Icons.access_time,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildReadOnlyField(
                                      label: 'Price',
                                      value: _getFormattedPrice(),
                                      icon: Icons.euro,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.3),

                        const SizedBox(height: 24),

                        // Editable Booking Details
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
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
                                    Icons.edit,
                                    color: const Color(0xFF12B347),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Your Booking Details',
                                    style: GoogleFonts.museoModerno(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Date and Time Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDateTimeField(
                                      label: 'Booking Date',
                                      icon: Icons.calendar_today,
                                      value: _formatDate(_selectedDate),
                                      onTap: _selectDate,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDateTimeField(
                                      label: 'Preferred Time',
                                      icon: Icons.access_time,
                                      value: _selectedTime.format(context),
                                      onTap: _selectTime,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Party Size
                              _buildTextField(
                                controller: _partyController,
                                label: 'Number of People',
                                icon: Icons.group,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter number of people';
                                  }
                                  final number = int.tryParse(value);
                                  if (number == null || number < 1) {
                                    return 'Please enter a valid number';
                                  }
                                  if (number > 20) {
                                    return 'Maximum 20 people per booking';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Personal Notes
                              _buildTextField(
                                controller: _notesController,
                                label: 'Personal Notes (Optional)',
                                icon: Icons.note_add,
                                maxLines: 3,
                                hintText: 'Any special requests or preferences...',
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.3),

                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showCancelBookingDialog(context),
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancel Booking'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
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
                                onPressed: _updateBooking,
                                icon: const Icon(Icons.save),
                                label: const Text('Update Booking'),
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
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF12B347),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF12B347), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF12B347),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedPrice() {
    final paymentStatus = widget.activity['paymentStatus'] ?? 'free';
    final price = widget.activity['price'] ?? 0.0;
    
    if (paymentStatus == 'free') {
      return 'Free';
    } else if (price > 0) {
      return '€${price.toStringAsFixed(2)} per person';
    } else {
      return 'Price TBD';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF12B347),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF12B347),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _updateBooking() {
    if (_formKey.currentState!.validate()) {
      final partySize = int.parse(_partyController.text);
      final notes = _notesController.text.trim();
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF12B347),
              ),
              const SizedBox(height: 16),
              Text(
                'Updating your booking...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
      
      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop(); // Close loading dialog
        
        // TODO: Update booking in backend/storage
        // Here you would typically call your API to update the booking
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF12B347),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Booking Updated!',
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
                  'Your booking has been successfully updated:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12B347).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF12B347).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📅 Date: ${_formatDate(_selectedDate)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF12B347),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🕐 Time: ${_selectedTime.format(context)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF12B347),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '👥 Party Size: ${partySize} ${partySize == 1 ? 'person' : 'people'}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF12B347),
                        ),
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '📝 Notes: $notes',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF12B347),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close success dialog
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(); // Go back to agenda
                  } else {
                    context.go('/agenda');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12B347),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      });
    }
  }

  void _showCancelBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Booking',
          style: GoogleFonts.museoModerno(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your booking for:',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '"${widget.activity['title']}"',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF12B347),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone. Check the cancellation policy for potential fees.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Keep Booking',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel Booking',
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

  void _cancelBooking() {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Cancelling your booking...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close loading dialog
      
      // TODO: Cancel booking in backend/storage
      // Here you would typically call your API to cancel the booking
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.cancel,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Booking Cancelled',
                style: GoogleFonts.museoModerno(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your booking has been successfully cancelled:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Activity: ${widget.activity['title']}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📅 Original Date: ${_formatDate(_selectedDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '💰 Refund Status: Processing',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Refund will be processed according to cancellation policy. You will receive a confirmation email shortly.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close success dialog
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(); // Go back to agenda
                } else {
                  context.go('/agenda');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
} 