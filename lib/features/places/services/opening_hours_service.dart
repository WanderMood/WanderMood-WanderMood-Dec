import 'dart:math';
import '../models/place.dart';

class OpeningHoursService {
  static PlaceOpeningHours generateOpeningHours(List<String> placeTypes) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    // Determine place category and typical hours
    String category = _categorizePlace(placeTypes);
    Map<String, String> typicalHours = _getTypicalHours(category);
    
    // Parse opening and closing times
    List<String> openParts = typicalHours['open']!.split(':');
    List<String> closeParts = typicalHours['close']!.split(':');
    int openHour = int.parse(openParts[0]);
    int openMin = int.parse(openParts[1]);
    int closeHour = int.parse(closeParts[0]);
    int closeMin = int.parse(closeParts[1]);
    
    // Handle overnight places (close hour < open hour means next day)
    bool isOvernight = closeHour < openHour;
    
    // Determine if currently open
    bool isCurrentlyOpen;
    if (isOvernight) {
      // For overnight places (like bars), open if after opening time OR before closing time
      isCurrentlyOpen = (currentHour > openHour || (currentHour == openHour && currentMinute >= openMin)) ||
                       (currentHour < closeHour || (currentHour == closeHour && currentMinute < closeMin));
    } else {
      // Regular places
      isCurrentlyOpen = (currentHour > openHour || (currentHour == openHour && currentMinute >= openMin)) &&
                       (currentHour < closeHour || (currentHour == closeHour && currentMinute < closeMin));
    }
    
    // Generate status message
    String status;
    if (isCurrentlyOpen) {
      if (isOvernight && currentHour < 6) {
        status = "Open until ${_formatTime(closeHour, closeMin)}";
      } else {
        status = "Open until ${_formatTime(closeHour, closeMin)}";
      }
    } else {
      status = "Opens at ${_formatTime(openHour, openMin)}";
    }
    
    // Create today's hours
    DailyHours todayHours = DailyHours(
      openTime: _formatTime(openHour, openMin),
      closeTime: _formatTime(closeHour, closeMin),
      isOpenAllDay: false,
      isClosed: false,
    );
    
    // Generate week schedule
    List<String> weekdayText = _generateWeekSchedule(category);
    
