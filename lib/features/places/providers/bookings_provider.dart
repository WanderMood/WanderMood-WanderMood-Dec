import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking.dart';
import '../models/place.dart';

part 'bookings_provider.g.dart';

@riverpod
class Bookings extends _$Bookings {
  static const String _bookingsKey = 'user_bookings';

  @override
  Future<List<Booking>> build() async {
    return await _loadBookings();
  }

  Future<List<Booking>> _loadBookings() async {
    try {
      print('📖 Loading bookings from storage...');
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString(_bookingsKey);
      
      if (bookingsJson != null) {
        print('📖 Found existing bookings JSON: ${bookingsJson.length} characters');
        final List<dynamic> jsonList = json.decode(bookingsJson);
        final bookings = jsonList.map((json) => Booking.fromJson(json)).toList();
        print('📖 Loaded ${bookings.length} bookings from storage');
        return bookings;
      }
      
      print('📖 No existing bookings found in storage');
      return [];
    } catch (e) {
      print('❌ Error loading bookings: $e');
      return [];
    }
  }

  Future<void> _saveBookingsToStorage(List<Booking> bookings) async {
    try {
      print('💾 Saving ${bookings.length} bookings to storage...');
      final prefs = await SharedPreferences.getInstance();
      final jsonList = bookings.map((booking) => booking.toJson()).toList();
      final jsonString = json.encode(jsonList);
      print('💾 JSON string length: ${jsonString.length} characters');
      await prefs.setString(_bookingsKey, jsonString);
      print('💾 Successfully saved bookings to SharedPreferences');
    } catch (e) {
      print('❌ Error saving bookings: $e');
    }
  }

  Future<String> addBooking({
    required Place place,
    required String bookingType,
    required DateTime date,
    required String time,
    required int guests,
    required double totalPrice,
  }) async {
    print('💾 Adding new booking for ${place.name}...');
    final bookingReference = _generateBookingReference();
    
    final booking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      place: place,
      bookingType: bookingType,
      date: date,
      time: time,
      guests: guests,
      totalPrice: totalPrice,
      bookingReference: bookingReference,
      createdAt: DateTime.now(),
    );

    print('💾 Created booking object: ${booking.id}');

    final currentBookings = state.value ?? [];
    print('💾 Current bookings count: ${currentBookings.length}');
    
    final updatedBookings = [...currentBookings, booking];
    print('💾 Updated bookings count: ${updatedBookings.length}');
    
    // Sort by date (upcoming first)
    updatedBookings.sort((a, b) => a.date.compareTo(b.date));
    
    state = AsyncValue.data(updatedBookings);
    print('💾 Updated state with ${updatedBookings.length} bookings');
    
    await _saveBookingsToStorage(updatedBookings);
    print('💾 Saved bookings to storage');
    
    return bookingReference;
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    final currentBookings = state.value ?? [];
    final updatedBookings = currentBookings.map((booking) {
      if (booking.id == bookingId) {
        return booking.copyWith(status: status);
      }
      return booking;
    }).toList();
    
    state = AsyncValue.data(updatedBookings);
    await _saveBookingsToStorage(updatedBookings);
  }

  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.cancelled);
  }

  Future<void> markAsCompleted(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.completed);
  }

  Future<void> addNotes(String bookingId, String notes) async {
    final currentBookings = state.value ?? [];
    final updatedBookings = currentBookings.map((booking) {
      if (booking.id == bookingId) {
        return booking.copyWith(notes: notes);
      }
      return booking;
    }).toList();
    
    state = AsyncValue.data(updatedBookings);
    await _saveBookingsToStorage(updatedBookings);
  }

  List<Booking> getUpcomingBookings() {
    final bookings = state.value ?? [];
    final now = DateTime.now();
    return bookings
        .where((booking) => 
            booking.date.isAfter(now) && 
            booking.status == BookingStatus.confirmed)
        .toList();
  }

  List<Booking> getPastBookings() {
    final bookings = state.value ?? [];
    final now = DateTime.now();
    return bookings
        .where((booking) => 
            booking.date.isBefore(now) || 
            booking.status == BookingStatus.completed ||
            booking.status == BookingStatus.cancelled)
        .toList();
  }

  List<Booking> getBookingsForDate(DateTime date) {
    final bookings = state.value ?? [];
    return bookings
        .where((booking) => 
            booking.date.year == date.year &&
            booking.date.month == date.month &&
            booking.date.day == date.day)
        .toList();
  }

  static String _generateBookingReference() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = 'WM';
    for (int i = 0; i < 6; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
  }
} 