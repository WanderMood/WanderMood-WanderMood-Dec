"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  MockupBottomNav,
  MockupStatusBar,
  MockupTopBar,
} from "./MockupChrome";
import type { MockupLocale } from "./MockupChrome";
import { MOCK_IMG_COFFEE } from "./mockup-place-images";

function normalizeLocale(locale?: string): MockupLocale {
  const l = (locale ?? "en").toLowerCase();
  if (l === "nl" || l === "en" || l === "de" || l === "es" || l === "fr") return l;
  return "en";
}

type MoodyCopy = {
  title: string;
  subtitle: string;
  msg1: string;
  userMsg: string;
  msg2: string;
  placeMeta: string;
  placeName: string;
  typeCoffee: string;
  addBtn: string;
  moreBtn: string;
  msg3: string;
  composerPh: string;
  addDay: string;
};

const MOODY_TR: Record<MockupLocale, MoodyCopy> = {
  nl: {
    title: "Moody",
    subtitle: "Je stadskenner",
    msg1: "Hé ☀️ Vandaag lekker niksen of toch de stad in?",
    userMsg: "Iets gezelligs, niet te ver lopen",
    msg2: "Top — ik zie al twee plekken die perfect passen 😎",
    placeMeta: "★ 4.6 · 8 min lopen",
    placeName: "Hopper Espresso Bar",
    typeCoffee: "Specialty coffee",
    addBtn: "Voeg toe",
    moreBtn: "Meer",
    msg3: "Denk: flat white, mooi licht, nul haast.",
    composerPh: "Bericht…",
    addDay: "+ Dag",
  },
  en: {
    title: "Moody",
    subtitle: "Your city expert",
    msg1: "Morning ☀️ Sofa day or are we actually doing something fun?",
    userMsg: "Something cozy, not miles away",
    msg2: "Love it — I’ve already got a vibe-first pick for you ✨",
    placeMeta: "★ 4.6 · 8 min walk",
    placeName: "Hopper Espresso Bar",
    typeCoffee: "Specialty coffee",
    addBtn: "Add",
    moreBtn: "More",
    msg3: "Picture this: flat white, golden light, zero rush.",
    composerPh: "Message…",
    addDay: "+ Day",
  },
  de: {
    title: "Moody",
    subtitle: "Dein Stadtexperte",
    msg1: "Hey ☀️ Heute chillen oder raus in die Stadt?",
    userMsg: "Etwas Gemütliches, nicht zu weit",
    msg2: "Perfekt — ich hab schon zwei Spots im Kopf 😎",
    placeMeta: "★ 4.6 · 8 Min. Fußweg",
    placeName: "Hopper Espresso Bar",
    typeCoffee: "Specialty coffee",
    addBtn: "Hinzufügen",
    moreBtn: "Mehr",
    msg3: "Stell dir vor: Flat White, schönes Licht, null Stress.",
    composerPh: "Nachricht…",
    addDay: "+ Tag",
  },
  es: {
    title: "Moody",
    subtitle: "Tu experto de la ciudad",
    msg1: "Buenas ☀️ ¿Hoy modo sofá o salimos a mover el esqueleto?",
    userMsg: "Algo acogedor, no muy lejos",
    msg2: "Me encanta — ya tengo dos sitios con tu vibra 😎",
    placeMeta: "★ 4.6 · 8 min andando",
    placeName: "Hopper Espresso Bar",
    typeCoffee: "Specialty coffee",
    addBtn: "Añadir",
    moreBtn: "Más",
    msg3: "Imagina: flat white, buena luz, cero prisa.",
    composerPh: "Mensaje…",
    addDay: "+ Día",
  },
  fr: {
    title: "Moody",
    subtitle: "Ton expert de la ville",
    msg1: "Coucou ☀️ Canapé aujourd’hui ou on sort bouger un peu ?",
    userMsg: "Quelque chose de cosy, pas trop loin",
    msg2: "Nickel — j’ai déjà deux spots qui collent à ton mood 😎",
    placeMeta: "★ 4.6 · 8 min à pied",
    placeName: "Hopper Espresso Bar",
    typeCoffee: "Specialty coffee",
    addBtn: "Ajouter",
    moreBtn: "Plus",
    msg3: "Imagine : flat white, belle lumière, zéro stress.",
    composerPh: "Message…",
    addDay: "+ Jour",
  },
};

export function MoodyChatMockup({ locale }: { locale?: string }) {
  const loc = normalizeLocale(locale);
  const t = MOODY_TR[loc] ?? MOODY_TR.en;

  const pm = t.placeMeta.split(" · ");
  const ratingPart = pm[0] ?? "";
  const distPart = pm.slice(1).join(" · ");
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);

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
    setOn(true);
    setStep(1);
    q(() => setStep(2), 600);
    q(() => setStep(3), 1800);
    q(() => setStep(4), 3200);
    q(() => setStep(5), 4200);
    q(() => setStep(6), 5400);
    q(() => setStep(7), 6600);
    q(() => setStep(8), 8000);
    q(() => setStep(9), 10000);
    q(() => {
      setOn(false);
      setStep(0);
    }, 11500);
    q(() => runRef.current?.(), 13200);
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

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      className={`wm-mock wm-app wm-moody wm-moody--s${step} ${on ? "wm-mock--on" : ""}`}
    >
      <MockupStatusBar />
      <div className="wm-app__main">
        <div className="wm-mock__scroll wm-moody__scroll">
          <MockupTopBar
            title={t.title}
            leftExtra={
              <span className="wm-appTopBar__moodyAva" aria-hidden>
                M
              </span>
            }
          />

          <div className="wm-moody__thread">
            <div className="wm-moody__typing" aria-hidden>
              <span />
              <span />
              <span />
            </div>

            <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__msg1">
              {t.msg1}
            </div>

            <div className="wm-moody__bubble wm-moody__bubble--u">{t.userMsg}</div>

            <div className="wm-moody__typing wm-moody__typing--2" aria-hidden>
              <span />
              <span />
              <span />
            </div>

            <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__msg2">
              {t.msg2}
            </div>

            <div className="wm-moody__place">
              <div className="wm-placeCard wm-placeCard--coffee wm-moody__placeInner">
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
                    <span className="wm-placeCard__rating">{ratingPart}</span>
                  </div>
                  <div className="wm-placeCard__badge">{t.typeCoffee}</div>
                  <div className="wm-placeCard__bottom">
                    <span className="wm-placeCard__dist">
                      {distPart ? `📍 ${distPart}` : ""}
                    </span>
                    <span className="wm-placeCard__add">{t.addDay}</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__bubble--quote wm-moody__msg3">
              {t.msg3}
            </div>
          </div>

          <div className="wm-moody__composer" aria-hidden>
            <span className="wm-moody__composerPh">{t.composerPh}</span>
          </div>
        </div>
      </div>
      <MockupBottomNav active="moody" locale={locale} />
    </div>
  );
}
