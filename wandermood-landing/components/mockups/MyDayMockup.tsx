"use client";

import { useCallback, useEffect, useRef, useState } from "react";

function WmStatusBar() {
  return (
    <div className="wm-mock__status">
      <span className="wm-mock__time">9:41</span>
      <div className="wm-mock__sys">
        <span className="wm-mock__signal" aria-hidden>
          <span />
          <span />
          <span />
        </span>
        <span className="wm-mock__wifi" aria-hidden />
        <span className="wm-mock__battery" aria-hidden>
          <span className="wm-mock__battery-fill" />
        </span>
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
    setExiting(false);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 500);
    q(() => setStep(3), 1200);
    q(() => {
      setStep(4);
      setPKick(true);
    }, 1800);
    q(() => setPKick(false), 2480);
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
    q(() => setStep(8), 7000);
    q(() => setStep(9), 9000);
    q(() => setStep(10), 10500);
    q(() => setExiting(true), 12000);
    q(() => {
      setExiting(false);
      setOn(false);
      setStep(0);
    }, 13500);
    q(() => runRef.current?.(), 14000);
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
    step === 8 ? "wm-day--scroll" : "",
    exiting ? "wm-mock--exiting" : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div ref={root} role="presentation" aria-hidden className={cls}>
      <WmStatusBar />
      <div className="wm-mock__scroll">
        <div className="wm-day__panorama">
          <div className="wm-day__titleRow">
            <header className="wm-day__head">
              <div className="wm-day__date">Zaterdag, 11 mei</div>
              <div className="wm-day__title">Jouw dag</div>
            </header>
            <div className="wm-day__bell" aria-hidden>
              🔔
            </div>
          </div>
          <div className="wm-day__wx">☀️ 18°C · Rotterdam · Lekker dagje uit</div>
          <div className="wm-day__timeline">
            <div className="wm-day__line" aria-hidden />
            <div className="wm-day__slot">
              <div className="wm-day__dot" aria-hidden />
              <div className="wm-day__hero">
                <span className="wm-day__heroEmoji" aria-hidden>
                  ☕
                </span>
                <div className="wm-day__heroTop">
                  <span className="wm-day__heroTime">09:00</span>
                  <span className="wm-day__heroStatus">
                    <span className="wm-day__heroDot" aria-hidden />
                    ✓ Je bent er
                  </span>
                </div>
                <div className="wm-day__heroName">Hopper Espresso Bar</div>
                <span className="wm-day__heroBadge">☕ Met Sarah</span>
              </div>
            </div>
            <div className="wm-day__slot">
              <div className="wm-day__dot" aria-hidden />
              <div className="wm-day__slotRow">
                <span className="wm-day__compactTime">13:00</span>
                <div className="wm-day__compact wm-day__compact--b">
                  <div className="wm-day__compactMid">
                    <div className="wm-day__compactName">DEPOT Boijmans Van Beuningen</div>
                    <span className="wm-day__compactBadge">🎭 Met Sarah</span>
                  </div>
                  <span className="wm-day__compactChev" aria-hidden>
                    ›
                  </span>
                </div>
              </div>
            </div>
            <div className="wm-day__slot">
              <div className="wm-day__dot" aria-hidden />
              <div className="wm-day__slotRow">
                <span className="wm-day__compactTime">19:00</span>
                <div className="wm-day__compact wm-day__compact--c">
                  <div className="wm-day__compactMid">
                    <div className="wm-day__compactName">Wijnbar Sobre</div>
                    <span className="wm-day__compactBadge">🍷 Met Sarah</span>
                  </div>
                  <span className="wm-day__compactChev" aria-hidden>
                    ›
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
