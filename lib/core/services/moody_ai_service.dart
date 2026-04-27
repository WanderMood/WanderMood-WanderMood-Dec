import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import '../constants/api_constants.dart';
import '../../features/places/models/place.dart';
import 'package:wandermood/l10n/app_localizations.dart';

part 'moody_ai_service.g.dart';

@riverpod
MoodyAIService moodyAIService(MoodyAIServiceRef ref) => MoodyAIService();

class MoodyAIService {
  final String apiKey = ApiConstants.openAiApiKey;
  final String baseUrl = ApiConstants.openAiBaseUrl;

  /// BCP-47 primary tag; tips prompts and fallbacks match Edge `AppLang`.
  static String normalizeTipsLanguageCode(String? code) {
    final x = (code ?? 'en').toLowerCase().split(RegExp(r'[-_]')).first;
    if (x == 'nl' || x == 'es' || x == 'de' || x == 'fr') return x;
    return 'en';
  }

  static String _humanOutputLanguage(String lang) {
    switch (lang) {
      case 'nl':
        return 'Dutch';
      case 'es':
        return 'Spanish';
      case 'de':
        return 'German';
      case 'fr':
        return 'French';
      default:
        return 'English';
    }
  }

  /// Short tips when the client cannot call OpenAI (dedupe wait, errors).
  static List<String> emergencyTips(String languageCode) {
    final lang = normalizeTipsLanguageCode(languageCode);
    switch (lang) {
      case 'nl':
        return [
          '🕐 Check openingstijden voordat je gaat — zo voorkom je teleurstelling',
          '📱 Download offline kaarten voor het geval het signaal zwak is',
          '💧 Neem water mee, vooral bij warm weer',
        ];
      case 'es':
        return [
          '🕐 Revisa el horario antes de ir para evitar disgustos',
          '📱 Descarga mapas offline por si la cobertura es mala',
          '💧 Lleva agua, sobre todo si hace calor',
        ];
      case 'de':
        return [
          '🕐 Prüfe die Öffnungszeiten vor dem Besuch — so vermeidest du Enttäuschungen',
          '📱 Lade Offline-Karten herunter, falls das Netz schwach ist',
          '💧 Nimm Wasser mit, besonders bei warmem Wetter',
        ];
      case 'fr':
        return [
          '🕐 Vérifie les horaires avant d’y aller pour éviter les mauvaises surprises',
          '📱 Télécharge des cartes hors ligne au cas où le réseau serait faible',
          '💧 Emporte de l’eau, surtout par temps chaud',
        ];
      default:
        return [
          '🕐 Check opening hours before your visit to avoid disappointment',
          '📱 Download offline maps in case of poor signal',
          '💧 Stay hydrated and bring water, especially during warmer weather',
        ];
    }
  }

  /// Generate personalized Moody Tips for a specific place using AI
  Future<List<String>> generateMoodyTips({
    required Place place,
    String? userMood,
    String? timeOfDay,
    String? weather,
    List<String>? userPreferences,
    String languageCode = 'en',
  }) async {
    final lang = normalizeTipsLanguageCode(languageCode);
    if (apiKey.isEmpty) {
      debugPrint('⚠️ OpenAI API key not configured, using fallback tips');
      return _getFallbackTips(place, lang);
    }

    try {
      final url = Uri.parse('$baseUrl${ApiConstants.completions}');
      
      final prompt = _buildPrompt(
        place: place,
        userMood: userMood,
        timeOfDay: timeOfDay,
        weather: weather,
        userPreferences: userPreferences,
        outputLang: lang,
      );

      debugPrint('🤖 Generating Moody Tips for: ${place.name}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini', // Cost-effective and fast
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(lang),
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Parse the response and extract tips
        final tips = _parseAIResponse(content, place: place, lang: lang);
        
        debugPrint('✅ Generated ${tips.length} AI-powered Moody Tips');
        return tips;
      } else {
        debugPrint('❌ OpenAI API error: ${response.statusCode}');
        return _getFallbackTips(place, lang);
      }
    } catch (e) {
      debugPrint('❌ Error generating Moody Tips: $e');
      return _getFallbackTips(place, lang);
    }
  }

  /// User-visible / model-facing name for tips (never raw error placeholders).
  String _placeLabelForTips(Place place) {
    const bad = {
      'error loading place',
      'place details unavailable',
      'unknown place',
    };
    final n = place.name.trim().toLowerCase();
    if (bad.contains(n)) return 'this spot';
    return place.name;
  }

