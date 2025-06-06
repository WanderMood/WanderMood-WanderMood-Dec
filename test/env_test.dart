import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load the environment variables
  await dotenv.load(fileName: '.env');
  
  // Print all environment variables
  print('Environment variables:');
  dotenv.env.forEach((key, value) {
    print('$key: ${value.isEmpty ? "EMPTY" : "VALUE PRESENT"}');
  });
  
  // Specifically check for the OpenWeather API key
  final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
  print('OpenWeather API Key: ${apiKey == null ? "NULL" : (apiKey.isEmpty ? "EMPTY" : "VALUE PRESENT")}');
} 