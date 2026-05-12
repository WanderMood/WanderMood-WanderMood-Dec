"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useTranslations } from "next-intl";
import {
  MockupBottomNav,
  MockupStatusBar,
  MockupTopBar,
} from "./MockupChrome";

import type { TranslationValues } from "next-intl";

/** 0 default, 1 foodie swap, 2 halal swap */
type MoodPhase = 0 | 1 | 2;

type MockupT = (key: string, values?: TranslationValues) => string;

function cardTriple(phase: MoodPhase, t: MockupT): [string, string, string] {
  if (phase === 1)
    return [
      t("exploreCard1b"),
      t("exploreCard2b"),
      t("exploreCard3b"),
    ];
  if (phase === 2)
    return [
      t("exploreCard1c"),
      t("exploreCard2c"),
      t("exploreCard3c"),
    ];
  return [t("exploreCard1a"), t("exploreCard2a"), t("exploreCard3a")];
}

function typeTriple(phase: MoodPhase, t: MockupT): [string, string, string] {
  if (phase === 1)
    return [
      t("typeFoodHall"),
      t("typeStreetfood"),
      t("typeNature"),
    ];
  if (phase === 2)
    return [
      t("exploreFilterHalal"),
      t("exploreFilterHalal"),
      t("exploreFilterHalal"),
    ];
  return [
    t("typeSpecialtyCoffee"),
    t("typeMuseum"),
    t("typeNature"),
  ];
}

