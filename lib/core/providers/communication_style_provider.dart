import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CommunicationStyle {
  energetic,
  friendly,
  professional,
  direct,
}

class CommunicationStyleState {
  final CommunicationStyle style;
  final Map<String, Map<String, String>> texts;

  CommunicationStyleState({
    required this.style,
    required this.texts,
  });

  CommunicationStyleState copyWith({
    CommunicationStyle? style,
    Map<String, Map<String, String>>? texts,
  }) {
    return CommunicationStyleState(
      style: style ?? this.style,
      texts: texts ?? this.texts,
    );
  }
}

class CommunicationStyleNotifier extends StateNotifier<CommunicationStyleState> {
  CommunicationStyleNotifier() : super(CommunicationStyleState(
    style: CommunicationStyle.friendly, // Default
    texts: _generateAllTexts(),
  ));

  void setCommunicationStyle(String styleKey) {
    final style = _getStyleFromKey(styleKey);
    state = state.copyWith(style: style);
  }

  // Method to get the current style as a string for API calls
  String getCurrentStyleString() {
    return state.style.toString().split('.').last;
  }

  CommunicationStyle _getStyleFromKey(String key) {
    switch (key) {
      case 'energetic':
        return CommunicationStyle.energetic;
      case 'friendly':
        return CommunicationStyle.friendly;
      case 'professional':
        return CommunicationStyle.professional;
      case 'direct':
        return CommunicationStyle.direct;
      default:
        return CommunicationStyle.friendly;
    }
  }

  String getText(String screen, String key) {
    final styleKey = state.style.toString().split('.').last;
    return state.texts[screen]?[styleKey] ?? state.texts[screen]?['friendly'] ?? '';
  }

