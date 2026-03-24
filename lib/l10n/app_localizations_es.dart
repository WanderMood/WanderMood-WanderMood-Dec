// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'WanderMood';

  @override
  String get splashTagline => 'Tu compañero de viaje según tu estado de ánimo';

  @override
  String get welcome => 'Bienvenido';

  @override
  String get hello => 'Hola';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String get heyNightOwl => 'Hola búho nocturno';

  @override
  String get readyToCreateYourFirstDay =>
      '¿Listo para crear tu primer día increíble?';

  @override
  String get createMyFirstDay => 'Crear mi primer día';

  @override
  String get myDayHeaderMorning =>
      '¡Buenos días! Vamos a hacer que hoy valga la pena.';

  @override
  String get myDayHeaderAfternoon =>
      '¡Buenas tardes! Tu día todavía promete mucho.';

  @override
  String get myDayHeaderEvening =>
      '¡Buenas noches! Veamos qué más puede ser este día.';

  @override
  String get myDayNoPlanHeaderSubtitle =>
      'Aún no hay planes. Tu día sigue abierto.';

  @override
  String get myDayEmptyGreetingMorningBody =>
      'Te espera un día fresco lleno de posibilidades.';

  @override
  String get myDayEmptyGreetingAfternoonBody =>
      'Todavía hay tiempo para convertir hoy en algo memorable.';

  @override
  String get myDayEmptyGreetingEveningBody =>
      'La noche sigue abierta. Planea algo especial o tómatelo con calma.';

  @override
  String get myDayEmptyPlanTitle => '¿Listo para planear tu día?';

  @override
  String get myDayEmptyPlanSubtitle =>
      'Crea un plan para tu día y empieza a descubrir lugares que encajen con tu ánimo, tu tiempo y tu energía.';

  @override
  String get myDayEmptyCreateButton => 'Crear Mi Día';

  @override
  String get myDayEmptyBrowseButton => 'Ver actividades';

  @override
  String get myDayEmptyAskMoodyButton => 'Preguntar a Moody';

  @override
  String get myDayQuickAddActivity => 'Añadir actividad';

  @override
  String get moodyFeedbackPromptBody =>
      '¿Cómo va? Toca para contarme cómo te sientes.';

  @override
  String get moodyFeedbackShareAction => 'Compartir comentarios';

  @override
  String get myDayEmptyInspiredTitle => 'Inspírate';

  @override
  String get myDayInspiredCafesTitle => 'Descubrir cafés';

  @override
  String get myDayInspiredCafesSubtitle =>
      'Encuentra sitios acogedores para relajarte';

  @override
  String get myDayInspiredTrendingTitle => 'Lugares en tendencia';

  @override
  String get myDayInspiredTrendingSubtitle => 'Sitios populares esta semana';

  @override
  String get myDayInspiredHiddenGemsTitle => 'Joyas ocultas';

  @override
  String get myDayInspiredHiddenGemsSubtitle => 'Favoritos locales cerca de ti';

  @override
  String get skipForNow => 'Omitir por ahora';

  @override
  String moodyIntroGreeting(String name) {
    return '¡Hola $name! 👋';
  }

  @override
  String get moodyIntroImMoody => 'Soy Moody.';

  @override
  String get moodyIntroSubtext =>
      'Estoy aquí para ayudarte a planear días que encajen con tu estado de ánimo, energía y vibe.';

  @override
  String get moodyIntroSuggestActivities => 'Sugeriré actividades como:';

  @override
  String get moodyIntroTakesLessThan =>
      'Menos de un minuto • Usa tus preferencias';

  @override
  String get moodyIntroNameFallback => 'ahí';

  @override
  String get moodyIntroActLocalRestaurant => 'Descubrir restaurante local';

  @override
  String get moodyIntroActMuseum => 'Visita a museo o galería';

  @override
  String get moodyIntroActLocalMarket => 'Explorar mercado local';

  @override
  String get moodyIntroActNature => 'Paseo por la naturaleza o parque';

  @override
  String get moodyIntroActNightlife => 'Bar o lounge por la noche';

  @override
  String get moodyIntroActSpa => 'Experiencia de spa o bienestar';

  @override
  String get moodyIntroActCoffee => 'Lugar para el café de la mañana';

  @override
  String get moodyIntroActAdventure => 'Aventura al aire libre activa';

  @override
  String get moodyIntroActPeacefulWalk => 'Paseo tranquilo al atardecer';

  @override
  String get moodyIntroActHistorical => 'Visita a sitio histórico';

  @override
  String get moodyIntroActRomantic => 'Cena romántica';

  @override
  String get moodyIntroActSocial => 'Lugar para quedar con amigos';

  @override
  String get moodyIntroActScenic => 'Mirador con vistas';

  @override
  String get moodyIntroActEarlyMorning => 'Experiencia de madrugada';

  @override
  String get moodyIntroActEvening => 'Entretenimiento nocturno';

  @override
  String get moodyIntroActAfternoon => 'Actividad de tarde';

  @override
  String get moodyIntroActSurprise => 'Descubrimiento sorpresa';

  @override
  String get moodyIntroActMarketVisit => 'Visita al mercado local';

  @override
  String get moodyIntroActEveningWalk => 'Paseo al atardecer con vistas';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continueButton => 'Continuar';

  @override
  String get back => 'Atrás';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get dateOfBirth => 'Fecha de nacimiento';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get bio => 'Biografía';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get allowNotifications => 'Permitir notificaciones';

  @override
  String get masterControlForAllNotifications =>
      'Control maestro para todas las notificaciones';

  @override
  String get activityNotifications => 'Notificaciones de actividad';

  @override
  String get activityReminders => 'Recordatorios de actividad';

  @override
  String get remindersForUpcomingActivities =>
      'Recordatorios para actividades y planes próximos';

  @override
  String get moodTracking => 'Seguimiento del estado de ánimo';

  @override
  String get dailyPromptsToTrackYourMood =>
      'Prompts diarios para rastrear tu estado de ánimo';

  @override
  String get travelAndWeather => 'Viajes y clima';

  @override
  String get weatherAlerts => 'Alertas meteorológicas';

  @override
  String get getAlertsAboutWeatherChanges =>
      'Recibe alertas sobre cambios en el clima';

  @override
  String get travelTips => 'Consejos de viaje';

  @override
  String get suggestionsForYourTrips =>
      'Sugerencias para tus viajes y actividades';

  @override
  String get localEvents => 'Eventos locales';

  @override
  String get notificationsAboutEventsInYourArea =>
      'Notificaciones sobre eventos en tu área';

  @override
  String get social => 'Social';

  @override
  String get friendActivity => 'Actividad de amigos';

  @override
  String get whenFriendsShareTrips =>
      'Cuando los amigos comparten viajes o actividades';

  @override
  String get specialOffers => 'Ofertas especiales';

  @override
  String get promotionalOffersAndAppUpdates =>
      'Ofertas promocionales y actualizaciones de la aplicación';

  @override
  String get languageSettings => 'Configuración de idioma';

  @override
  String get chooseYourPreferredLanguage =>
      'Elige tu idioma preferido para la interfaz de la aplicación. Esto afectará todo el texto y el contenido en toda la aplicación.';

  @override
  String get privacySettings => 'Configuración de privacidad';

  @override
  String get publicProfile => 'Perfil público';

  @override
  String get allowOthersToViewYourProfile =>
      'Permitir que otros vean tu perfil';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get receivePushNotifications => 'Recibir notificaciones push';

  @override
  String get emailNotifications => 'Notificaciones por correo electrónico';

  @override
  String get receiveEmailNotifications =>
      'Recibir notificaciones por correo electrónico';

  @override
  String get manageYourPrivacySettings =>
      'Administra tu configuración de privacidad y preferencias de notificaciones. Estas configuraciones controlan quién puede ver tu perfil y cómo recibes actualizaciones.';

  @override
  String get themeSettings => 'Configuración de tema';

  @override
  String get chooseYourPreferredTheme =>
      'Elige tu tema preferido para la aplicación. Puedes seguir la configuración de tu sistema o elegir un tema específico.';

  @override
  String get system => 'Sistema';

  @override
  String get followSystemTheme => 'Seguir tema del sistema';

  @override
  String get light => 'Claro';

  @override
  String get lightTheme => 'Tema claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get darkTheme => 'Tema oscuro';

  @override
  String get changeYourMood => '¿Cambiar tu estado de ánimo?';

  @override
  String get doYouWantToContinueToChangeMood =>
      '¿Quieres continuar para cambiar tu estado de ánimo? Esto te llevará a la pantalla de selección de estado de ánimo.';

  @override
  String get enabled => 'habilitado';

  @override
  String get disabled => 'deshabilitado';

  @override
  String get updated => 'actualizado';

  @override
  String get failedToUpdate => 'Error al actualizar';

  @override
  String languageUpdatedTo(String language) {
    return 'Idioma actualizado a $language';
  }

  @override
  String themeUpdatedTo(String theme) {
    return 'Tema actualizado a $theme';
  }

  @override
  String get profileVisibilityUpdated => 'Visibilidad del perfil actualizada';

  @override
  String get pushNotificationsEnabled => 'Notificaciones push habilitadas';

  @override
  String get pushNotificationsDisabled => 'Notificaciones push deshabilitadas';

  @override
  String get emailNotificationsEnabled =>
      'Notificaciones por correo electrónico habilitadas';

  @override
  String get emailNotificationsDisabled =>
      'Notificaciones por correo electrónico deshabilitadas';

  @override
  String get settings => 'Settings';

  @override
  String get privacy => 'Privacy';

  @override
  String get privateProfile => 'Private Profile';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingTitle => '¡Preparando tu día perfecto!';

  @override
  String get loadingSubtitle =>
      '¡Estamos preparando actividades personalizadas,\nlugares e ideas solo para ti!';

  @override
  String get loadingStep0 => 'Preparando tu experiencia personalizada...';

  @override
  String get loadingStep1 => 'Cargando tus preferencias...';

  @override
  String get loadingStep2 => 'Buscando actividades que te encantarán...';

  @override
  String get loadingStep3 => 'Seleccionando actividades perfectas para ti...';

  @override
  String get loadingStep4 => '¡Casi listo! Configurando tu panel...';

  @override
  String get loadingStep5 => 'Preparando tu panel personalizado...';

  @override
  String get loadingStep6 =>
      '¡Listo para explorar! (Algunos datos se cargarán por el camino)';

  @override
  String get loadingFact0 =>
      '¿Sabías que hay 195 países en el mundo, cada uno con culturas y tradiciones únicas?';

  @override
  String get loadingFact1 =>
      '¡El aeropuerto más transitado del mundo atiende a más de 100 millones de pasajeros al año!';

  @override
  String get loadingFact2 =>
      '¡Hay más de 1.500 sitios del Patrimonio Mundial de la UNESCO en todo el mundo!';

  @override
  String get loadingFact3 =>
      '¡La Gran Muralla China es visible desde el espacio y se extiende más de 21.000 km!';

  @override
  String get loadingFact4 =>
      '¡Se hablan más de 6.900 idiomas en todo el mundo!';

  @override
  String get loadingFact5 =>
      '¡La selva amazónica produce el 20 % del oxígeno del mundo!';

  @override
  String get loadingFact6 =>
      '¡El Monte Everest crece unos 4 mm cada año debido a fuerzas geológicas!';

  @override
  String get loadingFact7 =>
      '¡El desierto del Sáhara es más grande que todo Estados Unidos!';

  @override
  String get weatherCurrentLocation => 'Ubicación actual';

  @override
  String get loadingFactNl0 =>
      '¡Países Bajos tiene más museos por kilómetro cuadrado que ningún otro país!';

  @override
  String get loadingFactNl1 =>
      '¡Róterdam alberga el puerto más grande de Europa, con más de 400 millones de toneladas al año!';

  @override
  String get loadingFactNl2 =>
      '¡Hay más de 35.000 km de carriles bici – suficiente para rodear la Tierra!';

  @override
  String get loadingFactNl3 =>
      '¡Ámsterdam tiene más canales que Venecia y más puentes que París!';

  @override
  String get loadingFactNl4 =>
      '¡Los neerlandeses comen más de 150 millones de stroopwafels al año!';

  @override
  String get loadingFactNl5 =>
      '¡Países Bajos es el segundo mayor exportador de alimentos del mundo a pesar de su tamaño!';

  @override
  String get loadingFactNl6 =>
      '¡Keukenhof muestra más de 7 millones de bulbos en 32 hectáreas!';

  @override
  String get loadingFactNl7 =>
      '¡Los neerlandeses son de media los más altos del mundo!';

  @override
  String get loadingFactUs0 =>
      '¡EE. UU. tiene 63 parques nacionales, de Yellowstone al Gran Cañón!';

  @override
  String get loadingFactUs1 =>
      '¡Alaska tiene más de 3 millones de lagos y más de 100.000 glaciares!';

  @override
  String get loadingFactUs2 => '¡La red interestatal supera los 75.000 km!';

  @override
  String get loadingFactUs3 =>
      '¡Times Square recibe más de 50 millones de visitas al año!';

  @override
  String get loadingFactUs4 =>
      '¡EE. UU. tiene la mayor economía del mundo y Silicon Valley!';

  @override
  String get loadingFactUs5 =>
      '¡Hawái es el único estado que cultiva café comercialmente!';

  @override
  String get loadingFactUs6 =>
      '¡El Golden Gate está pintado en «International Orange»!';

  @override
  String get loadingFactUs7 =>
      '¡Disney World en Florida es más grande que la ciudad de San Francisco!';

  @override
  String get loadingFactJp0 =>
      '¡Japón tiene más de 6.800 islas, pero solo 430 están habitadas!';

  @override
  String get loadingFactJp1 => '¡El Shinkansen puede superar los 300 km/h!';

  @override
  String get loadingFactJp2 =>
      '¡El Fuji es un volcán activo; última erupción en 1707!';

  @override
  String get loadingFactJp3 =>
      '¡Japón tiene más de 100.000 templos y santuarios!';

  @override
  String get loadingFactJp4 =>
      '¡Tokio es el área metropolitana más grande del mundo, con más de 37 millones de personas!';

  @override
  String get loadingFactJp5 =>
      '¡Japón consume cerca del 80 % del atún rojo mundial!';

  @override
  String get loadingFactJp6 =>
      '¡En Japón hay una máquina expendedora por cada 23 personas!';

  @override
  String get loadingFactJp7 =>
      '¡La floración del cerezo atrae millones de visitantes cada primavera!';

  @override
  String get loadingFactUk0 =>
      '¡El Reino Unido tiene más de 1.500 castillos, de fortalezas a residencias reales!';

  @override
  String get loadingFactUk1 =>
      '¡«Big Ben» no es el nombre de la torre – es Elizabeth Tower!';

  @override
  String get loadingFactUk2 =>
      '¡El Reino Unido ha dado más músicos famosos por habitante!';

  @override
  String get loadingFactUk3 =>
      '¡Stonehenge tiene más de 5.000 años y sigue siendo un misterio!';

  @override
  String get loadingFactUk4 =>
      '¡El metro de Londres es el más antiguo del mundo (1863)!';

  @override
  String get loadingFactUk5 =>
      '¡El Reino Unido tiene 15 sitios UNESCO, incluidos Bath y Edimburgo!';

  @override
  String get loadingFactUk6 =>
      '¡Escocia tiene más de 3.000 castillos y unas 790 islas!';

  @override
  String get loadingFactUk7 =>
      '¡Los británicos beben unos 100 millones de tazas de té al día!';

  @override
  String get loadingFactDe0 =>
      '¡Alemania tiene más de 25.000 castillos y palacios!';

  @override
  String get loadingFactDe1 =>
      '¡El muro de Berlín medía 155 km y duró 28 años!';

  @override
  String get loadingFactDe2 =>
      '¡El Oktoberfest a menudo empieza en septiembre!';

  @override
  String get loadingFactDe3 =>
      '¡La Selva Negra inspiró muchos cuentos de los hermanos Grimm!';

  @override
  String get loadingFactDe4 =>
      '¡En un ~60 % de autopistas alemanas a menudo no hay límite general!';

  @override
  String get loadingFactDe5 =>
      '¡Neuschwanstein inspiró el castillo de la Bella Durmiente de Disney!';

  @override
  String get loadingFactDe6 =>
      '¡Alemania tiene la mayor economía de Europa y fama de ingeniería!';

  @override
  String get loadingFactDe7 =>
      '¡El Rin atraviesa Alemania y está lleno de castillos medievales!';

  @override
  String get loadingFactFr0 =>
      '¡Francia es el país más visitado del mundo – más de 89 millones de turistas al año!';

  @override
  String get loadingFactFr1 =>
      '¡La Torre Eiffel fue al principio una estructura temporal para la Expo de 1889!';

  @override
  String get loadingFactFr2 =>
      '¡Francia produce más de 400 quesos – ¡uno para cada día!';

  @override
  String get loadingFactFr3 =>
      '¡Versalles tiene 2.300 habitaciones y 67 escaleras!';

  @override
  String get loadingFactFr4 =>
      '¡Francia tiene 44 sitios UNESCO, incluido Mont-Saint-Michel!';

  @override
  String get loadingFactFr5 =>
      '¡El Louvre es el museo de arte más grande del mundo!';

  @override
  String get loadingFactFr6 =>
      '¡La Costa Azul se extiende cientos de km por el Mediterráneo!';

  @override
  String get loadingFactFr7 =>
      '¡Francia acoge la carrera ciclista más famosa: el Tour de Francia!';

  @override
  String guestPlaceDistanceKm(String km) {
    return '$km km';
  }

  @override
  String guestPlaceHoursRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get prefSocialVibeTitleFallback => '¿Cuál es tu vibe social? 👥';

  @override
  String get prefSocialVibeSubtitleFallback =>
      '¿Cómo te gusta vivir las cosas?';

  @override
  String get prefPlanningPaceTitleFallback => 'Cuéntame tu ritmo ⏰';

  @override
  String get prefPlanningPaceSubtitleFallback => 'Tu estilo de planificación';

  @override
  String get prefTravelStyleTitleFallback => '¡Por último! ✨';

  @override
  String get prefTravelStyleSubtitleFallback => '¿Cuál es tu estilo de viaje?';

  @override
  String get prefStartMyJourney => 'Empezar mi viaje';

  @override
  String get onboardingPagerSlide1Title => 'Conoce a Moody 😄';

  @override
  String get onboardingPagerSlide1Subtitle => 'Tu BFF de viaje 💬🌍';

  @override
  String get onboardingPagerSlide1Description =>
      'Moody aprende tu vibe, tu energía y cómo va tu día. Con eso creo planes personalizados solo para ti. Piensa en mí como tu colega curioso que siempre quiere explorar 🌆🎈';

  @override
  String get onboardingPagerSlide2Title => 'Viaja con tu mood 🌈';

  @override
  String get onboardingPagerSlide2Subtitle => 'Tus emociones, tu viaje 💭';

  @override
  String get onboardingPagerSlide2Description =>
      'Ya sea tranquilo, romántico o aventurero… dime cómo te sientes y haré planes personalizados 🌸🏞️\nDesde joyas ocultas hasta paseos al atardecer: primero tu mood, siempre.';

  @override
  String get onboardingPagerSlide3Title => 'Tu día, a tu manera 🫶🏾';

  @override
  String get onboardingPagerSlide3Subtitle =>
      'Del amanecer hasta la noche ☀️🌙';

  @override
  String get onboardingPagerSlide3Description =>
      'Tu plan se divide en momentos—mañana, tarde, noche. Elige tu vibe, tus favoritos, yo me encargo de la magia. 🧭🎯 Según lugar, hora, clima y mood.';

  @override
  String get onboardingPagerSlide4Title => 'Cada día es un mood 🎨';

  @override
  String get onboardingPagerSlide4Subtitle =>
      'Descubre sitios nuevos cada día🌍';

  @override
  String get onboardingPagerSlide4Description =>
      'WanderMood hace que cada día sea una aventura. Despierta, revisa tu vibe, explora actividades escogidas a mano 💡📍 Deja que tu mood marque el camino una y otra vez.';

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
  String get introTagline => 'Tu estado de ánimo. Tu día. Tu aventura.';

  @override
  String get introTitleLine1 => 'Tu estado de ánimo,';

  @override
  String get introTitleLine2 => 'Tu aventura';

  @override
  String get introSkip => 'Omitir';

  @override
  String get introSeeHowItWorks => 'Ver cómo funciona';

  @override
  String get demoMoodyGreeting => '¡Hola! 👋 Soy Moody, tu compañero de viaje.';

  @override
  String get demoMoodyAskVibe =>
      'Te ayudo a descubrir lugares según cómo te sientes. ¿Cuál es tu estado de ánimo hoy?';

  @override
  String demoUserFeeling(String mood) {
    return 'Me siento $mood';
  }

  @override
  String get demoMoodyResponseAdventurous =>
      '¡Buena energía! 🔥 Aquí tienes sitios que encajan con tu espíritu aventurero...';

  @override
  String get demoMoodyResponseRelaxed =>
      '¡Un día tranquilo! ☕ Aquí tienes sitios para relajarte...';

  @override
  String get demoMoodyResponseRomantic =>
      '¡Qué bonito! 💕 Tengo sitios perfectos para el romance...';

  @override
  String get demoMoodyResponseCultural =>
      '¡Explorador curioso! 🎨 Echa un vistazo a estas joyas culturales...';

  @override
  String get demoMoodyResponseFoodie =>
      '¡Qué rico! 🍕 Aquí tienes sitios que te van a encantar...';

  @override
  String get demoMoodyResponseSocial =>
      '¡Vamos! 🎉 Tengo sitios geniales para quedar con amigos...';

  @override
  String get demoMoodyResponseDefault =>
      '¡Buena elección! 🌟 Aquí tienes sitios ideales para tu estado de ánimo...';

  @override
  String get demoMoodAdventurous => 'Aventurero';

  @override
  String get demoMoodRelaxed => 'Relajado';

  @override
  String get demoMoodRomantic => 'Romántico';

  @override
  String get demoMoodCultural => 'Cultural';

  @override
  String get demoMoodFoodie => 'Foodie';

  @override
  String get demoMoodSocial => 'Social';

  @override
  String get demoExploreMore => 'Explorar más';

  @override
  String get demoMode => 'Modo demo';

  @override
  String get demoMoodyName => 'Moody';

  @override
  String get demoTapToSelectMood => 'Toca para elegir tu estado de ánimo:';

  @override
  String get demoReadyToSignUp => '¿Listo para registrarte? Empieza ahora →';

  @override
  String get guestExplorePlaces => 'Explorar lugares';

  @override
  String get guestPreviewMode => 'Vista previa • Funciones limitadas';

  @override
  String get guestGuest => 'Invitado';

  @override
  String get guestSignUpFree => 'Registrarse gratis';

  @override
  String get guestLovingWhatYouSee => '¿Te gusta lo que ves?';

  @override
  String get guestSignUpSaveFavorites =>
      'Regístrate para guardar favoritos y crear planes';

  @override
  String get guestSignUp => 'Registrarse';

  @override
  String get guestSignUpToSaveFavorites =>
      '¡Regístrate para guardar favoritos!';

  @override
  String get guestNoPlacesMatchFilters =>
      'Ningún lugar coincide con los filtros';

  @override
  String get guestTryDifferentCategory => 'Prueba otra categoría';

  @override
  String get guestMoodySays => 'Moody dice...';

  @override
  String get guestGreatChoice =>
      '¡Buena elección para tu estado de ánimo de hoy!';

  @override
  String get guestSignUpToUnlock => 'Regístrate para desbloquear';

  @override
  String get guestSignUpUnlockDescription =>
      'Guardar favoritos, crear planes y recomendaciones personalizadas';

  @override
  String get guestSignUpFreeSparkle => 'Registrarse gratis ✨';

  @override
  String get guestExploringLikePro => '¡Exploras como un pro!';

  @override
  String get guestReadyToSaveFavorites =>
      '¿Listo para guardar favoritos y crear planes?';

  @override
  String get guestMaybeLater => 'Quizá más tarde';

  @override
  String get guestFilterHalal => 'Halal';

  @override
  String get guestFilterBlackOwned => 'De propiedad negra';

  @override
  String get guestFilterAesthetic => 'Estético';

  @override
  String get guestFilterLgbtq => 'LGBTQ+';

  @override
  String get guestFilterVegan => 'Vegano';

  @override
  String get guestFilterVegetarian => 'Vegetariano';

  @override
  String get guestFilterWheelchair => 'Accesible';

  @override
  String get guestCategoryAll => 'Todos';

  @override
  String get guestCategoryRestaurants => 'Restaurantes';

  @override
  String get guestCategoryCafes => 'Cafés';

  @override
  String get guestCategoryParks => 'Parques';

  @override
  String get guestCategoryMuseums => 'Museos';

  @override
  String get guestCategoryNightlife => 'Vida nocturna';

  @override
  String get demoActTitleMountainTrailHike => 'Senderismo de montaña';

  @override
  String get demoActTitleCityBikeTour => 'Tour en bici por la ciudad';

  @override
  String get demoActTitleIndoorClimbing => 'Escalada indoor';

  @override
  String get demoActTitleCozyCornerCafe => 'Café acogedor';

  @override
  String get demoActTitleBotanicalGarden => 'Jardín botánico';

  @override
  String get demoActTitleWellnessSpa => 'Spa de bienestar';

  @override
  String get demoActTitleSunsetViewpoint => 'Mirador al atardecer';

  @override
  String get demoActTitleWineAndDine => 'Vino y cena';

  @override
  String get demoActTitleRoseGardenWalk => 'Paseo por el jardín de rosas';

  @override
  String get demoActTitleHistoryMuseum => 'Museo de historia';

  @override
  String get demoActTitleLocalTheater => 'Teatro local';

  @override
  String get demoActTitleArtGallery => 'Galería de arte';

  @override
  String get demoActTitleLocalFavorite => 'Favorito local';

  @override
  String get demoActTitleCozyCafe => 'Café acogedor';

  @override
  String get demoActTitleWineBar => 'Bar de vinos';

  @override
  String get demoActTitleRooftopBar => 'Bar en la azotea';

  @override
  String get demoActTitleArcadeLounge => 'Arcade lounge';

  @override
  String get demoActTitleLiveMusicSpot => 'Local de música en vivo';

  @override
  String get demoActTitlePopularSpot => 'Lugar popular';

  @override
  String get demoActTitleFunActivity => 'Actividad divertida';

  @override
  String get demoActSubScenic32 => 'Aventura con vistas • 3,2 km';

  @override
  String get demoActSubActive18 => 'Exploración activa • 1,8 km';

  @override
  String get demoActSubThrilling25 => 'Experiencia emocionante • 2,5 km';

  @override
  String get demoActSubUnwinding08 => 'Perfecto para relajarse • 0,8 km';

  @override
  String get demoActSubPeaceful21 => 'Escape tranquilo • 2,1 km';

  @override
  String get demoActSubRelaxation34 => 'Relajación total • 3,4 km';

  @override
  String get demoActSubMagical15 => 'Ambiente mágico • 1,5 km';

  @override
  String get demoActSubIntimate09 => 'Ambiente íntimo • 0,9 km';

  @override
  String get demoActSubStroll23 => 'Paseo bonito • 2,3 km';

  @override
  String get demoActSubExhibits12 => 'Exposiciones fascinantes • 1,2 km';

  @override
  String get demoActSubLive18 => 'Espectáculos en vivo • 1,8 km';

  @override
  String get demoActSubContemporary07 => 'Arte contemporáneo • 0,7 km';

  @override
  String get demoActSubTopReviewed05 => 'Muy bien valorado • 0,5 km';

  @override
  String get demoActSubBrunch09 => 'Gran brunch • 0,9 km';

  @override
  String get demoActSubSmallPlates12 => 'Pequeños platos • 1,2 km';

  @override
  String get demoActSubVibes11 => 'Ambiente y vistas • 1,1 km';

  @override
  String get demoActSubGames07 => 'Juegos y copas • 0,7 km';

  @override
  String get demoActSubTonightsGig15 => 'Concierto de esta noche • 1,5 km';

  @override
  String get demoActSubHighlyRated10 => 'Muy valorado • 1,0 km';

  @override
  String get demoActSubGreatToday15 => 'Ideal para hoy • 1,5 km';

  @override
  String get demoActSubTopReviewed08 => 'Muy bien valorado • 0,8 km';

  @override
  String get guestPlaceNameCozyCorner => 'El Rincón Acogedor';

  @override
  String get guestPlaceNameSunsetTerrace => 'Terraza al atardecer';

  @override
  String get guestPlaceNameCityArtMuseum => 'Museo de arte urbano';

  @override
  String get guestPlaceNameGreenPark => 'Parque verde';

  @override
  String get guestPlaceNameJazzLounge => 'Jazz lounge';

  @override
  String get guestPlaceNameRooftopBar => 'Bar en la azotea';

  @override
  String get guestPlaceNameFreshKitchen => 'Cocina fresca';

  @override
  String get guestPlaceNameHistoryMuseum => 'Museo de historia';

  @override
  String get guestPlaceNameSpiceRoute => 'Ruta de las especias';

  @override
  String get guestPlaceNameSoulKitchen => 'Soul kitchen';

  @override
  String get guestPlaceNameStudioCafe => 'Café estudio';

  @override
  String get guestPlaceDescCozyCorner =>
      'Un café de barrio acogedor con café especial y pasteles frescos.';

  @override
  String get guestPlaceDescSunsetTerrace =>
      'Cena en terraza con vistas y ambiente relajado.';

  @override
  String get guestPlaceDescCityArtMuseum =>
      'Arte moderno y exposiciones temporales en un edificio singular.';

  @override
  String get guestPlaceDescGreenPark =>
      'Espacio verde ideal para pasear o hacer picnic.';

  @override
  String get guestPlaceDescJazzLounge =>
      'Jazz en vivo, cócteles y interior con ambiente.';

  @override
  String get guestPlaceDescRooftopBar =>
      'Vistas al skyline y cócteles a la hora dorada.';

  @override
  String get guestPlaceDescFreshKitchen =>
      'Bowls saludables y coloridos con ingredientes frescos.';

  @override
  String get guestPlaceDescHistoryMuseum =>
      'Historia local y patrimonio en un edificio histórico.';

  @override
  String get guestPlaceDescSpiceRoute => 'Sabores halal y porciones generosas.';

  @override
  String get guestPlaceDescSoulKitchen =>
      'Comida reconfortante y música en vivo en un espacio acogedor.';

  @override
  String get guestPlaceDescStudioCafe =>
      'Interior minimalista y buena luz para trabajar o quedar.';

  @override
  String get guestOpenNow => 'Abierto ahora';

  @override
  String get guestClosed => 'Cerrado';

  @override
  String get guestFree => 'Gratis';

  @override
  String get guestPaid => 'De pago';

  @override
  String guestDistanceAway(String distance) {
    return '$distance de distancia';
  }

  @override
  String get guestHours => 'Horario';

  @override
  String get signupJoinWanderMood => 'Únete a WanderMood';

  @override
  String get signupSubtitle =>
      'Introduce tu email para empezar.\n¡No hace falta contraseña!';

  @override
  String get signupEmailLabel => 'Email';

  @override
  String get signupEmailHint => 'tu@ejemplo.com';

  @override
  String get signupEmailRequired => 'Introduce tu email';

  @override
  String get signupEmailInvalid => 'Introduce un email válido';

  @override
  String get signupSendMagicLink => 'Enviar magic link';

  @override
  String get signupErrorGeneric => 'Algo ha ido mal. Inténtalo de nuevo.';

  @override
  String get signupWhatYouGet => 'Qué obtienes';

  @override
  String get signupBenefitPersonalized => 'Recomendaciones personalizadas';

  @override
  String get signupBenefitFavorites => 'Guarda tus sitios favoritos';

  @override
  String get signupBenefitDayPlans => 'Crea planes de día';

  @override
  String get signupBenefitMoodMatching =>
      'Actividades según tu estado de ánimo';

  @override
  String get signupTerms =>
      'Al continuar, aceptas nuestros Términos y Política de Privacidad';

  @override
  String get signupCheckEmail => '¡Revisa tu email!';

  @override
  String get signupWeSentLinkTo => 'Hemos enviado un magic link a';

  @override
  String get signupClickLinkInEmail =>
      'Haz clic en el enlace del email para iniciar sesión';

  @override
  String get signupLinkExpires => 'El enlace caduca en 24 horas';

  @override
  String get signupCheckSpam =>
      'Revisa la carpeta de spam si no está en la bandeja';

  @override
  String get signupTryAgain => '¿No has recibido el email? Inténtalo de nuevo';

  @override
  String signupAlmostThere(String city) {
    return '¡Casi listo! Un clic más para aventuras por estado de ánimo en $city ✨';
  }

  @override
  String get signupAlmostThereTitle => '¡Casi listo!';

  @override
  String signupAlmostThereBody(String city) {
    return 'Un clic más para aventuras por estado de ánimo en $city ✨';
  }

  @override
  String signupJoinTravelersInCity(String count, String city) {
    return '¡Únete a $count viajeros en $city!';
  }

  @override
  String signupJoinTravelers(String count) {
    return '¡Únete a $count viajeros!';
  }

  @override
  String get signupWhatYouUnlock => 'Qué desbloqueas';

  @override
  String get signupUnlockPersonalized => 'Recomendaciones personalizadas';

  @override
  String get signupUnlockFavorites => 'Guarda tus sitios favoritos';

  @override
  String get signupUnlockDayPlans => 'Crea planes de día';

  @override
  String get signupUnlockMoodMatching => 'Actividades según tu estado de ánimo';

  @override
  String get signupRating => '4,9/5 valoración';

  @override
  String get signupLoveIt => '98% les encanta';

  @override
  String get signupTestimonial =>
      '¡WanderMood me ayudó a descubrir sitios que no conocía!';

  @override
  String signupTestimonialBy(String city) {
    return '– Sarah, $city';
  }

  @override
  String get signupDefaultCity => 'Rotterdam';

  @override
  String get profileSnackAvatarUpdated => '¡Foto de perfil actualizada!';

  @override
  String profileSnackAvatarFailed(String error) {
    return 'Error al actualizar: $error';
  }

  @override
  String get profileErrorLoad => 'No se pudo cargar el perfil';

  @override
  String get profileRetry => 'Reintentar';

  @override
  String get profileFallbackUser => 'Usuario';

  @override
  String get profileStatsTitle => 'Tus estadísticas';

  @override
  String get profileStatsCheckinsTitle => 'Check-ins';

  @override
  String get profileStatsPlacesTitle => 'Lugares';

  @override
  String get profileStatsPlacesSubtitle => 'Toca para explorar';

  @override
  String get profileStatsTopMoodTitle => 'Top estado de ánimo';

  @override
  String get profileStatsStreakTitle => 'Streak';

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
  String get profileFavoriteVibesTitle => 'Tus vibes favoritas';

  @override
  String get profileFavoriteVibesEdit => 'Editar';

  @override
  String get profileFavoriteVibesAdd => '+ Añadir vibe';

  @override
  String get profileMoodJourneyTitle => 'Tu viaje de ánimo';

  @override
  String get profileMoodJourneySubtitle => 'Ver tu historial de ánimo';

  @override
  String get moodHistoryIntro =>
      'Una línea de tiempo tranquila de cómo te has sentido.';

  @override
  String get moodHistorySectionRecent => 'Reciente';

  @override
  String get moodHistorySectionTimeline => 'Línea de tiempo';

  @override
  String get moodHistoryEmptyTitle => 'Tu viaje empieza aquí';

  @override
  String get moodHistoryEmptyBody =>
      'Registra tu ánimo desde Moody Hub o Mi día—tus momentos aparecerán abajo.';

  @override
  String get moodHistoryLoginRequired =>
      'Inicia sesión para ver tu viaje de ánimo.';

  @override
  String get moodHistoryErrorUser => 'No se pudo cargar tu cuenta.';

  @override
  String get moodHistoryErrorMoods => 'No se pudieron cargar los ánimos.';

  @override
  String get moodHistoryTodayBadge => 'Hoy';

  @override
  String get moodHistoryDayToday => 'Hoy';

  @override
  String get moodHistoryDayYesterday => 'Ayer';

  @override
  String get profileTravelGlobeTitle => 'Tu globo viajero';

  @override
  String get profileTravelGlobeSubtitle => 'Explora tu viaje';

  @override
  String get profilePreferencesTitle => 'Tus preferencias';

  @override
  String get profilePreferencesEditAll => 'Editar todo';

  @override
  String get profilePreferencesBudgetStyle => 'Estilo de presupuesto';

  @override
  String get profilePreferencesSocialVibe => 'Vibe social';

  @override
  String get profilePreferencesFoodPreferences => 'Preferencias alimentarias';

  @override
  String get profilePreferencesEmptyHint =>
      'Toca \"Editar todo\" para configurar tus preferencias';

  @override
  String get profilePreferencesFilledHint =>
      'Estas preferencias guían sutilmente qué lugares y planes te van mejor.';

  @override
  String get profilePreferencesEmptyDescription =>
      'Completa tus preferencias para que WanderMood se adapte mejor a tu estilo.';

  @override
  String get profileSectionWorldTitle => 'Tu mundo';

  @override
  String get profileSectionWorldSubtitle =>
      'Lugares que guardas, estados de ánimo que sigues y la historia de tus viajes.';

  @override
  String get profileSectionPreferencesSubtitle =>
      'Los detalles que hacen WanderMood más personal e inteligente.';

  @override
  String get profileSavedPlacesSubtitle =>
      'Lugares que quieres encontrar fácilmente más tarde.';

  @override
  String get profileSavedPlacesEmptyHint =>
      'Aún no tienes lugares guardados. Guarda algunos favoritos para que tu perfil se sienta más como tu mapa de viajes.';

  @override
  String get profileSavedPlacesCarouselEmpty =>
      'Sin guardados aún — toca ♥ en un lugar para guardarlo.';

  @override
  String get profileBioEmptyHint => 'Añade una bio corta en Editar perfil.';

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
      'Elige algunos vibes para que Moody entienda rápidamente lo que buscas.';

  @override
  String get profileFavoriteVibesFilledDescription =>
      'Estos vibes ayudan a WanderMood a determinar qué lugares y planes te van mejor.';

  @override
  String get profileFavoriteVibesEmptyHint =>
      'Añade tu primer vibe y dale más personalidad a tu perfil enseguida.';

  @override
  String get profileVibesProTipsTitle => '💡 Pro Tips';

  @override
  String get profileVibesProTipsBody =>
      '• Sé honesto sobre lo que disfrutas — ¡mejores recomendaciones!\n• Puedes cambiar esto en cualquier momento\n• Mezcla diferentes vibes para sugerencias variadas';

  @override
  String get profileModeLocalCardDescription =>
      'WanderMood mantiene tus sugerencias más cerca de casa y alineadas con tu ritmo habitual.';

  @override
  String get profileModeTravelCardDescription =>
      'WanderMood piensa más como compañero de viaje y te envía a nuevos lugares por descubrir.';

  @override
  String get profileActionEdit => 'Editar';

  @override
  String get profileActionShare => 'Compartir';

  @override
  String get profileAgeGroup20s => 'Aventurero 20 años';

  @override
  String get profileAgeGroup30s => 'Aventurero 30 años';

  @override
  String get profileAgeGroup40s => 'Aventurero 40 años';

  @override
  String get profileAgeGroup50s => 'Aventurero 50 años';

  @override
  String get profileAgeGroup55Plus => 'Aventurero 55+';

  @override
  String get profileBudgetLow => '\$ Budget';

  @override
  String get profileBudgetMid => '\$\$ Moderado';

  @override
  String get profileBudgetHigh => '\$\$\$ Lujo';

  @override
  String get profileSocialSolo => 'Solo';

  @override
  String get profileSocialCouple => 'Pareja';

  @override
  String get profileSocialGroup => 'Grupo';

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
  String get profileEditUsernameLabel => 'Username';

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
  String get profileEditFavoriteVibesTitle => 'Vibes favoritas';

  @override
  String get profileEditFavoriteVibesEdit => 'Editar';

  @override
  String get profileEditFavoriteVibesSubtitle =>
      'Elige tus vibes favoritas para personalizar tus recomendaciones';

  @override
  String get profileEditPhotoTake => 'Take Photo';

  @override
  String get profileEditPhotoChoose => 'Choose from Gallery';

  @override
  String get profileEditPhotoRemove => 'Remove Photo';

  @override
  String get profileEditVibesTitle => 'Editar vibes favoritas';

  @override
  String get profileEditVibesDone => 'Listo';

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
  String get profileVibesUpdated => '¡Vibes actualizadas! 🎉';

  @override
  String profileVibesSaveFailed(String error) {
    return 'Error al guardar las vibes: $error';
  }

  @override
  String get profileVibesEditTitle => 'Editar vibes favoritas';

  @override
  String get profileVibesSave => 'Guardar';

  @override
  String profileVibesSelectedCount(String count) {
    return 'Seleccionados ($count/5)';
  }

  @override
  String get profileVibesMaxReached => 'Máximo alcanzado';

  @override
  String get profileVibesChooseTitle => 'Elige tus vibes';

  @override
  String get profileVibesAddMore => 'Añadir más vibes';

  @override
  String get profileVibesSubtitle =>
      'Elige hasta 5 vibes que encajen contigo. Las usaremos para personalizar tus recomendaciones.';

  @override
  String get profileVibesCurrentTitle => 'TUS VIBES ACTUALES';

  @override
  String get shareProfileTitle => 'Compartir perfil';

  @override
  String shareProfileShareTextMy(String url) {
    return '¡Mira mi perfil en WanderMood! 🧳✨\n\n$url';
  }

  @override
  String shareProfileShareTextNamed(String name, String url) {
    return '¡Mira el perfil de $name en WanderMood! 🧳✨\n\n$url';
  }

  @override
  String get shareProfileMy => 'mi';

  @override
  String get shareProfileDefaultUsername => 'viajero';

  @override
  String get shareProfileEmailSubject => 'Mira mi perfil de WanderMood';

  @override
  String shareProfileFailedToShare(String error) {
    return 'Error al compartir: $error';
  }

  @override
  String get shareProfileDefaultBio =>
      'Siempre persiguiendo atardeceres y buen rollo ✨';

  @override
  String get shareProfileDayStreak => 'Racha de días';

  @override
  String get shareProfileQRCode => 'Código QR';

  @override
  String get shareProfileScanToConnect => 'Escanea para conectar';

  @override
  String get shareProfileCopyLink => 'Copiar enlace';

  @override
  String get shareProfileShareAnywhere => 'Compartir en cualquier sitio';

  @override
  String get shareProfileShareVia => 'Compartir vía';

  @override
  String get shareProfileInstagram => 'Instagram';

  @override
  String get shareProfileWhatsApp => 'WhatsApp';

  @override
  String get shareProfileTwitter => 'Twitter';

  @override
  String get shareProfileEmail => 'Correo';

  @override
  String get shareProfilePublicProfile => 'Perfil público';

  @override
  String get shareProfileAnyoneCanView => 'Cualquiera puede ver tu perfil';

  @override
  String shareProfileUpdateFailed(String error) {
    return 'Error al actualizar: $error';
  }

  @override
  String get shareProfileMyQRCode => 'Mi código QR';

  @override
  String get shareProfileHowItWorks => 'Cómo funciona';

  @override
  String get shareProfileQRInstructions =>
      '¡Pide a alguien que escanee este código con la app WanderMood para conectar al instante y compartir tu perfil!';

  @override
  String get shareProfileDownloaded => '¡Descargado!';

  @override
  String get shareProfileSaveQRCode => 'Guardar código QR';

  @override
  String shareProfileShareMessage(String url) {
    return '¡Mira mi perfil de WanderMood! $url';
  }

  @override
  String get shareProfileShareQRImage => 'Compartir imagen QR';

  @override
  String get shareProfileShareLinkTitle => 'Compartir enlace';

  @override
  String get shareProfileYourProfileLink => 'TU ENLACE DE PERFIL';

  @override
  String get shareProfileLinkCopied => '¡Enlace copiado!';

  @override
  String get shareProfileQuickShare => 'COMPARTIR RÁPIDO';

  @override
  String get shareProfileLinkInfo =>
      'Cualquiera con este enlace puede ver tu perfil público. Puedes cambiar la privacidad cuando quieras.';

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
  String get drawerMyAgenda => 'My Agenda';

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
  String drawerDayStreak(String count) {
    return '$count Day Streak';
  }

  @override
  String get profileModeLocal => 'Modo local';

  @override
  String get profileModeTravel => 'De viaje';

  @override
  String get profileModeWhatDoesThisDo => '¿Qué hace esto?';

  @override
  String get profileModeSwitchToLocal => 'Cambiar a modo local';

  @override
  String get profileModeSwitchToTravel => 'Cambiar a modo viaje';

  @override
  String get profileModeCancel => 'Cancelar';

  @override
  String get profileModeChangeAnytime => 'Puedes cambiarlo cuando quieras';

  @override
  String get profileModeUpdated => '¡Modo actualizado!';

  @override
  String get profileModeUpdating =>
      'Tus recomendaciones se están actualizando...';

  @override
  String get profileModeTravelModesExplained => 'Modos de viaje explicados';

  @override
  String get profileModeLocalTitle => 'Modo local';

  @override
  String get profileModeLocalDescription => 'Descubriendo joyas en tu barrio';

  @override
  String get profileModeLocalFeature1 => 'Cafés y rincones locales';

  @override
  String get profileModeLocalFeature2 => 'Favoritos del barrio';

  @override
  String get profileModeLocalFeature3 => 'Lugares menos turísticos';

  @override
  String get profileModeTravelTitle => 'Modo viaje';

  @override
  String get profileModeTravelDescription =>
      'Explora los imprescindibles como viajero';

  @override
  String get profileModeTravelFeature1 => 'Monumentos famosos';

  @override
  String get profileModeTravelFeature2 => 'Imprescindibles';

  @override
  String get profileModeTravelFeature3 => 'Sitios turísticos';

  @override
  String get profileModeLocalExplainer =>
      'Perfecto en casa o explorando tu ciudad. ¡Descubre lo que gusta a los locales!';

  @override
  String get profileModeLocalExample =>
      'Ejemplo: en vez de la Torre Eiffel, verás la Boulangerie de la esquina a la que van los parisinos.';

  @override
  String get profileModeTravelExplainer =>
      'Perfecto cuando viajas o visitas una ciudad nueva. ¡Todos los imprescindibles!';

  @override
  String get profileModeTravelExample =>
      'Ejemplo: en París verás la Torre Eiffel, el Louvre y el Arco de Triunfo.';

  @override
  String get profileModeSwitchAnytime =>
      '¡Cambia cuando quieras! ¿De vacaciones? Modo viaje. ¿En casa? Modo local. Tus recomendaciones se adaptan al instante.';

  @override
  String get profileModeGotIt => '¡Entendido!';

  @override
  String get profileModeProTip => 'Consejo pro';

  @override
  String get profileModeLocalGem1 => 'Joyas del barrio';

  @override
  String get profileModeLocalGem2 => 'Cafés y restaurantes locales';

  @override
  String get profileModeLocalGem3 => 'Sitios menos concurridos';

  @override
  String get profileModeLocalGem4 => 'Experiencias locales auténticas';

  @override
  String get profileModeTravelSpot1 => 'Monumentos y atracciones';

  @override
  String get profileModeTravelSpot2 => 'Imprescindibles turísticos';

  @override
  String get profileModeTravelSpot3 => 'Destinos populares';

  @override
  String get profileModeTravelSpot4 => 'Lugares turísticos';

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
  String get settingsHubTitle => 'Ajustes';

  @override
  String get settingsQuickTipTitle => 'Consejo rápido';

  @override
  String get settingsQuickTipBody =>
      'Para editar tu perfil o tus preferencias, vuelve a tu pantalla de perfil.';

  @override
  String get settingsSectionPrivacySecurity => 'Privacidad y seguridad';

  @override
  String get settingsSectionAppSettings => 'Ajustes de la app';

  @override
  String get settingsSectionMore => 'Más';

  @override
  String get settingsSectionDangerZone => 'Zona peligrosa';

  @override
  String get settingsAccountSecurityTitle => 'Seguridad de la cuenta';

  @override
  String get settingsAccountSecuritySubtitle => '2FA';

  @override
  String get settingsTwoFactorTitle => 'Autenticación en dos pasos';

  @override
  String get settingsTwoFactorEnabled => 'Activado';

  @override
  String get settingsTwoFactorNotEnabled => 'No activado';

  @override
  String get settingsTwoFactorBadgeRecommended => 'Recomendado';

  @override
  String get settingsActiveSessionsTitle => 'Sesiones activas';

  @override
  String settingsActiveSessionsSubtitle(String count) {
    return '$count dispositivos';
  }

  @override
  String get settingsPrivacyTitle => 'Privacy';

  @override
  String get settingsPrivacySubtitle => 'Visibilidad del perfil, datos';

  @override
  String get settingsHubNotificationsSubtitle =>
      'Push, correo, dentro de la app';

  @override
  String get settingsLocationLabel => 'Location';

  @override
  String get settingsLocationSubtitle => 'Detección automática, permisos';

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
  String get settingsHelpSupportSubtitle => 'Preguntas frecuentes, contáctanos';

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
  String get notificationsMethodsTitle => 'Métodos de notificación';

  @override
  String get notificationsPushTitle => 'Notificaciones push';

  @override
  String get notificationsPushSubtitle =>
      'Recibir notificaciones push en este dispositivo';

  @override
  String get notificationsEmailTitle => 'Notificaciones por correo';

  @override
  String get notificationsEmailSubtitle =>
      'Recibir actualizaciones por correo electrónico';

  @override
  String get notificationsInAppTitle => 'Notificaciones dentro de la app';

  @override
  String get notificationsInAppSubtitle =>
      'Ver notificaciones dentro de la app';

  @override
  String get notificationsWhatToNotifyTitle => 'Qué notificar';

  @override
  String get notificationsNewActivitiesTitle => 'Nuevas actividades';

  @override
  String get notificationsNewActivitiesSubtitle =>
      'Cuando nuevas actividades coinciden con tu vibe';

  @override
  String get notificationsNearbyEventsTitle => 'Eventos cercanos';

  @override
  String get notificationsNearbyEventsSubtitle =>
      'Eventos que ocurren cerca de ti';

  @override
  String get notificationsFriendActivityTitle => 'Actividad de amigos';

  @override
  String get notificationsFriendActivitySubtitle =>
      'Cuando tus amigos comparten o les gusta algo';

  @override
  String get locationScreenTitle => 'Ubicación';

  @override
  String get locationCurrentLocationTitle => 'Ubicación actual';

  @override
  String get locationCurrentLocationValue => 'Róterdam, Países Bajos';

  @override
  String get locationSectionSettingsTitle => 'Ajustes de ubicación';

  @override
  String get locationAutoDetectTitle => 'Detectar ubicación automáticamente';

  @override
  String get locationAutoDetectSubtitle =>
      'Detectar automáticamente tu ubicación actual';

  @override
  String get locationSectionDefaultTitle => 'Ubicación predeterminada';

  @override
  String get locationDefaultCityLabel => 'Róterdam';

  @override
  String get locationDefaultUsedWhenOff =>
      'Se usa cuando la ubicación está desactivada';

  @override
  String get locationPermissionsTitle => 'Permisos de ubicación';

  @override
  String get locationPermissionsSubtitle =>
      'Gestionar en los ajustes del sistema';

  @override
  String get locationSnackbarUpdated => 'Ajustes de ubicación actualizados';

  @override
  String locationSnackbarError(String error) {
    return 'Error al actualizar los ajustes de ubicación: $error';
  }

  @override
  String get languageUpdated => 'Idioma actualizado';

  @override
  String get subscriptionScreenTitle => 'Suscripción';

  @override
  String get subscriptionCurrentPlanLabel => 'Plan actual';

  @override
  String get subscriptionPlanFree => 'Gratis';

  @override
  String get subscriptionPlanPremium => 'Premium';

  @override
  String get subscriptionUpgradeHeading => 'Subir a';

  @override
  String get subscriptionUpgradeTitle => 'Premium';

  @override
  String get subscriptionFeatureUnlimitedSuggestions =>
      'Sugerencias de actividades ilimitadas';

  @override
  String get subscriptionFeatureAdvancedMoodMatching =>
      'Matching de estado de ánimo avanzado';

  @override
  String get subscriptionFeaturePrioritySupport => 'Soporte prioritario';

  @override
  String get subscriptionFeatureNoAds => 'Sin anuncios';

  @override
  String get subscriptionUpgradeCta => 'Subir por 4,99 € al mes';

  @override
  String get dataStorageTitle => 'Datos y almacenamiento';

  @override
  String get dataStorageStorageUsedLabel => 'Almacenamiento usado';

  @override
  String get dataStorageExportTitle => 'Exportar mis datos';

  @override
  String get dataStorageExportSubtitle => 'Descargar todos tus datos (RGPD)';

  @override
  String get dataStorageClearCacheTitle => 'Borrar caché';

  @override
  String get dataStorageClearCacheSubtitle => 'Liberar espacio';

  @override
  String get dataStorageDownloadHistoryTitle => 'Historial de descargas';

  @override
  String get dataStorageDownloadHistorySubtitle =>
      'Ver exportaciones anteriores';

  @override
  String get dataStorageExportFileTitle => 'Exportación de datos de WanderMood';

  @override
  String get dataStorageExportSuccess => 'Datos exportados correctamente';

  @override
  String dataStorageExportFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get dataStorageCacheCleared => 'Caché borrada correctamente';

  @override
  String dataStorageCacheFailed(String error) {
    return 'Error al borrar la caché: $error';
  }

  @override
  String get helpSupportScreenTitle => 'Ayuda y soporte';

  @override
  String get helpSupportSearchHint => 'Buscar en los artículos de ayuda...';

  @override
  String get helpSupportQuickLinksTitle => 'Accesos rápidos';

  @override
  String get helpSupportFaqTitle => 'Preguntas frecuentes';

  @override
  String get helpSupportFaqSubtitle => 'Dudas más comunes';

  @override
  String get helpSupportContactTitle => 'Contactar';

  @override
  String get helpSupportContactSubtitle => 'Envíanos un correo';

  @override
  String get helpSupportLiveChatTitle => 'Chat en vivo';

  @override
  String get helpSupportLiveChatSubtitle => 'Habla con soporte';

  @override
  String get helpSupportLiveChatBadgeOnline => 'En línea';

  @override
  String get helpSupportReportBugTitle => 'Reportar un error';

  @override
  String get helpSupportReportBugSubtitle => 'Ayúdanos a mejorar';

  @override
  String get helpSupportLegalTitle => 'Legal';

  @override
  String get helpSupportPrivacyTitle => 'Política de privacidad';

  @override
  String get helpSupportPrivacySubtitle => 'Cómo protegemos tus datos';

  @override
  String get helpSupportTermsTitle => 'Términos de uso';

  @override
  String get helpSupportTermsSubtitle => 'Condiciones generales';

  @override
  String get helpSupportEmailAddress => 'support@wandermood.com';

  @override
  String get helpSupportEmailSubject => 'Soporte WanderMood';

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
  String get prefInterestFood => 'Comida y bebida';

  @override
  String get prefInterestFoodDesc => 'Local cuisine and unique restaurants';

  @override
  String get prefInterestArts => 'Arts & Culture';

  @override
  String get prefInterestArtsDesc => 'Museums, galleries, and theaters';

  @override
  String get prefInterestShopping => 'Compras';

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
  String get prefSectionSocialVibe => 'Vibe social';

  @override
  String get prefSectionPlanningPace => 'Planning Pace ⏰';

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
  String get prefTravelStyleTouristHighlights => 'Atracciones turísticas';

  @override
  String get prefTravelStyleTouristHighlightsDesc =>
      'Lugares imprescindibles, sitios populares';

  @override
  String get prefTravelStyleOffBeatenPath => 'Fuera de lo común';

  @override
  String get prefTravelStyleOffBeatenPathDesc =>
      'Joyas ocultas, experiencias únicas';

  @override
  String get dayPlanTodayItinerary => 'ITINERARIO DE HOY';

  @override
  String get dayPlanBasedOn => 'Tu plan del día según:';

  @override
  String get dayPlanEditMoods => 'Editar estados de ánimo →';

  @override
  String get dayPlanAddToMyDay => 'Añadir a Mi Día';

  @override
  String dayPlanAddMoreToMyDay(String count) {
    return 'Agregar $count más a Mi Día';
  }

  @override
  String get dayPlanViewMyDay => 'Ver Mi Día';

  @override
  String get dayPlanPlanAddedToMyDay => '¡Plan añadido a Mi Día!';

  @override
  String get dayPlanAddPlanFailed =>
      'No se pudo añadir el plan. Inténtalo de nuevo.';

  @override
  String get dayPlanAllAlternativesUsed =>
      '¡Has usado las 3 opciones alternativas para esta actividad!';

  @override
  String dayPlanFindingOptions(String name) {
    return 'Buscando nuevas opciones para $name...';
  }

  @override
  String get dayPlanNoOptionsFound =>
      'No hay más opciones para este horario. ¡Prueba otro estado de ánimo!';

  @override
  String get dayPlanFindOptionsFailed =>
      'No se encontraron nuevas opciones. Inténtalo más tarde.';

  @override
  String get dayPlanAllOptionsUsed => 'Todas las opciones usadas';

  @override
  String get dayPlanNotFeelingThis => '¿No te convence?';

  @override
  String dayPlanTryAgainLeft(String count) {
    return '¿Probar otra? ($count restantes)';
  }

  @override
  String get dayPlanMorning => 'MAÑANA';

  @override
  String get dayPlanAfternoon => 'TARDE';

  @override
  String get dayPlanEvening => 'NOCHE';

  @override
  String get dayPlanThemeExploreDiscover => 'Explorar y descubrir';

  @override
  String get dayPlanThemeTrueLocalFind => 'Un hallazgo local';

  @override
  String get dayPlanThemeWindDownCulture => 'Relajación y cultura';

  @override
  String get dayPlanThemeCulturalDeepDive => 'Inmersión cultural';

  @override
  String get dayPlanThemeFoodieFind => 'Un find foodie';

  @override
  String get dayPlanThemeSunsetVibes => 'Atardecer y cultura';

  @override
  String get dayPlanThemeWindDownRelax => 'Relajación y calma';

  @override
  String get dayPlanThemeAdventureAwaits => 'Aventura te espera';

  @override
  String get dayPlanThemeOutdoorNature => 'Exterior y naturaleza';

  @override
  String get dayPlanThemeCreativeVibes => 'Vibes creativas';

  @override
  String get dayPlanThemeRomanticMoments => 'Momentos románticos';

  @override
  String get dayPlanThemeYourVibe => 'Tu vibe';

  @override
  String get dayPlanCardActivity => 'Actividad';

  @override
  String get dayPlanCardFree => 'Gratis';

  @override
  String get dayPlanCardOpenNow => 'Abierto ahora';

  @override
  String get dayPlanCardClosed => 'Cerrado';

  @override
  String get dayPlanCardNotFeelingThis => '¿No te convence?';

  @override
  String get dayPlanCardDirections => 'Cómo llegar';

  @override
  String get dayPlanCardSeeActivity => 'Ver actividad';

  @override
  String get dayPlanCardUnableToOpenDirections =>
      'No se pudo abrir las direcciones';

  @override
  String get dayPlanCardFailedToShare => 'Error al compartir';

  @override
  String dayPlanCardRemovedFromSaved(String name) {
    return '$name eliminado de guardados';
  }

  @override
  String dayPlanCardFailedToRemove(String name) {
    return 'No se pudo eliminar $name';
  }

  @override
  String get dayPlanCardCouldNotSaveMoodyHub =>
      'No se pudo guardar en Moody Hub. Puede que tengas que iniciar sesión.';

  @override
  String get dayPlanCardCouldNotAddMyDay =>
      'No se pudo añadir a Mi Día. Puede que tengas que iniciar sesión.';

  @override
  String dayPlanCardSavedToMoodyHubAndMyDay(String name) {
    return '¡$name guardado! Lo encuentras en Moody Hub (guardados) y Mi Día.';
  }

  @override
  String dayPlanCardSavedToMoodyHub(String name) {
    return '$name guardado en Moody Hub.';
  }

  @override
  String dayPlanCardAddedToMyDay(String name) {
    return '$name añadido a Mi Día.';
  }

  @override
  String get dayPlanCardAdded => 'Añadido';

  @override
  String get dayPlanCardAddRemainingToMyDay => 'Añadir el resto a Mi Día';

  @override
  String dayPlanCardMatch(String percent) {
    return '$percent% coincidencia';
  }

  @override
  String get dayPlanCardAddToMyDay => '+ Añadir a Mi Día';

  @override
  String moodHubGreetingFriendly(String name) {
    return '¡Hola, $name!';
  }

  @override
  String moodHubGreetingBestie(String name) {
    return '¡Hola, $name! 😊';
  }

  @override
  String moodHubGreetingProfessional(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String moodHubGreetingDirect(String name) {
    return 'Hola, $name';
  }

  @override
  String get moodHubGreetingHeyThere => '¡Hola!';

  @override
  String get moodHubGreetingHi => 'Hola';

  @override
  String get moodHubWhatIsYourMood => '¿Cuál es tu estado de ánimo';

  @override
  String get moodHubThisMorning => 'esta mañana?';

  @override
  String get moodHubThisAfternoon => 'esta tarde?';

  @override
  String get moodHubThisEvening => 'esta noche?';

  @override
  String get moodHubTonight => 'esta noche?';

  @override
  String get moodHubBannerMorning => 'Buenos días — vamos a marcar el tono.';

  @override
  String get moodHubBannerAfternoon =>
      'Buenas tardes — hora de conectar con tu vibe.';

  @override
  String get moodHubBannerEvening => 'Buenas noches — ¿cuál es tu vibe?';

  @override
  String get moodHubBannerNight => 'Noche — busquemos algo que encaje.';

  @override
  String get moodHubCreatePlan => '¡Crea tu plan perfecto! 🎯';

  @override
  String get moodHubBackToHub => 'Volver al Hub';

  @override
  String moodHubSelectUpTo(String max) {
    return 'Puedes elegir hasta $max estados de ánimo';
  }

  @override
  String get moodHubSelectedMoods => 'Estados de ánimo elegidos: ';

  @override
  String get moodHubNoMoodOptions => 'No hay opciones de estado de ánimo';

  @override
  String get moodHubMoodyThinking => 'Moody está pensando...';

  @override
  String get moodHubMoodHappy => 'Feliz';

  @override
  String get moodHubMoodAdventurous => 'Aventurero';

  @override
  String get moodHubMoodRelaxed => 'Relajado';

  @override
  String get moodHubMoodEnergetic => 'Enérgico';

  @override
  String get moodHubMoodRomantic => 'Romántico';

  @override
  String get moodHubMoodSocial => 'Social';

  @override
  String get moodHubMoodCultural => 'Cultural';

  @override
  String get moodHubMoodCurious => 'Curioso';

  @override
  String get moodHubMoodCozy => 'Acogedor';

  @override
  String get moodHubMoodExcited => 'Emocionado';

  @override
  String get moodHubMoodFoody => 'Foodie';

  @override
  String get moodHubMoodSurprise => 'Sorpresa';

  @override
  String get planLoadingErrorTitle => '¡Ups! Algo salió mal';

  @override
  String get planLoadingTryAgain => 'Intentar de nuevo';

  @override
  String get planLoadingErrorGeneric =>
      'No se pudieron generar actividades. Intenta de nuevo o elige otros estados de ánimo.';

  @override
  String get planLoadingErrorNetwork =>
      'Error de conexión. Comprueba tu conexión a internet.';

  @override
  String get planLoadingErrorLocation =>
      'Se necesita acceso a la ubicación. Activa los servicios de ubicación.';

  @override
  String get planLoadingErrorService =>
      'Servicio no disponible. Intenta en unos minutos.';

  @override
  String get planLoadingErrorApiKey =>
      'Error de configuración. Contacta con soporte.';

  @override
  String get planLoadingErrorNotFound =>
      'Servicio no disponible. Intenta más tarde.';

  @override
  String get planLoadingErrorNoActivities =>
      'No se encontraron actividades. Prueba otros estados de ánimo o comprueba la ubicación.';

  @override
  String get planLoadingMessage => 'Creando tu plan…';

  @override
  String get moodySays => 'Moody dice';

  @override
  String get dayPlanMoodyCardTitle => 'Moody';

  @override
  String get moodCultural => 'Cultural';

  @override
  String get moodCozy => 'Acogedor';

  @override
  String get moodFoody => 'Foodie';

  @override
  String get moodRelaxed => 'Relajado';

  @override
  String get moodAdventurous => 'Aventurero';

  @override
  String get moodSocial => 'Social';

  @override
  String get moodCreative => 'Creativo';

  @override
  String get moodRomantic => 'Romántico';

  @override
  String get moodEnergetic => 'Enérgico';

  @override
  String get moodCurious => 'Curioso';

  @override
  String dayPlanFoundNewOption(String name, String remaining) {
    return '✨ Nueva opción encontrada: $name. ($remaining cambios más disponibles)';
  }

  @override
  String activityDetailMatch(String percent) {
    return '$percent% de coincidencia';
  }

  @override
  String activityDetailPhotoCount(String count) {
    return '$count foto';
  }

  @override
  String get activityDetailRatingExceptional => 'Excepcional';

  @override
  String get activityDetailDuration => 'Duración';

  @override
  String get activityDetailPrice => 'Precio';

  @override
  String get activityDetailDistance => 'Distancia';

  @override
  String get activityDetailAbout => 'Sobre';

  @override
  String get activityDetailHighlights => 'Destacados';

  @override
  String get activityDetailLocation => 'Ubicación';

  @override
  String get activityDetailGetDirections => 'Cómo llegar →';

  @override
  String get activityDetailFrom => 'Desde';

  @override
  String get activityDetailPerPerson => 'por persona';

  @override
  String get activityDetailDirections => 'Direcciones';

  @override
  String get activityDetailBookNow => 'Reservar ahora';

  @override
  String get getReadyTitle => 'Prepárate';

  @override
  String getReadyLeaveBy(String time) {
    return 'Sal antes de las $time';
  }

  @override
  String getReadyTripSummary(String mode, int minutes) {
    return '$mode · ~$minutes min de trayecto';
  }

  @override
  String getReadyWeatherAt(String time) {
    return 'Tiempo a las $time';
  }

  @override
  String get getReadyWeatherTipDefault => 'Parece un buen momento para salir.';

  @override
  String get getReadyWeatherTipCool =>
      'Puede hacer un poco de frío – lleva una chaqueta ligera.';

  @override
  String get getReadyWeatherTipRain =>
      'Se espera lluvia – mejor llevar paraguas.';

  @override
  String get getReadyChecklistTitle => 'Qué llevar';

  @override
  String get getReadyItemWallet => 'Cartera y forma de pago';

  @override
  String get getReadyItemPhoneCharged => 'Móvil con batería cargada';

  @override
  String get getReadyItemReusableBag => 'Bolsa o recipiente reutilizable';

  @override
  String get getReadyItemShoes => 'Zapatos cómodos para caminar';

  @override
  String get getReadyItemWater => 'Botella de agua';

  @override
  String get getReadyItemId => 'DNI / tarjeta de transporte si hace falta';

  @override
  String get getReadyReminderTitle => 'Recuérdame cuándo salir';

  @override
  String get getReadyReminderSubtitle =>
      'Te avisaremos unos minutos antes de la hora de salida.';

  @override
  String get getReadyQuickActions => 'Acciones rápidas';

  @override
  String get getReadyQuickShare => 'Compartir';

  @override
  String get getReadyQuickCalendar => 'Calendario';

  @override
  String get getReadyQuickParking => 'Parking';

  @override
  String get getReadyPrimaryCta => '¡Estoy listo/a! 🚀';

  @override
  String get getReadyLetsGo => '¡Vamos!';

  @override
  String get getReadyAdventureStartsIn => 'La aventura empieza en…';

  @override
  String get getReadyHours => 'HORAS';

  @override
  String get getReadyMins => 'MIN';

  @override
  String get getReadyRoute => 'Ruta';

  @override
  String get getReadyYourAdventureEnergy => 'Tu energía aventurera';

  @override
  String get getReadyBoostEnergyHint =>
      'Marca los puntos para subir tu energía.';

  @override
  String get getReadyPackEssentials => 'Prepara lo esencial';

  @override
  String get getReadyVibePlaylist => 'Playlist de ambiente';

  @override
  String getReadyGetInMood(String mood) {
    return '¡Entra en modo $mood!';
  }

  @override
  String getReadyPlaylistLabel(String theme) {
    return 'Happy $theme Beats';
  }

  @override
  String get getReadyPlay => 'Reproducir';

  @override
  String get getReadyNudgeMe => '¡Avísame cuando sea la hora!';

  @override
  String getReadyReminderAt(String time) {
    return 'Te avisaremos a las $time';
  }

  @override
  String get getReadyCantWait => '¡Qué ganas de ver qué descubres!';

  @override
  String noPlanDayOpen(String city) {
    return 'Tu día en $city está abierto. ¿Quieres que prepare un plan, o buscas una vibra específica?';
  }

  @override
  String get noPlanPlanMyWholeDay => '✨ Planear mi día completo';

  @override
  String get noPlanFindMeCoffee => '☕ Encuentra café para mí';

  @override
  String get noPlanGetMeMoving => '🏃 Ponme en movimiento';

  @override
  String get noPlanJustChat => 'Solo charlar';

  @override
  String get noPlanPlanLater => 'Quizás más tarde';

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
    return '$title saved for later!';
  }

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
  String get myDayHeroActiveSubtitle => 'Estás en esta actividad ahora mismo.';

  @override
  String get myDayUnableLoadActivities =>
      'No se pudieron cargar las actividades';

  @override
  String get navMyDay => 'Mi Día';

  @override
  String get navExplore => 'Explorar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get myDayWeekendEmptyTitle => '¡Tu fin de semana aún está vacío!';

  @override
  String get myDayWeekendEmptySubtitle =>
      '¿Quieres planear el sábado o el domingo con antelación?';

  @override
  String myDayWeekendSaturdayShort(String day) {
    return 'Sáb $day';
  }

  @override
  String myDayWeekendSundayShort(String day) {
    return 'Dom $day';
  }

  @override
  String placeCardFailedToShare(String error) {
    return 'Error al compartir: $error';
  }

  @override
  String placeCardSaved(String name) {
    return '¡$name guardado!';
  }

  @override
  String placeCardFailedToggleSave(String name) {
    return 'No se pudo actualizar el guardado de $name';
  }

  @override
  String placeDetailSavedToFavorites(String name) {
    return '¡$name guardado en favoritos!';
  }

  @override
  String get placeDetailSaveToggleFailed =>
      'No se pudo actualizar el lugar guardado';

  @override
  String placeDetailCouldNotOpenMaps(String error) {
    return 'No se pudieron abrir los mapas: $error';
  }

  @override
  String get bookingSavedViewMyBookings =>
      '¡Reserva guardada! Ver en Mis Reservas';

  @override
  String get bookingViewAction => 'Ver';

  @override
  String bookingErrorSaving(String error) {
    return 'Error al guardar la reserva: $error';
  }

  @override
  String get gygCodeCopied => 'Código copiado 💚';

  @override
  String get socialNewMessageComingSoon =>
      '¡La función de nuevos mensajes llegará pronto!';

  @override
  String get socialSearchMessagesHint => 'Buscar mensajes';

  @override
  String get socialCallComingSoon => '¡La función de llamada llegará pronto!';

  @override
  String get socialVideoCallComingSoon => '¡La videollamada llegará pronto!';

  @override
  String get socialPhotoSharingComingSoon => '¡Compartir fotos llegará pronto!';

  @override
  String get socialTypeMessageHint => 'Escribe un mensaje...';

  @override
  String get socialReportUser => 'Reportar usuario';

  @override
  String get socialBlockUser => 'Bloquear usuario';

  @override
  String get socialShareProfile => 'Compartir perfil';

  @override
  String socialMessageTraveler(String name) {
    return 'Mensaje a $name';
  }

  @override
  String get socialWriteMessageHint => 'Escribe tu mensaje...';

  @override
  String socialMessageSentTo(String name) {
    return '¡Mensaje enviado a $name!';
  }

  @override
  String get socialSend => 'Enviar';

  @override
  String get socialUserReportedThankYou =>
      'Usuario reportado. Gracias por ayudar a mantener segura la comunidad.';

  @override
  String socialUserBlocked(String name) {
    return '$name ha sido bloqueado/a.';
  }

  @override
  String socialProfileShared(String name) {
    return '¡Perfil de $name compartido!';
  }

  @override
  String get socialSavedPostsUnavailable =>
      'Las publicaciones guardadas aún no están disponibles.';

  @override
  String get socialCloseFriendsUnavailable =>
      'Close friends aún no está disponible.';

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
      'You do not have any planned activities in your agenda yet';

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
  String get signupNoPasswordNeeded => 'Sin contraseña ✨';

  @override
  String get signupRatingBadge => '⭐ 4,9/5 · Gratis · Sin contraseña';

  @override
  String get signupPrivacyPrefix => 'Al continuar, aceptas nuestra ';

  @override
  String get signupPrivacyLinkLabel => 'política de privacidad';

  @override
  String get signupSuccessCheckInbox => '¡Revisa tu bandeja! 📬';

  @override
  String get signupSuccessWeSentTo => 'Enviamos un enlace a';

  @override
  String get signupOpenGmail => 'Abrir Gmail';

  @override
  String get signupOpenOutlook => 'Abrir Outlook';

  @override
  String get signupOpenAppleMail => 'Abrir Apple Mail';

  @override
  String get signupOpenEmailApp => 'Abrir app de correo';

  @override
  String get signupNoEmailReceived => '¿No recibiste el correo?';

  @override
  String get signupWrongEmailAddress => '¿Dirección incorrecta?';

  @override
  String get introHeadline1 => 'Tu mood,';

  @override
  String get introHeadline2 => 'tu aventura';

  @override
  String get demoModeLabel => '▶ Modo demo';

  @override
  String get demoSkip => 'Omitir';

  @override
  String get demoTapToChooseMood => 'Toca para elegir tu mood:';

  @override
  String get demoDiscoverMore => 'Descubrir más →';

  @override
  String get demoMoodyQuestion =>
      'Te ayudo a descubrir lugares increíbles según cómo te sientes. ¿Cuál es tu mood hoy?';

  @override
  String get demoUserReplyRelaxed => 'Me siento relajado';

  @override
  String get demoUserReplyAdventurous => 'Me siento aventurero';

  @override
  String get demoUserReplyRomantic => 'Me siento romántico';

  @override
  String get demoUserReplyCultural => 'Me siento cultural';

  @override
  String get demoUserReplyFoodie => 'Me siento como un foodie';

  @override
  String get demoUserReplySocial => 'Me siento social';

  @override
  String get demoUserReplyDefault => '¡Este es mi mood!';

  @override
  String get dayMon => 'Lunes';

  @override
  String get dayTue => 'Martes';

  @override
  String get dayWed => 'Miércoles';

  @override
  String get dayThu => 'Jueves';

  @override
  String get dayFri => 'Viernes';

  @override
  String get daySat => 'Sábado';

  @override
  String get daySun => 'Domingo';

  @override
  String get monthJan => 'ene';

  @override
  String get monthFeb => 'feb';

  @override
  String get monthMar => 'mar';

  @override
  String get monthApr => 'abr';

  @override
  String get monthMay => 'may';

  @override
  String get monthJun => 'jun';

  @override
  String get monthJul => 'jul';

  @override
  String get monthAug => 'ago';

  @override
  String get monthSep => 'sep';

  @override
  String get monthOct => 'oct';

  @override
  String get monthNov => 'nov';

  @override
  String get monthDec => 'dic';

  @override
  String get myDayEmptyDayTitle => 'Tu día está vacío ✨';

  @override
  String get myDayEmptyDaySubtitle =>
      'Deja que Moody haga un plan para tu mood de hoy';

  @override
  String get myDayPlanWithMoodyButton => 'Planificar mi día con Moody';

  @override
  String get myDayExploreActivitiesButton => 'Explorar actividades';

  @override
  String get myDayExploreNearbyButton => 'Explorar cerca';

  @override
  String get myDayAskMoodyButton => 'Preguntar a Moody';

  @override
  String get myDayGetReadyButton => 'Prepararse';

  @override
  String get myDayRightNow => 'AHORA';

  @override
  String get myDayStatusError => '⚠️ ERROR';

  @override
  String get myDayStatusUnableToLoad => 'No se puede cargar';

  @override
  String get myDayOpenGoogleMaps => 'Google Maps';

  @override
  String get myDayOpenAppleMaps => 'Apple Maps';

  @override
  String get agendaTitle => 'Mi Agenda';

  @override
  String get agendaStatusCancelled => 'CANCELADO';

  @override
  String get agendaTodayEmpty => 'Hoy está vacío';

  @override
  String get agendaTodaySubtitle =>
      'Deja que Moody planifique tu día según tu mood';

  @override
  String get agendaTomorrowEmpty => 'Mañana está libre';

  @override
  String get agendaTomorrowSubtitle => 'Planifica lo que quieres hacer mañana';

  @override
  String agendaDayEmpty(String dayName) {
    return '$dayName está vacío';
  }

  @override
  String agendaDaySubtitle(String dayName) {
    return '¿Quieres planificar para $dayName?';
  }

  @override
  String get agendaFarFutureEmpty => 'Nada planificado aún';

  @override
  String get agendaFarFutureSubtitle => 'Planifica actividades para este día';

  @override
  String get agendaPlanWithMoody => 'Planificar con Moody';

  @override
  String get agendaAddActivity => 'Agregar actividad';

  @override
  String get agendaUntitledActivity => 'Actividad sin título';

  @override
  String get agendaNoDescription => 'Sin descripción disponible';

  @override
  String get agendaLocationTBD => 'Ubicación por definir';

  @override
  String get exploreCategoryAll => 'Todo';

  @override
  String get exploreCategoryPopular => 'Popular';

  @override
  String get exploreCategoryAccommodations => 'Alojamientos';

  @override
  String get exploreCategoryNature => 'Naturaleza';

  @override
  String get exploreCategoryCulture => 'Cultura';

  @override
  String get exploreCategoryFood => 'Comida';

  @override
  String get exploreCategoryActivities => 'Actividades';

  @override
  String get exploreCategoryHistory => 'Historia';

  @override
  String get exploreFilterAdditionalOptions => 'Opciones adicionales';

  @override
  String get exploreFilterParking => 'Estacionamiento';

  @override
  String get exploreFilterTransport => 'Transporte';

  @override
  String get exploreFilterCreditCards => 'Tarjetas de crédito';

  @override
  String get exploreFilterWifi => 'Wi-Fi';

  @override
  String get exploreFilterCharging => 'Carga';

  @override
  String get exploreFilterInstagrammable => 'Para Instagram';

  @override
  String get exploreFilterArtisticDesign => 'Diseño artístico';

  @override
  String get exploreFilterAestheticSpaces => 'Espacios estéticos';

  @override
  String get exploreFilterScenicViews => 'Vistas panorámicas';

  @override
  String get exploreFilterBestAtNight => 'Mejor de noche';

  @override
  String get exploreFilterBestAtSunset => 'Mejor al atardecer';

  @override
  String get exploreNoPlacesOnMap => 'No hay lugares en el mapa';

  @override
  String get timeLabelToday => 'Hoy';

  @override
  String get timeLabelTomorrow => 'Mañana';

  @override
  String get timeLabelMorning => 'Mañana';

  @override
  String get timeLabelAfternoon => 'Tarde';

  @override
  String get timeLabelEvening => 'Noche';

  @override
  String get exploreFilterIndoorOnly => 'Solo interior';

  @override
  String get exploreFilterOutdoorOnly => 'Solo exterior';

  @override
  String get exploreFilterWeatherSafe => 'A salvo del clima';

  @override
  String get exploreFilterOpenNow => 'Abierto ahora';

  @override
  String get exploreFilterQuiet => 'Tranquilo';

  @override
  String get exploreFilterLively => 'Animado';

  @override
  String get exploreFilterRomanticVibe => 'Ambiente romántico';

  @override
  String get exploreFilterSurpriseMe => 'Sorpréndeme';

  @override
  String get exploreFilterVegan => 'Vegano';

  @override
  String get exploreFilterVegetarian => 'Vegetariano';

  @override
  String get exploreFilterHalal => 'Halal';

  @override
  String get exploreFilterGlutenFree => 'Sin gluten';

  @override
  String get exploreFilterPescatarian => 'Pescatariano';

  @override
  String get exploreFilterNoAlcohol => 'Sin alcohol';

  @override
  String get exploreFilterWheelchairAccessible =>
      'Accesible en silla de ruedas';

  @override
  String get exploreFilterLgbtqFriendly => 'LGBTQ+ amigable';

  @override
  String get exploreFilterSeniorFriendly => 'Apto para mayores';

  @override
  String get exploreFilterBabyFriendly => 'Apto para bebés';

  @override
  String get exploreFilterBlackOwned => 'Black-owned';

  @override
  String get exploreFilterPriceRange => 'Rango de precio (€)';

  @override
  String get exploreFilterMaxDistance => 'Distancia máxima (km)';

  @override
  String get chatSheetMoodyName => 'Moody';

  @override
  String get chatSheetErrorMessage =>
      '¡Vaya! Tengo problemas de conexión ahora mismo. ¿Puedes intentarlo de nuevo? 🤔';

  @override
  String get chatSheetEmptyStateBody =>
      '¡Conozco la ciudad como la palma de mi mano! Dime tu mood y crearé el día perfecto para ti. Ya sea aventurero, romántico o relajado - ¡te tengo cubierto! 🎯';

  @override
  String get chatSheetCraftingMessage =>
      'Moody está preparando algo especial...';

  @override
  String get chatSheetInputHint => '¿Cuál es tu mood hoy?';

  @override
  String get moodyConversationGreeting =>
      '¡Hola! ¿Cómo te sientes hoy? Puedo sugerirte actividades según tu mood.';

  @override
  String get moodyConversationTalkToMoody => 'Hablar con Moody';

  @override
  String get moodyConversationSpeaking => 'Hablando...';

  @override
  String get moodyConversationListening => 'Escuchando...';

  @override
  String get moodyConversationThinking => 'Pensando...';

  @override
  String get moodyConversationTypeMessage => 'Escribe tu mensaje...';

  @override
  String get homeSelectLocation => 'Seleccionar ubicación';

  @override
  String get homeCurrentLocation => 'Ubicación actual';

  @override
  String get homeUsingGps => 'Usando GPS';

  @override
  String get homeGettingLocation => 'Obteniendo ubicación...';

  @override
  String homeLocationResult(String location) {
    return 'Ubicación: $location';
  }

  @override
  String get homeLocationNotFound => 'No se pudo obtener la ubicación';

  @override
  String get homeChatErrorRetry =>
      'Lo siento, no pude responder ahora. ¡Inténtalo de nuevo! 😅';

  @override
  String get checkInQ1Title => '¿Cómo estuvo tu día?';

  @override
  String get checkInQ1Subtitle => 'Moody quiere conocerte mejor 🌙';

  @override
  String get checkInQ1Question => '¿Cuál fue el mejor momento de hoy?';

  @override
  String get checkInQ1Activities => 'Las actividades 🎯';

  @override
  String get checkInQ1Friends => 'Con amigos 👥';

  @override
  String get checkInQ1Exploring => 'Explorar 🔍';

  @override
  String get checkInQ1Food => 'Comida y bebida 🍽';

  @override
  String get checkInQ1Relaxing => 'Relajarse 🛋';

  @override
  String get checkInMaybeLater => 'Quizás luego';

  @override
  String checkInQ2Question(String name) {
    return '¿Valió la pena $name?';
  }

  @override
  String get checkInQ2Amazing => '¡Increíble! 🤩';

  @override
  String get checkInQ2Good => 'Bien 👍';

  @override
  String get checkInQ2Ok => 'Estuvo bien';

  @override
  String get checkInQ2NotForMe => 'No es para mí';

  @override
  String get checkInQ3Question => '¿Cómo te sientes ahora?';

  @override
  String get checkInQ3Happy => 'Feliz';

  @override
  String get checkInQ3Relaxed => 'Relajado';

  @override
  String get checkInQ3Tired => 'Cansado';

  @override
  String get checkInQ3Mixed => 'Mixto';

  @override
  String get checkInDoneTitle => '¡Gracias! Hasta mañana 🌟';

  @override
  String get checkInDoneSubtitle => 'Moody recordará esto para la próxima vez';

  @override
  String get checkInSaveError => 'Error al guardar. Inténtalo de nuevo.';

  @override
  String get checkInClose => 'Cerrar';

  @override
  String get dagSheetOpener1 => '¡Estás en casa! ¿Cómo estuvo tu día?';

  @override
  String get dagSheetOpener2 => '¡Cuéntame! ¿Cómo estuvo hoy?';

  @override
  String get dagSheetOpener3 => '¿Cómo fue hoy?';

  @override
  String get dagSheetOpener4 => 'Moody tiene curiosidad — ¿cómo estuvo tu día?';

  @override
  String get dagSheetE1Amazing => '¡Increíble! 🤩';

  @override
  String get dagSheetE1PrettyGood => 'Bastante bien 😊';

  @override
  String get dagSheetE1Okay => 'Más o menos 😐';

  @override
  String get dagSheetE1Letdown => 'Decepcionante 😔';

  @override
  String get dagSheetFollowupAmazing =>
      '¡Genial! ¿Cuál fue el mejor momento? 🌟';

  @override
  String get dagSheetFollowupPrettyGood =>
      '¡Bien! ¿Algo que realmente destacó?';

  @override
  String get dagSheetFollowupOkay =>
      'Respuesta honesta. ¿Qué podría haber sido mejor?';

  @override
  String get dagSheetFollowupLetdown => 'Qué lástima... ¿Qué salió mal?';

  @override
  String get dagSheetFollowupDefault => '¡Cuéntame más! ✨';

  @override
  String get dagSheetE2Activities => 'Las actividades 🎯';

  @override
  String get dagSheetE2People => 'Con gente 👥';

  @override
  String get dagSheetE2Exploring => 'El explorar 🔍';

  @override
  String get dagSheetE2Food => 'Buena comida 🍽';

  @override
  String get dagSheetE2Relaxing => 'Simplemente relajarse 🛋';

  @override
  String get dagSheetE2Unexpected => 'Algo inesperado ✨';

  @override
  String get dagSheetClosing1 => 'Bien hecho hoy. Buenas noches 🌙';

  @override
  String get dagSheetClosing2 =>
      'Moody lo recordará para mañana. ¡Hasta entonces! ✨';

  @override
  String get dagSheetClosing3 =>
      'Gracias por compartir. Mañana será otro día especial 🌟';

  @override
  String get dagSheetClosing4 => 'Que descanses. Mañana lo haremos especial 🌙';

  @override
  String get dagSheetReflectionPrompt =>
      '¿Algo más que quieras compartir? Todo vale — o déjalo vacío y descansa. ✨';

  @override
  String get dagSheetReflectionHint => 'Escribe aquí… (opcional)';

  @override
  String get dagSheetGoodnight => 'Buenas noches Moody 🌙';

  @override
  String carouselPerfectMatches(String count) {
    return '$count coincidencias perfectas';
  }

  @override
  String get carouselRefreshing => 'Actualizando recomendaciones...';

  @override
  String get carouselTopPick => 'TOP ELECCIÓN';

  @override
  String get carouselTellMeMore => 'Cuéntame más';

  @override
  String get carouselAddToDay => 'Añadir al día';

  @override
  String get carouselDirections => 'Cómo llegar';

  @override
  String get carouselShare => 'Compartir';

  @override
  String get carouselDetails => 'Detalles';

  @override
  String get carouselSaveForLater => 'Guardar para después';

  @override
  String get carouselNotInterested => 'No me interesa';

  @override
  String get carouselNoRecommendations => 'Sin recomendaciones aún';

  @override
  String get carouselCheckBackSoon =>
      '¡Vuelve pronto para sugerencias personalizadas!';

  @override
  String get prefBack => 'Atrás';

  @override
  String get interestsPrompt => '¿Qué te gusta? ¡Lo busco para ti! 🔍';

  @override
  String get interestsTitle => '¿Cuáles son tus intereses?';

  @override
  String get interestsSubtitle => 'Elige todo lo que te llame la atención.';

  @override
  String get interestsMultipleChoice => 'Múltiples opciones posibles';

  @override
  String get interestsContinue => 'Continuar →';

  @override
  String get interestFoodDining => 'Comida y bebida';

  @override
  String get interestArtsCulture => 'Arte y cultura';

  @override
  String get interestShoppingMarkets => 'Compras y mercados';

  @override
  String get interestSports => 'Deporte y actividades';

  @override
  String get interestNatureOutdoors => 'Naturaleza y parques';

  @override
  String get interestNightlife => 'Vida nocturna';

  @override
  String get interestCoffeeCafes => 'Cafés';

  @override
  String get interestPhotographySpots => 'Fotografía y lugares';

  @override
  String get prefTravelProfileTitle => 'Tu perfil de viaje';

  @override
  String get prefSocialVibeLabel => 'Vibe social 👥';

  @override
  String get prefPaceLabel => 'Ritmo de planificación ⚡';

  @override
  String get prefStyleLabel => 'Tu estilo 🌟';

  @override
  String prefStyleLimit(String count) {
    return 'Elige hasta $count estilos que te encajen.';
  }

  @override
  String get prefMoodySpeech =>
      '¡Solo unas preguntas más y te conoceré completamente! ✈️';

  @override
  String get prefSocialSoloTitle => 'Aventuras en solitario';

  @override
  String get prefSocialSoloHint => 'Tiempo para mí';

  @override
  String get prefSocialSmallTitle => 'Grupos pequeños';

  @override
  String get prefSocialSmallHint => 'Ambiente íntimo';

  @override
  String get prefSocialButterflyTitle => 'Mariposa social';

  @override
  String get prefSocialButterflyHint => 'Conocer gente nueva';

  @override
  String get prefSocialMoodTitle => 'Según el momento';

  @override
  String get prefSocialMoodHint => 'A veces solo, a veces social';

  @override
  String get prefPaceNow => 'Ahora mismo ⚡';

  @override
  String get prefPaceToday => 'Hoy 📅';

  @override
  String get prefPacePlanned => 'Planificado 🗓';

  @override
  String get prefStyleLocalTitle => 'Experiencia local';

  @override
  String get prefStyleLocalSubtitle =>
      'Auténtico y fuera de las rutas habituales.';

  @override
  String get prefStyleLuxuryTitle => 'Buscador de lujo';

  @override
  String get prefStyleLuxurySubtitle => 'Comodidad y experiencias especiales.';

  @override
  String get prefStyleBudgetTitle => 'Consciente del presupuesto';

  @override
  String get prefStyleBudgetSubtitle => 'Máxima diversión, gasto inteligente.';

  @override
  String get prefStyleOffTitle => 'Fuera de lo común';

  @override
  String get prefStyleOffSubtitle => 'Joyas escondidas y favoritos locales.';

  @override
  String get prefStyleTouristTitle => 'Principales atracciones turísticas';

  @override
  String get prefStyleTouristSubtitle => 'Lugares icónicos que debes ver.';

  @override
  String get gamificationTitle => 'Logros';

  @override
  String get gamificationYourProgress => 'Tu progreso';

  @override
  String get gamificationCompleteToUnlock =>
      'Completa actividades para desbloquear logros';

  @override
  String get gamificationUnlocked => 'Desbloqueado';

  @override
  String get gamificationInProgress => 'En progreso';

  @override
  String get gamificationLocked => 'Bloqueado';

  @override
  String gamificationUnlockedOn(String date) {
    return 'Desbloqueado el $date';
  }

  @override
  String get gamificationClose => 'Cerrar';

  @override
  String get gamificationCategoryExploration => 'Exploración';

  @override
  String get gamificationCategoryActivities => 'Actividades';

  @override
  String get gamificationCategorySocial => 'Social';

  @override
  String get gamificationCategoryStreaks => 'Rachas';

  @override
  String get gamificationCategoryMood => 'Estado de ánimo';

  @override
  String get gamificationCategorySpecial => 'Especial';

  @override
  String get gamificationCategoryOther => 'Otros';

  @override
  String get prefScreenTitle => 'Tus preferencias';

  @override
  String get prefSave => 'Guardar';

  @override
  String get prefSavedSuccess => 'Preferencias guardadas';

  @override
  String get prefSaveError => 'Error al guardar';

  @override
  String get prefSectionAgeGroup => 'Grupo de edad';

  @override
  String get prefSectionAgeGroupSub =>
      'Nos ayuda a recomendar actividades apropiadas para tu edad';

  @override
  String get prefSectionBudget => 'Presupuesto';

  @override
  String get prefSectionBudgetSub =>
      'Tu rango de gasto típico para actividades';

  @override
  String get prefSectionSocialVibeSub =>
      '¿Prefieres actividades en solitario o escenas sociales?';

  @override
  String get prefSectionActivityPace => 'Ritmo de actividad';

  @override
  String get prefSectionActivityPaceSub =>
      '¿Qué tan activo quieres que sea tu día?';

  @override
  String get prefSectionTimeAvailable => 'Tiempo disponible';

  @override
  String get prefSectionTimeAvailableSub =>
      '¿Cuánto tiempo sueles tener para las actividades?';

  @override
  String get prefSectionInterests => 'Tus intereses';

  @override
  String get prefSectionInterestsSub => 'Selecciona todo lo que aplique';

  @override
  String get prefAge1824Label => 'Principios de los 20';

  @override
  String get prefAge1824Desc => 'Económico, social';

  @override
  String get prefAge2534Label => '20s-30s';

  @override
  String get prefAge2534Desc => 'Moderno, aventurero';

  @override
  String get prefAge3544Label => '30s-40s';

  @override
  String get prefAge3544Desc => 'Experiencias de calidad';

  @override
  String get prefAge4554Label => '40s-50s';

  @override
  String get prefAge4554Desc => 'Refinado, relajado';

  @override
  String get prefAge55Label => '55+';

  @override
  String get prefAge55Desc => 'Cultural, pintoresco';

  @override
  String get prefBudgetLabel => 'Económico';

  @override
  String get prefBudgetDesc => 'Gratis - 20€';

  @override
  String get prefModerateLabel => 'Moderado';

  @override
  String get prefModerateDesc => '20€ - 50€';

  @override
  String get prefUpscaleLabel => 'De lujo';

  @override
  String get prefUpscaleDesc => '50€ - 100€';

  @override
  String get prefLuxuryLabel => 'Lujo';

  @override
  String get prefLuxuryDesc => '100€+';

  @override
  String get prefSoloLabel => 'Apto para solitarios';

  @override
  String get prefSoloDesc => 'Tranquilo, en paz, tiempo para mí';

  @override
  String get prefSmallGroupLabel => 'Grupos pequeños';

  @override
  String get prefSmallGroupDesc => 'Reuniones íntimas y acogedoras';

  @override
  String get prefMixLabel => 'Mezcla de ambos';

  @override
  String get prefMixDesc => 'Flexible, variado';

  @override
  String get prefSocialSceneLabel => 'Escena social';

  @override
  String get prefSocialSceneDesc => 'Animado, conocer gente';

  @override
  String get prefSlowChillLabel => 'Tranquilo y relajado';

  @override
  String get prefSlowChillDesc => 'Sin prisas';

  @override
  String get prefModerateActivityLabel => 'Moderado';

  @override
  String get prefModerateActivityDesc => 'Ritmo equilibrado';

  @override
  String get prefActiveLabel => 'Activo';

  @override
  String get prefActiveDesc => 'Enérgico, siempre en marcha';

  @override
  String get prefQuickVisitLabel => 'Visita rápida';

  @override
  String get prefHalfDayLabel => 'Medio día';

  @override
  String get prefFullDayLabel => 'Día completo';

  @override
  String get prefInterestCulture => 'Cultura y arte';

  @override
  String get prefInterestNature => 'Naturaleza y aire libre';

  @override
  String get prefInterestNightlife => 'Vida nocturna';

  @override
  String get prefInterestWellness => 'Bienestar';

  @override
  String get prefInterestAdventure => 'Aventura';

  @override
  String get prefInterestHistory => 'Historia';

  @override
  String get achievementsUnlocked => 'Logros desbloqueados';

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get deleteAccountAreYouSure => '¿Estás seguro?';

  @override
  String get deleteAccountWarning =>
      'Esta acción no se puede deshacer. Todos tus datos, actividades y preferencias se eliminarán de forma permanente.';

  @override
  String get deleteAccountWhatWillBeDeleted => 'Lo que se eliminará:';

  @override
  String get deleteAccountProfile => 'Tu perfil y preferencias';

  @override
  String get deleteAccountActivities => 'Todas las actividades guardadas';

  @override
  String get deleteAccountAchievements => 'Tus logros y progreso';

  @override
  String get deleteAccountPhotos => 'Todas las fotos y recuerdos';

  @override
  String get deleteAccountTypeToConfirm => 'Escribe \"DELETE\" para confirmar';

  @override
  String get deleteAccountTypeIncorrect =>
      'Por favor escribe DELETE para confirmar';

  @override
  String get deleteAccountFinalTitle => 'Confirmación final';

  @override
  String get deleteAccountFinalContent =>
      'Esta acción no se puede deshacer. Todos tus datos se eliminarán de forma permanente.';

  @override
  String get deleteAccountCancel => 'Cancelar';

  @override
  String get deleteAccountDeleteForever => 'Eliminar para siempre';

  @override
  String get deleteAccountDeleteButton => 'Eliminar mi cuenta para siempre';

  @override
  String get deleteAccountSuccess => 'Cuenta eliminada correctamente';

  @override
  String get deleteAccountError => 'Error al eliminar la cuenta';

  @override
  String get placeDetailAboutThisPlace => 'Sobre este lugar';

  @override
  String get placeDetailGoodToKnow => 'Bueno saber';

  @override
  String get placeDetailDurationLabel => 'Duración';

  @override
  String get placeDetailPriceLabel => 'Precio';

  @override
  String get placeDetailDistanceLabel => 'Distancia';

  @override
  String get placeDetailBestTimeLabel => 'Mejor hora';

  @override
  String get placeDetailGoodWithLabel => 'Bien con';

  @override
  String get placeDetailEnergyLabel => 'Energía';

  @override
  String get placeDetailTimeNeededLabel => 'Tiempo necesario';

  @override
  String get placeDetailNoPhotos => 'No hay fotos disponibles';

  @override
  String get placeDetailNoReviews => 'No hay reseñas disponibles';

  @override
  String get placeDetailReviewsWhenAvailable =>
      'Las reseñas aparecerán aquí cuando estén disponibles';

  @override
  String get placeDetailNotFound => 'Lugar no encontrado';

  @override
  String get placeDetailOpenMaps => 'Abrir mapas';

  @override
  String get placeDetailCheckLocally => 'Comprobar localmente';

  @override
  String get placeDetailFreeToVisit => 'Entrada gratuita';

  @override
  String get placeDetailVaries => 'Varía';

  @override
  String get placeDetailFreeEntry => 'Entrada libre';

  @override
  String get placeDetailEvening => 'Tarde/noche';

  @override
  String get placeDetailMorning => 'Mañana';

  @override
  String get placeDetailAfternoon => 'Tarde';

  @override
  String get placeDetailAnytime => 'Cualquier momento';

  @override
  String get placeDetailGoodFitForTonight => 'Buena opción para esta noche';

  @override
  String get placeDetailBestOnWeekends => 'Mejor los fines de semana';

  @override
  String get placeDetailSkipIfChill => 'Evitar si buscas algo tranquilo';

  @override
  String get placeDetailClosedCheckHours =>
      'Cerrado ahora — consulta el horario';

  @override
  String get placeDetailFriendsGroups => 'Amigos / Grupos';

  @override
  String get placeDetailSoloDate => 'Solo / Cita';

  @override
  String get placeDetailSoloFriends => 'Solo / Amigos';

  @override
  String get placeDetailAnonymous => 'Anónimo';

  @override
  String get placeDetailRecently => 'Recientemente';

  @override
  String get moodyHubYourDayToday => 'Tu día hoy';

  @override
  String get moodyHubChangeMood => 'Cambiar estado de ánimo';

  @override
  String get moodyHubNoMoodChosen => 'Aún no has elegido un estado de ánimo';

  @override
  String get moodyHubJourneyPrefix => 'Tu energía hoy: ';

  @override
  String get moodyHubJourneySuffix => '';

  @override
  String get moodyHubFallbackAiMessage =>
      'Tu día está listo — Moody está aquí para ti 🌟';

  @override
  String get moodyHubActivitySingular => 'actividad';

  @override
  String get moodyHubActivityPlural => 'actividades';

  @override
  String get moodyHubPlanForWhen => '¿Para cuándo planeas?';
}
