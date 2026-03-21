#!/usr/bin/env python3
"""Insert loading country facts + related keys into app_en.arb after loadingFact7."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARB = ROOT / "lib/l10n/app_en.arb"

INSERT = r'''
  "weatherCurrentLocation": "Current location",
  "loadingFactNl0": "The Netherlands has more museums per square mile than any other country!",
  "loadingFactNl1": "Rotterdam is home to Europe's largest port, handling over 400 million tons of cargo annually!",
  "loadingFactNl2": "The Netherlands has over 35,000 kilometers of bike paths - enough to circle the Earth!",
  "loadingFactNl3": "Amsterdam has more canals than Venice and more bridges than Paris!",
  "loadingFactNl4": "The Dutch consume over 150 million stroopwafels every year!",
  "loadingFactNl5": "The Netherlands is the world's second-largest exporter of food despite its small size!",
  "loadingFactNl6": "Keukenhof Gardens displays over 7 million flower bulbs across 32 hectares!",
  "loadingFactNl7": "The Dutch are the tallest people in the world with an average height of 6 feet!",
  "loadingFactUs0": "The US has 63 national parks, from Yellowstone to the Grand Canyon!",
  "loadingFactUs1": "Alaska has more than 3 million lakes and over 100,000 glaciers!",
  "loadingFactUs2": "The US Interstate Highway System spans over 47,000 miles!",
  "loadingFactUs3": "Times Square in NYC is visited by over 50 million people annually!",
  "loadingFactUs4": "The US has the world's largest economy and is home to Silicon Valley!",
  "loadingFactUs5": "Hawaii is the only US state that commercially grows coffee!",
  "loadingFactUs6": "The Golden Gate Bridge in San Francisco is painted International Orange!",
  "loadingFactUs7": "Disney World in Florida is larger than the city of San Francisco!",
  "loadingFactJp0": "Japan has over 6,800 islands, but only 430 are inhabited!",
  "loadingFactJp1": "The Japanese Shinkansen bullet trains can reach speeds of 200 mph!",
  "loadingFactJp2": "Mount Fuji is actually an active volcano that last erupted in 1707!",
  "loadingFactJp3": "Japan has more than 100,000 temples and shrines!",
  "loadingFactJp4": "Tokyo is the world's largest metropolitan area with over 37 million people!",
  "loadingFactJp5": "Japan consumes about 80% of the world's bluefin tuna!",
  "loadingFactJp6": "The Japanese love vending machines - there's one for every 23 people!",
  "loadingFactJp7": "Cherry blossom season in Japan attracts millions of visitors each spring!",
  "loadingFactUk0": "The UK has over 1,500 castles, from medieval fortresses to royal residences!",
  "loadingFactUk1": "London's Big Ben is not actually the name of the clock tower - it's Elizabeth Tower!",
  "loadingFactUk2": "The UK has produced more world-famous musicians per capita than any other country!",
  "loadingFactUk3": "Stonehenge is over 5,000 years old and still shrouded in mystery!",
  "loadingFactUk4": "The London Underground is the world's oldest subway system, opened in 1863!",
  "loadingFactUk5": "The UK has 15 UNESCO World Heritage Sites including Bath and Edinburgh!",
  "loadingFactUk6": "Scotland has over 3,000 castles and about 790 islands!",
  "loadingFactUk7": "The British drink about 100 million cups of tea every day!",
  "loadingFactDe0": "Germany has over 25,000 castles and palaces scattered across the country!",
  "loadingFactDe1": "The Berlin Wall was 96 miles long and stood for 28 years!",
  "loadingFactDe2": "Germany is famous for Oktoberfest, which actually starts in September!",
  "loadingFactDe3": "The Black Forest region inspired many Brothers Grimm fairy tales!",
  "loadingFactDe4": "Germany has no general speed limit on about 60% of its Autobahn highways!",
  "loadingFactDe5": "Neuschwanstein Castle was the inspiration for Disney's Sleeping Beauty castle!",
  "loadingFactDe6": "Germany has the largest economy in Europe and is known for engineering!",
  "loadingFactDe7": "The Rhine River flows through Germany and is lined with medieval castles!",
  "loadingFactFr0": "France is the world's most visited country with over 89 million tourists annually!",
  "loadingFactFr1": "The Eiffel Tower was originally built as a temporary structure for the 1889 World's Fair!",
  "loadingFactFr2": "France produces over 400 types of cheese - one for every day of the year!",
  "loadingFactFr3": "The Palace of Versailles has 2,300 rooms and 67 staircases!",
  "loadingFactFr4": "France has 44 UNESCO World Heritage Sites, including Mont-Saint-Michel!",
  "loadingFactFr5": "The Louvre Museum is the world's largest art museum!",
  "loadingFactFr6": "The French Riviera stretches for 550 miles along the Mediterranean!",
  "loadingFactFr7": "France is home to the world's most famous bicycle race - the Tour de France!",
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
  "prefSocialVibeTitleFallback": "What's your social vibe? 👥",
  "prefSocialVibeSubtitleFallback": "How do you like to experience things?",
  "prefPlanningPaceTitleFallback": "Tell me your pace ⏰",
  "prefPlanningPaceSubtitleFallback": "Your planning style",
  "prefTravelStyleTitleFallback": "Last but not least! ✨",
  "prefTravelStyleSubtitleFallback": "What's your travel style?",
  "prefStartMyJourney": "Start My Journey",
  "onboardingPagerSlide1Title": "Meet Moody 😄",
  "onboardingPagerSlide1Subtitle": "Your travel BFF 💬🌍",
  "onboardingPagerSlide1Description": "Moody gets to know your vibe, your energy, and the kind of day you're having. With all that, I create personalized plans — made just for you. Think of me as your fun, curious bestie who's always down to explore 🌆🎈",
  "onboardingPagerSlide2Title": "Travel by Mood 🌈",
  "onboardingPagerSlide2Subtitle": "Your Feelings, Your Journey 💭",
  "onboardingPagerSlide2Description": "Whether you're in a peaceful, romantic, or adventurous mood... just tell me how you feel, and I'll create personalized plans 🌸🏞️\nFrom hidden gems to sunset strolls—mood first, always.",
  "onboardingPagerSlide3Title": "Your Day, Your Way 🫶🏾",
  "onboardingPagerSlide3Subtitle": "Sunrise to sunset, I've got you ☀️🌙",
  "onboardingPagerSlide3Description": "Your plan is broken into moments—morning, afternoon, evening, and night. Choose your vibe, pick your favorites, and I'll handle the magic. 🧭🎯 All based on location, time, weather & mood.",
  "onboardingPagerSlide4Title": "Every Day's a Mood 🎨",
  "onboardingPagerSlide4Subtitle": "Discover new places - every day🌍",
  "onboardingPagerSlide4Description": "WanderMood makes every day feel like a new adventure. Wake up, check your vibe, explore hand-picked activities 💡📍 Let your mood lead the way—again and again."
'''

def main():
    text = ARB.read_text(encoding="utf-8")
    needle = '  "loadingFact7": "The Sahara Desert is larger than the entire United States!",\n  "appSettings"'
    if needle not in text:
        raise SystemExit("needle not found in app_en.arb")
    block = INSERT.lstrip("\n")
    if block.endswith("\n"):
        block = block[:-1]
    if not block.endswith(","):
        block += ","
    text = text.replace(
        needle,
        '  "loadingFact7": "The Sahara Desert is larger than the entire United States!",\n'
        + block
        + "\n  \"appSettings\"",
    )
    ARB.write_text(text, encoding="utf-8")
    print("patched", ARB)


if __name__ == "__main__":
    main()
