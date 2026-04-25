import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/domain/enums/moody_feature.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_loading_screen.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/services/connectivity_service.dart';
import 'package:wandermood/core/utils/offline_feedback.dart';
import 'package:wandermood/core/utils/wandermood_tts_presentation.dart';
import 'package:wandermood/core/services/notification_service.dart';
import 'package:wandermood/core/notifications/moody_chat_reminder_in_app_mirror.dart';
import 'package:wandermood/core/notifications/notification_copy.dart';

// WanderMood v2 — Moody conversation overlay (aligned with moody_chat_sheet / Screen 9)
const Color _wmSkyTint = Color(0xFFEDF5F9);
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);

/// Composer-only: quoted message for the next outgoing line (same idea as Moody Hub).
class _ReplyDraft {
  const _ReplyDraft({required this.quotedText, required this.quotedIsUser});
  final String quotedText;
  final bool quotedIsUser;
}

String _userMessageWithReplyForModel(
  String userText,
  String? replyToText,
  bool? replyToIsUser,
) {
  final body = userText.trim();
  final q = replyToText?.trim();
  if (q == null || q.isEmpty) return body;
  final safeQuote = q.length > 600 ? '${q.substring(0, 600)}…' : q;
  final replyingToSelf = replyToIsUser == true;
  final header = replyingToSelf
      ? '(The user is replying to their own earlier message: """$safeQuote""")'
      : '(The user is replying to this earlier Moody message: """$safeQuote""")';
  return '$header\n\n$body';
}

class MoodyConversationScreen extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final Set<String> selectedMoods;
  
  const MoodyConversationScreen({
    Key? key, 
    required this.onClose,
    this.selectedMoods = const {},
  }) : super(key: key);

  @override
  ConsumerState<MoodyConversationScreen> createState() => _MoodyConversationScreenState();
}

