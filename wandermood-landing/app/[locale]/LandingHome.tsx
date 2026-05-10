"use client";

import { useEffect, useMemo, useRef } from "react";
import { useLocale, useTranslations } from "next-intl";
import { Link, usePathname, useRouter } from "@/i18n/navigation";
import LandingTour, { type LandingTourHandle } from "@/components/LandingTour";
import { LandingWalkthroughPlayer } from "@/components/LandingWalkthroughPlayer";
import { buildWalkthroughCopyForVideo } from "@/lib/build-walkthrough-copy";

const APP_STORE_URL =
  "https://apps.apple.com/nl/app/wandermood/id6760943488";

const APP_STORE_LINK_PROPS = {
  href: APP_STORE_URL,
  target: "_blank",
  rel: "noopener noreferrer",
} as const;

const LOCALES = [
  { code: "en", label: "EN" },
  { code: "nl", label: "NL" },
  { code: "de", label: "DE" },
  { code: "es", label: "ES" },
  { code: "fr", label: "FR" },
] as const;

/** Old full-page deck used these hashes; map to new sections after deploy. */
const LEGACY_HASH_TARGETS: Record<string, string> = {
  hero: "app-preview",
  experience: "how",
  "how-it-works": "how",
  cta: "download",
};

const MOOD_ITEMS = [
  { key: "relaxed", emoji: "😌" },
  { key: "foodie", emoji: "🍴" },
  { key: "energetic", emoji: "🔥" },
  { key: "adventurous", emoji: "🏕️" },
  { key: "cultural", emoji: "🎨" },
  { key: "cozy", emoji: "🧘" },
  { key: "romantic", emoji: "💕" },
  { key: "social", emoji: "👥" },
  { key: "curious", emoji: "🔍" },
  { key: "excited", emoji: "🌟" },
  { key: "happy", emoji: "😊" },
  { key: "surprise", emoji: "😲" },
] as const;

function AppStoreIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden>
      <path
        d="M11 2H5C4.4 2 4 2.4 4 3v10c0 .6.4 1 1 1h6c.6 0 1-.4 1-1V3c0-.6-.4-1-1-1zm-3 10.5a.75.75 0 110-1.5.75.75 0 010 1.5z"
        fill="currentColor"
      />
    </svg>
  );
}

function CheckIcon() {
  return (
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
  );
}

