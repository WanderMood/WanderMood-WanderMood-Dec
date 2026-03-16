import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/auth/domain/models/user_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/api_keys.dart';
import 'preferences_provider.dart';

part 'onboarding_service.g.dart';

@riverpod
class OnboardingService extends _$OnboardingService {
  static const String _onboardingKey = 'onboarding_complete';

  OpenAI? _openAI;
  String _googlePlacesApiKey = '';
  String _openWeatherApiKey = '';

  @override
  FutureOr<Map<String, dynamic>?> build() async {
    try {
      _googlePlacesApiKey = '';
      _openWeatherApiKey = '';
      
      final openaiKey = ApiKeys.openAiKey;
      _googlePlacesApiKey = ApiKeys.googlePlacesKey;
      _openWeatherApiKey = ApiKeys.openWeather;
      
      if (openaiKey.isNotEmpty) {
        OpenAI.apiKey = openaiKey;
        _openAI = OpenAI.instance;
        print('OpenAI initialized successfully');
      } else {
        print('WARNING: OpenAI API key is not set, using mock implementation');
      }
      
      if (_openWeatherApiKey.isEmpty || _openWeatherApiKey == 'YOUR_ACTUAL_API_KEY_HERE') {
        print('WARNING: OpenWeather API key is not set or is using the placeholder value');
      }
    } catch (e) {
      print('ERROR initializing API services: $e');
      print('Will use mock implementations instead');
    }
    
    return null;
  }

