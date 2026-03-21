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

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your mood-based travel companion'**
  String get splashTagline;

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

  /// Tagline on the intro screen below Mood-Based Travel Buddy
  ///
  /// In en, this message translates to:
  /// **'Your mood. Your day. Your adventure.'**
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
  /// **'See How It Works'**
  String get introSeeHowItWorks;

  /// No description provided for @demoMoodyGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hey there! 👋 I\'m Moody, your travel buddy.'**
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
  /// **'Love that energy! 🔥 Here are some exciting spots that match your adventurous spirit...'**
  String get demoMoodyResponseAdventurous;

  /// No description provided for @demoMoodyResponseRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Ah, a chill day! ☕ Let me find you some peaceful spots to unwind...'**
  String get demoMoodyResponseRelaxed;

  /// No description provided for @demoMoodyResponseRomantic.
  ///
  /// In en, this message translates to:
  /// **'How lovely! 💕 I\'ve got some beautiful places perfect for romance...'**
  String get demoMoodyResponseRomantic;

  /// No description provided for @demoMoodyResponseCultural.
  ///
  /// In en, this message translates to:
  /// **'A curious explorer! 🎨 Check out these fascinating cultural gems...'**
  String get demoMoodyResponseCultural;

  /// No description provided for @demoMoodyResponseFoodie.
  ///
  /// In en, this message translates to:
  /// **'Yum! 🍕 Here are some delicious spots that\'ll satisfy your taste buds...'**
  String get demoMoodyResponseFoodie;

  /// No description provided for @demoMoodyResponseSocial.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go! 🎉 I\'ve got some fun places perfect for hanging out with friends...'**
  String get demoMoodyResponseSocial;

  /// No description provided for @demoMoodyResponseDefault.
  ///
  /// In en, this message translates to:
  /// **'Great choice! 🌟 Here are some perfect spots for your mood...'**
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
  /// **'Join WanderMood'**
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
  /// **'Send Magic Link'**
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
  /// **'A calm timeline of how you\'ve been feeling.'**
  String get moodHistoryIntro;

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
  /// **'Check in from Moody Hub or My Day—your moments will line up below.'**
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
  /// **'Username'**
  String get profileEditUsernameLabel;

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
  /// **'My Agenda'**
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

  /// No description provided for @drawerDayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} Day Streak'**
  String drawerDayStreak(String count);

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
  /// **'Upgrade to'**
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

  /// No description provided for @subscriptionUpgradeCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for €4.99/month'**
  String get subscriptionUpgradeCta;

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
  /// **'support@wandermood.com'**
  String get helpSupportEmailAddress;

  /// No description provided for @helpSupportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'WanderMood Support'**
  String get helpSupportEmailSubject;

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
  /// **'Food & Dining'**
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
  /// **'Shopping & Markets'**
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

  /// No description provided for @prefSectionSocialVibe.
  ///
  /// In en, this message translates to:
  /// **'Social Vibe 👥'**
  String get prefSectionSocialVibe;

  /// No description provided for @prefSectionPlanningPace.
  ///
  /// In en, this message translates to:
  /// **'Planning Pace ⏰'**
  String get prefSectionPlanningPace;

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
  /// **'Moody is thinking...'**
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

  /// No description provided for @noPlanDayOpen.
  ///
  /// In en, this message translates to:
  /// **'Your day in {city} is wide open. Want me to put a plan together, or are you looking for a specific vibe?'**
  String noPlanDayOpen(String city);

  /// No description provided for @noPlanPlanMyWholeDay.
  ///
  /// In en, this message translates to:
  /// **'✨ Plan my whole day'**
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
  /// **'Just chat'**
  String get noPlanJustChat;

  /// No description provided for @noPlanPlanLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get noPlanPlanLater;

  /// No description provided for @myDayHeroActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re in this activity right now.'**
  String get myDayHeroActiveSubtitle;
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
