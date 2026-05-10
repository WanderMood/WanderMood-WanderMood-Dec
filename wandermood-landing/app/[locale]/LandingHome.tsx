"use client";

import { useEffect, useMemo, useRef } from "react";
import Image from "next/image";
import { useLocale, useTranslations } from "next-intl";
import { Link, usePathname, useRouter } from "@/i18n/navigation";
import { getLandingImages } from "@/lib/landing-images";

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
    <svg width="10" height="8" viewBox="0 0 10 8" fill="none" aria-hidden>
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

function PhoneShot({
  src,
  alt,
  priority,
  className,
}: {
  src: string;
  alt: string;
  priority?: boolean;
  className?: string;
}) {
  return (
    <div className={`landing-device-shell ${className ?? ""}`}>
      <div className="landing-device-screen">
        <Image
          src={src}
          alt={alt}
          fill
          className="landing-device-img"
          sizes="(max-width: 900px) 78vw, 240px"
          priority={priority}
        />
      </div>
    </div>
  );
}

/** iPhone 16 Pro Max–style frame: titanium rail + side controls (CSS). */
function IPhone16ProMaxShot({
  src,
  alt,
  className,
}: {
  src: string;
  alt: string;
  className?: string;
}) {
  return (
    <div className={`landing-iphone16 ${className ?? ""}`}>
      <span className="landing-iphone16-btn landing-iphone16-btn--vol-up" aria-hidden />
      <span className="landing-iphone16-btn landing-iphone16-btn--vol-down" aria-hidden />
      <span className="landing-iphone16-btn landing-iphone16-btn--power" aria-hidden />
      <span className="landing-iphone16-btn landing-iphone16-btn--camera-ctl" aria-hidden />
      <div className="landing-iphone16-rail">
        <div className="landing-iphone16-inner">
          <div className="landing-iphone16-screen">
            <Image
              src={src}
              alt={alt}
              fill
              className="landing-iphone16-img"
              sizes="(max-width: 900px) 90vw, 300px"
            />
          </div>
        </div>
      </div>
    </div>
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

  const img = useMemo(() => getLandingImages(currentLocale), [currentLocale]);

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
            }, i * 60);
            observer.unobserve(el);
          }
        });
      },
      { threshold: 0.1 },
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

  const title2 = t("hero.title2");

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
            <a href="#features">{t("nav.features")}</a>
          </li>
          <li>
            <a href="#meet-moody">{t("nav.meetMoody")}</a>
          </li>
          <li>
            <a href="#mood-match">{t("nav.moodMatch")}</a>
          </li>
          <li>
            <a href="#explore-city">{t("nav.exploreNav")}</a>
          </li>
          <li>
            <Link href="/partners">{t("nav.partners")}</Link>
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

      <section id="app-preview" className="landing-hero-v2">
        <div className="landing-hero-inner">
          <div className="landing-hero-copy">
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
              {title2 ? (
                <>
                  <br />
                  {title2}
                </>
              ) : null}
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
            <p className="landing-proof-line">
              <span className="landing-proof-strong">{t("proof.appStoreLine")}</span>{" "}
              {t("proof.line")}
            </p>
          </div>
          <div className="landing-hero-visual">
            <PhoneShot
              src={img.heroPhone}
              alt={t("imgAlt.hero")}
              priority
              className="landing-hero-phone"
            />
          </div>
        </div>
      </section>

      <div className="divider" aria-hidden />

      <section id="features" className="landing-why">
        <div className="landing-section-inner">
          <p className="section-eyebrow reveal">{t("why.eyebrow")}</p>
          <h2 className="reveal landing-section-title">
            {t("why.title")} <em>{t("why.titleEm")}</em>
          </h2>
          <p className="section-sub reveal landing-why-sub">{t("why.sub")}</p>
          <div className="landing-why-grid">
            {(
              [
                ["u1t", "u1b"],
                ["u2t", "u2b"],
                ["u3t", "u3b"],
                ["u4t", "u4b"],
                ["u5t", "u5b"],
                ["u6t", "u6b"],
              ] as const
            ).map(([tk, bk]) => (
              <div key={tk} className="landing-why-card reveal">
                <h3>{t(`why.${tk}`)}</h3>
                <p>{t(`why.${bk}`)}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="how" className="landing-demo">
        <div className="landing-section-inner">
          <p className="section-eyebrow reveal">{t("demo.eyebrow")}</p>
          <h2 className="reveal landing-section-title">
            {t("demo.title")} <em>{t("demo.titleEm")}</em>
          </h2>
          <p className="section-sub reveal">{t("demo.sub")}</p>
          <div className="landing-demo-grid">
            {(
              [
                ["s1t", "s1b", img.stepMood],
                ["s2t", "s2b", img.stepMoody],
                ["s3t", "s3b", img.stepPlan],
                ["s4t", "s4b", img.stepDetail],
              ] as const
            ).map(([tk, bk, shot]) => (
              <div key={tk} className="landing-demo-step reveal">
                <PhoneShot src={shot} alt={t("imgAlt.demoStep")} className="landing-demo-phone" />
                <h3>{t(`demo.${tk}`)}</h3>
                <p>{t(`demo.${bk}`)}</p>
              </div>
            ))}
          </div>
          <div className="landing-mid-cta reveal">
            <a {...APP_STORE_LINK_PROPS} className="btn-primary">
              <AppStoreIcon />
              {t("hero.appStore")}
            </a>
          </div>
        </div>
      </section>

      <section id="meet-moody" className="landing-meet">
        <div className="landing-section-inner landing-meet-grid">
          <div>
            <p className="section-eyebrow reveal">{t("meetMoodySect.eyebrow")}</p>
            <h2 className="reveal landing-section-title">{t("meetMoodySect.title")}</h2>
            <p className="section-sub reveal">{t("meetMoodySect.sub")}</p>
            <ul className="landing-chat-prompts reveal">
              {(["q1", "q2", "q3", "q4", "q5", "q6"] as const).map((k) => (
                <li key={k}>{t(`meetMoodySect.${k}`)}</li>
              ))}
            </ul>
            <a {...APP_STORE_LINK_PROPS} className="btn-primary landing-meet-cta">
              <AppStoreIcon />
              {t("hero.appStore")}
            </a>
          </div>
          <div className="reveal">
            <PhoneShot src={img.meetMoody} alt={t("imgAlt.meetMoody")} />
          </div>
        </div>
      </section>

      <section id="mood-match" className="landing-mood-match">
        <div className="landing-section-inner landing-mood-match-grid">
          <div className="reveal landing-mood-match-shots">
            <PhoneShot
              src={img.moodMatchWait}
              alt={t("imgAlt.moodMatchWait")}
              className="landing-mm-wait"
            />
            <PhoneShot
              src={img.moodMatch}
              alt={t("imgAlt.moodMatch")}
              className="landing-mm-result"
            />
          </div>
          <div>
            <p className="section-eyebrow reveal">{t("moodMatchSect.eyebrow")}</p>
            <h2 className="reveal landing-section-title">
              {t("moodMatchSect.title")} <em>{t("moodMatchSect.titleEm")}</em>
            </h2>
            <p className="section-sub reveal">{t("moodMatchSect.sub")}</p>
            <a {...APP_STORE_LINK_PROPS} className="btn-primary landing-mood-match-cta reveal">
              <AppStoreIcon />
              {t("moodMatchSect.cta")}
            </a>
          </div>
        </div>
      </section>

      <section id="explore-city" className="landing-explore">
        <div className="landing-section-inner landing-explore-grid">
          <div className="reveal">
            <PhoneShot src={img.explore} alt={t("imgAlt.explore")} />
          </div>
          <div>
            <p className="section-eyebrow reveal">{t("exploreSect.eyebrow")}</p>
            <h2 className="reveal landing-section-title">
              {t("exploreSect.title")} <em>{t("exploreSect.titleEm")}</em>
            </h2>
            <p className="section-sub reveal">{t("exploreSect.sub")}</p>
            <ul className="landing-bullet-list reveal">
              {(["b1", "b2", "b3", "b4", "b5"] as const).map((k) => (
                <li key={k}>{t(`exploreSect.${k}`)}</li>
              ))}
            </ul>
            <a {...APP_STORE_LINK_PROPS} className="btn-secondary">
              {t("hero.appStore")}
            </a>
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
        <div className="b2b-inner landing-b2b-grid">
          <div>
            <p className="section-eyebrow reveal">{t("b2b.eyebrow")}</p>
            <h2 className="reveal">
              {t("b2b.titleBefore")}
              <em>{t("b2b.titleEm")}</em>
            </h2>
            <p className="b2b-desc reveal">{t("b2b.desc1")}</p>
            <p className="b2b-small reveal">{t("b2b.desc2")}</p>
            <Link href="/partners#aanvragen" className="btn-trial reveal">
              {t("b2b.trialCta")}
            </Link>
          </div>
          <div className="reveal landing-b2b-visual">
            <p className="landing-b2b-caption">{t("b2bPreview.caption")}</p>
            <IPhone16ProMaxShot src={img.b2bExplore} alt={t("imgAlt.b2bExplore")} />
          </div>
          <div className="pricing-card reveal landing-b2b-pricing">
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
        </ul>
        <div className="footer-copy">
          © {new Date().getFullYear()} {tFooter("brand")}
        </div>
      </footer>
    </div>
  );
}
