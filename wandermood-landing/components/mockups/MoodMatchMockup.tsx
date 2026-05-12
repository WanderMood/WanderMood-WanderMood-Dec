"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { MockupStatusBar, MockupTopBar } from "./MockupChrome";
import type { MockupLocale } from "./MockupChrome";
import {
  MOCK_IMG_COFFEE,
  MOCK_IMG_MUSEUM,
  MOCK_IMG_WINE,
} from "./mockup-place-images";

const TARGET_SCORE = 78;
const SCORE_DURATION_MS = 1500;
const RING_R = 50;

function normalizeLocale(locale?: string): MockupLocale {
  const l = (locale ?? "en").toLowerCase();
  if (l === "nl" || l === "en" || l === "de" || l === "es" || l === "fr") return l;
  return "en";
}

type MMCopy = {
  title: string;
  you: string;
  partner: string;
  match: string;
  balance: string;
  moods: string;
  moodyMsg: string;
  morning: string;
  afternoon: string;
  evening: string;
  confirm: string;
  slot1: string;
  slot2: string;
  slot3: string;
  meta1: string;
  meta2: string;
  meta3: string;
};

const MM_TR: Record<MockupLocale, MMCopy> = {
  nl: {
    title: "Mood Match",
    you: "Jij",
    partner: "Sarah",
    match: "match",
    balance: "Goede balans",
    moods: "🎭 Cultureel · 💕 Romantisch",
    moodyMsg: "Ik heb plekken gevonden die voor jullie allebei werken 💚",
    morning: "Ochtend",
    afternoon: "Middag",
    evening: "Avond",
    confirm: "Plan bevestigen →",
    slot1: "Hopper Espresso Bar",
    slot2: "DEPOT Boijmans",
    slot3: "Wijnbar Sobre",
    meta1: "09:00 · Specialty coffee · 📍 0,8km",
    meta2: "13:00 · Museum · 📍 2,1km",
    meta3: "19:00 · Wijnbar · 📍 1,2km",
  },
  en: {
    title: "Mood Match",
    you: "You",
    partner: "Sarah",
    match: "match",
    balance: "Good balance",
    moods: "🎭 Cultural · 💕 Romantic",
    moodyMsg: "I found places that work for both of you 💚",
    morning: "Morning",
    afternoon: "Afternoon",
    evening: "Evening",
    confirm: "Confirm plan →",
    slot1: "Hopper Espresso Bar",
    slot2: "DEPOT Boijmans",
    slot3: "Wijnbar Sobre",
    meta1: "09:00 · Specialty coffee · 📍 0.8km",
    meta2: "13:00 · Museum · 📍 2.1km",
    meta3: "19:00 · Wine bar · 📍 1.2km",
  },
  de: {
    title: "Mood Match",
    you: "Du",
    partner: "Sarah",
    match: "Match",
    balance: "Gute Balance",
    moods: "🎭 Kulturell · 💕 Romantisch",
    moodyMsg: "Ich habe Orte gefunden, die für euch beide passen 💚",
    morning: "Morgen",
    afternoon: "Mittag",
    evening: "Abend",
    confirm: "Plan bestätigen →",
    slot1: "Hopper Espresso Bar",
    slot2: "DEPOT Boijmans",
    slot3: "Wijnbar Sobre",
    meta1: "09:00 · Specialty Coffee · 📍 0,8 km",
    meta2: "13:00 · Museum · 📍 2,1 km",
    meta3: "19:00 · Weinbar · 📍 1,2 km",
  },
  es: {
    title: "Mood Match",
    you: "Tú",
    partner: "Sarah",
    match: "match",
    balance: "Buen equilibrio",
    moods: "🎭 Cultural · 💕 Romántico",
    moodyMsg: "Encontré lugares que funcionan para ambos 💚",
    morning: "Mañana",
    afternoon: "Tarde",
    evening: "Noche",
    confirm: "Confirmar plan →",
    slot1: "Hopper Espresso Bar",
    slot2: "DEPOT Boijmans",
    slot3: "Wijnbar Sobre",
    meta1: "09:00 · Café especialidad · 📍 0,8 km",
    meta2: "13:00 · Museo · 📍 2,1 km",
    meta3: "19:00 · Bar de vinos · 📍 1,2 km",
  },
  fr: {
    title: "Mood Match",
    you: "Toi",
    partner: "Sarah",
    match: "match",
    balance: "Bon équilibre",
    moods: "🎭 Culturel · 💕 Romantique",
    moodyMsg: "J’ai trouvé des lieux qui conviennent à vous deux 💚",
    morning: "Matin",
    afternoon: "Après-midi",
    evening: "Soir",
    confirm: "Confirmer le plan →",
    slot1: "Hopper Espresso Bar",
    slot2: "DEPOT Boijmans",
    slot3: "Wijnbar Sobre",
    meta1: "09:00 · Café de spécialité · 📍 0,8 km",
    meta2: "13:00 · Musée · 📍 2,1 km",
    meta3: "19:00 · Bar à vin · 📍 1,2 km",
  },
};

