"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  MockupBottomNav,
  MockupStatusBar,
  MockupTopBar,
} from "./MockupChrome";
import type { MockupLocale } from "./MockupChrome";
import {
  MOCK_IMG_COFFEE,
  MOCK_IMG_FOOD_MARKET,
  MOCK_IMG_MUSEUM,
  MOCK_IMG_PARK,
  MOCK_IMG_RESTAURANT,
  MOCK_IMG_WINE,
  MOCK_STORY_IMGS,
} from "./mockup-place-images";

/** 0 default, 1 foodie swap, 2 halal swap */
type MoodPhase = 0 | 1 | 2;

function normalizeLocale(locale?: string): MockupLocale {
  const l = (locale ?? "en").toLowerCase();
  if (l === "nl" || l === "en" || l === "de" || l === "es" || l === "fr") return l;
  return "en";
}

type ExploreCopy = {
  topTitle: string;
  chipMore: string;
  trending: string;
  trendingPill: string;
  addDay: string;
  moods: [string, string, string, string];
  filters: [string, string, string];
  places: [string, string, string];
  foodie: [string, string, string];
  halal: [string, string, string];
  distances: [string, string, string];
  ratings: [string, string, string];
  typesDefault: [string, string, string];
  typesFoodie: [string, string, string];
  typesHalal: [string, string, string];
  stories: [string, string, string, string, string];
};

