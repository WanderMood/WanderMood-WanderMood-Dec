import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('nl')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'WanderMood'**
  String get appTitle;

  /// No description provided for @moodHomeHowAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get moodHomeHowAreYouFeeling;

  /// No description provided for @moodHomeCtxNewUserMorning.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start your day with the right energy.'**
  String get moodHomeCtxNewUserMorning;

  /// No description provided for @moodHomeCtxNewUserAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Time to make the most of your afternoon.'**
  String get moodHomeCtxNewUserAfternoon;

  /// No description provided for @moodHomeCtxNewUserEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening\'s here — let\'s find your perfect vibe.'**
  String get moodHomeCtxNewUserEvening;

  /// No description provided for @moodHomeCtxNewUserNight.
  ///
  /// In en, this message translates to:
  /// **'Late night energy — let\'s find something that fits.'**
  String get moodHomeCtxNewUserNight;

  /// No description provided for @moodHomeCtxReturnMorningWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend morning vibes — let\'s set the tone.'**
  String get moodHomeCtxReturnMorningWeekend;

  /// No description provided for @moodHomeCtxReturnMorningWeekday.
  ///
  /// In en, this message translates to:
  /// **'Fresh start to the day — what feels right?'**
  String get moodHomeCtxReturnMorningWeekday;

  /// No description provided for @moodHomeCtxReturnAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon\'s rolling in — time to match your energy.'**
  String get moodHomeCtxReturnAfternoon;

  /// No description provided for @moodHomeCtxReturnEveningWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend evening — let\'s find something that fits.'**
  String get moodHomeCtxReturnEveningWeekend;

  /// No description provided for @moodHomeCtxReturnEveningWeekday.
  ///
  /// In en, this message translates to:
  /// **'Workday\'s done — what\'s your evening vibe?'**
  String get moodHomeCtxReturnEveningWeekday;

  /// No description provided for @moodHomeCtxReturnNight.
  ///
  /// In en, this message translates to:
  /// **'Late night energy — let\'s see what calls to you.'**
  String get moodHomeCtxReturnNight;

  /// No description provided for @moodHomeCtxFallback.
  ///
  /// In en, this message translates to:
  /// **'Let\'s find the right vibe for today.'**
  String get moodHomeCtxFallback;

  /// No description provided for @moodHomeHeroGreetingEarlyMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Rise and shine! ☀️'**
  String get moodHomeHeroGreetingEarlyMorningTitle;

  /// No description provided for @moodHomeHeroGreetingEarlyMorningSubWeekend.
  ///
  /// In en, this message translates to:
  /// **'Perfect weekend morning for adventures'**
  String get moodHomeHeroGreetingEarlyMorningSubWeekend;

  /// No description provided for @moodHomeHeroGreetingEarlyMorningSubWeekday.
  ///
  /// In en, this message translates to:
  /// **'Ready to make today amazing?'**
  String get moodHomeHeroGreetingEarlyMorningSubWeekday;

  /// No description provided for @moodHomeHeroGreetingLateMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Hey there! 👋'**
  String get moodHomeHeroGreetingLateMorningTitle;

  /// No description provided for @moodHomeHeroGreetingLateMorningSub.
  ///
  /// In en, this message translates to:
  /// **'I\'ve been thinking about your perfect day'**
  String get moodHomeHeroGreetingLateMorningSub;

  /// No description provided for @moodHomeHeroGreetingAfternoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Afternoon vibes! ✨'**
  String get moodHomeHeroGreetingAfternoonTitle;

  /// No description provided for @moodHomeHeroGreetingAfternoonSub.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind for today?'**
  String get moodHomeHeroGreetingAfternoonSub;

  /// No description provided for @moodHomeHeroGreetingEarlyEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening explorer! 🌆'**
  String get moodHomeHeroGreetingEarlyEveningTitle;

  /// No description provided for @moodHomeHeroGreetingEarlyEveningSubWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend nights are the best for discoveries'**
  String get moodHomeHeroGreetingEarlyEveningSubWeekend;

  /// No description provided for @moodHomeHeroGreetingEarlyEveningSubWeekday.
  ///
  /// In en, this message translates to:
  /// **'How did your day treat you?'**
  String get moodHomeHeroGreetingEarlyEveningSubWeekday;

  /// No description provided for @moodHomeHeroGreetingNightTitle.
  ///
  /// In en, this message translates to:
  /// **'Night owl! 🌙'**
  String get moodHomeHeroGreetingNightTitle;

  /// No description provided for @moodHomeHeroGreetingNightSub.
  ///
  /// In en, this message translates to:
  /// **'Late night adventures calling?'**
  String get moodHomeHeroGreetingNightSub;

  /// No description provided for @moodHomeEmptyChatPitch.
  ///
  /// In en, this message translates to:
  /// **'I know {city} like the back of my hand! Tell me your mood, and I\'ll craft the perfect day just for you. Whether you\'re feeling adventurous, romantic, or need some chill vibes — I\'ve got you covered! 🎯'**
  String moodHomeEmptyChatPitch(String city);

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your mood-based travel companion'**
  String get splashTagline;

  /// No description provided for @splashPlanYourDayByFeeling.
  ///
  /// In en, this message translates to:
  /// **'Plan your day by how you feel'**
  String get splashPlanYourDayByFeeling;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @heyNightOwl.
  ///
  /// In en, this message translates to:
  /// **'Hey night owl'**
  String get heyNightOwl;

  /// No description provided for @readyToCreateYourFirstDay.
  ///
  /// In en, this message translates to:
  /// **'Ready to create your first amazing day?'**
  String get readyToCreateYourFirstDay;

  /// No description provided for @createMyFirstDay.
  ///
  /// In en, this message translates to:
  /// **'Create my first day'**
  String get createMyFirstDay;

  /// No description provided for @myDayHeaderMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning! Let\'s make today amazing.'**
  String get myDayHeaderMorning;

  /// No description provided for @myDayHeaderAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon! Your day is looking great.'**
  String get myDayHeaderAfternoon;

  /// No description provided for @myDayHeaderEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening! Let\'s see what the rest of today can become.'**
  String get myDayHeaderEvening;

  /// No description provided for @myDayNoPlanHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No plans yet. Your day is still open.'**
  String get myDayNoPlanHeaderSubtitle;

  /// No description provided for @myDayEmptyGreetingMorningBody.
  ///
  /// In en, this message translates to:
  /// **'A fresh day full of possibilities awaits.'**
  String get myDayEmptyGreetingMorningBody;

  /// No description provided for @myDayEmptyGreetingAfternoonBody.
  ///
  /// In en, this message translates to:
  /// **'There is still time to turn today into something memorable.'**
  String get myDayEmptyGreetingAfternoonBody;

  /// No description provided for @myDayEmptyGreetingEveningBody.
  ///
  /// In en, this message translates to:
  /// **'The night is still open. Plan something special or ease into it slowly.'**
  String get myDayEmptyGreetingEveningBody;

  /// No description provided for @myDayEmptyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to plan your day?'**
  String get myDayEmptyPlanTitle;

  /// No description provided for @myDayEmptyPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a day plan and start exploring places that match your mood, timing, and energy.'**
  String get myDayEmptyPlanSubtitle;

  /// No description provided for @myDayEmptyCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create My Day'**
  String get myDayEmptyCreateButton;

  /// No description provided for @myDayEmptyBrowseButton.
  ///
  /// In en, this message translates to:
  /// **'Browse Activities'**
  String get myDayEmptyBrowseButton;

  /// No description provided for @myDayEmptyAskMoodyButton.
  ///
  /// In en, this message translates to:
  /// **'Ask Moody'**
  String get myDayEmptyAskMoodyButton;

  /// No description provided for @myDayQuickAddActivity.
  ///
  /// In en, this message translates to:
  /// **'Add activity'**
  String get myDayQuickAddActivity;

  /// No description provided for @moodyFeedbackPromptBody.
  ///
  /// In en, this message translates to:
  /// **'How\'s it going? Tap to tell me about your experience!'**
  String get moodyFeedbackPromptBody;

  /// No description provided for @moodyFeedbackShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share feedback'**
  String get moodyFeedbackShareAction;

  /// No description provided for @myDayEmptyInspiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Get inspired'**
  String get myDayEmptyInspiredTitle;

  /// No description provided for @myDayInspiredCafesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover cafes'**
  String get myDayInspiredCafesTitle;

  /// No description provided for @myDayInspiredCafesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find cozy spots to relax'**
  String get myDayInspiredCafesSubtitle;

  /// No description provided for @myDayInspiredTrendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Trending places'**
  String get myDayInspiredTrendingTitle;

  /// No description provided for @myDayInspiredTrendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Popular spots this week'**
  String get myDayInspiredTrendingSubtitle;

  /// No description provided for @myDayInspiredHiddenGemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden gems'**
  String get myDayInspiredHiddenGemsTitle;

  /// No description provided for @myDayInspiredHiddenGemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local favorites nearby'**
  String get myDayInspiredHiddenGemsSubtitle;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @moodyIntroGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hey {name}! 👋'**
  String moodyIntroGreeting(String name);

  /// No description provided for @moodyIntroImMoody.
  ///
  /// In en, this message translates to:
  /// **'I\'m Moody.'**
  String get moodyIntroImMoody;

  /// No description provided for @moodyIntroSubtext.
  ///
  /// In en, this message translates to:
  /// **'I\'m here to help you plan days that match your mood, energy, and vibe.'**
  String get moodyIntroSubtext;

  /// No description provided for @moodyIntroSuggestActivities.
  ///
  /// In en, this message translates to:
  /// **'I\'ll suggest activities like:'**
  String get moodyIntroSuggestActivities;

  /// No description provided for @moodyIntroTakesLessThan.
  ///
  /// In en, this message translates to:
  /// **'Takes less than a minute • Uses your preferences'**
  String get moodyIntroTakesLessThan;

  /// No description provided for @moodyIntroNameFallback.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get moodyIntroNameFallback;

  /// No description provided for @moodyIntroActLocalRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Local restaurant discovery'**
  String get moodyIntroActLocalRestaurant;

  /// No description provided for @moodyIntroActMuseum.
  ///
  /// In en, this message translates to:
  /// **'Museum or gallery visit'**
  String get moodyIntroActMuseum;

  /// No description provided for @moodyIntroActLocalMarket.
  ///
  /// In en, this message translates to:
  /// **'Local market exploration'**
  String get moodyIntroActLocalMarket;

  /// No description provided for @moodyIntroActNature.
  ///
  /// In en, this message translates to:
  /// **'Nature walk or park visit'**
  String get moodyIntroActNature;

  /// No description provided for @moodyIntroActNightlife.
  ///
  /// In en, this message translates to:
  /// **'Evening bar or lounge'**
  String get moodyIntroActNightlife;

  /// No description provided for @moodyIntroActSpa.
  ///
  /// In en, this message translates to:
  /// **'Spa or wellness experience'**
  String get moodyIntroActSpa;

  /// No description provided for @moodyIntroActCoffee.
  ///
  /// In en, this message translates to:
  /// **'Morning coffee spot'**
  String get moodyIntroActCoffee;

  /// No description provided for @moodyIntroActAdventure.
  ///
  /// In en, this message translates to:
  /// **'Active outdoor adventure'**
  String get moodyIntroActAdventure;

  /// No description provided for @moodyIntroActPeacefulWalk.
  ///
  /// In en, this message translates to:
  /// **'Peaceful evening walk'**
  String get moodyIntroActPeacefulWalk;

  /// No description provided for @moodyIntroActHistorical.
  ///
  /// In en, this message translates to:
  /// **'Historical site visit'**
  String get moodyIntroActHistorical;

  /// No description provided for @moodyIntroActRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic dining experience'**
  String get moodyIntroActRomantic;

  /// No description provided for @moodyIntroActSocial.
  ///
  /// In en, this message translates to:
  /// **'Social gathering spot'**
  String get moodyIntroActSocial;

  /// No description provided for @moodyIntroActScenic.
  ///
  /// In en, this message translates to:
  /// **'Scenic viewpoint'**
  String get moodyIntroActScenic;

  /// No description provided for @moodyIntroActEarlyMorning.
  ///
  /// In en, this message translates to:
  /// **'Early morning experience'**
  String get moodyIntroActEarlyMorning;

  /// No description provided for @moodyIntroActEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening entertainment'**
  String get moodyIntroActEvening;

  /// No description provided for @moodyIntroActAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon activity'**
  String get moodyIntroActAfternoon;

  /// No description provided for @moodyIntroActSurprise.
  ///
  /// In en, this message translates to:
  /// **'Surprise discovery'**
  String get moodyIntroActSurprise;

  /// No description provided for @moodyIntroActMarketVisit.
  ///
  /// In en, this message translates to:
  /// **'Local market visit'**
  String get moodyIntroActMarketVisit;

  /// No description provided for @moodyIntroActEveningWalk.
  ///
  /// In en, this message translates to:
  /// **'Evening walk with a view'**
  String get moodyIntroActEveningWalk;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @allowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get allowNotifications;

  /// No description provided for @masterControlForAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Master control for all notifications'**
  String get masterControlForAllNotifications;

  /// No description provided for @activityNotifications.
  ///
  /// In en, this message translates to:
  /// **'Activity Notifications'**
  String get activityNotifications;

  /// No description provided for @activityReminders.
  ///
  /// In en, this message translates to:
  /// **'Activity Reminders'**
  String get activityReminders;

  /// No description provided for @remindersForUpcomingActivities.
  ///
  /// In en, this message translates to:
  /// **'Reminders for upcoming activities and plans'**
  String get remindersForUpcomingActivities;

  /// No description provided for @moodTracking.
  ///
  /// In en, this message translates to:
  /// **'Mood Tracking'**
  String get moodTracking;

  /// No description provided for @dailyPromptsToTrackYourMood.
  ///
  /// In en, this message translates to:
  /// **'Daily prompts to track your mood'**
  String get dailyPromptsToTrackYourMood;

  /// No description provided for @travelAndWeather.
  ///
  /// In en, this message translates to:
  /// **'Travel & Weather'**
  String get travelAndWeather;

  /// No description provided for @weatherAlerts.
  ///
  /// In en, this message translates to:
  /// **'Weather Alerts'**
  String get weatherAlerts;

  /// No description provided for @getAlertsAboutWeatherChanges.
  ///
  /// In en, this message translates to:
  /// **'Get alerts about weather changes'**
  String get getAlertsAboutWeatherChanges;

  /// No description provided for @travelTips.
  ///
  /// In en, this message translates to:
  /// **'Travel Tips'**
  String get travelTips;

  /// No description provided for @suggestionsForYourTrips.
  ///
  /// In en, this message translates to:
  /// **'Suggestions for your trips and activities'**
  String get suggestionsForYourTrips;

  /// No description provided for @localEvents.
  ///
  /// In en, this message translates to:
  /// **'Local Events'**
  String get localEvents;

  /// No description provided for @notificationsAboutEventsInYourArea.
  ///
  /// In en, this message translates to:
  /// **'Notifications about events in your area'**
  String get notificationsAboutEventsInYourArea;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @friendActivity.
  ///
  /// In en, this message translates to:
  /// **'Friend Activity'**
  String get friendActivity;

  /// No description provided for @whenFriendsShareTrips.
  ///
  /// In en, this message translates to:
  /// **'When friends share trips or activities'**
  String get whenFriendsShareTrips;

  /// No description provided for @specialOffers.
  ///
  /// In en, this message translates to:
  /// **'Special Offers'**
  String get specialOffers;

  /// No description provided for @promotionalOffersAndAppUpdates.
  ///
  /// In en, this message translates to:
  /// **'Promotional offers and app updates'**
  String get promotionalOffersAndAppUpdates;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @chooseYourPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language for the app interface. This will affect all text and content throughout the app.'**
  String get chooseYourPreferredLanguage;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @publicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get publicProfile;

  /// No description provided for @allowOthersToViewYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Allow others to view your profile'**
  String get allowOthersToViewYourProfile;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receivePushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications'**
  String get receivePushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @receiveEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive email notifications'**
  String get receiveEmailNotifications;

  /// No description provided for @manageYourPrivacySettings.
  ///
  /// In en, this message translates to:
  /// **'Manage your privacy settings and notification preferences. These settings control who can see your profile and how you receive updates.'**
  String get manageYourPrivacySettings;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// No description provided for @chooseYourPreferredTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred theme for the app. You can follow your system settings or choose a specific theme.'**
  String get chooseYourPreferredTheme;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @followSystemTheme.
  ///
  /// In en, this message translates to:
  /// **'Follow system theme'**
  String get followSystemTheme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @changeYourMood.
  ///
  /// In en, this message translates to:
  /// **'Change your mood?'**
  String get changeYourMood;

  /// No description provided for @doYouWantToContinueToChangeMood.
  ///
  /// In en, this message translates to:
  /// **'Do you want to continue to change mood? This will take you to the mood selection screen.'**
  String get doYouWantToContinueToChangeMood;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get disabled;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get updated;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get failedToUpdate;

  /// No description provided for @languageUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Language updated to {language}'**
  String languageUpdatedTo(String language);

  /// No description provided for @themeUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Theme updated to {theme}'**
  String themeUpdatedTo(String theme);

  /// No description provided for @profileVisibilityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile visibility updated'**
  String get profileVisibilityUpdated;

  /// No description provided for @pushNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Push notifications enabled'**
  String get pushNotificationsEnabled;

  /// No description provided for @pushNotificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Push notifications disabled'**
  String get pushNotificationsDisabled;

  /// No description provided for @emailNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Email notifications enabled'**
  String get emailNotificationsEnabled;

  /// No description provided for @emailNotificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Email notifications disabled'**
  String get emailNotificationsDisabled;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privateProfile.
  ///
  /// In en, this message translates to:
  /// **'Private Profile'**
  String get privateProfile;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Setting up your\nperfect day!'**
  String get loadingTitle;

  /// No description provided for @loadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re preparing personalized activities,\nplaces, and insights just for you!'**
  String get loadingSubtitle;

  /// No description provided for @loadingStep0.
  ///
  /// In en, this message translates to:
  /// **'Preparing your personalized experience...'**
  String get loadingStep0;

  /// No description provided for @loadingStep1.
  ///
  /// In en, this message translates to:
  /// **'Loading your preferences...'**
  String get loadingStep1;

  /// No description provided for @loadingStep2.
  ///
  /// In en, this message translates to:
  /// **'Finding activities you\'ll love...'**
  String get loadingStep2;

  /// No description provided for @loadingStep3.
  ///
  /// In en, this message translates to:
  /// **'Curating perfect activities for you...'**
  String get loadingStep3;

  /// No description provided for @loadingStep4.
  ///
  /// In en, this message translates to:
  /// **'Almost ready! Setting up your dashboard...'**
  String get loadingStep4;

  /// No description provided for @loadingStep5.
  ///
  /// In en, this message translates to:
  /// **'Preparing your personalized dashboard...'**
  String get loadingStep5;

  /// No description provided for @loadingStep6.
  ///
  /// In en, this message translates to:
  /// **'Ready to explore! (Some data will load as you go)'**
  String get loadingStep6;

  /// No description provided for @loadingFact0.
  ///
  /// In en, this message translates to:
  /// **'Did you know? There are 195 countries in the world, each with unique cultures and traditions!'**
  String get loadingFact0;

  /// No description provided for @loadingFact1.
  ///
  /// In en, this message translates to:
  /// **'The world\'s busiest airport serves over 100 million passengers annually!'**
  String get loadingFact1;

  /// No description provided for @loadingFact2.
  ///
  /// In en, this message translates to:
  /// **'There are over 1,500 UNESCO World Heritage Sites across the globe!'**
  String get loadingFact2;

  /// No description provided for @loadingFact3.
  ///
  /// In en, this message translates to:
  /// **'The Great Wall of China is visible from space and stretches over 13,000 miles!'**
  String get loadingFact3;

  /// No description provided for @loadingFact4.
  ///
  /// In en, this message translates to:
  /// **'There are more than 6,900 languages spoken around the world!'**
  String get loadingFact4;

  /// No description provided for @loadingFact5.
  ///
  /// In en, this message translates to:
  /// **'The Amazon rainforest produces 20% of the world\'s oxygen!'**
  String get loadingFact5;

  /// No description provided for @loadingFact6.
  ///
  /// In en, this message translates to:
  /// **'Mount Everest grows about 4mm taller each year due to geological forces!'**
  String get loadingFact6;

  /// No description provided for @loadingFact7.
  ///
  /// In en, this message translates to:
  /// **'The Sahara Desert is larger than the entire United States!'**
  String get loadingFact7;

  /// No description provided for @weatherCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get weatherCurrentLocation;

  /// No description provided for @loadingFactNl0.
  ///
  /// In en, this message translates to:
  /// **'The Netherlands has more museums per square mile than any other country!'**
  String get loadingFactNl0;

  /// No description provided for @loadingFactNl1.
  ///
  /// In en, this message translates to:
  /// **'Rotterdam is home to Europe\'s largest port, handling over 400 million tons of cargo annually!'**
  String get loadingFactNl1;

  /// No description provided for @loadingFactNl2.
  ///
  /// In en, this message translates to:
  /// **'The Netherlands has over 35,000 kilometers of bike paths - enough to circle the Earth!'**
  String get loadingFactNl2;

  /// No description provided for @loadingFactNl3.
  ///
  /// In en, this message translates to:
  /// **'Amsterdam has more canals than Venice and more bridges than Paris!'**
  String get loadingFactNl3;

  /// No description provided for @loadingFactNl4.
  ///
  /// In en, this message translates to:
  /// **'The Dutch consume over 150 million stroopwafels every year!'**
  String get loadingFactNl4;

  /// No description provided for @loadingFactNl5.
  ///
  /// In en, this message translates to:
  /// **'The Netherlands is the world\'s second-largest exporter of food despite its small size!'**
  String get loadingFactNl5;

  /// No description provided for @loadingFactNl6.
  ///
  /// In en, this message translates to:
  /// **'Keukenhof Gardens displays over 7 million flower bulbs across 32 hectares!'**
  String get loadingFactNl6;

  /// No description provided for @loadingFactNl7.
  ///
  /// In en, this message translates to:
  /// **'The Dutch are the tallest people in the world with an average height of 6 feet!'**
  String get loadingFactNl7;

  /// No description provided for @loadingFactUs0.
  ///
  /// In en, this message translates to:
  /// **'The US has 63 national parks, from Yellowstone to the Grand Canyon!'**
  String get loadingFactUs0;

  /// No description provided for @loadingFactUs1.
  ///
  /// In en, this message translates to:
  /// **'Alaska has more than 3 million lakes and over 100,000 glaciers!'**
  String get loadingFactUs1;

  /// No description provided for @loadingFactUs2.
  ///
  /// In en, this message translates to:
  /// **'The US Interstate Highway System spans over 47,000 miles!'**
  String get loadingFactUs2;

  /// No description provided for @loadingFactUs3.
  ///
  /// In en, this message translates to:
  /// **'Times Square in NYC is visited by over 50 million people annually!'**
  String get loadingFactUs3;

  /// No description provided for @loadingFactUs4.
  ///
  /// In en, this message translates to:
  /// **'The US has the world\'s largest economy and is home to Silicon Valley!'**
  String get loadingFactUs4;

  /// No description provided for @loadingFactUs5.
  ///
  /// In en, this message translates to:
  /// **'Hawaii is the only US state that commercially grows coffee!'**
  String get loadingFactUs5;

  /// No description provided for @loadingFactUs6.
  ///
  /// In en, this message translates to:
  /// **'The Golden Gate Bridge in San Francisco is painted International Orange!'**
  String get loadingFactUs6;

  /// No description provided for @loadingFactUs7.
  ///
  /// In en, this message translates to:
  /// **'Disney World in Florida is larger than the city of San Francisco!'**
  String get loadingFactUs7;

  /// No description provided for @loadingFactJp0.
  ///
  /// In en, this message translates to:
  /// **'Japan has over 6,800 islands, but only 430 are inhabited!'**
  String get loadingFactJp0;

  /// No description provided for @loadingFactJp1.
  ///
  /// In en, this message translates to:
  /// **'The Japanese Shinkansen bullet trains can reach speeds of 200 mph!'**
  String get loadingFactJp1;

  /// No description provided for @loadingFactJp2.
  ///
  /// In en, this message translates to:
  /// **'Mount Fuji is actually an active volcano that last erupted in 1707!'**
  String get loadingFactJp2;

  /// No description provided for @loadingFactJp3.
  ///
  /// In en, this message translates to:
  /// **'Japan has more than 100,000 temples and shrines!'**
  String get loadingFactJp3;

  /// No description provided for @loadingFactJp4.
  ///
  /// In en, this message translates to:
  /// **'Tokyo is the world\'s largest metropolitan area with over 37 million people!'**
  String get loadingFactJp4;

  /// No description provided for @loadingFactJp5.
  ///
  /// In en, this message translates to:
  /// **'Japan consumes about 80% of the world\'s bluefin tuna!'**
  String get loadingFactJp5;

  /// No description provided for @loadingFactJp6.
  ///
  /// In en, this message translates to:
  /// **'The Japanese love vending machines - there\'s one for every 23 people!'**
  String get loadingFactJp6;

  /// No description provided for @loadingFactJp7.
  ///
  /// In en, this message translates to:
  /// **'Cherry blossom season in Japan attracts millions of visitors each spring!'**
  String get loadingFactJp7;

  /// No description provided for @loadingFactUk0.
  ///
  /// In en, this message translates to:
  /// **'The UK has over 1,500 castles, from medieval fortresses to royal residences!'**
  String get loadingFactUk0;

  /// No description provided for @loadingFactUk1.
  ///
  /// In en, this message translates to:
  /// **'London\'s Big Ben is not actually the name of the clock tower - it\'s Elizabeth Tower!'**
  String get loadingFactUk1;

  /// No description provided for @loadingFactUk2.
  ///
  /// In en, this message translates to:
  /// **'The UK has produced more world-famous musicians per capita than any other country!'**
  String get loadingFactUk2;

  /// No description provided for @loadingFactUk3.
  ///
  /// In en, this message translates to:
  /// **'Stonehenge is over 5,000 years old and still shrouded in mystery!'**
  String get loadingFactUk3;

  /// No description provided for @loadingFactUk4.
  ///
  /// In en, this message translates to:
  /// **'The London Underground is the world\'s oldest subway system, opened in 1863!'**
  String get loadingFactUk4;

  /// No description provided for @loadingFactUk5.
  ///
  /// In en, this message translates to:
  /// **'The UK has 15 UNESCO World Heritage Sites including Bath and Edinburgh!'**
  String get loadingFactUk5;

  /// No description provided for @loadingFactUk6.
  ///
  /// In en, this message translates to:
  /// **'Scotland has over 3,000 castles and about 790 islands!'**
  String get loadingFactUk6;

  /// No description provided for @loadingFactUk7.
  ///
  /// In en, this message translates to:
  /// **'The British drink about 100 million cups of tea every day!'**
  String get loadingFactUk7;

  /// No description provided for @loadingFactDe0.
  ///
  /// In en, this message translates to:
  /// **'Germany has over 25,000 castles and palaces scattered across the country!'**
  String get loadingFactDe0;

  /// No description provided for @loadingFactDe1.
  ///
  /// In en, this message translates to:
  /// **'The Berlin Wall was 96 miles long and stood for 28 years!'**
  String get loadingFactDe1;

  /// No description provided for @loadingFactDe2.
  ///
  /// In en, this message translates to:
  /// **'Germany is famous for Oktoberfest, which actually starts in September!'**
  String get loadingFactDe2;

  /// No description provided for @loadingFactDe3.
  ///
  /// In en, this message translates to:
  /// **'The Black Forest region inspired many Brothers Grimm fairy tales!'**
  String get loadingFactDe3;

  /// No description provided for @loadingFactDe4.
  ///
  /// In en, this message translates to:
  /// **'Germany has no general speed limit on about 60% of its Autobahn highways!'**
  String get loadingFactDe4;

  /// No description provided for @loadingFactDe5.
  ///
  /// In en, this message translates to:
  /// **'Neuschwanstein Castle was the inspiration for Disney\'s Sleeping Beauty castle!'**
  String get loadingFactDe5;

  /// No description provided for @loadingFactDe6.
  ///
  /// In en, this message translates to:
  /// **'Germany has the largest economy in Europe and is known for engineering!'**
  String get loadingFactDe6;

  /// No description provided for @loadingFactDe7.
  ///
  /// In en, this message translates to:
  /// **'The Rhine River flows through Germany and is lined with medieval castles!'**
  String get loadingFactDe7;

  /// No description provided for @loadingFactFr0.
  ///
  /// In en, this message translates to:
  /// **'France is the world\'s most visited country with over 89 million tourists annually!'**
  String get loadingFactFr0;

  /// No description provided for @loadingFactFr1.
  ///
  /// In en, this message translates to:
  /// **'The Eiffel Tower was originally built as a temporary structure for the 1889 World\'s Fair!'**
  String get loadingFactFr1;

  /// No description provided for @loadingFactFr2.
  ///
  /// In en, this message translates to:
  /// **'France produces over 400 types of cheese - one for every day of the year!'**
  String get loadingFactFr2;

  /// No description provided for @loadingFactFr3.
  ///
  /// In en, this message translates to:
  /// **'The Palace of Versailles has 2,300 rooms and 67 staircases!'**
  String get loadingFactFr3;

  /// No description provided for @loadingFactFr4.
  ///
  /// In en, this message translates to:
  /// **'France has 44 UNESCO World Heritage Sites, including Mont-Saint-Michel!'**
  String get loadingFactFr4;

  /// No description provided for @loadingFactFr5.
  ///
  /// In en, this message translates to:
  /// **'The Louvre Museum is the world\'s largest art museum!'**
  String get loadingFactFr5;

  /// No description provided for @loadingFactFr6.
  ///
  /// In en, this message translates to:
  /// **'The French Riviera stretches for 550 miles along the Mediterranean!'**
  String get loadingFactFr6;

  /// No description provided for @loadingFactFr7.
  ///
  /// In en, this message translates to:
  /// **'France is home to the world\'s most famous bicycle race - the Tour de France!'**
  String get loadingFactFr7;

  /// No description provided for @guestPlaceDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String guestPlaceDistanceKm(String km);

  /// No description provided for @guestPlaceHoursRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String guestPlaceHoursRange(String start, String end);

  /// No description provided for @prefSocialVibeTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'What\'s your social vibe? 👥'**
  String get prefSocialVibeTitleFallback;

  /// No description provided for @prefSocialVibeSubtitleFallback.
  ///
  /// In en, this message translates to:
  /// **'How do you like to experience things?'**
  String get prefSocialVibeSubtitleFallback;

  /// No description provided for @prefPlanningPaceTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Tell me your pace ⏰'**
  String get prefPlanningPaceTitleFallback;

  /// No description provided for @prefPlanningPaceSubtitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Your planning style'**
  String get prefPlanningPaceSubtitleFallback;

  /// No description provided for @prefTravelStyleTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Last but not least! ✨'**
  String get prefTravelStyleTitleFallback;

  /// No description provided for @prefTravelStyleSubtitleFallback.
  ///
  /// In en, this message translates to:
  /// **'What\'s your travel style?'**
  String get prefTravelStyleSubtitleFallback;

  /// No description provided for @prefStartMyJourney.
  ///
  /// In en, this message translates to:
  /// **'Start My Journey'**
  String get prefStartMyJourney;

  /// No description provided for @onboardingPagerSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Meet Moody 😄'**
  String get onboardingPagerSlide1Title;

  /// No description provided for @onboardingPagerSlide1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your travel BFF 💬🌍'**
  String get onboardingPagerSlide1Subtitle;

  /// No description provided for @onboardingPagerSlide1Description.
  ///
  /// In en, this message translates to:
  /// **'Moody gets to know your vibe, your energy, and the kind of day you\'re having. With all that, I create personalized plans — made just for you. Think of me as your fun, curious bestie who\'s always down to explore 🌆🎈'**
  String get onboardingPagerSlide1Description;

  /// No description provided for @onboardingPagerSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Travel by Mood 🌈'**
  String get onboardingPagerSlide2Title;

  /// No description provided for @onboardingPagerSlide2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Feelings, Your Journey 💭'**
  String get onboardingPagerSlide2Subtitle;

  /// No description provided for @onboardingPagerSlide2Description.
  ///
  /// In en, this message translates to:
  /// **'Whether you\'re in a peaceful, romantic, or adventurous mood... just tell me how you feel, and I\'ll create personalized plans 🌸🏞️\nFrom hidden gems to sunset strolls—mood first, always.'**
  String get onboardingPagerSlide2Description;

  /// No description provided for @onboardingPagerSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Your Day, Your Way 🫶🏾'**
  String get onboardingPagerSlide3Title;

  /// No description provided for @onboardingPagerSlide3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sunrise to sunset, I\'ve got you ☀️🌙'**
  String get onboardingPagerSlide3Subtitle;

  /// No description provided for @onboardingPagerSlide3Description.
  ///
  /// In en, this message translates to:
  /// **'Your plan is broken into moments—morning, afternoon, evening, and night. Choose your vibe, pick your favorites, and I\'ll handle the magic. 🧭🎯 All based on location, time, weather & mood.'**
  String get onboardingPagerSlide3Description;

  /// No description provided for @onboardingPagerSlide4Title.
  ///
  /// In en, this message translates to:
  /// **'Every Day\'s a Mood 🎨'**
  String get onboardingPagerSlide4Title;

  /// No description provided for @onboardingPagerSlide4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover new places - every day🌍'**
  String get onboardingPagerSlide4Subtitle;

  /// No description provided for @onboardingPagerSlide4Description.
  ///
  /// In en, this message translates to:
  /// **'WanderMood makes every day feel like a new adventure. Wake up, check your vibe, explore hand-picked activities 💡📍 Let your mood lead the way—again and again.'**
  String get onboardingPagerSlide4Description;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @pushEmailInApp.
  ///
  /// In en, this message translates to:
  /// **'Push, email, and in-app'**
  String get pushEmailInApp;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @autoDetectPermissions.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect and permissions'**
  String get autoDetectPermissions;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'unlocked'**
  String get unlocked;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @dataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get dataStorage;

  /// No description provided for @exportClearCache.
  ///
  /// In en, this message translates to:
  /// **'Export data and clear cache'**
  String get exportClearCache;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @faqContactUs.
  ///
  /// In en, this message translates to:
  /// **'FAQ and contact us'**
  String get faqContactUs;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @permanentlyDeleteYourData.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your data'**
  String get permanentlyDeleteYourData;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @logOutOfYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Log out of your account'**
  String get logOutOfYourAccount;

  /// Subtitle on the intro screen under the headline; reassures users onboarding is quick.
  ///
  /// In en, this message translates to:
  /// **'This takes only 10 seconds, I promise.'**
  String get introTagline;

  /// No description provided for @introTitleLine1.
  ///
  /// In en, this message translates to:
  /// **'Your Mood,'**
  String get introTitleLine1;

  /// No description provided for @introTitleLine2.
  ///
  /// In en, this message translates to:
  /// **'Your Adventure'**
  String get introTitleLine2;

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introSkip;

  /// No description provided for @introSeeHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'Take a look, this is fun!'**
  String get introSeeHowItWorks;

  /// No description provided for @demoMoodyGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hey… I\'m Moody 🙂'**
  String get demoMoodyGreeting;

  /// No description provided for @demoMoodyAskVibe.
  ///
  /// In en, this message translates to:
  /// **'I help you discover amazing places based on how you\'re feeling. What\'s your mood today?'**
  String get demoMoodyAskVibe;

  /// No description provided for @demoUserFeeling.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling {mood}'**
  String demoUserFeeling(String mood);

  /// No description provided for @demoMoodyResponseAdventurous.
  ///
  /// In en, this message translates to:
  /// **'Time for adventure! I know exactly what you need 🔥'**
  String get demoMoodyResponseAdventurous;

  /// No description provided for @demoMoodyResponseRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Taking it easy today? Great plan! 🌿'**
  String get demoMoodyResponseRelaxed;

  /// No description provided for @demoMoodyResponseRomantic.
  ///
  /// In en, this message translates to:
  /// **'A romantic day? I\'ve got you.'**
  String get demoMoodyResponseRomantic;

  /// No description provided for @demoMoodyResponseCultural.
  ///
  /// In en, this message translates to:
  /// **'The city\'s culture scene is waiting for you 🎭'**
  String get demoMoodyResponseCultural;

  /// No description provided for @demoMoodyResponseFoodie.
  ///
  /// In en, this message translates to:
  /// **'I know the best spots in the city 🍽'**
  String get demoMoodyResponseFoodie;

  /// No description provided for @demoMoodyResponseSocial.
  ///
  /// In en, this message translates to:
  /// **'Looking for fun? I\'ve got you! 👥'**
  String get demoMoodyResponseSocial;

  /// No description provided for @demoMoodyResponseDefault.
  ///
  /// In en, this message translates to:
  /// **'Nice! Let\'s go explore ✨'**
  String get demoMoodyResponseDefault;

  /// No description provided for @demoMoodAdventurous.
  ///
  /// In en, this message translates to:
  /// **'Adventurous'**
  String get demoMoodAdventurous;

  /// No description provided for @demoMoodRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get demoMoodRelaxed;

  /// No description provided for @demoMoodRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get demoMoodRomantic;

  /// No description provided for @demoMoodCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get demoMoodCultural;

  /// No description provided for @demoMoodFoodie.
  ///
  /// In en, this message translates to:
  /// **'Foodie'**
  String get demoMoodFoodie;

  /// No description provided for @demoMoodSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get demoMoodSocial;

  /// No description provided for @demoExploreMore.
  ///
  /// In en, this message translates to:
  /// **'Explore More'**
  String get demoExploreMore;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get demoMode;

  /// No description provided for @demoMoodyName.
  ///
  /// In en, this message translates to:
  /// **'Moody'**
  String get demoMoodyName;

  /// No description provided for @demoTapToSelectMood.
  ///
  /// In en, this message translates to:
  /// **'Tap to select your mood:'**
  String get demoTapToSelectMood;

  /// No description provided for @demoReadyToSignUp.
  ///
  /// In en, this message translates to:
  /// **'Ready to sign up? Start now →'**
  String get demoReadyToSignUp;

  /// No description provided for @guestExplorePlaces.
  ///
  /// In en, this message translates to:
  /// **'Explore Places'**
  String get guestExplorePlaces;

  /// No description provided for @guestPreviewMode.
  ///
  /// In en, this message translates to:
  /// **'Preview mode • Limited features'**
  String get guestPreviewMode;

  /// No description provided for @guestGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestGuest;

  /// No description provided for @guestSignUpFree.
  ///
  /// In en, this message translates to:
  /// **'Sign Up Free'**
  String get guestSignUpFree;

  /// No description provided for @guestLovingWhatYouSee.
  ///
  /// In en, this message translates to:
  /// **'Loving what you see?'**
  String get guestLovingWhatYouSee;

  /// No description provided for @guestSignUpSaveFavorites.
  ///
  /// In en, this message translates to:
  /// **'Sign up to save favorites & create plans'**
  String get guestSignUpSaveFavorites;

  /// No description provided for @guestSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get guestSignUp;

  /// No description provided for @guestSignUpToSaveFavorites.
  ///
  /// In en, this message translates to:
  /// **'Sign up to save your favorites!'**
  String get guestSignUpToSaveFavorites;

  /// No description provided for @guestNoPlacesMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No places match these filters'**
  String get guestNoPlacesMatchFilters;

  /// No description provided for @guestTryDifferentCategory.
  ///
  /// In en, this message translates to:
  /// **'Try a different category'**
  String get guestTryDifferentCategory;

  /// No description provided for @guestMoodySays.
  ///
  /// In en, this message translates to:
  /// **'Moody says...'**
  String get guestMoodySays;

  /// No description provided for @guestGreatChoice.
  ///
  /// In en, this message translates to:
  /// **'Great choice for your mood today!'**
  String get guestGreatChoice;

  /// No description provided for @guestSignUpToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Sign up to unlock'**
  String get guestSignUpToUnlock;

  /// No description provided for @guestSignUpUnlockDescription.
  ///
  /// In en, this message translates to:
  /// **'Save favorites, create plans, and get personalized recommendations'**
  String get guestSignUpUnlockDescription;

  /// No description provided for @guestSignUpFreeSparkle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up Free ✨'**
  String get guestSignUpFreeSparkle;

  /// No description provided for @guestExploringLikePro.
  ///
  /// In en, this message translates to:
  /// **'You\'re exploring like a pro!'**
  String get guestExploringLikePro;

  /// No description provided for @guestReadyToSaveFavorites.
  ///
  /// In en, this message translates to:
  /// **'Ready to save your favorites and create personalized day plans?'**
  String get guestReadyToSaveFavorites;

  /// No description provided for @guestMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get guestMaybeLater;

  /// No description provided for @guestFilterHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get guestFilterHalal;

  /// No description provided for @guestFilterBlackOwned.
  ///
  /// In en, this message translates to:
  /// **'Black-owned'**
  String get guestFilterBlackOwned;

  /// No description provided for @guestFilterAesthetic.
  ///
  /// In en, this message translates to:
  /// **'Aesthetic'**
  String get guestFilterAesthetic;

  /// No description provided for @guestFilterLgbtq.
  ///
  /// In en, this message translates to:
  /// **'LGBTQ+'**
  String get guestFilterLgbtq;

  /// No description provided for @guestFilterVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get guestFilterVegan;

  /// No description provided for @guestFilterVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get guestFilterVegetarian;

  /// No description provided for @guestFilterWheelchair.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair'**
  String get guestFilterWheelchair;

  /// No description provided for @guestCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get guestCategoryAll;

  /// No description provided for @guestCategoryRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get guestCategoryRestaurants;

  /// No description provided for @guestCategoryCafes.
  ///
  /// In en, this message translates to:
  /// **'Cafés'**
  String get guestCategoryCafes;

  /// No description provided for @guestCategoryParks.
  ///
  /// In en, this message translates to:
  /// **'Parks'**
  String get guestCategoryParks;

  /// No description provided for @guestCategoryMuseums.
  ///
  /// In en, this message translates to:
  /// **'Museums'**
  String get guestCategoryMuseums;

  /// No description provided for @guestCategoryNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get guestCategoryNightlife;

  /// No description provided for @demoActTitleMountainTrailHike.
  ///
  /// In en, this message translates to:
  /// **'Mountain Trail Hike'**
  String get demoActTitleMountainTrailHike;

  /// No description provided for @demoActTitleCityBikeTour.
  ///
  /// In en, this message translates to:
  /// **'City Bike Tour'**
  String get demoActTitleCityBikeTour;

  /// No description provided for @demoActTitleIndoorClimbing.
  ///
  /// In en, this message translates to:
  /// **'Indoor Climbing'**
  String get demoActTitleIndoorClimbing;

  /// No description provided for @demoActTitleCozyCornerCafe.
  ///
  /// In en, this message translates to:
  /// **'Cozy Corner Café'**
  String get demoActTitleCozyCornerCafe;

  /// No description provided for @demoActTitleBotanicalGarden.
  ///
  /// In en, this message translates to:
  /// **'Botanical Garden'**
  String get demoActTitleBotanicalGarden;

  /// No description provided for @demoActTitleWellnessSpa.
  ///
  /// In en, this message translates to:
  /// **'Wellness Spa'**
  String get demoActTitleWellnessSpa;

  /// No description provided for @demoActTitleSunsetViewpoint.
  ///
  /// In en, this message translates to:
  /// **'Sunset Viewpoint'**
  String get demoActTitleSunsetViewpoint;

  /// No description provided for @demoActTitleWineAndDine.
  ///
  /// In en, this message translates to:
  /// **'Wine & Dine'**
  String get demoActTitleWineAndDine;

  /// No description provided for @demoActTitleRoseGardenWalk.
  ///
  /// In en, this message translates to:
  /// **'Rose Garden Walk'**
  String get demoActTitleRoseGardenWalk;

  /// No description provided for @demoActTitleHistoryMuseum.
  ///
  /// In en, this message translates to:
  /// **'History Museum'**
  String get demoActTitleHistoryMuseum;

  /// No description provided for @demoActTitleLocalTheater.
  ///
  /// In en, this message translates to:
  /// **'Local Theater'**
  String get demoActTitleLocalTheater;

  /// No description provided for @demoActTitleArtGallery.
  ///
  /// In en, this message translates to:
  /// **'Art Gallery'**
  String get demoActTitleArtGallery;

  /// No description provided for @demoActTitleLocalFavorite.
  ///
  /// In en, this message translates to:
  /// **'Local Favorite'**
  String get demoActTitleLocalFavorite;

  /// No description provided for @demoActTitleCozyCafe.
  ///
  /// In en, this message translates to:
  /// **'Cozy Café'**
  String get demoActTitleCozyCafe;

  /// No description provided for @demoActTitleWineBar.
  ///
  /// In en, this message translates to:
  /// **'Wine Bar'**
  String get demoActTitleWineBar;

  /// No description provided for @demoActTitleRooftopBar.
  ///
  /// In en, this message translates to:
  /// **'Rooftop Bar'**
  String get demoActTitleRooftopBar;

  /// No description provided for @demoActTitleArcadeLounge.
  ///
  /// In en, this message translates to:
  /// **'Arcade Lounge'**
  String get demoActTitleArcadeLounge;

  /// No description provided for @demoActTitleLiveMusicSpot.
  ///
  /// In en, this message translates to:
  /// **'Live Music Spot'**
  String get demoActTitleLiveMusicSpot;

  /// No description provided for @demoActTitlePopularSpot.
  ///
  /// In en, this message translates to:
  /// **'Popular Spot'**
  String get demoActTitlePopularSpot;

  /// No description provided for @demoActTitleFunActivity.
  ///
  /// In en, this message translates to:
  /// **'Fun Activity'**
  String get demoActTitleFunActivity;

  /// No description provided for @demoActSubScenic32.
  ///
  /// In en, this message translates to:
  /// **'Scenic adventure • 3.2 km away'**
  String get demoActSubScenic32;

  /// No description provided for @demoActSubActive18.
  ///
  /// In en, this message translates to:
  /// **'Active exploration • 1.8 km away'**
  String get demoActSubActive18;

  /// No description provided for @demoActSubThrilling25.
  ///
  /// In en, this message translates to:
  /// **'Thrilling experience • 2.5 km away'**
  String get demoActSubThrilling25;

  /// No description provided for @demoActSubUnwinding08.
  ///
  /// In en, this message translates to:
  /// **'Perfect for unwinding • 0.8 km away'**
  String get demoActSubUnwinding08;

  /// No description provided for @demoActSubPeaceful21.
  ///
  /// In en, this message translates to:
  /// **'Peaceful escape • 2.1 km away'**
  String get demoActSubPeaceful21;

  /// No description provided for @demoActSubRelaxation34.
  ///
  /// In en, this message translates to:
  /// **'Total relaxation • 3.4 km away'**
  String get demoActSubRelaxation34;

  /// No description provided for @demoActSubMagical15.
  ///
  /// In en, this message translates to:
  /// **'Magical atmosphere • 1.5 km away'**
  String get demoActSubMagical15;

  /// No description provided for @demoActSubIntimate09.
  ///
  /// In en, this message translates to:
  /// **'Intimate setting • 0.9 km away'**
  String get demoActSubIntimate09;

  /// No description provided for @demoActSubStroll23.
  ///
  /// In en, this message translates to:
  /// **'Beautiful stroll • 2.3 km away'**
  String get demoActSubStroll23;

  /// No description provided for @demoActSubExhibits12.
  ///
  /// In en, this message translates to:
  /// **'Fascinating exhibits • 1.2 km away'**
  String get demoActSubExhibits12;

  /// No description provided for @demoActSubLive18.
  ///
  /// In en, this message translates to:
  /// **'Live performances • 1.8 km away'**
  String get demoActSubLive18;

  /// No description provided for @demoActSubContemporary07.
  ///
  /// In en, this message translates to:
  /// **'Contemporary art • 0.7 km away'**
  String get demoActSubContemporary07;

  /// No description provided for @demoActSubTopReviewed05.
  ///
  /// In en, this message translates to:
  /// **'Top reviewed • 0.5 km away'**
  String get demoActSubTopReviewed05;

  /// No description provided for @demoActSubBrunch09.
  ///
  /// In en, this message translates to:
  /// **'Great brunch • 0.9 km away'**
  String get demoActSubBrunch09;

  /// No description provided for @demoActSubSmallPlates12.
  ///
  /// In en, this message translates to:
  /// **'Small plates • 1.2 km away'**
  String get demoActSubSmallPlates12;

  /// No description provided for @demoActSubVibes11.
  ///
  /// In en, this message translates to:
  /// **'Atmosphere & views • 1.1 km away'**
  String get demoActSubVibes11;

  /// No description provided for @demoActSubGames07.
  ///
  /// In en, this message translates to:
  /// **'Games & drinks • 0.7 km away'**
  String get demoActSubGames07;

  /// No description provided for @demoActSubTonightsGig15.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s gig • 1.5 km away'**
  String get demoActSubTonightsGig15;

  /// No description provided for @demoActSubHighlyRated10.
  ///
  /// In en, this message translates to:
  /// **'Highly rated • 1.0 km away'**
  String get demoActSubHighlyRated10;

  /// No description provided for @demoActSubGreatToday15.
  ///
  /// In en, this message translates to:
  /// **'Great for today • 1.5 km away'**
  String get demoActSubGreatToday15;

  /// No description provided for @demoActSubTopReviewed08.
  ///
  /// In en, this message translates to:
  /// **'Top reviewed • 0.8 km away'**
  String get demoActSubTopReviewed08;

  /// No description provided for @guestPlaceNameCozyCorner.
  ///
  /// In en, this message translates to:
  /// **'The Cozy Corner'**
  String get guestPlaceNameCozyCorner;

  /// No description provided for @guestPlaceNameSunsetTerrace.
  ///
  /// In en, this message translates to:
  /// **'Sunset Terrace'**
  String get guestPlaceNameSunsetTerrace;

  /// No description provided for @guestPlaceNameCityArtMuseum.
  ///
  /// In en, this message translates to:
  /// **'City Art Museum'**
  String get guestPlaceNameCityArtMuseum;

  /// No description provided for @guestPlaceNameGreenPark.
  ///
  /// In en, this message translates to:
  /// **'Green Park'**
  String get guestPlaceNameGreenPark;

  /// No description provided for @guestPlaceNameJazzLounge.
  ///
  /// In en, this message translates to:
  /// **'Jazz Lounge'**
  String get guestPlaceNameJazzLounge;

  /// No description provided for @guestPlaceNameRooftopBar.
  ///
  /// In en, this message translates to:
  /// **'Rooftop Bar'**
  String get guestPlaceNameRooftopBar;

  /// No description provided for @guestPlaceNameFreshKitchen.
  ///
  /// In en, this message translates to:
  /// **'Fresh Kitchen'**
  String get guestPlaceNameFreshKitchen;

  /// No description provided for @guestPlaceNameHistoryMuseum.
  ///
  /// In en, this message translates to:
  /// **'History Museum'**
  String get guestPlaceNameHistoryMuseum;

  /// No description provided for @guestPlaceNameSpiceRoute.
  ///
  /// In en, this message translates to:
  /// **'Spice Route'**
  String get guestPlaceNameSpiceRoute;

  /// No description provided for @guestPlaceNameSoulKitchen.
  ///
  /// In en, this message translates to:
  /// **'Soul Kitchen'**
  String get guestPlaceNameSoulKitchen;

  /// No description provided for @guestPlaceNameStudioCafe.
  ///
  /// In en, this message translates to:
  /// **'Studio Café'**
  String get guestPlaceNameStudioCafe;

  /// No description provided for @guestPlaceDescCozyCorner.
  ///
  /// In en, this message translates to:
  /// **'A warm neighbourhood café with specialty coffee and fresh pastries.'**
  String get guestPlaceDescCozyCorner;

  /// No description provided for @guestPlaceDescSunsetTerrace.
  ///
  /// In en, this message translates to:
  /// **'Terrace dining with a view and a relaxed evening atmosphere.'**
  String get guestPlaceDescSunsetTerrace;

  /// No description provided for @guestPlaceDescCityArtMuseum.
  ///
  /// In en, this message translates to:
  /// **'Modern art and rotating exhibitions in a striking building.'**
  String get guestPlaceDescCityArtMuseum;

  /// No description provided for @guestPlaceDescGreenPark.
  ///
  /// In en, this message translates to:
  /// **'Lush green space perfect for a stroll or a picnic.'**
  String get guestPlaceDescGreenPark;

  /// No description provided for @guestPlaceDescJazzLounge.
  ///
  /// In en, this message translates to:
  /// **'Live jazz, craft cocktails, and a moody interior.'**
  String get guestPlaceDescJazzLounge;

  /// No description provided for @guestPlaceDescRooftopBar.
  ///
  /// In en, this message translates to:
  /// **'Skyline views and cocktails at golden hour.'**
  String get guestPlaceDescRooftopBar;

  /// No description provided for @guestPlaceDescFreshKitchen.
  ///
  /// In en, this message translates to:
  /// **'Healthy, colourful bowls and fresh ingredients.'**
  String get guestPlaceDescFreshKitchen;

  /// No description provided for @guestPlaceDescHistoryMuseum.
  ///
  /// In en, this message translates to:
  /// **'Local history and heritage in a grand historic building.'**
  String get guestPlaceDescHistoryMuseum;

  /// No description provided for @guestPlaceDescSpiceRoute.
  ///
  /// In en, this message translates to:
  /// **'Halal-friendly flavours and generous portions.'**
  String get guestPlaceDescSpiceRoute;

  /// No description provided for @guestPlaceDescSoulKitchen.
  ///
  /// In en, this message translates to:
  /// **'Comfort food and live music in a welcoming space.'**
  String get guestPlaceDescSoulKitchen;

  /// No description provided for @guestPlaceDescStudioCafe.
  ///
  /// In en, this message translates to:
  /// **'Minimal interior and great light for working or meeting.'**
  String get guestPlaceDescStudioCafe;

  /// No description provided for @guestOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get guestOpenNow;

  /// No description provided for @guestClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get guestClosed;

  /// No description provided for @guestFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get guestFree;

  /// No description provided for @guestPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get guestPaid;

  /// No description provided for @guestDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String guestDistanceAway(String distance);

  /// No description provided for @guestHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get guestHours;

  /// No description provided for @signupJoinWanderMood.
  ///
  /// In en, this message translates to:
  /// **'Want this every day?'**
  String get signupJoinWanderMood;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to get started.\nNo password needed!'**
  String get signupSubtitle;

  /// No description provided for @signupEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signupEmailLabel;

  /// No description provided for @signupEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get signupEmailHint;

  /// No description provided for @signupEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get signupEmailRequired;

  /// No description provided for @signupEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get signupEmailInvalid;

  /// No description provided for @signupSendMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Send my link'**
  String get signupSendMagicLink;

  /// No description provided for @signupErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get signupErrorGeneric;

  /// No description provided for @signupWhatYouGet.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll get'**
  String get signupWhatYouGet;

  /// No description provided for @signupBenefitPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized recommendations'**
  String get signupBenefitPersonalized;

  /// No description provided for @signupBenefitFavorites.
  ///
  /// In en, this message translates to:
  /// **'Save your favorite places'**
  String get signupBenefitFavorites;

  /// No description provided for @signupBenefitDayPlans.
  ///
  /// In en, this message translates to:
  /// **'Create custom day plans'**
  String get signupBenefitDayPlans;

  /// No description provided for @signupBenefitMoodMatching.
  ///
  /// In en, this message translates to:
  /// **'Mood-based activity matching'**
  String get signupBenefitMoodMatching;

  /// No description provided for @signupTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy'**
  String get signupTerms;

  /// No description provided for @signupCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email!'**
  String get signupCheckEmail;

  /// No description provided for @signupWeSentLinkTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a magic link to'**
  String get signupWeSentLinkTo;

  /// No description provided for @signupClickLinkInEmail.
  ///
  /// In en, this message translates to:
  /// **'Click the link in the email to sign in'**
  String get signupClickLinkInEmail;

  /// No description provided for @signupLinkExpires.
  ///
  /// In en, this message translates to:
  /// **'The link expires in 24 hours'**
  String get signupLinkExpires;

  /// No description provided for @signupCheckSpam.
  ///
  /// In en, this message translates to:
  /// **'Check spam folder if not in inbox'**
  String get signupCheckSpam;

  /// No description provided for @signupTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive email? Try again'**
  String get signupTryAgain;

  /// No description provided for @signupAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'You\'re almost there! One click away from discovering amazing mood-based adventures in {city} ✨'**
  String signupAlmostThere(String city);

  /// No description provided for @signupAlmostThereTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re almost there!'**
  String get signupAlmostThereTitle;

  /// No description provided for @signupAlmostThereBody.
  ///
  /// In en, this message translates to:
  /// **'One click away from discovering amazing mood-based adventures in {city} ✨'**
  String signupAlmostThereBody(String city);

  /// No description provided for @signupJoinTravelersInCity.
  ///
  /// In en, this message translates to:
  /// **'Join {count} travelers in {city}!'**
  String signupJoinTravelersInCity(String count, String city);

  /// No description provided for @signupJoinTravelers.
  ///
  /// In en, this message translates to:
  /// **'Join {count} travelers!'**
  String signupJoinTravelers(String count);

  /// No description provided for @signupWhatYouUnlock.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll unlock'**
  String get signupWhatYouUnlock;

  /// No description provided for @signupUnlockPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized recommendations'**
  String get signupUnlockPersonalized;

  /// No description provided for @signupUnlockFavorites.
  ///
  /// In en, this message translates to:
  /// **'Save your favorite places'**
  String get signupUnlockFavorites;

  /// No description provided for @signupUnlockDayPlans.
  ///
  /// In en, this message translates to:
  /// **'Create custom day plans'**
  String get signupUnlockDayPlans;

  /// No description provided for @signupUnlockMoodMatching.
  ///
  /// In en, this message translates to:
  /// **'Mood-based activity matching'**
  String get signupUnlockMoodMatching;

  /// No description provided for @signupRating.
  ///
  /// In en, this message translates to:
  /// **'4.9/5 Rating'**
  String get signupRating;

  /// No description provided for @signupLoveIt.
  ///
  /// In en, this message translates to:
  /// **'98% Love It'**
  String get signupLoveIt;

  /// No description provided for @signupTestimonial.
  ///
  /// In en, this message translates to:
  /// **'WanderMood helped me discover places I never knew existed!'**
  String get signupTestimonial;

  /// No description provided for @signupTestimonialBy.
  ///
  /// In en, this message translates to:
  /// **'– Sarah, {city}'**
  String signupTestimonialBy(String city);

  /// No description provided for @signupDefaultCity.
  ///
  /// In en, this message translates to:
  /// **'Rotterdam'**
  String get signupDefaultCity;

  /// No description provided for @profileSnackAvatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated!'**
  String get profileSnackAvatarUpdated;

  /// No description provided for @profileSnackAvatarFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update picture: {error}'**
  String profileSnackAvatarFailed(String error);

  /// No description provided for @profileErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get profileErrorLoad;

  /// No description provided for @profileRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get profileRetry;

  /// No description provided for @profileFallbackUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileFallbackUser;

  /// No description provided for @profileStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Stats'**
  String get profileStatsTitle;

  /// No description provided for @profileStatsCheckinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-ins'**
  String get profileStatsCheckinsTitle;

  /// No description provided for @profileStatsPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get profileStatsPlacesTitle;

  /// No description provided for @profileStatsPlacesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to explore'**
  String get profileStatsPlacesSubtitle;

  /// No description provided for @profileStatsTopMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Mood'**
  String get profileStatsTopMoodTitle;

  /// No description provided for @profileStatsStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get profileStatsStreakTitle;

  /// No description provided for @profileStatsStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{day streak} other{days streak}}'**
  String profileStatsStreakSubtitle(int count);

  /// No description provided for @profileTopMoodEmpty.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get profileTopMoodEmpty;

  /// No description provided for @profileSavedPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get profileSavedPlacesTitle;

  /// No description provided for @profileSavedPlacesSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get profileSavedPlacesSeeAll;

  /// No description provided for @profileSavedPlacesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet'**
  String get profileSavedPlacesEmpty;

  /// No description provided for @profileEditProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditProfileButton;

  /// No description provided for @profileAppSettingsLink.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get profileAppSettingsLink;

  /// No description provided for @profileFavoriteVibesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Favorite Vibes'**
  String get profileFavoriteVibesTitle;

  /// No description provided for @profileFavoriteVibesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps Moody tune suggestions to how you like to feel when you’re out.'**
  String get profileFavoriteVibesSubtitle;

  /// No description provided for @profileFavoriteVibesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileFavoriteVibesEdit;

  /// No description provided for @profileFavoriteVibesAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Add Vibe'**
  String get profileFavoriteVibesAdd;

  /// No description provided for @profileMoodJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Mood Journey'**
  String get profileMoodJourneyTitle;

  /// No description provided for @profileMoodJourneySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your mood history'**
  String get profileMoodJourneySubtitle;

  /// No description provided for @moodHistoryIntro.
  ///
  /// In en, this message translates to:
  /// **'Your recent check-ins.'**
  String get moodHistoryIntro;

  /// No description provided for @moodHistoryScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mood check-ins and notes, newest first.'**
  String get moodHistoryScreenSubtitle;

  /// No description provided for @moodHistorySectionRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get moodHistorySectionRecent;

  /// No description provided for @moodHistorySectionTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get moodHistorySectionTimeline;

  /// No description provided for @moodHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your journey starts here'**
  String get moodHistoryEmptyTitle;

  /// No description provided for @moodHistoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Log a mood from Moody or My Day to build your streak.'**
  String get moodHistoryEmptyBody;

  /// No description provided for @moodHistoryLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your mood journey.'**
  String get moodHistoryLoginRequired;

  /// No description provided for @moodHistoryErrorUser.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading your account.'**
  String get moodHistoryErrorUser;

  /// No description provided for @moodHistoryErrorMoods.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading moods.'**
  String get moodHistoryErrorMoods;

  /// No description provided for @moodHistoryTodayBadge.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get moodHistoryTodayBadge;

  /// No description provided for @moodHistoryDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get moodHistoryDayToday;

  /// No description provided for @moodHistoryDayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get moodHistoryDayYesterday;

  /// No description provided for @profileTravelGlobeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Travel Globe'**
  String get profileTravelGlobeTitle;

  /// No description provided for @profileTravelGlobeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore your travel journey'**
  String get profileTravelGlobeSubtitle;

  /// No description provided for @profilePreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Preferences'**
  String get profilePreferencesTitle;

  /// No description provided for @profilePreferencesEditAll.
  ///
  /// In en, this message translates to:
  /// **'Edit All'**
  String get profilePreferencesEditAll;

  /// No description provided for @profilePreferencesNoneSet.
  ///
  /// In en, this message translates to:
  /// **'No preferences set yet.'**
  String get profilePreferencesNoneSet;

  /// No description provided for @profileSnackLocalModeSaved.
  ///
  /// In en, this message translates to:
  /// **'Local mode saved'**
  String get profileSnackLocalModeSaved;

  /// No description provided for @profileSnackTravelingModeSaved.
  ///
  /// In en, this message translates to:
  /// **'Travel mode saved'**
  String get profileSnackTravelingModeSaved;

  /// No description provided for @profilePreferencesBudgetStyle.
  ///
  /// In en, this message translates to:
  /// **'Budget Style'**
  String get profilePreferencesBudgetStyle;

  /// No description provided for @profilePreferencesSocialVibe.
  ///
  /// In en, this message translates to:
  /// **'Social Vibe'**
  String get profilePreferencesSocialVibe;

  /// No description provided for @profilePreferencesFoodPreferences.
  ///
  /// In en, this message translates to:
  /// **'Food Preferences'**
  String get profilePreferencesFoodPreferences;

  /// No description provided for @profilePreferencesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Edit All\" to set your preferences'**
  String get profilePreferencesEmptyHint;

  /// No description provided for @profilePreferencesFilledHint.
  ///
  /// In en, this message translates to:
  /// **'These preferences subtly guide which places and plans fit you best.'**
  String get profilePreferencesFilledHint;

  /// No description provided for @profilePreferencesEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Fill in your preferences so WanderMood can better align with your style.'**
  String get profilePreferencesEmptyDescription;

  /// No description provided for @profileSectionWorldTitle.
  ///
  /// In en, this message translates to:
  /// **'Your World'**
  String get profileSectionWorldTitle;

  /// No description provided for @profileSectionWorldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Places you save, moods you track, and the story of your travels.'**
  String get profileSectionWorldSubtitle;

  /// No description provided for @profileSectionPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Style, pace, and how you like to travel.'**
  String get profileSectionPreferencesSubtitle;

  /// No description provided for @profileSavedPlacesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Places you want to easily find back later.'**
  String get profileSavedPlacesSubtitle;

  /// No description provided for @profileSavedPlacesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'You have no saved places yet. Save a few favorites so your profile feels more like your travel map.'**
  String get profileSavedPlacesEmptyHint;

  /// No description provided for @profileSavedPlacesCarouselEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saves yet — tap ♥ on a place to bookmark it.'**
  String get profileSavedPlacesCarouselEmpty;

  /// No description provided for @profileBioEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a short bio in Edit profile.'**
  String get profileBioEmptyHint;

  /// No description provided for @profileStatsTopMoodEmpty.
  ///
  /// In en, this message translates to:
  /// **'Still discovering'**
  String get profileStatsTopMoodEmpty;

  /// No description provided for @profileStatsSavePlacesHint.
  ///
  /// In en, this message translates to:
  /// **'Start saving places that match your mood.'**
  String get profileStatsSavePlacesHint;

  /// No description provided for @profileStatsSavedPlacesReady.
  ///
  /// In en, this message translates to:
  /// **'Your saved spots are ready whenever you need inspiration.'**
  String get profileStatsSavedPlacesReady;

  /// No description provided for @profileFavoriteVibesEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a few vibes so Moody quickly understands what you’re really looking for.'**
  String get profileFavoriteVibesEmptyDescription;

  /// No description provided for @profileFavoriteVibesFilledDescription.
  ///
  /// In en, this message translates to:
  /// **'These vibes help WanderMood determine which places and plans suit you best.'**
  String get profileFavoriteVibesFilledDescription;

  /// No description provided for @profileFavoriteVibesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add vibes'**
  String get profileFavoriteVibesEmptyHint;

  /// No description provided for @profileVibesProTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'💡 Pro Tips'**
  String get profileVibesProTipsTitle;

  /// No description provided for @profileVibesProTipsBody.
  ///
  /// In en, this message translates to:
  /// **'• Be honest about what you enjoy — better recommendations!\n• You can change these anytime\n• Mix different vibes for varied suggestions'**
  String get profileVibesProTipsBody;

  /// No description provided for @profileModeLocalCardDescription.
  ///
  /// In en, this message translates to:
  /// **'WanderMood keeps your suggestions closer to home and aligned with your regular rhythm.'**
  String get profileModeLocalCardDescription;

  /// No description provided for @profileModeTravelCardDescription.
  ///
  /// In en, this message translates to:
  /// **'WanderMood thinks more like a travel companion and sends you to new places to discover.'**
  String get profileModeTravelCardDescription;

  /// No description provided for @profileActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileActionEdit;

  /// No description provided for @profileActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get profileActionShare;

  /// No description provided for @profileGenderWoman.
  ///
  /// In en, this message translates to:
  /// **'Woman'**
  String get profileGenderWoman;

  /// No description provided for @profileGenderMan.
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get profileGenderMan;

  /// No description provided for @profileGenderNonBinary.
  ///
  /// In en, this message translates to:
  /// **'Non-binary'**
  String get profileGenderNonBinary;

  /// No description provided for @profileGenderPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get profileGenderPreferNotToSay;

  /// No description provided for @profileEditGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'How do you identify?'**
  String get profileEditGenderLabel;

  /// No description provided for @profileAgeGroup20s.
  ///
  /// In en, this message translates to:
  /// **'20s Adventurer'**
  String get profileAgeGroup20s;

  /// No description provided for @profileAgeGroup30s.
  ///
  /// In en, this message translates to:
  /// **'30s Adventurer'**
  String get profileAgeGroup30s;

  /// No description provided for @profileAgeGroup40s.
  ///
  /// In en, this message translates to:
  /// **'40s Adventurer'**
  String get profileAgeGroup40s;

  /// No description provided for @profileAgeGroup50s.
  ///
  /// In en, this message translates to:
  /// **'50s Adventurer'**
  String get profileAgeGroup50s;

  /// No description provided for @profileAgeGroup55Plus.
  ///
  /// In en, this message translates to:
  /// **'55+ Adventurer'**
  String get profileAgeGroup55Plus;

  /// No description provided for @profileAgeGroupGenericSuffix.
  ///
  /// In en, this message translates to:
  /// **'{ageGroup} Adventurer'**
  String profileAgeGroupGenericSuffix(String ageGroup);

  /// No description provided for @profileBudgetLow.
  ///
  /// In en, this message translates to:
  /// **'\$ Budget'**
  String get profileBudgetLow;

  /// No description provided for @profileBudgetMid.
  ///
  /// In en, this message translates to:
  /// **'\$\$ Moderate'**
  String get profileBudgetMid;

  /// No description provided for @profileBudgetHigh.
  ///
  /// In en, this message translates to:
  /// **'\$\$\$ Luxury'**
  String get profileBudgetHigh;

  /// No description provided for @profileSocialSolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get profileSocialSolo;

  /// No description provided for @profileSocialCouple.
  ///
  /// In en, this message translates to:
  /// **'Couple'**
  String get profileSocialCouple;

  /// No description provided for @profileSocialGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get profileSocialGroup;

  /// No description provided for @profileSocialMix.
  ///
  /// In en, this message translates to:
  /// **'Mix'**
  String get profileSocialMix;

  /// No description provided for @profileSocialSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get profileSocialSocial;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// No description provided for @profileEditProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profileEditProfilePhoto;

  /// No description provided for @profileEditProfilePhotoTap.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get profileEditProfilePhotoTap;

  /// No description provided for @profileEditNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileEditNameLabel;

  /// No description provided for @profileEditUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username *'**
  String get profileEditUsernameLabel;

  /// No description provided for @profileEditUsernameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Username is required.'**
  String get profileEditUsernameRequiredError;

  /// No description provided for @profileEditUsernameFormatError.
  ///
  /// In en, this message translates to:
  /// **'Use 3–30 characters: letters, numbers, or underscores only.'**
  String get profileEditUsernameFormatError;

  /// No description provided for @profileEditUsernameTakenError.
  ///
  /// In en, this message translates to:
  /// **'That username is already taken. Try another.'**
  String get profileEditUsernameTakenError;

  /// No description provided for @profileEditEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEditEmailLabel;

  /// No description provided for @profileEditBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileEditBioLabel;

  /// No description provided for @profileEditSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get profileEditSelectDate;

  /// No description provided for @profileEditUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'username'**
  String get profileEditUsernameHint;

  /// No description provided for @profileEditEmailHint.
  ///
  /// In en, this message translates to:
  /// **'email@example.com'**
  String get profileEditEmailHint;

  /// No description provided for @profileEditNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get profileEditNameHint;

  /// No description provided for @profileEditBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get profileEditBioHint;

  /// No description provided for @profileEditLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileEditLocationLabel;

  /// No description provided for @profileEditLocationHint.
  ///
  /// In en, this message translates to:
  /// **'City, Country'**
  String get profileEditLocationHint;

  /// No description provided for @profileEditBirthdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get profileEditBirthdayLabel;

  /// No description provided for @profileEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileEditSave;

  /// No description provided for @profileEditNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No Changes'**
  String get profileEditNoChanges;

  /// No description provided for @profileEditFavoriteVibesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite Vibes'**
  String get profileEditFavoriteVibesTitle;

  /// No description provided for @profileEditFavoriteVibesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEditFavoriteVibesEdit;

  /// No description provided for @profileEditFavoriteVibesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your favorite vibes to personalize your recommendations'**
  String get profileEditFavoriteVibesSubtitle;

  /// No description provided for @profileEditPhotoTake.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get profileEditPhotoTake;

  /// No description provided for @profileEditPhotoChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get profileEditPhotoChoose;

  /// No description provided for @profileEditPhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get profileEditPhotoRemove;

  /// No description provided for @profileEditVibesTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Favorite Vibes'**
  String get profileEditVibesTitle;

  /// No description provided for @profileEditVibesDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get profileEditVibesDone;

  /// No description provided for @profileEditUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileEditUpdated;

  /// No description provided for @profileEditUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String profileEditUpdateFailed(String error);

  /// No description provided for @profileEditErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String profileEditErrorLoading(String error);

  /// No description provided for @profileEditUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get profileEditUnsavedTitle;

  /// No description provided for @profileEditUnsavedMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved edits. If you leave now, your changes will be lost.'**
  String get profileEditUnsavedMessage;

  /// No description provided for @profileEditDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get profileEditDiscard;

  /// No description provided for @profileEditKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get profileEditKeepEditing;

  /// No description provided for @profileVibesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Vibes updated! 🎉'**
  String get profileVibesUpdated;

  /// No description provided for @profileVibesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save vibes: {error}'**
  String profileVibesSaveFailed(String error);

  /// No description provided for @profileVibesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Favorite Vibes'**
  String get profileVibesEditTitle;

  /// No description provided for @profileVibesSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileVibesSave;

  /// No description provided for @profileVibesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected ({count}/5)'**
  String profileVibesSelectedCount(String count);

  /// No description provided for @profileVibesMaxReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum reached'**
  String get profileVibesMaxReached;

  /// No description provided for @profileVibesChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Vibes'**
  String get profileVibesChooseTitle;

  /// No description provided for @profileVibesAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add More Vibes'**
  String get profileVibesAddMore;

  /// No description provided for @profileVibesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select up to 5 vibes that match your personality. We\'ll use these to personalize your recommendations!'**
  String get profileVibesSubtitle;

  /// No description provided for @profileVibesCurrentTitle.
  ///
  /// In en, this message translates to:
  /// **'YOUR CURRENT VIBES'**
  String get profileVibesCurrentTitle;

  /// No description provided for @profileEditPhotoOverlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get profileEditPhotoOverlayLabel;

  /// No description provided for @profileEditLocationHintExamples.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rotterdam, Amsterdam...'**
  String get profileEditLocationHintExamples;

  /// No description provided for @preferencesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit preferences'**
  String get preferencesScreenTitle;

  /// No description provided for @prefSectionCommunicationStyle.
  ///
  /// In en, this message translates to:
  /// **'Communication style'**
  String get prefSectionCommunicationStyle;

  /// No description provided for @prefSectionInterests.
  ///
  /// In en, this message translates to:
  /// **'Your Interests'**
  String get prefSectionInterests;

  /// No description provided for @prefSectionSocialVibe.
  ///
  /// In en, this message translates to:
  /// **'Social Vibe'**
  String get prefSectionSocialVibe;

  /// No description provided for @prefSectionTravelStyles.
  ///
  /// In en, this message translates to:
  /// **'Travel styles'**
  String get prefSectionTravelStyles;

  /// No description provided for @prefSectionFavoriteMoods.
  ///
  /// In en, this message translates to:
  /// **'Favorite moods'**
  String get prefSectionFavoriteMoods;

  /// No description provided for @prefSectionPlanningPace.
  ///
  /// In en, this message translates to:
  /// **'Planning Pace ⏰'**
  String get prefSectionPlanningPace;

  /// No description provided for @prefSectionSelectedMoods.
  ///
  /// In en, this message translates to:
  /// **'Selected moods'**
  String get prefSectionSelectedMoods;

  /// No description provided for @prefSectionDietaryInclusion.
  ///
  /// In en, this message translates to:
  /// **'Dietary & inclusion'**
  String get prefSectionDietaryInclusion;

  /// No description provided for @prefDietaryInclusionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moody uses these for recommendations across the app. Select any that apply.'**
  String get prefDietaryInclusionSubtitle;

  /// No description provided for @prefCommFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get prefCommFriendly;

  /// No description provided for @prefCommPlayful.
  ///
  /// In en, this message translates to:
  /// **'Playful'**
  String get prefCommPlayful;

  /// No description provided for @prefCommCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get prefCommCalm;

  /// No description provided for @prefCommPractical.
  ///
  /// In en, this message translates to:
  /// **'Practical'**
  String get prefCommPractical;

  /// No description provided for @prefIntFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get prefIntFood;

  /// No description provided for @prefIntCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get prefIntCulture;

  /// No description provided for @prefIntNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get prefIntNature;

  /// No description provided for @prefIntNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get prefIntNightlife;

  /// No description provided for @prefIntShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get prefIntShopping;

  /// No description provided for @prefIntWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get prefIntWellness;

  /// No description provided for @prefSocSolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get prefSocSolo;

  /// No description provided for @prefSocSmallGroup.
  ///
  /// In en, this message translates to:
  /// **'Small-group'**
  String get prefSocSmallGroup;

  /// No description provided for @prefSocMix.
  ///
  /// In en, this message translates to:
  /// **'Mix'**
  String get prefSocMix;

  /// No description provided for @prefSocSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get prefSocSocial;

  /// No description provided for @prefTravelRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get prefTravelRelaxed;

  /// No description provided for @prefTravelAdventurous.
  ///
  /// In en, this message translates to:
  /// **'Adventurous'**
  String get prefTravelAdventurous;

  /// No description provided for @prefTravelCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get prefTravelCultural;

  /// No description provided for @prefTravelCityBreak.
  ///
  /// In en, this message translates to:
  /// **'City-break'**
  String get prefTravelCityBreak;

  /// No description provided for @prefFavHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get prefFavHappy;

  /// No description provided for @prefFavAdventurous.
  ///
  /// In en, this message translates to:
  /// **'Adventurous'**
  String get prefFavAdventurous;

  /// No description provided for @prefFavCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get prefFavCalm;

  /// No description provided for @prefFavRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get prefFavRomantic;

  /// No description provided for @prefFavEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get prefFavEnergetic;

  /// No description provided for @prefPlanSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same Day Planner'**
  String get prefPlanSameDay;

  /// No description provided for @prefPlanWeekAhead.
  ///
  /// In en, this message translates to:
  /// **'Week Ahead Planner'**
  String get prefPlanWeekAhead;

  /// No description provided for @prefPlanSpontaneous.
  ///
  /// In en, this message translates to:
  /// **'Spontaneous'**
  String get prefPlanSpontaneous;

  /// No description provided for @prefSelHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get prefSelHappy;

  /// No description provided for @prefSelRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get prefSelRelaxed;

  /// No description provided for @prefSelCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get prefSelCultural;

  /// No description provided for @prefSelRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get prefSelRomantic;

  /// No description provided for @prefSelEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get prefSelEnergetic;

  /// No description provided for @prefSelCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get prefSelCreative;

  /// No description provided for @profileVibeAdventurousName.
  ///
  /// In en, this message translates to:
  /// **'Adventurous'**
  String get profileVibeAdventurousName;

  /// No description provided for @profileVibeAdventurousDesc.
  ///
  /// In en, this message translates to:
  /// **'Thrilling activities & outdoor adventures'**
  String get profileVibeAdventurousDesc;

  /// No description provided for @profileVibeChillName.
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get profileVibeChillName;

  /// No description provided for @profileVibeChillDesc.
  ///
  /// In en, this message translates to:
  /// **'Relaxed, laid-back experiences'**
  String get profileVibeChillDesc;

  /// No description provided for @profileVibeFoodieName.
  ///
  /// In en, this message translates to:
  /// **'Foodie'**
  String get profileVibeFoodieName;

  /// No description provided for @profileVibeFoodieDesc.
  ///
  /// In en, this message translates to:
  /// **'Culinary experiences & dining'**
  String get profileVibeFoodieDesc;

  /// No description provided for @profileVibeSocialName.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get profileVibeSocialName;

  /// No description provided for @profileVibeSocialDesc.
  ///
  /// In en, this message translates to:
  /// **'Meeting people & social events'**
  String get profileVibeSocialDesc;

  /// No description provided for @profileVibeCulturalName.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get profileVibeCulturalName;

  /// No description provided for @profileVibeCulturalDesc.
  ///
  /// In en, this message translates to:
  /// **'Museums, art & history'**
  String get profileVibeCulturalDesc;

  /// No description provided for @profileVibeNatureName.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get profileVibeNatureName;

  /// No description provided for @profileVibeNatureDesc.
  ///
  /// In en, this message translates to:
  /// **'Parks, gardens & outdoors'**
  String get profileVibeNatureDesc;

  /// No description provided for @profileVibeRomanticName.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get profileVibeRomanticName;

  /// No description provided for @profileVibeRomanticDesc.
  ///
  /// In en, this message translates to:
  /// **'Date nights & romantic spots'**
  String get profileVibeRomanticDesc;

  /// No description provided for @profileVibeWellnessName.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get profileVibeWellnessName;

  /// No description provided for @profileVibeWellnessDesc.
  ///
  /// In en, this message translates to:
  /// **'Spas, yoga & self-care'**
  String get profileVibeWellnessDesc;

  /// No description provided for @profileVibeNightlifeName.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get profileVibeNightlifeName;

  /// No description provided for @profileVibeNightlifeDesc.
  ///
  /// In en, this message translates to:
  /// **'Bars, clubs & evening fun'**
  String get profileVibeNightlifeDesc;

  /// No description provided for @profileVibeShoppingName.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get profileVibeShoppingName;

  /// No description provided for @profileVibeShoppingDesc.
  ///
  /// In en, this message translates to:
  /// **'Markets, boutiques & malls'**
  String get profileVibeShoppingDesc;

  /// No description provided for @profileVibeCreativeName.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get profileVibeCreativeName;

  /// No description provided for @profileVibeCreativeDesc.
  ///
  /// In en, this message translates to:
  /// **'Art studios & creative spaces'**
  String get profileVibeCreativeDesc;

  /// No description provided for @profileVibeSportyName.
  ///
  /// In en, this message translates to:
  /// **'Sporty'**
  String get profileVibeSportyName;

  /// No description provided for @profileVibeSportyDesc.
  ///
  /// In en, this message translates to:
  /// **'Sports & fitness activities'**
  String get profileVibeSportyDesc;

  /// No description provided for @profileGlobeYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Your Journey'**
  String get profileGlobeYourJourney;

  /// No description provided for @profileGlobeDemoHint.
  ///
  /// In en, this message translates to:
  /// **'Demo — tap a marker!'**
  String get profileGlobeDemoHint;

  /// No description provided for @profileGlobePlacesVisitedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} places visited'**
  String profileGlobePlacesVisitedCount(String count);

  /// No description provided for @profileGlobeBadgeDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get profileGlobeBadgeDemo;

  /// No description provided for @profileGlobeControlRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get profileGlobeControlRotate;

  /// No description provided for @profileGlobeControlPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get profileGlobeControlPause;

  /// No description provided for @profileGlobeControlReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get profileGlobeControlReset;

  /// No description provided for @profileGlobeUnknownMood.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get profileGlobeUnknownMood;

  /// No description provided for @shareProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get shareProfileTitle;

  /// No description provided for @shareProfileShareTextMy.
  ///
  /// In en, this message translates to:
  /// **'Check out my profile on WanderMood! 🧳✨\n\n{url}'**
  String shareProfileShareTextMy(String url);

  /// No description provided for @shareProfileShareTextNamed.
  ///
  /// In en, this message translates to:
  /// **'Check out {name}\'s profile on WanderMood! 🧳✨\n\n{url}'**
  String shareProfileShareTextNamed(String name, String url);

  /// No description provided for @shareProfileMy.
  ///
  /// In en, this message translates to:
  /// **'my'**
  String get shareProfileMy;

  /// No description provided for @shareProfileDefaultUsername.
  ///
  /// In en, this message translates to:
  /// **'wanderer'**
  String get shareProfileDefaultUsername;

  /// No description provided for @shareProfileEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Check out my WanderMood profile'**
  String get shareProfileEmailSubject;

  /// No description provided for @shareProfileFailedToShare.
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {error}'**
  String shareProfileFailedToShare(String error);

  /// No description provided for @shareProfileDefaultBio.
  ///
  /// In en, this message translates to:
  /// **'Always chasing sunsets & good vibes ✨'**
  String get shareProfileDefaultBio;

  /// No description provided for @shareProfileDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get shareProfileDayStreak;

  /// No description provided for @shareProfileQRCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get shareProfileQRCode;

  /// No description provided for @shareProfileScanToConnect.
  ///
  /// In en, this message translates to:
  /// **'Scan to connect'**
  String get shareProfileScanToConnect;

  /// No description provided for @shareProfileCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get shareProfileCopyLink;

  /// No description provided for @shareProfileShareAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Share anywhere'**
  String get shareProfileShareAnywhere;

  /// No description provided for @shareProfileShareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via'**
  String get shareProfileShareVia;

  /// No description provided for @shareProfileInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get shareProfileInstagram;

  /// No description provided for @shareProfileWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get shareProfileWhatsApp;

  /// No description provided for @shareProfileTwitter.
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get shareProfileTwitter;

  /// No description provided for @shareProfileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get shareProfileEmail;

  /// No description provided for @shareProfilePublicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get shareProfilePublicProfile;

  /// No description provided for @shareProfileAnyoneCanView.
  ///
  /// In en, this message translates to:
  /// **'Anyone can view your profile'**
  String get shareProfileAnyoneCanView;

  /// No description provided for @shareProfileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update: {error}'**
  String shareProfileUpdateFailed(String error);

  /// No description provided for @shareProfileMyQRCode.
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get shareProfileMyQRCode;

  /// No description provided for @shareProfileHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get shareProfileHowItWorks;

  /// No description provided for @shareProfileQRInstructions.
  ///
  /// In en, this message translates to:
  /// **'Ask someone to scan this code with their WanderMood app to instantly connect and share your profile!'**
  String get shareProfileQRInstructions;

  /// No description provided for @shareProfileDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded!'**
  String get shareProfileDownloaded;

  /// No description provided for @shareProfileSaveQRCode.
  ///
  /// In en, this message translates to:
  /// **'Save QR Code'**
  String get shareProfileSaveQRCode;

  /// No description provided for @shareProfileShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out my WanderMood profile! {url}'**
  String shareProfileShareMessage(String url);

  /// No description provided for @shareProfileShareQRImage.
  ///
  /// In en, this message translates to:
  /// **'Share QR Image'**
  String get shareProfileShareQRImage;

  /// No description provided for @shareProfileShareLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareProfileShareLinkTitle;

  /// No description provided for @shareProfileYourProfileLink.
  ///
  /// In en, this message translates to:
  /// **'YOUR PROFILE LINK'**
  String get shareProfileYourProfileLink;

  /// No description provided for @shareProfileLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link Copied!'**
  String get shareProfileLinkCopied;

  /// No description provided for @shareProfileQuickShare.
  ///
  /// In en, this message translates to:
  /// **'QUICK SHARE'**
  String get shareProfileQuickShare;

  /// No description provided for @shareProfileLinkInfo.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this link can view your public profile. You can change your privacy settings anytime.'**
  String get shareProfileLinkInfo;

  /// No description provided for @drawerYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Your Journey'**
  String get drawerYourJourney;

  /// No description provided for @drawerNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get drawerNavigation;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get drawerAccount;

  /// No description provided for @drawerMoodHistory.
  ///
  /// In en, this message translates to:
  /// **'Mood History'**
  String get drawerMoodHistory;

  /// No description provided for @drawerSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved Places'**
  String get drawerSavedPlaces;

  /// No description provided for @drawerMyAgenda.
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get drawerMyAgenda;

  /// No description provided for @drawerMyBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get drawerMyBookings;

  /// No description provided for @drawerAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get drawerAppSettings;

  /// No description provided for @drawerNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get drawerNotifications;

  /// No description provided for @drawerLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get drawerLanguage;

  /// No description provided for @drawerHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get drawerHelpSupport;

  /// No description provided for @drawerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get drawerProfile;

  /// No description provided for @drawerLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get drawerLogOut;

  /// No description provided for @drawerErrorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get drawerErrorLoadingProfile;

  /// No description provided for @drawerErrorSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Error signing out: {error}'**
  String drawerErrorSigningOut(String error);

  /// No description provided for @drawerNewExplorer.
  ///
  /// In en, this message translates to:
  /// **'New Explorer'**
  String get drawerNewExplorer;

  /// No description provided for @drawerMasterWanderer.
  ///
  /// In en, this message translates to:
  /// **'Master Wanderer'**
  String get drawerMasterWanderer;

  /// No description provided for @drawerAdventureExpert.
  ///
  /// In en, this message translates to:
  /// **'Adventure Expert'**
  String get drawerAdventureExpert;

  /// No description provided for @drawerSeasonedExplorer.
  ///
  /// In en, this message translates to:
  /// **'Seasoned Explorer'**
  String get drawerSeasonedExplorer;

  /// No description provided for @drawerTravelEnthusiast.
  ///
  /// In en, this message translates to:
  /// **'Travel Enthusiast'**
  String get drawerTravelEnthusiast;

  /// No description provided for @profileModeLocal.
  ///
  /// In en, this message translates to:
  /// **'Local Mode'**
  String get profileModeLocal;

  /// No description provided for @profileModeTravel.
  ///
  /// In en, this message translates to:
  /// **'Traveling'**
  String get profileModeTravel;

  /// No description provided for @profileModeWhatDoesThisDo.
  ///
  /// In en, this message translates to:
  /// **'What does this do?'**
  String get profileModeWhatDoesThisDo;

  /// No description provided for @profileModeSwitchToLocal.
  ///
  /// In en, this message translates to:
  /// **'Switch to Local Mode'**
  String get profileModeSwitchToLocal;

  /// No description provided for @profileModeSwitchToTravel.
  ///
  /// In en, this message translates to:
  /// **'Switch to Travel Mode'**
  String get profileModeSwitchToTravel;

  /// No description provided for @profileModeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileModeCancel;

  /// No description provided for @profileModeChangeAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime'**
  String get profileModeChangeAnytime;

  /// No description provided for @profileModeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Mode Updated!'**
  String get profileModeUpdated;

  /// No description provided for @profileModeUpdating.
  ///
  /// In en, this message translates to:
  /// **'Your recommendations are updating...'**
  String get profileModeUpdating;

  /// No description provided for @profileModeTravelModesExplained.
  ///
  /// In en, this message translates to:
  /// **'Travel Modes Explained'**
  String get profileModeTravelModesExplained;

  /// No description provided for @profileModeLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Mode'**
  String get profileModeLocalTitle;

  /// No description provided for @profileModeLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'Discovering hidden gems in your neighborhood'**
  String get profileModeLocalDescription;

  /// No description provided for @profileModeLocalFeature1.
  ///
  /// In en, this message translates to:
  /// **'Local cafes & hidden spots'**
  String get profileModeLocalFeature1;

  /// No description provided for @profileModeLocalFeature2.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood favorites'**
  String get profileModeLocalFeature2;

  /// No description provided for @profileModeLocalFeature3.
  ///
  /// In en, this message translates to:
  /// **'Less touristy places'**
  String get profileModeLocalFeature3;

  /// No description provided for @profileModeTravelTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Mode'**
  String get profileModeTravelTitle;

  /// No description provided for @profileModeTravelDescription.
  ///
  /// In en, this message translates to:
  /// **'Explore must-see attractions as a traveler'**
  String get profileModeTravelDescription;

  /// No description provided for @profileModeTravelFeature1.
  ///
  /// In en, this message translates to:
  /// **'Famous landmarks'**
  String get profileModeTravelFeature1;

  /// No description provided for @profileModeTravelFeature2.
  ///
  /// In en, this message translates to:
  /// **'Must-see attractions'**
  String get profileModeTravelFeature2;

  /// No description provided for @profileModeTravelFeature3.
  ///
  /// In en, this message translates to:
  /// **'Tourist-friendly spots'**
  String get profileModeTravelFeature3;

  /// No description provided for @profileModeLocalExplainer.
  ///
  /// In en, this message translates to:
  /// **'Perfect for when you\'re at home or exploring your own city. Discover places locals love!'**
  String get profileModeLocalExplainer;

  /// No description provided for @profileModeLocalExample.
  ///
  /// In en, this message translates to:
  /// **'Example: Instead of the Eiffel Tower, you\'ll see the cozy boulangerie around the corner that Parisians actually go to.'**
  String get profileModeLocalExample;

  /// No description provided for @profileModeTravelExplainer.
  ///
  /// In en, this message translates to:
  /// **'Perfect for when you\'re traveling or visiting a new city. See all the iconic spots!'**
  String get profileModeTravelExplainer;

  /// No description provided for @profileModeTravelExample.
  ///
  /// In en, this message translates to:
  /// **'Example: In Paris, you\'ll see the Eiffel Tower, Louvre Museum, and Arc de Triomphe - all the classics!'**
  String get profileModeTravelExample;

  /// No description provided for @profileModeSwitchAnytime.
  ///
  /// In en, this message translates to:
  /// **'Switch between modes anytime! Going on vacation? Switch to Travel Mode. Back home? Switch to Local Mode. Your recommendations adapt instantly!'**
  String get profileModeSwitchAnytime;

  /// No description provided for @profileModeGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get profileModeGotIt;

  /// No description provided for @profileModeProTip.
  ///
  /// In en, this message translates to:
  /// **'Pro Tip'**
  String get profileModeProTip;

  /// No description provided for @profileModeLocalGem1.
  ///
  /// In en, this message translates to:
  /// **'Hidden neighborhood gems'**
  String get profileModeLocalGem1;

  /// No description provided for @profileModeLocalGem2.
  ///
  /// In en, this message translates to:
  /// **'Local cafes & restaurants'**
  String get profileModeLocalGem2;

  /// No description provided for @profileModeLocalGem3.
  ///
  /// In en, this message translates to:
  /// **'Less crowded spots'**
  String get profileModeLocalGem3;

  /// No description provided for @profileModeLocalGem4.
  ///
  /// In en, this message translates to:
  /// **'Authentic local experiences'**
  String get profileModeLocalGem4;

  /// No description provided for @profileModeTravelSpot1.
  ///
  /// In en, this message translates to:
  /// **'Famous landmarks & attractions'**
  String get profileModeTravelSpot1;

  /// No description provided for @profileModeTravelSpot2.
  ///
  /// In en, this message translates to:
  /// **'Must-see tourist spots'**
  String get profileModeTravelSpot2;

  /// No description provided for @profileModeTravelSpot3.
  ///
  /// In en, this message translates to:
  /// **'Popular destinations'**
  String get profileModeTravelSpot3;

  /// No description provided for @profileModeTravelSpot4.
  ///
  /// In en, this message translates to:
  /// **'Tourist-friendly locations'**
  String get profileModeTravelSpot4;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsSectionDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get settingsSectionDiscovery;

  /// No description provided for @settingsSectionDataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get settingsSectionDataPrivacy;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable push notifications'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsLocationTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Tracking'**
  String get settingsLocationTrackingTitle;

  /// No description provided for @settingsLocationTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow app to track your location'**
  String get settingsLocationTrackingSubtitle;

  /// No description provided for @settingsDarkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkModeTitle;

  /// No description provided for @settingsDarkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme throughout the app'**
  String get settingsDarkModeSubtitle;

  /// No description provided for @settingsDiscoveryRadiusTitle.
  ///
  /// In en, this message translates to:
  /// **'Discovery Radius'**
  String get settingsDiscoveryRadiusTitle;

  /// No description provided for @settingsDiscoveryRadiusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show places within {distance} km'**
  String settingsDiscoveryRadiusSubtitle(String distance);

  /// No description provided for @settingsClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear App Cache'**
  String get settingsClearCacheTitle;

  /// No description provided for @settingsClearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free up space by removing cached images and data'**
  String get settingsClearCacheSubtitle;

  /// No description provided for @settingsPrivacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicyTitle;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsTermsOfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfServiceTitle;

  /// No description provided for @settingsTermsOfServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read our terms of service'**
  String get settingsTermsOfServiceSubtitle;

  /// No description provided for @settingsSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get settingsSaveButton;

  /// No description provided for @settingsClearCacheDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache?'**
  String get settingsClearCacheDialogTitle;

  /// No description provided for @settingsClearCacheDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove all cached data. Your saved places and settings will not be affected.'**
  String get settingsClearCacheDialogBody;

  /// No description provided for @settingsDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsDialogCancel;

  /// No description provided for @settingsDialogConfirmClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsDialogConfirmClear;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get settingsCacheCleared;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @settingsHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsHubTitle;

  /// No description provided for @settingsQuickTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Tip'**
  String get settingsQuickTipTitle;

  /// No description provided for @settingsQuickTipBody.
  ///
  /// In en, this message translates to:
  /// **'To edit your profile or preferences, go back to your profile screen!'**
  String get settingsQuickTipBody;

  /// No description provided for @settingsSectionPrivacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get settingsSectionPrivacySecurity;

  /// No description provided for @settingsSectionAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsSectionAppSettings;

  /// No description provided for @settingsSectionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get settingsSectionMore;

  /// No description provided for @settingsSectionDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get settingsSectionDangerZone;

  /// No description provided for @settingsAccountSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get settingsAccountSecurityTitle;

  /// No description provided for @settingsAccountSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Password, 2FA'**
  String get settingsAccountSecuritySubtitle;

  /// No description provided for @settingsTwoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get settingsTwoFactorTitle;

  /// No description provided for @settingsTwoFactorEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settingsTwoFactorEnabled;

  /// No description provided for @settingsTwoFactorNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Not enabled'**
  String get settingsTwoFactorNotEnabled;

  /// No description provided for @settingsTwoFactorBadgeRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get settingsTwoFactorBadgeRecommended;

  /// No description provided for @settingsActiveSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get settingsActiveSessionsTitle;

  /// No description provided for @settingsActiveSessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} devices'**
  String settingsActiveSessionsSubtitle(String count);

  /// No description provided for @activeSessionsNoActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No active sessions'**
  String get activeSessionsNoActiveTitle;

  /// No description provided for @activeSessionsNoActiveBody.
  ///
  /// In en, this message translates to:
  /// **'You are not signed in on any devices.'**
  String get activeSessionsNoActiveBody;

  /// No description provided for @activeSessionsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Active Session{count, plural, one{} other{s}}'**
  String activeSessionsCountLabel(int count);

  /// No description provided for @activeSessionsSignOutAllOther.
  ///
  /// In en, this message translates to:
  /// **'Sign Out All Other Devices'**
  String get activeSessionsSignOutAllOther;

  /// No description provided for @activeSessionsUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown Device'**
  String get activeSessionsUnknownDevice;

  /// No description provided for @activeSessionsCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get activeSessionsCurrentBadge;

  /// No description provided for @activeSessionsUnknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get activeSessionsUnknownLocation;

  /// No description provided for @activeSessionsSignOutThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Sign out this device'**
  String get activeSessionsSignOutThisDevice;

  /// No description provided for @activeSessionsErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading sessions'**
  String get activeSessionsErrorLoading;

  /// No description provided for @activeSessionsTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get activeSessionsTimeJustNow;

  /// No description provided for @activeSessionsTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hour{count, plural, one{} other{s}} ago'**
  String activeSessionsTimeHoursAgo(int count);

  /// No description provided for @activeSessionsTimeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get activeSessionsTimeYesterday;

  /// No description provided for @activeSessionsTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String activeSessionsTimeDaysAgo(int count);

  /// No description provided for @activeSessionsTimeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} week{count, plural, one{} other{s}} ago'**
  String activeSessionsTimeWeeksAgo(int count);

  /// No description provided for @activeSessionsDialogSignOutDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out Device'**
  String get activeSessionsDialogSignOutDeviceTitle;

  /// No description provided for @activeSessionsDialogSignOutDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out from {device}?'**
  String activeSessionsDialogSignOutDeviceBody(String device);

  /// No description provided for @activeSessionsDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get activeSessionsDialogCancel;

  /// No description provided for @activeSessionsDialogSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get activeSessionsDialogSignOut;

  /// No description provided for @activeSessionsToastSignedOutDevice.
  ///
  /// In en, this message translates to:
  /// **'Device signed out successfully'**
  String get activeSessionsToastSignedOutDevice;

  /// No description provided for @activeSessionsToastSignOutDeviceError.
  ///
  /// In en, this message translates to:
  /// **'Error signing out device: {error}'**
  String activeSessionsToastSignOutDeviceError(String error);

  /// No description provided for @activeSessionsDialogSignOutAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out All Other Devices'**
  String get activeSessionsDialogSignOutAllTitle;

  /// No description provided for @activeSessionsDialogSignOutAllBody.
  ///
  /// In en, this message translates to:
  /// **'This will sign you out from all devices except this one. Are you sure?'**
  String get activeSessionsDialogSignOutAllBody;

  /// No description provided for @activeSessionsDialogSignOutAllCta.
  ///
  /// In en, this message translates to:
  /// **'Sign Out All'**
  String get activeSessionsDialogSignOutAllCta;

  /// No description provided for @activeSessionsToastSignedOutAll.
  ///
  /// In en, this message translates to:
  /// **'All other devices signed out successfully'**
  String get activeSessionsToastSignedOutAll;

  /// No description provided for @activeSessionsToastSignOutAllError.
  ///
  /// In en, this message translates to:
  /// **'Error signing out devices: {error}'**
  String activeSessionsToastSignOutAllError(String error);

  /// No description provided for @twoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorTitle;

  /// No description provided for @twoFactorEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'2FA is Enabled'**
  String get twoFactorEnabledTitle;

  /// No description provided for @twoFactorDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Two-Factor Authentication'**
  String get twoFactorDisabledTitle;

  /// No description provided for @twoFactorEnabledBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is protected with two-factor authentication.'**
  String get twoFactorEnabledBody;

  /// No description provided for @twoFactorDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security to your account by requiring a verification code in addition to your password.'**
  String get twoFactorDisabledBody;

  /// No description provided for @twoFactorBenefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Benefits:'**
  String get twoFactorBenefitsTitle;

  /// No description provided for @twoFactorBenefitUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Protects against unauthorized access'**
  String get twoFactorBenefitUnauthorized;

  /// No description provided for @twoFactorBenefitSensitiveOps.
  ///
  /// In en, this message translates to:
  /// **'Required for sensitive operations'**
  String get twoFactorBenefitSensitiveOps;

  /// No description provided for @twoFactorBenefitLoginAlerts.
  ///
  /// In en, this message translates to:
  /// **'Get notified of login attempts'**
  String get twoFactorBenefitLoginAlerts;

  /// No description provided for @twoFactorDisableCta.
  ///
  /// In en, this message translates to:
  /// **'Disable 2FA'**
  String get twoFactorDisableCta;

  /// No description provided for @twoFactorEnableCta.
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA'**
  String get twoFactorEnableCta;

  /// No description provided for @twoFactorDisableInfo.
  ///
  /// In en, this message translates to:
  /// **'To disable 2FA, you will need to verify your identity.'**
  String get twoFactorDisableInfo;

  /// No description provided for @twoFactorEnableInfo.
  ///
  /// In en, this message translates to:
  /// **'You will need an authenticator app (like Google Authenticator) to set up 2FA.'**
  String get twoFactorEnableInfo;

  /// No description provided for @twoFactorToastSetupStarted.
  ///
  /// In en, this message translates to:
  /// **'2FA setup started. Please complete the setup process.'**
  String get twoFactorToastSetupStarted;

  /// No description provided for @twoFactorToastDisabled.
  ///
  /// In en, this message translates to:
  /// **'2FA has been disabled.'**
  String get twoFactorToastDisabled;

  /// No description provided for @twoFactorToastError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String twoFactorToastError(String error);

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile visibility, data'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsHubNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Push, email, in-app'**
  String get settingsHubNotificationsSubtitle;

  /// No description provided for @settingsLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settingsLocationLabel;

  /// No description provided for @settingsLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect, permissions'**
  String get settingsLocationSubtitle;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeLabel;

  /// No description provided for @settingsThemeValueSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeValueSystem;

  /// No description provided for @settingsAchievementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get settingsAchievementsLabel;

  /// No description provided for @settingsAchievementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} unlocked'**
  String settingsAchievementsSubtitle(String count);

  /// No description provided for @settingsSubscriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscriptionLabel;

  /// No description provided for @settingsSubscriptionSubtitleFree.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get settingsSubscriptionSubtitleFree;

  /// No description provided for @settingsSubscriptionBadgeFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get settingsSubscriptionBadgeFree;

  /// No description provided for @settingsDataStorageLabel.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get settingsDataStorageLabel;

  /// No description provided for @settingsDataStorageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export, clear cache'**
  String get settingsDataStorageSubtitle;

  /// No description provided for @settingsHelpSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelpSupportLabel;

  /// No description provided for @settingsHelpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ, contact us'**
  String get settingsHelpSupportSubtitle;

  /// No description provided for @settingsDangerDeleteAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDangerDeleteAccountLabel;

  /// No description provided for @settingsDangerDeleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your data'**
  String get settingsDangerDeleteAccountSubtitle;

  /// No description provided for @settingsDangerSignOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsDangerSignOutLabel;

  /// No description provided for @settingsDangerSignOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of your account'**
  String get settingsDangerSignOutSubtitle;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'WanderMood v{version}'**
  String settingsAppVersion(String version);

  /// No description provided for @settingsAppTagline.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ for travelers'**
  String get settingsAppTagline;

  /// No description provided for @settingsSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOutTitle;

  /// No description provided for @settingsSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsSignOutMessage;

  /// No description provided for @settingsSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOutConfirm;

  /// No description provided for @settingsOpenPrivacyNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open Privacy Policy. Please check your internet connection.'**
  String get settingsOpenPrivacyNetworkError;

  /// No description provided for @settingsOpenPrivacyError.
  ///
  /// In en, this message translates to:
  /// **'Error opening Privacy Policy: {error}'**
  String settingsOpenPrivacyError(String error);

  /// No description provided for @settingsOpenTermsNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open Terms of Service. Please check your internet connection.'**
  String get settingsOpenTermsNetworkError;

  /// No description provided for @settingsOpenTermsError.
  ///
  /// In en, this message translates to:
  /// **'Error opening Terms of Service: {error}'**
  String settingsOpenTermsError(String error);

  /// No description provided for @notificationsMethodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Methods'**
  String get notificationsMethodsTitle;

  /// No description provided for @notificationsPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get notificationsPushTitle;

  /// No description provided for @notificationsPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications on this device'**
  String get notificationsPushSubtitle;

  /// No description provided for @notificationsEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get notificationsEmailTitle;

  /// No description provided for @notificationsEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive updates via email'**
  String get notificationsEmailSubtitle;

  /// No description provided for @notificationsInAppTitle.
  ///
  /// In en, this message translates to:
  /// **'In-App Notifications'**
  String get notificationsInAppTitle;

  /// No description provided for @notificationsInAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See notifications inside the app'**
  String get notificationsInAppSubtitle;

  /// No description provided for @notificationsWhatToNotifyTitle.
  ///
  /// In en, this message translates to:
  /// **'What to Notify'**
  String get notificationsWhatToNotifyTitle;

  /// No description provided for @notificationsNewActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'New Activities'**
  String get notificationsNewActivitiesTitle;

  /// No description provided for @notificationsNewActivitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When new activities match your vibe'**
  String get notificationsNewActivitiesSubtitle;

  /// No description provided for @notificationsNearbyEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Events'**
  String get notificationsNearbyEventsTitle;

  /// No description provided for @notificationsNearbyEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Events happening around you'**
  String get notificationsNearbyEventsSubtitle;

  /// No description provided for @notificationsFriendActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend Activity'**
  String get notificationsFriendActivityTitle;

  /// No description provided for @notificationsFriendActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When friends share or like something'**
  String get notificationsFriendActivitySubtitle;

  /// No description provided for @locationScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationScreenTitle;

  /// No description provided for @locationCurrentLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get locationCurrentLocationTitle;

  /// No description provided for @locationCurrentLocationValue.
  ///
  /// In en, this message translates to:
  /// **'Rotterdam, Netherlands'**
  String get locationCurrentLocationValue;

  /// No description provided for @locationSectionSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Settings'**
  String get locationSectionSettingsTitle;

  /// No description provided for @locationAutoDetectTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-Detect Location'**
  String get locationAutoDetectTitle;

  /// No description provided for @locationAutoDetectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically detect your current location'**
  String get locationAutoDetectSubtitle;

  /// No description provided for @locationSectionDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Default Location'**
  String get locationSectionDefaultTitle;

  /// No description provided for @locationDefaultCityLabel.
  ///
  /// In en, this message translates to:
  /// **'Rotterdam'**
  String get locationDefaultCityLabel;

  /// No description provided for @locationDefaultUsedWhenOff.
  ///
  /// In en, this message translates to:
  /// **'Used when location is off'**
  String get locationDefaultUsedWhenOff;

  /// No description provided for @locationPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Permissions'**
  String get locationPermissionsTitle;

  /// No description provided for @locationPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage in system settings'**
  String get locationPermissionsSubtitle;

  /// No description provided for @locationSnackbarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location settings updated'**
  String get locationSnackbarUpdated;

  /// No description provided for @locationSnackbarError.
  ///
  /// In en, this message translates to:
  /// **'Error updating location settings: {error}'**
  String locationSnackbarError(String error);

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// No description provided for @subscriptionScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionScreenTitle;

  /// No description provided for @subscriptionCurrentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get subscriptionCurrentPlanLabel;

  /// No description provided for @subscriptionPlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get subscriptionPlanFree;

  /// No description provided for @subscriptionPlanPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get subscriptionPlanPremium;

  /// No description provided for @subscriptionUpgradeHeading.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get subscriptionUpgradeHeading;

  /// No description provided for @subscriptionUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get subscriptionUpgradeTitle;

  /// No description provided for @subscriptionFeatureUnlimitedSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Unlimited activity suggestions'**
  String get subscriptionFeatureUnlimitedSuggestions;

  /// No description provided for @subscriptionFeatureAdvancedMoodMatching.
  ///
  /// In en, this message translates to:
  /// **'Advanced mood matching'**
  String get subscriptionFeatureAdvancedMoodMatching;

  /// No description provided for @subscriptionFeaturePrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get subscriptionFeaturePrioritySupport;

  /// No description provided for @subscriptionFeatureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get subscriptionFeatureNoAds;

  /// No description provided for @subscriptionFeatureEarlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Early access to new features'**
  String get subscriptionFeatureEarlyAccess;

  /// No description provided for @subscriptionUpgradeCta.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get subscriptionUpgradeCta;

  /// No description provided for @subscriptionUpgradeFootnote.
  ///
  /// In en, this message translates to:
  /// **'Paid plans will use Apple In-App Purchase when available. This version is free — no payment is collected in the app.'**
  String get subscriptionUpgradeFootnote;

  /// No description provided for @dataStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get dataStorageTitle;

  /// No description provided for @dataStorageStorageUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage Used'**
  String get dataStorageStorageUsedLabel;

  /// No description provided for @dataStorageExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get dataStorageExportTitle;

  /// No description provided for @dataStorageExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download all your data (GDPR)'**
  String get dataStorageExportSubtitle;

  /// No description provided for @dataStorageClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get dataStorageClearCacheTitle;

  /// No description provided for @dataStorageClearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free up storage space'**
  String get dataStorageClearCacheSubtitle;

  /// No description provided for @dataStorageDownloadHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Download History'**
  String get dataStorageDownloadHistoryTitle;

  /// No description provided for @dataStorageDownloadHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View past exports'**
  String get dataStorageDownloadHistorySubtitle;

  /// No description provided for @dataStorageExportFileTitle.
  ///
  /// In en, this message translates to:
  /// **'My WanderMood Data Export'**
  String get dataStorageExportFileTitle;

  /// No description provided for @dataStorageExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully'**
  String get dataStorageExportSuccess;

  /// No description provided for @dataStorageExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String dataStorageExportFailed(String error);

  /// No description provided for @dataStorageCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get dataStorageCacheCleared;

  /// No description provided for @dataStorageCacheFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear cache: {error}'**
  String dataStorageCacheFailed(String error);

  /// No description provided for @helpSupportScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportScreenTitle;

  /// No description provided for @helpSupportSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search help articles...'**
  String get helpSupportSearchHint;

  /// No description provided for @helpSupportQuickLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get helpSupportQuickLinksTitle;

  /// No description provided for @helpSupportFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get helpSupportFaqTitle;

  /// No description provided for @helpSupportFaqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get helpSupportFaqSubtitle;

  /// No description provided for @helpSupportContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get helpSupportContactTitle;

  /// No description provided for @helpSupportContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send us an email'**
  String get helpSupportContactSubtitle;

  /// No description provided for @helpSupportLiveChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get helpSupportLiveChatTitle;

  /// No description provided for @helpSupportLiveChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with support'**
  String get helpSupportLiveChatSubtitle;

  /// No description provided for @helpSupportLiveChatBadgeOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get helpSupportLiveChatBadgeOnline;

  /// No description provided for @helpSupportReportBugTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get helpSupportReportBugTitle;

  /// No description provided for @helpSupportReportBugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve'**
  String get helpSupportReportBugSubtitle;

  /// No description provided for @helpSupportLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get helpSupportLegalTitle;

  /// No description provided for @helpSupportPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get helpSupportPrivacyTitle;

  /// No description provided for @helpSupportPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we protect your data'**
  String get helpSupportPrivacySubtitle;

  /// No description provided for @helpSupportTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get helpSupportTermsTitle;

  /// No description provided for @helpSupportTermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and conditions'**
  String get helpSupportTermsSubtitle;

  /// No description provided for @helpSupportEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'info@wandermood.com'**
  String get helpSupportEmailAddress;

  /// No description provided for @helpSupportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'WanderMood Support'**
  String get helpSupportEmailSubject;

  /// No description provided for @helpSupportEmailSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get helpSupportEmailSupportTitle;

  /// No description provided for @settingsLocationChangeCta.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settingsLocationChangeCta;

  /// No description provided for @savedPlacesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get savedPlacesScreenTitle;

  /// No description provided for @savedPlacesTabAllSaved.
  ///
  /// In en, this message translates to:
  /// **'All saved'**
  String get savedPlacesTabAllSaved;

  /// No description provided for @savedPlacesTabCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get savedPlacesTabCollections;

  /// No description provided for @savedPlacesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet'**
  String get savedPlacesEmptyTitle;

  /// No description provided for @savedPlacesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon on any place in Explore to save it here.'**
  String get savedPlacesEmptyBody;

  /// No description provided for @savedPlacesHoldToCollect.
  ///
  /// In en, this message translates to:
  /// **'Hold to collect'**
  String get savedPlacesHoldToCollect;

  /// No description provided for @savedPlacesSavedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Saved {when}'**
  String savedPlacesSavedPrefix(String when);

  /// No description provided for @savedPlacesTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get savedPlacesTimeJustNow;

  /// No description provided for @savedPlacesTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String savedPlacesTimeHoursAgo(int count);

  /// No description provided for @savedPlacesTimeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get savedPlacesTimeYesterday;

  /// No description provided for @savedPlacesTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String savedPlacesTimeDaysAgo(int count);

  /// No description provided for @savedPlacesPlaceCountOne.
  ///
  /// In en, this message translates to:
  /// **'{count} place'**
  String savedPlacesPlaceCountOne(int count);

  /// No description provided for @savedPlacesPlaceCountMany.
  ///
  /// In en, this message translates to:
  /// **'{count} places'**
  String savedPlacesPlaceCountMany(int count);

  /// No description provided for @savedPlacesNewCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get savedPlacesNewCollection;

  /// No description provided for @savedPlacesNewCollectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Group your saves'**
  String get savedPlacesNewCollectionSubtitle;

  /// No description provided for @savedPlacesAddToCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get savedPlacesAddToCollectionTitle;

  /// No description provided for @savedPlacesNoCollectionsHint.
  ///
  /// In en, this message translates to:
  /// **'No collections yet. Create one in the Collections tab.'**
  String get savedPlacesNoCollectionsHint;

  /// No description provided for @savedPlacesPlacesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} places'**
  String savedPlacesPlacesCount(int count);

  /// No description provided for @savedPlacesAddedToCollection.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String savedPlacesAddedToCollection(String name);

  /// No description provided for @savedPlacesActionAddToMyDay.
  ///
  /// In en, this message translates to:
  /// **'Add to My Day'**
  String get savedPlacesActionAddToMyDay;

  /// No description provided for @savedPlacesActionAddToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get savedPlacesActionAddToCollection;

  /// No description provided for @savedPlacesActionViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get savedPlacesActionViewDetails;

  /// No description provided for @savedPlacesPlanSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to My Day'**
  String get savedPlacesPlanSheetTitle;

  /// No description provided for @savedPlacesPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get savedPlacesPickDate;

  /// No description provided for @savedPlacesSelectedDate.
  ///
  /// In en, this message translates to:
  /// **'Selected: {date}'**
  String savedPlacesSelectedDate(String date);

  /// No description provided for @locationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get locationPickerTitle;

  /// No description provided for @locationPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a city or location…'**
  String get locationPickerSearchHint;

  /// No description provided for @locationPickerEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search for a location'**
  String get locationPickerEmptyPrompt;

  /// No description provided for @locationPickerNoResults.
  ///
  /// In en, this message translates to:
  /// **'No locations found'**
  String get locationPickerNoResults;

  /// No description provided for @locationPickerToastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated to {place}'**
  String locationPickerToastUpdated(String place);

  /// No description provided for @locationPickerToastError.
  ///
  /// In en, this message translates to:
  /// **'Error saving location: {error}'**
  String locationPickerToastError(String error);

  /// No description provided for @settingsPrivacyScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyScreenTitle;

  /// No description provided for @privacyProfileVisibilitySection.
  ///
  /// In en, this message translates to:
  /// **'Profile visibility'**
  String get privacyProfileVisibilitySection;

  /// No description provided for @privacyVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get privacyVisibilityPublic;

  /// No description provided for @privacyVisibilityPublicSub.
  ///
  /// In en, this message translates to:
  /// **'Anyone can see your profile'**
  String get privacyVisibilityPublicSub;

  /// No description provided for @privacyVisibilityFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends only'**
  String get privacyVisibilityFriends;

  /// No description provided for @privacyVisibilityFriendsSub.
  ///
  /// In en, this message translates to:
  /// **'Only your friends can see'**
  String get privacyVisibilityFriendsSub;

  /// No description provided for @privacyVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privacyVisibilityPrivate;

  /// No description provided for @privacyVisibilityPrivateSub.
  ///
  /// In en, this message translates to:
  /// **'Only you can see'**
  String get privacyVisibilityPrivateSub;

  /// No description provided for @privacyWhatOthersSeeSection.
  ///
  /// In en, this message translates to:
  /// **'What others can see'**
  String get privacyWhatOthersSeeSection;

  /// No description provided for @privacyShowEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Show email address'**
  String get privacyShowEmailLabel;

  /// No description provided for @privacyShowAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Show age'**
  String get privacyShowAgeLabel;

  /// No description provided for @privacyToastVisibilityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile visibility updated'**
  String get privacyToastVisibilityUpdated;

  /// No description provided for @privacyToastError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String privacyToastError(String error);

  /// No description provided for @privacyToastEmailVisible.
  ///
  /// In en, this message translates to:
  /// **'Email will be visible to others'**
  String get privacyToastEmailVisible;

  /// No description provided for @privacyToastEmailHidden.
  ///
  /// In en, this message translates to:
  /// **'Email is now hidden'**
  String get privacyToastEmailHidden;

  /// No description provided for @privacyToastAgeVisible.
  ///
  /// In en, this message translates to:
  /// **'Age will be visible to others'**
  String get privacyToastAgeVisible;

  /// No description provided for @privacyToastAgeHidden.
  ///
  /// In en, this message translates to:
  /// **'Age is now hidden'**
  String get privacyToastAgeHidden;

  /// No description provided for @languageNameEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @languageNativeEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNativeEn;

  /// No description provided for @languageNameNl.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get languageNameNl;

  /// No description provided for @languageNativeNl.
  ///
  /// In en, this message translates to:
  /// **'Nederlands'**
  String get languageNativeNl;

  /// No description provided for @languageNameEs.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageNameEs;

  /// No description provided for @languageNativeEs.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageNativeEs;

  /// No description provided for @languageNameFr.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageNameFr;

  /// No description provided for @languageNativeFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageNativeFr;

  /// No description provided for @languageNameDe.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageNameDe;

  /// No description provided for @languageNativeDe.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageNativeDe;

  /// No description provided for @languageNameIt.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageNameIt;

  /// No description provided for @languageNativeIt.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageNativeIt;

  /// No description provided for @prefCommunicationTitle.
  ///
  /// In en, this message translates to:
  /// **'How should I talk to you? 💬'**
  String get prefCommunicationTitle;

  /// No description provided for @prefCommunicationIntro.
  ///
  /// In en, this message translates to:
  /// **'To make our journey together more enjoyable, I\'d love to know how you prefer me to communicate with you.'**
  String get prefCommunicationIntro;

  /// No description provided for @prefCommunicationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps me adjust my tone and style to match your preferences perfectly! 🎯'**
  String get prefCommunicationSubtitle;

  /// No description provided for @prefStyleFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get prefStyleFriendly;

  /// No description provided for @prefStyleFriendlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Casual and warm communication'**
  String get prefStyleFriendlyDesc;

  /// No description provided for @prefStyleProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get prefStyleProfessional;

  /// No description provided for @prefStyleProfessionalDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear and formal communication'**
  String get prefStyleProfessionalDesc;

  /// No description provided for @prefStyleEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get prefStyleEnergetic;

  /// No description provided for @prefStyleEnergeticDesc.
  ///
  /// In en, this message translates to:
  /// **'Fun and enthusiastic communication'**
  String get prefStyleEnergeticDesc;

  /// No description provided for @prefStyleDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get prefStyleDirect;

  /// No description provided for @prefStyleDirectDesc.
  ///
  /// In en, this message translates to:
  /// **'Straight to the point'**
  String get prefStyleDirectDesc;

  /// No description provided for @prefMoodAdventurous.
  ///
  /// In en, this message translates to:
  /// **'Adventurous'**
  String get prefMoodAdventurous;

  /// No description provided for @prefMoodPeaceful.
  ///
  /// In en, this message translates to:
  /// **'Peaceful'**
  String get prefMoodPeaceful;

  /// No description provided for @prefMoodSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get prefMoodSocial;

  /// No description provided for @prefMoodCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get prefMoodCultural;

  /// No description provided for @prefMoodFoody.
  ///
  /// In en, this message translates to:
  /// **'Foody'**
  String get prefMoodFoody;

  /// No description provided for @prefMoodSpontaneous.
  ///
  /// In en, this message translates to:
  /// **'Spontaneous'**
  String get prefMoodSpontaneous;

  /// No description provided for @prefMoodTitleFriendly.
  ///
  /// In en, this message translates to:
  /// **'What\'s your travel mood? 😊'**
  String get prefMoodTitleFriendly;

  /// No description provided for @prefMoodTitleEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Let\'s sync our vibes! ✨'**
  String get prefMoodTitleEnergetic;

  /// No description provided for @prefMoodTitleProfessional.
  ///
  /// In en, this message translates to:
  /// **'Travel Mood Preferences'**
  String get prefMoodTitleProfessional;

  /// No description provided for @prefMoodTitleDirect.
  ///
  /// In en, this message translates to:
  /// **'Select your moods'**
  String get prefMoodTitleDirect;

  /// No description provided for @prefMoodSubtitleFriendly.
  ///
  /// In en, this message translates to:
  /// **'What inspires you to get out and explore?'**
  String get prefMoodSubtitleFriendly;

  /// No description provided for @prefMoodSubtitleEnergetic.
  ///
  /// In en, this message translates to:
  /// **'What moods inspire you to explore?'**
  String get prefMoodSubtitleEnergetic;

  /// No description provided for @prefMoodSubtitleProfessional.
  ///
  /// In en, this message translates to:
  /// **'What type of experiences appeal to you most?'**
  String get prefMoodSubtitleProfessional;

  /// No description provided for @prefMoodSubtitleDirect.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred experience types:'**
  String get prefMoodSubtitleDirect;

  /// No description provided for @prefMultipleHintFriendly.
  ///
  /// In en, this message translates to:
  /// **'You can select multiple options ✨'**
  String get prefMultipleHintFriendly;

  /// No description provided for @prefMultipleHintEnergetic.
  ///
  /// In en, this message translates to:
  /// **'You can pick multiple - go wild! ✨'**
  String get prefMultipleHintEnergetic;

  /// No description provided for @prefMultipleHintProfessional.
  ///
  /// In en, this message translates to:
  /// **'Multiple selections are permitted'**
  String get prefMultipleHintProfessional;

  /// No description provided for @prefMultipleHintDirect.
  ///
  /// In en, this message translates to:
  /// **'Multiple selections allowed'**
  String get prefMultipleHintDirect;

  /// No description provided for @prefInterestStays.
  ///
  /// In en, this message translates to:
  /// **'Stays & Getaways'**
  String get prefInterestStays;

  /// No description provided for @prefInterestStaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Charming hotels and dreamy places'**
  String get prefInterestStaysDesc;

  /// No description provided for @prefInterestFood.
  ///
  /// In en, this message translates to:
  /// **'Food & Drink'**
  String get prefInterestFood;

  /// No description provided for @prefInterestFoodDesc.
  ///
  /// In en, this message translates to:
  /// **'Local cuisine and unique restaurants'**
  String get prefInterestFoodDesc;

  /// No description provided for @prefInterestArts.
  ///
  /// In en, this message translates to:
  /// **'Arts & Culture'**
  String get prefInterestArts;

  /// No description provided for @prefInterestArtsDesc.
  ///
  /// In en, this message translates to:
  /// **'Museums, galleries, and theaters'**
  String get prefInterestArtsDesc;

  /// No description provided for @prefInterestShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get prefInterestShopping;

  /// No description provided for @prefInterestShoppingDesc.
  ///
  /// In en, this message translates to:
  /// **'Local markets and shopping districts'**
  String get prefInterestShoppingDesc;

  /// No description provided for @prefInterestSports.
  ///
  /// In en, this message translates to:
  /// **'Sports & Activities'**
  String get prefInterestSports;

  /// No description provided for @prefInterestSportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Active experiences and sports venues'**
  String get prefInterestSportsDesc;

  /// No description provided for @prefInterestsTitleFriendly.
  ///
  /// In en, this message translates to:
  /// **'What catches your interest? 🌟'**
  String get prefInterestsTitleFriendly;

  /// No description provided for @prefInterestsTitleEnergetic.
  ///
  /// In en, this message translates to:
  /// **'What gets you hyped? 🔥'**
  String get prefInterestsTitleEnergetic;

  /// No description provided for @prefInterestsTitleProfessional.
  ///
  /// In en, this message translates to:
  /// **'Travel Interest Categories'**
  String get prefInterestsTitleProfessional;

  /// No description provided for @prefInterestsTitleDirect.
  ///
  /// In en, this message translates to:
  /// **'Select interests'**
  String get prefInterestsTitleDirect;

  /// No description provided for @prefInterestsSubtitleFriendly.
  ///
  /// In en, this message translates to:
  /// **'Choose the activities that sound fun to you'**
  String get prefInterestsSubtitleFriendly;

  /// No description provided for @prefInterestsSubtitleEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Pick all the things that make your heart race!'**
  String get prefInterestsSubtitleEnergetic;

  /// No description provided for @prefInterestsSubtitleProfessional.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred activity categories'**
  String get prefInterestsSubtitleProfessional;

  /// No description provided for @prefInterestsSubtitleDirect.
  ///
  /// In en, this message translates to:
  /// **'Choose activity types:'**
  String get prefInterestsSubtitleDirect;

  /// No description provided for @prefTravelTitleFriendly.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your travel style ✈️'**
  String get prefTravelTitleFriendly;

  /// No description provided for @prefTravelTitleEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your travel style ✈️'**
  String get prefTravelTitleEnergetic;

  /// No description provided for @prefTravelTitleProfessional.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your travel style ✈️'**
  String get prefTravelTitleProfessional;

  /// No description provided for @prefTravelTitleDirect.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your travel style ✈️'**
  String get prefTravelTitleDirect;

  /// No description provided for @prefTravelSubtitleFriendly.
  ///
  /// In en, this message translates to:
  /// **'A few quick questions to personalize your experience'**
  String get prefTravelSubtitleFriendly;

  /// No description provided for @prefTravelSubtitleEnergetic.
  ///
  /// In en, this message translates to:
  /// **'A few quick questions to personalize your experience'**
  String get prefTravelSubtitleEnergetic;

  /// No description provided for @prefTravelSubtitleProfessional.
  ///
  /// In en, this message translates to:
  /// **'A few quick questions to personalize your experience'**
  String get prefTravelSubtitleProfessional;

  /// No description provided for @prefTravelSubtitleDirect.
  ///
  /// In en, this message translates to:
  /// **'A few quick questions to personalize your experience'**
  String get prefTravelSubtitleDirect;

  /// No description provided for @prefSectionTravelStyle.
  ///
  /// In en, this message translates to:
  /// **'Travel Style 🎯'**
  String get prefSectionTravelStyle;

  /// No description provided for @prefSelectUpToStyles.
  ///
  /// In en, this message translates to:
  /// **'Select up to {count} styles'**
  String prefSelectUpToStyles(int count);

  /// No description provided for @prefSocialSolo.
  ///
  /// In en, this message translates to:
  /// **'Solo Adventures'**
  String get prefSocialSolo;

  /// No description provided for @prefSocialSoloDesc.
  ///
  /// In en, this message translates to:
  /// **'Me time is the best time'**
  String get prefSocialSoloDesc;

  /// No description provided for @prefSocialSmallGroups.
  ///
  /// In en, this message translates to:
  /// **'Small Groups'**
  String get prefSocialSmallGroups;

  /// No description provided for @prefSocialSmallGroupsDesc.
  ///
  /// In en, this message translates to:
  /// **'Close friends, intimate vibes'**
  String get prefSocialSmallGroupsDesc;

  /// No description provided for @prefSocialButterfly.
  ///
  /// In en, this message translates to:
  /// **'Social Butterfly'**
  String get prefSocialButterfly;

  /// No description provided for @prefSocialButterflyDesc.
  ///
  /// In en, this message translates to:
  /// **'Love meeting new people'**
  String get prefSocialButterflyDesc;

  /// No description provided for @prefSocialMoodDependent.
  ///
  /// In en, this message translates to:
  /// **'Mood Dependent'**
  String get prefSocialMoodDependent;

  /// No description provided for @prefSocialMoodDependentDesc.
  ///
  /// In en, this message translates to:
  /// **'Sometimes solo, sometimes social'**
  String get prefSocialMoodDependentDesc;

  /// No description provided for @prefPaceRightNow.
  ///
  /// In en, this message translates to:
  /// **'Right Now Vibes'**
  String get prefPaceRightNow;

  /// No description provided for @prefPaceRightNowDesc.
  ///
  /// In en, this message translates to:
  /// **'What should I do right now?'**
  String get prefPaceRightNowDesc;

  /// No description provided for @prefPaceSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same Day Planner'**
  String get prefPaceSameDay;

  /// No description provided for @prefPaceSameDayDesc.
  ///
  /// In en, this message translates to:
  /// **'Plan in the morning for the day'**
  String get prefPaceSameDayDesc;

  /// No description provided for @prefPaceWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend Prepper'**
  String get prefPaceWeekend;

  /// No description provided for @prefPaceWeekendDesc.
  ///
  /// In en, this message translates to:
  /// **'Plan a few days ahead'**
  String get prefPaceWeekendDesc;

  /// No description provided for @prefPaceMaster.
  ///
  /// In en, this message translates to:
  /// **'Master Planner'**
  String get prefPaceMaster;

  /// No description provided for @prefPaceMasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Love planning weeks ahead'**
  String get prefPaceMasterDesc;

  /// No description provided for @prefTravelStyleSpontaneous.
  ///
  /// In en, this message translates to:
  /// **'Spontaneous'**
  String get prefTravelStyleSpontaneous;

  /// No description provided for @prefTravelStyleSpontaneousDesc.
  ///
  /// In en, this message translates to:
  /// **'Go with the flow, embrace surprises'**
  String get prefTravelStyleSpontaneousDesc;

  /// No description provided for @prefTravelStylePlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get prefTravelStylePlanned;

  /// No description provided for @prefTravelStylePlannedDesc.
  ///
  /// In en, this message translates to:
  /// **'Organized itineraries, scheduled visits'**
  String get prefTravelStylePlannedDesc;

  /// No description provided for @prefTravelStyleLocal.
  ///
  /// In en, this message translates to:
  /// **'Local Experience'**
  String get prefTravelStyleLocal;

  /// No description provided for @prefTravelStyleLocalDesc.
  ///
  /// In en, this message translates to:
  /// **'Live like a local, authentic spots'**
  String get prefTravelStyleLocalDesc;

  /// No description provided for @prefTravelStyleLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury Seeker'**
  String get prefTravelStyleLuxury;

  /// No description provided for @prefTravelStyleLuxuryDesc.
  ///
  /// In en, this message translates to:
  /// **'Premium experiences, high-end spots'**
  String get prefTravelStyleLuxuryDesc;

  /// No description provided for @prefTravelStyleBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget Conscious'**
  String get prefTravelStyleBudget;

  /// No description provided for @prefTravelStyleBudgetDesc.
  ///
  /// In en, this message translates to:
  /// **'Great value, smart spending'**
  String get prefTravelStyleBudgetDesc;

  /// No description provided for @prefTravelStyleTouristHighlights.
  ///
  /// In en, this message translates to:
  /// **'Tourist Highlights'**
  String get prefTravelStyleTouristHighlights;

  /// No description provided for @prefTravelStyleTouristHighlightsDesc.
  ///
  /// In en, this message translates to:
  /// **'Must-see attractions, popular spots'**
  String get prefTravelStyleTouristHighlightsDesc;

  /// No description provided for @prefTravelStyleOffBeatenPath.
  ///
  /// In en, this message translates to:
  /// **'Off the Beaten Path'**
  String get prefTravelStyleOffBeatenPath;

  /// No description provided for @prefTravelStyleOffBeatenPathDesc.
  ///
  /// In en, this message translates to:
  /// **'Hidden gems, unique experiences'**
  String get prefTravelStyleOffBeatenPathDesc;

  /// No description provided for @dayPlanTodayItinerary.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S ITINERARY'**
  String get dayPlanTodayItinerary;

  /// No description provided for @dayPlanBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Your Day Plan based on:'**
  String get dayPlanBasedOn;

  /// No description provided for @dayPlanEditMoods.
  ///
  /// In en, this message translates to:
  /// **'Edit Moods →'**
  String get dayPlanEditMoods;

  /// No description provided for @dayPlanAddToMyDay.
  ///
  /// In en, this message translates to:
  /// **'Add to My Day'**
  String get dayPlanAddToMyDay;

  /// No description provided for @dayPlanAddMoreToMyDay.
  ///
  /// In en, this message translates to:
  /// **'Add {count} more to My Day'**
  String dayPlanAddMoreToMyDay(String count);

  /// No description provided for @dayPlanViewMyDay.
  ///
  /// In en, this message translates to:
  /// **'View My Day'**
  String get dayPlanViewMyDay;

  /// Hint shown below the greyed-out View My Day button
  ///
  /// In en, this message translates to:
  /// **'Add at least one activity to continue'**
  String get dayPlanSelectAtLeastOne;

  /// No description provided for @dayPlanAddAllSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Add all {count} to My Day'**
  String dayPlanAddAllSuggestions(String count);

  /// No description provided for @dayPlanPlanAddedToMyDay.
  ///
  /// In en, this message translates to:
  /// **'Plan added to My Day!'**
  String get dayPlanPlanAddedToMyDay;

  /// No description provided for @dayPlanAddPlanFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add plan. Try again.'**
  String get dayPlanAddPlanFailed;

  /// No description provided for @dayPlanAllAlternativesUsed.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all 3 alternative options for this activity!'**
  String get dayPlanAllAlternativesUsed;

  /// No description provided for @dayPlanFindingOptions.
  ///
  /// In en, this message translates to:
  /// **'Finding new options for {name}...'**
  String dayPlanFindingOptions(String name);

  /// No description provided for @dayPlanNoOptionsFound.
  ///
  /// In en, this message translates to:
  /// **'No other options found for this time slot. Try a different mood!'**
  String get dayPlanNoOptionsFound;

  /// No description provided for @dayPlanFindOptionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to find new options. Please try again later.'**
  String get dayPlanFindOptionsFailed;

  /// No description provided for @dayPlanAllOptionsUsed.
  ///
  /// In en, this message translates to:
  /// **'All options used'**
  String get dayPlanAllOptionsUsed;

  /// No description provided for @dayPlanNotFeelingThis.
  ///
  /// In en, this message translates to:
  /// **'Not feeling this?'**
  String get dayPlanNotFeelingThis;

  /// No description provided for @dayPlanTryAgainLeft.
  ///
  /// In en, this message translates to:
  /// **'Try again? ({count} left)'**
  String dayPlanTryAgainLeft(String count);

  /// No description provided for @dayPlanMorning.
  ///
  /// In en, this message translates to:
  /// **'MORNING'**
  String get dayPlanMorning;

  /// No description provided for @dayPlanAfternoon.
  ///
  /// In en, this message translates to:
  /// **'AFTERNOON'**
  String get dayPlanAfternoon;

  /// No description provided for @dayPlanEvening.
  ///
  /// In en, this message translates to:
  /// **'EVENING'**
  String get dayPlanEvening;

  /// No description provided for @dayPlanThemeExploreDiscover.
  ///
  /// In en, this message translates to:
  /// **'Explore & Discover'**
  String get dayPlanThemeExploreDiscover;

  /// No description provided for @dayPlanThemeTrueLocalFind.
  ///
  /// In en, this message translates to:
  /// **'A True Local Find'**
  String get dayPlanThemeTrueLocalFind;

  /// No description provided for @dayPlanThemeWindDownCulture.
  ///
  /// In en, this message translates to:
  /// **'Wind Down & Culture'**
  String get dayPlanThemeWindDownCulture;

  /// No description provided for @dayPlanThemeCulturalDeepDive.
  ///
  /// In en, this message translates to:
  /// **'Cultural Deep Dive'**
  String get dayPlanThemeCulturalDeepDive;

  /// No description provided for @dayPlanThemeFoodieFind.
  ///
  /// In en, this message translates to:
  /// **'A True \'Foodie\' Find'**
  String get dayPlanThemeFoodieFind;

  /// No description provided for @dayPlanThemeSunsetVibes.
  ///
  /// In en, this message translates to:
  /// **'Sunset Vibes & Culture'**
  String get dayPlanThemeSunsetVibes;

  /// No description provided for @dayPlanThemeWindDownRelax.
  ///
  /// In en, this message translates to:
  /// **'Wind Down & Relax'**
  String get dayPlanThemeWindDownRelax;

  /// No description provided for @dayPlanThemeAdventureAwaits.
  ///
  /// In en, this message translates to:
  /// **'Adventure Awaits'**
  String get dayPlanThemeAdventureAwaits;

  /// No description provided for @dayPlanThemeOutdoorNature.
  ///
  /// In en, this message translates to:
  /// **'Outdoor & Nature'**
  String get dayPlanThemeOutdoorNature;

  /// No description provided for @dayPlanThemeCreativeVibes.
  ///
  /// In en, this message translates to:
  /// **'Creative Vibes'**
  String get dayPlanThemeCreativeVibes;

  /// No description provided for @dayPlanThemeRomanticMoments.
  ///
  /// In en, this message translates to:
  /// **'Romantic Moments'**
  String get dayPlanThemeRomanticMoments;

  /// No description provided for @dayPlanThemeYourVibe.
  ///
  /// In en, this message translates to:
  /// **'Your Vibe'**
  String get dayPlanThemeYourVibe;

  /// No description provided for @dayPlanCardActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get dayPlanCardActivity;

  /// No description provided for @dayPlanCardFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get dayPlanCardFree;

  /// No description provided for @dayPlanCardOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get dayPlanCardOpenNow;

  /// No description provided for @dayPlanCardClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get dayPlanCardClosed;

  /// No description provided for @dayPlanCardNotFeelingThis.
  ///
  /// In en, this message translates to:
  /// **'Not feeling this?'**
  String get dayPlanCardNotFeelingThis;

  /// No description provided for @dayPlanCardDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get dayPlanCardDirections;

  /// No description provided for @dayPlanCardSeeActivity.
  ///
  /// In en, this message translates to:
  /// **'See activity'**
  String get dayPlanCardSeeActivity;

  /// No description provided for @dayPlanCardUnableToOpenDirections.
  ///
  /// In en, this message translates to:
  /// **'Unable to open directions'**
  String get dayPlanCardUnableToOpenDirections;

  /// No description provided for @dayPlanCardFailedToShare.
  ///
  /// In en, this message translates to:
  /// **'Failed to share'**
  String get dayPlanCardFailedToShare;

  /// No description provided for @dayPlanCardRemovedFromSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from saved places'**
  String dayPlanCardRemovedFromSaved(String name);

  /// No description provided for @dayPlanCardFailedToRemove.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove {name}'**
  String dayPlanCardFailedToRemove(String name);

  /// No description provided for @dayPlanCardCouldNotSaveMoodyHub.
  ///
  /// In en, this message translates to:
  /// **'Could not save to Moody Hub. Sign in may be required.'**
  String get dayPlanCardCouldNotSaveMoodyHub;

  /// No description provided for @dayPlanCardCouldNotAddMyDay.
  ///
  /// In en, this message translates to:
  /// **'Could not add to My Day. Sign in may be required.'**
  String get dayPlanCardCouldNotAddMyDay;

  /// No description provided for @dayPlanCardSavedToMoodyHubAndMyDay.
  ///
  /// In en, this message translates to:
  /// **'{name} saved! Find it in Moody Hub (saved) and My Day.'**
  String dayPlanCardSavedToMoodyHubAndMyDay(String name);

  /// No description provided for @dayPlanCardSavedToMoodyHub.
  ///
  /// In en, this message translates to:
  /// **'{name} saved to Moody Hub.'**
  String dayPlanCardSavedToMoodyHub(String name);

  /// No description provided for @dayPlanCardAddedToMyDay.
  ///
  /// In en, this message translates to:
  /// **'{name} added to My Day.'**
  String dayPlanCardAddedToMyDay(String name);

  /// No description provided for @dayPlanCardAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get dayPlanCardAdded;

  /// No description provided for @dayPlanCardAddRemainingToMyDay.
  ///
  /// In en, this message translates to:
  /// **'Add remaining to My Day'**
  String get dayPlanCardAddRemainingToMyDay;

  /// No description provided for @dayPlanCardMatch.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Match'**
  String dayPlanCardMatch(String percent);

  /// No description provided for @dayPlanCardAddToMyDay.
  ///
  /// In en, this message translates to:
  /// **'+ Add to My Day'**
  String get dayPlanCardAddToMyDay;

  /// No description provided for @moodHubGreetingFriendly.
  ///
  /// In en, this message translates to:
  /// **'Hey, {name}!'**
  String moodHubGreetingFriendly(String name);

  /// No description provided for @moodHubGreetingBestie.
  ///
  /// In en, this message translates to:
  /// **'Hey bestie, {name}! 😊'**
  String moodHubGreetingBestie(String name);

  /// No description provided for @moodHubGreetingProfessional.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String moodHubGreetingProfessional(String greeting, String name);

  /// No description provided for @moodHubGreetingDirect.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String moodHubGreetingDirect(String name);

  /// No description provided for @moodHubGreetingHeyThere.
  ///
  /// In en, this message translates to:
  /// **'Hey there!'**
  String get moodHubGreetingHeyThere;

  /// No description provided for @moodHubGreetingHi.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get moodHubGreetingHi;

  /// No description provided for @moodHubWhatIsYourMood.
  ///
  /// In en, this message translates to:
  /// **'What\'s your mood'**
  String get moodHubWhatIsYourMood;

  /// No description provided for @moodHubThisMorning.
  ///
  /// In en, this message translates to:
  /// **'this morning?'**
  String get moodHubThisMorning;

  /// No description provided for @moodHubThisAfternoon.
  ///
  /// In en, this message translates to:
  /// **'this afternoon?'**
  String get moodHubThisAfternoon;

  /// No description provided for @moodHubThisEvening.
  ///
  /// In en, this message translates to:
  /// **'this evening?'**
  String get moodHubThisEvening;

  /// No description provided for @moodHubTonight.
  ///
  /// In en, this message translates to:
  /// **'tonight?'**
  String get moodHubTonight;

  /// No description provided for @moodHubBannerMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning vibes — let\'s set the tone.'**
  String get moodHubBannerMorning;

  /// No description provided for @moodHubBannerAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon\'s here — time to match your vibe.'**
  String get moodHubBannerAfternoon;

  /// No description provided for @moodHubBannerEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening\'s here — what\'s your vibe?'**
  String get moodHubBannerEvening;

  /// No description provided for @moodHubBannerNight.
  ///
  /// In en, this message translates to:
  /// **'Late night energy — let\'s find something that fits.'**
  String get moodHubBannerNight;

  /// No description provided for @moodHubMoodPickerBanner.
  ///
  /// In en, this message translates to:
  /// **'Pick up to three moods below — I\'ll shape ideas around them.'**
  String get moodHubMoodPickerBanner;

  /// No description provided for @moodyIdleWakeOpenPlan.
  ///
  /// In en, this message translates to:
  /// **'Let\'s open your plan for today.'**
  String get moodyIdleWakeOpenPlan;

  /// No description provided for @moodyIdleWakeChooseMood.
  ///
  /// In en, this message translates to:
  /// **'What are we doing today? Pick your mood and we\'ll build the day.'**
  String get moodyIdleWakeChooseMood;

  /// No description provided for @moodyIdleTapMoodyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Moody to open WanderMood'**
  String get moodyIdleTapMoodyHint;

  /// No description provided for @moodyIdleTapMoodySub.
  ///
  /// In en, this message translates to:
  /// **'You have to tap the face above — there\'s no other way in.'**
  String get moodyIdleTapMoodySub;

  /// No description provided for @moodyIdleTapMoodyContinueShort.
  ///
  /// In en, this message translates to:
  /// **'Tap Moody to continue'**
  String get moodyIdleTapMoodyContinueShort;

  /// No description provided for @moodyIdleWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get moodyIdleWelcomeBack;

  /// No description provided for @moodyIdleFallbackMorning.
  ///
  /// In en, this message translates to:
  /// **'Moody was grabbing a coffee ☕'**
  String get moodyIdleFallbackMorning;

  /// No description provided for @moodyIdleFallbackDay.
  ///
  /// In en, this message translates to:
  /// **'Moody was out and about — ready when you are ✨'**
  String get moodyIdleFallbackDay;

  /// No description provided for @moodyIdleFallbackEvening.
  ///
  /// In en, this message translates to:
  /// **'Moody was winding down 🌙'**
  String get moodyIdleFallbackEvening;

  /// No description provided for @moodyIdleFallbackNight.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours… Moody was almost asleep 😴'**
  String get moodyIdleFallbackNight;

  /// No description provided for @moodyIdleGateMorning0.
  ///
  /// In en, this message translates to:
  /// **'Good morning. Ready to shape today?'**
  String get moodyIdleGateMorning0;

  /// No description provided for @moodyIdleGateMorning1.
  ///
  /// In en, this message translates to:
  /// **'Morning — want to see what’s on your list?'**
  String get moodyIdleGateMorning1;

  /// No description provided for @moodyIdleGateMorning2.
  ///
  /// In en, this message translates to:
  /// **'You’re up. Open your day whenever you’re ready.'**
  String get moodyIdleGateMorning2;

  /// No description provided for @moodyIdleGateMorning3.
  ///
  /// In en, this message translates to:
  /// **'New day. Tap when you want to get started.'**
  String get moodyIdleGateMorning3;

  /// No description provided for @moodyIdleGateMorning4.
  ///
  /// In en, this message translates to:
  /// **'Still easing in? No rush — tap Moody when you’re ready.'**
  String get moodyIdleGateMorning4;

  /// No description provided for @moodyIdleGateEvening0.
  ///
  /// In en, this message translates to:
  /// **'Good evening. Want to pick up your plan?'**
  String get moodyIdleGateEvening0;

  /// No description provided for @moodyIdleGateEvening1.
  ///
  /// In en, this message translates to:
  /// **'Evening — here when you want to close the loop.'**
  String get moodyIdleGateEvening1;

  /// No description provided for @moodyIdleGateEvening2.
  ///
  /// In en, this message translates to:
  /// **'Winding down? Your day is a tap away.'**
  String get moodyIdleGateEvening2;

  /// No description provided for @moodyIdleGateEvening3.
  ///
  /// In en, this message translates to:
  /// **'Back for a bit? Moody’s here to help.'**
  String get moodyIdleGateEvening3;

  /// No description provided for @moodyIdleGateEvening4.
  ///
  /// In en, this message translates to:
  /// **'Take a breath — open your plan if it helps.'**
  String get moodyIdleGateEvening4;

  /// No description provided for @moodyHubNewConversation.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get moodyHubNewConversation;

  /// No description provided for @moodHubCreatePlan.
  ///
  /// In en, this message translates to:
  /// **'Let\'s create your perfect plan! 🎯'**
  String get moodHubCreatePlan;

  /// No description provided for @moodHubBackToHub.
  ///
  /// In en, this message translates to:
  /// **'Back to Hub'**
  String get moodHubBackToHub;

  /// No description provided for @moodHubSelectUpTo.
  ///
  /// In en, this message translates to:
  /// **'You can select up to {max} moods'**
  String moodHubSelectUpTo(String max);

  /// No description provided for @moodHubSelectedMoods.
  ///
  /// In en, this message translates to:
  /// **'Selected moods: '**
  String get moodHubSelectedMoods;

  /// No description provided for @moodHubNoMoodOptions.
  ///
  /// In en, this message translates to:
  /// **'No mood options available'**
  String get moodHubNoMoodOptions;

  /// No description provided for @moodHubMoodyThinking.
  ///
  /// In en, this message translates to:
  /// **'Let me think…'**
  String get moodHubMoodyThinking;

  /// No description provided for @moodHubMoodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHubMoodHappy;

  /// No description provided for @moodHubMoodAdventurous.
  ///
  /// In en, this message translates to:
  /// **'Adventurous'**
  String get moodHubMoodAdventurous;

  /// No description provided for @moodHubMoodRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get moodHubMoodRelaxed;

  /// No description provided for @moodHubMoodEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get moodHubMoodEnergetic;

  /// No description provided for @moodHubMoodRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get moodHubMoodRomantic;

  /// No description provided for @moodHubMoodSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get moodHubMoodSocial;

  /// No description provided for @moodHubMoodCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get moodHubMoodCultural;

  /// No description provided for @moodHubMoodCurious.
  ///
  /// In en, this message translates to:
  /// **'Curious'**
  String get moodHubMoodCurious;

  /// No description provided for @moodHubMoodCozy.
  ///
  /// In en, this message translates to:
  /// **'Cozy'**
  String get moodHubMoodCozy;

  /// No description provided for @moodHubMoodExcited.
  ///
  /// In en, this message translates to:
  /// **'Excited'**
  String get moodHubMoodExcited;

  /// No description provided for @moodHubMoodFoody.
  ///
  /// In en, this message translates to:
  /// **'Foody'**
  String get moodHubMoodFoody;

  /// No description provided for @moodHubMoodSurprise.
  ///
  /// In en, this message translates to:
  /// **'Surprise'**
  String get moodHubMoodSurprise;

  /// No description provided for @planLoadingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get planLoadingErrorTitle;

  /// No description provided for @planLoadingTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get planLoadingTryAgain;

  /// No description provided for @planLoadingErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Unable to generate activities. Please try again or select different moods.'**
  String get planLoadingErrorGeneric;

  /// No description provided for @planLoadingErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network connection error. Please check your internet connection and try again.'**
  String get planLoadingErrorNetwork;

  /// No description provided for @planLoadingErrorLocation.
  ///
  /// In en, this message translates to:
  /// **'Location access required. Please enable location services and try again.'**
  String get planLoadingErrorLocation;

  /// No description provided for @planLoadingErrorService.
  ///
  /// In en, this message translates to:
  /// **'Service temporarily unavailable. Please try again in a few minutes.'**
  String get planLoadingErrorService;

  /// No description provided for @planLoadingErrorApiKey.
  ///
  /// In en, this message translates to:
  /// **'Configuration error. Please contact support if this persists.'**
  String get planLoadingErrorApiKey;

  /// No description provided for @planLoadingErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Service unavailable. Please try again later.'**
  String get planLoadingErrorNotFound;

  /// No description provided for @planLoadingErrorNoActivities.
  ///
  /// In en, this message translates to:
  /// **'No activities found for your selected moods and location. Please try different moods or check your location settings.'**
  String get planLoadingErrorNoActivities;

  /// No description provided for @planLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Building your plan…'**
  String get planLoadingMessage;

  /// No description provided for @planLoadingCreatingYourDay.
  ///
  /// In en, this message translates to:
  /// **'I\'m putting your day together…'**
  String get planLoadingCreatingYourDay;

  /// No description provided for @planLoadingPhaseChecking.
  ///
  /// In en, this message translates to:
  /// **'I\'m checking what fits you…'**
  String get planLoadingPhaseChecking;

  /// No description provided for @planLoadingPhaseBuilding.
  ///
  /// In en, this message translates to:
  /// **'I\'m lining up the right spots…'**
  String get planLoadingPhaseBuilding;

  /// No description provided for @planLoadingPhaseAlmost.
  ///
  /// In en, this message translates to:
  /// **'Almost there — one sec…'**
  String get planLoadingPhaseAlmost;

  /// No description provided for @planLoadingCompactHeadline.
  ///
  /// In en, this message translates to:
  /// **'I\'m finishing your day…'**
  String get planLoadingCompactHeadline;

  /// No description provided for @groupPlanLoadingCompactHeadline.
  ///
  /// In en, this message translates to:
  /// **'I\'m finishing your shared day…'**
  String get groupPlanLoadingCompactHeadline;

  /// No description provided for @planLoadingCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get planLoadingCancel;

  /// No description provided for @planLoadingErrorBackToMoody.
  ///
  /// In en, this message translates to:
  /// **'Back to Moody'**
  String get planLoadingErrorBackToMoody;

  /// No description provided for @moodyHubCompanionFallback.
  ///
  /// In en, this message translates to:
  /// **'Your day is taking shape — I\'m right here with you. Change your mood, peek at Explore, or chat with me whenever you like.'**
  String get moodyHubCompanionFallback;

  /// No description provided for @moodyHubNudgeNoPlan.
  ///
  /// In en, this message translates to:
  /// **'Pick a mood and I’ll build you a day that actually fits.'**
  String get moodyHubNudgeNoPlan;

  /// No description provided for @moodyHubNudgePlanNext.
  ///
  /// In en, this message translates to:
  /// **'Next up: {title} at {time}. I’ll keep the flow smooth.'**
  String moodyHubNudgePlanNext(String title, String time);

  /// No description provided for @moodyHubNudgePlanWrap.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} done. Tell me if you want the rest lighter or bolder.'**
  String moodyHubNudgePlanWrap(String done, String total);

  /// No description provided for @dayPlanMoodyMessageFallback.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what I picked for your vibe. Add what you love to My Day, then tap View My Day when you\'re ready.'**
  String get dayPlanMoodyMessageFallback;

  /// No description provided for @dayPlanMoodyReplaceEnergeticVibePhrase.
  ///
  /// In en, this message translates to:
  /// **'a great match for your mood'**
  String get dayPlanMoodyReplaceEnergeticVibePhrase;

  /// No description provided for @dayPlanFirstViewportGuidance.
  ///
  /// In en, this message translates to:
  /// **'Open a card for details. Add with the green button, then View My Day.'**
  String get dayPlanFirstViewportGuidance;

  /// No description provided for @moodHomeChatIntroWithCity.
  ///
  /// In en, this message translates to:
  /// **'I know {city} well and love helping you discover it. Tell me your mood — I\'ll suggest a day that fits. Adventurous, romantic, or chill — we\'ve got this.'**
  String moodHomeChatIntroWithCity(String city);

  /// No description provided for @moodHomeChatIntroNoCity.
  ///
  /// In en, this message translates to:
  /// **'Tell me your mood and I\'ll help shape a day that fits. Adventurous, romantic, or chill — we\'ve got this.'**
  String get moodHomeChatIntroNoCity;

  /// No description provided for @moodHomeConversationEmptyTitleMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get moodHomeConversationEmptyTitleMorning;

  /// No description provided for @moodHomeConversationEmptyBodyMorning.
  ///
  /// In en, this message translates to:
  /// **'Let\'s shape a day that feels like you. Tell me your mood when you\'re ready.'**
  String get moodHomeConversationEmptyBodyMorning;

  /// No description provided for @moodHomeConversationEmptyTitleMidday.
  ///
  /// In en, this message translates to:
  /// **'Hey there!'**
  String get moodHomeConversationEmptyTitleMidday;

  /// No description provided for @moodHomeConversationEmptyBodyMidday.
  ///
  /// In en, this message translates to:
  /// **'I\'ve been thinking about your perfect day — share your mood when you\'re ready.'**
  String get moodHomeConversationEmptyBodyMidday;

  /// No description provided for @moodHomeConversationEmptyTitleAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon!'**
  String get moodHomeConversationEmptyTitleAfternoon;

  /// No description provided for @moodHomeConversationEmptyBodyAfternoon.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind for today? Your mood is a great place to start.'**
  String get moodHomeConversationEmptyBodyAfternoon;

  /// No description provided for @moodHomeConversationEmptyTitleEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening explorer!'**
  String get moodHomeConversationEmptyTitleEvening;

  /// No description provided for @moodHomeConversationEmptyBodyEvening.
  ///
  /// In en, this message translates to:
  /// **'Weekend or weekday — let\'s find the right energy for tonight.'**
  String get moodHomeConversationEmptyBodyEvening;

  /// No description provided for @moodHomeConversationEmptyTitleNight.
  ///
  /// In en, this message translates to:
  /// **'Still up?'**
  String get moodHomeConversationEmptyTitleNight;

  /// No description provided for @moodHomeConversationEmptyBodyNight.
  ///
  /// In en, this message translates to:
  /// **'Late-night ideas are welcome — tell me how you\'re feeling.'**
  String get moodHomeConversationEmptyBodyNight;

  /// No description provided for @moodySays.
  ///
  /// In en, this message translates to:
  /// **'Moody says'**
  String get moodySays;

  /// No description provided for @dayPlanMoodyCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Moody'**
  String get dayPlanMoodyCardTitle;

  /// No description provided for @moodCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get moodCultural;

  /// No description provided for @moodCozy.
  ///
  /// In en, this message translates to:
  /// **'Cozy'**
  String get moodCozy;

  /// No description provided for @moodFoody.
  ///
  /// In en, this message translates to:
  /// **'Foody'**
  String get moodFoody;

  /// No description provided for @moodRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get moodRelaxed;

  /// No description provided for @moodAdventurous.
  ///
  /// In en, this message translates to:
  /// **'Adventurous'**
  String get moodAdventurous;

  /// No description provided for @moodSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get moodSocial;

  /// No description provided for @moodCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get moodCreative;

  /// No description provided for @moodRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get moodRomantic;

  /// No description provided for @moodEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get moodEnergetic;

  /// No description provided for @moodCurious.
  ///
  /// In en, this message translates to:
  /// **'Curious'**
  String get moodCurious;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodFoodie.
  ///
  /// In en, this message translates to:
  /// **'Foodie'**
  String get moodFoodie;

  /// No description provided for @moodExcited.
  ///
  /// In en, this message translates to:
  /// **'Excited'**
  String get moodExcited;

  /// No description provided for @moodSurprise.
  ///
  /// In en, this message translates to:
  /// **'Surprise'**
  String get moodSurprise;

  /// No description provided for @dayPlanFoundNewOption.
  ///
  /// In en, this message translates to:
  /// **'✨ Found a new option: {name}! ({remaining} more changes available)'**
  String dayPlanFoundNewOption(String name, String remaining);

  /// No description provided for @activityDetailMatch.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Match'**
  String activityDetailMatch(String percent);

  /// No description provided for @activityDetailPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photo'**
  String activityDetailPhotoCount(String count);

  /// No description provided for @activityDetailPhotoCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String activityDetailPhotoCountPlural(String count);

  /// No description provided for @activityDetailTabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get activityDetailTabDetails;

  /// No description provided for @activityDetailTabPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get activityDetailTabPhotos;

  /// No description provided for @activityDetailTabReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get activityDetailTabReviews;

  /// No description provided for @activityDetailReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. They\'ll show here when this place is linked to live listings.'**
  String get activityDetailReviewsEmpty;

  /// No description provided for @activityDetailPreviewSampleNote.
  ///
  /// In en, this message translates to:
  /// **'Sample photos and reviews for this preview.'**
  String get activityDetailPreviewSampleNote;

  /// No description provided for @activityDetailDemoReviewRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get activityDetailDemoReviewRecent;

  /// No description provided for @activityDetailDemoReview1Author.
  ///
  /// In en, this message translates to:
  /// **'Maya K.'**
  String get activityDetailDemoReview1Author;

  /// No description provided for @activityDetailDemoReview1Body.
  ///
  /// In en, this message translates to:
  /// **'Quiet and lovely — exactly the slow morning we wanted.'**
  String get activityDetailDemoReview1Body;

  /// No description provided for @activityDetailDemoReview2Author.
  ///
  /// In en, this message translates to:
  /// **'Joost V.'**
  String get activityDetailDemoReview2Author;

  /// No description provided for @activityDetailDemoReview2Body.
  ///
  /// In en, this message translates to:
  /// **'Great coffee and friendly service. We\'ll be back.'**
  String get activityDetailDemoReview2Body;

  /// No description provided for @activityDetailDemoReview3Author.
  ///
  /// In en, this message translates to:
  /// **'Sara L.'**
  String get activityDetailDemoReview3Author;

  /// No description provided for @activityDetailDemoReview3Body.
  ///
  /// In en, this message translates to:
  /// **'Cozy corners for two. Perfect before a walk in town.'**
  String get activityDetailDemoReview3Body;

  /// No description provided for @activityDetailDemoReview4Author.
  ///
  /// In en, this message translates to:
  /// **'Eli R.'**
  String get activityDetailDemoReview4Author;

  /// No description provided for @activityDetailDemoReview4Body.
  ///
  /// In en, this message translates to:
  /// **'Small menu, but everything we tried hit the spot.'**
  String get activityDetailDemoReview4Body;

  /// No description provided for @activityDetailRatingExceptional.
  ///
  /// In en, this message translates to:
  /// **'Exceptional'**
  String get activityDetailRatingExceptional;

  /// No description provided for @activityDetailDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get activityDetailDuration;

  /// No description provided for @activityDetailPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get activityDetailPrice;

  /// No description provided for @activityDetailDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get activityDetailDistance;

  /// No description provided for @activityDetailDistanceNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get activityDetailDistanceNearby;

  /// No description provided for @activityDetailAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get activityDetailAbout;

  /// No description provided for @activityDetailHighlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get activityDetailHighlights;

  /// No description provided for @activityDetailLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get activityDetailLocation;

  /// No description provided for @activityDetailGetDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions →'**
  String get activityDetailGetDirections;

  /// No description provided for @activityDetailFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get activityDetailFrom;

  /// No description provided for @activityDetailPerPerson.
  ///
  /// In en, this message translates to:
  /// **'per person'**
  String get activityDetailPerPerson;

  /// No description provided for @activityDetailDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get activityDetailDirections;

  /// No description provided for @activityDetailBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get activityDetailBookNow;

  /// No description provided for @getReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Ready'**
  String get getReadyTitle;

  /// No description provided for @getReadyLeaveBy.
  ///
  /// In en, this message translates to:
  /// **'Leave by {time}'**
  String getReadyLeaveBy(String time);

  /// No description provided for @getReadyTripSummary.
  ///
  /// In en, this message translates to:
  /// **'{mode} · ~{minutes} min trip'**
  String getReadyTripSummary(String mode, int minutes);

  /// No description provided for @getReadyTransportWalking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get getReadyTransportWalking;

  /// No description provided for @getReadyTransportPublicTransport.
  ///
  /// In en, this message translates to:
  /// **'Public transport'**
  String get getReadyTransportPublicTransport;

  /// No description provided for @getReadyWeatherAt.
  ///
  /// In en, this message translates to:
  /// **'Weather at {time}'**
  String getReadyWeatherAt(String time);

  /// No description provided for @getReadyWeatherTipDefault.
  ///
  /// In en, this message translates to:
  /// **'Looks like a great time to head out.'**
  String get getReadyWeatherTipDefault;

  /// No description provided for @getReadyWeatherTipCool.
  ///
  /// In en, this message translates to:
  /// **'It might be a bit chilly – bring a light jacket.'**
  String get getReadyWeatherTipCool;

  /// No description provided for @getReadyWeatherTipRain.
  ///
  /// In en, this message translates to:
  /// **'Rain is expected – consider bringing an umbrella.'**
  String get getReadyWeatherTipRain;

  /// No description provided for @getReadyChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'What to bring'**
  String get getReadyChecklistTitle;

  /// No description provided for @getReadyItemWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet & payment method'**
  String get getReadyItemWallet;

  /// No description provided for @getReadyItemPhoneCharged.
  ///
  /// In en, this message translates to:
  /// **'Phone fully charged'**
  String get getReadyItemPhoneCharged;

  /// No description provided for @getReadyItemReusableBag.
  ///
  /// In en, this message translates to:
  /// **'Reusable bag or container'**
  String get getReadyItemReusableBag;

  /// No description provided for @getReadyItemShoes.
  ///
  /// In en, this message translates to:
  /// **'Comfortable walking shoes'**
  String get getReadyItemShoes;

  /// No description provided for @getReadyItemWater.
  ///
  /// In en, this message translates to:
  /// **'Water bottle'**
  String get getReadyItemWater;

  /// No description provided for @getReadyItemId.
  ///
  /// In en, this message translates to:
  /// **'ID / travel card if needed'**
  String get getReadyItemId;

  /// No description provided for @getReadyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me to leave'**
  String get getReadyReminderTitle;

  /// No description provided for @getReadyReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a gentle nudge a few minutes before.'**
  String get getReadyReminderSubtitle;

  /// No description provided for @getReadyQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get getReadyQuickActions;

  /// No description provided for @getReadyQuickShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get getReadyQuickShare;

  /// No description provided for @getReadyQuickCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get getReadyQuickCalendar;

  /// No description provided for @getReadyQuickParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get getReadyQuickParking;

  /// No description provided for @getReadyPrimaryCta.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready! 🚀'**
  String get getReadyPrimaryCta;

  /// No description provided for @getReadyLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Go!'**
  String get getReadyLetsGo;

  /// No description provided for @getReadyAdventureStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Adventure starts in…'**
  String get getReadyAdventureStartsIn;

  /// No description provided for @getReadyHours.
  ///
  /// In en, this message translates to:
  /// **'HOURS'**
  String get getReadyHours;

  /// No description provided for @getReadyMins.
  ///
  /// In en, this message translates to:
  /// **'MINS'**
  String get getReadyMins;

  /// No description provided for @getReadyRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get getReadyRoute;

  /// No description provided for @travelTimeLessThanOneMinWalk.
  ///
  /// In en, this message translates to:
  /// **'< 1 min walk'**
  String get travelTimeLessThanOneMinWalk;

  /// No description provided for @travelTimeMinWalk.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min walk'**
  String travelTimeMinWalk(int minutes);

  /// No description provided for @travelTimeBikeAndWalk.
  ///
  /// In en, this message translates to:
  /// **'{bikeMinutes} min bike · {walkMinutes} min walk'**
  String travelTimeBikeAndWalk(int bikeMinutes, int walkMinutes);

  /// No description provided for @travelTimeTransitApprox.
  ///
  /// In en, this message translates to:
  /// **'≈ {transitMinutes} min transit · {distance}'**
  String travelTimeTransitApprox(int transitMinutes, String distance);

  /// No description provided for @getReadyYourAdventureEnergy.
  ///
  /// In en, this message translates to:
  /// **'Your Adventure Energy'**
  String get getReadyYourAdventureEnergy;

  /// No description provided for @getReadyBoostEnergyHint.
  ///
  /// In en, this message translates to:
  /// **'Check off items below to boost your energy!'**
  String get getReadyBoostEnergyHint;

  /// No description provided for @getReadyPackEssentials.
  ///
  /// In en, this message translates to:
  /// **'Pack Your Essentials'**
  String get getReadyPackEssentials;

  /// No description provided for @getReadyVibePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Vibe Playlist'**
  String get getReadyVibePlaylist;

  /// No description provided for @getReadyGetInMood.
  ///
  /// In en, this message translates to:
  /// **'Get in the {mood} mood!'**
  String getReadyGetInMood(String mood);

  /// No description provided for @getReadyPlaylistLabel.
  ///
  /// In en, this message translates to:
  /// **'Happy {theme} Beats'**
  String getReadyPlaylistLabel(String theme);

  /// No description provided for @getReadyPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get getReadyPlay;

  /// No description provided for @getReadyNudgeMe.
  ///
  /// In en, this message translates to:
  /// **'Nudge me when it\'s time!'**
  String get getReadyNudgeMe;

  /// No description provided for @getReadyReminderAt.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remind you at {time}'**
  String getReadyReminderAt(String time);

  /// No description provided for @getReadyCantWait.
  ///
  /// In en, this message translates to:
  /// **'Can\'t wait to see what you discover!'**
  String get getReadyCantWait;

  /// No description provided for @noPlanDayOpenInCity.
  ///
  /// In en, this message translates to:
  /// **'Your day in {city} is still wide open — I\'ve already got ideas bubbling. Want me to sketch a full flow, or should we chase one vibe first?'**
  String noPlanDayOpenInCity(String city);

  /// No description provided for @noPlanDayOpenAroundYou.
  ///
  /// In en, this message translates to:
  /// **'Your day is still wide open — I\'ve already got ideas bubbling. Want me to sketch a full flow, or should we chase one vibe first?'**
  String get noPlanDayOpenAroundYou;

  /// No description provided for @noPlanDayOpenLocating.
  ///
  /// In en, this message translates to:
  /// **'Hang on… I\'m locking in where you are, then we\'ll pick your next move.'**
  String get noPlanDayOpenLocating;

  /// No description provided for @noPlanPlanMyWholeDay.
  ///
  /// In en, this message translates to:
  /// **'Plan my whole day'**
  String get noPlanPlanMyWholeDay;

  /// No description provided for @noPlanFindMeCoffee.
  ///
  /// In en, this message translates to:
  /// **'☕ Find me coffee'**
  String get noPlanFindMeCoffee;

  /// No description provided for @noPlanGetMeMoving.
  ///
  /// In en, this message translates to:
  /// **'🏃 Get me moving'**
  String get noPlanGetMeMoving;

  /// No description provided for @noPlanJustChat.
  ///
  /// In en, this message translates to:
  /// **'💬 Tell me what\'s on your mind'**
  String get noPlanJustChat;

  /// No description provided for @noPlanPlanLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get noPlanPlanLater;

  /// No description provided for @dayPlanNoLinkedPlaceAlternative.
  ///
  /// In en, this message translates to:
  /// **'No high-quality linked-place alternative found yet. Try again.'**
  String get dayPlanNoLinkedPlaceAlternative;

  /// No description provided for @myDayCheckInPrompt.
  ///
  /// In en, this message translates to:
  /// **'You\'re here! Tap Done when you\'re finished.'**
  String get myDayCheckInPrompt;

  /// No description provided for @myDayDonePrompt.
  ///
  /// In en, this message translates to:
  /// **'Nice one! You can leave a review now.'**
  String get myDayDonePrompt;

  /// No description provided for @myDayGetReadyUpcomingFallback.
  ///
  /// In en, this message translates to:
  /// **'Your upcoming activity'**
  String get myDayGetReadyUpcomingFallback;

  /// No description provided for @myDayDirectionsOpensInMaps.
  ///
  /// In en, this message translates to:
  /// **'Opens in maps app'**
  String get myDayDirectionsOpensInMaps;

  /// No description provided for @myDayCallVenue.
  ///
  /// In en, this message translates to:
  /// **'Call Venue'**
  String get myDayCallVenue;

  /// No description provided for @myDayCallVenueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm details or ask questions'**
  String get myDayCallVenueSubtitle;

  /// No description provided for @myDayNoPhoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'No phone number available'**
  String get myDayNoPhoneAvailable;

  /// No description provided for @myDayAddToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get myDayAddToCalendar;

  /// No description provided for @myDayAddToCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set reminder and details'**
  String get myDayAddToCalendarSubtitle;

  /// No description provided for @myDayAddedToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Added to calendar'**
  String get myDayAddedToCalendar;

  /// No description provided for @myDayAllSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set! Have a great time!'**
  String get myDayAllSet;

  /// No description provided for @myDayReadyCta.
  ///
  /// In en, this message translates to:
  /// **'I\'m Ready!'**
  String get myDayReadyCta;

  /// No description provided for @myDayTabActivated.
  ///
  /// In en, this message translates to:
  /// **'{tab} activated!'**
  String myDayTabActivated(String tab);

  /// No description provided for @myDaySaveForLater.
  ///
  /// In en, this message translates to:
  /// **'Save for later'**
  String get myDaySaveForLater;

  /// No description provided for @myDayDirectionsChooseFor.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to get directions to {title}'**
  String myDayDirectionsChooseFor(String title);

  /// No description provided for @myDayActivityOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity options'**
  String get myDayActivityOptionsTitle;

  /// No description provided for @myDayViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get myDayViewDetails;

  /// No description provided for @myDayImHere.
  ///
  /// In en, this message translates to:
  /// **'I\'m here'**
  String get myDayImHere;

  /// No description provided for @myDayImHereSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check in when you arrive at this spot'**
  String get myDayImHereSubtitle;

  /// No description provided for @myDayDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get myDayDone;

  /// No description provided for @myDayDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark complete and leave a review'**
  String get myDayDoneSubtitle;

  /// No description provided for @myDayShareActivity.
  ///
  /// In en, this message translates to:
  /// **'Share activity'**
  String get myDayShareActivity;

  /// No description provided for @myDayShareComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share functionality coming soon!'**
  String get myDayShareComingSoon;

  /// No description provided for @myDaySavedForLater.
  ///
  /// In en, this message translates to:
  /// **'{title} saved to Saved places!'**
  String myDaySavedForLater(String title);

  /// No description provided for @myDaySavePlaceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save to Saved places. Try again.'**
  String get myDaySavePlaceFailed;

  /// No description provided for @myDayShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share. Try again.'**
  String get myDayShareFailed;

  /// No description provided for @myDayDirectionsNavigateTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigate to'**
  String get myDayDirectionsNavigateTitle;

  /// No description provided for @myDayDeleteActivity.
  ///
  /// In en, this message translates to:
  /// **'Delete activity'**
  String get myDayDeleteActivity;

  /// No description provided for @myDayDeleteActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this activity from My Day'**
  String get myDayDeleteActivitySubtitle;

  /// No description provided for @myDayDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete activity?'**
  String get myDayDeleteConfirmTitle;

  /// No description provided for @myDayDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed from your My Day plan.'**
  String myDayDeleteConfirmBody(String title);

  /// No description provided for @myDayDeleteActivityCta.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get myDayDeleteActivityCta;

  /// No description provided for @myDayDeleteMissingId.
  ///
  /// In en, this message translates to:
  /// **'Could not delete activity (missing id).'**
  String get myDayDeleteMissingId;

  /// No description provided for @myDayDeletedFromPlan.
  ///
  /// In en, this message translates to:
  /// **'{title} deleted from My Day.'**
  String myDayDeletedFromPlan(String title);

  /// No description provided for @myDayDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed. Please try again.'**
  String get myDayDeleteFailed;

  /// No description provided for @myDayActivityLocationFallback.
  ///
  /// In en, this message translates to:
  /// **'Activity Location'**
  String get myDayActivityLocationFallback;

  /// No description provided for @myDayUnableOpenDirections.
  ///
  /// In en, this message translates to:
  /// **'Unable to open directions'**
  String get myDayUnableOpenDirections;

  /// No description provided for @myDayChatWithMoodyTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with Moody'**
  String get myDayChatWithMoodyTitle;

  /// No description provided for @myDayChatWithMoodyComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon! Moody will be able to help you plan your day and suggest activities based on your mood and preferences.'**
  String get myDayChatWithMoodyComingSoon;

  /// No description provided for @myDayHeroActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re in this activity right now.'**
  String get myDayHeroActiveSubtitle;

  /// No description provided for @myDayUnableLoadActivities.
  ///
  /// In en, this message translates to:
  /// **'Unable to load activities'**
  String get myDayUnableLoadActivities;

  /// No description provided for @navMyDay.
  ///
  /// In en, this message translates to:
  /// **'My Day'**
  String get navMyDay;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navAgenda.
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get navAgenda;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navMoody.
  ///
  /// In en, this message translates to:
  /// **'Moody'**
  String get navMoody;

  /// No description provided for @mainNavNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get mainNavNoConnection;

  /// No description provided for @exploreAlreadyInDayPlan.
  ///
  /// In en, this message translates to:
  /// **'Already in your day plan 👍'**
  String get exploreAlreadyInDayPlan;

  /// No description provided for @myDayStatusTitleRightNow.
  ///
  /// In en, this message translates to:
  /// **'Right Now'**
  String get myDayStatusTitleRightNow;

  /// No description provided for @myDayStatusTitleUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get myDayStatusTitleUpNext;

  /// No description provided for @myDayStatusTitleAllDone.
  ///
  /// In en, this message translates to:
  /// **'✅ All Done'**
  String get myDayStatusTitleAllDone;

  /// No description provided for @myDayStatusTitleFreeTime.
  ///
  /// In en, this message translates to:
  /// **'📅 FREE TIME'**
  String get myDayStatusTitleFreeTime;

  /// No description provided for @myDayStatusDescActive.
  ///
  /// In en, this message translates to:
  /// **'You\'re here! Tap Done when you\'re finished.'**
  String get myDayStatusDescActive;

  /// No description provided for @myDayStatusDescUpcomingMorning.
  ///
  /// In en, this message translates to:
  /// **'Planned for the morning · tap \"I\'m Here\" when you arrive'**
  String get myDayStatusDescUpcomingMorning;

  /// No description provided for @myDayStatusDescUpcomingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Planned for the afternoon · tap \"I\'m Here\" when you arrive'**
  String get myDayStatusDescUpcomingAfternoon;

  /// No description provided for @myDayStatusDescUpcomingEvening.
  ///
  /// In en, this message translates to:
  /// **'Planned for the evening · tap \"I\'m Here\" when you arrive'**
  String get myDayStatusDescUpcomingEvening;

  /// No description provided for @myDayStatusDescCompleted.
  ///
  /// In en, this message translates to:
  /// **'Great day! You\'ve completed everything.'**
  String get myDayStatusDescCompleted;

  /// No description provided for @myDayPeriodMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get myDayPeriodMorning;

  /// No description provided for @myDayPeriodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get myDayPeriodAfternoon;

  /// No description provided for @myDayPeriodEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get myDayPeriodEvening;

  /// No description provided for @myDayFreeTimeSuggestionMorning.
  ///
  /// In en, this message translates to:
  /// **'Perfect time to start your day with energy'**
  String get myDayFreeTimeSuggestionMorning;

  /// No description provided for @myDayFreeTimeSuggestionAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Great time to explore and discover'**
  String get myDayFreeTimeSuggestionAfternoon;

  /// No description provided for @myDayFreeTimeSuggestionEvening.
  ///
  /// In en, this message translates to:
  /// **'Wind down with something special'**
  String get myDayFreeTimeSuggestionEvening;

  /// No description provided for @myDayTimelineActivityCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 activity} other{{count} activities}}'**
  String myDayTimelineActivityCount(int count);

  /// No description provided for @myDayTimelineAllDone.
  ///
  /// In en, this message translates to:
  /// **'All Done'**
  String get myDayTimelineAllDone;

  /// No description provided for @myDayTimelineSectionComplete.
  ///
  /// In en, this message translates to:
  /// **'Great job completing this section!'**
  String get myDayTimelineSectionComplete;

  /// No description provided for @myDayTimelineTapForDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap for details'**
  String get myDayTimelineTapForDetails;

  /// No description provided for @myDayTimelinePrimaryImHere.
  ///
  /// In en, this message translates to:
  /// **'I\'m Here'**
  String get myDayTimelinePrimaryImHere;

  /// No description provided for @myDayTimelinePrimaryDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get myDayTimelinePrimaryDone;

  /// No description provided for @myDayTimelinePrimaryReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get myDayTimelinePrimaryReview;

  /// No description provided for @myDayTimelinePrimaryReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get myDayTimelinePrimaryReviewed;

  /// No description provided for @myDayTimelineStatusImHere.
  ///
  /// In en, this message translates to:
  /// **'I\'M HERE'**
  String get myDayTimelineStatusImHere;

  /// No description provided for @myDayTimelineStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'PLANNED'**
  String get myDayTimelineStatusPlanned;

  /// No description provided for @myDayTimelineStatusDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get myDayTimelineStatusDone;

  /// No description provided for @myDayTimelineStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get myDayTimelineStatusCancelled;

  /// No description provided for @myDayActivityFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get myDayActivityFallbackLabel;

  /// No description provided for @myDayExecutionHeroYoureHereBadge.
  ///
  /// In en, this message translates to:
  /// **'You\'re here!'**
  String get myDayExecutionHeroYoureHereBadge;

  /// No description provided for @myDayExecutionHeroInProgressBadge.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get myDayExecutionHeroInProgressBadge;

  /// No description provided for @myDayExecutionHeroActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Enjoying it? Tap Done when you\'re ready to move on.'**
  String get myDayExecutionHeroActiveHint;

  /// No description provided for @myDayExecutionHeroReviewedAt.
  ///
  /// In en, this message translates to:
  /// **'Reviewed at {time}'**
  String myDayExecutionHeroReviewedAt(String time);

  /// No description provided for @myDayExecutionHeroCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'Completed today'**
  String get myDayExecutionHeroCompletedToday;

  /// No description provided for @myDayExecutionHeroBadgeReviewedCaps.
  ///
  /// In en, this message translates to:
  /// **'REVIEWED'**
  String get myDayExecutionHeroBadgeReviewedCaps;

  /// No description provided for @myDayExecutionHeroBadgeReadyToReviewCaps.
  ///
  /// In en, this message translates to:
  /// **'READY TO REVIEW'**
  String get myDayExecutionHeroBadgeReadyToReviewCaps;

  /// No description provided for @myDayExecutionHeroReviewCaptureHint.
  ///
  /// In en, this message translates to:
  /// **'Capture how it felt while the experience is still fresh.'**
  String get myDayExecutionHeroReviewCaptureHint;

  /// No description provided for @myDayExecutionHeroUpNextBadge.
  ///
  /// In en, this message translates to:
  /// **'UP NEXT'**
  String get myDayExecutionHeroUpNextBadge;

  /// No description provided for @myDayExecutionHeroUpNextAfterSlotBadge.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get myDayExecutionHeroUpNextAfterSlotBadge;

  /// No description provided for @myDayExecutionHeroTapImHereWhenArrive.
  ///
  /// In en, this message translates to:
  /// **'Tap \"I\'m Here\" when you arrive.'**
  String get myDayExecutionHeroTapImHereWhenArrive;

  /// No description provided for @myDayTimelineSectionMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'🌅 Morning'**
  String get myDayTimelineSectionMorningTitle;

  /// No description provided for @myDayTimelineSectionMorningFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'🌅 This morning'**
  String get myDayTimelineSectionMorningFocusTitle;

  /// No description provided for @myDayTimelineSectionMorningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your day right'**
  String get myDayTimelineSectionMorningSubtitle;

  /// No description provided for @myDayTimelineSectionAfternoonTitle.
  ///
  /// In en, this message translates to:
  /// **'🌞 Afternoon'**
  String get myDayTimelineSectionAfternoonTitle;

  /// No description provided for @myDayTimelineSectionAfternoonFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'🌞 This afternoon'**
  String get myDayTimelineSectionAfternoonFocusTitle;

  /// No description provided for @myDayTimelineSectionAfternoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Peak adventure time'**
  String get myDayTimelineSectionAfternoonSubtitle;

  /// No description provided for @myDayTimelineSectionEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'🌆 Evening'**
  String get myDayTimelineSectionEveningTitle;

  /// No description provided for @myDayTimelineSectionEveningFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'🌆 This evening'**
  String get myDayTimelineSectionEveningFocusTitle;

  /// No description provided for @myDayTimelineSectionEveningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wind down and enjoy'**
  String get myDayTimelineSectionEveningSubtitle;

  /// No description provided for @myDayTimelineSectionEarlierTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earlier in your day'**
  String get myDayTimelineSectionEarlierTodaySubtitle;

  /// No description provided for @myDaySlotPlannedForMorning.
  ///
  /// In en, this message translates to:
  /// **'This morning'**
  String get myDaySlotPlannedForMorning;

  /// No description provided for @myDaySlotPlannedForAfternoon.
  ///
  /// In en, this message translates to:
  /// **'This afternoon'**
  String get myDaySlotPlannedForAfternoon;

  /// No description provided for @myDaySlotThisEvening.
  ///
  /// In en, this message translates to:
  /// **'This evening'**
  String get myDaySlotThisEvening;

  /// No description provided for @myDayTimelineSectionMorningPastTitle.
  ///
  /// In en, this message translates to:
  /// **'🌅 Morning'**
  String get myDayTimelineSectionMorningPastTitle;

  /// No description provided for @myDayTimelineSectionAfternoonPastTitle.
  ///
  /// In en, this message translates to:
  /// **'🌞 Afternoon'**
  String get myDayTimelineSectionAfternoonPastTitle;

  /// No description provided for @myDayWeekendEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your weekend is still empty!'**
  String get myDayWeekendEmptyTitle;

  /// No description provided for @myDayWeekendEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Want to plan Saturday or Sunday in advance?'**
  String get myDayWeekendEmptySubtitle;

  /// No description provided for @myDayWeekendSaturdayShort.
  ///
  /// In en, this message translates to:
  /// **'Sa {day}'**
  String myDayWeekendSaturdayShort(String day);

  /// No description provided for @myDayWeekendSundayShort.
  ///
  /// In en, this message translates to:
  /// **'Su {day}'**
  String myDayWeekendSundayShort(String day);

  /// No description provided for @placeCardFailedToShare.
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {error}'**
  String placeCardFailedToShare(String error);

  /// No description provided for @placeCardSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} saved!'**
  String placeCardSaved(String name);

  /// No description provided for @placeCardFailedToggleSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to update saved state for {name}'**
  String placeCardFailedToggleSave(String name);

  /// No description provided for @placeDetailSavedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'{name} saved to favorites!'**
  String placeDetailSavedToFavorites(String name);

  /// No description provided for @placeDetailSaveToggleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update saved place'**
  String get placeDetailSaveToggleFailed;

  /// No description provided for @placeDetailCouldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps: {error}'**
  String placeDetailCouldNotOpenMaps(String error);

  /// No description provided for @bookingSavedViewMyBookings.
  ///
  /// In en, this message translates to:
  /// **'Booking saved! View in My Bookings'**
  String get bookingSavedViewMyBookings;

  /// No description provided for @bookingViewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get bookingViewAction;

  /// No description provided for @bookingErrorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving booking: {error}'**
  String bookingErrorSaving(String error);

  /// No description provided for @bookingReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review booking'**
  String get bookingReviewTitle;

  /// No description provided for @bookingNoPaymentInAppBody.
  ///
  /// In en, this message translates to:
  /// **'WanderMood does not collect payment for venues in this app. What you save here is for your trip plan. Contact the place directly to reserve or pay.'**
  String get bookingNoPaymentInAppBody;

  /// No description provided for @bookingSaveToPlanCta.
  ///
  /// In en, this message translates to:
  /// **'Save to my plan'**
  String get bookingSaveToPlanCta;

  /// No description provided for @bookingEstimatedTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated total (not charged in app)'**
  String get bookingEstimatedTotalLabel;

  /// No description provided for @bookingPlanSavedHeader.
  ///
  /// In en, this message translates to:
  /// **'Plan saved'**
  String get bookingPlanSavedHeader;

  /// No description provided for @bookingAddedToPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Added to your plan!'**
  String get bookingAddedToPlanTitle;

  /// No description provided for @bookingAddedToPlanBody.
  ///
  /// In en, this message translates to:
  /// **'{placeName} is saved in My Bookings and your agenda. Final booking and payment are arranged with the venue — not through this app.'**
  String bookingAddedToPlanBody(String placeName);

  /// No description provided for @bookingReferenceLine.
  ///
  /// In en, this message translates to:
  /// **'Reference: {reference}'**
  String bookingReferenceLine(String reference);

  /// No description provided for @bookingSectionTotalEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get bookingSectionTotalEstimate;

  /// No description provided for @bookingGuestsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 guest} other{{count} guests}}'**
  String bookingGuestsSummary(int count);

  /// No description provided for @gygCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied 💚'**
  String get gygCodeCopied;

  /// No description provided for @placeCardSeeActivity.
  ///
  /// In en, this message translates to:
  /// **'See activity'**
  String get placeCardSeeActivity;

  /// No description provided for @placeCardPriceVaries.
  ///
  /// In en, this message translates to:
  /// **'Price varies'**
  String get placeCardPriceVaries;

  /// No description provided for @gygEdviennePicksInCity.
  ///
  /// In en, this message translates to:
  /// **'✨ Edvienne\'s Picks in {city}'**
  String gygEdviennePicksInCity(String city);

  /// No description provided for @gygMapCompactTitle.
  ///
  /// In en, this message translates to:
  /// **'Edvienne\'s Picks — {city}'**
  String gygMapCompactTitle(String city);

  /// No description provided for @gygMapCompactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to open GetYourGuide & your discount'**
  String get gygMapCompactSubtitle;

  /// No description provided for @gygPrimaryTitleInCity.
  ///
  /// In en, this message translates to:
  /// **'✨ Edvienne\'s Picks in {city}'**
  String gygPrimaryTitleInCity(String city);

  /// No description provided for @gygTagline48h.
  ///
  /// In en, this message translates to:
  /// **'What I\'d book if I had 48 hours here 🤍'**
  String get gygTagline48h;

  /// No description provided for @gygOpenInApp.
  ///
  /// In en, this message translates to:
  /// **'Open in GetYourGuide app (with promo)'**
  String get gygOpenInApp;

  /// No description provided for @gygOpenInWeb.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get gygOpenInWeb;

  /// No description provided for @gygPromoGift.
  ///
  /// In en, this message translates to:
  /// **'🎁 A little extra from me: {code}'**
  String gygPromoGift(String code);

  /// No description provided for @gygPromoAppOnly.
  ///
  /// In en, this message translates to:
  /// **'Valid only in the GetYourGuide app.'**
  String get gygPromoAppOnly;

  /// No description provided for @gygCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get gygCopy;

  /// No description provided for @gygPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by GetYourGuide'**
  String get gygPoweredBy;

  /// No description provided for @gygComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'I\'m still curating the best picks for this city 🤍'**
  String get gygComingSoonBody;

  /// No description provided for @gygCategoryFoodDrink.
  ///
  /// In en, this message translates to:
  /// **'🍴 Food & drink'**
  String get gygCategoryFoodDrink;

  /// No description provided for @gygCategoryBoatTours.
  ///
  /// In en, this message translates to:
  /// **'⛵ Boat tours'**
  String get gygCategoryBoatTours;

  /// No description provided for @gygCategoryCulture.
  ///
  /// In en, this message translates to:
  /// **'🎭 Culture'**
  String get gygCategoryCulture;

  /// No description provided for @gygCategoryAdventure.
  ///
  /// In en, this message translates to:
  /// **'🧗 Adventure'**
  String get gygCategoryAdventure;

  /// No description provided for @gygCategoryLuxury.
  ///
  /// In en, this message translates to:
  /// **'✨ Luxury'**
  String get gygCategoryLuxury;

  /// No description provided for @socialNewMessageComingSoon.
  ///
  /// In en, this message translates to:
  /// **'New message feature coming soon!'**
  String get socialNewMessageComingSoon;

  /// No description provided for @socialSearchMessagesHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get socialSearchMessagesHint;

  /// No description provided for @socialCallComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Call feature coming soon!'**
  String get socialCallComingSoon;

  /// No description provided for @socialVideoCallComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Video call feature coming soon!'**
  String get socialVideoCallComingSoon;

  /// No description provided for @socialPhotoSharingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Photo sharing coming soon!'**
  String get socialPhotoSharingComingSoon;

  /// No description provided for @socialTypeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get socialTypeMessageHint;

  /// No description provided for @socialReportUser.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get socialReportUser;

  /// No description provided for @socialBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get socialBlockUser;

  /// No description provided for @socialShareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get socialShareProfile;

  /// No description provided for @socialMessageTraveler.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String socialMessageTraveler(String name);

  /// No description provided for @socialWriteMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write your message...'**
  String get socialWriteMessageHint;

  /// No description provided for @socialMessageSentTo.
  ///
  /// In en, this message translates to:
  /// **'Message sent to {name}!'**
  String socialMessageSentTo(String name);

  /// No description provided for @socialSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get socialSend;

  /// No description provided for @socialUserReportedThankYou.
  ///
  /// In en, this message translates to:
  /// **'User reported. Thank you for keeping our community safe.'**
  String get socialUserReportedThankYou;

  /// No description provided for @socialUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} has been blocked.'**
  String socialUserBlocked(String name);

  /// No description provided for @socialProfileShared.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s profile shared!'**
  String socialProfileShared(String name);

  /// No description provided for @socialSavedPostsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Saved posts are not available yet.'**
  String get socialSavedPostsUnavailable;

  /// No description provided for @socialCloseFriendsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Close friends is not available yet.'**
  String get socialCloseFriendsUnavailable;

  /// No description provided for @socialMarkAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get socialMarkAsRead;

  /// No description provided for @socialMarkAsUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get socialMarkAsUnread;

  /// No description provided for @socialFollowBack.
  ///
  /// In en, this message translates to:
  /// **'Follow Back'**
  String get socialFollowBack;

  /// No description provided for @socialViewPost.
  ///
  /// In en, this message translates to:
  /// **'View Post'**
  String get socialViewPost;

  /// No description provided for @socialReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get socialReply;

  /// No description provided for @socialAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get socialAccept;

  /// No description provided for @socialFilteringBy.
  ///
  /// In en, this message translates to:
  /// **'Filtering by: {filter}'**
  String socialFilteringBy(String filter);

  /// No description provided for @socialOpeningPost.
  ///
  /// In en, this message translates to:
  /// **'Opening post...'**
  String get socialOpeningPost;

  /// No description provided for @socialOpeningUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Opening {name} profile...'**
  String socialOpeningUserProfile(String name);

  /// No description provided for @socialOpeningTrendingPost.
  ///
  /// In en, this message translates to:
  /// **'Opening trending post...'**
  String get socialOpeningTrendingPost;

  /// No description provided for @socialOpeningMention.
  ///
  /// In en, this message translates to:
  /// **'Opening mention...'**
  String get socialOpeningMention;

  /// No description provided for @socialFollowingUser.
  ///
  /// In en, this message translates to:
  /// **'Following {name}!'**
  String socialFollowingUser(String name);

  /// No description provided for @socialReplyToComment.
  ///
  /// In en, this message translates to:
  /// **'Reply to Comment'**
  String get socialReplyToComment;

  /// No description provided for @socialWriteReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reply...'**
  String get socialWriteReplyHint;

  /// No description provided for @socialReplySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent!'**
  String get socialReplySent;

  /// No description provided for @socialRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted!'**
  String get socialRequestAccepted;

  /// No description provided for @socialOpeningContent.
  ///
  /// In en, this message translates to:
  /// **'Opening content...'**
  String get socialOpeningContent;

  /// No description provided for @socialNotificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get socialNotificationDeleted;

  /// No description provided for @socialUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get socialUndo;

  /// No description provided for @socialClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get socialClose;

  /// No description provided for @socialToggleState.
  ///
  /// In en, this message translates to:
  /// **'{title} {state}'**
  String socialToggleState(String title, String state);

  /// No description provided for @socialAllNotificationsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get socialAllNotificationsRead;

  /// No description provided for @socialYouHaveNewNotifications.
  ///
  /// In en, this message translates to:
  /// **'You have {count} new notifications'**
  String socialYouHaveNewNotifications(String count);

  /// No description provided for @socialSampleNotificationLiked.
  ///
  /// In en, this message translates to:
  /// **'• Sarah liked your post'**
  String get socialSampleNotificationLiked;

  /// No description provided for @socialSampleNotificationFollowed.
  ///
  /// In en, this message translates to:
  /// **'• Marco started following you'**
  String get socialSampleNotificationFollowed;

  /// No description provided for @socialSampleNotificationStory.
  ///
  /// In en, this message translates to:
  /// **'• New travel story from Luna'**
  String get socialSampleNotificationStory;

  /// No description provided for @notificationCardDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get notificationCardDeleteTooltip;

  /// No description provided for @notificationCentreMoodMatchTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Planning together'**
  String get notificationCentreMoodMatchTimelineTitle;

  /// No description provided for @notificationCentreMoodMatchTimelineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A calm timeline of your Mood Match.'**
  String get notificationCentreMoodMatchTimelineSubtitle;

  /// No description provided for @notificationCentreTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get notificationCentreTitle;

  /// No description provided for @notificationCentreEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Nothing new — you\'re all caught up. I\'ll let you know when something happens.'**
  String get notificationCentreEmptyState;

  /// No description provided for @notificationCentreMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationCentreMarkAllRead;

  /// No description provided for @notificationCentreSectionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get notificationCentreSectionNew;

  /// No description provided for @notificationCentreSectionEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notificationCentreSectionEarlier;

  /// No description provided for @notificationCentreReadDividerLabel.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationCentreReadDividerLabel;

  /// No description provided for @notificationCentreAllFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationCentreAllFilter;

  /// No description provided for @notificationCentreActivitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get notificationCentreActivitiesLabel;

  /// No description provided for @notificationCentreSocialLabel.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get notificationCentreSocialLabel;

  /// No description provided for @notificationCentreMoodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Moody'**
  String get notificationCentreMoodyLabel;

  /// No description provided for @notificationCentreCategoryMoodMatch.
  ///
  /// In en, this message translates to:
  /// **'Mood Match'**
  String get notificationCentreCategoryMoodMatch;

  /// No description provided for @notificationCentreRelativeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String notificationCentreRelativeMinutesAgo(int count);

  /// No description provided for @socialOpeningAllTravelStories.
  ///
  /// In en, this message translates to:
  /// **'Opening all travel stories...'**
  String get socialOpeningAllTravelStories;

  /// No description provided for @socialOpeningUserStory.
  ///
  /// In en, this message translates to:
  /// **'Opening {name}\'s story...'**
  String socialOpeningUserStory(String name);

  /// No description provided for @socialSavePost.
  ///
  /// In en, this message translates to:
  /// **'Save Post'**
  String get socialSavePost;

  /// No description provided for @socialFollowUser.
  ///
  /// In en, this message translates to:
  /// **'Follow {name}'**
  String socialFollowUser(String name);

  /// No description provided for @socialReportPost.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get socialReportPost;

  /// No description provided for @socialLikedUserPost.
  ///
  /// In en, this message translates to:
  /// **'Liked {name}\'s post!'**
  String socialLikedUserPost(String name);

  /// No description provided for @socialCommentOnUserPost.
  ///
  /// In en, this message translates to:
  /// **'Comment on {name}\'s post'**
  String socialCommentOnUserPost(String name);

  /// No description provided for @socialWriteCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get socialWriteCommentHint;

  /// No description provided for @socialCommentPosted.
  ///
  /// In en, this message translates to:
  /// **'Comment posted!'**
  String get socialCommentPosted;

  /// No description provided for @socialPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get socialPost;

  /// No description provided for @socialSharedUserPost.
  ///
  /// In en, this message translates to:
  /// **'Shared {name}\'s post!'**
  String socialSharedUserPost(String name);

  /// No description provided for @socialSavedUserPost.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}\'s post!'**
  String socialSavedUserPost(String name);

  /// No description provided for @socialReportedUserPost.
  ///
  /// In en, this message translates to:
  /// **'Reported {name}\'s post'**
  String socialReportedUserPost(String name);

  /// No description provided for @socialShareComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share feature coming soon!'**
  String get socialShareComingSoon;

  /// No description provided for @socialFoundPostsWithTag.
  ///
  /// In en, this message translates to:
  /// **'Found {count} posts with #{tag}'**
  String socialFoundPostsWithTag(String count, String tag);

  /// No description provided for @socialLinkCopiedClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get socialLinkCopiedClipboard;

  /// No description provided for @socialAddCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get socialAddCommentHint;

  /// No description provided for @socialCommentFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Comment feature coming soon!'**
  String get socialCommentFeatureComingSoon;

  /// No description provided for @socialRemovedFromCollection.
  ///
  /// In en, this message translates to:
  /// **'{place} removed from {collection}'**
  String socialRemovedFromCollection(String place, String collection);

  /// No description provided for @socialEditCollection.
  ///
  /// In en, this message translates to:
  /// **'Edit collection'**
  String get socialEditCollection;

  /// No description provided for @socialCollectionName.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get socialCollectionName;

  /// No description provided for @socialDeleteCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete collection?'**
  String get socialDeleteCollectionTitle;

  /// No description provided for @socialPickDayForPlan.
  ///
  /// In en, this message translates to:
  /// **'Pick day for plan'**
  String get socialPickDayForPlan;

  /// No description provided for @socialDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get socialDay;

  /// No description provided for @socialTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get socialTime;

  /// No description provided for @socialAddToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get socialAddToCollection;

  /// No description provided for @socialRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String socialRemoved(String name);

  /// No description provided for @socialCollectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rotterdam weekend, Kid-friendly…'**
  String get socialCollectionNameHint;

  /// No description provided for @socialCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get socialCreate;

  /// No description provided for @socialMessagingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Messaging feature coming soon!'**
  String get socialMessagingComingSoon;

  /// No description provided for @socialQrSharingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'QR code sharing coming soon!'**
  String get socialQrSharingComingSoon;

  /// No description provided for @socialReportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Report feature coming soon!'**
  String get socialReportComingSoon;

  /// No description provided for @socialBlockComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Block feature coming soon!'**
  String get socialBlockComingSoon;

  /// No description provided for @socialUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get socialUserNotFound;

  /// No description provided for @socialPleaseSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Please select an image'**
  String get socialPleaseSelectImage;

  /// No description provided for @socialStoryPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Story posted successfully!'**
  String get socialStoryPostedSuccess;

  /// No description provided for @socialCreateStory.
  ///
  /// In en, this message translates to:
  /// **'Create Story'**
  String get socialCreateStory;

  /// No description provided for @socialTapAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a photo'**
  String get socialTapAddPhoto;

  /// No description provided for @socialAddStoryCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption to your story...'**
  String get socialAddStoryCaptionHint;

  /// No description provided for @socialAddLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get socialAddLocation;

  /// No description provided for @socialLocationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Location feature coming soon!'**
  String get socialLocationComingSoon;

  /// No description provided for @socialActivityTaggingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Activity tagging coming soon!'**
  String get socialActivityTaggingComingSoon;

  /// No description provided for @socialNameUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and username are required'**
  String get socialNameUsernameRequired;

  /// No description provided for @socialSelectUpToTags.
  ///
  /// In en, this message translates to:
  /// **'You can select up to {count} tags'**
  String socialSelectUpToTags(String count);

  /// No description provided for @socialPleaseAddOneImage.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one image'**
  String get socialPleaseAddOneImage;

  /// No description provided for @socialPostCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post created successfully!'**
  String get socialPostCreatedSuccess;

  /// No description provided for @socialCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get socialCreatePost;

  /// No description provided for @socialAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get socialAddPhotos;

  /// No description provided for @socialAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get socialAddMore;

  /// No description provided for @socialWriteCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write a caption...'**
  String get socialWriteCaptionHint;

  /// No description provided for @moodySpeechNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is not available on this device'**
  String get moodySpeechNotAvailable;

  /// No description provided for @socialFailedSharePost.
  ///
  /// In en, this message translates to:
  /// **'Failed to share post: {error}'**
  String socialFailedSharePost(String error);

  /// No description provided for @socialViewingPostsTagged.
  ///
  /// In en, this message translates to:
  /// **'Viewing posts tagged with #{tag}'**
  String socialViewingPostsTagged(String tag);

  /// No description provided for @socialSearchTravelersHint.
  ///
  /// In en, this message translates to:
  /// **'Search travelers by name or interests...'**
  String get socialSearchTravelersHint;

  /// No description provided for @socialConnectionRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Connection request sent to {name}!'**
  String socialConnectionRequestSent(String name);

  /// No description provided for @socialViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get socialViewProfile;

  /// No description provided for @socialSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get socialSendRequest;

  /// No description provided for @socialProfileUpdatedDevMode.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully! (Development mode)'**
  String get socialProfileUpdatedDevMode;

  /// No description provided for @socialErrorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {error}'**
  String socialErrorUpdatingProfile(String error);

  /// No description provided for @socialUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get socialUploadingPhoto;

  /// No description provided for @socialErrorUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error uploading photo: {error}'**
  String socialErrorUploadingPhoto(String error);

  /// No description provided for @socialEditProfileInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile Info'**
  String get socialEditProfileInfo;

  /// No description provided for @myDayAddSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to add activities.'**
  String get myDayAddSignInRequired;

  /// No description provided for @myDayAddFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Could not add activity. Please try again.'**
  String get myDayAddFailedTryAgain;

  /// No description provided for @activityOptionsViewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get activityOptionsViewAction;

  /// No description provided for @exploreNoPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get exploreNoPlacesFound;

  /// Subtitle shown below 'No places found'
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or adjust your filters.'**
  String get exploreNoPlacesFoundHint;

  /// Loading indicator while a search is in progress
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get exploreSearching;

  /// No description provided for @agendaChooseActivityForDay.
  ///
  /// In en, this message translates to:
  /// **'Choose an activity to add for {day}.'**
  String agendaChooseActivityForDay(String day);

  /// No description provided for @agendaLoadingActivities.
  ///
  /// In en, this message translates to:
  /// **'Loading activities...'**
  String get agendaLoadingActivities;

  /// No description provided for @agendaErrorLoadingActivities.
  ///
  /// In en, this message translates to:
  /// **'Error loading activities'**
  String get agendaErrorLoadingActivities;

  /// No description provided for @agendaPleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get agendaPleaseTryAgainLater;

  /// No description provided for @agendaNoActivitiesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No activities scheduled'**
  String get agendaNoActivitiesScheduled;

  /// No description provided for @agendaNoActivitiesPlannedYet.
  ///
  /// In en, this message translates to:
  /// **'You do not have any planned activities in My Plans yet'**
  String get agendaNoActivitiesPlannedYet;

  /// No description provided for @agendaDeleteMissingId.
  ///
  /// In en, this message translates to:
  /// **'Could not delete activity (missing id).'**
  String get agendaDeleteMissingId;

  /// No description provided for @agendaRemovedFromPlanner.
  ///
  /// In en, this message translates to:
  /// **'{title} removed from your planner.'**
  String agendaRemovedFromPlanner(String title);

  /// No description provided for @socialGetDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get socialGetDirections;

  /// No description provided for @socialShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get socialShare;

  /// No description provided for @socialOpenDirectionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open directions'**
  String get socialOpenDirectionsFailed;

  /// No description provided for @socialDeleteActivityConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete activity?'**
  String get socialDeleteActivityConfirmTitle;

  /// No description provided for @socialDeleteFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Delete failed. Please try again.'**
  String get socialDeleteFailedTryAgain;

  /// No description provided for @socialShareActivityDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Activity details copied to share'**
  String get socialShareActivityDetailsCopied;

  /// No description provided for @dailyScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Schedule'**
  String get dailyScheduleTitle;

  /// No description provided for @dailyScheduleToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dailyScheduleToday;

  /// No description provided for @dailyScheduleTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dailyScheduleTomorrow;

  /// No description provided for @dailyScheduleNoActivities.
  ///
  /// In en, this message translates to:
  /// **'No activities scheduled'**
  String get dailyScheduleNoActivities;

  /// No description provided for @dailyScheduleExplorePrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to explore activities'**
  String get dailyScheduleExplorePrompt;

  /// No description provided for @dailyScheduleExploreActivities.
  ///
  /// In en, this message translates to:
  /// **'Explore Activities'**
  String get dailyScheduleExploreActivities;

  /// No description provided for @dailyScheduleUpcomingActivities.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Activities'**
  String get dailyScheduleUpcomingActivities;

  /// No description provided for @dailyScheduleCompletedActivities.
  ///
  /// In en, this message translates to:
  /// **'Completed Activities'**
  String get dailyScheduleCompletedActivities;

  /// No description provided for @dailyScheduleActivitiesPlanned.
  ///
  /// In en, this message translates to:
  /// **'{count} activities planned'**
  String dailyScheduleActivitiesPlanned(String count);

  /// No description provided for @dailyScheduleActivitiesCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} activities completed'**
  String dailyScheduleActivitiesCompleted(String count);

  /// No description provided for @dailyScheduleNoActivitiesForDate.
  ///
  /// In en, this message translates to:
  /// **'No activities scheduled for this date'**
  String get dailyScheduleNoActivitiesForDate;

  /// No description provided for @dailyScheduleConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get dailyScheduleConfirmed;

  /// No description provided for @dailyScheduleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dailyScheduleCompleted;

  /// No description provided for @dailyScheduleDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String dailyScheduleDurationMinutes(String minutes);

  /// No description provided for @signupNoPasswordNeeded.
  ///
  /// In en, this message translates to:
  /// **'This is WanderMood — I\'ll do this for you whenever you feel like it 😌'**
  String get signupNoPasswordNeeded;

  /// No description provided for @signupRatingBadge.
  ///
  /// In en, this message translates to:
  /// **'No password'**
  String get signupRatingBadge;

  /// No description provided for @signupPrivacyPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get signupPrivacyPrefix;

  /// No description provided for @signupPrivacyLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get signupPrivacyLinkLabel;

  /// No description provided for @signupSuccessCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'I just sent you something ✉️'**
  String get signupSuccessCheckInbox;

  /// No description provided for @signupSuccessTapLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the link — I\'ll be there 😌'**
  String get signupSuccessTapLinkSubtitle;

  /// No description provided for @signupSuccessSentToLine.
  ///
  /// In en, this message translates to:
  /// **'Sent to: {email}'**
  String signupSuccessSentToLine(String email);

  /// No description provided for @signupOpenGmail.
  ///
  /// In en, this message translates to:
  /// **'Open Gmail'**
  String get signupOpenGmail;

  /// No description provided for @signupOpenOutlook.
  ///
  /// In en, this message translates to:
  /// **'Open Outlook'**
  String get signupOpenOutlook;

  /// No description provided for @signupOpenAppleMail.
  ///
  /// In en, this message translates to:
  /// **'Open Apple Mail'**
  String get signupOpenAppleMail;

  /// No description provided for @signupOpenEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Open your email'**
  String get signupOpenEmailApp;

  /// No description provided for @signupInboxFooterPrefix.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it? '**
  String get signupInboxFooterPrefix;

  /// No description provided for @signupInboxFooterResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get signupInboxFooterResend;

  /// No description provided for @signupInboxFooterOr.
  ///
  /// In en, this message translates to:
  /// **' or '**
  String get signupInboxFooterOr;

  /// No description provided for @signupInboxFooterChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'change email'**
  String get signupInboxFooterChangeEmail;

  /// No description provided for @introHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Your mood,'**
  String get introHeadline1;

  /// No description provided for @introHeadline2.
  ///
  /// In en, this message translates to:
  /// **'your adventure'**
  String get introHeadline2;

  /// No description provided for @onboardingLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m getting to know you! 🧠'**
  String get onboardingLoadingTitle;

  /// No description provided for @onboardingLoadingSubtitle0.
  ///
  /// In en, this message translates to:
  /// **'Saving your interests...'**
  String get onboardingLoadingSubtitle0;

  /// No description provided for @onboardingLoadingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Tuning your style...'**
  String get onboardingLoadingSubtitle1;

  /// No description provided for @onboardingLoadingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Finding places that fit you...'**
  String get onboardingLoadingSubtitle2;

  /// No description provided for @onboardingLoadingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Getting myself ready for you...'**
  String get onboardingLoadingSubtitle3;

  /// No description provided for @onboardingLoadingFooter.
  ///
  /// In en, this message translates to:
  /// **'This\'ll just take a moment ✨'**
  String get onboardingLoadingFooter;

  /// No description provided for @demoModeLabel.
  ///
  /// In en, this message translates to:
  /// **'▶ Demo mode'**
  String get demoModeLabel;

  /// No description provided for @demoSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get demoSkip;

  /// No description provided for @demoTapToChooseMood.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose your mood:'**
  String get demoTapToChooseMood;

  /// No description provided for @demoDiscoverMore.
  ///
  /// In en, this message translates to:
  /// **'Discover more →'**
  String get demoDiscoverMore;

  /// No description provided for @demoMoodSurpriseMe.
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get demoMoodSurpriseMe;

  /// No description provided for @demoMoodyGreetingLine2.
  ///
  /// In en, this message translates to:
  /// **'Tell me what kind of day you\'re after — I\'ll take care of the rest.'**
  String get demoMoodyGreetingLine2;

  /// No description provided for @demoMoodyQuestion.
  ///
  /// In en, this message translates to:
  /// **'So… what kind of day are we having?'**
  String get demoMoodyQuestion;

  /// No description provided for @demoUserReplyRelaxed.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling relaxed'**
  String get demoUserReplyRelaxed;

  /// No description provided for @demoUserReplyAdventurous.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling adventurous'**
  String get demoUserReplyAdventurous;

  /// No description provided for @demoUserReplyRomantic.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling romantic'**
  String get demoUserReplyRomantic;

  /// No description provided for @demoUserReplyCultural.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling cultural'**
  String get demoUserReplyCultural;

  /// No description provided for @demoUserReplyFoodie.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling like a foodie'**
  String get demoUserReplyFoodie;

  /// No description provided for @demoUserReplySocial.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling social'**
  String get demoUserReplySocial;

  /// No description provided for @demoUserReplySurpriseMe.
  ///
  /// In en, this message translates to:
  /// **'Surprise me!'**
  String get demoUserReplySurpriseMe;

  /// No description provided for @demoUserReplyDefault.
  ///
  /// In en, this message translates to:
  /// **'This is my mood!'**
  String get demoUserReplyDefault;

  /// No description provided for @demoMoodReactionRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Soft mornings and slow moments—I\'ve got you.'**
  String get demoMoodReactionRelaxed;

  /// No description provided for @demoMoodReactionFoodie.
  ///
  /// In en, this message translates to:
  /// **'We\'re eating well today.'**
  String get demoMoodReactionFoodie;

  /// No description provided for @demoMoodReactionEnergetic.
  ///
  /// In en, this message translates to:
  /// **'High energy—let\'s make it count.'**
  String get demoMoodReactionEnergetic;

  /// No description provided for @demoMoodReactionAdventurous.
  ///
  /// In en, this message translates to:
  /// **'Adventure mode activated.'**
  String get demoMoodReactionAdventurous;

  /// No description provided for @demoMoodReactionCultural.
  ///
  /// In en, this message translates to:
  /// **'Curiosity looks good on you.'**
  String get demoMoodReactionCultural;

  /// No description provided for @demoMoodReactionCozy.
  ///
  /// In en, this message translates to:
  /// **'Cozy, quiet, and just right.'**
  String get demoMoodReactionCozy;

  /// No description provided for @demoMoodReactionSurprise.
  ///
  /// In en, this message translates to:
  /// **'A little mystery—I\'ve got ideas for you. ✨'**
  String get demoMoodReactionSurprise;

  /// No description provided for @demoMoodReactionDefault.
  ///
  /// In en, this message translates to:
  /// **'Love it—let\'s shape your day.'**
  String get demoMoodReactionDefault;

  /// No description provided for @demoPuttingDayTogether.
  ///
  /// In en, this message translates to:
  /// **'Putting your day together…'**
  String get demoPuttingDayTogether;

  /// No description provided for @guestDemoResultTitlePicked.
  ///
  /// In en, this message translates to:
  /// **'I picked these for you'**
  String get guestDemoResultTitlePicked;

  /// No description provided for @guestDemoResultTitleWithMood.
  ///
  /// In en, this message translates to:
  /// **'{moodLabel}'**
  String guestDemoResultTitleWithMood(String moodLabel);

  /// No description provided for @guestDemoDayPlanMoodyBlurb.
  ///
  /// In en, this message translates to:
  /// **'I put this together for you — start here 👇'**
  String get guestDemoDayPlanMoodyBlurb;

  /// No description provided for @guestDemoPreviewAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Rotterdam city center · demo pins'**
  String get guestDemoPreviewAreaLabel;

  /// No description provided for @guestDayPlanHeadingMadeForYou.
  ///
  /// In en, this message translates to:
  /// **'I made this for you'**
  String get guestDayPlanHeadingMadeForYou;

  /// No description provided for @guestDayPlanHeroHint.
  ///
  /// In en, this message translates to:
  /// **'Tap any stop for details, photos & reviews.'**
  String get guestDayPlanHeroHint;

  /// No description provided for @guestDayPlanContinueWithMoody.
  ///
  /// In en, this message translates to:
  /// **'Continue with Moody'**
  String get guestDayPlanContinueWithMoody;

  /// No description provided for @guestDemoMoodyRelaxed0.
  ///
  /// In en, this message translates to:
  /// **'Trees first, screens later. 🌿'**
  String get guestDemoMoodyRelaxed0;

  /// No description provided for @guestDemoMoodyRelaxed1.
  ///
  /// In en, this message translates to:
  /// **'You moved — now melt into the chair. ☕'**
  String get guestDemoMoodyRelaxed1;

  /// No description provided for @guestDemoMoodyRelaxed2.
  ///
  /// In en, this message translates to:
  /// **'Golden hour hits different from this spot 🌅'**
  String get guestDemoMoodyRelaxed2;

  /// No description provided for @guestDemoMoodyFoodie0.
  ///
  /// In en, this message translates to:
  /// **'Still warm, good coffee — exactly how your day should start ☕'**
  String get guestDemoMoodyFoodie0;

  /// No description provided for @guestDemoMoodyFoodie1.
  ///
  /// In en, this message translates to:
  /// **'Get here early… these sell out fast 🥐'**
  String get guestDemoMoodyFoodie1;

  /// No description provided for @guestDemoMoodyFoodie2.
  ///
  /// In en, this message translates to:
  /// **'Come hungry — portions are generous 🍽️'**
  String get guestDemoMoodyFoodie2;

  /// No description provided for @guestDemoMoodySocial0.
  ///
  /// In en, this message translates to:
  /// **'Easy to slide in solo or with friends — the vibe is welcoming 🎉'**
  String get guestDemoMoodySocial0;

  /// No description provided for @guestDemoMoodySocial1.
  ///
  /// In en, this message translates to:
  /// **'Pull up a bench — someone’s always finishing a story. 🥗'**
  String get guestDemoMoodySocial1;

  /// No description provided for @guestDemoMoodySocial2.
  ///
  /// In en, this message translates to:
  /// **'Strike up a chat at the bar; regulars love newcomers 👋'**
  String get guestDemoMoodySocial2;

  /// No description provided for @guestDemoMoodyAdventurous0.
  ///
  /// In en, this message translates to:
  /// **'Earn the view — then earn lunch. 🥾'**
  String get guestDemoMoodyAdventurous0;

  /// No description provided for @guestDemoMoodyAdventurous1.
  ///
  /// In en, this message translates to:
  /// **'You crushed the climb — now let the harbor do the work. 🛥️'**
  String get guestDemoMoodyAdventurous1;

  /// No description provided for @guestDemoMoodyAdventurous2.
  ///
  /// In en, this message translates to:
  /// **'Let the day’s noise fade into golden hour. 🌇'**
  String get guestDemoMoodyAdventurous2;

  /// No description provided for @guestDemoMoodyCultural0.
  ///
  /// In en, this message translates to:
  /// **'Give yourself time to read every plaque 🏛️'**
  String get guestDemoMoodyCultural0;

  /// No description provided for @guestDemoMoodyCultural1.
  ///
  /// In en, this message translates to:
  /// **'Museum brain off, espresso on. ☕'**
  String get guestDemoMoodyCultural1;

  /// No description provided for @guestDemoMoodyCultural2.
  ///
  /// In en, this message translates to:
  /// **'Culture, but make it unbuttoned-collar. 🎷'**
  String get guestDemoMoodyCultural2;

  /// No description provided for @guestDemoMoodyRomantic0.
  ///
  /// In en, this message translates to:
  /// **'Low lights, shared plates — keep the phones away.'**
  String get guestDemoMoodyRomantic0;

  /// No description provided for @guestDemoMoodyRomantic1.
  ///
  /// In en, this message translates to:
  /// **'Ask for a corner table if you can — worth it 🕯️'**
  String get guestDemoMoodyRomantic1;

  /// No description provided for @guestDemoMoodyRomantic2.
  ///
  /// In en, this message translates to:
  /// **'Split dessert. Non-negotiable 🍰'**
  String get guestDemoMoodyRomantic2;

  /// No description provided for @guestDemoTagWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get guestDemoTagWalk;

  /// No description provided for @guestDemoTagNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get guestDemoTagNature;

  /// No description provided for @guestDemoTagCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get guestDemoTagCafe;

  /// No description provided for @guestDemoTagCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get guestDemoTagCalm;

  /// No description provided for @guestDemoTagRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get guestDemoTagRestaurant;

  /// No description provided for @guestDemoTagSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get guestDemoTagSunset;

  /// No description provided for @guestDemoTagBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get guestDemoTagBreakfast;

  /// No description provided for @guestDemoTagMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get guestDemoTagMarket;

  /// No description provided for @guestDemoTagLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get guestDemoTagLunch;

  /// No description provided for @guestDemoTagDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get guestDemoTagDinner;

  /// No description provided for @guestDemoTagActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get guestDemoTagActive;

  /// No description provided for @guestDemoTagOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get guestDemoTagOutdoor;

  /// No description provided for @guestDemoTagNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get guestDemoTagNightlife;

  /// No description provided for @guestDemoTagMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get guestDemoTagMusic;

  /// No description provided for @guestDemoTagHiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get guestDemoTagHiking;

  /// No description provided for @guestDemoTagView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get guestDemoTagView;

  /// No description provided for @guestDemoTagBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get guestDemoTagBar;

  /// No description provided for @guestDemoTagMuseum.
  ///
  /// In en, this message translates to:
  /// **'Museum'**
  String get guestDemoTagMuseum;

  /// No description provided for @guestDemoTagArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get guestDemoTagArt;

  /// No description provided for @guestDemoTagGarden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get guestDemoTagGarden;

  /// No description provided for @guestDemoTagJazz.
  ///
  /// In en, this message translates to:
  /// **'Jazz'**
  String get guestDemoTagJazz;

  /// No description provided for @guestDemoTagWine.
  ///
  /// In en, this message translates to:
  /// **'Wine'**
  String get guestDemoTagWine;

  /// No description provided for @guestDemoTagCozy.
  ///
  /// In en, this message translates to:
  /// **'Cozy'**
  String get guestDemoTagCozy;

  /// No description provided for @guestDemoTagQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get guestDemoTagQuiet;

  /// No description provided for @guestDemoTagDrinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get guestDemoTagDrinks;

  /// No description provided for @guestDemoTagEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get guestDemoTagEvening;

  /// No description provided for @guestDemoRelaxed1Name.
  ///
  /// In en, this message translates to:
  /// **'Parkside Morning Reset'**
  String get guestDemoRelaxed1Name;

  /// No description provided for @guestDemoRelaxed1Meta.
  ///
  /// In en, this message translates to:
  /// **'09:00 • Free'**
  String get guestDemoRelaxed1Meta;

  /// No description provided for @guestDemoRelaxed1Desc.
  ///
  /// In en, this message translates to:
  /// **'Easy loops under the trees — wake the body without racing.'**
  String get guestDemoRelaxed1Desc;

  /// No description provided for @guestDemoRelaxed2Name.
  ///
  /// In en, this message translates to:
  /// **'Slow Matcha Counter'**
  String get guestDemoRelaxed2Name;

  /// No description provided for @guestDemoRelaxed2Meta.
  ///
  /// In en, this message translates to:
  /// **'12:30 • €€'**
  String get guestDemoRelaxed2Meta;

  /// No description provided for @guestDemoRelaxed2Desc.
  ///
  /// In en, this message translates to:
  /// **'Sit deep, sip slow — let the morning walk settle in.'**
  String get guestDemoRelaxed2Desc;

  /// No description provided for @guestDemoRelaxed3Name.
  ///
  /// In en, this message translates to:
  /// **'Sunset Terrace'**
  String get guestDemoRelaxed3Name;

  /// No description provided for @guestDemoRelaxed3Meta.
  ///
  /// In en, this message translates to:
  /// **'18:00 • €€€'**
  String get guestDemoRelaxed3Meta;

  /// No description provided for @guestDemoRelaxed3Desc.
  ///
  /// In en, this message translates to:
  /// **'Golden hour, one drink, nowhere to be.'**
  String get guestDemoRelaxed3Desc;

  /// No description provided for @guestDemoFoodie1Name.
  ///
  /// In en, this message translates to:
  /// **'Oven & Oak Bakery'**
  String get guestDemoFoodie1Name;

  /// No description provided for @guestDemoFoodie1Meta.
  ///
  /// In en, this message translates to:
  /// **'08:00 • €'**
  String get guestDemoFoodie1Meta;

  /// No description provided for @guestDemoFoodie1Desc.
  ///
  /// In en, this message translates to:
  /// **'Fresh pastries and coffee to start the day.'**
  String get guestDemoFoodie1Desc;

  /// No description provided for @guestDemoFoodie2Name.
  ///
  /// In en, this message translates to:
  /// **'Market Hall Bites'**
  String get guestDemoFoodie2Name;

  /// No description provided for @guestDemoFoodie2Meta.
  ///
  /// In en, this message translates to:
  /// **'12:00 • €€'**
  String get guestDemoFoodie2Meta;

  /// No description provided for @guestDemoFoodie2Desc.
  ///
  /// In en, this message translates to:
  /// **'Tasting trays from local vendors.'**
  String get guestDemoFoodie2Desc;

  /// No description provided for @guestDemoFoodie3Name.
  ///
  /// In en, this message translates to:
  /// **'Chef\'s Table Pop-up'**
  String get guestDemoFoodie3Name;

  /// No description provided for @guestDemoFoodie3Meta.
  ///
  /// In en, this message translates to:
  /// **'19:00 • €€€'**
  String get guestDemoFoodie3Meta;

  /// No description provided for @guestDemoFoodie3Desc.
  ///
  /// In en, this message translates to:
  /// **'Small plates and seasonal specials.'**
  String get guestDemoFoodie3Desc;

  /// No description provided for @guestDemoSocial1Name.
  ///
  /// In en, this message translates to:
  /// **'Park Run Meet-up'**
  String get guestDemoSocial1Name;

  /// No description provided for @guestDemoSocial1Meta.
  ///
  /// In en, this message translates to:
  /// **'07:30 • Free'**
  String get guestDemoSocial1Meta;

  /// No description provided for @guestDemoSocial1Desc.
  ///
  /// In en, this message translates to:
  /// **'Quick miles with friendly faces.'**
  String get guestDemoSocial1Desc;

  /// No description provided for @guestDemoSocial2Name.
  ///
  /// In en, this message translates to:
  /// **'Market Hall Long Table'**
  String get guestDemoSocial2Name;

  /// No description provided for @guestDemoSocial2Meta.
  ///
  /// In en, this message translates to:
  /// **'13:00 • €€'**
  String get guestDemoSocial2Meta;

  /// No description provided for @guestDemoSocial2Desc.
  ///
  /// In en, this message translates to:
  /// **'Shared plates and easy chatter — recover together after the run.'**
  String get guestDemoSocial2Desc;

  /// No description provided for @guestDemoSocial3Name.
  ///
  /// In en, this message translates to:
  /// **'Late Live Set'**
  String get guestDemoSocial3Name;

  /// No description provided for @guestDemoSocial3Meta.
  ///
  /// In en, this message translates to:
  /// **'21:00 • €€'**
  String get guestDemoSocial3Meta;

  /// No description provided for @guestDemoSocial3Desc.
  ///
  /// In en, this message translates to:
  /// **'Loud speakers, cold drinks, big vibes.'**
  String get guestDemoSocial3Desc;

  /// No description provided for @guestDemoAdventurous1Name.
  ///
  /// In en, this message translates to:
  /// **'Ridge Sunrise Hike'**
  String get guestDemoAdventurous1Name;

  /// No description provided for @guestDemoAdventurous1Meta.
  ///
  /// In en, this message translates to:
  /// **'06:00 • Free'**
  String get guestDemoAdventurous1Meta;

  /// No description provided for @guestDemoAdventurous1Desc.
  ///
  /// In en, this message translates to:
  /// **'Steep trail, wide views, early start.'**
  String get guestDemoAdventurous1Desc;

  /// No description provided for @guestDemoAdventurous2Name.
  ///
  /// In en, this message translates to:
  /// **'Quayside Lunch Deck'**
  String get guestDemoAdventurous2Name;

  /// No description provided for @guestDemoAdventurous2Meta.
  ///
  /// In en, this message translates to:
  /// **'13:00 • €€'**
  String get guestDemoAdventurous2Meta;

  /// No description provided for @guestDemoAdventurous2Desc.
  ///
  /// In en, this message translates to:
  /// **'Long lunch with harbor views — legs up, calories back, no rush.'**
  String get guestDemoAdventurous2Desc;

  /// No description provided for @guestDemoAdventurous3Name.
  ///
  /// In en, this message translates to:
  /// **'Waterfront Sundown Bar'**
  String get guestDemoAdventurous3Name;

  /// No description provided for @guestDemoAdventurous3Meta.
  ///
  /// In en, this message translates to:
  /// **'19:00 • €€'**
  String get guestDemoAdventurous3Meta;

  /// No description provided for @guestDemoAdventurous3Desc.
  ///
  /// In en, this message translates to:
  /// **'Golden-hour drinks and small plates — land the day softly.'**
  String get guestDemoAdventurous3Desc;

  /// No description provided for @guestDemoCultural1Name.
  ///
  /// In en, this message translates to:
  /// **'Modern Wing Tour'**
  String get guestDemoCultural1Name;

  /// No description provided for @guestDemoCultural1Meta.
  ///
  /// In en, this message translates to:
  /// **'10:00 • €'**
  String get guestDemoCultural1Meta;

  /// No description provided for @guestDemoCultural1Desc.
  ///
  /// In en, this message translates to:
  /// **'Guided look at the new exhibition.'**
  String get guestDemoCultural1Desc;

  /// No description provided for @guestDemoCultural2Name.
  ///
  /// In en, this message translates to:
  /// **'Sculpture Garden Café'**
  String get guestDemoCultural2Name;

  /// No description provided for @guestDemoCultural2Meta.
  ///
  /// In en, this message translates to:
  /// **'14:00 • €'**
  String get guestDemoCultural2Meta;

  /// No description provided for @guestDemoCultural2Desc.
  ///
  /// In en, this message translates to:
  /// **'Espresso between wings — let what you saw sink in.'**
  String get guestDemoCultural2Desc;

  /// No description provided for @guestDemoCultural3Name.
  ///
  /// In en, this message translates to:
  /// **'Canal-Side Jazz Room'**
  String get guestDemoCultural3Name;

  /// No description provided for @guestDemoCultural3Meta.
  ///
  /// In en, this message translates to:
  /// **'20:00 • €€'**
  String get guestDemoCultural3Meta;

  /// No description provided for @guestDemoCultural3Desc.
  ///
  /// In en, this message translates to:
  /// **'Dim lights, small band — culture without the sprint finish.'**
  String get guestDemoCultural3Desc;

  /// No description provided for @guestDemoRomantic1Name.
  ///
  /// In en, this message translates to:
  /// **'Courtyard Café'**
  String get guestDemoRomantic1Name;

  /// No description provided for @guestDemoRomantic1Meta.
  ///
  /// In en, this message translates to:
  /// **'10:00 • €€'**
  String get guestDemoRomantic1Meta;

  /// No description provided for @guestDemoRomantic1Desc.
  ///
  /// In en, this message translates to:
  /// **'Quiet corners and shared pastries.'**
  String get guestDemoRomantic1Desc;

  /// No description provided for @guestDemoRomantic2Name.
  ///
  /// In en, this message translates to:
  /// **'Independent Bookshop Browse'**
  String get guestDemoRomantic2Name;

  /// No description provided for @guestDemoRomantic2Meta.
  ///
  /// In en, this message translates to:
  /// **'15:00 • €'**
  String get guestDemoRomantic2Meta;

  /// No description provided for @guestDemoRomantic2Desc.
  ///
  /// In en, this message translates to:
  /// **'Piles of reads and vinyl in the back.'**
  String get guestDemoRomantic2Desc;

  /// No description provided for @guestDemoRomantic3Name.
  ///
  /// In en, this message translates to:
  /// **'Low-lit Wine Room'**
  String get guestDemoRomantic3Name;

  /// No description provided for @guestDemoRomantic3Meta.
  ///
  /// In en, this message translates to:
  /// **'20:00 • €€€'**
  String get guestDemoRomantic3Meta;

  /// No description provided for @guestDemoRomantic3Desc.
  ///
  /// In en, this message translates to:
  /// **'Small pours, soft music, no rush.'**
  String get guestDemoRomantic3Desc;

  /// No description provided for @guestDemoRelaxed1MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nCity park with loops under mature trees—wide gravel paths, a duck pond pinch, and benches every few curves. Locals walk dogs, read on blankets; there is no entry fee.\n\n---\n🗺️ Layout & vibe\n\nMostly flat, stroller-friendly circuits (~2 km on the outer loop). Mornings are misty-quiet; you will hear more birds than traffic from here.\n\n---\n⏱️ Good to know\n\nFree to enter. Washrooms near the main entrance. After rain, shoes that forgive mud are a win.\n\n---\n💬 Moody says\n\nNo pace to hit—if you match steps to breath for one lap, you already won.'**
  String get guestDemoRelaxed1MoodyAbout;

  /// No description provided for @guestDemoRelaxed2MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nJapanese-style matcha bar: stone-ground ceremonial grade, oat and soy milk, and seasonal lattes (think sakura in spring, yuzu in winter). Pastries stay light—mochi muffins, sesame cookies, minimal sugar crash.\n\n---\n🪑 Space & vibe\n\nLow counter, matte ceramics, soft daylight. Baristas explain matcha grades without the lecture. Laptop corners exist, but phones-down regulars get the best foam.\n\n---\n⏱️ Good to know\n\nMid-range spend (snack + drink). Busy 12:00–14:00—slide in a bit earlier for a slower pour.\n\n---\n💬 Moody says\n\nSit until the morning you already had settles in your bones—that is the whole assignment.'**
  String get guestDemoRelaxed2MoodyAbout;

  /// No description provided for @guestDemoRelaxed3MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nRooftop terrace restaurant: Mediterranean-leaning small plates (mezze, grilled fish, burrata), natural wines by the glass, and bottles that lean Italian + Portuguese.\n\n---\n🌅 Why sunset works here\n\nWest-facing glass rail—the sky does the lighting design. Book ahead; walk-ins sometimes grab bar spots when lucky.\n\n---\n⏱️ Good to know\n\nUpper-mid price tier. Even summer evenings get breezy off the water—bring a light layer.\n\n---\n💬 Moody says\n\nOne drink, one horizon, zero inbox—pretend that is the only notification that matters.'**
  String get guestDemoRelaxed3MoodyAbout;

  /// No description provided for @guestDemoFoodie1MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nArtisan bakery + coffee bar: sourdough loaves, butter croissants laminated in-house, seasonal fruit tarts. Espresso rotates single-origin weekly; batch brew if you are sprinting.\n\n---\n🥐 What to order\n\nAsk for whatever left the oven in the last hour. Savory danishes vanish first on Saturdays.\n\n---\n⏱️ Good to know\n\nOpens early; expect a friendly line 09:00–10:30 weekends. Card-only at the counter.\n\n---\n💬 Moody says\n\nCrumbs on your sleeve count as a five-star review—lean in.'**
  String get guestDemoFoodie1MoodyAbout;

  /// No description provided for @guestDemoFoodie2MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nCovered market hall: 30+ stalls—Dutch cheeses, roti, oysters, Korean bowls, and herring if you are feeling brave. Built for tasting: small plates so you can mix countries in one lunch.\n\n---\n🍽️ How it works\n\nOrder from vendors, meet at the long communal tables in the middle. Most stalls are cashless; allergen cards are posted.\n\n---\n⏱️ Good to know\n\nRush hour 12:00–13:30—scout a table first, then divide and conquer.\n\n---\n💬 Moody says\n\nGrab one thing you cannot pronounce—I will be smug when you love it.'**
  String get guestDemoFoodie2MoodyAbout;

  /// No description provided for @guestDemoFoodie3MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nEvening chef counter / pop-up dinner: open kitchen, menu that shifts every few weeks, small plates or a set menu. Wine list leans acid-forward whites, light gamay, orange bottles, natural picks.\n\n---\n🔥 Kitchen style\n\nLive fire + local produce call-outs on the board. Vegetarian route exists with a heads-up when you book.\n\n---\n⏱️ Good to know\n\nReservation strongly recommended. Casual-nice dress. Price tier is splurge-okay.\n\n---\n💬 Moody says\n\nSay yes to the server is essential bite—that is where the plot twist lives.'**
  String get guestDemoFoodie3MoodyAbout;

  /// No description provided for @guestDemoSocial1MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nOrganised park run / group jog at a fixed meeting pin—about 5 km, all paces welcome, volunteer hosts. Free to join; barcode timing if you like stats.\n\n---\n👟 Who shows up\n\nFirst-timers, stroller parents, and speedy folks who lap politely. Zero podium pressure unless you want it.\n\n---\n⏱️ Good to know\n\nQuick briefing a few minutes before go-time. Bag drop is honour-system near the flag—travel light if you can.\n\n---\n💬 Moody says\n\nHigh-five a stranger or just nod—both count as social XP today.'**
  String get guestDemoSocial1MoodyAbout;

  /// No description provided for @guestDemoSocial2MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nMarket-hall communal tables: stalls all around you, shared benches, loud happy chaos. Order small plates from different vendors and trade bites like a very civilised buffet raid.\n\n---\n🍻 The social cheat code\n\nLong tables = easy icebreakers—ask what someone ordered and steal a recommendation.\n\n---\n⏱️ Good to know\n\nPeak 13:00–14:00. Wipe crumbs when you leave—staff quietly love you for it.\n\n---\n💬 Moody says\n\nSteal a fry, share a story, blame me later.'**
  String get guestDemoSocial2MoodyAbout;

  /// No description provided for @guestDemoSocial3MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nLive-music bar: indie bands midweek, louder DJ nights on weekends. Craft beer taps + classic cocktails. Standing room near the stage; booths if you arrive with a plan.\n\n---\n🎶 Sound & scene\n\nSet times often live on socials. Earplugs at the bar if you like your hearing long-term.\n\n---\n⏱️ Good to know\n\nCover charge some Fridays/Saturdays. 18+ after 22:00. Coat check by the door.\n\n---\n💬 Moody says\n\nScratchy voice tomorrow means you did nightlife correctly.'**
  String get guestDemoSocial3MoodyAbout;

  /// No description provided for @guestDemoAdventurous1MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nRidge trail loop just outside the city: steep first kilometre, open viewpoints, roots and gravel underfoot. Not climbing ropes—just honest hills most fit hikers finish in 2–3 hours with snacks.\n\n---\n🥾 Gear & safety\n\nTrail shoes or boots, at least 1L water, wind layer at the top. Offline map helps—signal thins on the spine.\n\n---\n⏱️ Good to know\n\nFree access; small parking lot fills by 07:30 on sunny weekends. Sunrise starts are cooler and calmer.\n\n---\n💬 Moody says\n\nSnap the photo, then pocket the phone for ten minutes—the view rented IMAX seats for you.'**
  String get guestDemoAdventurous1MoodyAbout;

  /// No description provided for @guestDemoAdventurous2MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nHarbor-front deck restaurant: seafood towers, whole grilled fish, bitterballen for the table, Dutch gin cocktails. Big windows on the water; heaters on the pier when it chills.\n\n---\n⚓ Why it fits after a hike\n\nSalty, high-protein, celebratory—chairs you can sink into for two hours without guilt.\n\n---\n⏱️ Good to know\n\nBook on blue-sky days. Seagulls are professionals—guard your fries like state secrets.\n\n---\n💬 Moody says\n\nOrder the messy thing; napkins exist for exactly this moment.'**
  String get guestDemoAdventurous2MoodyAbout;

  /// No description provided for @guestDemoAdventurous3MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nWaterfront bar at golden hour: spritz list, local beers, small plates—oysters, charcuterie, croquettes. The room slowly shifts from standing-and-chatting to lounge-and-watch-the-sky.\n\n---\n🍹 Drinks\n\nNatural wine by the glass; negroni riffs on tap in summer.\n\n---\n⏱️ Good to know\n\nHappy hour some weekdays 17:00–19:00. Wind picks up—jacket or borrow a blanket from the host stand.\n\n---\n💬 Moody says\n\nStay for one more round if the sky is still showing off.'**
  String get guestDemoAdventurous3MoodyAbout;

  /// No description provided for @guestDemoCultural1MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nMuseum new wing with a rotating contemporary show—think large photography, installation, or mixed media. Check the banner at the entrance for this month\'s focus.\n\n---\n🎧 Extras\n\nQR audio guides; Dutch + English wall texts. Gift shop stocks exhibition posters and weirdly good postcards.\n\n---\n⏱️ Good to know\n\nTimed tickets on busy weekends. Café upstairs is a legit reset stop between floors.\n\n---\n💬 Moody says\n\nIf one piece rents space in your head for days, the ticket already paid rent back.'**
  String get guestDemoCultural1MoodyAbout;

  /// No description provided for @guestDemoCultural2MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nSculpture garden café tucked between museum wings: espresso, filter coffee, cardamom buns, light lunch salads. Glass walls look straight onto bronze pieces and clipped hedges.\n\n---\n🌿 Seating\n\nTerrace when it is dry; mid-century chairs inside when it drizzles—both feel intentional.\n\n---\n⏱️ Good to know\n\nGarden access sometimes needs a museum ticket—read the sign at the gate. Sunday brunch queues; weekday afternoons are softer.\n\n---\n💬 Moody says\n\nStare at the foam, then at a statue—let your brain file what you just saw.'**
  String get guestDemoCultural2MoodyAbout;

  /// No description provided for @guestDemoCultural3MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nIntimate canal-side jazz room: house trio on quieter nights, guest bands weekends. By-the-glass wines from Loire, Alto Adige, and a few skin-contact bottles; classic cocktails; cheese and charcuterie boards.\n\n---\n🎷 Room & sound\n\nAbout 60 seats—close enough to read the bassist\'s face. Two sets with a breather; service goes whisper-quiet during solos.\n\n---\n⏱️ Good to know\n\nReservations strongly recommended after 19:00. Smart-casual dress keeps the room feeling special.\n\n---\n💬 Moody says\n\nHum on the walk home—if you do, I nailed the encore pick.'**
  String get guestDemoCultural3MoodyAbout;

  /// No description provided for @guestDemoRomantic1MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nCourtyard café behind a brick arch: viennoiserie, Dutch apple tart, savory galettes at lunch. Coffee from a small Rotterdam roaster; tea list leans floral and cozy.\n\n---\n🪴 Atmosphere\n\nFountain murmur, ivy walls, a handful of two-tops that feel tucked away. Shared blankets appear on chilly evenings.\n\n---\n⏱️ Good to know\n\nWeekend brunch books fast—walk-in luck often after 14:00. Card and contactless.\n\n---\n💬 Moody says\n\nOrder one pastry to split and fight over the last crumb—I am taking notes.'**
  String get guestDemoRomantic1MoodyAbout;

  /// No description provided for @guestDemoRomantic2MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nIndependent bookshop—not a chain. Front tables: new fiction and translated lit. Middle aisles: essays, design, travel. Back room: curated used stacks plus a vinyl corner (jazz, soul, small Dutch indie labels).\n\n---\n🎧 Listen & browse\n\nPreview headphones at the counter. Staff shelf tags are spicy opinions, not corporate blurbs. Friday readings sometimes—chalkboard by the stairs has the schedule.\n\n---\n⏱️ Good to know\n\nPhones on quiet, please. Bags at the door. Monthly discount cart lives by the stairs—treasure hunt energy.\n\n---\n💬 Moody says\n\nHunt the title that feels like it waited for you—I will take full credit if you find it.'**
  String get guestDemoRomantic2MoodyAbout;

  /// No description provided for @guestDemoRomantic3MoodyAbout.
  ///
  /// In en, this message translates to:
  /// **'📚 What kind of place is this?\n\nLow-lit wine room with 80+ bottles on display—Italy (Barbera, Etna, Chianti riserva), France (Beaujolais, Loire Chenin, modest Bordeaux), Spain (Rioja, Priorat), plus orange wines and pet-nat from small Dutch importers. Coravin pours on pricier labels.\n\n---\n🍷 How drinking works\n\nRotating by-the-glass list (roughly 6 whites, 6 reds, 2 skin-contact). Bottles pair with small plates: olives, anchovies, burrata, charcuterie. Corkage waived with a food order on many nights—ask when you sit.\n\n---\n⏱️ Good to know\n\nSommelier does table rounds—say surprise us and mean it. Reservations after 19:30; smart-casual keeps the glow right.\n\n---\n💬 Moody says\n\nPick one bottle you cannot pronounce—we will toast to courage and pretend we are sommeliers.'**
  String get guestDemoRomantic3MoodyAbout;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySun;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'may'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'dec'**
  String get monthDec;

  /// No description provided for @myDayEmptyDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Your day is empty ✨'**
  String get myDayEmptyDayTitle;

  /// No description provided for @myDayEmptyDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let Moody make a plan for your mood today'**
  String get myDayEmptyDaySubtitle;

  /// No description provided for @myDayPlanWithMoodyButton.
  ///
  /// In en, this message translates to:
  /// **'Plan my day with Moody'**
  String get myDayPlanWithMoodyButton;

  /// No description provided for @myDayExploreActivitiesButton.
  ///
  /// In en, this message translates to:
  /// **'Explore activities'**
  String get myDayExploreActivitiesButton;

  /// No description provided for @myDayExploreNearbyButton.
  ///
  /// In en, this message translates to:
  /// **'Explore Nearby'**
  String get myDayExploreNearbyButton;

  /// No description provided for @myDayAskMoodyButton.
  ///
  /// In en, this message translates to:
  /// **'Ask Moody'**
  String get myDayAskMoodyButton;

  /// No description provided for @myDayOpenFullPlaceDetails.
  ///
  /// In en, this message translates to:
  /// **'Open full place'**
  String get myDayOpenFullPlaceDetails;

  /// No description provided for @placeQuickSheetAddToMyDayCta.
  ///
  /// In en, this message translates to:
  /// **'+add to my day'**
  String get placeQuickSheetAddToMyDayCta;

  /// No description provided for @myDayMoodStreakBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day streak} other{{count} days streak}}'**
  String myDayMoodStreakBadge(int count);

  /// No description provided for @myDayGetReadyButton.
  ///
  /// In en, this message translates to:
  /// **'Get Ready'**
  String get myDayGetReadyButton;

  /// No description provided for @myDayRightNow.
  ///
  /// In en, this message translates to:
  /// **'RIGHT NOW'**
  String get myDayRightNow;

  /// No description provided for @myDayStatusError.
  ///
  /// In en, this message translates to:
  /// **'⚠️ ERROR'**
  String get myDayStatusError;

  /// No description provided for @myDayStatusUnableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load status'**
  String get myDayStatusUnableToLoad;

  /// No description provided for @myDayOpenGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get myDayOpenGoogleMaps;

  /// No description provided for @myDayOpenAppleMaps.
  ///
  /// In en, this message translates to:
  /// **'Apple Maps'**
  String get myDayOpenAppleMaps;

  /// No description provided for @agendaTitle.
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get agendaTitle;

  /// No description provided for @agendaStatusDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get agendaStatusDone;

  /// No description provided for @agendaStatusNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get agendaStatusNow;

  /// No description provided for @agendaStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get agendaStatusUpcoming;

  /// No description provided for @agendaStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get agendaStatusCancelled;

  /// No description provided for @agendaHeaderToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get agendaHeaderToday;

  /// No description provided for @agendaHeaderTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get agendaHeaderTomorrow;

  /// No description provided for @agendaHeaderYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get agendaHeaderYesterday;

  /// No description provided for @agendaTodayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Today is still empty'**
  String get agendaTodayEmpty;

  /// No description provided for @agendaTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let Moody plan your day based on your mood'**
  String get agendaTodaySubtitle;

  /// No description provided for @agendaTomorrowEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is still free'**
  String get agendaTomorrowEmpty;

  /// No description provided for @agendaTomorrowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan what you want to do tomorrow'**
  String get agendaTomorrowSubtitle;

  /// No description provided for @agendaDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'{dayName} is still empty'**
  String agendaDayEmpty(String dayName);

  /// No description provided for @agendaDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Want to plan for {dayName}?'**
  String agendaDaySubtitle(String dayName);

  /// No description provided for @agendaFarFutureEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get agendaFarFutureEmpty;

  /// No description provided for @agendaFarFutureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan activities for this day'**
  String get agendaFarFutureSubtitle;

  /// No description provided for @agendaPlanWithMoody.
  ///
  /// In en, this message translates to:
  /// **'Plan with Moody'**
  String get agendaPlanWithMoody;

  /// No description provided for @agendaAddActivity.
  ///
  /// In en, this message translates to:
  /// **'Add activity'**
  String get agendaAddActivity;

  /// No description provided for @agendaEmptyPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'No activities planned yet'**
  String get agendaEmptyPlansTitle;

  /// No description provided for @agendaEmptyPlansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your day is all yours. Want Moody to build the perfect plan for you?'**
  String get agendaEmptyPlansSubtitle;

  /// No description provided for @agendaMoodyOverviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Today\'s still wide open — we\'ll make it good ✨'**
  String get agendaMoodyOverviewEmpty;

  /// No description provided for @agendaMoodyOverviewOne.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what I lined up for you today 👀'**
  String get agendaMoodyOverviewOne;

  /// No description provided for @agendaMoodyOverviewTwo.
  ///
  /// In en, this message translates to:
  /// **'Looking solid today'**
  String get agendaMoodyOverviewTwo;

  /// No description provided for @agendaMoodyOverviewMany.
  ///
  /// In en, this message translates to:
  /// **'I\'ve got a nice stack ready for you'**
  String get agendaMoodyOverviewMany;

  /// No description provided for @agendaMoodyOverviewLoading.
  ///
  /// In en, this message translates to:
  /// **'Let me peek at your day...'**
  String get agendaMoodyOverviewLoading;

  /// No description provided for @agendaMoodyOverviewError.
  ///
  /// In en, this message translates to:
  /// **'Keeping it simple for today'**
  String get agendaMoodyOverviewError;

  /// No description provided for @agendaMoodyCardLineDone.
  ///
  /// In en, this message translates to:
  /// **'Nice — you already checked this one off.'**
  String get agendaMoodyCardLineDone;

  /// No description provided for @agendaMoodyCardLineActive.
  ///
  /// In en, this message translates to:
  /// **'You\'re in the middle of this — good energy.'**
  String get agendaMoodyCardLineActive;

  /// No description provided for @agendaMoodyCardLineBooked.
  ///
  /// In en, this message translates to:
  /// **'Solid pick — this one\'s locked in for you.'**
  String get agendaMoodyCardLineBooked;

  /// No description provided for @agendaMoodyCardLineDefault.
  ///
  /// In en, this message translates to:
  /// **'You\'re going to enjoy this one.'**
  String get agendaMoodyCardLineDefault;

  /// No description provided for @agendaViewActivityCta.
  ///
  /// In en, this message translates to:
  /// **'View activity'**
  String get agendaViewActivityCta;

  /// No description provided for @agendaRouteCta.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get agendaRouteCta;

  /// No description provided for @agendaUntitledActivity.
  ///
  /// In en, this message translates to:
  /// **'Untitled Activity'**
  String get agendaUntitledActivity;

  /// No description provided for @agendaNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get agendaNoDescription;

  /// No description provided for @agendaLocationTBD.
  ///
  /// In en, this message translates to:
  /// **'Location TBD'**
  String get agendaLocationTBD;

  /// No description provided for @agendaDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be removed from your planner.'**
  String agendaDeleteDialogBody(String title);

  /// No description provided for @agendaDeleteDialogBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get agendaDeleteDialogBack;

  /// No description provided for @agendaDeleteDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get agendaDeleteDialogConfirm;

  /// No description provided for @exploreCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exploreCategoryAll;

  /// No description provided for @exploreCategoryPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get exploreCategoryPopular;

  /// No description provided for @exploreCategoryAccommodations.
  ///
  /// In en, this message translates to:
  /// **'Accommodations'**
  String get exploreCategoryAccommodations;

  /// No description provided for @exploreCategoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get exploreCategoryNature;

  /// No description provided for @exploreCategoryCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get exploreCategoryCulture;

  /// No description provided for @exploreCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get exploreCategoryFood;

  /// No description provided for @exploreCategoryActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get exploreCategoryActivities;

  /// No description provided for @exploreCategoryHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get exploreCategoryHistory;

  /// No description provided for @exploreFilterAdditionalOptions.
  ///
  /// In en, this message translates to:
  /// **'Additional Options'**
  String get exploreFilterAdditionalOptions;

  /// No description provided for @exploreFilterParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get exploreFilterParking;

  /// No description provided for @exploreFilterTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get exploreFilterTransport;

  /// No description provided for @exploreFilterCreditCards.
  ///
  /// In en, this message translates to:
  /// **'Credit Cards'**
  String get exploreFilterCreditCards;

  /// No description provided for @exploreFilterWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get exploreFilterWifi;

  /// No description provided for @exploreFilterCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get exploreFilterCharging;

  /// No description provided for @exploreFilterInstagrammable.
  ///
  /// In en, this message translates to:
  /// **'Instagrammable'**
  String get exploreFilterInstagrammable;

  /// No description provided for @exploreFilterArtisticDesign.
  ///
  /// In en, this message translates to:
  /// **'Artistic Design'**
  String get exploreFilterArtisticDesign;

  /// No description provided for @exploreFilterAestheticSpaces.
  ///
  /// In en, this message translates to:
  /// **'Aesthetic Spaces'**
  String get exploreFilterAestheticSpaces;

  /// No description provided for @exploreFilterScenicViews.
  ///
  /// In en, this message translates to:
  /// **'Scenic Views'**
  String get exploreFilterScenicViews;

  /// No description provided for @exploreFilterBestAtNight.
  ///
  /// In en, this message translates to:
  /// **'Best at Night'**
  String get exploreFilterBestAtNight;

  /// No description provided for @exploreFilterBestAtSunset.
  ///
  /// In en, this message translates to:
  /// **'Best at Sunset'**
  String get exploreFilterBestAtSunset;

  /// No description provided for @exploreNoPlacesOnMap.
  ///
  /// In en, this message translates to:
  /// **'No places to display on map'**
  String get exploreNoPlacesOnMap;

  /// No description provided for @timeLabelToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get timeLabelToday;

  /// No description provided for @timeLabelTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get timeLabelTomorrow;

  /// No description provided for @timeLabelMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get timeLabelMorning;

  /// No description provided for @timeLabelAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get timeLabelAfternoon;

  /// No description provided for @timeLabelEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get timeLabelEvening;

  /// No description provided for @exploreFilterIndoorOnly.
  ///
  /// In en, this message translates to:
  /// **'Indoor Only'**
  String get exploreFilterIndoorOnly;

  /// No description provided for @exploreFilterOutdoorOnly.
  ///
  /// In en, this message translates to:
  /// **'Outdoor Only'**
  String get exploreFilterOutdoorOnly;

  /// No description provided for @exploreFilterWeatherSafe.
  ///
  /// In en, this message translates to:
  /// **'Weather-Safe'**
  String get exploreFilterWeatherSafe;

  /// No description provided for @exploreFilterOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get exploreFilterOpenNow;

  /// No description provided for @exploreFilterQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get exploreFilterQuiet;

  /// No description provided for @exploreFilterLively.
  ///
  /// In en, this message translates to:
  /// **'Lively'**
  String get exploreFilterLively;

  /// No description provided for @exploreFilterRomanticVibe.
  ///
  /// In en, this message translates to:
  /// **'Romantic Vibe'**
  String get exploreFilterRomanticVibe;

  /// No description provided for @exploreFilterSurpriseMe.
  ///
  /// In en, this message translates to:
  /// **'Surprise Me'**
  String get exploreFilterSurpriseMe;

  /// No description provided for @exploreFilterVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get exploreFilterVegan;

  /// No description provided for @exploreFilterVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get exploreFilterVegetarian;

  /// No description provided for @exploreFilterHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get exploreFilterHalal;

  /// No description provided for @exploreFilterGlutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten-Free'**
  String get exploreFilterGlutenFree;

  /// No description provided for @exploreFilterPescatarian.
  ///
  /// In en, this message translates to:
  /// **'Pescatarian'**
  String get exploreFilterPescatarian;

  /// No description provided for @exploreFilterNoAlcohol.
  ///
  /// In en, this message translates to:
  /// **'No Alcohol'**
  String get exploreFilterNoAlcohol;

  /// No description provided for @exploreFilterWheelchairAccessible.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair Accessible'**
  String get exploreFilterWheelchairAccessible;

  /// No description provided for @exploreFilterLgbtqFriendly.
  ///
  /// In en, this message translates to:
  /// **'LGBTQ+ Friendly'**
  String get exploreFilterLgbtqFriendly;

  /// No description provided for @exploreFilterSensoryFriendly.
  ///
  /// In en, this message translates to:
  /// **'Sensory-friendly'**
  String get exploreFilterSensoryFriendly;

  /// No description provided for @exploreFilterFamilyFriendly.
  ///
  /// In en, this message translates to:
  /// **'Family-friendly'**
  String get exploreFilterFamilyFriendly;

  /// No description provided for @exploreFilterSeniorFriendly.
  ///
  /// In en, this message translates to:
  /// **'Senior-Friendly'**
  String get exploreFilterSeniorFriendly;

  /// No description provided for @exploreFilterBabyFriendly.
  ///
  /// In en, this message translates to:
  /// **'Baby-Friendly'**
  String get exploreFilterBabyFriendly;

  /// No description provided for @exploreFilterBlackOwned.
  ///
  /// In en, this message translates to:
  /// **'Black-owned'**
  String get exploreFilterBlackOwned;

  /// No description provided for @exploreFilterPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range (€)'**
  String get exploreFilterPriceRange;

  /// No description provided for @exploreFilterMaxDistance.
  ///
  /// In en, this message translates to:
  /// **'Maximum Distance (km)'**
  String get exploreFilterMaxDistance;

  /// No description provided for @exploreErrorLocationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Location required'**
  String get exploreErrorLocationRequiredTitle;

  /// No description provided for @exploreErrorLoadingPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Error loading places'**
  String get exploreErrorLoadingPlacesTitle;

  /// No description provided for @exploreErrorLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services or set your location in settings to discover places near you.'**
  String get exploreErrorLocationBody;

  /// No description provided for @exploreErrorEnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get exploreErrorEnableLocation;

  /// No description provided for @exploreAdvancedFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get exploreAdvancedFiltersTitle;

  /// No description provided for @exploreFiltersActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 filter active} other{{count} filters active}}'**
  String exploreFiltersActiveCount(int count);

  /// No description provided for @exploreMoodyHintFiltersActive.
  ///
  /// In en, this message translates to:
  /// **'Nice, {count, plural, one{1 filter is on} other{{count} filters are on}}.'**
  String exploreMoodyHintFiltersActive(int count);

  /// No description provided for @exploreMoodyHintFiltersIntro.
  ///
  /// In en, this message translates to:
  /// **'I\'m Moody. Pick a few filters and I\'ll find better matches right away.'**
  String get exploreMoodyHintFiltersIntro;

  /// No description provided for @exploreClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get exploreClearAll;

  /// No description provided for @exploreSectionQuickSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Quick picks'**
  String get exploreSectionQuickSuggestions;

  /// No description provided for @exploreSectionDietaryPreferences.
  ///
  /// In en, this message translates to:
  /// **'Dietary preferences'**
  String get exploreSectionDietaryPreferences;

  /// No description provided for @exploreSectionAccessibilityInclusion.
  ///
  /// In en, this message translates to:
  /// **'Accessibility & inclusion'**
  String get exploreSectionAccessibilityInclusion;

  /// No description provided for @exploreSectionComfortConvenience.
  ///
  /// In en, this message translates to:
  /// **'Practical'**
  String get exploreSectionComfortConvenience;

  /// No description provided for @exploreSectionPhotoAesthetic.
  ///
  /// In en, this message translates to:
  /// **'Photo & vibe'**
  String get exploreSectionPhotoAesthetic;

  /// No description provided for @exploreSaveFiltersWithCount.
  ///
  /// In en, this message translates to:
  /// **'Save {count} filters'**
  String exploreSaveFiltersWithCount(int count);

  /// No description provided for @exploreSaveFilters.
  ///
  /// In en, this message translates to:
  /// **'Save filters'**
  String get exploreSaveFilters;

  /// No description provided for @exploreQuickFilters.
  ///
  /// In en, this message translates to:
  /// **'Quick filters'**
  String get exploreQuickFilters;

  /// No description provided for @exploreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search activities, restaurants, museums...'**
  String get exploreSearchHint;

  /// No description provided for @exploreCategoryChipOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get exploreCategoryChipOutdoor;

  /// No description provided for @exploreCategoryChipShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get exploreCategoryChipShopping;

  /// No description provided for @exploreCategoryChipNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get exploreCategoryChipNightlife;

  /// No description provided for @explorePriceLevelBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get explorePriceLevelBudget;

  /// No description provided for @explorePriceLevelModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get explorePriceLevelModerate;

  /// No description provided for @explorePriceLevelExpensive.
  ///
  /// In en, this message translates to:
  /// **'Expensive'**
  String get explorePriceLevelExpensive;

  /// No description provided for @explorePriceLevelLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get explorePriceLevelLuxury;

  /// No description provided for @exploreMoodAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get exploreMoodAdventure;

  /// No description provided for @exploreMoodCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get exploreMoodCreative;

  /// No description provided for @exploreMoodRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get exploreMoodRelaxed;

  /// No description provided for @exploreMoodMindful.
  ///
  /// In en, this message translates to:
  /// **'Mindful'**
  String get exploreMoodMindful;

  /// No description provided for @exploreMoodRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get exploreMoodRomantic;

  /// No description provided for @exploreAddToMyDayDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get exploreAddToMyDayDayLabel;

  /// No description provided for @exploreAddToMyDayPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get exploreAddToMyDayPickDate;

  /// No description provided for @exploreAddToMyDaySelectedDate.
  ///
  /// In en, this message translates to:
  /// **'Selected: {date}'**
  String exploreAddToMyDaySelectedDate(String date);

  /// No description provided for @exploreAddToMyDayTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get exploreAddToMyDayTimeLabel;

  /// No description provided for @exploreDatePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get exploreDatePickerHelp;

  /// No description provided for @exploreDatePickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get exploreDatePickerConfirm;

  /// No description provided for @exploreTimeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning ☀️'**
  String get exploreTimeGreetingMorning;

  /// No description provided for @exploreTimeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon 🌤'**
  String get exploreTimeGreetingAfternoon;

  /// No description provided for @exploreTimeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening 🌙'**
  String get exploreTimeGreetingEvening;

  /// No description provided for @exploreTimeGreetingLateNight.
  ///
  /// In en, this message translates to:
  /// **'Late night vibes 🌙'**
  String get exploreTimeGreetingLateNight;

  /// No description provided for @exploreSectionBecauseFood.
  ///
  /// In en, this message translates to:
  /// **'Because you love food 🍜'**
  String get exploreSectionBecauseFood;

  /// No description provided for @exploreSectionBecauseCulture.
  ///
  /// In en, this message translates to:
  /// **'Because you love culture 🏛️'**
  String get exploreSectionBecauseCulture;

  /// No description provided for @exploreSectionBecauseNightlife.
  ///
  /// In en, this message translates to:
  /// **'Because you love nightlife 🌙'**
  String get exploreSectionBecauseNightlife;

  /// No description provided for @exploreSectionBecauseOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Because you love the outdoors 🌿'**
  String get exploreSectionBecauseOutdoor;

  /// No description provided for @exploreSectionBecauseCoffee.
  ///
  /// In en, this message translates to:
  /// **'Because you love coffee ☕'**
  String get exploreSectionBecauseCoffee;

  /// No description provided for @exploreSectionTrendingInCity.
  ///
  /// In en, this message translates to:
  /// **'Trending in {city} 🔥'**
  String exploreSectionTrendingInCity(String city);

  /// No description provided for @exploreSectionPerfectVibe.
  ///
  /// In en, this message translates to:
  /// **'Perfect for your vibe ✨'**
  String get exploreSectionPerfectVibe;

  /// No description provided for @exploreSectionPerfectSolo.
  ///
  /// In en, this message translates to:
  /// **'Perfect for solo days ✨'**
  String get exploreSectionPerfectSolo;

  /// No description provided for @exploreSectionPerfectGroups.
  ///
  /// In en, this message translates to:
  /// **'Perfect for groups 👥'**
  String get exploreSectionPerfectGroups;

  /// No description provided for @exploreSectionSomethingDifferent.
  ///
  /// In en, this message translates to:
  /// **'Something different 🎲'**
  String get exploreSectionSomethingDifferent;

  /// No description provided for @exploreSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get exploreSeeAll;

  /// No description provided for @exploreLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more →'**
  String get exploreLoadMore;

  /// Shown when Load more reaches the end of the locally cached explore pool.
  ///
  /// In en, this message translates to:
  /// **'You have seen all ideas saved for this area. Pull down to refresh for new suggestions.'**
  String get exploreEndOfCachedPool;

  /// No description provided for @exploreSectionErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load places — tap to retry'**
  String get exploreSectionErrorRetry;

  /// No description provided for @exploreOfflineShowingCached.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing cached results'**
  String get exploreOfflineShowingCached;

  /// No description provided for @exploreOfflineEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet\nto discover places'**
  String get exploreOfflineEmptyBody;

  /// No description provided for @explorePlaceDescriptionFallback.
  ///
  /// In en, this message translates to:
  /// **'Explore {name}'**
  String explorePlaceDescriptionFallback(String name);

  /// No description provided for @exploreContextStripDiscovering.
  ///
  /// In en, this message translates to:
  /// **'Discovering {city}'**
  String exploreContextStripDiscovering(String city);

  /// No description provided for @exploreContextStripSearch.
  ///
  /// In en, this message translates to:
  /// **'Showing results for \"{query}\"'**
  String exploreContextStripSearch(String query);

  /// No description provided for @exploreContextStripFiltered.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 filter on} other{{count} filters on}}'**
  String exploreContextStripFiltered(int count);

  /// No description provided for @exploreContextPlacesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 place} other{{count} places}}'**
  String exploreContextPlacesCount(int count);

  /// No description provided for @explorePeekViewFullPlace.
  ///
  /// In en, this message translates to:
  /// **'View full place'**
  String get explorePeekViewFullPlace;

  /// No description provided for @chatSheetMoodyName.
  ///
  /// In en, this message translates to:
  /// **'Moody'**
  String get chatSheetMoodyName;

  /// No description provided for @chatSheetErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Oops! I\'m having trouble connecting right now. Can you try again? 🤔'**
  String get chatSheetErrorMessage;

  /// No description provided for @chatSheetEmptyStateBody.
  ///
  /// In en, this message translates to:
  /// **'I know the city like the back of my hand! Tell me your mood, and I\'ll craft the perfect day just for you. Whether you\'re feeling adventurous, romantic, or need some chill vibes - I\'ve got you covered! 🎯'**
  String get chatSheetEmptyStateBody;

  /// No description provided for @chatSheetCraftingMessage.
  ///
  /// In en, this message translates to:
  /// **'Moody is typing...'**
  String get chatSheetCraftingMessage;

  /// No description provided for @chatSheetInputHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s your mood today?'**
  String get chatSheetInputHint;

  /// No description provided for @chatSheetMessageCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatSheetMessageCopy;

  /// No description provided for @chatSheetMessageReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatSheetMessageReply;

  /// No description provided for @chatSheetCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get chatSheetCopied;

  /// No description provided for @chatSheetReplyLabelYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatSheetReplyLabelYou;

  /// No description provided for @moodyConversationGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi there! How are you feeling today? I can suggest activities based on your mood.'**
  String get moodyConversationGreeting;

  /// No description provided for @moodyConversationTalkToMoody.
  ///
  /// In en, this message translates to:
  /// **'Talk to Moody'**
  String get moodyConversationTalkToMoody;

  /// No description provided for @moodyConversationSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking...'**
  String get moodyConversationSpeaking;

  /// No description provided for @moodyConversationListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get moodyConversationListening;

  /// No description provided for @moodyConversationThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get moodyConversationThinking;

  /// No description provided for @moodyConversationTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get moodyConversationTypeMessage;

  /// No description provided for @homeSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get homeSelectLocation;

  /// No description provided for @homeCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get homeCurrentLocation;

  /// No description provided for @homeUsingGps.
  ///
  /// In en, this message translates to:
  /// **'Using GPS'**
  String get homeUsingGps;

  /// No description provided for @homeGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get homeGettingLocation;

  /// No description provided for @homeLocationResult.
  ///
  /// In en, this message translates to:
  /// **'Location: {location}'**
  String homeLocationResult(String location);

  /// No description provided for @homeLocationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not get location'**
  String get homeLocationNotFound;

  /// No description provided for @homeChatErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I couldn\'t respond right now. Try again! 😅'**
  String get homeChatErrorRetry;

  /// No description provided for @checkInQ1Title.
  ///
  /// In en, this message translates to:
  /// **'How was your day?'**
  String get checkInQ1Title;

  /// No description provided for @checkInQ1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Moody wants to get to know you better 🌙'**
  String get checkInQ1Subtitle;

  /// No description provided for @checkInQ1Question.
  ///
  /// In en, this message translates to:
  /// **'What was the best moment of today?'**
  String get checkInQ1Question;

  /// No description provided for @checkInQ1Activities.
  ///
  /// In en, this message translates to:
  /// **'The activities 🎯'**
  String get checkInQ1Activities;

  /// No description provided for @checkInQ1Friends.
  ///
  /// In en, this message translates to:
  /// **'With friends 👥'**
  String get checkInQ1Friends;

  /// No description provided for @checkInQ1Exploring.
  ///
  /// In en, this message translates to:
  /// **'Exploring 🔍'**
  String get checkInQ1Exploring;

  /// No description provided for @checkInQ1Food.
  ///
  /// In en, this message translates to:
  /// **'Food & drinks 🍽'**
  String get checkInQ1Food;

  /// No description provided for @checkInQ1Relaxing.
  ///
  /// In en, this message translates to:
  /// **'Relaxing 🛋'**
  String get checkInQ1Relaxing;

  /// No description provided for @checkInMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get checkInMaybeLater;

  /// No description provided for @checkInQ2Question.
  ///
  /// In en, this message translates to:
  /// **'Was {name} worth it?'**
  String checkInQ2Question(String name);

  /// No description provided for @checkInQ2Amazing.
  ///
  /// In en, this message translates to:
  /// **'Amazing! 🤩'**
  String get checkInQ2Amazing;

  /// No description provided for @checkInQ2Good.
  ///
  /// In en, this message translates to:
  /// **'Good 👍'**
  String get checkInQ2Good;

  /// No description provided for @checkInQ2Ok.
  ///
  /// In en, this message translates to:
  /// **'It was okay'**
  String get checkInQ2Ok;

  /// No description provided for @checkInQ2NotForMe.
  ///
  /// In en, this message translates to:
  /// **'Not for me'**
  String get checkInQ2NotForMe;

  /// No description provided for @checkInQ3Question.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling now?'**
  String get checkInQ3Question;

  /// No description provided for @checkInQ3Happy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get checkInQ3Happy;

  /// No description provided for @checkInQ3Relaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get checkInQ3Relaxed;

  /// No description provided for @checkInQ3Tired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get checkInQ3Tired;

  /// No description provided for @checkInQ3Mixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get checkInQ3Mixed;

  /// No description provided for @checkInDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you! See you tomorrow 🌟'**
  String get checkInDoneTitle;

  /// No description provided for @checkInDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moody will remember this for next time'**
  String get checkInDoneSubtitle;

  /// No description provided for @checkInSaveError.
  ///
  /// In en, this message translates to:
  /// **'Save failed. Please try again.'**
  String get checkInSaveError;

  /// No description provided for @checkInClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get checkInClose;

  /// No description provided for @checkInWithMoodyTitle.
  ///
  /// In en, this message translates to:
  /// **'Check in with Moody'**
  String get checkInWithMoodyTitle;

  /// No description provided for @checkInGreetingDefault.
  ///
  /// In en, this message translates to:
  /// **'Hey! How\'s your day going?'**
  String get checkInGreetingDefault;

  /// No description provided for @checkInGreetingMorningAfterTired.
  ///
  /// In en, this message translates to:
  /// **'Good morning! Did you sleep well? 🌅'**
  String get checkInGreetingMorningAfterTired;

  /// No description provided for @checkInGreetingMorningFresh.
  ///
  /// In en, this message translates to:
  /// **'Good morning! How are you feeling today? ☀️'**
  String get checkInGreetingMorningFresh;

  /// No description provided for @checkInTellMeEverything.
  ///
  /// In en, this message translates to:
  /// **'Tell me everything! 💚'**
  String get checkInTellMeEverything;

  /// No description provided for @checkInHowAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get checkInHowAreYouFeeling;

  /// No description provided for @checkInWhatDidYouDoToday.
  ///
  /// In en, this message translates to:
  /// **'What did you do today?'**
  String get checkInWhatDidYouDoToday;

  /// No description provided for @checkInQuickReactionsHeading.
  ///
  /// In en, this message translates to:
  /// **'Quick reactions'**
  String get checkInQuickReactionsHeading;

  /// No description provided for @checkInTellMeMoreHeading.
  ///
  /// In en, this message translates to:
  /// **'Tell me more... (optional)'**
  String get checkInTellMeMoreHeading;

  /// No description provided for @checkInTextFieldHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind? Share anything! 💭'**
  String get checkInTextFieldHint;

  /// No description provided for @checkInSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send to Moody'**
  String get checkInSendButton;

  /// No description provided for @checkInThanksMoodyButton.
  ///
  /// In en, this message translates to:
  /// **'Thanks Moody! 💚'**
  String get checkInThanksMoodyButton;

  /// No description provided for @checkInAiFallbackThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thanks for checking in! I love hearing about your day 💛'**
  String get checkInAiFallbackThankYou;

  /// No description provided for @checkInMoodGreatLabel.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get checkInMoodGreatLabel;

  /// No description provided for @checkInMoodGreatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Living my best life!'**
  String get checkInMoodGreatSubtitle;

  /// No description provided for @checkInMoodTiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get checkInMoodTiredLabel;

  /// No description provided for @checkInMoodTiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Need some rest'**
  String get checkInMoodTiredSubtitle;

  /// No description provided for @checkInMoodAmazingLabel.
  ///
  /// In en, this message translates to:
  /// **'Amazing'**
  String get checkInMoodAmazingLabel;

  /// No description provided for @checkInMoodAmazingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Best day ever!'**
  String get checkInMoodAmazingSubtitle;

  /// No description provided for @checkInMoodOkayLabel.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get checkInMoodOkayLabel;

  /// No description provided for @checkInMoodOkaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Just coasting'**
  String get checkInMoodOkaySubtitle;

  /// No description provided for @checkInMoodThoughtfulLabel.
  ///
  /// In en, this message translates to:
  /// **'Thoughtful'**
  String get checkInMoodThoughtfulLabel;

  /// No description provided for @checkInMoodThoughtfulSubtitle.
  ///
  /// In en, this message translates to:
  /// **'In my feels'**
  String get checkInMoodThoughtfulSubtitle;

  /// No description provided for @checkInMoodChillLabel.
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get checkInMoodChillLabel;

  /// No description provided for @checkInMoodChillSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Taking it easy'**
  String get checkInMoodChillSubtitle;

  /// No description provided for @checkInTagExploredPlaces.
  ///
  /// In en, this message translates to:
  /// **'Explored places'**
  String get checkInTagExploredPlaces;

  /// No description provided for @checkInTagGreatFood.
  ///
  /// In en, this message translates to:
  /// **'Had great food'**
  String get checkInTagGreatFood;

  /// No description provided for @checkInTagMetFriends.
  ///
  /// In en, this message translates to:
  /// **'Met friends'**
  String get checkInTagMetFriends;

  /// No description provided for @checkInTagRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get checkInTagRelaxed;

  /// No description provided for @checkInTagWorkedOut.
  ///
  /// In en, this message translates to:
  /// **'Worked out'**
  String get checkInTagWorkedOut;

  /// No description provided for @checkInTagCreativeTime.
  ///
  /// In en, this message translates to:
  /// **'Creative time'**
  String get checkInTagCreativeTime;

  /// No description provided for @checkInTagAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get checkInTagAdventure;

  /// No description provided for @checkInTagSelfCare.
  ///
  /// In en, this message translates to:
  /// **'Self-care'**
  String get checkInTagSelfCare;

  /// No description provided for @checkInReactionLovedIt.
  ///
  /// In en, this message translates to:
  /// **'Loved it'**
  String get checkInReactionLovedIt;

  /// No description provided for @checkInReactionOnFire.
  ///
  /// In en, this message translates to:
  /// **'On fire'**
  String get checkInReactionOnFire;

  /// No description provided for @checkInReactionMagical.
  ///
  /// In en, this message translates to:
  /// **'Magical'**
  String get checkInReactionMagical;

  /// No description provided for @checkInReactionExhausted.
  ///
  /// In en, this message translates to:
  /// **'Exhausted'**
  String get checkInReactionExhausted;

  /// No description provided for @checkInReactionAmazing.
  ///
  /// In en, this message translates to:
  /// **'Amazing'**
  String get checkInReactionAmazing;

  /// No description provided for @checkInReactionPeaceful.
  ///
  /// In en, this message translates to:
  /// **'Peaceful'**
  String get checkInReactionPeaceful;

  /// No description provided for @dagSheetOpener1.
  ///
  /// In en, this message translates to:
  /// **'You\'re home! How was your day?'**
  String get dagSheetOpener1;

  /// No description provided for @dagSheetOpener2.
  ///
  /// In en, this message translates to:
  /// **'Tell me! How was it today?'**
  String get dagSheetOpener2;

  /// No description provided for @dagSheetOpener3.
  ///
  /// In en, this message translates to:
  /// **'How did it go today?'**
  String get dagSheetOpener3;

  /// No description provided for @dagSheetOpener4.
  ///
  /// In en, this message translates to:
  /// **'Moody is curious — how was your day?'**
  String get dagSheetOpener4;

  /// No description provided for @dagSheetE1Amazing.
  ///
  /// In en, this message translates to:
  /// **'Amazing! 🤩'**
  String get dagSheetE1Amazing;

  /// No description provided for @dagSheetE1PrettyGood.
  ///
  /// In en, this message translates to:
  /// **'Pretty good 😊'**
  String get dagSheetE1PrettyGood;

  /// No description provided for @dagSheetE1Okay.
  ///
  /// In en, this message translates to:
  /// **'Okay 😐'**
  String get dagSheetE1Okay;

  /// No description provided for @dagSheetE1Letdown.
  ///
  /// In en, this message translates to:
  /// **'Letdown 😔'**
  String get dagSheetE1Letdown;

  /// No description provided for @dagSheetFollowupAmazing.
  ///
  /// In en, this message translates to:
  /// **'Awesome! What was the best moment? 🌟'**
  String get dagSheetFollowupAmazing;

  /// No description provided for @dagSheetFollowupPrettyGood.
  ///
  /// In en, this message translates to:
  /// **'Nice! Something that really stood out?'**
  String get dagSheetFollowupPrettyGood;

  /// No description provided for @dagSheetFollowupOkay.
  ///
  /// In en, this message translates to:
  /// **'Fair enough. What could have been better?'**
  String get dagSheetFollowupOkay;

  /// No description provided for @dagSheetFollowupLetdown.
  ///
  /// In en, this message translates to:
  /// **'Too bad... What went wrong?'**
  String get dagSheetFollowupLetdown;

  /// No description provided for @dagSheetFollowupDefault.
  ///
  /// In en, this message translates to:
  /// **'Tell me more! ✨'**
  String get dagSheetFollowupDefault;

  /// No description provided for @dagSheetE2Activities.
  ///
  /// In en, this message translates to:
  /// **'The activities 🎯'**
  String get dagSheetE2Activities;

  /// No description provided for @dagSheetE2People.
  ///
  /// In en, this message translates to:
  /// **'With people 👥'**
  String get dagSheetE2People;

  /// No description provided for @dagSheetE2Exploring.
  ///
  /// In en, this message translates to:
  /// **'The exploring 🔍'**
  String get dagSheetE2Exploring;

  /// No description provided for @dagSheetE2Food.
  ///
  /// In en, this message translates to:
  /// **'Great food 🍽'**
  String get dagSheetE2Food;

  /// No description provided for @dagSheetE2Relaxing.
  ///
  /// In en, this message translates to:
  /// **'Just relaxing 🛋'**
  String get dagSheetE2Relaxing;

  /// No description provided for @dagSheetE2Unexpected.
  ///
  /// In en, this message translates to:
  /// **'Something unexpected ✨'**
  String get dagSheetE2Unexpected;

  /// No description provided for @dagSheetClosing1.
  ///
  /// In en, this message translates to:
  /// **'Well done today. Sleep well 🌙'**
  String get dagSheetClosing1;

  /// No description provided for @dagSheetClosing2.
  ///
  /// In en, this message translates to:
  /// **'Moody will remember this for tomorrow. See you! ✨'**
  String get dagSheetClosing2;

  /// No description provided for @dagSheetClosing3.
  ///
  /// In en, this message translates to:
  /// **'Thanks for sharing. Tomorrow is another beautiful day 🌟'**
  String get dagSheetClosing3;

  /// No description provided for @dagSheetClosing4.
  ///
  /// In en, this message translates to:
  /// **'Sleep well. Tomorrow we\'ll make it special 🌙'**
  String get dagSheetClosing4;

  /// No description provided for @dagSheetReflectionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Anything else on your mind? All good — or leave it empty and go sleep. ✨'**
  String get dagSheetReflectionPrompt;

  /// No description provided for @dagSheetReflectionHint.
  ///
  /// In en, this message translates to:
  /// **'Type here… (optional)'**
  String get dagSheetReflectionHint;

  /// No description provided for @dagSheetGoodnight.
  ///
  /// In en, this message translates to:
  /// **'Goodnight Moody 🌙'**
  String get dagSheetGoodnight;

  /// No description provided for @carouselPerfectMatches.
  ///
  /// In en, this message translates to:
  /// **'{count} perfect matches'**
  String carouselPerfectMatches(String count);

  /// No description provided for @carouselRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing recommendations...'**
  String get carouselRefreshing;

  /// No description provided for @carouselTopPick.
  ///
  /// In en, this message translates to:
  /// **'TOP PICK'**
  String get carouselTopPick;

  /// No description provided for @carouselTellMeMore.
  ///
  /// In en, this message translates to:
  /// **'Tell me more'**
  String get carouselTellMeMore;

  /// No description provided for @carouselAddToDay.
  ///
  /// In en, this message translates to:
  /// **'Add to day'**
  String get carouselAddToDay;

  /// No description provided for @carouselDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get carouselDirections;

  /// No description provided for @carouselShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get carouselShare;

  /// No description provided for @carouselDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get carouselDetails;

  /// No description provided for @carouselSaveForLater.
  ///
  /// In en, this message translates to:
  /// **'Save for later'**
  String get carouselSaveForLater;

  /// No description provided for @carouselNotInterested.
  ///
  /// In en, this message translates to:
  /// **'Not interested'**
  String get carouselNotInterested;

  /// No description provided for @carouselNoRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations yet'**
  String get carouselNoRecommendations;

  /// No description provided for @carouselCheckBackSoon.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for personalized suggestions!'**
  String get carouselCheckBackSoon;

  /// No description provided for @prefBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get prefBack;

  /// No description provided for @interestsPrompt.
  ///
  /// In en, this message translates to:
  /// **'What do you like? I\'ll find it for you! 🔍'**
  String get interestsPrompt;

  /// No description provided for @interestsTitle.
  ///
  /// In en, this message translates to:
  /// **'What are your interests?'**
  String get interestsTitle;

  /// No description provided for @interestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose everything that appeals to you.'**
  String get interestsSubtitle;

  /// No description provided for @interestsMultipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple choices possible'**
  String get interestsMultipleChoice;

  /// No description provided for @interestsContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue →'**
  String get interestsContinue;

  /// No description provided for @interestFoodDining.
  ///
  /// In en, this message translates to:
  /// **'Food & Drinks'**
  String get interestFoodDining;

  /// No description provided for @interestArtsCulture.
  ///
  /// In en, this message translates to:
  /// **'Arts & Culture'**
  String get interestArtsCulture;

  /// No description provided for @interestShoppingMarkets.
  ///
  /// In en, this message translates to:
  /// **'Shopping & Markets'**
  String get interestShoppingMarkets;

  /// No description provided for @interestSports.
  ///
  /// In en, this message translates to:
  /// **'Sports & Activities'**
  String get interestSports;

  /// No description provided for @interestNatureOutdoors.
  ///
  /// In en, this message translates to:
  /// **'Nature & Parks'**
  String get interestNatureOutdoors;

  /// No description provided for @interestNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get interestNightlife;

  /// No description provided for @interestCoffeeCafes.
  ///
  /// In en, this message translates to:
  /// **'Coffee & Cafés'**
  String get interestCoffeeCafes;

  /// No description provided for @interestPhotographySpots.
  ///
  /// In en, this message translates to:
  /// **'Photography & Spots'**
  String get interestPhotographySpots;

  /// No description provided for @prefTravelProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Travel Profile'**
  String get prefTravelProfileTitle;

  /// No description provided for @prefSocialVibeLabel.
  ///
  /// In en, this message translates to:
  /// **'Social Vibe 👥'**
  String get prefSocialVibeLabel;

  /// No description provided for @prefPaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Planning Pace ⚡'**
  String get prefPaceLabel;

  /// No description provided for @prefStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Style 🌟'**
  String get prefStyleLabel;

  /// No description provided for @prefStyleLimit.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {count} styles that suit you.'**
  String prefStyleLimit(String count);

  /// No description provided for @prefMoodySpeech.
  ///
  /// In en, this message translates to:
  /// **'Just a few more questions and I\'ll know you completely! ✈️'**
  String get prefMoodySpeech;

  /// No description provided for @prefSocialSoloTitle.
  ///
  /// In en, this message translates to:
  /// **'Solo Adventures'**
  String get prefSocialSoloTitle;

  /// No description provided for @prefSocialSoloHint.
  ///
  /// In en, this message translates to:
  /// **'Time for myself'**
  String get prefSocialSoloHint;

  /// No description provided for @prefSocialSmallTitle.
  ///
  /// In en, this message translates to:
  /// **'Small Groups'**
  String get prefSocialSmallTitle;

  /// No description provided for @prefSocialSmallHint.
  ///
  /// In en, this message translates to:
  /// **'Intimate setting'**
  String get prefSocialSmallHint;

  /// No description provided for @prefSocialButterflyTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Butterfly'**
  String get prefSocialButterflyTitle;

  /// No description provided for @prefSocialButterflyHint.
  ///
  /// In en, this message translates to:
  /// **'Meeting new people'**
  String get prefSocialButterflyHint;

  /// No description provided for @prefSocialMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood Dependent'**
  String get prefSocialMoodTitle;

  /// No description provided for @prefSocialMoodHint.
  ///
  /// In en, this message translates to:
  /// **'Sometimes solo, sometimes social'**
  String get prefSocialMoodHint;

  /// No description provided for @prefPaceNow.
  ///
  /// In en, this message translates to:
  /// **'Right Now ⚡'**
  String get prefPaceNow;

  /// No description provided for @prefPaceToday.
  ///
  /// In en, this message translates to:
  /// **'Today 📅'**
  String get prefPaceToday;

  /// No description provided for @prefPacePlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned 🗓'**
  String get prefPacePlanned;

  /// No description provided for @prefStyleLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Experience'**
  String get prefStyleLocalTitle;

  /// No description provided for @prefStyleLocalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Authentic and off the beaten track.'**
  String get prefStyleLocalSubtitle;

  /// No description provided for @prefStyleLuxuryTitle.
  ///
  /// In en, this message translates to:
  /// **'Luxury Seeker'**
  String get prefStyleLuxuryTitle;

  /// No description provided for @prefStyleLuxurySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comfort and special experiences.'**
  String get prefStyleLuxurySubtitle;

  /// No description provided for @prefStyleBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Conscious'**
  String get prefStyleBudgetTitle;

  /// No description provided for @prefStyleBudgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum fun, smart spending.'**
  String get prefStyleBudgetSubtitle;

  /// No description provided for @prefStyleOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Off the Beaten Path'**
  String get prefStyleOffTitle;

  /// No description provided for @prefStyleOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden gems and local favorites.'**
  String get prefStyleOffSubtitle;

  /// No description provided for @prefStyleTouristTitle.
  ///
  /// In en, this message translates to:
  /// **'Tourist Highlights'**
  String get prefStyleTouristTitle;

  /// No description provided for @prefStyleTouristSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Iconic places you want to have seen.'**
  String get prefStyleTouristSubtitle;

  /// No description provided for @gamificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get gamificationTitle;

  /// No description provided for @gamificationYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get gamificationYourProgress;

  /// No description provided for @gamificationCompleteToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Complete activities to unlock achievements'**
  String get gamificationCompleteToUnlock;

  /// No description provided for @gamificationUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get gamificationUnlocked;

  /// No description provided for @gamificationInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get gamificationInProgress;

  /// No description provided for @gamificationLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get gamificationLocked;

  /// No description provided for @gamificationUnlockedOn.
  ///
  /// In en, this message translates to:
  /// **'Unlocked on {date}'**
  String gamificationUnlockedOn(String date);

  /// No description provided for @gamificationClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get gamificationClose;

  /// No description provided for @gamificationCategoryExploration.
  ///
  /// In en, this message translates to:
  /// **'Exploration'**
  String get gamificationCategoryExploration;

  /// No description provided for @gamificationCategoryActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get gamificationCategoryActivities;

  /// No description provided for @gamificationCategorySocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get gamificationCategorySocial;

  /// No description provided for @gamificationCategoryStreaks.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get gamificationCategoryStreaks;

  /// No description provided for @gamificationCategoryMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get gamificationCategoryMood;

  /// No description provided for @gamificationCategorySpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get gamificationCategorySpecial;

  /// No description provided for @gamificationCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get gamificationCategoryOther;

  /// No description provided for @achievementExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get achievementExplorer;

  /// No description provided for @achievementEarlyBird.
  ///
  /// In en, this message translates to:
  /// **'Early Bird'**
  String get achievementEarlyBird;

  /// No description provided for @achievementStreakMaster.
  ///
  /// In en, this message translates to:
  /// **'Streak Master'**
  String get achievementStreakMaster;

  /// No description provided for @achievementMoodTracker.
  ///
  /// In en, this message translates to:
  /// **'Mood Tracker'**
  String get achievementMoodTracker;

  /// No description provided for @achievementAdventurer.
  ///
  /// In en, this message translates to:
  /// **'Adventurer'**
  String get achievementAdventurer;

  /// No description provided for @prefScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Preferences'**
  String get prefScreenTitle;

  /// No description provided for @prefSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get prefSave;

  /// No description provided for @prefSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved successfully'**
  String get prefSavedSuccess;

  /// No description provided for @prefSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving preferences'**
  String get prefSaveError;

  /// No description provided for @prefSectionAgeGroup.
  ///
  /// In en, this message translates to:
  /// **'Age Group'**
  String get prefSectionAgeGroup;

  /// No description provided for @prefSectionAgeGroupSub.
  ///
  /// In en, this message translates to:
  /// **'Helps us recommend age-appropriate activities'**
  String get prefSectionAgeGroupSub;

  /// No description provided for @prefSectionBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget Comfort'**
  String get prefSectionBudget;

  /// No description provided for @prefSectionBudgetSub.
  ///
  /// In en, this message translates to:
  /// **'Your typical spending range for activities'**
  String get prefSectionBudgetSub;

  /// No description provided for @prefSectionSocialVibeSub.
  ///
  /// In en, this message translates to:
  /// **'Do you prefer solo activities or social scenes?'**
  String get prefSectionSocialVibeSub;

  /// No description provided for @prefSectionActivityPace.
  ///
  /// In en, this message translates to:
  /// **'Activity Pace'**
  String get prefSectionActivityPace;

  /// No description provided for @prefSectionActivityPaceSub.
  ///
  /// In en, this message translates to:
  /// **'How energetic do you like your day?'**
  String get prefSectionActivityPaceSub;

  /// No description provided for @prefSectionTimeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Typical Time Available'**
  String get prefSectionTimeAvailable;

  /// No description provided for @prefSectionTimeAvailableSub.
  ///
  /// In en, this message translates to:
  /// **'How much time do you usually have for activities?'**
  String get prefSectionTimeAvailableSub;

  /// No description provided for @prefSectionInterestsSub.
  ///
  /// In en, this message translates to:
  /// **'Select all that apply (helps personalize recommendations)'**
  String get prefSectionInterestsSub;

  /// No description provided for @prefAge1824Label.
  ///
  /// In en, this message translates to:
  /// **'Early 20s'**
  String get prefAge1824Label;

  /// No description provided for @prefAge1824Desc.
  ///
  /// In en, this message translates to:
  /// **'Budget-friendly, social'**
  String get prefAge1824Desc;

  /// No description provided for @prefAge2534Label.
  ///
  /// In en, this message translates to:
  /// **'20s-30s'**
  String get prefAge2534Label;

  /// No description provided for @prefAge2534Desc.
  ///
  /// In en, this message translates to:
  /// **'Trendy, adventurous'**
  String get prefAge2534Desc;

  /// No description provided for @prefAge3544Label.
  ///
  /// In en, this message translates to:
  /// **'30s-40s'**
  String get prefAge3544Label;

  /// No description provided for @prefAge3544Desc.
  ///
  /// In en, this message translates to:
  /// **'Quality experiences'**
  String get prefAge3544Desc;

  /// No description provided for @prefAge4554Label.
  ///
  /// In en, this message translates to:
  /// **'40s-50s'**
  String get prefAge4554Label;

  /// No description provided for @prefAge4554Desc.
  ///
  /// In en, this message translates to:
  /// **'Refined, relaxed'**
  String get prefAge4554Desc;

  /// No description provided for @prefAge55Label.
  ///
  /// In en, this message translates to:
  /// **'55+'**
  String get prefAge55Label;

  /// No description provided for @prefAge55Desc.
  ///
  /// In en, this message translates to:
  /// **'Cultural, scenic'**
  String get prefAge55Desc;

  /// No description provided for @prefBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get prefBudgetLabel;

  /// No description provided for @prefBudgetDesc.
  ///
  /// In en, this message translates to:
  /// **'Free - \$20'**
  String get prefBudgetDesc;

  /// No description provided for @prefModerateLabel.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get prefModerateLabel;

  /// No description provided for @prefModerateDesc.
  ///
  /// In en, this message translates to:
  /// **'\$20 - \$50'**
  String get prefModerateDesc;

  /// No description provided for @prefUpscaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Upscale'**
  String get prefUpscaleLabel;

  /// No description provided for @prefUpscaleDesc.
  ///
  /// In en, this message translates to:
  /// **'\$50 - \$100'**
  String get prefUpscaleDesc;

  /// No description provided for @prefLuxuryLabel.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get prefLuxuryLabel;

  /// No description provided for @prefLuxuryDesc.
  ///
  /// In en, this message translates to:
  /// **'\$100+'**
  String get prefLuxuryDesc;

  /// No description provided for @prefSoloLabel.
  ///
  /// In en, this message translates to:
  /// **'Solo Friendly'**
  String get prefSoloLabel;

  /// No description provided for @prefSoloDesc.
  ///
  /// In en, this message translates to:
  /// **'Quiet, peaceful, me-time'**
  String get prefSoloDesc;

  /// No description provided for @prefSmallGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Small Groups'**
  String get prefSmallGroupLabel;

  /// No description provided for @prefSmallGroupDesc.
  ///
  /// In en, this message translates to:
  /// **'Intimate, cozy gatherings'**
  String get prefSmallGroupDesc;

  /// No description provided for @prefMixLabel.
  ///
  /// In en, this message translates to:
  /// **'Mix of Both'**
  String get prefMixLabel;

  /// No description provided for @prefMixDesc.
  ///
  /// In en, this message translates to:
  /// **'Flexible, variety'**
  String get prefMixDesc;

  /// No description provided for @prefSocialSceneLabel.
  ///
  /// In en, this message translates to:
  /// **'Social Scene'**
  String get prefSocialSceneLabel;

  /// No description provided for @prefSocialSceneDesc.
  ///
  /// In en, this message translates to:
  /// **'Lively, meet people'**
  String get prefSocialSceneDesc;

  /// No description provided for @prefSlowChillLabel.
  ///
  /// In en, this message translates to:
  /// **'Slow & Chill'**
  String get prefSlowChillLabel;

  /// No description provided for @prefSlowChillDesc.
  ///
  /// In en, this message translates to:
  /// **'Take it easy'**
  String get prefSlowChillDesc;

  /// No description provided for @prefModerateActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get prefModerateActivityLabel;

  /// No description provided for @prefModerateActivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Balanced pace'**
  String get prefModerateActivityDesc;

  /// No description provided for @prefActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get prefActiveLabel;

  /// No description provided for @prefActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Energetic, on-the-go'**
  String get prefActiveDesc;

  /// No description provided for @prefQuickVisitLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick Visit'**
  String get prefQuickVisitLabel;

  /// No description provided for @prefHalfDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Half Day'**
  String get prefHalfDayLabel;

  /// No description provided for @prefFullDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Day'**
  String get prefFullDayLabel;

  /// No description provided for @prefInterestCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture & Arts'**
  String get prefInterestCulture;

  /// No description provided for @prefInterestNature.
  ///
  /// In en, this message translates to:
  /// **'Nature & Outdoors'**
  String get prefInterestNature;

  /// No description provided for @prefInterestNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get prefInterestNightlife;

  /// No description provided for @prefInterestWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get prefInterestWellness;

  /// No description provided for @prefInterestAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get prefInterestAdventure;

  /// No description provided for @prefInterestHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get prefInterestHistory;

  /// No description provided for @achievementsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievements Unlocked'**
  String get achievementsUnlocked;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountAreYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get deleteAccountAreYouSure;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data, activities, and preferences will be permanently deleted.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountWhatWillBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'What will be deleted:'**
  String get deleteAccountWhatWillBeDeleted;

  /// No description provided for @deleteAccountProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile and preferences'**
  String get deleteAccountProfile;

  /// No description provided for @deleteAccountActivities.
  ///
  /// In en, this message translates to:
  /// **'All saved activities'**
  String get deleteAccountActivities;

  /// No description provided for @deleteAccountAchievements.
  ///
  /// In en, this message translates to:
  /// **'Your achievements and progress'**
  String get deleteAccountAchievements;

  /// No description provided for @deleteAccountPhotos.
  ///
  /// In en, this message translates to:
  /// **'All photos and memories'**
  String get deleteAccountPhotos;

  /// No description provided for @deleteAccountConfirmKeyword.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAccountConfirmKeyword;

  /// No description provided for @deleteAccountTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"DELETE\" to confirm'**
  String get deleteAccountTypeToConfirm;

  /// No description provided for @deleteAccountTypeIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Please type DELETE to confirm'**
  String get deleteAccountTypeIncorrect;

  /// No description provided for @deleteAccountFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'Final Confirmation'**
  String get deleteAccountFinalTitle;

  /// No description provided for @deleteAccountFinalContent.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccountFinalContent;

  /// No description provided for @deleteAccountCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteAccountCancel;

  /// No description provided for @deleteAccountDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteAccountDeleteForever;

  /// No description provided for @deleteAccountDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account Forever'**
  String get deleteAccountDeleteButton;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting account'**
  String get deleteAccountError;

  /// No description provided for @settingsNotificationsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get settingsNotificationsSectionTitle;

  /// No description provided for @settingsNotificationsTripRemindersLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip reminders'**
  String get settingsNotificationsTripRemindersLabel;

  /// No description provided for @settingsNotificationsTripRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders for planned activities'**
  String get settingsNotificationsTripRemindersSubtitle;

  /// No description provided for @settingsNotificationsWeatherUpdatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Weather updates'**
  String get settingsNotificationsWeatherUpdatesLabel;

  /// No description provided for @settingsNotificationsWeatherUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates about the weather at your destination'**
  String get settingsNotificationsWeatherUpdatesSubtitle;

  /// No description provided for @settingsNotificationsLocalDeviceFootnote.
  ///
  /// In en, this message translates to:
  /// **'These options apply to notifications on this device (including scheduled reminders). They are not separate cloud push messages.'**
  String get settingsNotificationsLocalDeviceFootnote;

  /// No description provided for @premiumComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium — coming soon'**
  String get premiumComingSoonTitle;

  /// No description provided for @premiumComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions will be offered with Apple In-App Purchase in a future update. WanderMood is free to use in this version.'**
  String get premiumComingSoonBody;

  /// No description provided for @premiumComingSoonFootnote.
  ///
  /// In en, this message translates to:
  /// **'We do not collect card details, Apple Pay, or other payments in this build.'**
  String get premiumComingSoonFootnote;

  /// No description provided for @premiumComingSoonCta.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get premiumComingSoonCta;

  /// No description provided for @premiumUpgradeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumUpgradeScreenTitle;

  /// No description provided for @premiumMonthlyPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Plan'**
  String get premiumMonthlyPlanLabel;

  /// No description provided for @premiumMonthlyPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'€4.99/month'**
  String get premiumMonthlyPriceLabel;

  /// No description provided for @premiumBestValueBadge.
  ///
  /// In en, this message translates to:
  /// **'Best Value'**
  String get premiumBestValueBadge;

  /// No description provided for @premiumPaymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get premiumPaymentMethodTitle;

  /// No description provided for @premiumPaymentMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Credit/Debit Card'**
  String get premiumPaymentMethodCard;

  /// No description provided for @premiumPaymentMethodPaypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get premiumPaymentMethodPaypal;

  /// No description provided for @premiumPaymentMethodApplePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get premiumPaymentMethodApplePay;

  /// No description provided for @premiumSubscribeCta.
  ///
  /// In en, this message translates to:
  /// **'Subscribe for €4.99/month'**
  String get premiumSubscribeCta;

  /// No description provided for @premiumSecurityNotice.
  ///
  /// In en, this message translates to:
  /// **'Your payment information is encrypted and secure'**
  String get premiumSecurityNotice;

  /// No description provided for @premiumToastActivated.
  ///
  /// In en, this message translates to:
  /// **'Premium subscription activated!'**
  String get premiumToastActivated;

  /// No description provided for @premiumToastPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed: {error}'**
  String premiumToastPaymentFailed(String error);

  /// No description provided for @premiumCardDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Card Details'**
  String get premiumCardDetailsTitle;

  /// No description provided for @premiumCardNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get premiumCardNumberLabel;

  /// No description provided for @premiumCardNumberHint.
  ///
  /// In en, this message translates to:
  /// **'1234 5678 9012 3456'**
  String get premiumCardNumberHint;

  /// No description provided for @premiumExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry (MM/YY)'**
  String get premiumExpiryLabel;

  /// No description provided for @premiumExpiryHint.
  ///
  /// In en, this message translates to:
  /// **'12/25'**
  String get premiumExpiryHint;

  /// No description provided for @premiumCvvLabel.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get premiumCvvLabel;

  /// No description provided for @premiumCvvHint.
  ///
  /// In en, this message translates to:
  /// **'123'**
  String get premiumCvvHint;

  /// No description provided for @premiumCardholderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get premiumCardholderNameLabel;

  /// No description provided for @premiumCardholderNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get premiumCardholderNameHint;

  /// No description provided for @premiumValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get premiumValidationRequired;

  /// No description provided for @premiumValidationCardNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Card number is required'**
  String get premiumValidationCardNumberRequired;

  /// No description provided for @premiumValidationInvalidCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid card number'**
  String get premiumValidationInvalidCardNumber;

  /// No description provided for @premiumValidationInvalidCvv.
  ///
  /// In en, this message translates to:
  /// **'Invalid CVV'**
  String get premiumValidationInvalidCvv;

  /// No description provided for @premiumValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get premiumValidationNameRequired;

  /// No description provided for @placeDetailAboutThisPlace.
  ///
  /// In en, this message translates to:
  /// **'About this place'**
  String get placeDetailAboutThisPlace;

  /// No description provided for @placeDetailBlurbExtraAddress.
  ///
  /// In en, this message translates to:
  /// **'Address and quick actions are listed just below this section.'**
  String get placeDetailBlurbExtraAddress;

  /// No description provided for @placeDetailBlurbExtraRatingCount.
  ///
  /// In en, this message translates to:
  /// **'Public listings average about {rating} out of 5 across {count} ratings.'**
  String placeDetailBlurbExtraRatingCount(String rating, int count);

  /// No description provided for @placeDetailBlurbExtraRatingOnly.
  ///
  /// In en, this message translates to:
  /// **'Typical scores land around {rating} out of 5 on public listings.'**
  String placeDetailBlurbExtraRatingOnly(String rating);

  /// No description provided for @placeDetailBlurbExtraReviewsTab.
  ///
  /// In en, this message translates to:
  /// **'The Reviews tab shows what visitors mention lately; hours and busy times help you plan your visit.'**
  String get placeDetailBlurbExtraReviewsTab;

  /// No description provided for @placeDetailGoodToKnow.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get placeDetailGoodToKnow;

  /// No description provided for @placeDetailDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get placeDetailDurationLabel;

  /// No description provided for @placeDetailPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get placeDetailPriceLabel;

  /// No description provided for @placeDetailDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get placeDetailDistanceLabel;

  /// No description provided for @placeDetailBestTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Best time'**
  String get placeDetailBestTimeLabel;

  /// No description provided for @placeDetailGoodWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Good with'**
  String get placeDetailGoodWithLabel;

  /// No description provided for @placeDetailEnergyLabel.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get placeDetailEnergyLabel;

  /// No description provided for @placeDetailTimeNeededLabel.
  ///
  /// In en, this message translates to:
  /// **'Time needed'**
  String get placeDetailTimeNeededLabel;

  /// No description provided for @placeDetailNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos available'**
  String get placeDetailNoPhotos;

  /// No description provided for @placeDetailLoadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Loading photos…'**
  String get placeDetailLoadingPhotos;

  /// No description provided for @placeDetailAmazingFeatures.
  ///
  /// In en, this message translates to:
  /// **'Amazing features'**
  String get placeDetailAmazingFeatures;

  /// No description provided for @placeDetailIndoorVibes.
  ///
  /// In en, this message translates to:
  /// **'Indoor vibes'**
  String get placeDetailIndoorVibes;

  /// No description provided for @placeDetailOutdoorFun.
  ///
  /// In en, this message translates to:
  /// **'Outdoor fun'**
  String get placeDetailOutdoorFun;

  /// No description provided for @placeDetailEnergyChipLow.
  ///
  /// In en, this message translates to:
  /// **'Low energy'**
  String get placeDetailEnergyChipLow;

  /// No description provided for @placeDetailEnergyChipMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium energy'**
  String get placeDetailEnergyChipMedium;

  /// No description provided for @placeDetailEnergyChipHigh.
  ///
  /// In en, this message translates to:
  /// **'High energy'**
  String get placeDetailEnergyChipHigh;

  /// No description provided for @placeDetailHeroOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get placeDetailHeroOpenNow;

  /// No description provided for @placeDetailHeroClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get placeDetailHeroClosed;

  /// No description provided for @placeDetailHeroOpenNowLine.
  ///
  /// In en, this message translates to:
  /// **'✅ Open now!'**
  String get placeDetailHeroOpenNowLine;

  /// No description provided for @placeDetailHeroClosedLine.
  ///
  /// In en, this message translates to:
  /// **'❌ Closed'**
  String get placeDetailHeroClosedLine;

  /// No description provided for @placeDetailOpen247.
  ///
  /// In en, this message translates to:
  /// **'Open 24/7'**
  String get placeDetailOpen247;

  /// No description provided for @placeDetailPrice5to15.
  ///
  /// In en, this message translates to:
  /// **'€5–15'**
  String get placeDetailPrice5to15;

  /// No description provided for @placeDetailPrice8to25.
  ///
  /// In en, this message translates to:
  /// **'€8–25'**
  String get placeDetailPrice8to25;

  /// No description provided for @placeDetailPrice10to20.
  ///
  /// In en, this message translates to:
  /// **'€10–20'**
  String get placeDetailPrice10to20;

  /// No description provided for @placeDetailPrice10to25.
  ///
  /// In en, this message translates to:
  /// **'€10–25'**
  String get placeDetailPrice10to25;

  /// No description provided for @placeDetailPrice15to35.
  ///
  /// In en, this message translates to:
  /// **'€15–35'**
  String get placeDetailPrice15to35;

  /// No description provided for @placeDetailPrice15to40.
  ///
  /// In en, this message translates to:
  /// **'€15–40'**
  String get placeDetailPrice15to40;

  /// No description provided for @placeDetailPrice40to80.
  ///
  /// In en, this message translates to:
  /// **'€40–80'**
  String get placeDetailPrice40to80;

  /// No description provided for @placeDetailPrice30to50.
  ///
  /// In en, this message translates to:
  /// **'€30–50'**
  String get placeDetailPrice30to50;

  /// No description provided for @placeDetailPrice50Plus.
  ///
  /// In en, this message translates to:
  /// **'€50+'**
  String get placeDetailPrice50Plus;

  /// No description provided for @placeDetailFreeEntryPayItems.
  ///
  /// In en, this message translates to:
  /// **'Free entry (pay for items)'**
  String get placeDetailFreeEntryPayItems;

  /// No description provided for @placeDetailFreeDonationsWelcome.
  ///
  /// In en, this message translates to:
  /// **'Free (donations welcome)'**
  String get placeDetailFreeDonationsWelcome;

  /// No description provided for @placeDetailUnavailableName.
  ///
  /// In en, this message translates to:
  /// **'Place details unavailable'**
  String get placeDetailUnavailableName;

  /// No description provided for @placeDetailOpeningStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get placeDetailOpeningStatusOpen;

  /// No description provided for @placeDetailOpeningStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'closed'**
  String get placeDetailOpeningStatusClosed;

  /// No description provided for @myDayCarouselSpotFallbackDescription.
  ///
  /// In en, this message translates to:
  /// **'A spot worth checking out'**
  String get myDayCarouselSpotFallbackDescription;

  /// No description provided for @myDayFreeTimeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Activities in your free time'**
  String get myDayFreeTimeSectionTitle;

  /// No description provided for @myDayFreeTimeSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover what you can do right now'**
  String get myDayFreeTimeSectionSubtitle;

  /// No description provided for @myDayFreeTimeIntroOneLine.
  ///
  /// In en, this message translates to:
  /// **'Near you. Discover what you can do right now.'**
  String get myDayFreeTimeIntroOneLine;

  /// No description provided for @myDayFreeTimeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No suggestions cached yet. Open Discover for your area — fresh ideas will show up here.'**
  String get myDayFreeTimeEmptyHint;

  /// No description provided for @myDayFreeTimeLoadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load suggestions. Try again in a moment.'**
  String get myDayFreeTimeLoadingFailed;

  /// No description provided for @myDayFreeTimeLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get myDayFreeTimeLoadMore;

  /// No description provided for @myDayFreeTimeNearYouBadge.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get myDayFreeTimeNearYouBadge;

  /// No description provided for @myDayFreeTimeDirectionsShort.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get myDayFreeTimeDirectionsShort;

  /// No description provided for @myDayFreeTimeCategoryExercise.
  ///
  /// In en, this message translates to:
  /// **'Outdoors & activity'**
  String get myDayFreeTimeCategoryExercise;

  /// No description provided for @myDayFreeTimeCategoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Going out'**
  String get myDayFreeTimeCategoryEntertainment;

  /// No description provided for @myDayFreeTimeCategorySocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get myDayFreeTimeCategorySocial;

  /// No description provided for @myDayFreeTimeCategorySpot.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get myDayFreeTimeCategorySpot;

  /// No description provided for @exploreCardBlurbRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Sit-down dining with changing menus — check the listing for cuisine and hours.'**
  String get exploreCardBlurbRestaurant;

  /// No description provided for @exploreCardBlurbBar.
  ///
  /// In en, this message translates to:
  /// **'Drinks-focused spot — cocktails, wine, or beer depending on what they pour.'**
  String get exploreCardBlurbBar;

  /// No description provided for @exploreCardBlurbCafe.
  ///
  /// In en, this message translates to:
  /// **'Coffee, light bites, and a calm stop — pastries or brunch where offered.'**
  String get exploreCardBlurbCafe;

  /// No description provided for @exploreCardBlurbBakery.
  ///
  /// In en, this message translates to:
  /// **'Fresh bread, pastries, and quick savory bites to stay or take away.'**
  String get exploreCardBlurbBakery;

  /// No description provided for @exploreCardBlurbTakeaway.
  ///
  /// In en, this message translates to:
  /// **'Quick meals and grab-and-go food — handy for a fast bite.'**
  String get exploreCardBlurbTakeaway;

  /// No description provided for @exploreCardBlurbMuseum.
  ///
  /// In en, this message translates to:
  /// **'Exhibitions and collections indoors — tickets and hours on the detail page.'**
  String get exploreCardBlurbMuseum;

  /// No description provided for @exploreCardBlurbZoo.
  ///
  /// In en, this message translates to:
  /// **'Animal exhibits indoors and out — entry is usually ticketed.'**
  String get exploreCardBlurbZoo;

  /// No description provided for @exploreCardBlurbAquarium.
  ///
  /// In en, this message translates to:
  /// **'Aquarium galleries and family-friendly visits — typically ticketed.'**
  String get exploreCardBlurbAquarium;

  /// No description provided for @exploreCardBlurbNightlife.
  ///
  /// In en, this message translates to:
  /// **'Late-night venue — music, dancing, or a lively crowd; fees may apply.'**
  String get exploreCardBlurbNightlife;

  /// No description provided for @exploreCardBlurbPark.
  ///
  /// In en, this message translates to:
  /// **'Outdoor space to walk, sit, or relax — usually free to visit.'**
  String get exploreCardBlurbPark;

  /// No description provided for @exploreCardBlurbAttraction.
  ///
  /// In en, this message translates to:
  /// **'City experience or landmark — may need tickets or a time slot.'**
  String get exploreCardBlurbAttraction;

  /// No description provided for @exploreCardBlurbSpa.
  ///
  /// In en, this message translates to:
  /// **'Treatments and downtime — booking ahead helps on busy days.'**
  String get exploreCardBlurbSpa;

  /// No description provided for @exploreCardBlurbShopping.
  ///
  /// In en, this message translates to:
  /// **'Shops and browsing — opening hours vary by retailer.'**
  String get exploreCardBlurbShopping;

  /// No description provided for @exploreCardBlurbDefault.
  ///
  /// In en, this message translates to:
  /// **'Local place to discover — open the card for hours and practical info.'**
  String get exploreCardBlurbDefault;

  /// No description provided for @exploreCardBlurbSecondSentenceRating.
  ///
  /// In en, this message translates to:
  /// **'Guests rate it around {rating} out of 5 on average — tap through for reviews, photos, and opening hours.'**
  String exploreCardBlurbSecondSentenceRating(String rating);

  /// No description provided for @exploreCardBlurbSecondSentenceNoRating.
  ///
  /// In en, this message translates to:
  /// **'Tap the listing for address, photos, and what reviewers mention most often.'**
  String get exploreCardBlurbSecondSentenceNoRating;

  /// No description provided for @exploreCardBlurbPoiNamed.
  ///
  /// In en, this message translates to:
  /// **'{name} appears on the map as a neighborhood spot — a nice spontaneous stop if you are nearby.'**
  String exploreCardBlurbPoiNamed(String name);

  /// No description provided for @exploreCardBlurbTour.
  ///
  /// In en, this message translates to:
  /// **'Guided experiences and local know-how — check the listing for booking and what is included.'**
  String get exploreCardBlurbTour;

  /// No description provided for @moodyPlaceBlurbSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'You are Moody, the warm voice of the WanderMood travel app. You write accurate and engaging place descriptions for cards. You must not invent menu items, prices, or amenities. Only use facts supplied by the user message. If facts are thin, stay general but still engaging.'**
  String get moodyPlaceBlurbSystemPrompt;

  /// No description provided for @moodyPlaceBlurbUserMessage.
  ///
  /// In en, this message translates to:
  /// **'These are the only verified facts about a real place (from maps data or visitor text). Do not add details that are not supported by them.\n\n{facts}\n\nWrite at least 3 detailed sentences about the atmosphere and offerings for a travel app card. Tone: friendly, like Moody. Use only the facts above. Output entirely in {languageName}. Plain prose: no bullet points, no quotation marks, no lists.'**
  String moodyPlaceBlurbUserMessage(String facts, String languageName);

  /// No description provided for @moodyPlaceBlurbLabelName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get moodyPlaceBlurbLabelName;

  /// No description provided for @moodyPlaceBlurbLabelAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get moodyPlaceBlurbLabelAddress;

  /// No description provided for @moodyPlaceBlurbLabelTypes.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get moodyPlaceBlurbLabelTypes;

  /// No description provided for @moodyPlaceBlurbLabelRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get moodyPlaceBlurbLabelRating;

  /// No description provided for @moodyPlaceBlurbLabelReviewCount.
  ///
  /// In en, this message translates to:
  /// **'Review count'**
  String get moodyPlaceBlurbLabelReviewCount;

  /// No description provided for @moodyPlaceBlurbLabelOverview.
  ///
  /// In en, this message translates to:
  /// **'Place overview'**
  String get moodyPlaceBlurbLabelOverview;

  /// No description provided for @moodyPlaceBlurbLabelVisitorNotes.
  ///
  /// In en, this message translates to:
  /// **'Visitor notes'**
  String get moodyPlaceBlurbLabelVisitorNotes;

  /// No description provided for @moodyPlaceBlurbLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get moodyPlaceBlurbLanguageEnglish;

  /// No description provided for @moodyPlaceBlurbLanguageDutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get moodyPlaceBlurbLanguageDutch;

  /// No description provided for @moodyPlaceBlurbLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get moodyPlaceBlurbLanguageGerman;

  /// No description provided for @moodyPlaceBlurbLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get moodyPlaceBlurbLanguageFrench;

  /// No description provided for @moodyPlaceBlurbLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get moodyPlaceBlurbLanguageSpanish;

  /// No description provided for @moodyPlaceDetailBlurbSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'You are Moody, the warm voice of the WanderMood travel app. You write a fuller, accurate place description for a detail screen. You must not invent menu items, prices, or amenities. Only use facts supplied by the user message. If facts are thin, stay general but still engaging.'**
  String get moodyPlaceDetailBlurbSystemPrompt;

  /// No description provided for @moodyPlaceDetailBlurbUserMessage.
  ///
  /// In en, this message translates to:
  /// **'These are the only verified facts about a real place (from maps data or visitor text). Do not add details that are not supported by them.\n\n{facts}\n\nWrite 5 to 8 detailed sentences including practical tips, history, and why it\'s worth visiting for a travel app place detail screen. Expand on what visitors might experience, atmosphere, and practical cues only when supported by the facts above. Tone: friendly, like Moody. Output entirely in {languageName}. Plain prose: no bullet points, no quotation marks, no lists.'**
  String moodyPlaceDetailBlurbUserMessage(String facts, String languageName);

  /// No description provided for @moodCarouselNearbyBadge.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get moodCarouselNearbyBadge;

  /// No description provided for @moodCarouselSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get moodCarouselSave;

  /// No description provided for @moodCarouselAddToMorning.
  ///
  /// In en, this message translates to:
  /// **'Add to morning'**
  String get moodCarouselAddToMorning;

  /// No description provided for @moodCarouselAddToAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Add to afternoon'**
  String get moodCarouselAddToAfternoon;

  /// No description provided for @moodCarouselAddToEvening.
  ///
  /// In en, this message translates to:
  /// **'Add to evening'**
  String get moodCarouselAddToEvening;

  /// No description provided for @moodCarouselActivityVisitName.
  ///
  /// In en, this message translates to:
  /// **'Visit {name}'**
  String moodCarouselActivityVisitName(String name);

  /// No description provided for @moodCarouselToastAddedMorning.
  ///
  /// In en, this message translates to:
  /// **'{name} added to your morning!'**
  String moodCarouselToastAddedMorning(String name);

  /// No description provided for @moodCarouselToastAddedAfternoon.
  ///
  /// In en, this message translates to:
  /// **'{name} added to your afternoon!'**
  String moodCarouselToastAddedAfternoon(String name);

  /// No description provided for @moodCarouselToastAddedEvening.
  ///
  /// In en, this message translates to:
  /// **'{name} added to your evening!'**
  String moodCarouselToastAddedEvening(String name);

  /// No description provided for @moodCarouselToastAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add {name}. Please try again.'**
  String moodCarouselToastAddFailed(String name);

  /// No description provided for @moodCarouselToastView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get moodCarouselToastView;

  /// No description provided for @myDayFreeTimeInsightDuration.
  ///
  /// In en, this message translates to:
  /// **'⏱️ ~{minutes} min'**
  String myDayFreeTimeInsightDuration(int minutes);

  /// No description provided for @myDayFreeTimeInsightRating.
  ///
  /// In en, this message translates to:
  /// **'⭐ {rating}'**
  String myDayFreeTimeInsightRating(String rating);

  /// No description provided for @myDayFreeTimeInsightPricePaid.
  ///
  /// In en, this message translates to:
  /// **'💶 {symbols}'**
  String myDayFreeTimeInsightPricePaid(String symbols);

  /// No description provided for @placeCardSignInToAddMyDay.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to add activities to My Day'**
  String get placeCardSignInToAddMyDay;

  /// No description provided for @placeCardAddedToMyDay.
  ///
  /// In en, this message translates to:
  /// **'Added {name} to My Day!'**
  String placeCardAddedToMyDay(String name);

  /// No description provided for @placeCardFailedAddToMyDay.
  ///
  /// In en, this message translates to:
  /// **'Failed to add {name} to My Day'**
  String placeCardFailedAddToMyDay(String name);

  /// No description provided for @placeCardUnableOpenDirections.
  ///
  /// In en, this message translates to:
  /// **'Unable to open directions'**
  String get placeCardUnableOpenDirections;

  /// No description provided for @placeCardView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get placeCardView;

  /// No description provided for @placeCardReviewCountInParens.
  ///
  /// In en, this message translates to:
  /// **'({count} reviews)'**
  String placeCardReviewCountInParens(int count);

  /// No description provided for @placeDetailNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews available'**
  String get placeDetailNoReviews;

  /// No description provided for @placeDetailReviewsWhenAvailable.
  ///
  /// In en, this message translates to:
  /// **'Reviews will appear here when available'**
  String get placeDetailReviewsWhenAvailable;

  /// No description provided for @placeDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Place not found'**
  String get placeDetailNotFound;

  /// No description provided for @placeDetailOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Open maps'**
  String get placeDetailOpenMaps;

  /// No description provided for @placeDetailCheckLocally.
  ///
  /// In en, this message translates to:
  /// **'Check locally'**
  String get placeDetailCheckLocally;

  /// No description provided for @placeDetailFreeToVisit.
  ///
  /// In en, this message translates to:
  /// **'Free to visit'**
  String get placeDetailFreeToVisit;

  /// No description provided for @placeDetailVaries.
  ///
  /// In en, this message translates to:
  /// **'Varies'**
  String get placeDetailVaries;

  /// No description provided for @placeDetailFreeEntry.
  ///
  /// In en, this message translates to:
  /// **'Free entry'**
  String get placeDetailFreeEntry;

  /// No description provided for @placeDetailEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get placeDetailEvening;

  /// No description provided for @placeDetailMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get placeDetailMorning;

  /// No description provided for @placeDetailAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get placeDetailAfternoon;

  /// No description provided for @placeDetailAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get placeDetailAnytime;

  /// No description provided for @placeDetailGoodFitForTonight.
  ///
  /// In en, this message translates to:
  /// **'Good fit for tonight'**
  String get placeDetailGoodFitForTonight;

  /// No description provided for @placeDetailBestOnWeekends.
  ///
  /// In en, this message translates to:
  /// **'Best on weekends'**
  String get placeDetailBestOnWeekends;

  /// No description provided for @placeDetailSkipIfChill.
  ///
  /// In en, this message translates to:
  /// **'Skip if you\'re looking for something chill'**
  String get placeDetailSkipIfChill;

  /// No description provided for @placeDetailClosedCheckHours.
  ///
  /// In en, this message translates to:
  /// **'Closed now — check hours'**
  String get placeDetailClosedCheckHours;

  /// No description provided for @placeDetailFriendsGroups.
  ///
  /// In en, this message translates to:
  /// **'Friends / Groups'**
  String get placeDetailFriendsGroups;

  /// No description provided for @placeDetailSoloDate.
  ///
  /// In en, this message translates to:
  /// **'Solo / Date'**
  String get placeDetailSoloDate;

  /// No description provided for @placeDetailSoloFriends.
  ///
  /// In en, this message translates to:
  /// **'Solo / Friends'**
  String get placeDetailSoloFriends;

  /// No description provided for @placeDetailAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get placeDetailAnonymous;

  /// No description provided for @placeDetailRecently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get placeDetailRecently;

  /// No description provided for @placeDetailMoodyName.
  ///
  /// In en, this message translates to:
  /// **'Moody'**
  String get placeDetailMoodyName;

  /// No description provided for @placeDetailMoodyLoadingTips.
  ///
  /// In en, this message translates to:
  /// **'Checking this place…'**
  String get placeDetailMoodyLoadingTips;

  /// No description provided for @placeDetailMoodyFallbackTipA.
  ///
  /// In en, this message translates to:
  /// **'Check opening hours before you go.'**
  String get placeDetailMoodyFallbackTipA;

  /// No description provided for @placeDetailMoodyFallbackTipB.
  ///
  /// In en, this message translates to:
  /// **'Stay hydrated.'**
  String get placeDetailMoodyFallbackTipB;

  /// No description provided for @placeDetailMoodyFallbackTipC.
  ///
  /// In en, this message translates to:
  /// **'Save maps offline if you can.'**
  String get placeDetailMoodyFallbackTipC;

  /// No description provided for @placeDetailBestTimeLunchDinner.
  ///
  /// In en, this message translates to:
  /// **'Lunch / dinner'**
  String get placeDetailBestTimeLunchDinner;

  /// No description provided for @placeDetailDurationAllowOneToTwo.
  ///
  /// In en, this message translates to:
  /// **'Allow 1–2 hours'**
  String get placeDetailDurationAllowOneToTwo;

  /// No description provided for @placeDetailDurationOneToTwo.
  ///
  /// In en, this message translates to:
  /// **'1–2 hours'**
  String get placeDetailDurationOneToTwo;

  /// No description provided for @placeDetailDurationOneToTwoPointFive.
  ///
  /// In en, this message translates to:
  /// **'1–2.5 hours'**
  String get placeDetailDurationOneToTwoPointFive;

  /// No description provided for @placeDetailDurationOneHalfToThree.
  ///
  /// In en, this message translates to:
  /// **'1.5–3 hours'**
  String get placeDetailDurationOneHalfToThree;

  /// No description provided for @placeDetailDurationThirtyToSixty.
  ///
  /// In en, this message translates to:
  /// **'30–60 minutes'**
  String get placeDetailDurationThirtyToSixty;

  /// No description provided for @placeDetailDurationThirtyToFortyFive.
  ///
  /// In en, this message translates to:
  /// **'30–45 minutes'**
  String get placeDetailDurationThirtyToFortyFive;

  /// No description provided for @placeDetailDurationFortyFiveToNinety.
  ///
  /// In en, this message translates to:
  /// **'45 min – 1.5 hours'**
  String get placeDetailDurationFortyFiveToNinety;

  /// No description provided for @placeDetailDurationOneToThree.
  ///
  /// In en, this message translates to:
  /// **'1–3 hours'**
  String get placeDetailDurationOneToThree;

  /// No description provided for @placeDetailDurationTwoToFour.
  ///
  /// In en, this message translates to:
  /// **'2–4 hours'**
  String get placeDetailDurationTwoToFour;

  /// No description provided for @placeDetailDurationOneToFour.
  ///
  /// In en, this message translates to:
  /// **'1–4 hours'**
  String get placeDetailDurationOneToFour;

  /// No description provided for @placeDetailDurationTwoToThree.
  ///
  /// In en, this message translates to:
  /// **'2–3 hours'**
  String get placeDetailDurationTwoToThree;

  /// No description provided for @placeDetailDurationAboutOneHour.
  ///
  /// In en, this message translates to:
  /// **'~1 hour'**
  String get placeDetailDurationAboutOneHour;

  /// No description provided for @placeDetailTabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get placeDetailTabDetails;

  /// No description provided for @placeDetailTabPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get placeDetailTabPhotos;

  /// No description provided for @placeDetailTabReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get placeDetailTabReviews;

  /// No description provided for @placeDetailGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get placeDetailGalleryTitle;

  /// No description provided for @placeDetailPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String placeDetailPhotoCount(int count);

  /// No description provided for @placeDetailReviewsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get placeDetailReviewsSectionTitle;

  /// No description provided for @placeCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get placeCategoryFood;

  /// No description provided for @placeCategoryRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get placeCategoryRestaurant;

  /// No description provided for @placeCategoryCafe.
  ///
  /// In en, this message translates to:
  /// **'Café'**
  String get placeCategoryCafe;

  /// No description provided for @placeCategoryBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get placeCategoryBar;

  /// No description provided for @placeCategoryMuseum.
  ///
  /// In en, this message translates to:
  /// **'Museum'**
  String get placeCategoryMuseum;

  /// No description provided for @placeCategoryPark.
  ///
  /// In en, this message translates to:
  /// **'Park'**
  String get placeCategoryPark;

  /// No description provided for @placeCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get placeCategoryShopping;

  /// No description provided for @placeCategoryCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get placeCategoryCulture;

  /// No description provided for @placeCategoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get placeCategoryNature;

  /// No description provided for @placeCategoryNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get placeCategoryNightlife;

  /// No description provided for @placeCategoryAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get placeCategoryAdventure;

  /// No description provided for @placeCategorySpot.
  ///
  /// In en, this message translates to:
  /// **'Spot'**
  String get placeCategorySpot;

  /// No description provided for @dayPlanDurationHoursOnly.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String dayPlanDurationHoursOnly(int hours);

  /// No description provided for @dayPlanDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String dayPlanDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @dayPlanDurationMinutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String dayPlanDurationMinutesOnly(int minutes);

  /// No description provided for @plannerSheetScheduledPrefix.
  ///
  /// In en, this message translates to:
  /// **'Scheduled {when}'**
  String plannerSheetScheduledPrefix(String when);

  /// No description provided for @plannerSheetAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get plannerSheetAbout;

  /// No description provided for @plannerSheetNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available for this activity yet.'**
  String get plannerSheetNoDescription;

  /// No description provided for @plannerSheetTabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get plannerSheetTabDetails;

  /// No description provided for @plannerSheetTabPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get plannerSheetTabPhotos;

  /// No description provided for @plannerSheetTabReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get plannerSheetTabReviews;

  /// No description provided for @plannerSheetNoExtraPhotos.
  ///
  /// In en, this message translates to:
  /// **'No extra photos on this plan yet.\nWhen the activity is linked to a place, you\'ll see a full gallery in Explore.'**
  String get plannerSheetNoExtraPhotos;

  /// No description provided for @plannerSheetRatingOnPlan.
  ///
  /// In en, this message translates to:
  /// **'Rating on your plan'**
  String get plannerSheetRatingOnPlan;

  /// No description provided for @plannerSheetWrittenReviews.
  ///
  /// In en, this message translates to:
  /// **'Written reviews'**
  String get plannerSheetWrittenReviews;

  /// No description provided for @plannerSheetReviewsExplainerWithRating.
  ///
  /// In en, this message translates to:
  /// **'Star ratings from your plan are shown above. Full Google reviews and more photos appear when this activity is linked to a place — open it from Explore, or schedule it from a place card so WanderMood can attach a place id.'**
  String get plannerSheetReviewsExplainerWithRating;

  /// No description provided for @plannerSheetReviewsExplainerNoRating.
  ///
  /// In en, this message translates to:
  /// **'There\'s no review data on this scheduled item yet. Link it to a Google place (e.g. add it from Explore) to read real visitor reviews in the full place view.'**
  String get plannerSheetReviewsExplainerNoRating;

  /// No description provided for @plannerMoodyAdviceBlurb.
  ///
  /// In en, this message translates to:
  /// **'Tips from Moody:\n• Check opening hours (and weather if you\'ll be outside).\n• Arrive a few minutes early so you can settle in.\n• Stay hydrated and keep an open mind — enjoy the moment!'**
  String get plannerMoodyAdviceBlurb;

  /// No description provided for @plannerMoodMatchQuickTogether.
  ///
  /// In en, this message translates to:
  /// **'You + {partner}'**
  String plannerMoodMatchQuickTogether(String partner);

  /// No description provided for @plannerMoodMatchQuickStory.
  ///
  /// In en, this message translates to:
  /// **'{placeTitle} is in your shared day because it lines up with what you both shared with me — separately, just between us.'**
  String plannerMoodMatchQuickStory(String placeTitle);

  /// No description provided for @plannerMoodMatchQuickPlaceFallback.
  ///
  /// In en, this message translates to:
  /// **'This stop'**
  String get plannerMoodMatchQuickPlaceFallback;

  /// No description provided for @plannerMoodMatchQuickYouLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get plannerMoodMatchQuickYouLabel;

  /// No description provided for @plannerMoodMatchQuickMoodyNote.
  ///
  /// In en, this message translates to:
  /// **'I\'m talking to both of you here — the tabs below are straight venue facts, same as always.'**
  String get plannerMoodMatchQuickMoodyNote;

  /// No description provided for @plannerMoodMatchPairStory_romantic_adventurous.
  ///
  /// In en, this message translates to:
  /// **'{place} threads the needle — intimate atmosphere for the romantic mood, an unexpected menu or setting that satisfies the adventurous one.'**
  String plannerMoodMatchPairStory_romantic_adventurous(String place);

  /// No description provided for @plannerMoodMatchPairStory_adventurous_relaxed.
  ///
  /// In en, this message translates to:
  /// **'{place} works because there\'s enough newness to keep one of you curious, and enough comfort to let the other breathe.'**
  String plannerMoodMatchPairStory_adventurous_relaxed(String place);

  /// No description provided for @plannerMoodMatchPairStory_cultural_social.
  ///
  /// In en, this message translates to:
  /// **'{place} gives you both something to discover and something to talk about — the kind of stop that turns into a real conversation.'**
  String plannerMoodMatchPairStory_cultural_social(String place);

  /// No description provided for @plannerMoodMatchPairStory_relaxed_social.
  ///
  /// In en, this message translates to:
  /// **'{place} is easy and open — room to unwind together without any pressure.'**
  String plannerMoodMatchPairStory_relaxed_social(String place);

  /// No description provided for @plannerMoodMatchPairStory_energetic_relaxed.
  ///
  /// In en, this message translates to:
  /// **'{place} splits the difference — one of you stays energised, the other finds a moment to reset.'**
  String plannerMoodMatchPairStory_energetic_relaxed(String place);

  /// No description provided for @plannerMoodMatchPairStory_cultural_romantic.
  ///
  /// In en, this message translates to:
  /// **'{place} earns its place here by blending atmosphere with something worth looking at together.'**
  String plannerMoodMatchPairStory_cultural_romantic(String place);

  /// No description provided for @plannerMoodMatchPairStory_energetic_adventurous.
  ///
  /// In en, this message translates to:
  /// **'{place} keeps the tempo up — you both wanted something that moves, and this delivers.'**
  String plannerMoodMatchPairStory_energetic_adventurous(String place);

  /// No description provided for @plannerMoodMatchPairStory_contemplative_any.
  ///
  /// In en, this message translates to:
  /// **'I picked {place} because it gives you both space — to talk, to sit with it, or just to be there together.'**
  String plannerMoodMatchPairStory_contemplative_any(String place);

  /// No description provided for @plannerMoodMatchPairStory_same_mood.
  ///
  /// In en, this message translates to:
  /// **'You both came in with the same energy — {place} leans straight into that.'**
  String plannerMoodMatchPairStory_same_mood(String place);

  /// No description provided for @plannerMoodMatchPairStory_default.
  ///
  /// In en, this message translates to:
  /// **'{place} fits what you both shared with me separately — I lined it up so neither mood gets left behind.'**
  String plannerMoodMatchPairStory_default(String place);

  /// No description provided for @plannerMoodMatchNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Leave a note for {partner}…'**
  String plannerMoodMatchNoteHint(String partner);

  /// No description provided for @plannerMoodMatchNoteSave.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get plannerMoodMatchNoteSave;

  /// No description provided for @plannerMoodMatchNoteSaved.
  ///
  /// In en, this message translates to:
  /// **'Sent ✓'**
  String get plannerMoodMatchNoteSaved;

  /// No description provided for @plannerMoodMatchNoteSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get plannerMoodMatchNoteSaving;

  /// No description provided for @plannerMoodMatchNotePartnerLabel.
  ///
  /// In en, this message translates to:
  /// **'{partner} says:'**
  String plannerMoodMatchNotePartnerLabel(String partner);

  /// No description provided for @plannerMoodMatchNoteYourLabel.
  ///
  /// In en, this message translates to:
  /// **'Your note'**
  String get plannerMoodMatchNoteYourLabel;

  /// No description provided for @plannerMoodMatchNoteSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get plannerMoodMatchNoteSectionTitle;

  /// No description provided for @plannerMoodMatchNoteSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved — {partner} will see this when they open this stop (or right away if their sheet is open).'**
  String plannerMoodMatchNoteSavedSnackbar(String partner);

  /// No description provided for @moodyChatSubtitleEnergeticCity.
  ///
  /// In en, this message translates to:
  /// **'Your {city} hype travel bestie'**
  String moodyChatSubtitleEnergeticCity(String city);

  /// No description provided for @moodyChatSubtitleEnergeticNoCity.
  ///
  /// In en, this message translates to:
  /// **'Your hype travel bestie'**
  String get moodyChatSubtitleEnergeticNoCity;

  /// No description provided for @moodyChatSubtitleFriendlyCity.
  ///
  /// In en, this message translates to:
  /// **'Your {city} travel bestie'**
  String moodyChatSubtitleFriendlyCity(String city);

  /// No description provided for @moodyChatSubtitleFriendlyNoCity.
  ///
  /// In en, this message translates to:
  /// **'Your travel bestie'**
  String get moodyChatSubtitleFriendlyNoCity;

  /// No description provided for @moodyChatSubtitleProfessionalCity.
  ///
  /// In en, this message translates to:
  /// **'Your travel companion in {city}'**
  String moodyChatSubtitleProfessionalCity(String city);

  /// No description provided for @moodyChatSubtitleProfessionalNoCity.
  ///
  /// In en, this message translates to:
  /// **'Your professional travel companion'**
  String get moodyChatSubtitleProfessionalNoCity;

  /// No description provided for @moodyChatSubtitleDirectCity.
  ///
  /// In en, this message translates to:
  /// **'{city} · straight-up travel bestie'**
  String moodyChatSubtitleDirectCity(String city);

  /// No description provided for @moodyChatSubtitleDirectNoCity.
  ///
  /// In en, this message translates to:
  /// **'Straight-up travel bestie'**
  String get moodyChatSubtitleDirectNoCity;

  /// No description provided for @moodyHubYourDayToday.
  ///
  /// In en, this message translates to:
  /// **'Your day today'**
  String get moodyHubYourDayToday;

  /// No description provided for @moodyHubChangeMood.
  ///
  /// In en, this message translates to:
  /// **'Change mood'**
  String get moodyHubChangeMood;

  /// No description provided for @moodyHubNoMoodChosen.
  ///
  /// In en, this message translates to:
  /// **'No mood selected yet'**
  String get moodyHubNoMoodChosen;

  /// No description provided for @moodyHubJourneyPrefix.
  ///
  /// In en, this message translates to:
  /// **'You are on a '**
  String get moodyHubJourneyPrefix;

  /// No description provided for @moodyHubJourneySuffix.
  ///
  /// In en, this message translates to:
  /// **' journey'**
  String get moodyHubJourneySuffix;

  /// No description provided for @moodyHubFallbackAiMessage.
  ///
  /// In en, this message translates to:
  /// **'Your day is set — Moody\'s here for you 🌟'**
  String get moodyHubFallbackAiMessage;

  /// No description provided for @moodyHubActivitySingular.
  ///
  /// In en, this message translates to:
  /// **'activity'**
  String get moodyHubActivitySingular;

  /// No description provided for @moodyHubActivityPlural.
  ///
  /// In en, this message translates to:
  /// **'activities'**
  String get moodyHubActivityPlural;

  /// No description provided for @moodyHubPlanForWhen.
  ///
  /// In en, this message translates to:
  /// **'Which day?'**
  String get moodyHubPlanForWhen;

  /// No description provided for @moodyHubListComma.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get moodyHubListComma;

  /// No description provided for @moodyHubListAnd.
  ///
  /// In en, this message translates to:
  /// **' & '**
  String get moodyHubListAnd;

  /// No description provided for @moodyReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Review'**
  String get moodyReviewTitle;

  /// No description provided for @moodyReviewHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How did it land? I\'m listening.'**
  String get moodyReviewHeroSubtitle;

  /// No description provided for @moodyReviewHowWasIt.
  ///
  /// In en, this message translates to:
  /// **'How was it?'**
  String get moodyReviewHowWasIt;

  /// No description provided for @moodyReviewStarsFeedback5.
  ///
  /// In en, this message translates to:
  /// **'🌟 Amazing!'**
  String get moodyReviewStarsFeedback5;

  /// No description provided for @moodyReviewStarsFeedback4.
  ///
  /// In en, this message translates to:
  /// **'😊 Really good!'**
  String get moodyReviewStarsFeedback4;

  /// No description provided for @moodyReviewStarsFeedback3.
  ///
  /// In en, this message translates to:
  /// **'👍 Pretty good!'**
  String get moodyReviewStarsFeedback3;

  /// No description provided for @moodyReviewStarsFeedback2.
  ///
  /// In en, this message translates to:
  /// **'😐 It was okay'**
  String get moodyReviewStarsFeedback2;

  /// No description provided for @moodyReviewStarsFeedback1.
  ///
  /// In en, this message translates to:
  /// **'😞 Not great'**
  String get moodyReviewStarsFeedback1;

  /// No description provided for @moodyReviewYourVibe.
  ///
  /// In en, this message translates to:
  /// **'Your vibe'**
  String get moodyReviewYourVibe;

  /// No description provided for @moodyReviewVibeAmazing.
  ///
  /// In en, this message translates to:
  /// **'Amazing'**
  String get moodyReviewVibeAmazing;

  /// No description provided for @moodyReviewVibeGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodyReviewVibeGood;

  /// No description provided for @moodyReviewVibeOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get moodyReviewVibeOkay;

  /// No description provided for @moodyReviewVibeMeh.
  ///
  /// In en, this message translates to:
  /// **'Meh'**
  String get moodyReviewVibeMeh;

  /// No description provided for @moodyReviewOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'Any thoughts? (optional)'**
  String get moodyReviewOptionalNote;

  /// No description provided for @moodyReviewNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What stood out while it’s fresh?'**
  String get moodyReviewNoteHint;

  /// No description provided for @moodyReviewNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'💡 I use this to tune your next days — private to you and WanderMood.'**
  String get moodyReviewNoteHelper;

  /// No description provided for @moodyReviewSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get moodyReviewSave;

  /// No description provided for @moodyReviewNeedStars.
  ///
  /// In en, this message translates to:
  /// **'Pick a star rating to continue'**
  String get moodyReviewNeedStars;

  /// No description provided for @moodyReviewHelpsMoody.
  ///
  /// In en, this message translates to:
  /// **'This stays between us — and shapes better picks for you.'**
  String get moodyReviewHelpsMoody;

  /// No description provided for @moodyReviewThanksToast.
  ///
  /// In en, this message translates to:
  /// **'Saved — thank you!'**
  String get moodyReviewThanksToast;

  /// No description provided for @profileMomentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your visits'**
  String get profileMomentsTitle;

  /// No description provided for @profileMomentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Places you rated after My Day — private, yours to change'**
  String get profileMomentsSubtitle;

  /// No description provided for @profileMomentsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get profileMomentsSeeAll;

  /// No description provided for @profileMomentsEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Rate a stop on My Day and it shows up here.'**
  String get profileMomentsEmptyCta;

  /// No description provided for @momentsListHeroLine.
  ///
  /// In en, this message translates to:
  /// **'How places felt for you — private unless you choose a partner perk.'**
  String get momentsListHeroLine;

  /// No description provided for @momentsListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No visits yet'**
  String get momentsListEmptyTitle;

  /// No description provided for @momentsListEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you finish a stop on My Day and tap Review, your note appears here. It stays private unless you opt into a partner perk later.'**
  String get momentsListEmptySubtitle;

  /// No description provided for @momentsListError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your visits'**
  String get momentsListError;

  /// No description provided for @momentsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this visit?'**
  String get momentsDeleteConfirmTitle;

  /// No description provided for @momentsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes your rating for {place}. You can add a new one after your next visit.'**
  String momentsDeleteConfirmBody(Object place);

  /// No description provided for @momentsRemovedToast.
  ///
  /// In en, this message translates to:
  /// **'Visit removed'**
  String get momentsRemovedToast;

  /// No description provided for @momentsRemoveCta.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get momentsRemoveCta;

  /// No description provided for @momentsTapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to update'**
  String get momentsTapToEdit;

  /// No description provided for @momentsStarsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} star} other{{count} stars}}'**
  String momentsStarsCount(int count);

  /// No description provided for @getReadyChecklistItemReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to go!'**
  String get getReadyChecklistItemReady;

  /// No description provided for @getReadyShareInvite.
  ///
  /// In en, this message translates to:
  /// **'Join me at {title} around {time} – planned with WanderMood.'**
  String getReadyShareInvite(Object title, Object time);

  /// No description provided for @getReadyCalendarEventTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'WanderMood activity'**
  String get getReadyCalendarEventTitleFallback;

  /// No description provided for @getReadyCalendarEventDetailsFallback.
  ///
  /// In en, this message translates to:
  /// **'Planned with WanderMood'**
  String get getReadyCalendarEventDetailsFallback;

  /// No description provided for @getReadyShareTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'this place'**
  String get getReadyShareTitleFallback;

  /// No description provided for @getReadyCalendarOpenHint.
  ///
  /// In en, this message translates to:
  /// **'{label} – open in browser or app'**
  String getReadyCalendarOpenHint(Object label);

  /// No description provided for @getReadyPlaylistSearchQuery.
  ///
  /// In en, this message translates to:
  /// **'Happy {theme} Beats'**
  String getReadyPlaylistSearchQuery(Object theme);

  /// No description provided for @getReadyPlaylistThemeFoodie.
  ///
  /// In en, this message translates to:
  /// **'Foodie'**
  String get getReadyPlaylistThemeFoodie;

  /// No description provided for @getReadyPlaylistThemeCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get getReadyPlaylistThemeCultural;

  /// No description provided for @getReadyPlaylistThemeShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get getReadyPlaylistThemeShopping;

  /// No description provided for @getReadyPlaylistThemeOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get getReadyPlaylistThemeOutdoor;

  /// No description provided for @getReadyPlaylistThemeAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get getReadyPlaylistThemeAdventure;

  /// No description provided for @getReadyMoodFragmentAdventure.
  ///
  /// In en, this message translates to:
  /// **'adventure'**
  String get getReadyMoodFragmentAdventure;

  /// No description provided for @getReadyMoodFragmentRelaxed.
  ///
  /// In en, this message translates to:
  /// **'relaxation'**
  String get getReadyMoodFragmentRelaxed;

  /// No description provided for @getReadyMoodFragmentEnergetic.
  ///
  /// In en, this message translates to:
  /// **'energy'**
  String get getReadyMoodFragmentEnergetic;

  /// No description provided for @getReadyMoodFragmentRomantic.
  ///
  /// In en, this message translates to:
  /// **'romance'**
  String get getReadyMoodFragmentRomantic;

  /// No description provided for @getReadyMoodFragmentCultural.
  ///
  /// In en, this message translates to:
  /// **'culture'**
  String get getReadyMoodFragmentCultural;

  /// No description provided for @getReadyMoodFragmentExplorer.
  ///
  /// In en, this message translates to:
  /// **'exploration'**
  String get getReadyMoodFragmentExplorer;

  /// No description provided for @getReadyMoodFragmentFoodie.
  ///
  /// In en, this message translates to:
  /// **'foodie'**
  String get getReadyMoodFragmentFoodie;

  /// No description provided for @moodHomeAlreadyPlannedTitle.
  ///
  /// In en, this message translates to:
  /// **'{dayName} is already planned!'**
  String moodHomeAlreadyPlannedTitle(String dayName);

  /// No description provided for @moodHomeActivitiesReadyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 activity is ready for you.} other{{count} activities are ready for you.}}'**
  String moodHomeActivitiesReadyCount(num count);

  /// No description provided for @moodHomeViewPlan.
  ///
  /// In en, this message translates to:
  /// **'View plan'**
  String get moodHomeViewPlan;

  /// No description provided for @moodHomePlanAgain.
  ///
  /// In en, this message translates to:
  /// **'Plan again'**
  String get moodHomePlanAgain;

  /// No description provided for @planLoadingRotating1.
  ///
  /// In en, this message translates to:
  /// **'I\'m weighing your mood and the time of day…'**
  String get planLoadingRotating1;

  /// No description provided for @planLoadingRotating2.
  ///
  /// In en, this message translates to:
  /// **'I\'m scanning the map for strong picks…'**
  String get planLoadingRotating2;

  /// No description provided for @planLoadingRotating3.
  ///
  /// In en, this message translates to:
  /// **'Tightening the last details ✨'**
  String get planLoadingRotating3;

  /// No description provided for @settingsTravelModeHelpLabel.
  ///
  /// In en, this message translates to:
  /// **'Travel mode help'**
  String get settingsTravelModeHelpLabel;

  /// No description provided for @settingsTravelModeHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reopen Local vs Travel guide'**
  String get settingsTravelModeHelpSubtitle;

  /// No description provided for @placeDetailOpeningHours.
  ///
  /// In en, this message translates to:
  /// **'Opening Hours'**
  String get placeDetailOpeningHours;

  /// No description provided for @placeTypeRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get placeTypeRestaurant;

  /// No description provided for @placeTypeCafe.
  ///
  /// In en, this message translates to:
  /// **'Café'**
  String get placeTypeCafe;

  /// No description provided for @placeTypeBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get placeTypeBar;

  /// No description provided for @placeTypeNightclub.
  ///
  /// In en, this message translates to:
  /// **'Nightclub'**
  String get placeTypeNightclub;

  /// No description provided for @placeTypeMuseum.
  ///
  /// In en, this message translates to:
  /// **'Museum'**
  String get placeTypeMuseum;

  /// No description provided for @placeTypeArtGallery.
  ///
  /// In en, this message translates to:
  /// **'Art Gallery'**
  String get placeTypeArtGallery;

  /// No description provided for @placeTypePark.
  ///
  /// In en, this message translates to:
  /// **'Park'**
  String get placeTypePark;

  /// No description provided for @placeTypeTouristAttraction.
  ///
  /// In en, this message translates to:
  /// **'Tourist Attraction'**
  String get placeTypeTouristAttraction;

  /// No description provided for @placeTypeBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get placeTypeBakery;

  /// No description provided for @placeTypeShoppingMall.
  ///
  /// In en, this message translates to:
  /// **'Shopping Mall'**
  String get placeTypeShoppingMall;

  /// No description provided for @placeTypeSpa.
  ///
  /// In en, this message translates to:
  /// **'Spa'**
  String get placeTypeSpa;

  /// No description provided for @placeTypeGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get placeTypeGym;

  /// No description provided for @placeTypeMovieTheater.
  ///
  /// In en, this message translates to:
  /// **'Cinema'**
  String get placeTypeMovieTheater;

  /// No description provided for @placeTypeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get placeTypeLibrary;

  /// No description provided for @placeTypeChurch.
  ///
  /// In en, this message translates to:
  /// **'Church'**
  String get placeTypeChurch;

  /// No description provided for @placeTypeAmusementPark.
  ///
  /// In en, this message translates to:
  /// **'Amusement Park'**
  String get placeTypeAmusementPark;

  /// No description provided for @placeTypeZoo.
  ///
  /// In en, this message translates to:
  /// **'Zoo'**
  String get placeTypeZoo;

  /// No description provided for @placeTypeAquarium.
  ///
  /// In en, this message translates to:
  /// **'Aquarium'**
  String get placeTypeAquarium;

  /// No description provided for @placeTypeBowling.
  ///
  /// In en, this message translates to:
  /// **'Bowling'**
  String get placeTypeBowling;

  /// No description provided for @placeTypeStadium.
  ///
  /// In en, this message translates to:
  /// **'Stadium'**
  String get placeTypeStadium;

  /// No description provided for @placeCardSocialTrending.
  ///
  /// In en, this message translates to:
  /// **'🔥 Trending'**
  String get placeCardSocialTrending;

  /// No description provided for @placeCardSocialHiddenGem.
  ///
  /// In en, this message translates to:
  /// **'💎 Hidden gem'**
  String get placeCardSocialHiddenGem;

  /// No description provided for @placeCardSocialLovedByLocals.
  ///
  /// In en, this message translates to:
  /// **'❤️ Locals love it'**
  String get placeCardSocialLovedByLocals;

  /// No description provided for @placeCardSocialPopular.
  ///
  /// In en, this message translates to:
  /// **'⭐ Popular'**
  String get placeCardSocialPopular;

  /// No description provided for @placeCardBestMorning.
  ///
  /// In en, this message translates to:
  /// **'☀️ Best in the morning'**
  String get placeCardBestMorning;

  /// No description provided for @placeCardBestAfternoon.
  ///
  /// In en, this message translates to:
  /// **'🌤 Best in the afternoon'**
  String get placeCardBestAfternoon;

  /// No description provided for @placeCardBestEvening.
  ///
  /// In en, this message translates to:
  /// **'🌙 Best in the evening'**
  String get placeCardBestEvening;

  /// No description provided for @placeCardBestAllDay.
  ///
  /// In en, this message translates to:
  /// **'🕐 Great any time'**
  String get placeCardBestAllDay;

  /// No description provided for @placeCardVenuePlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get placeCardVenuePlace;

  /// No description provided for @placeCardVenueGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get placeCardVenueGallery;

  /// No description provided for @placeCardVenueAttraction.
  ///
  /// In en, this message translates to:
  /// **'Attraction'**
  String get placeCardVenueAttraction;

  /// No description provided for @placeCardVenueHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get placeCardVenueHotel;

  /// No description provided for @placeCardVenueClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get placeCardVenueClub;

  /// No description provided for @placeDescFood.
  ///
  /// In en, this message translates to:
  /// **'{name} is a great spot for food lovers looking for a quality meal in the area.'**
  String placeDescFood(String name);

  /// No description provided for @placeDescFoodWithReviews.
  ///
  /// In en, this message translates to:
  /// **'{name} is a popular restaurant with {reviewCount} reviews and a rating of {rating}. A great choice for a quality meal.'**
  String placeDescFoodWithReviews(
      String name, String rating, String reviewCount);

  /// No description provided for @placeDescCafe.
  ///
  /// In en, this message translates to:
  /// **'{name} is a cozy café perfect for a coffee break or a light bite in a relaxed atmosphere.'**
  String placeDescCafe(String name);

  /// No description provided for @placeDescCafeWithRating.
  ///
  /// In en, this message translates to:
  /// **'{name} is a highly regarded café with a {rating}-star rating, perfect for coffee and a relaxing break.'**
  String placeDescCafeWithRating(String name, String rating);

  /// No description provided for @placeDescBar.
  ///
  /// In en, this message translates to:
  /// **'{name} is a great bar for enjoying drinks and a lively atmosphere with friends.'**
  String placeDescBar(String name);

  /// No description provided for @placeDescMuseum.
  ///
  /// In en, this message translates to:
  /// **'{name} offers an enriching cultural experience with fascinating exhibits and inspiring collections.'**
  String placeDescMuseum(String name);

  /// No description provided for @placeDescPark.
  ///
  /// In en, this message translates to:
  /// **'{name} is a beautiful green space ideal for a walk, relaxation, or outdoor activities.'**
  String placeDescPark(String name);

  /// No description provided for @placeDescAttraction.
  ///
  /// In en, this message translates to:
  /// **'{name} is a must-visit destination with unique experiences and memorable moments.'**
  String placeDescAttraction(String name);

  /// No description provided for @placeDescAttractionWithRating.
  ///
  /// In en, this message translates to:
  /// **'{name} is a top-rated attraction with {rating} stars, offering unique and memorable experiences.'**
  String placeDescAttractionWithRating(String name, String rating);

  /// No description provided for @placeDescSpa.
  ///
  /// In en, this message translates to:
  /// **'{name} is a premium wellness destination offering relaxing treatments and rejuvenating experiences.'**
  String placeDescSpa(String name);

  /// No description provided for @placeDescGeneric.
  ///
  /// In en, this message translates to:
  /// **'{name} is a wonderful place to discover, with great atmosphere and excellent vibes.'**
  String placeDescGeneric(String name);

  /// No description provided for @placeDescGenericWithRating.
  ///
  /// In en, this message translates to:
  /// **'{name} is a highly-rated local gem with {rating} stars, offering a unique experience worth exploring.'**
  String placeDescGenericWithRating(String name, String rating);

  /// No description provided for @notifReEngagementEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Psst... Moody misses you 👀'**
  String get notifReEngagementEnergeticV0Title;

  /// No description provided for @notifReEngagementEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'The world\'s been waiting. Ready to explore again?'**
  String get notifReEngagementEnergeticV0Body;

  /// No description provided for @notifReEngagementEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Your wanderlust called'**
  String get notifReEngagementEnergeticV1Title;

  /// No description provided for @notifReEngagementEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'It left a voicemail. Something about adventure. Want to listen?'**
  String get notifReEngagementEnergeticV1Body;

  /// No description provided for @notifReEngagementEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Plot twist needed'**
  String get notifReEngagementEnergeticV2Title;

  /// No description provided for @notifReEngagementEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Your story\'s been on pause. Time to write the next chapter.'**
  String get notifReEngagementEnergeticV2Body;

  /// No description provided for @notifReEngagementFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Hey, we\'ve been thinking of you 💛'**
  String get notifReEngagementFriendlyV0Title;

  /// No description provided for @notifReEngagementFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Come back and I will help plan your next adventure.'**
  String get notifReEngagementFriendlyV0Body;

  /// No description provided for @notifReEngagementFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Missing your energy around here!'**
  String get notifReEngagementFriendlyV1Title;

  /// No description provided for @notifReEngagementFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Your travel bestie is ready whenever you are.'**
  String get notifReEngagementFriendlyV1Body;

  /// No description provided for @notifReEngagementFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Good to see you again soon'**
  String get notifReEngagementFriendlyV2Title;

  /// No description provided for @notifReEngagementFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Ready to discover something new together?'**
  String get notifReEngagementFriendlyV2Body;

  /// No description provided for @notifReEngagementProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get notifReEngagementProfessionalV0Title;

  /// No description provided for @notifReEngagementProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Your travel plans are waiting.'**
  String get notifReEngagementProfessionalV0Body;

  /// No description provided for @notifReEngagementProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Time to explore'**
  String get notifReEngagementProfessionalV1Title;

  /// No description provided for @notifReEngagementProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Open the app to pick up where you left off.'**
  String get notifReEngagementProfessionalV1Body;

  /// No description provided for @notifReEngagementProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Your journey continues'**
  String get notifReEngagementProfessionalV2Title;

  /// No description provided for @notifReEngagementProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'New recommendations are ready for you.'**
  String get notifReEngagementProfessionalV2Body;

  /// No description provided for @notifReEngagementDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t checked in lately'**
  String get notifReEngagementDirectV0Title;

  /// No description provided for @notifReEngagementDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Open WanderMood to continue.'**
  String get notifReEngagementDirectV0Body;

  /// No description provided for @notifReEngagementDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Your travel plans are waiting'**
  String get notifReEngagementDirectV1Title;

  /// No description provided for @notifReEngagementDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue.'**
  String get notifReEngagementDirectV1Body;

  /// No description provided for @notifReEngagementDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Back when you\'re ready'**
  String get notifReEngagementDirectV2Title;

  /// No description provided for @notifReEngagementDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Your saved plans and mood history are here.'**
  String get notifReEngagementDirectV2Body;

  /// No description provided for @notifMorningWithPlanFallbackActivity.
  ///
  /// In en, this message translates to:
  /// **'your first stop'**
  String get notifMorningWithPlanFallbackActivity;

  /// No description provided for @notifMorningWithPlanEnergeticTitle.
  ///
  /// In en, this message translates to:
  /// **'Rise and shine {weatherEmoji}'**
  String notifMorningWithPlanEnergeticTitle(String weatherEmoji);

  /// No description provided for @notifMorningWithPlanEnergeticBody.
  ///
  /// In en, this message translates to:
  /// **'First up: {activityName}. Let\'s own today.'**
  String notifMorningWithPlanEnergeticBody(String activityName);

  /// No description provided for @notifMorningWithPlanFriendlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Good morning {weatherEmoji}'**
  String notifMorningWithPlanFriendlyTitle(String weatherEmoji);

  /// No description provided for @notifMorningWithPlanFriendlyBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re starting with {activityName} today — I\'m here if you need me.'**
  String notifMorningWithPlanFriendlyBody(String activityName);

  /// No description provided for @notifMorningWithPlanProfessionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Good morning {weatherEmoji}'**
  String notifMorningWithPlanProfessionalTitle(String weatherEmoji);

  /// No description provided for @notifMorningWithPlanProfessionalBody.
  ///
  /// In en, this message translates to:
  /// **'Your schedule includes {activityName} today.'**
  String notifMorningWithPlanProfessionalBody(String activityName);

  /// No description provided for @notifMorningWithPlanDirectTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s plan {weatherEmoji}'**
  String notifMorningWithPlanDirectTitle(String weatherEmoji);

  /// No description provided for @notifMorningWithPlanDirectBody.
  ///
  /// In en, this message translates to:
  /// **'{activityName} is first. Tap to open.'**
  String notifMorningWithPlanDirectBody(String activityName);

  /// No description provided for @notifDailyMoodCheckInEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'What vibe are we serving today? ✨'**
  String get notifDailyMoodCheckInEnergeticV0Title;

  /// No description provided for @notifDailyMoodCheckInEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Log your mood and I will find your perfect match.'**
  String get notifDailyMoodCheckInEnergeticV0Body;

  /// No description provided for @notifDailyMoodCheckInEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Mood check! Go.'**
  String get notifDailyMoodCheckInEnergeticV1Title;

  /// No description provided for @notifDailyMoodCheckInEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Three seconds. Maximum insights. Let\'s see it.'**
  String get notifDailyMoodCheckInEnergeticV1Body;

  /// No description provided for @notifDailyMoodCheckInEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Your emotional GPS needs calibrating'**
  String get notifDailyMoodCheckInEnergeticV2Title;

  /// No description provided for @notifDailyMoodCheckInEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Tell Moody how you\'re feeling — it shapes everything.'**
  String get notifDailyMoodCheckInEnergeticV2Body;

  /// No description provided for @notifDailyMoodCheckInFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Good morning! How are you feeling? 😊'**
  String get notifDailyMoodCheckInFriendlyV0Title;

  /// No description provided for @notifDailyMoodCheckInFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Log your mood and let\'s plan something that fits.'**
  String get notifDailyMoodCheckInFriendlyV0Body;

  /// No description provided for @notifDailyMoodCheckInFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Daily mood check-in time'**
  String get notifDailyMoodCheckInFriendlyV1Title;

  /// No description provided for @notifDailyMoodCheckInFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'A quick tap so I know how your day is going.'**
  String get notifDailyMoodCheckInFriendlyV1Body;

  /// No description provided for @notifDailyMoodCheckInFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'How\'s your travel mood today?'**
  String get notifDailyMoodCheckInFriendlyV2Title;

  /// No description provided for @notifDailyMoodCheckInFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Share how you\'re feeling and discover what matches.'**
  String get notifDailyMoodCheckInFriendlyV2Body;

  /// No description provided for @notifDailyMoodCheckInProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Daily mood check-in'**
  String get notifDailyMoodCheckInProfessionalV0Title;

  /// No description provided for @notifDailyMoodCheckInProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s mood for personalised recommendations.'**
  String get notifDailyMoodCheckInProfessionalV0Body;

  /// No description provided for @notifDailyMoodCheckInProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Time to check in'**
  String get notifDailyMoodCheckInProfessionalV1Title;

  /// No description provided for @notifDailyMoodCheckInProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Record your mood to continue your streak.'**
  String get notifDailyMoodCheckInProfessionalV1Body;

  /// No description provided for @notifDailyMoodCheckInProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Mood log reminder'**
  String get notifDailyMoodCheckInProfessionalV2Title;

  /// No description provided for @notifDailyMoodCheckInProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Your daily check-in keeps recommendations accurate.'**
  String get notifDailyMoodCheckInProfessionalV2Body;

  /// No description provided for @notifDailyMoodCheckInDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s mood'**
  String get notifDailyMoodCheckInDirectV0Title;

  /// No description provided for @notifDailyMoodCheckInDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to check in.'**
  String get notifDailyMoodCheckInDirectV0Body;

  /// No description provided for @notifDailyMoodCheckInDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in'**
  String get notifDailyMoodCheckInDirectV1Title;

  /// No description provided for @notifDailyMoodCheckInDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get notifDailyMoodCheckInDirectV1Body;

  /// No description provided for @notifDailyMoodCheckInDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Mood reminder'**
  String get notifDailyMoodCheckInDirectV2Title;

  /// No description provided for @notifDailyMoodCheckInDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Log your mood to keep your streak alive.'**
  String get notifDailyMoodCheckInDirectV2Body;

  /// No description provided for @notifGenerateMyDayEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Let Moody cook today 🔥'**
  String get notifGenerateMyDayEnergeticV0Title;

  /// No description provided for @notifGenerateMyDayEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Your perfect day is one tap away — trust the algorithm.'**
  String get notifGenerateMyDayEnergeticV0Body;

  /// No description provided for @notifGenerateMyDayEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Blank day? Not on Moody\'s watch'**
  String get notifGenerateMyDayEnergeticV1Title;

  /// No description provided for @notifGenerateMyDayEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Tell Moody your mood and watch the magic happen.'**
  String get notifGenerateMyDayEnergeticV1Body;

  /// No description provided for @notifGenerateMyDayEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Today could be legendary'**
  String get notifGenerateMyDayEnergeticV2Title;

  /// No description provided for @notifGenerateMyDayEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'You in? Moody\'s ready to generate something unforgettable.'**
  String get notifGenerateMyDayEnergeticV2Body;

  /// No description provided for @notifGenerateMyDayFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Ready to plan today? 🗺️'**
  String get notifGenerateMyDayFriendlyV0Title;

  /// No description provided for @notifGenerateMyDayFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Let Moody put together the perfect day for your mood.'**
  String get notifGenerateMyDayFriendlyV0Body;

  /// No description provided for @notifGenerateMyDayFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Your day is full of possibilities'**
  String get notifGenerateMyDayFriendlyV1Title;

  /// No description provided for @notifGenerateMyDayFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Generate a plan and make the most of today.'**
  String get notifGenerateMyDayFriendlyV1Body;

  /// No description provided for @notifGenerateMyDayFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Moody has ideas for today!'**
  String get notifGenerateMyDayFriendlyV2Title;

  /// No description provided for @notifGenerateMyDayFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to see what\'s perfect for your current mood.'**
  String get notifGenerateMyDayFriendlyV2Body;

  /// No description provided for @notifGenerateMyDayProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Plan your day'**
  String get notifGenerateMyDayProfessionalV0Title;

  /// No description provided for @notifGenerateMyDayProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Generate a mood-matched itinerary for today.'**
  String get notifGenerateMyDayProfessionalV0Body;

  /// No description provided for @notifGenerateMyDayProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Daily planner ready'**
  String get notifGenerateMyDayProfessionalV1Title;

  /// No description provided for @notifGenerateMyDayProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to create today\'s activity plan.'**
  String get notifGenerateMyDayProfessionalV1Body;

  /// No description provided for @notifGenerateMyDayProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Generate today\'s itinerary'**
  String get notifGenerateMyDayProfessionalV2Title;

  /// No description provided for @notifGenerateMyDayProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Personalised to your mood and preferences.'**
  String get notifGenerateMyDayProfessionalV2Body;

  /// No description provided for @notifGenerateMyDayDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Plan today'**
  String get notifGenerateMyDayDirectV0Title;

  /// No description provided for @notifGenerateMyDayDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to generate your day.'**
  String get notifGenerateMyDayDirectV0Body;

  /// No description provided for @notifGenerateMyDayDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Generate My Day'**
  String get notifGenerateMyDayDirectV1Title;

  /// No description provided for @notifGenerateMyDayDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Create today\'s itinerary now.'**
  String get notifGenerateMyDayDirectV1Body;

  /// No description provided for @notifGenerateMyDayDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s plan'**
  String get notifGenerateMyDayDirectV2Title;

  /// No description provided for @notifGenerateMyDayDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to build your schedule.'**
  String get notifGenerateMyDayDirectV2Body;

  /// No description provided for @notifWeatherNudgeEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'The weather just got interesting ☀️'**
  String get notifWeatherNudgeEnergeticV0Title;

  /// No description provided for @notifWeatherNudgeEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Moody\'s already updating your picks. Check what\'s good.'**
  String get notifWeatherNudgeEnergeticV0Body;

  /// No description provided for @notifWeatherNudgeEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Weather alert: perfect adventure conditions'**
  String get notifWeatherNudgeEnergeticV1Title;

  /// No description provided for @notifWeatherNudgeEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Get out there — Moody\'s got the spots.'**
  String get notifWeatherNudgeEnergeticV1Body;

  /// No description provided for @notifWeatherNudgeEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Rain? Moody has opinions about that'**
  String get notifWeatherNudgeEnergeticV2Title;

  /// No description provided for @notifWeatherNudgeEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to see what\'s actually great on a day like this.'**
  String get notifWeatherNudgeEnergeticV2Body;

  /// No description provided for @notifWeatherNudgeFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s weather is looking great! 🌤️'**
  String get notifWeatherNudgeFriendlyV0Title;

  /// No description provided for @notifWeatherNudgeFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Perfect for getting out — want to see what\'s nearby?'**
  String get notifWeatherNudgeFriendlyV0Body;

  /// No description provided for @notifWeatherNudgeFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Weather update for your plans'**
  String get notifWeatherNudgeFriendlyV1Title;

  /// No description provided for @notifWeatherNudgeFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Check the latest conditions and adjust your day.'**
  String get notifWeatherNudgeFriendlyV1Body;

  /// No description provided for @notifWeatherNudgeFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Cosy day incoming'**
  String get notifWeatherNudgeFriendlyV2Title;

  /// No description provided for @notifWeatherNudgeFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Let Moody suggest something perfect for this weather.'**
  String get notifWeatherNudgeFriendlyV2Body;

  /// No description provided for @notifWeatherNudgeProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Weather update'**
  String get notifWeatherNudgeProfessionalV0Title;

  /// No description provided for @notifWeatherNudgeProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Conditions have changed. Check activity suggestions.'**
  String get notifWeatherNudgeProfessionalV0Body;

  /// No description provided for @notifWeatherNudgeProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s forecast'**
  String get notifWeatherNudgeProfessionalV1Title;

  /// No description provided for @notifWeatherNudgeProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Updated recommendations based on current weather.'**
  String get notifWeatherNudgeProfessionalV1Body;

  /// No description provided for @notifWeatherNudgeProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Weather change noted'**
  String get notifWeatherNudgeProfessionalV2Title;

  /// No description provided for @notifWeatherNudgeProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Your activity plan has been refreshed.'**
  String get notifWeatherNudgeProfessionalV2Body;

  /// No description provided for @notifWeatherNudgeDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Weather changed'**
  String get notifWeatherNudgeDirectV0Title;

  /// No description provided for @notifWeatherNudgeDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Check updated activity suggestions.'**
  String get notifWeatherNudgeDirectV0Body;

  /// No description provided for @notifWeatherNudgeDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Weather alert'**
  String get notifWeatherNudgeDirectV1Title;

  /// No description provided for @notifWeatherNudgeDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap for weather-matched plans.'**
  String get notifWeatherNudgeDirectV1Body;

  /// No description provided for @notifWeatherNudgeDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s conditions'**
  String get notifWeatherNudgeDirectV2Title;

  /// No description provided for @notifWeatherNudgeDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Updated picks based on the weather.'**
  String get notifWeatherNudgeDirectV2Body;

  /// No description provided for @notifLocationDiscoveryEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'You\'re surrounded by hidden gems 💎'**
  String get notifLocationDiscoveryEnergeticV0Title;

  /// No description provided for @notifLocationDiscoveryEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Moody spotted something amazing near you. Go look.'**
  String get notifLocationDiscoveryEnergeticV0Body;

  /// No description provided for @notifLocationDiscoveryEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Plot twist: your next fave spot is 5 mins away'**
  String get notifLocationDiscoveryEnergeticV1Title;

  /// No description provided for @notifLocationDiscoveryEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'No excuses. Moody found it. Tap to see.'**
  String get notifLocationDiscoveryEnergeticV1Body;

  /// No description provided for @notifLocationDiscoveryEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Something\'s calling your name nearby'**
  String get notifLocationDiscoveryEnergeticV2Title;

  /// No description provided for @notifLocationDiscoveryEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Your GPS says you should definitely check this out.'**
  String get notifLocationDiscoveryEnergeticV2Body;

  /// No description provided for @notifLocationDiscoveryFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Something great is near you! 📍'**
  String get notifLocationDiscoveryFriendlyV0Title;

  /// No description provided for @notifLocationDiscoveryFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Moody found a spot that might be just your thing.'**
  String get notifLocationDiscoveryFriendlyV0Body;

  /// No description provided for @notifLocationDiscoveryFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Discovery nearby'**
  String get notifLocationDiscoveryFriendlyV1Title;

  /// No description provided for @notifLocationDiscoveryFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'There\'s something worth checking out close to where you are.'**
  String get notifLocationDiscoveryFriendlyV1Body;

  /// No description provided for @notifLocationDiscoveryFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Moody found something interesting'**
  String get notifLocationDiscoveryFriendlyV2Title;

  /// No description provided for @notifLocationDiscoveryFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'A local gem is waiting just around the corner.'**
  String get notifLocationDiscoveryFriendlyV2Body;

  /// No description provided for @notifLocationDiscoveryProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Nearby discovery'**
  String get notifLocationDiscoveryProfessionalV0Title;

  /// No description provided for @notifLocationDiscoveryProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'A new location matches your travel interests.'**
  String get notifLocationDiscoveryProfessionalV0Body;

  /// No description provided for @notifLocationDiscoveryProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Local point of interest'**
  String get notifLocationDiscoveryProfessionalV1Title;

  /// No description provided for @notifLocationDiscoveryProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Something relevant to your preferences is close by.'**
  String get notifLocationDiscoveryProfessionalV1Body;

  /// No description provided for @notifLocationDiscoveryProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Place discovered nearby'**
  String get notifLocationDiscoveryProfessionalV2Title;

  /// No description provided for @notifLocationDiscoveryProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Check the activity suggestion for your area.'**
  String get notifLocationDiscoveryProfessionalV2Body;

  /// No description provided for @notifLocationDiscoveryDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Place nearby'**
  String get notifLocationDiscoveryDirectV0Title;

  /// No description provided for @notifLocationDiscoveryDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Something matches your interests. Tap to see.'**
  String get notifLocationDiscoveryDirectV0Body;

  /// No description provided for @notifLocationDiscoveryDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Local discovery'**
  String get notifLocationDiscoveryDirectV1Title;

  /// No description provided for @notifLocationDiscoveryDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'New spot near you.'**
  String get notifLocationDiscoveryDirectV1Body;

  /// No description provided for @notifLocationDiscoveryDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Nearby activity'**
  String get notifLocationDiscoveryDirectV2Title;

  /// No description provided for @notifLocationDiscoveryDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Check what\'s close.'**
  String get notifLocationDiscoveryDirectV2Body;

  /// No description provided for @notifSavedActivityReminderEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Your saved spots are feeling ignored 👀'**
  String get notifSavedActivityReminderEnergeticV0Title;

  /// No description provided for @notifSavedActivityReminderEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'You saved it for a reason. Time to actually go.'**
  String get notifSavedActivityReminderEnergeticV0Body;

  /// No description provided for @notifSavedActivityReminderEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'That thing on your list? Still there.'**
  String get notifSavedActivityReminderEnergeticV1Title;

  /// No description provided for @notifSavedActivityReminderEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Moody\'s keeping receipts. Shall we make it happen?'**
  String get notifSavedActivityReminderEnergeticV1Body;

  /// No description provided for @notifSavedActivityReminderEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Reminder: you have taste'**
  String get notifSavedActivityReminderEnergeticV2Title;

  /// No description provided for @notifSavedActivityReminderEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Your saved activities are proof. Go experience them.'**
  String get notifSavedActivityReminderEnergeticV2Body;

  /// No description provided for @notifSavedActivityReminderFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Remember that place you saved? 🌟'**
  String get notifSavedActivityReminderFriendlyV0Title;

  /// No description provided for @notifSavedActivityReminderFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'It\'s still on your list — want to make plans?'**
  String get notifSavedActivityReminderFriendlyV0Body;

  /// No description provided for @notifSavedActivityReminderFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Your saved activities are waiting'**
  String get notifSavedActivityReminderFriendlyV1Title;

  /// No description provided for @notifSavedActivityReminderFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Ready to turn those saves into actual plans?'**
  String get notifSavedActivityReminderFriendlyV1Body;

  /// No description provided for @notifSavedActivityReminderFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget your saved spots!'**
  String get notifSavedActivityReminderFriendlyV2Title;

  /// No description provided for @notifSavedActivityReminderFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'You picked these for a reason — let me help you go.'**
  String get notifSavedActivityReminderFriendlyV2Body;

  /// No description provided for @notifSavedActivityReminderProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Saved activity reminder'**
  String get notifSavedActivityReminderProfessionalV0Title;

  /// No description provided for @notifSavedActivityReminderProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'You have activities saved. Ready to plan a visit?'**
  String get notifSavedActivityReminderProfessionalV0Body;

  /// No description provided for @notifSavedActivityReminderProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Your saved list'**
  String get notifSavedActivityReminderProfessionalV1Title;

  /// No description provided for @notifSavedActivityReminderProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Revisit your saved places and schedule a visit.'**
  String get notifSavedActivityReminderProfessionalV1Body;

  /// No description provided for @notifSavedActivityReminderProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Saved places waiting'**
  String get notifSavedActivityReminderProfessionalV2Title;

  /// No description provided for @notifSavedActivityReminderProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Plan a visit to your bookmarked activities.'**
  String get notifSavedActivityReminderProfessionalV2Body;

  /// No description provided for @notifSavedActivityReminderDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Saved activities need attention'**
  String get notifSavedActivityReminderDirectV0Title;

  /// No description provided for @notifSavedActivityReminderDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to view your list.'**
  String get notifSavedActivityReminderDirectV0Body;

  /// No description provided for @notifSavedActivityReminderDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Your saved list'**
  String get notifSavedActivityReminderDirectV1Title;

  /// No description provided for @notifSavedActivityReminderDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Check and plan a visit.'**
  String get notifSavedActivityReminderDirectV1Body;

  /// No description provided for @notifSavedActivityReminderDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Saved spots reminder'**
  String get notifSavedActivityReminderDirectV2Title;

  /// No description provided for @notifSavedActivityReminderDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Schedule a visit to a saved activity.'**
  String get notifSavedActivityReminderDirectV2Body;

  /// No description provided for @notifFestivalEventEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Something epic is happening near you 🎉'**
  String get notifFestivalEventEnergeticV0Title;

  /// No description provided for @notifFestivalEventEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Moody can\'t keep quiet about this. You need to see it.'**
  String get notifFestivalEventEnergeticV0Body;

  /// No description provided for @notifFestivalEventEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'An event just dropped that has your name on it'**
  String get notifFestivalEventEnergeticV1Title;

  /// No description provided for @notifFestivalEventEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Seriously, this one\'s too good to miss. Tap to see.'**
  String get notifFestivalEventEnergeticV1Body;

  /// No description provided for @notifFestivalEventEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Festival alert! Your kind of thing.'**
  String get notifFestivalEventEnergeticV2Title;

  /// No description provided for @notifFestivalEventEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Moody found an event that matches your vibe. Go.'**
  String get notifFestivalEventEnergeticV2Body;

  /// No description provided for @notifFestivalEventFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'There\'s a fun event coming up! 🎊'**
  String get notifFestivalEventFriendlyV0Title;

  /// No description provided for @notifFestivalEventFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Something\'s happening nearby that you might love.'**
  String get notifFestivalEventFriendlyV0Body;

  /// No description provided for @notifFestivalEventFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Event alert near you'**
  String get notifFestivalEventFriendlyV1Title;

  /// No description provided for @notifFestivalEventFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Moody found something worth checking out this week.'**
  String get notifFestivalEventFriendlyV1Body;

  /// No description provided for @notifFestivalEventFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Something exciting is happening'**
  String get notifFestivalEventFriendlyV2Title;

  /// No description provided for @notifFestivalEventFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'A local event that fits your interests is coming up.'**
  String get notifFestivalEventFriendlyV2Body;

  /// No description provided for @notifFestivalEventProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Upcoming local event'**
  String get notifFestivalEventProfessionalV0Title;

  /// No description provided for @notifFestivalEventProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'An event matching your interests is taking place soon.'**
  String get notifFestivalEventProfessionalV0Body;

  /// No description provided for @notifFestivalEventProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Event notification'**
  String get notifFestivalEventProfessionalV1Title;

  /// No description provided for @notifFestivalEventProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'A relevant festival or event is happening nearby.'**
  String get notifFestivalEventProfessionalV1Body;

  /// No description provided for @notifFestivalEventProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Festival alert'**
  String get notifFestivalEventProfessionalV2Title;

  /// No description provided for @notifFestivalEventProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Local event details are ready for review.'**
  String get notifFestivalEventProfessionalV2Body;

  /// No description provided for @notifFestivalEventDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Event nearby this week'**
  String get notifFestivalEventDirectV0Title;

  /// No description provided for @notifFestivalEventDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to see details.'**
  String get notifFestivalEventDirectV0Body;

  /// No description provided for @notifFestivalEventDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Local festival happening'**
  String get notifFestivalEventDirectV1Title;

  /// No description provided for @notifFestivalEventDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Check event details.'**
  String get notifFestivalEventDirectV1Body;

  /// No description provided for @notifFestivalEventDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Upcoming event'**
  String get notifFestivalEventDirectV2Title;

  /// No description provided for @notifFestivalEventDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Event near you this week.'**
  String get notifFestivalEventDirectV2Body;

  /// No description provided for @notifCompanionMorningEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Morning! I\'m already plotting ☀️'**
  String get notifCompanionMorningEnergeticV0Title;

  /// No description provided for @notifCompanionMorningEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'What are we doing today? Drop your mood and let\'s go.'**
  String get notifCompanionMorningEnergeticV0Body;

  /// No description provided for @notifCompanionMorningEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Rise and explore! ✨'**
  String get notifCompanionMorningEnergeticV1Title;

  /// No description provided for @notifCompanionMorningEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'A new day = new adventures. I\'m ready when you are.'**
  String get notifCompanionMorningEnergeticV1Body;

  /// No description provided for @notifCompanionMorningEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Your travel bestie is awake'**
  String get notifCompanionMorningEnergeticV2Title;

  /// No description provided for @notifCompanionMorningEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'And honestly a little too excited about today\'s possibilities.'**
  String get notifCompanionMorningEnergeticV2Body;

  /// No description provided for @notifCompanionMorningFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Good morning! ☀️'**
  String get notifCompanionMorningFriendlyV0Title;

  /// No description provided for @notifCompanionMorningFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling? Let me help make today amazing.'**
  String get notifCompanionMorningFriendlyV0Body;

  /// No description provided for @notifCompanionMorningFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Morning check-in'**
  String get notifCompanionMorningFriendlyV1Title;

  /// No description provided for @notifCompanionMorningFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Start the day with your mood and let\'s plan something great.'**
  String get notifCompanionMorningFriendlyV1Body;

  /// No description provided for @notifCompanionMorningFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'I\'m saying good morning 😊'**
  String get notifCompanionMorningFriendlyV2Title;

  /// No description provided for @notifCompanionMorningFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Share how you\'re feeling and let\'s make today count.'**
  String get notifCompanionMorningFriendlyV2Body;

  /// No description provided for @notifCompanionMorningProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get notifCompanionMorningProfessionalV0Title;

  /// No description provided for @notifCompanionMorningProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Check in with today\'s mood to get personalised suggestions.'**
  String get notifCompanionMorningProfessionalV0Body;

  /// No description provided for @notifCompanionMorningProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Morning check-in'**
  String get notifCompanionMorningProfessionalV1Title;

  /// No description provided for @notifCompanionMorningProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Log your mood to start your day with tailored recommendations.'**
  String get notifCompanionMorningProfessionalV1Body;

  /// No description provided for @notifCompanionMorningProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Start your day'**
  String get notifCompanionMorningProfessionalV2Title;

  /// No description provided for @notifCompanionMorningProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Today\'s recommendations are ready for your mood.'**
  String get notifCompanionMorningProfessionalV2Body;

  /// No description provided for @notifCompanionMorningDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Morning check-in'**
  String get notifCompanionMorningDirectV0Title;

  /// No description provided for @notifCompanionMorningDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Log your mood to start the day.'**
  String get notifCompanionMorningDirectV0Body;

  /// No description provided for @notifCompanionMorningDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get notifCompanionMorningDirectV1Title;

  /// No description provided for @notifCompanionMorningDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to check in.'**
  String get notifCompanionMorningDirectV1Body;

  /// No description provided for @notifCompanionMorningDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Start your day'**
  String get notifCompanionMorningDirectV2Title;

  /// No description provided for @notifCompanionMorningDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Log your mood.'**
  String get notifCompanionMorningDirectV2Body;

  /// No description provided for @notifCompanionAfternoonEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Midday report — how\'s it going? 🌞'**
  String get notifCompanionAfternoonEnergeticV0Title;

  /// No description provided for @notifCompanionAfternoonEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Tell me what you\'re feeling. We can still make today legendary.'**
  String get notifCompanionAfternoonEnergeticV0Body;

  /// No description provided for @notifCompanionAfternoonEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Afternoon check! Still thriving? ✨'**
  String get notifCompanionAfternoonEnergeticV1Title;

  /// No description provided for @notifCompanionAfternoonEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Update your mood and I\'ll update your picks.'**
  String get notifCompanionAfternoonEnergeticV1Body;

  /// No description provided for @notifCompanionAfternoonEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Halfway through the day'**
  String get notifCompanionAfternoonEnergeticV2Title;

  /// No description provided for @notifCompanionAfternoonEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'How\'s your energy? I\'ve got afternoon plans if you need them.'**
  String get notifCompanionAfternoonEnergeticV2Body;

  /// No description provided for @notifCompanionAfternoonFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Afternoon check-in! 😊'**
  String get notifCompanionAfternoonFriendlyV0Title;

  /// No description provided for @notifCompanionAfternoonFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Hope your day\'s been great — how are you feeling now?'**
  String get notifCompanionAfternoonFriendlyV0Body;

  /// No description provided for @notifCompanionAfternoonFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'I\'m thinking of you'**
  String get notifCompanionAfternoonFriendlyV1Title;

  /// No description provided for @notifCompanionAfternoonFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'How\'s your afternoon going? Update your mood anytime.'**
  String get notifCompanionAfternoonFriendlyV1Body;

  /// No description provided for @notifCompanionAfternoonFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Midday check-in'**
  String get notifCompanionAfternoonFriendlyV2Title;

  /// No description provided for @notifCompanionAfternoonFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Check in with how you\'re feeling and see what\'s nearby.'**
  String get notifCompanionAfternoonFriendlyV2Body;

  /// No description provided for @notifCompanionAfternoonProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Afternoon check-in'**
  String get notifCompanionAfternoonProfessionalV0Title;

  /// No description provided for @notifCompanionAfternoonProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Update your mood for afternoon recommendations.'**
  String get notifCompanionAfternoonProfessionalV0Body;

  /// No description provided for @notifCompanionAfternoonProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Midday update'**
  String get notifCompanionAfternoonProfessionalV1Title;

  /// No description provided for @notifCompanionAfternoonProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Log how you\'re feeling to refine today\'s suggestions.'**
  String get notifCompanionAfternoonProfessionalV1Body;

  /// No description provided for @notifCompanionAfternoonProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'How\'s your afternoon?'**
  String get notifCompanionAfternoonProfessionalV2Title;

  /// No description provided for @notifCompanionAfternoonProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Check in to keep your travel profile current.'**
  String get notifCompanionAfternoonProfessionalV2Body;

  /// No description provided for @notifCompanionAfternoonDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Afternoon check-in'**
  String get notifCompanionAfternoonDirectV0Title;

  /// No description provided for @notifCompanionAfternoonDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get notifCompanionAfternoonDirectV0Body;

  /// No description provided for @notifCompanionAfternoonDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Midday check'**
  String get notifCompanionAfternoonDirectV1Title;

  /// No description provided for @notifCompanionAfternoonDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Update your mood.'**
  String get notifCompanionAfternoonDirectV1Body;

  /// No description provided for @notifCompanionAfternoonDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get notifCompanionAfternoonDirectV2Title;

  /// No description provided for @notifCompanionAfternoonDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to log your mood.'**
  String get notifCompanionAfternoonDirectV2Body;

  /// No description provided for @notifCompanionEveningEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Evening! What did you get up to? 🌙'**
  String get notifCompanionEveningEnergeticV0Title;

  /// No description provided for @notifCompanionEveningEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Catch me up — any highlights from today?'**
  String get notifCompanionEveningEnergeticV0Body;

  /// No description provided for @notifCompanionEveningEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Golden hour check ✨'**
  String get notifCompanionEveningEnergeticV1Title;

  /// No description provided for @notifCompanionEveningEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Wind down, reflect, share. What was the best bit?'**
  String get notifCompanionEveningEnergeticV1Body;

  /// No description provided for @notifCompanionEveningEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Night mode activated'**
  String get notifCompanionEveningEnergeticV2Title;

  /// No description provided for @notifCompanionEveningEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Tell me about your day — and maybe plan tomorrow.'**
  String get notifCompanionEveningEnergeticV2Body;

  /// No description provided for @notifCompanionEveningFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Good evening! 🌙'**
  String get notifCompanionEveningFriendlyV0Title;

  /// No description provided for @notifCompanionEveningFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'How was your day? Share your mood and reflect with me.'**
  String get notifCompanionEveningFriendlyV0Body;

  /// No description provided for @notifCompanionEveningFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Evening check-in'**
  String get notifCompanionEveningFriendlyV1Title;

  /// No description provided for @notifCompanionEveningFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Wind down time — any adventures to log?'**
  String get notifCompanionEveningFriendlyV1Body;

  /// No description provided for @notifCompanionEveningFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Evening check-in'**
  String get notifCompanionEveningFriendlyV2Title;

  /// No description provided for @notifCompanionEveningFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling as the day wraps up?'**
  String get notifCompanionEveningFriendlyV2Body;

  /// No description provided for @notifCompanionEveningProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Evening check-in'**
  String get notifCompanionEveningProfessionalV0Title;

  /// No description provided for @notifCompanionEveningProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Reflect on today and log your end-of-day mood.'**
  String get notifCompanionEveningProfessionalV0Body;

  /// No description provided for @notifCompanionEveningProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'End of day'**
  String get notifCompanionEveningProfessionalV1Title;

  /// No description provided for @notifCompanionEveningProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Record your evening mood for a full picture of your day.'**
  String get notifCompanionEveningProfessionalV1Body;

  /// No description provided for @notifCompanionEveningProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get notifCompanionEveningProfessionalV2Title;

  /// No description provided for @notifCompanionEveningProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Today\'s activity summary is ready. Log your reflection.'**
  String get notifCompanionEveningProfessionalV2Body;

  /// No description provided for @notifCompanionEveningDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Evening check-in'**
  String get notifCompanionEveningDirectV0Title;

  /// No description provided for @notifCompanionEveningDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'How was your day?'**
  String get notifCompanionEveningDirectV0Body;

  /// No description provided for @notifCompanionEveningDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'End of day'**
  String get notifCompanionEveningDirectV1Title;

  /// No description provided for @notifCompanionEveningDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Log your mood.'**
  String get notifCompanionEveningDirectV1Body;

  /// No description provided for @notifCompanionEveningDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get notifCompanionEveningDirectV2Title;

  /// No description provided for @notifCompanionEveningDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to check in.'**
  String get notifCompanionEveningDirectV2Body;

  /// No description provided for @notifStreakMilestoneEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'{days} days straight — Moody is SHOOK 🔥'**
  String notifStreakMilestoneEnergeticV0Title(String days);

  /// No description provided for @notifStreakMilestoneEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'You\'re basically a WanderMood legend at this point. Keep going.'**
  String get notifStreakMilestoneEnergeticV0Body;

  /// No description provided for @notifStreakMilestoneEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Alert: {days}-day streak detected ⚡'**
  String notifStreakMilestoneEnergeticV1Title(String days);

  /// No description provided for @notifStreakMilestoneEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'This is extremely impressive and Moody is not chill about it.'**
  String get notifStreakMilestoneEnergeticV1Body;

  /// No description provided for @notifStreakMilestoneEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak! You\'re on fire!'**
  String notifStreakMilestoneEnergeticV2Title(String days);

  /// No description provided for @notifStreakMilestoneEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'The world needs more explorers like you. Don\'t stop now.'**
  String get notifStreakMilestoneEnergeticV2Body;

  /// No description provided for @notifStreakMilestoneFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Wow, {days} days in a row! 🎉'**
  String notifStreakMilestoneFriendlyV0Title(String days);

  /// No description provided for @notifStreakMilestoneFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been so consistent — Moody is really proud of you!'**
  String get notifStreakMilestoneFriendlyV0Body;

  /// No description provided for @notifStreakMilestoneFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak reached!'**
  String notifStreakMilestoneFriendlyV1Title(String days);

  /// No description provided for @notifStreakMilestoneFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing amazing. Keep that travel energy going!'**
  String get notifStreakMilestoneFriendlyV1Body;

  /// No description provided for @notifStreakMilestoneFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'You\'re on a {days}-day streak 🔥'**
  String notifStreakMilestoneFriendlyV2Title(String days);

  /// No description provided for @notifStreakMilestoneFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'What an achievement — here\'s to the next milestone!'**
  String get notifStreakMilestoneFriendlyV2Body;

  /// No description provided for @notifStreakMilestoneProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak milestone'**
  String notifStreakMilestoneProfessionalV0Title(String days);

  /// No description provided for @notifStreakMilestoneProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Consistent engagement. Your streak continues.'**
  String get notifStreakMilestoneProfessionalV0Body;

  /// No description provided for @notifStreakMilestoneProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Streak milestone reached'**
  String get notifStreakMilestoneProfessionalV1Title;

  /// No description provided for @notifStreakMilestoneProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'{days} consecutive days. Keep it going.'**
  String notifStreakMilestoneProfessionalV1Body(String days);

  /// No description provided for @notifStreakMilestoneProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String notifStreakMilestoneProfessionalV2Title(String days);

  /// No description provided for @notifStreakMilestoneProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Streak milestone achieved.'**
  String get notifStreakMilestoneProfessionalV2Body;

  /// No description provided for @notifStreakMilestoneDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String notifStreakMilestoneDirectV0Title(String days);

  /// No description provided for @notifStreakMilestoneDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Keep going.'**
  String get notifStreakMilestoneDirectV0Body;

  /// No description provided for @notifStreakMilestoneDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Streak milestone: {days} days'**
  String notifStreakMilestoneDirectV1Title(String days);

  /// No description provided for @notifStreakMilestoneDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Don\'t break it now.'**
  String get notifStreakMilestoneDirectV1Body;

  /// No description provided for @notifStreakMilestoneDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'{days} consecutive days'**
  String notifStreakMilestoneDirectV2Title(String days);

  /// No description provided for @notifStreakMilestoneDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Streak milestone reached.'**
  String get notifStreakMilestoneDirectV2Body;

  /// No description provided for @notifAchievementUnlockedEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'🏆 YOU JUST EARNED \'{achievementTitle}\'!'**
  String notifAchievementUnlockedEnergeticV0Title(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Moody is doing an actual happy dance right now. You legend.'**
  String get notifAchievementUnlockedEnergeticV0Body;

  /// No description provided for @notifAchievementUnlockedEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Badge unlocked: {achievementTitle} ✨'**
  String notifAchievementUnlockedEnergeticV1Title(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'This one\'s got your name all over it. Well deserved.'**
  String get notifAchievementUnlockedEnergeticV1Body;

  /// No description provided for @notifAchievementUnlockedEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Achievement get: {achievementTitle} 🎉'**
  String notifAchievementUnlockedEnergeticV2Title(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Added to your collection. Moody knew you could do it.'**
  String get notifAchievementUnlockedEnergeticV2Body;

  /// No description provided for @notifAchievementUnlockedFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'New achievement unlocked! 🏆'**
  String get notifAchievementUnlockedFriendlyV0Title;

  /// No description provided for @notifAchievementUnlockedFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'You earned the \'{achievementTitle}\' badge — that\'s amazing!'**
  String notifAchievementUnlockedFriendlyV0Body(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Congrats! \'{achievementTitle}\' is yours 🌟'**
  String notifAchievementUnlockedFriendlyV1Title(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'You worked for this one. Enjoy the milestone!'**
  String get notifAchievementUnlockedFriendlyV1Body;

  /// No description provided for @notifAchievementUnlockedFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'You unlocked \'{achievementTitle}\'!'**
  String notifAchievementUnlockedFriendlyV2Title(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Achievement added to your profile — you\'re on a roll!'**
  String get notifAchievementUnlockedFriendlyV2Body;

  /// No description provided for @notifAchievementUnlockedProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked: {achievementTitle}'**
  String notifAchievementUnlockedProfessionalV0Title(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Badge earned and added to your profile.'**
  String get notifAchievementUnlockedProfessionalV0Body;

  /// No description provided for @notifAchievementUnlockedProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'New badge: {achievementTitle}'**
  String notifAchievementUnlockedProfessionalV1Title(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Achievement milestone reached.'**
  String get notifAchievementUnlockedProfessionalV1Body;

  /// No description provided for @notifAchievementUnlockedProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'{achievementTitle}'**
  String notifAchievementUnlockedProfessionalV2Title(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked.'**
  String get notifAchievementUnlockedProfessionalV2Body;

  /// No description provided for @notifAchievementUnlockedDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Badge earned: {achievementTitle}'**
  String notifAchievementUnlockedDirectV0Title(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked.'**
  String get notifAchievementUnlockedDirectV0Body;

  /// No description provided for @notifAchievementUnlockedDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'{achievementTitle} unlocked'**
  String notifAchievementUnlockedDirectV1Title(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'New achievement added.'**
  String get notifAchievementUnlockedDirectV1Body;

  /// No description provided for @notifAchievementUnlockedDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Achievement: {achievementTitle}'**
  String notifAchievementUnlockedDirectV2Title(String achievementTitle);

  /// No description provided for @notifAchievementUnlockedDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Earned.'**
  String get notifAchievementUnlockedDirectV2Body;

  /// No description provided for @notifWeeklyMoodRecapEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Your week in moods just dropped 📊'**
  String get notifWeeklyMoodRecapEnergeticV0Title;

  /// No description provided for @notifWeeklyMoodRecapEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Plot twist: you contain multitudes. Want to see the data?'**
  String get notifWeeklyMoodRecapEnergeticV0Body;

  /// No description provided for @notifWeeklyMoodRecapEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Weekly mood report — and it\'s giving a lot'**
  String get notifWeeklyMoodRecapEnergeticV1Title;

  /// No description provided for @notifWeeklyMoodRecapEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Moody crunched the numbers. The results are interesting.'**
  String get notifWeeklyMoodRecapEnergeticV1Body;

  /// No description provided for @notifWeeklyMoodRecapEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'7 days, infinite vibes'**
  String get notifWeeklyMoodRecapEnergeticV2Title;

  /// No description provided for @notifWeeklyMoodRecapEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Your mood recap is here and honestly? You\'re fascinating.'**
  String get notifWeeklyMoodRecapEnergeticV2Body;

  /// No description provided for @notifWeeklyMoodRecapFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Your weekly mood recap is ready! 🌈'**
  String get notifWeeklyMoodRecapFriendlyV0Title;

  /// No description provided for @notifWeeklyMoodRecapFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to reflect on how your week felt.'**
  String get notifWeeklyMoodRecapFriendlyV0Body;

  /// No description provided for @notifWeeklyMoodRecapFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Week in review 📊'**
  String get notifWeeklyMoodRecapFriendlyV1Title;

  /// No description provided for @notifWeeklyMoodRecapFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Here\'s a look at your moods this week — want to explore it?'**
  String get notifWeeklyMoodRecapFriendlyV1Body;

  /// No description provided for @notifWeeklyMoodRecapFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Moody has your mood summary ready'**
  String get notifWeeklyMoodRecapFriendlyV2Title;

  /// No description provided for @notifWeeklyMoodRecapFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'A little reflection goes a long way. Check your week.'**
  String get notifWeeklyMoodRecapFriendlyV2Body;

  /// No description provided for @notifWeeklyMoodRecapProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Weekly mood summary'**
  String get notifWeeklyMoodRecapProfessionalV0Title;

  /// No description provided for @notifWeeklyMoodRecapProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Your mood report for the past 7 days is ready.'**
  String get notifWeeklyMoodRecapProfessionalV0Body;

  /// No description provided for @notifWeeklyMoodRecapProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Week in review'**
  String get notifWeeklyMoodRecapProfessionalV1Title;

  /// No description provided for @notifWeeklyMoodRecapProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Mood data and insights from this week are available.'**
  String get notifWeeklyMoodRecapProfessionalV1Body;

  /// No description provided for @notifWeeklyMoodRecapProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Weekly report'**
  String get notifWeeklyMoodRecapProfessionalV2Title;

  /// No description provided for @notifWeeklyMoodRecapProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Review your mood patterns from the past week.'**
  String get notifWeeklyMoodRecapProfessionalV2Body;

  /// No description provided for @notifWeeklyMoodRecapDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Weekly mood recap'**
  String get notifWeeklyMoodRecapDirectV0Title;

  /// No description provided for @notifWeeklyMoodRecapDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to view your summary.'**
  String get notifWeeklyMoodRecapDirectV0Body;

  /// No description provided for @notifWeeklyMoodRecapDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Mood summary ready'**
  String get notifWeeklyMoodRecapDirectV1Title;

  /// No description provided for @notifWeeklyMoodRecapDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Check your week.'**
  String get notifWeeklyMoodRecapDirectV1Body;

  /// No description provided for @notifWeeklyMoodRecapDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Weekly report'**
  String get notifWeeklyMoodRecapDirectV2Title;

  /// No description provided for @notifWeeklyMoodRecapDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'7-day mood data ready.'**
  String get notifWeeklyMoodRecapDirectV2Body;

  /// No description provided for @notifPostTripReflectionEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'You just did a whole thing! 🗺️'**
  String get notifPostTripReflectionEnergeticV0Title;

  /// No description provided for @notifPostTripReflectionEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'We need ALL the details. How was the adventure?'**
  String get notifPostTripReflectionEnergeticV0Body;

  /// No description provided for @notifPostTripReflectionEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Trip complete — debrief time'**
  String get notifPostTripReflectionEnergeticV1Title;

  /// No description provided for @notifPostTripReflectionEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Moody wants a full recap. Rate it, log it, live it.'**
  String get notifPostTripReflectionEnergeticV1Body;

  /// No description provided for @notifPostTripReflectionEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Tell me everything'**
  String get notifPostTripReflectionEnergeticV2Title;

  /// No description provided for @notifPostTripReflectionEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'That adventure you just finished? It deserves a proper reflection.'**
  String get notifPostTripReflectionEnergeticV2Body;

  /// No description provided for @notifPostTripReflectionFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Hope your trip was amazing! 🌟'**
  String get notifPostTripReflectionFriendlyV0Title;

  /// No description provided for @notifPostTripReflectionFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'How did it go? Share your thoughts and log a post-trip mood.'**
  String get notifPostTripReflectionFriendlyV0Body;

  /// No description provided for @notifPostTripReflectionFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Your plan is complete'**
  String get notifPostTripReflectionFriendlyV1Title;

  /// No description provided for @notifPostTripReflectionFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to reflect on how it went.'**
  String get notifPostTripReflectionFriendlyV1Body;

  /// No description provided for @notifPostTripReflectionFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Time for a trip reflection 😊'**
  String get notifPostTripReflectionFriendlyV2Title;

  /// No description provided for @notifPostTripReflectionFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Log how you felt about your adventure — Moody wants to know!'**
  String get notifPostTripReflectionFriendlyV2Body;

  /// No description provided for @notifPostTripReflectionProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get notifPostTripReflectionProfessionalV0Title;

  /// No description provided for @notifPostTripReflectionProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Share your post-trip reflection and mood rating.'**
  String get notifPostTripReflectionProfessionalV0Body;

  /// No description provided for @notifPostTripReflectionProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Post-trip feedback'**
  String get notifPostTripReflectionProfessionalV1Title;

  /// No description provided for @notifPostTripReflectionProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Log how your completed plan went.'**
  String get notifPostTripReflectionProfessionalV1Body;

  /// No description provided for @notifPostTripReflectionProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Trip summary'**
  String get notifPostTripReflectionProfessionalV2Title;

  /// No description provided for @notifPostTripReflectionProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Record your post-activity mood and reflections.'**
  String get notifPostTripReflectionProfessionalV2Body;

  /// No description provided for @notifPostTripReflectionDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Log your post-trip mood'**
  String get notifPostTripReflectionDirectV0Title;

  /// No description provided for @notifPostTripReflectionDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience.'**
  String get notifPostTripReflectionDirectV0Body;

  /// No description provided for @notifPostTripReflectionDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Trip done'**
  String get notifPostTripReflectionDirectV1Title;

  /// No description provided for @notifPostTripReflectionDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Reflect on how it went.'**
  String get notifPostTripReflectionDirectV1Body;

  /// No description provided for @notifPostTripReflectionDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Post-trip check-in'**
  String get notifPostTripReflectionDirectV2Title;

  /// No description provided for @notifPostTripReflectionDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Log your experience.'**
  String get notifPostTripReflectionDirectV2Body;

  /// No description provided for @notifMoodFollowUpEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Still feeling {moodType}? 💡'**
  String notifMoodFollowUpEnergeticV0Title(String moodType);

  /// No description provided for @notifMoodFollowUpEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Moody found something that matches your energy perfectly.'**
  String get notifMoodFollowUpEnergeticV0Body;

  /// No description provided for @notifMoodFollowUpEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Your {moodType} vibe deserves an outlet'**
  String notifMoodFollowUpEnergeticV1Title(String moodType);

  /// No description provided for @notifMoodFollowUpEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Here\'s exactly where to take that energy. You\'ll love it.'**
  String get notifMoodFollowUpEnergeticV1Body;

  /// No description provided for @notifMoodFollowUpEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'{moodType} energy + this place = chef\'s kiss'**
  String notifMoodFollowUpEnergeticV2Title(String moodType);

  /// No description provided for @notifMoodFollowUpEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Moody did the math. Trust the algorithm.'**
  String get notifMoodFollowUpEnergeticV2Body;

  /// No description provided for @notifMoodFollowUpFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Based on your {moodType} mood 💛'**
  String notifMoodFollowUpFriendlyV0Title(String moodType);

  /// No description provided for @notifMoodFollowUpFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Moody found something nearby that fits perfectly. Want to see?'**
  String get notifMoodFollowUpFriendlyV0Body;

  /// No description provided for @notifMoodFollowUpFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'A suggestion for your {moodType} vibe'**
  String notifMoodFollowUpFriendlyV1Title(String moodType);

  /// No description provided for @notifMoodFollowUpFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Something close by that matches how you\'re feeling.'**
  String get notifMoodFollowUpFriendlyV1Body;

  /// No description provided for @notifMoodFollowUpFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Still feeling {moodType}?'**
  String notifMoodFollowUpFriendlyV2Title(String moodType);

  /// No description provided for @notifMoodFollowUpFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Here\'s a great match for your current energy.'**
  String get notifMoodFollowUpFriendlyV2Body;

  /// No description provided for @notifMoodFollowUpProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Mood-matched suggestion'**
  String get notifMoodFollowUpProfessionalV0Title;

  /// No description provided for @notifMoodFollowUpProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Activity recommendation based on your {moodType} check-in.'**
  String notifMoodFollowUpProfessionalV0Body(String moodType);

  /// No description provided for @notifMoodFollowUpProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Based on your mood'**
  String get notifMoodFollowUpProfessionalV1Title;

  /// No description provided for @notifMoodFollowUpProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Curated suggestion aligned with your {moodType} preference.'**
  String notifMoodFollowUpProfessionalV1Body(String moodType);

  /// No description provided for @notifMoodFollowUpProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Activity match'**
  String get notifMoodFollowUpProfessionalV2Title;

  /// No description provided for @notifMoodFollowUpProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Suggestion tailored to your {moodType} mood.'**
  String notifMoodFollowUpProfessionalV2Body(String moodType);

  /// No description provided for @notifMoodFollowUpDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Suggestion for your {moodType} mood'**
  String notifMoodFollowUpDirectV0Title(String moodType);

  /// No description provided for @notifMoodFollowUpDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to see what matches.'**
  String get notifMoodFollowUpDirectV0Body;

  /// No description provided for @notifMoodFollowUpDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Activity match'**
  String get notifMoodFollowUpDirectV1Title;

  /// No description provided for @notifMoodFollowUpDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Based on your {moodType} check-in.'**
  String notifMoodFollowUpDirectV1Body(String moodType);

  /// No description provided for @notifMoodFollowUpDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'{moodType} mood match ready'**
  String notifMoodFollowUpDirectV2Title(String moodType);

  /// No description provided for @notifMoodFollowUpDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to see.'**
  String get notifMoodFollowUpDirectV2Body;

  /// No description provided for @notifSocialEngagementEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Someone\'s vibing with your post 👀'**
  String get notifSocialEngagementEnergeticV0Title;

  /// No description provided for @notifSocialEngagementEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Go see who\'s feeling your adventure energy.'**
  String get notifSocialEngagementEnergeticV0Body;

  /// No description provided for @notifSocialEngagementEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Your mood post got attention!'**
  String get notifSocialEngagementEnergeticV1Title;

  /// No description provided for @notifSocialEngagementEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Someone reacted — Moody is curious what they thought.'**
  String get notifSocialEngagementEnergeticV1Body;

  /// No description provided for @notifSocialEngagementEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'People are talking about your adventure 🎉'**
  String get notifSocialEngagementEnergeticV2Title;

  /// No description provided for @notifSocialEngagementEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Your post got some love. Go check it out.'**
  String get notifSocialEngagementEnergeticV2Body;

  /// No description provided for @notifSocialEngagementFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Someone liked your post! 💛'**
  String get notifSocialEngagementFriendlyV0Title;

  /// No description provided for @notifSocialEngagementFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Your shared adventure resonated with someone.'**
  String get notifSocialEngagementFriendlyV0Body;

  /// No description provided for @notifSocialEngagementFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'New activity on your post'**
  String get notifSocialEngagementFriendlyV1Title;

  /// No description provided for @notifSocialEngagementFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Someone\'s engaging with your travel content.'**
  String get notifSocialEngagementFriendlyV1Body;

  /// No description provided for @notifSocialEngagementFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Your post got some love'**
  String get notifSocialEngagementFriendlyV2Title;

  /// No description provided for @notifSocialEngagementFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Check out who\'s reacting to your adventure.'**
  String get notifSocialEngagementFriendlyV2Body;

  /// No description provided for @notifSocialEngagementProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'New activity on your post'**
  String get notifSocialEngagementProfessionalV0Title;

  /// No description provided for @notifSocialEngagementProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Someone has reacted to your shared content.'**
  String get notifSocialEngagementProfessionalV0Body;

  /// No description provided for @notifSocialEngagementProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Post engagement'**
  String get notifSocialEngagementProfessionalV1Title;

  /// No description provided for @notifSocialEngagementProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'New interaction on your recent activity.'**
  String get notifSocialEngagementProfessionalV1Body;

  /// No description provided for @notifSocialEngagementProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Social notification'**
  String get notifSocialEngagementProfessionalV2Title;

  /// No description provided for @notifSocialEngagementProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Your post has new activity.'**
  String get notifSocialEngagementProfessionalV2Body;

  /// No description provided for @notifSocialEngagementDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'New like on your post'**
  String get notifSocialEngagementDirectV0Title;

  /// No description provided for @notifSocialEngagementDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to see.'**
  String get notifSocialEngagementDirectV0Body;

  /// No description provided for @notifSocialEngagementDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Post activity'**
  String get notifSocialEngagementDirectV1Title;

  /// No description provided for @notifSocialEngagementDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Someone reacted to your post.'**
  String get notifSocialEngagementDirectV1Body;

  /// No description provided for @notifSocialEngagementDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'New comment'**
  String get notifSocialEngagementDirectV2Title;

  /// No description provided for @notifSocialEngagementDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Your post has a new comment.'**
  String get notifSocialEngagementDirectV2Body;

  /// No description provided for @notifFriendActivityEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Your travel buddy is making moves 🗺️'**
  String get notifFriendActivityEnergeticV0Title;

  /// No description provided for @notifFriendActivityEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Someone in your network just did something worth knowing about.'**
  String get notifFriendActivityEnergeticV0Body;

  /// No description provided for @notifFriendActivityEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Plot twist: your crew is exploring'**
  String get notifFriendActivityEnergeticV1Title;

  /// No description provided for @notifFriendActivityEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'Don\'t get FOMO — check what your travel friends are up to.'**
  String get notifFriendActivityEnergeticV1Body;

  /// No description provided for @notifFriendActivityEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Network activity detected 👀'**
  String get notifFriendActivityEnergeticV2Title;

  /// No description provided for @notifFriendActivityEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'A friend just logged a mood or started a new plan. Curious?'**
  String get notifFriendActivityEnergeticV2Body;

  /// No description provided for @notifFriendActivityFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'A friend just shared their adventure 💛'**
  String get notifFriendActivityFriendlyV0Title;

  /// No description provided for @notifFriendActivityFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Someone you follow has new travel activity. Go check it out.'**
  String get notifFriendActivityFriendlyV0Body;

  /// No description provided for @notifFriendActivityFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Your travel buddy is on the move'**
  String get notifFriendActivityFriendlyV1Title;

  /// No description provided for @notifFriendActivityFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'One of your friends has something new to share.'**
  String get notifFriendActivityFriendlyV1Body;

  /// No description provided for @notifFriendActivityFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Friend activity'**
  String get notifFriendActivityFriendlyV2Title;

  /// No description provided for @notifFriendActivityFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Someone you follow just posted a mood or plan.'**
  String get notifFriendActivityFriendlyV2Body;

  /// No description provided for @notifFriendActivityProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Network activity'**
  String get notifFriendActivityProfessionalV0Title;

  /// No description provided for @notifFriendActivityProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Someone you follow has posted new travel content.'**
  String get notifFriendActivityProfessionalV0Body;

  /// No description provided for @notifFriendActivityProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Friend update'**
  String get notifFriendActivityProfessionalV1Title;

  /// No description provided for @notifFriendActivityProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Activity from your network is available.'**
  String get notifFriendActivityProfessionalV1Body;

  /// No description provided for @notifFriendActivityProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Connection activity'**
  String get notifFriendActivityProfessionalV2Title;

  /// No description provided for @notifFriendActivityProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Someone you follow has an update.'**
  String get notifFriendActivityProfessionalV2Body;

  /// No description provided for @notifFriendActivityDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Friend posted'**
  String get notifFriendActivityDirectV0Title;

  /// No description provided for @notifFriendActivityDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'New activity in your network.'**
  String get notifFriendActivityDirectV0Body;

  /// No description provided for @notifFriendActivityDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Travel buddy update'**
  String get notifFriendActivityDirectV1Title;

  /// No description provided for @notifFriendActivityDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Someone you follow has new content.'**
  String get notifFriendActivityDirectV1Body;

  /// No description provided for @notifFriendActivityDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Network update'**
  String get notifFriendActivityDirectV2Title;

  /// No description provided for @notifFriendActivityDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Friend activity available.'**
  String get notifFriendActivityDirectV2Body;

  /// No description provided for @notifWeekendPlanningNudgeEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'The weekend is almost here and you have zero plans'**
  String get notifWeekendPlanningNudgeEnergeticV0Title;

  /// No description provided for @notifWeekendPlanningNudgeEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Moody to the rescue. Tap to fix that immediately.'**
  String get notifWeekendPlanningNudgeEnergeticV0Body;

  /// No description provided for @notifWeekendPlanningNudgeEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Blank weekend detected 🎨'**
  String get notifWeekendPlanningNudgeEnergeticV1Title;

  /// No description provided for @notifWeekendPlanningNudgeEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'This is a creative emergency. Let Moody fill that canvas.'**
  String get notifWeekendPlanningNudgeEnergeticV1Body;

  /// No description provided for @notifWeekendPlanningNudgeEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Friday energy! Weekend plans?'**
  String get notifWeekendPlanningNudgeEnergeticV2Title;

  /// No description provided for @notifWeekendPlanningNudgeEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'Because \'see how it goes\' is not a Moody-approved strategy.'**
  String get notifWeekendPlanningNudgeEnergeticV2Body;

  /// No description provided for @notifWeekendPlanningNudgeFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'The weekend\'s coming up! Any plans? 🌟'**
  String get notifWeekendPlanningNudgeFriendlyV0Title;

  /// No description provided for @notifWeekendPlanningNudgeFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Let Moody help you plan something you\'ll actually love.'**
  String get notifWeekendPlanningNudgeFriendlyV0Body;

  /// No description provided for @notifWeekendPlanningNudgeFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Weekend planning time!'**
  String get notifWeekendPlanningNudgeFriendlyV1Title;

  /// No description provided for @notifWeekendPlanningNudgeFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'A few taps and Moody can put together a perfect weekend plan.'**
  String get notifWeekendPlanningNudgeFriendlyV1Body;

  /// No description provided for @notifWeekendPlanningNudgeFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Ready to plan your weekend?'**
  String get notifWeekendPlanningNudgeFriendlyV2Title;

  /// No description provided for @notifWeekendPlanningNudgeFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Moody\'s got ideas — want to see what fits your mood?'**
  String get notifWeekendPlanningNudgeFriendlyV2Body;

  /// No description provided for @notifWeekendPlanningNudgeProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Weekend planning'**
  String get notifWeekendPlanningNudgeProfessionalV0Title;

  /// No description provided for @notifWeekendPlanningNudgeProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Create a weekend itinerary tailored to your preferences.'**
  String get notifWeekendPlanningNudgeProfessionalV0Body;

  /// No description provided for @notifWeekendPlanningNudgeProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Plan your weekend'**
  String get notifWeekendPlanningNudgeProfessionalV1Title;

  /// No description provided for @notifWeekendPlanningNudgeProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'Weekend activities are available to schedule.'**
  String get notifWeekendPlanningNudgeProfessionalV1Body;

  /// No description provided for @notifWeekendPlanningNudgeProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Weekend ahead'**
  String get notifWeekendPlanningNudgeProfessionalV2Title;

  /// No description provided for @notifWeekendPlanningNudgeProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to plan your upcoming days.'**
  String get notifWeekendPlanningNudgeProfessionalV2Body;

  /// No description provided for @notifWeekendPlanningNudgeDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Plan your weekend'**
  String get notifWeekendPlanningNudgeDirectV0Title;

  /// No description provided for @notifWeekendPlanningNudgeDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'No plans yet. Tap to create some.'**
  String get notifWeekendPlanningNudgeDirectV0Body;

  /// No description provided for @notifWeekendPlanningNudgeDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Weekend scheduler'**
  String get notifWeekendPlanningNudgeDirectV1Title;

  /// No description provided for @notifWeekendPlanningNudgeDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Add plans for the upcoming weekend.'**
  String get notifWeekendPlanningNudgeDirectV1Body;

  /// No description provided for @notifWeekendPlanningNudgeDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'Weekend ahead'**
  String get notifWeekendPlanningNudgeDirectV2Title;

  /// No description provided for @notifWeekendPlanningNudgeDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to plan.'**
  String get notifWeekendPlanningNudgeDirectV2Body;

  /// No description provided for @notifTrendingInYourCityEnergeticV0Title.
  ///
  /// In en, this message translates to:
  /// **'Something is TRENDING near you right now 🔥'**
  String get notifTrendingInYourCityEnergeticV0Title;

  /// No description provided for @notifTrendingInYourCityEnergeticV0Body.
  ///
  /// In en, this message translates to:
  /// **'Everyone in your city is doing this and Moody can\'t keep quiet.'**
  String get notifTrendingInYourCityEnergeticV0Body;

  /// No description provided for @notifTrendingInYourCityEnergeticV1Title.
  ///
  /// In en, this message translates to:
  /// **'Hot take: this is blowing up in your area'**
  String get notifTrendingInYourCityEnergeticV1Title;

  /// No description provided for @notifTrendingInYourCityEnergeticV1Body.
  ///
  /// In en, this message translates to:
  /// **'You probably should know about this. Tap to see.'**
  String get notifTrendingInYourCityEnergeticV1Body;

  /// No description provided for @notifTrendingInYourCityEnergeticV2Title.
  ///
  /// In en, this message translates to:
  /// **'Trend alert in your city!'**
  String get notifTrendingInYourCityEnergeticV2Title;

  /// No description provided for @notifTrendingInYourCityEnergeticV2Body.
  ///
  /// In en, this message translates to:
  /// **'This is the moment. Are you going to be part of it?'**
  String get notifTrendingInYourCityEnergeticV2Body;

  /// No description provided for @notifTrendingInYourCityFriendlyV0Title.
  ///
  /// In en, this message translates to:
  /// **'Something popular is happening near you! 🌟'**
  String get notifTrendingInYourCityFriendlyV0Title;

  /// No description provided for @notifTrendingInYourCityFriendlyV0Body.
  ///
  /// In en, this message translates to:
  /// **'Moody spotted a trend in your area that fits your style.'**
  String get notifTrendingInYourCityFriendlyV0Body;

  /// No description provided for @notifTrendingInYourCityFriendlyV1Title.
  ///
  /// In en, this message translates to:
  /// **'Trending in your city'**
  String get notifTrendingInYourCityFriendlyV1Title;

  /// No description provided for @notifTrendingInYourCityFriendlyV1Body.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what everyone\'s been enjoying nearby this week.'**
  String get notifTrendingInYourCityFriendlyV1Body;

  /// No description provided for @notifTrendingInYourCityFriendlyV2Title.
  ///
  /// In en, this message translates to:
  /// **'Hot right now in your area'**
  String get notifTrendingInYourCityFriendlyV2Title;

  /// No description provided for @notifTrendingInYourCityFriendlyV2Body.
  ///
  /// In en, this message translates to:
  /// **'Check out what\'s trending and see if it\'s your thing.'**
  String get notifTrendingInYourCityFriendlyV2Body;

  /// No description provided for @notifTrendingInYourCityProfessionalV0Title.
  ///
  /// In en, this message translates to:
  /// **'Trending locally'**
  String get notifTrendingInYourCityProfessionalV0Title;

  /// No description provided for @notifTrendingInYourCityProfessionalV0Body.
  ///
  /// In en, this message translates to:
  /// **'Popular activity in your area matching your interests.'**
  String get notifTrendingInYourCityProfessionalV0Body;

  /// No description provided for @notifTrendingInYourCityProfessionalV1Title.
  ///
  /// In en, this message translates to:
  /// **'Local trend'**
  String get notifTrendingInYourCityProfessionalV1Title;

  /// No description provided for @notifTrendingInYourCityProfessionalV1Body.
  ///
  /// In en, this message translates to:
  /// **'What\'s popular nearby this week.'**
  String get notifTrendingInYourCityProfessionalV1Body;

  /// No description provided for @notifTrendingInYourCityProfessionalV2Title.
  ///
  /// In en, this message translates to:
  /// **'Popular nearby'**
  String get notifTrendingInYourCityProfessionalV2Title;

  /// No description provided for @notifTrendingInYourCityProfessionalV2Body.
  ///
  /// In en, this message translates to:
  /// **'Trending activity available in your area.'**
  String get notifTrendingInYourCityProfessionalV2Body;

  /// No description provided for @notifTrendingInYourCityDirectV0Title.
  ///
  /// In en, this message translates to:
  /// **'Trending near you'**
  String get notifTrendingInYourCityDirectV0Title;

  /// No description provided for @notifTrendingInYourCityDirectV0Body.
  ///
  /// In en, this message translates to:
  /// **'Check what\'s popular in your area.'**
  String get notifTrendingInYourCityDirectV0Body;

  /// No description provided for @notifTrendingInYourCityDirectV1Title.
  ///
  /// In en, this message translates to:
  /// **'Local hotspot'**
  String get notifTrendingInYourCityDirectV1Title;

  /// No description provided for @notifTrendingInYourCityDirectV1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap to see what\'s trending.'**
  String get notifTrendingInYourCityDirectV1Body;

  /// No description provided for @notifTrendingInYourCityDirectV2Title.
  ///
  /// In en, this message translates to:
  /// **'What\'s popular now'**
  String get notifTrendingInYourCityDirectV2Title;

  /// No description provided for @notifTrendingInYourCityDirectV2Body.
  ///
  /// In en, this message translates to:
  /// **'Trending activity near you.'**
  String get notifTrendingInYourCityDirectV2Body;

  /// No description provided for @commPrefChooseStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your Moody style'**
  String get commPrefChooseStyleTitle;

  /// No description provided for @commPrefChooseStyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'So I can match my tone perfectly to you.'**
  String get commPrefChooseStyleSubtitle;

  /// No description provided for @commPrefSpeechBubble.
  ///
  /// In en, this message translates to:
  /// **'How do you want me to talk to you? 😊'**
  String get commPrefSpeechBubble;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re in! Welcome 🎉'**
  String get authWelcomeTitle;

  /// No description provided for @authCallbackConfirmingEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirming your email…'**
  String get authCallbackConfirmingEmail;

  /// No description provided for @authCallbackVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Email verification failed. Please try again.'**
  String get authCallbackVerificationFailed;

  /// No description provided for @authRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get authRememberMe;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authSignInHeadline.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get authSignInHeadline;

  /// No description provided for @authLoginCta.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLoginCta;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get authOrContinueWith;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authNoAccount;

  /// No description provided for @authRegisterCta.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterCta;

  /// No description provided for @authReviewerHint.
  ///
  /// In en, this message translates to:
  /// **'App Store reviewer? Tap here'**
  String get authReviewerHint;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authPasswordRequired;

  /// No description provided for @authDemoSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Demo sign-in failed. Please try again.'**
  String get authDemoSignInFailed;

  /// No description provided for @authSignInCancelledOrFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled or failed. Please try again.'**
  String get authSignInCancelledOrFailed;

  /// No description provided for @authSignInFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get authSignInFailedGeneric;

  /// No description provided for @authSocialLoginNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Social login is not configured yet. Please use email/password for now.'**
  String get authSocialLoginNotConfigured;

  /// No description provided for @authSignInCancelledShort.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get authSignInCancelledShort;

  /// No description provided for @authNetworkErrorCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get authNetworkErrorCheckConnection;

  /// No description provided for @authGoogleSignInIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In setup is incomplete. Please use email/password for now.'**
  String get authGoogleSignInIncomplete;

  /// No description provided for @authFacebookSignInIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Facebook Sign-In setup is incomplete. Please use email/password for now.'**
  String get authFacebookSignInIncomplete;

  /// No description provided for @moodyChatMicrophoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is needed for voice input.'**
  String get moodyChatMicrophoneRequired;

  /// No description provided for @chatSheetMicrophoneOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get chatSheetMicrophoneOpenSettings;

  /// No description provided for @devAdminScreenDisabled.
  ///
  /// In en, this message translates to:
  /// **'Admin screen is disabled in production builds.'**
  String get devAdminScreenDisabled;

  /// No description provided for @moodStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood statistics'**
  String get moodStatsTitle;

  /// No description provided for @moodStatsAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average mood'**
  String get moodStatsAverageLabel;

  /// No description provided for @moodStatsTotalEntriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total entries'**
  String get moodStatsTotalEntriesLabel;

  /// No description provided for @moodStatsTypesLabel.
  ///
  /// In en, this message translates to:
  /// **'Mood types'**
  String get moodStatsTypesLabel;

  /// No description provided for @signupAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signupAlreadyHaveAccount;

  /// No description provided for @signupFormCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signupFormCreateAccount;

  /// No description provided for @signupFormJourneyLine.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you started on your journey!'**
  String get signupFormJourneyLine;

  /// No description provided for @signupFormFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get signupFormFullNameLabel;

  /// No description provided for @signupFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get signupFormNameRequired;

  /// No description provided for @signupFormPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters'**
  String signupFormPasswordMinLength(int min);

  /// No description provided for @signupFormConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get signupFormConfirmPasswordLabel;

  /// No description provided for @signupFormConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get signupFormConfirmPasswordRequired;

  /// No description provided for @signupFormPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signupFormPasswordsMismatch;

  /// No description provided for @signupFormAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'I accept the terms and conditions'**
  String get signupFormAcceptTerms;

  /// No description provided for @signupFormTermsNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions'**
  String get signupFormTermsNotAccepted;

  /// No description provided for @signupFormAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get signupFormAccountCreated;

  /// No description provided for @signupFormVerifyEmailToast.
  ///
  /// In en, this message translates to:
  /// **'Account created! Please check your email at {email} to verify your account.'**
  String signupFormVerifyEmailToast(String email);

  /// No description provided for @signupFormEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please sign in instead.'**
  String get signupFormEmailAlreadyRegistered;

  /// No description provided for @signupFormFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-up failed: {message}'**
  String signupFormFailed(String message);

  /// No description provided for @dialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// No description provided for @supportHowCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get supportHowCanWeHelp;

  /// No description provided for @supportContactUsCard.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get supportContactUsCard;

  /// No description provided for @supportSendFeedbackCard.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get supportSendFeedbackCard;

  /// No description provided for @supportTutorialCard.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get supportTutorialCard;

  /// No description provided for @supportReportIssueCard.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get supportReportIssueCard;

  /// No description provided for @supportFaqSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get supportFaqSectionTitle;

  /// No description provided for @supportFaq1Q.
  ///
  /// In en, this message translates to:
  /// **'How do I plan a new adventure?'**
  String get supportFaq1Q;

  /// No description provided for @supportFaq1A.
  ///
  /// In en, this message translates to:
  /// **'To plan a new adventure, go to the Explore tab and start a new plan. You can choose your mood, interests, and travel preferences to get personalized recommendations.'**
  String get supportFaq1A;

  /// No description provided for @supportFaq2Q.
  ///
  /// In en, this message translates to:
  /// **'Can I save places for later?'**
  String get supportFaq2Q;

  /// No description provided for @supportFaq2A.
  ///
  /// In en, this message translates to:
  /// **'Yes! When viewing a place, tap the heart icon to save it to your Saved Places, which you can access from your profile menu.'**
  String get supportFaq2A;

  /// No description provided for @supportFaq3Q.
  ///
  /// In en, this message translates to:
  /// **'How do I track my mood?'**
  String get supportFaq3Q;

  /// No description provided for @supportFaq3A.
  ///
  /// In en, this message translates to:
  /// **'WanderMood can remind you to track your mood. You can also add a mood entry from the Moody hub when you check in.'**
  String get supportFaq3A;

  /// No description provided for @supportFaq4Q.
  ///
  /// In en, this message translates to:
  /// **'What do the achievement badges mean?'**
  String get supportFaq4Q;

  /// No description provided for @supportFaq4A.
  ///
  /// In en, this message translates to:
  /// **'Badges are earned by completing activities in the app. Visit Achievements in your profile to see requirements for each badge.'**
  String get supportFaq4A;

  /// No description provided for @supportFaq5Q.
  ///
  /// In en, this message translates to:
  /// **'How does WanderMood use my location?'**
  String get supportFaq5Q;

  /// No description provided for @supportFaq5A.
  ///
  /// In en, this message translates to:
  /// **'WanderMood uses your location to suggest nearby places and activities. You can adjust location permissions in app settings.'**
  String get supportFaq5A;

  /// No description provided for @supportFaq6Q.
  ///
  /// In en, this message translates to:
  /// **'Can I use WanderMood offline?'**
  String get supportFaq6Q;

  /// No description provided for @supportFaq6A.
  ///
  /// In en, this message translates to:
  /// **'Some features need an internet connection. Saved places and items already on your device may still be viewable offline.'**
  String get supportFaq6A;

  /// No description provided for @supportAdditionalResources.
  ///
  /// In en, this message translates to:
  /// **'Additional Resources'**
  String get supportAdditionalResources;

  /// No description provided for @supportAppVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get supportAppVersionLabel;

  /// No description provided for @supportContactDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get supportContactDialogTitle;

  /// No description provided for @supportEmailUsAt.
  ///
  /// In en, this message translates to:
  /// **'Email us at:'**
  String get supportEmailUsAt;

  /// No description provided for @supportEmailSupportHours.
  ///
  /// In en, this message translates to:
  /// **'Our support team is available Monday–Friday, 9am–5pm PST.'**
  String get supportEmailSupportHours;

  /// No description provided for @supportToastOpeningFeedback.
  ///
  /// In en, this message translates to:
  /// **'Opening feedback form…'**
  String get supportToastOpeningFeedback;

  /// No description provided for @supportToastOpeningTutorial.
  ///
  /// In en, this message translates to:
  /// **'Opening app tutorial…'**
  String get supportToastOpeningTutorial;

  /// No description provided for @supportToastOpeningIssue.
  ///
  /// In en, this message translates to:
  /// **'Opening issue report…'**
  String get supportToastOpeningIssue;

  /// No description provided for @appTourStepMyDayBody.
  ///
  /// In en, this message translates to:
  /// **'Your plan is broken into moments—morning, afternoon, evening, and night. Choose your vibe, pick your favorites, and I\'ll handle the magic. 🧭🎯 All based on location, time, weather & mood.'**
  String get appTourStepMyDayBody;

  /// No description provided for @appTourStepExploreBody.
  ///
  /// In en, this message translates to:
  /// **'To plan a new adventure, go to the Explore tab and start a new plan. You can choose your mood, interests, and travel preferences to get personalized recommendations.'**
  String get appTourStepExploreBody;

  /// No description provided for @appTourStepMoodyBody.
  ///
  /// In en, this message translates to:
  /// **'Moody gets to know your vibe, your energy, and the kind of day you\'re having. With all that, I create personalized plans — made just for you. Think of me as your fun, curious bestie who\'s always down to explore 🌆🎈'**
  String get appTourStepMoodyBody;

  /// No description provided for @appTourStepAgendaBody.
  ///
  /// In en, this message translates to:
  /// **'See what\'s scheduled in My Plans — today, tomorrow, or any day — and jump back to Moody when a day is still wide open.'**
  String get appTourStepAgendaBody;

  /// No description provided for @appTourStepProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Saved places, travel mode, stats, and favorite vibes live here. Tap App settings for notifications, language, privacy, and help.'**
  String get appTourStepProfileBody;

  /// No description provided for @settingsAppTourLabel.
  ///
  /// In en, this message translates to:
  /// **'App tour'**
  String get settingsAppTourLabel;

  /// No description provided for @settingsAppTourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Walk through the bottom tabs again anytime'**
  String get settingsAppTourSubtitle;

  /// No description provided for @helpSupportAppTourTitle.
  ///
  /// In en, this message translates to:
  /// **'App tour'**
  String get helpSupportAppTourTitle;

  /// No description provided for @helpSupportAppTourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replay the interactive walkthrough of the main tabs'**
  String get helpSupportAppTourSubtitle;

  /// No description provided for @recListTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Recommendations'**
  String get recListTitle;

  /// No description provided for @recErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get recErrorPrefix;

  /// No description provided for @recTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get recTryAgain;

  /// No description provided for @recNoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'No recommendations available'**
  String get recNoneAvailable;

  /// No description provided for @recLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location: {location}'**
  String recLocationLabel(String location);

  /// No description provided for @recPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price: {price}'**
  String recPriceLabel(String price);

  /// No description provided for @recFavoriteUpdated.
  ///
  /// In en, this message translates to:
  /// **'Favorite updated successfully'**
  String get recFavoriteUpdated;

  /// No description provided for @recFavoriteError.
  ///
  /// In en, this message translates to:
  /// **'Error updating favorite: {error}'**
  String recFavoriteError(String error);

  /// No description provided for @recDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendation details'**
  String get recDetailTitle;

  /// No description provided for @recDetailMarkCompleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark as complete'**
  String get recDetailMarkCompleteTooltip;

  /// No description provided for @recDetailStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get recDetailStatusCompleted;

  /// No description provided for @recDetailStatusNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed yet'**
  String get recDetailStatusNotCompleted;

  /// No description provided for @recDetailSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get recDetailSectionDescription;

  /// No description provided for @recDetailSectionCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get recDetailSectionCategory;

  /// No description provided for @recDetailSectionTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get recDetailSectionTags;

  /// No description provided for @recDetailSectionConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get recDetailSectionConfidence;

  /// No description provided for @recDetailSectionMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get recDetailSectionMood;

  /// No description provided for @recDetailMoodRegisteredOn.
  ///
  /// In en, this message translates to:
  /// **'Logged on {date}'**
  String recDetailMoodRegisteredOn(String date);

  /// No description provided for @recDetailSectionWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get recDetailSectionWeather;

  /// No description provided for @recDetailWeatherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{temp}°C, {humidity}% humidity'**
  String recDetailWeatherSubtitle(String temp, String humidity);

  /// No description provided for @adventurePlanTitleYour.
  ///
  /// In en, this message translates to:
  /// **'Your '**
  String get adventurePlanTitleYour;

  /// No description provided for @adventurePlanTitleHighlight.
  ///
  /// In en, this message translates to:
  /// **'Adventure Plan'**
  String get adventurePlanTitleHighlight;

  /// No description provided for @adventurePlanTitleForToday.
  ///
  /// In en, this message translates to:
  /// **' for today'**
  String get adventurePlanTitleForToday;

  /// No description provided for @adventurePlanLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading adventures: {error}'**
  String adventurePlanLoadError(String error);

  /// No description provided for @adventurePlanDemoTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'32°'**
  String get adventurePlanDemoTemperatureLabel;

  /// No description provided for @adventurePlanDemoCityLabel.
  ///
  /// In en, this message translates to:
  /// **'Washington DC'**
  String get adventurePlanDemoCityLabel;

  /// No description provided for @trendingDetailNoRelatedPlaces.
  ///
  /// In en, this message translates to:
  /// **'No related places found'**
  String get trendingDetailNoRelatedPlaces;

  /// No description provided for @trendingDetailRelatedPlacesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load related places'**
  String get trendingDetailRelatedPlacesError;

  /// No description provided for @trendingDetailSimilarPlacesSection.
  ///
  /// In en, this message translates to:
  /// **'Similar places'**
  String get trendingDetailSimilarPlacesSection;

  /// No description provided for @trendingDetailLongDining.
  ///
  /// In en, this message translates to:
  /// **'Experience the culinary delights at {title}! Join locals and visitors as they savor amazing flavors and create memorable dining moments. Perfect for food lovers exploring the area. 🍽️✨'**
  String trendingDetailLongDining(String title);

  /// No description provided for @trendingDetailLongCulture.
  ///
  /// In en, this message translates to:
  /// **'Immerse yourself in the rich cultural heritage at {title}. Discover art, history, and creativity that defines the local landscape. A must-visit for anyone seeking inspiration and knowledge. 🎨🏛️'**
  String trendingDetailLongCulture(String title);

  /// No description provided for @trendingDetailLongOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Connect with nature and enjoy the fresh air at {title}. Whether you\'re looking for a peaceful walk or an active adventure, this outdoor destination offers the perfect escape. 🌳🚶‍♀️'**
  String trendingDetailLongOutdoor(String title);

  /// No description provided for @trendingDetailLongSightseeing.
  ///
  /// In en, this message translates to:
  /// **'Capture breathtaking views and iconic moments at {title}. This scenic spot offers some of the best photography opportunities and unforgettable vistas nearby. Don\'t forget your camera! 📸🌅'**
  String trendingDetailLongSightseeing(String title);

  /// No description provided for @trendingDetailLongShopping.
  ///
  /// In en, this message translates to:
  /// **'Discover unique finds and local treasures at {title}. From boutique stores to local markets, this shopping destination offers something special for every taste and budget. 🛍️💎'**
  String trendingDetailLongShopping(String title);

  /// No description provided for @trendingDetailLongFitness.
  ///
  /// In en, this message translates to:
  /// **'Stay active and energized at {title}. Whether you\'re maintaining your fitness routine or trying something new, this location provides excellent facilities for health and wellness. 💪🏃‍♀️'**
  String trendingDetailLongFitness(String title);

  /// No description provided for @trendingDetailLongDefault.
  ///
  /// In en, this message translates to:
  /// **'Join the trending excitement at {title}! This popular destination is capturing the attention of locals and visitors alike. Discover what makes this place special and create your own memorable experience. ⭐🎉'**
  String trendingDetailLongDefault(String title);

  /// No description provided for @receiptDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get receiptDownloadPdf;

  /// No description provided for @receiptShare.
  ///
  /// In en, this message translates to:
  /// **'Share Receipt'**
  String get receiptShare;

  /// No description provided for @placePhotoTapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get placePhotoTapToView;

  /// No description provided for @periodActivitiesRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove activity?'**
  String get periodActivitiesRemoveTitle;

  /// No description provided for @periodActivitiesRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{name}\"?'**
  String periodActivitiesRemoveBody(String name);

  /// No description provided for @periodActivitiesRemoveCta.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get periodActivitiesRemoveCta;

  /// No description provided for @periodActivitiesSwipeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get periodActivitiesSwipeDelete;

  /// No description provided for @periodActivitiesSwipeComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get periodActivitiesSwipeComplete;

  /// No description provided for @weatherFailedLoadCurrent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load weather'**
  String get weatherFailedLoadCurrent;

  /// No description provided for @weatherFailedLoadForecast.
  ///
  /// In en, this message translates to:
  /// **'Failed to load forecast'**
  String get weatherFailedLoadForecast;

  /// No description provided for @weatherDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherDetailTitle;

  /// No description provided for @weatherDetailLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get weatherDetailLoading;

  /// No description provided for @weatherDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load weather'**
  String get weatherDetailLoadError;

  /// No description provided for @weatherDetail24Hour.
  ///
  /// In en, this message translates to:
  /// **'24-hour outlook'**
  String get weatherDetail24Hour;

  /// No description provided for @weatherDetail3Day.
  ///
  /// In en, this message translates to:
  /// **'Next few days'**
  String get weatherDetail3Day;

  /// No description provided for @weatherDetailFeelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like {degrees}°'**
  String weatherDetailFeelsLike(int degrees);

  /// No description provided for @weatherMoodyTipTimeTonight.
  ///
  /// In en, this message translates to:
  /// **'Tonight'**
  String get weatherMoodyTipTimeTonight;

  /// No description provided for @weatherMoodyTipRainMorningBody.
  ///
  /// In en, this message translates to:
  /// **'Rain this morning — grab your umbrella before heading out.'**
  String get weatherMoodyTipRainMorningBody;

  /// No description provided for @weatherMoodyTipRainAfternoonBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s raining outside. A café or museum visit hits different on a day like this.'**
  String get weatherMoodyTipRainAfternoonBody;

  /// No description provided for @weatherMoodyTipRainEveningBody.
  ///
  /// In en, this message translates to:
  /// **'Rain tonight — the perfect excuse to find a cosy spot inside.'**
  String get weatherMoodyTipRainEveningBody;

  /// No description provided for @weatherMoodyTipRainNightBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s raining and dark out. Stay cosy — outdoor plans can wait till tomorrow.'**
  String get weatherMoodyTipRainNightBody;

  /// No description provided for @weatherMoodyTipSunnyHighUvMorningBody.
  ///
  /// In en, this message translates to:
  /// **'Great start! Apply sunscreen — UV builds fast once the sun is up.'**
  String get weatherMoodyTipSunnyHighUvMorningBody;

  /// No description provided for @weatherMoodyTipSunnyHighUvAfternoonBody.
  ///
  /// In en, this message translates to:
  /// **'UV is high right now. Find shade for a break and keep your water bottle close.'**
  String get weatherMoodyTipSunnyHighUvAfternoonBody;

  /// No description provided for @weatherMoodyTipSunnyHighUvEveningBody.
  ///
  /// In en, this message translates to:
  /// **'The sun is lower now — a perfect time for a walk or terrace visit.'**
  String get weatherMoodyTipSunnyHighUvEveningBody;

  /// No description provided for @weatherMoodyTipSunnyHighUvNightBody.
  ///
  /// In en, this message translates to:
  /// **'Clear skies tonight — a great evening for a stroll under the stars.'**
  String get weatherMoodyTipSunnyHighUvNightBody;

  /// No description provided for @weatherMoodyTipSunnyMildMorningBody.
  ///
  /// In en, this message translates to:
  /// **'Mild and dry — a great morning for a walk or breakfast outside.'**
  String get weatherMoodyTipSunnyMildMorningBody;

  /// No description provided for @weatherMoodyTipSunnyMildAfternoonBody.
  ///
  /// In en, this message translates to:
  /// **'Dry and comfortable out there. Terraces and parks are calling.'**
  String get weatherMoodyTipSunnyMildAfternoonBody;

  /// No description provided for @weatherMoodyTipSunnyMildEveningBody.
  ///
  /// In en, this message translates to:
  /// **'A lovely evening for a walk, a bite outside, or just some fresh air.'**
  String get weatherMoodyTipSunnyMildEveningBody;

  /// No description provided for @weatherMoodyTipSunnyMildNightBody.
  ///
  /// In en, this message translates to:
  /// **'Nice and calm out there. A quiet evening walk might be just what you need.'**
  String get weatherMoodyTipSunnyMildNightBody;

  /// No description provided for @weatherMoodyTipCloudyMorningBody.
  ///
  /// In en, this message translates to:
  /// **'Grey skies this morning — bring an extra layer and maybe a warm coffee.'**
  String get weatherMoodyTipCloudyMorningBody;

  /// No description provided for @weatherMoodyTipCloudyAfternoonBody.
  ///
  /// In en, this message translates to:
  /// **'Cloudy and a bit cool. Good day for indoor spots or a museum.'**
  String get weatherMoodyTipCloudyAfternoonBody;

  /// No description provided for @weatherMoodyTipCloudyEveningBody.
  ///
  /// In en, this message translates to:
  /// **'The clouds are in for the evening. A cosy dinner inside sounds perfect.'**
  String get weatherMoodyTipCloudyEveningBody;

  /// No description provided for @weatherMoodyTipCloudyNightBody.
  ///
  /// In en, this message translates to:
  /// **'Overcast and still. Wrap up if you\'re heading out — it feels cooler than it looks.'**
  String get weatherMoodyTipCloudyNightBody;

  /// No description provided for @weatherMoodyTipDefaultMorningBody.
  ///
  /// In en, this message translates to:
  /// **'Mixed conditions today — layer up so you\'re ready for anything.'**
  String get weatherMoodyTipDefaultMorningBody;

  /// No description provided for @weatherMoodyTipDefaultAfternoonBody.
  ///
  /// In en, this message translates to:
  /// **'Conditions may shift this afternoon. Keep an eye on the forecast.'**
  String get weatherMoodyTipDefaultAfternoonBody;

  /// No description provided for @weatherMoodyTipDefaultEveningBody.
  ///
  /// In en, this message translates to:
  /// **'The evening is here — check the latest forecast before heading out.'**
  String get weatherMoodyTipDefaultEveningBody;

  /// No description provided for @weatherMoodyTipDefaultNightBody.
  ///
  /// In en, this message translates to:
  /// **'Quiet outside for now. Check tomorrow\'s forecast in the morning.'**
  String get weatherMoodyTipDefaultNightBody;

  /// No description provided for @weatherNoDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No weather data available'**
  String get weatherNoDataAvailable;

  /// No description provided for @weatherShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get weatherShowMore;

  /// No description provided for @weatherShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get weatherShowLess;

  /// No description provided for @locationPickerSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get locationPickerSelectTitle;

  /// No description provided for @locationDropdownSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get locationDropdownSearchResults;

  /// No description provided for @locationDropdownPopularCities.
  ///
  /// In en, this message translates to:
  /// **'Popular cities'**
  String get locationDropdownPopularCities;

  /// No description provided for @locationDropdownNoCitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get locationDropdownNoCitiesFound;

  /// No description provided for @locationDropdownSearchCitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Search cities'**
  String get locationDropdownSearchCitiesTitle;

  /// No description provided for @locationDropdownUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get locationDropdownUseCurrentLocation;

  /// No description provided for @locationDropdownDetectExactLocation.
  ///
  /// In en, this message translates to:
  /// **'Detect your exact location'**
  String get locationDropdownDetectExactLocation;

  /// No description provided for @locationDropdownFindCitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find cities in {country}'**
  String locationDropdownFindCitiesSubtitle(String country);

  /// No description provided for @locationDropdownErrorLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Your city'**
  String get locationDropdownErrorLocationLabel;

  /// No description provided for @weatherLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading weather data: {error}'**
  String weatherLoadError(String error);

  /// No description provided for @weatherStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather statistics'**
  String get weatherStatsTitle;

  /// No description provided for @weatherHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather history'**
  String get weatherHistoryTitle;

  /// No description provided for @weatherToggleTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get weatherToggleTemperature;

  /// No description provided for @weatherToggleHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weatherToggleHumidity;

  /// No description provided for @weatherTogglePrecipitation.
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get weatherTogglePrecipitation;

  /// No description provided for @weatherForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get weatherForecastTitle;

  /// No description provided for @weatherNoForecasts.
  ///
  /// In en, this message translates to:
  /// **'No forecasts available'**
  String get weatherNoForecasts;

  /// No description provided for @weatherAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather alerts'**
  String get weatherAlertsTitle;

  /// No description provided for @weatherNoActiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts'**
  String get weatherNoActiveAlerts;

  /// No description provided for @myDayWeatherDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather in {city}'**
  String myDayWeatherDialogTitle(String city);

  /// No description provided for @myDayWeatherFeelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get myDayWeatherFeelsLike;

  /// No description provided for @myDayWeatherHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get myDayWeatherHumidity;

  /// No description provided for @myDayWeatherDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get myDayWeatherDescriptionLabel;

  /// No description provided for @myDayWeatherClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get myDayWeatherClose;

  /// No description provided for @myDayWeatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather data unavailable'**
  String get myDayWeatherUnavailable;

  /// No description provided for @myDayWeatherCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get myDayWeatherCheckConnection;

  /// No description provided for @myDayWeatherClearSkyFallback.
  ///
  /// In en, this message translates to:
  /// **'Clear skies'**
  String get myDayWeatherClearSkyFallback;

  /// No description provided for @weatherMainClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherMainClear;

  /// No description provided for @weatherMainClouds.
  ///
  /// In en, this message translates to:
  /// **'Clouds'**
  String get weatherMainClouds;

  /// No description provided for @weatherMainRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherMainRain;

  /// No description provided for @weatherMainDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherMainDrizzle;

  /// No description provided for @weatherMainThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherMainThunderstorm;

  /// No description provided for @weatherMainSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherMainSnow;

  /// No description provided for @weatherMainMist.
  ///
  /// In en, this message translates to:
  /// **'Mist'**
  String get weatherMainMist;

  /// No description provided for @weatherMainFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherMainFog;

  /// No description provided for @weatherMainHaze.
  ///
  /// In en, this message translates to:
  /// **'Slight haze'**
  String get weatherMainHaze;

  /// No description provided for @weatherMainHazeDescription.
  ///
  /// In en, this message translates to:
  /// **'Reduced visibility because the air is hazy'**
  String get weatherMainHazeDescription;

  /// No description provided for @weatherMainSmoke.
  ///
  /// In en, this message translates to:
  /// **'Smoke'**
  String get weatherMainSmoke;

  /// No description provided for @weatherMainDust.
  ///
  /// In en, this message translates to:
  /// **'Dust'**
  String get weatherMainDust;

  /// No description provided for @weatherMainSand.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get weatherMainSand;

  /// No description provided for @weatherMainAsh.
  ///
  /// In en, this message translates to:
  /// **'Ash'**
  String get weatherMainAsh;

  /// No description provided for @weatherMainSquall.
  ///
  /// In en, this message translates to:
  /// **'Squall'**
  String get weatherMainSquall;

  /// No description provided for @weatherMainTornado.
  ///
  /// In en, this message translates to:
  /// **'Tornado'**
  String get weatherMainTornado;

  /// No description provided for @weatherMainOther.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherMainOther;

  /// No description provided for @weatherHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No historical data available'**
  String get weatherHistoryEmpty;

  /// No description provided for @weatherHistoryInvalid.
  ///
  /// In en, this message translates to:
  /// **'No valid historical data available'**
  String get weatherHistoryInvalid;

  /// No description provided for @moodHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No mood history available'**
  String get moodHistoryEmpty;

  /// No description provided for @exploreLoadMoreIdeas.
  ///
  /// In en, this message translates to:
  /// **'Load more ideas'**
  String get exploreLoadMoreIdeas;

  /// No description provided for @agendaPaymentBadgeFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get agendaPaymentBadgeFree;

  /// No description provided for @agendaPaymentBadgePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get agendaPaymentBadgePaid;

  /// No description provided for @agendaPaymentBadgeReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get agendaPaymentBadgeReserved;

  /// No description provided for @agendaPaymentBadgePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get agendaPaymentBadgePending;

  /// No description provided for @agendaDurationShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String agendaDurationShort(String minutes);

  /// No description provided for @groupPlanWithFriendMenu.
  ///
  /// In en, this message translates to:
  /// **'Plan with a friend'**
  String get groupPlanWithFriendMenu;

  /// No description provided for @groupPlanTogetherTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan together'**
  String get groupPlanTogetherTitle;

  /// No description provided for @groupPlanHubBody.
  ///
  /// In en, this message translates to:
  /// **'Combine moods with a travel partner. Both of you use your own phone — share a short code or open it from a message.'**
  String get groupPlanHubBody;

  /// No description provided for @groupPlanTileStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a session'**
  String get groupPlanTileStartTitle;

  /// No description provided for @groupPlanTileStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You’ll get a code to send your friend'**
  String get groupPlanTileStartSubtitle;

  /// No description provided for @groupPlanTileJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with code'**
  String get groupPlanTileJoinTitle;

  /// No description provided for @groupPlanTileJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your friend'**
  String get groupPlanTileJoinSubtitle;

  /// No description provided for @groupPlanCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan with a friend'**
  String get groupPlanCreateTitle;

  /// No description provided for @groupPlanCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Create a shared session. You’ll get a short code to send your travel partner — they enter it on their phone.'**
  String get groupPlanCreateBody;

  /// No description provided for @groupPlanCreateOptionalTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional title (e.g. Today in Lisbon)'**
  String get groupPlanCreateOptionalTitleLabel;

  /// No description provided for @groupPlanCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create & share code'**
  String get groupPlanCreateButton;

  /// No description provided for @groupPlanShareSubject.
  ///
  /// In en, this message translates to:
  /// **'WanderMood group plan'**
  String get groupPlanShareSubject;

  /// No description provided for @groupPlanInviteShare.
  ///
  /// In en, this message translates to:
  /// **'Join my WanderMood day plan! Code: {code}\n(Open WanderMood → Plan with a friend → Enter code)'**
  String groupPlanInviteShare(String code);

  /// No description provided for @groupPlanJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a friend'**
  String get groupPlanJoinTitle;

  /// No description provided for @groupPlanJoinBody.
  ///
  /// In en, this message translates to:
  /// **'Scan your friend\'s QR code together, or enter their code below.'**
  String get groupPlanJoinBody;

  /// No description provided for @groupPlanJoinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Join code'**
  String get groupPlanJoinCodeLabel;

  /// No description provided for @groupPlanJoinCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. A1B2C3'**
  String get groupPlanJoinCodeHint;

  /// No description provided for @groupPlanJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Join session'**
  String get groupPlanJoinButton;

  /// No description provided for @groupPlanJoinSnackEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code your friend shared.'**
  String get groupPlanJoinSnackEnterCode;

  /// No description provided for @groupPlanJoinError.
  ///
  /// In en, this message translates to:
  /// **'Could not join: {error}'**
  String groupPlanJoinError(String error);

  /// No description provided for @groupPlanShareQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Show this to your friend'**
  String get groupPlanShareQrTitle;

  /// No description provided for @groupPlanShareQrOrCode.
  ///
  /// In en, this message translates to:
  /// **'or enter code {code}'**
  String groupPlanShareQrOrCode(String code);

  /// No description provided for @groupPlanShareViaMessage.
  ///
  /// In en, this message translates to:
  /// **'Share via message'**
  String get groupPlanShareViaMessage;

  /// No description provided for @groupPlanShareContinueLobby.
  ///
  /// In en, this message translates to:
  /// **'Continue to lobby'**
  String get groupPlanShareContinueLobby;

  /// No description provided for @groupPlanShareScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite your friend'**
  String get groupPlanShareScreenTitle;

  /// No description provided for @groupPlanJoinScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get groupPlanJoinScanQr;

  /// No description provided for @groupPlanJoinEnterInstead.
  ///
  /// In en, this message translates to:
  /// **'Enter code instead'**
  String get groupPlanJoinEnterInstead;

  /// No description provided for @groupPlanJoinScanInstead.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code instead'**
  String get groupPlanJoinScanInstead;

  /// No description provided for @groupPlanScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get groupPlanScanTitle;

  /// No description provided for @groupPlanCreateError.
  ///
  /// In en, this message translates to:
  /// **'Could not create session: {error}'**
  String groupPlanCreateError(String error);

  /// No description provided for @groupPlanLobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Group plan'**
  String get groupPlanLobbyTitle;

  /// No description provided for @groupPlanLobbyShareCode.
  ///
  /// In en, this message translates to:
  /// **'Share this code'**
  String get groupPlanLobbyShareCode;

  /// No description provided for @groupPlanLobbyMoodsProgress.
  ///
  /// In en, this message translates to:
  /// **'{locked} / {total} moods locked in'**
  String groupPlanLobbyMoodsProgress(int locked, int total);

  /// No description provided for @groupPlanLobbyWaitingFriend.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your friend to join…'**
  String get groupPlanLobbyWaitingFriend;

  /// No description provided for @groupPlanLobbyWhosIn.
  ///
  /// In en, this message translates to:
  /// **'Who’s in'**
  String get groupPlanLobbyWhosIn;

  /// No description provided for @groupPlanLobbyMoodLine.
  ///
  /// In en, this message translates to:
  /// **'Mood: {mood}'**
  String groupPlanLobbyMoodLine(String mood);

  /// No description provided for @groupPlanLobbyStillChoosing.
  ///
  /// In en, this message translates to:
  /// **'Still choosing…'**
  String get groupPlanLobbyStillChoosing;

  /// No description provided for @groupPlanLobbyYourMood.
  ///
  /// In en, this message translates to:
  /// **'Your mood today'**
  String get groupPlanLobbyYourMood;

  /// No description provided for @groupPlanLobbyLockMood.
  ///
  /// In en, this message translates to:
  /// **'Lock in my mood'**
  String get groupPlanLobbyLockMood;

  /// No description provided for @groupPlanLobbyBuilding.
  ///
  /// In en, this message translates to:
  /// **'Your shared plan is coming together.'**
  String get groupPlanLobbyBuilding;

  /// No description provided for @groupPlanLobbyPlanFailed.
  ///
  /// In en, this message translates to:
  /// **'Plan generation failed. Pull to refresh or try again in a moment.'**
  String get groupPlanLobbyPlanFailed;

  /// No description provided for @groupPlanLobbyPickMoodSnack.
  ///
  /// In en, this message translates to:
  /// **'Pick a mood first.'**
  String get groupPlanLobbyPickMoodSnack;

  /// No description provided for @groupPlanLobbySubmitError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String groupPlanLobbySubmitError(String error);

  /// No description provided for @groupPlanMoodAdventurous.
  ///
  /// In en, this message translates to:
  /// **'Adventurous'**
  String get groupPlanMoodAdventurous;

  /// No description provided for @groupPlanMoodRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get groupPlanMoodRelaxed;

  /// No description provided for @groupPlanMoodSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get groupPlanMoodSocial;

  /// No description provided for @groupPlanMoodCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get groupPlanMoodCultural;

  /// No description provided for @groupPlanMoodRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get groupPlanMoodRomantic;

  /// No description provided for @groupPlanMoodEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get groupPlanMoodEnergetic;

  /// No description provided for @groupPlanMoodFoody.
  ///
  /// In en, this message translates to:
  /// **'Foody'**
  String get groupPlanMoodFoody;

  /// No description provided for @groupPlanMoodCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get groupPlanMoodCreative;

  /// No description provided for @groupPlanResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shared plan'**
  String get groupPlanResultTitle;

  /// No description provided for @groupPlanResultNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No plan found yet.'**
  String get groupPlanResultNoPlan;

  /// No description provided for @groupPlanResultBackToApp.
  ///
  /// In en, this message translates to:
  /// **'Back to app'**
  String get groupPlanResultBackToApp;

  /// No description provided for @groupPlanResultMoodsLine.
  ///
  /// In en, this message translates to:
  /// **'Moods: {moods}'**
  String groupPlanResultMoodsLine(String moods);

  /// No description provided for @groupPlanResultIdeasTitle.
  ///
  /// In en, this message translates to:
  /// **'Ideas for today'**
  String get groupPlanResultIdeasTitle;

  /// No description provided for @groupPlanResultAddHint.
  ///
  /// In en, this message translates to:
  /// **'Adds use the date selected on My Day (defaults to today). Open My Day first if you want another day.'**
  String get groupPlanResultAddHint;

  /// No description provided for @groupPlanResultAddToMyDay.
  ///
  /// In en, this message translates to:
  /// **'Add to My Day'**
  String get groupPlanResultAddToMyDay;

  /// No description provided for @groupPlanResultAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get groupPlanResultAdded;

  /// No description provided for @groupPlanResultFooter.
  ///
  /// In en, this message translates to:
  /// **'Each person adds stops to their own My Day. Same plan, two calendars.'**
  String get groupPlanResultFooter;

  /// No description provided for @groupPlanResultAddedToast.
  ///
  /// In en, this message translates to:
  /// **'Added \"{name}\" to My Day'**
  String groupPlanResultAddedToast(String name);

  /// No description provided for @groupPlanResultDuplicateToast.
  ///
  /// In en, this message translates to:
  /// **'Could not add (duplicate or same time slot). Try another idea.'**
  String get groupPlanResultDuplicateToast;

  /// No description provided for @groupPlanResultAddFailedToast.
  ///
  /// In en, this message translates to:
  /// **'Add failed: {error}'**
  String groupPlanResultAddFailedToast(String error);

  /// No description provided for @groupPlanResultViewMyDay.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get groupPlanResultViewMyDay;

  /// No description provided for @groupPlanInviteOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open in the app: {url}'**
  String groupPlanInviteOpenLink(String url);

  /// No description provided for @groupPlanHubHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan with friends'**
  String get groupPlanHubHeroTitle;

  /// No description provided for @groupPlanHubHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Two moods, one shared day. Moody figures out what works for both.'**
  String get groupPlanHubHeroSubtitle;

  /// No description provided for @groupPlanHubStartCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a group plan'**
  String get groupPlanHubStartCardTitle;

  /// No description provided for @groupPlanHubStartCardSub.
  ///
  /// In en, this message translates to:
  /// **'Get a code to share with your friend'**
  String get groupPlanHubStartCardSub;

  /// No description provided for @groupPlanHubJoinCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a plan'**
  String get groupPlanHubJoinCardTitle;

  /// No description provided for @groupPlanHubJoinCardSub.
  ///
  /// In en, this message translates to:
  /// **'Enter a code from your friend'**
  String get groupPlanHubJoinCardSub;

  /// No description provided for @groupPlanHowItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get groupPlanHowItWorksTitle;

  /// No description provided for @groupPlanHowItWorksBody.
  ///
  /// In en, this message translates to:
  /// **'You each pick your mood independently. I\'ll blend them into one plan you both love.'**
  String get groupPlanHowItWorksBody;

  /// No description provided for @groupPlanCreateHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You + a friend'**
  String get groupPlanCreateHeaderSubtitle;

  /// No description provided for @groupPlanCreateHeaderCaption.
  ///
  /// In en, this message translates to:
  /// **'Pick your moods separately, get one shared plan'**
  String get groupPlanCreateHeaderCaption;

  /// No description provided for @groupPlanSessionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Session name (optional)'**
  String get groupPlanSessionNameLabel;

  /// No description provided for @groupPlanSessionNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekend in Amsterdam'**
  String get groupPlanSessionNamePlaceholder;

  /// No description provided for @groupPlanCreateCta.
  ///
  /// In en, this message translates to:
  /// **'Create & share link'**
  String get groupPlanCreateCta;

  /// No description provided for @groupPlanCreateShareHint.
  ///
  /// In en, this message translates to:
  /// **'Next you will see a QR code to show in person, or you can share a link by message.'**
  String get groupPlanCreateShareHint;

  /// No description provided for @groupPlanLobbyTitleWaitingFriend.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your friend…'**
  String get groupPlanLobbyTitleWaitingFriend;

  /// No description provided for @groupPlanLobbyTitleWaitingName.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}…'**
  String groupPlanLobbyTitleWaitingName(String name);

  /// No description provided for @groupPlanLobbyTitleEveryoneReady.
  ///
  /// In en, this message translates to:
  /// **'Everyone\'s ready!'**
  String get groupPlanLobbyTitleEveryoneReady;

  /// No description provided for @groupPlanLobbyShareCodeUpper.
  ///
  /// In en, this message translates to:
  /// **'Share this code'**
  String get groupPlanLobbyShareCodeUpper;

  /// No description provided for @groupPlanLobbyShareLinkCta.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get groupPlanLobbyShareLinkCta;

  /// No description provided for @groupPlanLobbyStatusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get groupPlanLobbyStatusLocked;

  /// No description provided for @groupPlanLobbyStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get groupPlanLobbyStatusWaiting;

  /// No description provided for @groupPlanMoodSectionUppercase.
  ///
  /// In en, this message translates to:
  /// **'Your mood today'**
  String get groupPlanMoodSectionUppercase;

  /// No description provided for @groupPlanLobbyLockCta.
  ///
  /// In en, this message translates to:
  /// **'Lock in my mood'**
  String get groupPlanLobbyLockCta;

  /// No description provided for @groupPlanLobbyWaitingLockIn.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to lock in…'**
  String groupPlanLobbyWaitingLockIn(String name);

  /// No description provided for @groupPlanLobbyGenerateCta.
  ///
  /// In en, this message translates to:
  /// **'Generate our plan'**
  String get groupPlanLobbyGenerateCta;

  /// No description provided for @groupPlanLobbyLockingIn.
  ///
  /// In en, this message translates to:
  /// **'🔒 Locking in…'**
  String get groupPlanLobbyLockingIn;

  /// No description provided for @groupPlanLobbyWaitingFriendJoin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your friend to join…'**
  String get groupPlanLobbyWaitingFriendJoin;

  /// No description provided for @groupPlanResultBlendKicker.
  ///
  /// In en, this message translates to:
  /// **'Moody blended your moods ✨'**
  String get groupPlanResultBlendKicker;

  /// No description provided for @groupPlanResultIdeasTitleEmoji.
  ///
  /// In en, this message translates to:
  /// **'Ideas for today 💡'**
  String get groupPlanResultIdeasTitleEmoji;

  /// No description provided for @groupPlanResultLoadingMoody.
  ///
  /// In en, this message translates to:
  /// **'Moody is building your plan… ✨'**
  String get groupPlanResultLoadingMoody;

  /// No description provided for @groupPlanResultFooterPhones.
  ///
  /// In en, this message translates to:
  /// **'Each of you adds what you want to your own My Day — two phones, same plan 📱📱'**
  String get groupPlanResultFooterPhones;

  /// No description provided for @groupPlanResultMoodChipYou.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {mood} (you)'**
  String groupPlanResultMoodChipYou(String emoji, String mood);

  /// No description provided for @groupPlanResultMoodChipName.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {mood} ({name})'**
  String groupPlanResultMoodChipName(String emoji, String mood, String name);

  /// No description provided for @groupPlanYouShort.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get groupPlanYouShort;

  /// No description provided for @groupPlanMoodCozy.
  ///
  /// In en, this message translates to:
  /// **'Cozy'**
  String get groupPlanMoodCozy;

  /// No description provided for @groupPlanMoodSurprise.
  ///
  /// In en, this message translates to:
  /// **'Surprise'**
  String get groupPlanMoodSurprise;

  /// No description provided for @moodMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood Match'**
  String get moodMatchTitle;

  /// No description provided for @moodMatchNotificationTapAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'This plan is already saved — here’s your summary.'**
  String get moodMatchNotificationTapAlreadySaved;

  /// No description provided for @moodMatchNotificationTapSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'This Mood Match is no longer available.'**
  String get moodMatchNotificationTapSessionEnded;

  /// No description provided for @moodMatchNotificationTapOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t open that plan.'**
  String get moodMatchNotificationTapOpenFailed;

  /// No description provided for @moodMatchNotificationTapStaleUpdate.
  ///
  /// In en, this message translates to:
  /// **'Nothing new to do here — that plan may have changed.'**
  String get moodMatchNotificationTapStaleUpdate;

  /// No description provided for @moodMatchTagline.
  ///
  /// In en, this message translates to:
  /// **'Two moods. One perfect day.'**
  String get moodMatchTagline;

  /// No description provided for @moodMatchTaglineHub.
  ///
  /// In en, this message translates to:
  /// **'Two moods. One perfect day. Built for both of you.'**
  String get moodMatchTaglineHub;

  /// No description provided for @moodMatchHubMoodyHeroLine1.
  ///
  /// In en, this message translates to:
  /// **'Two private mood picks, one shared day—built for both of you.'**
  String get moodMatchHubMoodyHeroLine1;

  /// No description provided for @moodMatchHubMoodyHeroLine2.
  ///
  /// In en, this message translates to:
  /// **'Tap Start or Join when you’re ready.'**
  String get moodMatchHubMoodyHeroLine2;

  /// No description provided for @moodMatchHubCardBodyPickYourMood.
  ///
  /// In en, this message translates to:
  /// **'I still need your mood — I’ll keep it hush-hush until you’re both locked.'**
  String get moodMatchHubCardBodyPickYourMood;

  /// No description provided for @moodMatchHubCardBodyDayTheirPick.
  ///
  /// In en, this message translates to:
  /// **'{name} floated a day — pop in and say yes or nudge a tweak.'**
  String moodMatchHubCardBodyDayTheirPick(String name);

  /// No description provided for @moodMatchHubCardBodyDayWaitingOnThem.
  ///
  /// In en, this message translates to:
  /// **'I sent a day their way — waiting on {name} to tap yes or counter.'**
  String moodMatchHubCardBodyDayWaitingOnThem(String name);

  /// No description provided for @moodMatchHubCardCtaReviewDay.
  ///
  /// In en, this message translates to:
  /// **'Review day'**
  String get moodMatchHubCardCtaReviewDay;

  /// No description provided for @moodMatchHubCardCtaCheckProgress.
  ///
  /// In en, this message translates to:
  /// **'Check progress'**
  String get moodMatchHubCardCtaCheckProgress;

  /// No description provided for @moodMatchStartBtn.
  ///
  /// In en, this message translates to:
  /// **'Start a Mood Match'**
  String get moodMatchStartBtn;

  /// No description provided for @moodMatchStartBtnSub.
  ///
  /// In en, this message translates to:
  /// **'Invite someone, pick moods, get a shared plan'**
  String get moodMatchStartBtnSub;

  /// No description provided for @moodMatchJoinBtn.
  ///
  /// In en, this message translates to:
  /// **'Join a Mood Match'**
  String get moodMatchJoinBtn;

  /// No description provided for @moodMatchJoinBtnSub.
  ///
  /// In en, this message translates to:
  /// **'Enter a code or scan QR'**
  String get moodMatchJoinBtnSub;

  /// No description provided for @moodMatchHubMoodyIntroFriendly.
  ///
  /// In en, this message translates to:
  /// **'Okaaay, planning with someone else?\nThis is my favourite thing to do 😏'**
  String get moodMatchHubMoodyIntroFriendly;

  /// No description provided for @moodMatchHubMoodyIntroProfessional.
  ///
  /// In en, this message translates to:
  /// **'Mood Match aligns two private mood picks into one shared day plan—clear, fair, and built for both of you.'**
  String get moodMatchHubMoodyIntroProfessional;

  /// No description provided for @moodMatchHubMoodyIntroEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Planning a day together?! I’m SO here for this—let’s make it unforgettable.'**
  String get moodMatchHubMoodyIntroEnergetic;

  /// No description provided for @moodMatchHubMoodyIntroDirect.
  ///
  /// In en, this message translates to:
  /// **'You each pick a mood on your own phone. I\'ll turn that into one shared plan. Start or join when you’re ready.'**
  String get moodMatchHubMoodyIntroDirect;

  /// No description provided for @moodMatchHubMoodyIntroWaitingFriendly.
  ///
  /// In en, this message translates to:
  /// **'You’re already in a Mood Match—your friend still needs to join. Open the plan to jump back in, or send a gentle nudge.'**
  String get moodMatchHubMoodyIntroWaitingFriendly;

  /// No description provided for @moodMatchHubMoodyIntroWaitingProfessional.
  ///
  /// In en, this message translates to:
  /// **'You have an active Mood Match awaiting the other guest. Use Open plan to return to the lobby, or share a reminder.'**
  String get moodMatchHubMoodyIntroWaitingProfessional;

  /// No description provided for @moodMatchHubMoodyIntroWaitingEnergetic.
  ///
  /// In en, this message translates to:
  /// **'We’re this close—your friend still has to hop in! Open the plan to keep the vibe going, or nudge them (they’ll love it).'**
  String get moodMatchHubMoodyIntroWaitingEnergetic;

  /// No description provided for @moodMatchHubMoodyIntroWaitingDirect.
  ///
  /// In en, this message translates to:
  /// **'Session in progress; friend not in yet. Open plan to continue or nudge.'**
  String get moodMatchHubMoodyIntroWaitingDirect;

  /// No description provided for @moodMatchHubPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue your plan 👀'**
  String get moodMatchHubPendingTitle;

  /// No description provided for @moodMatchHubPendingStory.
  ///
  /// In en, this message translates to:
  /// **'Your friend still has to hop in.'**
  String get moodMatchHubPendingStory;

  /// No description provided for @moodMatchHubPendingCodeSmall.
  ///
  /// In en, this message translates to:
  /// **'Code {code}'**
  String moodMatchHubPendingCodeSmall(String code);

  /// No description provided for @moodMatchHubPendingCode.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String moodMatchHubPendingCode(String code);

  /// No description provided for @moodMatchHubPendingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your friend to join…'**
  String get moodMatchHubPendingWaiting;

  /// No description provided for @moodMatchHubPendingBuilding.
  ///
  /// In en, this message translates to:
  /// **'I\'m building your shared plan…'**
  String get moodMatchHubPendingBuilding;

  /// No description provided for @moodMatchHubPendingMoodsStory.
  ///
  /// In en, this message translates to:
  /// **'We\'re waiting for your match to lock in their mood.'**
  String get moodMatchHubPendingMoodsStory;

  /// No description provided for @moodMatchHubPendingResumeStory.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off — your day and shared plan are next.'**
  String get moodMatchHubPendingResumeStory;

  /// No description provided for @moodMatchHubContinueSession.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get moodMatchHubContinueSession;

  /// No description provided for @moodMatchHubCancelSession.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get moodMatchHubCancelSession;

  /// No description provided for @moodMatchHubReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Mood Match is ready!'**
  String get moodMatchHubReadyTitle;

  /// No description provided for @moodMatchHubReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your shared day’s ready — peek whenever you like.'**
  String get moodMatchHubReadySubtitle;

  /// No description provided for @moodMatchHubSeePlanCta.
  ///
  /// In en, this message translates to:
  /// **'See the plan'**
  String get moodMatchHubSeePlanCta;

  /// No description provided for @moodMatchHubCardBadgeReady.
  ///
  /// In en, this message translates to:
  /// **'Your plan is ready'**
  String get moodMatchHubCardBadgeReady;

  /// No description provided for @moodMatchHubCardBadgeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming plan'**
  String get moodMatchHubCardBadgeUpcoming;

  /// No description provided for @moodMatchHubCardBadgeWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}…'**
  String moodMatchHubCardBadgeWaitingFor(String name);

  /// No description provided for @moodMatchHubCardStartsToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s the day ✨'**
  String get moodMatchHubCardStartsToday;

  /// No description provided for @moodMatchHubCardStartsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Starts tomorrow ✨'**
  String get moodMatchHubCardStartsTomorrow;

  /// No description provided for @moodMatchHubCardStartsInDays.
  ///
  /// In en, this message translates to:
  /// **'Starts in {days} days ✨'**
  String moodMatchHubCardStartsInDays(int days);

  /// No description provided for @moodMatchHubCardYouAndPartner.
  ///
  /// In en, this message translates to:
  /// **'You + {name} 💕'**
  String moodMatchHubCardYouAndPartner(String name);

  /// No description provided for @moodMatchHubCardDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get moodMatchHubCardDateToday;

  /// No description provided for @moodMatchHubCardDateTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get moodMatchHubCardDateTomorrow;

  /// No description provided for @moodMatchHubCardWaitingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Plan is waiting to be completed…'**
  String get moodMatchHubCardWaitingHeadline;

  /// No description provided for @moodMatchHubCardInfoPickingMood.
  ///
  /// In en, this message translates to:
  /// **'Picking a mood…'**
  String get moodMatchHubCardInfoPickingMood;

  /// No description provided for @moodMatchHubCardInfoJoining.
  ///
  /// In en, this message translates to:
  /// **'Waiting to join…'**
  String get moodMatchHubCardInfoJoining;

  /// No description provided for @moodMatchHubCardInfoBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building your plan…'**
  String get moodMatchHubCardInfoBuilding;

  /// No description provided for @moodMatchHubCardInfoNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next: your day & plan'**
  String get moodMatchHubCardInfoNextStep;

  /// No description provided for @moodMatchHubStatusGenerating.
  ///
  /// In en, this message translates to:
  /// **'I’m stitching your shared day together—almost there ✨'**
  String get moodMatchHubStatusGenerating;

  /// No description provided for @moodMatchHubStatusNeedGuest.
  ///
  /// In en, this message translates to:
  /// **'Your match hasn’t joined yet—open the lobby or give them a gentle nudge.'**
  String get moodMatchHubStatusNeedGuest;

  /// No description provided for @moodMatchHubStatusNeedMood.
  ///
  /// In en, this message translates to:
  /// **'We’re one mood away—waiting on them to lock theirs in 👀'**
  String get moodMatchHubStatusNeedMood;

  /// No description provided for @moodMatchHubStatusNeedDay.
  ///
  /// In en, this message translates to:
  /// **'Both moods are in—pick your day next and I’ll finish the plan.'**
  String get moodMatchHubStatusNeedDay;

  /// No description provided for @moodMatchHubStatusPlanReady.
  ///
  /// In en, this message translates to:
  /// **'Your shared day is ready—tap through whenever you feel like it.'**
  String get moodMatchHubStatusPlanReady;

  /// No description provided for @moodMatchHubStatusPlanUpcoming.
  ///
  /// In en, this message translates to:
  /// **'You’re on for {when}—your plan’s warm and waiting.'**
  String moodMatchHubStatusPlanUpcoming(String when);

  /// No description provided for @moodMatchHubUntitledSession.
  ///
  /// In en, this message translates to:
  /// **'Mood Match'**
  String get moodMatchHubUntitledSession;

  /// No description provided for @moodMatchCreateAlreadyWaiting.
  ///
  /// In en, this message translates to:
  /// **'You already have a session waiting. Open it from the hub.'**
  String get moodMatchCreateAlreadyWaiting;

  /// No description provided for @moodMatchHubCancelError.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel: {error}'**
  String moodMatchHubCancelError(String error);

  /// No description provided for @moodMatchNewFeatureBadge.
  ///
  /// In en, this message translates to:
  /// **'New feature'**
  String get moodMatchNewFeatureBadge;

  /// No description provided for @moodMatchGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String moodMatchGoodMorning(String name);

  /// No description provided for @moodMatchHowItWorksOneLiner.
  ///
  /// In en, this message translates to:
  /// **'You each pick your mood privately; I\'ll blend them into one plan you both love.'**
  String get moodMatchHowItWorksOneLiner;

  /// No description provided for @moodMatchStepYourMood.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2 · Your mood'**
  String get moodMatchStepYourMood;

  /// No description provided for @moodMatchFeelQuestionMorning.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling this morning?'**
  String get moodMatchFeelQuestionMorning;

  /// No description provided for @moodMatchFeelQuestionAfternoon.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling this afternoon?'**
  String get moodMatchFeelQuestionAfternoon;

  /// No description provided for @moodMatchFeelQuestionEvening.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling this evening?'**
  String get moodMatchFeelQuestionEvening;

  /// No description provided for @moodMatchFeelQuestionLate.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling right now?'**
  String get moodMatchFeelQuestionLate;

  /// No description provided for @moodMatchPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'{name} won\'t see this until you both lock in'**
  String moodMatchPrivateHint(String name);

  /// No description provided for @moodMatchMoodyPickQuoteFriendly.
  ///
  /// In en, this message translates to:
  /// **'Pick whatever\'s real. I\'ll make it work for both of you.'**
  String get moodMatchMoodyPickQuoteFriendly;

  /// No description provided for @moodMatchMoodyPickQuoteProfessional.
  ///
  /// In en, this message translates to:
  /// **'Choose the mood that best reflects you today. I will reconcile both selections into one coherent plan.'**
  String get moodMatchMoodyPickQuoteProfessional;

  /// No description provided for @moodMatchMoodyPickQuoteEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Go with your gut—bold, soft, whatever! I’ll turn both picks into something you’ll both love.'**
  String get moodMatchMoodyPickQuoteEnergetic;

  /// No description provided for @moodMatchMoodyPickQuoteDirect.
  ///
  /// In en, this message translates to:
  /// **'Select your mood. Your friend won’t see it until you both lock in.'**
  String get moodMatchMoodyPickQuoteDirect;

  /// No description provided for @moodMatchSelectMoodButton.
  ///
  /// In en, this message translates to:
  /// **'Select your mood'**
  String get moodMatchSelectMoodButton;

  /// No description provided for @moodMatchLockBtn.
  ///
  /// In en, this message translates to:
  /// **'Lock in {mood}'**
  String moodMatchLockBtn(String mood);

  /// No description provided for @moodMatchLobbyEveryoneReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Everyone\'s ready! 🎉'**
  String get moodMatchLobbyEveryoneReadyTitle;

  /// No description provided for @moodMatchLobbyEveryoneReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blending both vibes into your shared plan…'**
  String get moodMatchLobbyEveryoneReadySubtitle;

  /// No description provided for @moodMatchLobbyWaitingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hang tight — your match is almost ready.'**
  String get moodMatchLobbyWaitingSubtitle;

  /// No description provided for @moodMatchLobbyBuildingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finding places that fit both of you…'**
  String get moodMatchLobbyBuildingSubtitle;

  /// No description provided for @moodMatchLobbyCommentaryWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to figure out their vibe… 👀'**
  String moodMatchLobbyCommentaryWaiting(String name);

  /// No description provided for @moodMatchLobbyCommentaryFriendLocked.
  ///
  /// In en, this message translates to:
  /// **'{name} locked in! I\'m ready whenever you are 🎯'**
  String moodMatchLobbyCommentaryFriendLocked(String name);

  /// No description provided for @moodMatchLobbyCommentaryBothLocked.
  ///
  /// In en, this message translates to:
  /// **'Got both vibes. Building your match…'**
  String get moodMatchLobbyCommentaryBothLocked;

  /// No description provided for @moodMatchWhileYouWaitHint.
  ///
  /// In en, this message translates to:
  /// **'Moody will reveal your compatibility score when {name} locks in'**
  String moodMatchWhileYouWaitHint(String name);

  /// No description provided for @moodMatchRevealScore.
  ///
  /// In en, this message translates to:
  /// **'Vibe match today'**
  String get moodMatchRevealScore;

  /// No description provided for @moodMatchRevealCta.
  ///
  /// In en, this message translates to:
  /// **'See our plan'**
  String get moodMatchRevealCta;

  /// No description provided for @moodMatchRevealCopyHighFriendly.
  ///
  /// In en, this message translates to:
  /// **'You\'re basically the same person today 😌 \nThis plan built itself.'**
  String get moodMatchRevealCopyHighFriendly;

  /// No description provided for @moodMatchRevealCopyHighProfessional.
  ///
  /// In en, this message translates to:
  /// **'Your mood inputs align closely. The shared itinerary follows logically from both selections.'**
  String get moodMatchRevealCopyHighProfessional;

  /// No description provided for @moodMatchRevealCopyHighEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Twin vibe energy today! 🔥 This plan basically assembled itself—you\'re going to love it.'**
  String get moodMatchRevealCopyHighEnergetic;

  /// No description provided for @moodMatchRevealCopyHighDirect.
  ///
  /// In en, this message translates to:
  /// **'Very similar moods. The plan reflects both of you with minimal compromise.'**
  String get moodMatchRevealCopyHighDirect;

  /// No description provided for @moodMatchRevealCopyGoodFriendly.
  ///
  /// In en, this message translates to:
  /// **'Different vibes, but I made it work. \nTrust me on this one.'**
  String get moodMatchRevealCopyGoodFriendly;

  /// No description provided for @moodMatchRevealCopyGoodProfessional.
  ///
  /// In en, this message translates to:
  /// **'You chose different moods; I balanced both in one practical shared itinerary.'**
  String get moodMatchRevealCopyGoodProfessional;

  /// No description provided for @moodMatchRevealCopyGoodEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Different moods? I turned that into a win—this lineup still feels exciting for both of you!'**
  String get moodMatchRevealCopyGoodEnergetic;

  /// No description provided for @moodMatchRevealCopyGoodDirect.
  ///
  /// In en, this message translates to:
  /// **'Moods differed; the itinerary bridges both. Review the stops together.'**
  String get moodMatchRevealCopyGoodDirect;

  /// No description provided for @moodMatchRevealCopyCreativeFriendly.
  ///
  /// In en, this message translates to:
  /// **'Okay this was a challenge. But I actually love \nwhat I found. You will too.'**
  String get moodMatchRevealCopyCreativeFriendly;

  /// No description provided for @moodMatchRevealCopyCreativeProfessional.
  ///
  /// In en, this message translates to:
  /// **'Your moods diverged more than usual; I prioritized overlap you can both enjoy today.'**
  String get moodMatchRevealCopyCreativeProfessional;

  /// No description provided for @moodMatchRevealCopyCreativeEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Spicy combo on paper—but I found gems that still feel fun together. Let\'s go!'**
  String get moodMatchRevealCopyCreativeEnergetic;

  /// No description provided for @moodMatchRevealCopyCreativeDirect.
  ///
  /// In en, this message translates to:
  /// **'Low overlap between moods. The plan emphasizes neutral, crowd-pleasing picks.'**
  String get moodMatchRevealCopyCreativeDirect;

  /// No description provided for @moodMatchScoreLabelPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect match ✨'**
  String get moodMatchScoreLabelPerfect;

  /// No description provided for @moodMatchScoreLabelGreat.
  ///
  /// In en, this message translates to:
  /// **'Great combo'**
  String get moodMatchScoreLabelGreat;

  /// No description provided for @moodMatchScoreLabelGoodBalance.
  ///
  /// In en, this message translates to:
  /// **'Good balance'**
  String get moodMatchScoreLabelGoodBalance;

  /// No description provided for @moodMatchScoreLabelInteresting.
  ///
  /// In en, this message translates to:
  /// **'Interesting mix'**
  String get moodMatchScoreLabelInteresting;

  /// No description provided for @moodMatchScoreLabelCreative.
  ///
  /// In en, this message translates to:
  /// **'Moody got creative'**
  String get moodMatchScoreLabelCreative;

  /// No description provided for @moodMatchRevealMoodyFallback.
  ///
  /// In en, this message translates to:
  /// **'Your {moodA} and {moodB} sides are a surprisingly good team — I\'m into it.'**
  String moodMatchRevealMoodyFallback(String moodA, String moodB);

  /// No description provided for @moodMatchResultCompatLine.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match · {label}'**
  String moodMatchResultCompatLine(int percent, String label);

  /// No description provided for @moodMatchResultCompatGreat.
  ///
  /// In en, this message translates to:
  /// **'Great combo ✓'**
  String get moodMatchResultCompatGreat;

  /// No description provided for @moodMatchResultFooterStrip.
  ///
  /// In en, this message translates to:
  /// **'You each add what you want to your own My Day'**
  String get moodMatchResultFooterStrip;

  /// No description provided for @moodMatchLobbyChoosingBadge.
  ///
  /// In en, this message translates to:
  /// **'Choosing'**
  String get moodMatchLobbyChoosingBadge;

  /// No description provided for @moodMatchLobbyReadyBadge.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get moodMatchLobbyReadyBadge;

  /// No description provided for @moodMatchSeePlanShareA11y.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get moodMatchSeePlanShareA11y;

  /// No description provided for @moodMatchMoodTileSublabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose'**
  String get moodMatchMoodTileSublabel;

  /// No description provided for @moodMatchBlendChip.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {label}'**
  String moodMatchBlendChip(String emoji, String label);

  /// No description provided for @moodMatchWithFriendMenu.
  ///
  /// In en, this message translates to:
  /// **'Mood Match'**
  String get moodMatchWithFriendMenu;

  /// No description provided for @moodMatchInviteShare.
  ///
  /// In en, this message translates to:
  /// **'Join my Mood Match on WanderMood! Code: {code}'**
  String moodMatchInviteShare(String code);

  /// No description provided for @moodMatchShareMoodyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Nice—your match probably has WanderMood already 💚 Tap Invite on WanderMood first and I will help you find them 👀 Link & QR are tucked below if you need them 📎✨'**
  String get moodMatchShareMoodyPrompt;

  /// No description provided for @moodMatchShareFriendCodeIntro.
  ///
  /// In en, this message translates to:
  /// **'Your match only needs this code if they open WanderMood without the link—it is for their phone, not yours.'**
  String get moodMatchShareFriendCodeIntro;

  /// No description provided for @moodMatchShareLinkQrFoldTitle.
  ///
  /// In en, this message translates to:
  /// **'Need a link or QR instead?'**
  String get moodMatchShareLinkQrFoldTitle;

  /// No description provided for @moodMatchShareLinkQrFoldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For other chats, or if they are not on WanderMood yet.'**
  String get moodMatchShareLinkQrFoldSubtitle;

  /// No description provided for @moodMatchShareBottomHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: notifications can alert you when they join. You can go to the lobby anytime.'**
  String get moodMatchShareBottomHint;

  /// No description provided for @moodMatchPartnerJoinedNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} joined'**
  String moodMatchPartnerJoinedNotifTitle(String name);

  /// No description provided for @moodMatchPartnerJoinedNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Open your Mood Match lobby to keep going.'**
  String get moodMatchPartnerJoinedNotifBody;

  /// No description provided for @moodMatchPartnerJoinedNotifNameFallback.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get moodMatchPartnerJoinedNotifNameFallback;

  /// No description provided for @moodMatchInviteWanderMoodCta.
  ///
  /// In en, this message translates to:
  /// **'Invite on WanderMood'**
  String get moodMatchInviteWanderMoodCta;

  /// No description provided for @moodMatchInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a WanderMood friend'**
  String get moodMatchInviteTitle;

  /// No description provided for @moodMatchInviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send your join link first — it works in any chat. Search a username here to nudge someone already on WanderMood (optional).'**
  String get moodMatchInviteSubtitle;

  /// No description provided for @moodMatchInviteJoinLinkCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your join link'**
  String get moodMatchInviteJoinLinkCardTitle;

  /// No description provided for @moodMatchInviteJoinLinkCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy this https link and send it. It stays reliable if an in-app ping can’t be delivered.'**
  String get moodMatchInviteJoinLinkCardSubtitle;

  /// No description provided for @moodMatchInviteCopyLinkAction.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get moodMatchInviteCopyLinkAction;

  /// No description provided for @moodMatchInviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Join link copied'**
  String get moodMatchInviteLinkCopied;

  /// No description provided for @moodMatchInviteSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get moodMatchInviteSearchHint;

  /// No description provided for @moodMatchInviteSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters'**
  String get moodMatchInviteSearchEmpty;

  /// No description provided for @moodMatchInviteNoResults.
  ///
  /// In en, this message translates to:
  /// **'No profiles match that search'**
  String get moodMatchInviteNoResults;

  /// No description provided for @moodMatchInviteButton.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get moodMatchInviteButton;

  /// No description provided for @moodMatchInviteSent.
  ///
  /// In en, this message translates to:
  /// **'In-app invite sent'**
  String get moodMatchInviteSent;

  /// No description provided for @moodMatchInviteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t send the in-app invite (server). Copy your join link and send it in any chat—that always works.'**
  String get moodMatchInviteFailed;

  /// No description provided for @moodMatchInviteNotDeliveredInApp.
  ///
  /// In en, this message translates to:
  /// **'No in-app ping delivered — they may have in-app notifications off. Send your join link instead.'**
  String get moodMatchInviteNotDeliveredInApp;

  /// No description provided for @moodMatchInviteNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood Match invite'**
  String get moodMatchInviteNotifTitle;

  /// No description provided for @moodMatchInviteNotifMessage.
  ///
  /// In en, this message translates to:
  /// **'{inviter} invited you to Mood Match.\nCode: {code}\n{link}'**
  String moodMatchInviteNotifMessage(String inviter, String code, String link);

  /// No description provided for @moodMatchInviteInboxTag.
  ///
  /// In en, this message translates to:
  /// **'New Mood Match invite'**
  String get moodMatchInviteInboxTag;

  /// No description provided for @moodMatchInviteInboxBody.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a Mood Match. Pick your vibe (it stays yours until you’re both in), then we’ll line things up.'**
  String moodMatchInviteInboxBody(String name);

  /// No description provided for @moodMatchInviteInboxJoin.
  ///
  /// In en, this message translates to:
  /// **'Join Mood Match'**
  String get moodMatchInviteInboxJoin;

  /// No description provided for @moodMatchInviteInboxJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining…'**
  String get moodMatchInviteInboxJoining;

  /// No description provided for @moodMatchInviteInboxDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get moodMatchInviteInboxDismiss;

  /// No description provided for @moodMatchInviteInboxJoinError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t join right now. Try again in a moment.'**
  String get moodMatchInviteInboxJoinError;

  /// No description provided for @moodMatchInvitedWaitingTag.
  ///
  /// In en, this message translates to:
  /// **'INVITE SENT'**
  String get moodMatchInvitedWaitingTag;

  /// No description provided for @moodMatchInvitedWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to open the app and join.'**
  String moodMatchInvitedWaitingBody(String name);

  /// No description provided for @moodMatchInvitedWaitingNudge.
  ///
  /// In en, this message translates to:
  /// **'Nudge again'**
  String get moodMatchInvitedWaitingNudge;

  /// No description provided for @moodMatchShareShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get moodMatchShareShareLink;

  /// No description provided for @moodMatchShareCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get moodMatchShareCopyLink;

  /// No description provided for @moodMatchShareWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get moodMatchShareWhatsApp;

  /// No description provided for @moodMatchShareCopiedToast.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get moodMatchShareCopiedToast;

  /// No description provided for @moodMatchFriendThey.
  ///
  /// In en, this message translates to:
  /// **'your friend'**
  String get moodMatchFriendThey;

  /// No description provided for @moodMatchHubOpenPlan.
  ///
  /// In en, this message translates to:
  /// **'Open plan'**
  String get moodMatchHubOpenPlan;

  /// No description provided for @moodMatchHubNudgeFriend.
  ///
  /// In en, this message translates to:
  /// **'Nudge friend'**
  String get moodMatchHubNudgeFriend;

  /// No description provided for @moodMatchHubOngoingTitle.
  ///
  /// In en, this message translates to:
  /// **'Ongoing matches'**
  String get moodMatchHubOngoingTitle;

  /// No description provided for @moodMatchHubActiveMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Active matches'**
  String get moodMatchHubActiveMatchesTitle;

  /// No description provided for @moodMatchHubCompletedMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Added to My Day'**
  String get moodMatchHubCompletedMatchesTitle;

  /// No description provided for @moodMatchHubPlanDraftingBadge.
  ///
  /// In en, this message translates to:
  /// **'Finishing your picks'**
  String get moodMatchHubPlanDraftingBadge;

  /// No description provided for @moodMatchHubPlanDraftingBody.
  ///
  /// In en, this message translates to:
  /// **'Lock the stops you want, then send them to {name} to review.'**
  String moodMatchHubPlanDraftingBody(String name);

  /// No description provided for @moodMatchHubOwnerWaitingGuestReviewBody.
  ///
  /// In en, this message translates to:
  /// **'You shared the plan — waiting on {name} to review and confirm their picks.'**
  String moodMatchHubOwnerWaitingGuestReviewBody(String name);

  /// No description provided for @moodMatchHubGuestReviewBadge.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get moodMatchHubGuestReviewBadge;

  /// No description provided for @moodMatchHubGuestReviewBody.
  ///
  /// In en, this message translates to:
  /// **'{name} sent the shared plan — tap in to review your picks.'**
  String moodMatchHubGuestReviewBody(String name);

  /// No description provided for @moodMatchHubCtaReviewPlan.
  ///
  /// In en, this message translates to:
  /// **'Review plan'**
  String get moodMatchHubCtaReviewPlan;

  /// No description provided for @moodMatchHubCompletedBadge.
  ///
  /// In en, this message translates to:
  /// **'On your day'**
  String get moodMatchHubCompletedBadge;

  /// No description provided for @moodMatchHubCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'This blend is already on your calendar.'**
  String get moodMatchHubCompletedBody;

  /// No description provided for @moodMatchHubCompletedCta.
  ///
  /// In en, this message translates to:
  /// **'Open My Day'**
  String get moodMatchHubCompletedCta;

  /// No description provided for @moodMatchHubTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get moodMatchHubTabActive;

  /// No description provided for @moodMatchHubTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get moodMatchHubTabCompleted;

  /// No description provided for @moodMatchHubTabActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Mood matches still being processed.'**
  String get moodMatchHubTabActiveHint;

  /// No description provided for @moodMatchHubTabCompletedHint.
  ///
  /// In en, this message translates to:
  /// **'Plans you’ve added to My Day.'**
  String get moodMatchHubTabCompletedHint;

  /// No description provided for @moodMatchHubTabActiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active matches here — start one or join a friend’s code.'**
  String get moodMatchHubTabActiveEmpty;

  /// No description provided for @moodMatchHubTabCompletedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet — when you tap Add to My Day on a finished plan, it shows up here.'**
  String get moodMatchHubTabCompletedEmpty;

  /// No description provided for @moodMatchHubInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'PENDING INVITES'**
  String get moodMatchHubInvitesTitle;

  /// No description provided for @moodMatchHubInvitesCollapsedHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 invite waiting — tap to open} other{{count} invites waiting — tap to open}}'**
  String moodMatchHubInvitesCollapsedHint(int count);

  /// No description provided for @moodMatchHubConfirmDismissInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this invite?'**
  String get moodMatchHubConfirmDismissInviteTitle;

  /// No description provided for @moodMatchHubConfirmDismissInviteBody.
  ///
  /// In en, this message translates to:
  /// **'You can still join later with the join code if your friend shares it again.'**
  String get moodMatchHubConfirmDismissInviteBody;

  /// No description provided for @moodMatchHubConfirmLeaveSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this Mood Match?'**
  String get moodMatchHubConfirmLeaveSessionTitle;

  /// No description provided for @moodMatchHubConfirmLeaveSessionBodyGuest.
  ///
  /// In en, this message translates to:
  /// **'You\'ll leave this Mood Match. We\'ll let your friend know.'**
  String get moodMatchHubConfirmLeaveSessionBodyGuest;

  /// No description provided for @moodMatchHubConfirmLeaveSessionBodyHost.
  ///
  /// In en, this message translates to:
  /// **'This removes the Mood Match for both of you. Your friend will be notified.'**
  String get moodMatchHubConfirmLeaveSessionBodyHost;

  /// No description provided for @moodMatchHubConfirmRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get moodMatchHubConfirmRemoveAction;

  /// No description provided for @moodMatchHubLeaveSuccessGuestToast.
  ///
  /// In en, this message translates to:
  /// **'You left the Mood Match. We let your friend know.'**
  String get moodMatchHubLeaveSuccessGuestToast;

  /// No description provided for @moodMatchHubLeaveSuccessHostToast.
  ///
  /// In en, this message translates to:
  /// **'Mood Match removed. We let your friend know.'**
  String get moodMatchHubLeaveSuccessHostToast;

  /// No description provided for @moodMatchLobbyWaitTease0.
  ///
  /// In en, this message translates to:
  /// **'Waiting on {name}… no pressure 👀'**
  String moodMatchLobbyWaitTease0(String name);

  /// No description provided for @moodMatchLobbyWaitTease1.
  ///
  /// In en, this message translates to:
  /// **'Still nothing from {name}… typical 😭'**
  String moodMatchLobbyWaitTease1(String name);

  /// No description provided for @moodMatchLobbyWaitTease2.
  ///
  /// In en, this message translates to:
  /// **'I have a whole plan ready. Just saying. 🌀'**
  String get moodMatchLobbyWaitTease2;

  /// No description provided for @moodMatchLobbyWaitTease3.
  ///
  /// In en, this message translates to:
  /// **'{name} is taking their time… worth it though, trust me'**
  String moodMatchLobbyWaitTease3(String name);

  /// No description provided for @moodMatchLobbyFriendJoinedLine.
  ///
  /// In en, this message translates to:
  /// **'{name} just joined! 🎯 Now pick your mood.'**
  String moodMatchLobbyFriendJoinedLine(String name);

  /// No description provided for @moodMatchLobbyBothLockedHold.
  ///
  /// In en, this message translates to:
  /// **'Got both vibes. Give me a second… 🤔'**
  String get moodMatchLobbyBothLockedHold;

  /// No description provided for @moodMatchLockInVibeTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock in your vibe'**
  String get moodMatchLockInVibeTitle;

  /// No description provided for @moodMatchLockInVibeBtn.
  ///
  /// In en, this message translates to:
  /// **'Lock my mood'**
  String get moodMatchLockInVibeBtn;

  /// No description provided for @moodMatchChangeMind.
  ///
  /// In en, this message translates to:
  /// **'Change my mind'**
  String get moodMatchChangeMind;

  /// No description provided for @moodMatchPrivacyNoteLockIn.
  ///
  /// In en, this message translates to:
  /// **'Your mood is only shared once {name} locks in too.'**
  String moodMatchPrivacyNoteLockIn(String name);

  /// No description provided for @moodMatchMoodyReactionCurious.
  ///
  /// In en, this message translates to:
  /// **'Ooh, curious energy! I like where this is going...'**
  String get moodMatchMoodyReactionCurious;

  /// No description provided for @moodMatchMoodyReactionRomantic.
  ///
  /// In en, this message translates to:
  /// **'Love is in the air... *fans self*'**
  String get moodMatchMoodyReactionRomantic;

  /// No description provided for @moodMatchMoodyReactionFoody.
  ///
  /// In en, this message translates to:
  /// **'Oh! Someone\'s hungry. I\'ll find you something delicious.'**
  String get moodMatchMoodyReactionFoody;

  /// No description provided for @moodMatchMoodyReactionRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Deep breath. We\'re finding you something chill.'**
  String get moodMatchMoodyReactionRelaxed;

  /// No description provided for @moodMatchMoodyReactionEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Let\'s GO! High energy incoming... 🔥'**
  String get moodMatchMoodyReactionEnergetic;

  /// No description provided for @moodMatchMoodyReactionCozy.
  ///
  /// In en, this message translates to:
  /// **'Warm vibes detected. Bringing the comfort...'**
  String get moodMatchMoodyReactionCozy;

  /// No description provided for @moodMatchMoodyReactionAdventurous.
  ///
  /// In en, this message translates to:
  /// **'Adventure mode: activated! Hold on tight...'**
  String get moodMatchMoodyReactionAdventurous;

  /// No description provided for @moodMatchMoodyReactionCultural.
  ///
  /// In en, this message translates to:
  /// **'A taste for culture! I\'ve got just the thing.'**
  String get moodMatchMoodyReactionCultural;

  /// No description provided for @moodMatchMoodyReactionSocial.
  ///
  /// In en, this message translates to:
  /// **'Social butterfly! Let\'s find a buzzing spot.'**
  String get moodMatchMoodyReactionSocial;

  /// No description provided for @moodMatchMoodyReactionExcited.
  ///
  /// In en, this message translates to:
  /// **'The excitement is REAL. Let\'s make it happen!'**
  String get moodMatchMoodyReactionExcited;

  /// No description provided for @moodMatchMoodyReactionHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy vibes are the best vibes 😄'**
  String get moodMatchMoodyReactionHappy;

  /// No description provided for @moodMatchMoodyReactionSurprise.
  ///
  /// In en, this message translates to:
  /// **'A surprise mood! My favorite kind.'**
  String get moodMatchMoodyReactionSurprise;

  /// No description provided for @moodMatchStatusMoodLocked.
  ///
  /// In en, this message translates to:
  /// **'Mood locked ✓'**
  String get moodMatchStatusMoodLocked;

  /// No description provided for @moodMatchStatusPickingMood.
  ///
  /// In en, this message translates to:
  /// **'Picking a mood...'**
  String get moodMatchStatusPickingMood;

  /// No description provided for @moodMatchStatusLockedIn.
  ///
  /// In en, this message translates to:
  /// **'Locked in'**
  String get moodMatchStatusLockedIn;

  /// No description provided for @moodMatchBadgeLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked in'**
  String get moodMatchBadgeLocked;

  /// No description provided for @moodMatchLiveUpdateOpened.
  ///
  /// In en, this message translates to:
  /// **'{name} just opened the app'**
  String moodMatchLiveUpdateOpened(String name);

  /// No description provided for @moodMatchLiveUpdatePicking.
  ///
  /// In en, this message translates to:
  /// **'{name} is picking their mood...'**
  String moodMatchLiveUpdatePicking(String name);

  /// No description provided for @moodMatchLiveUpdateLocked.
  ///
  /// In en, this message translates to:
  /// **'{name} locked in their mood!'**
  String moodMatchLiveUpdateLocked(String name);

  /// No description provided for @moodMatchWaitingBothBetter.
  ///
  /// In en, this message translates to:
  /// **'Both moods in? Even better together.'**
  String get moodMatchWaitingBothBetter;

  /// No description provided for @moodMatchStepAlmostTag.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get moodMatchStepAlmostTag;

  /// No description provided for @moodMatchWaitingOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting on {name}'**
  String moodMatchWaitingOnTitle(String name);

  /// No description provided for @moodMatchWaitingOnSub.
  ///
  /// In en, this message translates to:
  /// **'{name} is still choosing — privately. When they lock in, you both move on together.'**
  String moodMatchWaitingOnSub(String name);

  /// No description provided for @moodMatchWaitingTeaserTag.
  ///
  /// In en, this message translates to:
  /// **'Locked in'**
  String get moodMatchWaitingTeaserTag;

  /// No description provided for @moodMatchWaitingTeaserTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} picked their vibe'**
  String moodMatchWaitingTeaserTitle(String name);

  /// No description provided for @moodMatchWaitingTeaserSub.
  ///
  /// In en, this message translates to:
  /// **'Shhh — the actual mood stays a secret till the reveal.'**
  String get moodMatchWaitingTeaserSub;

  /// No description provided for @moodMatchPlanBuildSub.
  ///
  /// In en, this message translates to:
  /// **'Usually just a few seconds.'**
  String get moodMatchPlanBuildSub;

  /// No description provided for @moodMatchMatchLoadingAppBar.
  ///
  /// In en, this message translates to:
  /// **'Hang on'**
  String get moodMatchMatchLoadingAppBar;

  /// No description provided for @moodMatchPlanBuildButton.
  ///
  /// In en, this message translates to:
  /// **'Building your plan…'**
  String get moodMatchPlanBuildButton;

  /// No description provided for @moodMatchWaitingPreviewHeadlineNamed.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s turn'**
  String moodMatchWaitingPreviewHeadlineNamed(String name);

  /// No description provided for @moodMatchWaitingPreviewHeadlineGeneric.
  ///
  /// In en, this message translates to:
  /// **'Your match\'s turn'**
  String get moodMatchWaitingPreviewHeadlineGeneric;

  /// No description provided for @moodMatchWaitingQuietHint.
  ///
  /// In en, this message translates to:
  /// **'Shared ideas will show here once you\'ve picked a day together.'**
  String get moodMatchWaitingQuietHint;

  /// No description provided for @moodMatchRemoveSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this Mood Match?'**
  String get moodMatchRemoveSessionTitle;

  /// No description provided for @moodMatchRemoveSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Your match will leave this session too. This can\'t be undone.'**
  String get moodMatchRemoveSessionBody;

  /// No description provided for @moodMatchRemoveSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get moodMatchRemoveSessionConfirm;

  /// No description provided for @moodMatchRemoveSessionCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get moodMatchRemoveSessionCancel;

  /// No description provided for @moodMatchOwnerWaitingConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting on {name} to confirm'**
  String moodMatchOwnerWaitingConfirmTitle(String name);

  /// No description provided for @moodMatchOwnerWaitingConfirmSub.
  ///
  /// In en, this message translates to:
  /// **'They\'ll get a ping to confirm the day + time you suggested. You\'ll both land back on your shared plan when it\'s set.'**
  String get moodMatchOwnerWaitingConfirmSub;

  /// No description provided for @moodMatchGuestConfirmTitleWithTime.
  ///
  /// In en, this message translates to:
  /// **'{day} · {time}'**
  String moodMatchGuestConfirmTitleWithTime(String day, String time);

  /// No description provided for @moodMatchGuestConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{name} picked {day} around {time}. Works for you?'**
  String moodMatchGuestConfirmBody(String name, String day, String time);

  /// No description provided for @moodMatchGuestCounterCta.
  ///
  /// In en, this message translates to:
  /// **'Suggest a different moment'**
  String get moodMatchGuestCounterCta;

  /// No description provided for @moodMatchGuestCounterTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a moment that works'**
  String get moodMatchGuestCounterTitle;

  /// No description provided for @moodMatchGuestCounterSub.
  ///
  /// In en, this message translates to:
  /// **'{name} can accept or suggest another moment before you both go back to your shared plan.'**
  String moodMatchGuestCounterSub(String name);

  /// No description provided for @moodMatchGuestCounterSendCta.
  ///
  /// In en, this message translates to:
  /// **'Send back'**
  String get moodMatchGuestCounterSendCta;

  /// No description provided for @moodMatchOwnerCounterTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} suggested {day} · {time}'**
  String moodMatchOwnerCounterTitle(String name, String day, String time);

  /// No description provided for @moodMatchOwnerCounterBody.
  ///
  /// In en, this message translates to:
  /// **'Your match suggested a different moment. Accept it, or propose another day and time.'**
  String get moodMatchOwnerCounterBody;

  /// No description provided for @moodMatchOwnerCounterAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept {day}'**
  String moodMatchOwnerCounterAccept(String day);

  /// No description provided for @moodMatchOwnerCounterKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep my pick'**
  String get moodMatchOwnerCounterKeep;

  /// No description provided for @moodMatchOwnerCounterSuggestAnother.
  ///
  /// In en, this message translates to:
  /// **'Suggest another time →'**
  String get moodMatchOwnerCounterSuggestAnother;

  /// No description provided for @moodMatchWaitingGuestReviewPlan.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to review…'**
  String moodMatchWaitingGuestReviewPlan(String name);

  /// No description provided for @moodMatchPlanSentToGuestBanner.
  ///
  /// In en, this message translates to:
  /// **'Sent to {name}'**
  String moodMatchPlanSentToGuestBanner(String name);

  /// No description provided for @moodMatchPlanV2SelectAllThreeToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select all 3 to continue'**
  String get moodMatchPlanV2SelectAllThreeToContinue;

  /// No description provided for @moodMatchSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get moodMatchSaving;

  /// No description provided for @moodMatchDayPickerStep.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2 — you decide'**
  String get moodMatchDayPickerStep;

  /// No description provided for @moodMatchDayPickerStepGuest.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2 — your match picks'**
  String get moodMatchDayPickerStepGuest;

  /// No description provided for @moodMatchDayPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Which day works for you both?'**
  String get moodMatchDayPickerTitle;

  /// No description provided for @moodMatchDayPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You choose — {name} gets to confirm.'**
  String moodMatchDayPickerSubtitle(String name);

  /// No description provided for @moodMatchDayPickerToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get moodMatchDayPickerToday;

  /// No description provided for @moodMatchDayPickerNote.
  ///
  /// In en, this message translates to:
  /// **'{name} will get a nudge to confirm.'**
  String moodMatchDayPickerNote(String name);

  /// No description provided for @moodMatchDayPickerPreview.
  ///
  /// In en, this message translates to:
  /// **'{ownerName} suggested {day}'**
  String moodMatchDayPickerPreview(String ownerName, String day);

  /// No description provided for @moodMatchDayPickerCta.
  ///
  /// In en, this message translates to:
  /// **'Continue — see your match →'**
  String get moodMatchDayPickerCta;

  /// No description provided for @moodMatchDayPickerOpenSheetCta.
  ///
  /// In en, this message translates to:
  /// **'Choose day & time'**
  String get moodMatchDayPickerOpenSheetCta;

  /// No description provided for @moodMatchDayPickerSheetChangeCta.
  ///
  /// In en, this message translates to:
  /// **'Change day or time'**
  String get moodMatchDayPickerSheetChangeCta;

  /// No description provided for @moodMatchDayPickerWholeDay.
  ///
  /// In en, this message translates to:
  /// **'Whole day'**
  String get moodMatchDayPickerWholeDay;

  /// No description provided for @moodMatchPlanResultMoodyV1.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your day with {name} — three picks we think fit both your vibes.'**
  String moodMatchPlanResultMoodyV1(String name);

  /// No description provided for @moodMatchPlanResultMoodyV2.
  ///
  /// In en, this message translates to:
  /// **'Built around what you both wanted today. Tap any spot to peek inside before you confirm with {name}.'**
  String moodMatchPlanResultMoodyV2(String name);

  /// No description provided for @moodMatchPlanResultMoodyV3.
  ///
  /// In en, this message translates to:
  /// **'Try them in order, or shuffle — your call. {name} sees the same plan from their side.'**
  String moodMatchPlanResultMoodyV3(String name);

  /// No description provided for @moodMatchPlanResultMoodyV4.
  ///
  /// In en, this message translates to:
  /// **'Three small moments shaped around your moods. Anything off? Hit Swap and we\'ll find another option.'**
  String moodMatchPlanResultMoodyV4(String name);

  /// No description provided for @moodMatchDayPickerSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a date for both of you'**
  String get moodMatchDayPickerSheetTitle;

  /// No description provided for @moodMatchDayPickerSheetMoodyLine.
  ///
  /// In en, this message translates to:
  /// **'No rush — {name} will confirm your pick.'**
  String moodMatchDayPickerSheetMoodyLine(String name);

  /// No description provided for @moodMatchDayPickerSheetDone.
  ///
  /// In en, this message translates to:
  /// **'Lock it in →'**
  String get moodMatchDayPickerSheetDone;

  /// No description provided for @moodMatchDayPickerTimeHint.
  ///
  /// In en, this message translates to:
  /// **'We’ll use this after your plan is ready. Your match still picks their own slot.'**
  String get moodMatchDayPickerTimeHint;

  /// No description provided for @moodMatchDayNotifyMaybeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t notify your match in time — ask them to open the app to confirm the day.'**
  String get moodMatchDayNotifyMaybeFailed;

  /// No description provided for @moodMatchGuestWaitingDay.
  ///
  /// In en, this message translates to:
  /// **'{name} is picking a day for you both...'**
  String moodMatchGuestWaitingDay(String name);

  /// No description provided for @moodMatchGuestConfirmDay.
  ///
  /// In en, this message translates to:
  /// **'Works for {day}?'**
  String moodMatchGuestConfirmDay(String day);

  /// No description provided for @moodMatchGuestConfirmYes.
  ///
  /// In en, this message translates to:
  /// **'Works for me ✓'**
  String get moodMatchGuestConfirmYes;

  /// No description provided for @moodMatchGuestConfirmNo.
  ///
  /// In en, this message translates to:
  /// **'Suggest another day'**
  String get moodMatchGuestConfirmNo;

  /// No description provided for @moodMatchTimePickerStep.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2 — just for you'**
  String get moodMatchTimePickerStep;

  /// No description provided for @moodMatchTimePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'When do YOU want to start?'**
  String get moodMatchTimePickerTitle;

  /// No description provided for @moodMatchTimePickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{day} · {name} picks their own slot too'**
  String moodMatchTimePickerSubtitle(String day, String name);

  /// No description provided for @moodMatchTimePickerMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get moodMatchTimePickerMorning;

  /// No description provided for @moodMatchTimePickerAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get moodMatchTimePickerAfternoon;

  /// No description provided for @moodMatchTimePickerEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get moodMatchTimePickerEvening;

  /// No description provided for @moodMatchTimePickerMorningNote.
  ///
  /// In en, this message translates to:
  /// **'Start fresh and beat the crowds.'**
  String get moodMatchTimePickerMorningNote;

  /// No description provided for @moodMatchTimePickerAfternoonNote.
  ///
  /// In en, this message translates to:
  /// **'Midday energy — perfect for most spots.'**
  String get moodMatchTimePickerAfternoonNote;

  /// No description provided for @moodMatchTimePickerEveningNote.
  ///
  /// In en, this message translates to:
  /// **'Golden hour vibes all the way.'**
  String get moodMatchTimePickerEveningNote;

  /// No description provided for @moodMatchTimePickerWithBadge.
  ///
  /// In en, this message translates to:
  /// **'You and {name} are planning this together'**
  String moodMatchTimePickerWithBadge(String name);

  /// No description provided for @moodMatchTimePickerCta.
  ///
  /// In en, this message translates to:
  /// **'Add to My Day'**
  String get moodMatchTimePickerCta;

  /// No description provided for @moodMatchTimePickerOtherNote.
  ///
  /// In en, this message translates to:
  /// **'{name} will pick their own slot separately'**
  String moodMatchTimePickerOtherNote(String name);

  /// No description provided for @moodMatchResultTag.
  ///
  /// In en, this message translates to:
  /// **'MATCH RESULT'**
  String get moodMatchResultTag;

  /// No description provided for @moodMatchResultCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get moodMatchResultCompatibility;

  /// No description provided for @moodMatchFriendYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get moodMatchFriendYou;

  /// No description provided for @moodMatchReactionLoveIt.
  ///
  /// In en, this message translates to:
  /// **'Love it'**
  String get moodMatchReactionLoveIt;

  /// No description provided for @moodMatchReactionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get moodMatchReactionSkip;

  /// No description provided for @moodMatchReactionSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get moodMatchReactionSwap;

  /// No description provided for @moodMatchConflictBadge.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get moodMatchConflictBadge;

  /// No description provided for @moodMatchConflictBanner.
  ///
  /// In en, this message translates to:
  /// **'{name} proposed {place} instead'**
  String moodMatchConflictBanner(String name, String place);

  /// No description provided for @moodMatchConflictKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep original'**
  String get moodMatchConflictKeep;

  /// No description provided for @moodMatchConflictAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept {name}\'s pick'**
  String moodMatchConflictAccept(String name);

  /// No description provided for @moodMatchPlanSortedCta.
  ///
  /// In en, this message translates to:
  /// **'Plan sorted → Choose start time'**
  String get moodMatchPlanSortedCta;

  /// No description provided for @moodMatchPlanHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'Start your morning here'**
  String get moodMatchPlanHeroLabel;

  /// No description provided for @moodMatchPlanMoreIdeas.
  ///
  /// In en, this message translates to:
  /// **'More ideas'**
  String get moodMatchPlanMoreIdeas;

  /// No description provided for @moodMatchPlanMoreIdeasCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more idea} other{{count} more ideas}}'**
  String moodMatchPlanMoreIdeasCount(int count);

  /// No description provided for @moodMatchPlanSwapHint.
  ///
  /// In en, this message translates to:
  /// **'Swapped picks come from your match\'s other ideas.'**
  String get moodMatchPlanSwapHint;

  /// No description provided for @moodMatchConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Added to your day'**
  String get moodMatchConfirmTitle;

  /// No description provided for @moodMatchConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{day} · {slot} start'**
  String moodMatchConfirmSubtitle(String day, String slot);

  /// No description provided for @moodMatchConfirmOtherNote.
  ///
  /// In en, this message translates to:
  /// **'{name} gets a nudge to pick their slot.'**
  String moodMatchConfirmOtherNote(String name);

  /// No description provided for @moodMatchConfirmOtherStatus.
  ///
  /// In en, this message translates to:
  /// **'{name} — Notified, picking their start time'**
  String moodMatchConfirmOtherStatus(String name);

  /// No description provided for @moodMatchConfirmViewMyDay.
  ///
  /// In en, this message translates to:
  /// **'View My Day'**
  String get moodMatchConfirmViewMyDay;

  /// No description provided for @moodMatchInMyDaySuccess.
  ///
  /// In en, this message translates to:
  /// **'Your plan for {date} is in My Day.'**
  String moodMatchInMyDaySuccess(String date);

  /// No description provided for @moodMatchInMyDaySuccessShort.
  ///
  /// In en, this message translates to:
  /// **'Your plan is in My Day.'**
  String get moodMatchInMyDaySuccessShort;

  /// No description provided for @moodMatchConfirmBackToPlan.
  ///
  /// In en, this message translates to:
  /// **'← Back to plan'**
  String get moodMatchConfirmBackToPlan;

  /// No description provided for @moodMatchWithBadge.
  ///
  /// In en, this message translates to:
  /// **'With {name}'**
  String moodMatchWithBadge(String name);

  /// No description provided for @moodMatchPlanV2GuestMoody.
  ///
  /// In en, this message translates to:
  /// **'{name} picked these for you both. Say what works.'**
  String moodMatchPlanV2GuestMoody(String name);

  /// No description provided for @moodMatchPlanV2ContextYouPickedDay.
  ///
  /// In en, this message translates to:
  /// **'📅 {day} · You picked the day'**
  String moodMatchPlanV2ContextYouPickedDay(String day);

  /// No description provided for @moodMatchPlanV2ContextOwnerPickedDay.
  ///
  /// In en, this message translates to:
  /// **'📅 {day} · {name} picked the day'**
  String moodMatchPlanV2ContextOwnerPickedDay(String day, String name);

  /// No description provided for @moodMatchPlanV2ContextPlannedDay.
  ///
  /// In en, this message translates to:
  /// **'📅 {day} · Planned day'**
  String moodMatchPlanV2ContextPlannedDay(String day);

  /// No description provided for @moodMatchPlanV2ImIn.
  ///
  /// In en, this message translates to:
  /// **'I\'m in ✓'**
  String get moodMatchPlanV2ImIn;

  /// No description provided for @moodMatchPlanV2SwapThis.
  ///
  /// In en, this message translates to:
  /// **'Swap this'**
  String get moodMatchPlanV2SwapThis;

  /// No description provided for @moodMatchPlanV2YouConfirmed.
  ///
  /// In en, this message translates to:
  /// **'You confirmed ✓'**
  String get moodMatchPlanV2YouConfirmed;

  /// No description provided for @moodMatchPlanV2WaitingForYou.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get moodMatchPlanV2WaitingForYou;

  /// No description provided for @moodMatchPlanV2ConfirmBeforeSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm or swap before sending'**
  String get moodMatchPlanV2ConfirmBeforeSend;

  /// No description provided for @moodMatchPlanV2ConfirmedByYou.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by you · {name} hasn\'t seen it yet'**
  String moodMatchPlanV2ConfirmedByYou(String name);

  /// No description provided for @moodMatchPlanV2SendToGuest.
  ///
  /// In en, this message translates to:
  /// **'Send to {name} →'**
  String moodMatchPlanV2SendToGuest(String name);

  /// No description provided for @moodMatchPlanV2ConfirmAllToSend.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Confirm your pick to send to {name}} other{Confirm all {count} spots to send to {name}}}'**
  String moodMatchPlanV2ConfirmAllToSend(int count, String name);

  /// No description provided for @moodMatchPlanV2GuestWaitingShare.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to share the plan'**
  String moodMatchPlanV2GuestWaitingShare(String name);

  /// No description provided for @moodMatchPlanV2WorksForMe.
  ///
  /// In en, this message translates to:
  /// **'Works for me ✓'**
  String get moodMatchPlanV2WorksForMe;

  /// No description provided for @moodMatchPlanV2NotForMe.
  ///
  /// In en, this message translates to:
  /// **'Not for me'**
  String get moodMatchPlanV2NotForMe;

  /// No description provided for @moodMatchPlanV2BothIn.
  ///
  /// In en, this message translates to:
  /// **'Both in ✓'**
  String get moodMatchPlanV2BothIn;

  /// No description provided for @moodMatchPlanV2YourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get moodMatchPlanV2YourTurn;

  /// No description provided for @moodMatchPlanV2SwapRequested.
  ///
  /// In en, this message translates to:
  /// **'Swap requested'**
  String get moodMatchPlanV2SwapRequested;

  /// No description provided for @moodMatchPlanV2OwnerInYourCall.
  ///
  /// In en, this message translates to:
  /// **'{name} is in · your call'**
  String moodMatchPlanV2OwnerInYourCall(String name);

  /// No description provided for @moodMatchPlanV2YouBothIn.
  ///
  /// In en, this message translates to:
  /// **'You and {name} are both in'**
  String moodMatchPlanV2YouBothIn(String name);

  /// No description provided for @moodMatchPlanV2SlotNotInThisPlan.
  ///
  /// In en, this message translates to:
  /// **'{partLabel} isn\'t in this Mood Match — you only planned one part of the day together.'**
  String moodMatchPlanV2SlotNotInThisPlan(String partLabel);

  /// No description provided for @moodMatchPlanV2YouBothInThisMoment.
  ///
  /// In en, this message translates to:
  /// **'You\'re both in for this moment ✓'**
  String get moodMatchPlanV2YouBothInThisMoment;

  /// No description provided for @moodMatchPlanV2WaitingOwnerSwap.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} on the swap…'**
  String moodMatchPlanV2WaitingOwnerSwap(String name);

  /// No description provided for @moodMatchPlanV2ConfirmAllGuest.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Confirm your pick to finish} other{Confirm all {count} picks to finish}}'**
  String moodMatchPlanV2ConfirmAllGuest(int count);

  /// No description provided for @moodMatchPlanV2StopsReviewed.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String moodMatchPlanV2StopsReviewed(int done, int total);

  /// No description provided for @moodMatchPlanV2FooterGuestReviewNudge.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} · confirm each tab above'**
  String moodMatchPlanV2FooterGuestReviewNudge(int done, int total);

  /// No description provided for @moodMatchPlanV2OwnerPickEachPart.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} selected — pick the rest above'**
  String moodMatchPlanV2OwnerPickEachPart(int done, int total);

  /// No description provided for @moodMatchPlanV2UndoMyChoice.
  ///
  /// In en, this message translates to:
  /// **'Change my answer'**
  String get moodMatchPlanV2UndoMyChoice;

  /// No description provided for @moodMatchPlanV2PlanConfirmedTime.
  ///
  /// In en, this message translates to:
  /// **'Plan confirmed — pick your start time →'**
  String get moodMatchPlanV2PlanConfirmedTime;

  /// No description provided for @moodMatchPlanV2OpenMyDay.
  ///
  /// In en, this message translates to:
  /// **'Add to My Plans ✓'**
  String get moodMatchPlanV2OpenMyDay;

  /// No description provided for @moodMatchRevealMaeMorning.
  ///
  /// In en, this message translates to:
  /// **'MORNING'**
  String get moodMatchRevealMaeMorning;

  /// No description provided for @moodMatchRevealMaeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'AFTERNOON'**
  String get moodMatchRevealMaeAfternoon;

  /// No description provided for @moodMatchRevealMaeEvening.
  ///
  /// In en, this message translates to:
  /// **'EVENING'**
  String get moodMatchRevealMaeEvening;

  /// No description provided for @moodMatchPlanV2SwapSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick something else for {slot}'**
  String moodMatchPlanV2SwapSheetTitle(String slot);

  /// No description provided for @moodMatchPlanV2SwapSheetMoody.
  ///
  /// In en, this message translates to:
  /// **'Here are some other options to try.'**
  String get moodMatchPlanV2SwapSheetMoody;

  /// No description provided for @moodMatchPlanV2PickThis.
  ///
  /// In en, this message translates to:
  /// **'Pick this'**
  String get moodMatchPlanV2PickThis;

  /// No description provided for @moodMatchPlanV2YourPickSaved.
  ///
  /// In en, this message translates to:
  /// **'Your pick'**
  String get moodMatchPlanV2YourPickSaved;

  /// No description provided for @moodMatchPlanV2SwapBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to swap the {slot}'**
  String moodMatchPlanV2SwapBannerTitle(String name, String slot);

  /// No description provided for @moodMatchPlanV2SwapBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'They suggested {proposed} instead of {original}'**
  String moodMatchPlanV2SwapBannerSubtitle(String proposed, String original);

  /// No description provided for @moodMatchPlanV2KeepOriginal.
  ///
  /// In en, this message translates to:
  /// **'Keep {name}'**
  String moodMatchPlanV2KeepOriginal(String name);

  /// No description provided for @moodMatchPlanV2AcceptSwap.
  ///
  /// In en, this message translates to:
  /// **'Accept {name}'**
  String moodMatchPlanV2AcceptSwap(String name);

  /// No description provided for @moodMatchPlanV2SentToGuest.
  ///
  /// In en, this message translates to:
  /// **'Plan sent to {name}'**
  String moodMatchPlanV2SentToGuest(String name);

  /// No description provided for @moodMatchPlanV2GuestSuggestedSwap.
  ///
  /// In en, this message translates to:
  /// **'{name} suggested: {proposed} instead'**
  String moodMatchPlanV2GuestSuggestedSwap(String name, String proposed);

  /// No description provided for @moodMatchPlanV2ActuallyKeep.
  ///
  /// In en, this message translates to:
  /// **'Actually keep it'**
  String get moodMatchPlanV2ActuallyKeep;

  /// No description provided for @moodMatchPlanV2WaitingForOwnerEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}…'**
  String moodMatchPlanV2WaitingForOwnerEllipsis(String name);

  /// No description provided for @moodMatchPlanV2WaitingGuestApproveSwap.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to OK your suggestion for this slot.'**
  String moodMatchPlanV2WaitingGuestApproveSwap(String name);

  /// No description provided for @moodMatchPlanV2OwnerSuggestedDifferentPlace.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to swap this for {proposed}.'**
  String moodMatchPlanV2OwnerSuggestedDifferentPlace(
      String name, String proposed);

  /// No description provided for @moodMatchPlanV2UseOwnersPick.
  ///
  /// In en, this message translates to:
  /// **'Use their pick'**
  String get moodMatchPlanV2UseOwnersPick;

  /// No description provided for @moodMatchPlanV2KeepCurrentPlace.
  ///
  /// In en, this message translates to:
  /// **'Keep this place'**
  String get moodMatchPlanV2KeepCurrentPlace;

  /// No description provided for @moodMatchPlanV2WithdrawSwap.
  ///
  /// In en, this message translates to:
  /// **'Withdraw suggestion'**
  String get moodMatchPlanV2WithdrawSwap;

  /// No description provided for @moodMatchPlanV2RespondSwapsOnCards.
  ///
  /// In en, this message translates to:
  /// **'Respond to swap suggestions on the cards'**
  String get moodMatchPlanV2RespondSwapsOnCards;

  /// No description provided for @moodMatchPlanV2SuggestDifferentPlace.
  ///
  /// In en, this message translates to:
  /// **'Suggest a change'**
  String get moodMatchPlanV2SuggestDifferentPlace;

  /// No description provided for @moodMatchPlanV2YourSwapPendingOwner.
  ///
  /// In en, this message translates to:
  /// **'You suggested {proposed}. Waiting for {name} to respond.'**
  String moodMatchPlanV2YourSwapPendingOwner(String proposed, String name);

  /// No description provided for @moodMatchToastPlanShared.
  ///
  /// In en, this message translates to:
  /// **'{name} shared the Mood Match plan with you.'**
  String moodMatchToastPlanShared(String name);

  /// No description provided for @moodMatchToastSwapRequested.
  ///
  /// In en, this message translates to:
  /// **'{name} suggested a different place: {place}.'**
  String moodMatchToastSwapRequested(String name, String place);

  /// No description provided for @moodMatchToastSwapAccepted.
  ///
  /// In en, this message translates to:
  /// **'{name} accepted the swap.'**
  String moodMatchToastSwapAccepted(String name);

  /// No description provided for @moodMatchToastSwapDeclined.
  ///
  /// In en, this message translates to:
  /// **'{name} declined the swap for {slot}.'**
  String moodMatchToastSwapDeclined(String name, String slot);

  /// No description provided for @moodMatchToastPartnerConfirmedSlot.
  ///
  /// In en, this message translates to:
  /// **'{name} confirmed a slot ({slot}).'**
  String moodMatchToastPartnerConfirmedSlot(String name, String slot);

  /// No description provided for @moodMatchToastGuestDeclinedOriginalDay.
  ///
  /// In en, this message translates to:
  /// **'{name} is not available for the day you proposed.'**
  String moodMatchToastGuestDeclinedOriginalDay(String name);

  /// No description provided for @moodMatchToastGuestProposedNewDay.
  ///
  /// In en, this message translates to:
  /// **'{name} suggested a different date — open the Mood Match day step.'**
  String moodMatchToastGuestProposedNewDay(String name);

  /// No description provided for @moodMatchSaveMyDayFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add to My Plans: {details}'**
  String moodMatchSaveMyDayFailed(String details);

  /// No description provided for @moodMatchPlanV2BasedOnMoods.
  ///
  /// In en, this message translates to:
  /// **'Based on moods: {moods}'**
  String moodMatchPlanV2BasedOnMoods(String moods);

  /// No description provided for @moodMatchPlanV2ActivityMood.
  ///
  /// In en, this message translates to:
  /// **'Mood: {mood}'**
  String moodMatchPlanV2ActivityMood(String mood);

  /// No description provided for @moodMatchHubBrandTag.
  ///
  /// In en, this message translates to:
  /// **'Mood Match'**
  String get moodMatchHubBrandTag;

  /// No description provided for @moodMatchHubEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Pick a friend. Two moods → one shared day.'**
  String get moodMatchHubEmptySub;

  /// No description provided for @moodMatchHubCtaStart.
  ///
  /// In en, this message translates to:
  /// **'Start Mood Match'**
  String get moodMatchHubCtaStart;

  /// No description provided for @moodMatchHubCtaResume.
  ///
  /// In en, this message translates to:
  /// **'Resume Mood Match'**
  String get moodMatchHubCtaResume;

  /// No description provided for @moodMatchHubCtaOpenShared.
  ///
  /// In en, this message translates to:
  /// **'Open shared plan'**
  String get moodMatchHubCtaOpenShared;

  /// No description provided for @moodMatchHubCtaReviewShared.
  ///
  /// In en, this message translates to:
  /// **'Review plan'**
  String get moodMatchHubCtaReviewShared;

  /// No description provided for @moodMatchHubSubWaitingJoin.
  ///
  /// In en, this message translates to:
  /// **'Waiting on {name} to join'**
  String moodMatchHubSubWaitingJoin(String name);

  /// No description provided for @moodMatchHubSubWaitingJoinNoName.
  ///
  /// In en, this message translates to:
  /// **'Waiting on your friend to join'**
  String get moodMatchHubSubWaitingJoinNoName;

  /// No description provided for @moodMatchHubSubWaitingMood.
  ///
  /// In en, this message translates to:
  /// **'Waiting on {name}\'s mood'**
  String moodMatchHubSubWaitingMood(String name);

  /// No description provided for @moodMatchHubSubWaitingMoodNoName.
  ///
  /// In en, this message translates to:
  /// **'Waiting on their mood'**
  String get moodMatchHubSubWaitingMoodNoName;

  /// No description provided for @moodMatchHubSubDayProposed.
  ///
  /// In en, this message translates to:
  /// **'{name} suggested a day — review'**
  String moodMatchHubSubDayProposed(String name);

  /// No description provided for @moodMatchHubSubDayProposedNoName.
  ///
  /// In en, this message translates to:
  /// **'A day was suggested — review'**
  String get moodMatchHubSubDayProposedNoName;

  /// No description provided for @moodMatchHubSubBuildingWith.
  ///
  /// In en, this message translates to:
  /// **'Building your shared day with {name}…'**
  String moodMatchHubSubBuildingWith(String name);

  /// No description provided for @moodMatchHubSubBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building your shared day…'**
  String get moodMatchHubSubBuilding;

  /// No description provided for @moodMatchHubSubReadyWith.
  ///
  /// In en, this message translates to:
  /// **'Your shared day with {name} is ready.'**
  String moodMatchHubSubReadyWith(String name);

  /// No description provided for @moodMatchHubSubReady.
  ///
  /// In en, this message translates to:
  /// **'Your shared day is ready.'**
  String get moodMatchHubSubReady;

  /// No description provided for @moodMatchHubMoreSessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+1 more Mood Match} other{+{count} more Mood Matches}}'**
  String moodMatchHubMoreSessions(int count);

  /// No description provided for @moodyHubActionFindCoffee.
  ///
  /// In en, this message translates to:
  /// **'Find coffee'**
  String get moodyHubActionFindCoffee;

  /// No description provided for @moodyHubActionGetMeActive.
  ///
  /// In en, this message translates to:
  /// **'Get me active'**
  String get moodyHubActionGetMeActive;

  /// No description provided for @moodyHubActionContinueDay.
  ///
  /// In en, this message translates to:
  /// **'Continue day'**
  String get moodyHubActionContinueDay;

  /// No description provided for @moodyHubActionReplaceActivity.
  ///
  /// In en, this message translates to:
  /// **'Replace activity'**
  String get moodyHubActionReplaceActivity;

  /// No description provided for @moodyHubMoodMatchViewMatches.
  ///
  /// In en, this message translates to:
  /// **'View matches'**
  String get moodyHubMoodMatchViewMatches;

  /// No description provided for @moodyHubIntroHeroEmpty.
  ///
  /// In en, this message translates to:
  /// **'Hey, your day is still open. Want me to plan something, or just chat for a bit?'**
  String get moodyHubIntroHeroEmpty;

  /// No description provided for @moodyHubIntroHeroActive.
  ///
  /// In en, this message translates to:
  /// **'Your day\'s already rolling. I\'m here if you want to tweak it or just chat.'**
  String get moodyHubIntroHeroActive;

  /// No description provided for @moodyHubIntroHeroSharedReady.
  ///
  /// In en, this message translates to:
  /// **'Your shared plan is ready at the top. Want to open it, or keep chatting?'**
  String get moodyHubIntroHeroSharedReady;

  /// No description provided for @moodyHubHeroBodyEmptyFriendly.
  ///
  /// In en, this message translates to:
  /// **'Hey, your day is still open. What are you in the mood for? 🤔'**
  String get moodyHubHeroBodyEmptyFriendly;

  /// No description provided for @moodyHubHeroBodyEmptyFriendly2.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet — and that\'s exciting! What do you feel like doing today? ✨'**
  String get moodyHubHeroBodyEmptyFriendly2;

  /// No description provided for @moodyHubHeroBodyEmptyFriendly3.
  ///
  /// In en, this message translates to:
  /// **'Blank canvas today. We could go anywhere with this! What\'s calling you? 🎨'**
  String get moodyHubHeroBodyEmptyFriendly3;

  /// No description provided for @moodyHubHeroBodyEmptyFriendly4.
  ///
  /// In en, this message translates to:
  /// **'Your day is wide open. Want me to build something around your mood? 🪄'**
  String get moodyHubHeroBodyEmptyFriendly4;

  /// No description provided for @moodyHubHeroBodyEmptyProfessional.
  ///
  /// In en, this message translates to:
  /// **'Your schedule is open. I can outline a clear, focused day plan—or we can keep this concise and practical. 📋'**
  String get moodyHubHeroBodyEmptyProfessional;

  /// No description provided for @moodyHubHeroBodyEmptyProfessional2.
  ///
  /// In en, this message translates to:
  /// **'Nothing locked in yet. Tell me your priorities and I\'ll structure the day. 🎯'**
  String get moodyHubHeroBodyEmptyProfessional2;

  /// No description provided for @moodyHubHeroBodyEmptyProfessional3.
  ///
  /// In en, this message translates to:
  /// **'Open day ahead. Where do you want to focus your energy? ⚡'**
  String get moodyHubHeroBodyEmptyProfessional3;

  /// No description provided for @moodyHubHeroBodyEmptyProfessional4.
  ///
  /// In en, this message translates to:
  /// **'Your calendar is clear. Ready to put together a sharp plan when you are. 📅'**
  String get moodyHubHeroBodyEmptyProfessional4;

  /// No description provided for @moodyHubHeroBodyEmptyEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Okay let\'s GO! 🚀 Your day is wide open and anything is possible right now!'**
  String get moodyHubHeroBodyEmptyEnergetic;

  /// No description provided for @moodyHubHeroBodyEmptyEnergetic2.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the agenda yet — honestly? Perfect. Let\'s make it legendary! 🌟'**
  String get moodyHubHeroBodyEmptyEnergetic2;

  /// No description provided for @moodyHubHeroBodyEmptyEnergetic3.
  ///
  /// In en, this message translates to:
  /// **'Fresh start, full energy, zero plans. That\'s literally my favourite combo! What are we doing? ⚡'**
  String get moodyHubHeroBodyEmptyEnergetic3;

  /// No description provided for @moodyHubHeroBodyEmptyEnergetic4.
  ///
  /// In en, this message translates to:
  /// **'The day is yours and it\'s still untouched. Tell me what you\'re feeling and let\'s build something real! 🔥'**
  String get moodyHubHeroBodyEmptyEnergetic4;

  /// No description provided for @moodyHubHeroBodyEmptyDirect.
  ///
  /// In en, this message translates to:
  /// **'Your day is open. Plan something, or chat—your call. 📍'**
  String get moodyHubHeroBodyEmptyDirect;

  /// No description provided for @moodyHubHeroBodyEmptyDirect2.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled. What do you want to do? 🗺️'**
  String get moodyHubHeroBodyEmptyDirect2;

  /// No description provided for @moodyHubHeroBodyEmptyDirect3.
  ///
  /// In en, this message translates to:
  /// **'Open day. I can plan it or you can — just say the word. ✌️'**
  String get moodyHubHeroBodyEmptyDirect3;

  /// No description provided for @moodyHubHeroBodyEmptyDirect4.
  ///
  /// In en, this message translates to:
  /// **'No plans yet. Drop a mood or an idea and we move. 🚀'**
  String get moodyHubHeroBodyEmptyDirect4;

  /// No description provided for @moodyHubHeroBodyActiveFriendly.
  ///
  /// In en, this message translates to:
  /// **'Your day is already rolling! I\'m here if you want to add something or just talk. 🎈'**
  String get moodyHubHeroBodyActiveFriendly;

  /// No description provided for @moodyHubHeroBodyActiveFriendly2.
  ///
  /// In en, this message translates to:
  /// **'You\'ve got things lined up — love that for you. Need anything tweaked? 🛠️'**
  String get moodyHubHeroBodyActiveFriendly2;

  /// No description provided for @moodyHubHeroBodyActiveFriendly3.
  ///
  /// In en, this message translates to:
  /// **'Day\'s in motion. Want to add a little something extra, or just check in? 💫'**
  String get moodyHubHeroBodyActiveFriendly3;

  /// No description provided for @moodyHubHeroBodyActiveFriendly4.
  ///
  /// In en, this message translates to:
  /// **'Looking good on the plan front! Let me know if anything needs adjusting. ✨'**
  String get moodyHubHeroBodyActiveFriendly4;

  /// No description provided for @moodyHubHeroBodyActiveProfessional.
  ///
  /// In en, this message translates to:
  /// **'Your day is underway. I can help refine timing or priorities—or keep this brief. ⏱️'**
  String get moodyHubHeroBodyActiveProfessional;

  /// No description provided for @moodyHubHeroBodyActiveProfessional2.
  ///
  /// In en, this message translates to:
  /// **'Schedule is set. Let me know if you want to optimise anything. 📈'**
  String get moodyHubHeroBodyActiveProfessional2;

  /// No description provided for @moodyHubHeroBodyActiveProfessional3.
  ///
  /// In en, this message translates to:
  /// **'You have a plan in place. I\'m available if adjustments come up. 🔄'**
  String get moodyHubHeroBodyActiveProfessional3;

  /// No description provided for @moodyHubHeroBodyActiveProfessional4.
  ///
  /// In en, this message translates to:
  /// **'Day is structured. Ready to adapt if needed. 📋'**
  String get moodyHubHeroBodyActiveProfessional4;

  /// No description provided for @moodyHubHeroBodyActiveEnergetic.
  ///
  /// In en, this message translates to:
  /// **'You\'re already moving — let\'s keep that momentum going! Anything to add? 🔥'**
  String get moodyHubHeroBodyActiveEnergetic;

  /// No description provided for @moodyHubHeroBodyActiveEnergetic2.
  ///
  /// In en, this message translates to:
  /// **'Look at you with a plan! Want to level it up or just vibe with what you have? 🚀'**
  String get moodyHubHeroBodyActiveEnergetic2;

  /// No description provided for @moodyHubHeroBodyActiveEnergetic3.
  ///
  /// In en, this message translates to:
  /// **'Day is set and you\'re ready — I love the energy! Tweak anything or just crush it? 💥'**
  String get moodyHubHeroBodyActiveEnergetic3;

  /// No description provided for @moodyHubHeroBodyActiveEnergetic4.
  ///
  /// In en, this message translates to:
  /// **'You\'ve got something going already! Want to stack on more or just ride the wave? 🌊'**
  String get moodyHubHeroBodyActiveEnergetic4;

  /// No description provided for @moodyHubHeroBodyActiveDirect.
  ///
  /// In en, this message translates to:
  /// **'Day\'s in motion. Tweak something, or chat. 📍'**
  String get moodyHubHeroBodyActiveDirect;

  /// No description provided for @moodyHubHeroBodyActiveDirect2.
  ///
  /// In en, this message translates to:
  /// **'Plan\'s set. Need anything changed? 🔄'**
  String get moodyHubHeroBodyActiveDirect2;

  /// No description provided for @moodyHubHeroBodyActiveDirect3.
  ///
  /// In en, this message translates to:
  /// **'You\'ve got a day. Add something or leave it. ✌️'**
  String get moodyHubHeroBodyActiveDirect3;

  /// No description provided for @moodyHubHeroBodyActiveDirect4.
  ///
  /// In en, this message translates to:
  /// **'Moving already. I\'m here if it needs a change. ⚡'**
  String get moodyHubHeroBodyActiveDirect4;

  /// No description provided for @moodyHubHeroBodySharedReadyFriendly.
  ///
  /// In en, this message translates to:
  /// **'Your shared plan is waiting — open it and let\'s make the day official! 🎉'**
  String get moodyHubHeroBodySharedReadyFriendly;

  /// No description provided for @moodyHubHeroBodySharedReadyProfessional.
  ///
  /// In en, this message translates to:
  /// **'Your shared plan is ready. Open it when you\'re ready, or continue our conversation here. 📋'**
  String get moodyHubHeroBodySharedReadyProfessional;

  /// No description provided for @moodyHubHeroBodySharedReadyEnergetic.
  ///
  /// In en, this message translates to:
  /// **'The collab plan is ready — open it right now because this one is going to be so good! 🔥'**
  String get moodyHubHeroBodySharedReadyEnergetic;

  /// No description provided for @moodyHubHeroBodySharedReadyDirect.
  ///
  /// In en, this message translates to:
  /// **'Shared plan is ready. Open it, or stay here. 📍'**
  String get moodyHubHeroBodySharedReadyDirect;

  /// No description provided for @moodyHubHeroBodySharedReadyDayEmptyFriendly.
  ///
  /// In en, this message translates to:
  /// **'You and your friend have a shared plan ready — open it to add everything to your day! ✨'**
  String get moodyHubHeroBodySharedReadyDayEmptyFriendly;

  /// No description provided for @moodyHubHeroBodySharedReadyDayEmptyProfessional.
  ///
  /// In en, this message translates to:
  /// **'A collaborative plan is ready in Mood Match. Open it to add activities to your day, or continue our conversation here. 🤝'**
  String get moodyHubHeroBodySharedReadyDayEmptyProfessional;

  /// No description provided for @moodyHubHeroBodySharedReadyDayEmptyEnergetic.
  ///
  /// In en, this message translates to:
  /// **'The Mood Match plan is ready and it\'s good — open it and load your day! 🚀'**
  String get moodyHubHeroBodySharedReadyDayEmptyEnergetic;

  /// No description provided for @moodyHubHeroBodySharedReadyDayEmptyDirect.
  ///
  /// In en, this message translates to:
  /// **'Shared plan in Mood Match. Open it to add to your day, or stay here. 📍'**
  String get moodyHubHeroBodySharedReadyDayEmptyDirect;

  /// No description provided for @moodyHubHeroBodyInviteFriendly.
  ///
  /// In en, this message translates to:
  /// **'Your last Mood Match is already on your plan. Ready to do it again with someone? 👯‍♀️'**
  String get moodyHubHeroBodyInviteFriendly;

  /// No description provided for @moodyHubHeroBodyInviteFriendly2.
  ///
  /// In en, this message translates to:
  /// **'That Mood Match was a moment! Who are you feeling like exploring with next? 🗺️'**
  String get moodyHubHeroBodyInviteFriendly2;

  /// No description provided for @moodyHubHeroBodyInviteFriendly3.
  ///
  /// In en, this message translates to:
  /// **'Last plan is locked in. Want to set up a new Mood Match with a friend? ✌️'**
  String get moodyHubHeroBodyInviteFriendly3;

  /// No description provided for @moodyHubHeroBodyInviteFriendly4.
  ///
  /// In en, this message translates to:
  /// **'Your shared day is on your plan. Another one? Tell me who you want to go out with. 💫'**
  String get moodyHubHeroBodyInviteFriendly4;

  /// No description provided for @moodyHubHeroBodyInviteProfessional.
  ///
  /// In en, this message translates to:
  /// **'Your previous Mood Match is on your schedule. When you\'re ready, start a new match to plan another day together. 🤝'**
  String get moodyHubHeroBodyInviteProfessional;

  /// No description provided for @moodyHubHeroBodyInviteProfessional2.
  ///
  /// In en, this message translates to:
  /// **'Last collaborative plan is confirmed. Initiate a new Mood Match when it suits you. 📅'**
  String get moodyHubHeroBodyInviteProfessional2;

  /// No description provided for @moodyHubHeroBodyInviteProfessional3.
  ///
  /// In en, this message translates to:
  /// **'Previous session is complete. Ready to schedule the next collaborative day? 🗓️'**
  String get moodyHubHeroBodyInviteProfessional3;

  /// No description provided for @moodyHubHeroBodyInviteProfessional4.
  ///
  /// In en, this message translates to:
  /// **'Your shared plan is in the books. Start a new match to plan ahead. 📋'**
  String get moodyHubHeroBodyInviteProfessional4;

  /// No description provided for @moodyHubHeroBodyInviteEnergetic.
  ///
  /// In en, this message translates to:
  /// **'That Mood Match is on your plan and I love it! Who\'s next? Let\'s match again! 🔥'**
  String get moodyHubHeroBodyInviteEnergetic;

  /// No description provided for @moodyHubHeroBodyInviteEnergetic2.
  ///
  /// In en, this message translates to:
  /// **'You did a Mood Match and it\'s on your plan — okay iconic! Who are we dragging into the next one? 🚀'**
  String get moodyHubHeroBodyInviteEnergetic2;

  /// No description provided for @moodyHubHeroBodyInviteEnergetic3.
  ///
  /// In en, this message translates to:
  /// **'Last match: done. Next match: waiting for you! Let\'s go again! ⚡'**
  String get moodyHubHeroBodyInviteEnergetic3;

  /// No description provided for @moodyHubHeroBodyInviteEnergetic4.
  ///
  /// In en, this message translates to:
  /// **'Your shared day is locked in — love that! Ready to plan another one? I\'ll make it even better. 🌟'**
  String get moodyHubHeroBodyInviteEnergetic4;

  /// No description provided for @moodyHubHeroBodyInviteDirect.
  ///
  /// In en, this message translates to:
  /// **'Last Mood Match is on your plan. Start a new one when you want. 📍'**
  String get moodyHubHeroBodyInviteDirect;

  /// No description provided for @moodyHubHeroBodyInviteDirect2.
  ///
  /// In en, this message translates to:
  /// **'Done with last match. Start the next one. ✌️'**
  String get moodyHubHeroBodyInviteDirect2;

  /// No description provided for @moodyHubHeroBodyInviteDirect3.
  ///
  /// In en, this message translates to:
  /// **'Plan saved. New Mood Match when you\'re ready. 🔄'**
  String get moodyHubHeroBodyInviteDirect3;

  /// No description provided for @moodyHubHeroBodyInviteDirect4.
  ///
  /// In en, this message translates to:
  /// **'Last one\'s on your plan. Match again? 🤝'**
  String get moodyHubHeroBodyInviteDirect4;

  /// No description provided for @moodyHubMoodMatchInviteCta.
  ///
  /// In en, this message translates to:
  /// **'Start a Mood Match'**
  String get moodyHubMoodMatchInviteCta;

  /// No description provided for @moodyHubInviteCardBody.
  ///
  /// In en, this message translates to:
  /// **'Match with a friend and plan a day together—coffee, a walk, date, whatever fits you both. 👯‍♀️🗺️'**
  String get moodyHubInviteCardBody;

  /// No description provided for @moodyHubPlanYourDayCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your day'**
  String get moodyHubPlanYourDayCardTitle;

  /// No description provided for @moodyHubPlanYourDayCardBody.
  ///
  /// In en, this message translates to:
  /// **'Tell me your mood and I’ll build a full solo day—places, timing, and vibes that fit just you. ✨🧳'**
  String get moodyHubPlanYourDayCardBody;

  /// No description provided for @moodyHubContinueDayCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue your day'**
  String get moodyHubContinueDayCardTitle;

  /// No description provided for @moodyHubContinueDayCardBody.
  ///
  /// In en, this message translates to:
  /// **'You’ve got things on your timeline. Jump back to My Day or chat with me to tweak the flow. 🔄'**
  String get moodyHubContinueDayCardBody;

  /// No description provided for @moodyHubChangeMoodCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Change mood'**
  String get moodyHubChangeMoodCardTitle;

  /// No description provided for @moodyHubChangeMoodCardBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a new vibe and I’ll tweak how your day feels—places, pace, and energy that match you. ✨🎨'**
  String get moodyHubChangeMoodCardBody;

  /// No description provided for @moodyHubCollapsedActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Moody Hub'**
  String get moodyHubCollapsedActionsTitle;

  /// No description provided for @moodyHubCollapsedActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your day, Mood Match, and more.'**
  String get moodyHubCollapsedActionsSubtitle;

  /// No description provided for @moodMatchAlreadyOnYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Already on your plan'**
  String get moodMatchAlreadyOnYourPlan;

  /// No description provided for @weatherModalNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get weatherModalNow;

  /// No description provided for @weatherModalTipTitle.
  ///
  /// In en, this message translates to:
  /// **'My tip for today'**
  String get weatherModalTipTitle;

  /// No description provided for @weatherModalTipRain.
  ///
  /// In en, this message translates to:
  /// **'Rain is expected today. Bring an umbrella and consider an indoor activity.'**
  String get weatherModalTipRain;

  /// No description provided for @weatherModalTipSunnyHighUv.
  ///
  /// In en, this message translates to:
  /// **'It is sunny and UV is high today. Use sunscreen, bring water, and plan a few shade breaks.'**
  String get weatherModalTipSunnyHighUv;

  /// No description provided for @weatherModalTipSunny.
  ///
  /// In en, this message translates to:
  /// **'Mild and dry weather today. Great for a walk or a terrace stop.'**
  String get weatherModalTipSunny;

  /// No description provided for @weatherModalTipCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy and likely cooler. Bring one extra layer to stay comfortable.'**
  String get weatherModalTipCloudy;

  /// No description provided for @weatherModalTipDefault.
  ///
  /// In en, this message translates to:
  /// **'Conditions may change today. Dress in layers and check the forecast again later.'**
  String get weatherModalTipDefault;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
