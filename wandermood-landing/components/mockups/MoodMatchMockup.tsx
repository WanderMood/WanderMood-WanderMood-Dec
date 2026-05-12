"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { WmBottomNav, WmStatusBar, type WmNavLabels } from "./mockup_chrome";

type MockLocale = "nl" | "en" | "de" | "es" | "fr";

function mockLocale(locale: string): MockLocale {
  const l = locale?.toLowerCase() ?? "nl";
  if (l === "en" || l === "de" || l === "es" || l === "fr") return l;
  return "nl";
}

const IMG = {
  coffee:
    "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=160&h=200&fit=crop&q=70",
  museum:
    "https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?w=160&h=200&fit=crop&q=70",
  bar: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=160&h=200&fit=crop&q=70",
} as const;

type MM = {
  nav: WmNavLabels;
  title: string;
  you: string;
  partner: string;
  match: string;
  balance: string;
  moodyMsg: string;
  morning: string;
  afternoon: string;
  evening: string;
  confirm: string;
  moods: string;
  typeCoffee: string;
  typeMuseum: string;
  typeWine: string;
  meta1: string;
  meta2: string;
  meta3: string;
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
    you: "Jij",
    partner: "Sarah",
    match: "match",
    balance: "Goede balans",
    moodyMsg: "Ik heb plekken gevonden die voor jullie allebei werken 💚",
    morning: "Ochtend",
    afternoon: "Middag",
    evening: "Avond",
    confirm: "Plan bevestigen →",
    moods: "🎭 Cultureel · 💕 Romantisch",
    typeCoffee: "Specialty coffee",
    typeMuseum: "Museum",
    typeWine: "Wijnbar",
    meta1: "09:00 · Specialty coffee · 📍 0.8km",
    meta2: "13:00 · Museum · 📍 2.1km",
    meta3: "19:00 · Wijnbar · 📍 1.2km",
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
    you: "You",
    partner: "Sarah",
    match: "match",
    balance: "Good balance",
    moodyMsg: "I found places that work for both of you 💚",
    morning: "Morning",
    afternoon: "Afternoon",
    evening: "Evening",
    confirm: "Confirm plan →",
    moods: "🎭 Cultural · 💕 Romantic",
    typeCoffee: "Specialty coffee",
    typeMuseum: "Museum",
    typeWine: "Wine bar",
    meta1: "09:00 · Specialty coffee · 📍 0.8km",
    meta2: "13:00 · Museum · 📍 2.1km",
    meta3: "19:00 · Wine bar · 📍 1.2km",
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
    you: "Du",
    partner: "Sarah",
    match: "Match",
    balance: "Gute Balance",
    moodyMsg: "Ich habe Orte gefunden, die für euch beide passen 💚",
    morning: "Morgen",
    afternoon: "Mittag",
    evening: "Abend",
    confirm: "Plan bestätigen →",
    moods: "🎭 Kulturell · 💕 Romantisch",
    typeCoffee: "Specialty coffee",
    typeMuseum: "Museum",
    typeWine: "Weinbar",
    meta1: "09:00 · Specialty coffee · 📍 0.8km",
    meta2: "13:00 · Museum · 📍 2.1km",
    meta3: "19:00 · Weinbar · 📍 1.2km",
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
    you: "Tú",
    partner: "Sarah",
    match: "match",
    balance: "Buen equilibrio",
    moodyMsg: "Encontré lugares que funcionan para ambos 💚",
    morning: "Mañana",
    afternoon: "Tarde",
    evening: "Noche",
    confirm: "Confirmar plan →",
    moods: "🎭 Cultural · 💕 Romántico",
    typeCoffee: "Specialty coffee",
    typeMuseum: "Museo",
    typeWine: "Bar de vinos",
    meta1: "09:00 · Specialty coffee · 📍 0.8km",
    meta2: "13:00 · Museo · 📍 2.1km",
    meta3: "19:00 · Bar de vinos · 📍 1.2km",
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
    you: "Toi",
    partner: "Sarah",
    match: "match",
    balance: "Bon équilibre",
    moodyMsg: "J'ai trouvé des endroits qui conviennent à vous deux 💚",
    morning: "Matin",
    afternoon: "Après-midi",
    evening: "Soir",
    confirm: "Confirmer le plan →",
    moods: "🎭 Culturel · 💕 Romantique",
    typeCoffee: "Specialty coffee",
    typeMuseum: "Musée",
    typeWine: "Bar à vin",
    meta1: "09:00 · Specialty coffee · 📍 0.8km",
    meta2: "13:00 · Musée · 📍 2.1km",
    meta3: "19:00 · Bar à vin · 📍 1.2km",
    placeCoffee: "Hopper Espresso Bar",
    placeMuseum: "DEPOT Boijmans",
    placeWine: "Wijnbar Sobre",
  },
};