class _MoodyConversationScreenState extends ConsumerState<MoodyConversationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Set once in [didChangeDependencies]; used for STT locale + TTS language.
  String _langCode = 'en';

  static String _ttsLang(String lang) {
    const m = {'nl': 'nl-NL', 'de': 'de-DE', 'fr': 'fr-FR', 'es': 'es-ES'};
    return m[lang] ?? 'en-US';
  }

  static String _sttLocale(String lang) {
    const m = {'nl': 'nl_NL', 'de': 'de_DE', 'fr': 'fr_FR', 'es': 'es_ES'};
    return m[lang] ?? 'en_US';
  }
  final TextEditingController _textController = TextEditingController();
  
  bool _isListening = false;
  String _userInput = '';
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _continuousMode = false;
  bool _speechRecognitionAvailable = false;
  bool _conversationCompleted = false;
  Timer? _silenceTimer;
  bool _greetingAdded = false;
  
  List<ChatMessage> _chatMessages = [];
  final ScrollController _scrollController = ScrollController();
  _PendingReminder? _pendingReminder;
  _ReplyDraft? _replyDraft;
  
  // Detected moods based on conversation
  Set<String> _detectedMoods = {};
  int _conversationTurns = 0;
  
  // Map of mood keywords to detect from conversation
  final Map<String, String> _moodKeywords = {
    'happy': 'Happy',
    'excited': 'Excited',
    'relaxed': 'Relaxed',
    'calm': 'Relaxed',
    'peaceful': 'Relaxed',
    'romantic': 'Romantic',
    'date': 'Romantic', 
    'love': 'Romantic',
    'adventure': 'Adventure',
    'adventurous': 'Adventure',
    'explore': 'Adventure',
    'hike': 'Adventure',
    'energetic': 'Energetic',
    'active': 'Energetic',
    'exercise': 'Energetic',
    'family': 'Family fun',
    'kids': 'Family fun',
    'children': 'Family fun',
    'food': 'Foody',
    'eat': 'Foody',
    'restaurant': 'Foody',
    'cuisine': 'Foody',
    'mindful': 'Mindful',
    'meditation': 'Mindful',
    'creative': 'Creative',
    'art': 'Creative',
    'festival': 'Festive',
    'celebration': 'Festive',
    'party': 'Festive',
    'luxury': 'Luxurious',
    'luxurious': 'Luxurious',
    'premium': 'Luxurious',
    'surprise': 'Surprise',
    'unexpected': 'Surprise',
  };
  
  // Advanced keyword weighting for better detection
  final Map<String, double> _keywordWeights = {
    'love': 1.5,
    'really want': 1.8,
    'looking for': 1.5,
    'enjoy': 1.3,
    'prefer': 1.4,
    'interested in': 1.5,
    'favorite': 1.7,
    'hate': -1.0,
    'dislike': -0.8,
    'not interested': -1.0,
    'boring': -0.7,
    'avoid': -0.9,
  };
  
  // Track keyword occurrences for better mood detection
  final Map<String, int> _moodOccurrences = {};
  
  // Track mood keyword strength - how confidently each mood is detected
  final Map<String, double> _moodStrengths = {};
  
  // Confidence threshold to suggest plan
  final double _confidenceThreshold = 0.6;
  
  // Conversation memory to track context
  final List<String> _conversationMemory = [];
  
  // Last few topics mentioned by the user for context
  final Set<String> _recentTopics = {};
  
  // Topic categories for better context understanding
  final Map<String, List<String>> _topicCategories = {
    'outdoor': ['outdoor', 'nature', 'park', 'hike', 'walk', 'beach', 'mountain'],
    'indoor': ['indoor', 'museum', 'gallery', 'cinema', 'theater', 'restaurant'],
    'active': ['active', 'sports', 'exercise', 'run', 'swim', 'bike', 'cycling'],
    'relaxed': ['relax', 'chill', 'quiet', 'peace', 'rest', 'sleep', 'calm'],
    'cultural': ['culture', 'history', 'art', 'music', 'concert', 'show', 'performance'],
    'social': ['social', 'friends', 'family', 'group', 'together', 'people', 'crowd'],
    'solo': ['alone', 'solo', 'myself', 'individual', 'personal', 'private'],
  };
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTts();
    _initSpeechRecognition();
    
    // Copy any pre-selected moods
    _detectedMoods = Set.from(widget.selectedMoods);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _langCode = Localizations.localeOf(context).languageCode;
    if (!_greetingAdded) {
      _greetingAdded = true;
      final greeting = AppLocalizations.of(context)!.moodyConversationGreeting;
      _addMoodyMessage(greeting);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _speakMoodyResponse(greeting);
      });
    }
  }
  
  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }
  
  Future<void> _initTts() async {
    await applyWanderMoodTtsPresentation(
      tts: _flutterTts,
      bcp47Locale: _ttsLang(_langCode),
    );

    _flutterTts.setStartHandler(() {
      if (!mounted) return;
      setState(() {
        _isSpeaking = true;
      });
    });
    
    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
      });
    });
    
    _flutterTts.setErrorHandler((message) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
      });
    });
  }
  
  Future<void> _initSpeechRecognition() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      var available = await _speech.initialize(
        onStatus: (status) {
          if (status != 'done') return;
          if (!mounted) return;
          _silenceTimer?.cancel();
          setState(() {
            _isListening = false;
          });

          // One-shot STT: whenever the listen session ends (silence, timeout, or
          // user tapped stop), submit the transcript — same path as Moody Hub UX.
          final toSend = _userInput.trim();
          if (toSend.isEmpty || _conversationCompleted) return;

          _handleUserInput(toSend);

          if (_continuousMode && !_conversationCompleted) {
            _waitForMoodyAndListen();
          }
        },
        onError: (error) {
          setState(() {
            _isListening = false;
          });
          if (kDebugMode) debugPrint("Speech recognition error: $error");
        },
      );
      
      setState(() {
        _speechRecognitionAvailable = available;
      });
      
      if (available) {
        if (kDebugMode) debugPrint("Speech recognition initialized");
      } else {
        if (kDebugMode) debugPrint("Speech recognition not available");
      }
    } else {
      if (kDebugMode) debugPrint("Microphone permission denied");
    }
  }
  
  // Add new method to wait for Moody to finish speaking before listening again
  void _waitForMoodyAndListen() {
    // Check periodically if Moody has finished speaking
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isSpeaking && !_isProcessing && _continuousMode && !_conversationCompleted) {
        timer.cancel();
        // Add a small delay before listening again
        Future.delayed(const Duration(milliseconds: 800), () {
          if (_continuousMode && mounted && !_conversationCompleted) {
            _startListening();
          }
        });
      }
      
      // If continuous mode was turned off or conversation completed, cancel the timer
      if (!_continuousMode || _conversationCompleted) {
        timer.cancel();
      }
    });
  }
  
  // New method to activate continuous mode
  void _toggleContinuousMode() {
    if (_conversationCompleted) return;
    
    setState(() {
      _continuousMode = !_continuousMode;
    });
    
    if (_continuousMode) {
      // If turning on continuous mode, start listening
      _startListening();
    } else {
      // If turning off continuous mode, stop listening
      if (_isListening) {
        _speech.stop();
        setState(() {
          _isListening = false;
        });
      }
      
      // Cancel any pending timers
      _silenceTimer?.cancel();
    }
  }
  
  // Extract the listening start functionality to a separate method
  Future<void> _startListening() async {
    if (_conversationCompleted) return;
    
    setState(() {
      _isListening = true;
      _userInput = '';
    });
    _textController.value = const TextEditingValue();

    try {
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          setState(() {
            _userInput = text;
          });
          _textController.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );

          // Reset silence timer on each result
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(seconds: 2), () {
            if (_isListening && _userInput.trim().isNotEmpty) {
              _speech.stop();
            }
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: _sttLocale(_langCode),
        listenOptions: stt.SpeechListenOptions(partialResults: true),
      );
    } catch (e) {
      if (kDebugMode) debugPrint("Error starting speech recognition: $e");
      setState(() {
        _isListening = false;
      });
    }
  }
  
  // Update the _listen method to use the new functionality
  Future<void> _listen() async {
    if (_conversationCompleted) return;
    
    if (!_speechRecognitionAvailable) {
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.moodySpeechNotAvailable,
        isError: true,
      );
      return;
    }
    
    if (_continuousMode) {
      // Toggle continuous mode off
      _toggleContinuousMode();
      return;
    }
    
    if (!_isListening) {
      _startListening();
    } else {
      _speech.stop();
      // Submit happens in [onStatus] when status is `done` (single code path).
    }
  }
  
  Future<void> _speakMoodyResponse(String text) async {
    if (!mounted) return;
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    if (!mounted) return;
    await _flutterTts.speak(text);
  }
  
  // Check if the user is ready for a plan based on their input
  bool _isUserReadyForPlan(String input) {
    final lowercaseInput = input.toLowerCase();
    
    // Direct indicators the user wants suggestions
    if (lowercaseInput.contains('suggest') || 
        lowercaseInput.contains('recommend') ||
        lowercaseInput.contains('show me') ||
        lowercaseInput.contains('what can i do')) {
      return true;
    }
    
    // Agreement words should ALWAYS trigger a plan when Moody has suggested one
    // This is critical to prevent looping - any affirmative response means "yes" to suggestions
    if (lowercaseInput.contains('yes') || 
        lowercaseInput.contains('sure') ||
        lowercaseInput.contains('okay') ||
        lowercaseInput.contains('ok') ||
        lowercaseInput.contains('good') ||
        lowercaseInput.contains('sounds good') ||
        lowercaseInput.contains('please') ||
        lowercaseInput.contains('yep') ||
        lowercaseInput.contains('yeah')) {
      return true;
    }
    
    // Check for enthusiasm markers
    bool showsEnthusiasm = lowercaseInput.contains('!') || 
                            lowercaseInput.contains('great') ||
                            lowercaseInput.contains('awesome') ||
                            lowercaseInput.contains('perfect');
    
    // If the user is enthusiastic and we've detected a mood, consider them ready
    if (showsEnthusiasm && _detectedMoods.isNotEmpty && _conversationTurns >= 2) {
      return true;
    }
    
    return false;
  }

  // Analyze conversation for context
  void _analyzeConversationContext(String input) {
    final lowercaseInput = input.toLowerCase();
    
    // Add to conversation memory (max 5 entries)
    _conversationMemory.add(lowercaseInput);
    if (_conversationMemory.length > 5) {
      _conversationMemory.removeAt(0);
    }
    
    // Extract topics from the input
    for (var category in _topicCategories.entries) {
      for (var keyword in category.value) {
        if (lowercaseInput.contains(keyword)) {
          _recentTopics.add(category.key);
          break; // Found one keyword from this category, no need to check others
        }
      }
    }
    
    // Limit recent topics to avoid noise
    if (_recentTopics.length > 3) {
      // Keep only the most recent topics (based on this input)
      var newTopics = <String>{};
      for (var category in _topicCategories.entries) {
        for (var keyword in category.value) {
          if (lowercaseInput.contains(keyword)) {
            newTopics.add(category.key);
            if (newTopics.length >= 3) break;
          }
        }
        if (newTopics.length >= 3) break;
      }
      _recentTopics.clear();
      _recentTopics.addAll(newTopics);
    }
  }
  
  // Modify _handleUserInput to include context analysis
  void _handleUserInput(String input) {
    if (input.isEmpty || _conversationCompleted) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final replySnap = _replyDraft;
    setState(() {
      _isProcessing = true;
      _replyDraft = null;
      _userInput = '';
      _textController.clear();
    });

    // Add user message to chat (optional reply metadata)
    _addUserMessage(input, replyDraft: replySnap);

    // Analyze conversation context
    _analyzeConversationContext(input);

    final reminder = _parseReminderIntent(input);
    if (reminder != null) {
      final inMinutes = reminder.fireAt
          .difference(MoodyClock.now())
          .inMinutes
          .clamp(0, 10080);
      setState(() {
        _pendingReminder = reminder;
        _isProcessing = false;
      });
      final response = _langCode == 'nl'
          ? 'Top, ik kan je hierover herinneren. Zal ik een reminder zetten voor over $inMinutes minuten?'
          : 'Got it. I can remind you about this. Want me to set a reminder in $inMinutes minutes?';
      _addMoodyMessage(response);
      _speakMoodyResponse(response);
      return;
    }
    
    // Detect mood keywords from input
    _detectMoods(input);
    
    // Check if user is directly asking for a plan
    if (_isUserReadyForPlan(input)) {
      _suggestPlan();
      return;
    }
    
    // Generate response (in real app, this would call an API/model)
    final modelInput = _userMessageWithReplyForModel(
      input,
      replySnap?.quotedText,
      replySnap?.quotedIsUser,
    );
    _generateMoodyResponse(modelInput, input);
  }
  
  void _detectMoods(String input) {
    final String lowercaseInput = input.toLowerCase();
    
    // Check for mood keywords and calculate strength
    for (var entry in _moodKeywords.entries) {
      // Base detection - if keyword is present
      if (lowercaseInput.contains(entry.key)) {
        // Add to detected moods
        _detectedMoods.add(entry.value);
        
        // Increment occurrence count
        _moodOccurrences[entry.value] = (_moodOccurrences[entry.value] ?? 0) + 1;
        
        // Base strength is 1.0
        double strength = 1.0;
        
        // Check for modifiers near the keyword
        for (var weightEntry in _keywordWeights.entries) {
          // Check if the modifier is within 15 characters of the keyword
          int keywordPos = lowercaseInput.indexOf(entry.key);
          int range = 15; // Characters to look before and after
          
          // Calculate search range
          int startPos = max(0, keywordPos - range);
          int endPos = min(lowercaseInput.length, keywordPos + entry.key.length + range);
          String context = lowercaseInput.substring(startPos, endPos);
          
          // If modifier is in context, adjust strength
          if (context.contains(weightEntry.key)) {
            strength *= weightEntry.value;
          }
        }
        
        // Update strength
        _moodStrengths[entry.value] = (_moodStrengths[entry.value] ?? 0.0) + strength;
      }
    }
    
    // Analyze negations
    if (lowercaseInput.contains('not ') || lowercaseInput.contains("don't ") || 
        lowercaseInput.contains("doesn't ") || lowercaseInput.contains("isn't ")) {
      // Check for negated moods and reduce their strength
      for (var mood in _detectedMoods.toList()) {
        // Look for constructs like "not relaxing" or "don't want adventure"
        for (var entry in _moodKeywords.entries.where((e) => e.value == mood)) {
          // Check for negation near the keyword
          String negationPattern = 'not ${entry.key}';
          String dontPattern = "don't ${entry.key}";
          String doesntPattern = "doesn't ${entry.key}";
          String isntPattern = "isn't ${entry.key}";
          
          if (lowercaseInput.contains(negationPattern) || 
              lowercaseInput.contains(dontPattern) || 
              lowercaseInput.contains(doesntPattern) || 
              lowercaseInput.contains(isntPattern)) {
            // Greatly reduce mood strength or remove it entirely
            _moodStrengths[mood] = (_moodStrengths[mood] ?? 0.0) * 0.2;
            
            // If strength is very low, remove the mood
            if ((_moodStrengths[mood] ?? 0.0) < 0.3) {
              _detectedMoods.remove(mood);
              _moodOccurrences.remove(mood);
            }
          }
        }
      }
    }
    
    // If we have more than 3 detected moods, keep the strongest ones
    if (_detectedMoods.length > 3) {
      // Sort moods by strength (highest first)
      final sortedMoods = _detectedMoods.toList()
        ..sort((a, b) => (_moodStrengths[b] ?? 0.0).compareTo(_moodStrengths[a] ?? 0.0));
      
      // Keep only top 3
      _detectedMoods = sortedMoods.take(3).toSet();
    }
  }

  _PendingReminder? _parseReminderIntent(String input) {
    final t = input.toLowerCase().trim();
    final asksReminder = t.contains('herinner') ||
        t.contains('remind me') ||
        t.contains('remember me') ||
        t.contains('reminder');
    if (!asksReminder) return null;

    final minuteMatch = RegExp(
      r'(\d+)\s*(min|mins|minute|minutes|minuut|minuten)\b',
    ).firstMatch(t);
    if (minuteMatch != null) {
      final m = int.tryParse(minuteMatch.group(1) ?? '');
      if (m != null && m > 0) {
        return _PendingReminder(
          fireAt: MoodyClock.now().add(Duration(minutes: m)),
          body: _langCode == 'nl'
              ? 'Ik herinner je aan wat je net met mij besprak.'
              : 'I am reminding you about what we just discussed.',
        );
      }
    }

    if (t.contains('morgen') || t.contains('tomorrow')) {
      final now = MoodyClock.now();
      final tomorrow = DateTime(now.year, now.month, now.day).add(
        const Duration(days: 1),
      );
      return _PendingReminder(
        fireAt: tomorrow.add(const Duration(hours: 9)),
        body: _langCode == 'nl'
            ? 'Hoe ging het met wat je mij gisteren vertelde?'
            : 'How did it go with what you told me yesterday?',
      );
    }

    return null;
  }

  Future<void> _confirmPendingReminder() async {
    final pending = _pendingReminder;
    if (pending == null) return;
    final id = pending.fireAt.millisecondsSinceEpoch.remainder(1 << 30);
    try {
      await NotificationService.instance.scheduleAt(
        id,
        NotificationCopy(title: 'Moody', body: pending.body),
        pending.fireAt,
      );
      mirrorMoodyChatReminderToInAppNotification(
        fireAt: pending.fireAt,
        localNotificationId: id,
      );
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() => _pendingReminder = null);
    final msg = _langCode == 'nl'
        ? 'Klaar. Ik heb je reminder gezet.'
        : 'Done. I set your reminder.';
    _addMoodyMessage(msg);
    showWanderMoodToast(context, message: msg);
  }

  void _dismissPendingReminder() {
    if (!mounted) return;
    setState(() => _pendingReminder = null);
  }
  
  // Calculate confidence based on conversation turns and mood strengths
  double _calculateConfidence() {
    if (_detectedMoods.isEmpty) return 0.0;
    
    // Base confidence based on conversation turns
    double confidence = _conversationTurns < 2 ? 0.3 : 
                        _conversationTurns < 3 ? 0.5 : 0.7;
    
    // Calculate average mood strength
    double totalStrength = 0.0;
    for (var mood in _detectedMoods) {
      totalStrength += _moodStrengths[mood] ?? 0.0;
    }
    double avgStrength = totalStrength / _detectedMoods.length;
    
    // Adjust confidence based on strength
    confidence *= avgStrength;
    
    // Adjust based on consistent mentions
    if (_detectedMoods.length == 1 && (_moodOccurrences[_detectedMoods.first] ?? 0) > 1) {
      // Single mood mentioned multiple times indicates higher confidence
      confidence += 0.1 * (_moodOccurrences[_detectedMoods.first] ?? 1);
    }
    
    // Cap confidence between 0 and 1
    return confidence.clamp(0.0, 1.0);
  }
  
  /// [modelInput] may include a reply-to prefix for context; [rawUserInput] is what the user typed.
  Future<void> _generateMoodyResponse(
    String modelInput,
    String rawUserInput,
  ) async {
    // Increment conversation turns
    _conversationTurns++;
    
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Simple responses based on user input keywords
    String response = '';
    final lowercaseModel = modelInput.toLowerCase();
    final lowercaseRaw = rawUserInput.toLowerCase();
    
    // ANY form of "yes" response should trigger plan suggestion after initial turns
    if (_conversationTurns >= 2 && (
        lowercaseRaw.contains('yes') || 
        lowercaseRaw.contains('sure') || 
        lowercaseRaw.contains('okay') || 
        lowercaseRaw.contains('ok') || 
        lowercaseRaw.contains('yeah') || 
        lowercaseRaw.contains('yep'))) {
      _suggestPlan();
      return;
    }
    
    // Calculate confidence in mood detection
    double confidence = _calculateConfidence();
    
    // Check if we've reached confidence threshold to make a suggestion
    if (_detectedMoods.isNotEmpty && confidence >= _confidenceThreshold) {
      _suggestPlan();
      return;
    }
    
    // If we're getting close to confidence threshold but not quite there
    if (_detectedMoods.isNotEmpty && confidence >= 0.4 && _conversationTurns >= 2) {
      // Ask a more direct question to confirm mood
      String detectedMood = _detectedMoods.isNotEmpty ? _detectedMoods.first : "adventurous";
      
      response = "Based on our conversation, I think you might be feeling $detectedMood. Would you like me to suggest some activities for this mood?";
      
      setState(() {
        _isProcessing = false;
      });
      
      // Add response to chat
      _addMoodyMessage(response);
      
      // Speak the response
      _speakMoodyResponse(response);
      return;
    }
    
    // Handle "I don't know" or uncertain responses
    if (lowercaseModel.contains("don't know") || 
        lowercaseModel.contains("not sure") || 
        lowercaseModel.contains("uncertain")) {
      // Try to guide the conversation
      response = "That's okay! Let me ask another way - are you looking for something relaxing, exciting, or perhaps romantic?";
      
      setState(() {
        _isProcessing = false;
      });
      
      // Add response to chat
      _addMoodyMessage(response);
      
      // Speak the response
      _speakMoodyResponse(response);
      return;
    }
    
    if (lowercaseModel.contains('hello') || lowercaseModel.contains('hi')) {
      response = "Hello! How can I assist you with your travel plans today?";
    } else if (lowercaseModel.contains('weather')) {
              response = "It's a beautiful day in Rotterdam! Currently 22°C and sunny.";
    } else if (lowercaseModel.contains('restaurant') || lowercaseModel.contains('food') || lowercaseModel.contains('eat')) {
      response = "I can suggest some great restaurants based on your mood! Are you looking for something romantic or adventurous?";
    } else if (lowercaseModel.contains('activity') || lowercaseModel.contains('do')) {
      response = "There are lots of activities nearby! Would you like outdoor adventures or cultural experiences?";
    } else if (lowercaseModel.contains('happy') || lowercaseModel.contains('glad')) {
      response = "I'm so glad you're happy! When you're in a good mood, I recommend exploring the vibrant markets or taking a scenic hike.";
    } else if (lowercaseModel.contains('sad') || lowercaseModel.contains('tired')) {
      response = "I'm sorry to hear that. How about a relaxing day at a spa or a calm walk along the coast to help lift your spirits?";
    } else if (lowercaseModel.contains('romantic')) {
      response = "For a romantic experience, I suggest a sunset cruise in the bay or dinner at a cozy restaurant with ocean views.";
    } else if (lowercaseModel.contains('adventure')) {
      response = "If you're feeling adventurous, try hiking at Land's End or taking a bike ride across the Golden Gate Bridge!";
    } else if (lowercaseModel.contains('thank')) {
      response = "You're welcome! I'm always here to help make your travels more enjoyable.";
    } else if (lowercaseModel.contains('bye')) {
      response = "Goodbye! Have a wonderful day. Feel free to talk to me anytime you need travel suggestions!";
    } else if (_conversationTurns == 1) {
      // First response should ask more about their mood
      response = "That's interesting! Could you tell me more about how you're feeling today or what kind of activities you enjoy?";
    } else if (_conversationTurns == 2) {
      // Second response should ask a more direct question
      response = "I'd love to suggest some activities for you! Are you more in the mood for something energetic, relaxing, or romantic?";
    } else if (_conversationTurns >= 4) {
      // Make a direct plan suggestion after 4 turns
      _suggestPlan();
      return;
    } else {
      // For third response, be more direct in getting mood info
      response = "Based on our conversation, I could recommend some great activities. Tell me more specifically - are you looking for adventure, relaxation, or something else?";
    }
    
    setState(() {
      _isProcessing = false;
    });
    
    // Add response to chat
    _addMoodyMessage(response);
    
    // Speak the response
    _speakMoodyResponse(response);
  }
  
  void _suggestPlan() {
    // Stop any ongoing speech
    _flutterTts.stop();
    
    // Set conversation as completed to prevent further interaction
    setState(() {
      _conversationCompleted = true;
      _isProcessing = false;
      _isListening = false;
      _continuousMode = false;
    });
    
    // Final response message
    String finalResponse = "Perfect! Based on our conversation, I've determined that you're in the mood for ";
    
    if (_detectedMoods.isEmpty) {
      // Default to "Adventure" if no mood detected
      _detectedMoods.add("Adventure");
    }
    
    // List the detected moods
    finalResponse += _detectedMoods.join(", ");
    finalResponse += " activities. Let me create a personalized plan just for you!";
    
    // Add and speak the final message
    _addMoodyMessage(finalResponse);
    _speakMoodyResponse(finalResponse);
    
    // Wait for speech to finish, then navigate
    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
      });
      _showPlanTransition();
    });
  }
  
  void _showPlanTransition() {
    // Visual feedback for plan creation
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return Center(
          child: Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated moody icon
                MoodyCharacter(
                  size: 100,
                  mood: 'happy',
                ).animate(
                  onPlay: (controller) => controller.repeat(),
                ).scale(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  "Creating Your Plan",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Mood tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _detectedMoods.map((mood) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _wmForestTint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _wmParchment.withOpacity(0.8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: _wmForest, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            mood,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                
                // Loading animation
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(_wmForest),
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(),
                ).shimmer(
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                ),
              ],
            ),
          ),
        );
      },
    );
    
    // Navigate to plan loading screen after a short delay to let dialog animation play
    Future.delayed(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;
      final connected = await ref.read(connectivityServiceProvider).isConnected;
      if (!mounted) return;

      Navigator.of(context).pop();

      if (!connected) {
        showOfflineSnackBar(context);
        return;
      }

      widget.onClose();

      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PlanLoadingScreen(
            selectedMoods: _detectedMoods.toList(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }
  
  void _addUserMessage(String message, {_ReplyDraft? replyDraft}) {
    setState(() {
      _chatMessages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: MoodyClock.now(),
        replyToText: replyDraft?.quotedText,
        replyToIsUser: replyDraft?.quotedIsUser,
      ));
    });
    _scrollToBottom();
  }
  
  void _addMoodyMessage(String message) {
    setState(() {
      _chatMessages.add(ChatMessage(
        text: message,
        isUser: false,
        timestamp: MoodyClock.now(),
      ));
    });
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _flutterTts.stop();
    _speech.cancel();
    _scrollController.dispose();
    _silenceTimer?.cancel();
    _textController.dispose();
    _continuousMode = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred background
          GestureDetector(
            onTap: _conversationCompleted ? null : widget.onClose,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          ),
          
          // Main conversation container
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.75,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Column(
                        children: const [
                          Expanded(flex: 4, child: ColoredBox(color: _wmSkyTint)),
                          Expanded(flex: 6, child: ColoredBox(color: _wmCream)),
                        ],
                      ),
                      Column(
                    children: [
                      // Header with title and close button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_pendingReminder != null) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _wmForestTint,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _wmParchment.withOpacity(0.8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _langCode == 'nl'
                                            ? 'Reminder klaar om te zetten'
                                            : 'Reminder ready to set',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: _wmCharcoal,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _dismissPendingReminder,
                                      child: Text(
                                        _langCode == 'nl' ? 'Nee' : 'No',
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: _confirmPendingReminder,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _wmForest,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        _langCode == 'nl'
                                            ? 'Zet reminder'
                                            : 'Set reminder',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Row(
                              children: [
                            Text(
                              AppLocalizations.of(context)!.moodyConversationTalkToMoody,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _conversationCompleted ? null : widget.onClose,
                              icon: const Icon(Icons.close),
                              color: Colors.black54,
                            ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Moody character (sky halo — v2)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _wmSky,
                            boxShadow: [
                              BoxShadow(
                                color: _wmSky.withOpacity(0.35),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: MoodyCharacter(
                            size: 120,
                            mood: _isProcessing ? 'thinking' : (_isSpeaking ? 'talking' : 'happy'),
                            currentFeature: MoodyFeature.none,
                            mouthScaleFactor: _isSpeaking ? 1.2 : 1.0,
                          ).animate(
                            onPlay: (controller) => controller.repeat(reverse: true),
                          ).scale(
                            duration: const Duration(milliseconds: 2000),
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.05, 1.05),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                      
                      // Status indicator
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          _isSpeaking 
                              ? AppLocalizations.of(context)!.moodyConversationSpeaking
                              : (_isListening 
                                  ? AppLocalizations.of(context)!.moodyConversationListening
                                  : (_isProcessing 
                                      ? AppLocalizations.of(context)!.moodyConversationThinking
                                      : "")),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: _isSpeaking
                                ? _wmForest
                                : (_isListening
                                    ? _wmForest
                                    : Colors.black54),
                          ),
                        ),
                      ),
                      
                      // Detected Moods Indicator
                      if (_detectedMoods.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Detected moods:",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: _detectedMoods.map((mood) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _wmForestTint,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _wmParchment.withOpacity(0.9)),
                                    ),
                                    child: Text(
                                      mood,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: _wmForest,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      
                      // Progress indicator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                        child: Row(
                          children: List.generate(3, (index) {
                            bool isActive = _conversationTurns > index;
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? _wmForest : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      
                      // Chat messages
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _chatMessages.length,
                            itemBuilder: (context, index) {
                              final message = _chatMessages[index];
                              return _buildChatMessage(message);
                            },
                          ),
                        ),
                      ),
                      
                      // Input area
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: _wmParchment.withOpacity(0.65)),
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildReplyComposerBanner(),
                            Row(
                          children: [
                            // Text input field
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                textInputAction: TextInputAction.send,
                                decoration: InputDecoration(
                                  hintText: _isListening
                                      ? AppLocalizations.of(context)!.moodyConversationListening
                                      : AppLocalizations.of(context)!.moodyConversationTypeMessage,
                                  hintStyle: GoogleFonts.poppins(color: Colors.black45),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(
                                      color: _wmParchment,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: _wmForest,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: _wmCharcoal,
                                ),
                                enabled: !_isListening && !_conversationCompleted,
                                onChanged: (value) {
                                  setState(() {
                                    _userInput = value;
                                  });
                                },
                                onSubmitted: (value) {
                                  final trimmed = value.trim();
                                  if (trimmed.isNotEmpty) {
                                    _handleUserInput(trimmed);
                                  }
                                },
                              ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Voice input button
                            GestureDetector(
                              onTap: _conversationCompleted ? null : _listen,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _conversationCompleted
                                      ? Colors.grey.withOpacity(0.5)
                                      : _wmForest,
                                  shape: BoxShape.circle,
                                  boxShadow: _conversationCompleted
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: _wmForest.withOpacity(0.35),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                ),
                                child: Icon(
                                  _isListening ? Icons.stop : Icons.mic,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            
                            // People button (contacts)
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                // Share conversation feature - coming soon (hidden for now)
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   SnackBar(
                                //     content: Text(
                                //       'Share conversation with friends feature coming soon',
                                //       style: GoogleFonts.poppins(),
                                //     ),
                                //     duration: const Duration(seconds: 2),
                                //   ),
                                // );
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.people,
                                  color: Colors.black54,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _openMessageActions(ChatMessage msg) {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.copy_rounded, color: _wmForest),
                    title: Text(
                      l10n.chatSheetMessageCopy,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: _wmCharcoal,
                      ),
                    ),
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: msg.copyableText),
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.chatSheetCopied),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.reply_rounded, color: _wmForest),
                    title: Text(
                      l10n.chatSheetMessageReply,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: _wmCharcoal,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      if (!mounted) return;
                      setState(() {
                        _replyDraft = _ReplyDraft(
                          quotedText: msg.text,
                          quotedIsUser: msg.isUser,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyComposerBanner() {
    final d = _replyDraft;
    if (d == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final label = d.quotedIsUser
        ? (l10n?.chatSheetReplyLabelYou ?? 'You')
        : (l10n?.chatSheetMoodyName ?? 'Moody');
    final snippet = d.quotedText.trim();
    if (snippet.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 40,
                decoration: BoxDecoration(
                  color: _wmForest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _wmForest,
                      ),
                    ),
                    Text(
                      snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.3,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: _wmCharcoal.withOpacity(0.55),
                ),
                onPressed: () => setState(() => _replyDraft = null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final isUser = message.isUser;
    final l10n = AppLocalizations.of(context);
    final moodyName = l10n?.chatSheetMoodyName ?? 'Moody';
    final youLabel = l10n?.chatSheetReplyLabelYou ?? 'You';
    final quote = message.replyToText?.trim();
    final showQuote = quote != null && quote.isNotEmpty;
    final quoteAuthor =
        message.replyToIsUser == true ? youLabel : moodyName;

    final bubbleBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showQuote) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                constraints: const BoxConstraints(minHeight: 28),
                decoration: BoxDecoration(
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.55)
                      : _wmForest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quoteAuthor,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.9)
                            : _wmForest,
                      ),
                    ),
                    Text(
                      quote,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.35,
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.88)
                            : const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Text(
          message.text,
          style: GoogleFonts.poppins(
            color: isUser ? Colors.white : _wmCharcoal,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _wmSky,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "assets/images/moody_icon.png",
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.face,
                        color: _wmForest,
                        size: 20,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _openMessageActions(message),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [_wmForest, Color(0xFF347558)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [_wmForestTint, _wmSkyTint],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: bubbleBody,
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_wmForest, Color(0xFF347558)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? replyToText;
  final bool? replyToIsUser;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.replyToText,
    this.replyToIsUser,
  });

  String get copyableText {
    final q = replyToText?.trim();
    if (q == null || q.isEmpty) return text;
    return '> $q\n\n$text';
  }
} 

class _PendingReminder {
  final DateTime fireAt;
  final String body;

  _PendingReminder({
    required this.fireAt,
    required this.body,
  });
}