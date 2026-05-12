"use client";

import { useCallback, useEffect, useRef, useState } from "react";

export function MyDayMockup() {
  const root = useRef<HTMLDivElement>(null);
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
    q(() => setStep(2), 500);
    q(() => setStep(3), 1200);
    q(() => setStep(4), 1800);
    q(() => setStep(5), 2800);
    q(() => setStep(6), 3500);
    q(() => {
      setStep(7);
      setPulse(true);
      setBright(true);
    }, 5000);
    q(() => {
      setPulse(false);
      setBright(false);
    }, 6200);
    q(() => setScrollSim(true), 7000);
    q(() => setScrollSim(false), 9000);
    q(() => {
      setOn(false);
      setStep(0);
    }, 10500);
    q(() => runRef.current?.(), 10500 + 1500 + 500);
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
    pulse ? "wm-day--pulseHero" : "",
    bright ? "wm-day--brightCheck" : "",
    scrollSim ? "wm-day--scrollSim" : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div ref={root} role="presentation" aria-hidden className={cls}>
      <div className="wm-statusBar">
        <span className="wm-statusBar__time">9:41</span>
        <div className="wm-statusBar__icons" aria-hidden>
          <span className="wm-statusBar__signal">
            <span />
            <span />
            <span />
          </span>
          <span className="wm-statusBar__wifi" />
          <span className="wm-statusBar__bat">
            <span className="wm-statusBar__batTerm" />
          </span>
        </div>
      </div>

      <div className="wm-mock__scroll wm-day__outer">
        <header className="wm-day__head">
          <div className="wm-day__headInner">
            <div>
              <div className="wm-day__date">Zaterdag, 11 mei</div>
              <div className="wm-day__title">Jouw dag</div>
            </div>
            <span className="wm-day__bell" aria-hidden>
              🔔
            </span>
          </div>
        </header>

        <div className="wm-day__wx">☀️ 18°C · Rotterdam · Lekker dagje uit</div>

        <div className="wm-day__track">
          <div className="wm-day__timeline">
            <div className="wm-day__line" aria-hidden />

            <div className="wm-day__slot wm-day__slot--hero">
              <div className="wm-day__time">09:00</div>
              <div className="wm-day__dot" aria-hidden />
              <div className="wm-day__hero">
                <div className="wm-day__heroAccent" aria-hidden />
                <div className="wm-day__heroDeco" aria-hidden>
                  ☕
                </div>
                <div className="wm-day__heroTop">
                  <span className="wm-day__heroTime">09:00</span>
                  <span className="wm-day__heroHere">
                    <span className="wm-day__hereDot" aria-hidden />
                    ✓ Je bent er
                  </span>
                </div>
                <div className="wm-day__heroName">Hopper Espresso Bar</div>
                <div className="wm-day__heroBadge">☕ Met Sarah</div>
              </div>
            </div>

            <div className="wm-day__slot wm-day__slot--compact">
              <div className="wm-day__time">13:00</div>
              <div className="wm-day__dot" aria-hidden />
              <div className="wm-day__smallCard">
                <div className="wm-day__smallMain">
                  <div className="wm-day__smallName">DEPOT Boijmans Van Beuningen</div>
                  <div className="wm-day__smallBadge">🎭 Met Sarah</div>
                </div>
                <span className="wm-day__chev" aria-hidden>
                  ›
                </span>
              </div>
            </div>

            <div className="wm-day__slot wm-day__slot--compact">
              <div className="wm-day__time">19:00</div>
              <div className="wm-day__dot" aria-hidden />
              <div className="wm-day__smallCard">
                <div className="wm-day__smallMain">
                  <div className="wm-day__smallName">Wijnbar Sobre</div>
                  <div className="wm-day__smallBadge">🍷 Met Sarah</div>
                </div>
                <span className="wm-day__chev" aria-hidden>
                  ›
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
