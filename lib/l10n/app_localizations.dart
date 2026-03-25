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
  /// **'See how it works →'**
  String get introSeeHowItWorks;

  /// No description provided for @demoMoodyGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hey! 👋 I\'m Moody, your travel companion.'**
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
  /// **'A romantic day? Moody has you 💕'**
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
  /// **'The details that make WanderMood more personal and smarter.'**
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
  /// **'Add your first vibe and give your profile more personality right away.'**
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

  /// No description provided for @subscriptionFeatureEarlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Early access to new features'**
  String get subscriptionFeatureEarlyAccess;

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
  /// **'{title} saved for later!'**
  String myDaySavedForLater(String title);

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

  /// No description provided for @myDayTimelineSectionEveningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wind down and enjoy'**
  String get myDayTimelineSectionEveningSubtitle;

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
  /// **'You do not have any planned activities in your agenda yet'**
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
  /// **'No password needed ✨'**
  String get signupNoPasswordNeeded;

  /// No description provided for @signupRatingBadge.
  ///
  /// In en, this message translates to:
  /// **'⭐ 4.9/5 · Free · No password'**
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
  /// **'Check your inbox! 📬'**
  String get signupSuccessCheckInbox;

  /// No description provided for @signupSuccessWeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to'**
  String get signupSuccessWeSentTo;

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
  /// **'Open email app'**
  String get signupOpenEmailApp;

  /// No description provided for @signupNoEmailReceived.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive an email?'**
  String get signupNoEmailReceived;

  /// No description provided for @signupWrongEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Wrong email address?'**
  String get signupWrongEmailAddress;

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

  /// No description provided for @demoMoodyQuestion.
  ///
  /// In en, this message translates to:
  /// **'I help you discover amazing places based on how you feel. What\'s your mood today?'**
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

  /// No description provided for @demoUserReplyDefault.
  ///
  /// In en, this message translates to:
  /// **'This is my mood!'**
  String get demoUserReplyDefault;

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
  /// **'My Agenda'**
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
  /// **'Nice! {count, plural, one{1 filter} other{{count} filters}} active — I\'ll keep that in mind.'**
  String exploreMoodyHintFiltersActive(int count);

  /// No description provided for @exploreMoodyHintFiltersIntro.
  ///
  /// In en, this message translates to:
  /// **'Hey! I\'m Moody. Use filters to find exactly what fits your vibe — dietary, accessibility, photo spots, and more.'**
  String get exploreMoodyHintFiltersIntro;

  /// No description provided for @exploreClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get exploreClearAll;

  /// No description provided for @exploreSectionQuickSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Quick suggestions'**
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
  /// **'Comfort & convenience'**
  String get exploreSectionComfortConvenience;

  /// No description provided for @exploreSectionPhotoAesthetic.
  ///
  /// In en, this message translates to:
  /// **'Photo & aesthetic'**
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

  /// No description provided for @explorePlaceDescriptionFallback.
  ///
  /// In en, this message translates to:
  /// **'Explore {name}'**
  String explorePlaceDescriptionFallback(String name);

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

  /// No description provided for @premiumUpgradeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
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
  /// **'When are you planning for?'**
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
  /// **'What stood out? Any tips for others?'**
  String get moodyReviewNoteHint;

  /// No description provided for @moodyReviewNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'💡 This helps others discover great spots!'**
  String get moodyReviewNoteHelper;

  /// No description provided for @moodyReviewSave.
  ///
  /// In en, this message translates to:
  /// **'Save Review'**
  String get moodyReviewSave;

  /// No description provided for @moodyReviewNeedStars.
  ///
  /// In en, this message translates to:
  /// **'Please add a star rating to continue'**
  String get moodyReviewNeedStars;

  /// No description provided for @moodyReviewHelpsMoody.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps Moody learn!'**
  String get moodyReviewHelpsMoody;

  /// No description provided for @moodyReviewThanksToast.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review! 🚀'**
  String get moodyReviewThanksToast;

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

  /// No description provided for @planLoadingRotating2.
  ///
  /// In en, this message translates to:
  /// **'Putting your day together…'**
  String get planLoadingRotating2;

  /// No description provided for @planLoadingRotating3.
  ///
  /// In en, this message translates to:
  /// **'Almost there — your plan is almost ready ✨'**
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
