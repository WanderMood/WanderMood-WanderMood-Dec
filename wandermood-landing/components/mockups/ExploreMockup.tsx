"use client";

import { useCallback, useEffect, useRef, useState } from "react";

function WmStatusBar() {
  return (
    <div className="wm-mock__status">
      <span className="wm-mock__time">9:41</span>
      <div className="wm-mock__sys">
        <span className="wm-mock__signal" aria-hidden>
          <span />
          <span />
          <span />
        </span>
        <span className="wm-mock__wifi" aria-hidden />
        <span className="wm-mock__battery" aria-hidden>
          <span className="wm-mock__battery-fill" />
        </span>
      </div>
    </div>
  );
}

type Phase = "geo" | "food" | "cult";

type CardCopy = {
  name: string;
  meta: string;
  quote: string;
  emoji: string;
};

const PHASE_CARDS: Record<Phase, [CardCopy, CardCopy, CardCopy]> = {
  geo: [
    {
      name: "Hopper Espresso Bar",
      meta: "★ 4.6 · Specialty coffee",
      quote: "Flat white, goed licht.",
      emoji: "☕",
    },
    {
      name: "DEPOT Boijmans",
      meta: "★ 4.4 · Museum",
      quote: "Neem je tijd in de eerste zaal.",
      emoji: "🏛️",
    },
    {
      name: "Kralingse Bos",
      meta: "★ 4.7 · Natuur",
      quote: "Even ontsnappen aan de stad.",
      emoji: "🌿",
    },
  ],
  food: [
    {
      name: "Bazar",
      meta: "★ 4.5 · Wereldkeuken",
      quote: "Shared plates & gezellig gedruis.",
      emoji: "🍽️",
    },
    {
      name: "Fenix Food Factory",
      meta: "★ 4.6 · Foodhall",
      quote: "Veel keus aan kraampjes.",
      emoji: "🍽️",
    },
    {
      name: "Kralingse Bos",
      meta: "★ 4.7 · Lunch buiten",
      quote: "Picknick na je hap.",
      emoji: "🌿",
    },
  ],
  cult: [
    {
      name: "DEPOT Boijmans",
      meta: "★ 4.4 · Depot",
      quote: "Iconische containers.",
      emoji: "🏛️",
    },
    {
      name: "Museum Boijmans",
      meta: "★ 4.5 · Kunst",
      quote: "Klassieke meesters.",
      emoji: "🎨",
    },
    {
      name: "Kralingse Bos",
      meta: "★ 4.7 · Rust",
      quote: "Na de musea.",
      emoji: "🌿",
    },
  ],
};

export function ExploreMockup() {
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [phase, setPhase] = useState<Phase>("geo");
  const [chipActive, setChipActive] = useState(0);
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
    setChipActive(0);
    setExiting(false);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 300);
    q(() => setStep(3), 700);
    q(() => setStep(4), 1400);
    q(() => setStep(5), 2200);
    q(() => setStep(6), 2800);
    q(() => setStep(7), 3400);
    q(() => {
      setStep(8);
      setChipActive(1);
    }, 5000);
    q(() => {
      setStep(9);
      setPhase("food");
    }, 7000);
    q(() => {
      setStep(10);
      setChipActive(2);
      setPhase("cult");
    }, 9000);
    q(() => setStep(11), 11500);
    q(() => setExiting(true), 13000);
    q(() => {
      setExiting(false);
      setOn(false);
      setStep(0);
      setPhase("geo");
      setChipActive(0);
    }, 14500);
    q(() => runRef.current?.(), 15000);
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

  const cards = PHASE_CARDS[phase];

  const chipCls = (i: number) => {
    const base = "wm-explore__chip";
    if (chipActive === 0 && i === 0) return `${base} wm-explore__chip--active`;
    if (chipActive === 1 && i === 1) return `${base} wm-explore__chip--active2`;
    if (chipActive === 2 && i === 2) return `${base} wm-explore__chip--active3`;
    return base;
  };

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      className={`wm-mock wm-explore wm-explore--s${step} ${on ? "wm-mock--on" : ""} ${exiting ? "wm-mock--exiting" : ""}`}
    >
      <WmStatusBar />
      <div className="wm-mock__scroll">
        <div className="wm-explore__search">
          <span aria-hidden>🔍</span>
          <span>Ontdek Rotterdam…</span>
        </div>
        <div className="wm-explore__chips">
          <span className={chipCls(0)}>{chipActive === 0 ? "Gezellig ✓" : "Gezellig"}</span>
          <span className={chipCls(1)}>{chipActive === 1 ? "Foodie ✓" : "Foodie"}</span>
          <span className={chipCls(2)}>{chipActive === 2 ? "Cultureel ✓" : "Cultureel"}</span>
          <span className="wm-explore__chip">Avontuurlijk</span>
          <span className="wm-explore__chip">Meer</span>
        </div>
        <div className="wm-explore__storiesBlock">
          <div className="wm-explore__trendLabel">Trending op WanderMood</div>
          <div className="wm-explore__stories">
            <div className="wm-explore__storyItem">
              <div className="wm-explore__dot" />
              <span className="wm-explore__storyLbl">Hopper</span>
            </div>
            <div className="wm-explore__storyItem">
              <div className="wm-explore__dot" />
              <span className="wm-explore__storyLbl">DEPOT</span>
            </div>
            <div className="wm-explore__storyItem">
              <div className="wm-explore__dot" />
              <span className="wm-explore__storyLbl">Kralingen</span>
            </div>
          </div>
        </div>
        <div className="wm-explore__cardsViewport">
          <div className="wm-explore__cards">
            <div className="wm-explore__card wm-explore__card--a">
              <div className="wm-explore__thumb" aria-hidden>
                {cards[0].emoji}
              </div>
              <div className="wm-explore__cardBody">
                <div className="wm-explore__name">{cards[0].name}</div>
                <div className="wm-explore__meta">{cards[0].meta}</div>
                <div className="wm-explore__quote">{cards[0].quote}</div>
              </div>
              <span className="wm-explore__bookmark" aria-hidden>
                🔖
              </span>
            </div>
            <div className="wm-explore__card wm-explore__card--b">
              <span className="wm-explore__trendingPill">🔥 Trending</span>
              <div className="wm-explore__thumb" aria-hidden>
                {cards[1].emoji}
              </div>
              <div className="wm-explore__cardBody">
                <div className="wm-explore__name">{cards[1].name}</div>
                <div className="wm-explore__meta">{cards[1].meta}</div>
                <div className="wm-explore__quote">{cards[1].quote}</div>
              </div>
              <span className="wm-explore__bookmark" aria-hidden>
                🔖
              </span>
            </div>
            <div className="wm-explore__card wm-explore__card--c">
              <div className="wm-explore__thumb" aria-hidden>
                {cards[2].emoji}
              </div>
              <div className="wm-explore__cardBody">
                <div className="wm-explore__name">{cards[2].name}</div>
                <div className="wm-explore__meta">{cards[2].meta}</div>
                <div className="wm-explore__quote">{cards[2].quote}</div>
              </div>
              <span className="wm-explore__bookmark" aria-hidden>
                🔖
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
