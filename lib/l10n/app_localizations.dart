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

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

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
