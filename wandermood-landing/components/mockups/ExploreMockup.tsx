"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { WmBottomNav, WmStatusBar, type WmNavLabels } from "./mockup_chrome";

type MockLocale = "nl" | "en" | "de" | "es" | "fr";

function mockLocale(locale: string): MockLocale {
  const l = locale?.toLowerCase() ?? "nl";
  if (l === "en" || l === "de" || l === "es" || l === "fr") return l;
  return "nl";
}

const U = {
  coffee:
    "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=160&h=200&fit=crop&q=70",
  museum:
    "https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?w=160&h=200&fit=crop&q=70",
  park: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=160&h=200&fit=crop&q=70",
  bar: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=160&h=200&fit=crop&q=70",
  restaurant:
    "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=160&h=200&fit=crop&q=70",
  foodMarket:
    "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=160&h=200&fit=crop&q=70",
} as const;

const STORY = {
  a: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=80&h=80&fit=crop&q=70",
  b: "https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?w=80&h=80&fit=crop&q=70",
  c: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=80&h=80&fit=crop&q=70",
} as const;

type Phase = "geo" | "food" | "halal";

type Row = {
  name: string;
  rating: string;
  badge: string;
  dist: string;
  src: string;
  trending?: boolean;
};

type ExploreT = {
  nav: WmNavLabels;
  screenTitle: string;
  trending: string;
  addDay: string;
  trendingPill: string;
  more: string;
  moods: [string, string, string, string];
  filters: [string, string, string];
  places: [string, string, string];
  distances: [string, string, string];
  ratings: [string, string, string];
  types: [string, string, string];
  foodNames: [string, string, string];
  foodDist: [string, string, string];
  foodTypes: [string, string, string];
  foodRatings: [string, string, string];
  halalNames: [string, string, string];
  halalDist: [string, string, string];
  halalRatings: [string, string, string];
  halalBadge: string;
  peekName: string;
  peekBadge: string;
  storyLbl: [string, string, string];
};

