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
  wine: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=160&h=200&fit=crop&q=70",
} as const;

type DayV1 = {
  nav: WmNavLabels;
  date: string;
  title: string;
  weather: string;
  depotLong: string;
  slot1Sub: string;
  slot2Sub: string;
  slot3Sub: string;
};

const DAY_V1: Record<MockLocale, DayV1> = {
  nl: {
    nav: {
      day: "Mijn Dag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profiel",
    },
    date: "Zaterdag, 11 mei",
    title: "Jouw dag",
    weather: "☀️ 18°C · Rotterdam · Lekker dagje uit",
    depotLong: "DEPOT Boijmans Van Beuningen",
    slot1Sub: "☕ Met Sarah · Je bent er!",
    slot2Sub: "🎭 Met Sarah",
    slot3Sub: "🍷 Met Sarah",
  },
  en: {
    nav: {
      day: "My Day",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profile",
    },
    date: "Saturday, 11 May",
    title: "Your day",
    weather: "☀️ 18°C · Rotterdam · Great day out",
    depotLong: "DEPOT Boijmans Van Beuningen",
    slot1Sub: "☕ With Sarah · You're here!",
    slot2Sub: "🎭 With Sarah",
    slot3Sub: "🍷 With Sarah",
  },
  de: {
    nav: {
      day: "Mein Tag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    date: "Samstag, 11. Mai",
    title: "Dein Tag",
    weather: "☀️ 18°C · Rotterdam · Schöner Tag",
    depotLong: "DEPOT Boijmans Van Beuningen",
    slot1Sub: "☕ Mit Sarah · Du bist da!",
    slot2Sub: "🎭 Mit Sarah",
    slot3Sub: "🍷 Mit Sarah",
  },
  es: {
    nav: {
      day: "Mi Día",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Perfil",
    },
    date: "Sábado, 11 mayo",
    title: "Tu día",
    weather: "☀️ 18°C · Rotterdam · Buen día",
    depotLong: "DEPOT Boijmans Van Beuningen",
    slot1Sub: "☕ Con Sarah · ¡Ya estás!",
    slot2Sub: "🎭 Con Sarah",
    slot3Sub: "🍷 Con Sarah",
  },
  fr: {
    nav: {
      day: "Ma Journée",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    date: "Samedi, 11 mai",
    title: "Ta journée",
    weather: "☀️ 18°C · Rotterdam · Belle journée",
    depotLong: "DEPOT Boijmans Van Beuningen",
    slot1Sub: "☕ Avec Sarah · Tu y es !",
    slot2Sub: "🎭 Avec Sarah",
    slot3Sub: "🍷 Avec Sarah",
  },
};

export function MyDayMockup({ locale }: { locale: string }) {
  const t = DAY_V1[mockLocale(locale)];
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [pKick, setPKick] = useState(false);
  const [pulse, setPulse] = useState(false);

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
    setPKick(false);
    setPulse(false);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 380);
    q(() => setStep(3), 720);
    q(() => {
      setStep(4);
      setPKick(true);
    }, 1620);
    q(() => setPKick(false), 2360);
    q(() => setStep(5), 1840);
    q(() => setStep(6), 2060);
    q(() => {
      setStep(7);
      setPulse(true);
    }, 5060);
    q(() => setPulse(false), 6320);
    q(() => {
      setOn(false);
      setStep(0);
    }, 8560);
    q(() => runRef.current?.(), 8560 + 5000);
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

  const cls = [
    "wm-mock",
    "wm-day",
    `wm-day--s${step}`,
    on ? "wm-mock--on" : "",
    pKick ? "wm-day--pKick" : "",
    pulse ? "wm-day--pulse" : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div ref={root} role="presentation" aria-hidden className={cls}>
      <div className="wm-day__bar">
        <span>9:41</span>
        <span aria-hidden>🔔</span>
      </div>
      <div className="wm-mock__scroll">
        <header className="wm-day__head">
          <div className="wm-day__date">{t.date}</div>
          <div className="wm-day__title">{t.title}</div>
        </header>
        <div className="wm-day__wx">{t.weather}</div>
        <div className="wm-day__timeline">
          <div className="wm-day__line" aria-hidden />
          <div className="wm-day__slot">
            <div className="wm-day__time">09:00</div>
            <div className="wm-day__dot" aria-hidden />
            <div className="wm-day__card wm-day__card--here">
              <img
                className="wm-day__cardImg"
                src={U.coffee}
                alt=""
                width={160}
                height={200}
              />
              <div className="wm-day__cardMain">
                <div className="wm-day__row">
                  <div className="wm-day__name">Hopper Espresso Bar</div>
                  <span className="wm-day__check" aria-hidden>
                    ✓
                  </span>
                </div>
                <div className="wm-day__sub">{t.slot1Sub}</div>
              </div>
            </div>
          </div>
          <div className="wm-day__slot">
            <div className="wm-day__time">13:00</div>
            <div className="wm-day__dot" aria-hidden />
            <div className="wm-day__card">
              <img
                className="wm-day__cardImg"
                src={U.museum}
                alt=""
                width={160}
                height={200}
              />
              <div className="wm-day__cardMain">
                <div className="wm-day__name">{t.depotLong}</div>
                <div className="wm-day__sub">{t.slot2Sub}</div>
              </div>
            </div>
          </div>
          <div className="wm-day__slot">
            <div className="wm-day__time">19:00</div>
            <div className="wm-day__dot" aria-hidden />
            <div className="wm-day__card">
              <img
                className="wm-day__cardImg"
                src={U.wine}
                alt=""
                width={160}
                height={200}
              />
              <div className="wm-day__cardMain">
                <div className="wm-day__name">Wijnbar Sobre</div>
                <div className="wm-day__sub">{t.slot3Sub}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <WmBottomNav active="day" labels={t.nav} />
    </div>
  );
}
