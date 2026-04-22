"use client";

import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from "react";
import { useTranslations } from "next-intl";

const STORAGE_KEY = "wm_landing_tour_v1_finished";
/** Same breakpoint as landing.css (900px), where `.nav-links` is hidden. */
const NAV_COMPACT_QUERY = "(max-width: 900px)";

export type LandingTourHandle = {
  start: () => void;
};

type Rect = { left: number; top: number; width: number; height: number };

function readTargetRect(id: string, pad: number): Rect | null {
  if (typeof document === "undefined") return null;
  const el = document.getElementById(id);
  if (!el) return null;
  const r = el.getBoundingClientRect();
  return {
    left: r.left - pad,
    top: r.top - pad,
    width: r.width + pad * 2,
    height: r.height + pad * 2,
  };
}

const LandingTour = forwardRef<LandingTourHandle>(function LandingTour(_, ref) {
  const t = useTranslations("landing");
  const [open, setOpen] = useState(false);
  const [step, setStep] = useState(0);
  const [rect, setRect] = useState<Rect | null>(null);
  const [tooltipAbove, setTooltipAbove] = useState(false);
  const [reduceMotion, setReduceMotion] = useState(false);
  const [compactNav, setCompactNav] = useState(false);
  const tooltipRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const mq = window.matchMedia(NAV_COMPACT_QUERY);
    const sync = () => setCompactNav(mq.matches);
    sync();
    mq.addEventListener("change", sync);
    return () => mq.removeEventListener("change", sync);
  }, []);

  const steps = useMemo(() => {
    const navBody = compactNav
      ? t("tour.navBodyCompact")
      : t("tour.navBody", {
          how: t("nav.how"),
          moods: t("nav.moods"),
          business: t("nav.business"),
          download: t("nav.download"),
        });
    return [
      { targetId: "landing-nav", title: t("tour.navTitle"), body: navBody },
      {
        targetId: "app-preview",
        title: `${t("hero.title1")} ${t("hero.titleEm")} ${t("hero.title2")}`,
        body: t("hero.sub"),
      },
      {
        targetId: "how",
        title: `${t("how.title1")} ${t("how.titleEm")}`,
        body: t("how.sub"),
      },
      {
        targetId: "moods",
        title: `${t("moodsSection.title1")} ${t("moodsSection.titleEm")}`,
        body: t("tour.moodsBody"),
      },
      {
        targetId: "business",
        title: `${t("b2b.titleBefore")}${t("b2b.titleEm")}`,
        body: t("b2b.desc1"),
      },
      {
        targetId: "download",
        title: `${t("cta.title1")} ${t("cta.titleEm")}`,
        body: t("cta.sub"),
      },
    ];
  }, [t, compactNav]);

  const refreshRect = useCallback(() => {
    const id = steps[step]?.targetId;
    if (!id) return;
    const next = readTargetRect(id, 10);
    setRect(next);
  }, [step, steps]);

  const closeAndPersist = useCallback(() => {
    setOpen(false);
    setStep(0);
    setRect(null);
    try {
      localStorage.setItem(STORAGE_KEY, "1");
    } catch {
      /* ignore */
    }
    document.body.style.overflow = "";
  }, []);

  const start = useCallback(() => {
    setStep(0);
    setOpen(true);
    document.body.style.overflow = "hidden";
  }, []);

  useImperativeHandle(ref, () => ({ start }), [start]);

  useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    setReduceMotion(mq.matches);
    const onChange = () => setReduceMotion(mq.matches);
    mq.addEventListener("change", onChange);
    return () => mq.removeEventListener("change", onChange);
  }, []);

  useEffect(() => {
    if (!open) return;
    const id = steps[step]?.targetId;
    if (!id) return;
    const el = document.getElementById(id);
    el?.scrollIntoView({ behavior: reduceMotion ? "auto" : "smooth", block: "center" });
    const t1 = window.setTimeout(refreshRect, reduceMotion ? 0 : 400);
    const onResize = () => refreshRect();
    window.addEventListener("resize", onResize);
    window.addEventListener("scroll", onResize, true);
    return () => {
      window.clearTimeout(t1);
      window.removeEventListener("resize", onResize);
      window.removeEventListener("scroll", onResize, true);
    };
  }, [open, step, steps, refreshRect, reduceMotion]);

  useEffect(() => {
    if (!open) return;
    refreshRect();
  }, [open, refreshRect]);

  useEffect(() => {
    if (!open || !rect) return;
    const tt = tooltipRef.current;
    if (!tt) return;
    const th = tt.offsetHeight;
    const margin = 16;
    const spaceBelow = window.innerHeight - rect.top - rect.height - margin;
    setTooltipAbove(spaceBelow < th + 80 && rect.top > th + 80);
  }, [open, rect, step]);

  useEffect(() => {
    if (typeof window === "undefined") return;
    const done = localStorage.getItem(STORAGE_KEY);
    if (done) return;
    const t0 = window.setTimeout(() => {
      setStep(0);
      setOpen(true);
      document.body.style.overflow = "hidden";
    }, 900);
    return () => window.clearTimeout(t0);
  }, []);

  useEffect(
    () => () => {
      document.body.style.overflow = "";
    },
    [],
  );

  if (!open || !steps[step]) return null;

  const last = step === steps.length - 1;
  const cursorTransition = reduceMotion ? "none" : "top 0.35s ease, left 0.35s ease";

  return (
    <div
      className="landing-tour-root"
      role="dialog"
      aria-modal="true"
      aria-label={t("tour.closeAria")}
      aria-labelledby="landing-tour-title"
      aria-describedby="landing-tour-desc"
    >
      <div className="landing-tour-blocker" aria-hidden />
      {rect && (
        <>
          <div
            className="landing-tour-spotlight"
            style={{
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              borderRadius: 14,
              boxShadow: "0 0 0 9999px rgba(15, 18, 16, 0.78)",
            }}
          />
          {!reduceMotion && (
            <div
              className="landing-tour-cursor"
              aria-hidden
              style={{
                transition: cursorTransition,
                left: rect.left + rect.width / 2 - 6,
                top: rect.top + rect.height / 2 - 4,
              }}
            />
          )}
        </>
      )}
      <div
        ref={tooltipRef}
        className={`landing-tour-tooltip ${tooltipAbove ? "landing-tour-tooltip--above" : ""}`}
        style={
          rect
            ? (() => {
                const tw = Math.min(340, typeof window !== "undefined" ? window.innerWidth - 32 : 340);
                const left = Math.min(
                  Math.max(16, rect.left + rect.width / 2 - tw / 2),
                  (typeof window !== "undefined" ? window.innerWidth : 400) - tw - 16,
                );
                return tooltipAbove
                  ? { left, bottom: (typeof window !== "undefined" ? window.innerHeight : 600) - rect.top + 16 }
                  : { left, top: rect.top + rect.height + 16 };
              })()
            : { left: 24, bottom: 24 }
        }
      >
        <p className="landing-tour-step-label" id="landing-tour-step">
          {t("tour.stepOf", { current: step + 1, total: steps.length })}
        </p>
        <h2 id="landing-tour-title" className="landing-tour-title">
          {steps[step].title}
        </h2>
        <p id="landing-tour-desc" className="landing-tour-desc">
          {steps[step].body}
        </p>
        <div className="landing-tour-actions">
          <button type="button" className="landing-tour-skip" onClick={closeAndPersist}>
            {t("tour.skip")}
          </button>
          <button
            type="button"
            className="landing-tour-next"
            onClick={() => {
              if (last) closeAndPersist();
              else setStep((s) => s + 1);
            }}
          >
            {last ? t("tour.done") : t("tour.next")}
          </button>
        </div>
      </div>
    </div>
  );
});

export default LandingTour;
