import 'package:wandermood/core/models/place.dart';

enum TimeSlot {
  morning,
  afternoon,
  evening
}

class Activity {
  final String id;
  final Place place;
  final DateTime startTime;
  final Duration duration;
  final TimeSlot timeSlot;
  final List<String> tags;
  final String? customDescription;
  final double? moodScore;

  Activity({
    required this.id,
    required this.place,
    required this.startTime,
    required this.duration,
    required this.timeSlot,
    this.tags = const [],
    this.customDescription,
    this.moodScore,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      startTime: DateTime.parse(json['startTime'] as String),
      duration: Duration(minutes: json['durationMinutes'] as int),
      timeSlot: TimeSlot.values.firstWhere(
        (e) => e.toString() == 'TimeSlot.${json['timeSlot']}',
      ),
      tags: List<String>.from(json['tags'] ?? []),
      customDescription: json['customDescription'] as String?,
      moodScore: (json['moodScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place': place.toJson(),
      'startTime': startTime.toIso8601String(),
      'durationMinutes': duration.inMinutes,
      'timeSlot': timeSlot.toString().split('.').last,
      'tags': tags,
      'customDescription': customDescription,
      'moodScore': moodScore,
    };
  }

  DateTime get endTime => startTime.add(duration);

  Activity copyWith({
    String? id,
    Place? place,
    DateTime? startTime,
    Duration? duration,
    TimeSlot? timeSlot,
    List<String>? tags,
    String? customDescription,
    double? moodScore,
  }) {
    return Activity(
      id: id ?? this.id,
      place: place ?? this.place,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      timeSlot: timeSlot ?? this.timeSlot,
      tags: tags ?? this.tags,
      customDescription: customDescription ?? this.customDescription,
      moodScore: moodScore ?? this.moodScore,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Helper method to check if this activity is a restaurant or dining-related
  bool get isRestaurant {
    final typeBlob =
        place.types.map((e) => e.toLowerCase()).join(' ');
    return tags.contains('restaurant') ||
        tags.contains('dining') ||
        place.name.toLowerCase().contains('restaurant') ||
        place.name.toLowerCase().contains('dining') ||
        typeBlob.contains('restaurant') ||
        typeBlob.contains('dining') ||
        typeBlob.contains('food');
  }
} 