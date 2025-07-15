import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_openai/dart_openai.dart';
import '../../../../core/constants/api_keys.dart';
import '../../domain/models/place.dart';

final openAIServiceProvider = Provider((ref) => OpenAIService(
  apiKey: ApiKeys.openAiKey,
));

class OpenAIService {
  final String apiKey;
  late final OpenAI _openAI;

  OpenAIService({required this.apiKey}) {
    OpenAI.apiKey = apiKey;
    _openAI = OpenAI.instance;
  }

  Future<OpenAIChatCompletionModel> chat({
    required String model,
    required List<OpenAIChatCompletionChoiceMessageModel> messages,
  }) async {
    return await _openAI.chat.create(
      model: model,
      messages: messages,
    );
  }

  Future<List<Place>> analyzeMoodCompatibility({
    required List<Place> places,
    required List<String> moods,
  }) async {
    try {
      final analyzedPlaces = await Future.wait(
        places.map((place) async {
          // Create prompt for mood compatibility analysis
          final prompt = '''
            Analyze how well this place matches the following moods: ${moods.join(', ')}
            
            Place details:
            Name: ${place.name}
            Description: ${place.description}
            Tags: ${place.tags.join(', ')}
            
            Provide a score from 0.0 to 1.0 and a brief explanation.
          ''';

          // Get completion from OpenAI
          final completion = await _openAI.completion.create(
            model: 'gpt-3.5-turbo-instruct',
            prompt: prompt,
            maxTokens: 150,
            temperature: 0.7,
          );

          // Parse response
          final response = completion.choices.first.text;
          final lines = response.split('\n');
          final score = double.tryParse(
            lines.firstWhere(
              (line) => line.contains('Score:'),
              orElse: () => 'Score: 0.5',
            ).split(':').last.trim(),
          ) ?? 0.5;
          final explanation = lines.firstWhere(
            (line) => line.contains('Explanation:'),
            orElse: () => 'Explanation: This place somewhat matches your mood.',
          ).split(':').last.trim();

          // Return updated place
          return place.copyWith(
            moodMatchScore: score,
            moodMatchExplanation: explanation,
          );
        }),
      );

      // Sort places by mood match score
      analyzedPlaces.sort((a, b) => 
        (b.moodMatchScore ?? 0).compareTo(a.moodMatchScore ?? 0));

      return analyzedPlaces;
    } catch (e) {
      throw Exception('Failed to analyze mood compatibility: $e');
    }
  }

  Future<String> generatePlanDescription({
    required List<Place> places,
    required List<String> moods,
  }) async {
    try {
      // Create prompt for plan description
      final prompt = '''
        Create an engaging description for a day plan based on these moods: ${moods.join(', ')}
        
        The plan includes these places:
        ${places.map((p) => '- ${p.name}: ${p.description}').join('\n')}
        
        Make it personal and enthusiastic, highlighting how the places match the moods.
        Keep it concise (2-3 sentences).
      ''';

      // Get completion from OpenAI
      final completion = await _openAI.completion.create(
        model: 'gpt-3.5-turbo-instruct',
        prompt: prompt,
        maxTokens: 150,
        temperature: 0.7,
      );

      return completion.choices.first.text.trim();
    } catch (e) {
      throw Exception('Failed to generate plan description: $e');
    }
  }
} 