const EXPLORE_TR: Record<MockupLocale, ExploreCopy> = {
  nl: {
    topTitle: "Ontdekken",
    chipMore: "Meer →",
    trending: "Trending op WanderMood",
    trendingPill: "🔥 Trending",
    addDay: "+ Dag",
    moods: ["Gezellig", "Foodie", "Cultureel", "Avontuurlijk"],
    filters: ["Halal", "Gezinsvriendelijk", "🐕 Honden"],
    places: ["Hopper Espresso Bar", "DEPOT Boijmans", "Kralingse Bos"],
    foodie: ["Bazar Rotterdam", "Fenix Food Factory", "De Biertuin"],
    halal: ["Sultan Falafel", "MADO Rotterdam", "Meraki Greek Grill"],
    distances: ["📍 8 min lopen", "🚲 12 min fietsen", "📍 15 min lopen"],
    ratings: ["★ 4.6", "★ 4.4", "★ 4.3"],
    typesDefault: ["Specialty coffee", "Museum", "Park"],
    typesFoodie: ["Foodhal", "Streetfood", "Wijnbar"],
    typesHalal: ["Halal", "Halal", "Halal"],
    stories: ["Hopper", "DEPOT", "Sobre", "Matcha bar", "Sportschool"],
  },
  en: {
    topTitle: "Explore",
    chipMore: "More →",
    trending: "Trending on WanderMood",
    trendingPill: "🔥 Trending",
    addDay: "+ Day",
    moods: ["Cozy", "Foodie", "Cultural", "Adventurous"],
    filters: ["Halal", "Family friendly", "🐕 Dogs"],
    places: ["Hopper Espresso Bar", "DEPOT Boijmans", "Kralingse Bos"],
    foodie: ["Bazar Rotterdam", "Fenix Food Factory", "De Biertuin"],
    halal: ["Sultan Falafel", "MADO Rotterdam", "Meraki Greek Grill"],
    distances: ["📍 8 min walk", "🚲 12 min bike", "📍 15 min walk"],
    ratings: ["★ 4.6", "★ 4.4", "★ 4.3"],
    typesDefault: ["Specialty coffee", "Museum", "Park"],
    typesFoodie: ["Food hall", "Streetfood", "Wine bar"],
    typesHalal: ["Halal", "Halal", "Halal"],
    stories: ["Hopper", "DEPOT", "Sobre", "Matcha bar", "Training floor"],
  },
  de: {
    topTitle: "Entdecken",
    chipMore: "Mehr →",
    trending: "Trending auf WanderMood",
    trendingPill: "🔥 Trending",
    addDay: "+ Tag",
    moods: ["Gemütlich", "Foodie", "Kulturell", "Abenteuerlich"],
    filters: ["Halal", "Familienfreundlich", "🐕 Hunde"],
    places: ["Hopper Espresso Bar", "DEPOT Boijmans", "Kralingse Bos"],
    foodie: ["Bazar Rotterdam", "Fenix Food Factory", "De Biertuin"],
    halal: ["Sultan Falafel", "MADO Rotterdam", "Meraki Greek Grill"],
    distances: ["📍 8 Min. Fußweg", "🚲 12 Min. Fahrrad", "📍 15 Min. Fußweg"],
    ratings: ["★ 4.6", "★ 4.4", "★ 4.3"],
    typesDefault: ["Specialty coffee", "Museum", "Park"],
    typesFoodie: ["Food-Halle", "Streetfood", "Weinbar"],
    typesHalal: ["Halal", "Halal", "Halal"],
    stories: ["Hopper", "DEPOT", "Sobre", "Matcha-Bar", "Gym"],
  },
  es: {
    topTitle: "Explorar",
    chipMore: "Más →",
    trending: "Tendencias en WanderMood",
    trendingPill: "🔥 Tendencia",
    addDay: "+ Día",
    moods: ["Acogedor", "Foodie", "Cultural", "Aventurero"],
    filters: ["Halal", "Familiar", "🐕 Perros"],
    places: ["Hopper Espresso Bar", "DEPOT Boijmans", "Kralingse Bos"],
    foodie: ["Bazar Rotterdam", "Fenix Food Factory", "De Biertuin"],
    halal: ["Sultan Falafel", "MADO Rotterdam", "Meraki Greek Grill"],
    distances: ["📍 8 min andando", "🚲 12 min bici", "📍 15 min andando"],
    ratings: ["★ 4.6", "★ 4.4", "★ 4.3"],
    typesDefault: ["Specialty coffee", "Museum", "Parque"],
    typesFoodie: ["Mercado", "Street food", "Bar de vinos"],
    typesHalal: ["Halal", "Halal", "Halal"],
    stories: ["Hopper", "DEPOT", "Sobre", "Matcha", "Gimnasio"],
  },
  fr: {
    topTitle: "Explorer",
    chipMore: "Plus →",
    trending: "Tendances sur WanderMood",
    trendingPill: "🔥 Tendance",
    addDay: "+ Jour",
    moods: ["Cosy", "Foodie", "Culturel", "Aventurier"],
    filters: ["Halal", "Famille", "🐕 Chiens"],
    places: ["Hopper Espresso Bar", "DEPOT Boijmans", "Kralingse Bos"],
    foodie: ["Bazar Rotterdam", "Fenix Food Factory", "De Biertuin"],
    halal: ["Sultan Falafel", "MADO Rotterdam", "Meraki Greek Grill"],
    distances: ["📍 8 min à pied", "🚲 12 min vélo", "📍 15 min à pied"],
    ratings: ["★ 4.6", "★ 4.4", "★ 4.3"],
    typesDefault: ["Specialty coffee", "Musée", "Parc"],
    typesFoodie: ["Hall gastronomique", "Street food", "Bar à vin"],
    typesHalal: ["Halal", "Halal", "Halal"],
    stories: ["Hopper", "DEPOT", "Sobre", "Matcha", "Salle de sport"],
  },
};

function namesForPhase(phase: MoodPhase, x: ExploreCopy): [string, string, string] {
  if (phase === 1) return x.foodie;
  if (phase === 2) return x.halal;
  return x.places;
}

function typesForPhase(phase: MoodPhase, x: ExploreCopy): [string, string, string] {
  if (phase === 1) return x.typesFoodie;
  if (phase === 2) return x.typesHalal;
  return x.typesDefault;
}

function imgsForPhase(phase: MoodPhase): [string, string, string] {
  if (phase === 1)
    return [MOCK_IMG_RESTAURANT, MOCK_IMG_FOOD_MARKET, MOCK_IMG_WINE];
  if (phase === 2)
    return [MOCK_IMG_RESTAURANT, MOCK_IMG_FOOD_MARKET, MOCK_IMG_RESTAURANT];
  return [MOCK_IMG_COFFEE, MOCK_IMG_MUSEUM, MOCK_IMG_PARK];
}

function PlacePhotoImg({ src }: { src: string }) {
  return (
    <img
      src={src}
      alt=""
      style={{
        width: "80px",
        height: "100%",
        objectFit: "cover",
        display: "block",
        flexShrink: 0,
        borderRadius: "14px 0 0 14px",
      }}
    />
  );
}

