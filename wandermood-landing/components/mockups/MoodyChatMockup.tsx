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
        <div className="wm-moody__title">Moody</div>
        <div className="wm-moody__thread">
          <div className="wm-moody__bubble wm-moody__bubble--m">
            Waar heb je zin in vandaag?
          </div>
          <div className="wm-moody__bubble wm-moody__bubble--u">
            Gezellig koffie in Rotterdam
          </div>
          <div className="wm-moody__bubble wm-moody__bubble--m">
            Top — ik zoek plekken voor je.
          </div>
        </div>
        <div className="wm-moody__hint">Tip: stel gerust een vervolgvraag.</div>
      </div>
    </div>
  );
}
