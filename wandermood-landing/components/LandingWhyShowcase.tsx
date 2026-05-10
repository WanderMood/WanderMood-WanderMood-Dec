"use client";

import { useCallback, useMemo, useState } from "react";
import Image from "next/image";
import { useLocale, useTranslations } from "next-intl";
import { getWhyShowcaseScreens } from "@/lib/landing-images";
import { IPhone16ProMaxShot } from "@/components/landing-device-shots";

const WHY_CARDS = [
  ["u1t", "u1b"],
  ["u2t", "u2b"],
  ["u3t", "u3b"],
  ["u4t", "u4b"],
  ["u5t", "u5b"],
  ["u6t", "u6b"],
] as const;

const PREVIEW_KEYS = ["u1", "u2", "u3", "u4", "u5", "u6"] as const;

export function LandingWhyShowcase() {
  const t = useTranslations("landing");
  const locale = useLocale();
  const screens = useMemo(() => getWhyShowcaseScreens(locale), [locale]);
  const [active, setActive] = useState(0);

  const onCardEnter = useCallback((index: number) => {
    if (typeof window !== "undefined" && window.matchMedia("(min-width: 901px)").matches) {
      setActive(index);
    }
  }, []);

  return (
    <section id="features" className="landing-why landing-why--showcase">
      <div className="landing-section-inner">
        <p className="section-eyebrow reveal">{t("why.eyebrow")}</p>
        <h2 className="reveal landing-section-title">
          {t("why.title")} <em>{t("why.titleEm")}</em>
        </h2>
        <p className="section-sub reveal landing-why-sub">{t("why.sub")}</p>

        <div className="landing-why-desktop reveal">
          <div
            className="landing-why-desktop-grid"
            role="tablist"
            aria-label={t("why.eyebrow")}
          >
            {WHY_CARDS.map(([titleKey, bodyKey], index) => (
              <button
                key={titleKey}
                type="button"
                role="tab"
                id={`why-tab-${index}`}
                aria-selected={active === index}
                aria-controls="why-preview-panel"
                className={`landing-why-pick ${active === index ? "is-active" : ""}`}
                onClick={() => setActive(index)}
                onFocus={() => setActive(index)}
                onMouseEnter={() => onCardEnter(index)}
              >
                <span className="landing-why-pick-index" aria-hidden>
                  {String(index + 1).padStart(2, "0")}
                </span>
                <span className="landing-why-pick-text">
                  <span className="landing-why-pick-title">{t(`why.${titleKey}`)}</span>
                  <span className="landing-why-pick-body">{t(`why.${bodyKey}`)}</span>
                </span>
              </button>
            ))}
          </div>
          <div className="landing-why-preview-wrap">
            <div
              id="why-preview-panel"
              role="tabpanel"
              aria-labelledby={`why-tab-${active}`}
              aria-live="polite"
              className="landing-why-preview-panel"
            >
              <div className="landing-why-preview-stage" key={active}>
                <IPhone16ProMaxShot
                  src={screens[active]}
                  alt={t(`why.previewAlt.${PREVIEW_KEYS[active]}`)}
                  sizes="(max-width: 900px) 85vw, 260px"
                  railMaxWidthPx={260}
                />
              </div>
            </div>
          </div>
        </div>

        <div className="landing-why-mobile reveal" aria-label={t("why.swipeHint")}>
          <p className="landing-why-mobile-hint">{t("why.swipeHint")}</p>
          <div className="landing-why-mobile-track">
            {WHY_CARDS.map(([titleKey, bodyKey], index) => (
              <article key={titleKey} className="landing-why-mobile-card">
                <div className="landing-why-mobile-thumb">
                  <Image
                    src={screens[index]}
                    alt={t(`why.previewAlt.${PREVIEW_KEYS[index]}`)}
                    width={360}
                    height={520}
                    className="landing-why-mobile-thumb-img"
                    sizes="(max-width: 600px) 78vw, 280px"
                  />
                </div>
                <h3 className="landing-why-mobile-title">{t(`why.${titleKey}`)}</h3>
                <p className="landing-why-mobile-body">{t(`why.${bodyKey}`)}</p>
              </article>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