function StoryCircleImg({ src }: { src: string }) {
  return (
    <img
      src={src}
      alt=""
      className="wm-explore__storyImg"
      style={{
        width: "38px",
        height: "38px",
        objectFit: "cover",
        display: "block",
        borderRadius: "50%",
      }}
    />
  );
}

export function ExploreMockup({ locale }: { locale?: string }) {
  const loc = normalizeLocale(locale);
  const t = EXPLORE_TR[loc] ?? EXPLORE_TR.en;

  const root = useRef<HTMLDivElement>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [moodPhase, setMoodPhase] = useState<MoodPhase>(0);
  const [chipIdx, setChipIdx] = useState(0);
  const [filterHalal, setFilterHalal] = useState(false);
  const [shimmer, setShimmer] = useState(false);

  const clearT = () => {
    timers.current.forEach((id) => clearTimeout(id));
    timers.current = [];
  };

  const q = (fn: () => void, ms: number) => {
    timers.current.push(window.setTimeout(fn, ms));
  };

  const runRef = useRef<(() => void) | null>(null);

  const runCycle = useCallback(() => {
    clearT();
    setMoodPhase(0);
    setChipIdx(0);
    setFilterHalal(false);
    setShimmer(false);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 400);
    q(() => setStep(3), 900);
    q(() => setStep(4), 1400);
    q(() => setStep(5), 2000);
    q(() => setStep(6), 2500);
    q(() => setStep(7), 3000);
    q(() => setStep(8), 3400);
    q(() => {
      setChipIdx(1);
      setShimmer(true);
    }, 5000);
    q(() => setShimmer(false), 5600);
    q(() => setMoodPhase(1), 6500);
    q(() => {
      setFilterHalal(true);
      setShimmer(true);
    }, 9000);
    q(() => setShimmer(false), 9600);
    q(() => setMoodPhase(2), 10500);
    q(() => {
      setOn(false);
      setStep(0);
      setMoodPhase(0);
      setChipIdx(0);
      setFilterHalal(false);
    }, 15000);
    q(() => runRef.current?.(), 16700);
  }, []);

  useEffect(() => {
    runRef.current = runCycle;
  }, [runCycle]);

  useEffect(() => {
    const el = root.current;
    if (!el) return;
    const io = new IntersectionObserver(
      ([e]) => {
        inView.current = e.isIntersecting;
        if (!e.isIntersecting) {
          clearT();
          return;
        }
        if (document.visibilityState === "visible") {
          clearT();
          runCycle();
        }
      },
      { threshold: 0.22 },
    );
    io.observe(el);
    const onVis = () => {
      if (document.visibilityState !== "visible") clearT();
      else if (inView.current) {
        clearT();
        runCycle();
      }
    };
    document.addEventListener("visibilitychange", onVis);
    return () => {
      io.disconnect();
      document.removeEventListener("visibilitychange", onVis);
      clearT();
    };
  }, [runCycle]);

  useEffect(() => {
    const el = scrollRef.current;
    if (!el) return;
    if (!on) el.scrollTop = 0;
  }, [on]);

  useEffect(() => {
    if (!on || step < 8) return;
    const id = window.setTimeout(() => {
      const el = scrollRef.current;
      if (!el) return;
      const max = el.scrollHeight - el.clientHeight;
      if (max <= 8) return;
      el.scrollTo({ top: max, behavior: "smooth" });
    }, 220);
    return () => clearTimeout(id);
  }, [on, step, moodPhase, filterHalal, chipIdx, shimmer]);

  const names = useMemo(() => namesForPhase(moodPhase, t), [moodPhase, t]);
  const types = useMemo(() => typesForPhase(moodPhase, t), [moodPhase, t]);
  const cardImgs = useMemo(() => imgsForPhase(moodPhase), [moodPhase]);

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      data-phase={moodPhase}
      data-filter-halal={filterHalal ? "1" : "0"}
      data-chip={chipIdx}
      data-shimmer={shimmer ? "1" : "0"}
      className={`wm-mock wm-app wm-explore wm-explore--s${step} ${on ? "wm-mock--on" : ""}`}
    >
      <MockupStatusBar />
      <div className="wm-app__main">
        <div ref={scrollRef} className="wm-mock__scroll wm-explore__scroll">
          <MockupTopBar
            title={t.topTitle}
            right={
              <span className="wm-appTopBar__iconBtn" aria-hidden>
                ≡
              </span>
            }
          />

          <div className="wm-explore__chips">
            <span
              className={`wm-explore__chip ${chipIdx === 0 ? "wm-explore__chip--active" : ""}`}
            >
              ✨ {chipIdx === 0 ? `${t.moods[0]} ✓` : t.moods[0]}
            </span>
            <span
              className={`wm-explore__chip ${chipIdx === 1 ? "wm-explore__chip--activeFood" : ""}`}
            >
              🍽️ {chipIdx === 1 ? `${t.moods[1]} ✓` : t.moods[1]}
            </span>
            <span className="wm-explore__chip">🎭 {t.moods[2]}</span>
            <span className="wm-explore__chip">🚀 {t.moods[3]}</span>
            <span className="wm-explore__chip">{t.chipMore}</span>
          </div>

          <div className="wm-explore__filters">
            <span
              className={`wm-explore__filter ${filterHalal ? "wm-explore__filter--active" : ""}`}
            >
              {t.filters[0]}
            </span>
            <span className="wm-explore__filter">{t.filters[1]}</span>
            <span className="wm-explore__filter">{t.filters[2]}</span>
          </div>

          <div className="wm-explore__trend">
            <div className="wm-explore__storiesLabel">{t.trending}</div>
            <div className="wm-explore__stories">
              {MOCK_STORY_IMGS.map((src, i) => (
                <div key={src} className="wm-explore__story">
                  <StoryCircleImg src={src} />
                  <span className="wm-explore__storyCap">{t.stories[i]}</span>
                </div>
              ))}
            </div>
          </div>

          <div
            className={`wm-explore__cards ${shimmer ? "wm-explore__cards--shimmer" : ""}`}
          >
            <div className="wm-placeCard wm-placeCard--coffee wm-explore__cardRow wm-explore__cardRow--a">
              <div className="wm-placeCard__photo">
                <PlacePhotoImg src={cardImgs[0]} />
              </div>
              <div className="wm-placeCard__body">
                <div className="wm-placeCard__top">
                  <span className="wm-placeCard__name">{names[0]}</span>
                  <span className="wm-placeCard__rating">{t.ratings[0]}</span>
                </div>
                <div className="wm-placeCard__badge">{types[0]}</div>
                <div className="wm-placeCard__bottom">
                  <span className="wm-placeCard__dist">{t.distances[0]}</span>
                  <span className="wm-placeCard__add">{t.addDay}</span>
                </div>
              </div>
            </div>

            <div className="wm-placeCard wm-placeCard--museum wm-explore__cardRow wm-explore__cardRow--b">
              <div className="wm-placeCard__photo">
                <PlacePhotoImg src={cardImgs[1]} />
              </div>
              <div className="wm-placeCard__body">
                <div className="wm-placeCard__top">
                  <span className="wm-placeCard__name">{names[1]}</span>
                  <span className="wm-placeCard__rating">{t.ratings[1]}</span>
                </div>
                <div className="wm-placeCard__badge">{types[1]}</div>
                <div className="wm-placeCard__bottom">
                  <span className="wm-placeCard__dist">{t.distances[1]}</span>
                  <span className="wm-placeCard__add">{t.addDay}</span>
                </div>
              </div>
              <span className="wm-placeCard__trending">{t.trendingPill}</span>
            </div>

            <div className="wm-placeCard wm-placeCard--park wm-explore__cardRow wm-explore__cardRow--c">
              <div className="wm-placeCard__photo">
                <PlacePhotoImg src={cardImgs[2]} />
              </div>
              <div className="wm-placeCard__body">
                <div className="wm-placeCard__top">
                  <span className="wm-placeCard__name">{names[2]}</span>
                  <span className="wm-placeCard__rating">{t.ratings[2]}</span>
                </div>
                <div className="wm-placeCard__badge">{types[2]}</div>
                <div className="wm-placeCard__bottom">
                  <span className="wm-placeCard__dist">{t.distances[2]}</span>
                  <span className="wm-placeCard__add">{t.addDay}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <MockupBottomNav active="explore" locale={locale} />
    </div>
  );
}
