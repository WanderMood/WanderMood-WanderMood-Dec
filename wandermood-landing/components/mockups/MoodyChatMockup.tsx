"use client";

import { useCallback, useEffect, useRef, useState } from "react";

export function MoodyChatMockup() {
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

  /* Steps 1–9 visible; fade at ~11500ms; restart after 1.5s fade + 0.5s blank */
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
    q(() => runRef.current?.(), 11500 + 1500 + 500);
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
      <div className="wm-mock__scroll wm-moody__scroll">
        <header className="wm-moody__top">
          <div className="wm-moody__ava" aria-hidden>
            M
          </div>
          <div className="wm-moody__brand">
            <div className="wm-moody__brandTitle">Moody</div>
            <div className="wm-moody__brandSub">Je stadskenner</div>
          </div>
        </header>

        <div className="wm-moody__thread">
          <div className="wm-moody__typing" aria-hidden>
            <span />
            <span />
            <span />
          </div>

          <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__msg1">
            Goedemorgen ☀️ Luie vibe vandaag of wil je echt iets doen?
          </div>

          <div className="wm-moody__bubble wm-moody__bubble--u">
            Iets gezelligs, niet te ver
          </div>

          <div className="wm-moody__typing wm-moody__typing--2" aria-hidden>
            <span />
            <span />
            <span />
          </div>

          <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__msg2">
            Dan weet ik precies waar ik je heen stuur 💚
          </div>

          <div className="wm-moody__place">
            <div className="wm-moody__placeDot" aria-hidden>
              <span>☕</span>
            </div>
            <div className="wm-moody__placeBody">
              <div className="wm-moody__placeTop">
                <div>
                  <div className="wm-moody__placeName">Hopper Espresso Bar</div>
                  <div className="wm-moody__placeMeta">★ 4.6 · 8 min lopen</div>
                </div>
              </div>
              <div className="wm-moody__placeBtns">
                <button type="button" className="wm-moody__pill wm-moody__pill--pri">
                  Voeg toe
                </button>
                <button type="button" className="wm-moody__pill wm-moody__pill--sec">
                  Meer
                </button>
              </div>
            </div>
          </div>

          <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__bubble--quote wm-moody__msg3">
            Flat white, goed licht, geen haast.
          </div>
        </div>

        <div className="wm-moody__composer" aria-hidden>
          <span className="wm-moody__composerPh">Bericht…</span>
        </div>
      </div>
    </div>
  );
}