const EXPLORE: Record<MockLocale, ExploreT> = {
  nl: {
    nav: {
      day: "Mijn Dag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profiel",
    },
    screenTitle: "Explore",
    trending: "Trending op WanderMood",
    addDay: "+ Dag",
    trendingPill: "🔥 Trending",
    more: "Meer →",
    moods: ["Gezellig", "Foodie", "Cultureel", "Avontuurlijk"],
    filters: ["Halal", "Gezinsvriendelijk", "🐕 Honden"],
    places: ["Hopper Espresso Bar", "DEPOT Boijmans", "Kralingse Bos"],
    distances: ["📍 8 min lopen", "🚲 12 min fietsen", "📍 15 min lopen"],
    ratings: ["★ 4.6", "★ 4.4", "★ 4.3"],
    types: ["Specialty coffee", "Museum", "Park"],
    foodNames: ["Bazar Rotterdam", "Fenix Food Factory", "De Biertuin"],
    foodDist: ["📍 10 min lopen", "📍 6 min lopen", "🚶 12 min lopen"],
    foodTypes: ["Wereldkeuken", "Foodhall", "Bar & bites"],
    foodRatings: ["★ 4.5", "★ 4.6", "★ 4.5"],
    halalNames: ["Sultan Döner", "Merhaba Grill", "De Halal Kitchen"],
    halalDist: ["📍 5 min lopen", "📍 8 min lopen", "🚲 9 min fietsen"],
    halalRatings: ["★ 4.7", "★ 4.6", "★ 4.5"],
    halalBadge: "Halal",
    peekName: "Hotel New York",
    peekBadge: "Hotel",
    storyLbl: ["Hopper", "DEPOT", "Kralingen"],
  },
  en: {
    nav: {
      day: "My Day",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profile",
    },
    screenTitle: "Explore",
    trending: "Trending on WanderMood",
    addDay: "+ Day",
    trendingPill: "🔥 Trending",
    more: "More →",
    moods: ["Cozy", "Foodie", "Cultural", "Adventurous"],
    filters: ["Halal", "Family friendly", "🐕 Dogs"],
    places: ["Hopper Espresso Bar", "DEPOT Boijmans", "Kralingse Bos"],
    distances: ["📍 8 min walk", "🚲 12 min bike", "📍 15 min walk"],
    ratings: ["★ 4.6", "★ 4.4", "★ 4.3"],
    types: ["Specialty coffee", "Museum", "Park"],
    foodNames: ["Bazar Rotterdam", "Fenix Food Factory", "De Biertuin"],
    foodDist: ["📍 10 min walk", "📍 6 min walk", "🚶 12 min walk"],
    foodTypes: ["World kitchen", "Food hall", "Bar & bites"],
    foodRatings: ["★ 4.5", "★ 4.6", "★ 4.5"],
    halalNames: ["Sultan Döner", "Merhaba Grill", "De Halal Kitchen"],
    halalDist: ["📍 5 min walk", "📍 8 min walk", "🚲 9 min bike"],
    halalRatings: ["★ 4.7", "★ 4.6", "★ 4.5"],
    halalBadge: "Halal",
    peekName: "Hotel New York",
    peekBadge: "Hotel",
    storyLbl: ["Hopper", "DEPOT", "Kralingen"],
  },
  de: {
    nav: {
      day: "Mein Tag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    screenTitle: "Explore",
    trending: "Trending auf WanderMood",
    addDay: "+ Tag",
    trendingPill: "🔥 Trending",
    more: "Mehr →",
    moods: ["Gemütlich", "Foodie", "Kulturell", "Abenteuerlich"],
    filters: ["Halal", "Familienfreundlich", "🐕 Hunde"],
    places: ["Hopper Espresso Bar", "DEPOT Boijmans", "Kralingse Bos"],
    distances: ["📍 8 Min. Fußweg", "🚲 12 Min. Fahrrad", "📍 15 Min. Fußweg"],
    ratings: ["★ 4.6", "★ 4.4", "★ 4.3"],
    types: ["Specialty coffee", "Museum", "Park"],
    foodNames: ["Bazar Rotterdam", "Fenix Food Factory", "De Biertuin"],
    foodDist: ["📍 10 Min. Fußweg", "📍 6 Min. Fußweg", "🚶 12 Min. Fußweg"],
    foodTypes: ["Weltküche", "Foodhall", "Bar & Snacks"],
    foodRatings: ["★ 4.5", "★ 4.6", "★ 4.5"],
    halalNames: ["Sultan Döner", "Merhaba Grill", "De Halal Kitchen"],
    halalDist: ["📍 5 Min. Fußweg", "📍 8 Min. Fußweg", "🚲 9 Min. Fahrrad"],
    halalRatings: ["★ 4.7", "★ 4.6", "★ 4.5"],
    halalBadge: "Halal",
    peekName: "Hotel New York",
    peekBadge: "Hotel",
    storyLbl: ["Hopper", "DEPOT", "Kralingen"],
  },
  es: {
    nav: {
      day: "Mi Día",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Perfil",
    },
    screenTitle: "Explore",
    trending: "Tendencias en WanderMood",
    addDay: "+ Día",
    trendingPill: "🔥 Trending",
    more: "Más →",
    moods: ["Acogedor", "Foodie", "Cultural", "Aventurero"],
    filters: ["Halal", "Familiar", "🐕 Perros"],
    places: ["Hopper Espresso Bar", "DEPOT Boijmans", "Kralingse Bos"],
    distances: ["📍 8 min andando", "🚲 12 min bici", "📍 15 min andando"],
    ratings: ["★ 4.6", "★ 4.4", "★ 4.3"],
    types: ["Specialty coffee", "Museum", "Parque"],
    foodNames: ["Bazar Rotterdam", "Fenix Food Factory", "De Biertuin"],
    foodDist: ["📍 10 min andando", "📍 6 min andando", "🚶 12 min andando"],
    foodTypes: ["Cocina del mundo", "Mercado gastronómico", "Bar"],
    foodRatings: ["★ 4.5", "★ 4.6", "★ 4.5"],
    halalNames: ["Sultan Döner", "Merhaba Grill", "De Halal Kitchen"],
    halalDist: ["📍 5 min andando", "📍 8 min andando", "🚲 9 min bici"],
    halalRatings: ["★ 4.7", "★ 4.6", "★ 4.5"],
    halalBadge: "Halal",
    peekName: "Hotel New York",
    peekBadge: "Hotel",
    storyLbl: ["Hopper", "DEPOT", "Kralingen"],
  },
  fr: {
    nav: {
      day: "Ma Journée",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    screenTitle: "Explore",
    trending: "Tendances sur WanderMood",
    addDay: "+ Jour",
    trendingPill: "🔥 Trending",
    more: "Plus →",
    moods: ["Cosy", "Foodie", "Culturel", "Aventurier"],
    filters: ["Halal", "Famille", "🐕 Chiens"],
    places: ["Hopper Espresso Bar", "DEPOT Boijmans", "Kralingse Bos"],
    distances: ["📍 8 min à pied", "🚲 12 min vélo", "📍 15 min à pied"],
    ratings: ["★ 4.6", "★ 4.4", "★ 4.3"],
    types: ["Specialty coffee", "Musée", "Parc"],
    foodNames: ["Bazar Rotterdam", "Fenix Food Factory", "De Biertuin"],
    foodDist: ["📍 10 min à pied", "📍 6 min à pied", "🚶 12 min à pied"],
    foodTypes: ["Cuisine du monde", "Food hall", "Bar"],
    foodRatings: ["★ 4.5", "★ 4.6", "★ 4.5"],
    halalNames: ["Sultan Döner", "Merhaba Grill", "De Halal Kitchen"],
    halalDist: ["📍 5 min à pied", "📍 8 min à pied", "🚲 9 min vélo"],
    halalRatings: ["★ 4.7", "★ 4.6", "★ 4.5"],
    halalBadge: "Halal",
    peekName: "Hotel New York",
    peekBadge: "Hôtel",
    storyLbl: ["Hopper", "DEPOT", "Kralingen"],
  },
};

function rowsForPhase(t: ExploreT, phase: Phase): [Row, Row, Row] {
  if (phase === "geo") {
    return [
      {
        name: t.places[0],
        rating: t.ratings[0],
        badge: t.types[0],
        dist: t.distances[0],
        src: U.coffee,
      },
      {
        name: t.places[1],
        rating: t.ratings[1],
        badge: t.types[1],
        dist: t.distances[1],
        src: U.museum,
        trending: true,
      },
      {
        name: t.places[2],
        rating: t.ratings[2],
        badge: t.types[2],
        dist: t.distances[2],
        src: U.park,
      },
    ];
  }
  if (phase === "food") {
    return [
      {
        name: t.foodNames[0],
        rating: t.foodRatings[0],
        badge: t.foodTypes[0],
        dist: t.foodDist[0],
        src: U.restaurant,
      },
      {
        name: t.foodNames[1],
        rating: t.foodRatings[1],
        badge: t.foodTypes[1],
        dist: t.foodDist[1],
        src: U.foodMarket,
        trending: true,
      },
      {
        name: t.foodNames[2],
        rating: t.foodRatings[2],
        badge: t.foodTypes[2],
        dist: t.foodDist[2],
        src: U.bar,
      },
    ];
  }
  return [
    {
      name: t.halalNames[0],
      rating: t.halalRatings[0],
      badge: t.halalBadge,
      dist: t.halalDist[0],
      src: U.restaurant,
    },
    {
      name: t.halalNames[1],
      rating: t.halalRatings[1],
      badge: t.halalBadge,
      dist: t.halalDist[1],
      src: U.restaurant,
      trending: true,
    },
    {
      name: t.halalNames[2],
      rating: t.halalRatings[2],
      badge: t.halalBadge,
      dist: t.halalDist[2],
      src: U.foodMarket,
    },
  ];
}

function PlaceCard({
  row,
  trendingPill,
  addLabel,
  trending,
}: {
  row: Row;
  trendingPill: string;
  addLabel: string;
  trending?: boolean;
}) {
  return (
    <div className="wm-card">
      <img
        src={row.src}
        alt=""
        className="wm-card__photoImg"
        width={80}
        height={100}
      />
      <div className="wm-card__body">
        <div className="wm-card__top">
          <span className="wm-card__name">{row.name}</span>
          <span className="wm-card__rating">{row.rating}</span>
        </div>
        <span className="wm-card__badge">{row.badge}</span>
        <div className="wm-card__bottom">
          <span className="wm-card__dist">{row.dist}</span>
          <span className="wm-card__add">{addLabel}</span>
        </div>
      </div>
      {trending ? (
        <span className="wm-explore__trending" aria-hidden>
          {trendingPill}
        </span>
      ) : null}
    </div>
  );
}

const MOOD_EMOJI = ["✨", "🍽️", "🎭", "🚀"] as const;

export function ExploreMockup({ locale }: { locale: string }) {
  const t = EXPLORE[mockLocale(locale)];
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [phase, setPhase] = useState<Phase>("geo");
  const [moodIdx, setMoodIdx] = useState(0);
  const [halalOn, setHalalOn] = useState(false);
  const [shimmer, setShimmer] = useState(false);
  const [exiting, setExiting] = useState(false);

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
    setPhase("geo");
    setMoodIdx(0);
    setHalalOn(false);
    setShimmer(false);
    setExiting(false);
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
      setMoodIdx(1);
      setShimmer(true);
      setStep(9);
    }, 5000);
    q(() => setShimmer(false), 5600);
    q(() => {
      setPhase("food");
      setStep(10);
    }, 6500);
    q(() => {
      setHalalOn(true);
      setShimmer(true);
      setStep(11);
    }, 9000);
    q(() => setShimmer(false), 9600);
    q(() => {
      setPhase("halal");
      setStep(12);
    }, 10500);
    q(() => setStep(13), 13000);
    q(() => setStep(14), 13500);
    q(() => setExiting(true), 15000);
    q(() => {
      setExiting(false);
      setOn(false);
      setStep(0);
      setPhase("geo");
      setMoodIdx(0);
      setHalalOn(false);
    }, 16500);
    q(() => runRef.current?.(), 16500);
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

  const rows = rowsForPhase(t, phase);
  const peekRow: Row = {
    name: t.peekName,
    rating: "★ 4.5",
    badge: t.peekBadge,
    dist: t.foodDist[0],
    src: U.restaurant,
  };

  const chipCls = (i: number) => {
    const base = "wm-explore__chip";
    if (moodIdx === i) return `${base} wm-explore__chip--on`;
    return base;
  };

  const moodLabels = [
    `${MOOD_EMOJI[0]} ${t.moods[0]}`,
    `${MOOD_EMOJI[1]} ${t.moods[1]}`,
    `${MOOD_EMOJI[2]} ${t.moods[2]}`,
    `${MOOD_EMOJI[3]} ${t.moods[3]}`,
    t.more,
  ];

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      className={`wm-mock wm-explore wm-explore--s${step} ${shimmer ? "wm-explore--shimmer" : ""} ${on ? "wm-mock--on" : ""} ${exiting ? "wm-mock--exiting" : ""}`}
    >
      <WmStatusBar />
      <div className="wm-mock__scroll">
        <header className="wm-topbar">
          <div className="wm-topbar__left">
            <span className="wm-topbar__title">{t.screenTitle}</span>
          </div>
          <div className="wm-topbar__right" aria-hidden>
            ⚙️
          </div>
        </header>

        <div className="wm-explore__chipsRow">
          {moodLabels.map((label, i) => (
            <span key={label} className={chipCls(i)}>
              {moodIdx === i && i < 4 ? `${label} ✓` : label}
            </span>
          ))}
        </div>

        <div className="wm-explore__filters">
          <span
            className={`wm-explore__filter ${halalOn ? "wm-explore__filter--on" : ""}`}
          >
            {t.filters[0]}
          </span>
          <span className="wm-explore__filter">{t.filters[1]}</span>
          <span className="wm-explore__filter">{t.filters[2]}</span>
        </div>

        <div className="wm-explore__secLabel">{t.trending}</div>

        <div className="wm-explore__storiesBlock">
          <div className="wm-explore__stories">
            <div className="wm-explore__storyItem">
              <img
                src={STORY.a}
                alt=""
                className="wm-explore__storyImg"
                width={38}
                height={38}
              />
              <span className="wm-explore__storyLbl">{t.storyLbl[0]}</span>
            </div>
            <div className="wm-explore__storyItem">
              <img
                src={STORY.b}
                alt=""
                className="wm-explore__storyImg"
                width={38}
                height={38}
              />
              <span className="wm-explore__storyLbl">{t.storyLbl[1]}</span>
            </div>
            <div className="wm-explore__storyItem">
              <img
                src={STORY.c}
                alt=""
                className="wm-explore__storyImg"
                width={38}
                height={38}
              />
              <span className="wm-explore__storyLbl">{t.storyLbl[2]}</span>
            </div>
          </div>
        </div>

        <div className="wm-explore__cardsViewport">
          <div className="wm-explore__cards">
            <div className="wm-explore__cardWrap wm-explore__cardWrap--1">
              <PlaceCard
                row={rows[0]}
                trendingPill={t.trendingPill}
                addLabel={t.addDay}
                trending={rows[0].trending === true}
              />
            </div>
            <div className="wm-explore__cardWrap wm-explore__cardWrap--2">
              <PlaceCard
                row={rows[1]}
                trendingPill={t.trendingPill}
                addLabel={t.addDay}
                trending={rows[1].trending === true}
              />
            </div>
            <div className="wm-explore__cardWrap wm-explore__cardWrap--3">
              <PlaceCard
                row={rows[2]}
                trendingPill={t.trendingPill}
                addLabel={t.addDay}
                trending={rows[2].trending === true}
              />
            </div>
            <div className="wm-explore__peekClip">
              <div className="wm-explore__cardWrap wm-explore__cardWrap--4">
                <PlaceCard
                  row={peekRow}
                  trendingPill={t.trendingPill}
                  addLabel={t.addDay}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <WmBottomNav active="explore" labels={t.nav} />
    </div>
  );
}
