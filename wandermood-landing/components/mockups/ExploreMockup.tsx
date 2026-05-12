"use client";

import { useCallback, useEffect, useRef, useState } from "react";

/** 0 = Gezellig content, 1 = Foodie, 2 = Cultureel */
type MoodPhase = 0 | 1 | 2;

export function ExploreMockup() {
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [moodPhase, setMoodPhase] = useState<MoodPhase>(0);
  const [chipIdx, setChipIdx] = useState(0);
  const [shimmer, setShimmer] = useState(false);

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
    setMoodPhase(0);
    setChipIdx(0);
    setShimmer(false);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 300);
    q(() => setStep(3), 700);
    q(() => setStep(4), 1400);
    q(() => setStep(5), 2200);
    q(() => setStep(6), 2800);
    q(() => setStep(7), 3400);
    q(() => {
      setStep(8);
      setChipIdx(1);
      setShimmer(true);
    }, 5000);
    q(() => setShimmer(false), 5600);
    q(() => {
      setStep(9);
      setMoodPhase(1);
    }, 7000);
    q(() => {
      setStep(10);
      setChipIdx(2);
      setShimmer(true);
      setMoodPhase(2);
    }, 9000);
    q(() => setShimmer(false), 9600);
    q(() => setStep(11), 11500);
    q(() => {
      setOn(false);
      setStep(0);
      setMoodPhase(0);
      setChipIdx(0);
    }, 13000);
    q(() => runRef.current?.(), 13000 + 1500 + 500);
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

  const labels = [
    {
      n1: "Hopper Espresso Bar",
      m1: "★ 4.6 · Specialty coffee",
      q1: "Flat white, goed licht.",
      n2: "DEPOT Boijmans",
      m2: "★ 4.4 · Museum",
      q2: "Neem je tijd in de zaal.",
      n3: "Kralingse Bos",
      m3: "★ 4.7 · Natuur",
      q3: "Frisse wandeling.",
    },
    {
      n1: "Bazar",
      m1: "★ 4.5 · Food hall",
      q1: "Veel keus, bruisend.",
      n2: "Fenix Food Factory",
      m2: "★ 4.6 · Streetfood",
      q2: "Harbor views & bites.",
      n3: "Kralingse Bos",
      m3: "★ 4.7 · Natuur",
      q3: "Lekker uitwaaien.",
    },
    {
      n1: "DEPOT Boijmans",
      m1: "★ 4.6 · Museum",
      q1: "Iconen en nieuw werk.",
      n2: "Museum Boijmans",
      m2: "★ 4.5 · Tentoonstelling",
      q2: "Samen cultuur snuiven.",
      n3: "Kralingse Bos",
      m3: "★ 4.7 · Natuur",
      q3: "Rust na museums.",
    },
  ][moodPhase];

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      data-phase={moodPhase}
      data-shimmer={shimmer ? "1" : "0"}
      className={`wm-mock wm-explore wm-explore--s${step} ${on ? "wm-mock--on" : ""}`}
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

      <div className="wm-mock__scroll wm-explore__scroll">
        <div className="wm-explore__search">
          <span aria-hidden>🔍</span>
          <span>Ontdek Rotterdam…</span>
        </div>

        <div className="wm-explore__chips">
          <span className={`wm-explore__chip ${chipIdx === 0 ? "wm-explore__chip--active" : ""}`}>
            {chipIdx === 0 ? "Gezellig ✓" : "Gezellig"}
          </span>
          <span className={`wm-explore__chip ${chipIdx === 1 ? "wm-explore__chip--activeFood" : ""}`}>
            {chipIdx === 1 ? "Foodie ✓" : "Foodie"}
          </span>
          <span className={`wm-explore__chip ${chipIdx === 2 ? "wm-explore__chip--activeCult" : ""}`}>
            {chipIdx === 2 ? "Cultureel ✓" : "Cultureel"}
          </span>
          <span className="wm-explore__chip">Avontuurlijk</span>
          <span className="wm-explore__chip">Meer</span>
        </div>

        <div className="wm-explore__trend">
          <div className="wm-explore__trendRow">
            <div className="wm-explore__storiesLabel">Trending op WanderMood</div>
          </div>
          <div className="wm-explore__stories">
            <div className="wm-explore__story">
              <div className="wm-explore__storyDot" />
              <span className="wm-explore__storyCap">Hopper</span>
            </div>
            <div className="wm-explore__story">
              <div className="wm-explore__storyDot wm-explore__storyDot--b" />
              <span className="wm-explore__storyCap">DEPOT</span>
            </div>
            <div className="wm-explore__story">
              <div className="wm-explore__storyDot wm-explore__storyDot--c" />
              <span className="wm-explore__storyCap">Sobre</span>
            </div>
          </div>
        </div>

        <div className={`wm-explore__cards ${shimmer ? "wm-explore__cards--shimmer" : ""}`}>
          <div className="wm-explore__cardRow wm-explore__cardRow--a">
            <div className="wm-explore__thumb">☕</div>
            <div className="wm-explore__cardMain">
              <div className="wm-explore__name">{labels.n1}</div>
              <div className="wm-explore__meta">{labels.m1}</div>
              <div className="wm-explore__quote">{labels.q1}</div>
            </div>
            <span className="wm-explore__bookmark" aria-hidden>
              🔖
            </span>
          </div>

          <div className="wm-explore__cardRow wm-explore__cardRow--b">
            <div className="wm-explore__thumb wm-explore__thumb--b">🏛️</div>
            <div className="wm-explore__cardMain">
              <div className="wm-explore__name">{labels.n2}</div>
              <div className="wm-explore__meta">{labels.m2}</div>
              <div className="wm-explore__quote">{labels.q2}</div>
              <div className="wm-explore__trendingPill">🔥 Trending</div>
            </div>
            <span className="wm-explore__bookmark" aria-hidden>
              🔖
            </span>
          </div>

          <div className="wm-explore__peekWrap">
            <div className="wm-explore__cardRow wm-explore__cardRow--c wm-explore__cardRow--peek">
              <div className="wm-explore__thumb wm-explore__thumb--c">🌿</div>
              <div className="wm-explore__cardMain">
                <div className="wm-explore__name">{labels.n3}</div>
                <div className="wm-explore__meta">{labels.m3}</div>
                <div className="wm-explore__quote">{labels.q3}</div>
              </div>
              <span className="wm-explore__bookmark" aria-hidden>
                🔖
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