function CardPhoto({ src }: { src: string }) {
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

export function MoodMatchMockup({ locale }: { locale?: string }) {
  const loc = normalizeLocale(locale);
  const tx = MM_TR[loc] ?? MM_TR.en;

  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const scoreRafRef = useRef<number>(0);

  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [score, setScore] = useState(0);
  const [typed, setTyped] = useState("");
  const [sConfirmed, setSConfirmed] = useState(false);
  const [sPulse, setSPulse] = useState(false);
  const [typingOn, setTypingOn] = useState(false);
  const [ringAnimate, setRingAnimate] = useState(false);

  const clearT = () => {
    timers.current.forEach((id) => clearTimeout(id));
    timers.current = [];
  };

  const cancelScoreRaf = () => {
    if (scoreRafRef.current && typeof cancelAnimationFrame === "function") {
      cancelAnimationFrame(scoreRafRef.current);
      scoreRafRef.current = 0;
    }
  };

  const q = (fn: () => void, ms: number) => {
    timers.current.push(window.setTimeout(fn, ms));
  };

  const runRef = useRef<(() => void) | null>(null);

  const runCycle = useCallback(() => {
    clearT();
    cancelScoreRaf();
    setScore(0);
    setRingAnimate(false);
    setTyped("");
    setSConfirmed(false);
    setSPulse(false);
    setTypingOn(false);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 400);
    q(() => setStep(3), 800);
    q(() => {
      setStep(4);
      setRingAnimate(false);
      cancelScoreRaf();
      window.setTimeout(() => {
        setRingAnimate(true);
        const startTime = performance.now();
        const tick = (now: number) => {
          const elapsed = now - startTime;
          const progress = Math.min(elapsed / SCORE_DURATION_MS, 1);
          const current =
            progress >= 1 ? TARGET_SCORE : Math.round(progress * TARGET_SCORE);
          setScore(current);
          if (progress < 1) {
            scoreRafRef.current = requestAnimationFrame(tick);
          }
        };
        scoreRafRef.current = requestAnimationFrame(tick);
      }, 50);
    }, 1200);
    q(() => setStep(5), 3200);
    q(() => setStep(6), 3400);
    q(() => setStep(7), 3800);
    q(() => {
      setStep(8);
      setTypingOn(true);
    }, 4400);
    q(() => setStep(9), 6800);
    q(() => setStep(10), 7200);
    q(() => setStep(11), 7600);
    q(() => setStep(12), 8200);
    q(() => {
      setSConfirmed(true);
    }, 10000);
    q(() => {
      setSPulse(true);
    }, 12000);
    q(() => setSPulse(false), 12400);
    q(() => {
      setOn(false);
      setStep(0);
      setTyped("");
      setScore(0);
      setTypingOn(false);
      setRingAnimate(false);
      cancelScoreRaf();
    }, 15500);
    q(() => runRef.current?.(), 17200);
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
          cancelScoreRaf();
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
      if (document.visibilityState !== "visible") {
        clearT();
        cancelScoreRaf();
      } else if (inView.current) {
        clearT();
        runCycle();
      }
    };
    document.addEventListener("visibilitychange", onVis);
    return () => {
      io.disconnect();
      document.removeEventListener("visibilitychange", onVis);
      clearT();
      cancelScoreRaf();
    };
  }, [runCycle]);

  useEffect(() => {
    if (!typingOn) return;
    setTyped("");
    let i = 0;
    const fullLine = tx.moodyMsg;
    const id = window.setInterval(() => {
      i += 1;
      setTyped(fullLine.slice(0, i));
      if (i >= fullLine.length) clearInterval(id);
    }, 30);
    return () => clearInterval(id);
  }, [typingOn, tx.moodyMsg]);

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      data-s-confirm={sConfirmed ? "1" : "0"}
      data-s-pulse={sPulse ? "1" : "0"}
      className={`wm-mock wm-app wm-mm wm-mm--espresso wm-mm--s${step} ${on ? "wm-mock--on" : ""}`}
    >
      <MockupStatusBar variant="dark" />
      <div className="wm-app__main">
        <div className="wm-mock__scroll wm-mm__scroll">
          <MockupTopBar title={tx.title} />

          <div className="wm-mm__avatarsRow">
            <div className="wm-mm__avatars">
              <div className="wm-mm__avCol">
                <div className="wm-mm__av wm-mm__av--e">E</div>
                <span className="wm-mm__avLabel">{tx.you}</span>
              </div>
              <div className="wm-mm__heart" aria-hidden>
                💚
              </div>
              <div className="wm-mm__avCol">
                <div className="wm-mm__av wm-mm__av--s">S</div>
                <span className="wm-mm__avLabel">{tx.partner}</span>
              </div>
            </div>
          </div>

          <div className="wm-mm__ringWrap">
            <svg
              className="wm-mm__ring"
              viewBox="0 0 120 120"
              width={110}
              height={110}
              aria-hidden
            >
              <circle
                className="wm-mm__track"
                cx={60}
                cy={60}
                r={RING_R}
                fill="none"
                strokeWidth={8}
              />
              <circle
                className={`wm-mm__prog ${ringAnimate ? "wm-mm__prog--animate" : ""}`}
                cx={60}
                cy={60}
                r={RING_R}
                fill="none"
                strokeWidth={8}
                strokeLinecap="round"
                transform="rotate(-90 60 60)"
              />
              <text x={60} y={56} textAnchor="middle" className="wm-mm__score">
                {score}
              </text>
              <text x={60} y={68} textAnchor="middle" className="wm-mm__subring">
                {tx.match}
              </text>
            </svg>
          </div>

          <div className="wm-mm__balance">{tx.balance}</div>
          <div className="wm-mm__pills">{tx.moods}</div>

          <div className="wm-mm__moody">
            <div className="wm-mm__mav">M</div>
            <div className="wm-mm__mtext">{typed}</div>
          </div>

          <div className="wm-mm__plans">
            <div className="wm-mmPlan wm-mmPlan--morning">
              <div className="wm-mmPlan__hdr">
                <span>
                  🌅 {tx.morning}
                </span>
              </div>
              <div className="wm-placeCard wm-placeCard--coffee wm-mmPlan__card">
                <div className="wm-placeCard__photo">
                  <CardPhoto src={MOCK_IMG_COFFEE} />
                </div>
                <div className="wm-placeCard__body">
                  <div className="wm-placeCard__top">
                    <span className="wm-placeCard__name">{tx.slot1}</span>
                  </div>
                  <div className="wm-placeCard__metaLine">{tx.meta1}</div>
                  <div className="wm-mmPlan__dots">
                    <span className="wm-mmPlan__dot wm-mmPlan__dot--fill">E</span>
                    <span className="wm-mmPlan__dot wm-mmPlan__dot--fill">S</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="wm-mmPlan wm-mmPlan--noon">
              <div className="wm-mmPlan__hdr">
                <span>
                  ☀️ {tx.afternoon}
                </span>
              </div>
              <div className="wm-placeCard wm-placeCard--museum wm-mmPlan__card">
                <div className="wm-placeCard__photo">
                  <CardPhoto src={MOCK_IMG_MUSEUM} />
                </div>
                <div className="wm-placeCard__body">
                  <div className="wm-placeCard__top">
                    <span className="wm-placeCard__name">{tx.slot2}</span>
                  </div>
                  <div className="wm-placeCard__metaLine">{tx.meta2}</div>
                  <div className="wm-mmPlan__dots">
                    <span className="wm-mmPlan__dot wm-mmPlan__dot--fill">E</span>
                    <span
                      className={`wm-mmPlan__dot ${sConfirmed ? "wm-mmPlan__dot--fill" : "wm-mmPlan__dot--out"} ${sPulse ? "wm-mmPlan__dot--pulse" : ""}`}
                    >
                      S
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div className="wm-mmPlan wm-mmPlan--eve">
              <div className="wm-mmPlan__hdr">
                <span>
                  🌆 {tx.evening}
                </span>
              </div>
              <div className="wm-placeCard wm-placeCard--bar wm-mmPlan__card">
                <div className="wm-placeCard__photo">
                  <CardPhoto src={MOCK_IMG_WINE} />
                </div>
                <div className="wm-placeCard__body">
                  <div className="wm-placeCard__top">
                    <span className="wm-placeCard__name">{tx.slot3}</span>
                  </div>
                  <div className="wm-placeCard__metaLine">{tx.meta3}</div>
                  <div className="wm-mmPlan__dots">
                    <span className="wm-mmPlan__dot wm-mmPlan__dot--out">E</span>
                    <span className="wm-mmPlan__dot wm-mmPlan__dot--out">S</span>
                  </div>
                </div>
              </div>
            </div>

            <button type="button" className="wm-mm__confirm">
              {tx.confirm}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