export function MoodMatchMockup({ locale }: { locale: string }) {
  const t = MM_I18N[mockLocale(locale)];
  const moodyLineRef = useRef(t.moodyMsg);
  moodyLineRef.current = t.moodyMsg;
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const rafRef = useRef<number>(0);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [score, setScore] = useState(0);
  const [typed, setTyped] = useState("");
  const [ringSession, setRingSession] = useState(0);
  const [ringAnimate, setRingAnimate] = useState(false);
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
    if (typeof cancelAnimationFrame === "function" && rafRef.current) {
      cancelAnimationFrame(rafRef.current);
      rafRef.current = 0;
    }
    setTyped("");
    setScore(0);
    setRingSession((s) => s + 1);
    setRingAnimate(false);
    setExiting(false);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 400);
    q(() => setStep(3), 800);
    q(() => setStep(4), 1200);
    q(() => setStep(5), 3400);
    q(() => setStep(6), 3800);
    q(() => setStep(7), 4400);
    q(() => setStep(8), 6800);
    q(() => setStep(9), 7200);
    q(() => setStep(10), 7600);
    q(() => setStep(11), 8200);
    q(() => setStep(12), 10000);
    q(() => setStep(13), 12000);
    q(() => setStep(14), 14000);
    q(() => setExiting(true), 15500);
    q(() => {
      setOn(false);
      setStep(0);
      setTyped("");
      setScore(0);
      setRingAnimate(false);
      setExiting(false);
    }, 17000);
    q(() => runRef.current?.(), 17000);
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
    if (step !== 4) return;
    setRingAnimate(false);
    const tmr = window.setTimeout(() => {
      setRingAnimate(true);
    }, 50);
    return () => clearTimeout(tmr);
  }, [step]);

  useEffect(() => {
    if (!ringAnimate) return;
    let cancelled = false;
    const TARGET = 78;
    const DURATION = 1500;
    const startTime = performance.now();
    const tick = (now: number) => {
      if (cancelled) return;
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / DURATION, 1);
      setScore(progress >= 1 ? TARGET : Math.round(progress * TARGET));
      if (progress < 1) {
        rafRef.current = requestAnimationFrame(tick);
      }
    };
    rafRef.current = requestAnimationFrame(tick);
    return () => {
      cancelled = true;
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
      rafRef.current = 0;
    };
  }, [ringAnimate]);

  useEffect(() => {
    if (step !== 7) return;
    const line = moodyLineRef.current;
    let i = 0;
    const id = window.setInterval(() => {
      i += 1;
      setTyped(line.slice(0, i));
      if (i >= line.length) clearInterval(id);
    }, 30);
    return () => clearInterval(id);
  }, [step]);

  const sConfirm = step >= 12;
  const sPulse = step >= 13;

  const rootCls = [
    "wm-mock",
    "wm-mm",
    `wm-mm--s${Math.min(step, 14)}`,
    step >= 3 ? "wm-mm--heart" : "",
    on ? "wm-mock--on" : "",
    exiting ? "wm-mock--exiting" : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div ref={root} role="presentation" aria-hidden className={rootCls}>
      <WmStatusBar dark />
      <div className="wm-mock__scroll">
        <header className="wm-topbar">
          <div className="wm-topbar__left">
            <span className="wm-topbar__title">{t.title}</span>
          </div>
        </header>

        <div className="wm-mm__users">
          <div className="wm-mm__user">
            <div className="wm-mm__av wm-mm__av--e">E</div>
            <span className="wm-mm__userLbl">{t.you}</span>
          </div>
          <div className="wm-mm__dash" aria-hidden />
          <div className="wm-mm__heart" aria-hidden>
            💚
          </div>
          <div className="wm-mm__dash" aria-hidden />
          <div className="wm-mm__user">
            <div className="wm-mm__av wm-mm__av--s">S</div>
            <span className="wm-mm__userLbl">{t.partner}</span>
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
              r={50}
              fill="none"
              strokeWidth={8}
            />
            <circle
              key={ringSession}
              className={`wm-mm__prog ${ringAnimate ? "wm-mm__prog--draw" : ""}`}
              cx={60}
              cy={60}
              r={50}
              fill="none"
              strokeWidth={8}
              strokeDasharray={314}
              strokeLinecap="round"
              transform="rotate(-90 60 60)"
            />
            <text x={60} y={58} textAnchor="middle" className="wm-mm__score">
              {score}
            </text>
            <text x={60} y={74} textAnchor="middle" className="wm-mm__subring">
              {t.match}
            </text>
          </svg>
        </div>

        <div className="wm-mm__balance">{t.balance}</div>
        <div className="wm-mm__pills">
          <span className="wm-mm__pill">{t.moods}</span>
        </div>

        <div className="wm-mm__moody">
          <div className="wm-mm__mav">M</div>
          <div className="wm-mm__mtext">{typed}</div>
        </div>

        <div
          className={`wm-mm__planRow ${step >= 8 ? "wm-mm__planRow--in" : ""}`}
        >
          <div className="wm-mm__planHead">🌅 {t.morning}</div>
          <div className="wm-card wm-card--sm">
            <img
              src={IMG.coffee}
              alt=""
              width={80}
              height={72}
              style={{
                width: "80px",
                height: "100%",
                objectFit: "cover",
                display: "block",
                flexShrink: 0,
                borderRadius: "14px 0 0 14px",
              }}
            />
            <div className="wm-card__body">
              <div className="wm-card__top">
                <span className="wm-card__name">{t.placeCoffee}</span>
                <span className="wm-card__rating">★ 4.6</span>
              </div>
              <span className="wm-card__badge">{t.typeCoffee}</span>
              <div className="wm-card__bottom">
                <span className="wm-card__dist">{t.meta1}</span>
                <div className="wm-mm__planAv">
                  <span className="wm-mm__miniAv wm-mm__miniAv--e wm-mm__miniAv--fill">
                    E
                  </span>
                  <span className="wm-mm__miniAv wm-mm__miniAv--s wm-mm__miniAv--fill">
                    S
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div
          className={`wm-mm__planRow ${step >= 9 ? "wm-mm__planRow--in" : ""}`}
        >
          <div className="wm-mm__planHead">☀️ {t.afternoon}</div>
          <div className="wm-card wm-card--sm">
            <img
              src={IMG.museum}
              alt=""
              width={80}
              height={72}
              style={{
                width: "80px",
                height: "100%",
                objectFit: "cover",
                display: "block",
                flexShrink: 0,
                borderRadius: "14px 0 0 14px",
              }}
            />
            <div className="wm-card__body">
              <div className="wm-card__top">
                <span className="wm-card__name">{t.placeMuseum}</span>
                <span className="wm-card__rating">★ 4.4</span>
              </div>
              <span className="wm-card__badge">{t.typeMuseum}</span>
              <div className="wm-card__bottom">
                <span className="wm-card__dist">{t.meta2}</span>
                <div className="wm-mm__planAv">
                  <span className="wm-mm__miniAv wm-mm__miniAv--e wm-mm__miniAv--fill">
                    E
                  </span>
                  <span
                    className={`wm-mm__miniAv wm-mm__miniAv--s ${sConfirm ? "wm-mm__miniAv--fill" : "wm-mm__miniAv--empty"} ${sPulse && sConfirm ? "wm-mm__miniAv--pulse" : ""}`}
                  >
                    S
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div
          className={`wm-mm__planRow ${step >= 10 ? "wm-mm__planRow--in" : ""}`}
        >
          <div className="wm-mm__planHead">🌆 {t.evening}</div>
          <div className="wm-card wm-card--sm">
            <img
              src={IMG.bar}
              alt=""
              width={80}
              height={72}
              style={{
                width: "80px",
                height: "100%",
                objectFit: "cover",
                display: "block",
                flexShrink: 0,
                borderRadius: "14px 0 0 14px",
              }}
            />
            <div className="wm-card__body">
              <div className="wm-card__top">
                <span className="wm-card__name">{t.placeWine}</span>
                <span className="wm-card__rating">★ 4.6</span>
              </div>
              <span className="wm-card__badge">{t.typeWine}</span>
              <div className="wm-card__bottom">
                <span className="wm-card__dist">{t.meta3}</span>
                <div className="wm-mm__planAv">
                  <span className="wm-mm__miniAv wm-mm__miniAv--e wm-mm__miniAv--empty">
                    E
                  </span>
                  <span className="wm-mm__miniAv wm-mm__miniAv--s wm-mm__miniAv--empty">
                    S
                  </span>
                </div>
              </div>
            </div>
          </div>
          <button
            type="button"
            className={`wm-mm__cta ${step >= 11 ? "wm-mm__cta--in" : ""}`}
          >
            {t.confirm}
          </button>
        </div>
      </div>
      <WmBottomNav active="plans" variant="dark" labels={t.nav} />
    </div>
  );
}