  static Map<String, Map<String, String>> _generateAllTexts() {
    return {
      'mood': {
        'energetic': 'Let\'s sync our vibes! ✨',
        'friendly': 'What\'s your travel mood? 😊',
        'professional': 'Travel Mood Preferences',
        'direct': 'Select your moods',
      },
      'mood_subtitle': {
        'energetic': 'What moods inspire you to explore?',
        'friendly': 'What inspires you to get out and explore?',
        'professional': 'What type of experiences appeal to you most?',
        'direct': 'Choose your preferred experience types:',
      },
      'interests': {
        'energetic': 'What gets you hyped? 🔥',
        'friendly': 'What catches your interest? 🌟',
        'professional': 'Travel Interest Categories',
        'direct': 'Select interests',
      },
      'interests_subtitle': {
        'energetic': 'Pick all the things that make your heart race!',
        'friendly': 'Choose the activities that sound fun to you',
        'professional': 'Select your preferred activity categories',
        'direct': 'Choose activity types:',
      },
      'home_base': {
        'energetic': 'Where\'s home base? 🏠',
        'friendly': 'What\'s your travel style? 🏠',
        'professional': 'Travel Experience Level',
        'direct': 'Travel background',
      },
      'home_base_subtitle': {
        'energetic': 'Help me understand your travel style',
        'friendly': 'Let me know your travel background',
        'professional': 'Please indicate your travel experience level',
        'direct': 'Select your level:',
      },
      'social_vibe': {
        'energetic': 'What\'s your social vibe? 👥',
        'friendly': 'How do you like to explore? 👥',
        'professional': 'Social Preference Settings',
        'direct': 'Group preferences',
      },
      'social_vibe_subtitle': {
        'energetic': 'How do you like to experience things?',
        'friendly': 'What\'s your preferred group size?',
        'professional': 'Please select your social interaction preferences',
        'direct': 'Choose group size:',
      },
      'planning_pace': {
        'energetic': 'Tell me your pace ⏰',
        'friendly': 'What\'s your planning style? ⏰',
        'professional': 'Planning Timeline Preferences',
        'direct': 'Planning timeframe',
      },
      'planning_pace_subtitle': {
        'energetic': 'Your planning style',
        'friendly': 'How far ahead do you like to plan?',
        'professional': 'Please indicate your preferred planning timeline',
        'direct': 'Select timeframe:',
      },
      'travel_style': {
        'energetic': 'How do you roll? ⏰',
        'friendly': 'What\'s your travel approach? 🎒',
        'professional': 'Travel Style Assessment',
        'direct': 'Travel style',
      },
      'travel_style_subtitle': {
        'energetic': 'Your planning style',
        'friendly': 'How do you like to travel?',
        'professional': 'Please select your preferred travel approach',
        'direct': 'Choose style:',
      },
      'budget': {
        'energetic': 'Budget preferences 💸',
        'friendly': 'What\'s your budget style? 💰',
        'professional': 'Budget Range Selection',
        'direct': 'Budget range',
      },
      'budget_subtitle': {
        'energetic': 'Let\'s talk about your ideal budget range',
        'friendly': 'Let\'s find options that work for you',
        'professional': 'Please select your preferred spending range',
        'direct': 'Select range:',
      },
      'continue_button': {
        'energetic': 'Let\'s go!',
        'friendly': 'Continue',
        'professional': 'Proceed',
        'direct': 'Next',
      },
      'finish_button': {
        'energetic': 'I\'m ready! 🚀',
        'friendly': 'All set!',
        'professional': 'Complete Setup',
        'direct': 'Finish',
      },
      'multiple_selection_hint': {
        'energetic': 'You can pick multiple - go wild! ✨',
        'friendly': 'You can select multiple options ✨',
        'professional': 'Multiple selections are permitted',
        'direct': 'Multiple selections allowed',
      },
      'welcome_title': {
        'energetic': 'Hey there, adventure seeker! 🌟',
        'friendly': 'Welcome to WanderMood! 😊',
        'professional': 'Welcome to WanderMood',
        'direct': 'Let\'s get started',
      },
      'welcome_subtitle': {
        'energetic': 'Ready to discover your perfect vibe?',
        'friendly': 'Let\'s find your perfect travel experiences',
        'professional': 'Personalized travel recommendation system',
        'direct': 'Travel recommendations',
      },
      'welcome_button': {
        'energetic': 'I\'m ready, let\'s go! 🚀',
        'friendly': 'I\'m ready, let\'s go',
        'professional': 'Begin Setup',
        'direct': 'Start',
      },
      'summary_title': {
        'energetic': '🧳 Your Travel Profile',
        'friendly': '🧳 Your Travel Profile',
        'professional': 'Travel Preferences Summary',
        'direct': 'Your Profile',
      },
      'summary_subtitle': {
        'energetic': 'Here\'s what I\'ve learned about your vibe so far—looks pretty awesome if you ask me 😎',
        'friendly': 'Here\'s what I\'ve learned about your travel style—looking great! 😊',
        'professional': 'Below is a comprehensive summary of your travel preferences and recommendations.',
        'direct': 'Your preferences summary:',
      },
      'summary_personality_title': {
        'energetic': 'Your Travel Personality',
        'friendly': 'Your Travel Personality',
        'professional': 'Travel Profile Analysis',
        'direct': 'Profile Type',
      },
      'summary_vibe_title': {
        'energetic': 'Your Current Vibe',
        'friendly': 'Your Travel Vibe',
        'professional': 'Mood Preferences',
        'direct': 'Selected Moods',
      },
      'summary_vibe_subtitle': {
        'energetic': 'How you like to feel as you explore',
        'friendly': 'The feelings you want from your travels',
        'professional': 'Preferred experiential mood categories',
        'direct': 'Experience types',
      },
      'summary_interests_title': {
        'energetic': 'Things That Spark Your Curiosity',
        'friendly': 'What Catches Your Interest',
        'professional': 'Interest Categories',
        'direct': 'Selected Interests',
      },
      'summary_interests_subtitle': {
        'energetic': 'Stuff that catches your eye',
        'friendly': 'Activities that appeal to you',
        'professional': 'Preferred activity categories',
        'direct': 'Activity types',
      },
      'summary_budget_title': {
        'energetic': 'How You Like to Spend',
        'friendly': 'Your Budget Style',
        'professional': 'Budget Range Selection',
        'direct': 'Budget Range',
      },
      'summary_budget_subtitle': {
        'energetic': 'We\'ll match the vibe to your wallet',
        'friendly': 'We\'ll find options that work for you',
        'professional': 'Recommendations will align with your budget preferences',
        'direct': 'Spending level',
      },
      'summary_preview_title': {
        'energetic': 'Coming up for you...',
        'friendly': 'What\'s coming up for you...',
        'professional': 'Upcoming Recommendations',
        'direct': 'Next recommendations',
      },
      'summary_bottom_message': {
        'energetic': 'You\'ve got great taste! I\'m cooking up something unforgettable 💡 Ready to see where it takes you?',
        'friendly': 'Great choices! I\'m preparing some wonderful recommendations for you. Ready to explore?',
        'professional': 'Your preferences have been processed. The system is generating personalized recommendations.',
        'direct': 'Preferences saved. Ready to explore?',
      },
      'summary_start_button': {
        'energetic': 'Start exploring! 🚀',
        'friendly': 'Let\'s start exploring!',
        'professional': 'Begin Exploration',
        'direct': 'Start',
      },
      'summary_edit_button': {
        'energetic': 'Edit preferences',
        'friendly': 'Edit preferences',
        'professional': 'Modify Preferences',
        'direct': 'Edit',
      },
    };
  }
}

final communicationStyleProvider = StateNotifierProvider<CommunicationStyleNotifier, CommunicationStyleState>((ref) {
  return CommunicationStyleNotifier();
});

// Helper provider to get text easily
final dynamicTextProvider = Provider.family<String, Map<String, String>>((ref, params) {
  final communicationState = ref.watch(communicationStyleProvider);
  final notifier = ref.read(communicationStyleProvider.notifier);
  return notifier.getText(params['screen']!, params['key']!);
}); 