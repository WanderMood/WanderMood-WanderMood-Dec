import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/screens/payment_screen.dart';

class BookingBottomSheet extends StatefulWidget {
  final Place place;

  const BookingBottomSheet({
    required this.place,
    Key? key,
  }) : super(key: key);

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  int _selectedGuests = 2;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '10:00 AM';
  String _selectedBookingType = 'Standard Visit';

  final Map<String, double> _bookingTypes = {
    'Standard Visit': 15.00,
    'Guided Tour': 25.00,
    'Premium Experience': 45.00,
    'Group Booking': 12.00,
  };

  final List<String> _availableTimes = [
    '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM'
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBookingTypeSelection(),
                      const SizedBox(height: 24),
                      _buildDateSelection(),
                      const SizedBox(height: 24),
                      _buildTimeSelection(),
                      const SizedBox(height: 24),
                      _buildGuestSelection(),
                      const SizedBox(height: 24),
                      _buildPriceSummary(),
                      const SizedBox(height: 32),
                      _buildBookButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book ${widget.place.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your perfect visit',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Experience Type',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _bookingTypes.entries.map((entry) {
            final isSelected = _selectedBookingType == entry.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF2A6049) 
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected 
                    ? const Color(0xFF2A6049).withOpacity(0.05)
                    : Colors.white,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF2A6049) 
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2A6049),
                            ),
                          ),
                        )
                      : null,
                ),
                title: Text(
                  entry.key,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? const Color(0xFF2A6049) : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  _getBookingTypeDescription(entry.key),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Text(
                  '€${entry.value.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF2A6049) : Colors.black87,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedBookingType = entry.key;
                  });
                  HapticFeedback.lightImpact();
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getBookingTypeDescription(String type) {
    switch (type) {
      case 'Standard Visit':
        return 'Regular access with self-guided exploration';
      case 'Guided Tour':
        return 'Expert guide with detailed insights';
      case 'Premium Experience':
        return 'VIP access with exclusive areas';
      case 'Group Booking':
        return 'Special rate for groups of 6+ people';
      default:
        return '';
    }
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF2A6049),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTimes.map((time) {
            final isSelected = _selectedTime == time;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = time;
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF2A6049) 
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF2A6049) 
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGuestSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Guests',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.people,
                color: Color(0xFF2A6049),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$_selectedGuests Guest${_selectedGuests > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _selectedGuests > 1 
                        ? () {
                            setState(() {
                              _selectedGuests--;
                            });
                            HapticFeedback.lightImpact();
                          }
                        : null,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _selectedGuests > 1 
                            ? const Color(0xFF2A6049) 
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color: _selectedGuests > 1 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _selectedGuests < 20 
                        ? () {
                            setState(() {
                              _selectedGuests++;
                            });
                            HapticFeedback.lightImpact();
                          }
                        : null,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _selectedGuests < 20 
                            ? const Color(0xFF2A6049) 
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: _selectedGuests < 20 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    final basePrice = _bookingTypes[_selectedBookingType]!;
    final totalPrice = basePrice * _selectedGuests;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A6049).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2A6049).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_selectedBookingType × $_selectedGuests',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '€${totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2A6049),
                ),
              ),
              Text(
                '€${totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2A6049),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A6049),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // Pill-shaped button
          ),
          elevation: 2,
        ),
        child: Text(
          'Continue to Payment',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF2A6049),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _processBooking() {
    HapticFeedback.mediumImpact();
    
    // Close the bottom sheet
    Navigator.pop(context);
    
    // Navigate to payment screen
    final totalPrice = _bookingTypes[_selectedBookingType]! * _selectedGuests;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          place: widget.place,
          bookingType: _selectedBookingType,
          date: _selectedDate,
          time: _selectedTime,
          guests: _selectedGuests,
          totalPrice: totalPrice,
        ),
      ),
    );
  }
} 