export default function LandingHome() {
  const t = useTranslations("landing");
  const tFooter = useTranslations("footer");
  const tLegal = useTranslations("legal.common");
  const router = useRouter();
  const pathname = usePathname();
  const currentLocale = useLocale();
  const rootRef = useRef<HTMLDivElement>(null);
  const tourRef = useRef<LandingTourHandle>(null);

  const trialMail = `mailto:${tLegal("contactEmail")}?subject=${encodeURIComponent(t("b2b.trialSubject"))}`;

  const walkthroughVideoProps = useMemo(() => {
    const { stepTitles, stepBodies } = buildWalkthroughCopyForVideo(t);
    return { stepTitles, stepBodies };
  }, [t]);

  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;
    const nodes = root.querySelectorAll(".reveal");
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry, i) => {
          if (entry.isIntersecting) {
            const el = entry.target as HTMLElement;
            window.setTimeout(() => {
              el.classList.add("visible");
            }, i * 80);
            observer.unobserve(el);
          }
        });
      },
      { threshold: 0.12 },
    );
    nodes.forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    const raw = window.location.hash.slice(1);
    if (!raw) return;
    const id = LEGACY_HASH_TARGETS[raw] ?? raw;
    const el = document.getElementById(id);
    if (!el) return;
    window.requestAnimationFrame(() => {
      el.scrollIntoView({ behavior: "smooth", block: "start" });
    });
  }, [pathname]);

  return (
    <div ref={rootRef} className="landing-root">
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
            <a href="#how">{t("nav.how")}</a>
          </li>
          <li>
            <Link href="/partners">{t("nav.partners")}</Link>
          </li>
          <li>
            <a href="#moods">{t("nav.moods")}</a>
          </li>
          <li>
            <a href="#business">{t("nav.business")}</a>
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
                aria-label={`${label}`}
              >
                {label}
              </button>
            ))}
          </div>
          <a {...APP_STORE_LINK_PROPS} className="nav-cta">
            {t("nav.download")}
          </a>
        </div>
      </nav>

      <section id="app-preview">
        <div className="hero">
          <div>
            <div className="hero-badge">
              <svg width="8" height="8" viewBox="0 0 8 8" aria-hidden>
                <circle cx="4" cy="4" r="4" fill="#2A6049" />
              </svg>
              {t("hero.badge")}
            </div>
            <h1>
              {t("hero.title1")}
              <br />
              <em>{t("hero.titleEm")}</em>
              <br />
              {t("hero.title2")}
            </h1>
            <p className="hero-sub">{t("hero.sub")}</p>
            <div className="hero-actions">
              <a {...APP_STORE_LINK_PROPS} className="btn-primary">
                <AppStoreIcon />
                {t("hero.appStore")}
              </a>
              <a href="#how" className="btn-secondary">
                {t("hero.seeHow")}
              </a>
            </div>
          </div>
          <div className="phone-wrap">
            <div className="phone-outer">
              <div className="phone-notch" aria-hidden />
              <div className="phone-screen">
                <div className="phone-status">
                  <span>9:41</span>
                  <span aria-hidden>●●●</span>
                </div>
                <div className="phone-header">
                  <div className="phone-header-row">
                    <div>
                      <div className="phone-greeting">{t("phone.greeting")}</div>
                      <div className="phone-title">{t("phone.myDay")}</div>
                    </div>
                    <div className="phone-avatar" aria-hidden />
                  </div>
                  <div className="phone-moody-bubble">{t("phone.bubble")}</div>
                </div>
                <div className="phone-body">
                  <div className="phone-label">{t("phone.planLabel")}</div>
                  <div className="phone-card">
                    <div className="phone-dot" style={{ background: "#E8784A" }} aria-hidden />
                    <div>
                      <div className="phone-card-name">{t("phone.card1Name")}</div>
                      <div className="phone-card-time">{t("phone.card1Time")}</div>
                      <div className="phone-card-desc">{t("phone.card1Desc")}</div>
                    </div>
                  </div>
                  <div className="phone-card">
                    <div className="phone-dot" style={{ background: "#2A6049" }} aria-hidden />
                    <div>
                      <div className="phone-card-name">{t("phone.card2Name")}</div>
                      <div className="phone-card-time">{t("phone.card2Time")}</div>
                      <div className="phone-card-desc">{t("phone.card2Desc")}</div>
                    </div>
                  </div>
                  <div className="phone-card">
                    <div className="phone-dot" style={{ background: "#A8C8DC" }} aria-hidden />
                    <div>
                      <div className="phone-card-name">{t("phone.card3Name")}</div>
                      <div className="phone-card-time">{t("phone.card3Time")}</div>
                      <div className="phone-card-desc">{t("phone.card3Desc")}</div>
                    </div>
                  </div>
                </div>
                <div className="phone-navbar">
                  <div className="phone-nav-item active">
                    <div className="phone-nav-dot" aria-hidden>
                      🏠
                    </div>
                    <span>{t("phone.tabMyDay")}</span>
                  </div>
                  <div className="phone-nav-item">
                    <div className="phone-nav-dot" aria-hidden>
                      🔍
                    </div>
                    <span>{t("phone.tabExplore")}</span>
                  </div>
                  <div className="phone-nav-item">
                    <div className="phone-nav-dot" aria-hidden>
                      🌀
                    </div>
                    <span>{t("phone.tabMoody")}</span>
                  </div>
                  <div className="phone-nav-item">
                    <div className="phone-nav-dot" aria-hidden>
                      👤
                    </div>
                    <span>{t("phone.tabProfile")}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <div className="divider" aria-hidden />

      <section id="walkthrough-video" className="walkthrough-video-section">
        <div className="walkthrough-video-inner">
          <p className="section-eyebrow reveal">{t("walkthroughVideo.eyebrow")}</p>
          <h2 className="reveal walkthrough-video-title">
            {t("walkthroughVideo.title1")}
            <br />
            <em>{t("walkthroughVideo.titleEm")}</em>
          </h2>
          <p className="section-sub reveal">{t("walkthroughVideo.sub")}</p>
          <div className="walkthrough-video-player-wrap reveal">
            <LandingWalkthroughPlayer {...walkthroughVideoProps} />
          </div>
        </div>
      </section>

      <div className="divider" aria-hidden />

      <section id="how">
        <div className="section">
          <p className="section-eyebrow reveal">{t("how.eyebrow")}</p>
          <h2 className="reveal">
            {t("how.title1")}
            <br />
            <em>{t("how.titleEm")}</em>
          </h2>
          <p className="section-sub reveal">{t("how.sub")}</p>
          <div className="steps-grid">
            <div className="step-card reveal">
              <div className="step-number">01</div>
              <h3>{t("how.step1Title")}</h3>
              <p>{t("how.step1Body")}</p>
              <div className="step-moody">{t("how.step1Moody")}</div>
            </div>
            <div className="step-card reveal">
              <div className="step-number">02</div>
              <h3>{t("how.step2Title")}</h3>
              <p>{t("how.step2Body")}</p>
              <div className="step-moody">{t("how.step2Moody")}</div>
            </div>
            <div className="step-card reveal">
              <div className="step-number">03</div>
              <h3>{t("how.step3Title")}</h3>
              <p>{t("how.step3Body")}</p>
              <div className="step-moody">{t("how.step3Moody")}</div>
            </div>
          </div>
        </div>
      </section>

      <section id="moods" className="moods-section">
        <div className="moods-inner">
          <p className="section-eyebrow reveal">{t("moodsSection.eyebrow")}</p>
          <h2 className="reveal">
            {t("moodsSection.title1")}
            <br />
            <em>{t("moodsSection.titleEm")}</em>
          </h2>
          <div className="moods-grid">
            {MOOD_ITEMS.map(({ key, emoji }) => (
              <div key={key} className="mood-chip reveal">
                <span className="mood-emoji">{emoji}</span>
                <span className="mood-name">{t(`moods.${key}`)}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="business" className="b2b-section">
        <div className="b2b-inner">
          <div>
            <p className="section-eyebrow reveal">{t("b2b.eyebrow")}</p>
            <h2 className="reveal">
              {t("b2b.titleBefore")}
              <em>{t("b2b.titleEm")}</em>
            </h2>
            <p className="b2b-desc reveal">{t("b2b.desc1")}</p>
            <p className="b2b-small reveal">{t("b2b.desc2")}</p>
          </div>
          <div className="pricing-card reveal">
            <div className="pricing-price">{t("b2b.price")}</div>
            <div className="pricing-note">{t("b2b.priceNote")}</div>
            <ul className="pricing-features">
              {(["f1", "f2", "f3", "f4"] as const).map((k) => (
                <li key={k}>
                  <div className="check-circle">
                    <CheckIcon />
                  </div>
                  {t(`b2b.${k}`)}
                </li>
              ))}
            </ul>
            <Link href="/partners#aanvragen" className="btn-trial">
              {t("b2b.trialCta")}
            </Link>
          </div>
        </div>
      </section>

      <section id="download">
        <div className="cta-section">
          <p className="section-eyebrow reveal" style={{ textAlign: "center" }}>
            {t("cta.eyebrow")}
          </p>
          <h2 className="reveal">
            {t("cta.title1")}
            <br />
            <em>{t("cta.titleEm")}</em>
          </h2>
          <p className="reveal">{t("cta.sub")}</p>
          <div className="cta-buttons reveal">
            <a {...APP_STORE_LINK_PROPS} className="btn-primary">
              <AppStoreIcon />
              {t("cta.appStore")}
            </a>
            {process.env.NEXT_PUBLIC_SHOW_GOOGLE_PLAY === "true" ? (
              <a href="#" className="btn-secondary">
                {t("cta.googlePlay")}
              </a>
            ) : null}
          </div>
        </div>
      </section>

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
            <a href="#business">{tFooter("forBusiness")}</a>
          </li>
          <li>
            <button type="button" className="footer-tour-btn" onClick={() => tourRef.current?.start()}>
              {t("tour.replay")}
            </button>
          </li>
        </ul>
        <div className="footer-copy">
          © {new Date().getFullYear()} {tFooter("brand")}
        </div>
      </footer>
      <LandingTour ref={tourRef} />
    </div>
  );
}
