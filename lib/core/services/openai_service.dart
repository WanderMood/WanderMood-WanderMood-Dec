import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class OpenAIService {
  final String apiKey = ApiConstants.openAiApiKey;
  final String baseUrl = ApiConstants.openAiBaseUrl;

  Future<String> generatePlanDescription({
    required String mood,
    required String location,
    required List<Map<String, dynamic>> places,
  }) async {
    final url = Uri.parse('$baseUrl${ApiConstants.completions}');
    
    // Create a prompt that includes the places and asks for a personalized description
    final placesText = places.map((place) => place['name']).join(', ');
    final prompt = '''Create a personalized day plan for someone feeling $mood in $location.
    Available places: $placesText.
    Include a brief description of why each place matches their mood and what they can do there.
    Keep the tone friendly and conversational.''';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4-turbo-preview',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful travel assistant creating personalized day plans based on mood.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      }
      return 'Unable to generate plan description at the moment.';
    } catch (e) {
      print('Error generating plan description: $e');
      return 'Error generating plan description. Please try again.';
    }
  }

  Future<Map<String, dynamic>> analyzePlaceForMood({
    required String mood,
    required Map<String, dynamic> place,
  }) async {
    final url = Uri.parse('$baseUrl${ApiConstants.completions}');
    
    final prompt = '''Analyze how well this place matches someone feeling $mood:
    Place: ${place['name']}
    Type: ${place['types']?.join(', ')}
    Rating: ${place['rating']}
    
    Return a mood match score (0-100) and explain why.''';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4-turbo-preview',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an AI analyzing places for mood compatibility.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysis = data['choices'][0]['message']['content'];
        
        // Extract score from analysis (implement parsing logic)
        final scoreMatch = RegExp(r'(\d+)').firstMatch(analysis);
        final score = scoreMatch != null 
          ? double.parse(scoreMatch.group(1)!) 
          : 50.0;
        
        return {
          'score': score,
          'explanation': analysis,
        };
      }
      return {'score': 50.0, 'explanation': 'Unable to analyze mood match.'};
    } catch (e) {
      print('Error analyzing place for mood: $e');
      return {'score': 50.0, 'explanation': 'Error during analysis.'};
    }
  }
} 