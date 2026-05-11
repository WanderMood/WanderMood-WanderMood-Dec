"use client";

import Image from "next/image";
import { useEffect, useMemo, useRef, useState } from "react";
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

const APP_STORE_BY_LOCALE: Record<string, string> = {
  en: "https://apps.apple.com/app/wandermood/id6760943488",
  nl: "https://apps.apple.com/nl/app/wandermood/id6760943488",
  de: "https://apps.apple.com/de/app/wandermood/id6760943488",
  es: "https://apps.apple.com/es/app/wandermood/id6760943488",
  fr: "https://apps.apple.com/fr/app/wandermood/id6760943488",
};

const WHAT_CARD_KEYS = [1, 2, 3, 4, 5, 6] as const;

const WHO_EMOJI = ["🍽️", "🏛️", "🏨", "🗺️"] as const;

export default function PartnersClient() {
  const t = useTranslations("partners");
  const tFooter = useTranslations("footer");
  const tLegal = useTranslations("legal.common");
  const router = useRouter();
  const pathname = usePathname();
  const currentLocale = useLocale();
  const rootRef = useRef<HTMLDivElement>(null);
  const [applyOpen, setApplyOpen] = useState(false);
  const [openFaq, setOpenFaq] = useState<number | null>(0);
  const [navScrolled, setNavScrolled] = useState(false);

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

  const appStoreUrl = APP_STORE_BY_LOCALE[currentLocale] ?? APP_STORE_BY_LOCALE.en;

  useEffect(() => {
    const onScroll = () => setNavScrolled(window.scrollY > 20);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;
    const nodes = root.querySelectorAll(".reveal");
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) e.target.classList.add("visible");
        });
      },
      { threshold: 0.08, rootMargin: "0px 0px -40px 0px" },
    );
    nodes.forEach((n) => observer.observe(n));
    return () => observer.disconnect();
  }, []);

  return (
    <div ref={rootRef} className="landing-root landing-page--partners">
      <PartnerApplyModal open={applyOpen} onClose={() => setApplyOpen(false)} />

      <nav
        id="landing-nav"
        className={`partners-top-nav ${navScrolled ? "partners-top-nav--scrolled" : ""}`}
      >
        <Link href="/" className="nav-logo partners-top-nav__logo">
          <div className="nav-logo-icon nav-logo-icon--app">
            <Image
              src="/icon.png"
              alt=""
              width={34}
              height={34}
              sizes="34px"
              priority
              className="nav-logo-app-img"
            />
          </div>
          <span className="nav-logo-text">{tFooter("brand")}</span>
        </Link>
        <ul className="nav-links partners-top-nav__links">
          <li>
            <Link href="/">{t("nav.home")}</Link>
          </li>
          <li>
            <a href="#hoe-werkt-het">{t("nav.how")}</a>
          </li>
          <li>
            <a href="#aanvragen">{t("nav.apply")}</a>
          </li>
        </ul>
        <div className="nav-end partners-top-nav__end">
          <div className="nav-locales partners-top-nav__locales" role="group" aria-label="Language">
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
          <a
            href={appStoreUrl}
            className="partners-top-nav__download"
            target="_blank"
            rel="noopener noreferrer"
          >
            {t("nav.download")}
          </a>
        </div>
      </nav>

      <section className="partners-hero partners-surface partners-surface--dark">
        <div className="partners-inner">
          <p className="partners-label reveal">{t("hero.eyebrow")}</p>
          <h1 className="partners-hero-title reveal">{t("hero.title")}</h1>
          <p className="partners-hero-sub reveal">{t("hero.sub")}</p>
          <div className="partners-hero-actions reveal">
            <button type="button" className="partners-btn-primary" onClick={() => setApplyOpen(true)}>
              {t("hero.ctaPrimary")}
            </button>
            <a href="#hoe-werkt-het" className="partners-btn-secondary">
              {t("hero.ctaSecondary")}
            </a>
          </div>
        </div>
      </section>

      <section className="partners-insight partners-surface partners-surface--dark">
        <div className="partners-inner partners-insight__inner">
          <div className="partners-insight__col reveal">
            <div className="partners-insight__num">{t("insight.col1Num")}</div>
            <p className="partners-insight__label">{t("insight.col1Label")}</p>
          </div>
          <div className="partners-insight__divider" aria-hidden />
          <div className="partners-insight__col reveal">
            <div className="partners-insight__num">{t("insight.col2Num")}</div>
            <p className="partners-insight__label">{t("insight.col2Label")}</p>
          </div>
          <div className="partners-insight__divider" aria-hidden />
          <div className="partners-insight__col reveal">
            <div className="partners-insight__num">{t("insight.col3Num")}</div>
            <p className="partners-insight__label">{t("insight.col3Label")}</p>
          </div>
        </div>
      </section>

      <section id="wie" className="partners-section partners-surface partners-surface--beige partners-shell-overlap">
        <div className="partners-inner">
          <h2 className="partners-section-title partners-section-title--ink reveal">{t("who.title")}</h2>
          <div className="partners-who-grid">
            {[1, 2, 3, 4].map((n) => (
              <div key={n} className="partners-who-card reveal">
                <h3>
                  <span className="partners-who-card__emoji" aria-hidden>
                    {WHO_EMOJI[n - 1]}
                  </span>{" "}
                  {t(`who.card${n}Title` as "who.card1Title")}
                </h3>
                <p>{t(`who.card${n}Body` as "who.card1Body")}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="hoe-werkt-het" className="partners-section partners-surface partners-surface--dark partners-shell-overlap">
        <div className="partners-inner">
          <h2 className="partners-section-title reveal">{t("how.title")}</h2>
          <div className="partners-steps">
            {([1, 2, 3] as const).map((n) => (
              <div key={n} className="partners-step-card reveal">
                <div className="partners-step-card__num">
                  {n === 1 ? "01" : null}
                  {n === 2 ? "02" : null}
                  {n === 3 ? "03" : null}
                </div>
                <h3>{t(`how.step${n}Title` as "how.step1Title")}</h3>
                <p>{t(`how.step${n}Body` as "how.step1Body")}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="wat-krijg-je" className="partners-section partners-surface partners-surface--beige partners-shell-overlap">
        <div className="partners-inner">
          <h2 className="partners-section-title partners-section-title--ink reveal">{t("what.title")}</h2>
          <div className="partners-what-cards">
            {WHAT_CARD_KEYS.map((n) => (
              <div key={n} className="partners-what-card reveal">
                <div className="partners-what-card__emoji" aria-hidden>
                  {t(`what.card${n}Emoji` as "what.card1Emoji")}
                </div>
                <h3 className="partners-what-card__title">{t(`what.card${n}Title` as "what.card1Title")}</h3>
                <p className="partners-what-card__body">{t(`what.card${n}Body` as "what.card1Body")}</p>
              </div>
            ))}
          </div>

          <div className="partners-pricing-wrap reveal">
            <div className="partners-pricing-dark">
              <span className="partners-pricing-pill">{t("what.pricingPill")}</span>
              <div className="partners-price-big">{t("what.price")}</div>
              <div className="partners-price-sub">{t("what.perMonth")}</div>
              <div className="partners-price-note">{t("what.trialNote")}</div>
              <p className="partners-pricing-lockin">{t("what.pricingLockIn")}</p>
              <ul className="partners-pricing-bullets">
                {(["p1", "p2", "p3", "p4"] as const).map((k) => (
                  <li key={k}>
                    <span className="partners-pricing-check" aria-hidden>
                      <svg width="12" height="10" viewBox="0 0 12 10">
                        <polyline
                          points="1,5 4,9 11,1"
                          stroke="currentColor"
                          strokeWidth="1.6"
                          fill="none"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        />
                      </svg>
                    </span>
                    {t(`what.${k}`)}
                  </li>
                ))}
              </ul>
              <div className="partners-price-small">{t("what.cancelNote")}</div>
              <button type="button" className="partners-btn-cream" onClick={() => setApplyOpen(true)}>
                {t("what.pricingCta")}
              </button>
              <p className="partners-pricing-trust">{t("what.priceTrust")}</p>
            </div>
          </div>

          <p className="partners-honest reveal">{t("honest")}</p>
        </div>
      </section>

      <section id="aanvragen" className="partners-section partners-surface partners-surface--dark partners-shell-overlap">
        <div className="partners-inner">
          <p className="partners-label reveal">{t("hero.eyebrow")}</p>
          <h2 className="partners-section-title reveal">{t("form.title")}</h2>
          <p className="partners-form-lead reveal">{t("form.sub")}</p>

          <div className="partners-form-card reveal">
            <button type="button" className="partners-btn-primary partners-btn-primary--wide" onClick={() => setApplyOpen(true)}>
              {t("hero.ctaPrimary")}
            </button>
          </div>

          <form hidden aria-hidden="true" tabIndex={-1} data-partner-form-legacy />
        </div>
      </section>

      <section className="partners-section partners-surface partners-surface--beige partners-shell-overlap partners-faq-section">
        <div className="partners-inner">
          <h2 className="partners-section-title partners-section-title--ink reveal">{t("faq.title")}</h2>
          <div className="partners-faq-list">
            {faqItems.map((item, i) => (
              <div key={i} className="partners-faq-item reveal">
                <button
                  type="button"
                  className="partners-faq-q"
                  aria-expanded={openFaq === i}
                  onClick={() => setOpenFaq(openFaq === i ? null : i)}
                >
                  {item.q}
                  <span aria-hidden className="partners-faq-toggle">
                    {openFaq === i ? "−" : "+"}
                  </span>
                </button>
                {openFaq === i ? <div className="partners-faq-a">{item.a}</div> : null}
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="partners-final partners-surface partners-surface--dark partners-shell-overlap">
        <div className="partners-inner partners-final__inner">
          <h2 className="partners-final__title reveal">{t("final.title")}</h2>
          <p className="partners-final__sub reveal">{t("final.sub")}</p>
          <button type="button" className="partners-btn-primary" onClick={() => setApplyOpen(true)}>
            {t("final.cta")}
          </button>
        </div>
      </section>

      <footer className="landing-footer partners-footer">
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
        </ul>
        <div className="footer-copy">
          © {new Date().getFullYear()} {tFooter("brand")}
        </div>
      </footer>
    </div>
  );
}
