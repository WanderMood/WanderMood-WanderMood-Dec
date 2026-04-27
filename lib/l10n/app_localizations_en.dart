// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WanderMood';

  @override
  String get moodHomeHowAreYouFeeling => 'How are you feeling today?';

  @override
  String get moodHomeCtxNewUserMorning =>
      'Let\'s start your day with the right energy.';

  @override
  String get moodHomeCtxNewUserAfternoon =>
      'Time to make the most of your afternoon.';

  @override
  String get moodHomeCtxNewUserEvening =>
      'Evening\'s here — let\'s find your perfect vibe.';

  @override
  String get moodHomeCtxNewUserNight =>
      'Late night energy — let\'s find something that fits.';

  @override
  String get moodHomeCtxReturnMorningWeekend =>
      'Weekend morning vibes — let\'s set the tone.';

  @override
  String get moodHomeCtxReturnMorningWeekday =>
      'Fresh start to the day — what feels right?';

  @override
  String get moodHomeCtxReturnAfternoon =>
      'Afternoon\'s rolling in — time to match your energy.';

  @override
  String get moodHomeCtxReturnEveningWeekend =>
      'Weekend evening — let\'s find something that fits.';

  @override
  String get moodHomeCtxReturnEveningWeekday =>
      'Workday\'s done — what\'s your evening vibe?';

  @override
  String get moodHomeCtxReturnNight =>
      'Late night energy — let\'s see what calls to you.';

  @override
  String get moodHomeCtxFallback => 'Let\'s find the right vibe for today.';

  @override
  String get moodHomeHeroGreetingEarlyMorningTitle => 'Rise and shine! ☀️';

  @override
  String get moodHomeHeroGreetingEarlyMorningSubWeekend =>
      'Perfect weekend morning for adventures';

  @override
  String get moodHomeHeroGreetingEarlyMorningSubWeekday =>
      'Ready to make today amazing?';

  @override
  String get moodHomeHeroGreetingLateMorningTitle => 'Hey there! 👋';

  @override
  String get moodHomeHeroGreetingLateMorningSub =>
      'I\'ve been thinking about your perfect day';

  @override
  String get moodHomeHeroGreetingAfternoonTitle => 'Afternoon vibes! ✨';

  @override
  String get moodHomeHeroGreetingAfternoonSub =>
      'What\'s on your mind for today?';

  @override
  String get moodHomeHeroGreetingEarlyEveningTitle => 'Evening explorer! 🌆';

  @override
  String get moodHomeHeroGreetingEarlyEveningSubWeekend =>
      'Weekend nights are the best for discoveries';

  @override
  String get moodHomeHeroGreetingEarlyEveningSubWeekday =>
      'How did your day treat you?';

  @override
  String get moodHomeHeroGreetingNightTitle => 'Night owl! 🌙';

  @override
  String get moodHomeHeroGreetingNightSub => 'Late night adventures calling?';

  @override
  String moodHomeEmptyChatPitch(String city) {
    return 'I know $city like the back of my hand! Tell me your mood, and I\'ll craft the perfect day just for you. Whether you\'re feeling adventurous, romantic, or need some chill vibes — I\'ve got you covered! 🎯';
  }

  @override
  String get splashTagline => 'Your mood-based travel companion';

  @override
  String get splashPlanYourDayByFeeling => 'Plan your day by how you feel';

  @override
  String get welcome => 'Welcome';

  @override
  String get hello => 'Hello';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get heyNightOwl => 'Hey night owl';

  @override
  String get readyToCreateYourFirstDay =>
      'Ready to create your first amazing day?';

  @override
  String get createMyFirstDay => 'Create my first day';

  @override
  String get myDayHeaderMorning => 'Good morning! Let\'s make today amazing.';

  @override
  String get myDayHeaderAfternoon =>
      'Good afternoon! Your day is looking great.';

  @override
  String get myDayHeaderEvening =>
      'Good evening! Let\'s see what the rest of today can become.';

  @override
  String get myDayNoPlanHeaderSubtitle =>
      'No plans yet. Your day is still open.';

  @override
  String get myDayEmptyGreetingMorningBody =>
      'A fresh day full of possibilities awaits.';

  @override
  String get myDayEmptyGreetingAfternoonBody =>
      'There is still time to turn today into something memorable.';

  @override
  String get myDayEmptyGreetingEveningBody =>
      'The night is still open. Plan something special or ease into it slowly.';

  @override
  String get myDayEmptyPlanTitle => 'Ready to plan your day?';

  @override
  String get myDayEmptyPlanSubtitle =>
      'Create a day plan and start exploring places that match your mood, timing, and energy.';

  @override
  String get myDayEmptyCreateButton => 'Create My Day';

  @override
  String get myDayEmptyBrowseButton => 'Browse Activities';

  @override
  String get myDayEmptyAskMoodyButton => 'Ask Moody';

  @override
  String get myDayQuickAddActivity => 'Add activity';

  @override
  String get moodyFeedbackPromptBody =>
      'How\'s it going? Tap to tell me about your experience!';

  @override
  String get moodyFeedbackShareAction => 'Share feedback';

  @override
  String get myDayEmptyInspiredTitle => 'Get inspired';

  @override
  String get myDayInspiredCafesTitle => 'Discover cafes';

  @override
  String get myDayInspiredCafesSubtitle => 'Find cozy spots to relax';

  @override
  String get myDayInspiredTrendingTitle => 'Trending places';

  @override
  String get myDayInspiredTrendingSubtitle => 'Popular spots this week';

  @override
  String get myDayInspiredHiddenGemsTitle => 'Hidden gems';

  @override
  String get myDayInspiredHiddenGemsSubtitle => 'Local favorites nearby';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String moodyIntroGreeting(String name) {
    return 'Hey $name! 👋';
  }

  @override
  String get moodyIntroImMoody => 'I\'m Moody.';

  @override
  String get moodyIntroSubtext =>
      'I\'m here to help you plan days that match your mood, energy, and vibe.';

  @override
  String get moodyIntroSuggestActivities => 'I\'ll suggest activities like:';

  @override
  String get moodyIntroTakesLessThan =>
      'Takes less than a minute • Uses your preferences';

  @override
  String get moodyIntroNameFallback => 'there';

  @override
  String get moodyIntroActLocalRestaurant => 'Local restaurant discovery';

  @override
  String get moodyIntroActMuseum => 'Museum or gallery visit';

  @override
  String get moodyIntroActLocalMarket => 'Local market exploration';

  @override
  String get moodyIntroActNature => 'Nature walk or park visit';

  @override
  String get moodyIntroActNightlife => 'Evening bar or lounge';

  @override
  String get moodyIntroActSpa => 'Spa or wellness experience';

  @override
  String get moodyIntroActCoffee => 'Morning coffee spot';

  @override
  String get moodyIntroActAdventure => 'Active outdoor adventure';

  @override
  String get moodyIntroActPeacefulWalk => 'Peaceful evening walk';

  @override
  String get moodyIntroActHistorical => 'Historical site visit';

  @override
  String get moodyIntroActRomantic => 'Romantic dining experience';

  @override
  String get moodyIntroActSocial => 'Social gathering spot';

  @override
  String get moodyIntroActScenic => 'Scenic viewpoint';

  @override
  String get moodyIntroActEarlyMorning => 'Early morning experience';

  @override
  String get moodyIntroActEvening => 'Evening entertainment';

  @override
  String get moodyIntroActAfternoon => 'Afternoon activity';

  @override
  String get moodyIntroActSurprise => 'Surprise discovery';

  @override
  String get moodyIntroActMarketVisit => 'Local market visit';

  @override
  String get moodyIntroActEveningWalk => 'Evening walk with a view';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueButton => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get fullName => 'Full Name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get selectDate => 'Select Date';

  @override
  String get bio => 'Bio';

  @override
  String get notifications => 'Notifications';

  @override
  String get allowNotifications => 'Allow Notifications';

  @override
  String get masterControlForAllNotifications =>
      'Master control for all notifications';

  @override
  String get activityNotifications => 'Activity Notifications';

  @override
  String get activityReminders => 'Activity Reminders';

  @override
  String get remindersForUpcomingActivities =>
      'Reminders for upcoming activities and plans';

  @override
  String get moodTracking => 'Mood Tracking';

  @override
  String get dailyPromptsToTrackYourMood => 'Daily prompts to track your mood';

  @override
  String get travelAndWeather => 'Travel & Weather';

  @override
  String get weatherAlerts => 'Weather Alerts';

  @override
  String get getAlertsAboutWeatherChanges => 'Get alerts about weather changes';

  @override
  String get travelTips => 'Travel Tips';

  @override
  String get suggestionsForYourTrips =>
      'Suggestions for your trips and activities';

  @override
  String get localEvents => 'Local Events';

  @override
  String get notificationsAboutEventsInYourArea =>
      'Notifications about events in your area';

  @override
  String get social => 'Social';

  @override
  String get friendActivity => 'Friend Activity';

  @override
  String get whenFriendsShareTrips => 'When friends share trips or activities';

  @override
  String get specialOffers => 'Special Offers';

  @override
  String get promotionalOffersAndAppUpdates =>
      'Promotional offers and app updates';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get chooseYourPreferredLanguage =>
      'Choose your preferred language for the app interface. This will affect all text and content throughout the app.';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get publicProfile => 'Public Profile';

  @override
  String get allowOthersToViewYourProfile =>
      'Allow others to view your profile';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get receivePushNotifications => 'Receive push notifications';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get receiveEmailNotifications => 'Receive email notifications';

  @override
  String get manageYourPrivacySettings =>
      'Manage your privacy settings and notification preferences. These settings control who can see your profile and how you receive updates.';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get chooseYourPreferredTheme =>
      'Choose your preferred theme for the app. You can follow your system settings or choose a specific theme.';

  @override
  String get system => 'System';

  @override
  String get followSystemTheme => 'Follow system theme';

  @override
  String get light => 'Light';

  @override
  String get lightTheme => 'Light theme';

  @override
  String get dark => 'Dark';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get changeYourMood => 'Change your mood?';

  @override
  String get doYouWantToContinueToChangeMood =>
      'Do you want to continue to change mood? This will take you to the mood selection screen.';

  @override
  String get enabled => 'enabled';

  @override
  String get disabled => 'disabled';

  @override
  String get updated => 'updated';

  @override
  String get failedToUpdate => 'Failed to update';

  @override
  String languageUpdatedTo(String language) {
    return 'Language updated to $language';
  }

  @override
  String themeUpdatedTo(String theme) {
    return 'Theme updated to $theme';
  }

  @override
  String get profileVisibilityUpdated => 'Profile visibility updated';

  @override
  String get pushNotificationsEnabled => 'Push notifications enabled';

  @override
  String get pushNotificationsDisabled => 'Push notifications disabled';

  @override
  String get emailNotificationsEnabled => 'Email notifications enabled';

  @override
  String get emailNotificationsDisabled => 'Email notifications disabled';

  @override
  String get settings => 'Settings';

  @override
  String get privacy => 'Privacy';

  @override
  String get privateProfile => 'Private Profile';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingTitle => 'Setting up your\nperfect day!';

  @override
  String get loadingSubtitle =>
      'We\'re preparing personalized activities,\nplaces, and insights just for you!';

  @override
  String get loadingStep0 => 'Preparing your personalized experience...';

  @override
  String get loadingStep1 => 'Loading your preferences...';

  @override
  String get loadingStep2 => 'Finding activities you\'ll love...';

  @override
  String get loadingStep3 => 'Curating perfect activities for you...';

  @override
  String get loadingStep4 => 'Almost ready! Setting up your dashboard...';

  @override
  String get loadingStep5 => 'Preparing your personalized dashboard...';

  @override
  String get loadingStep6 =>
      'Ready to explore! (Some data will load as you go)';

  @override
  String get loadingFact0 =>
      'Did you know? There are 195 countries in the world, each with unique cultures and traditions!';

  @override
  String get loadingFact1 =>
      'The world\'s busiest airport serves over 100 million passengers annually!';

  @override
  String get loadingFact2 =>
      'There are over 1,500 UNESCO World Heritage Sites across the globe!';

  @override
  String get loadingFact3 =>
      'The Great Wall of China is visible from space and stretches over 13,000 miles!';

  @override
  String get loadingFact4 =>
      'There are more than 6,900 languages spoken around the world!';

  @override
  String get loadingFact5 =>
      'The Amazon rainforest produces 20% of the world\'s oxygen!';

  @override
  String get loadingFact6 =>
      'Mount Everest grows about 4mm taller each year due to geological forces!';

  @override
  String get loadingFact7 =>
      'The Sahara Desert is larger than the entire United States!';

  @override
  String get weatherCurrentLocation => 'Current location';

  @override
  String get loadingFactNl0 =>
      'The Netherlands has more museums per square mile than any other country!';

  @override
  String get loadingFactNl1 =>
      'Rotterdam is home to Europe\'s largest port, handling over 400 million tons of cargo annually!';

  @override
  String get loadingFactNl2 =>
      'The Netherlands has over 35,000 kilometers of bike paths - enough to circle the Earth!';

  @override
  String get loadingFactNl3 =>
      'Amsterdam has more canals than Venice and more bridges than Paris!';

  @override
  String get loadingFactNl4 =>
      'The Dutch consume over 150 million stroopwafels every year!';

  @override
  String get loadingFactNl5 =>
      'The Netherlands is the world\'s second-largest exporter of food despite its small size!';

  @override
  String get loadingFactNl6 =>
      'Keukenhof Gardens displays over 7 million flower bulbs across 32 hectares!';

  @override
  String get loadingFactNl7 =>
      'The Dutch are the tallest people in the world with an average height of 6 feet!';

  @override
  String get loadingFactUs0 =>
      'The US has 63 national parks, from Yellowstone to the Grand Canyon!';

  @override
  String get loadingFactUs1 =>
      'Alaska has more than 3 million lakes and over 100,000 glaciers!';

  @override
  String get loadingFactUs2 =>
      'The US Interstate Highway System spans over 47,000 miles!';

  @override
  String get loadingFactUs3 =>
      'Times Square in NYC is visited by over 50 million people annually!';

  @override
  String get loadingFactUs4 =>
      'The US has the world\'s largest economy and is home to Silicon Valley!';

  @override
  String get loadingFactUs5 =>
      'Hawaii is the only US state that commercially grows coffee!';

  @override
  String get loadingFactUs6 =>
      'The Golden Gate Bridge in San Francisco is painted International Orange!';

  @override
  String get loadingFactUs7 =>
      'Disney World in Florida is larger than the city of San Francisco!';

  @override
  String get loadingFactJp0 =>
      'Japan has over 6,800 islands, but only 430 are inhabited!';

  @override
  String get loadingFactJp1 =>
      'The Japanese Shinkansen bullet trains can reach speeds of 200 mph!';

  @override
  String get loadingFactJp2 =>
      'Mount Fuji is actually an active volcano that last erupted in 1707!';

  @override
  String get loadingFactJp3 =>
      'Japan has more than 100,000 temples and shrines!';

  @override
  String get loadingFactJp4 =>
      'Tokyo is the world\'s largest metropolitan area with over 37 million people!';

  @override
  String get loadingFactJp5 =>
      'Japan consumes about 80% of the world\'s bluefin tuna!';

  @override
  String get loadingFactJp6 =>
      'The Japanese love vending machines - there\'s one for every 23 people!';

  @override
  String get loadingFactJp7 =>
      'Cherry blossom season in Japan attracts millions of visitors each spring!';

  @override
  String get loadingFactUk0 =>
      'The UK has over 1,500 castles, from medieval fortresses to royal residences!';

  @override
  String get loadingFactUk1 =>
      'London\'s Big Ben is not actually the name of the clock tower - it\'s Elizabeth Tower!';

  @override
  String get loadingFactUk2 =>
      'The UK has produced more world-famous musicians per capita than any other country!';

  @override
  String get loadingFactUk3 =>
      'Stonehenge is over 5,000 years old and still shrouded in mystery!';

  @override
  String get loadingFactUk4 =>
      'The London Underground is the world\'s oldest subway system, opened in 1863!';

  @override
  String get loadingFactUk5 =>
      'The UK has 15 UNESCO World Heritage Sites including Bath and Edinburgh!';

  @override
  String get loadingFactUk6 =>
      'Scotland has over 3,000 castles and about 790 islands!';

  @override
  String get loadingFactUk7 =>
      'The British drink about 100 million cups of tea every day!';

  @override
  String get loadingFactDe0 =>
      'Germany has over 25,000 castles and palaces scattered across the country!';

  @override
  String get loadingFactDe1 =>
      'The Berlin Wall was 96 miles long and stood for 28 years!';

  @override
  String get loadingFactDe2 =>
      'Germany is famous for Oktoberfest, which actually starts in September!';

  @override
  String get loadingFactDe3 =>
      'The Black Forest region inspired many Brothers Grimm fairy tales!';

  @override
  String get loadingFactDe4 =>
      'Germany has no general speed limit on about 60% of its Autobahn highways!';

  @override
  String get loadingFactDe5 =>
      'Neuschwanstein Castle was the inspiration for Disney\'s Sleeping Beauty castle!';

  @override
  String get loadingFactDe6 =>
      'Germany has the largest economy in Europe and is known for engineering!';

  @override
  String get loadingFactDe7 =>
      'The Rhine River flows through Germany and is lined with medieval castles!';

  @override
  String get loadingFactFr0 =>
      'France is the world\'s most visited country with over 89 million tourists annually!';

  @override
  String get loadingFactFr1 =>
      'The Eiffel Tower was originally built as a temporary structure for the 1889 World\'s Fair!';

  @override
  String get loadingFactFr2 =>
      'France produces over 400 types of cheese - one for every day of the year!';

  @override
  String get loadingFactFr3 =>
      'The Palace of Versailles has 2,300 rooms and 67 staircases!';

  @override
  String get loadingFactFr4 =>
      'France has 44 UNESCO World Heritage Sites, including Mont-Saint-Michel!';

  @override
  String get loadingFactFr5 =>
      'The Louvre Museum is the world\'s largest art museum!';

  @override
  String get loadingFactFr6 =>
      'The French Riviera stretches for 550 miles along the Mediterranean!';

  @override
  String get loadingFactFr7 =>
      'France is home to the world\'s most famous bicycle race - the Tour de France!';

  @override
  String guestPlaceDistanceKm(String km) {
    return '$km km';
  }

  @override
  String guestPlaceHoursRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get prefSocialVibeTitleFallback => 'What\'s your social vibe? 👥';

  @override
  String get prefSocialVibeSubtitleFallback =>
      'How do you like to experience things?';

  @override
  String get prefPlanningPaceTitleFallback => 'Tell me your pace ⏰';

  @override
  String get prefPlanningPaceSubtitleFallback => 'Your planning style';

  @override
  String get prefTravelStyleTitleFallback => 'Last but not least! ✨';

  @override
  String get prefTravelStyleSubtitleFallback => 'What\'s your travel style?';

  @override
  String get prefStartMyJourney => 'Start My Journey';

  @override
  String get onboardingPagerSlide1Title => 'Meet Moody 😄';

  @override
  String get onboardingPagerSlide1Subtitle => 'Your travel BFF 💬🌍';

  @override
  String get onboardingPagerSlide1Description =>
      'Moody gets to know your vibe, your energy, and the kind of day you\'re having. With all that, I create personalized plans — made just for you. Think of me as your fun, curious bestie who\'s always down to explore 🌆🎈';

  @override
  String get onboardingPagerSlide2Title => 'Travel by Mood 🌈';

  @override
  String get onboardingPagerSlide2Subtitle => 'Your Feelings, Your Journey 💭';

  @override
  String get onboardingPagerSlide2Description =>
      'Whether you\'re in a peaceful, romantic, or adventurous mood... just tell me how you feel, and I\'ll create personalized plans 🌸🏞️\nFrom hidden gems to sunset strolls—mood first, always.';

  @override
  String get onboardingPagerSlide3Title => 'Your Day, Your Way 🫶🏾';

  @override
  String get onboardingPagerSlide3Subtitle =>
      'Sunrise to sunset, I\'ve got you ☀️🌙';

  @override
  String get onboardingPagerSlide3Description =>
      'Your plan is broken into moments—morning, afternoon, evening, and night. Choose your vibe, pick your favorites, and I\'ll handle the magic. 🧭🎯 All based on location, time, weather & mood.';

  @override
  String get onboardingPagerSlide4Title => 'Every Day\'s a Mood 🎨';

  @override
  String get onboardingPagerSlide4Subtitle =>
      'Discover new places - every day🌍';

  @override
  String get onboardingPagerSlide4Description =>
      'WanderMood makes every day feel like a new adventure. Wake up, check your vibe, explore hand-picked activities 💡📍 Let your mood lead the way—again and again.';

  @override
  String get appSettings => 'App Settings';

  @override
  String get pushEmailInApp => 'Push, email, and in-app';

  @override
  String get location => 'Location';

  @override
  String get autoDetectPermissions => 'Auto-detect and permissions';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get more => 'More';

  @override
  String get achievements => 'Achievements';

  @override
  String get unlocked => 'unlocked';

  @override
  String get subscription => 'Subscription';

  @override
  String get free => 'Free';

  @override
  String get plan => 'Plan';

  @override
  String get premium => 'Premium';

  @override
  String get dataStorage => 'Data & Storage';

  @override
  String get exportClearCache => 'Export data and clear cache';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get faqContactUs => 'FAQ and contact us';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get permanentlyDeleteYourData => 'Permanently delete your data';

  @override
  String get signOut => 'Sign Out';

  @override
  String get logOutOfYourAccount => 'Log out of your account';

  @override
  String get introTagline => 'This takes only 10 seconds, I promise.';

  @override
  String get introTitleLine1 => 'Your Mood,';

  @override
  String get introTitleLine2 => 'Your Adventure';

  @override
  String get introSkip => 'Skip';

  @override
  String get introSeeHowItWorks => 'Take a look, this is fun!';

  @override
  String get demoMoodyGreeting => 'Hey… I\'m Moody 🙂';

  @override
  String get demoMoodyAskVibe =>
      'I help you discover amazing places based on how you\'re feeling. What\'s your mood today?';

  @override
  String demoUserFeeling(String mood) {
    return 'I\'m feeling $mood';
  }

  @override
  String get demoMoodyResponseAdventurous =>
      'Time for adventure! I know exactly what you need 🔥';

  @override
  String get demoMoodyResponseRelaxed => 'Taking it easy today? Great plan! 🌿';

  @override
  String get demoMoodyResponseRomantic => 'A romantic day? I\'ve got you.';

  @override
  String get demoMoodyResponseCultural =>
      'The city\'s culture scene is waiting for you 🎭';

  @override
  String get demoMoodyResponseFoodie => 'I know the best spots in the city 🍽';

  @override
  String get demoMoodyResponseSocial => 'Looking for fun? I\'ve got you! 👥';

  @override
  String get demoMoodyResponseDefault => 'Nice! Let\'s go explore ✨';

  @override
  String get demoMoodAdventurous => 'Adventurous';

  @override
  String get demoMoodRelaxed => 'Relaxed';

  @override
  String get demoMoodRomantic => 'Romantic';

  @override
  String get demoMoodCultural => 'Cultural';

  @override
  String get demoMoodFoodie => 'Foodie';

  @override
  String get demoMoodSocial => 'Social';

  @override
  String get demoExploreMore => 'Explore More';

  @override
  String get demoMode => 'Demo Mode';

  @override
  String get demoMoodyName => 'Moody';

  @override
  String get demoTapToSelectMood => 'Tap to select your mood:';

  @override
  String get demoReadyToSignUp => 'Ready to sign up? Start now →';

  @override
  String get guestExplorePlaces => 'Explore Places';

  @override
  String get guestPreviewMode => 'Preview mode • Limited features';

  @override
  String get guestGuest => 'Guest';

  @override
  String get guestSignUpFree => 'Sign Up Free';

  @override
  String get guestLovingWhatYouSee => 'Loving what you see?';

  @override
  String get guestSignUpSaveFavorites =>
      'Sign up to save favorites & create plans';

  @override
  String get guestSignUp => 'Sign Up';

  @override
  String get guestSignUpToSaveFavorites => 'Sign up to save your favorites!';

  @override
  String get guestNoPlacesMatchFilters => 'No places match these filters';

  @override
  String get guestTryDifferentCategory => 'Try a different category';

  @override
  String get guestMoodySays => 'Moody says...';

  @override
  String get guestGreatChoice => 'Great choice for your mood today!';

  @override
  String get guestSignUpToUnlock => 'Sign up to unlock';

  @override
  String get guestSignUpUnlockDescription =>
      'Save favorites, create plans, and get personalized recommendations';

  @override
  String get guestSignUpFreeSparkle => 'Sign Up Free ✨';

  @override
  String get guestExploringLikePro => 'You\'re exploring like a pro!';

  @override
  String get guestReadyToSaveFavorites =>
      'Ready to save your favorites and create personalized day plans?';

  @override
  String get guestMaybeLater => 'Maybe later';

  @override
  String get guestFilterHalal => 'Halal';

  @override
  String get guestFilterBlackOwned => 'Black-owned';

  @override
  String get guestFilterAesthetic => 'Aesthetic';

  @override
  String get guestFilterLgbtq => 'LGBTQ+';

  @override
  String get guestFilterVegan => 'Vegan';

  @override
  String get guestFilterVegetarian => 'Vegetarian';

  @override
  String get guestFilterWheelchair => 'Wheelchair';

  @override
  String get guestCategoryAll => 'All';

  @override
  String get guestCategoryRestaurants => 'Restaurants';

  @override
  String get guestCategoryCafes => 'Cafés';

  @override
  String get guestCategoryParks => 'Parks';

  @override
  String get guestCategoryMuseums => 'Museums';

  @override
  String get guestCategoryNightlife => 'Nightlife';

  @override
  String get demoActTitleMountainTrailHike => 'Mountain Trail Hike';

  @override
  String get demoActTitleCityBikeTour => 'City Bike Tour';

  @override
  String get demoActTitleIndoorClimbing => 'Indoor Climbing';

  @override
  String get demoActTitleCozyCornerCafe => 'Cozy Corner Café';

  @override
  String get demoActTitleBotanicalGarden => 'Botanical Garden';

  @override
  String get demoActTitleWellnessSpa => 'Wellness Spa';

  @override
  String get demoActTitleSunsetViewpoint => 'Sunset Viewpoint';

  @override
  String get demoActTitleWineAndDine => 'Wine & Dine';

  @override
  String get demoActTitleRoseGardenWalk => 'Rose Garden Walk';

  @override
  String get demoActTitleHistoryMuseum => 'History Museum';

  @override
  String get demoActTitleLocalTheater => 'Local Theater';

  @override
  String get demoActTitleArtGallery => 'Art Gallery';

  @override
  String get demoActTitleLocalFavorite => 'Local Favorite';

  @override
  String get demoActTitleCozyCafe => 'Cozy Café';

  @override
  String get demoActTitleWineBar => 'Wine Bar';

  @override
  String get demoActTitleRooftopBar => 'Rooftop Bar';

  @override
  String get demoActTitleArcadeLounge => 'Arcade Lounge';

  @override
  String get demoActTitleLiveMusicSpot => 'Live Music Spot';

  @override
  String get demoActTitlePopularSpot => 'Popular Spot';

  @override
  String get demoActTitleFunActivity => 'Fun Activity';

  @override
  String get demoActSubScenic32 => 'Scenic adventure • 3.2 km away';

  @override
  String get demoActSubActive18 => 'Active exploration • 1.8 km away';

  @override
  String get demoActSubThrilling25 => 'Thrilling experience • 2.5 km away';

  @override
  String get demoActSubUnwinding08 => 'Perfect for unwinding • 0.8 km away';

  @override
  String get demoActSubPeaceful21 => 'Peaceful escape • 2.1 km away';

  @override
  String get demoActSubRelaxation34 => 'Total relaxation • 3.4 km away';

  @override
  String get demoActSubMagical15 => 'Magical atmosphere • 1.5 km away';

  @override
  String get demoActSubIntimate09 => 'Intimate setting • 0.9 km away';

  @override
  String get demoActSubStroll23 => 'Beautiful stroll • 2.3 km away';

  @override
  String get demoActSubExhibits12 => 'Fascinating exhibits • 1.2 km away';

  @override
  String get demoActSubLive18 => 'Live performances • 1.8 km away';

  @override
  String get demoActSubContemporary07 => 'Contemporary art • 0.7 km away';

  @override
  String get demoActSubTopReviewed05 => 'Top reviewed • 0.5 km away';

  @override
  String get demoActSubBrunch09 => 'Great brunch • 0.9 km away';

  @override
  String get demoActSubSmallPlates12 => 'Small plates • 1.2 km away';

  @override
  String get demoActSubVibes11 => 'Atmosphere & views • 1.1 km away';

  @override
  String get demoActSubGames07 => 'Games & drinks • 0.7 km away';

  @override
  String get demoActSubTonightsGig15 => 'Tonight\'s gig • 1.5 km away';

  @override
  String get demoActSubHighlyRated10 => 'Highly rated • 1.0 km away';

  @override
  String get demoActSubGreatToday15 => 'Great for today • 1.5 km away';

  @override
  String get demoActSubTopReviewed08 => 'Top reviewed • 0.8 km away';

  @override
  String get guestPlaceNameCozyCorner => 'The Cozy Corner';

  @override
  String get guestPlaceNameSunsetTerrace => 'Sunset Terrace';

  @override
  String get guestPlaceNameCityArtMuseum => 'City Art Museum';

  @override
  String get guestPlaceNameGreenPark => 'Green Park';

  @override
  String get guestPlaceNameJazzLounge => 'Jazz Lounge';

  @override
  String get guestPlaceNameRooftopBar => 'Rooftop Bar';

  @override
  String get guestPlaceNameFreshKitchen => 'Fresh Kitchen';

  @override
  String get guestPlaceNameHistoryMuseum => 'History Museum';

  @override
  String get guestPlaceNameSpiceRoute => 'Spice Route';

  @override
  String get guestPlaceNameSoulKitchen => 'Soul Kitchen';

  @override
  String get guestPlaceNameStudioCafe => 'Studio Café';

  @override
  String get guestPlaceDescCozyCorner =>
      'A warm neighbourhood café with specialty coffee and fresh pastries.';

  @override
  String get guestPlaceDescSunsetTerrace =>
      'Terrace dining with a view and a relaxed evening atmosphere.';

  @override
  String get guestPlaceDescCityArtMuseum =>
      'Modern art and rotating exhibitions in a striking building.';

  @override
  String get guestPlaceDescGreenPark =>
      'Lush green space perfect for a stroll or a picnic.';

  @override
  String get guestPlaceDescJazzLounge =>
      'Live jazz, craft cocktails, and a moody interior.';

  @override
  String get guestPlaceDescRooftopBar =>
      'Skyline views and cocktails at golden hour.';

  @override
  String get guestPlaceDescFreshKitchen =>
      'Healthy, colourful bowls and fresh ingredients.';

  @override
  String get guestPlaceDescHistoryMuseum =>
      'Local history and heritage in a grand historic building.';

  @override
  String get guestPlaceDescSpiceRoute =>
      'Halal-friendly flavours and generous portions.';

  @override
  String get guestPlaceDescSoulKitchen =>
      'Comfort food and live music in a welcoming space.';

  @override
  String get guestPlaceDescStudioCafe =>
      'Minimal interior and great light for working or meeting.';

  @override
  String get guestOpenNow => 'Open now';

  @override
  String get guestClosed => 'Closed';

  @override
  String get guestFree => 'Free';

  @override
  String get guestPaid => 'Paid';

  @override
  String guestDistanceAway(String distance) {
    return '$distance away';
  }

  @override
  String get guestHours => 'Hours';

  @override
  String get signupJoinWanderMood => 'Want this every day?';

  @override
  String get signupSubtitle =>
      'Enter your email to get started.\nNo password needed!';

  @override
  String get signupEmailLabel => 'Email';

  @override
  String get signupEmailHint => 'you@example.com';

  @override
  String get signupEmailRequired => 'Please enter your email';

  @override
  String get signupEmailInvalid => 'Please enter a valid email';

  @override
  String get signupSendMagicLink => 'Send my link';

  @override
  String get signupErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get signupWhatYouGet => 'What you\'ll get';

  @override
  String get signupBenefitPersonalized => 'Personalized recommendations';

  @override
  String get signupBenefitFavorites => 'Save your favorite places';

  @override
  String get signupBenefitDayPlans => 'Create custom day plans';

  @override
  String get signupBenefitMoodMatching => 'Mood-based activity matching';

  @override
  String get signupTerms =>
      'By continuing, you agree to our Terms of Service and Privacy Policy';

  @override
  String get signupCheckEmail => 'Check your email!';

  @override
  String get signupWeSentLinkTo => 'We sent a magic link to';

  @override
  String get signupClickLinkInEmail => 'Click the link in the email to sign in';

  @override
  String get signupLinkExpires => 'The link expires in 24 hours';

  @override
  String get signupCheckSpam => 'Check spam folder if not in inbox';

  @override
  String get signupTryAgain => 'Didn\'t receive email? Try again';

  @override
  String signupAlmostThere(String city) {
    return 'You\'re almost there! One click away from discovering amazing mood-based adventures in $city ✨';
  }

  @override
  String get signupAlmostThereTitle => 'You\'re almost there!';

  @override
  String signupAlmostThereBody(String city) {
    return 'One click away from discovering amazing mood-based adventures in $city ✨';
  }

  @override
  String signupJoinTravelersInCity(String count, String city) {
    return 'Join $count travelers in $city!';
  }

  @override
  String signupJoinTravelers(String count) {
    return 'Join $count travelers!';
  }

  @override
  String get signupWhatYouUnlock => 'What you\'ll unlock';

  @override
  String get signupUnlockPersonalized => 'Personalized recommendations';

  @override
  String get signupUnlockFavorites => 'Save your favorite places';

  @override
  String get signupUnlockDayPlans => 'Create custom day plans';

  @override
  String get signupUnlockMoodMatching => 'Mood-based activity matching';

  @override
  String get signupRating => '4.9/5 Rating';

  @override
  String get signupLoveIt => '98% Love It';

  @override
  String get signupTestimonial =>
      'WanderMood helped me discover places I never knew existed!';

  @override
  String signupTestimonialBy(String city) {
    return '– Sarah, $city';
  }

  @override
  String get signupDefaultCity => 'Rotterdam';

  @override
  String get profileSnackAvatarUpdated => 'Profile picture updated!';

  @override
  String profileSnackAvatarFailed(String error) {
    return 'Failed to update picture: $error';
  }

  @override
  String get profileErrorLoad => 'Could not load profile';

  @override
  String get profileRetry => 'Retry';

  @override
  String get profileFallbackUser => 'User';

  @override
  String get profileStatsTitle => 'Your Stats';

  @override
  String get profileStatsCheckinsTitle => 'Check-ins';

  @override
  String get profileStatsPlacesTitle => 'Places';

  @override
  String get profileStatsPlacesSubtitle => 'Tap to explore';

  @override
  String get profileStatsTopMoodTitle => 'Top Mood';

  @override
  String get profileStatsStreakTitle => 'Streak';

  @override
  String profileStatsStreakSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days streak',
      one: 'day streak',
    );
    return '$_temp0';
  }

  @override
  String get profileTopMoodEmpty => 'None yet';

  @override
  String get profileSavedPlacesTitle => 'Saved places';

  @override
  String get profileSavedPlacesSeeAll => 'See all';

  @override
  String get profileSavedPlacesEmpty => 'No saved places yet';

  @override
  String get profileEditProfileButton => 'Edit profile';

  @override
  String get profileAppSettingsLink => 'App settings';

  @override
  String get profileFavoriteVibesTitle => 'Your Favorite Vibes';

  @override
  String get profileFavoriteVibesSubtitle =>
      'Helps Moody tune suggestions to how you like to feel when you’re out.';

  @override
  String get profileFavoriteVibesEdit => 'Edit';

  @override
  String get profileFavoriteVibesAdd => '+ Add Vibe';

  @override
  String get profileMoodJourneyTitle => 'Your Mood Journey';

  @override
  String get profileMoodJourneySubtitle => 'View your mood history';

  @override
  String get moodHistoryIntro => 'Your recent check-ins.';

  @override
  String get moodHistoryScreenSubtitle =>
      'Mood check-ins and notes, newest first.';

  @override
  String get moodHistorySectionRecent => 'Recent';

  @override
  String get moodHistorySectionTimeline => 'Timeline';

  @override
  String get moodHistoryEmptyTitle => 'Your journey starts here';

  @override
  String get moodHistoryEmptyBody =>
      'Log a mood from Moody or My Day to build your streak.';

  @override
  String get moodHistoryEmptyTimelineHint =>
      'Each mood you log becomes a step on this path — your timeline grows here.';

  @override
  String get moodHistoryEmptyPrimaryCta => 'Log a mood in Moody';

  @override
  String get moodHistoryLoginRequired => 'Sign in to see your mood journey.';

  @override
  String get moodHistoryErrorUser =>
      'Something went wrong loading your account.';

  @override
  String get moodHistoryErrorMoods => 'Something went wrong loading moods.';

  @override
  String get moodHistoryTodayBadge => 'Today';

  @override
  String get moodHistoryDayToday => 'Today';

  @override
  String get moodHistoryDayYesterday => 'Yesterday';

  @override
  String get profileTravelGlobeTitle => 'Your Travel Globe';

  @override
  String get profileTravelGlobeSubtitle => 'Explore your travel journey';

  @override
  String get profilePreferencesTitle => 'Your Preferences';

  @override
  String get profilePreferencesEditAll => 'Edit All';

  @override
  String get profilePreferencesNoneSet => 'No preferences set yet.';

  @override
  String get profileSnackLocalModeSaved => 'Local mode saved';

  @override
  String get profileSnackTravelingModeSaved => 'Travel mode saved';

  @override
  String get profilePreferencesBudgetStyle => 'Budget Style';

  @override
  String get profilePreferencesSocialVibe => 'Social Vibe';

  @override
  String get profilePreferencesFoodPreferences => 'Food Preferences';

  @override
  String get profilePreferencesEmptyHint =>
      'Tap \"Edit All\" to set your preferences';

  @override
  String get profilePreferencesFilledHint =>
      'These preferences subtly guide which places and plans fit you best.';

  @override
  String get profilePreferencesEmptyDescription =>
      'Fill in your preferences so WanderMood can better align with your style.';

  @override
  String get profileSectionWorldTitle => 'Your World';

  @override
  String get profileSectionWorldSubtitle =>
      'Places you save, moods you track, and the story of your travels.';

  @override
  String get profileSectionPreferencesSubtitle =>
      'Style, pace, and how you like to travel.';

  @override
  String get profileSavedPlacesSubtitle =>
      'Places you want to easily find back later.';

  @override
  String get profileSavedPlacesEmptyHint =>
      'You have no saved places yet. Save a few favorites so your profile feels more like your travel map.';

  @override
  String get profileSavedPlacesCarouselEmpty =>
      'No saves yet — tap ♥ on a place to bookmark it.';

  @override
  String get profileBioEmptyHint => 'Add a short bio in Edit profile.';

  @override
  String get profileStatsTopMoodEmpty => 'Still discovering';

  @override
  String get profileStatsSavePlacesHint =>
      'Start saving places that match your mood.';

  @override
  String get profileStatsSavedPlacesReady =>
      'Your saved spots are ready whenever you need inspiration.';

  @override
  String get profileFavoriteVibesEmptyDescription =>
      'Choose a few vibes so Moody quickly understands what you’re really looking for.';

  @override
  String get profileFavoriteVibesFilledDescription =>
      'These vibes help WanderMood determine which places and plans suit you best.';

  @override
  String get profileFavoriteVibesEmptyHint => 'Add vibes';

  @override
  String get profileVibesProTipsTitle => '💡 Pro Tips';

  @override
  String get profileVibesProTipsBody =>
      '• Be honest about what you enjoy — better recommendations!\n• You can change these anytime\n• Mix different vibes for varied suggestions';

  @override
  String get profileModeLocalCardDescription =>
      'WanderMood keeps your suggestions closer to home and aligned with your regular rhythm.';

  @override
  String get profileModeTravelCardDescription =>
      'WanderMood thinks more like a travel companion and sends you to new places to discover.';

  @override
  String get profileActionEdit => 'Edit';

  @override
  String get profileActionShare => 'Share';

  @override
  String get profileGenderWoman => 'Woman';

  @override
  String get profileGenderMan => 'Man';

  @override
  String get profileGenderNonBinary => 'Non-binary';

  @override
  String get profileGenderPreferNotToSay => 'Prefer not to say';

  @override
  String get profileEditGenderLabel => 'How do you identify?';

  @override
  String get profileAgeGroup20s => '20s Adventurer';

  @override
  String get profileAgeGroup30s => '30s Adventurer';

  @override
  String get profileAgeGroup40s => '40s Adventurer';

  @override
  String get profileAgeGroup50s => '50s Adventurer';

  @override
  String get profileAgeGroup55Plus => '55+ Adventurer';

  @override
  String profileAgeGroupGenericSuffix(String ageGroup) {
    return '$ageGroup Adventurer';
  }

  @override
  String get profileBudgetLow => '\$ Budget';

  @override
  String get profileBudgetMid => '\$\$ Moderate';

  @override
  String get profileBudgetHigh => '\$\$\$ Luxury';

  @override
  String get profileSocialSolo => 'Solo';

  @override
  String get profileSocialCouple => 'Couple';

  @override
  String get profileSocialGroup => 'Group';

  @override
  String get profileSocialMix => 'Mix';

  @override
  String get profileSocialSocial => 'Social';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileEditProfilePhoto => 'Profile Photo';

  @override
  String get profileEditProfilePhotoTap => 'Tap to change';

  @override
  String get profileEditNameLabel => 'Full Name';

  @override
  String get profileEditUsernameLabel => 'Username *';

  @override
  String get profileEditUsernameRequiredError => 'Username is required.';

  @override
  String get profileEditUsernameFormatError =>
      'Use 3–30 characters: letters, numbers, or underscores only.';

  @override
  String get profileEditUsernameTakenError =>
      'That username is already taken. Try another.';

  @override
  String get profileEditEmailLabel => 'Email';

  @override
  String get profileEditBioLabel => 'Bio';

  @override
  String get profileEditSelectDate => 'Select date';

  @override
  String get profileEditUsernameHint => 'username';

  @override
  String get profileEditEmailHint => 'email@example.com';

  @override
  String get profileEditNameHint => 'Enter your name';

  @override
  String get profileEditBioHint => 'Tell us about yourself...';

  @override
  String get profileEditLocationLabel => 'Location';

  @override
  String get profileEditLocationHint => 'City, Country';

  @override
  String get profileEditBirthdayLabel => 'Birthday';

  @override
  String get profileEditSave => 'Save';

  @override
  String get profileEditNoChanges => 'No Changes';

  @override
  String get profileEditFavoriteVibesTitle => 'Favorite Vibes';

  @override
  String get profileEditFavoriteVibesEdit => 'Edit';

  @override
  String get profileEditFavoriteVibesSubtitle =>
      'Select your favorite vibes to personalize your recommendations';

  @override
  String get profileEditPhotoTake => 'Take Photo';

  @override
  String get profileEditPhotoChoose => 'Choose from Gallery';

  @override
  String get profileEditPhotoRemove => 'Remove Photo';

  @override
  String get profileEditVibesTitle => 'Edit Favorite Vibes';

  @override
  String get profileEditVibesDone => 'Done';

  @override
  String get profileEditUpdated => 'Profile updated successfully';

  @override
  String profileEditUpdateFailed(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String profileEditErrorLoading(String error) {
    return 'Error loading profile: $error';
  }

  @override
  String get profileEditUnsavedTitle => 'Discard changes?';

  @override
  String get profileEditUnsavedMessage =>
      'You have unsaved edits. If you leave now, your changes will be lost.';

  @override
  String get profileEditDiscard => 'Discard';

  @override
  String get profileEditKeepEditing => 'Keep editing';

  @override
  String get profileVibesUpdated => 'Vibes updated! 🎉';

  @override
  String profileVibesSaveFailed(String error) {
    return 'Failed to save vibes: $error';
  }

  @override
  String get profileVibesEditTitle => 'Edit Favorite Vibes';

  @override
  String get profileVibesSave => 'Save';

  @override
  String profileVibesSelectedCount(String count) {
    return 'Selected ($count/5)';
  }

  @override
  String get profileVibesMaxReached => 'Maximum reached';

  @override
  String get profileVibesChooseTitle => 'Choose Your Vibes';

  @override
  String get profileVibesAddMore => 'Add More Vibes';

  @override
  String get profileVibesSubtitle =>
      'Select up to 5 vibes that match your personality. We\'ll use these to personalize your recommendations!';

  @override
  String get profileVibesCurrentTitle => 'YOUR CURRENT VIBES';

  @override
  String get profileEditPhotoOverlayLabel => 'Change';

  @override
  String get profileEditLocationHintExamples => 'e.g. Rotterdam, Amsterdam...';

  @override
  String get preferencesScreenTitle => 'Edit preferences';

  @override
  String get prefSectionCommunicationStyle => 'Communication style';

  @override
  String get prefSectionInterests => 'Your Interests';

  @override
  String get prefSectionSocialVibe => 'Social Vibe';

  @override
  String get prefSectionTravelStyles => 'Travel styles';

  @override
  String get prefSectionFavoriteMoods => 'Favorite moods';

  @override
  String get prefSectionPlanningPace => 'Planning Pace ⏰';

  @override
  String get prefSectionSelectedMoods => 'Selected moods';

  @override
  String get prefSectionDietaryInclusion => 'Dietary & inclusion';

  @override
  String get prefDietaryInclusionSubtitle =>
      'Moody uses these for recommendations across the app. Select any that apply.';

  @override
  String get prefCommFriendly => 'Friendly';

  @override
  String get prefCommPlayful => 'Playful';

  @override
  String get prefCommCalm => 'Calm';

  @override
  String get prefCommPractical => 'Practical';

  @override
  String get prefIntFood => 'Food';

  @override
  String get prefIntCulture => 'Culture';

  @override
  String get prefIntNature => 'Nature';

  @override
  String get prefIntNightlife => 'Nightlife';

  @override
  String get prefIntShopping => 'Shopping';

  @override
  String get prefIntWellness => 'Wellness';

  @override
  String get prefSocSolo => 'Solo';

  @override
  String get prefSocSmallGroup => 'Small-group';

  @override
  String get prefSocMix => 'Mix';

  @override
  String get prefSocSocial => 'Social';

  @override
  String get prefTravelRelaxed => 'Relaxed';

  @override
  String get prefTravelAdventurous => 'Adventurous';

  @override
  String get prefTravelCultural => 'Cultural';

  @override
  String get prefTravelCityBreak => 'City-break';

  @override
  String get prefFavHappy => 'Happy';

  @override
  String get prefFavAdventurous => 'Adventurous';

  @override
  String get prefFavCalm => 'Calm';

  @override
  String get prefFavRomantic => 'Romantic';

  @override
  String get prefFavEnergetic => 'Energetic';

  @override
  String get prefPlanSameDay => 'Same Day Planner';

  @override
  String get prefPlanWeekAhead => 'Week Ahead Planner';

  @override
  String get prefPlanSpontaneous => 'Spontaneous';

  @override
  String get prefSelHappy => 'Happy';

  @override
  String get prefSelRelaxed => 'Relaxed';

  @override
  String get prefSelCultural => 'Cultural';

  @override
  String get prefSelRomantic => 'Romantic';

  @override
  String get prefSelEnergetic => 'Energetic';

  @override
  String get prefSelCreative => 'Creative';

  @override
  String get profileVibeAdventurousName => 'Adventurous';

  @override
  String get profileVibeAdventurousDesc =>
      'Thrilling activities & outdoor adventures';

  @override
  String get profileVibeChillName => 'Chill';

  @override
  String get profileVibeChillDesc => 'Relaxed, laid-back experiences';

  @override
  String get profileVibeFoodieName => 'Foodie';

  @override
  String get profileVibeFoodieDesc => 'Culinary experiences & dining';

  @override
  String get profileVibeSocialName => 'Social';

  @override
  String get profileVibeSocialDesc => 'Meeting people & social events';

  @override
  String get profileVibeCulturalName => 'Cultural';

  @override
  String get profileVibeCulturalDesc => 'Museums, art & history';

  @override
  String get profileVibeNatureName => 'Nature';

  @override
  String get profileVibeNatureDesc => 'Parks, gardens & outdoors';

  @override
  String get profileVibeRomanticName => 'Romantic';

  @override
  String get profileVibeRomanticDesc => 'Date nights & romantic spots';

  @override
  String get profileVibeWellnessName => 'Wellness';

  @override
  String get profileVibeWellnessDesc => 'Spas, yoga & self-care';

  @override
  String get profileVibeNightlifeName => 'Nightlife';

  @override
  String get profileVibeNightlifeDesc => 'Bars, clubs & evening fun';

  @override
  String get profileVibeShoppingName => 'Shopping';

  @override
  String get profileVibeShoppingDesc => 'Markets, boutiques & malls';

  @override
  String get profileVibeCreativeName => 'Creative';

  @override
  String get profileVibeCreativeDesc => 'Art studios & creative spaces';

  @override
  String get profileVibeSportyName => 'Sporty';

  @override
  String get profileVibeSportyDesc => 'Sports & fitness activities';

  @override
  String get profileGlobeYourJourney => 'Your Journey';

  @override
  String get profileGlobeDemoHint => 'Demo — tap a marker!';

  @override
  String profileGlobePlacesVisitedCount(String count) {
    return '$count places visited';
  }

  @override
  String get profileGlobeBadgeDemo => 'Demo';

  @override
  String get profileGlobeControlRotate => 'Rotate';

  @override
  String get profileGlobeControlPause => 'Pause';

  @override
  String get profileGlobeControlReset => 'Reset';

  @override
  String get profileGlobeUnknownMood => 'Unknown';

  @override
  String get shareProfileTitle => 'Share Profile';

  @override
  String shareProfileShareTextMy(String url) {
    return 'Check out my profile on WanderMood! 🧳✨\n\n$url';
  }

  @override
  String shareProfileShareTextNamed(String name, String url) {
    return 'Check out $name\'s profile on WanderMood! 🧳✨\n\n$url';
  }

  @override
  String get shareProfileMy => 'my';

  @override
  String get shareProfileDefaultUsername => 'wanderer';

  @override
  String get shareProfileEmailSubject => 'Check out my WanderMood profile';

  @override
  String shareProfileFailedToShare(String error) {
    return 'Failed to share: $error';
  }

  @override
  String get shareProfileDefaultBio => 'Always chasing sunsets & good vibes ✨';

  @override
  String get shareProfileDayStreak => 'Day Streak';

  @override
  String get shareProfileQRCode => 'QR Code';

  @override
  String get shareProfileScanToConnect => 'Scan to connect';

  @override
  String get shareProfileCopyLink => 'Copy Link';

  @override
  String get shareProfileShareAnywhere => 'Share anywhere';

  @override
  String get shareProfileShareVia => 'Share via';

  @override
  String get shareProfileInstagram => 'Instagram';

  @override
  String get shareProfileWhatsApp => 'WhatsApp';

  @override
  String get shareProfileTwitter => 'Twitter';

  @override
  String get shareProfileEmail => 'Email';

  @override
  String get shareProfilePublicProfile => 'Public Profile';

  @override
  String get shareProfileAnyoneCanView => 'Anyone can view your profile';

  @override
  String shareProfileUpdateFailed(String error) {
    return 'Failed to update: $error';
  }

  @override
  String get shareProfileMyQRCode => 'My QR Code';

  @override
  String get shareProfileHowItWorks => 'How it works';

  @override
  String get shareProfileQRInstructions =>
      'Ask someone to scan this code with their WanderMood app to instantly connect and share your profile!';

  @override
  String get shareProfileDownloaded => 'Downloaded!';

  @override
  String get shareProfileSaveQRCode => 'Save QR Code';

  @override
  String shareProfileShareMessage(String url) {
    return 'Check out my WanderMood profile! $url';
  }

  @override
  String get shareProfileShareQRImage => 'Share QR Image';

  @override
  String get shareProfileShareLinkTitle => 'Share Link';

  @override
  String get shareProfileYourProfileLink => 'YOUR PROFILE LINK';

  @override
  String get shareProfileLinkCopied => 'Link Copied!';

  @override
  String get shareProfileQuickShare => 'QUICK SHARE';

  @override
  String get shareProfileLinkInfo =>
      'Anyone with this link can view your public profile. You can change your privacy settings anytime.';

  @override
  String get drawerYourJourney => 'Your Journey';

  @override
  String get drawerNavigation => 'Navigation';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerAccount => 'Account';

  @override
  String get drawerMoodHistory => 'Mood History';

  @override
  String get drawerSavedPlaces => 'Saved Places';

  @override
  String get drawerMyAgenda => 'My Plans';

  @override
  String get drawerMyBookings => 'My Bookings';

  @override
  String get drawerAppSettings => 'App Settings';

  @override
  String get drawerNotifications => 'Notifications';

  @override
  String get drawerLanguage => 'Language';

  @override
  String get drawerHelpSupport => 'Help & Support';

  @override
  String get drawerProfile => 'Profile';

  @override
  String get drawerLogOut => 'Log Out';

  @override
  String get drawerErrorLoadingProfile => 'Error loading profile';

  @override
  String drawerErrorSigningOut(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get drawerNewExplorer => 'New Explorer';

  @override
  String get drawerMasterWanderer => 'Master Wanderer';

  @override
  String get drawerAdventureExpert => 'Adventure Expert';

  @override
  String get drawerSeasonedExplorer => 'Seasoned Explorer';

  @override
  String get drawerTravelEnthusiast => 'Travel Enthusiast';

  @override
  String get profileModeLocal => 'Local Mode';

  @override
  String get profileModeTravel => 'Traveling';

  @override
  String get profileModeWhatDoesThisDo => 'What does this do?';

  @override
  String get profileModeSwitchToLocal => 'Switch to Local Mode';

  @override
  String get profileModeSwitchToTravel => 'Switch to Travel Mode';

  @override
  String get profileModeCancel => 'Cancel';

  @override
  String get profileModeChangeAnytime => 'You can change this anytime';

  @override
  String get profileModeUpdated => 'Mode Updated!';

  @override
  String get profileModeUpdating => 'Your recommendations are updating...';

  @override
  String get profileModeTravelModesExplained => 'Travel Modes Explained';

  @override
  String get profileModeLocalTitle => 'Local Mode';

  @override
  String get profileModeLocalDescription =>
      'Discovering hidden gems in your neighborhood';

  @override
  String get profileModeLocalFeature1 => 'Local cafes & hidden spots';

  @override
  String get profileModeLocalFeature2 => 'Neighborhood favorites';

  @override
  String get profileModeLocalFeature3 => 'Less touristy places';

  @override
  String get profileModeTravelTitle => 'Travel Mode';

  @override
  String get profileModeTravelDescription =>
      'Explore must-see attractions as a traveler';

  @override
  String get profileModeTravelFeature1 => 'Famous landmarks';

  @override
  String get profileModeTravelFeature2 => 'Must-see attractions';

  @override
  String get profileModeTravelFeature3 => 'Tourist-friendly spots';

  @override
  String get profileModeLocalExplainer =>
      'Perfect for when you\'re at home or exploring your own city. Discover places locals love!';

  @override
  String get profileModeLocalExample =>
      'Example: Instead of the Eiffel Tower, you\'ll see the cozy boulangerie around the corner that Parisians actually go to.';

  @override
  String get profileModeTravelExplainer =>
      'Perfect for when you\'re traveling or visiting a new city. See all the iconic spots!';

  @override
  String get profileModeTravelExample =>
      'Example: In Paris, you\'ll see the Eiffel Tower, Louvre Museum, and Arc de Triomphe - all the classics!';

  @override
  String get profileModeSwitchAnytime =>
      'Switch between modes anytime! Going on vacation? Switch to Travel Mode. Back home? Switch to Local Mode. Your recommendations adapt instantly!';

  @override
  String get profileModeGotIt => 'Got it!';

  @override
  String get profileModeProTip => 'Pro Tip';

  @override
  String get profileModeLocalGem1 => 'Hidden neighborhood gems';

  @override
  String get profileModeLocalGem2 => 'Local cafes & restaurants';

  @override
  String get profileModeLocalGem3 => 'Less crowded spots';

  @override
  String get profileModeLocalGem4 => 'Authentic local experiences';

  @override
  String get profileModeTravelSpot1 => 'Famous landmarks & attractions';

  @override
  String get profileModeTravelSpot2 => 'Must-see tourist spots';

  @override
  String get profileModeTravelSpot3 => 'Popular destinations';

  @override
  String get profileModeTravelSpot4 => 'Tourist-friendly locations';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionDiscovery => 'Discovery';

  @override
  String get settingsSectionDataPrivacy => 'Data & Privacy';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Enable push notifications';

  @override
  String get settingsLocationTrackingTitle => 'Location Tracking';

  @override
  String get settingsLocationTrackingSubtitle =>
      'Allow app to track your location';

  @override
  String get settingsDarkModeTitle => 'Dark Mode';

  @override
  String get settingsDarkModeSubtitle => 'Use dark theme throughout the app';

  @override
  String get settingsDiscoveryRadiusTitle => 'Discovery Radius';

  @override
  String settingsDiscoveryRadiusSubtitle(String distance) {
    return 'Show places within $distance km';
  }

  @override
  String get settingsClearCacheTitle => 'Clear App Cache';

  @override
  String get settingsClearCacheSubtitle =>
      'Free up space by removing cached images and data';

  @override
  String get settingsPrivacyPolicyTitle => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicySubtitle => 'Read our privacy policy';

  @override
  String get settingsTermsOfServiceTitle => 'Terms of Service';

  @override
  String get settingsTermsOfServiceSubtitle => 'Read our terms of service';

  @override
  String get settingsSaveButton => 'Save Settings';

  @override
  String get settingsClearCacheDialogTitle => 'Clear Cache?';

  @override
  String get settingsClearCacheDialogBody =>
      'This will remove all cached data. Your saved places and settings will not be affected.';

  @override
  String get settingsDialogCancel => 'Cancel';

  @override
  String get settingsDialogConfirmClear => 'Clear';

  @override
  String get settingsCacheCleared => 'Cache cleared successfully';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsHubTitle => 'Settings';

  @override
  String get settingsQuickTipTitle => 'Quick Tip';

  @override
  String get settingsQuickTipBody =>
      'To edit your profile or preferences, go back to your profile screen!';

  @override
  String get settingsSectionPrivacySecurity => 'Privacy & Security';

  @override
  String get settingsSectionAppSettings => 'App Settings';

  @override
  String get settingsSectionMore => 'More';

  @override
  String get settingsSectionDangerZone => 'Danger Zone';

  @override
  String get settingsAccountSecurityTitle => 'Account Security';

  @override
  String get settingsAccountSecuritySubtitle => 'Password, 2FA';

  @override
  String get settingsTwoFactorTitle => 'Two-Factor Authentication';

  @override
  String get settingsTwoFactorEnabled => 'Enabled';

  @override
  String get settingsTwoFactorNotEnabled => 'Not enabled';

  @override
  String get settingsTwoFactorBadgeRecommended => 'Recommended';

  @override
  String get settingsActiveSessionsTitle => 'Active Sessions';

  @override
  String settingsActiveSessionsSubtitle(String count) {
    return '$count devices';
  }

  @override
  String get activeSessionsNoActiveTitle => 'No active sessions';

  @override
  String get activeSessionsNoActiveBody =>
      'You are not signed in on any devices.';

  @override
  String activeSessionsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count Active Session$_temp0';
  }

  @override
  String get activeSessionsSignOutAllOther => 'Sign Out All Other Devices';

  @override
  String get activeSessionsUnknownDevice => 'Unknown Device';

  @override
  String get activeSessionsCurrentBadge => 'Current';

  @override
  String get activeSessionsUnknownLocation => 'Unknown location';

  @override
  String get activeSessionsSignOutThisDevice => 'Sign out this device';

  @override
  String get activeSessionsErrorLoading => 'Error loading sessions';

  @override
  String get activeSessionsTimeJustNow => 'Just now';

  @override
  String activeSessionsTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count hour$_temp0 ago';
  }

  @override
  String get activeSessionsTimeYesterday => 'Yesterday';

  @override
  String activeSessionsTimeDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String activeSessionsTimeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count week$_temp0 ago';
  }

  @override
  String get activeSessionsDialogSignOutDeviceTitle => 'Sign Out Device';

  @override
  String activeSessionsDialogSignOutDeviceBody(String device) {
    return 'Are you sure you want to sign out from $device?';
  }

  @override
  String get activeSessionsDialogCancel => 'Cancel';

  @override
  String get activeSessionsDialogSignOut => 'Sign Out';

  @override
  String get activeSessionsToastSignedOutDevice =>
      'Device signed out successfully';

  @override
  String activeSessionsToastSignOutDeviceError(String error) {
    return 'Error signing out device: $error';
  }

  @override
  String get activeSessionsDialogSignOutAllTitle =>
      'Sign Out All Other Devices';

  @override
  String get activeSessionsDialogSignOutAllBody =>
      'This will sign you out from all devices except this one. Are you sure?';

  @override
  String get activeSessionsDialogSignOutAllCta => 'Sign Out All';

  @override
  String get activeSessionsToastSignedOutAll =>
      'All other devices signed out successfully';

  @override
  String activeSessionsToastSignOutAllError(String error) {
    return 'Error signing out devices: $error';
  }

  @override
  String get twoFactorTitle => 'Two-Factor Authentication';

  @override
  String get twoFactorEnabledTitle => '2FA is Enabled';

  @override
  String get twoFactorDisabledTitle => 'Enable Two-Factor Authentication';

  @override
  String get twoFactorEnabledBody =>
      'Your account is protected with two-factor authentication.';

  @override
  String get twoFactorDisabledBody =>
      'Add an extra layer of security to your account by requiring a verification code in addition to your password.';

  @override
  String get twoFactorBenefitsTitle => 'Benefits:';

  @override
  String get twoFactorBenefitUnauthorized =>
      'Protects against unauthorized access';

  @override
  String get twoFactorBenefitSensitiveOps =>
      'Required for sensitive operations';

  @override
  String get twoFactorBenefitLoginAlerts => 'Get notified of login attempts';

  @override
  String get twoFactorDisableCta => 'Disable 2FA';

  @override
  String get twoFactorEnableCta => 'Enable 2FA';

  @override
  String get twoFactorDisableInfo =>
      'To disable 2FA, you will need to verify your identity.';

  @override
  String get twoFactorEnableInfo =>
      'You will need an authenticator app (like Google Authenticator) to set up 2FA.';

  @override
  String get twoFactorToastSetupStarted =>
      '2FA setup started. Please complete the setup process.';

  @override
  String get twoFactorToastDisabled => '2FA has been disabled.';

  @override
  String twoFactorToastError(String error) {
    return 'Error: $error';
  }

  @override
  String get settingsPrivacyTitle => 'Privacy';

  @override
  String get settingsPrivacySubtitle => 'Profile visibility, data';

  @override
  String get settingsHubNotificationsSubtitle => 'Push, email, in-app';

  @override
  String get settingsLocationLabel => 'Location';

  @override
  String get settingsLocationSubtitle => 'Auto-detect, permissions';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get settingsThemeValueSystem => 'System';

  @override
  String get settingsAchievementsLabel => 'Achievements';

  @override
  String settingsAchievementsSubtitle(String count) {
    return '$count unlocked';
  }

  @override
  String get settingsSubscriptionLabel => 'Subscription';

  @override
  String get settingsSubscriptionSubtitleFree => 'Free Plan';

  @override
  String get settingsSubscriptionBadgeFree => 'Free';

  @override
  String get settingsDataStorageLabel => 'Data & Storage';

  @override
  String get settingsDataStorageSubtitle => 'Export, clear cache';

  @override
  String get settingsHelpSupportLabel => 'Help & Support';

  @override
  String get settingsHelpSupportSubtitle => 'FAQ, contact us';

  @override
  String get settingsDangerDeleteAccountLabel => 'Delete Account';

  @override
  String get settingsDangerDeleteAccountSubtitle =>
      'Permanently delete your data';

  @override
  String get settingsDangerSignOutLabel => 'Sign Out';

  @override
  String get settingsDangerSignOutSubtitle => 'Log out of your account';

  @override
  String settingsAppVersion(String version) {
    return 'WanderMood v$version';
  }

  @override
  String get settingsAppTagline => 'Made with ❤️ for travelers';

  @override
  String get settingsSignOutTitle => 'Sign Out';

  @override
  String get settingsSignOutMessage => 'Are you sure you want to sign out?';

  @override
  String get settingsSignOutConfirm => 'Sign Out';

  @override
  String get settingsOpenPrivacyNetworkError =>
      'Unable to open Privacy Policy. Please check your internet connection.';

  @override
  String settingsOpenPrivacyError(String error) {
    return 'Error opening Privacy Policy: $error';
  }

  @override
  String get settingsOpenTermsNetworkError =>
      'Unable to open Terms of Service. Please check your internet connection.';

  @override
  String settingsOpenTermsError(String error) {
    return 'Error opening Terms of Service: $error';
  }

  @override
  String get notificationsMethodsTitle => 'Notification Methods';

  @override
  String get notificationsPushTitle => 'Push Notifications';

  @override
  String get notificationsPushSubtitle =>
      'Receive push notifications on this device';

  @override
  String get notificationsEmailTitle => 'Email Notifications';

  @override
  String get notificationsEmailSubtitle => 'Receive updates via email';

  @override
  String get notificationsInAppTitle => 'In-App Notifications';

  @override
  String get notificationsInAppSubtitle => 'See notifications inside the app';

  @override
  String get notificationsWhatToNotifyTitle => 'What to Notify';

  @override
  String get notificationsNewActivitiesTitle => 'New Activities';

  @override
  String get notificationsNewActivitiesSubtitle =>
      'When new activities match your vibe';

  @override
  String get notificationsNearbyEventsTitle => 'Nearby Events';

  @override
  String get notificationsNearbyEventsSubtitle => 'Events happening around you';

  @override
  String get notificationsFriendActivityTitle => 'Friend Activity';

  @override
  String get notificationsFriendActivitySubtitle =>
      'When friends share or like something';

  @override
  String get locationScreenTitle => 'Location';

  @override
  String get locationCurrentLocationTitle => 'Current Location';

  @override
  String get locationCurrentLocationValue => 'Rotterdam, Netherlands';

  @override
  String get locationSectionSettingsTitle => 'Location Settings';

  @override
  String get locationAutoDetectTitle => 'Auto-Detect Location';

  @override
  String get locationAutoDetectSubtitle =>
      'Automatically detect your current location';

  @override
  String get locationSectionDefaultTitle => 'Default Location';

  @override
  String get locationDefaultCityLabel => 'Rotterdam';

  @override
  String get locationDefaultUsedWhenOff => 'Used when location is off';

  @override
  String get locationPermissionsTitle => 'Location Permissions';

  @override
  String get locationPermissionsSubtitle => 'Manage in system settings';

  @override
  String get locationSnackbarUpdated => 'Location settings updated';

  @override
  String locationSnackbarError(String error) {
    return 'Error updating location settings: $error';
  }

  @override
  String get languageUpdated => 'Language updated';

  @override
  String get subscriptionScreenTitle => 'Subscription';

  @override
  String get subscriptionCurrentPlanLabel => 'Current Plan';

  @override
  String get subscriptionPlanFree => 'Free';

  @override
  String get subscriptionPlanPremium => 'Premium';

  @override
  String get subscriptionUpgradeHeading => 'Coming soon';

  @override
  String get subscriptionUpgradeTitle => 'Premium';

  @override
  String get subscriptionFeatureUnlimitedSuggestions =>
      'Unlimited activity suggestions';

  @override
  String get subscriptionFeatureAdvancedMoodMatching =>
      'Advanced mood matching';

  @override
  String get subscriptionFeaturePrioritySupport => 'Priority support';

  @override
  String get subscriptionFeatureNoAds => 'No ads';

  @override
  String get subscriptionFeatureEarlyAccess => 'Early access to new features';

  @override
  String get subscriptionUpgradeCta => 'Learn more';

  @override
  String get subscriptionUpgradeFootnote =>
      'Paid plans will use Apple In-App Purchase when available. This version is free — no payment is collected in the app.';

  @override
  String get dataStorageTitle => 'Data & Storage';

  @override
  String get dataStorageStorageUsedLabel => 'Storage Used';

  @override
  String get dataStorageExportTitle => 'Export My Data';

  @override
  String get dataStorageExportSubtitle => 'Download all your data (GDPR)';

  @override
  String get dataStorageClearCacheTitle => 'Clear Cache';

  @override
  String get dataStorageClearCacheSubtitle => 'Free up storage space';

  @override
  String get dataStorageDownloadHistoryTitle => 'Download History';

  @override
  String get dataStorageDownloadHistorySubtitle => 'View past exports';

  @override
  String get dataStorageExportFileTitle => 'My WanderMood Data Export';

  @override
  String get dataStorageExportSuccess => 'Data exported successfully';

  @override
  String dataStorageExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get dataStorageCacheCleared => 'Cache cleared successfully';

  @override
  String dataStorageCacheFailed(String error) {
    return 'Failed to clear cache: $error';
  }

  @override
  String get helpSupportScreenTitle => 'Help & Support';

  @override
  String get helpSupportSearchHint => 'Search help articles...';

  @override
  String get helpSupportQuickLinksTitle => 'Quick Links';

  @override
  String get helpSupportFaqTitle => 'FAQs';

  @override
  String get helpSupportFaqSubtitle => 'Frequently asked questions';

  @override
  String get helpSupportContactTitle => 'Contact Us';

  @override
  String get helpSupportContactSubtitle => 'Send us an email';

  @override
  String get helpSupportLiveChatTitle => 'Live Chat';

  @override
  String get helpSupportLiveChatSubtitle => 'Chat with support';

  @override
  String get helpSupportLiveChatBadgeOnline => 'Online';

  @override
  String get helpSupportReportBugTitle => 'Report a Bug';

  @override
  String get helpSupportReportBugSubtitle => 'Help us improve';

  @override
  String get helpSupportLegalTitle => 'Legal';

  @override
  String get helpSupportPrivacyTitle => 'Privacy Policy';

  @override
  String get helpSupportPrivacySubtitle => 'How we protect your data';

  @override
  String get helpSupportTermsTitle => 'Terms of Service';

  @override
  String get helpSupportTermsSubtitle => 'Terms and conditions';

  @override
  String get helpSupportEmailAddress => 'info@wandermood.com';

  @override
  String get helpSupportEmailSubject => 'WanderMood Support';

  @override
  String get helpSupportEmailSupportTitle => 'Email support';

  @override
  String get settingsLocationChangeCta => 'Change';

  @override
  String get savedPlacesScreenTitle => 'Saved places';

  @override
  String get savedPlacesTabAllSaved => 'All saved';

  @override
  String get savedPlacesTabCollections => 'Collections';

  @override
  String get savedPlacesEmptyTitle => 'No saved places yet';

  @override
  String get savedPlacesEmptyBody =>
      'Tap the bookmark icon on any place in Explore to save it here.';

  @override
  String get savedPlacesHoldToCollect => 'Hold to collect';

  @override
  String savedPlacesSavedPrefix(String when) {
    return 'Saved $when';
  }

  @override
  String get savedPlacesTimeJustNow => 'just now';

  @override
  String savedPlacesTimeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String get savedPlacesTimeYesterday => 'yesterday';

  @override
  String savedPlacesTimeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String savedPlacesPlaceCountOne(int count) {
    return '$count place';
  }

  @override
  String savedPlacesPlaceCountMany(int count) {
    return '$count places';
  }

  @override
  String get savedPlacesNewCollection => 'New collection';

  @override
  String get savedPlacesNewCollectionSubtitle => 'Group your saves';

  @override
  String get savedPlacesAddToCollectionTitle => 'Add to collection';

  @override
  String get savedPlacesNoCollectionsHint =>
      'No collections yet. Create one in the Collections tab.';

  @override
  String savedPlacesPlacesCount(int count) {
    return '$count places';
  }

  @override
  String savedPlacesAddedToCollection(String name) {
    return 'Added to $name';
  }

  @override
  String get savedPlacesActionAddToMyDay => 'Add to My Day';

  @override
  String get savedPlacesActionAddToCollection => 'Add to collection';

  @override
  String get savedPlacesActionViewDetails => 'View details';

  @override
  String get savedPlacesPlanSheetTitle => 'Add to My Day';

  @override
  String get savedPlacesPickDate => 'Pick date';

  @override
  String savedPlacesSelectedDate(String date) {
    return 'Selected: $date';
  }

  @override
  String get locationPickerTitle => 'Select location';

  @override
  String get locationPickerSearchHint => 'Search for a city or location…';

  @override
  String get locationPickerEmptyPrompt =>
      'Start typing to search for a location';

  @override
  String get locationPickerNoResults => 'No locations found';

  @override
  String locationPickerToastUpdated(String place) {
    return 'Location updated to $place';
  }

  @override
  String locationPickerToastError(String error) {
    return 'Error saving location: $error';
  }

  @override
  String get settingsPrivacyScreenTitle => 'Privacy';

  @override
  String get privacyProfileVisibilitySection => 'Profile visibility';

  @override
  String get privacyVisibilityPublic => 'Public';

  @override
  String get privacyVisibilityPublicSub => 'Anyone can see your profile';

  @override
  String get privacyVisibilityFriends => 'Friends only';

  @override
  String get privacyVisibilityFriendsSub => 'Only your friends can see';

  @override
  String get privacyVisibilityPrivate => 'Private';

  @override
  String get privacyVisibilityPrivateSub => 'Only you can see';

  @override
  String get privacyWhatOthersSeeSection => 'What others can see';

  @override
  String get privacyShowEmailLabel => 'Show email address';

  @override
  String get privacyShowAgeLabel => 'Show age';

  @override
  String get privacyToastVisibilityUpdated => 'Profile visibility updated';

  @override
  String privacyToastError(String error) {
    return 'Error: $error';
  }

  @override
  String get privacyToastEmailVisible => 'Email will be visible to others';

  @override
  String get privacyToastEmailHidden => 'Email is now hidden';

  @override
  String get privacyToastAgeVisible => 'Age will be visible to others';

  @override
  String get privacyToastAgeHidden => 'Age is now hidden';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNativeEn => 'English';

  @override
  String get languageNameNl => 'Dutch';

  @override
  String get languageNativeNl => 'Nederlands';

  @override
  String get languageNameEs => 'Spanish';

  @override
  String get languageNativeEs => 'Español';

  @override
  String get languageNameFr => 'French';

  @override
  String get languageNativeFr => 'Français';

  @override
  String get languageNameDe => 'German';

  @override
  String get languageNativeDe => 'Deutsch';

  @override
  String get languageNameIt => 'Italian';

  @override
  String get languageNativeIt => 'Italiano';

  @override
  String get prefCommunicationTitle => 'How should I talk to you? 💬';

  @override
  String get prefCommunicationIntro =>
      'To make our journey together more enjoyable, I\'d love to know how you prefer me to communicate with you.';

  @override
  String get prefCommunicationSubtitle =>
      'This helps me adjust my tone and style to match your preferences perfectly! 🎯';

  @override
  String get prefStyleFriendly => 'Friendly';

  @override
  String get prefStyleFriendlyDesc => 'Casual and warm communication';

  @override
  String get prefStyleProfessional => 'Professional';

  @override
  String get prefStyleProfessionalDesc => 'Clear and formal communication';

  @override
  String get prefStyleEnergetic => 'Energetic';

  @override
  String get prefStyleEnergeticDesc => 'Fun and enthusiastic communication';

  @override
  String get prefStyleDirect => 'Direct';

  @override
  String get prefStyleDirectDesc => 'Straight to the point';

  @override
  String get prefMoodAdventurous => 'Adventurous';

  @override
  String get prefMoodPeaceful => 'Peaceful';

  @override
  String get prefMoodSocial => 'Social';

  @override
  String get prefMoodCultural => 'Cultural';

  @override
  String get prefMoodFoody => 'Foody';

  @override
  String get prefMoodSpontaneous => 'Spontaneous';

  @override
  String get prefMoodTitleFriendly => 'What\'s your travel mood? 😊';

  @override
  String get prefMoodTitleEnergetic => 'Let\'s sync our vibes! ✨';

  @override
  String get prefMoodTitleProfessional => 'Travel Mood Preferences';

  @override
  String get prefMoodTitleDirect => 'Select your moods';

  @override
  String get prefMoodSubtitleFriendly =>
      'What inspires you to get out and explore?';

  @override
  String get prefMoodSubtitleEnergetic => 'What moods inspire you to explore?';

  @override
  String get prefMoodSubtitleProfessional =>
      'What type of experiences appeal to you most?';

  @override
  String get prefMoodSubtitleDirect =>
      'Choose your preferred experience types:';

  @override
  String get prefMultipleHintFriendly => 'You can select multiple options ✨';

  @override
  String get prefMultipleHintEnergetic => 'You can pick multiple - go wild! ✨';

  @override
  String get prefMultipleHintProfessional =>
      'Multiple selections are permitted';

  @override
  String get prefMultipleHintDirect => 'Multiple selections allowed';

  @override
  String get prefInterestStays => 'Stays & Getaways';

  @override
  String get prefInterestStaysDesc => 'Charming hotels and dreamy places';

  @override
  String get prefInterestFood => 'Food & Drink';

  @override
  String get prefInterestFoodDesc => 'Local cuisine and unique restaurants';

  @override
  String get prefInterestArts => 'Arts & Culture';

  @override
  String get prefInterestArtsDesc => 'Museums, galleries, and theaters';

  @override
  String get prefInterestShopping => 'Shopping';

  @override
  String get prefInterestShoppingDesc => 'Local markets and shopping districts';

  @override
  String get prefInterestSports => 'Sports & Activities';

  @override
  String get prefInterestSportsDesc => 'Active experiences and sports venues';

  @override
  String get prefInterestsTitleFriendly => 'What catches your interest? 🌟';

  @override
  String get prefInterestsTitleEnergetic => 'What gets you hyped? 🔥';

  @override
  String get prefInterestsTitleProfessional => 'Travel Interest Categories';

  @override
  String get prefInterestsTitleDirect => 'Select interests';

  @override
  String get prefInterestsSubtitleFriendly =>
      'Choose the activities that sound fun to you';

  @override
  String get prefInterestsSubtitleEnergetic =>
      'Pick all the things that make your heart race!';

  @override
  String get prefInterestsSubtitleProfessional =>
      'Select your preferred activity categories';

  @override
  String get prefInterestsSubtitleDirect => 'Choose activity types:';

  @override
  String get prefTravelTitleFriendly => 'Tell us about your travel style ✈️';

  @override
  String get prefTravelTitleEnergetic => 'Tell us about your travel style ✈️';

  @override
  String get prefTravelTitleProfessional =>
      'Tell us about your travel style ✈️';

  @override
  String get prefTravelTitleDirect => 'Tell us about your travel style ✈️';

  @override
  String get prefTravelSubtitleFriendly =>
      'A few quick questions to personalize your experience';

  @override
  String get prefTravelSubtitleEnergetic =>
      'A few quick questions to personalize your experience';

  @override
  String get prefTravelSubtitleProfessional =>
      'A few quick questions to personalize your experience';

  @override
  String get prefTravelSubtitleDirect =>
      'A few quick questions to personalize your experience';

  @override
  String get prefSectionTravelStyle => 'Travel Style 🎯';

  @override
  String prefSelectUpToStyles(int count) {
    return 'Select up to $count styles';
  }

  @override
  String get prefSocialSolo => 'Solo Adventures';

  @override
  String get prefSocialSoloDesc => 'Me time is the best time';

  @override
  String get prefSocialSmallGroups => 'Small Groups';

  @override
  String get prefSocialSmallGroupsDesc => 'Close friends, intimate vibes';

  @override
  String get prefSocialButterfly => 'Social Butterfly';

  @override
  String get prefSocialButterflyDesc => 'Love meeting new people';

  @override
  String get prefSocialMoodDependent => 'Mood Dependent';

  @override
  String get prefSocialMoodDependentDesc => 'Sometimes solo, sometimes social';

  @override
  String get prefPaceRightNow => 'Right Now Vibes';

  @override
  String get prefPaceRightNowDesc => 'What should I do right now?';

  @override
  String get prefPaceSameDay => 'Same Day Planner';

  @override
  String get prefPaceSameDayDesc => 'Plan in the morning for the day';

  @override
  String get prefPaceWeekend => 'Weekend Prepper';

  @override
  String get prefPaceWeekendDesc => 'Plan a few days ahead';

  @override
  String get prefPaceMaster => 'Master Planner';

  @override
  String get prefPaceMasterDesc => 'Love planning weeks ahead';

  @override
  String get prefTravelStyleSpontaneous => 'Spontaneous';

  @override
  String get prefTravelStyleSpontaneousDesc =>
      'Go with the flow, embrace surprises';

  @override
  String get prefTravelStylePlanned => 'Planned';

  @override
  String get prefTravelStylePlannedDesc =>
      'Organized itineraries, scheduled visits';

  @override
  String get prefTravelStyleLocal => 'Local Experience';

  @override
  String get prefTravelStyleLocalDesc => 'Live like a local, authentic spots';

  @override
  String get prefTravelStyleLuxury => 'Luxury Seeker';

  @override
  String get prefTravelStyleLuxuryDesc => 'Premium experiences, high-end spots';

  @override
  String get prefTravelStyleBudget => 'Budget Conscious';

  @override
  String get prefTravelStyleBudgetDesc => 'Great value, smart spending';

  @override
  String get prefTravelStyleTouristHighlights => 'Tourist Highlights';

  @override
  String get prefTravelStyleTouristHighlightsDesc =>
      'Must-see attractions, popular spots';

  @override
  String get prefTravelStyleOffBeatenPath => 'Off the Beaten Path';

  @override
  String get prefTravelStyleOffBeatenPathDesc =>
      'Hidden gems, unique experiences';

  @override
  String get dayPlanTodayItinerary => 'TODAY\'S ITINERARY';

  @override
  String get dayPlanBasedOn => 'Your Day Plan based on:';

  @override
  String get dayPlanEditMoods => 'Edit Moods →';

  @override
  String get dayPlanAddToMyDay => 'Add to My Day';

  @override
  String dayPlanAddMoreToMyDay(String count) {
    return 'Add $count more to My Day';
  }

  @override
  String get dayPlanViewMyDay => 'View My Day';

  @override
  String get dayPlanSelectAtLeastOne => 'Add at least one activity to continue';

  @override
  String dayPlanAddAllSuggestions(String count) {
    return 'Add all $count to My Day';
  }

  @override
  String get dayPlanPlanAddedToMyDay => 'Plan added to My Day!';

  @override
  String get dayPlanAddPlanFailed => 'Couldn\'t add plan. Try again.';

  @override
  String get dayPlanAllAlternativesUsed =>
      'You\'ve used all 3 alternative options for this activity!';

  @override
  String dayPlanFindingOptions(String name) {
    return 'Finding new options for $name...';
  }

  @override
  String get dayPlanNoOptionsFound =>
      'No other options found for this time slot. Try a different mood!';

  @override
  String get dayPlanFindOptionsFailed =>
      'Failed to find new options. Please try again later.';

  @override
  String get dayPlanAllOptionsUsed => 'All options used';

  @override
  String get dayPlanNotFeelingThis => 'Not feeling this?';

  @override
  String dayPlanTryAgainLeft(String count) {
    return 'Try again? ($count left)';
  }

  @override
  String get dayPlanMorning => 'MORNING';

  @override
  String get dayPlanAfternoon => 'AFTERNOON';

  @override
  String get dayPlanEvening => 'EVENING';

  @override
  String get dayPlanThemeExploreDiscover => 'Explore & Discover';

  @override
  String get dayPlanThemeTrueLocalFind => 'A True Local Find';

  @override
  String get dayPlanThemeWindDownCulture => 'Wind Down & Culture';

  @override
  String get dayPlanThemeCulturalDeepDive => 'Cultural Deep Dive';

  @override
  String get dayPlanThemeFoodieFind => 'A True \'Foodie\' Find';

  @override
  String get dayPlanThemeSunsetVibes => 'Sunset Vibes & Culture';

  @override
  String get dayPlanThemeWindDownRelax => 'Wind Down & Relax';

  @override
  String get dayPlanThemeAdventureAwaits => 'Adventure Awaits';

  @override
  String get dayPlanThemeOutdoorNature => 'Outdoor & Nature';

  @override
  String get dayPlanThemeCreativeVibes => 'Creative Vibes';

  @override
  String get dayPlanThemeRomanticMoments => 'Romantic Moments';

  @override
  String get dayPlanThemeYourVibe => 'Your Vibe';

  @override
  String get dayPlanCardActivity => 'Activity';

  @override
  String get dayPlanCardFree => 'Free';

  @override
  String get dayPlanCardOpenNow => 'Open now';

  @override
  String get dayPlanCardClosed => 'Closed';

  @override
  String get dayPlanCardNotFeelingThis => 'Not feeling this?';

  @override
  String get dayPlanCardDirections => 'Directions';

  @override
  String get dayPlanCardSeeActivity => 'See activity';

  @override
  String get dayPlanCardUnableToOpenDirections => 'Unable to open directions';

  @override
  String get dayPlanCardFailedToShare => 'Failed to share';

  @override
  String dayPlanCardRemovedFromSaved(String name) {
    return '$name removed from saved places';
  }

  @override
  String dayPlanCardFailedToRemove(String name) {
    return 'Failed to remove $name';
  }

  @override
  String get dayPlanCardCouldNotSaveMoodyHub =>
      'Could not save to Moody Hub. Sign in may be required.';

  @override
  String get dayPlanCardCouldNotAddMyDay =>
      'Could not add to My Day. Sign in may be required.';

  @override
  String dayPlanCardSavedToMoodyHubAndMyDay(String name) {
    return '$name saved! Find it in Moody Hub (saved) and My Day.';
  }

  @override
  String dayPlanCardSavedToMoodyHub(String name) {
    return '$name saved to Moody Hub.';
  }

  @override
  String dayPlanCardAddedToMyDay(String name) {
    return '$name added to My Day.';
  }

  @override
  String get dayPlanCardAdded => 'Added';

  @override
  String get dayPlanCardAddRemainingToMyDay => 'Add remaining to My Day';

  @override
  String dayPlanCardMatch(String percent) {
    return '$percent% Match';
  }

  @override
  String get dayPlanCardAddToMyDay => '+ Add to My Day';

  @override
  String moodHubGreetingFriendly(String name) {
    return 'Hey, $name!';
  }

  @override
  String moodHubGreetingBestie(String name) {
    return 'Hey bestie, $name! 😊';
  }

  @override
  String moodHubGreetingProfessional(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String moodHubGreetingDirect(String name) {
    return 'Hi, $name';
  }

  @override
  String get moodHubGreetingHeyThere => 'Hey there!';

  @override
  String get moodHubGreetingHi => 'Hi';

  @override
  String get moodHubWhatIsYourMood => 'What\'s your mood';

  @override
  String get moodHubThisMorning => 'this morning?';

  @override
  String get moodHubThisAfternoon => 'this afternoon?';

  @override
  String get moodHubThisEvening => 'this evening?';

  @override
  String get moodHubTonight => 'tonight?';

  @override
  String get moodHubBannerMorning => 'Morning vibes — let\'s set the tone.';

  @override
  String get moodHubBannerAfternoon =>
      'Afternoon\'s here — time to match your vibe.';

  @override
  String get moodHubBannerEvening => 'Evening\'s here — what\'s your vibe?';

  @override
  String get moodHubBannerNight =>
      'Late night energy — let\'s find something that fits.';

  @override
  String get moodHubMoodPickerBanner =>
      'Pick up to three moods below — I\'ll shape ideas around them.';

  @override
  String get moodyIdleWakeOpenPlan => 'Let\'s open your plan for today.';

  @override
  String get moodyIdleWakeChooseMood =>
      'What are we doing today? Pick your mood and we\'ll build the day.';

  @override
  String get moodyIdleTapMoodyHint => 'Tap Moody to open WanderMood';

  @override
  String get moodyIdleTapMoodySub =>
      'You have to tap the face above — there\'s no other way in.';

  @override
  String get moodyIdleTapMoodyContinueShort => 'Tap Moody to continue';

  @override
  String get moodyIdleWelcomeBack => 'Welcome back!';

  @override
  String get moodyIdleFallbackMorning => 'Moody was grabbing a coffee ☕';

  @override
  String get moodyIdleFallbackDay =>
      'Moody was out and about — ready when you are ✨';

  @override
  String get moodyIdleFallbackEvening => 'Moody was winding down 🌙';

  @override
  String get moodyIdleFallbackNight =>
      'Quiet hours… Moody was almost asleep 😴';

  @override
  String get moodyIdleGateMorning0 => 'Good morning. Ready to shape today?';

  @override
  String get moodyIdleGateMorning1 =>
      'Morning — want to see what’s on your list?';

  @override
  String get moodyIdleGateMorning2 =>
      'You’re up. Open your day whenever you’re ready.';

  @override
  String get moodyIdleGateMorning3 =>
      'New day. Tap when you want to get started.';

  @override
  String get moodyIdleGateMorning4 =>
      'Still easing in? No rush — tap Moody when you’re ready.';

  @override
  String get moodyIdleGateEvening0 =>
      'Good evening. Want to pick up your plan?';

  @override
  String get moodyIdleGateEvening1 =>
      'Evening — here when you want to close the loop.';

  @override
  String get moodyIdleGateEvening2 => 'Winding down? Your day is a tap away.';

  @override
  String get moodyIdleGateEvening3 => 'Back for a bit? Moody’s here to help.';

  @override
  String get moodyIdleGateEvening4 =>
      'Take a breath — open your plan if it helps.';

  @override
  String get moodyHubNewConversation => 'New conversation';

  @override
  String get moodHubCreatePlan => 'Let\'s create your perfect plan! 🎯';

  @override
  String get moodHubBackToHub => 'Back to Hub';

  @override
  String moodHubSelectUpTo(String max) {
    return 'You can select up to $max moods';
  }

  @override
  String get moodHubSelectedMoods => 'Selected moods: ';

  @override
  String get moodHubNoMoodOptions => 'No mood options available';

  @override
  String get moodHubMoodyThinking => 'Let me think…';

  @override
  String get moodHubMoodHappy => 'Happy';

  @override
  String get moodHubMoodAdventurous => 'Adventurous';

  @override
  String get moodHubMoodRelaxed => 'Relaxed';

  @override
  String get moodHubMoodEnergetic => 'Energetic';

  @override
  String get moodHubMoodRomantic => 'Romantic';

  @override
  String get moodHubMoodSocial => 'Social';

  @override
  String get moodHubMoodCultural => 'Cultural';

  @override
  String get moodHubMoodCurious => 'Curious';

  @override
  String get moodHubMoodCozy => 'Cozy';

  @override
  String get moodHubMoodExcited => 'Excited';

  @override
  String get moodHubMoodFoody => 'Foody';

  @override
  String get moodHubMoodSurprise => 'Surprise';

  @override
  String get planLoadingErrorTitle => 'Oops! Something went wrong';

  @override
  String get planLoadingTryAgain => 'Try Again';

  @override
  String get planLoadingErrorGeneric =>
      'Unable to generate activities. Please try again or select different moods.';

  @override
  String get planLoadingErrorNetwork =>
      'Network connection error. Please check your internet connection and try again.';

  @override
  String get planLoadingErrorLocation =>
      'Location access required. Please enable location services and try again.';

  @override
  String get planLoadingErrorService =>
      'Service temporarily unavailable. Please try again in a few minutes.';

  @override
  String get planLoadingErrorApiKey =>
      'Configuration error. Please contact support if this persists.';

  @override
  String get planLoadingErrorNotFound =>
      'Service unavailable. Please try again later.';

  @override
  String get planLoadingErrorNoActivities =>
      'No activities found for your selected moods and location. Please try different moods or check your location settings.';

  @override
  String get planLoadingMessage => 'Building your plan…';

  @override
  String get planLoadingCreatingYourDay => 'I\'m putting your day together…';

  @override
  String get planLoadingPhaseChecking => 'I\'m checking what fits you…';

  @override
  String get planLoadingPhaseBuilding => 'I\'m lining up the right spots…';

  @override
  String get planLoadingPhaseAlmost => 'Almost there — one sec…';

  @override
  String get planLoadingCompactHeadline => 'I\'m finishing your day…';

  @override
  String get groupPlanLoadingCompactHeadline =>
      'I\'m finishing your shared day…';

  @override
  String get planLoadingCancel => 'Cancel';

  @override
  String get planLoadingErrorBackToMoody => 'Back to Moody';

  @override
  String get moodyHubCompanionFallback =>
      'Your day is taking shape — I\'m right here with you. Change your mood, peek at Explore, or chat with me whenever you like.';

  @override
  String get moodyHubNudgeNoPlan =>
      'Pick a mood and I’ll build you a day that actually fits.';

  @override
  String moodyHubNudgePlanNext(String title, String time) {
    return 'Next up: $title at $time. I’ll keep the flow smooth.';
  }

  @override
  String moodyHubNudgePlanWrap(String done, String total) {
    return '$done/$total done. Tell me if you want the rest lighter or bolder.';
  }

  @override
  String get dayPlanMoodyMessageFallback =>
      'Here\'s what I picked for your vibe. Add what you love to My Day, then tap View My Day when you\'re ready.';

  @override
  String get dayPlanMoodyReplaceEnergeticVibePhrase =>
      'a great match for your mood';

  @override
  String get dayPlanFirstViewportGuidance =>
      'Open a card for details. Add with the green button, then View My Day.';

  @override
  String moodHomeChatIntroWithCity(String city) {
    return 'I know $city well and love helping you discover it. Tell me your mood — I\'ll suggest a day that fits. Adventurous, romantic, or chill — we\'ve got this.';
  }

  @override
  String get moodHomeChatIntroNoCity =>
      'Tell me your mood and I\'ll help shape a day that fits. Adventurous, romantic, or chill — we\'ve got this.';

  @override
  String get moodHomeConversationEmptyTitleMorning => 'Good morning!';

  @override
  String get moodHomeConversationEmptyBodyMorning =>
      'Let\'s shape a day that feels like you. Tell me your mood when you\'re ready.';

  @override
  String get moodHomeConversationEmptyTitleMidday => 'Hey there!';

  @override
  String get moodHomeConversationEmptyBodyMidday =>
      'I\'ve been thinking about your perfect day — share your mood when you\'re ready.';

  @override
  String get moodHomeConversationEmptyTitleAfternoon => 'Afternoon!';

  @override
  String get moodHomeConversationEmptyBodyAfternoon =>
      'What\'s on your mind for today? Your mood is a great place to start.';

  @override
  String get moodHomeConversationEmptyTitleEvening => 'Evening explorer!';

  @override
  String get moodHomeConversationEmptyBodyEvening =>
      'Weekend or weekday — let\'s find the right energy for tonight.';

  @override
  String get moodHomeConversationEmptyTitleNight => 'Still up?';

  @override
  String get moodHomeConversationEmptyBodyNight =>
      'Late-night ideas are welcome — tell me how you\'re feeling.';

  @override
  String get moodySays => 'Moody says';

  @override
  String get dayPlanMoodyCardTitle => 'Moody';

  @override
  String get moodCultural => 'Cultural';

  @override
  String get moodCozy => 'Cozy';

  @override
  String get moodFoody => 'Foody';

  @override
  String get moodRelaxed => 'Relaxed';

  @override
  String get moodAdventurous => 'Adventurous';

  @override
  String get moodSocial => 'Social';

  @override
  String get moodCreative => 'Creative';

  @override
  String get moodRomantic => 'Romantic';

  @override
  String get moodEnergetic => 'Energetic';

  @override
  String get moodCurious => 'Curious';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodFoodie => 'Foodie';

  @override
  String get moodExcited => 'Excited';

  @override
  String get moodSurprise => 'Surprise';

  @override
  String dayPlanFoundNewOption(String name, String remaining) {
    return '✨ Found a new option: $name! ($remaining more changes available)';
  }

  @override
  String activityDetailMatch(String percent) {
    return '$percent% Match';
  }

  @override
  String activityDetailPhotoCount(String count) {
    return '$count photo';
  }

  @override
  String activityDetailPhotoCountPlural(String count) {
    return '$count photos';
  }

  @override
  String get activityDetailTabDetails => 'Details';

  @override
  String get activityDetailTabPhotos => 'Photos';

  @override
  String get activityDetailTabReviews => 'Reviews';

  @override
  String get activityDetailReviewsEmpty =>
      'No reviews yet. They\'ll show here when this place is linked to live listings.';

  @override
  String get activityDetailPreviewSampleNote =>
      'Sample photos and reviews for this preview.';

  @override
  String get activityDetailDemoReviewRecent => 'Recently';

  @override
  String get activityDetailDemoReview1Author => 'Maya K.';

  @override
  String get activityDetailDemoReview1Body =>
      'Quiet and lovely — exactly the slow morning we wanted.';

  @override
  String get activityDetailDemoReview2Author => 'Joost V.';

  @override
  String get activityDetailDemoReview2Body =>
      'Great coffee and friendly service. We\'ll be back.';

  @override
  String get activityDetailDemoReview3Author => 'Sara L.';

  @override
  String get activityDetailDemoReview3Body =>
      'Cozy corners for two. Perfect before a walk in town.';

  @override
  String get activityDetailDemoReview4Author => 'Eli R.';

  @override
  String get activityDetailDemoReview4Body =>
      'Small menu, but everything we tried hit the spot.';

  @override
  String get activityDetailRatingExceptional => 'Exceptional';

  @override
  String get activityDetailDuration => 'Duration';

  @override
  String get activityDetailPrice => 'Price';

  @override
  String get activityDetailDistance => 'Distance';

  @override
  String get activityDetailDistanceNearby => 'Nearby';

  @override
  String get activityDetailAbout => 'About';

  @override
  String get activityDetailHighlights => 'Highlights';

  @override
  String get activityDetailLocation => 'Location';

  @override
  String get activityDetailGetDirections => 'Get Directions →';

  @override
  String get activityDetailFrom => 'From';

  @override
  String get activityDetailPerPerson => 'per person';

  @override
  String get activityDetailDirections => 'Directions';

  @override
  String get activityDetailBookNow => 'Book Now';

  @override
  String get getReadyTitle => 'Get Ready';

  @override
  String getReadyLeaveBy(String time) {
    return 'Leave by $time';
  }

  @override
  String getReadyTripSummary(String mode, int minutes) {
    return '$mode · ~$minutes min trip';
  }

  @override
  String get getReadyTransportWalking => 'Walking';

  @override
  String get getReadyTransportPublicTransport => 'Public transport';

  @override
  String getReadyWeatherAt(String time) {
    return 'Weather at $time';
  }

  @override
  String get getReadyWeatherTipDefault =>
      'Looks like a great time to head out.';

  @override
  String get getReadyWeatherTipCool =>
      'It might be a bit chilly – bring a light jacket.';

  @override
  String get getReadyWeatherTipRain =>
      'Rain is expected – consider bringing an umbrella.';

  @override
  String get getReadyChecklistTitle => 'What to bring';

  @override
  String get getReadyItemWallet => 'Wallet & payment method';

  @override
  String get getReadyItemPhoneCharged => 'Phone fully charged';

  @override
  String get getReadyItemReusableBag => 'Reusable bag or container';

  @override
  String get getReadyItemShoes => 'Comfortable walking shoes';

  @override
  String get getReadyItemWater => 'Water bottle';

  @override
  String get getReadyItemId => 'ID / travel card if needed';

  @override
  String get getReadyReminderTitle => 'Remind me to leave';

  @override
  String get getReadyReminderSubtitle =>
      'We\'ll send a gentle nudge a few minutes before.';

  @override
  String get getReadyQuickActions => 'Quick actions';

  @override
  String get getReadyQuickShare => 'Share';

  @override
  String get getReadyQuickCalendar => 'Calendar';

  @override
  String get getReadyQuickParking => 'Parking';

  @override
  String get getReadyPrimaryCta => 'I\'m ready! 🚀';

  @override
  String get getReadyLetsGo => 'Let\'s Go!';

  @override
  String get getReadyAdventureStartsIn => 'Adventure starts in…';

  @override
  String get getReadyHours => 'HOURS';

  @override
  String get getReadyMins => 'MINS';

  @override
  String get getReadyRoute => 'Route';

  @override
  String get travelTimeLessThanOneMinWalk => '< 1 min walk';

  @override
  String travelTimeMinWalk(int minutes) {
    return '$minutes min walk';
  }

  @override
  String travelTimeBikeAndWalk(int bikeMinutes, int walkMinutes) {
    return '$bikeMinutes min bike · $walkMinutes min walk';
  }

  @override
  String travelTimeTransitApprox(int transitMinutes, String distance) {
    return '≈ $transitMinutes min transit · $distance';
  }

  @override
  String get getReadyYourAdventureEnergy => 'Your Adventure Energy';

  @override
  String get getReadyBoostEnergyHint =>
      'Check off items below to boost your energy!';

  @override
  String get getReadyPackEssentials => 'Pack Your Essentials';

  @override
  String get getReadyVibePlaylist => 'Vibe Playlist';

  @override
  String getReadyGetInMood(String mood) {
    return 'Get in the $mood mood!';
  }

  @override
  String getReadyPlaylistLabel(String theme) {
    return 'Happy $theme Beats';
  }

  @override
  String get getReadyPlay => 'Play';

  @override
  String get getReadyNudgeMe => 'Nudge me when it\'s time!';

  @override
  String getReadyReminderAt(String time) {
    return 'We\'ll remind you at $time';
  }

  @override
  String get getReadyCantWait => 'Can\'t wait to see what you discover!';

  @override
  String noPlanDayOpenInCity(String city) {
    return 'Your day in $city is still wide open — I\'ve already got ideas bubbling. Want me to sketch a full flow, or should we chase one vibe first?';
  }

  @override
  String get noPlanDayOpenAroundYou =>
      'Your day is still wide open — I\'ve already got ideas bubbling. Want me to sketch a full flow, or should we chase one vibe first?';

  @override
  String get noPlanDayOpenLocating =>
      'Hang on… I\'m locking in where you are, then we\'ll pick your next move.';

  @override
  String get noPlanPlanMyWholeDay => 'Plan my whole day';

  @override
  String get noPlanFindMeCoffee => '☕ Find me coffee';

  @override
  String get noPlanGetMeMoving => '🏃 Get me moving';

  @override
  String get noPlanJustChat => '💬 Tell me what\'s on your mind';

  @override
  String get noPlanPlanLater => 'Maybe later';

  @override
  String get dayPlanNoLinkedPlaceAlternative =>
      'No high-quality linked-place alternative found yet. Try again.';

  @override
  String get myDayCheckInPrompt =>
      'You\'re here! Tap Done when you\'re finished.';

  @override
  String get myDayDonePrompt => 'Nice one! You can leave a review now.';

  @override
  String get myDayGetReadyUpcomingFallback => 'Your upcoming activity';

  @override
  String get myDayDirectionsOpensInMaps => 'Opens in maps app';

  @override
  String get myDayCallVenue => 'Call Venue';

  @override
  String get myDayCallVenueSubtitle => 'Confirm details or ask questions';

  @override
  String get myDayNoPhoneAvailable => 'No phone number available';

  @override
  String get myDayAddToCalendar => 'Add to Calendar';

  @override
  String get myDayAddToCalendarSubtitle => 'Set reminder and details';

  @override
  String get myDayAddedToCalendar => 'Added to calendar';

  @override
  String get myDayAllSet => 'You\'re all set! Have a great time!';

  @override
  String get myDayReadyCta => 'I\'m Ready!';

  @override
  String myDayTabActivated(String tab) {
    return '$tab activated!';
  }

  @override
  String get myDaySaveForLater => 'Save for later';

  @override
  String myDayDirectionsChooseFor(String title) {
    return 'Choose how you\'d like to get directions to $title';
  }

  @override
  String get myDayActivityOptionsTitle => 'Activity options';

  @override
  String get myDayViewDetails => 'View details';

  @override
  String get myDayImHere => 'I\'m here';

  @override
  String get myDayImHereSubtitle => 'Check in when you arrive at this spot';

  @override
  String get myDayDone => 'Done';

  @override
  String get myDayDoneSubtitle => 'Mark complete and leave a review';

  @override
  String get myDayShareActivity => 'Share activity';

  @override
  String get myDayShareComingSoon => 'Share functionality coming soon!';

  @override
  String myDaySavedForLater(String title) {
    return '$title saved to Saved places!';
  }

  @override
  String get myDaySavePlaceFailed =>
      'Could not save to Saved places. Try again.';

  @override
  String get myDayShareFailed => 'Could not share. Try again.';

  @override
  String get myDayDirectionsNavigateTitle => 'Navigate to';

  @override
  String get myDayDeleteActivity => 'Delete activity';

  @override
  String get myDayDeleteActivitySubtitle => 'Remove this activity from My Day';

  @override
  String get myDayDeleteConfirmTitle => 'Delete activity?';

  @override
  String myDayDeleteConfirmBody(String title) {
    return '\"$title\" will be removed from your My Day plan.';
  }

  @override
  String get myDayDeleteActivityCta => 'Delete';

  @override
  String get myDayDeleteMissingId => 'Could not delete activity (missing id).';

  @override
  String myDayDeletedFromPlan(String title) {
    return '$title deleted from My Day.';
  }

  @override
  String get myDayDeleteFailed => 'Delete failed. Please try again.';

  @override
  String get myDayActivityLocationFallback => 'Activity Location';

  @override
  String get myDayUnableOpenDirections => 'Unable to open directions';

  @override
  String get myDayChatWithMoodyTitle => 'Chat with Moody';

  @override
  String get myDayChatWithMoodyComingSoon =>
      'Coming soon! Moody will be able to help you plan your day and suggest activities based on your mood and preferences.';

  @override
  String get myDayHeroActiveSubtitle => 'You\'re in this activity right now.';

  @override
  String get myDayUnableLoadActivities => 'Unable to load activities';

  @override
  String get navMyDay => 'My Day';

  @override
  String get navExplore => 'Explore';

  @override
  String get navAgenda => 'My Plans';

  @override
  String get navProfile => 'Profile';

  @override
  String get navMoody => 'Moody';

  @override
  String get mainNavNoConnection => 'No internet connection';

  @override
  String get exploreAlreadyInDayPlan => 'Already in your day plan 👍';

  @override
  String get myDayStatusTitleRightNow => 'Right Now';

  @override
  String get myDayStatusTitleUpNext => 'Up Next';

  @override
  String get myDayStatusTitleAllDone => '✅ All Done';

  @override
  String get myDayStatusTitleFreeTime => '📅 FREE TIME';

  @override
  String get myDayStatusDescActive =>
      'You\'re here! Tap Done when you\'re finished.';

  @override
  String get myDayStatusDescUpcomingMorning =>
      'Planned for the morning · tap \"I\'m Here\" when you arrive';

  @override
  String get myDayStatusDescUpcomingAfternoon =>
      'Planned for the afternoon · tap \"I\'m Here\" when you arrive';

  @override
  String get myDayStatusDescUpcomingEvening =>
      'Planned for the evening · tap \"I\'m Here\" when you arrive';

  @override
  String get myDayStatusDescCompleted =>
      'Great day! You\'ve completed everything.';

  @override
  String get myDayPeriodMorning => 'Morning';

  @override
  String get myDayPeriodAfternoon => 'Afternoon';

  @override
  String get myDayPeriodEvening => 'Evening';

  @override
  String get myDayFreeTimeSuggestionMorning =>
      'Perfect time to start your day with energy';

  @override
  String get myDayFreeTimeSuggestionAfternoon =>
      'Great time to explore and discover';

  @override
  String get myDayFreeTimeSuggestionEvening =>
      'Wind down with something special';

  @override
  String myDayTimelineActivityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
    );
    return '$_temp0';
  }

  @override
  String get myDayTimelineAllDone => 'All Done';

  @override
  String get myDayTimelineSectionComplete =>
      'Great job completing this section!';

  @override
  String get myDayTimelineTapForDetails => 'Tap for details';

  @override
  String get myDayTimelinePrimaryImHere => 'I\'m Here';

  @override
  String get myDayTimelinePrimaryDone => 'Done';

  @override
  String get myDayTimelinePrimaryReview => 'Review';

  @override
  String get myDayTimelinePrimaryReviewed => 'Reviewed';

  @override
  String get myDayTimelineStatusImHere => 'I\'M HERE';

  @override
  String get myDayTimelineStatusPlanned => 'PLANNED';

  @override
  String get myDayTimelineStatusDone => 'DONE';

  @override
  String get myDayTimelineStatusCancelled => 'CANCELLED';

  @override
  String get myDayActivityFallbackLabel => 'Activity';

  @override
  String get myDayExecutionHeroYoureHereBadge => 'You\'re here!';

  @override
  String get myDayExecutionHeroInProgressBadge => 'IN PROGRESS';

  @override
  String get myDayExecutionHeroActiveHint =>
      'Enjoying it? Tap Done when you\'re ready to move on.';

  @override
  String myDayExecutionHeroReviewedAt(String time) {
    return 'Reviewed at $time';
  }

  @override
  String get myDayExecutionHeroCompletedToday => 'Completed today';

  @override
  String get myDayExecutionHeroBadgeReviewedCaps => 'REVIEWED';

  @override
  String get myDayExecutionHeroBadgeReadyToReviewCaps => 'READY TO REVIEW';

  @override
  String get myDayExecutionHeroReviewCaptureHint =>
      'Capture how it felt while the experience is still fresh.';

  @override
  String get myDayExecutionHeroUpNextBadge => 'UP NEXT';

  @override
  String get myDayExecutionHeroUpNextAfterSlotBadge => 'NEXT';

  @override
  String get myDayExecutionHeroTapImHereWhenArrive =>
      'Tap \"I\'m Here\" when you arrive.';

  @override
  String get myDayTimelineSectionMorningTitle => '🌅 Morning';

  @override
  String get myDayTimelineSectionMorningFocusTitle => '🌅 This morning';

  @override
  String get myDayTimelineSectionMorningSubtitle => 'Start your day right';

  @override
  String get myDayTimelineSectionAfternoonTitle => '🌞 Afternoon';

  @override
  String get myDayTimelineSectionAfternoonFocusTitle => '🌞 This afternoon';

  @override
  String get myDayTimelineSectionAfternoonSubtitle => 'Peak adventure time';

  @override
  String get myDayTimelineSectionEveningTitle => '🌆 Evening';

  @override
  String get myDayTimelineSectionEveningFocusTitle => '🌆 This evening';

  @override
  String get myDayTimelineSectionEveningSubtitle => 'Wind down and enjoy';

  @override
  String get myDayTimelineSectionEarlierTodaySubtitle => 'Earlier in your day';

  @override
  String get myDaySlotPlannedForMorning => 'This morning';

  @override
  String get myDaySlotPlannedForAfternoon => 'This afternoon';

  @override
  String get myDaySlotThisEvening => 'This evening';

  @override
  String get myDayTimelineSectionMorningPastTitle => '🌅 Morning';

  @override
  String get myDayTimelineSectionAfternoonPastTitle => '🌞 Afternoon';

  @override
  String get myDayWeekendEmptyTitle => 'Your weekend is still empty!';

  @override
  String get myDayWeekendEmptySubtitle =>
      'Want to plan Saturday or Sunday in advance?';

  @override
  String myDayWeekendSaturdayShort(String day) {
    return 'Sa $day';
  }

  @override
  String myDayWeekendSundayShort(String day) {
    return 'Su $day';
  }

  @override
  String placeCardFailedToShare(String error) {
    return 'Failed to share: $error';
  }

  @override
  String placeCardSaved(String name) {
    return '$name saved!';
  }

  @override
  String placeCardFailedToggleSave(String name) {
    return 'Failed to update saved state for $name';
  }

  @override
  String placeDetailSavedToFavorites(String name) {
    return '$name saved to favorites!';
  }

  @override
  String get placeDetailSaveToggleFailed => 'Failed to update saved place';

  @override
  String placeDetailCouldNotOpenMaps(String error) {
    return 'Could not open maps: $error';
  }

  @override
  String get bookingSavedViewMyBookings => 'Booking saved! View in My Bookings';

  @override
  String get bookingViewAction => 'View';

  @override
  String bookingErrorSaving(String error) {
    return 'Error saving booking: $error';
  }

  @override
  String get bookingReviewTitle => 'Review booking';

  @override
  String get bookingNoPaymentInAppBody =>
      'WanderMood does not collect payment for venues in this app. What you save here is for your trip plan. Contact the place directly to reserve or pay.';

  @override
  String get bookingSaveToPlanCta => 'Save to my plan';

  @override
  String get bookingEstimatedTotalLabel =>
      'Estimated total (not charged in app)';

  @override
  String get bookingPlanSavedHeader => 'Plan saved';

  @override
  String get bookingAddedToPlanTitle => 'Added to your plan!';

  @override
  String bookingAddedToPlanBody(String placeName) {
    return '$placeName is saved in My Bookings and your agenda. Final booking and payment are arranged with the venue — not through this app.';
  }

  @override
  String bookingReferenceLine(String reference) {
    return 'Reference: $reference';
  }

  @override
  String get bookingSectionTotalEstimate => 'Estimated total';

  @override
  String bookingGuestsSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String get gygCodeCopied => 'Code copied 💚';

  @override
  String get placeCardSeeActivity => 'See activity';

  @override
  String get placeCardPriceVaries => 'Price varies';

  @override
  String gygEdviennePicksInCity(String city) {
    return '✨ Edvienne\'s Picks in $city';
  }

  @override
  String gygMapCompactTitle(String city) {
    return 'Edvienne\'s Picks — $city';
  }

  @override
  String get gygMapCompactSubtitle =>
      'Tap to open GetYourGuide & your discount';

  @override
  String gygPrimaryTitleInCity(String city) {
    return '✨ Edvienne\'s Picks in $city';
  }

  @override
  String get gygTagline48h => 'What I\'d book if I had 48 hours here 🤍';

  @override
  String get gygOpenInApp => 'Open in GetYourGuide app (with promo)';

  @override
  String get gygOpenInWeb => 'Open in browser';

  @override
  String gygPromoGift(String code) {
    return '🎁 A little extra from me: $code';
  }

  @override
  String get gygPromoAppOnly => 'Valid only in the GetYourGuide app.';

  @override
  String get gygCopy => 'Copy';

  @override
  String get gygPoweredBy => 'Powered by GetYourGuide';

  @override
  String get gygComingSoonBody =>
      'I\'m still curating the best picks for this city 🤍';

  @override
  String get gygCategoryFoodDrink => '🍴 Food & drink';

  @override
  String get gygCategoryBoatTours => '⛵ Boat tours';

  @override
  String get gygCategoryCulture => '🎭 Culture';

  @override
  String get gygCategoryAdventure => '🧗 Adventure';

  @override
  String get gygCategoryLuxury => '✨ Luxury';

  @override
  String get socialNewMessageComingSoon => 'New message feature coming soon!';

  @override
  String get socialSearchMessagesHint => 'Search messages';

  @override
  String get socialCallComingSoon => 'Call feature coming soon!';

  @override
  String get socialVideoCallComingSoon => 'Video call feature coming soon!';

  @override
  String get socialPhotoSharingComingSoon => 'Photo sharing coming soon!';

  @override
  String get socialTypeMessageHint => 'Type a message...';

  @override
  String get socialReportUser => 'Report User';

  @override
  String get socialBlockUser => 'Block User';

  @override
  String get socialShareProfile => 'Share Profile';

  @override
  String socialMessageTraveler(String name) {
    return 'Message $name';
  }

  @override
  String get socialWriteMessageHint => 'Write your message...';

  @override
  String socialMessageSentTo(String name) {
    return 'Message sent to $name!';
  }

  @override
  String get socialSend => 'Send';

  @override
  String get socialUserReportedThankYou =>
      'User reported. Thank you for keeping our community safe.';

  @override
  String socialUserBlocked(String name) {
    return '$name has been blocked.';
  }

  @override
  String socialProfileShared(String name) {
    return '$name\'s profile shared!';
  }

  @override
  String get socialSavedPostsUnavailable =>
      'Saved posts are not available yet.';

  @override
  String get socialCloseFriendsUnavailable =>
      'Close friends is not available yet.';

  @override
  String get socialMarkAsRead => 'Mark as read';

  @override
  String get socialMarkAsUnread => 'Mark as unread';

  @override
  String get socialFollowBack => 'Follow Back';

  @override
  String get socialViewPost => 'View Post';

  @override
  String get socialReply => 'Reply';

  @override
  String get socialAccept => 'Accept';

  @override
  String socialFilteringBy(String filter) {
    return 'Filtering by: $filter';
  }

  @override
  String get socialOpeningPost => 'Opening post...';

  @override
  String socialOpeningUserProfile(String name) {
    return 'Opening $name profile...';
  }

  @override
  String get socialOpeningTrendingPost => 'Opening trending post...';

  @override
  String get socialOpeningMention => 'Opening mention...';

  @override
  String socialFollowingUser(String name) {
    return 'Following $name!';
  }

  @override
  String get socialReplyToComment => 'Reply to Comment';

  @override
  String get socialWriteReplyHint => 'Write your reply...';

  @override
  String get socialReplySent => 'Reply sent!';

  @override
  String get socialRequestAccepted => 'Request accepted!';

  @override
  String get socialOpeningContent => 'Opening content...';

  @override
  String get socialNotificationDeleted => 'Notification deleted';

  @override
  String get socialUndo => 'Undo';

  @override
  String get socialClose => 'Close';

  @override
  String socialToggleState(String title, String state) {
    return '$title $state';
  }

  @override
  String get socialAllNotificationsRead => 'All notifications marked as read';

  @override
  String socialYouHaveNewNotifications(String count) {
    return 'You have $count new notifications';
  }

  @override
  String get socialSampleNotificationLiked => '• Sarah liked your post';

  @override
  String get socialSampleNotificationFollowed =>
      '• Marco started following you';

  @override
  String get socialSampleNotificationStory => '• New travel story from Luna';

  @override
  String get notificationCardDeleteTooltip => 'Remove';

  @override
  String get notificationCentreMoodMatchTimelineTitle => 'Planning together';

  @override
  String get notificationCentreMoodMatchTimelineSubtitle =>
      'A calm timeline of your Mood Match.';

  @override
  String get notificationCentreTitle => 'Updates';

  @override
  String get notificationCentreEmptyState =>
      'Nothing new — you\'re all caught up. I\'ll let you know when something happens.';

  @override
  String get notificationCentreMarkAllRead => 'Mark all read';

  @override
  String get notificationCentreSectionNew => 'New';

  @override
  String get notificationCentreSectionEarlier => 'Earlier';

  @override
  String get notificationCentreReadDividerLabel => 'Read';

  @override
  String get notificationCentreAllFilter => 'All';

  @override
  String get notificationCentreActivitiesLabel => 'Activities';

  @override
  String get notificationCentreSocialLabel => 'Social';

  @override
  String get notificationCentreMoodyLabel => 'Moody';

  @override
  String get notificationCentreCategoryMoodMatch => 'Mood Match';

  @override
  String notificationCentreRelativeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get socialOpeningAllTravelStories => 'Opening all travel stories...';

  @override
  String socialOpeningUserStory(String name) {
    return 'Opening $name\'s story...';
  }

  @override
  String get socialSavePost => 'Save Post';

  @override
  String socialFollowUser(String name) {
    return 'Follow $name';
  }

  @override
  String get socialReportPost => 'Report Post';

  @override
  String socialLikedUserPost(String name) {
    return 'Liked $name\'s post!';
  }

  @override
  String socialCommentOnUserPost(String name) {
    return 'Comment on $name\'s post';
  }

  @override
  String get socialWriteCommentHint => 'Write a comment...';

  @override
  String get socialCommentPosted => 'Comment posted!';

  @override
  String get socialPost => 'Post';

  @override
  String socialSharedUserPost(String name) {
    return 'Shared $name\'s post!';
  }

  @override
  String socialSavedUserPost(String name) {
    return 'Saved $name\'s post!';
  }

  @override
  String socialReportedUserPost(String name) {
    return 'Reported $name\'s post';
  }

  @override
  String get socialShareComingSoon => 'Share feature coming soon!';

  @override
  String socialFoundPostsWithTag(String count, String tag) {
    return 'Found $count posts with #$tag';
  }

  @override
  String get socialLinkCopiedClipboard => 'Link copied to clipboard';

  @override
  String get socialAddCommentHint => 'Add a comment...';

  @override
  String get socialCommentFeatureComingSoon => 'Comment feature coming soon!';

  @override
  String socialRemovedFromCollection(String place, String collection) {
    return '$place removed from $collection';
  }

  @override
  String get socialEditCollection => 'Edit collection';

  @override
  String get socialCollectionName => 'Collection name';

  @override
  String get socialDeleteCollectionTitle => 'Delete collection?';

  @override
  String get socialPickDayForPlan => 'Pick day for plan';

  @override
  String get socialDay => 'Day';

  @override
  String get socialTime => 'Time';

  @override
  String get socialAddToCollection => 'Add to collection';

  @override
  String socialRemoved(String name) {
    return '$name removed';
  }

  @override
  String get socialCollectionNameHint =>
      'e.g. Rotterdam weekend, Kid-friendly…';

  @override
  String get socialCreate => 'Create';

  @override
  String get socialMessagingComingSoon => 'Messaging feature coming soon!';

  @override
  String get socialQrSharingComingSoon => 'QR code sharing coming soon!';

  @override
  String get socialReportComingSoon => 'Report feature coming soon!';

  @override
  String get socialBlockComingSoon => 'Block feature coming soon!';

  @override
  String get socialUserNotFound => 'User not found';

  @override
  String get socialPleaseSelectImage => 'Please select an image';

  @override
  String get socialStoryPostedSuccess => 'Story posted successfully!';

  @override
  String get socialCreateStory => 'Create Story';

  @override
  String get socialTapAddPhoto => 'Tap to add a photo';

  @override
  String get socialAddStoryCaptionHint => 'Add a caption to your story...';

  @override
  String get socialAddLocation => 'Add Location';

  @override
  String get socialLocationComingSoon => 'Location feature coming soon!';

  @override
  String get socialActivityTaggingComingSoon => 'Activity tagging coming soon!';

  @override
  String get socialNameUsernameRequired => 'Name and username are required';

  @override
  String socialSelectUpToTags(String count) {
    return 'You can select up to $count tags';
  }

  @override
  String get socialPleaseAddOneImage => 'Please add at least one image';

  @override
  String get socialPostCreatedSuccess => 'Post created successfully!';

  @override
  String get socialCreatePost => 'Create Post';

  @override
  String get socialAddPhotos => 'Add Photos';

  @override
  String get socialAddMore => 'Add More';

  @override
  String get socialWriteCaptionHint => 'Write a caption...';

  @override
  String get moodySpeechNotAvailable =>
      'Speech recognition is not available on this device';

  @override
  String socialFailedSharePost(String error) {
    return 'Failed to share post: $error';
  }

  @override
  String socialViewingPostsTagged(String tag) {
    return 'Viewing posts tagged with #$tag';
  }

  @override
  String get socialSearchTravelersHint =>
      'Search travelers by name or interests...';

  @override
  String socialConnectionRequestSent(String name) {
    return 'Connection request sent to $name!';
  }

  @override
  String get socialViewProfile => 'View Profile';

  @override
  String get socialSendRequest => 'Send Request';

  @override
  String get socialProfileUpdatedDevMode =>
      'Profile updated successfully! (Development mode)';

  @override
  String socialErrorUpdatingProfile(String error) {
    return 'Error updating profile: $error';
  }

  @override
  String get socialUploadingPhoto => 'Uploading photo...';

  @override
  String socialErrorUploadingPhoto(String error) {
    return 'Error uploading photo: $error';
  }

  @override
  String get socialEditProfileInfo => 'Edit Profile Info';

  @override
  String get myDayAddSignInRequired => 'Sign in to add activities.';

  @override
  String get myDayAddFailedTryAgain =>
      'Could not add activity. Please try again.';

  @override
  String get activityOptionsViewAction => 'View';

  @override
  String get exploreNoPlacesFound => 'No places found';

  @override
  String get exploreNoPlacesFoundHint =>
      'Try different keywords or adjust your filters.';

  @override
  String get exploreSearching => 'Searching…';

  @override
  String agendaChooseActivityForDay(String day) {
    return 'Choose an activity to add for $day.';
  }

  @override
  String get agendaLoadingActivities => 'Loading activities...';

  @override
  String get agendaErrorLoadingActivities => 'Error loading activities';

  @override
  String get agendaPleaseTryAgainLater => 'Please try again later';

  @override
  String get agendaNoActivitiesScheduled => 'No activities scheduled';

  @override
  String get agendaNoActivitiesPlannedYet =>
      'You do not have any planned activities in My Plans yet';

  @override
  String get agendaDeleteMissingId => 'Could not delete activity (missing id).';

  @override
  String agendaRemovedFromPlanner(String title) {
    return '$title removed from your planner.';
  }

  @override
  String get socialGetDirections => 'Get directions';

  @override
  String get socialShare => 'Share';

  @override
  String get socialOpenDirectionsFailed => 'Unable to open directions';

  @override
  String get socialDeleteActivityConfirmTitle => 'Delete activity?';

  @override
  String get socialDeleteFailedTryAgain => 'Delete failed. Please try again.';

  @override
  String get socialShareActivityDetailsCopied =>
      'Activity details copied to share';

  @override
  String get dailyScheduleTitle => 'Daily Schedule';

  @override
  String get dailyScheduleToday => 'Today';

  @override
  String get dailyScheduleTomorrow => 'Tomorrow';

  @override
  String get dailyScheduleNoActivities => 'No activities scheduled';

  @override
  String get dailyScheduleExplorePrompt =>
      'Tap the button below to explore activities';

  @override
  String get dailyScheduleExploreActivities => 'Explore Activities';

  @override
  String get dailyScheduleUpcomingActivities => 'Upcoming Activities';

  @override
  String get dailyScheduleCompletedActivities => 'Completed Activities';

  @override
  String dailyScheduleActivitiesPlanned(String count) {
    return '$count activities planned';
  }

  @override
  String dailyScheduleActivitiesCompleted(String count) {
    return '$count activities completed';
  }

  @override
  String get dailyScheduleNoActivitiesForDate =>
      'No activities scheduled for this date';

  @override
  String get dailyScheduleConfirmed => 'Confirmed';

  @override
  String get dailyScheduleCompleted => 'Completed';

  @override
  String dailyScheduleDurationMinutes(String minutes) {
    return '$minutes minutes';
  }

  @override
  String get signupNoPasswordNeeded =>
      'This is WanderMood — I\'ll do this for you whenever you feel like it 😌';

  @override
  String get signupRatingBadge => 'No password';

  @override
  String get signupPrivacyPrefix => 'By continuing, you agree to our ';

  @override
  String get signupPrivacyLinkLabel => 'privacy policy';

  @override
  String get signupSuccessCheckInbox => 'I just sent you something ✉️';

  @override
  String get signupSuccessTapLinkSubtitle => 'Tap the link — I\'ll be there 😌';

  @override
  String signupSuccessSentToLine(String email) {
    return 'Sent to: $email';
  }

  @override
  String get signupOpenGmail => 'Open Gmail';

  @override
  String get signupOpenOutlook => 'Open Outlook';

  @override
  String get signupOpenAppleMail => 'Open Apple Mail';

  @override
  String get signupOpenEmailApp => 'Open your email';

  @override
  String get signupInboxFooterPrefix => 'Didn\'t get it? ';

  @override
  String get signupInboxFooterResend => 'Resend';

  @override
  String get signupInboxFooterOr => ' or ';

  @override
  String get signupInboxFooterChangeEmail => 'change email';

  @override
  String get introHeadline1 => 'Your mood,';

  @override
  String get introHeadline2 => 'your adventure';

  @override
  String get onboardingLoadingTitle => 'I\'m getting to know you! 🧠';

  @override
  String get onboardingLoadingSubtitle0 => 'Saving your interests...';

  @override
  String get onboardingLoadingSubtitle1 => 'Tuning your style...';

  @override
  String get onboardingLoadingSubtitle2 => 'Finding places that fit you...';

  @override
  String get onboardingLoadingSubtitle3 => 'Getting myself ready for you...';

  @override
  String get onboardingLoadingFooter => 'This\'ll just take a moment ✨';

  @override
  String get demoModeLabel => '▶ Demo mode';

  @override
  String get demoSkip => 'Skip';

  @override
  String get demoTapToChooseMood => 'Tap to choose your mood:';

  @override
  String get demoDiscoverMore => 'Discover more →';

  @override
  String get demoMoodSurpriseMe => 'Surprise me';

  @override
  String get demoMoodyGreetingLine2 =>
      'Tell me what kind of day you\'re after — I\'ll take care of the rest.';

  @override
  String get demoMoodyQuestion => 'So… what kind of day are we having?';

  @override
  String get demoUserReplyRelaxed => 'I\'m feeling relaxed';

  @override
  String get demoUserReplyAdventurous => 'I\'m feeling adventurous';

  @override
  String get demoUserReplyRomantic => 'I\'m feeling romantic';

  @override
  String get demoUserReplyCultural => 'I\'m feeling cultural';

  @override
  String get demoUserReplyFoodie => 'I\'m feeling like a foodie';

  @override
  String get demoUserReplySocial => 'I\'m feeling social';

  @override
  String get demoUserReplySurpriseMe => 'Surprise me!';

  @override
  String get demoUserReplyDefault => 'This is my mood!';

  @override
  String get demoMoodReactionRelaxed =>
      'Soft mornings and slow moments—I\'ve got you.';

  @override
  String get demoMoodReactionFoodie => 'We\'re eating well today.';

  @override
  String get demoMoodReactionEnergetic => 'High energy—let\'s make it count.';

  @override
  String get demoMoodReactionAdventurous => 'Adventure mode activated.';

  @override
  String get demoMoodReactionCultural => 'Curiosity looks good on you.';

  @override
  String get demoMoodReactionCozy => 'Cozy, quiet, and just right.';

  @override
  String get demoMoodReactionSurprise =>
      'A little mystery—I\'ve got ideas for you. ✨';

  @override
  String get demoMoodReactionDefault => 'Love it—let\'s shape your day.';

  @override
  String get demoPuttingDayTogether => 'Putting your day together…';

  @override
  String get guestDemoResultTitlePicked => 'I picked these for you';

  @override
  String guestDemoResultTitleWithMood(String moodLabel) {
    return '$moodLabel';
  }

  @override
  String get guestDemoDayPlanMoodyBlurb =>
      'I put this together for you — start here 👇';

  @override
  String get guestDemoPreviewAreaLabel => 'Rotterdam city center · demo pins';

  @override
  String get guestDayPlanHeadingMadeForYou => 'I made this for you';

  @override
  String get guestDayPlanHeroHint =>
      'Tap any stop for details, photos & reviews.';

  @override
  String get guestDayPlanContinueWithMoody => 'Continue with Moody';

  @override
  String get guestDemoMoodyRelaxed0 => 'Trees first, screens later. 🌿';

  @override
  String get guestDemoMoodyRelaxed1 => 'You moved — now melt into the chair. ☕';

  @override
  String get guestDemoMoodyRelaxed2 =>
      'Golden hour hits different from this spot 🌅';

  @override
  String get guestDemoMoodyFoodie0 =>
      'Still warm, good coffee — exactly how your day should start ☕';

  @override
  String get guestDemoMoodyFoodie1 => 'Get here early… these sell out fast 🥐';

  @override
  String get guestDemoMoodyFoodie2 => 'Come hungry — portions are generous 🍽️';

  @override
  String get guestDemoMoodySocial0 =>
      'Easy to slide in solo or with friends — the vibe is welcoming 🎉';

  @override
  String get guestDemoMoodySocial1 =>
      'Pull up a bench — someone’s always finishing a story. 🥗';

  @override
  String get guestDemoMoodySocial2 =>
      'Strike up a chat at the bar; regulars love newcomers 👋';

  @override
  String get guestDemoMoodyAdventurous0 =>
      'Earn the view — then earn lunch. 🥾';

  @override
  String get guestDemoMoodyAdventurous1 =>
      'You crushed the climb — now let the harbor do the work. 🛥️';

  @override
  String get guestDemoMoodyAdventurous2 =>
      'Let the day’s noise fade into golden hour. 🌇';

  @override
  String get guestDemoMoodyCultural0 =>
      'Give yourself time to read every plaque 🏛️';

  @override
  String get guestDemoMoodyCultural1 => 'Museum brain off, espresso on. ☕';

  @override
  String get guestDemoMoodyCultural2 =>
      'Culture, but make it unbuttoned-collar. 🎷';

  @override
  String get guestDemoMoodyRomantic0 =>
      'Low lights, shared plates — keep the phones away.';

  @override
  String get guestDemoMoodyRomantic1 =>
      'Ask for a corner table if you can — worth it 🕯️';

  @override
  String get guestDemoMoodyRomantic2 => 'Split dessert. Non-negotiable 🍰';

  @override
  String get guestDemoTagWalk => 'Walk';

  @override
  String get guestDemoTagNature => 'Nature';

  @override
  String get guestDemoTagCafe => 'Cafe';

  @override
  String get guestDemoTagCalm => 'Calm';

  @override
  String get guestDemoTagRestaurant => 'Restaurant';

  @override
  String get guestDemoTagSunset => 'Sunset';

  @override
  String get guestDemoTagBreakfast => 'Breakfast';

  @override
  String get guestDemoTagMarket => 'Market';

  @override
  String get guestDemoTagLunch => 'Lunch';

  @override
  String get guestDemoTagDinner => 'Dinner';

  @override
  String get guestDemoTagActive => 'Active';

  @override
  String get guestDemoTagOutdoor => 'Outdoor';

  @override
  String get guestDemoTagNightlife => 'Nightlife';

  @override
  String get guestDemoTagMusic => 'Music';

  @override
  String get guestDemoTagHiking => 'Hiking';

  @override
  String get guestDemoTagView => 'View';

  @override
  String get guestDemoTagBar => 'Bar';

  @override
  String get guestDemoTagMuseum => 'Museum';

  @override
  String get guestDemoTagArt => 'Art';

  @override
  String get guestDemoTagGarden => 'Garden';

  @override
  String get guestDemoTagJazz => 'Jazz';

  @override
  String get guestDemoTagWine => 'Wine';

  @override
  String get guestDemoTagCozy => 'Cozy';

  @override
  String get guestDemoTagQuiet => 'Quiet';

  @override
  String get guestDemoTagDrinks => 'Drinks';

  @override
  String get guestDemoTagEvening => 'Evening';

  @override
  String get guestDemoRelaxed1Name => 'Parkside Morning Reset';

  @override
  String get guestDemoRelaxed1Meta => '09:00 • Free';

  @override
  String get guestDemoRelaxed1Desc =>
      'Easy loops under the trees — wake the body without racing.';

  @override
  String get guestDemoRelaxed2Name => 'Slow Matcha Counter';

  @override
  String get guestDemoRelaxed2Meta => '12:30 • €€';

  @override
  String get guestDemoRelaxed2Desc =>
      'Sit deep, sip slow — let the morning walk settle in.';

  @override
  String get guestDemoRelaxed3Name => 'Sunset Terrace';

  @override
  String get guestDemoRelaxed3Meta => '18:00 • €€€';

  @override
  String get guestDemoRelaxed3Desc => 'Golden hour, one drink, nowhere to be.';

  @override
  String get guestDemoFoodie1Name => 'Oven & Oak Bakery';

  @override
  String get guestDemoFoodie1Meta => '08:00 • €';

  @override
  String get guestDemoFoodie1Desc =>
      'Fresh pastries and coffee to start the day.';

  @override
  String get guestDemoFoodie2Name => 'Market Hall Bites';

  @override
  String get guestDemoFoodie2Meta => '12:00 • €€';

  @override
  String get guestDemoFoodie2Desc => 'Tasting trays from local vendors.';

  @override
  String get guestDemoFoodie3Name => 'Chef\'s Table Pop-up';

  @override
  String get guestDemoFoodie3Meta => '19:00 • €€€';

  @override
  String get guestDemoFoodie3Desc => 'Small plates and seasonal specials.';

  @override
  String get guestDemoSocial1Name => 'Park Run Meet-up';

  @override
  String get guestDemoSocial1Meta => '07:30 • Free';

  @override
  String get guestDemoSocial1Desc => 'Quick miles with friendly faces.';

  @override
  String get guestDemoSocial2Name => 'Market Hall Long Table';

  @override
  String get guestDemoSocial2Meta => '13:00 • €€';

  @override
  String get guestDemoSocial2Desc =>
      'Shared plates and easy chatter — recover together after the run.';

  @override
  String get guestDemoSocial3Name => 'Late Live Set';

  @override
  String get guestDemoSocial3Meta => '21:00 • €€';

  @override
  String get guestDemoSocial3Desc => 'Loud speakers, cold drinks, big vibes.';

  @override
  String get guestDemoAdventurous1Name => 'Ridge Sunrise Hike';

  @override
  String get guestDemoAdventurous1Meta => '06:00 • Free';

  @override
  String get guestDemoAdventurous1Desc =>
      'Steep trail, wide views, early start.';

  @override
  String get guestDemoAdventurous2Name => 'Quayside Lunch Deck';

  @override
  String get guestDemoAdventurous2Meta => '13:00 • €€';

  @override
  String get guestDemoAdventurous2Desc =>
      'Long lunch with harbor views — legs up, calories back, no rush.';

  @override
  String get guestDemoAdventurous3Name => 'Waterfront Sundown Bar';

  @override
  String get guestDemoAdventurous3Meta => '19:00 • €€';

  @override
  String get guestDemoAdventurous3Desc =>
      'Golden-hour drinks and small plates — land the day softly.';

  @override
  String get guestDemoCultural1Name => 'Modern Wing Tour';

  @override
  String get guestDemoCultural1Meta => '10:00 • €';

  @override
  String get guestDemoCultural1Desc => 'Guided look at the new exhibition.';

  @override
  String get guestDemoCultural2Name => 'Sculpture Garden Café';

  @override
  String get guestDemoCultural2Meta => '14:00 • €';

  @override
  String get guestDemoCultural2Desc =>
      'Espresso between wings — let what you saw sink in.';

  @override
  String get guestDemoCultural3Name => 'Canal-Side Jazz Room';

  @override
  String get guestDemoCultural3Meta => '20:00 • €€';

  @override
  String get guestDemoCultural3Desc =>
      'Dim lights, small band — culture without the sprint finish.';

  @override
  String get guestDemoRomantic1Name => 'Courtyard Café';

  @override
  String get guestDemoRomantic1Meta => '10:00 • €€';

  @override
  String get guestDemoRomantic1Desc => 'Quiet corners and shared pastries.';

  @override
  String get guestDemoRomantic2Name => 'Independent Bookshop Browse';

  @override
  String get guestDemoRomantic2Meta => '15:00 • €';

  @override
  String get guestDemoRomantic2Desc => 'Piles of reads and vinyl in the back.';

  @override
  String get guestDemoRomantic3Name => 'Low-lit Wine Room';

  @override
  String get guestDemoRomantic3Meta => '20:00 • €€€';

  @override
  String get guestDemoRomantic3Desc => 'Small pours, soft music, no rush.';

  @override
  String get guestDemoRelaxed1MoodyAbout =>
      '📚 What kind of place is this?\n\nCity park with loops under mature trees—wide gravel paths, a duck pond pinch, and benches every few curves. Locals walk dogs, read on blankets; there is no entry fee.\n\n---\n🗺️ Layout & vibe\n\nMostly flat, stroller-friendly circuits (~2 km on the outer loop). Mornings are misty-quiet; you will hear more birds than traffic from here.\n\n---\n⏱️ Good to know\n\nFree to enter. Washrooms near the main entrance. After rain, shoes that forgive mud are a win.\n\n---\n💬 Moody says\n\nNo pace to hit—if you match steps to breath for one lap, you already won.';

  @override
  String get guestDemoRelaxed2MoodyAbout =>
      '📚 What kind of place is this?\n\nJapanese-style matcha bar: stone-ground ceremonial grade, oat and soy milk, and seasonal lattes (think sakura in spring, yuzu in winter). Pastries stay light—mochi muffins, sesame cookies, minimal sugar crash.\n\n---\n🪑 Space & vibe\n\nLow counter, matte ceramics, soft daylight. Baristas explain matcha grades without the lecture. Laptop corners exist, but phones-down regulars get the best foam.\n\n---\n⏱️ Good to know\n\nMid-range spend (snack + drink). Busy 12:00–14:00—slide in a bit earlier for a slower pour.\n\n---\n💬 Moody says\n\nSit until the morning you already had settles in your bones—that is the whole assignment.';

  @override
  String get guestDemoRelaxed3MoodyAbout =>
      '📚 What kind of place is this?\n\nRooftop terrace restaurant: Mediterranean-leaning small plates (mezze, grilled fish, burrata), natural wines by the glass, and bottles that lean Italian + Portuguese.\n\n---\n🌅 Why sunset works here\n\nWest-facing glass rail—the sky does the lighting design. Book ahead; walk-ins sometimes grab bar spots when lucky.\n\n---\n⏱️ Good to know\n\nUpper-mid price tier. Even summer evenings get breezy off the water—bring a light layer.\n\n---\n💬 Moody says\n\nOne drink, one horizon, zero inbox—pretend that is the only notification that matters.';

  @override
  String get guestDemoFoodie1MoodyAbout =>
      '📚 What kind of place is this?\n\nArtisan bakery + coffee bar: sourdough loaves, butter croissants laminated in-house, seasonal fruit tarts. Espresso rotates single-origin weekly; batch brew if you are sprinting.\n\n---\n🥐 What to order\n\nAsk for whatever left the oven in the last hour. Savory danishes vanish first on Saturdays.\n\n---\n⏱️ Good to know\n\nOpens early; expect a friendly line 09:00–10:30 weekends. Card-only at the counter.\n\n---\n💬 Moody says\n\nCrumbs on your sleeve count as a five-star review—lean in.';

  @override
  String get guestDemoFoodie2MoodyAbout =>
      '📚 What kind of place is this?\n\nCovered market hall: 30+ stalls—Dutch cheeses, roti, oysters, Korean bowls, and herring if you are feeling brave. Built for tasting: small plates so you can mix countries in one lunch.\n\n---\n🍽️ How it works\n\nOrder from vendors, meet at the long communal tables in the middle. Most stalls are cashless; allergen cards are posted.\n\n---\n⏱️ Good to know\n\nRush hour 12:00–13:30—scout a table first, then divide and conquer.\n\n---\n💬 Moody says\n\nGrab one thing you cannot pronounce—I will be smug when you love it.';

  @override
  String get guestDemoFoodie3MoodyAbout =>
      '📚 What kind of place is this?\n\nEvening chef counter / pop-up dinner: open kitchen, menu that shifts every few weeks, small plates or a set menu. Wine list leans acid-forward whites, light gamay, orange bottles, natural picks.\n\n---\n🔥 Kitchen style\n\nLive fire + local produce call-outs on the board. Vegetarian route exists with a heads-up when you book.\n\n---\n⏱️ Good to know\n\nReservation strongly recommended. Casual-nice dress. Price tier is splurge-okay.\n\n---\n💬 Moody says\n\nSay yes to the server is essential bite—that is where the plot twist lives.';

  @override
  String get guestDemoSocial1MoodyAbout =>
      '📚 What kind of place is this?\n\nOrganised park run / group jog at a fixed meeting pin—about 5 km, all paces welcome, volunteer hosts. Free to join; barcode timing if you like stats.\n\n---\n👟 Who shows up\n\nFirst-timers, stroller parents, and speedy folks who lap politely. Zero podium pressure unless you want it.\n\n---\n⏱️ Good to know\n\nQuick briefing a few minutes before go-time. Bag drop is honour-system near the flag—travel light if you can.\n\n---\n💬 Moody says\n\nHigh-five a stranger or just nod—both count as social XP today.';

  @override
  String get guestDemoSocial2MoodyAbout =>
      '📚 What kind of place is this?\n\nMarket-hall communal tables: stalls all around you, shared benches, loud happy chaos. Order small plates from different vendors and trade bites like a very civilised buffet raid.\n\n---\n🍻 The social cheat code\n\nLong tables = easy icebreakers—ask what someone ordered and steal a recommendation.\n\n---\n⏱️ Good to know\n\nPeak 13:00–14:00. Wipe crumbs when you leave—staff quietly love you for it.\n\n---\n💬 Moody says\n\nSteal a fry, share a story, blame me later.';

  @override
  String get guestDemoSocial3MoodyAbout =>
      '📚 What kind of place is this?\n\nLive-music bar: indie bands midweek, louder DJ nights on weekends. Craft beer taps + classic cocktails. Standing room near the stage; booths if you arrive with a plan.\n\n---\n🎶 Sound & scene\n\nSet times often live on socials. Earplugs at the bar if you like your hearing long-term.\n\n---\n⏱️ Good to know\n\nCover charge some Fridays/Saturdays. 18+ after 22:00. Coat check by the door.\n\n---\n💬 Moody says\n\nScratchy voice tomorrow means you did nightlife correctly.';

  @override
  String get guestDemoAdventurous1MoodyAbout =>
      '📚 What kind of place is this?\n\nRidge trail loop just outside the city: steep first kilometre, open viewpoints, roots and gravel underfoot. Not climbing ropes—just honest hills most fit hikers finish in 2–3 hours with snacks.\n\n---\n🥾 Gear & safety\n\nTrail shoes or boots, at least 1L water, wind layer at the top. Offline map helps—signal thins on the spine.\n\n---\n⏱️ Good to know\n\nFree access; small parking lot fills by 07:30 on sunny weekends. Sunrise starts are cooler and calmer.\n\n---\n💬 Moody says\n\nSnap the photo, then pocket the phone for ten minutes—the view rented IMAX seats for you.';

  @override
  String get guestDemoAdventurous2MoodyAbout =>
      '📚 What kind of place is this?\n\nHarbor-front deck restaurant: seafood towers, whole grilled fish, bitterballen for the table, Dutch gin cocktails. Big windows on the water; heaters on the pier when it chills.\n\n---\n⚓ Why it fits after a hike\n\nSalty, high-protein, celebratory—chairs you can sink into for two hours without guilt.\n\n---\n⏱️ Good to know\n\nBook on blue-sky days. Seagulls are professionals—guard your fries like state secrets.\n\n---\n💬 Moody says\n\nOrder the messy thing; napkins exist for exactly this moment.';

  @override
  String get guestDemoAdventurous3MoodyAbout =>
      '📚 What kind of place is this?\n\nWaterfront bar at golden hour: spritz list, local beers, small plates—oysters, charcuterie, croquettes. The room slowly shifts from standing-and-chatting to lounge-and-watch-the-sky.\n\n---\n🍹 Drinks\n\nNatural wine by the glass; negroni riffs on tap in summer.\n\n---\n⏱️ Good to know\n\nHappy hour some weekdays 17:00–19:00. Wind picks up—jacket or borrow a blanket from the host stand.\n\n---\n💬 Moody says\n\nStay for one more round if the sky is still showing off.';

  @override
  String get guestDemoCultural1MoodyAbout =>
      '📚 What kind of place is this?\n\nMuseum new wing with a rotating contemporary show—think large photography, installation, or mixed media. Check the banner at the entrance for this month\'s focus.\n\n---\n🎧 Extras\n\nQR audio guides; Dutch + English wall texts. Gift shop stocks exhibition posters and weirdly good postcards.\n\n---\n⏱️ Good to know\n\nTimed tickets on busy weekends. Café upstairs is a legit reset stop between floors.\n\n---\n💬 Moody says\n\nIf one piece rents space in your head for days, the ticket already paid rent back.';

  @override
  String get guestDemoCultural2MoodyAbout =>
      '📚 What kind of place is this?\n\nSculpture garden café tucked between museum wings: espresso, filter coffee, cardamom buns, light lunch salads. Glass walls look straight onto bronze pieces and clipped hedges.\n\n---\n🌿 Seating\n\nTerrace when it is dry; mid-century chairs inside when it drizzles—both feel intentional.\n\n---\n⏱️ Good to know\n\nGarden access sometimes needs a museum ticket—read the sign at the gate. Sunday brunch queues; weekday afternoons are softer.\n\n---\n💬 Moody says\n\nStare at the foam, then at a statue—let your brain file what you just saw.';

  @override
  String get guestDemoCultural3MoodyAbout =>
      '📚 What kind of place is this?\n\nIntimate canal-side jazz room: house trio on quieter nights, guest bands weekends. By-the-glass wines from Loire, Alto Adige, and a few skin-contact bottles; classic cocktails; cheese and charcuterie boards.\n\n---\n🎷 Room & sound\n\nAbout 60 seats—close enough to read the bassist\'s face. Two sets with a breather; service goes whisper-quiet during solos.\n\n---\n⏱️ Good to know\n\nReservations strongly recommended after 19:00. Smart-casual dress keeps the room feeling special.\n\n---\n💬 Moody says\n\nHum on the walk home—if you do, I nailed the encore pick.';

  @override
  String get guestDemoRomantic1MoodyAbout =>
      '📚 What kind of place is this?\n\nCourtyard café behind a brick arch: viennoiserie, Dutch apple tart, savory galettes at lunch. Coffee from a small Rotterdam roaster; tea list leans floral and cozy.\n\n---\n🪴 Atmosphere\n\nFountain murmur, ivy walls, a handful of two-tops that feel tucked away. Shared blankets appear on chilly evenings.\n\n---\n⏱️ Good to know\n\nWeekend brunch books fast—walk-in luck often after 14:00. Card and contactless.\n\n---\n💬 Moody says\n\nOrder one pastry to split and fight over the last crumb—I am taking notes.';

  @override
  String get guestDemoRomantic2MoodyAbout =>
      '📚 What kind of place is this?\n\nIndependent bookshop—not a chain. Front tables: new fiction and translated lit. Middle aisles: essays, design, travel. Back room: curated used stacks plus a vinyl corner (jazz, soul, small Dutch indie labels).\n\n---\n🎧 Listen & browse\n\nPreview headphones at the counter. Staff shelf tags are spicy opinions, not corporate blurbs. Friday readings sometimes—chalkboard by the stairs has the schedule.\n\n---\n⏱️ Good to know\n\nPhones on quiet, please. Bags at the door. Monthly discount cart lives by the stairs—treasure hunt energy.\n\n---\n💬 Moody says\n\nHunt the title that feels like it waited for you—I will take full credit if you find it.';

  @override
  String get guestDemoRomantic3MoodyAbout =>
      '📚 What kind of place is this?\n\nLow-lit wine room with 80+ bottles on display—Italy (Barbera, Etna, Chianti riserva), France (Beaujolais, Loire Chenin, modest Bordeaux), Spain (Rioja, Priorat), plus orange wines and pet-nat from small Dutch importers. Coravin pours on pricier labels.\n\n---\n🍷 How drinking works\n\nRotating by-the-glass list (roughly 6 whites, 6 reds, 2 skin-contact). Bottles pair with small plates: olives, anchovies, burrata, charcuterie. Corkage waived with a food order on many nights—ask when you sit.\n\n---\n⏱️ Good to know\n\nSommelier does table rounds—say surprise us and mean it. Reservations after 19:30; smart-casual keeps the glow right.\n\n---\n💬 Moody says\n\nPick one bottle you cannot pronounce—we will toast to courage and pretend we are sommeliers.';

  @override
  String get dayMon => 'Monday';

  @override
  String get dayTue => 'Tuesday';

  @override
  String get dayWed => 'Wednesday';

  @override
  String get dayThu => 'Thursday';

  @override
  String get dayFri => 'Friday';

  @override
  String get daySat => 'Saturday';

  @override
  String get daySun => 'Sunday';

  @override
  String get monthJan => 'jan';

  @override
  String get monthFeb => 'feb';

  @override
  String get monthMar => 'mar';

  @override
  String get monthApr => 'apr';

  @override
  String get monthMay => 'may';

  @override
  String get monthJun => 'jun';

  @override
  String get monthJul => 'jul';

  @override
  String get monthAug => 'aug';

  @override
  String get monthSep => 'sep';

  @override
  String get monthOct => 'oct';

  @override
  String get monthNov => 'nov';

  @override
  String get monthDec => 'dec';

  @override
  String get myDayEmptyDayTitle => 'Your day is empty ✨';

  @override
  String get myDayEmptyDaySubtitle =>
      'Let Moody make a plan for your mood today';

  @override
  String get myDayPlanWithMoodyButton => 'Plan my day with Moody';

  @override
  String get myDayExploreActivitiesButton => 'Explore activities';

  @override
  String get myDayExploreNearbyButton => 'Explore Nearby';

  @override
  String get myDayAskMoodyButton => 'Ask Moody';

  @override
  String get myDayOpenFullPlaceDetails => 'Open full place';

  @override
  String get placeQuickSheetAddToMyDayCta => '+add to my day';

  @override
  String myDayMoodStreakBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get myDayGetReadyButton => 'Get Ready';

  @override
  String get myDayRightNow => 'RIGHT NOW';

  @override
  String get myDayStatusError => '⚠️ ERROR';

  @override
  String get myDayStatusUnableToLoad => 'Unable to load status';

  @override
  String get myDayOpenGoogleMaps => 'Google Maps';

  @override
  String get myDayOpenAppleMaps => 'Apple Maps';

  @override
  String get agendaTitle => 'My Plans';

  @override
  String get agendaStatusDone => 'DONE';

  @override
  String get agendaStatusNow => 'NOW';

  @override
  String get agendaStatusUpcoming => 'UPCOMING';

  @override
  String get agendaStatusCancelled => 'CANCELLED';

  @override
  String get agendaHeaderToday => 'Today';

  @override
  String get agendaHeaderTomorrow => 'Tomorrow';

  @override
  String get agendaHeaderYesterday => 'Yesterday';

  @override
  String get agendaTodayEmpty => 'Today is still empty';

  @override
  String get agendaTodaySubtitle =>
      'Let Moody plan your day based on your mood';

  @override
  String get agendaTomorrowEmpty => 'Tomorrow is still free';

  @override
  String get agendaTomorrowSubtitle => 'Plan what you want to do tomorrow';

  @override
  String agendaDayEmpty(String dayName) {
    return '$dayName is still empty';
  }

  @override
  String agendaDaySubtitle(String dayName) {
    return 'Want to plan for $dayName?';
  }

  @override
  String get agendaFarFutureEmpty => 'Nothing planned yet';

  @override
  String get agendaFarFutureSubtitle => 'Plan activities for this day';

  @override
  String get agendaPlanWithMoody => 'Plan with Moody';

  @override
  String get agendaAddActivity => 'Add activity';

  @override
  String get agendaEmptyPlansTitle => 'No activities planned yet';

  @override
  String get agendaEmptyPlansSubtitle =>
      'Your day is all yours. Want Moody to build the perfect plan for you?';

  @override
  String get agendaMoodyOverviewEmpty =>
      'Today\'s still wide open — we\'ll make it good ✨';

  @override
  String get agendaMoodyOverviewOne =>
      'Here\'s what I lined up for you today 👀';

  @override
  String get agendaMoodyOverviewTwo => 'Looking solid today';

  @override
  String get agendaMoodyOverviewMany => 'I\'ve got a nice stack ready for you';

  @override
  String get agendaMoodyOverviewLoading => 'Let me peek at your day...';

  @override
  String get agendaMoodyOverviewError => 'Keeping it simple for today';

  @override
  String get agendaMoodyCardLineDone =>
      'Nice — you already checked this one off.';

  @override
  String get agendaMoodyCardLineActive =>
      'You\'re in the middle of this — good energy.';

  @override
  String get agendaMoodyCardLineBooked =>
      'Solid pick — this one\'s locked in for you.';

  @override
  String get agendaMoodyCardLineDefault => 'You\'re going to enjoy this one.';

  @override
  String get agendaViewActivityCta => 'View activity';

  @override
  String get agendaRouteCta => 'Route';

  @override
  String get agendaUntitledActivity => 'Untitled Activity';

  @override
  String get agendaNoDescription => 'No description available';

  @override
  String get agendaLocationTBD => 'Location TBD';

  @override
  String agendaDeleteDialogBody(String title) {
    return '“$title” will be removed from your planner.';
  }

  @override
  String get agendaDeleteDialogBack => 'Back';

  @override
  String get agendaDeleteDialogConfirm => 'Delete';

  @override
  String get exploreCategoryAll => 'All';

  @override
  String get exploreCategoryPopular => 'Popular';

  @override
  String get exploreCategoryAccommodations => 'Accommodations';

  @override
  String get exploreCategoryNature => 'Nature';

  @override
  String get exploreCategoryCulture => 'Culture';

  @override
  String get exploreCategoryFood => 'Food';

  @override
  String get exploreCategoryActivities => 'Activities';

  @override
  String get exploreCategoryHistory => 'History';

  @override
  String get exploreFilterAdditionalOptions => 'Additional Options';

  @override
  String get exploreFilterParking => 'Parking';

  @override
  String get exploreFilterTransport => 'Transport';

  @override
  String get exploreFilterCreditCards => 'Credit Cards';

  @override
  String get exploreFilterWifi => 'Wi-Fi';

  @override
  String get exploreFilterCharging => 'Charging';

  @override
  String get exploreFilterInstagrammable => 'Instagrammable';

  @override
  String get exploreFilterArtisticDesign => 'Artistic Design';

  @override
  String get exploreFilterAestheticSpaces => 'Aesthetic Spaces';

  @override
  String get exploreFilterScenicViews => 'Scenic Views';

  @override
  String get exploreFilterBestAtNight => 'Best at Night';

  @override
  String get exploreFilterBestAtSunset => 'Best at Sunset';

  @override
  String get exploreNoPlacesOnMap => 'No places to display on map';

  @override
  String get timeLabelToday => 'Today';

  @override
  String get timeLabelTomorrow => 'Tomorrow';

  @override
  String get timeLabelMorning => 'Morning';

  @override
  String get timeLabelAfternoon => 'Afternoon';

  @override
  String get timeLabelEvening => 'Evening';

  @override
  String get exploreFilterIndoorOnly => 'Indoor Only';

  @override
  String get exploreFilterOutdoorOnly => 'Outdoor Only';

  @override
  String get exploreFilterWeatherSafe => 'Weather-Safe';

  @override
  String get exploreFilterOpenNow => 'Open Now';

  @override
  String get exploreFilterQuiet => 'Quiet';

  @override
  String get exploreFilterLively => 'Lively';

  @override
  String get exploreFilterRomanticVibe => 'Romantic Vibe';

  @override
  String get exploreFilterSurpriseMe => 'Surprise Me';

  @override
  String get exploreFilterVegan => 'Vegan';

  @override
  String get exploreFilterVegetarian => 'Vegetarian';

  @override
  String get exploreFilterHalal => 'Halal';

  @override
  String get exploreFilterGlutenFree => 'Gluten-Free';

  @override
  String get exploreFilterPescatarian => 'Pescatarian';

  @override
  String get exploreFilterNoAlcohol => 'No Alcohol';

  @override
  String get exploreFilterWheelchairAccessible => 'Wheelchair Accessible';

  @override
  String get exploreFilterLgbtqFriendly => 'LGBTQ+ Friendly';

  @override
  String get exploreFilterSensoryFriendly => 'Sensory-friendly';

  @override
  String get exploreFilterFamilyFriendly => 'Family-friendly';

  @override
  String get exploreFilterSeniorFriendly => 'Senior-Friendly';

  @override
  String get exploreFilterBabyFriendly => 'Baby-Friendly';

  @override
  String get exploreFilterBlackOwned => 'Black-owned';

  @override
  String get exploreFilterPriceRange => 'Price Range (€)';

  @override
  String get exploreFilterMaxDistance => 'Maximum Distance (km)';

  @override
  String get exploreErrorLocationRequiredTitle => 'Location required';

  @override
  String get exploreErrorLoadingPlacesTitle => 'Error loading places';

  @override
  String get exploreErrorLocationBody =>
      'Please enable location services or set your location in settings to discover places near you.';

  @override
  String get exploreErrorEnableLocation => 'Enable location';

  @override
  String get exploreAdvancedFiltersTitle => 'Advanced Filters';

  @override
  String exploreFiltersActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters active',
      one: '1 filter active',
    );
    return '$_temp0';
  }

  @override
  String exploreMoodyHintFiltersActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters are on',
      one: '1 filter is on',
    );
    return 'Nice, $_temp0.';
  }

  @override
  String get exploreMoodyHintFiltersIntro =>
      'I\'m Moody. Pick a few filters and I\'ll find better matches right away.';

  @override
  String get exploreClearAll => 'Clear all';

  @override
  String get exploreSectionQuickSuggestions => 'Quick picks';

  @override
  String get exploreSectionDietaryPreferences => 'Dietary preferences';

  @override
  String get exploreSectionAccessibilityInclusion =>
      'Accessibility & inclusion';

  @override
  String get exploreSectionComfortConvenience => 'Practical';

  @override
  String get exploreSectionPhotoAesthetic => 'Photo & vibe';

  @override
  String exploreSaveFiltersWithCount(int count) {
    return 'Save $count filters';
  }

  @override
  String get exploreSaveFilters => 'Save filters';

  @override
  String get exploreQuickFilters => 'Quick filters';

  @override
  String get exploreSearchHint => 'Search activities, restaurants, museums...';

  @override
  String get exploreCategoryChipOutdoor => 'Outdoor';

  @override
  String get exploreCategoryChipShopping => 'Shopping';

  @override
  String get exploreCategoryChipNightlife => 'Nightlife';

  @override
  String get explorePriceLevelBudget => 'Budget';

  @override
  String get explorePriceLevelModerate => 'Moderate';

  @override
  String get explorePriceLevelExpensive => 'Expensive';

  @override
  String get explorePriceLevelLuxury => 'Luxury';

  @override
  String get exploreMoodAdventure => 'Adventure';

  @override
  String get exploreMoodCreative => 'Creative';

  @override
  String get exploreMoodRelaxed => 'Relaxed';

  @override
  String get exploreMoodMindful => 'Mindful';

  @override
  String get exploreMoodRomantic => 'Romantic';

  @override
  String get exploreAddToMyDayDayLabel => 'Day';

  @override
  String get exploreAddToMyDayPickDate => 'Pick date';

  @override
  String exploreAddToMyDaySelectedDate(String date) {
    return 'Selected: $date';
  }

  @override
  String get exploreAddToMyDayTimeLabel => 'Time';

  @override
  String get exploreDatePickerHelp => 'Choose a date';

  @override
  String get exploreDatePickerConfirm => 'Choose';

  @override
  String get exploreTimeGreetingMorning => 'Good morning ☀️';

  @override
  String get exploreTimeGreetingAfternoon => 'Good afternoon 🌤';

  @override
  String get exploreTimeGreetingEvening => 'Good evening 🌙';

  @override
  String get exploreTimeGreetingLateNight => 'Late night vibes 🌙';

  @override
  String get exploreSectionBecauseFood => 'Because you love food 🍜';

  @override
  String get exploreSectionBecauseCulture => 'Because you love culture 🏛️';

  @override
  String get exploreSectionBecauseNightlife => 'Because you love nightlife 🌙';

  @override
  String get exploreSectionBecauseOutdoor => 'Because you love the outdoors 🌿';

  @override
  String get exploreSectionBecauseCoffee => 'Because you love coffee ☕';

  @override
  String exploreSectionTrendingInCity(String city) {
    return 'Trending in $city 🔥';
  }

  @override
  String get exploreSectionPerfectVibe => 'Perfect for your vibe ✨';

  @override
  String get exploreSectionPerfectSolo => 'Perfect for solo days ✨';

  @override
  String get exploreSectionPerfectGroups => 'Perfect for groups 👥';

  @override
  String get exploreSectionSomethingDifferent => 'Something different 🎲';

  @override
  String get exploreSeeAll => 'See all';

  @override
  String get exploreLoadMore => 'Load more →';

  @override
  String get exploreEndOfCachedPool =>
      'You have seen all ideas saved for this area. Pull down to refresh for new suggestions.';

  @override
  String get exploreSectionErrorRetry => 'Could not load places — tap to retry';

  @override
  String get exploreOfflineShowingCached => 'Offline — showing cached results';

  @override
  String get exploreOfflineEmptyBody =>
      'Connect to the internet\nto discover places';

  @override
  String explorePlaceDescriptionFallback(String name) {
    return 'Explore $name';
  }

  @override
  String exploreContextStripDiscovering(String city) {
    return 'Discovering $city';
  }

  @override
  String exploreContextStripSearch(String query) {
    return 'Showing results for \"$query\"';
  }

  @override
  String exploreContextStripFiltered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters on',
      one: '1 filter on',
    );
    return '$_temp0';
  }

  @override
  String exploreContextPlacesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get explorePeekViewFullPlace => 'View full place';

  @override
  String get chatSheetMoodyName => 'Moody';

  @override
  String get chatSheetErrorMessage =>
      'Oops! I\'m having trouble connecting right now. Can you try again? 🤔';

  @override
  String get chatSheetEmptyStateBody =>
      'I know the city like the back of my hand! Tell me your mood, and I\'ll craft the perfect day just for you. Whether you\'re feeling adventurous, romantic, or need some chill vibes - I\'ve got you covered! 🎯';

  @override
  String get chatSheetCraftingMessage => 'Moody is typing...';

  @override
  String get chatSheetInputHint => 'What\'s your mood today?';

  @override
  String get chatSheetInputHintAboutPlace => 'Ask about this place…';

  @override
  String get chatSheetInputHintDayChat => 'Chat with Moody about your day…';

  @override
  String get chatSheetMicTooltip => 'Speak your question';

  @override
  String get moodyPlaceThreadFallbackPlace => 'this spot';

  @override
  String moodyPlaceThreadExploreV0Friendly(String place) {
    return 'Ooh—$place. I\'m here with you. Crowd, light, best time… what do you want to know?';
  }

  @override
  String moodyPlaceThreadExploreV1Friendly(String place) {
    return '$place… nice. Where are you stuck—timing, vibe, or a backup nearby?';
  }

  @override
  String moodyPlaceThreadExploreV2Friendly(String place) {
    return 'Ok I\'m zoomed in on $place. No brochure voice—just ask.';
  }

  @override
  String moodyPlaceThreadExploreV3Friendly(String place) {
    return 'If you\'re stress-testing $place: what do you need right now—quiet, energy, plan B?';
  }

  @override
  String moodyPlaceThreadExploreV4Friendly(String place) {
    return '$place\'s pinned. What do you want to know before you drop it in your day?';
  }

  @override
  String moodyPlaceThreadExploreV5Friendly(String place) {
    return 'Say the awkward part about $place—kid chaos? date night? \"is this dumb right now?\" All fine.';
  }

  @override
  String moodyPlaceThreadExploreV0Professional(String place) {
    return 'Let\'s look at $place. What do you need: crowds, lighting, or the best time to go?';
  }

  @override
  String moodyPlaceThreadExploreV1Professional(String place) {
    return 'For $place, what\'s unclear—schedule, atmosphere, or a nearby alternative?';
  }

  @override
  String moodyPlaceThreadExploreV2Professional(String place) {
    return 'Focus: $place. Ask your question—I\'ll answer plainly, without brochure language.';
  }

  @override
  String moodyPlaceThreadExploreV3Professional(String place) {
    return 'About $place: do you need calm, energy, or a backup option?';
  }

  @override
  String moodyPlaceThreadExploreV4Professional(String place) {
    return '$place is set. What information do you need before you add it to your day?';
  }

  @override
  String moodyPlaceThreadExploreV5Professional(String place) {
    return 'Ask about $place—fit, timing, or practical concerns.';
  }

  @override
  String moodyPlaceThreadExploreV0Direct(String place) {
    return '$place—crowds, light, best time. What?';
  }

  @override
  String moodyPlaceThreadExploreV1Direct(String place) {
    return '$place. Timing, vibe, backup?';
  }

  @override
  String moodyPlaceThreadExploreV2Direct(String place) {
    return '$place. Your question?';
  }

  @override
  String moodyPlaceThreadExploreV3Direct(String place) {
    return '$place. Quiet, energy, or plan B?';
  }

  @override
  String moodyPlaceThreadExploreV4Direct(String place) {
    return '$place. What do you need to know?';
  }

  @override
  String moodyPlaceThreadExploreV5Direct(String place) {
    return '$place—say what you\'re checking.';
  }

  @override
  String moodyPlaceThreadExploreV0Energetic(String place) {
    return 'Ooh—$place! Hit me: crowds, light, best time… what do you want to know? ✨';
  }

  @override
  String moodyPlaceThreadExploreV1Energetic(String place) {
    return '$place… love it. Where are you stuck—time, vibe, plan B? 🔥';
  }

  @override
  String moodyPlaceThreadExploreV2Energetic(String place) {
    return 'Locked on $place—no brochure voice, just ask 💬';
  }

  @override
  String moodyPlaceThreadExploreV3Energetic(String place) {
    return 'Stress-testing $place: quiet, energy, or backup nearby? ⚡';
  }

  @override
  String moodyPlaceThreadExploreV4Energetic(String place) {
    return '$place\'s pinned—what do you want to know before you drop it in your day? 🙌';
  }

  @override
  String moodyPlaceThreadExploreV5Energetic(String place) {
    return 'Say the awkward part about $place—all good 😅';
  }

  @override
  String get moodyPlaceThreadMyDayV0FriendlyEmpty =>
      'This free slice—what do you want sharp on: swap, timing, or \"does this even fit\"?';

  @override
  String moodyPlaceThreadMyDayV0FriendlyPlace(String place) {
    return 'That $place block—say what\'s bugging you: swap, timing, vibe…';
  }

  @override
  String get moodyPlaceThreadMyDayV1FriendlyEmpty =>
      'I\'m watching this empty slot with you. What would you *want* to feel today?';

  @override
  String moodyPlaceThreadMyDayV1FriendlyPlace(String place) {
    return '$place on your day—tweak it or trade it?';
  }

  @override
  String get moodyPlaceThreadMyDayV2FriendlyEmpty =>
      'Free time. No question is too small.';

  @override
  String moodyPlaceThreadMyDayV2FriendlyPlace(String place) {
    return 'About $place—real talk: are you unsure it fits today?';
  }

  @override
  String get moodyPlaceThreadMyDayV3FriendlyEmpty =>
      'Let\'s keep this slot human: what\'s the actual question?';

  @override
  String moodyPlaceThreadMyDayV3FriendlyPlace(String place) {
    return '$place… backup, better timing, or just certainty?';
  }

  @override
  String get moodyPlaceThreadMyDayV4FriendlyEmpty =>
      'I\'m here. What do you want to know about this part of your day?';

  @override
  String moodyPlaceThreadMyDayV4FriendlyPlace(String place) {
    return 'I\'m on $place. What part of the plan is giving you friction?';
  }

  @override
  String get moodyPlaceThreadMyDayV5FriendlyEmpty =>
      'Go—I\'ll add context, you steer the vibe.';

  @override
  String moodyPlaceThreadMyDayV5FriendlyPlace(String place) {
    return '$place: say what you need. I\'ll match it.';
  }

  @override
  String get moodyPlaceThreadMyDayV0ProfessionalEmpty =>
      'This open block: swap, timing, or does it fit your plan?';

  @override
  String moodyPlaceThreadMyDayV0ProfessionalPlace(String place) {
    return 'Your $place block: what do you need—swap, timing, or atmosphere?';
  }

  @override
  String get moodyPlaceThreadMyDayV1ProfessionalEmpty =>
      'Empty slot: what do you want to achieve today?';

  @override
  String moodyPlaceThreadMyDayV1ProfessionalPlace(String place) {
    return '$place on your schedule: adjust or replace?';
  }

  @override
  String get moodyPlaceThreadMyDayV2ProfessionalEmpty =>
      'Free time. What question matters most?';

  @override
  String moodyPlaceThreadMyDayV2ProfessionalPlace(String place) {
    return 'About $place: does it fit today\'s plan?';
  }

  @override
  String get moodyPlaceThreadMyDayV3ProfessionalEmpty =>
      'This time window: what\'s the core question?';

  @override
  String moodyPlaceThreadMyDayV3ProfessionalPlace(String place) {
    return '$place: backup, better timing, or certainty?';
  }

  @override
  String get moodyPlaceThreadMyDayV4ProfessionalEmpty =>
      'How can I help with this part of your day?';

  @override
  String moodyPlaceThreadMyDayV4ProfessionalPlace(String place) {
    return 'For $place: where is your plan sticking?';
  }

  @override
  String get moodyPlaceThreadMyDayV5ProfessionalEmpty =>
      'Ask your question; I\'ll help with context.';

  @override
  String moodyPlaceThreadMyDayV5ProfessionalPlace(String place) {
    return '$place: what do you need?';
  }

  @override
  String get moodyPlaceThreadMyDayV0DirectEmpty =>
      'Open block. Swap, timing, fit?';

  @override
  String moodyPlaceThreadMyDayV0DirectPlace(String place) {
    return '$place block. Swap, timing, vibe?';
  }

  @override
  String get moodyPlaceThreadMyDayV1DirectEmpty => 'Empty slot. What feeling?';

  @override
  String moodyPlaceThreadMyDayV1DirectPlace(String place) {
    return '$place. Tweak or trade?';
  }

  @override
  String get moodyPlaceThreadMyDayV2DirectEmpty => 'Free. Question?';

  @override
  String moodyPlaceThreadMyDayV2DirectPlace(String place) {
    return '$place. Fits today?';
  }

  @override
  String get moodyPlaceThreadMyDayV3DirectEmpty => 'Slot. Real question?';

  @override
  String moodyPlaceThreadMyDayV3DirectPlace(String place) {
    return '$place. Backup, timing, certainty?';
  }

  @override
  String get moodyPlaceThreadMyDayV4DirectEmpty => 'This slice. What?';

  @override
  String moodyPlaceThreadMyDayV4DirectPlace(String place) {
    return '$place. Friction?';
  }

  @override
  String get moodyPlaceThreadMyDayV5DirectEmpty => 'Go.';

  @override
  String moodyPlaceThreadMyDayV5DirectPlace(String place) {
    return '$place. What?';
  }

  @override
  String get moodyPlaceThreadMyDayV0EnergeticEmpty =>
      'Free slice—sharp on: swap, timing, or \"does this even fit\"? ⚡';

  @override
  String moodyPlaceThreadMyDayV0EnergeticPlace(String place) {
    return 'That $place block—say what\'s bugging you: swap, timing, vibe ✨';
  }

  @override
  String get moodyPlaceThreadMyDayV1EnergeticEmpty =>
      'Empty slot—what do you *want* to feel today? 🔥';

  @override
  String moodyPlaceThreadMyDayV1EnergeticPlace(String place) {
    return '$place on your day—tweak it or trade it? 💬';
  }

  @override
  String get moodyPlaceThreadMyDayV2EnergeticEmpty =>
      'Free time. No question is too small 🙌';

  @override
  String moodyPlaceThreadMyDayV2EnergeticPlace(String place) {
    return 'About $place—real talk: unsure it fits today? 😅';
  }

  @override
  String get moodyPlaceThreadMyDayV3EnergeticEmpty =>
      'Keep this slot human: what\'s the actual question? ✨';

  @override
  String moodyPlaceThreadMyDayV3EnergeticPlace(String place) {
    return '$place… backup, better timing, or certainty? ⚡';
  }

  @override
  String get moodyPlaceThreadMyDayV4EnergeticEmpty =>
      'I\'m here—what do you want to know about this part of your day? 💬';

  @override
  String moodyPlaceThreadMyDayV4EnergeticPlace(String place) {
    return 'I\'m on $place—where\'s the friction in your plan? 🔥';
  }

  @override
  String get moodyPlaceThreadMyDayV5EnergeticEmpty =>
      'Go—I\'ll add context, you steer the vibe 🙌';

  @override
  String moodyPlaceThreadMyDayV5EnergeticPlace(String place) {
    return '$place: say what you need. I\'ll match it ✨';
  }

  @override
  String get chatSheetMessageCopy => 'Copy';

  @override
  String get chatSheetMessageReply => 'Reply';

  @override
  String get chatSheetCopied => 'Copied to clipboard';

  @override
  String get chatSheetReplyLabelYou => 'You';

  @override
  String get moodyConversationGreeting =>
      'Hi there! How are you feeling today? I can suggest activities based on your mood.';

  @override
  String get moodyConversationTalkToMoody => 'Talk to Moody';

  @override
  String get moodyConversationSpeaking => 'Speaking...';

  @override
  String get moodyConversationListening => 'Listening...';

  @override
  String get moodyConversationThinking => 'Thinking...';

  @override
  String get moodyConversationTypeMessage => 'Type your message...';

  @override
  String get homeSelectLocation => 'Select Location';

  @override
  String get homeCurrentLocation => 'Current Location';

  @override
  String get homeUsingGps => 'Using GPS';

  @override
  String get homeGettingLocation => 'Getting your location...';

  @override
  String homeLocationResult(String location) {
    return 'Location: $location';
  }

  @override
  String get homeLocationNotFound => 'Could not get location';

  @override
  String get homeChatErrorRetry =>
      'Sorry, I couldn\'t respond right now. Try again! 😅';

  @override
  String get checkInQ1Title => 'How was your day?';

  @override
  String get checkInQ1Subtitle => 'Moody wants to get to know you better 🌙';

  @override
  String get checkInQ1Question => 'What was the best moment of today?';

  @override
  String get checkInQ1Activities => 'The activities 🎯';

  @override
  String get checkInQ1Friends => 'With friends 👥';

  @override
  String get checkInQ1Exploring => 'Exploring 🔍';

  @override
  String get checkInQ1Food => 'Food & drinks 🍽';

  @override
  String get checkInQ1Relaxing => 'Relaxing 🛋';

  @override
  String get checkInMaybeLater => 'Maybe later';

  @override
  String checkInQ2Question(String name) {
    return 'Was $name worth it?';
  }

  @override
  String get checkInQ2Amazing => 'Amazing! 🤩';

  @override
  String get checkInQ2Good => 'Good 👍';

  @override
  String get checkInQ2Ok => 'It was okay';

  @override
  String get checkInQ2NotForMe => 'Not for me';

  @override
  String get checkInQ3Question => 'How are you feeling now?';

  @override
  String get checkInQ3Happy => 'Happy';

  @override
  String get checkInQ3Relaxed => 'Relaxed';

  @override
  String get checkInQ3Tired => 'Tired';

  @override
  String get checkInQ3Mixed => 'Mixed';

  @override
  String get checkInDoneTitle => 'Thank you! See you tomorrow 🌟';

  @override
  String get checkInDoneSubtitle => 'Moody will remember this for next time';

  @override
  String get checkInSaveError => 'Save failed. Please try again.';

  @override
  String get checkInClose => 'Close';

  @override
  String get checkInWithMoodyTitle => 'Check in with Moody';

  @override
  String get checkInGreetingDefault => 'Hey! How\'s your day going?';

  @override
  String get checkInGreetingMorningAfterTired =>
      'Good morning! Did you sleep well? 🌅';

  @override
  String get checkInGreetingMorningFresh =>
      'Good morning! How are you feeling today? ☀️';

  @override
  String get checkInTellMeEverything => 'Tell me everything! 💚';

  @override
  String get checkInHowAreYouFeeling => 'How are you feeling?';

  @override
  String get checkInWhatDidYouDoToday => 'What did you do today?';

  @override
  String get checkInQuickReactionsHeading => 'Quick reactions';

  @override
  String get checkInTellMeMoreHeading => 'Tell me more... (optional)';

  @override
  String get checkInTextFieldHint => 'What\'s on your mind? Share anything! 💭';

  @override
  String get checkInSendButton => 'Send to Moody';

  @override
  String get checkInThanksMoodyButton => 'Thanks Moody! 💚';

  @override
  String get checkInAiFallbackThankYou =>
      'Thanks for checking in! I love hearing about your day 💛';

  @override
  String get checkInMoodGreatLabel => 'Great';

  @override
  String get checkInMoodGreatSubtitle => 'Living my best life!';

  @override
  String get checkInMoodTiredLabel => 'Tired';

  @override
  String get checkInMoodTiredSubtitle => 'Need some rest';

  @override
  String get checkInMoodAmazingLabel => 'Amazing';

  @override
  String get checkInMoodAmazingSubtitle => 'Best day ever!';

  @override
  String get checkInMoodOkayLabel => 'Okay';

  @override
  String get checkInMoodOkaySubtitle => 'Just coasting';

  @override
  String get checkInMoodThoughtfulLabel => 'Thoughtful';

  @override
  String get checkInMoodThoughtfulSubtitle => 'In my feels';

  @override
  String get checkInMoodChillLabel => 'Chill';

  @override
  String get checkInMoodChillSubtitle => 'Taking it easy';

  @override
  String get checkInTagExploredPlaces => 'Explored places';

  @override
  String get checkInTagGreatFood => 'Had great food';

  @override
  String get checkInTagMetFriends => 'Met friends';

  @override
  String get checkInTagRelaxed => 'Relaxed';

  @override
  String get checkInTagWorkedOut => 'Worked out';

  @override
  String get checkInTagCreativeTime => 'Creative time';

  @override
  String get checkInTagAdventure => 'Adventure';

  @override
  String get checkInTagSelfCare => 'Self-care';

  @override
  String get checkInReactionLovedIt => 'Loved it';

  @override
  String get checkInReactionOnFire => 'On fire';

  @override
  String get checkInReactionMagical => 'Magical';

  @override
  String get checkInReactionExhausted => 'Exhausted';

  @override
  String get checkInReactionAmazing => 'Amazing';

  @override
  String get checkInReactionPeaceful => 'Peaceful';

  @override
  String get dagSheetOpener1 => 'You\'re home! How was your day?';

  @override
  String get dagSheetOpener2 => 'Tell me! How was it today?';

  @override
  String get dagSheetOpener3 => 'How did it go today?';

  @override
  String get dagSheetOpener4 => 'Moody is curious — how was your day?';

  @override
  String get dagSheetE1Amazing => 'Amazing! 🤩';

  @override
  String get dagSheetE1PrettyGood => 'Pretty good 😊';

  @override
  String get dagSheetE1Okay => 'Okay 😐';

  @override
  String get dagSheetE1Letdown => 'Letdown 😔';

  @override
  String get dagSheetFollowupAmazing => 'Awesome! What was the best moment? 🌟';

  @override
  String get dagSheetFollowupPrettyGood =>
      'Nice! Something that really stood out?';

  @override
  String get dagSheetFollowupOkay =>
      'Fair enough. What could have been better?';

  @override
  String get dagSheetFollowupLetdown => 'Too bad... What went wrong?';

  @override
  String get dagSheetFollowupDefault => 'Tell me more! ✨';

  @override
  String get dagSheetE2Activities => 'The activities 🎯';

  @override
  String get dagSheetE2People => 'With people 👥';

  @override
  String get dagSheetE2Exploring => 'The exploring 🔍';

  @override
  String get dagSheetE2Food => 'Great food 🍽';

  @override
  String get dagSheetE2Relaxing => 'Just relaxing 🛋';

  @override
  String get dagSheetE2Unexpected => 'Something unexpected ✨';

  @override
  String get dagSheetClosing1 => 'Well done today. Sleep well 🌙';

  @override
  String get dagSheetClosing2 =>
      'Moody will remember this for tomorrow. See you! ✨';

  @override
  String get dagSheetClosing3 =>
      'Thanks for sharing. Tomorrow is another beautiful day 🌟';

  @override
  String get dagSheetClosing4 =>
      'Sleep well. Tomorrow we\'ll make it special 🌙';

  @override
  String get dagSheetReflectionPrompt =>
      'Anything else on your mind? All good — or leave it empty and go sleep. ✨';

  @override
  String get dagSheetReflectionHint => 'Type here… (optional)';

  @override
  String get dagSheetGoodnight => 'Goodnight Moody 🌙';

  @override
  String carouselPerfectMatches(String count) {
    return '$count perfect matches';
  }

  @override
  String get carouselRefreshing => 'Refreshing recommendations...';

  @override
  String get carouselTopPick => 'TOP PICK';

  @override
  String get carouselTellMeMore => 'Tell me more';

  @override
  String get carouselAddToDay => 'Add to day';

  @override
  String get carouselDirections => 'Directions';

  @override
  String get carouselShare => 'Share';

  @override
  String get carouselDetails => 'Details';

  @override
  String get carouselSaveForLater => 'Save for later';

  @override
  String get carouselNotInterested => 'Not interested';

  @override
  String get carouselNoRecommendations => 'No recommendations yet';

  @override
  String get carouselCheckBackSoon =>
      'Check back soon for personalized suggestions!';

  @override
  String get prefBack => 'Back';

  @override
  String get interestsPrompt => 'What do you like? I\'ll find it for you! 🔍';

  @override
  String get interestsTitle => 'What are your interests?';

  @override
  String get interestsSubtitle => 'Choose everything that appeals to you.';

  @override
  String get interestsMultipleChoice => 'Multiple choices possible';

  @override
  String get interestsContinue => 'Continue →';

  @override
  String get interestFoodDining => 'Food & Drinks';

  @override
  String get interestArtsCulture => 'Arts & Culture';

  @override
  String get interestShoppingMarkets => 'Shopping & Markets';

  @override
  String get interestSports => 'Sports & Activities';

  @override
  String get interestNatureOutdoors => 'Nature & Parks';

  @override
  String get interestNightlife => 'Nightlife';

  @override
  String get interestCoffeeCafes => 'Coffee & Cafés';

  @override
  String get interestPhotographySpots => 'Photography & Spots';

  @override
  String get prefTravelProfileTitle => 'Your Travel Profile';

  @override
  String get prefSocialVibeLabel => 'Social Vibe 👥';

  @override
  String get prefPaceLabel => 'Planning Pace ⚡';

  @override
  String get prefStyleLabel => 'Your Style 🌟';

  @override
  String prefStyleLimit(String count) {
    return 'Choose up to $count styles that suit you.';
  }

  @override
  String get prefMoodySpeech =>
      'Just a few more questions and I\'ll know you completely! ✈️';

  @override
  String get prefSocialSoloTitle => 'Solo Adventures';

  @override
  String get prefSocialSoloHint => 'Time for myself';

  @override
  String get prefSocialSmallTitle => 'Small Groups';

  @override
  String get prefSocialSmallHint => 'Intimate setting';

  @override
  String get prefSocialButterflyTitle => 'Social Butterfly';

  @override
  String get prefSocialButterflyHint => 'Meeting new people';

  @override
  String get prefSocialMoodTitle => 'Mood Dependent';

  @override
  String get prefSocialMoodHint => 'Sometimes solo, sometimes social';

  @override
  String get prefPaceNow => 'Right Now ⚡';

  @override
  String get prefPaceToday => 'Today 📅';

  @override
  String get prefPacePlanned => 'Planned 🗓';

  @override
  String get prefStyleLocalTitle => 'Local Experience';

  @override
  String get prefStyleLocalSubtitle => 'Authentic and off the beaten track.';

  @override
  String get prefStyleLuxuryTitle => 'Luxury Seeker';

  @override
  String get prefStyleLuxurySubtitle => 'Comfort and special experiences.';

  @override
  String get prefStyleBudgetTitle => 'Budget Conscious';

  @override
  String get prefStyleBudgetSubtitle => 'Maximum fun, smart spending.';

  @override
  String get prefStyleOffTitle => 'Off the Beaten Path';

  @override
  String get prefStyleOffSubtitle => 'Hidden gems and local favorites.';

  @override
  String get prefStyleTouristTitle => 'Tourist Highlights';

  @override
  String get prefStyleTouristSubtitle => 'Iconic places you want to have seen.';

  @override
  String get gamificationTitle => 'Achievements';

  @override
  String get gamificationYourProgress => 'Your Progress';

  @override
  String get gamificationCompleteToUnlock =>
      'Complete activities to unlock achievements';

  @override
  String get gamificationUnlocked => 'Unlocked';

  @override
  String get gamificationInProgress => 'In Progress';

  @override
  String get gamificationLocked => 'Locked';

  @override
  String gamificationUnlockedOn(String date) {
    return 'Unlocked on $date';
  }

  @override
  String get gamificationClose => 'Close';

  @override
  String get gamificationCategoryExploration => 'Exploration';

  @override
  String get gamificationCategoryActivities => 'Activities';

  @override
  String get gamificationCategorySocial => 'Social';

  @override
  String get gamificationCategoryStreaks => 'Streaks';

  @override
  String get gamificationCategoryMood => 'Mood';

  @override
  String get gamificationCategorySpecial => 'Special';

  @override
  String get gamificationCategoryOther => 'Other';

  @override
  String get achievementExplorer => 'Explorer';

  @override
  String get achievementEarlyBird => 'Early Bird';

  @override
  String get achievementStreakMaster => 'Streak Master';

  @override
  String get achievementMoodTracker => 'Mood Tracker';

  @override
  String get achievementAdventurer => 'Adventurer';

  @override
  String get prefScreenTitle => 'Your Preferences';

  @override
  String get prefSave => 'Save';

  @override
  String get prefSavedSuccess => 'Preferences saved successfully';

  @override
  String get prefSaveError => 'Error saving preferences';

  @override
  String get prefSectionAgeGroup => 'Age Group';

  @override
  String get prefSectionAgeGroupSub =>
      'Helps us recommend age-appropriate activities';

  @override
  String get prefSectionBudget => 'Budget Comfort';

  @override
  String get prefSectionBudgetSub =>
      'Your typical spending range for activities';

  @override
  String get prefSectionSocialVibeSub =>
      'Do you prefer solo activities or social scenes?';

  @override
  String get prefSectionActivityPace => 'Activity Pace';

  @override
  String get prefSectionActivityPaceSub =>
      'How energetic do you like your day?';

  @override
  String get prefSectionTimeAvailable => 'Typical Time Available';

  @override
  String get prefSectionTimeAvailableSub =>
      'How much time do you usually have for activities?';

  @override
  String get prefSectionInterestsSub =>
      'Select all that apply (helps personalize recommendations)';

  @override
  String get prefAge1824Label => 'Early 20s';

  @override
  String get prefAge1824Desc => 'Budget-friendly, social';

  @override
  String get prefAge2534Label => '20s-30s';

  @override
  String get prefAge2534Desc => 'Trendy, adventurous';

  @override
  String get prefAge3544Label => '30s-40s';

  @override
  String get prefAge3544Desc => 'Quality experiences';

  @override
  String get prefAge4554Label => '40s-50s';

  @override
  String get prefAge4554Desc => 'Refined, relaxed';

  @override
  String get prefAge55Label => '55+';

  @override
  String get prefAge55Desc => 'Cultural, scenic';

  @override
  String get prefBudgetLabel => 'Budget';

  @override
  String get prefBudgetDesc => 'Free - \$20';

  @override
  String get prefModerateLabel => 'Moderate';

  @override
  String get prefModerateDesc => '\$20 - \$50';

  @override
  String get prefUpscaleLabel => 'Upscale';

  @override
  String get prefUpscaleDesc => '\$50 - \$100';

  @override
  String get prefLuxuryLabel => 'Luxury';

  @override
  String get prefLuxuryDesc => '\$100+';

  @override
  String get prefSoloLabel => 'Solo Friendly';

  @override
  String get prefSoloDesc => 'Quiet, peaceful, me-time';

  @override
  String get prefSmallGroupLabel => 'Small Groups';

  @override
  String get prefSmallGroupDesc => 'Intimate, cozy gatherings';

  @override
  String get prefMixLabel => 'Mix of Both';

  @override
  String get prefMixDesc => 'Flexible, variety';

  @override
  String get prefSocialSceneLabel => 'Social Scene';

  @override
  String get prefSocialSceneDesc => 'Lively, meet people';

  @override
  String get prefSlowChillLabel => 'Slow & Chill';

  @override
  String get prefSlowChillDesc => 'Take it easy';

  @override
  String get prefModerateActivityLabel => 'Moderate';

  @override
  String get prefModerateActivityDesc => 'Balanced pace';

  @override
  String get prefActiveLabel => 'Active';

  @override
  String get prefActiveDesc => 'Energetic, on-the-go';

  @override
  String get prefQuickVisitLabel => 'Quick Visit';

  @override
  String get prefHalfDayLabel => 'Half Day';

  @override
  String get prefFullDayLabel => 'Full Day';

  @override
  String get prefInterestCulture => 'Culture & Arts';

  @override
  String get prefInterestNature => 'Nature & Outdoors';

  @override
  String get prefInterestNightlife => 'Nightlife';

  @override
  String get prefInterestWellness => 'Wellness';

  @override
  String get prefInterestAdventure => 'Adventure';

  @override
  String get prefInterestHistory => 'History';

  @override
  String get achievementsUnlocked => 'Achievements Unlocked';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountAreYouSure => 'Are you sure?';

  @override
  String get deleteAccountWarning =>
      'This action cannot be undone. All your data, activities, and preferences will be permanently deleted.';

  @override
  String get deleteAccountWhatWillBeDeleted => 'What will be deleted:';

  @override
  String get deleteAccountProfile => 'Your profile and preferences';

  @override
  String get deleteAccountActivities => 'All saved activities';

  @override
  String get deleteAccountAchievements => 'Your achievements and progress';

  @override
  String get deleteAccountPhotos => 'All photos and memories';

  @override
  String get deleteAccountConfirmKeyword => 'DELETE';

  @override
  String get deleteAccountTypeToConfirm => 'Type \"DELETE\" to confirm';

  @override
  String get deleteAccountTypeIncorrect => 'Please type DELETE to confirm';

  @override
  String get deleteAccountFinalTitle => 'Final Confirmation';

  @override
  String get deleteAccountFinalContent =>
      'This action cannot be undone. All your data will be permanently deleted.';

  @override
  String get deleteAccountCancel => 'Cancel';

  @override
  String get deleteAccountDeleteForever => 'Delete Forever';

  @override
  String get deleteAccountDeleteButton => 'Delete My Account Forever';

  @override
  String get deleteAccountSuccess => 'Account deleted successfully';

  @override
  String get deleteAccountError => 'Error deleting account';

  @override
  String get settingsNotificationsSectionTitle => 'NOTIFICATIONS';

  @override
  String get settingsNotificationsTripRemindersLabel => 'Trip reminders';

  @override
  String get settingsNotificationsTripRemindersSubtitle =>
      'Reminders for planned activities';

  @override
  String get settingsNotificationsWeatherUpdatesLabel => 'Weather updates';

  @override
  String get settingsNotificationsWeatherUpdatesSubtitle =>
      'Updates about the weather at your destination';

  @override
  String get settingsNotificationsLocalDeviceFootnote =>
      'These options apply to notifications on this device (including scheduled reminders). They are not separate cloud push messages.';

  @override
  String get premiumComingSoonTitle => 'Premium — coming soon';

  @override
  String get premiumComingSoonBody =>
      'Subscriptions will be offered with Apple In-App Purchase in a future update. WanderMood is free to use in this version.';

  @override
  String get premiumComingSoonFootnote =>
      'We do not collect card details, Apple Pay, or other payments in this build.';

  @override
  String get premiumComingSoonCta => 'OK';

  @override
  String get premiumUpgradeScreenTitle => 'Premium';

  @override
  String get premiumMonthlyPlanLabel => 'Monthly Plan';

  @override
  String get premiumMonthlyPriceLabel => '€4.99/month';

  @override
  String get premiumBestValueBadge => 'Best Value';

  @override
  String get premiumPaymentMethodTitle => 'Payment Method';

  @override
  String get premiumPaymentMethodCard => 'Credit/Debit Card';

  @override
  String get premiumPaymentMethodPaypal => 'PayPal';

  @override
  String get premiumPaymentMethodApplePay => 'Apple Pay';

  @override
  String get premiumSubscribeCta => 'Subscribe for €4.99/month';

  @override
  String get premiumSecurityNotice =>
      'Your payment information is encrypted and secure';

  @override
  String get premiumToastActivated => 'Premium subscription activated!';

  @override
  String premiumToastPaymentFailed(String error) {
    return 'Payment failed: $error';
  }

  @override
  String get premiumCardDetailsTitle => 'Card Details';

  @override
  String get premiumCardNumberLabel => 'Card Number';

  @override
  String get premiumCardNumberHint => '1234 5678 9012 3456';

  @override
  String get premiumExpiryLabel => 'Expiry (MM/YY)';

  @override
  String get premiumExpiryHint => '12/25';

  @override
  String get premiumCvvLabel => 'CVV';

  @override
  String get premiumCvvHint => '123';

  @override
  String get premiumCardholderNameLabel => 'Cardholder Name';

  @override
  String get premiumCardholderNameHint => 'John Doe';

  @override
  String get premiumValidationRequired => 'Required';

  @override
  String get premiumValidationCardNumberRequired => 'Card number is required';

  @override
  String get premiumValidationInvalidCardNumber => 'Invalid card number';

  @override
  String get premiumValidationInvalidCvv => 'Invalid CVV';

  @override
  String get premiumValidationNameRequired => 'Name is required';

  @override
  String get placeDetailAboutThisPlace => 'About this place';

  @override
  String get placeDetailBlurbExtraAddress =>
      'Address and quick actions are listed just below this section.';

  @override
  String placeDetailBlurbExtraRatingCount(String rating, int count) {
    return 'Public listings average about $rating out of 5 across $count ratings.';
  }

  @override
  String placeDetailBlurbExtraRatingOnly(String rating) {
    return 'Typical scores land around $rating out of 5 on public listings.';
  }

  @override
  String get placeDetailBlurbExtraReviewsTab =>
      'The Reviews tab shows what visitors mention lately; hours and busy times help you plan your visit.';

  @override
  String get placeDetailGoodToKnow => 'Good to know';

  @override
  String get placeDetailDurationLabel => 'Duration';

  @override
  String get placeDetailPriceLabel => 'Price';

  @override
  String get placeDetailDistanceLabel => 'Distance';

  @override
  String get placeDetailBestTimeLabel => 'Best time';

  @override
  String get placeDetailGoodWithLabel => 'Good with';

  @override
  String get placeDetailEnergyLabel => 'Energy';

  @override
  String get placeDetailTimeNeededLabel => 'Time needed';

  @override
  String get placeDetailNoPhotos => 'No photos available';

  @override
  String get placeDetailLoadingPhotos => 'Loading photos…';

  @override
  String get placeDetailAmazingFeatures => 'Amazing features';

  @override
  String get placeDetailIndoorVibes => 'Indoor vibes';

  @override
  String get placeDetailOutdoorFun => 'Outdoor fun';

  @override
  String get placeDetailEnergyChipLow => 'Low energy';

  @override
  String get placeDetailEnergyChipMedium => 'Medium energy';

  @override
  String get placeDetailEnergyChipHigh => 'High energy';

  @override
  String get placeDetailHeroOpenNow => 'Open now';

  @override
  String get placeDetailHeroClosed => 'Closed';

  @override
  String get placeDetailHeroOpenNowLine => '✅ Open now!';

  @override
  String get placeDetailHeroClosedLine => '❌ Closed';

  @override
  String get placeDetailOpen247 => 'Open 24/7';

  @override
  String get placeDetailPrice5to15 => '€5–15';

  @override
  String get placeDetailPrice8to25 => '€8–25';

  @override
  String get placeDetailPrice10to20 => '€10–20';

  @override
  String get placeDetailPrice10to25 => '€10–25';

  @override
  String get placeDetailPrice15to35 => '€15–35';

  @override
  String get placeDetailPrice15to40 => '€15–40';

  @override
  String get placeDetailPrice40to80 => '€40–80';

  @override
  String get placeDetailPrice30to50 => '€30–50';

  @override
  String get placeDetailPrice50Plus => '€50+';

  @override
  String get placeDetailFreeEntryPayItems => 'Free entry (pay for items)';

  @override
  String get placeDetailFreeDonationsWelcome => 'Free (donations welcome)';

  @override
  String get placeDetailUnavailableName => 'Place details unavailable';

  @override
  String get placeDetailOpeningStatusOpen => 'open';

  @override
  String get placeDetailOpeningStatusClosed => 'closed';

  @override
  String get myDayCarouselSpotFallbackDescription =>
      'A spot worth checking out';

  @override
  String get myDayFreeTimeSectionTitle => 'Activities in your free time';

  @override
  String get myDayFreeTimeSectionSubtitle =>
      'Discover what you can do right now';

  @override
  String get myDayFreeTimeIntroOneLine =>
      'Near you. Discover what you can do right now.';

  @override
  String get myDayFreeTimeEmptyHint =>
      'No suggestions cached yet. Open Discover for your area — fresh ideas will show up here.';

  @override
  String get myDayFreeTimeLoadingFailed =>
      'Couldn’t load suggestions. Try again in a moment.';

  @override
  String get myDayFreeTimeLoadMore => 'Load more';

  @override
  String get myDayFreeTimeNearYouBadge => 'Near you';

  @override
  String get myDayFreeTimeDirectionsShort => 'Directions';

  @override
  String get myDayFreeTimeCategoryExercise => 'Outdoors & activity';

  @override
  String get myDayFreeTimeCategoryEntertainment => 'Going out';

  @override
  String get myDayFreeTimeCategorySocial => 'Social';

  @override
  String get myDayFreeTimeCategorySpot => 'Place';

  @override
  String get exploreCardBlurbRestaurant =>
      'Sit-down dining with changing menus — check the listing for cuisine and hours.';

  @override
  String get exploreCardBlurbBar =>
      'Drinks-focused spot — cocktails, wine, or beer depending on what they pour.';

  @override
  String get exploreCardBlurbCafe =>
      'Coffee, light bites, and a calm stop — pastries or brunch where offered.';

  @override
  String get exploreCardBlurbBakery =>
      'Fresh bread, pastries, and quick savory bites to stay or take away.';

  @override
  String get exploreCardBlurbTakeaway =>
      'Quick meals and grab-and-go food — handy for a fast bite.';

  @override
  String get exploreCardBlurbMuseum =>
      'Exhibitions and collections indoors — tickets and hours on the detail page.';

  @override
  String get exploreCardBlurbZoo =>
      'Animal exhibits indoors and out — entry is usually ticketed.';

  @override
  String get exploreCardBlurbAquarium =>
      'Aquarium galleries and family-friendly visits — typically ticketed.';

  @override
  String get exploreCardBlurbNightlife =>
      'Late-night venue — music, dancing, or a lively crowd; fees may apply.';

  @override
  String get exploreCardBlurbPark =>
      'Outdoor space to walk, sit, or relax — usually free to visit.';

  @override
  String get exploreCardBlurbAttraction =>
      'City experience or landmark — may need tickets or a time slot.';

  @override
  String get exploreCardBlurbSpa =>
      'Treatments and downtime — booking ahead helps on busy days.';

  @override
  String get exploreCardBlurbShopping =>
      'Shops and browsing — opening hours vary by retailer.';

  @override
  String get exploreCardBlurbDefault =>
      'Local place to discover — open the card for hours and practical info.';

  @override
  String exploreCardBlurbSecondSentenceRating(String rating) {
    return 'Guests rate it around $rating out of 5 on average — tap through for reviews, photos, and opening hours.';
  }

  @override
  String get exploreCardBlurbSecondSentenceNoRating =>
      'Tap the listing for address, photos, and what reviewers mention most often.';

  @override
  String exploreCardBlurbPoiNamed(String name) {
    return '$name appears on the map as a neighborhood spot — a nice spontaneous stop if you are nearby.';
  }

  @override
  String get exploreCardBlurbTour =>
      'Guided experiences and local know-how — check the listing for booking and what is included.';

  @override
  String get moodyPlaceBlurbSystemPrompt =>
      'You are Moody, the warm voice of the WanderMood travel app. You write accurate and engaging place descriptions for cards. You must not invent menu items, prices, or amenities. Only use facts supplied by the user message. If facts are thin, stay general but still engaging.';

  @override
  String moodyPlaceBlurbUserMessage(String facts, String languageName) {
    return 'These are the only verified facts about a real place (from maps data or visitor text). Do not add details that are not supported by them.\n\n$facts\n\nWrite at least 3 detailed sentences about the atmosphere and offerings for a travel app card. Tone: friendly, like Moody. Use only the facts above. Output entirely in $languageName. Plain prose: no bullet points, no quotation marks, no lists.';
  }

  @override
  String get moodyPlaceBlurbLabelName => 'Name';

  @override
  String get moodyPlaceBlurbLabelAddress => 'Address';

  @override
  String get moodyPlaceBlurbLabelTypes => 'Types';

  @override
  String get moodyPlaceBlurbLabelRating => 'Rating';

  @override
  String get moodyPlaceBlurbLabelReviewCount => 'Review count';

  @override
  String get moodyPlaceBlurbLabelOverview => 'Place overview';

  @override
  String get moodyPlaceBlurbLabelVisitorNotes => 'Visitor notes';

  @override
  String get moodyPlaceBlurbLanguageEnglish => 'English';

  @override
  String get moodyPlaceBlurbLanguageDutch => 'Dutch';

  @override
  String get moodyPlaceBlurbLanguageGerman => 'German';

  @override
  String get moodyPlaceBlurbLanguageFrench => 'French';

  @override
  String get moodyPlaceBlurbLanguageSpanish => 'Spanish';

  @override
  String get moodyPlaceDetailBlurbSystemPrompt =>
      'You are Moody, the warm voice of the WanderMood travel app. You write a fuller, accurate place description for a detail screen. You must not invent menu items, prices, or amenities. Only use facts supplied by the user message. If facts are thin, stay general but still engaging.';

  @override
  String moodyPlaceDetailBlurbUserMessage(String facts, String languageName) {
    return 'These are the only verified facts about a real place (from maps data or visitor text). Do not add details that are not supported by them.\n\n$facts\n\nWrite 5 to 8 detailed sentences including practical tips, history, and why it\'s worth visiting for a travel app place detail screen. Expand on what visitors might experience, atmosphere, and practical cues only when supported by the facts above. Tone: friendly, like Moody. Output entirely in $languageName. Plain prose: no bullet points, no quotation marks, no lists.';
  }

  @override
  String get moodCarouselNearbyBadge => 'Nearby';

  @override
  String get moodCarouselSave => 'Save';

  @override
  String get moodCarouselAddToMorning => 'Add to morning';

  @override
  String get moodCarouselAddToAfternoon => 'Add to afternoon';

  @override
  String get moodCarouselAddToEvening => 'Add to evening';

  @override
  String moodCarouselActivityVisitName(String name) {
    return 'Visit $name';
  }

  @override
  String moodCarouselToastAddedMorning(String name) {
    return '$name added to your morning!';
  }

  @override
  String moodCarouselToastAddedAfternoon(String name) {
    return '$name added to your afternoon!';
  }

  @override
  String moodCarouselToastAddedEvening(String name) {
    return '$name added to your evening!';
  }

  @override
  String moodCarouselToastAddFailed(String name) {
    return 'Failed to add $name. Please try again.';
  }

  @override
  String get moodCarouselToastView => 'View';

  @override
  String myDayFreeTimeInsightDuration(int minutes) {
    return '⏱️ ~$minutes min';
  }

  @override
  String myDayFreeTimeInsightRating(String rating) {
    return '⭐ $rating';
  }

  @override
  String myDayFreeTimeInsightPricePaid(String symbols) {
    return '💶 $symbols';
  }

  @override
  String get placeCardSignInToAddMyDay =>
      'Please sign in to add activities to My Day';

  @override
  String placeCardAddedToMyDay(String name) {
    return 'Added $name to My Day!';
  }

  @override
  String placeCardFailedAddToMyDay(String name) {
    return 'Failed to add $name to My Day';
  }

  @override
  String get placeCardUnableOpenDirections => 'Unable to open directions';

  @override
  String get placeCardView => 'View';

  @override
  String placeCardReviewCountInParens(int count) {
    return '($count reviews)';
  }

  @override
  String get placeDetailNoReviews => 'No reviews available';

  @override
  String get placeDetailReviewsWhenAvailable =>
      'Reviews will appear here when available';

  @override
  String get placeDetailNotFound => 'Place not found';

  @override
  String get placeDetailOpenMaps => 'Open maps';

  @override
  String get placeDetailCheckLocally => 'Check locally';

  @override
  String get placeDetailFreeToVisit => 'Free to visit';

  @override
  String get placeDetailVaries => 'Varies';

  @override
  String get placeDetailFreeEntry => 'Free entry';

  @override
  String get placeDetailEvening => 'Evening';

  @override
  String get placeDetailMorning => 'Morning';

  @override
  String get placeDetailAfternoon => 'Afternoon';

  @override
  String get placeDetailAnytime => 'Anytime';

  @override
  String get placeDetailGoodFitForTonight => 'Good fit for tonight';

  @override
  String get placeDetailBestOnWeekends => 'Best on weekends';

  @override
  String get placeDetailSkipIfChill =>
      'Skip if you\'re looking for something chill';

  @override
  String get placeDetailClosedCheckHours => 'Closed now — check hours';

  @override
  String get placeDetailFriendsGroups => 'Friends / Groups';

  @override
  String get placeDetailSoloDate => 'Solo / Date';

  @override
  String get placeDetailSoloFriends => 'Solo / Friends';

  @override
  String get placeDetailAnonymous => 'Anonymous';

  @override
  String get placeDetailRecently => 'Recently';

  @override
  String get placeDetailMoodyName => 'Moody';

  @override
  String get placeDetailMoodyLoadingTips => 'Checking this place…';

  @override
  String get placeDetailMoodyFallbackTipA =>
      'Check opening hours before you go.';

  @override
  String get placeDetailMoodyFallbackTipB => 'Stay hydrated.';

  @override
  String get placeDetailMoodyFallbackTipC => 'Save maps offline if you can.';

  @override
  String get placeDetailBestTimeLunchDinner => 'Lunch / dinner';

  @override
  String get placeDetailDurationAllowOneToTwo => 'Allow 1–2 hours';

  @override
  String get placeDetailDurationOneToTwo => '1–2 hours';

  @override
  String get placeDetailDurationOneToTwoPointFive => '1–2.5 hours';

  @override
  String get placeDetailDurationOneHalfToThree => '1.5–3 hours';

  @override
  String get placeDetailDurationThirtyToSixty => '30–60 minutes';

  @override
  String get placeDetailDurationThirtyToFortyFive => '30–45 minutes';

  @override
  String get placeDetailDurationFortyFiveToNinety => '45 min – 1.5 hours';

  @override
  String get placeDetailDurationOneToThree => '1–3 hours';

  @override
  String get placeDetailDurationTwoToFour => '2–4 hours';

  @override
  String get placeDetailDurationOneToFour => '1–4 hours';

  @override
  String get placeDetailDurationTwoToThree => '2–3 hours';

  @override
  String get placeDetailDurationAboutOneHour => '~1 hour';

  @override
  String get placeDetailTabDetails => 'Details';

  @override
  String get placeDetailTabPhotos => 'Photos';

  @override
  String get placeDetailTabReviews => 'Reviews';

  @override
  String get placeDetailGalleryTitle => 'Gallery';

  @override
  String placeDetailPhotoCount(int count) {
    return '$count photos';
  }

  @override
  String get placeDetailReviewsSectionTitle => 'Reviews';

  @override
  String get placeCategoryFood => 'Food';

  @override
  String get placeCategoryRestaurant => 'Restaurant';

  @override
  String get placeCategoryCafe => 'Café';

  @override
  String get placeCategoryBar => 'Bar';

  @override
  String get placeCategoryMuseum => 'Museum';

  @override
  String get placeCategoryPark => 'Park';

  @override
  String get placeCategoryShopping => 'Shopping';

  @override
  String get placeCategoryCulture => 'Culture';

  @override
  String get placeCategoryNature => 'Nature';

  @override
  String get placeCategoryNightlife => 'Nightlife';

  @override
  String get placeCategoryAdventure => 'Adventure';

  @override
  String get placeCategorySpot => 'Spot';

  @override
  String dayPlanDurationHoursOnly(int hours) {
    return '$hours h';
  }

  @override
  String dayPlanDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String dayPlanDurationMinutesOnly(int minutes) {
    return '$minutes min';
  }

  @override
  String plannerSheetScheduledPrefix(String when) {
    return 'Scheduled $when';
  }

  @override
  String get plannerSheetAbout => 'About';

  @override
  String get plannerSheetNoDescription =>
      'No description available for this activity yet.';

  @override
  String get plannerSheetTabDetails => 'Details';

  @override
  String get plannerSheetTabPhotos => 'Photos';

  @override
  String get plannerSheetTabReviews => 'Reviews';

  @override
  String get plannerSheetNoExtraPhotos =>
      'No extra photos on this plan yet.\nWhen the activity is linked to a place, you\'ll see a full gallery in Explore.';

  @override
  String get plannerSheetRatingOnPlan => 'Rating on your plan';

  @override
  String get plannerSheetWrittenReviews => 'Written reviews';

  @override
  String get plannerSheetReviewsExplainerWithRating =>
      'Star ratings from your plan are shown above. Full Google reviews and more photos appear when this activity is linked to a place — open it from Explore, or schedule it from a place card so WanderMood can attach a place id.';

  @override
  String get plannerSheetReviewsExplainerNoRating =>
      'There\'s no review data on this scheduled item yet. Link it to a Google place (e.g. add it from Explore) to read real visitor reviews in the full place view.';

  @override
  String get plannerMoodyAdviceBlurb =>
      'Tips from Moody:\n• Check opening hours (and weather if you\'ll be outside).\n• Arrive a few minutes early so you can settle in.\n• Stay hydrated and keep an open mind — enjoy the moment!';

  @override
  String plannerMoodMatchQuickTogether(String partner) {
    return 'You + $partner';
  }

  @override
  String plannerMoodMatchQuickStory(String placeTitle) {
    return '$placeTitle is in your shared day because it lines up with what you both shared with me — separately, just between us.';
  }

  @override
  String get plannerMoodMatchQuickPlaceFallback => 'This stop';

  @override
  String get plannerMoodMatchQuickYouLabel => 'You';

  @override
  String get plannerMoodMatchQuickMoodyNote =>
      'I\'m talking to both of you here — the tabs below are straight venue facts, same as always.';

  @override
  String plannerMoodMatchPairStory_romantic_adventurous(String place) {
    return '$place threads the needle — intimate atmosphere for the romantic mood, an unexpected menu or setting that satisfies the adventurous one.';
  }

  @override
  String plannerMoodMatchPairStory_adventurous_relaxed(String place) {
    return '$place works because there\'s enough newness to keep one of you curious, and enough comfort to let the other breathe.';
  }

  @override
  String plannerMoodMatchPairStory_cultural_social(String place) {
    return '$place gives you both something to discover and something to talk about — the kind of stop that turns into a real conversation.';
  }

  @override
  String plannerMoodMatchPairStory_relaxed_social(String place) {
    return '$place is easy and open — room to unwind together without any pressure.';
  }

  @override
  String plannerMoodMatchPairStory_energetic_relaxed(String place) {
    return '$place splits the difference — one of you stays energised, the other finds a moment to reset.';
  }

  @override
  String plannerMoodMatchPairStory_cultural_romantic(String place) {
    return '$place earns its place here by blending atmosphere with something worth looking at together.';
  }

  @override
  String plannerMoodMatchPairStory_energetic_adventurous(String place) {
    return '$place keeps the tempo up — you both wanted something that moves, and this delivers.';
  }

  @override
  String plannerMoodMatchPairStory_contemplative_any(String place) {
    return 'I picked $place because it gives you both space — to talk, to sit with it, or just to be there together.';
  }

  @override
  String plannerMoodMatchPairStory_same_mood(String place) {
    return 'You both came in with the same energy — $place leans straight into that.';
  }

  @override
  String plannerMoodMatchPairStory_default(String place) {
    return '$place fits what you both shared with me separately — I lined it up so neither mood gets left behind.';
  }

  @override
  String plannerMoodMatchNoteHint(String partner) {
    return 'Leave a note for $partner…';
  }

  @override
  String get plannerMoodMatchNoteSave => 'Send';

  @override
  String get plannerMoodMatchNoteSaved => 'Sent ✓';

  @override
  String get plannerMoodMatchNoteSaving => 'Saving…';

  @override
  String plannerMoodMatchNotePartnerLabel(String partner) {
    return '$partner says:';
  }

  @override
  String get plannerMoodMatchNoteYourLabel => 'Your note';

  @override
  String get plannerMoodMatchNoteSectionTitle => 'Notes';

  @override
  String plannerMoodMatchNoteSavedSnackbar(String partner) {
    return 'Saved — $partner will see this when they open this stop (or right away if their sheet is open).';
  }

  @override
  String moodyChatSubtitleEnergeticCity(String city) {
    return 'Your $city hype travel bestie';
  }

  @override
  String get moodyChatSubtitleEnergeticNoCity => 'Your hype travel bestie';

  @override
  String moodyChatSubtitleFriendlyCity(String city) {
    return 'Your $city travel bestie';
  }

  @override
  String get moodyChatSubtitleFriendlyNoCity => 'Your travel bestie';

  @override
  String moodyChatSubtitleProfessionalCity(String city) {
    return 'Your travel companion in $city';
  }

  @override
  String get moodyChatSubtitleProfessionalNoCity =>
      'Your professional travel companion';

  @override
  String moodyChatSubtitleDirectCity(String city) {
    return '$city · straight-up travel bestie';
  }

  @override
  String get moodyChatSubtitleDirectNoCity => 'Straight-up travel bestie';

  @override
  String get moodyHubYourDayToday => 'Your day today';

  @override
  String get moodyHubChangeMood => 'Change mood';

  @override
  String get moodyHubNoMoodChosen => 'No mood selected yet';

  @override
  String get moodyHubJourneyPrefix => 'You are on a ';

  @override
  String get moodyHubJourneySuffix => ' journey';

  @override
  String get moodyHubFallbackAiMessage =>
      'Your day is set — Moody\'s here for you 🌟';

  @override
  String get moodyHubActivitySingular => 'activity';

  @override
  String get moodyHubActivityPlural => 'activities';

  @override
  String get moodyHubPlanForWhen => 'Which day?';

  @override
  String get moodyHubListComma => ', ';

  @override
  String get moodyHubListAnd => ' & ';

  @override
  String get moodyReviewTitle => 'Quick Review';

  @override
  String get moodyReviewHeroSubtitle => 'How did it land? I\'m listening.';

  @override
  String get moodyReviewHowWasIt => 'How was it?';

  @override
  String get moodyReviewStarsFeedback5 => '🌟 Amazing!';

  @override
  String get moodyReviewStarsFeedback4 => '😊 Really good!';

  @override
  String get moodyReviewStarsFeedback3 => '👍 Pretty good!';

  @override
  String get moodyReviewStarsFeedback2 => '😐 It was okay';

  @override
  String get moodyReviewStarsFeedback1 => '😞 Not great';

  @override
  String get moodyReviewYourVibe => 'Your vibe';

  @override
  String get moodyReviewVibeAmazing => 'Amazing';

  @override
  String get moodyReviewVibeGood => 'Good';

  @override
  String get moodyReviewVibeOkay => 'Okay';

  @override
  String get moodyReviewVibeMeh => 'Meh';

  @override
  String get moodyReviewOptionalNote => 'Any thoughts? (optional)';

  @override
  String get moodyReviewNoteHint => 'What stood out while it’s fresh?';

  @override
  String get moodyReviewNoteHelper =>
      '💡 I use this to tune your next days — private to you and WanderMood.';

  @override
  String get moodyReviewSave => 'Save';

  @override
  String get moodyReviewNeedStars => 'Pick a star rating to continue';

  @override
  String get moodyReviewHelpsMoody =>
      'This stays between us — and shapes better picks for you.';

  @override
  String get moodyReviewThanksToast => 'Saved — thank you!';

  @override
  String get moodyReviewReadOnlyTitle => 'Your review';

  @override
  String get moodyReviewReadOnlyHeroSubtitle =>
      'Here\'s what you saved — view only, so partner insights stay fair.';

  @override
  String get profileMomentsTitle => 'Your visits';

  @override
  String get profileMomentsSubtitle =>
      'Places you rated after My Day — private to you';

  @override
  String get profileMomentsSeeAll => 'See all';

  @override
  String get profileMomentsEmptyCta =>
      'Rate a stop on My Day and it shows up here.';

  @override
  String get momentsListHeroLine =>
      'How places felt for you — private unless you choose a partner perk.';

  @override
  String get momentsListEmptyTitle => 'No visits yet';

  @override
  String get momentsListEmptySubtitle =>
      'When you finish a stop on My Day and tap Review, your note appears here. It stays private unless you opt into a partner perk later.';

  @override
  String get momentsListError => 'Could not load your visits';

  @override
  String get momentsDeleteConfirmTitle => 'Remove this visit?';

  @override
  String momentsDeleteConfirmBody(Object place) {
    return 'This deletes your rating for $place. You can add a new one after your next visit.';
  }

  @override
  String get momentsRemovedToast => 'Visit removed';

  @override
  String get momentsRemoveCta => 'Remove';

  @override
  String get momentsTapToEdit => 'Tap to view';

  @override
  String momentsStarsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '$count star',
    );
    return '$_temp0';
  }

  @override
  String get getReadyChecklistItemReady => 'Ready to go!';

  @override
  String getReadyShareInvite(Object title, Object time) {
    return 'Join me at $title around $time – planned with WanderMood.';
  }

  @override
  String get getReadyCalendarEventTitleFallback => 'WanderMood activity';

  @override
  String get getReadyCalendarEventDetailsFallback => 'Planned with WanderMood';

  @override
  String get getReadyShareTitleFallback => 'this place';

  @override
  String getReadyCalendarOpenHint(Object label) {
    return '$label – open in browser or app';
  }

  @override
  String getReadyPlaylistSearchQuery(Object theme) {
    return 'Happy $theme Beats';
  }

  @override
  String get getReadyPlaylistThemeFoodie => 'Foodie';

  @override
  String get getReadyPlaylistThemeCultural => 'Cultural';

  @override
  String get getReadyPlaylistThemeShopping => 'Shopping';

  @override
  String get getReadyPlaylistThemeOutdoor => 'Outdoor';

  @override
  String get getReadyPlaylistThemeAdventure => 'Adventure';

  @override
  String get getReadyMoodFragmentAdventure => 'adventure';

  @override
  String get getReadyMoodFragmentRelaxed => 'relaxation';

  @override
  String get getReadyMoodFragmentEnergetic => 'energy';

  @override
  String get getReadyMoodFragmentRomantic => 'romance';

  @override
  String get getReadyMoodFragmentCultural => 'culture';

  @override
  String get getReadyMoodFragmentExplorer => 'exploration';

  @override
  String get getReadyMoodFragmentFoodie => 'foodie';

  @override
  String moodHomeAlreadyPlannedTitle(String dayName) {
    return '$dayName is already planned!';
  }

  @override
  String moodHomeActivitiesReadyCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities are ready for you.',
      one: '1 activity is ready for you.',
    );
    return '$_temp0';
  }

  @override
  String get moodHomeViewPlan => 'View plan';

  @override
  String get moodHomePlanAgain => 'Plan again';

  @override
  String get planLoadingRotating1 =>
      'I\'m weighing your mood and the time of day…';

  @override
  String get planLoadingRotating2 => 'I\'m scanning the map for strong picks…';

  @override
  String get planLoadingRotating3 => 'Tightening the last details ✨';

  @override
  String get settingsTravelModeHelpLabel => 'Travel mode help';

  @override
  String get settingsTravelModeHelpSubtitle => 'Reopen Local vs Travel guide';

  @override
  String get placeDetailOpeningHours => 'Opening Hours';

  @override
  String get placeTypeRestaurant => 'Restaurant';

  @override
  String get placeTypeCafe => 'Café';

  @override
  String get placeTypeBar => 'Bar';

  @override
  String get placeTypeNightclub => 'Nightclub';

  @override
  String get placeTypeMuseum => 'Museum';

  @override
  String get placeTypeArtGallery => 'Art Gallery';

  @override
  String get placeTypePark => 'Park';

  @override
  String get placeTypeTouristAttraction => 'Tourist Attraction';

  @override
  String get placeTypeBakery => 'Bakery';

  @override
  String get placeTypeShoppingMall => 'Shopping Mall';

  @override
  String get placeTypeSpa => 'Spa';

  @override
  String get placeTypeGym => 'Gym';

  @override
  String get placeTypeMovieTheater => 'Cinema';

  @override
  String get placeTypeLibrary => 'Library';

  @override
  String get placeTypeChurch => 'Church';

  @override
  String get placeTypeAmusementPark => 'Amusement Park';

  @override
  String get placeTypeZoo => 'Zoo';

  @override
  String get placeTypeAquarium => 'Aquarium';

  @override
  String get placeTypeBowling => 'Bowling';

  @override
  String get placeTypeStadium => 'Stadium';

  @override
  String get placeCardSocialTrending => '🔥 Trending';

  @override
  String get placeCardSocialHiddenGem => '💎 Hidden gem';

  @override
  String get placeCardSocialLovedByLocals => '❤️ Locals love it';

  @override
  String get placeCardSocialPopular => '⭐ Popular';

  @override
  String get placeCardBestMorning => '☀️ Best in the morning';

  @override
  String get placeCardBestAfternoon => '🌤 Best in the afternoon';

  @override
  String get placeCardBestEvening => '🌙 Best in the evening';

  @override
  String get placeCardBestAllDay => '🕐 Great any time';

  @override
  String get placeCardVenuePlace => 'Place';

  @override
  String get placeCardVenueGallery => 'Gallery';

  @override
  String get placeCardVenueAttraction => 'Attraction';

  @override
  String get placeCardVenueHotel => 'Hotel';

  @override
  String get placeCardVenueClub => 'Club';

  @override
  String placeDescFood(String name) {
    return '$name is a great spot for food lovers looking for a quality meal in the area.';
  }

  @override
  String placeDescFoodWithReviews(
      String name, String rating, String reviewCount) {
    return '$name is a popular restaurant with $reviewCount reviews and a rating of $rating. A great choice for a quality meal.';
  }

  @override
  String placeDescCafe(String name) {
    return '$name is a cozy café perfect for a coffee break or a light bite in a relaxed atmosphere.';
  }

  @override
  String placeDescCafeWithRating(String name, String rating) {
    return '$name is a highly regarded café with a $rating-star rating, perfect for coffee and a relaxing break.';
  }

  @override
  String placeDescBar(String name) {
    return '$name is a great bar for enjoying drinks and a lively atmosphere with friends.';
  }

  @override
  String placeDescMuseum(String name) {
    return '$name offers an enriching cultural experience with fascinating exhibits and inspiring collections.';
  }

  @override
  String placeDescPark(String name) {
    return '$name is a beautiful green space ideal for a walk, relaxation, or outdoor activities.';
  }

  @override
  String placeDescAttraction(String name) {
    return '$name is a must-visit destination with unique experiences and memorable moments.';
  }

  @override
  String placeDescAttractionWithRating(String name, String rating) {
    return '$name is a top-rated attraction with $rating stars, offering unique and memorable experiences.';
  }

  @override
  String placeDescSpa(String name) {
    return '$name is a premium wellness destination offering relaxing treatments and rejuvenating experiences.';
  }

  @override
  String placeDescGeneric(String name) {
    return '$name is a wonderful place to discover, with great atmosphere and excellent vibes.';
  }

  @override
  String placeDescGenericWithRating(String name, String rating) {
    return '$name is a highly-rated local gem with $rating stars, offering a unique experience worth exploring.';
  }

  @override
  String get notifReEngagementEnergeticV0Title => 'Psst... Moody misses you 👀';

  @override
  String get notifReEngagementEnergeticV0Body =>
      'The world\'s been waiting. Ready to explore again?';

  @override
  String get notifReEngagementEnergeticV1Title => 'Your wanderlust called';

  @override
  String get notifReEngagementEnergeticV1Body =>
      'It left a voicemail. Something about adventure. Want to listen?';

  @override
  String get notifReEngagementEnergeticV2Title => 'Plot twist needed';

  @override
  String get notifReEngagementEnergeticV2Body =>
      'Your story\'s been on pause. Time to write the next chapter.';

  @override
  String get notifReEngagementFriendlyV0Title =>
      'Hey, we\'ve been thinking of you 💛';

  @override
  String get notifReEngagementFriendlyV0Body =>
      'Come back and I will help plan your next adventure.';

  @override
  String get notifReEngagementFriendlyV1Title =>
      'Missing your energy around here!';

  @override
  String get notifReEngagementFriendlyV1Body =>
      'Your travel bestie is ready whenever you are.';

  @override
  String get notifReEngagementFriendlyV2Title => 'Good to see you again soon';

  @override
  String get notifReEngagementFriendlyV2Body =>
      'Ready to discover something new together?';

  @override
  String get notifReEngagementProfessionalV0Title => 'Ready when you are';

  @override
  String get notifReEngagementProfessionalV0Body =>
      'Your travel plans are waiting.';

  @override
  String get notifReEngagementProfessionalV1Title => 'Time to explore';

  @override
  String get notifReEngagementProfessionalV1Body =>
      'Open the app to pick up where you left off.';

  @override
  String get notifReEngagementProfessionalV2Title => 'Your journey continues';

  @override
  String get notifReEngagementProfessionalV2Body =>
      'New recommendations are ready for you.';

  @override
  String get notifReEngagementDirectV0Title => 'You haven\'t checked in lately';

  @override
  String get notifReEngagementDirectV0Body => 'Open WanderMood to continue.';

  @override
  String get notifReEngagementDirectV1Title => 'Your travel plans are waiting';

  @override
  String get notifReEngagementDirectV1Body => 'Tap to continue.';

  @override
  String get notifReEngagementDirectV2Title => 'Back when you\'re ready';

  @override
  String get notifReEngagementDirectV2Body =>
      'Your saved plans and mood history are here.';

  @override
  String get notifMorningWithPlanFallbackActivity => 'your first stop';

  @override
  String notifMorningWithPlanEnergeticTitle(String weatherEmoji) {
    return 'Rise and shine $weatherEmoji';
  }

  @override
  String notifMorningWithPlanEnergeticBody(String activityName) {
    return 'First up: $activityName. Let\'s own today.';
  }

  @override
  String notifMorningWithPlanFriendlyTitle(String weatherEmoji) {
    return 'Good morning $weatherEmoji';
  }

  @override
  String notifMorningWithPlanFriendlyBody(String activityName) {
    return 'We\'re starting with $activityName today — I\'m here if you need me.';
  }

  @override
  String notifMorningWithPlanProfessionalTitle(String weatherEmoji) {
    return 'Good morning $weatherEmoji';
  }

  @override
  String notifMorningWithPlanProfessionalBody(String activityName) {
    return 'Your schedule includes $activityName today.';
  }

  @override
  String notifMorningWithPlanDirectTitle(String weatherEmoji) {
    return 'Today\'s plan $weatherEmoji';
  }

  @override
  String notifMorningWithPlanDirectBody(String activityName) {
    return '$activityName is first. Tap to open.';
  }

  @override
  String get notifDailyMoodCheckInEnergeticV0Title =>
      'What vibe are we serving today? ✨';

  @override
  String get notifDailyMoodCheckInEnergeticV0Body =>
      'Log your mood and I will find your perfect match.';

  @override
  String get notifDailyMoodCheckInEnergeticV1Title => 'Mood check! Go.';

  @override
  String get notifDailyMoodCheckInEnergeticV1Body =>
      'Three seconds. Maximum insights. Let\'s see it.';

  @override
  String get notifDailyMoodCheckInEnergeticV2Title =>
      'Your emotional GPS needs calibrating';

  @override
  String get notifDailyMoodCheckInEnergeticV2Body =>
      'Tell Moody how you\'re feeling — it shapes everything.';

  @override
  String get notifDailyMoodCheckInFriendlyV0Title =>
      'Good morning! How are you feeling? 😊';

  @override
  String get notifDailyMoodCheckInFriendlyV0Body =>
      'Log your mood and let\'s plan something that fits.';

  @override
  String get notifDailyMoodCheckInFriendlyV1Title => 'Daily mood check-in time';

  @override
  String get notifDailyMoodCheckInFriendlyV1Body =>
      'A quick tap so I know how your day is going.';

  @override
  String get notifDailyMoodCheckInFriendlyV2Title =>
      'How\'s your travel mood today?';

  @override
  String get notifDailyMoodCheckInFriendlyV2Body =>
      'Share how you\'re feeling and discover what matches.';

  @override
  String get notifDailyMoodCheckInProfessionalV0Title => 'Daily mood check-in';

  @override
  String get notifDailyMoodCheckInProfessionalV0Body =>
      'Log today\'s mood for personalised recommendations.';

  @override
  String get notifDailyMoodCheckInProfessionalV1Title => 'Time to check in';

  @override
  String get notifDailyMoodCheckInProfessionalV1Body =>
      'Record your mood to continue your streak.';

  @override
  String get notifDailyMoodCheckInProfessionalV2Title => 'Mood log reminder';

  @override
  String get notifDailyMoodCheckInProfessionalV2Body =>
      'Your daily check-in keeps recommendations accurate.';

  @override
  String get notifDailyMoodCheckInDirectV0Title => 'Log today\'s mood';

  @override
  String get notifDailyMoodCheckInDirectV0Body => 'Tap to check in.';

  @override
  String get notifDailyMoodCheckInDirectV1Title => 'Daily check-in';

  @override
  String get notifDailyMoodCheckInDirectV1Body => 'How are you feeling today?';

  @override
  String get notifDailyMoodCheckInDirectV2Title => 'Mood reminder';

  @override
  String get notifDailyMoodCheckInDirectV2Body =>
      'Log your mood to keep your streak alive.';

  @override
  String get notifGenerateMyDayEnergeticV0Title => 'Let Moody cook today 🔥';

  @override
  String get notifGenerateMyDayEnergeticV0Body =>
      'Your perfect day is one tap away — trust the algorithm.';

  @override
  String get notifGenerateMyDayEnergeticV1Title =>
      'Blank day? Not on Moody\'s watch';

  @override
  String get notifGenerateMyDayEnergeticV1Body =>
      'Tell Moody your mood and watch the magic happen.';

  @override
  String get notifGenerateMyDayEnergeticV2Title => 'Today could be legendary';

  @override
  String get notifGenerateMyDayEnergeticV2Body =>
      'You in? Moody\'s ready to generate something unforgettable.';

  @override
  String get notifGenerateMyDayFriendlyV0Title => 'Ready to plan today? 🗺️';

  @override
  String get notifGenerateMyDayFriendlyV0Body =>
      'Let Moody put together the perfect day for your mood.';

  @override
  String get notifGenerateMyDayFriendlyV1Title =>
      'Your day is full of possibilities';

  @override
  String get notifGenerateMyDayFriendlyV1Body =>
      'Generate a plan and make the most of today.';

  @override
  String get notifGenerateMyDayFriendlyV2Title => 'Moody has ideas for today!';

  @override
  String get notifGenerateMyDayFriendlyV2Body =>
      'Tap to see what\'s perfect for your current mood.';

  @override
  String get notifGenerateMyDayProfessionalV0Title => 'Plan your day';

  @override
  String get notifGenerateMyDayProfessionalV0Body =>
      'Generate a mood-matched itinerary for today.';

  @override
  String get notifGenerateMyDayProfessionalV1Title => 'Daily planner ready';

  @override
  String get notifGenerateMyDayProfessionalV1Body =>
      'Tap to create today\'s activity plan.';

  @override
  String get notifGenerateMyDayProfessionalV2Title =>
      'Generate today\'s itinerary';

  @override
  String get notifGenerateMyDayProfessionalV2Body =>
      'Personalised to your mood and preferences.';

  @override
  String get notifGenerateMyDayDirectV0Title => 'Plan today';

  @override
  String get notifGenerateMyDayDirectV0Body => 'Tap to generate your day.';

  @override
  String get notifGenerateMyDayDirectV1Title => 'Generate My Day';

  @override
  String get notifGenerateMyDayDirectV1Body => 'Create today\'s itinerary now.';

  @override
  String get notifGenerateMyDayDirectV2Title => 'Today\'s plan';

  @override
  String get notifGenerateMyDayDirectV2Body => 'Tap to build your schedule.';

  @override
  String get notifWeatherNudgeEnergeticV0Title =>
      'The weather just got interesting ☀️';

  @override
  String get notifWeatherNudgeEnergeticV0Body =>
      'Moody\'s already updating your picks. Check what\'s good.';

  @override
  String get notifWeatherNudgeEnergeticV1Title =>
      'Weather alert: perfect adventure conditions';

  @override
  String get notifWeatherNudgeEnergeticV1Body =>
      'Get out there — Moody\'s got the spots.';

  @override
  String get notifWeatherNudgeEnergeticV2Title =>
      'Rain? Moody has opinions about that';

  @override
  String get notifWeatherNudgeEnergeticV2Body =>
      'Tap to see what\'s actually great on a day like this.';

  @override
  String get notifWeatherNudgeFriendlyV0Title =>
      'Today\'s weather is looking great! 🌤️';

  @override
  String get notifWeatherNudgeFriendlyV0Body =>
      'Perfect for getting out — want to see what\'s nearby?';

  @override
  String get notifWeatherNudgeFriendlyV1Title =>
      'Weather update for your plans';

  @override
  String get notifWeatherNudgeFriendlyV1Body =>
      'Check the latest conditions and adjust your day.';

  @override
  String get notifWeatherNudgeFriendlyV2Title => 'Cosy day incoming';

  @override
  String get notifWeatherNudgeFriendlyV2Body =>
      'Let Moody suggest something perfect for this weather.';

  @override
  String get notifWeatherNudgeProfessionalV0Title => 'Weather update';

  @override
  String get notifWeatherNudgeProfessionalV0Body =>
      'Conditions have changed. Check activity suggestions.';

  @override
  String get notifWeatherNudgeProfessionalV1Title => 'Today\'s forecast';

  @override
  String get notifWeatherNudgeProfessionalV1Body =>
      'Updated recommendations based on current weather.';

  @override
  String get notifWeatherNudgeProfessionalV2Title => 'Weather change noted';

  @override
  String get notifWeatherNudgeProfessionalV2Body =>
      'Your activity plan has been refreshed.';

  @override
  String get notifWeatherNudgeDirectV0Title => 'Weather changed';

  @override
  String get notifWeatherNudgeDirectV0Body =>
      'Check updated activity suggestions.';

  @override
  String get notifWeatherNudgeDirectV1Title => 'Weather alert';

  @override
  String get notifWeatherNudgeDirectV1Body => 'Tap for weather-matched plans.';

  @override
  String get notifWeatherNudgeDirectV2Title => 'Today\'s conditions';

  @override
  String get notifWeatherNudgeDirectV2Body =>
      'Updated picks based on the weather.';

  @override
  String get notifLocationDiscoveryEnergeticV0Title =>
      'You\'re surrounded by hidden gems 💎';

  @override
  String get notifLocationDiscoveryEnergeticV0Body =>
      'Moody spotted something amazing near you. Go look.';

  @override
  String get notifLocationDiscoveryEnergeticV1Title =>
      'Plot twist: your next fave spot is 5 mins away';

  @override
  String get notifLocationDiscoveryEnergeticV1Body =>
      'No excuses. Moody found it. Tap to see.';

  @override
  String get notifLocationDiscoveryEnergeticV2Title =>
      'Something\'s calling your name nearby';

  @override
  String get notifLocationDiscoveryEnergeticV2Body =>
      'Your GPS says you should definitely check this out.';

  @override
  String get notifLocationDiscoveryFriendlyV0Title =>
      'Something great is near you! 📍';

  @override
  String get notifLocationDiscoveryFriendlyV0Body =>
      'Moody found a spot that might be just your thing.';

  @override
  String get notifLocationDiscoveryFriendlyV1Title => 'Discovery nearby';

  @override
  String get notifLocationDiscoveryFriendlyV1Body =>
      'There\'s something worth checking out close to where you are.';

  @override
  String get notifLocationDiscoveryFriendlyV2Title =>
      'Moody found something interesting';

  @override
  String get notifLocationDiscoveryFriendlyV2Body =>
      'A local gem is waiting just around the corner.';

  @override
  String get notifLocationDiscoveryProfessionalV0Title => 'Nearby discovery';

  @override
  String get notifLocationDiscoveryProfessionalV0Body =>
      'A new location matches your travel interests.';

  @override
  String get notifLocationDiscoveryProfessionalV1Title =>
      'Local point of interest';

  @override
  String get notifLocationDiscoveryProfessionalV1Body =>
      'Something relevant to your preferences is close by.';

  @override
  String get notifLocationDiscoveryProfessionalV2Title =>
      'Place discovered nearby';

  @override
  String get notifLocationDiscoveryProfessionalV2Body =>
      'Check the activity suggestion for your area.';

  @override
  String get notifLocationDiscoveryDirectV0Title => 'Place nearby';

  @override
  String get notifLocationDiscoveryDirectV0Body =>
      'Something matches your interests. Tap to see.';

  @override
  String get notifLocationDiscoveryDirectV1Title => 'Local discovery';

  @override
  String get notifLocationDiscoveryDirectV1Body => 'New spot near you.';

  @override
  String get notifLocationDiscoveryDirectV2Title => 'Nearby activity';

  @override
  String get notifLocationDiscoveryDirectV2Body => 'Check what\'s close.';

  @override
  String get notifSavedActivityReminderEnergeticV0Title =>
      'Your saved spots are feeling ignored 👀';

  @override
  String get notifSavedActivityReminderEnergeticV0Body =>
      'You saved it for a reason. Time to actually go.';

  @override
  String get notifSavedActivityReminderEnergeticV1Title =>
      'That thing on your list? Still there.';

  @override
  String get notifSavedActivityReminderEnergeticV1Body =>
      'Moody\'s keeping receipts. Shall we make it happen?';

  @override
  String get notifSavedActivityReminderEnergeticV2Title =>
      'Reminder: you have taste';

  @override
  String get notifSavedActivityReminderEnergeticV2Body =>
      'Your saved activities are proof. Go experience them.';

  @override
  String get notifSavedActivityReminderFriendlyV0Title =>
      'Remember that place you saved? 🌟';

  @override
  String get notifSavedActivityReminderFriendlyV0Body =>
      'It\'s still on your list — want to make plans?';

  @override
  String get notifSavedActivityReminderFriendlyV1Title =>
      'Your saved activities are waiting';

  @override
  String get notifSavedActivityReminderFriendlyV1Body =>
      'Ready to turn those saves into actual plans?';

  @override
  String get notifSavedActivityReminderFriendlyV2Title =>
      'Don\'t forget your saved spots!';

  @override
  String get notifSavedActivityReminderFriendlyV2Body =>
      'You picked these for a reason — let me help you go.';

  @override
  String get notifSavedActivityReminderProfessionalV0Title =>
      'Saved activity reminder';

  @override
  String get notifSavedActivityReminderProfessionalV0Body =>
      'You have activities saved. Ready to plan a visit?';

  @override
  String get notifSavedActivityReminderProfessionalV1Title => 'Your saved list';

  @override
  String get notifSavedActivityReminderProfessionalV1Body =>
      'Revisit your saved places and schedule a visit.';

  @override
  String get notifSavedActivityReminderProfessionalV2Title =>
      'Saved places waiting';

  @override
  String get notifSavedActivityReminderProfessionalV2Body =>
      'Plan a visit to your bookmarked activities.';

  @override
  String get notifSavedActivityReminderDirectV0Title =>
      'Saved activities need attention';

  @override
  String get notifSavedActivityReminderDirectV0Body => 'Tap to view your list.';

  @override
  String get notifSavedActivityReminderDirectV1Title => 'Your saved list';

  @override
  String get notifSavedActivityReminderDirectV1Body =>
      'Check and plan a visit.';

  @override
  String get notifSavedActivityReminderDirectV2Title => 'Saved spots reminder';

  @override
  String get notifSavedActivityReminderDirectV2Body =>
      'Schedule a visit to a saved activity.';

  @override
  String get notifFestivalEventEnergeticV0Title =>
      'Something epic is happening near you 🎉';

  @override
  String get notifFestivalEventEnergeticV0Body =>
      'Moody can\'t keep quiet about this. You need to see it.';

  @override
  String get notifFestivalEventEnergeticV1Title =>
      'An event just dropped that has your name on it';

  @override
  String get notifFestivalEventEnergeticV1Body =>
      'Seriously, this one\'s too good to miss. Tap to see.';

  @override
  String get notifFestivalEventEnergeticV2Title =>
      'Festival alert! Your kind of thing.';

  @override
  String get notifFestivalEventEnergeticV2Body =>
      'Moody found an event that matches your vibe. Go.';

  @override
  String get notifFestivalEventFriendlyV0Title =>
      'There\'s a fun event coming up! 🎊';

  @override
  String get notifFestivalEventFriendlyV0Body =>
      'Something\'s happening nearby that you might love.';

  @override
  String get notifFestivalEventFriendlyV1Title => 'Event alert near you';

  @override
  String get notifFestivalEventFriendlyV1Body =>
      'Moody found something worth checking out this week.';

  @override
  String get notifFestivalEventFriendlyV2Title =>
      'Something exciting is happening';

  @override
  String get notifFestivalEventFriendlyV2Body =>
      'A local event that fits your interests is coming up.';

  @override
  String get notifFestivalEventProfessionalV0Title => 'Upcoming local event';

  @override
  String get notifFestivalEventProfessionalV0Body =>
      'An event matching your interests is taking place soon.';

  @override
  String get notifFestivalEventProfessionalV1Title => 'Event notification';

  @override
  String get notifFestivalEventProfessionalV1Body =>
      'A relevant festival or event is happening nearby.';

  @override
  String get notifFestivalEventProfessionalV2Title => 'Festival alert';

  @override
  String get notifFestivalEventProfessionalV2Body =>
      'Local event details are ready for review.';

  @override
  String get notifFestivalEventDirectV0Title => 'Event nearby this week';

  @override
  String get notifFestivalEventDirectV0Body => 'Tap to see details.';

  @override
  String get notifFestivalEventDirectV1Title => 'Local festival happening';

  @override
  String get notifFestivalEventDirectV1Body => 'Check event details.';

  @override
  String get notifFestivalEventDirectV2Title => 'Upcoming event';

  @override
  String get notifFestivalEventDirectV2Body => 'Event near you this week.';

  @override
  String get notifCompanionMorningEnergeticV0Title =>
      'Morning! I\'m already plotting ☀️';

  @override
  String get notifCompanionMorningEnergeticV0Body =>
      'What are we doing today? Drop your mood and let\'s go.';

  @override
  String get notifCompanionMorningEnergeticV1Title => 'Rise and explore! ✨';

  @override
  String get notifCompanionMorningEnergeticV1Body =>
      'A new day = new adventures. I\'m ready when you are.';

  @override
  String get notifCompanionMorningEnergeticV2Title =>
      'Your travel bestie is awake';

  @override
  String get notifCompanionMorningEnergeticV2Body =>
      'And honestly a little too excited about today\'s possibilities.';

  @override
  String get notifCompanionMorningFriendlyV0Title => 'Good morning! ☀️';

  @override
  String get notifCompanionMorningFriendlyV0Body =>
      'How are you feeling? Let me help make today amazing.';

  @override
  String get notifCompanionMorningFriendlyV1Title => 'Morning check-in';

  @override
  String get notifCompanionMorningFriendlyV1Body =>
      'Start the day with your mood and let\'s plan something great.';

  @override
  String get notifCompanionMorningFriendlyV2Title =>
      'I\'m saying good morning 😊';

  @override
  String get notifCompanionMorningFriendlyV2Body =>
      'Share how you\'re feeling and let\'s make today count.';

  @override
  String get notifCompanionMorningProfessionalV0Title => 'Good morning';

  @override
  String get notifCompanionMorningProfessionalV0Body =>
      'Check in with today\'s mood to get personalised suggestions.';

  @override
  String get notifCompanionMorningProfessionalV1Title => 'Morning check-in';

  @override
  String get notifCompanionMorningProfessionalV1Body =>
      'Log your mood to start your day with tailored recommendations.';

  @override
  String get notifCompanionMorningProfessionalV2Title => 'Start your day';

  @override
  String get notifCompanionMorningProfessionalV2Body =>
      'Today\'s recommendations are ready for your mood.';

  @override
  String get notifCompanionMorningDirectV0Title => 'Morning check-in';

  @override
  String get notifCompanionMorningDirectV0Body =>
      'Log your mood to start the day.';

  @override
  String get notifCompanionMorningDirectV1Title => 'Good morning';

  @override
  String get notifCompanionMorningDirectV1Body => 'Tap to check in.';

  @override
  String get notifCompanionMorningDirectV2Title => 'Start your day';

  @override
  String get notifCompanionMorningDirectV2Body => 'Log your mood.';

  @override
  String get notifCompanionAfternoonEnergeticV0Title =>
      'Midday report — how\'s it going? 🌞';

  @override
  String get notifCompanionAfternoonEnergeticV0Body =>
      'Tell me what you\'re feeling. We can still make today legendary.';

  @override
  String get notifCompanionAfternoonEnergeticV1Title =>
      'Afternoon check! Still thriving? ✨';

  @override
  String get notifCompanionAfternoonEnergeticV1Body =>
      'Update your mood and I\'ll update your picks.';

  @override
  String get notifCompanionAfternoonEnergeticV2Title =>
      'Halfway through the day';

  @override
  String get notifCompanionAfternoonEnergeticV2Body =>
      'How\'s your energy? I\'ve got afternoon plans if you need them.';

  @override
  String get notifCompanionAfternoonFriendlyV0Title => 'Afternoon check-in! 😊';

  @override
  String get notifCompanionAfternoonFriendlyV0Body =>
      'Hope your day\'s been great — how are you feeling now?';

  @override
  String get notifCompanionAfternoonFriendlyV1Title => 'I\'m thinking of you';

  @override
  String get notifCompanionAfternoonFriendlyV1Body =>
      'How\'s your afternoon going? Update your mood anytime.';

  @override
  String get notifCompanionAfternoonFriendlyV2Title => 'Midday check-in';

  @override
  String get notifCompanionAfternoonFriendlyV2Body =>
      'Check in with how you\'re feeling and see what\'s nearby.';

  @override
  String get notifCompanionAfternoonProfessionalV0Title => 'Afternoon check-in';

  @override
  String get notifCompanionAfternoonProfessionalV0Body =>
      'Update your mood for afternoon recommendations.';

  @override
  String get notifCompanionAfternoonProfessionalV1Title => 'Midday update';

  @override
  String get notifCompanionAfternoonProfessionalV1Body =>
      'Log how you\'re feeling to refine today\'s suggestions.';

  @override
  String get notifCompanionAfternoonProfessionalV2Title =>
      'How\'s your afternoon?';

  @override
  String get notifCompanionAfternoonProfessionalV2Body =>
      'Check in to keep your travel profile current.';

  @override
  String get notifCompanionAfternoonDirectV0Title => 'Afternoon check-in';

  @override
  String get notifCompanionAfternoonDirectV0Body => 'How are you feeling?';

  @override
  String get notifCompanionAfternoonDirectV1Title => 'Midday check';

  @override
  String get notifCompanionAfternoonDirectV1Body => 'Update your mood.';

  @override
  String get notifCompanionAfternoonDirectV2Title => 'Afternoon';

  @override
  String get notifCompanionAfternoonDirectV2Body => 'Tap to log your mood.';

  @override
  String get notifCompanionEveningEnergeticV0Title =>
      'Evening! What did you get up to? 🌙';

  @override
  String get notifCompanionEveningEnergeticV0Body =>
      'Catch me up — any highlights from today?';

  @override
  String get notifCompanionEveningEnergeticV1Title => 'Golden hour check ✨';

  @override
  String get notifCompanionEveningEnergeticV1Body =>
      'Wind down, reflect, share. What was the best bit?';

  @override
  String get notifCompanionEveningEnergeticV2Title => 'Night mode activated';

  @override
  String get notifCompanionEveningEnergeticV2Body =>
      'Tell me about your day — and maybe plan tomorrow.';

  @override
  String get notifCompanionEveningFriendlyV0Title => 'Good evening! 🌙';

  @override
  String get notifCompanionEveningFriendlyV0Body =>
      'How was your day? Share your mood and reflect with me.';

  @override
  String get notifCompanionEveningFriendlyV1Title => 'Evening check-in';

  @override
  String get notifCompanionEveningFriendlyV1Body =>
      'Wind down time — any adventures to log?';

  @override
  String get notifCompanionEveningFriendlyV2Title => 'Evening check-in';

  @override
  String get notifCompanionEveningFriendlyV2Body =>
      'How are you feeling as the day wraps up?';

  @override
  String get notifCompanionEveningProfessionalV0Title => 'Evening check-in';

  @override
  String get notifCompanionEveningProfessionalV0Body =>
      'Reflect on today and log your end-of-day mood.';

  @override
  String get notifCompanionEveningProfessionalV1Title => 'End of day';

  @override
  String get notifCompanionEveningProfessionalV1Body =>
      'Record your evening mood for a full picture of your day.';

  @override
  String get notifCompanionEveningProfessionalV2Title => 'Good evening';

  @override
  String get notifCompanionEveningProfessionalV2Body =>
      'Today\'s activity summary is ready. Log your reflection.';

  @override
  String get notifCompanionEveningDirectV0Title => 'Evening check-in';

  @override
  String get notifCompanionEveningDirectV0Body => 'How was your day?';

  @override
  String get notifCompanionEveningDirectV1Title => 'End of day';

  @override
  String get notifCompanionEveningDirectV1Body => 'Log your mood.';

  @override
  String get notifCompanionEveningDirectV2Title => 'Good evening';

  @override
  String get notifCompanionEveningDirectV2Body => 'Tap to check in.';

  @override
  String notifStreakMilestoneEnergeticV0Title(String days) {
    return '$days days straight — Moody is SHOOK 🔥';
  }

  @override
  String get notifStreakMilestoneEnergeticV0Body =>
      'You\'re basically a WanderMood legend at this point. Keep going.';

  @override
  String notifStreakMilestoneEnergeticV1Title(String days) {
    return 'Alert: $days-day streak detected ⚡';
  }

  @override
  String get notifStreakMilestoneEnergeticV1Body =>
      'This is extremely impressive and Moody is not chill about it.';

  @override
  String notifStreakMilestoneEnergeticV2Title(String days) {
    return '$days-day streak! You\'re on fire!';
  }

  @override
  String get notifStreakMilestoneEnergeticV2Body =>
      'The world needs more explorers like you. Don\'t stop now.';

  @override
  String notifStreakMilestoneFriendlyV0Title(String days) {
    return 'Wow, $days days in a row! 🎉';
  }

  @override
  String get notifStreakMilestoneFriendlyV0Body =>
      'You\'ve been so consistent — Moody is really proud of you!';

  @override
  String notifStreakMilestoneFriendlyV1Title(String days) {
    return '$days-day streak reached!';
  }

  @override
  String get notifStreakMilestoneFriendlyV1Body =>
      'You\'re doing amazing. Keep that travel energy going!';

  @override
  String notifStreakMilestoneFriendlyV2Title(String days) {
    return 'You\'re on a $days-day streak 🔥';
  }

  @override
  String get notifStreakMilestoneFriendlyV2Body =>
      'What an achievement — here\'s to the next milestone!';

  @override
  String notifStreakMilestoneProfessionalV0Title(String days) {
    return '$days-day streak milestone';
  }

  @override
  String get notifStreakMilestoneProfessionalV0Body =>
      'Consistent engagement. Your streak continues.';

  @override
  String get notifStreakMilestoneProfessionalV1Title =>
      'Streak milestone reached';

  @override
  String notifStreakMilestoneProfessionalV1Body(String days) {
    return '$days consecutive days. Keep it going.';
  }

  @override
  String notifStreakMilestoneProfessionalV2Title(String days) {
    return '$days days';
  }

  @override
  String get notifStreakMilestoneProfessionalV2Body =>
      'Streak milestone achieved.';

  @override
  String notifStreakMilestoneDirectV0Title(String days) {
    return '$days-day streak';
  }

  @override
  String get notifStreakMilestoneDirectV0Body => 'Keep going.';

  @override
  String notifStreakMilestoneDirectV1Title(String days) {
    return 'Streak milestone: $days days';
  }

  @override
  String get notifStreakMilestoneDirectV1Body => 'Don\'t break it now.';

  @override
  String notifStreakMilestoneDirectV2Title(String days) {
    return '$days consecutive days';
  }

  @override
  String get notifStreakMilestoneDirectV2Body => 'Streak milestone reached.';

  @override
  String notifAchievementUnlockedEnergeticV0Title(String achievementTitle) {
    return '🏆 YOU JUST EARNED \'$achievementTitle\'!';
  }

  @override
  String get notifAchievementUnlockedEnergeticV0Body =>
      'Moody is doing an actual happy dance right now. You legend.';

  @override
  String notifAchievementUnlockedEnergeticV1Title(String achievementTitle) {
    return 'Badge unlocked: $achievementTitle ✨';
  }

  @override
  String get notifAchievementUnlockedEnergeticV1Body =>
      'This one\'s got your name all over it. Well deserved.';

  @override
  String notifAchievementUnlockedEnergeticV2Title(String achievementTitle) {
    return 'Achievement get: $achievementTitle 🎉';
  }

  @override
  String get notifAchievementUnlockedEnergeticV2Body =>
      'Added to your collection. Moody knew you could do it.';

  @override
  String get notifAchievementUnlockedFriendlyV0Title =>
      'New achievement unlocked! 🏆';

  @override
  String notifAchievementUnlockedFriendlyV0Body(String achievementTitle) {
    return 'You earned the \'$achievementTitle\' badge — that\'s amazing!';
  }

  @override
  String notifAchievementUnlockedFriendlyV1Title(String achievementTitle) {
    return 'Congrats! \'$achievementTitle\' is yours 🌟';
  }

  @override
  String get notifAchievementUnlockedFriendlyV1Body =>
      'You worked for this one. Enjoy the milestone!';

  @override
  String notifAchievementUnlockedFriendlyV2Title(String achievementTitle) {
    return 'You unlocked \'$achievementTitle\'!';
  }

  @override
  String get notifAchievementUnlockedFriendlyV2Body =>
      'Achievement added to your profile — you\'re on a roll!';

  @override
  String notifAchievementUnlockedProfessionalV0Title(String achievementTitle) {
    return 'Achievement unlocked: $achievementTitle';
  }

  @override
  String get notifAchievementUnlockedProfessionalV0Body =>
      'Badge earned and added to your profile.';

  @override
  String notifAchievementUnlockedProfessionalV1Title(String achievementTitle) {
    return 'New badge: $achievementTitle';
  }

  @override
  String get notifAchievementUnlockedProfessionalV1Body =>
      'Achievement milestone reached.';

  @override
  String notifAchievementUnlockedProfessionalV2Title(String achievementTitle) {
    return '$achievementTitle';
  }

  @override
  String get notifAchievementUnlockedProfessionalV2Body =>
      'Achievement unlocked.';

  @override
  String notifAchievementUnlockedDirectV0Title(String achievementTitle) {
    return 'Badge earned: $achievementTitle';
  }

  @override
  String get notifAchievementUnlockedDirectV0Body => 'Achievement unlocked.';

  @override
  String notifAchievementUnlockedDirectV1Title(String achievementTitle) {
    return '$achievementTitle unlocked';
  }

  @override
  String get notifAchievementUnlockedDirectV1Body => 'New achievement added.';

  @override
  String notifAchievementUnlockedDirectV2Title(String achievementTitle) {
    return 'Achievement: $achievementTitle';
  }

  @override
  String get notifAchievementUnlockedDirectV2Body => 'Earned.';

  @override
  String get notifWeeklyMoodRecapEnergeticV0Title =>
      'Your week in moods just dropped 📊';

  @override
  String get notifWeeklyMoodRecapEnergeticV0Body =>
      'Plot twist: you contain multitudes. Want to see the data?';

  @override
  String get notifWeeklyMoodRecapEnergeticV1Title =>
      'Weekly mood report — and it\'s giving a lot';

  @override
  String get notifWeeklyMoodRecapEnergeticV1Body =>
      'Moody crunched the numbers. The results are interesting.';

  @override
  String get notifWeeklyMoodRecapEnergeticV2Title => '7 days, infinite vibes';

  @override
  String get notifWeeklyMoodRecapEnergeticV2Body =>
      'Your mood recap is here and honestly? You\'re fascinating.';

  @override
  String get notifWeeklyMoodRecapFriendlyV0Title =>
      'Your weekly mood recap is ready! 🌈';

  @override
  String get notifWeeklyMoodRecapFriendlyV0Body =>
      'Take a moment to reflect on how your week felt.';

  @override
  String get notifWeeklyMoodRecapFriendlyV1Title => 'Week in review 📊';

  @override
  String get notifWeeklyMoodRecapFriendlyV1Body =>
      'Here\'s a look at your moods this week — want to explore it?';

  @override
  String get notifWeeklyMoodRecapFriendlyV2Title =>
      'Moody has your mood summary ready';

  @override
  String get notifWeeklyMoodRecapFriendlyV2Body =>
      'A little reflection goes a long way. Check your week.';

  @override
  String get notifWeeklyMoodRecapProfessionalV0Title => 'Weekly mood summary';

  @override
  String get notifWeeklyMoodRecapProfessionalV0Body =>
      'Your mood report for the past 7 days is ready.';

  @override
  String get notifWeeklyMoodRecapProfessionalV1Title => 'Week in review';

  @override
  String get notifWeeklyMoodRecapProfessionalV1Body =>
      'Mood data and insights from this week are available.';

  @override
  String get notifWeeklyMoodRecapProfessionalV2Title => 'Weekly report';

  @override
  String get notifWeeklyMoodRecapProfessionalV2Body =>
      'Review your mood patterns from the past week.';

  @override
  String get notifWeeklyMoodRecapDirectV0Title => 'Weekly mood recap';

  @override
  String get notifWeeklyMoodRecapDirectV0Body => 'Tap to view your summary.';

  @override
  String get notifWeeklyMoodRecapDirectV1Title => 'Mood summary ready';

  @override
  String get notifWeeklyMoodRecapDirectV1Body => 'Check your week.';

  @override
  String get notifWeeklyMoodRecapDirectV2Title => 'Weekly report';

  @override
  String get notifWeeklyMoodRecapDirectV2Body => '7-day mood data ready.';

  @override
  String get notifPostTripReflectionEnergeticV0Title =>
      'You just did a whole thing! 🗺️';

  @override
  String get notifPostTripReflectionEnergeticV0Body =>
      'We need ALL the details. How was the adventure?';

  @override
  String get notifPostTripReflectionEnergeticV1Title =>
      'Trip complete — debrief time';

  @override
  String get notifPostTripReflectionEnergeticV1Body =>
      'Moody wants a full recap. Rate it, log it, live it.';

  @override
  String get notifPostTripReflectionEnergeticV2Title => 'Tell me everything';

  @override
  String get notifPostTripReflectionEnergeticV2Body =>
      'That adventure you just finished? It deserves a proper reflection.';

  @override
  String get notifPostTripReflectionFriendlyV0Title =>
      'Hope your trip was amazing! 🌟';

  @override
  String get notifPostTripReflectionFriendlyV0Body =>
      'How did it go? Share your thoughts and log a post-trip mood.';

  @override
  String get notifPostTripReflectionFriendlyV1Title => 'Your plan is complete';

  @override
  String get notifPostTripReflectionFriendlyV1Body =>
      'Take a moment to reflect on how it went.';

  @override
  String get notifPostTripReflectionFriendlyV2Title =>
      'Time for a trip reflection 😊';

  @override
  String get notifPostTripReflectionFriendlyV2Body =>
      'Log how you felt about your adventure — Moody wants to know!';

  @override
  String get notifPostTripReflectionProfessionalV0Title => 'Trip completed';

  @override
  String get notifPostTripReflectionProfessionalV0Body =>
      'Share your post-trip reflection and mood rating.';

  @override
  String get notifPostTripReflectionProfessionalV1Title => 'Post-trip feedback';

  @override
  String get notifPostTripReflectionProfessionalV1Body =>
      'Log how your completed plan went.';

  @override
  String get notifPostTripReflectionProfessionalV2Title => 'Trip summary';

  @override
  String get notifPostTripReflectionProfessionalV2Body =>
      'Record your post-activity mood and reflections.';

  @override
  String get notifPostTripReflectionDirectV0Title => 'Log your post-trip mood';

  @override
  String get notifPostTripReflectionDirectV0Body => 'Rate your experience.';

  @override
  String get notifPostTripReflectionDirectV1Title => 'Trip done';

  @override
  String get notifPostTripReflectionDirectV1Body => 'Reflect on how it went.';

  @override
  String get notifPostTripReflectionDirectV2Title => 'Post-trip check-in';

  @override
  String get notifPostTripReflectionDirectV2Body => 'Log your experience.';

  @override
  String notifMoodFollowUpEnergeticV0Title(String moodType) {
    return 'Still feeling $moodType? 💡';
  }

  @override
  String get notifMoodFollowUpEnergeticV0Body =>
      'Moody found something that matches your energy perfectly.';

  @override
  String notifMoodFollowUpEnergeticV1Title(String moodType) {
    return 'Your $moodType vibe deserves an outlet';
  }

  @override
  String get notifMoodFollowUpEnergeticV1Body =>
      'Here\'s exactly where to take that energy. You\'ll love it.';

  @override
  String notifMoodFollowUpEnergeticV2Title(String moodType) {
    return '$moodType energy + this place = chef\'s kiss';
  }

  @override
  String get notifMoodFollowUpEnergeticV2Body =>
      'Moody did the math. Trust the algorithm.';

  @override
  String notifMoodFollowUpFriendlyV0Title(String moodType) {
    return 'Based on your $moodType mood 💛';
  }

  @override
  String get notifMoodFollowUpFriendlyV0Body =>
      'Moody found something nearby that fits perfectly. Want to see?';

  @override
  String notifMoodFollowUpFriendlyV1Title(String moodType) {
    return 'A suggestion for your $moodType vibe';
  }

  @override
  String get notifMoodFollowUpFriendlyV1Body =>
      'Something close by that matches how you\'re feeling.';

  @override
  String notifMoodFollowUpFriendlyV2Title(String moodType) {
    return 'Still feeling $moodType?';
  }

  @override
  String get notifMoodFollowUpFriendlyV2Body =>
      'Here\'s a great match for your current energy.';

  @override
  String get notifMoodFollowUpProfessionalV0Title => 'Mood-matched suggestion';

  @override
  String notifMoodFollowUpProfessionalV0Body(String moodType) {
    return 'Activity recommendation based on your $moodType check-in.';
  }

  @override
  String get notifMoodFollowUpProfessionalV1Title => 'Based on your mood';

  @override
  String notifMoodFollowUpProfessionalV1Body(String moodType) {
    return 'Curated suggestion aligned with your $moodType preference.';
  }

  @override
  String get notifMoodFollowUpProfessionalV2Title => 'Activity match';

  @override
  String notifMoodFollowUpProfessionalV2Body(String moodType) {
    return 'Suggestion tailored to your $moodType mood.';
  }

  @override
  String notifMoodFollowUpDirectV0Title(String moodType) {
    return 'Suggestion for your $moodType mood';
  }

  @override
  String get notifMoodFollowUpDirectV0Body => 'Tap to see what matches.';

  @override
  String get notifMoodFollowUpDirectV1Title => 'Activity match';

  @override
  String notifMoodFollowUpDirectV1Body(String moodType) {
    return 'Based on your $moodType check-in.';
  }

  @override
  String notifMoodFollowUpDirectV2Title(String moodType) {
    return '$moodType mood match ready';
  }

  @override
  String get notifMoodFollowUpDirectV2Body => 'Tap to see.';

  @override
  String get notifSocialEngagementEnergeticV0Title =>
      'Someone\'s vibing with your post 👀';

  @override
  String get notifSocialEngagementEnergeticV0Body =>
      'Go see who\'s feeling your adventure energy.';

  @override
  String get notifSocialEngagementEnergeticV1Title =>
      'Your mood post got attention!';

  @override
  String get notifSocialEngagementEnergeticV1Body =>
      'Someone reacted — Moody is curious what they thought.';

  @override
  String get notifSocialEngagementEnergeticV2Title =>
      'People are talking about your adventure 🎉';

  @override
  String get notifSocialEngagementEnergeticV2Body =>
      'Your post got some love. Go check it out.';

  @override
  String get notifSocialEngagementFriendlyV0Title =>
      'Someone liked your post! 💛';

  @override
  String get notifSocialEngagementFriendlyV0Body =>
      'Your shared adventure resonated with someone.';

  @override
  String get notifSocialEngagementFriendlyV1Title =>
      'New activity on your post';

  @override
  String get notifSocialEngagementFriendlyV1Body =>
      'Someone\'s engaging with your travel content.';

  @override
  String get notifSocialEngagementFriendlyV2Title => 'Your post got some love';

  @override
  String get notifSocialEngagementFriendlyV2Body =>
      'Check out who\'s reacting to your adventure.';

  @override
  String get notifSocialEngagementProfessionalV0Title =>
      'New activity on your post';

  @override
  String get notifSocialEngagementProfessionalV0Body =>
      'Someone has reacted to your shared content.';

  @override
  String get notifSocialEngagementProfessionalV1Title => 'Post engagement';

  @override
  String get notifSocialEngagementProfessionalV1Body =>
      'New interaction on your recent activity.';

  @override
  String get notifSocialEngagementProfessionalV2Title => 'Social notification';

  @override
  String get notifSocialEngagementProfessionalV2Body =>
      'Your post has new activity.';

  @override
  String get notifSocialEngagementDirectV0Title => 'New like on your post';

  @override
  String get notifSocialEngagementDirectV0Body => 'Tap to see.';

  @override
  String get notifSocialEngagementDirectV1Title => 'Post activity';

  @override
  String get notifSocialEngagementDirectV1Body =>
      'Someone reacted to your post.';

  @override
  String get notifSocialEngagementDirectV2Title => 'New comment';

  @override
  String get notifSocialEngagementDirectV2Body =>
      'Your post has a new comment.';

  @override
  String get notifFriendActivityEnergeticV0Title =>
      'Your travel buddy is making moves 🗺️';

  @override
  String get notifFriendActivityEnergeticV0Body =>
      'Someone in your network just did something worth knowing about.';

  @override
  String get notifFriendActivityEnergeticV1Title =>
      'Plot twist: your crew is exploring';

  @override
  String get notifFriendActivityEnergeticV1Body =>
      'Don\'t get FOMO — check what your travel friends are up to.';

  @override
  String get notifFriendActivityEnergeticV2Title =>
      'Network activity detected 👀';

  @override
  String get notifFriendActivityEnergeticV2Body =>
      'A friend just logged a mood or started a new plan. Curious?';

  @override
  String get notifFriendActivityFriendlyV0Title =>
      'A friend just shared their adventure 💛';

  @override
  String get notifFriendActivityFriendlyV0Body =>
      'Someone you follow has new travel activity. Go check it out.';

  @override
  String get notifFriendActivityFriendlyV1Title =>
      'Your travel buddy is on the move';

  @override
  String get notifFriendActivityFriendlyV1Body =>
      'One of your friends has something new to share.';

  @override
  String get notifFriendActivityFriendlyV2Title => 'Friend activity';

  @override
  String get notifFriendActivityFriendlyV2Body =>
      'Someone you follow just posted a mood or plan.';

  @override
  String get notifFriendActivityProfessionalV0Title => 'Network activity';

  @override
  String get notifFriendActivityProfessionalV0Body =>
      'Someone you follow has posted new travel content.';

  @override
  String get notifFriendActivityProfessionalV1Title => 'Friend update';

  @override
  String get notifFriendActivityProfessionalV1Body =>
      'Activity from your network is available.';

  @override
  String get notifFriendActivityProfessionalV2Title => 'Connection activity';

  @override
  String get notifFriendActivityProfessionalV2Body =>
      'Someone you follow has an update.';

  @override
  String get notifFriendActivityDirectV0Title => 'Friend posted';

  @override
  String get notifFriendActivityDirectV0Body => 'New activity in your network.';

  @override
  String get notifFriendActivityDirectV1Title => 'Travel buddy update';

  @override
  String get notifFriendActivityDirectV1Body =>
      'Someone you follow has new content.';

  @override
  String get notifFriendActivityDirectV2Title => 'Network update';

  @override
  String get notifFriendActivityDirectV2Body => 'Friend activity available.';

  @override
  String get notifWeekendPlanningNudgeEnergeticV0Title =>
      'The weekend is almost here and you have zero plans';

  @override
  String get notifWeekendPlanningNudgeEnergeticV0Body =>
      'Moody to the rescue. Tap to fix that immediately.';

  @override
  String get notifWeekendPlanningNudgeEnergeticV1Title =>
      'Blank weekend detected 🎨';

  @override
  String get notifWeekendPlanningNudgeEnergeticV1Body =>
      'This is a creative emergency. Let Moody fill that canvas.';

  @override
  String get notifWeekendPlanningNudgeEnergeticV2Title =>
      'Friday energy! Weekend plans?';

  @override
  String get notifWeekendPlanningNudgeEnergeticV2Body =>
      'Because \'see how it goes\' is not a Moody-approved strategy.';

  @override
  String get notifWeekendPlanningNudgeFriendlyV0Title =>
      'The weekend\'s coming up! Any plans? 🌟';

  @override
  String get notifWeekendPlanningNudgeFriendlyV0Body =>
      'Let Moody help you plan something you\'ll actually love.';

  @override
  String get notifWeekendPlanningNudgeFriendlyV1Title =>
      'Weekend planning time!';

  @override
  String get notifWeekendPlanningNudgeFriendlyV1Body =>
      'A few taps and Moody can put together a perfect weekend plan.';

  @override
  String get notifWeekendPlanningNudgeFriendlyV2Title =>
      'Ready to plan your weekend?';

  @override
  String get notifWeekendPlanningNudgeFriendlyV2Body =>
      'Moody\'s got ideas — want to see what fits your mood?';

  @override
  String get notifWeekendPlanningNudgeProfessionalV0Title => 'Weekend planning';

  @override
  String get notifWeekendPlanningNudgeProfessionalV0Body =>
      'Create a weekend itinerary tailored to your preferences.';

  @override
  String get notifWeekendPlanningNudgeProfessionalV1Title =>
      'Plan your weekend';

  @override
  String get notifWeekendPlanningNudgeProfessionalV1Body =>
      'Weekend activities are available to schedule.';

  @override
  String get notifWeekendPlanningNudgeProfessionalV2Title => 'Weekend ahead';

  @override
  String get notifWeekendPlanningNudgeProfessionalV2Body =>
      'Tap to plan your upcoming days.';

  @override
  String get notifWeekendPlanningNudgeDirectV0Title => 'Plan your weekend';

  @override
  String get notifWeekendPlanningNudgeDirectV0Body =>
      'No plans yet. Tap to create some.';

  @override
  String get notifWeekendPlanningNudgeDirectV1Title => 'Weekend scheduler';

  @override
  String get notifWeekendPlanningNudgeDirectV1Body =>
      'Add plans for the upcoming weekend.';

  @override
  String get notifWeekendPlanningNudgeDirectV2Title => 'Weekend ahead';

  @override
  String get notifWeekendPlanningNudgeDirectV2Body => 'Tap to plan.';

  @override
  String get notifTrendingInYourCityEnergeticV0Title =>
      'Something is TRENDING near you right now 🔥';

  @override
  String get notifTrendingInYourCityEnergeticV0Body =>
      'Everyone in your city is doing this and Moody can\'t keep quiet.';

  @override
  String get notifTrendingInYourCityEnergeticV1Title =>
      'Hot take: this is blowing up in your area';

  @override
  String get notifTrendingInYourCityEnergeticV1Body =>
      'You probably should know about this. Tap to see.';

  @override
  String get notifTrendingInYourCityEnergeticV2Title =>
      'Trend alert in your city!';

  @override
  String get notifTrendingInYourCityEnergeticV2Body =>
      'This is the moment. Are you going to be part of it?';

  @override
  String get notifTrendingInYourCityFriendlyV0Title =>
      'Something popular is happening near you! 🌟';

  @override
  String get notifTrendingInYourCityFriendlyV0Body =>
      'Moody spotted a trend in your area that fits your style.';

  @override
  String get notifTrendingInYourCityFriendlyV1Title => 'Trending in your city';

  @override
  String get notifTrendingInYourCityFriendlyV1Body =>
      'Here\'s what everyone\'s been enjoying nearby this week.';

  @override
  String get notifTrendingInYourCityFriendlyV2Title =>
      'Hot right now in your area';

  @override
  String get notifTrendingInYourCityFriendlyV2Body =>
      'Check out what\'s trending and see if it\'s your thing.';

  @override
  String get notifTrendingInYourCityProfessionalV0Title => 'Trending locally';

  @override
  String get notifTrendingInYourCityProfessionalV0Body =>
      'Popular activity in your area matching your interests.';

  @override
  String get notifTrendingInYourCityProfessionalV1Title => 'Local trend';

  @override
  String get notifTrendingInYourCityProfessionalV1Body =>
      'What\'s popular nearby this week.';

  @override
  String get notifTrendingInYourCityProfessionalV2Title => 'Popular nearby';

  @override
  String get notifTrendingInYourCityProfessionalV2Body =>
      'Trending activity available in your area.';

  @override
  String get notifTrendingInYourCityDirectV0Title => 'Trending near you';

  @override
  String get notifTrendingInYourCityDirectV0Body =>
      'Check what\'s popular in your area.';

  @override
  String get notifTrendingInYourCityDirectV1Title => 'Local hotspot';

  @override
  String get notifTrendingInYourCityDirectV1Body =>
      'Tap to see what\'s trending.';

  @override
  String get notifTrendingInYourCityDirectV2Title => 'What\'s popular now';

  @override
  String get notifTrendingInYourCityDirectV2Body =>
      'Trending activity near you.';

  @override
  String get commPrefChooseStyleTitle => 'Choose your Moody style';

  @override
  String get commPrefChooseStyleSubtitle =>
      'So I can match my tone perfectly to you.';

  @override
  String get commPrefSpeechBubble => 'How do you want me to talk to you? 😊';

  @override
  String get authWelcomeTitle => 'You\'re in! Welcome 🎉';

  @override
  String get authCallbackConfirmingEmail => 'Confirming your email…';

  @override
  String get authCallbackVerificationFailed =>
      'Email verification failed. Please try again.';

  @override
  String get authRememberMe => 'Remember me';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authSignInHeadline => 'Sign in to your account';

  @override
  String get authLoginCta => 'Log in';

  @override
  String get authOrContinueWith => 'or continue with';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authRegisterCta => 'Register';

  @override
  String get authReviewerHint => 'App Store reviewer? Tap here';

  @override
  String get authEmailRequired => 'Please enter your email address';

  @override
  String get authEmailInvalid => 'Please enter a valid email address';

  @override
  String get authPasswordRequired => 'Please enter your password';

  @override
  String get authDemoSignInFailed => 'Demo sign-in failed. Please try again.';

  @override
  String get authSignInCancelledOrFailed =>
      'Sign-in was cancelled or failed. Please try again.';

  @override
  String get authSignInFailedGeneric => 'Sign-in failed. Please try again.';

  @override
  String get authSocialLoginNotConfigured =>
      'Social login is not configured yet. Please use email/password for now.';

  @override
  String get authSignInCancelledShort => 'Sign-in was cancelled.';

  @override
  String get authNetworkErrorCheckConnection =>
      'Network error. Please check your internet connection.';

  @override
  String get authGoogleSignInIncomplete =>
      'Google Sign-In setup is incomplete. Please use email/password for now.';

  @override
  String get authFacebookSignInIncomplete =>
      'Facebook Sign-In setup is incomplete. Please use email/password for now.';

  @override
  String get moodyChatMicrophoneRequired =>
      'Microphone access is needed for voice input.';

  @override
  String get chatSheetMicrophoneOpenSettings => 'Open Settings';

  @override
  String get devAdminScreenDisabled =>
      'Admin screen is disabled in production builds.';

  @override
  String get moodStatsTitle => 'Mood statistics';

  @override
  String get moodStatsAverageLabel => 'Average mood';

  @override
  String get moodStatsTotalEntriesLabel => 'Total entries';

  @override
  String get moodStatsTypesLabel => 'Mood types';

  @override
  String get signupAlreadyHaveAccount => 'Already have an account?';

  @override
  String get signupFormCreateAccount => 'Create account';

  @override
  String get signupFormJourneyLine => 'Let\'s get you started on your journey!';

  @override
  String get signupFormFullNameLabel => 'Full name';

  @override
  String get signupFormNameRequired => 'Please enter your name';

  @override
  String signupFormPasswordMinLength(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get signupFormConfirmPasswordLabel => 'Confirm password';

  @override
  String get signupFormConfirmPasswordRequired =>
      'Please confirm your password';

  @override
  String get signupFormPasswordsMismatch => 'Passwords do not match';

  @override
  String get signupFormAcceptTerms => 'I accept the terms and conditions';

  @override
  String get signupFormTermsNotAccepted =>
      'Please accept the terms and conditions';

  @override
  String get signupFormAccountCreated => 'Account created successfully!';

  @override
  String signupFormVerifyEmailToast(String email) {
    return 'Account created! Please check your email at $email to verify your account.';
  }

  @override
  String get signupFormEmailAlreadyRegistered =>
      'This email is already registered. Please sign in instead.';

  @override
  String signupFormFailed(String message) {
    return 'Sign-up failed: $message';
  }

  @override
  String get dialogClose => 'Close';

  @override
  String get supportHowCanWeHelp => 'How can we help you?';

  @override
  String get supportContactUsCard => 'Contact Us';

  @override
  String get supportSendFeedbackCard => 'Send Feedback';

  @override
  String get supportTutorialCard => 'Tutorial';

  @override
  String get supportReportIssueCard => 'Report Issue';

  @override
  String get supportFaqSectionTitle => 'Frequently Asked Questions';

  @override
  String get supportFaq1Q => 'How do I plan a new adventure?';

  @override
  String get supportFaq1A =>
      'To plan a new adventure, go to the Explore tab and start a new plan. You can choose your mood, interests, and travel preferences to get personalized recommendations.';

  @override
  String get supportFaq2Q => 'Can I save places for later?';

  @override
  String get supportFaq2A =>
      'Yes! When viewing a place, tap the heart icon to save it to your Saved Places, which you can access from your profile menu.';

  @override
  String get supportFaq3Q => 'How do I track my mood?';

  @override
  String get supportFaq3A =>
      'WanderMood can remind you to track your mood. You can also add a mood entry from the Moody hub when you check in.';

  @override
  String get supportFaq4Q => 'What do the achievement badges mean?';

  @override
  String get supportFaq4A =>
      'Badges are earned by completing activities in the app. Visit Achievements in your profile to see requirements for each badge.';

  @override
  String get supportFaq5Q => 'How does WanderMood use my location?';

  @override
  String get supportFaq5A =>
      'WanderMood uses your location to suggest nearby places and activities. You can adjust location permissions in app settings.';

  @override
  String get supportFaq6Q => 'Can I use WanderMood offline?';

  @override
  String get supportFaq6A =>
      'Some features need an internet connection. Saved places and items already on your device may still be viewable offline.';

  @override
  String get supportAdditionalResources => 'Additional Resources';

  @override
  String get supportAppVersionLabel => 'App Version';

  @override
  String get supportContactDialogTitle => 'Contact Support';

  @override
  String get supportEmailUsAt => 'Email us at:';

  @override
  String get supportEmailSupportHours =>
      'Our support team is available Monday–Friday, 9am–5pm PST.';

  @override
  String get supportToastOpeningFeedback => 'Opening feedback form…';

  @override
  String get supportToastOpeningTutorial => 'Opening app tutorial…';

  @override
  String get supportToastOpeningIssue => 'Opening issue report…';

  @override
  String get appTourStepMyDayBody =>
      'Your plan is broken into moments—morning, afternoon, evening, and night. Choose your vibe, pick your favorites, and I\'ll handle the magic. 🧭🎯 All based on location, time, weather & mood.';

  @override
  String get appTourStepExploreBody =>
      'To plan a new adventure, go to the Explore tab and start a new plan. You can choose your mood, interests, and travel preferences to get personalized recommendations.';

  @override
  String get appTourStepMoodyBody =>
      'Moody gets to know your vibe, your energy, and the kind of day you\'re having. With all that, I create personalized plans — made just for you. Think of me as your fun, curious bestie who\'s always down to explore 🌆🎈';

  @override
  String get appTourStepAgendaBody =>
      'See what\'s scheduled in My Plans — today, tomorrow, or any day — and jump back to Moody when a day is still wide open.';

  @override
  String get appTourStepProfileBody =>
      'Saved places, travel mode, stats, and favorite vibes live here. Tap App settings for notifications, language, privacy, and help.';

  @override
  String get settingsAppTourLabel => 'App tour';

  @override
  String get settingsAppTourSubtitle =>
      'Walk through the bottom tabs again anytime';

  @override
  String get helpSupportAppTourTitle => 'App tour';

  @override
  String get helpSupportAppTourSubtitle =>
      'Replay the interactive walkthrough of the main tabs';

  @override
  String get recListTitle => 'Travel Recommendations';

  @override
  String get recErrorPrefix => 'Error:';

  @override
  String get recTryAgain => 'Try Again';

  @override
  String get recNoneAvailable => 'No recommendations available';

  @override
  String recLocationLabel(String location) {
    return 'Location: $location';
  }

  @override
  String recPriceLabel(String price) {
    return 'Price: $price';
  }

  @override
  String get recFavoriteUpdated => 'Favorite updated successfully';

  @override
  String recFavoriteError(String error) {
    return 'Error updating favorite: $error';
  }

  @override
  String get recDetailTitle => 'Recommendation details';

  @override
  String get recDetailMarkCompleteTooltip => 'Mark as complete';

  @override
  String get recDetailStatusCompleted => 'Completed';

  @override
  String get recDetailStatusNotCompleted => 'Not completed yet';

  @override
  String get recDetailSectionDescription => 'Description';

  @override
  String get recDetailSectionCategory => 'Category';

  @override
  String get recDetailSectionTags => 'Tags';

  @override
  String get recDetailSectionConfidence => 'Confidence';

  @override
  String get recDetailSectionMood => 'Mood';

  @override
  String recDetailMoodRegisteredOn(String date) {
    return 'Logged on $date';
  }

  @override
  String get recDetailSectionWeather => 'Weather';

  @override
  String recDetailWeatherSubtitle(String temp, String humidity) {
    return '$temp°C, $humidity% humidity';
  }

  @override
  String get adventurePlanTitleYour => 'Your ';

  @override
  String get adventurePlanTitleHighlight => 'Adventure Plan';

  @override
  String get adventurePlanTitleForToday => ' for today';

  @override
  String adventurePlanLoadError(String error) {
    return 'Error loading adventures: $error';
  }

  @override
  String get adventurePlanDemoTemperatureLabel => '32°';

  @override
  String get adventurePlanDemoCityLabel => 'Washington DC';

  @override
  String get trendingDetailNoRelatedPlaces => 'No related places found';

  @override
  String get trendingDetailRelatedPlacesError =>
      'Couldn\'t load related places';

  @override
  String get trendingDetailSimilarPlacesSection => 'Similar places';

  @override
  String trendingDetailLongDining(String title) {
    return 'Experience the culinary delights at $title! Join locals and visitors as they savor amazing flavors and create memorable dining moments. Perfect for food lovers exploring the area. 🍽️✨';
  }

  @override
  String trendingDetailLongCulture(String title) {
    return 'Immerse yourself in the rich cultural heritage at $title. Discover art, history, and creativity that defines the local landscape. A must-visit for anyone seeking inspiration and knowledge. 🎨🏛️';
  }

  @override
  String trendingDetailLongOutdoor(String title) {
    return 'Connect with nature and enjoy the fresh air at $title. Whether you\'re looking for a peaceful walk or an active adventure, this outdoor destination offers the perfect escape. 🌳🚶‍♀️';
  }

  @override
  String trendingDetailLongSightseeing(String title) {
    return 'Capture breathtaking views and iconic moments at $title. This scenic spot offers some of the best photography opportunities and unforgettable vistas nearby. Don\'t forget your camera! 📸🌅';
  }

  @override
  String trendingDetailLongShopping(String title) {
    return 'Discover unique finds and local treasures at $title. From boutique stores to local markets, this shopping destination offers something special for every taste and budget. 🛍️💎';
  }

  @override
  String trendingDetailLongFitness(String title) {
    return 'Stay active and energized at $title. Whether you\'re maintaining your fitness routine or trying something new, this location provides excellent facilities for health and wellness. 💪🏃‍♀️';
  }

  @override
  String trendingDetailLongDefault(String title) {
    return 'Join the trending excitement at $title! This popular destination is capturing the attention of locals and visitors alike. Discover what makes this place special and create your own memorable experience. ⭐🎉';
  }

  @override
  String get receiptDownloadPdf => 'Download PDF';

  @override
  String get receiptShare => 'Share Receipt';

  @override
  String get placePhotoTapToView => 'Tap to view';

  @override
  String get periodActivitiesRemoveTitle => 'Remove activity?';

  @override
  String periodActivitiesRemoveBody(String name) {
    return 'Are you sure you want to remove \"$name\"?';
  }

  @override
  String get periodActivitiesRemoveCta => 'Remove';

  @override
  String get periodActivitiesSwipeDelete => 'Delete';

  @override
  String get periodActivitiesSwipeComplete => 'Complete';

  @override
  String get weatherFailedLoadCurrent => 'Failed to load weather';

  @override
  String get weatherFailedLoadForecast => 'Failed to load forecast';

  @override
  String get weatherDetailTitle => 'Weather';

  @override
  String get weatherDetailLoading => 'Loading…';

  @override
  String get weatherDetailLoadError => 'Couldn’t load weather';

  @override
  String get weatherDetail24Hour => '24-hour outlook';

  @override
  String get weatherDetail3Day => 'Next few days';

  @override
  String weatherDetailFeelsLike(int degrees) {
    return 'Feels like $degrees°';
  }

  @override
  String get weatherMoodyTipTimeTonight => 'Tonight';

  @override
  String get weatherMoodyTipRainMorningBody =>
      'Rain this morning — grab your umbrella before heading out.';

  @override
  String get weatherMoodyTipRainAfternoonBody =>
      'It\'s raining outside. A café or museum visit hits different on a day like this.';

  @override
  String get weatherMoodyTipRainEveningBody =>
      'Rain tonight — the perfect excuse to find a cosy spot inside.';

  @override
  String get weatherMoodyTipRainNightBody =>
      'It\'s raining and dark out. Stay cosy — outdoor plans can wait till tomorrow.';

  @override
  String get weatherMoodyTipSunnyHighUvMorningBody =>
      'Great start! Apply sunscreen — UV builds fast once the sun is up.';

  @override
  String get weatherMoodyTipSunnyHighUvAfternoonBody =>
      'UV is high right now. Find shade for a break and keep your water bottle close.';

  @override
  String get weatherMoodyTipSunnyHighUvEveningBody =>
      'The sun is lower now — a perfect time for a walk or terrace visit.';

  @override
  String get weatherMoodyTipSunnyHighUvNightBody =>
      'Clear skies tonight — a great evening for a stroll under the stars.';

  @override
  String get weatherMoodyTipSunnyMildMorningBody =>
      'Mild and dry — a great morning for a walk or breakfast outside.';

  @override
  String get weatherMoodyTipSunnyMildAfternoonBody =>
      'Dry and comfortable out there. Terraces and parks are calling.';

  @override
  String get weatherMoodyTipSunnyMildEveningBody =>
      'A lovely evening for a walk, a bite outside, or just some fresh air.';

  @override
  String get weatherMoodyTipSunnyMildNightBody =>
      'Nice and calm out there. A quiet evening walk might be just what you need.';

  @override
  String get weatherMoodyTipCloudyMorningBody =>
      'Grey skies this morning — bring an extra layer and maybe a warm coffee.';

  @override
  String get weatherMoodyTipCloudyAfternoonBody =>
      'Cloudy and a bit cool. Good day for indoor spots or a museum.';

  @override
  String get weatherMoodyTipCloudyEveningBody =>
      'The clouds are in for the evening. A cosy dinner inside sounds perfect.';

  @override
  String get weatherMoodyTipCloudyNightBody =>
      'Overcast and still. Wrap up if you\'re heading out — it feels cooler than it looks.';

  @override
  String get weatherMoodyTipDefaultMorningBody =>
      'Mixed conditions today — layer up so you\'re ready for anything.';

  @override
  String get weatherMoodyTipDefaultAfternoonBody =>
      'Conditions may shift this afternoon. Keep an eye on the forecast.';

  @override
  String get weatherMoodyTipDefaultEveningBody =>
      'The evening is here — check the latest forecast before heading out.';

  @override
  String get weatherMoodyTipDefaultNightBody =>
      'Quiet outside for now. Check tomorrow\'s forecast in the morning.';

  @override
  String get weatherNoDataAvailable => 'No weather data available';

  @override
  String get weatherShowMore => 'Show More';

  @override
  String get weatherShowLess => 'Show Less';

  @override
  String get locationPickerSelectTitle => 'Select Location';

  @override
  String get locationDropdownSearchResults => 'Search results';

  @override
  String get locationDropdownPopularCities => 'Popular cities';

  @override
  String get locationDropdownNoCitiesFound => 'No cities found';

  @override
  String get locationDropdownSearchCitiesTitle => 'Search cities';

  @override
  String get locationDropdownUseCurrentLocation => 'Use current location';

  @override
  String get locationDropdownDetectExactLocation =>
      'Detect your exact location';

  @override
  String locationDropdownFindCitiesSubtitle(String country) {
    return 'Find cities in $country';
  }

  @override
  String get locationDropdownErrorLocationLabel => 'Your city';

  @override
  String weatherLoadError(String error) {
    return 'Error loading weather data: $error';
  }

  @override
  String get weatherStatsTitle => 'Weather statistics';

  @override
  String get weatherHistoryTitle => 'Weather history';

  @override
  String get weatherToggleTemperature => 'Temperature';

  @override
  String get weatherToggleHumidity => 'Humidity';

  @override
  String get weatherTogglePrecipitation => 'Precipitation';

  @override
  String get weatherForecastTitle => 'Forecast';

  @override
  String get weatherNoForecasts => 'No forecasts available';

  @override
  String get weatherAlertsTitle => 'Weather alerts';

  @override
  String get weatherNoActiveAlerts => 'No active alerts';

  @override
  String myDayWeatherDialogTitle(String city) {
    return 'Weather in $city';
  }

  @override
  String get myDayWeatherFeelsLike => 'Feels like';

  @override
  String get myDayWeatherHumidity => 'Humidity';

  @override
  String get myDayWeatherDescriptionLabel => 'Description';

  @override
  String get myDayWeatherClose => 'Close';

  @override
  String get myDayWeatherUnavailable => 'Weather data unavailable';

  @override
  String get myDayWeatherCheckConnection =>
      'Please check your internet connection';

  @override
  String get myDayWeatherClearSkyFallback => 'Clear skies';

  @override
  String get weatherMainClear => 'Clear';

  @override
  String get weatherMainClouds => 'Clouds';

  @override
  String get weatherMainRain => 'Rain';

  @override
  String get weatherMainDrizzle => 'Drizzle';

  @override
  String get weatherMainThunderstorm => 'Thunderstorm';

  @override
  String get weatherMainSnow => 'Snow';

  @override
  String get weatherMainMist => 'Mist';

  @override
  String get weatherMainFog => 'Fog';

  @override
  String get weatherMainHaze => 'Slight haze';

  @override
  String get weatherMainHazeDescription =>
      'Reduced visibility because the air is hazy';

  @override
  String get weatherMainSmoke => 'Smoke';

  @override
  String get weatherMainDust => 'Dust';

  @override
  String get weatherMainSand => 'Sand';

  @override
  String get weatherMainAsh => 'Ash';

  @override
  String get weatherMainSquall => 'Squall';

  @override
  String get weatherMainTornado => 'Tornado';

  @override
  String get weatherMainOther => 'Weather';

  @override
  String get weatherHistoryEmpty => 'No historical data available';

  @override
  String get weatherHistoryInvalid => 'No valid historical data available';

  @override
  String get moodHistoryEmpty => 'No mood history available';

  @override
  String get exploreLoadMoreIdeas => 'Load more ideas';

  @override
  String get agendaPaymentBadgeFree => 'Free';

  @override
  String get agendaPaymentBadgePaid => 'Paid';

  @override
  String get agendaPaymentBadgeReserved => 'Reserved';

  @override
  String get agendaPaymentBadgePending => 'Pending';

  @override
  String agendaDurationShort(String minutes) {
    return '$minutes min';
  }

  @override
  String get groupPlanWithFriendMenu => 'Plan with a friend';

  @override
  String get groupPlanTogetherTitle => 'Plan together';

  @override
  String get groupPlanHubBody =>
      'Combine moods with a travel partner. Both of you use your own phone — share a short code or open it from a message.';

  @override
  String get groupPlanTileStartTitle => 'Start a session';

  @override
  String get groupPlanTileStartSubtitle =>
      'You’ll get a code to send your friend';

  @override
  String get groupPlanTileJoinTitle => 'Join with code';

  @override
  String get groupPlanTileJoinSubtitle => 'Enter the code from your friend';

  @override
  String get groupPlanCreateTitle => 'Plan with a friend';

  @override
  String get groupPlanCreateBody =>
      'Create a shared session. You’ll get a short code to send your travel partner — they enter it on their phone.';

  @override
  String get groupPlanCreateOptionalTitleLabel =>
      'Optional title (e.g. Today in Lisbon)';

  @override
  String get groupPlanCreateButton => 'Create & share code';

  @override
  String get groupPlanShareSubject => 'WanderMood group plan';

  @override
  String groupPlanInviteShare(String code) {
    return 'Join my WanderMood day plan! Code: $code\n(Open WanderMood → Plan with a friend → Enter code)';
  }

  @override
  String get groupPlanJoinTitle => 'Join a friend';

  @override
  String get groupPlanJoinBody =>
      'Scan your friend\'s QR code together, or enter their code below.';

  @override
  String get groupPlanJoinCodeLabel => 'Join code';

  @override
  String get groupPlanJoinCodeHint => 'e.g. A1B2C3';

  @override
  String get groupPlanJoinButton => 'Join session';

  @override
  String get groupPlanJoinSnackEnterCode =>
      'Enter the code your friend shared.';

  @override
  String groupPlanJoinError(String error) {
    return 'Could not join: $error';
  }

  @override
  String get groupPlanShareQrTitle => 'Show this to your friend';

  @override
  String groupPlanShareQrOrCode(String code) {
    return 'or enter code $code';
  }

  @override
  String get groupPlanShareViaMessage => 'Share via message';

  @override
  String get groupPlanShareContinueLobby => 'Continue to lobby';

  @override
  String get groupPlanShareScreenTitle => 'Invite your friend';

  @override
  String get groupPlanJoinScanQr => 'Scan QR code';

  @override
  String get groupPlanJoinEnterInstead => 'Enter code instead';

  @override
  String get groupPlanJoinScanInstead => 'Scan QR code instead';

  @override
  String get groupPlanScanTitle => 'Scan QR code';

  @override
  String groupPlanCreateError(String error) {
    return 'Could not create session: $error';
  }

  @override
  String get groupPlanLobbyTitle => 'Group plan';

  @override
  String get groupPlanLobbyShareCode => 'Share this code';

  @override
  String groupPlanLobbyMoodsProgress(int locked, int total) {
    return '$locked / $total moods locked in';
  }

  @override
  String get groupPlanLobbyWaitingFriend => 'Waiting for your friend to join…';

  @override
  String get groupPlanLobbyWhosIn => 'Who’s in';

  @override
  String groupPlanLobbyMoodLine(String mood) {
    return 'Mood: $mood';
  }

  @override
  String get groupPlanLobbyStillChoosing => 'Still choosing…';

  @override
  String get groupPlanLobbyYourMood => 'Your mood today';

  @override
  String get groupPlanLobbyLockMood => 'Lock in my mood';

  @override
  String get groupPlanLobbyBuilding => 'Your shared plan is coming together.';

  @override
  String get groupPlanLobbyPlanFailed =>
      'Plan generation failed. Pull to refresh or try again in a moment.';

  @override
  String get groupPlanLobbyPickMoodSnack => 'Pick a mood first.';

  @override
  String groupPlanLobbySubmitError(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get groupPlanMoodAdventurous => 'Adventurous';

  @override
  String get groupPlanMoodRelaxed => 'Relaxed';

  @override
  String get groupPlanMoodSocial => 'Social';

  @override
  String get groupPlanMoodCultural => 'Cultural';

  @override
  String get groupPlanMoodRomantic => 'Romantic';

  @override
  String get groupPlanMoodEnergetic => 'Energetic';

  @override
  String get groupPlanMoodFoody => 'Foody';

  @override
  String get groupPlanMoodCreative => 'Creative';

  @override
  String get groupPlanResultTitle => 'Your shared plan';

  @override
  String get groupPlanResultNoPlan => 'No plan found yet.';

  @override
  String get groupPlanResultBackToApp => 'Back to app';

  @override
  String groupPlanResultMoodsLine(String moods) {
    return 'Moods: $moods';
  }

  @override
  String get groupPlanResultIdeasTitle => 'Ideas for today';

  @override
  String get groupPlanResultAddHint =>
      'Adds use the date selected on My Day (defaults to today). Open My Day first if you want another day.';

  @override
  String get groupPlanResultAddToMyDay => 'Add to My Day';

  @override
  String get groupPlanResultAdded => 'Added';

  @override
  String get groupPlanResultFooter =>
      'Each person adds stops to their own My Day. Same plan, two calendars.';

  @override
  String groupPlanResultAddedToast(String name) {
    return 'Added \"$name\" to My Day';
  }

  @override
  String get groupPlanResultDuplicateToast =>
      'Could not add (duplicate or same time slot). Try another idea.';

  @override
  String groupPlanResultAddFailedToast(String error) {
    return 'Add failed: $error';
  }

  @override
  String get groupPlanResultViewMyDay => 'View';

  @override
  String groupPlanInviteOpenLink(String url) {
    return 'Open in the app: $url';
  }

  @override
  String get groupPlanHubHeroTitle => 'Plan with friends';

  @override
  String get groupPlanHubHeroSubtitle =>
      'Two moods, one shared day. Moody figures out what works for both.';

  @override
  String get groupPlanHubStartCardTitle => 'Start a group plan';

  @override
  String get groupPlanHubStartCardSub => 'Get a code to share with your friend';

  @override
  String get groupPlanHubJoinCardTitle => 'Join a plan';

  @override
  String get groupPlanHubJoinCardSub => 'Enter a code from your friend';

  @override
  String get groupPlanHowItWorksTitle => 'How it works';

  @override
  String get groupPlanHowItWorksBody =>
      'You each pick your mood independently. I\'ll blend them into one plan you both love.';

  @override
  String get groupPlanCreateHeaderSubtitle => 'You + a friend';

  @override
  String get groupPlanCreateHeaderCaption =>
      'Pick your moods separately, get one shared plan';

  @override
  String get groupPlanSessionNameLabel => 'Session name (optional)';

  @override
  String get groupPlanSessionNamePlaceholder => 'e.g. Weekend in Amsterdam';

  @override
  String get groupPlanCreateCta => 'Create & share link';

  @override
  String get groupPlanCreateShareHint =>
      'Next you will see a QR code to show in person, or you can share a link by message.';

  @override
  String get groupPlanLobbyTitleWaitingFriend => 'Waiting for your friend…';

  @override
  String groupPlanLobbyTitleWaitingName(String name) {
    return 'Waiting for $name…';
  }

  @override
  String get groupPlanLobbyTitleEveryoneReady => 'Everyone\'s ready!';

  @override
  String get groupPlanLobbyShareCodeUpper => 'Share this code';

  @override
  String get groupPlanLobbyShareLinkCta => 'Share link';

  @override
  String get groupPlanLobbyStatusLocked => 'Locked';

  @override
  String get groupPlanLobbyStatusWaiting => 'Waiting';

  @override
  String get groupPlanMoodSectionUppercase => 'Your mood today';

  @override
  String get groupPlanLobbyLockCta => 'Lock in my mood';

  @override
  String groupPlanLobbyWaitingLockIn(String name) {
    return 'Waiting for $name to lock in…';
  }

  @override
  String get groupPlanLobbyGenerateCta => 'Generate our plan';

  @override
  String get groupPlanLobbyLockingIn => '🔒 Locking in…';

  @override
  String get groupPlanLobbyWaitingFriendJoin =>
      'Waiting for your friend to join…';

  @override
  String get groupPlanResultBlendKicker => 'Moody blended your moods ✨';

  @override
  String get groupPlanResultIdeasTitleEmoji => 'Ideas for today 💡';

  @override
  String get groupPlanResultLoadingMoody => 'Moody is building your plan… ✨';

  @override
  String get groupPlanResultFooterPhones =>
      'Each of you adds what you want to your own My Day — two phones, same plan 📱📱';

  @override
  String groupPlanResultMoodChipYou(String emoji, String mood) {
    return '$emoji $mood (you)';
  }

  @override
  String groupPlanResultMoodChipName(String emoji, String mood, String name) {
    return '$emoji $mood ($name)';
  }

  @override
  String get groupPlanYouShort => 'You';

  @override
  String get groupPlanMoodCozy => 'Cozy';

  @override
  String get groupPlanMoodSurprise => 'Surprise';

  @override
  String get moodMatchTitle => 'Mood Match';

  @override
  String get moodMatchNotificationTapAlreadySaved =>
      'This plan is already saved — here’s your summary.';

  @override
  String get moodMatchNotificationTapSessionEnded =>
      'This Mood Match is no longer available.';

  @override
  String get moodMatchNotificationTapOpenFailed =>
      'We couldn’t open that plan.';

  @override
  String get moodMatchNotificationTapStaleUpdate =>
      'Nothing new to do here — that plan may have changed.';

  @override
  String get moodMatchTagline => 'Two moods. One perfect day.';

  @override
  String get moodMatchTaglineHub =>
      'Two moods. One perfect day. Built for both of you.';

  @override
  String get moodMatchHubMoodyHeroLine1 =>
      'Two private mood picks, one shared day—built for both of you.';

  @override
  String get moodMatchHubMoodyHeroLine2 =>
      'Tap Start or Join when you’re ready.';

  @override
  String get moodMatchHubCardBodyPickYourMood =>
      'I still need your mood — I’ll keep it hush-hush until you’re both locked.';

  @override
  String moodMatchHubCardBodyDayTheirPick(String name) {
    return '$name floated a day — pop in and say yes or nudge a tweak.';
  }

  @override
  String moodMatchHubCardBodyDayWaitingOnThem(String name) {
    return 'I sent a day their way — waiting on $name to tap yes or counter.';
  }

  @override
  String get moodMatchHubCardCtaReviewDay => 'Review day';

  @override
  String get moodMatchHubCardCtaCheckProgress => 'Check progress';

  @override
  String get moodMatchStartBtn => 'Start a Mood Match';

  @override
  String get moodMatchStartBtnSub =>
      'Invite someone, pick moods, get a shared plan';

  @override
  String get moodMatchJoinBtn => 'Join a Mood Match';

  @override
  String get moodMatchJoinBtnSub => 'Enter a code or scan QR';

  @override
  String get moodMatchHubMoodyIntroFriendly =>
      'Okaaay, planning with someone else?\nThis is my favourite thing to do 😏';

  @override
  String get moodMatchHubMoodyIntroProfessional =>
      'Mood Match aligns two private mood picks into one shared day plan—clear, fair, and built for both of you.';

  @override
  String get moodMatchHubMoodyIntroEnergetic =>
      'Planning a day together?! I’m SO here for this—let’s make it unforgettable.';

  @override
  String get moodMatchHubMoodyIntroDirect =>
      'You each pick a mood on your own phone. I\'ll turn that into one shared plan. Start or join when you’re ready.';

  @override
  String get moodMatchHubMoodyIntroWaitingFriendly =>
      'You’re already in a Mood Match—your friend still needs to join. Open the plan to jump back in, or send a gentle nudge.';

  @override
  String get moodMatchHubMoodyIntroWaitingProfessional =>
      'You have an active Mood Match awaiting the other guest. Use Open plan to return to the lobby, or share a reminder.';

  @override
  String get moodMatchHubMoodyIntroWaitingEnergetic =>
      'We’re this close—your friend still has to hop in! Open the plan to keep the vibe going, or nudge them (they’ll love it).';

  @override
  String get moodMatchHubMoodyIntroWaitingDirect =>
      'Session in progress; friend not in yet. Open plan to continue or nudge.';

  @override
  String get moodMatchHubPendingTitle => 'Continue your plan 👀';

  @override
  String get moodMatchHubPendingStory => 'Your friend still has to hop in.';

  @override
  String moodMatchHubPendingCodeSmall(String code) {
    return 'Code $code';
  }

  @override
  String moodMatchHubPendingCode(String code) {
    return 'Code: $code';
  }

  @override
  String get moodMatchHubPendingWaiting => 'Waiting for your friend to join…';

  @override
  String get moodMatchHubPendingBuilding => 'I\'m building your shared plan…';

  @override
  String get moodMatchHubPendingMoodsStory =>
      'We\'re waiting for your match to lock in their mood.';

  @override
  String get moodMatchHubPendingResumeStory =>
      'Continue where you left off — your day and shared plan are next.';

  @override
  String get moodMatchHubContinueSession => 'Continue';

  @override
  String get moodMatchHubCancelSession => 'Cancel';

  @override
  String get moodMatchHubReadyTitle => 'Your Mood Match is ready!';

  @override
  String get moodMatchHubReadySubtitle =>
      'Your shared day’s ready — peek whenever you like.';

  @override
  String get moodMatchHubSeePlanCta => 'See the plan';

  @override
  String get moodMatchHubCardBadgeReady => 'Your plan is ready';

  @override
  String get moodMatchHubCardBadgeUpcoming => 'Upcoming plan';

  @override
  String moodMatchHubCardBadgeWaitingFor(String name) {
    return 'Waiting for $name…';
  }

  @override
  String get moodMatchHubCardStartsToday => 'Today\'s the day ✨';

  @override
  String get moodMatchHubCardStartsTomorrow => 'Starts tomorrow ✨';

  @override
  String moodMatchHubCardStartsInDays(int days) {
    return 'Starts in $days days ✨';
  }

  @override
  String moodMatchHubCardYouAndPartner(String name) {
    return 'You + $name 💕';
  }

  @override
  String get moodMatchHubCardDateToday => 'Today';

  @override
  String get moodMatchHubCardDateTomorrow => 'Tomorrow';

  @override
  String get moodMatchHubCardWaitingHeadline =>
      'Plan is waiting to be completed…';

  @override
  String get moodMatchHubCardInfoPickingMood => 'Picking a mood…';

  @override
  String get moodMatchHubCardInfoJoining => 'Waiting to join…';

  @override
  String get moodMatchHubCardInfoBuilding => 'Building your plan…';

  @override
  String get moodMatchHubCardInfoNextStep => 'Next: your day & plan';

  @override
  String get moodMatchHubStatusGenerating =>
      'I’m stitching your shared day together—almost there ✨';

  @override
  String get moodMatchHubStatusNeedGuest =>
      'Your match hasn’t joined yet—open the lobby or give them a gentle nudge.';

  @override
  String get moodMatchHubStatusNeedMood =>
      'We’re one mood away—waiting on them to lock theirs in 👀';

  @override
  String get moodMatchHubStatusNeedDay =>
      'Both moods are in—pick your day next and I’ll finish the plan.';

  @override
  String get moodMatchHubStatusPlanReady =>
      'Your shared day is ready—tap through whenever you feel like it.';

  @override
  String moodMatchHubStatusPlanUpcoming(String when) {
    return 'You’re on for $when—your plan’s warm and waiting.';
  }

  @override
  String get moodMatchHubUntitledSession => 'Mood Match';

  @override
  String get moodMatchCreateAlreadyWaiting =>
      'You already have a session waiting. Open it from the hub.';

  @override
  String moodMatchHubCancelError(String error) {
    return 'Could not cancel: $error';
  }

  @override
  String get moodMatchNewFeatureBadge => 'New feature';

  @override
  String moodMatchGoodMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String get moodMatchHowItWorksOneLiner =>
      'You each pick your mood privately; I\'ll blend them into one plan you both love.';

  @override
  String get moodMatchStepYourMood => 'Step 1 of 2 · Your mood';

  @override
  String get moodMatchFeelQuestionMorning =>
      'How are you feeling this morning?';

  @override
  String get moodMatchFeelQuestionAfternoon =>
      'How are you feeling this afternoon?';

  @override
  String get moodMatchFeelQuestionEvening =>
      'How are you feeling this evening?';

  @override
  String get moodMatchFeelQuestionLate => 'How are you feeling right now?';

  @override
  String moodMatchPrivateHint(String name) {
    return '$name won\'t see this until you both lock in';
  }

  @override
  String get moodMatchMoodyPickQuoteFriendly =>
      'Pick whatever\'s real. I\'ll make it work for both of you.';

  @override
  String get moodMatchMoodyPickQuoteProfessional =>
      'Choose the mood that best reflects you today. I will reconcile both selections into one coherent plan.';

  @override
  String get moodMatchMoodyPickQuoteEnergetic =>
      'Go with your gut—bold, soft, whatever! I’ll turn both picks into something you’ll both love.';

  @override
  String get moodMatchMoodyPickQuoteDirect =>
      'Select your mood. Your friend won’t see it until you both lock in.';

  @override
  String get moodMatchSelectMoodButton => 'Select your mood';

  @override
  String moodMatchLockBtn(String mood) {
    return 'Lock in $mood';
  }

  @override
  String get moodMatchLobbyEveryoneReadyTitle => 'Everyone\'s ready! 🎉';

  @override
  String get moodMatchLobbyEveryoneReadySubtitle =>
      'Blending both vibes into your shared plan…';

  @override
  String get moodMatchLobbyWaitingSubtitle =>
      'Hang tight — your match is almost ready.';

  @override
  String get moodMatchLobbyBuildingSubtitle =>
      'Finding places that fit both of you…';

  @override
  String moodMatchLobbyCommentaryWaiting(String name) {
    return 'Waiting for $name to figure out their vibe… 👀';
  }

  @override
  String moodMatchLobbyCommentaryFriendLocked(String name) {
    return '$name locked in! I\'m ready whenever you are 🎯';
  }

  @override
  String get moodMatchLobbyCommentaryBothLocked =>
      'Got both vibes. Building your match…';

  @override
  String moodMatchWhileYouWaitHint(String name) {
    return 'Moody will reveal your compatibility score when $name locks in';
  }

  @override
  String get moodMatchRevealScore => 'Vibe match today';

  @override
  String get moodMatchRevealCta => 'See our plan';

  @override
  String get moodMatchRevealCopyHighFriendly =>
      'You\'re basically the same person today 😌 \nThis plan built itself.';

  @override
  String get moodMatchRevealCopyHighProfessional =>
      'Your mood inputs align closely. The shared itinerary follows logically from both selections.';

  @override
  String get moodMatchRevealCopyHighEnergetic =>
      'Twin vibe energy today! 🔥 This plan basically assembled itself—you\'re going to love it.';

  @override
  String get moodMatchRevealCopyHighDirect =>
      'Very similar moods. The plan reflects both of you with minimal compromise.';

  @override
  String get moodMatchRevealCopyGoodFriendly =>
      'Different vibes, but I made it work. \nTrust me on this one.';

  @override
  String get moodMatchRevealCopyGoodProfessional =>
      'You chose different moods; I balanced both in one practical shared itinerary.';

  @override
  String get moodMatchRevealCopyGoodEnergetic =>
      'Different moods? I turned that into a win—this lineup still feels exciting for both of you!';

  @override
  String get moodMatchRevealCopyGoodDirect =>
      'Moods differed; the itinerary bridges both. Review the stops together.';

  @override
  String get moodMatchRevealCopyCreativeFriendly =>
      'Okay this was a challenge. But I actually love \nwhat I found. You will too.';

  @override
  String get moodMatchRevealCopyCreativeProfessional =>
      'Your moods diverged more than usual; I prioritized overlap you can both enjoy today.';

  @override
  String get moodMatchRevealCopyCreativeEnergetic =>
      'Spicy combo on paper—but I found gems that still feel fun together. Let\'s go!';

  @override
  String get moodMatchRevealCopyCreativeDirect =>
      'Low overlap between moods. The plan emphasizes neutral, crowd-pleasing picks.';

  @override
  String get moodMatchScoreLabelPerfect => 'Perfect match ✨';

  @override
  String get moodMatchScoreLabelGreat => 'Great combo';

  @override
  String get moodMatchScoreLabelGoodBalance => 'Good balance';

  @override
  String get moodMatchScoreLabelInteresting => 'Interesting mix';

  @override
  String get moodMatchScoreLabelCreative => 'Moody got creative';

  @override
  String moodMatchRevealMoodyFallback(String moodA, String moodB) {
    return 'Your $moodA and $moodB sides are a surprisingly good team — I\'m into it.';
  }

  @override
  String moodMatchResultCompatLine(int percent, String label) {
    return '$percent% match · $label';
  }

  @override
  String get moodMatchResultCompatGreat => 'Great combo ✓';

  @override
  String get moodMatchResultFooterStrip =>
      'You each add what you want to your own My Day';

  @override
  String get moodMatchLobbyChoosingBadge => 'Choosing';

  @override
  String get moodMatchLobbyReadyBadge => 'Ready';

  @override
  String get moodMatchSeePlanShareA11y => 'Share';

  @override
  String get moodMatchMoodTileSublabel => 'Tap to choose';

  @override
  String moodMatchBlendChip(String emoji, String label) {
    return '$emoji $label';
  }

  @override
  String get moodMatchWithFriendMenu => 'Mood Match';

  @override
  String moodMatchInviteShare(String code) {
    return 'Join my Mood Match on WanderMood! Code: $code';
  }

  @override
  String get moodMatchShareMoodyPrompt =>
      'Nice—your match probably has WanderMood already 💚 Tap Invite on WanderMood first and I will help you find them 👀 Link & QR are tucked below if you need them 📎✨';

  @override
  String get moodMatchShareFriendCodeIntro =>
      'Your match only needs this code if they open WanderMood without the link—it is for their phone, not yours.';

  @override
  String get moodMatchShareLinkQrFoldTitle => 'Need a link or QR instead?';

  @override
  String get moodMatchShareLinkQrFoldSubtitle =>
      'For other chats, or if they are not on WanderMood yet.';

  @override
  String get moodMatchShareBottomHint =>
      'Tip: notifications can alert you when they join. You can go to the lobby anytime.';

  @override
  String moodMatchPartnerJoinedNotifTitle(String name) {
    return '$name joined';
  }

  @override
  String get moodMatchPartnerJoinedNotifBody =>
      'Open your Mood Match lobby to keep going.';

  @override
  String get moodMatchPartnerJoinedNotifNameFallback => 'Someone';

  @override
  String get moodMatchInviteWanderMoodCta => 'Invite on WanderMood';

  @override
  String get moodMatchInviteTitle => 'Invite a WanderMood friend';

  @override
  String get moodMatchInviteSubtitle =>
      'Send your join link first — it works in any chat. Search a username here to nudge someone already on WanderMood (optional).';

  @override
  String get moodMatchInviteJoinLinkCardTitle => 'Your join link';

  @override
  String get moodMatchInviteJoinLinkCardSubtitle =>
      'Copy this https link and send it. It stays reliable if an in-app ping can’t be delivered.';

  @override
  String get moodMatchInviteCopyLinkAction => 'Copy link';

  @override
  String get moodMatchInviteLinkCopied => 'Join link copied';

  @override
  String get moodMatchInviteSearchHint => 'Username';

  @override
  String get moodMatchInviteSearchEmpty => 'Type at least 2 characters';

  @override
  String get moodMatchInviteNoResults => 'No profiles match that search';

  @override
  String get moodMatchInviteButton => 'Invite';

  @override
  String get moodMatchInviteSent => 'In-app invite sent';

  @override
  String get moodMatchInviteFailed =>
      'Couldn’t send the in-app invite (server). Copy your join link and send it in any chat—that always works.';

  @override
  String get moodMatchInviteNotDeliveredInApp =>
      'No in-app ping delivered — they may have in-app notifications off. Send your join link instead.';

  @override
  String get moodMatchInviteNotifTitle => 'Mood Match invite';

  @override
  String moodMatchInviteNotifMessage(String inviter, String code, String link) {
    return '$inviter invited you to Mood Match.\nCode: $code\n$link';
  }

  @override
  String get moodMatchInviteInboxTag => 'New Mood Match invite';

  @override
  String moodMatchInviteInboxBody(String name) {
    return '$name sent you a Mood Match. Pick your vibe (it stays yours until you’re both in), then we’ll line things up.';
  }

  @override
  String get moodMatchInviteInboxJoin => 'Join Mood Match';

  @override
  String get moodMatchInviteInboxJoining => 'Joining…';

  @override
  String get moodMatchInviteInboxDismiss => 'Not now';

  @override
  String get moodMatchInviteInboxJoinError =>
      'Couldn’t join right now. Try again in a moment.';

  @override
  String get moodMatchInvitedWaitingTag => 'INVITE SENT';

  @override
  String moodMatchInvitedWaitingBody(String name) {
    return 'Waiting for $name to open the app and join.';
  }

  @override
  String get moodMatchInvitedWaitingNudge => 'Nudge again';

  @override
  String get moodMatchShareShareLink => 'Share link';

  @override
  String get moodMatchShareCopyLink => 'Copy link';

  @override
  String get moodMatchShareWhatsApp => 'WhatsApp';

  @override
  String get moodMatchShareCopiedToast => 'Link copied';

  @override
  String get moodMatchFriendThey => 'your friend';

  @override
  String get moodMatchHubOpenPlan => 'Open plan';

  @override
  String get moodMatchHubNudgeFriend => 'Nudge friend';

  @override
  String get moodMatchHubOngoingTitle => 'Ongoing matches';

  @override
  String get moodMatchHubActiveMatchesTitle => 'Active matches';

  @override
  String get moodMatchHubCompletedMatchesTitle => 'Added to My Day';

  @override
  String get moodMatchHubPlanDraftingBadge => 'Finishing your picks';

  @override
  String moodMatchHubPlanDraftingBody(String name) {
    return 'Lock the stops you want, then send them to $name to review.';
  }

  @override
  String moodMatchHubOwnerWaitingGuestReviewBody(String name) {
    return 'You shared the plan — waiting on $name to review and confirm their picks.';
  }

  @override
  String get moodMatchHubGuestReviewBadge => 'Your turn';

  @override
  String moodMatchHubGuestReviewBody(String name) {
    return '$name sent the shared plan — tap in to review your picks.';
  }

  @override
  String get moodMatchHubCtaReviewPlan => 'Review plan';

  @override
  String get moodMatchHubCompletedBadge => 'On your day';

  @override
  String get moodMatchHubCompletedBody =>
      'This blend is already on your calendar.';

  @override
  String get moodMatchHubCompletedCta => 'Open My Day';

  @override
  String get moodMatchHubTabActive => 'Active';

  @override
  String get moodMatchHubTabCompleted => 'Completed';

  @override
  String get moodMatchHubTabActiveHint => 'Mood matches still being processed.';

  @override
  String get moodMatchHubTabCompletedHint => 'Plans you’ve added to My Day.';

  @override
  String get moodMatchHubTabActiveEmpty =>
      'No active matches here — start one or join a friend’s code.';

  @override
  String get moodMatchHubTabCompletedEmpty =>
      'Nothing saved yet — when you tap Add to My Day on a finished plan, it shows up here.';

  @override
  String get moodMatchHubInvitesTitle => 'PENDING INVITES';

  @override
  String moodMatchHubInvitesCollapsedHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invites waiting — tap to open',
      one: '1 invite waiting — tap to open',
    );
    return '$_temp0';
  }

  @override
  String get moodMatchHubConfirmDismissInviteTitle => 'Remove this invite?';

  @override
  String get moodMatchHubConfirmDismissInviteBody =>
      'You can still join later with the join code if your friend shares it again.';

  @override
  String get moodMatchHubConfirmLeaveSessionTitle => 'Remove this Mood Match?';

  @override
  String get moodMatchHubConfirmLeaveSessionBodyGuest =>
      'You\'ll leave this Mood Match. We\'ll let your friend know.';

  @override
  String get moodMatchHubConfirmLeaveSessionBodyHost =>
      'This removes the Mood Match for both of you. Your friend will be notified.';

  @override
  String get moodMatchHubConfirmRemoveAction => 'Remove';

  @override
  String get moodMatchHubLeaveSuccessGuestToast =>
      'You left the Mood Match. We let your friend know.';

  @override
  String get moodMatchHubLeaveSuccessHostToast =>
      'Mood Match removed. We let your friend know.';

  @override
  String moodMatchLobbyWaitTease0(String name) {
    return 'Waiting on $name… no pressure 👀';
  }

  @override
  String moodMatchLobbyWaitTease1(String name) {
    return 'Still nothing from $name… typical 😭';
  }

  @override
  String get moodMatchLobbyWaitTease2 =>
      'I have a whole plan ready. Just saying. 🌀';

  @override
  String moodMatchLobbyWaitTease3(String name) {
    return '$name is taking their time… worth it though, trust me';
  }

  @override
  String moodMatchLobbyFriendJoinedLine(String name) {
    return '$name just joined! 🎯 Now pick your mood.';
  }

  @override
  String get moodMatchLobbyBothLockedHold =>
      'Got both vibes. Give me a second… 🤔';

  @override
  String get moodMatchLockInVibeTitle => 'Lock in your vibe';

  @override
  String get moodMatchLockInVibeBtn => 'Lock my mood';

  @override
  String get moodMatchChangeMind => 'Change my mind';

  @override
  String moodMatchPrivacyNoteLockIn(String name) {
    return 'Your mood is only shared once $name locks in too.';
  }

  @override
  String get moodMatchMoodyReactionCurious =>
      'Ooh, curious energy! I like where this is going...';

  @override
  String get moodMatchMoodyReactionRomantic =>
      'Love is in the air... *fans self*';

  @override
  String get moodMatchMoodyReactionFoody =>
      'Oh! Someone\'s hungry. I\'ll find you something delicious.';

  @override
  String get moodMatchMoodyReactionRelaxed =>
      'Deep breath. We\'re finding you something chill.';

  @override
  String get moodMatchMoodyReactionEnergetic =>
      'Let\'s GO! High energy incoming... 🔥';

  @override
  String get moodMatchMoodyReactionCozy =>
      'Warm vibes detected. Bringing the comfort...';

  @override
  String get moodMatchMoodyReactionAdventurous =>
      'Adventure mode: activated! Hold on tight...';

  @override
  String get moodMatchMoodyReactionCultural =>
      'A taste for culture! I\'ve got just the thing.';

  @override
  String get moodMatchMoodyReactionSocial =>
      'Social butterfly! Let\'s find a buzzing spot.';

  @override
  String get moodMatchMoodyReactionExcited =>
      'The excitement is REAL. Let\'s make it happen!';

  @override
  String get moodMatchMoodyReactionHappy => 'Happy vibes are the best vibes 😄';

  @override
  String get moodMatchMoodyReactionSurprise =>
      'A surprise mood! My favorite kind.';

  @override
  String get moodMatchStatusMoodLocked => 'Mood locked ✓';

  @override
  String get moodMatchStatusPickingMood => 'Picking a mood...';

  @override
  String get moodMatchStatusLockedIn => 'Locked in';

  @override
  String get moodMatchBadgeLocked => 'Locked in';

  @override
  String moodMatchLiveUpdateOpened(String name) {
    return '$name just opened the app';
  }

  @override
  String moodMatchLiveUpdatePicking(String name) {
    return '$name is picking their mood...';
  }

  @override
  String moodMatchLiveUpdateLocked(String name) {
    return '$name locked in their mood!';
  }

  @override
  String get moodMatchWaitingBothBetter =>
      'Both moods in? Even better together.';

  @override
  String get moodMatchStepAlmostTag => 'Almost there';

  @override
  String moodMatchWaitingOnTitle(String name) {
    return 'Waiting on $name';
  }

  @override
  String moodMatchWaitingOnSub(String name) {
    return '$name is still choosing — privately. When they lock in, you both move on together.';
  }

  @override
  String get moodMatchWaitingTeaserTag => 'Locked in';

  @override
  String moodMatchWaitingTeaserTitle(String name) {
    return '$name picked their vibe';
  }

  @override
  String get moodMatchWaitingTeaserSub =>
      'Shhh — the actual mood stays a secret till the reveal.';

  @override
  String get moodMatchPlanBuildSub => 'Usually just a few seconds.';

  @override
  String get moodMatchMatchLoadingAppBar => 'Hang on';

  @override
  String get moodMatchPlanBuildButton => 'Building your plan…';

  @override
  String moodMatchWaitingPreviewHeadlineNamed(String name) {
    return '$name\'s turn';
  }

  @override
  String get moodMatchWaitingPreviewHeadlineGeneric => 'Your match\'s turn';

  @override
  String get moodMatchWaitingQuietHint =>
      'Shared ideas will show here once you\'ve picked a day together.';

  @override
  String get moodMatchRemoveSessionTitle => 'Remove this Mood Match?';

  @override
  String get moodMatchRemoveSessionBody =>
      'Your match will leave this session too. This can\'t be undone.';

  @override
  String get moodMatchRemoveSessionConfirm => 'Remove';

  @override
  String get moodMatchRemoveSessionCancel => 'Keep it';

  @override
  String moodMatchOwnerWaitingConfirmTitle(String name) {
    return 'Waiting on $name to confirm';
  }

  @override
  String get moodMatchOwnerWaitingConfirmSub =>
      'They\'ll get a ping to confirm the day + time you suggested. You\'ll both land back on your shared plan when it\'s set.';

  @override
  String moodMatchGuestConfirmTitleWithTime(String day, String time) {
    return '$day · $time';
  }

  @override
  String moodMatchGuestConfirmBody(String name, String day, String time) {
    return '$name picked $day around $time. Works for you?';
  }

  @override
  String get moodMatchGuestCounterCta => 'Suggest a different moment';

  @override
  String get moodMatchGuestCounterTitle => 'Pick a moment that works';

  @override
  String moodMatchGuestCounterSub(String name) {
    return '$name can accept or suggest another moment before you both go back to your shared plan.';
  }

  @override
  String get moodMatchGuestCounterSendCta => 'Send back';

  @override
  String moodMatchOwnerCounterTitle(String name, String day, String time) {
    return '$name suggested $day · $time';
  }

  @override
  String get moodMatchOwnerCounterBody =>
      'Your match suggested a different moment. Accept it, or propose another day and time.';

  @override
  String moodMatchOwnerCounterAccept(String day) {
    return 'Accept $day';
  }

  @override
  String get moodMatchOwnerCounterKeep => 'Keep my pick';

  @override
  String get moodMatchOwnerCounterSuggestAnother => 'Suggest another time →';

  @override
  String moodMatchWaitingGuestReviewPlan(String name) {
    return 'Waiting for $name to review…';
  }

  @override
  String moodMatchPlanSentToGuestBanner(String name) {
    return 'Sent to $name';
  }

  @override
  String get moodMatchPlanV2SelectAllThreeToContinue =>
      'Select all 3 to continue';

  @override
  String get moodMatchSaving => 'Saving…';

  @override
  String get moodMatchDayPickerStep => 'Step 1 of 2 — you decide';

  @override
  String get moodMatchDayPickerStepGuest => 'Step 1 of 2 — your match picks';

  @override
  String get moodMatchDayPickerTitle => 'Which day works for you both?';

  @override
  String moodMatchDayPickerSubtitle(String name) {
    return 'You choose — $name gets to confirm.';
  }

  @override
  String get moodMatchDayPickerToday => 'Today';

  @override
  String moodMatchDayPickerNote(String name) {
    return '$name will get a nudge to confirm.';
  }

  @override
  String moodMatchDayPickerPreview(String ownerName, String day) {
    return '$ownerName suggested $day';
  }

  @override
  String get moodMatchDayPickerCta => 'Continue — see your match →';

  @override
  String get moodMatchDayPickerOpenSheetCta => 'Choose day & time';

  @override
  String get moodMatchDayPickerSheetChangeCta => 'Change day or time';

  @override
  String get moodMatchDayPickerWholeDay => 'Whole day';

  @override
  String moodMatchPlanResultMoodyV1(String name) {
    return 'Here\'s your day with $name — three picks we think fit both your vibes.';
  }

  @override
  String moodMatchPlanResultMoodyV2(String name) {
    return 'Built around what you both wanted today. Tap any spot to peek inside before you confirm with $name.';
  }

  @override
  String moodMatchPlanResultMoodyV3(String name) {
    return 'Try them in order, or shuffle — your call. $name sees the same plan from their side.';
  }

  @override
  String moodMatchPlanResultMoodyV4(String name) {
    return 'Three small moments shaped around your moods. Anything off? Hit Swap and we\'ll find another option.';
  }

  @override
  String get moodMatchDayPickerSheetTitle => 'Pick a date for both of you';

  @override
  String moodMatchDayPickerSheetMoodyLine(String name) {
    return 'No rush — $name will confirm your pick.';
  }

  @override
  String get moodMatchDayPickerSheetDone => 'Lock it in →';

  @override
  String get moodMatchDayPickerTimeHint =>
      'We’ll use this after your plan is ready. Your match still picks their own slot.';

  @override
  String get moodMatchDayNotifyMaybeFailed =>
      'Couldn’t notify your match in time — ask them to open the app to confirm the day.';

  @override
  String moodMatchGuestWaitingDay(String name) {
    return '$name is picking a day for you both...';
  }

  @override
  String moodMatchGuestConfirmDay(String day) {
    return 'Works for $day?';
  }

  @override
  String get moodMatchGuestConfirmYes => 'Works for me ✓';

  @override
  String get moodMatchGuestConfirmNo => 'Suggest another day';

  @override
  String get moodMatchTimePickerStep => 'Step 2 of 2 — just for you';

  @override
  String get moodMatchTimePickerTitle => 'When do YOU want to start?';

  @override
  String moodMatchTimePickerSubtitle(String day, String name) {
    return '$day · $name picks their own slot too';
  }

  @override
  String get moodMatchTimePickerMorning => 'Morning';

  @override
  String get moodMatchTimePickerAfternoon => 'Afternoon';

  @override
  String get moodMatchTimePickerEvening => 'Evening';

  @override
  String get moodMatchTimePickerMorningNote =>
      'Start fresh and beat the crowds.';

  @override
  String get moodMatchTimePickerAfternoonNote =>
      'Midday energy — perfect for most spots.';

  @override
  String get moodMatchTimePickerEveningNote => 'Golden hour vibes all the way.';

  @override
  String moodMatchTimePickerWithBadge(String name) {
    return 'You and $name are planning this together';
  }

  @override
  String get moodMatchTimePickerCta => 'Add to My Day';

  @override
  String moodMatchTimePickerOtherNote(String name) {
    return '$name will pick their own slot separately';
  }

  @override
  String get moodMatchResultTag => 'MATCH RESULT';

  @override
  String get moodMatchResultCompatibility => 'Compatibility';

  @override
  String get moodMatchFriendYou => 'You';

  @override
  String get moodMatchReactionLoveIt => 'Love it';

  @override
  String get moodMatchReactionSkip => 'Skip';

  @override
  String get moodMatchReactionSwap => 'Swap';

  @override
  String get moodMatchConflictBadge => 'Conflict';

  @override
  String moodMatchConflictBanner(String name, String place) {
    return '$name proposed $place instead';
  }

  @override
  String get moodMatchConflictKeep => 'Keep original';

  @override
  String moodMatchConflictAccept(String name) {
    return 'Accept $name\'s pick';
  }

  @override
  String get moodMatchPlanSortedCta => 'Plan sorted → Choose start time';

  @override
  String get moodMatchPlanHeroLabel => 'Start your morning here';

  @override
  String get moodMatchPlanMoreIdeas => 'More ideas';

  @override
  String moodMatchPlanMoreIdeasCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more ideas',
      one: '1 more idea',
    );
    return '$_temp0';
  }

  @override
  String get moodMatchPlanSwapHint =>
      'Swapped picks come from your match\'s other ideas.';

  @override
  String get moodMatchConfirmTitle => 'Added to your day';

  @override
  String moodMatchConfirmSubtitle(String day, String slot) {
    return '$day · $slot start';
  }

  @override
  String moodMatchConfirmOtherNote(String name) {
    return '$name gets a nudge to pick their slot.';
  }

  @override
  String moodMatchConfirmOtherStatus(String name) {
    return '$name — Notified, picking their start time';
  }

  @override
  String get moodMatchConfirmViewMyDay => 'View My Day';

  @override
  String moodMatchInMyDaySuccess(String date) {
    return 'Your plan for $date is in My Day.';
  }

  @override
  String get moodMatchInMyDaySuccessShort => 'Your plan is in My Day.';

  @override
  String get moodMatchConfirmBackToPlan => '← Back to plan';

  @override
  String moodMatchWithBadge(String name) {
    return 'With $name';
  }

  @override
  String moodMatchPlanV2GuestMoody(String name) {
    return '$name picked these for you both. Say what works.';
  }

  @override
  String moodMatchPlanV2ContextYouPickedDay(String day) {
    return '📅 $day · You picked the day';
  }

  @override
  String moodMatchPlanV2ContextOwnerPickedDay(String day, String name) {
    return '📅 $day · $name picked the day';
  }

  @override
  String moodMatchPlanV2ContextPlannedDay(String day) {
    return '📅 $day · Planned day';
  }

  @override
  String get moodMatchPlanV2ImIn => 'I\'m in ✓';

  @override
  String get moodMatchPlanV2SwapThis => 'Swap this';

  @override
  String get moodMatchPlanV2YouConfirmed => 'You confirmed ✓';

  @override
  String get moodMatchPlanV2WaitingForYou => 'Waiting for you';

  @override
  String get moodMatchPlanV2ConfirmBeforeSend =>
      'Confirm or swap before sending';

  @override
  String moodMatchPlanV2ConfirmedByYou(String name) {
    return 'Confirmed by you · $name hasn\'t seen it yet';
  }

  @override
  String moodMatchPlanV2SendToGuest(String name) {
    return 'Send to $name →';
  }

  @override
  String moodMatchPlanV2ConfirmAllToSend(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Confirm all $count spots to send to $name',
      one: 'Confirm your pick to send to $name',
    );
    return '$_temp0';
  }

  @override
  String moodMatchPlanV2GuestWaitingShare(String name) {
    return 'Waiting for $name to share the plan';
  }

  @override
  String get moodMatchPlanV2WorksForMe => 'Works for me ✓';

  @override
  String get moodMatchPlanV2NotForMe => 'Not for me';

  @override
  String get moodMatchPlanV2BothIn => 'Both in ✓';

  @override
  String get moodMatchPlanV2YourTurn => 'Your turn';

  @override
  String get moodMatchPlanV2SwapRequested => 'Swap requested';

  @override
  String moodMatchPlanV2OwnerInYourCall(String name) {
    return '$name is in · your call';
  }

  @override
  String moodMatchPlanV2YouBothIn(String name) {
    return 'You and $name are both in';
  }

  @override
  String moodMatchPlanV2SlotNotInThisPlan(String partLabel) {
    return '$partLabel isn\'t in this Mood Match — you only planned one part of the day together.';
  }

  @override
  String get moodMatchPlanV2YouBothInThisMoment =>
      'You\'re both in for this moment ✓';

  @override
  String moodMatchPlanV2WaitingOwnerSwap(String name) {
    return 'Waiting for $name on the swap…';
  }

  @override
  String moodMatchPlanV2ConfirmAllGuest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Confirm all $count picks to finish',
      one: 'Confirm your pick to finish',
    );
    return '$_temp0';
  }

  @override
  String moodMatchPlanV2StopsReviewed(int done, int total) {
    return '$done of $total';
  }

  @override
  String moodMatchPlanV2FooterGuestReviewNudge(int done, int total) {
    return '$done/$total · confirm each tab above';
  }

  @override
  String moodMatchPlanV2OwnerPickEachPart(int done, int total) {
    return '$done of $total selected — pick the rest above';
  }

  @override
  String get moodMatchPlanV2UndoMyChoice => 'Change my answer';

  @override
  String get moodMatchPlanV2PlanConfirmedTime =>
      'Plan confirmed — pick your start time →';

  @override
  String get moodMatchPlanV2OpenMyDay => 'Add to My Plans ✓';

  @override
  String get moodMatchRevealMaeMorning => 'MORNING';

  @override
  String get moodMatchRevealMaeAfternoon => 'AFTERNOON';

  @override
  String get moodMatchRevealMaeEvening => 'EVENING';

  @override
  String moodMatchPlanV2SwapSheetTitle(String slot) {
    return 'Pick something else for $slot';
  }

  @override
  String get moodMatchPlanV2SwapSheetMoody =>
      'Here are some other options to try.';

  @override
  String get moodMatchPlanV2PickThis => 'Pick this';

  @override
  String get moodMatchPlanV2YourPickSaved => 'Your pick';

  @override
  String moodMatchPlanV2SwapBannerTitle(String name, String slot) {
    return '$name wants to swap the $slot';
  }

  @override
  String moodMatchPlanV2SwapBannerSubtitle(String proposed, String original) {
    return 'They suggested $proposed instead of $original';
  }

  @override
  String moodMatchPlanV2KeepOriginal(String name) {
    return 'Keep $name';
  }

  @override
  String moodMatchPlanV2AcceptSwap(String name) {
    return 'Accept $name';
  }

  @override
  String moodMatchPlanV2SentToGuest(String name) {
    return 'Plan sent to $name';
  }

  @override
  String moodMatchPlanV2GuestSuggestedSwap(String name, String proposed) {
    return '$name suggested: $proposed instead';
  }

  @override
  String get moodMatchPlanV2ActuallyKeep => 'Actually keep it';

  @override
  String moodMatchPlanV2WaitingForOwnerEllipsis(String name) {
    return 'Waiting for $name…';
  }

  @override
  String moodMatchPlanV2WaitingGuestApproveSwap(String name) {
    return 'Waiting for $name to OK your suggestion for this slot.';
  }

  @override
  String moodMatchPlanV2OwnerSuggestedDifferentPlace(
      String name, String proposed) {
    return '$name wants to swap this for $proposed.';
  }

  @override
  String get moodMatchPlanV2UseOwnersPick => 'Use their pick';

  @override
  String get moodMatchPlanV2KeepCurrentPlace => 'Keep this place';

  @override
  String get moodMatchPlanV2WithdrawSwap => 'Withdraw suggestion';

  @override
  String get moodMatchPlanV2RespondSwapsOnCards =>
      'Respond to swap suggestions on the cards';

  @override
  String get moodMatchPlanV2SuggestDifferentPlace => 'Suggest a change';

  @override
  String moodMatchPlanV2YourSwapPendingOwner(String proposed, String name) {
    return 'You suggested $proposed. Waiting for $name to respond.';
  }

  @override
  String moodMatchToastPlanShared(String name) {
    return '$name shared the Mood Match plan with you.';
  }

  @override
  String moodMatchToastSwapRequested(String name, String place) {
    return '$name suggested a different place: $place.';
  }

  @override
  String moodMatchToastSwapAccepted(String name) {
    return '$name accepted the swap.';
  }

  @override
  String moodMatchToastSwapDeclined(String name, String slot) {
    return '$name declined the swap for $slot.';
  }

  @override
  String moodMatchToastPartnerConfirmedSlot(String name, String slot) {
    return '$name confirmed a slot ($slot).';
  }

  @override
  String moodMatchToastGuestDeclinedOriginalDay(String name) {
    return '$name is not available for the day you proposed.';
  }

  @override
  String moodMatchToastGuestProposedNewDay(String name) {
    return '$name suggested a different date — open the Mood Match day step.';
  }

  @override
  String moodMatchSaveMyDayFailed(String details) {
    return 'Could not add to My Plans: $details';
  }

  @override
  String moodMatchPlanV2BasedOnMoods(String moods) {
    return 'Based on moods: $moods';
  }

  @override
  String moodMatchPlanV2ActivityMood(String mood) {
    return 'Mood: $mood';
  }

  @override
  String get moodMatchHubBrandTag => 'Mood Match';

  @override
  String get moodMatchHubEmptySub =>
      'Pick a friend. Two moods → one shared day.';

  @override
  String get moodMatchHubCtaStart => 'Start Mood Match';

  @override
  String get moodMatchHubCtaResume => 'Resume Mood Match';

  @override
  String get moodMatchHubCtaOpenShared => 'Open shared plan';

  @override
  String get moodMatchHubCtaReviewShared => 'Review plan';

  @override
  String moodMatchHubSubWaitingJoin(String name) {
    return 'Waiting on $name to join';
  }

  @override
  String get moodMatchHubSubWaitingJoinNoName =>
      'Waiting on your friend to join';

  @override
  String moodMatchHubSubWaitingMood(String name) {
    return 'Waiting on $name\'s mood';
  }

  @override
  String get moodMatchHubSubWaitingMoodNoName => 'Waiting on their mood';

  @override
  String moodMatchHubSubDayProposed(String name) {
    return '$name suggested a day — review';
  }

  @override
  String get moodMatchHubSubDayProposedNoName => 'A day was suggested — review';

  @override
  String moodMatchHubSubBuildingWith(String name) {
    return 'Building your shared day with $name…';
  }

  @override
  String get moodMatchHubSubBuilding => 'Building your shared day…';

  @override
  String moodMatchHubSubReadyWith(String name) {
    return 'Your shared day with $name is ready.';
  }

  @override
  String get moodMatchHubSubReady => 'Your shared day is ready.';

  @override
  String moodMatchHubMoreSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count more Mood Matches',
      one: '+1 more Mood Match',
    );
    return '$_temp0';
  }

  @override
  String get moodyHubActionFindCoffee => 'Find coffee';

  @override
  String get moodyHubActionGetMeActive => 'Get me active';

  @override
  String get moodyHubActionContinueDay => 'Continue day';

  @override
  String get moodyHubActionReplaceActivity => 'Replace activity';

  @override
  String get moodyHubMoodMatchViewMatches => 'View matches';

  @override
  String get moodyHubIntroHeroEmpty =>
      'Hey, your day is still open. Want me to plan something, or just chat for a bit?';

  @override
  String get moodyHubIntroHeroActive =>
      'Your day\'s already rolling. I\'m here if you want to tweak it or just chat.';

  @override
  String get moodyHubIntroHeroSharedReady =>
      'Your shared plan is ready at the top. Want to open it, or keep chatting?';

  @override
  String get moodyHubHeroBodyEmptyFriendly =>
      'Hey, your day is still open. What are you in the mood for? 🤔';

  @override
  String get moodyHubHeroBodyEmptyFriendly2 =>
      'Nothing planned yet — and that\'s exciting! What do you feel like doing today? ✨';

  @override
  String get moodyHubHeroBodyEmptyFriendly3 =>
      'Blank canvas today. We could go anywhere with this! What\'s calling you? 🎨';

  @override
  String get moodyHubHeroBodyEmptyFriendly4 =>
      'Your day is wide open. Want me to build something around your mood? 🪄';

  @override
  String get moodyHubHeroBodyEmptyProfessional =>
      'Your schedule is open. I can outline a clear, focused day plan—or we can keep this concise and practical. 📋';

  @override
  String get moodyHubHeroBodyEmptyProfessional2 =>
      'Nothing locked in yet. Tell me your priorities and I\'ll structure the day. 🎯';

  @override
  String get moodyHubHeroBodyEmptyProfessional3 =>
      'Open day ahead. Where do you want to focus your energy? ⚡';

  @override
  String get moodyHubHeroBodyEmptyProfessional4 =>
      'Your calendar is clear. Ready to put together a sharp plan when you are. 📅';

  @override
  String get moodyHubHeroBodyEmptyEnergetic =>
      'Okay let\'s GO! 🚀 Your day is wide open and anything is possible right now!';

  @override
  String get moodyHubHeroBodyEmptyEnergetic2 =>
      'Nothing on the agenda yet — honestly? Perfect. Let\'s make it legendary! 🌟';

  @override
  String get moodyHubHeroBodyEmptyEnergetic3 =>
      'Fresh start, full energy, zero plans. That\'s literally my favourite combo! What are we doing? ⚡';

  @override
  String get moodyHubHeroBodyEmptyEnergetic4 =>
      'The day is yours and it\'s still untouched. Tell me what you\'re feeling and let\'s build something real! 🔥';

  @override
  String get moodyHubHeroBodyEmptyDirect =>
      'Your day is open. Plan something, or chat—your call. 📍';

  @override
  String get moodyHubHeroBodyEmptyDirect2 =>
      'Nothing scheduled. What do you want to do? 🗺️';

  @override
  String get moodyHubHeroBodyEmptyDirect3 =>
      'Open day. I can plan it or you can — just say the word. ✌️';

  @override
  String get moodyHubHeroBodyEmptyDirect4 =>
      'No plans yet. Drop a mood or an idea and we move. 🚀';

  @override
  String get moodyHubHeroBodyActiveFriendly =>
      'Your day is already rolling! I\'m here if you want to add something or just talk. 🎈';

  @override
  String get moodyHubHeroBodyActiveFriendly2 =>
      'You\'ve got things lined up — love that for you. Need anything tweaked? 🛠️';

  @override
  String get moodyHubHeroBodyActiveFriendly3 =>
      'Day\'s in motion. Want to add a little something extra, or just check in? 💫';

  @override
  String get moodyHubHeroBodyActiveFriendly4 =>
      'Looking good on the plan front! Let me know if anything needs adjusting. ✨';

  @override
  String get moodyHubHeroBodyActiveProfessional =>
      'Your day is underway. I can help refine timing or priorities—or keep this brief. ⏱️';

  @override
  String get moodyHubHeroBodyActiveProfessional2 =>
      'Schedule is set. Let me know if you want to optimise anything. 📈';

  @override
  String get moodyHubHeroBodyActiveProfessional3 =>
      'You have a plan in place. I\'m available if adjustments come up. 🔄';

  @override
  String get moodyHubHeroBodyActiveProfessional4 =>
      'Day is structured. Ready to adapt if needed. 📋';

  @override
  String get moodyHubHeroBodyActiveEnergetic =>
      'You\'re already moving — let\'s keep that momentum going! Anything to add? 🔥';

  @override
  String get moodyHubHeroBodyActiveEnergetic2 =>
      'Look at you with a plan! Want to level it up or just vibe with what you have? 🚀';

  @override
  String get moodyHubHeroBodyActiveEnergetic3 =>
      'Day is set and you\'re ready — I love the energy! Tweak anything or just crush it? 💥';

  @override
  String get moodyHubHeroBodyActiveEnergetic4 =>
      'You\'ve got something going already! Want to stack on more or just ride the wave? 🌊';

  @override
  String get moodyHubHeroBodyActiveDirect =>
      'Day\'s in motion. Tweak something, or chat. 📍';

  @override
  String get moodyHubHeroBodyActiveDirect2 =>
      'Plan\'s set. Need anything changed? 🔄';

  @override
  String get moodyHubHeroBodyActiveDirect3 =>
      'You\'ve got a day. Add something or leave it. ✌️';

  @override
  String get moodyHubHeroBodyActiveDirect4 =>
      'Moving already. I\'m here if it needs a change. ⚡';

  @override
  String get moodyHubHeroBodySharedReadyFriendly =>
      'Your shared plan is waiting — open it and let\'s make the day official! 🎉';

  @override
  String get moodyHubHeroBodySharedReadyProfessional =>
      'Your shared plan is ready. Open it when you\'re ready, or continue our conversation here. 📋';

  @override
  String get moodyHubHeroBodySharedReadyEnergetic =>
      'The collab plan is ready — open it right now because this one is going to be so good! 🔥';

  @override
  String get moodyHubHeroBodySharedReadyDirect =>
      'Shared plan is ready. Open it, or stay here. 📍';

  @override
  String get moodyHubHeroBodySharedReadyDayEmptyFriendly =>
      'You and your friend have a shared plan ready — open it to add everything to your day! ✨';

  @override
  String get moodyHubHeroBodySharedReadyDayEmptyProfessional =>
      'A collaborative plan is ready in Mood Match. Open it to add activities to your day, or continue our conversation here. 🤝';

  @override
  String get moodyHubHeroBodySharedReadyDayEmptyEnergetic =>
      'The Mood Match plan is ready and it\'s good — open it and load your day! 🚀';

  @override
  String get moodyHubHeroBodySharedReadyDayEmptyDirect =>
      'Shared plan in Mood Match. Open it to add to your day, or stay here. 📍';

  @override
  String get moodyHubHeroBodyInviteFriendly =>
      'Your last Mood Match is already on your plan. Ready to do it again with someone? 👯‍♀️';

  @override
  String get moodyHubHeroBodyInviteFriendly2 =>
      'That Mood Match was a moment! Who are you feeling like exploring with next? 🗺️';

  @override
  String get moodyHubHeroBodyInviteFriendly3 =>
      'Last plan is locked in. Want to set up a new Mood Match with a friend? ✌️';

  @override
  String get moodyHubHeroBodyInviteFriendly4 =>
      'Your shared day is on your plan. Another one? Tell me who you want to go out with. 💫';

  @override
  String get moodyHubHeroBodyInviteProfessional =>
      'Your previous Mood Match is on your schedule. When you\'re ready, start a new match to plan another day together. 🤝';

  @override
  String get moodyHubHeroBodyInviteProfessional2 =>
      'Last collaborative plan is confirmed. Initiate a new Mood Match when it suits you. 📅';

  @override
  String get moodyHubHeroBodyInviteProfessional3 =>
      'Previous session is complete. Ready to schedule the next collaborative day? 🗓️';

  @override
  String get moodyHubHeroBodyInviteProfessional4 =>
      'Your shared plan is in the books. Start a new match to plan ahead. 📋';

  @override
  String get moodyHubHeroBodyInviteEnergetic =>
      'That Mood Match is on your plan and I love it! Who\'s next? Let\'s match again! 🔥';

  @override
  String get moodyHubHeroBodyInviteEnergetic2 =>
      'You did a Mood Match and it\'s on your plan — okay iconic! Who are we dragging into the next one? 🚀';

  @override
  String get moodyHubHeroBodyInviteEnergetic3 =>
      'Last match: done. Next match: waiting for you! Let\'s go again! ⚡';

  @override
  String get moodyHubHeroBodyInviteEnergetic4 =>
      'Your shared day is locked in — love that! Ready to plan another one? I\'ll make it even better. 🌟';

  @override
  String get moodyHubHeroBodyInviteDirect =>
      'Last Mood Match is on your plan. Start a new one when you want. 📍';

  @override
  String get moodyHubHeroBodyInviteDirect2 =>
      'Done with last match. Start the next one. ✌️';

  @override
  String get moodyHubHeroBodyInviteDirect3 =>
      'Plan saved. New Mood Match when you\'re ready. 🔄';

  @override
  String get moodyHubHeroBodyInviteDirect4 =>
      'Last one\'s on your plan. Match again? 🤝';

  @override
  String get moodyHubMoodMatchInviteCta => 'Start a Mood Match';

  @override
  String get moodyHubInviteCardBody =>
      'Match with a friend and plan a day together—coffee, a walk, date, whatever fits you both. 👯‍♀️🗺️';

  @override
  String get moodyHubPlanYourDayCardTitle => 'Plan your day';

  @override
  String get moodyHubPlanYourDayCardBody =>
      'Tell me your mood and I’ll build a full solo day—places, timing, and vibes that fit just you. ✨🧳';

  @override
  String get moodyHubContinueDayCardTitle => 'Continue your day';

  @override
  String get moodyHubContinueDayCardBody =>
      'You’ve got things on your timeline. Jump back to My Day or chat with me to tweak the flow. 🔄';

  @override
  String get moodyHubChangeMoodCardTitle => 'Change mood';

  @override
  String get moodyHubChangeMoodCardBody =>
      'Pick a new vibe and I’ll tweak how your day feels—places, pace, and energy that match you. ✨🎨';

  @override
  String get moodyHubCollapsedActionsTitle => 'Moody Hub';

  @override
  String get moodyHubCollapsedActionsSubtitle =>
      'Plan your day, Mood Match, and more.';

  @override
  String get moodMatchAlreadyOnYourPlan => 'Already on your plan';

  @override
  String get weatherModalNow => 'Now';

  @override
  String get weatherModalTipTitle => 'My tip for today';

  @override
  String get weatherModalTipRain =>
      'Rain is expected today. Bring an umbrella and consider an indoor activity.';

  @override
  String get weatherModalTipSunnyHighUv =>
      'It is sunny and UV is high today. Use sunscreen, bring water, and plan a few shade breaks.';

  @override
  String get weatherModalTipSunny =>
      'Mild and dry weather today. Great for a walk or a terrace stop.';

  @override
  String get weatherModalTipCloudy =>
      'Cloudy and likely cooler. Bring one extra layer to stay comfortable.';

  @override
  String get weatherModalTipDefault =>
      'Conditions may change today. Dress in layers and check the forecast again later.';
}
