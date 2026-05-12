"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { WmBottomNav, WmStatusBar, type WmNavLabels } from "./mockup_chrome";

type MockLocale = "nl" | "en" | "de" | "es" | "fr";

function mockLocale(locale: string): MockLocale {
  const l = locale?.toLowerCase() ?? "nl";
  if (l === "en" || l === "de" || l === "es" || l === "fr") return l;
  return "nl";
}

const IMG_COFFEE =
  "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=160&h=200&fit=crop&q=70";

type MoodyT = {
  nav: WmNavLabels;
  title: string;
  subtitle: string;
  msg1: string;
  userMsg: string;
  msg2: string;
  placeMeta: string;
  addBtn: string;
  moreBtn: string;
  msg3: string;
  typeCoffee: string;
  inputPh: string;
};

const MOODY: Record<MockLocale, MoodyT> = {
  nl: {
    nav: {
      day: "Mijn Dag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profiel",
    },
    title: "Moody",
    subtitle: "Je stadskenner",
    msg1: "Goedemorgen ☀️ Luie vibe vandaag of wil je echt iets doen?",
    userMsg: "Iets gezelligs, niet te ver",
    msg2: "Dan weet ik precies waar ik je heen stuur 💚",
    placeMeta: "★ 4.6 · 8 min lopen",
    addBtn: "Voeg toe",
    moreBtn: "Meer",
    msg3: "Flat white, goed licht, geen haast.",
    typeCoffee: "Specialty coffee",
    inputPh: "Bericht aan Moody…",
  },
  en: {
    nav: {
      day: "My Day",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profile",
    },
    title: "Moody",
    subtitle: "Your city expert",
    msg1:
      "Good morning ☀️ Lazy day or do you want to actually do something?",
    userMsg: "Something cozy, not too far",
    msg2: "Then I know exactly where to send you 💚",
    placeMeta: "★ 4.6 · 8 min walk",
    addBtn: "Add",
    moreBtn: "More",
    msg3: "Flat white, good light, no rush.",
    typeCoffee: "Specialty coffee",
    inputPh: "Message Moody…",
  },
  de: {
    nav: {
      day: "Mein Tag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    title: "Moody",
    subtitle: "Dein Stadtexperte",
    msg1: "Guten Morgen ☀️ Fauler Tag oder willst du was unternehmen?",
    userMsg: "Etwas Gemütliches, nicht zu weit",
    msg2: "Dann weiß ich genau wohin 💚",
    placeMeta: "★ 4.6 · 8 Min. Fußweg",
    addBtn: "Hinzufügen",
    moreBtn: "Mehr",
    msg3: "Flat White, gutes Licht, kein Stress.",
    typeCoffee: "Specialty coffee",
    inputPh: "Nachricht an Moody…",
  },
  es: {
    nav: {
      day: "Mi Día",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Perfil",
    },
    title: "Moody",
    subtitle: "Tu experto de la ciudad",
    msg1: "Buenos días ☀️ ¿Día tranquilo o quieres hacer algo?",
    userMsg: "Algo acogedor, no muy lejos",
    msg2: "Entonces sé exactamente adónde enviarte 💚",
    placeMeta: "★ 4.6 · 8 min andando",
    addBtn: "Añadir",
    moreBtn: "Más",
    msg3: "Flat white, buena luz, sin prisas.",
    typeCoffee: "Specialty coffee",
    inputPh: "Mensaje a Moody…",
  },
  fr: {
    nav: {
      day: "Ma Journée",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profil",
    },
    title: "Moody",
    subtitle: "Ton expert de la ville",
    msg1:
      "Bonjour ☀️ Journée tranquille ou tu veux faire quelque chose?",
    userMsg: "Quelque chose de cosy, pas trop loin",
    msg2: "Alors je sais exactement où t'envoyer 💚",
    placeMeta: "★ 4.6 · 8 min à pied",
    addBtn: "Ajouter",
    moreBtn: "Plus",
    msg3: "Flat white, bonne lumière, sans pression.",
    typeCoffee: "Specialty coffee",
    inputPh: "Message à Moody…",
  },
};

export function MoodyChatMockup({ locale }: { locale: string }) {
  const t = MOODY[mockLocale(locale)];
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
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
    setExiting(false);
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
    q(() => setExiting(true), 11500);
    q(() => {
      setExiting(false);
      setOn(false);
      setStep(0);
    }, 13000);
    q(() => runRef.current?.(), 13500);
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

  const showTyping1 = step === 2;
  const showMsg1 = step >= 3;
  const showUser = step >= 4;
  const showTyping2 = step === 5;
  const showMsg2 = step >= 6;
  const showCard = step >= 7;
  const showMsg3 = step >= 8;

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      className={`wm-mock wm-moody wm-moody--s${Math.min(step, 9)} ${on ? "wm-mock--on" : ""} ${exiting ? "wm-mock--exiting" : ""}`}
    >
      <WmStatusBar />
      <div className="wm-mock__scroll wm-moody__shell">
        <header className="wm-topbar">
          <div className="wm-topbar__left">
            <div className="wm-topbar__avatar" aria-hidden>
              M
            </div>
            <div className="wm-topbar__headlines">
              <span className="wm-topbar__title">{t.title}</span>
              <span className="wm-topbar__sub">{t.subtitle}</span>
            </div>
          </div>
        </header>

        <div className="wm-moody__thread">
          {showTyping1 ? (
            <div className="wm-moody__typing" aria-hidden>
              <span />
              <span />
              <span />
            </div>
          ) : null}

          {showMsg1 ? (
            <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__bubble--in">
              {t.msg1}
            </div>
          ) : null}

          {showUser ? (
            <div className="wm-moody__bubble wm-moody__bubble--u wm-moody__bubble--in">
              {t.userMsg}
            </div>
          ) : null}

          {showTyping2 ? (
            <div className="wm-moody__typing" aria-hidden>
              <span />
              <span />
              <span />
            </div>
          ) : null}

          {showMsg2 ? (
            <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__bubble--in">
              {t.msg2}
            </div>
          ) : null}

          {showCard ? (
            <div className="wm-card wm-moody__placeCard wm-moody__placeCard--in">
              <img
                src={IMG_COFFEE}
                alt=""
                className="wm-card__photoImg"
                width={80}
                height={100}
              />
              <div className="wm-card__body">
                <div className="wm-card__top">
                  <span className="wm-card__name">Hopper Espresso Bar</span>
                  <span className="wm-card__rating">★ 4.6</span>
                </div>
                <span className="wm-card__badge">{t.typeCoffee}</span>
                <div className="wm-moody__placeMeta">{t.placeMeta}</div>
                <div className="wm-moody__placeBtns">
                  <button type="button" className="wm-moody__btn wm-moody__btn--pri">
                    {t.addBtn}
                  </button>
                  <button type="button" className="wm-moody__btn wm-moody__btn--sec">
                    {t.moreBtn}
                  </button>
                </div>
              </div>
            </div>
          ) : null}

          {showMsg3 ? (
            <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__bubble--soft wm-moody__bubble--in">
              {t.msg3}
            </div>
          ) : null}
        </div>

        <div className="wm-moody__inputBar">{t.inputPh}</div>
      </div>
      <WmBottomNav active="moody" labels={t.nav} />
    </div>
  );
}
