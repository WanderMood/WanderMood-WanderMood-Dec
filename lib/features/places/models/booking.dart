import 'package:freezed_annotation/freezed_annotation.dart';
import 'place.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

@freezed
class Booking with _$Booking {
  const factory Booking({
    required String id,
    required Place place,
    required String bookingType,
    required DateTime date,
    required String time,
    required int guests,
    required double totalPrice,
    required String bookingReference,
    required DateTime createdAt,
    @Default(BookingStatus.confirmed) BookingStatus status,
    String? notes,
    DateTime? checkInTime,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);
}

@JsonEnum()
enum BookingStatus {
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('completed')
  completed,
  @JsonValue('no_show')
  noShow,
} 