  /// Build context-aware prompt for Moody AI
  String _buildPrompt({
    required Place place,
    String? userMood,
    String? timeOfDay,
    String? weather,
    List<String>? userPreferences,
    required String outputLang,
  }) {
    final context = <String>[];
    final placeLabel = _placeLabelForTips(place);
    final outName = _humanOutputLanguage(outputLang);

    // Add place context
    context.add('Place: $placeLabel');
    context.add('Location: ${place.address}');
    context.add('Type: ${place.activities.join(", ")}');
    if (place.rating > 0) context.add('Rating: ${place.rating}/5.0');
    if (place.isIndoor) context.add('Indoor venue');
    context.add('Energy level: ${place.energyLevel}');
    
    // Add user context
    if (userMood != null) context.add('User mood: $userMood');
    if (timeOfDay != null) context.add('Time of day: $timeOfDay');
    if (weather != null) context.add('Weather: $weather');
    if (userPreferences?.isNotEmpty == true) {
      context.add('User preferences: ${userPreferences!.join(", ")}');
    }

    return '''
Generate 3-4 personalized tips for visiting this place based on the context:

${context.join('\n')}

Make the tips:
- Practical and actionable
- Specific to this place and context
- Mood-appropriate and engaging
- Include relevant emojis
- First person only: speak as Moody directly to the user (I / me / we). Never third person ("Moody thinks…", "Tips from Moody", "Moody recommends").
- Write every tip entirely in $outName (no English unless the output language is English)

Format as a simple list, one tip per line, starting with an emoji.
    ''';
  }

  /// System prompt that defines Moody's personality
  String _getSystemPrompt(String lang) {
    final outName = _humanOutputLanguage(lang);
    return '''
You are Moody, WanderMood's friendly AI travel assistant. You're knowledgeable about travel, mood-based recommendations, and creating memorable experiences.

Your personality:
- Warm, enthusiastic, and helpful
- Mood-aware and emotionally intelligent
- Practical with insider tips
- Uses appropriate emojis to enhance communication
- Focuses on personalized, contextual advice
- Always first person when giving tips (I / me / we); never describe yourself in third person

Generate tips that are:
- Specific to the venue and user's current context
- Practical and immediately actionable
- Mood-appropriate and engaging
- 15-30 words each for quick reading
- Written entirely in $outName for the user (no other human language mixed in)
    ''';
  }

  /// Parse AI response and extract individual tips
  List<String> _parseAIResponse(String content, {Place? place, required String lang}) {
    final lines = content.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final tips = <String>[];
    
    for (String line in lines) {
      // Remove bullet points, numbers, and clean up
      String cleanLine = line
          .replaceAll(RegExp(r'^[-•*]\s*'), '')
          .replaceAll(RegExp(r'^\d+\.\s*'), '')
          .trim();
      
      // Skip if line is too short or looks like a header
      if (cleanLine.length < 10 || cleanLine.contains(':') && cleanLine.length < 20) {
        continue;
      }
      
      tips.add(cleanLine);
    }
    
    // Ensure we have at least 2 tips
    if (tips.length < 2) {
      return _getFallbackTips(place, lang);
    }
    
    // Limit to 4 tips max
    return tips.take(4).toList();
  }

