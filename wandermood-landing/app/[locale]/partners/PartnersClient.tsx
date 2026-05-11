"use client";

import { useMemo, useState } from "react";
import { useLocale, useTranslations } from "next-intl";
import { Link, usePathname, useRouter } from "@/i18n/navigation";
import { PartnerApplyModal } from "@/components/PartnerApplyModal";

const LOCALES = [
  { code: "en", label: "EN" },
  { code: "nl", label: "NL" },
  { code: "de", label: "DE" },
  { code: "es", label: "ES" },
  { code: "fr", label: "FR" },
] as const;

export default function PartnersClient() {
  const t = useTranslations("partners");
  const tFooter = useTranslations("footer");
  const tLegal = useTranslations("legal.common");
  const router = useRouter();
  const pathname = usePathname();
  const currentLocale = useLocale();
  const [applyOpen, setApplyOpen] = useState(false);
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  const faqItems = useMemo(() => {
    const keys = [
      ["q1", "a1"],
      ["q2", "a2"],
      ["q3", "a3"],
      ["q4", "a4"],
      ["q5", "a5"],
      ["q6", "a6"],
    ] as const;
    return keys.map(([qk, ak]) => ({
      q: t(`faq.${qk}` as "faq.q1"),
      a: t(`faq.${ak}` as "faq.a1"),
    }));
  }, [t]);

  return (
    <div className="landing-root">
      <PartnerApplyModal open={applyOpen} onClose={() => setApplyOpen(false)} />

      <nav id="landing-nav">
        <Link href="/" className="nav-logo">
          <div className="nav-logo-icon">
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" aria-hidden>
              <circle cx="10" cy="10" r="4.5" fill="white" opacity="0.9" />
              <path
                d="M10 3C10 3 16 6 16 10C16 14 10 17 10 17C10 17 4 14 4 10C4 6 10 3 10 3Z"
                stroke="white"
                strokeWidth="1.2"
                fill="none"
                opacity="0.45"
              />
            </svg>
          </div>
          <span className="nav-logo-text">{tFooter("brand")}</span>
        </Link>
        <ul className="nav-links">
          <li>
            <Link href="/">{t("nav.home")}</Link>
          </li>
          <li>
            <a href="#hoe-werkt-het">{t("hero.ctaSecondary")}</a>
          </li>
          <li>
            <a href="#wie">{t("who.title")}</a>
          </li>
          <li>
            <a href="#aanvragen">{t("nav.apply")}</a>
          </li>
        </ul>
        <div className="nav-end">
          <div className="nav-locales" role="group" aria-label="Language">
            {LOCALES.map(({ code, label }) => (
              <button
                key={code}
                type="button"
                className={`nav-locale-btn ${currentLocale === code ? "active" : ""}`}
                onClick={() => router.replace(pathname, { locale: code })}
                aria-pressed={currentLocale === code}
                aria-label={label}
              >
                {label}
              </button>
            ))}
          </div>
          <button type="button" className="nav-cta" onClick={() => setApplyOpen(true)}>
            {t("hero.ctaPrimary")}
          </button>
        </div>
      </nav>

      <section className="partners-hero">
        <p className="section-eyebrow">{t("hero.eyebrow")}</p>
        <h1>{t("hero.title")}</h1>
        <p className="hero-sub" style={{ marginBottom: 32 }}>
          {t("hero.sub")}
        </p>
        <div className="hero-actions">
          <button type="button" className="btn-primary" onClick={() => setApplyOpen(true)}>
            {t("hero.ctaPrimary")}
          </button>
          <a href="#hoe-werkt-het" className="btn-secondary">
            {t("hero.ctaSecondary")}
          </a>
        </div>
      </section>

      <div className="divider" aria-hidden />

      <section id="wie" className="partners-section">
        <h2>{t("who.title")}</h2>
        <div className="partners-who-grid">
          <div className="partners-who-card">
            <h3>🍽️ {t("who.card1Title")}</h3>
            <p>{t("who.card1Body")}</p>
          </div>
          <div className="partners-who-card">
            <h3>🏛️ {t("who.card2Title")}</h3>
            <p>{t("who.card2Body")}</p>
          </div>
          <div className="partners-who-card">
            <h3>🏨 {t("who.card3Title")}</h3>
            <p>{t("who.card3Body")}</p>
          </div>
          <div className="partners-who-card">
            <h3>🗺️ {t("who.card4Title")}</h3>
            <p>{t("who.card4Body")}</p>
          </div>
        </div>
      </section>

      <section id="hoe-werkt-het" className="partners-section">
        <h2>{t("how.title")}</h2>
        <div className="partners-steps">
          <div className="step-card">
            <div className="step-number">01</div>
            <h3>{t("how.step1Title")}</h3>
            <p>{t("how.step1Body")}</p>
          </div>
          <div className="step-card">
            <div className="step-number">02</div>
            <h3>{t("how.step2Title")}</h3>
            <p>{t("how.step2Body")}</p>
          </div>
          <div className="step-card">
            <div className="step-number">03</div>
            <h3>{t("how.step3Title")}</h3>
            <p>{t("how.step3Body")}</p>
          </div>
        </div>
      </section>

      <section id="wat-krijg-je" className="partners-section">
        <h2>{t("what.title")}</h2>
        <div className="partners-what-grid">
          <ul className="pricing-features" style={{ marginBottom: 0 }}>
            {(["f1", "f2", "f3", "f4", "f5", "f6"] as const).map((k) => (
              <li key={k}>
                <div className="check-circle">
                  <svg width="10" height="8" viewBox="0 0 10 8" aria-hidden>
                    <polyline
                      points="1,4 4,7 9,1"
                      stroke="#2A6049"
                      strokeWidth="1.5"
                      fill="none"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                </div>
                {t(`what.${k}`)}
              </li>
            ))}
          </ul>
          <div className="partners-pricing-dark">
            <div className="partners-price-big">{t("what.price")}</div>
            <div className="partners-price-sub">{t("what.perMonth")}</div>
            <div className="partners-price-note">{t("what.trialNote")}</div>
            <div className="partners-price-small">{t("what.cancelNote")}</div>
            <button
              type="button"
              className="partners-btn-cream"
              onClick={() => setApplyOpen(true)}
            >
              {t("what.pricingCta")}
            </button>
          </div>
        </div>
      </section>

      <p className="partners-honest">{t("honest")}</p>

      <section id="aanvragen" className="partners-section">
        <p className="section-eyebrow">{t("hero.eyebrow")}</p>
        <h2>{t("form.title")}</h2>
        <p className="section-sub" style={{ marginBottom: 28 }}>
          {t("form.sub")}
        </p>

        <div className="partners-form-card">
          <button type="button" className="btn-trial" onClick={() => setApplyOpen(true)}>
            {t("hero.ctaPrimary")}
          </button>
        </div>

        <form hidden aria-hidden="true" tabIndex={-1} data-partner-form-legacy />
      </section>

      <section className="partners-section">
        <h2>{t("faq.title")}</h2>
        <div>
          {faqItems.map((item, i) => (
            <div key={i} className="partners-faq-item">
              <button
                type="button"
                className="partners-faq-q"
                aria-expanded={openFaq === i}
                onClick={() => setOpenFaq(openFaq === i ? null : i)}
              >
                {item.q}
                <span aria-hidden style={{ color: "var(--stone)" }}>
                  {openFaq === i ? "−" : "+"}
                </span>
              </button>
              {openFaq === i ? <div className="partners-faq-a">{item.a}</div> : null}
            </div>
          ))}
        </div>
      </section>

      <div className="partners-final">
        <h2>{t("final.title")}</h2>
        <button
          type="button"
          className="btn-primary"
          style={{ justifyContent: "center" }}
          onClick={() => setApplyOpen(true)}
        >
          {t("final.cta")}
        </button>
      </div>

      <footer className="landing-footer">
        <div className="footer-logo">{tFooter("brand")}</div>
        <ul className="footer-links">
          <li>
            <Link href="/privacy">{tFooter("privacy")}</Link>
          </li>
          <li>
            <Link href="/terms">{tFooter("terms")}</Link>
          </li>
          <li>
            <a href={`mailto:${tLegal("contactEmail")}`}>{tFooter("contact")}</a>
          </li>
          <li>
            <Link href="/partners">{tFooter("partners")}</Link>
          </li>
          <li>
            <a href={`/${currentLocale}#business`}>{tFooter("forBusiness")}</a>
          </li>
        </ul>
        <div className="footer-copy">
          © {new Date().getFullYear()} {tFooter("brand")}
        </div>
      </footer>
    </div>
  );
}
