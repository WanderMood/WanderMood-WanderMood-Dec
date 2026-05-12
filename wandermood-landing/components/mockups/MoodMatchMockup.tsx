"use client";

import { useCallback, useEffect, useId, useRef, useState } from "react";
import { useTranslations } from "next-intl";
import {
  MockupBottomNav,
  MockupStatusBar,
  MockupTopBar,
} from "./MockupChrome";


export function MoodMatchMockup() {
  const t = useTranslations("landing.mockups");
  const root = useRef<HTMLDivElement>(null);
  const timers = useRef<number[]>([]);
  const inView = useRef(false);
  const raf = useRef<number>(0);
  const gradId = useId().replace(/:/g, "");
  const [on, setOn] = useState(false);
  const [step, setStep] = useState(0);
  const [score, setScore] = useState(0);
  const [typed, setTyped] = useState("");
  const [svgKey, setSvgKey] = useState(0);
  const [sConfirmed, setSConfirmed] = useState(false);
  const [sPulse, setSPulse] = useState(false);
  const [typingOn, setTypingOn] = useState(false);

  const clearT = () => {
    timers.current.forEach((id) => clearTimeout(id));
    timers.current = [];
  };

  const q = (fn: () => void, ms: number) => {
    timers.current.push(window.setTimeout(fn, ms));
  };

  const runRef = useRef<(() => void) | null>(null);

  const fullLine = t("mmMoodyTyping");

  const runCycle = useCallback(() => {
    clearT();
    if (typeof cancelAnimationFrame === "function" && raf.current) {
      cancelAnimationFrame(raf.current);
      raf.current = 0;
    }
    setTyped("");
    setScore(0);
    setSConfirmed(false);
    setSPulse(false);
    setTypingOn(false);
    setSvgKey((k) => k + 1);
    setOn(true);
    setStep(1);
    q(() => setStep(2), 400);
    q(() => setStep(3), 800);
    q(() => setStep(4), 1200);
    q(() => setStep(5), 3200);
    q(() => setStep(6), 3400);
    q(() => setStep(7), 3800);
    q(() => {
      setStep(8);
      setTypingOn(true);
    }, 4400);
    q(() => setStep(9), 6800);
    q(() => setStep(10), 7200);
    q(() => setStep(11), 7600);
    q(() => setStep(12), 8200);
    q(() => {
      setSConfirmed(true);
    }, 10000);
    q(() => {
      setSPulse(true);
    }, 12000);
    q(() => setSPulse(false), 12400);
    q(() => {
      setOn(false);
      setStep(0);
      setTyped("");
      setScore(0);
      setTypingOn(false);
    }, 15500);
    q(() => runRef.current?.(), 17200);
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

  useEffect(() => {
    if (step < 4 || step >= 5) return;
    const t0 = performance.now();
    const tick = (now: number) => {
      const u = Math.min(1, (now - t0) / 2000);
      setScore(Math.round(78 * u));
      if (u < 1) raf.current = requestAnimationFrame(tick);
    };
    raf.current = requestAnimationFrame(tick);
    return () => {
      if (raf.current) cancelAnimationFrame(raf.current);
      raf.current = 0;
    };
  }, [step, svgKey]);

  useEffect(() => {
    if (step >= 5) setScore(78);
  }, [step]);

  useEffect(() => {
    if (!typingOn) return;
    setTyped("");
    let i = 0;
    const id = window.setInterval(() => {
      i += 1;
      setTyped(fullLine.slice(0, i));
      if (i >= fullLine.length) clearInterval(id);
    }, 30);
    return () => clearInterval(id);
  }, [typingOn, fullLine]);

  return (
    <div
      ref={root}
      role="presentation"
      aria-hidden
      data-s-confirm={sConfirmed ? "1" : "0"}
      data-s-pulse={sPulse ? "1" : "0"}
      className={`wm-mock wm-app wm-mm wm-mm--s${step} ${on ? "wm-mock--on" : ""}`}
    >
      <MockupStatusBar />
      <div className="wm-app__main">
        <div className="wm-mock__scroll wm-mm__scroll">
          <MockupTopBar title={t("topMoodMatch")} />

          <div className="wm-mm__avatarsRow">
            <div className="wm-mm__avatars">
              <div className="wm-mm__avCol">
                <div className="wm-mm__av wm-mm__av--e">E</div>
                <span className="wm-mm__avLabel">{t("mmYou")}</span>
              </div>
              <div className="wm-mm__heart" aria-hidden>
                💚
              </div>
              <div className="wm-mm__avCol">
                <div className="wm-mm__av wm-mm__av--s">S</div>
                <span className="wm-mm__avLabel">{t("mmPartner")}</span>
              </div>
            </div>
          </div>

          <div className="wm-mm__ringWrap">
            <svg
              key={svgKey}
              className="wm-mm__ring"
              viewBox="0 0 120 120"
              width={110}
              height={110}
              aria-hidden
            >
              <defs>
                <linearGradient id={gradId} x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="#2A6049" />
                  <stop offset="100%" stopColor="#5DCAA5" />
                </linearGradient>
              </defs>
              <circle
                className="wm-mm__track"
                cx={60}
                cy={60}
                r={47}
                fill="none"
                strokeWidth={8}
              />
              <circle
                className="wm-mm__prog"
                cx={60}
                cy={60}
                r={47}
                fill="none"
                stroke={`url(#${gradId})`}
                strokeWidth={8}
                strokeLinecap="round"
                transform="rotate(-90 60 60)"
              />
              <text x={60} y={56} textAnchor="middle" className="wm-mm__score">
                {score}
              </text>
              <text x={60} y={68} textAnchor="middle" className="wm-mm__subring">
                {t("mmMatchLabel")}
              </text>
            </svg>
          </div>

          <div className="wm-mm__balance">{t("mmBalance")}</div>
          <div className="wm-mm__pills">{t("mmPills")}</div>

          <div className="wm-mm__moody">
            <div className="wm-mm__mav">M</div>
            <div className="wm-mm__mtext">{typed}</div>
          </div>

          <div className="wm-mm__plans">
            <div className="wm-mmPlan wm-mmPlan--morning">
              <div className="wm-mmPlan__hdr">
                <span>🌅 {t("mmPlanMorning")}</span>
              </div>
              <div className="wm-placeCard wm-placeCard--coffee wm-mmPlan__card">
                <div className="wm-placeCard__photo">
                  <span>☕</span>
                </div>
                <div className="wm-placeCard__body">
                  <div className="wm-placeCard__top">
                    <span className="wm-placeCard__name">{t("mmSlot1Title")}</span>
                  </div>
                  <div className="wm-placeCard__metaLine">{t("mmMeta1")}</div>
                  <div className="wm-mmPlan__dots">
                    <span className="wm-mmPlan__dot wm-mmPlan__dot--fill">E</span>
                    <span className="wm-mmPlan__dot wm-mmPlan__dot--fill">S</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="wm-mmPlan wm-mmPlan--noon">
              <div className="wm-mmPlan__hdr">
                <span>☀️ {t("mmPlanNoon")}</span>
              </div>
              <div className="wm-placeCard wm-placeCard--museum wm-mmPlan__card">
                <div className="wm-placeCard__photo">
                  <span>🏛️</span>
                </div>
                <div className="wm-placeCard__body">
                  <div className="wm-placeCard__top">
                    <span className="wm-placeCard__name">{t("mmSlot2Title")}</span>
                  </div>
                  <div className="wm-placeCard__metaLine">{t("mmMeta2")}</div>
                  <div className="wm-mmPlan__dots">
                    <span className="wm-mmPlan__dot wm-mmPlan__dot--fill">E</span>
                    <span
                      className={`wm-mmPlan__dot ${sConfirmed ? "wm-mmPlan__dot--fill" : "wm-mmPlan__dot--out"} ${sPulse ? "wm-mmPlan__dot--pulse" : ""}`}
                    >
                      S
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div className="wm-mmPlan wm-mmPlan--eve">
              <div className="wm-mmPlan__hdr">
                <span>🌆 {t("mmPlanEve")}</span>
              </div>
              <div className="wm-placeCard wm-placeCard--bar wm-mmPlan__card">
                <div className="wm-placeCard__photo">
                  <span>🍷</span>
                </div>
                <div className="wm-placeCard__body">
                  <div className="wm-placeCard__top">
                    <span className="wm-placeCard__name">{t("mmSlot3Title")}</span>
                  </div>
                  <div className="wm-placeCard__metaLine">{t("mmMeta3")}</div>
                  <div className="wm-mmPlan__dots">
                    <span className="wm-mmPlan__dot wm-mmPlan__dot--out">E</span>
                    <span className="wm-mmPlan__dot wm-mmPlan__dot--out">S</span>
                  </div>
                </div>
              </div>
            </div>

            <button type="button" className="wm-mm__confirm">
              {t("mmPlanConfirm")}
            </button>
          </div>
        </div>
      </div>
      <MockupBottomNav active="plans" />
    </div>
  );
}