  /// Localized short fallbacks when [lang] is not English (matches common Edge locales).
  List<String> _localizedPlaceFallbackTips(Place place, String lang) {
    final label = _placeLabelForTips(place);
    final now = MoodyClock.now();
    final hour = now.hour;
    final bucket = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';

    String tMorningOutdoor() {
      switch (lang) {
        case 'nl':
          return '🌅 Perfecte ochtend voor $label — mooi licht en meestal rustiger.';
        case 'es':
          return '🌅 Buen momento por la mañana en $label — suele haber buena luz y menos gente.';
        case 'de':
          return '🌅 Perfekter Vormittag für $label — schönes Licht und meist weniger los.';
        case 'fr':
          return '🌅 Beau moment le matin à $label — belle lumière et souvent moins de monde.';
        default:
          return '';
      }
    }

    String tAfternoonOutdoor() {
      switch (lang) {
        case 'nl':
          return '☀️ Namiddag bij $label? Neem zonnebescherming en water mee.';
        case 'es':
          return '☀️ ¿Por la tarde en $label? Lleva protección solar e hidrátate.';
        case 'de':
          return '☀️ Nachmittags bei $label? Sonnenschutz mitnehmen und trinken.';
        case 'fr':
          return '☀️ L’après-midi à $label ? Pense au soleil et à t’hydrater.';
        default:
          return '';
      }
    }

    String tEveningOutdoor() {
      switch (lang) {
        case 'nl':
          return '🌙 Avond bij $label kan prachtig zijn — check of er speciale uren zijn.';
        case 'es':
          return '🌙 Por la noche $label puede ser especial — mira si hay horario extendido.';
        case 'de':
          return '🌙 Abends kann $label besonders sein — prüf Öffnungszeiten/Events.';
        case 'fr':
          return '🌙 Le soir, $label peut être magique — vérifie horaires ou événements.';
        default:
          return '';
      }
    }

    String tShoes() {
      switch (lang) {
        case 'nl':
          return '👟 Comfortabele schoenen helpen om $label goed te verkennen.';
        case 'es':
          return '👟 Calzado cómodo ayuda a disfrutar más $label.';
        case 'de':
          return '👟 Bequeme Schuhe helfen, $label richtig zu erkunden.';
        case 'fr':
          return '👟 Des chaussures confortables pour bien profiter de $label.';
        default:
          return '';
      }
    }

    String tHours() {
      switch (lang) {
        case 'nl':
          return '🕐 Check openingstijden en reserveringen voor $label.';
        case 'es':
          return '🕐 Revisa horarios y reservas para $label.';
        case 'de':
          return '🕐 Prüf Öffnungszeiten und Reservierungen für $label.';
        case 'fr':
          return '🕐 Vérifie horaires et réservations pour $label.';
        default:
          return '';
      }
    }

    final tips = <String>[];
    final outdoorish = !place.isIndoor ||
        place.activities.any((a) {
          final x = a.toLowerCase();
          return x.contains('nature') || x.contains('outdoor') || x.contains('sightseeing');
        });
    if (outdoorish) {
      if (bucket == 'morning') {
        tips.add(tMorningOutdoor());
      } else if (bucket == 'afternoon') {
        tips.add(tAfternoonOutdoor());
      } else {
        tips.add(tEveningOutdoor());
      }
    } else {
      switch (lang) {
        case 'nl':
          tips.add('🏠 $label is meestal een fijne plek ongeacht het weer — check wel de openingstijden.');
        case 'es':
          tips.add('🏠 $label suele ir bien con cualquier clima — revisa el horario.');
        case 'de':
          tips.add('🏠 $label passt meist bei jedem Wetter — Öffnungszeiten checken.');
        case 'fr':
          tips.add('🏠 $label convient souvent quelle que soit la météo — vérifie les horaires.');
        default:
          break;
      }
    }
    tips.add(tHours());
    tips.add(tShoes());
    if (place.rating >= 4.0) {
      switch (lang) {
        case 'nl':
          tips.add('⭐ $label scoort goed bij bezoekers — veel plezier!');
        case 'es':
          tips.add('⭐ $label tiene muy buenas valoraciones — ¡disfruta!');
        case 'de':
          tips.add('⭐ $label ist gut bewertet — viel Spaß!');
        case 'fr':
          tips.add('⭐ $label est bien noté — bonne visite !');
        default:
          break;
      }
    }
    return tips.where((s) => s.isNotEmpty).take(4).toList();
  }

