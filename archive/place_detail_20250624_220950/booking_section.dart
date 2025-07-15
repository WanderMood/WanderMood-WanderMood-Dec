import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/core/theme/app_theme.dart';
import '../../models/place.dart';
import '../screens/booking_confirmation_screen.dart';

class BookingSection extends StatefulWidget {
  final Place place;

  const BookingSection({required this.place, Key? key}) : super(key: key);

  @override
  State<BookingSection> createState() => _BookingSectionState();
}

class _BookingSectionState extends State<BookingSection> {
  // Add a key for animations
  final _priceKey = GlobalKey<State>();

  int _quantity = 2;
  String _selectedDate = DateFormat('EEE, MMM d').format(DateTime.now().add(const Duration(days: 1)));
  
  // This would come from an API in a real app
  final Map<String, dynamic> _bookingOptions = {
    '🎟 Ticket Only': {
      'price': 12.50,
      'description': 'Basic entrance ticket',
      'url': 'https://getyourguide.com',
    },
    '🧭 Guided Tour': {
      'price': 25.00,
      'description': 'Guided tour with expert',
      'url': 'https://viator.com',
    },
    '👑 VIP Experience': {
      'price': 45.00,
      'description': 'Skip the line + special access',
      'url': 'https://booking.com',
    },
  };
  
  String _selectedOption = '🎟 Ticket Only';

  void _showDatePicker() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF12B347),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedDate != null) {
      setState(() {
        _selectedDate = DateFormat('EEE, MMM d').format(selectedDate);
      });
    }
  }

  void _showBookingOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Book ${widget.place.name}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Select Option',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Options
                  ..._bookingOptions.entries.map((entry) {
                    final option = entry.key;
                    final details = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedOption == option
                            ? const Color(0xFF12B347).withOpacity(0.1)
                            : Colors.grey.shade50,
                        border: Border.all(
                          color: _selectedOption == option
                              ? const Color(0xFF12B347)
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: RadioListTile<String>(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              option,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              '€${details['price'].toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF12B347),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          details['description'],
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: option,
                        groupValue: _selectedOption,
                        activeColor: const Color(0xFF12B347),
                        onChanged: (value) {
                          setModalState(() {
                            _selectedOption = value!;
                          });
                          setState(() {
                            _selectedOption = value!;
                          });
                        },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                  // Date selector
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Date',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: const Color(0xFF12B347),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      
                      if (selectedDate != null) {
                        setModalState(() {
                          _selectedDate = DateFormat('EEE, MMM d').format(selectedDate);
                        });
                        setState(() {
                          _selectedDate = DateFormat('EEE, MMM d').format(selectedDate);
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.calendar_today, 
                      color: Color(0xFF12B347),
                      size: 18,
                    ),
                    label: Text(
                      _selectedDate,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      side: const BorderSide(color: Color(0xFF12B347)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Quantity selector
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quantity',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            setModalState(() {
                              if (_quantity > 1) _quantity--;
                            });
                            setState(() {
                              if (_quantity > 1) {
                                _quantity--;
                                HapticFeedback.selectionClick();
                              }
                            });
                          },
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Color(0xFF12B347),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _quantity.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setModalState(() {
                              if (_quantity < 10) _quantity++;
                            });
                            setState(() {
                              if (_quantity < 10) {
                                _quantity++;
                                HapticFeedback.selectionClick();
                              }
                            });
                          },
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFF12B347),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12B347).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '€${(_bookingOptions[_selectedOption]['price'] * _quantity).toStringAsFixed(2)}',
                          key: _priceKey,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF12B347),
                          ),
                        ).animate(
                          key: ValueKey('${_selectedOption}_$_quantity'),
                          onPlay: (controller) => controller.forward(from: 0.0),
                        )
                        .fadeIn(duration: 200.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8), 
                          end: const Offset(1.0, 1.0),
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Book Now button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Close the bottom sheet
                        Navigator.pop(context);
                        
                        // Navigate to BookingConfirmationScreen
                        HapticFeedback.mediumImpact();
                        
                        final bookingDetails = {
                          'place': widget.place,
                          'bookingOption': _selectedOption,
                          'quantity': _quantity,
                          'date': _selectedDate,
                          'price': _bookingOptions[_selectedOption]['price'] * _quantity,
                        };
                        
                        // Show dialog that we're redirecting
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            // After dialog shows, schedule navigation
                            Future.delayed(const Duration(seconds: 1), () {
                              // Only pop and navigate if context is still valid
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => BookingConfirmationScreen(
                                      place: widget.place,
                                      bookingOption: _selectedOption,
                                      quantity: _quantity,
                                      date: _selectedDate,
                                      price: _bookingOptions[_selectedOption]['price'] * _quantity,
                                    ),
                                  ),
                                );
                              }
                            });
                            
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                'Redirecting',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    color: Color(0xFF12B347),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Taking you to Booking Confirmation Screen.',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12B347),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'SECURE THE SPOT 🔐',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'From',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '€${_bookingOptions[_selectedOption]['price'].toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF12B347),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: _showBookingOptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF12B347),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'SECURE THE SPOT 🔐',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 