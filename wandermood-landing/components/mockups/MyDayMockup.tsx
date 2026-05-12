"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useTranslations } from "next-intl";
import {
  MockupBottomNav,
  MockupStatusBar,
  MockupTopBar,
} from "./MockupChrome";

export function MyDayMockup() {
  const t = useTranslations("landing.mockups");
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
    q(() => setStep(2), 400);
    q(() => setStep(3), 900);
    q(() => setStep(4), 1800);
    q(() => setStep(5), 2400);
    q(() => setStep(6), 2800);
    q(() => setStep(7), 3200);
    q(() => setStep(8), 3600);
    q(() => setStep(9), 4000);
    q(() => setStep(10), 5000);
    q(() => setStep(11), 5500);
    q(() => setStep(12), 5700);
    q(() => setStep(13), 5900);
    q(() => setStep(14), 6100);
    q(() => {
      setPulse(true);
      setBright(true);
    }, 7500);
    q(() => {
      setPulse(false);
      setBright(false);
    }, 8200);
    q(() => setScrollSim(true), 9000);
    q(() => setScrollSim(false), 11000);
    q(() => {
      setOn(false);
      setStep(0);
    }, 14500);
    q(() => runRef.current?.(), 16200);
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
    "wm-app",
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
      <MockupStatusBar />
      <div className="wm-app__main">
        <div className="wm-mock__scroll wm-day__outer">
          <MockupTopBar
            title={t("topMyDay")}
            right={
              <span className="wm-appTopBar__bellWrap" aria-hidden>
                🔔
                <span className="wm-appTopBar__bellDot" />
              </span>
            }
          />

          <div className="wm-day__intro">
            <div className="wm-day__date">{t("myDayDate")}</div>
            <div className="wm-day__wx">{t("myDayWeather")}</div>
          </div>

          <div className="wm-day__hero">
            <div className="wm-day__heroAccent" aria-hidden />
            <div className="wm-day__heroDeco" aria-hidden>
              ☕
            </div>
            <div className="wm-day__heroTop">
              <span className="wm-day__heroTime">09:00</span>
              <span className="wm-day__heroHere">
                <span className="wm-day__hereDot" aria-hidden />
                {t("myDayHeroHere")}
              </span>
            </div>
            <div className="wm-day__heroName">{t("myDayHeroTitle")}</div>
            <div className="wm-day__heroBottom">
              <span className="wm-day__heroBadge">{t("myDayMetSarah")}</span>
              <span className="wm-day__heroRoute">{t("myDayRouteLink")}</span>
            </div>
          </div>

          <div className="wm-day__track">
            <div className="wm-day__timeline">
              <div className="wm-day__line" aria-hidden />

              <div className="wm-day__bridge wm-day__bridge--mid">
                {t("myDayPillBike12")}
              </div>

              <div className="wm-day__slot">
                <div className="wm-day__timeCol">
                  <span className="wm-day__time">13:00</span>
                  <span className="wm-day__dot wm-day__dot--fill" aria-hidden />
                </div>
                <div className="wm-placeCard wm-placeCard--museum wm-dayCard">
                  <div className="wm-placeCard__photo">
                    <span>🏛️</span>
                  </div>
                  <div className="wm-placeCard__body">
                    <div className="wm-placeCard__top">
                      <span className="wm-placeCard__name">{t("myDayAct1")}</span>
                      <span className="wm-placeCard__rating">
                        {t("ratingFmt", { rating: "4.4" })}
                      </span>
                    </div>
                    <div className="wm-placeCard__badge">{t("typeMuseum")}</div>
                    <div className="wm-placeCard__bottom">
                      <span className="wm-placeCard__dist">{t("myDayDist1")}</span>
                      <span className="wm-placeCard__add">{t("addDay")}</span>
                    </div>
                  </div>
                  <span className="wm-dayCard__with">{t("myDayAct1Meta")}</span>
                </div>
              </div>

              <div className="wm-day__bridge wm-day__bridge--mid">
                {t("myDayPillBike18")}
              </div>

              <div className="wm-day__slot">
                <div className="wm-day__timeCol">
                  <span className="wm-day__time">15:30</span>
                  <span className="wm-day__dot wm-day__dot--outline" aria-hidden />
                </div>
                <div className="wm-placeCard wm-placeCard--park wm-dayCard">
                  <div className="wm-placeCard__photo">
                    <span>🌿</span>
                  </div>
                  <div className="wm-placeCard__body">
                    <div className="wm-placeCard__top">
                      <span className="wm-placeCard__name">{t("myDayAct2")}</span>
                      <span className="wm-placeCard__rating">
                        {t("ratingFmt", { rating: "4.7" })}
                      </span>
                    </div>
                    <div className="wm-placeCard__badge">{t("typePark")}</div>
                    <div className="wm-placeCard__bottom">
                      <span className="wm-placeCard__dist">{t("myDayDist2")}</span>
                      <span className="wm-placeCard__add">{t("addDay")}</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="wm-day__bridge wm-day__bridge--mid">
                {t("myDayPillWalk10")}
              </div>

              <div className="wm-day__slot">
                <div className="wm-day__timeCol">
                  <span className="wm-day__time">19:00</span>
                  <span className="wm-day__dot wm-day__dot--outline" aria-hidden />
                </div>
                <div className="wm-placeCard wm-placeCard--bar wm-dayCard">
                  <div className="wm-placeCard__photo">
                    <span>🍷</span>
                  </div>
                  <div className="wm-placeCard__body">
                    <div className="wm-placeCard__top">
                      <span className="wm-placeCard__name">{t("myDayAct3")}</span>
                      <span className="wm-placeCard__rating">
                        {t("ratingFmt", { rating: "4.5" })}
                      </span>
                    </div>
                    <div className="wm-placeCard__badge">{t("typeWineBar")}</div>
                    <div className="wm-placeCard__bottom">
                      <span className="wm-placeCard__dist">{t("myDayDist3")}</span>
                      <span className="wm-placeCard__add">{t("addDay")}</span>
                    </div>
                  </div>
                  <span className="wm-dayCard__with">{t("myDayAct3Meta")}</span>
                </div>
              </div>
            </div>
          </div>

          <div className="wm-day__freeLabel">{t("freeTimeLabel")}</div>
          <div className="wm-day__freeRow">
            <div className="wm-day__freeChip">
              <span>☕</span>
              <span>{t("suggCoffee")}</span>
            </div>
            <div className="wm-day__freeChip">
              <span>🛍️</span>
              <span>{t("suggShop")}</span>
            </div>
            <div className="wm-day__freeChip">
              <span>🌳</span>
              <span>{t("suggWalk")}</span>
            </div>
            <div className="wm-day__freeChip">
              <span>🎨</span>
              <span>{t("suggMuseum")}</span>
            </div>
          </div>
        </div>
      </div>
      <MockupBottomNav active="myDay" />
    </div>
  );
}
