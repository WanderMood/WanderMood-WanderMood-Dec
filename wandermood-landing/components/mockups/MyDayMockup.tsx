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
} as const;

type DayT = {
  nav: WmNavLabels;
  title: string;
  date: string;
  weather: string;
  arrived: string;
  withSarah: string;
  freeTime: string;
  chips: [string, string, string, string];
  bike1: string;
  bike2: string;
  walk: string;
  route: string;
  typePark: string;
  addDay: string;
};

const DAY: Record<MockLocale, DayT> = {
  nl: {
    nav: {
      day: "Mijn Dag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profiel",
    },
    title: "Mijn Dag",
    date: "Zaterdag, 11 mei",
    weather: "☀️ 18°C · Rotterdam · Lekker dagje uit",
    arrived: "✓ Je bent er",
    withSarah: "Met Sarah",
    freeTime: "Misschien leuk in je vrije tijd",
    chips: ["☕ Koffie halen", "🛍️ Winkelen", "🌳 Wandelen", "🎨 Museum"],
    bike1: "🚲 12 min fietsen",
    bike2: "🚴 18 min fietsen",
    walk: "🚶 10 min lopen",
    route: "Routebeschrijving",
    typePark: "Park",
    addDay: "+ Dag",
  },
  en: {
    nav: {
      day: "My Day",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profile",
    },
    title: "My Day",
    date: "Saturday, 11 May",
    weather: "☀️ 18°C · Rotterdam · Great day out",
    arrived: "✓ You're here",
    withSarah: "With Sarah",
    freeTime: "Maybe fun in your free time",
    chips: ["☕ Get coffee", "🛍️ Shopping", "🌳 Walking", "🎨 Museum"],
    bike1: "🚲 12 min bike",
    bike2: "🚴 18 min bike",
    walk: "🚶 10 min walk",
    route: "Directions",
    typePark: "Park",
    addDay: "+ Day",
  },
  de: {
    nav: {
      day: "Mein Tag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    title: "Mein Tag",
    date: "Samstag, 11. Mai",
    weather: "☀️ 18°C · Rotterdam · Schöner Tag",
    arrived: "✓ Du bist da",
    withSarah: "Mit Sarah",
    freeTime: "Vielleicht interessant",
    chips: ["☕ Kaffee", "🛍️ Einkaufen", "🌳 Spazieren", "🎨 Museum"],
    bike1: "🚲 12 Min. Fahrrad",
    bike2: "🚴 18 Min. Fahrrad",
    walk: "🚶 10 Min. Fußweg",
    route: "Route",
    typePark: "Park",
    addDay: "+ Tag",
  },
  es: {
    nav: {
      day: "Mi Día",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Perfil",
    },
    title: "Mi Día",
    date: "Sábado, 11 mayo",
    weather: "☀️ 18°C · Rotterdam · Buen día",
    arrived: "✓ Ya estás",
    withSarah: "Con Sarah",
    freeTime: "Quizás te guste",
    chips: ["☕ Café", "🛍️ Compras", "🌳 Pasear", "🎨 Museo"],
    bike1: "🚲 12 min bici",
    bike2: "🚴 18 min bici",
    walk: "🚶 10 min andando",
    route: "Ruta",
    typePark: "Parque",
    addDay: "+ Día",
  },
  fr: {
    nav: {
      day: "Ma Journée",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    title: "Ma Journée",
    date: "Samedi, 11 mai",
    weather: "☀️ 18°C · Rotterdam · Belle journée",
    arrived: "✓ Tu y es",
    withSarah: "Avec Sarah",
    freeTime: "Peut-être sympa",
    chips: ["☕ Café", "🛍️ Shopping", "🌳 Promenade", "🎨 Musée"],
    bike1: "🚲 12 min vélo",
    bike2: "🚴 18 min vélo",
    walk: "🚶 10 min à pied",
    route: "Itinéraire",
    typePark: "Parc",
    addDay: "+ Jour",
  },
};

function chipParts(chip: string) {
  const i = chip.indexOf(" ");
  if (i <= 0) return { emoji: chip, text: "" };
  return { emoji: chip.slice(0, i), text: chip.slice(i + 1).trim() };
}

function DayCardSm({
  src,
  name,
  rating,
  badge,
  dist,
  addLabel,
}: {
  src: string;
  name: string;
  rating: string;
  badge: string;
  dist: string;
  addLabel: string;
}) {
  return (
    <div className="wm-card wm-card--sm">
      <img
        src={src}
        alt=""
        className="wm-card__photoImg"
        width={80}
        height={72}
      />
      <div className="wm-card__body">
        <div className="wm-card__top">
          <span className="wm-card__name">{name}</span>
          <span className="wm-card__rating">{rating}</span>
        </div>
        <span className="wm-card__badge">{badge}</span>
        <div className="wm-card__bottom">
          <span className="wm-card__dist">{dist}</span>
          <span className="wm-card__add">{addLabel}</span>
        </div>
      </div>
    </div>
  );
}

export function MyDayMockup({ locale }: { locale: string }) {
  const t = DAY[mockLocale(locale)];
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [pKick, setPKick] = useState(false);
  const [pulse, setPulse] = useState(false);
  const [bright, setBright] = useState(false);
  const [scrollSim, setScrollSim] = useState(false);
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
    setPKick(false);
    setPulse(false);
    setBright(false);
    setScrollSim(false);
    setExiting(false);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 400);
    q(() => {
      setStep(3);
      setPKick(true);
    }, 900);
    q(() => setPKick(false), 1480);
    q(() => setStep(4), 1800);
    q(() => setStep(5), 2400);
    q(() => setStep(6), 2800);
    q(() => setStep(7), 3200);
    q(() => setStep(8), 3600);
    q(() => setStep(9), 3800);
    q(() => setStep(10), 4000);
    q(() => setStep(11), 5000);
    q(() => setStep(12), 5500);
    q(() => setStep(13), 5700);
    q(() => setStep(14), 5900);
    q(() => setStep(15), 6100);
    q(() => {
      setPulse(true);
      setBright(true);
    }, 7500);
    q(() => {
      setPulse(false);
      setBright(false);
    }, 8300);
    q(() => setScrollSim(true), 9000);
    q(() => setScrollSim(false), 11000);
    q(() => setExiting(true), 14500);
    q(() => {
      setExiting(false);
      setOn(false);
      setStep(0);
    }, 16000);
    q(() => runRef.current?.(), 16000);
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
    bright ? "wm-day--bright" : "",
    scrollSim ? "wm-day--scroll" : "",
    exiting ? "wm-mock--exiting" : "",
  ]
    .filter(Boolean)
    .join(" ");

  const sarahMuseum = `🎭 ${t.withSarah}`;
  const sarahWine = `🍷 ${t.withSarah}`;

  return (
    <div ref={root} role="presentation" aria-hidden className={cls}>
      <WmStatusBar />
      <div className="wm-mock__scroll">
        <header className="wm-topbar">
          <div className="wm-topbar__left">
            <span className="wm-topbar__title">{t.title}</span>
          </div>
          <div className="wm-topbar__bell" aria-hidden>
            🔔
            <span className="wm-topbar__bellDot" />
          </div>
        </header>

        <div className="wm-day__panorama">
          <div className="wm-day__dateWx">
            <div className="wm-day__dateLine">{t.date}</div>
            <div className="wm-day__wxInline">{t.weather}</div>
          </div>

          <div className="wm-day__hero">
            <span className="wm-day__heroEmoji" aria-hidden>
              ☕
            </span>
            <div className="wm-day__heroTop">
              <span className="wm-day__heroTime">09:00</span>
              <span className="wm-day__heroStatus">{t.arrived}</span>
            </div>
            <div className="wm-day__heroName">Hopper Espresso Bar</div>
            <div className="wm-day__heroBot">
              <span className="wm-day__heroBadge">
                ☕ {t.withSarah}
              </span>
              <span className="wm-day__heroLink">{t.route}</span>
            </div>
          </div>

          <div className="wm-day__timeline">
            <div className="wm-day__line" aria-hidden />

            <div className="wm-day__between wm-day__between--1">
              <span className="wm-day__betweenPill">{t.bike1}</span>
            </div>

            <div className="wm-day__tlItem">
              <div className="wm-day__timeLbl">13:00</div>
              <div className="wm-day__dot wm-day__dot--out" aria-hidden />
              <div className="wm-day__tlCard wm-day__tlCard--1">
                <DayCardSm
                  src={U.museum}
                  name="DEPOT Boijmans"
                  rating="★ 4.4"
                  badge={sarahMuseum}
                  dist="📍 1.2 km"
                  addLabel={t.addDay}
                />
              </div>
            </div>

            <div className="wm-day__between wm-day__between--2">
              <span className="wm-day__betweenPill">{t.bike2}</span>
            </div>

            <div className="wm-day__tlItem">
              <div className="wm-day__timeLbl">15:30</div>
              <div className="wm-day__dot wm-day__dot--out" aria-hidden />
              <div className="wm-day__tlCard wm-day__tlCard--2">
                <DayCardSm
                  src={U.park}
                  name="Kralingse Bos"
                  rating="★ 4.7"
                  badge={t.typePark}
                  dist="📍 3.4 km"
                  addLabel={t.addDay}
                />
              </div>
            </div>

            <div className="wm-day__between wm-day__between--3">
              <span className="wm-day__betweenPill">{t.walk}</span>
            </div>

            <div className="wm-day__tlItem">
              <div className="wm-day__timeLbl">19:00</div>
              <div className="wm-day__dot wm-day__dot--out" aria-hidden />
              <div className="wm-day__tlCard wm-day__tlCard--3">
                <DayCardSm
                  src={U.bar}
                  name="Wijnbar Sobre"
                  rating="★ 4.6"
                  badge={sarahWine}
                  dist="📍 0.8 km"
                  addLabel={t.addDay}
                />
              </div>
            </div>
          </div>

          <div className="wm-day__freeLabel">{t.freeTime}</div>
          <div className="wm-day__freeRow">
            {t.chips.map((chip) => {
              const { emoji, text } = chipParts(chip);
              return (
                <div key={chip} className="wm-day__freeChip">
                  <span className="wm-day__freeEmoji" aria-hidden>
                    {emoji}
                  </span>
                  <span className="wm-day__freeTxt">{text}</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
      <WmBottomNav active="day" labels={t.nav} />
    </div>
  );
}
