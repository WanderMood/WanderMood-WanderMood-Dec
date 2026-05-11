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

export function MoodyChatMockup() {
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
      <div className="wm-mock__scroll">
        <header className="wm-moody__header">
          <div className="wm-moody__avatar" aria-hidden>
            M
          </div>
          <div className="wm-moody__headlines">
            <div className="wm-moody__brand">Moody</div>
            <div className="wm-moody__sub">Je stadskenner</div>
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
              Goedemorgen ☀️ Luie vibe vandaag of wil je echt iets doen?
            </div>
          ) : null}

          {showUser ? (
            <div className="wm-moody__bubble wm-moody__bubble--u wm-moody__bubble--in">
              Iets gezelligs, niet te ver
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
              Dan weet ik precies waar ik je heen stuur 💚
            </div>
          ) : null}

          {showCard ? (
            <div className="wm-moody__placeCard wm-moody__placeCard--in">
              <div className="wm-moody__placeCircle" aria-hidden>
                ☕
              </div>
              <div className="wm-moody__placeMid">
                <div className="wm-moody__placeName">Hopper Espresso Bar</div>
                <div className="wm-moody__placeMeta">★ 4.6 · 8 min lopen</div>
                <div className="wm-moody__placeBtns">
                  <button type="button" className="wm-moody__btn wm-moody__btn--pri">
                    Voeg toe
                  </button>
                  <button type="button" className="wm-moody__btn wm-moody__btn--sec">
                    Meer
                  </button>
                </div>
              </div>
            </div>
          ) : null}

          {showMsg3 ? (
            <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__bubble--soft wm-moody__bubble--in">
              Flat white, goed licht, geen haast.
            </div>
          ) : null}
        </div>

        <div className="wm-moody__inputBar">Bericht aan Moody…</div>
      </div>
    </div>
  );
}
