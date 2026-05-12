"use client";

import { useCallback, useEffect, useId, useRef, useState } from "react";
import { WmBottomNav, type WmNavLabels } from "./mockup_chrome";

type MockLocale = "nl" | "en" | "de" | "es" | "fr";

function mockLocale(locale: string): MockLocale {
  const l = locale?.toLowerCase() ?? "nl";
  if (l === "en" || l === "de" || l === "es" || l === "fr") return l;
  return "nl";
}

type MM = {
  nav: WmNavLabels;
  title: string;
  match: string;
  balance: string;
  moodyMsg: string;
  morning: string;
  afternoon: string;
  evening: string;
  moods: string;
  placeCoffee: string;
  placeMuseum: string;
  placeWine: string;
};

const MM_I18N: Record<MockLocale, MM> = {
  nl: {
    nav: {
      day: "Mijn Dag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profiel",
    },
    title: "Mood Match",
    match: "match",
    balance: "Goede balans",
    moodyMsg: "Ik heb plekken gevonden die voor jullie allebei werken 💚",
    morning: "Ochtend",
    afternoon: "Middag",
    evening: "Avond",
    moods: "🎭 Cultureel · 💕 Romantisch",
    placeCoffee: "Hopper Espresso Bar",
    placeMuseum: "DEPOT Boijmans",
    placeWine: "Wijnbar Sobre",
  },
  en: {
    nav: {
      day: "My Day",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profile",
    },
    title: "Mood Match",
    match: "match",
    balance: "Good balance",
    moodyMsg: "I found places that work for both of you 💚",
    morning: "Morning",
    afternoon: "Afternoon",
    evening: "Evening",
    moods: "🎭 Cultural · 💕 Romantic",
    placeCoffee: "Hopper Espresso Bar",
    placeMuseum: "DEPOT Boijmans",
    placeWine: "Wijnbar Sobre",
  },
  de: {
    nav: {
      day: "Mein Tag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    title: "Mood Match",
    match: "Match",
    balance: "Gute Balance",
    moodyMsg: "Ich habe Orte gefunden, die für euch beide passen 💚",
    morning: "Morgen",
    afternoon: "Mittag",
    evening: "Abend",
    moods: "🎭 Kulturell · 💕 Romantisch",
    placeCoffee: "Hopper Espresso Bar",
    placeMuseum: "DEPOT Boijmans",
    placeWine: "Wijnbar Sobre",
  },
  es: {
    nav: {
      day: "Mi Día",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Perfil",
    },
    title: "Mood Match",
    match: "match",
    balance: "Buen equilibrio",
    moodyMsg: "Encontré lugares que funcionan para ambos 💚",
    morning: "Mañana",
    afternoon: "Tarde",
    evening: "Noche",
    moods: "🎭 Cultural · 💕 Romántico",
    placeCoffee: "Hopper Espresso Bar",
    placeMuseum: "DEPOT Boijmans",
    placeWine: "Wijnbar Sobre",
  },
  fr: {
    nav: {
      day: "Ma Journée",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    title: "Mood Match",
    match: "match",
    balance: "Bon équilibre",
    moodyMsg: "J'ai trouvé des endroits qui conviennent à vous deux 💚",
    morning: "Matin",
    afternoon: "Après-midi",
    evening: "Soir",
    moods: "🎭 Culturel · 💕 Romantique",
    placeCoffee: "Hopper Espresso Bar",
    placeMuseum: "DEPOT Boijmans",
    placeWine: "Wijnbar Sobre",
  },
};

function moodPills(moods: string): string[] {
  const parts = moods.split(" · ").map((s) => s.trim()).filter(Boolean);
  return parts.length >= 2 ? parts : [moods, ""];
}

export function MoodMatchMockup({ locale }: { locale: string }) {
  const t = MM_I18N[mockLocale(locale)];
  const moodyLineRef = useRef(t.moodyMsg);
  moodyLineRef.current = t.moodyMsg;

  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const raf = useRef<number>(0);
  const gradId = useId().replace(/:/g, "");
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [score, setScore] = useState(0);
  const [typed, setTyped] = useState("");
  const [svgKey, setSvgKey] = useState(0);

  const [pillA, pillB] = moodPills(t.moods);
  const stepRef = useRef(step);
  stepRef.current = step;

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
    if (typeof cancelAnimationFrame === "function" && raf.current) {
      cancelAnimationFrame(raf.current);
      raf.current = 0;
    }
    setTyped("");
    setScore(0);
    setSvgKey((k) => k + 1);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 420);
    q(() => setStep(3), 820);
    q(() => setStep(4), 1180);
    q(() => setStep(5), 1520);
    q(() => setStep(7), 3120);
    q(() => setStep(8), 3480);
    q(() => setStep(9), 3820);
    q(() => {
      setOn(false);
      setStep(0);
      setTyped("");
      setScore(0);
    }, 8480);
    q(() => runRef.current?.(), 8480 + 5000);
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
    let cancelled = false;
    const DURATION = 1500;
    const TARGET = 78;
    let t0 = 0;
    let started = false;
    const tick = (now: number) => {
      if (cancelled) return;
      if (!started) {
        if (stepRef.current < 5) {
          raf.current = requestAnimationFrame(tick);
          return;
        }
        started = true;
        t0 = now;
      }
      const elapsed = now - t0;
      const progress = Math.min(elapsed / DURATION, 1);
      setScore(progress >= 1 ? TARGET : Math.round(progress * TARGET));
      if (progress < 1) {
        raf.current = requestAnimationFrame(tick);
      } else {
        raf.current = 0;
      }
    };
    raf.current = requestAnimationFrame(tick);
    return () => {
      cancelled = true;
      if (raf.current) cancelAnimationFrame(raf.current);
      raf.current = 0;
    };
  }, [svgKey]);

  useEffect(() => {
    if (step !== 9) return;
    let i = 0;
    const line = moodyLineRef.current;
    const id = window.setInterval(() => {
      i += 1;
      setTyped(line.slice(0, i));
      if (i >= line.length) {
        clearInterval(id);
        setStep(10);
      }
    }, 30);
    return () => clearInterval(id);
  }, [step]);

  const displayStep = step >= 10 ? 10 : step;

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      className={`wm-mock wm-mm wm-mm--s${displayStep} ${on ? "wm-mock--on" : ""}`}
    >
      <div className="wm-mock__status">
        <span>9:41</span>
        <span>●●●●</span>
      </div>
      <div className="wm-mock__scroll">
        <div className="wm-mm__label">{t.title}</div>
        <div className="wm-mm__avatars">
          <div className="wm-mm__av wm-mm__av--e">E</div>
          <div className="wm-mm__heart" aria-hidden>
            💚
          </div>
          <div className="wm-mm__av wm-mm__av--s">S</div>
        </div>
        <div className="wm-mm__ringWrap">
          <svg
            key={svgKey}
            className="wm-mm__ring"
            viewBox="0 0 120 120"
            width={100}
            height={100}
            aria-hidden
          >
            <defs>
              <linearGradient id={gradId} x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#2A6049" />
                <stop offset="100%" stopColor="#5DCAA5" />
              </linearGradient>
            </defs>
            <circle
              className="wm-mm__track"
              cx={60}
              cy={60}
              r={50}
              fill="none"
              strokeWidth={8}
            />
            <circle
              className="wm-mm__prog"
              cx={60}
              cy={60}
              r={50}
              fill="none"
              stroke={`url(#${gradId})`}
              strokeWidth={8}
              strokeDasharray={314}
              strokeDashoffset={314}
              strokeLinecap="round"
              transform="rotate(-90 60 60)"
            />
            <text x={60} y={57} textAnchor="middle" className="wm-mm__score">
              {score}
            </text>
            <text x={60} y={72} textAnchor="middle" className="wm-mm__subring">
              {t.match}
            </text>
          </svg>
        </div>
        <div className="wm-mm__balance">{t.balance}</div>
        <div className="wm-mm__pills">
          {pillB ? (
            <>
              <span className="wm-mm__pill">{pillA}</span>
              <span className="wm-mm__pill">{pillB}</span>
            </>
          ) : (
            <span className="wm-mm__pill">{pillA}</span>
          )}
        </div>
        <div className="wm-mm__moody">
          <div className="wm-mm__mav">M</div>
          <div className="wm-mm__mtext">{typed}</div>
        </div>
        <div className="wm-mm__plans">
          <div className="wm-mm__plan">
            🌅 {t.placeCoffee} · {t.morning}
          </div>
          <div className="wm-mm__plan">
            ☀️ {t.placeMuseum} · {t.afternoon}
          </div>
          <div className="wm-mm__plan">
            🌆 {t.placeWine} · {t.evening}
          </div>
        </div>
      </div>
      <WmBottomNav active="plans" variant="dark" labels={t.nav} />
    </div>
  );
}