  Future<void> processUserPreferences({
    required List<String> moods,
    required List<String> interests,
    required List<String> travelStyles,
    required String budget,
  }) async {
    state = const AsyncLoading();

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('Starting OpenAI analysis...');
      final analysis = await _analyzePreferencesWithOpenAI(
        moods: moods,
        interests: interests,
        travelStyles: travelStyles,
        budget: budget,
      ).timeout(const Duration(seconds: 15));
      print('OpenAI analysis complete');

      print('Fetching relevant locations...');
      final locations = await _getRelevantLocations(analysis)
          .timeout(const Duration(seconds: 10));
      print('Location fetch complete');

      print('Fetching weather data...');
      final weatherData = await _getWeatherData(locations)
          .timeout(const Duration(seconds: 10));
      print('Weather data fetch complete');

      print('Saving data to Supabase...');
      await _saveToSupabase(
        analysis: analysis,
        locations: locations,
        weatherData: weatherData,
      ).timeout(const Duration(seconds: 10));
      print('Data saved to Supabase');

      await completeOnboarding();
      print('Onboarding marked as complete');

      state = const AsyncData(null);
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception('Processing preferences took too long. Please try again.');
    } catch (e, st) {
      print('Error processing preferences: $e\n$st');
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<List<String>> _generateRecommendations({
    required List<String> moods,
    required List<String> interests,
    required List<String> travelStyles,
    required String budget,
  }) async {
    return [];
  }

  Future<void> _savePreferences({
    required List<String> moods,
    required List<String> interests,
    required List<String> travelStyles,
    required String budget,
    required List<String> recommendations,
  }) async {
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<Map<String, dynamic>> _analyzePreferencesWithOpenAI({
    required List<String> moods,
    required List<String> interests,
    required List<String> travelStyles,
    required String budget,
  }) async {
    try {
      // Check if OpenAI is initialized
      if (_openAI != null) {
        final prompt = '''
        Analyze the following travel preferences and suggest personalized travel experiences:
        
        Moods: ${moods.join(', ')}
        Interests: ${interests.join(', ')}
        Travel Styles: ${travelStyles.join(', ')}
        Budget: $budget
        
        Provide a structured response with:
        1. Recommended travel destinations
        2. Suggested activities
        3. Travel tips
        4. Best times to visit
        ''';

        try {
          final completion = await _openAI!.chat.create(
            model: 'gpt-3.5-turbo',
            messages: [
              OpenAIChatCompletionChoiceMessageModel(
                role: OpenAIChatMessageRole.system,
                content: [
                  OpenAIChatCompletionChoiceMessageContentItemModel.text(
                    'You are a travel expert providing personalized recommendations.'
                  )
                ],
              ),
              OpenAIChatCompletionChoiceMessageModel(
                role: OpenAIChatMessageRole.user,
                content: [
                  OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
                ],
              ),
            ],
          );

          final content = completion.choices.first.message.content;
          final recommendations = content?.isNotEmpty == true ? content!.first.text : 'No recommendations available';

          return {
            'recommendations': recommendations,
            'timestamp': DateTime.now().toIso8601String(),
          };
        } catch (e) {
          print('Error with OpenAI API call: $e');
        }
      } else {
        print('OpenAI is not initialized, using mock response');
      }
    } catch (e) {
      print('Error in _analyzePreferencesWithOpenAI: $e');
    }
    
    // Fall back to mock implementation
    return _getMockAnalysis(moods, interests, travelStyles, budget);
  }
  
  Map<String, dynamic> _getMockAnalysis(
    List<String> moods,
    List<String> interests,
    List<String> travelStyles,
    String budget
  ) {
    print('Using mock analysis for preferences');
    final moodDescriptions = moods.map((mood) => _getMoodDescription(mood)).join('\n');
    final interestActivities = interests.map((interest) => _getInterestActivities(interest)).join('\n');
    final styleRecommendations = travelStyles.map((style) => _getStyleRecommendation(style)).join('\n');
    
    final mockRecommendations = '''
    Based on your preferences, here are some personalized recommendations:
    
    1. Recommended travel destinations:
    - Amsterdam, Netherlands: Perfect for ${moods.join(', ')} experiences
    - Barcelona, Spain: Great for ${interests.join(', ')}
    - Kyoto, Japan: Ideal for ${travelStyles.join(', ')} travelers
    
    2. Suggested activities:
    $interestActivities
    
    3. Travel tips:
    - Consider visiting during shoulder seasons for better prices
    - For a $budget budget, focus on one region rather than multiple countries
    - $styleRecommendations
    
    4. Best times to visit:
    - Amsterdam: April-May or September-October
    - Barcelona: May-June or September
    - Kyoto: March-May or October-November
    ''';
    
    return {
      'recommendations': mockRecommendations,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  String _getMoodDescription(String mood) {
    switch (mood.toLowerCase()) {
      case 'romantic':
        return 'Candlelit dinners and intimate settings';
      case 'adventurous':
        return 'Thrilling outdoor activities';
      case 'relaxed':
        return 'Laid-back environments for unwinding';
      case 'foody':
        return 'Culinary delights and gastronomic experiences';
      case 'cultural':
        return 'Rich historical and artistic experiences';
      default:
        return 'Diverse experiences to match your mood';
    }
  }
  
  String _getInterestActivities(String interest) {
    switch (interest.toLowerCase()) {
      case 'nature & outdoors':
        return '- Hiking in natural parks\n- Wildlife photography opportunities';
      case 'arts & culture':
        return '- Museum visits\n- Local cultural workshops';
      case 'food & dining':
        return '- Food tours\n- Cooking classes with local chefs';
      case 'shopping & markets':
        return '- Visit local craft markets\n- Shopping districts with unique items';
      default:
        return '- Explore local favorites\n- Join guided tours focused on your interests';
    }
  }
  
  String _getStyleRecommendation(String style) {
    switch (style.toLowerCase()) {
      case 'spontaneous':
        return 'Keep some days unplanned to discover unexpected gems';
      case 'planned':
        return 'Book major attractions in advance to avoid disappointment';
      case 'local experience':
        return 'Stay in residential neighborhoods and use public transport';
      case 'tourist highlights':
        return 'Consider city passes for major attractions';
      case 'off the beaten path':
        return 'Research lesser-known areas and ask locals for recommendations';
      default:
        return 'Mix planned activities with free time for discoveries';
    }
  }

  Future<List<Map<String, dynamic>>> _getRelevantLocations(Map<String, dynamic> analysis) async {
    final locations = <Map<String, dynamic>>[];
    
    try {
      // Force using mock locations (Google Places API disabled)
      print('🚫 Google Places API disabled - using mock locations');
      return _getMockLocations();
    
      for (final location in analysis['recommendations'].split('\n')) {
        if (location.contains('destination')) {
          final placeName = location.split(':')[1].trim();
          
          try {
            final response = await http.get(Uri.parse(
              'https://maps.googleapis.com/maps/api/place/textsearch/json'
              '?query=$placeName'
              '&key=$_googlePlacesApiKey'
            ));

            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              if (data['results'].isNotEmpty) {
                locations.add(data['results'][0]);
              }
            } else {
              print('Google Places API error: ${response.statusCode}');
            }
          } catch (e) {
            print('Error calling Google Places API: $e');
          }
        }
      }
      
      if (locations.isEmpty) {
        print('No locations found from the API, using mock locations');
        return _getMockLocations();
      }
      
      return locations;
    } catch (e) {
      print('Error in _getRelevantLocations: $e');
      return _getMockLocations();
    }
  }
  
  List<Map<String, dynamic>> _getMockLocations() {
    print('Using mock location data');
    return [
      {
        'name': 'Amsterdam',
        'formatted_address': 'Amsterdam, Netherlands',
        'geometry': {
          'location': {
            'lat': 52.3676,
            'lng': 4.9041
          }
        },
        'rating': 4.5,
        'types': ['locality', 'political']
      },
      {
        'name': 'Barcelona',
        'formatted_address': 'Barcelona, Spain',
        'geometry': {
          'location': {
            'lat': 41.3851,
            'lng': 2.1734
          }
        },
        'rating': 4.6,
        'types': ['locality', 'political']
      },
      {
        'name': 'Kyoto',
        'formatted_address': 'Kyoto, Japan',
        'geometry': {
          'location': {
            'lat': 35.0116,
            'lng': 135.7681
          }
        },
        'rating': 4.7,
        'types': ['locality', 'political']
      }
    ];
  }

  Future<Map<String, dynamic>> _getWeatherData(List<Map<String, dynamic>> locations) async {
    final weatherData = <String, dynamic>{};
    
    // Always start with safe default data
    print('Initializing weather data...');
    
    try {
      // Skip weather API calls if key is missing or using the placeholder
      if (_openWeatherApiKey.isEmpty || _openWeatherApiKey == 'YOUR_ACTUAL_API_KEY_HERE') {
        print('Using mock weather data because OpenWeather API key is not set');
        return _getMockWeatherData(locations);
      }
      
      // If API key is available, use it
      for (final location in locations) {
        final lat = location['geometry']['location']['lat'];
        final lng = location['geometry']['location']['lng'];
        
        try {
          final response = await http.get(Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather'
            '?lat=$lat'
            '&lon=$lng'
            '&appid=$_openWeatherApiKey'
            '&units=metric'
          ));

          if (response.statusCode == 200) {
            weatherData[location['name']] = json.decode(response.body);
          } else {
            print('Weather API error: ${response.statusCode} - ${response.body}');
            weatherData[location['name']] = _getDefaultWeatherData();
          }
        } catch (e) {
          print('Error fetching weather data: $e');
          weatherData[location['name']] = _getDefaultWeatherData();
        }
      }
      
      return weatherData;
    } catch (e) {
      print('Error in weather data processing: $e');
      return _getMockWeatherData(locations);
    }
  }
  
  Map<String, dynamic> _getDefaultWeatherData() {
    return {
      'main': {
        'temp': 22.5,
        'humidity': 65,
      },
      'weather': [
        {
          'main': 'Clear',
          'description': 'clear sky',
          'icon': '01d'
        }
      ],
      'wind': {
        'speed': 4.1
      }
    };
  }
  
  Map<String, dynamic> _getMockWeatherData(List<Map<String, dynamic>> locations) {
    final weatherData = <String, dynamic>{};
    for (final location in locations) {
      weatherData[location['name']] = _getDefaultWeatherData();
    }
    return weatherData;
  }

  Future<void> _saveToSupabase({
    required Map<String, dynamic> analysis,
    required List<Map<String, dynamic>> locations,
    required Map<String, dynamic> weatherData,
  }) async {
    try {
      final supabase = SupabaseConfig.client;
      
      if (supabase == null) {
        print('Supabase client is not initialized, skipping database save');
        return;
      }
      
      await supabase.from('user_preferences').insert({
        'analysis': analysis,
        'locations': locations,
        'weather_data': weatherData,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('Successfully saved preferences to Supabase');
    } catch (e) {
      print('Error saving to Supabase: $e');
      print('Continuing with onboarding flow despite database error');
    }
  }
} 
 
 