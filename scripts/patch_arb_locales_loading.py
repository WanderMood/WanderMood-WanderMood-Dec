#!/usr/bin/env python3
"""Insert same keys as app_en.arb (after loadingFact7) into nl, de, fr, es ARB files."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = {
    "nl": ROOT / "lib/l10n/app_nl.arb",
    "de": ROOT / "lib/l10n/app_de.arb",
    "fr": ROOT / "lib/l10n/app_fr.arb",
    "es": ROOT / "lib/l10n/app_es.arb",
}

# Translated strings only (same keys as app_en patch); @metadata blocks identical to en.
BLOCKS = {
    "nl": r'''
  "weatherCurrentLocation": "Huidige locatie",
  "loadingFactNl0": "Nederland heeft meer musea per vierkante kilometer dan welk land ook!",
  "loadingFactNl1": "Rotterdam heeft de grootste haven van Europa, met jaarlijks meer dan 400 miljoen ton vracht!",
  "loadingFactNl2": "Nederland heeft meer dan 35.000 kilometer fietspaden – genoeg om de aarde te omcirkelen!",
  "loadingFactNl3": "Amsterdam heeft meer grachten dan Venetië en meer bruggen dan Parijs!",
  "loadingFactNl4": "Nederlanders eten jaarlijks meer dan 150 miljoen stroopwafels!",
  "loadingFactNl5": "Nederland is 's werelds op één na grootste exporteur van voedsel, ondanks het kleine oppervlak!",
  "loadingFactNl6": "Keukenhof toont meer dan 7 miljoen bloembollen op 32 hectare!",
  "loadingFactNl7": "Nederlanders zijn gemiddeld het langst ter wereld – rond 1,80 m!",
  "loadingFactUs0": "De VS hebben 63 nationale parken, van Yellowstone tot de Grand Canyon!",
  "loadingFactUs1": "Alaska heeft meer dan 3 miljoen meren en meer dan 100.000 gletsjers!",
  "loadingFactUs2": "Het Interstate Highway System in de VS is meer dan 75.000 km lang!",
  "loadingFactUs3": "Times Square in New York trekt jaarlijks meer dan 50 miljoen bezoekers!",
  "loadingFactUs4": "De VS hebben 's werelds grootste economie en Silicon Valley!",
  "loadingFactUs5": "Hawaï is de enige Amerikaanse staat met commerciële koffieteelt!",
  "loadingFactUs6": "De Golden Gate Bridge in San Francisco is geschilderd in International Orange!",
  "loadingFactUs7": "Disney World in Florida is groter dan de stad San Francisco!",
  "loadingFactJp0": "Japan telt meer dan 6.800 eilanden, maar slechts 430 zijn bewoond!",
  "loadingFactJp1": "De Japanse Shinkansen kan snelheden tot 320 km/u halen!",
  "loadingFactJp2": "De Fuji is een actieve vulkaan die voor het laatst uitbarstte in 1707!",
  "loadingFactJp3": "Japan heeft meer dan 100.000 tempels en schrijnen!",
  "loadingFactJp4": "Tokio is 's werelds grootste metropool met meer dan 37 miljoen inwoners!",
  "loadingFactJp5": "Japan consumeert ongeveer 80% van 's werelds blauwvintonijn!",
  "loadingFactJp6": "In Japan staat er gemiddeld elke 23 mensen een automaat!",
  "loadingFactJp7": "Het kersenbloesemseizoen trekt elk voorjaar miljoenen bezoekers!",
  "loadingFactUk0": "Het VK heeft meer dan 1.500 kastelen, van middeleeuwse forten tot koninklijke residenties!",
  "loadingFactUk1": "Big Ben is niet de naam van de klokkentoren – dat is Elizabeth Tower!",
  "loadingFactUk2": "Het VK leverde per hoofd meer wereldberoemde muzikanten dan welk land ook!",
  "loadingFactUk3": "Stonehenge is meer dan 5.000 jaar oud en blijft mysterieus!",
  "loadingFactUk4": "De London Underground is 's werelds oudste metro, geopend in 1863!",
  "loadingFactUk5": "Het VK heeft 15 UNESCO-werelderfgoederen, waaronder Bath en Edinburgh!",
  "loadingFactUk6": "Schotland heeft meer dan 3.000 kastelen en zo'n 790 eilanden!",
  "loadingFactUk7": "Britten drinken dagelijks zo'n 100 miljoen koppen thee!",
  "loadingFactDe0": "Duitsland heeft meer dan 25.000 kastelen en paleizen!",
  "loadingFactDe1": "De Berlijnse Muur was 155 km lang en stond 28 jaar!",
  "loadingFactDe2": "Oktoberfest begint vaak al in september!",
  "loadingFactDe3": "Het Zwarte Woud inspireerde veel sprookjes van de gebroeders Grimm!",
  "loadingFactDe4": "Op ruim 60% van de Autobahn geldt vaak geen algemene snelheidslimiet!",
  "loadingFactDe5": "Neuschwanstein was inspiratie voor het kasteel van Doornroosje bij Disney!",
  "loadingFactDe6": "Duitsland heeft de grootste economie van Europa en staat bekend om techniek!",
  "loadingFactDe7": "De Rijn stroomt door Duitsland en is bezaaid met middeleeuwse kastelen!",
  "loadingFactFr0": "Frankrijk is 's werelds meest bezochte land met jaarlijks meer dan 89 miljoen toeristen!",
  "loadingFactFr1": "De Eiffeltoren werd oorspronkelijk als tijdelijk bouwwerk voor de Wereldtentoonstelling van 1889 gebouwd!",
  "loadingFactFr2": "Frankrijk produceert meer dan 400 kazen – voor elke dag één!",
  "loadingFactFr3": "Paleis Versailles heeft 2.300 kamers en 67 trappenhuizen!",
  "loadingFactFr4": "Frankrijk heeft 44 UNESCO-werelderfgoederen, waaronder Mont-Saint-Michel!",
  "loadingFactFr5": "Het Louvre is 's werelds grootste kunstmuseum!",
  "loadingFactFr6": "De Côte d'Azur strekt zich honderden kilometers langs de Middellandse Zee uit!",
  "loadingFactFr7": "Frankrijk is het thuis van de beroemdste wielerkoers: de Tour de France!",
  "guestPlaceDistanceKm": "{km} km",
  "@guestPlaceDistanceKm": {
    "placeholders": {
      "km": {
        "type": "String"
      }
    }
  },
  "guestPlaceHoursRange": "{start} – {end}",
  "@guestPlaceHoursRange": {
    "placeholders": {
      "start": {
        "type": "String"
      },
      "end": {
        "type": "String"
      }
    }
  },
  "prefSocialVibeTitleFallback": "Wat is je sociale vibe? 👥",
  "prefSocialVibeSubtitleFallback": "Hoe ontdek je de wereld het liefst?",
  "prefPlanningPaceTitleFallback": "Vertel over je tempo ⏰",
  "prefPlanningPaceSubtitleFallback": "Jouw planningsstijl",
  "prefTravelStyleTitleFallback": "Tot slot! ✨",
  "prefTravelStyleSubtitleFallback": "Wat is je travel style?",
  "prefStartMyJourney": "Start mijn reis",
  "onboardingPagerSlide1Title": "Maak kennis met Moody 😄",
  "onboardingPagerSlide1Subtitle": "Je travel BFF 💬🌍",
  "onboardingPagerSlide1Description": "Moody leert je vibe, energie en hoe je dag voelt kennen. Daarmee maak ik persoonlijke plannen – speciaal voor jou. Zie me als je nieuwsgierige maatje die altijd wil ontdekken 🌆🎈",
  "onboardingPagerSlide2Title": "Reizen met mood 🌈",
  "onboardingPagerSlide2Subtitle": "Je gevoel, jouw reis 💭",
  "onboardingPagerSlide2Description": "Of je nu rustig, romantisch of avontuurlijk bent... vertel hoe je je voelt, dan maak ik persoonlijke plannen 🌸🏞️\nVan verborgen parels tot zonsondergangwandelingen – eerst jouw mood, altijd.",
  "onboardingPagerSlide3Title": "Jouw dag, jouw manier 🫶🏾",
  "onboardingPagerSlide3Subtitle": "Van zonsopgang tot laat op de avond ☀️🌙",
  "onboardingPagerSlide3Description": "Je plan bestaat uit momenten—ochtend, middag, avond en nacht. Kies je vibe, je favorieten, ik regel de magie. 🧭🎯 Alles op basis van locatie, tijd, weer & mood.",
  "onboardingPagerSlide4Title": "Elke dag een mood 🎨",
  "onboardingPagerSlide4Subtitle": "Ontdek nieuwe plekken – elke dag🌍",
  "onboardingPagerSlide4Description": "WanderMood maakt elke dag een nieuw avontuur. Word wakker, check je vibe, ontdek handgepickte activiteiten 💡📍 Laat je mood de weg wijzen – keer op keer."
''',
    "de": r'''
  "weatherCurrentLocation": "Aktueller Standort",
  "loadingFactNl0": "Die Niederlande haben mehr Museen pro Quadratkilometer als jedes andere Land!",
  "loadingFactNl1": "Rotterdam beherbergt Europas größten Hafen – über 400 Millionen Tonnen Fracht jährlich!",
  "loadingFactNl2": "In den Niederlanden gibt es über 35.000 km Radwege – genug, um die Erde zu umrunden!",
  "loadingFactNl3": "Amsterdam hat mehr Grachten als Venedig und mehr Brücken als Paris!",
  "loadingFactNl4": "Die Niederländer essen jährlich über 150 Millionen Stroopwafels!",
  "loadingFactNl5": "Die Niederlande sind trotz der Größe der zweitgrößte Lebensmittelexporteur der Welt!",
  "loadingFactNl6": "Keukenhof zeigt über 7 Millionen Blumenzwiebeln auf 32 Hektar!",
  "loadingFactNl7": "Die Niederländer sind durchschnittlich die größten Menschen der Welt!",
  "loadingFactUs0": "Die USA haben 63 Nationalparks – von Yellowstone bis zum Grand Canyon!",
  "loadingFactUs1": "Alaska hat über 3 Millionen Seen und über 100.000 Gletscher!",
  "loadingFactUs2": "Das US-Interstate-System ist über 75.000 km lang!",
  "loadingFactUs3": "Der Times Square in NYC zählt jährlich über 50 Millionen Besucher!",
  "loadingFactUs4": "Die USA haben die größte Volkswirtschaft der Welt und Silicon Valley!",
  "loadingFactUs5": "Hawaii ist der einzige US-Bundesstaat mit kommerziellem Kaffeeanbau!",
  "loadingFactUs6": "Die Golden Gate Bridge ist in „International Orange“ gestrichen!",
  "loadingFactUs7": "Disney World in Florida ist größer als die Stadt San Francisco!",
  "loadingFactJp0": "Japan hat über 6.800 Inseln, aber nur 430 sind bewohnt!",
  "loadingFactJp1": "Der Shinkansen kann über 300 km/h erreichen!",
  "loadingFactJp2": "Der Fuji ist ein aktiver Vulkan – zuletzt 1707 ausgebrochen!",
  "loadingFactJp3": "Japan hat über 100.000 Tempel und Schreine!",
  "loadingFactJp4": "Tokio ist mit über 37 Millionen Menschen die größte Metropolregion der Welt!",
  "loadingFactJp5": "Japan verbraucht etwa 80 % des weltweiten Thunfischfangs (Blauflossen-Thun)!",
  "loadingFactJp6": "In Japan gibt es etwa einen Automaten pro 23 Einwohner!",
  "loadingFactJp7": "Die Kirschblütenzeit zieht jeden Frühling Millionen Besucher an!",
  "loadingFactUk0": "Das UK hat über 1.500 Schlösser – von Burgen bis königlichen Residenzen!",
  "loadingFactUk1": "„Big Ben“ ist nicht der Name des Turms – offiziell heißt er Elizabeth Tower!",
  "loadingFactUk2": "Das UK hat pro Kopf besonders viele weltberühmte Musiker hervorgebracht!",
  "loadingFactUk3": "Stonehenge ist über 5.000 Jahre alt und voller Geheimnisse!",
  "loadingFactUk4": "Die London Underground ist die älteste U-Bahn der Welt (seit 1863)!",
  "loadingFactUk5": "Das UK hat 15 UNESCO-Welterbestätten, u. a. Bath und Edinburgh!",
  "loadingFactUk6": "Schottland hat über 3.000 Schlösser und rund 790 Inseln!",
  "loadingFactUk7": "Die Briten trinken täglich etwa 100 Millionen Tassen Tee!",
  "loadingFactDe0": "Deutschland hat über 25.000 Schlösser und Paläste!",
  "loadingFactDe1": "Die Berliner Mauer war 155 km lang und stand 28 Jahre!",
  "loadingFactDe2": "Das Oktoberfest beginnt oft schon im September!",
  "loadingFactDe3": "Der Schwarzwald inspirierte viele Märchen der Brüder Grimm!",
  "loadingFactDe4": "Auf etwa 60 % der Autobahnen gibt es oft kein generelles Tempolimit!",
  "loadingFactDe5": "Neuschwanstein inspirierte Disneys Dornröschen-Schloss!",
  "loadingFactDe6": "Deutschland hat die größte Volkswirtschaft Europas und ist für Ingenieurskunst bekannt!",
  "loadingFactDe7": "Der Rhein fließt durch Deutschland und ist gesäumt von mittelalterlichen Burgen!",
  "loadingFactFr0": "Frankreich ist das meistbesuchte Land der Welt – über 89 Mio. Touristen jährlich!",
  "loadingFactFr1": "Der Eiffelturm wurde ursprünglich als temporäres Bauwerk für die Weltausstellung 1889 gebaut!",
  "loadingFactFr2": "Frankreich produziert über 400 Käsesorten – für jeden Tag einen!",
  "loadingFactFr3": "Schloss Versailles hat 2.300 Räume und 67 Treppenhäuser!",
  "loadingFactFr4": "Frankreich hat 44 UNESCO-Welterbestätten, u. a. Mont-Saint-Michel!",
  "loadingFactFr5": "Der Louvre ist das größte Kunstmuseum der Welt!",
  "loadingFactFr6": "Die Côte d’Azur erstreckt sich hunderte Kilometer am Mittelmeer!",
  "loadingFactFr7": "Frankreich ist die Heimat der berühmtesten Radtour: der Tour de France!",
  "guestPlaceDistanceKm": "{km} km",
  "@guestPlaceDistanceKm": {
    "placeholders": {
      "km": {
        "type": "String"
      }
    }
  },
  "guestPlaceHoursRange": "{start} – {end}",
  "@guestPlaceHoursRange": {
    "placeholders": {
      "start": {
        "type": "String"
      },
      "end": {
        "type": "String"
      }
    }
  },
  "prefSocialVibeTitleFallback": "Wie ist deine Social-Vibe? 👥",
  "prefSocialVibeSubtitleFallback": "Wie erlebst du die Welt am liebsten?",
  "prefPlanningPaceTitleFallback": "Erzähl mir von deinem Tempo ⏰",
  "prefPlanningPaceSubtitleFallback": "Dein Planungsstil",
  "prefTravelStyleTitleFallback": "Zu guter Letzt! ✨",
  "prefTravelStyleSubtitleFallback": "Was ist dein Reisestil?",
  "prefStartMyJourney": "Meine Reise starten",
  "onboardingPagerSlide1Title": "Lerne Moody kennen 😄",
  "onboardingPagerSlide1Subtitle": "Dein Travel-BFF 💬🌍",
  "onboardingPagerSlide1Description": "Moody lernt deine Vibes, deine Energie und deinen Tag kennen. Daraus entstehen persönliche Pläne – nur für dich. Stell dir mich als neugierigen Kumpel vor, der immer Lust auf Entdecken hat 🌆🎈",
  "onboardingPagerSlide2Title": "Reisen nach Mood 🌈",
  "onboardingPagerSlide2Subtitle": "Dein Gefühl, deine Reise 💭",
  "onboardingPagerSlide2Description": "Ob ruhig, romantisch oder abenteuerlustig – sag mir, wie du dich fühlst, und ich erstelle persönliche Pläne 🌸🏞️\nVon Geheimtipps bis Sonnenuntergangs-Spaziergängen – zuerst dein Mood, immer.",
  "onboardingPagerSlide3Title": "Dein Tag, dein Weg 🫶🏾",
  "onboardingPagerSlide3Subtitle": "Vom Sonnenaufgang bis spät in die Nacht ☀️🌙",
  "onboardingPagerSlide3Description": "Dein Plan ist in Momente geteilt – Morgen, Mittag, Abend und Nacht. Wähle deine Vibes und Favoriten, ich kümmere mich um die Magie. 🧭🎯 Basierend auf Ort, Zeit, Wetter & Mood.",
  "onboardingPagerSlide4Title": "Jeder Tag ein Mood 🎨",
  "onboardingPagerSlide4Subtitle": "Neue Orte entdecken – jeden Tag🌍",
  "onboardingPagerSlide4Description": "WanderMood macht jeden Tag zum Abenteuer. Wach auf, check deine Vibe, entdecke handverlesene Aktivitäten 💡📍 Lass deinen Mood den Weg weisen – immer wieder."
''',
    "fr": r'''
  "weatherCurrentLocation": "Position actuelle",
  "loadingFactNl0": "Les Pays-Bas ont plus de musées par kilomètre carré que tout autre pays !",
  "loadingFactNl1": "Rotterdam abrite le plus grand port d'Europe, avec plus de 400 millions de tonnes de fret par an !",
  "loadingFactNl2": "Les Pays-Bas comptent plus de 35 000 km de pistes cyclables – assez pour faire le tour de la Terre !",
  "loadingFactNl3": "Amsterdam a plus de canaux que Venise et plus de ponts que Paris !",
  "loadingFactNl4": "Les Néerlandais consomment plus de 150 millions de stroopwafels par an !",
  "loadingFactNl5": "Les Pays-Bas sont le 2e exportateur mondial d'aliments malgré leur petite taille !",
  "loadingFactNl6": "Keukenhof expose plus de 7 millions de bulbes sur 32 hectares !",
  "loadingFactNl7": "Les Néerlandais sont en moyenne les plus grands au monde !",
  "loadingFactUs0": "Les États-Unis comptent 63 parcs nationaux, de Yellowstone au Grand Canyon !",
  "loadingFactUs1": "L'Alaska a plus de 3 millions de lacs et plus de 100 000 glaciers !",
  "loadingFactUs2": "Le réseau Interstate américain dépasse 75 000 km !",
  "loadingFactUs3": "Times Square à New York accueille plus de 50 millions de visiteurs par an !",
  "loadingFactUs4": "Les États-Unis ont la plus grande économie du monde et Silicon Valley !",
  "loadingFactUs5": "Hawaï est le seul État américain à produire du café commercialement !",
  "loadingFactUs6": "Le Golden Gate est peint en « International Orange » !",
  "loadingFactUs7": "Disney World en Floride est plus grand que la ville de San Francisco !",
  "loadingFactJp0": "Le Japon compte plus de 6 800 îles, mais seulement 430 sont habitées !",
  "loadingFactJp1": "Le Shinkansen peut dépasser 300 km/h !",
  "loadingFactJp2": "Le mont Fuji est un volcan actif ; dernière éruption en 1707 !",
  "loadingFactJp3": "Le Japon a plus de 100 000 temples et sanctuaires !",
  "loadingFactJp4": "Tokyo est la plus grande aire urbaine au monde – plus de 37 millions d'habitants !",
  "loadingFactJp5": "Le Japon consomme environ 80 % du thon rouge mondial !",
  "loadingFactJp6": "Au Japon, il y a environ un distributeur pour 23 habitants !",
  "loadingFactJp7": "La floraison des cerisiers attire des millions de visiteurs chaque printemps !",
  "loadingFactUk0": "Le Royaume-Uni compte plus de 1 500 châteaux, des forteresses aux résidences royales !",
  "loadingFactUk1": "« Big Ben » n'est pas le nom de la tour – c'est Elizabeth Tower !",
  "loadingFactUk2": "Le Royaume-Uni a produit plus de musiciens mondialement célèbres par habitant !",
  "loadingFactUk3": "Stonehenge a plus de 5 000 ans et reste mystérieux !",
  "loadingFactUk4": "Le métro de Londres est le plus ancien au monde (1863) !",
  "loadingFactUk5": "Le Royaume-Uni compte 15 sites UNESCO, dont Bath et Édimbourg !",
  "loadingFactUk6": "L'Écosse a plus de 3 000 châteaux et environ 790 îles !",
  "loadingFactUk7": "Les Britanniques boivent environ 100 millions de tasses de thé par jour !",
  "loadingFactDe0": "L'Allemagne compte plus de 25 000 châteaux et palais !",
  "loadingFactDe1": "Le mur de Berlin mesurait 155 km et a duré 28 ans !",
  "loadingFactDe2": "L'Oktoberfest commence souvent en septembre !",
  "loadingFactDe3": "La Forêt-Noire a inspiré de nombreux contes des frères Grimm !",
  "loadingFactDe4": "Environ 60 % des autoroutes allemandes n'ont souvent pas de limite générale !",
  "loadingFactDe5": "Neuschwanstein a inspiré le château de la Belle au bois dormant !",
  "loadingFactDe6": "L'Allemagne a la plus grande économie d'Europe et est réputée en ingénierie !",
  "loadingFactDe7": "Le Rhin traverse l'Allemagne et est bordé de châteaux médiévaux !",
  "loadingFactFr0": "La France est le pays le plus visité au monde – plus de 89 millions de touristes par an !",
  "loadingFactFr1": "La tour Eiffel fut d'abord un ouvrage temporaire pour l'Exposition de 1889 !",
  "loadingFactFr2": "La France produit plus de 400 fromages – un pour chaque jour de l'année !",
  "loadingFactFr3": "Le château de Versailles compte 2 300 pièces et 67 escaliers !",
  "loadingFactFr4": "La France compte 44 sites UNESCO, dont le Mont-Saint-Michel !",
  "loadingFactFr5": "Le Louvre est le plus grand musée d'art du monde !",
  "loadingFactFr6": "La Côte d'Azur s'étire sur des centaines de km en Méditerranée !",
  "loadingFactFr7": "La France accueille la course cycliste la plus célèbre : le Tour de France !",
  "guestPlaceDistanceKm": "{km} km",
  "@guestPlaceDistanceKm": {
    "placeholders": {
      "km": {
        "type": "String"
      }
    }
  },
  "guestPlaceHoursRange": "{start} – {end}",
  "@guestPlaceHoursRange": {
    "placeholders": {
      "start": {
        "type": "String"
      },
      "end": {
        "type": "String"
      }
    }
  },
  "prefSocialVibeTitleFallback": "Quelle est ta vibe sociale ? 👥",
  "prefSocialVibeSubtitleFallback": "Comment aimes-tu vivre les choses ?",
  "prefPlanningPaceTitleFallback": "Parle-moi de ton rythme ⏰",
  "prefPlanningPaceSubtitleFallback": "Ton style de planification",
  "prefTravelStyleTitleFallback": "Dernière étape ! ✨",
  "prefTravelStyleSubtitleFallback": "Quel est ton style de voyage ?",
  "prefStartMyJourney": "Commencer mon voyage",
  "onboardingPagerSlide1Title": "Rencontre Moody 😄",
  "onboardingPagerSlide1Subtitle": "Ton BFF voyage 💬🌍",
  "onboardingPagerSlide1Description": "Moody apprend ta vibe, ton énergie et comment se passe ta journée. J'en fais des plans perso rien que pour toi. Comme un pote curieux toujours partant pour explorer 🌆🎈",
  "onboardingPagerSlide2Title": "Voyager selon ton mood 🌈",
  "onboardingPagerSlide2Subtitle": "Tes émotions, ton voyage 💭",
  "onboardingPagerSlide2Description": "Que tu sois calme, romantique ou aventureux… dis-moi comment tu te sens et je crée des plans perso 🌸🏞️\nDes pépites aux balades au coucher du soleil – le mood d'abord, toujours.",
  "onboardingPagerSlide3Title": "Ta journée, à ta façon 🫶🏾",
  "onboardingPagerSlide3Subtitle": "Du lever au soir ☀️🌙",
  "onboardingPagerSlide3Description": "Ton plan est découpé en moments—matin, après-midi, soir et nuit. Choisis ta vibe, tes favoris, je gère la magie. 🧭🎯 Selon le lieu, l'heure, la météo & ton mood.",
  "onboardingPagerSlide4Title": "Chaque jour a son mood 🎨",
  "onboardingPagerSlide4Subtitle": "Découvre de nouveaux lieux – chaque jour🌍",
  "onboardingPagerSlide4Description": "WanderMood rend chaque jour aventureux. Réveille-toi, check ton vibe, explore des activités triées sur le volet 💡📍 Laisse ton mood guider – encore et encore."
''',
    "es": r'''
  "weatherCurrentLocation": "Ubicación actual",
  "loadingFactNl0": "¡Países Bajos tiene más museos por kilómetro cuadrado que ningún otro país!",
  "loadingFactNl1": "¡Róterdam alberga el puerto más grande de Europa, con más de 400 millones de toneladas al año!",
  "loadingFactNl2": "¡Hay más de 35.000 km de carriles bici – suficiente para rodear la Tierra!",
  "loadingFactNl3": "¡Ámsterdam tiene más canales que Venecia y más puentes que París!",
  "loadingFactNl4": "¡Los neerlandeses comen más de 150 millones de stroopwafels al año!",
  "loadingFactNl5": "¡Países Bajos es el segundo mayor exportador de alimentos del mundo a pesar de su tamaño!",
  "loadingFactNl6": "¡Keukenhof muestra más de 7 millones de bulbos en 32 hectáreas!",
  "loadingFactNl7": "¡Los neerlandeses son de media los más altos del mundo!",
  "loadingFactUs0": "¡EE. UU. tiene 63 parques nacionales, de Yellowstone al Gran Cañón!",
  "loadingFactUs1": "¡Alaska tiene más de 3 millones de lagos y más de 100.000 glaciares!",
  "loadingFactUs2": "¡La red interestatal supera los 75.000 km!",
  "loadingFactUs3": "¡Times Square recibe más de 50 millones de visitas al año!",
  "loadingFactUs4": "¡EE. UU. tiene la mayor economía del mundo y Silicon Valley!",
  "loadingFactUs5": "¡Hawái es el único estado que cultiva café comercialmente!",
  "loadingFactUs6": "¡El Golden Gate está pintado en «International Orange»!",
  "loadingFactUs7": "¡Disney World en Florida es más grande que la ciudad de San Francisco!",
  "loadingFactJp0": "¡Japón tiene más de 6.800 islas, pero solo 430 están habitadas!",
  "loadingFactJp1": "¡El Shinkansen puede superar los 300 km/h!",
  "loadingFactJp2": "¡El Fuji es un volcán activo; última erupción en 1707!",
  "loadingFactJp3": "¡Japón tiene más de 100.000 templos y santuarios!",
  "loadingFactJp4": "¡Tokio es el área metropolitana más grande del mundo, con más de 37 millones de personas!",
  "loadingFactJp5": "¡Japón consume cerca del 80 % del atún rojo mundial!",
  "loadingFactJp6": "¡En Japón hay una máquina expendedora por cada 23 personas!",
  "loadingFactJp7": "¡La floración del cerezo atrae millones de visitantes cada primavera!",
  "loadingFactUk0": "¡El Reino Unido tiene más de 1.500 castillos, de fortalezas a residencias reales!",
  "loadingFactUk1": "¡«Big Ben» no es el nombre de la torre – es Elizabeth Tower!",
  "loadingFactUk2": "¡El Reino Unido ha dado más músicos famosos por habitante!",
  "loadingFactUk3": "¡Stonehenge tiene más de 5.000 años y sigue siendo un misterio!",
  "loadingFactUk4": "¡El metro de Londres es el más antiguo del mundo (1863)!",
  "loadingFactUk5": "¡El Reino Unido tiene 15 sitios UNESCO, incluidos Bath y Edimburgo!",
  "loadingFactUk6": "¡Escocia tiene más de 3.000 castillos y unas 790 islas!",
  "loadingFactUk7": "¡Los británicos beben unos 100 millones de tazas de té al día!",
  "loadingFactDe0": "¡Alemania tiene más de 25.000 castillos y palacios!",
  "loadingFactDe1": "¡El muro de Berlín medía 155 km y duró 28 años!",
  "loadingFactDe2": "¡El Oktoberfest a menudo empieza en septiembre!",
  "loadingFactDe3": "¡La Selva Negra inspiró muchos cuentos de los hermanos Grimm!",
  "loadingFactDe4": "¡En un ~60 % de autopistas alemanas a menudo no hay límite general!",
  "loadingFactDe5": "¡Neuschwanstein inspiró el castillo de la Bella Durmiente de Disney!",
  "loadingFactDe6": "¡Alemania tiene la mayor economía de Europa y fama de ingeniería!",
  "loadingFactDe7": "¡El Rin atraviesa Alemania y está lleno de castillos medievales!",
  "loadingFactFr0": "¡Francia es el país más visitado del mundo – más de 89 millones de turistas al año!",
  "loadingFactFr1": "¡La Torre Eiffel fue al principio una estructura temporal para la Expo de 1889!",
  "loadingFactFr2": "¡Francia produce más de 400 quesos – ¡uno para cada día!",
  "loadingFactFr3": "¡Versalles tiene 2.300 habitaciones y 67 escaleras!",
  "loadingFactFr4": "¡Francia tiene 44 sitios UNESCO, incluido Mont-Saint-Michel!",
  "loadingFactFr5": "¡El Louvre es el museo de arte más grande del mundo!",
  "loadingFactFr6": "¡La Costa Azul se extiende cientos de km por el Mediterráneo!",
  "loadingFactFr7": "¡Francia acoge la carrera ciclista más famosa: el Tour de Francia!",
  "guestPlaceDistanceKm": "{km} km",
  "@guestPlaceDistanceKm": {
    "placeholders": {
      "km": {
        "type": "String"
      }
    }
  },
  "guestPlaceHoursRange": "{start} – {end}",
  "@guestPlaceHoursRange": {
    "placeholders": {
      "start": {
        "type": "String"
      },
      "end": {
        "type": "String"
      }
    }
  },
  "prefSocialVibeTitleFallback": "¿Cuál es tu vibe social? 👥",
  "prefSocialVibeSubtitleFallback": "¿Cómo te gusta vivir las cosas?",
  "prefPlanningPaceTitleFallback": "Cuéntame tu ritmo ⏰",
  "prefPlanningPaceSubtitleFallback": "Tu estilo de planificación",
  "prefTravelStyleTitleFallback": "¡Por último! ✨",
  "prefTravelStyleSubtitleFallback": "¿Cuál es tu estilo de viaje?",
  "prefStartMyJourney": "Empezar mi viaje",
  "onboardingPagerSlide1Title": "Conoce a Moody 😄",
  "onboardingPagerSlide1Subtitle": "Tu BFF de viaje 💬🌍",
  "onboardingPagerSlide1Description": "Moody aprende tu vibe, tu energía y cómo va tu día. Con eso creo planes personalizados solo para ti. Piensa en mí como tu colega curioso que siempre quiere explorar 🌆🎈",
  "onboardingPagerSlide2Title": "Viaja con tu mood 🌈",
  "onboardingPagerSlide2Subtitle": "Tus emociones, tu viaje 💭",
  "onboardingPagerSlide2Description": "Ya sea tranquilo, romántico o aventurero… dime cómo te sientes y haré planes personalizados 🌸🏞️\nDesde joyas ocultas hasta paseos al atardecer: primero tu mood, siempre.",
  "onboardingPagerSlide3Title": "Tu día, a tu manera 🫶🏾",
  "onboardingPagerSlide3Subtitle": "Del amanecer hasta la noche ☀️🌙",
  "onboardingPagerSlide3Description": "Tu plan se divide en momentos—mañana, tarde, noche. Elige tu vibe, tus favoritos, yo me encargo de la magia. 🧭🎯 Según lugar, hora, clima y mood.",
  "onboardingPagerSlide4Title": "Cada día es un mood 🎨",
  "onboardingPagerSlide4Subtitle": "Descubre sitios nuevos cada día🌍",
  "onboardingPagerSlide4Description": "WanderMood hace que cada día sea una aventura. Despierta, revisa tu vibe, explora actividades escogidas a mano 💡📍 Deja que tu mood marque el camino una y otra vez."
''',
}

def patch(locale: str) -> None:
    path = FILES[locale]
    text = path.read_text(encoding="utf-8")
    block = BLOCKS[locale].lstrip("\n")
    if block.endswith("\n"):
        block = block[:-1]
    if not block.endswith(","):
        block += ","
    needle = '  "loadingFact7": '
    # Find loadingFact7 line per file
    import re
    m = re.search(r'  "loadingFact7": "[^"]*",\s*\n', text)
    if not m:
        raise SystemExit(f"loadingFact7 not found in {path}")
    end = m.end()
    # Find next line after loadingFact7 blank line + dayPlan
    rest = text[end:]
    if not rest.lstrip().startswith('"dayPlanTodayItinerary"'):
        raise SystemExit(f"Unexpected content after loadingFact7 in {locale}")
    # Skip leading whitespace/newlines in rest
    idx = end
    while idx < len(text) and text[idx] in " \n":
        idx += 1
    new_text = text[:end] + "\n" + block + "\n" + text[idx:]
    path.write_text(new_text, encoding="utf-8")
    print("patched", path)


def main():
    for loc in BLOCKS:
        patch(loc)


if __name__ == "__main__":
    main()
