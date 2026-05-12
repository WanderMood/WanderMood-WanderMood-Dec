"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { WmBottomNav, WmStatusBar } from "./mockup_chrome";

type Grad = "coffee" | "museum" | "park" | "bar";

function photoClass(g: Grad) {
  const map: Record<Grad, string> = {
    coffee: "wm-card__photo--coffee",
    museum: "wm-card__photo--museum",
    park: "wm-card__photo--park",
    bar: "wm-card__photo--bar",
  };
  return map[g];
}

function DayCardSm({
  grad,
  emoji,
  name,
  rating,
  badge,
  dist,
}: {
  grad: Grad;
  emoji: string;
  name: string;
  rating: string;
  badge: string;
  dist: string;
}) {
  return (
    <div className="wm-card wm-card--sm">
      <div className={`wm-card__photo ${photoClass(grad)}`} aria-hidden>
        {emoji}
      </div>
      <div className="wm-card__body">
        <div className="wm-card__top">
          <span className="wm-card__name">{name}</span>
          <span className="wm-card__rating">{rating}</span>
        </div>
        <span className="wm-card__badge">{badge}</span>
        <div className="wm-card__bottom">
          <span className="wm-card__dist">{dist}</span>
          <span className="wm-card__add">+ Dag</span>
        </div>
      </div>
    </div>
  );
}

export function MyDayMockup() {
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

  return (
    <div ref={root} role="presentation" aria-hidden className={cls}>
      <WmStatusBar />
      <div className="wm-mock__scroll">
        <header className="wm-topbar">
          <div className="wm-topbar__left">
            <span className="wm-topbar__title">Mijn Dag</span>
          </div>
          <div className="wm-topbar__bell" aria-hidden>
            🔔
            <span className="wm-topbar__bellDot" />
          </div>
        </header>

        <div className="wm-day__panorama">
          <div className="wm-day__dateWx">
            <div className="wm-day__dateLine">Zaterdag, 11 mei</div>
            <div className="wm-day__wxInline">☀️ 18°C · Rotterdam</div>
          </div>

          <div className="wm-day__hero">
            <span className="wm-day__heroEmoji" aria-hidden>
              ☕
            </span>
            <div className="wm-day__heroTop">
              <span className="wm-day__heroTime">09:00</span>
              <span className="wm-day__heroStatus">✓ Je bent er</span>
            </div>
            <div className="wm-day__heroName">Hopper Espresso Bar</div>
            <div className="wm-day__heroBot">
              <span className="wm-day__heroBadge">☕ Met Sarah</span>
              <span className="wm-day__heroLink">Routebeschrijving</span>
            </div>
          </div>

          <div className="wm-day__timeline">
            <div className="wm-day__line" aria-hidden />

            <div className="wm-day__between wm-day__between--1">
              <span className="wm-day__betweenPill">🚲 12 min fietsen</span>
            </div>

            <div className="wm-day__tlItem">
              <div className="wm-day__timeLbl">13:00</div>
              <div className="wm-day__dot wm-day__dot--out" aria-hidden />
              <div className="wm-day__tlCard wm-day__tlCard--1">
                <DayCardSm
                  grad="museum"
                  emoji="🏛️"
                  name="DEPOT Boijmans"
                  rating="★ 4.4"
                  badge="🎭 Met Sarah"
                  dist="📍 1.2 km"
                />
              </div>
            </div>

            <div className="wm-day__between wm-day__between--2">
              <span className="wm-day__betweenPill">🚴 18 min fietsen</span>
            </div>

            <div className="wm-day__tlItem">
              <div className="wm-day__timeLbl">15:30</div>
              <div className="wm-day__dot wm-day__dot--out" aria-hidden />
              <div className="wm-day__tlCard wm-day__tlCard--2">
                <DayCardSm
                  grad="park"
                  emoji="🌿"
                  name="Kralingse Bos"
                  rating="★ 4.7"
                  badge="Park"
                  dist="📍 3.4 km"
                />
              </div>
            </div>

            <div className="wm-day__between wm-day__between--3">
              <span className="wm-day__betweenPill">🚶 10 min lopen</span>
            </div>

            <div className="wm-day__tlItem">
              <div className="wm-day__timeLbl">19:00</div>
              <div className="wm-day__dot wm-day__dot--out" aria-hidden />
              <div className="wm-day__tlCard wm-day__tlCard--3">
                <DayCardSm
                  grad="bar"
                  emoji="🍷"
                  name="Wijnbar Sobre"
                  rating="★ 4.6"
                  badge="🍷 Met Sarah"
                  dist="📍 0.8 km"
                />
              </div>
            </div>
          </div>

          <div className="wm-day__freeLabel">Misschien leuk in je vrije tijd</div>
          <div className="wm-day__freeRow">
            <div className="wm-day__freeChip">
              <span className="wm-day__freeEmoji" aria-hidden>
                ☕
              </span>
              <span className="wm-day__freeTxt">
                Koffie
                <br />
                halen
              </span>
            </div>
            <div className="wm-day__freeChip">
              <span className="wm-day__freeEmoji" aria-hidden>
                🛍️
              </span>
              <span className="wm-day__freeTxt">Winkelen</span>
            </div>
            <div className="wm-day__freeChip">
              <span className="wm-day__freeEmoji" aria-hidden>
                🌳
              </span>
              <span className="wm-day__freeTxt">Wandelen</span>
            </div>
            <div className="wm-day__freeChip">
              <span className="wm-day__freeEmoji" aria-hidden>
                🎨
              </span>
              <span className="wm-day__freeTxt">Museum</span>
            </div>
          </div>
        </div>
      </div>
      <WmBottomNav active="day" />
    </div>
  );
}
