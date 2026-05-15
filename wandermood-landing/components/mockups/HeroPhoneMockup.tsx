"use client";

import { MockupStatusBar } from "./MockupChrome";
import type { MockupLocale } from "./MockupChrome";
import { MOCK_IMG_COFFEE } from "./mockup-place-images";

function normalizeLocale(locale?: string): MockupLocale {
  const l = (locale ?? "en").toLowerCase();
  if (l === "nl" || l === "en" || l === "de" || l === "es" || l === "fr") return l;
  return "en";
}

type HeroCopy = {
  location: string;
  local: string;
  traveling: string;
  question: string;
  chipCozy: string;
  chipFoodie: string;
  chipCurious: string;
  moodyLine: string;
  placeName: string;
  placeType: string;
  walkDist: string;
  rating: string;
  addCta: string;
  tagline: string;
};

const HERO_TR: Record<MockupLocale, HeroCopy> = {
  nl: {
    location: "Rotterdam · 18°",
    local: "Lokaal",
    traveling: "Op reis",
    question: "Waar heb je zin in?",
    chipCozy: "Gezellig",
    chipFoodie: "Foodie",
    chipCurious: "Nieuwsgierig",
    moodyLine: "Top — ik heb iets dichtbij voor je.",
    placeName: "Hopper Espresso Bar",
    placeType: "Specialty coffee",
    walkDist: "📍 8 min lopen",
    rating: "★ 4.7",
    addCta: "+ In Mijn Dag",
    tagline: "Flat white, mooi licht, nul haast.",
  },
  en: {
    location: "Rotterdam · 18°",
    local: "Local",
    traveling: "Traveling",
    question: "What are you in the mood for?",
    chipCozy: "Cozy",
    chipFoodie: "Foodie",
    chipCurious: "Curious",
    moodyLine: "Say less. I found something nearby.",
    placeName: "Hopper Espresso Bar",
    placeType: "Specialty coffee",
    walkDist: "📍 8 min walk",
    rating: "★ 4.7",
    addCta: "+ Add to My Day",
    tagline: "Flat white, good light, no rush.",
  },
  de: {
    location: "Rotterdam · 18°",
    local: "Lokal",
    traveling: "Unterwegs",
    question: "Was hast du heute Lust auf?",
    chipCozy: "Gemütlich",
    chipFoodie: "Foodie",
    chipCurious: "Neugierig",
    moodyLine: "Alles klar — ich hab was in der Nähe.",
    placeName: "Hopper Espresso Bar",
    placeType: "Specialty coffee",
    walkDist: "📍 8 Min. Fußweg",
    rating: "★ 4.7",
    addCta: "+ Zu Mein Tag",
    tagline: "Flat White, schönes Licht, null Stress.",
  },
  es: {
    location: "Rotterdam · 18°",
    local: "Local",
    traveling: "De viaje",
    question: "¿Qué te apetece?",
    chipCozy: "Acogedor",
    chipFoodie: "Foodie",
    chipCurious: "Curioso",
    moodyLine: "Hecho — encontré algo cerca.",
    placeName: "Hopper Espresso Bar",
    placeType: "Specialty coffee",
    walkDist: "📍 8 min andando",
    rating: "★ 4.7",
    addCta: "+ A Mi día",
    tagline: "Flat white, buena luz, cero prisa.",
  },
  fr: {
    location: "Rotterdam · 18°",
    local: "Local",
    traveling: "En voyage",
    question: "Tu as envie de quoi ?",
    chipCozy: "Cosy",
    chipFoodie: "Foodie",
    chipCurious: "Curieux",
    moodyLine: "Compris — j’ai trouvé un truc tout près.",
    placeName: "Hopper Espresso Bar",
    placeType: "Specialty coffee",
    walkDist: "📍 8 min à pied",
    rating: "★ 4.7",
    addCta: "+ Ma journée",
    tagline: "Flat white, belle lumière, zéro stress.",
  },
};

export function HeroPhoneMockup({ locale }: { locale?: string }) {
  const loc = normalizeLocale(locale);
  const t = HERO_TR[loc] ?? HERO_TR.en;

  return (
    <div
      role="presentation"
      aria-hidden
      className="wm-mock wm-app wm-hero wm-mock--on"
    >
      <MockupStatusBar />
      <div className="wm-app__main">
        <div className="wm-mock__scroll wm-hero__scroll">
          <div className="wm-hero__locRow">
            <span className="wm-hero__locPin" aria-hidden>
              📍
            </span>
            <span className="wm-hero__locText">{t.location}</span>
            <span className="wm-hero__locChev" aria-hidden>
              ▾
            </span>
            <span className="wm-hero__spacer" />
            <span className="wm-hero__bell" aria-hidden>
              🔔
            </span>
          </div>

          <div className="wm-hero__toggle" aria-hidden>
            <span className="wm-hero__toggleSeg wm-hero__toggleSeg--on">{t.local}</span>
            <span className="wm-hero__toggleSeg">{t.traveling}</span>
          </div>

          <p className="wm-hero__question">{t.question}</p>

          <div className="wm-hero__chips" aria-hidden>
            <span className="wm-hero__chip wm-hero__chip--on">☺️ {t.chipCozy}</span>
            <span className="wm-hero__chip">🍽️ {t.chipFoodie}</span>
            <span className="wm-hero__chip">🔍 {t.chipCurious}</span>
          </div>

          <div className="wm-hero__bubble">{t.moodyLine}</div>

          <div className="wm-placeCard wm-placeCard--coffee wm-hero__card">
            <div className="wm-placeCard__photo">
              <img
                src={MOCK_IMG_COFFEE}
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
            </div>
            <div className="wm-placeCard__body">
              <div className="wm-placeCard__top">
                <span className="wm-placeCard__name">{t.placeName}</span>
                <span className="wm-placeCard__rating">{t.rating}</span>
              </div>
              <div className="wm-placeCard__badge">{t.placeType}</div>
              <div className="wm-placeCard__bottom">
                <span className="wm-placeCard__dist">{t.walkDist}</span>
                <span className="wm-placeCard__add">{t.addCta}</span>
              </div>
            </div>
          </div>

          <p className="wm-hero__tagline">{t.tagline}</p>
        </div>
      </div>
    </div>
  );
}
