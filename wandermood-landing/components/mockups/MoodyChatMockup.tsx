"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { WmBottomNav, type WmNavLabels } from "./mockup_chrome";

type MockLocale = "nl" | "en" | "de" | "es" | "fr";

function mockLocale(locale: string): MockLocale {
  const l = locale?.toLowerCase() ?? "nl";
  if (l === "en" || l === "de" || l === "es" || l === "fr") return l;
  return "nl";
}

type MoodyV1 = {
  nav: WmNavLabels;
  title: string;
  bubble1: string;
  bubbleUser: string;
  bubble2: string;
  hint: string;
};

const MOODY_V1: Record<MockLocale, MoodyV1> = {
  nl: {
    nav: {
      day: "Mijn Dag",
      explore: "Explore",
      moody: "Moody",
      plans: "Plans",
      profile: "Profiel",
    },
    title: "Moody",
    bubble1: "Waar heb je zin in vandaag?",
    bubbleUser: "Gezellig koffie in Rotterdam",
    bubble2: "Top — ik zoek plekken voor je.",
    hint: "Tip: stel gerust een vervolgvraag.",
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
    bubble1: "What are you in the mood for today?",
    bubbleUser: "Cozy coffee in Rotterdam",
    bubble2: "Nice — I'll find places for you.",
    hint: "Tip: feel free to ask a follow-up.",
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
    bubble1: "Worauf hast du heute Lust?",
    bubbleUser: "Gemütlicher Kaffee in Rotterdam",
    bubble2: "Super — ich suche Orte für dich.",
    hint: "Tipp: stell ruhig eine Nachfrage.",
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
    bubble1: "¿Qué te apetece hoy?",
    bubbleUser: "Café acogedor en Rotterdam",
    bubble2: "Genial — busco sitios para ti.",
    hint: "Tip: puedes hacer una pregunta de seguimiento.",
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
    bubble1: "Tu as envie de quoi aujourd'hui ?",
    bubbleUser: "Un café cosy à Rotterdam",
    bubble2: "Top — je te trouve des adresses.",
    hint: "Astuce : pose une question de suite.",
  },
};

export function MoodyChatMockup({ locale }: { locale: string }) {
  const t = MOODY_V1[mockLocale(locale)];
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
    q(() => setStep(2), 480);
    q(() => setStep(3), 960);
    q(() => setStep(4), 1500);
    q(() => setStep(5), 2100);
    q(() => {
      setOn(false);
      setStep(0);
    }, 5200);
    q(() => runRef.current?.(), 5200 + 5200);
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
      className={`wm-mock wm-moody wm-moody--s${step} ${on ? "wm-mock--on" : ""}`}
    >
      <div className="wm-mock__status">
        <span>9:41</span>
        <span>●●●●</span>
      </div>
      <div className="wm-mock__scroll">
        <div className="wm-moody__title">{t.title}</div>
        <div className="wm-moody__thread">
          <div className="wm-moody__bubble wm-moody__bubble--m">{t.bubble1}</div>
          <div className="wm-moody__bubble wm-moody__bubble--u">
            {t.bubbleUser}
          </div>
          <div className="wm-moody__bubble wm-moody__bubble--m">{t.bubble2}</div>
        </div>
        <div className="wm-moody__hint">{t.hint}</div>
      </div>
      <WmBottomNav active="moody" labels={t.nav} />
    </div>
  );
}
