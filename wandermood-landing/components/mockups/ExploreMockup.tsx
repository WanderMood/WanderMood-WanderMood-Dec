"use client";

import { useCallback, useEffect, useRef, useState } from "react";

export function ExploreMockup() {
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [chip, setChip] = useState(0);

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
    setChip(0);
    setOn(true);
    setStep(1);
    q(() => setStep(3), 420);
    q(() => setStep(4), 820);
    q(() => setStep(5), 1220);
    q(() => setStep(6), 1680);
    q(() => setStep(7), 2180);
    q(() => setStep(8), 2680);
    q(() => {
      setStep(9);
      setChip(1);
    }, 5800);
    q(() => setStep(10), 6600);
    q(() => {
      setOn(false);
      setStep(0);
      setChip(0);
    }, 8200);
    q(() => runRef.current?.(), 8200 + 5200);
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
      className={`wm-mock wm-explore wm-explore--s${step} ${on ? "wm-mock--on" : ""}`}
    >
      <div className="wm-mock__status">
        <span>9:41</span>
        <span>●●●●</span>
      </div>
      <div className="wm-mock__scroll">
        <div className="wm-explore__search">
          <span aria-hidden>🔍</span>
          <span>Ontdek Rotterdam…</span>
        </div>
        <div className="wm-explore__chips">
          <span
            className={`wm-explore__chip ${chip === 0 ? "wm-explore__chip--active" : ""}`}
          >
            {chip === 0 ? "Gezellig ✓" : "Gezellig"}
          </span>
          <span
            className={`wm-explore__chip ${chip === 1 ? "wm-explore__chip--active2" : ""}`}
          >
            {chip === 1 ? "Foodie ✓" : "Foodie"}
          </span>
          <span className="wm-explore__chip">Cultureel</span>
          <span className="wm-explore__chip">Meer…</span>
        </div>
        <div className="wm-explore__trend">
          <div className="wm-explore__trendRow">
            <div className="wm-explore__trendDots" aria-hidden>
              <span />
              <span />
              <span />
            </div>
            <span>Trending op WanderMood</span>
          </div>
        </div>
        <div className="wm-explore__stories" aria-hidden>
          <div className="wm-explore__dot" />
          <div className="wm-explore__dot" />
          <div className="wm-explore__dot" />
        </div>
        <div className="wm-explore__card wm-explore__card--a">
          <div className="wm-explore__name">Hopper Espresso Bar</div>
          <div className="wm-explore__meta">★ 4.6 · Specialty coffee · ☕</div>
          <div className="wm-explore__quote">&ldquo;Flat white, goed licht, geen haast.&rdquo;</div>
        </div>
        <div className="wm-explore__card wm-explore__card--b">
          <div className="wm-explore__name">DEPOT Boijmans</div>
          <div className="wm-explore__meta">★ 4.4 · Museum · 🎭</div>
          <div className="wm-explore__quote">&ldquo;Neem je tijd in de eerste zaal.&rdquo;</div>
        </div>
      </div>
    </div>
  );
}
