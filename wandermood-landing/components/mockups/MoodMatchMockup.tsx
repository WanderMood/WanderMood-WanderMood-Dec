"use client";

import { useCallback, useEffect, useId, useRef, useState } from "react";
import { WmBottomNav, WmStatusBar } from "./mockup_chrome";

const MOODY_LINE =
  "Ik heb plekken gevonden die voor jullie allebei werken 💚";

export function MoodMatchMockup() {
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
    if (typeof cancelAnimationFrame === "function" && raf.current) {
      cancelAnimationFrame(raf.current);
      raf.current = 0;
    }
    setTyped("");
    setScore(0);
    setSvgKey((k) => k + 1);
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
    if (step < 4) return;
    const t0 = performance.now();
    const tick = (now: number) => {
      const u = Math.min(1, (now - t0) / 2000);
      setScore(Math.round(78 * u));
      if (u < 1) raf.current = requestAnimationFrame(tick);
    };
    raf.current = requestAnimationFrame(tick);
    return () => {
      if (raf.current) cancelAnimationFrame(raf.current);
      raf.current = 0;
    };
  }, [step, svgKey]);

  useEffect(() => {
    if (step !== 7) return;
    let i = 0;
    const id = window.setInterval(() => {
      i += 1;
      setTyped(MOODY_LINE.slice(0, i));
      if (i >= MOODY_LINE.length) {
        clearInterval(id);
      }
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
    step >= 4 ? "wm-mm--ring" : "",
    on ? "wm-mock--on" : "",
    exiting ? "wm-mock--exiting" : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div ref={root} role="presentation" aria-hidden className={rootCls}>
      <WmStatusBar />
      <div className="wm-mock__scroll">
        <header className="wm-topbar">
          <div className="wm-topbar__left">
            <span className="wm-topbar__title">Mood Match</span>
          </div>
        </header>

        <div className="wm-mm__users">
          <div className="wm-mm__user">
            <div className="wm-mm__av wm-mm__av--e">E</div>
            <span className="wm-mm__userLbl">Jij</span>
          </div>
          <div className="wm-mm__dash" aria-hidden />
          <div className="wm-mm__heart" aria-hidden>
            💚
          </div>
          <div className="wm-mm__dash" aria-hidden />
          <div className="wm-mm__user">
            <div className="wm-mm__av wm-mm__av--s">S</div>
            <span className="wm-mm__userLbl">Sarah</span>
          </div>
        </div>

        <div className="wm-mm__ringWrap">
          <svg
            key={svgKey}
            className="wm-mm__ring"
            viewBox="0 0 120 120"
            width={110}
            height={110}
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
            <text x={60} y={58} textAnchor="middle" className="wm-mm__score">
              {score}
            </text>
            <text x={60} y={74} textAnchor="middle" className="wm-mm__subring">
              match
            </text>
          </svg>
        </div>

        <div className="wm-mm__balance">Goede balans</div>
        <div className="wm-mm__pills">
          <span className="wm-mm__pill">🎭 Cultureel</span>
          <span className="wm-mm__pill">💕 Romantisch</span>
        </div>

        <div className="wm-mm__moody">
          <div className="wm-mm__mav">M</div>
          <div className="wm-mm__mtext">{typed}</div>
        </div>

        <div
          className={`wm-mm__planRow ${step >= 8 ? "wm-mm__planRow--in" : ""}`}
        >
          <div className="wm-mm__planHead">🌅 Ochtend</div>
          <div className="wm-card wm-card--sm">
            <div className="wm-card__photo wm-card__photo--coffee" aria-hidden>
              ☕
            </div>
            <div className="wm-card__body">
              <div className="wm-card__top">
                <span className="wm-card__name">Hopper Espresso Bar</span>
                <span className="wm-card__rating">★ 4.6</span>
              </div>
              <span className="wm-card__badge">Specialty coffee</span>
              <div className="wm-card__bottom">
                <span className="wm-card__dist">
                  09:00 · Specialty coffee · 📍 0.8km
                </span>
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
          <div className="wm-mm__planHead">☀️ Middag</div>
          <div className="wm-card wm-card--sm">
            <div className="wm-card__photo wm-card__photo--museum" aria-hidden>
              🏛️
            </div>
            <div className="wm-card__body">
              <div className="wm-card__top">
                <span className="wm-card__name">DEPOT Boijmans</span>
                <span className="wm-card__rating">★ 4.4</span>
              </div>
              <span className="wm-card__badge">Museum</span>
              <div className="wm-card__bottom">
                <span className="wm-card__dist">
                  13:00 · Museum · 📍 2.1km
                </span>
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
          <div className="wm-mm__planHead">🌆 Avond</div>
          <div className="wm-card wm-card--sm">
            <div className="wm-card__photo wm-card__photo--bar" aria-hidden>
              🍷
            </div>
            <div className="wm-card__body">
              <div className="wm-card__top">
                <span className="wm-card__name">Wijnbar Sobre</span>
                <span className="wm-card__rating">★ 4.6</span>
              </div>
              <span className="wm-card__badge">Wijnbar</span>
              <div className="wm-card__bottom">
                <span className="wm-card__dist">
                  19:00 · Wijnbar · 📍 1.2km
                </span>
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
            Plan bevestigen →
          </button>
        </div>
      </div>
      <WmBottomNav active="plans" />
    </div>
  );
}
