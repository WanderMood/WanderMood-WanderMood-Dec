"use client";

import { useCallback, useEffect, useId, useRef, useState } from "react";

const MOODY_LINE =
  "Ik heb plekken gevonden die voor jullie allebei werken.";

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
    setOn(true);
    setStep(1);
    q(() => setStep(2), 420);
    q(() => setStep(3), 820);
    q(() => setStep(4), 1180);
    q(() => setStep(5), 1520);
    q(() => setStep(7), 3120);
    q(() => setStep(8), 3480);
    q(() => setStep(9), 3820);
    q(() => {
      setOn(false);
      setStep(0);
      setTyped("");
      setScore(0);
    }, 8480);
    q(() => runRef.current?.(), 8480 + 5000);
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
    if (step < 5) return;
    const t0 = performance.now();
    const tick = (now: number) => {
      const u = Math.min(1, (now - t0) / 1500);
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
    if (step !== 9) return;
    let i = 0;
    const id = window.setInterval(() => {
      i += 1;
      setTyped(MOODY_LINE.slice(0, i));
      if (i >= MOODY_LINE.length) {
        clearInterval(id);
        setStep(10);
      }
    }, 30);
    return () => clearInterval(id);
  }, [step]);

  const displayStep = step >= 10 ? 10 : step;

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      className={`wm-mock wm-mm wm-mm--s${displayStep} ${on ? "wm-mock--on" : ""}`}
    >
      <div className="wm-mock__status">
        <span>9:41</span>
        <span>●●●●</span>
      </div>
      <div className="wm-mock__scroll">
        <div className="wm-mm__label">Mood Match</div>
        <div className="wm-mm__avatars">
          <div className="wm-mm__av wm-mm__av--e">E</div>
          <div className="wm-mm__heart" aria-hidden>
            💚
          </div>
          <div className="wm-mm__av wm-mm__av--s">S</div>
        </div>
        <div className="wm-mm__ringWrap">
          <svg
            key={svgKey}
            className="wm-mm__ring"
            viewBox="0 0 120 120"
            width={100}
            height={100}
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
            <text x={60} y={57} textAnchor="middle" className="wm-mm__score">
              {score}
            </text>
            <text x={60} y={72} textAnchor="middle" className="wm-mm__subring">
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
        <div className="wm-mm__plans">
          <div className="wm-mm__plan">🌅 Hopper Espresso Bar · Ochtend</div>
          <div className="wm-mm__plan">☀️ DEPOT Boijmans · Middag</div>
          <div className="wm-mm__plan">🌆 Wijnbar Sobre · Avond</div>
        </div>
      </div>
    </div>
  );
}
