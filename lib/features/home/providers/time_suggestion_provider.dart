import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/theme/time_based_theme.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/features/plans/application/services/openai_service.dart';
import 'package:dart_openai/dart_openai.dart';

final timeSuggestionProvider = FutureProvider.autoDispose<String>((ref) async {
  final hour = MoodyClock.now().hour;
  final timeConfig = TimeBasedTheme.getConfigForHour(hour);
  final weather = await ref.watch(weatherProvider.future);
  final openAI = ref.read(openAIServiceProvider);

  try {
    // Create a context-aware prompt
    final prompt = '''
      Generate a short, engaging suggestion (max 50 chars) for activities based on:
      Time: ${timeConfig.name}
      Weather: ${weather?.details['description'] ?? 'unknown'}
      Activity types: ${timeConfig.activityTypes.join(', ')}
      Make it personal and motivating.
    ''';

    // Get completion from OpenAI
    final completion = await openAI.chat(
      model: 'gpt-3.5-turbo',
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              'You are a friendly AI suggesting activities based on time and weather.'
            ),
          ],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
          ],
        ),
      ],
    );

    final content = completion.choices.first.message.content;
    if (content == null || content.isEmpty) {
      return timeConfig.defaultSuggestion;
    }
    
    final suggestion = content.first.text?.trim() ?? timeConfig.defaultSuggestion;
    return suggestion.length > 50 ? timeConfig.defaultSuggestion : suggestion;
  } catch (e) {
    // Fallback to default suggestion if AI fails
    return timeConfig.defaultSuggestion;
  }
}); 