  /// Generate smart Moody Tips based on place context (for emergencies)
  List<String> _getFallbackTips(Place? place, String lang) {
    if (place == null) {
      return emergencyTips(lang);
    }

    if (lang != 'en') {
      final short = _localizedPlaceFallbackTips(place, lang);
      if (short.length >= 2) return short;
    }

    final tips = <String>[];
    final now = MoodyClock.now();
    final hour = now.hour;
    final timeOfDay = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';
    final label = _placeLabelForTips(place);

    // Generate dynamic activity-specific tips based on place name and type
    final placeName = place.name.toLowerCase();
    final activities = place.activities.map((a) => a.toLowerCase()).toList();
    
    // Museum-specific dynamic tips
    if (activities.contains('museums') || placeName.contains('museum')) {
      if (timeOfDay == 'morning') {
        tips.add('🌅 Perfect timing! Museums are less crowded in the morning for a peaceful experience');
      } else if (timeOfDay == 'afternoon') {
        tips.add('⏰ Great afternoon choice! Allow 2-3 hours to fully appreciate $label');
      } else {
        tips.add('🌙 Evening visit to $label? Check if they have special late hours or events');
      }
      tips.add('🎨 Ask staff about hidden gems or recently added exhibits at $label');
    }
    
    // Nature/Outdoor specific tips
    else if (activities.contains('nature') || activities.contains('outdoor') || !place.isIndoor) {
      if (timeOfDay == 'morning') {
        tips.add('🌅 Perfect morning choice! $label offers beautiful lighting and fewer crowds');
      } else if (timeOfDay == 'afternoon') {
        tips.add('☀️ Afternoon at $label? Bring sun protection and stay hydrated');
      } else {
        tips.add('🌅 Evening visit to $label might offer stunning sunset views!');
      }
      tips.add('👟 Comfortable shoes recommended for exploring $label to the fullest');
    }
    
    // Sightseeing specific tips
    else if (activities.contains('sightseeing')) {
      if (placeName.contains('tower') || placeName.contains('viewpoint')) {
        tips.add('📸 $label offers incredible photo opportunities - charge your camera!');
        tips.add('🌤️ Clear day? Perfect for spectacular views from $label');
      } else {
        tips.add('🚶‍♀️ Take your time exploring $label - there\'s always more to discover');
        tips.add('📱 Consider downloading a guide app for $label for insider details');
      }
    }
    
    // Food & Drink specific tips
    else if (activities.contains('food & drink') || placeName.contains('restaurant') || placeName.contains('café')) {
      if (timeOfDay == 'morning') {
        tips.add('☕ Morning at $label? Perfect time to try their breakfast specialties');
      } else if (timeOfDay == 'afternoon') {
        tips.add('🍽️ Great lunch spot! Ask $label staff for their signature dishes');
      } else {
        tips.add('🌙 Evening dining at $label? Consider making a reservation');
      }
      tips.add('🗣️ Chat with locals at $label - they know the best menu secrets');
    }
    
    // Shopping specific tips
    else if (activities.contains('shopping') || placeName.contains('market') || placeName.contains('shop')) {
      tips.add('💰 Bring cash to $label - some vendors prefer it over cards');
      tips.add('🛍️ $label is perfect for finding unique local treasures and souvenirs');
    }
    
    // Entertainment specific tips
    else if (activities.contains('entertainment')) {
      tips.add('🎭 Check $label\'s schedule - they might have special shows today');
      tips.add('📅 Arrive early at $label to get the best seats or spots');
    }
    
    // Energy level specific tips with place context
    switch (place.energyLevel.toLowerCase()) {
      case 'low':
        tips.add('😌 $label is perfect for unwinding - take your time and soak in the peaceful atmosphere');
        break;
      case 'medium':
        tips.add('⚖️ $label offers a nice balance - suitable for any energy level today');
        break;
      case 'high':
        tips.add('💪 Ready for adventure? $label will give you an energizing experience!');
        break;
    }
    
    // Rating-based tips with place context
    if (place.rating >= 4.5) {
      tips.add('⭐ $label is highly rated for good reason - prepare to be impressed!');
    } else if (place.rating >= 4.0) {
      tips.add('👍 $label has great reviews - perfect choice for your visit');
    }
    
    // Location-specific tips based on place name
    if (placeName.contains('rotterdam')) {
      tips.add('🚲 Consider biking to $label - Rotterdam is very bike-friendly!');
    }
    
    // Weather-based tips with place context
    if (place.isIndoor) {
      tips.add('🏠 $label is perfect for any weather - excellent choice regardless of conditions!');
    } else {
      tips.add('🌤️ Check the weather for your visit to $label to make the most of the experience');
    }
    
    // Add unique tips based on specific keywords in place name
    if (placeName.contains('historic') || placeName.contains('old') || placeName.contains('heritage')) {
      tips.add('📚 $label has rich history - consider getting a guide or audio tour');
    }
    
    if (placeName.contains('art') || placeName.contains('gallery')) {
      tips.add('🎨 Take time to appreciate the details at $label - art is meant to be savored');
    }
    
    if (placeName.contains('park') || placeName.contains('garden')) {
      tips.add('🌳 $label is perfect for a leisurely stroll and connecting with nature');
    }
    
    // Ensure we always have at least 3 tips, add generic but place-specific ones if needed
    if (tips.length < 3) {
      tips.add('💡 Ask locals about hidden features of $label - they know the best spots');
      tips.add('📸 $label has great photo opportunities - don\'t forget your camera!');
      tips.add('🎯 Visit $label with an open mind and prepare to discover something new');
    }
    
    // Limit to 4 tips max and ensure uniqueness
    return tips.toSet().take(4).toList();
  }

