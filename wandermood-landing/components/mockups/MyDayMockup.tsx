"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  MockupBottomNav,
  MockupStatusBar,
  MockupTopBar,
} from "./MockupChrome";
import type { MockupLocale } from "./MockupChrome";
import {
  MOCK_IMG_COFFEE,
  MOCK_IMG_MUSEUM,
  MOCK_IMG_PARK,
  MOCK_IMG_WINE,
} from "./mockup-place-images";

function normalizeLocale(locale?: string): MockupLocale {
  const l = (locale ?? "en").toLowerCase();
  if (l === "nl" || l === "en" || l === "de" || l === "es" || l === "fr") return l;
  return "en";
}

type DayCopy = {
  title: string;
  date: string;
  weather: string;
  arrived: string;
  heroPlace: string;
  withSarah: string;
  routeLink: string;
  bike1: string;
  bike2: string;
  walk: string;
  act1: string;
  act2: string;
  act3: string;
  act1Meta: string;
  act3Meta: string;
  dist1: string;
  dist2: string;
  dist3: string;
  typeMuseum: string;
  typePark: string;
  typeWine: string;
  ratings: [string, string, string];
  addDay: string;
};

const MY_DAY_TR: Record<MockupLocale, DayCopy> = {
  nl: {
    title: "Mijn Dag",
    date: "Zaterdag, 11 mei",
    weather: "☀️ 18°C · Rotterdam · Lekker dagje uit",
    arrived: "✓ Je bent er",
    heroPlace: "Hopper Espresso Bar",
    withSarah: "Met Sarah",
    routeLink: "Routebeschrijving",
    bike1: "🚲 12 min fietsen",
    bike2: "🚴 18 min fietsen",
    walk: "🚶 10 min lopen",
    act1: "DEPOT Boijmans",
    act2: "Kralingse Bos",
    act3: "Wijnbar Sobre",
    act1Meta: "🎭 Met Sarah",
    act3Meta: "🍷 Met Sarah",
    dist1: "📍 1,2 km",
    dist2: "📍 3,4 km",
    dist3: "📍 0,8 km",
    typeMuseum: "Museum",
    typePark: "Park",
    typeWine: "Wijnbar",
    ratings: ["★ 4.4", "★ 4.7", "★ 4.5"],
    addDay: "+ Dag",
  },
  en: {
    title: "My Day",
    date: "Saturday, 11 May",
    weather: "☀️ 18°C · Rotterdam · Great day out",
    arrived: "✓ You're here",
    heroPlace: "Hopper Espresso Bar",
    withSarah: "With Sarah",
    routeLink: "Directions",
    bike1: "🚲 12 min bike",
    bike2: "🚴 18 min bike",
    walk: "🚶 10 min walk",
    act1: "DEPOT Boijmans",
    act2: "Kralingse Bos",
    act3: "Wijnbar Sobre",
    act1Meta: "🎭 With Sarah",
    act3Meta: "🍷 With Sarah",
    dist1: "📍 1.2 km",
    dist2: "📍 3.4 km",
    dist3: "📍 0.8 km",
    typeMuseum: "Museum",
    typePark: "Park",
    typeWine: "Wine bar",
    ratings: ["★ 4.4", "★ 4.7", "★ 4.5"],
    addDay: "+ Day",
  },
  de: {
    title: "Mein Tag",
    date: "Samstag, 11. Mai",
    weather: "☀️ 18°C · Rotterdam · Schöner Tag",
    arrived: "✓ Du bist da",
    heroPlace: "Hopper Espresso Bar",
    withSarah: "Mit Sarah",
    routeLink: "Route",
    bike1: "🚲 12 Min. Fahrrad",
    bike2: "🚴 18 Min. Fahrrad",
    walk: "🚶 10 Min. Fußweg",
    act1: "DEPOT Boijmans",
    act2: "Kralingse Bos",
    act3: "Wijnbar Sobre",
    act1Meta: "🎭 Mit Sarah",
    act3Meta: "🍷 Mit Sarah",
    dist1: "📍 1,2 km",
    dist2: "📍 3,4 km",
    dist3: "📍 0,8 km",
    typeMuseum: "Museum",
    typePark: "Park",
    typeWine: "Weinbar",
    ratings: ["★ 4.4", "★ 4.7", "★ 4.5"],
    addDay: "+ Tag",
  },
  es: {
    title: "Mi Día",
    date: "Sábado, 11 mayo",
    weather: "☀️ 18°C · Rotterdam · Buen día",
    arrived: "✓ Ya estás",
    heroPlace: "Hopper Espresso Bar",
    withSarah: "Con Sarah",
    routeLink: "Indicaciones",
    bike1: "🚲 12 min bici",
    bike2: "🚴 18 min bici",
    walk: "🚶 10 min andando",
    act1: "DEPOT Boijmans",
    act2: "Kralingse Bos",
    act3: "Wijnbar Sobre",
    act1Meta: "🎭 Con Sarah",
    act3Meta: "🍷 Con Sarah",
    dist1: "📍 1,2 km",
    dist2: "📍 3,4 km",
    dist3: "📍 0,8 km",
    typeMuseum: "Museo",
    typePark: "Parque",
    typeWine: "Bar de vinos",
    ratings: ["★ 4.4", "★ 4.7", "★ 4.5"],
    addDay: "+ Día",
  },
  fr: {
    title: "Ma Journée",
    date: "Samedi, 11 mai",
    weather: "☀️ 18°C · Rotterdam · Belle journée",
    arrived: "✓ Tu y es",
    heroPlace: "Hopper Espresso Bar",
    withSarah: "Avec Sarah",
    routeLink: "Itinéraire",
    bike1: "🚲 12 min vélo",
    bike2: "🚴 18 min vélo",
    walk: "🚶 10 min à pied",
    act1: "DEPOT Boijmans",
    act2: "Kralingse Bos",
    act3: "Wijnbar Sobre",
    act1Meta: "🎭 Avec Sarah",
    act3Meta: "🍷 Avec Sarah",
    dist1: "📍 1,2 km",
    dist2: "📍 3,4 km",
    dist3: "📍 0,8 km",
    typeMuseum: "Musée",
    typePark: "Parc",
    typeWine: "Bar à vin",
    ratings: ["★ 4.4", "★ 4.7", "★ 4.5"],
    addDay: "+ Jour",
  },
};

