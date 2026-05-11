"use client";

import { useCallback, useEffect, useRef, useState } from "react";

export function MyDayMockup() {
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
          <div className="wm-day__date">Zaterdag, 11 mei</div>
          <div className="wm-day__title">Jouw dag</div>
        </header>
        <div className="wm-day__wx">☀️ 18°C · Rotterdam · Lekker dagje uit</div>
        <div className="wm-day__timeline">
          <div className="wm-day__line" aria-hidden />
          <div className="wm-day__slot">
            <div className="wm-day__time">09:00</div>
            <div className="wm-day__dot" aria-hidden />
            <div className="wm-day__card wm-day__card--here">
              <div className="wm-day__row">
                <div className="wm-day__name">Hopper Espresso Bar</div>
                <span className="wm-day__check" aria-hidden>
                  ✓
                </span>
              </div>
              <div className="wm-day__sub">☕ Met Sarah · Je bent er!</div>
            </div>
          </div>
          <div className="wm-day__slot">
            <div className="wm-day__time">13:00</div>
            <div className="wm-day__dot" aria-hidden />
            <div className="wm-day__card">
              <div className="wm-day__name">DEPOT Boijmans Van Beuningen</div>
              <div className="wm-day__sub">🎭 Met Sarah</div>
            </div>
          </div>
          <div className="wm-day__slot">
            <div className="wm-day__time">19:00</div>
            <div className="wm-day__dot" aria-hidden />
            <div className="wm-day__card">
              <div className="wm-day__name">Wijnbar Sobre</div>
              <div className="wm-day__sub">🍷 Met Sarah</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