  /// Grounded card blurb; [factsBlock] must already use localized labels.
  Future<String> generatePlaceCardBlurb({
    required AppLocalizations l10n,
    required String factsBlock,
    required String bcp47LanguageCode,
  }) async {
    if (apiKey.isEmpty) return '';
    final trimmed = factsBlock.trim();
    if (trimmed.isEmpty) return '';

    final lang = normalizeTipsLanguageCode(bcp47LanguageCode);
    final outName = switch (lang) {
      'nl' => l10n.moodyPlaceBlurbLanguageDutch,
      'de' => l10n.moodyPlaceBlurbLanguageGerman,
      'fr' => l10n.moodyPlaceBlurbLanguageFrench,
      'es' => l10n.moodyPlaceBlurbLanguageSpanish,
      _ => l10n.moodyPlaceBlurbLanguageEnglish,
    };

    try {
      final url = Uri.parse('$baseUrl${ApiConstants.completions}');
      final userMessage = l10n.moodyPlaceBlurbUserMessage(trimmed, outName);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': l10n.moodyPlaceBlurbSystemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.45,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ generatePlaceCardBlurb HTTP ${response.statusCode}');
        return '';
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final content =
          data['choices']?[0]?['message']?['content'] as String? ?? '';
      return _sanitizePlaceCardBlurb(content);
    } catch (e) {
      debugPrint('❌ generatePlaceCardBlurb: $e');
      return '';
    }
  }

  /// Longer grounded blurb for place detail screens; [factsBlock] must already use localized labels.
  Future<String> generatePlaceDetailBlurb({
    required AppLocalizations l10n,
    required String factsBlock,
    required String bcp47LanguageCode,
  }) async {
    if (apiKey.isEmpty) return '';
    final trimmed = factsBlock.trim();
    if (trimmed.isEmpty) return '';

    final lang = normalizeTipsLanguageCode(bcp47LanguageCode);
    final outName = switch (lang) {
      'nl' => l10n.moodyPlaceBlurbLanguageDutch,
      'de' => l10n.moodyPlaceBlurbLanguageGerman,
      'fr' => l10n.moodyPlaceBlurbLanguageFrench,
      'es' => l10n.moodyPlaceBlurbLanguageSpanish,
      _ => l10n.moodyPlaceBlurbLanguageEnglish,
    };

    try {
      final url = Uri.parse('$baseUrl${ApiConstants.completions}');
      final userMessage =
          l10n.moodyPlaceDetailBlurbUserMessage(trimmed, outName);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': l10n.moodyPlaceDetailBlurbSystemPrompt,
            },
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.45,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ generatePlaceDetailBlurb HTTP ${response.statusCode}');
        return '';
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final content =
          data['choices']?[0]?['message']?['content'] as String? ?? '';
      return _sanitizePlaceDetailBlurb(content);
    } catch (e) {
      debugPrint('❌ generatePlaceDetailBlurb: $e');
      return '';
    }
  }

  String _sanitizePlaceCardBlurb(String raw) {
    var s = raw.trim();
    s = s.replaceAll('"', '');
    if (s.length > 600) {
      s = '${s.substring(0, 580).trim()}…';
    }
    return s;
  }

  String _sanitizePlaceDetailBlurb(String raw) {
    var s = raw.trim();
    s = s.replaceAll('"', '');
    if (s.length > 2000) {
      s = '${s.substring(0, 1980).trim()}…';
    }
    return s;
  }

  /// Generate mood-specific activity suggestions using AI
  Future<List<String>> generateMoodActivities({
    required String mood,
    required String location,
    String? timeOfDay,
    String? weather,
  }) async {
    if (apiKey.isEmpty) {
      debugPrint('❌ OpenAI API key is empty - cannot generate mood activities');
      return [];
    }

    try {
      final url = Uri.parse('$baseUrl${ApiConstants.completions}');
      
      final prompt = '''
Suggest 4-5 specific activities in $location for someone feeling $mood.
${timeOfDay != null ? 'Time: $timeOfDay' : ''}
${weather != null ? 'Weather: $weather' : ''}

Make suggestions:
- Specific to the location
- Appropriate for the mood and time
- Include emojis
- Brief (10-15 words each)
- Actionable and realistic

Format as simple list, one per line.
      ''';

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are Moody, a friendly AI suggesting mood-based activities.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.8,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return _parseAIResponse(content, place: null, lang: 'en');
      }
    } catch (e) {
      debugPrint('❌ Error generating mood activities: $e');
      // Return empty list instead of fallback activities
      return [];
    }
    
    // Return empty list instead of fallback activities
    return [];
  }
} 