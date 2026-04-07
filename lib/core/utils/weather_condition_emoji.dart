import 'package:shared_preferences/shared_preferences.dart';

/// Persists last known OpenWeatherMap `weather.main` (e.g. Clear, Clouds, Rain)
/// from [weather_provider] so morning notifications can show a simple emoji.
const String kPrefsLastWeatherMain = 'wm_last_openweather_main';

/// Maps OpenWeatherMap condition `main` to a single emoji for notification titles.
String weatherEmojiFromOpenWeatherMain(String? main) {
  switch ((main ?? '').toLowerCase().trim()) {
    case 'clear':
      return '☀️';
    case 'clouds':
      return '☁️';
    case 'rain':
    case 'drizzle':
      return '🌧️';
    case 'thunderstorm':
      return '⛈️';
    case 'snow':
      return '❄️';
    case 'mist':
    case 'fog':
    case 'haze':
      return '🌫️';
    default:
      return '🌤️';
  }
}

Future<void> persistOpenWeatherMainForNotifications(String? main) async {
  if (main == null || main.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kPrefsLastWeatherMain, main);
}

String readStoredWeatherEmoji(SharedPreferences prefs) {
  final main = prefs.getString(kPrefsLastWeatherMain);
  return weatherEmojiFromOpenWeatherMain(main);
}