export function ExploreMockup() {
  const t = useTranslations("landing.mockups");
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [moodPhase, setMoodPhase] = useState<MoodPhase>(0);
  const [chipIdx, setChipIdx] = useState(0);
  const [filterHalal, setFilterHalal] = useState(false);
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
    setFilterHalal(false);
    setShimmer(false);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 400);
    q(() => setStep(3), 900);
    q(() => setStep(4), 1400);
    q(() => setStep(5), 2000);
    q(() => setStep(6), 2500);
    q(() => setStep(7), 3000);
    q(() => setStep(8), 3400);
    q(() => {
      setChipIdx(1);
      setShimmer(true);
    }, 5000);
    q(() => setShimmer(false), 5600);
    q(() => setMoodPhase(1), 6500);
    q(() => {
      setFilterHalal(true);
      setShimmer(true);
    }, 9000);
    q(() => setShimmer(false), 9600);
    q(() => setMoodPhase(2), 10500);
    q(() => {
      setOn(false);
      setStep(0);
      setMoodPhase(0);
      setChipIdx(0);
      setFilterHalal(false);
    }, 15000);
    q(() => runRef.current?.(), 16700);
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

  const names = cardTriple(moodPhase, t);
  const types = typeTriple(moodPhase, t);

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      data-phase={moodPhase}
      data-filter-halal={filterHalal ? "1" : "0"}
      data-chip={chipIdx}
      data-shimmer={shimmer ? "1" : "0"}
      className={`wm-mock wm-app wm-explore wm-explore--s${step} ${on ? "wm-mock--on" : ""}`}
    >
      <MockupStatusBar />
      <div className="wm-app__main">
        <div className="wm-mock__scroll wm-explore__scroll">
          <MockupTopBar
            title={t("topExplore")}
            right={
              <span className="wm-appTopBar__iconBtn" aria-hidden>
                ≡
              </span>
            }
          />

          <div className="wm-explore__chips">
            <span
              className={`wm-explore__chip ${chipIdx === 0 ? "wm-explore__chip--active" : ""}`}
            >
              ✨ {chipIdx === 0 ? `${t("exploreChipCozy")} ✓` : t("exploreChipCozy")}
            </span>
            <span
              className={`wm-explore__chip ${chipIdx === 1 ? "wm-explore__chip--activeFood" : ""}`}
            >
              🍽️{" "}
              {chipIdx === 1 ? `${t("exploreChipFoodie")} ✓` : t("exploreChipFoodie")}
            </span>
            <span className="wm-explore__chip">🎭 {t("exploreChipCulture")}</span>
            <span className="wm-explore__chip">
              🚀 {t("exploreChipAdventure")}
            </span>
            <span className="wm-explore__chip">{t("exploreChipMore")}</span>
          </div>

          <div className="wm-explore__filters">
            <span
              className={`wm-explore__filter ${filterHalal ? "wm-explore__filter--active" : ""}`}
            >
              {t("exploreFilterHalal")}
            </span>
            <span className="wm-explore__filter">{t("exploreFilterFamily")}</span>
            <span className="wm-explore__filter">{t("exploreFilterDogs")}</span>
          </div>

          <div className="wm-explore__trend">
            <div className="wm-explore__storiesLabel">{t("exploreTrending")}</div>
            <div className="wm-explore__stories">
              <div className="wm-explore__story">
                <div className="wm-explore__storyDot" />
                <span className="wm-explore__storyCap">{t("exploreStory1")}</span>
              </div>
              <div className="wm-explore__story">
                <div className="wm-explore__storyDot wm-explore__storyDot--b" />
                <span className="wm-explore__storyCap">{t("exploreStory2")}</span>
              </div>
              <div className="wm-explore__story">
                <div className="wm-explore__storyDot wm-explore__storyDot--c" />
                <span className="wm-explore__storyCap">{t("exploreStory3")}</span>
              </div>
            </div>
          </div>

          <div
            className={`wm-explore__cards ${shimmer ? "wm-explore__cards--shimmer" : ""}`}
          >
            <div className="wm-placeCard wm-placeCard--coffee wm-explore__cardRow wm-explore__cardRow--a">
              <div className="wm-placeCard__photo">
                <span>☕</span>
              </div>
              <div className="wm-placeCard__body">
                <div className="wm-placeCard__top">
                  <span className="wm-placeCard__name">{names[0]}</span>
                  <span className="wm-placeCard__rating">
                    {t("ratingFmt", { rating: "4.6" })}
                  </span>
                </div>
                <div className="wm-placeCard__badge">{types[0]}</div>
                <div className="wm-placeCard__bottom">
                  <span className="wm-placeCard__dist">
                    📍 {t("distWalk", { minutes: 8 })}
                  </span>
                  <span className="wm-placeCard__add">{t("addDay")}</span>
                </div>
              </div>
            </div>

            <div className="wm-placeCard wm-placeCard--museum wm-explore__cardRow wm-explore__cardRow--b">
              <div className="wm-placeCard__photo">
                <span>🏛️</span>
              </div>
              <div className="wm-placeCard__body">
                <div className="wm-placeCard__top">
                  <span className="wm-placeCard__name">{names[1]}</span>
                  <span className="wm-placeCard__rating">
                    {t("ratingFmt", { rating: "4.4" })}
                  </span>
                </div>
                <div className="wm-placeCard__badge">{types[1]}</div>
                <div className="wm-placeCard__bottom">
                  <span className="wm-placeCard__dist">
                    🚲 {t("distBike", { minutes: 12 })}
                  </span>
                  <span className="wm-placeCard__add">{t("addDay")}</span>
                </div>
              </div>
              <span className="wm-placeCard__trending">{t("trendingPill")}</span>
            </div>

            <div className="wm-placeCard wm-placeCard--park wm-explore__cardRow wm-explore__cardRow--c">
              <div className="wm-placeCard__photo">
                <span>🌿</span>
              </div>
              <div className="wm-placeCard__body">
                <div className="wm-placeCard__top">
                  <span className="wm-placeCard__name">{names[2]}</span>
                  <span className="wm-placeCard__rating">
                    {t("ratingFmt", { rating: "4.7" })}
                  </span>
                </div>
                <div className="wm-placeCard__badge">{types[2]}</div>
                <div className="wm-placeCard__bottom">
                  <span className="wm-placeCard__dist">
                    📍 {t("distWalk", { minutes: 15 })}
                  </span>
                  <span className="wm-placeCard__add">{t("addDay")}</span>
                </div>
              </div>
            </div>

            <div className="wm-explore__peekWrap">
              <div className="wm-placeCard wm-placeCard--bar wm-explore__peekCard">
                <div className="wm-placeCard__photo">
                  <span>🍸</span>
                </div>
                <div className="wm-placeCard__body">
                  <div className="wm-placeCard__top">
                    <span className="wm-placeCard__name">…</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <MockupBottomNav active="explore" />
    </div>
  );
}