function PlacePhotoImg({ src }: { src: string }) {
  return (
    <img
      src={src}
      alt=""
      style={{
        width: "64px",
        height: "100%",
        objectFit: "cover",
        display: "block",
        flexShrink: 0,
        borderRadius: "14px 0 0 14px",
      }}
    />
  );
}

export function MyDayMockup({ locale }: { locale?: string }) {
  const loc = normalizeLocale(locale);
  const t = MY_DAY_TR[loc] ?? MY_DAY_TR.en;

  const root = useRef<HTMLDivElement>(null);
  const outerRef = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [pulse, setPulse] = useState(false);
  const [bright, setBright] = useState(false);
  const [scrollSim, setScrollSim] = useState(false);

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
    setPulse(false);
    setBright(false);
    setScrollSim(false);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 400);
    q(() => setStep(3), 900);
    q(() => setStep(4), 1800);
    q(() => setStep(5), 2400);
    q(() => setStep(6), 2800);
    q(() => setStep(7), 3200);
    q(() => setStep(8), 3600);
    q(() => setStep(9), 4000);
    q(() => {
      setPulse(true);
      setBright(true);
    }, 7500);
    q(() => {
      setPulse(false);
      setBright(false);
    }, 8200);
    q(() => setScrollSim(true), 9000);
    q(() => setScrollSim(false), 11000);
    q(() => {
      setOn(false);
      setStep(0);
    }, 12000);
    q(() => runRef.current?.(), 13700);
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
    if (!scrollSim) return;
    const el = outerRef.current;
    if (!el) return;
    const id = window.requestAnimationFrame(() => {
      const max = el.scrollHeight - el.clientHeight;
      el.scrollTo({ top: max > 0 ? max : 0, behavior: "smooth" });
    });
    return () => cancelAnimationFrame(id);
  }, [scrollSim]);

  const cls = [
    "wm-mock",
    "wm-app",
    "wm-day",
    `wm-day--s${step}`,
    on ? "wm-mock--on" : "",
    pulse ? "wm-day--pulseHero" : "",
    bright ? "wm-day--brightCheck" : "",
    scrollSim ? "wm-day--scrollSim" : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div ref={root} role="presentation" aria-hidden className={cls}>
      <MockupStatusBar />
      <div className="wm-app__main">
        <div ref={outerRef} className="wm-mock__scroll wm-day__outer">
          <MockupTopBar
            title={t.title}
            right={
              <span className="wm-appTopBar__bellWrap" aria-hidden>
                🔔
                <span className="wm-appTopBar__bellDot" />
              </span>
            }
          />

          <div className="wm-day__intro">
            <div className="wm-day__date">{t.date}</div>
            <div className="wm-day__wx">{t.weather}</div>
          </div>

          <div className="wm-day__hero">
            <div className="wm-day__heroAccent" aria-hidden />
            <div className="wm-day__heroDeco" aria-hidden>
              ☕
            </div>
            <div className="wm-day__heroTop">
              <span className="wm-day__heroTime">09:00</span>
              <span className="wm-day__heroHere">
                <span className="wm-day__hereDot" aria-hidden />
                {t.arrived}
              </span>
            </div>
            <div className="wm-day__heroName">{t.heroPlace}</div>
            <div className="wm-day__heroBottom">
              <span className="wm-day__heroBadge">
                ☕ {t.withSarah}
              </span>
              <span className="wm-day__heroRoute">{t.routeLink}</span>
            </div>
          </div>

          <div className="wm-day__track">
            <div className="wm-day__timeline">
              <div className="wm-day__line" aria-hidden />

              <div className="wm-day__bridge wm-day__bridge--mid">{t.bike1}</div>

              <div className="wm-day__slot">
                <div className="wm-day__timeCol">
                  <span className="wm-day__time">13:00</span>
                  <span className="wm-day__dot wm-day__dot--fill" aria-hidden />
                </div>
                <div className="wm-placeCard wm-placeCard--museum wm-dayCard">
                  <div className="wm-placeCard__photo">
                    <PlacePhotoImg src={MOCK_IMG_MUSEUM} />
                  </div>
                  <div className="wm-placeCard__body">
                    <div className="wm-placeCard__top">
                      <span className="wm-placeCard__name">{t.act1}</span>
                      <span className="wm-placeCard__rating">{t.ratings[0]}</span>
                    </div>
                    <div className="wm-placeCard__badge">{t.typeMuseum}</div>
                    <div className="wm-placeCard__bottom">
                      <span className="wm-placeCard__dist">{t.dist1}</span>
                      <span className="wm-placeCard__add">{t.addDay}</span>
                    </div>
                  </div>
                  <span className="wm-dayCard__with">{t.act1Meta}</span>
                </div>
              </div>

              <div className="wm-day__bridge wm-day__bridge--mid">{t.bike2}</div>

              <div className="wm-day__slot">
                <div className="wm-day__timeCol">
                  <span className="wm-day__time">15:30</span>
                  <span className="wm-day__dot wm-day__dot--outline" aria-hidden />
                </div>
                <div className="wm-placeCard wm-placeCard--park wm-dayCard">
                  <div className="wm-placeCard__photo">
                    <PlacePhotoImg src={MOCK_IMG_PARK} />
                  </div>
                  <div className="wm-placeCard__body">
                    <div className="wm-placeCard__top">
                      <span className="wm-placeCard__name">{t.act2}</span>
                      <span className="wm-placeCard__rating">{t.ratings[1]}</span>
                    </div>
                    <div className="wm-placeCard__badge">{t.typePark}</div>
                    <div className="wm-placeCard__bottom">
                      <span className="wm-placeCard__dist">{t.dist2}</span>
                      <span className="wm-placeCard__add">{t.addDay}</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="wm-day__bridge wm-day__bridge--mid">{t.walk}</div>

              <div className="wm-day__slot">
                <div className="wm-day__timeCol">
                  <span className="wm-day__time">19:00</span>
                  <span className="wm-day__dot wm-day__dot--outline" aria-hidden />
                </div>
                <div className="wm-placeCard wm-placeCard--bar wm-dayCard">
                  <div className="wm-placeCard__photo">
                    <PlacePhotoImg src={MOCK_IMG_WINE} />
                  </div>
                  <div className="wm-placeCard__body">
                    <div className="wm-placeCard__top">
                      <span className="wm-placeCard__name">{t.act3}</span>
                      <span className="wm-placeCard__rating">{t.ratings[2]}</span>
                    </div>
                    <div className="wm-placeCard__badge">{t.typeWine}</div>
                    <div className="wm-placeCard__bottom">
                      <span className="wm-placeCard__dist">{t.dist3}</span>
                      <span className="wm-placeCard__add">{t.addDay}</span>
                    </div>
                  </div>
                  <span className="wm-dayCard__with">{t.act3Meta}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <MockupBottomNav active="myDay" locale={locale} />
    </div>
  );
}
