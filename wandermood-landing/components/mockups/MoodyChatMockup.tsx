"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useTranslations } from "next-intl";
import {
  MockupBottomNav,
  MockupStatusBar,
  MockupTopBar,
} from "./MockupChrome";

export function MoodyChatMockup() {
  const t = useTranslations("landing.mockups");
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
    q(() => runRef.current?.(), 13200);
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
      className={`wm-mock wm-app wm-moody wm-moody--s${step} ${on ? "wm-mock--on" : ""}`}
    >
      <MockupStatusBar />
      <div className="wm-app__main">
        <div className="wm-mock__scroll wm-moody__scroll">
          <MockupTopBar
            title={t("topMoody")}
            leftExtra={
              <span className="wm-appTopBar__moodyAva" aria-hidden>
                M
              </span>
            }
          />

          <div className="wm-moody__thread">
            <div className="wm-moody__typing" aria-hidden>
              <span />
              <span />
              <span />
            </div>

            <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__msg1">
              {t("moodyMsg1")}
            </div>

            <div className="wm-moody__bubble wm-moody__bubble--u">{t("moodyMsg2")}</div>

            <div className="wm-moody__typing wm-moody__typing--2" aria-hidden>
              <span />
              <span />
              <span />
            </div>

            <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__msg2">
              {t("moodyMsg3")}
            </div>

            <div className="wm-moody__place">
              <div className="wm-placeCard wm-placeCard--coffee wm-moody__placeInner">
                <div className="wm-placeCard__photo">
                  <span>☕</span>
                </div>
                <div className="wm-placeCard__body">
                  <div className="wm-placeCard__top">
                    <span className="wm-placeCard__name">{t("myDayHeroTitle")}</span>
                    <span className="wm-placeCard__rating">
                      {t("ratingFmt", { rating: "4.6" })}
                    </span>
                  </div>
                  <div className="wm-placeCard__badge">{t("typeSpecialtyCoffee")}</div>
                  <div className="wm-placeCard__bottom">
                    <span className="wm-placeCard__dist">
                      📍 {t("moodyDistWalk", { minutes: 8 })}
                    </span>
                    <span className="wm-placeCard__add">{t("addDay")}</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="wm-moody__bubble wm-moody__bubble--m wm-moody__bubble--quote wm-moody__msg3">
              {t("moodyPlaceQuote")}
            </div>
          </div>

          <div className="wm-moody__composer" aria-hidden>
            <span className="wm-moody__composerPh">{t("moodyComposerPh")}</span>
          </div>
        </div>
      </div>
      <MockupBottomNav active="moody" />
    </div>
  );
}
