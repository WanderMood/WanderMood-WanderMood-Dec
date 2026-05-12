"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { WmBottomNav, type WmNavLabels } from "./mockup_chrome";

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
} as const;

type ExploreV1 = {
  nav: WmNavLabels;
  search: string;
  trending: string;
  moods: [string, string, string];
  more: string;
  cardA: { name: string; meta: string; quote: string };
  cardB: { name: string; meta: string; quote: string };
};

const EXPLORE_V1: Record<MockLocale, ExploreV1> = {
  nl: {
    nav: {
      day: "Mijn Dag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profiel",
    },
    search: "Ontdek Rotterdam…",
    trending: "Trending op WanderMood",
    moods: ["Gezellig", "Foodie", "Cultureel"],
    more: "Meer…",
    cardA: {
      name: "Hopper Espresso Bar",
      meta: "★ 4.6 · Specialty coffee · ☕",
      quote: "Flat white, goed licht, geen haast.",
    },
    cardB: {
      name: "DEPOT Boijmans",
      meta: "★ 4.4 · Museum · 🎭",
      quote: "Neem je tijd in de eerste zaal.",
    },
  },
  en: {
    nav: {
      day: "My Day",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profile",
    },
    search: "Discover Rotterdam…",
    trending: "Trending on WanderMood",
    moods: ["Cozy", "Foodie", "Cultural"],
    more: "More…",
    cardA: {
      name: "Hopper Espresso Bar",
      meta: "★ 4.6 · Specialty coffee · ☕",
      quote: "Flat white, good light, no rush.",
    },
    cardB: {
      name: "DEPOT Boijmans",
      meta: "★ 4.4 · Museum · 🎭",
      quote: "Take your time in the first hall.",
    },
  },
  de: {
    nav: {
      day: "Mein Tag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    search: "Rotterdam entdecken…",
    trending: "Trending auf WanderMood",
    moods: ["Gemütlich", "Foodie", "Kulturell"],
    more: "Mehr…",
    cardA: {
      name: "Hopper Espresso Bar",
      meta: "★ 4.6 · Specialty coffee · ☕",
      quote: "Flat White, gutes Licht, kein Stress.",
    },
    cardB: {
      name: "DEPOT Boijmans",
      meta: "★ 4.4 · Museum · 🎭",
      quote: "Nimm dir Zeit im ersten Saal.",
    },
  },
  es: {
    nav: {
      day: "Mi Día",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Perfil",
    },
    search: "Descubre Rotterdam…",
    trending: "Tendencias en WanderMood",
    moods: ["Acogedor", "Foodie", "Cultural"],
    more: "Más…",
    cardA: {
      name: "Hopper Espresso Bar",
      meta: "★ 4.6 · Specialty coffee · ☕",
      quote: "Flat white, buena luz, sin prisas.",
    },
    cardB: {
      name: "DEPOT Boijmans",
      meta: "★ 4.4 · Museo · 🎭",
      quote: "Tómate tu tiempo en la primera sala.",
    },
  },
  fr: {
    nav: {
      day: "Ma Journée",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    search: "Découvrir Rotterdam…",
    trending: "Tendances sur WanderMood",
    moods: ["Cosy", "Foodie", "Culturel"],
    more: "Plus…",
    cardA: {
      name: "Hopper Espresso Bar",
      meta: "★ 4.6 · Specialty coffee · ☕",
      quote: "Flat white, belle lumière, sans stress.",
    },
    cardB: {
      name: "DEPOT Boijmans",
      meta: "★ 4.4 · Musée · 🎭",
      quote: "Prends ton temps dans la première salle.",
    },
  },
};

export function ExploreMockup({ locale }: { locale: string }) {
  const t = EXPLORE_V1[mockLocale(locale)];
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [chip, setChip] = useState(0);

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
    setChip(0);
    setOn(true);
    setStep(1);
    q(() => setStep(3), 420);
    q(() => setStep(4), 820);
    q(() => setStep(5), 1220);
    q(() => setStep(6), 1680);
    q(() => setStep(7), 2180);
    q(() => setStep(8), 2680);
    q(() => {
      setStep(9);
      setChip(1);
    }, 5800);
    q(() => setStep(10), 6600);
    q(() => {
      setOn(false);
      setStep(0);
      setChip(0);
    }, 8200);
    q(() => runRef.current?.(), 8200 + 5200);
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

  const [m0, m1, m2] = t.moods;

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      className={`wm-mock wm-explore wm-explore--s${step} ${on ? "wm-mock--on" : ""}`}
    >
      <div className="wm-mock__status">
        <span>9:41</span>
        <span>●●●●</span>
      </div>
      <div className="wm-mock__scroll">
        <div className="wm-explore__search">
          <span aria-hidden>🔍</span>
          <span>{t.search}</span>
        </div>
        <div className="wm-explore__chips">
          <span
            className={`wm-explore__chip ${chip === 0 ? "wm-explore__chip--active" : ""}`}
          >
            {chip === 0 ? `${m0} ✓` : m0}
          </span>
          <span
            className={`wm-explore__chip ${chip === 1 ? "wm-explore__chip--active2" : ""}`}
          >
            {chip === 1 ? `${m1} ✓` : m1}
          </span>
          <span className="wm-explore__chip">{m2}</span>
          <span className="wm-explore__chip">{t.more}</span>
        </div>
        <div className="wm-explore__trend">
          <div className="wm-explore__trendRow">
            <div className="wm-explore__trendDots" aria-hidden>
              <span />
              <span />
              <span />
            </div>
            <span>{t.trending}</span>
          </div>
        </div>
        <div className="wm-explore__stories" aria-hidden>
          <div className="wm-explore__dot" />
          <div className="wm-explore__dot" />
          <div className="wm-explore__dot" />
        </div>
        <div className="wm-explore__card wm-explore__card--a">
          <img
            className="wm-explore__cardImg"
            src={U.coffee}
            alt=""
            width={160}
            height={200}
          />
          <div className="wm-explore__cardBody">
            <div className="wm-explore__name">{t.cardA.name}</div>
            <div className="wm-explore__meta">{t.cardA.meta}</div>
            <div className="wm-explore__quote">
              &ldquo;{t.cardA.quote}&rdquo;
            </div>
          </div>
        </div>
        <div className="wm-explore__card wm-explore__card--b">
          <img
            className="wm-explore__cardImg"
            src={U.museum}
            alt=""
            width={160}
            height={200}
          />
          <div className="wm-explore__cardBody">
            <div className="wm-explore__name">{t.cardB.name}</div>
            <div className="wm-explore__meta">{t.cardB.meta}</div>
            <div className="wm-explore__quote">
              &ldquo;{t.cardB.quote}&rdquo;
            </div>
          </div>
        </div>
      </div>
      <WmBottomNav active="explore" labels={t.nav} />
    </div>
  );
}
