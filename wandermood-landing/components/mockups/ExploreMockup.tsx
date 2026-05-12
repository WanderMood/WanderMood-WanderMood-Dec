"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { WmBottomNav, WmStatusBar } from "./mockup_chrome";

type PhotoGrad = "coffee" | "museum" | "park" | "rest" | "bar";

type Row = {
  name: string;
  rating: string;
  badge: string;
  dist: string;
  emoji: string;
  grad: PhotoGrad;
  trending?: boolean;
};

type Phase = "geo" | "food" | "halal";

const PHASE_ROWS: Record<Phase, [Row, Row, Row]> = {
  geo: [
    {
      name: "Hopper Espresso Bar",
      rating: "★ 4.6",
      badge: "Specialty coffee",
      dist: "📍 8 min lopen",
      emoji: "☕",
      grad: "coffee",
    },
    {
      name: "DEPOT Boijmans",
      rating: "★ 4.4",
      badge: "Museum",
      dist: "🚲 12 min fietsen",
      emoji: "🏛️",
      grad: "museum",
      trending: true,
    },
    {
      name: "Kralingse Bos",
      rating: "★ 4.7",
      badge: "Park",
      dist: "📍 15 min lopen",
      emoji: "🌿",
      grad: "park",
    },
  ],
  food: [
    {
      name: "Bazar Rotterdam",
      rating: "★ 4.5",
      badge: "Wereldkeuken",
      dist: "📍 10 min lopen",
      emoji: "🍽️",
      grad: "rest",
    },
    {
      name: "Fenix Food Factory",
      rating: "★ 4.6",
      badge: "Foodhall",
      dist: "📍 6 min lopen",
      emoji: "🍽️",
      grad: "rest",
      trending: true,
    },
    {
      name: "De Biertuin",
      rating: "★ 4.5",
      badge: "Bar & bites",
      dist: "🚶 12 min lopen",
      emoji: "🍺",
      grad: "bar",
    },
  ],
  halal: [
    {
      name: "Sultan Döner",
      rating: "★ 4.7",
      badge: "Halal",
      dist: "📍 5 min lopen",
      emoji: "🥙",
      grad: "rest",
    },
    {
      name: "Merhaba Grill",
      rating: "★ 4.6",
      badge: "Halal",
      dist: "📍 8 min lopen",
      emoji: "🍖",
      grad: "rest",
      trending: true,
    },
    {
      name: "De Halal Kitchen",
      rating: "★ 4.5",
      badge: "Halal",
      dist: "🚲 9 min fietsen",
      emoji: "🍽️",
      grad: "rest",
    },
  ],
};

const PEEK_ROW: Row = {
  name: "Hotel New York",
  rating: "★ 4.5",
  badge: "Restaurant",
  dist: "📍 20 min lopen",
  emoji: "🍽️",
  grad: "rest",
};

const MOOD_CHIPS = [
  "✨ Gezellig",
  "🍽️ Foodie",
  "🎭 Cultureel",
  "🚀 Avontuurlijk",
  "Meer →",
];

function photoClass(g: PhotoGrad) {
  const map: Record<PhotoGrad, string> = {
    coffee: "wm-card__photo--coffee",
    museum: "wm-card__photo--museum",
    park: "wm-card__photo--park",
    rest: "wm-card__photo--rest",
    bar: "wm-card__photo--bar",
  };
  return map[g];
}

function PlaceCard({
  row,
  trending,
}: {
  row: Row;
  trending?: boolean;
}) {
  return (
    <div className="wm-card">
      <div className={`wm-card__photo ${photoClass(row.grad)}`} aria-hidden>
        {row.emoji}
      </div>
      <div className="wm-card__body">
        <div className="wm-card__top">
          <span className="wm-card__name">{row.name}</span>
          <span className="wm-card__rating">{row.rating}</span>
        </div>
        <span className="wm-card__badge">{row.badge}</span>
        <div className="wm-card__bottom">
          <span className="wm-card__dist">{row.dist}</span>
          <span className="wm-card__add">+ Dag</span>
        </div>
      </div>
      {trending ? (
        <span className="wm-explore__trending" aria-hidden>
          🔥 Trending
        </span>
      ) : null}
    </div>
  );
}

export function ExploreMockup() {
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

  const rows = PHASE_ROWS[phase];

  const chipCls = (i: number) => {
    const base = "wm-explore__chip";
    if (moodIdx === i) return `${base} wm-explore__chip--on`;
    return base;
  };

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
            <span className="wm-topbar__title">Explore</span>
          </div>
          <div className="wm-topbar__right" aria-hidden>
            ⚙️
          </div>
        </header>

        <div className="wm-explore__chipsRow">
          {MOOD_CHIPS.map((label, i) => (
            <span key={label} className={chipCls(i)}>
              {moodIdx === i && i < 4 ? `${label} ✓` : label}
            </span>
          ))}
        </div>

        <div className="wm-explore__filters">
          <span
            className={`wm-explore__filter ${halalOn ? "wm-explore__filter--on" : ""}`}
          >
            Halal
          </span>
          <span className="wm-explore__filter">Gezinsvriendelijk</span>
          <span className="wm-explore__filter">🐕 Honden</span>
        </div>

        <div className="wm-explore__secLabel">TRENDING OP WANDERMOOD</div>

        <div className="wm-explore__storiesBlock">
          <div className="wm-explore__stories">
            <div className="wm-explore__storyItem">
              <div className="wm-explore__storyDot" />
              <span className="wm-explore__storyLbl">Hopper</span>
            </div>
            <div className="wm-explore__storyItem">
              <div className="wm-explore__storyDot" />
              <span className="wm-explore__storyLbl">DEPOT</span>
            </div>
            <div className="wm-explore__storyItem">
              <div className="wm-explore__storyDot" />
              <span className="wm-explore__storyLbl">Kralingen</span>
            </div>
          </div>
        </div>

        <div className="wm-explore__cardsViewport">
          <div className="wm-explore__cards">
            <div className="wm-explore__cardWrap wm-explore__cardWrap--1">
              <PlaceCard row={rows[0]} trending={rows[0].trending === true} />
            </div>
            <div className="wm-explore__cardWrap wm-explore__cardWrap--2">
              <PlaceCard row={rows[1]} trending={rows[1].trending === true} />
            </div>
            <div className="wm-explore__cardWrap wm-explore__cardWrap--3">
              <PlaceCard row={rows[2]} trending={rows[2].trending === true} />
            </div>
            <div className="wm-explore__peekClip">
              <div className="wm-explore__cardWrap wm-explore__cardWrap--4">
                <PlaceCard row={PEEK_ROW} />
              </div>
            </div>
          </div>
        </div>
      </div>
      <WmBottomNav active="explore" />
    </div>
  );
}