    return PlaceOpeningHours(
      isOpen: isCurrentlyOpen,
      currentStatus: status,
      weekdayText: weekdayText,
      todayHours: todayHours,
    );
  }
  
  static String _categorizePlace(List<String> types) {
    // Priority-based categorization
    if (types.any((t) => ['bar', 'night_club', 'liquor_store'].contains(t))) return 'bar';
    if (types.any((t) => ['restaurant', 'meal_takeaway', 'meal_delivery'].contains(t))) return 'restaurant';
    if (types.any((t) => ['cafe', 'bakery'].contains(t))) return 'cafe';
    if (types.any((t) => ['museum', 'art_gallery', 'library'].contains(t))) return 'museum';
    if (types.any((t) => ['store', 'shopping_mall', 'clothing_store', 'book_store'].contains(t))) return 'retail';
    if (types.any((t) => ['gym', 'spa', 'beauty_salon'].contains(t))) return 'wellness';
    if (types.any((t) => ['park', 'zoo', 'amusement_park'].contains(t))) return 'attraction';
    if (types.any((t) => ['lodging', 'hotel'].contains(t))) return 'hotel';
    
    return 'general';
  }
  
  static Map<String, String> _getTypicalHours(String category) {
    final random = Random();
    
    switch (category) {
      case 'restaurant':
        // Restaurants typically 11:30 AM - 10:00 PM with some variation
        int openHour = 11 + random.nextInt(2); // 11-12
        int openMin = random.nextBool() ? 0 : 30;
        int closeHour = 21 + random.nextInt(3); // 21-23 (9-11 PM)
        return {'open': '$openHour:${openMin.toString().padLeft(2, '0')}', 
                'close': '$closeHour:00'};
        
      case 'cafe':
        // Cafes typically 7:00 AM - 6:00 PM
        int openHour = 7 + random.nextInt(2); // 7-8
        int closeHour = 17 + random.nextInt(3); // 17-19 (5-7 PM)
        return {'open': '$openHour:00', 'close': '$closeHour:00'};
        
      case 'bar':
        // Bars typically 5:00 PM - 2:00 AM
        int openHour = 16 + random.nextInt(3); // 16-18 (4-6 PM)
        int closeHour = 1 + random.nextInt(3); // 1-3 AM (next day)
        return {'open': '$openHour:00', 'close': '$closeHour:00'};
        
      case 'museum':
        // Museums typically 9:00 AM - 5:00 PM
        int openHour = 9 + random.nextInt(2); // 9-10
        int closeHour = 16 + random.nextInt(2); // 16-17 (4-5 PM)
        return {'open': '$openHour:00', 'close': '$closeHour:00'};
        
      case 'retail':
        // Retail stores typically 10:00 AM - 8:00 PM
        int openHour = 9 + random.nextInt(2); // 9-10
        int closeHour = 19 + random.nextInt(3); // 19-21 (7-9 PM)
        return {'open': '$openHour:00', 'close': '$closeHour:00'};
        
      case 'wellness':
        // Gyms/spas typically 6:00 AM - 10:00 PM
        int openHour = 6 + random.nextInt(2); // 6-7
        int closeHour = 21 + random.nextInt(2); // 21-22 (9-10 PM)
        return {'open': '$openHour:00', 'close': '$closeHour:00'};
        
      case 'attraction':
        // Tourist attractions typically 9:00 AM - 6:00 PM
        int openHour = 8 + random.nextInt(3); // 8-10
        int closeHour = 17 + random.nextInt(3); // 17-19 (5-7 PM)
        return {'open': '$openHour:00', 'close': '$closeHour:00'};
        
      case 'hotel':
        // Hotels are always open
        return {'open': '0:00', 'close': '23:59'};
        
      default:
        // General business hours
        return {'open': '9:00', 'close': '17:00'};
    }
  }
  
  static List<String> _generateWeekSchedule(String category) {
    Map<String, String> hours = _getTypicalHours(category);
    String openTime = hours['open']!;
    String closeTime = hours['close']!;
    
    List<String> schedule = [];
    
    switch (category) {
      case 'bar':
        // Bars often closed Sunday/Monday, different weekend hours
        schedule = [
          'Monday: Closed',
          'Tuesday: $openTime - $closeTime',
          'Wednesday: $openTime - $closeTime', 
          'Thursday: $openTime - $closeTime',
          'Friday: $openTime - 3:00',
          'Saturday: $openTime - 3:00',
          'Sunday: Closed',
        ];
        break;
        
      case 'museum':
        // Museums often closed Monday
        schedule = [
          'Monday: Closed',
          'Tuesday: $openTime - $closeTime',
          'Wednesday: $openTime - $closeTime',
          'Thursday: $openTime - $closeTime',
          'Friday: $openTime - $closeTime',
          'Saturday: $openTime - $closeTime',
          'Sunday: $openTime - $closeTime',
        ];
        break;
        
      case 'hotel':
        // Hotels are 24/7
        schedule = List.generate(7, (index) {
          String day = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][index];
          return '$day: Open 24 hours';
        });
        break;
        
      default:
        // Regular business schedule
        schedule = [
          'Monday: $openTime - $closeTime',
          'Tuesday: $openTime - $closeTime',
          'Wednesday: $openTime - $closeTime',
          'Thursday: $openTime - $closeTime',
          'Friday: $openTime - $closeTime',
          'Saturday: $openTime - $closeTime',
          'Sunday: $openTime - $closeTime',
        ];
        break;
    }
    
    return schedule;
  }
  
  static String _formatTime(int hour, int minute) {
    String period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    String minuteStr = minute == 0 ? '00' : minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }
} 