"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";
import Image from "next/image";
import { useLocale, useTranslations } from "next-intl";
import { Link, usePathname, useRouter } from "@/i18n/navigation";
import { AppStoreCtaLink } from "@/components/AppStoreCtaLink";
import { PhoneFrame } from "@/components/PhoneFrame";
import { ExploreMockup } from "@/components/mockups/ExploreMockup";
import { MoodMatchMockup } from "@/components/mockups/MoodMatchMockup";
import { MoodyChatMockup } from "@/components/mockups/MoodyChatMockup";
import { MyDayMockup } from "@/components/mockups/MyDayMockup";
import { getHomepageScreens } from "@/lib/homepage-screens";
import "@/components/mockups/mockups.css";

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
  hero: "hero",
  "app-preview": "hero",
  experience: "how",
  "how-it-works": "how",
  features: "features",
  "mood-match": "mood-match",
  moods: "moods",
  business: "business",
  cta: "download",
  download: "download",
};

const HOW_STEP_ICONS = ["🎭", "💬", "📅", "🗺️"] as const;

const MOOD_GRID = [
  { key: "relaxed", emoji: "😌" },
  { key: "foodie", emoji: "🍽️" },
  { key: "energetic", emoji: "⚡" },
  { key: "adventurous", emoji: "🚀" },
  { key: "cultural", emoji: "🎭" },
  { key: "cozy", emoji: "☕" },
  { key: "romantic", emoji: "💕" },
  { key: "social", emoji: "👫" },
  { key: "curious", emoji: "🔍" },
  { key: "excited", emoji: "🤩" },
  { key: "happy", emoji: "😊" },
  { key: "surprise", emoji: "😲" },
] as const;

type PublicStats = {
  users: number | null;
  partners: number | null;
  show: boolean;
};

function FeatureBandPhoneMock({ index, locale }: { index: number; locale: string }) {
  if (index === 0) return <MoodyChatMockup locale={locale} />;
  if (index === 1) return <MyDayMockup locale={locale} />;
  return <ExploreMockup locale={locale} />;
}

function AnimatedCounter({ value, locale }: { value: number; locale: string }) {
  const [count, setCount] = useState(0);
  const ref = useRef<HTMLSpanElement>(null);
  const started = useRef(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([e]) => {
        if (!e.isIntersecting || started.current) return;
        started.current = true;
        const t0 = performance.now();
        const dur = 1500;
        const step = (now: number) => {
          const t = Math.min(1, (now - t0) / dur);
          setCount(Math.floor(value * t));
          if (t < 1) requestAnimationFrame(step);
          else setCount(value);
        };
        requestAnimationFrame(step);
      },
      { threshold: 0.3 },
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [value]);

  const loc = locale === "nl" ? "nl-NL" : "en-GB";
  return (
    <span ref={ref} className="home-stat-value">
      {count.toLocaleString(loc)}
    </span>
  );
}

export default function LandingHome() {
  const th = useTranslations("landing.home");
  const tMoods = useTranslations("landing.moods");
  const tLanding = useTranslations("landing");
  const tFooter = useTranslations("footer");
  const tLegal = useTranslations("legal.common");
  const router = useRouter();
  const pathname = usePathname();
  const currentLocale = useLocale();
  const rootRef = useRef<HTMLDivElement>(null);
  const featurePanelRefs = useRef<(HTMLDivElement | null)[]>([]);
  const featureActiveRef = useRef(0);
  const featureFadeTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const moodsSectionRef = useRef<HTMLElement | null>(null);
  const [featurePhoneIdx, setFeaturePhoneIdx] = useState(0);
  const [featurePhoneFade, setFeaturePhoneFade] = useState(false);
  const [navScrolled, setNavScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [menuPortalReady, setMenuPortalReady] = useState(false);
  const [stats, setStats] = useState<PublicStats | null>(null);

  const screens = useMemo(() => getHomepageScreens(currentLocale), [currentLocale]);

  const featureSlides = useMemo(
    () => [
      {
        label: th("featMoodyLabel"),
        titleLine1: th("featMoodyH1"),
        titleLine2: th("featMoodyH2"),
        body: th("featMoodyB"),
      },
      {
        label: th("featDayLabel"),
        titleLine1: th("featDayH1"),
        titleLine2: th("featDayH2"),
        body: th("featDayB"),
      },
      {
        label: th("featExploreLabel"),
        titleLine1: th("featExploreH1"),
        titleLine2: th("featExploreH2"),
        body: th("featExploreB"),
      },
    ],
    [th],
  );

  useEffect(() => {
    const onScroll = () => setNavScrolled(window.scrollY > 20);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  useEffect(() => {
    fetch("/api/stats/public")
      .then((r) => r.json())
      .then((data: PublicStats) => setStats(data))
      .catch(() => {});
  }, []);

  useEffect(() => {
    const panels = featurePanelRefs.current.filter(
      (p): p is HTMLDivElement => p != null,
    );
    if (panels.length === 0) return;

    const mq = window.matchMedia("(min-width: 900px)");

    const updateStickyFeatures = () => {
      if (!mq.matches) {
        panels.forEach((p) => p.classList.remove("home-feature-panel--active"));
        return;
      }
      const mid = window.innerHeight * 0.45;
      const edge = 100;
      let best = 0;
      let bestDist = Infinity;
      panels.forEach((p, i) => {
        const r = p.getBoundingClientRect();
        if (r.bottom < edge || r.top > window.innerHeight - edge) return;
        const c = r.top + r.height / 2;
        const d = Math.abs(c - mid);
        if (d < bestDist) {
          bestDist = d;
          best = i;
        }
      });
      panels.forEach((p, i) => {
        p.classList.toggle("home-feature-panel--active", i === best);
      });
      if (best !== featureActiveRef.current) {
        featureActiveRef.current = best;
        if (featureFadeTimerRef.current) {
          clearTimeout(featureFadeTimerRef.current);
        }
        setFeaturePhoneFade(true);
        featureFadeTimerRef.current = setTimeout(() => {
          setFeaturePhoneIdx(best);
          setFeaturePhoneFade(false);
          featureFadeTimerRef.current = null;
        }, 200);
      }
    };

    panels[0]?.classList.add("home-feature-panel--active");
    featureActiveRef.current = 0;
    setFeaturePhoneIdx(0);

    const onScroll = () => {
      window.requestAnimationFrame(updateStickyFeatures);
    };

    const tInit = window.setTimeout(updateStickyFeatures, 0);
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll, { passive: true });
    mq.addEventListener("change", onScroll);

    return () => {
      clearTimeout(tInit);
      if (featureFadeTimerRef.current) {
        clearTimeout(featureFadeTimerRef.current);
      }
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
      mq.removeEventListener("change", onScroll);
    };
  }, [featureSlides, currentLocale]);

  useEffect(() => {
    const section = moodsSectionRef.current;
    if (!section) return;
    const grid = section.querySelector(".home-moods-grid");
    if (!grid) return;
    const obs = new IntersectionObserver(
      ([e]) => {
        if (e?.isIntersecting) {
          grid.classList.add("home-moods-animate");
          obs.disconnect();
        }
      },
      { threshold: 0.3 },
    );
    obs.observe(section);
    return () => obs.disconnect();
  }, []);

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
            }, i * 50);
            observer.unobserve(el);
          }
        });
      },
      { threshold: 0.3 },
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

  useEffect(() => {
    setMenuPortalReady(true);
  }, []);

  useEffect(() => {
    if (!menuOpen) return;
    const html = document.documentElement;
    const body = document.body;
    const prevBodyOverflow = body.style.overflow;
    const prevHtmlOverflow = html.style.overflow;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setMenuOpen(false);
    };
    body.style.overflow = "hidden";
    html.style.overflow = "hidden";
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("keydown", onKey);
      body.style.overflow = prevBodyOverflow;
      html.style.overflow = prevHtmlOverflow;
    };
  }, [menuOpen]);

  const howSteps = [
    { h: th("how1h"), p: th("how1p") },
    { h: th("how2h"), p: th("how2p") },
    { h: th("how3h"), p: th("how3p") },
    { h: th("how4h"), p: th("how4p") },
  ] as const;

  return (
    <>
      <div ref={rootRef} className="landing-root landing-page--home">
      <header
        className={`home-nav ${navScrolled ? "home-nav--scrolled" : ""}`}
        id="landing-nav"
      >
        <Link href="/" className="nav-logo">
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

        <ul className="home-nav-links">
          <li>
            <a href="#how">{th("navHow")}</a>
          </li>
          <li>
            <a href="#features">{th("navFeatures")}</a>
          </li>
          <li>
            <Link href="/partners">{th("navPartners")}</Link>
          </li>
        </ul>

        <div className="home-nav-end">
          <div className="home-nav-locales" role="group" aria-label="Language">
            {LOCALES.map(({ code, label }) => (
              <button
                key={code}
                type="button"
                className={`home-nav-locale-btn ${currentLocale === code ? "active" : ""}`}
                onClick={() => router.replace(pathname, { locale: code })}
                aria-pressed={currentLocale === code}
                aria-label={label}
              >
                {label}
              </button>
            ))}
          </div>
          <a {...APP_STORE_LINK_PROPS} className="home-nav-download">
            {th("navDownload")}
          </a>
          <button
            type="button"
            className="home-nav-burger"
            aria-expanded={menuOpen}
            aria-label={menuOpen ? th("navMenuClose") : th("navMenuOpen")}
            onClick={() => setMenuOpen((o) => !o)}
          >
            {menuOpen ? (
              <span className="home-nav-burger-close" aria-hidden>
                ×
              </span>
            ) : (
              <span className="home-nav-burger-icon" aria-hidden>
                <span />
                <span />
                <span />
              </span>
            )}
          </button>
        </div>
      </header>

      <section id="hero" className="home-hero section-dark">
        <div className="home-hero-inner">
          <div className="home-hero-copy">
            <h1 className="home-hero-h1">
              <span className="block">
                {th("heroL1a")}
                <em>{th("heroL1b")}</em>
                {th("heroL1c")}
              </span>
              <span className="block">{th("heroL2")}</span>
              <span className="block">{th("heroL3")}</span>
            </h1>
            <p className="home-hero-sub">
              {th("heroSubLine1")}
              <br />
              {th("heroSubLine2")}
            </p>
            <div className="home-hero-cta">
              <div className="home-hero-badge-block">
                <AppStoreCtaLink
                  {...APP_STORE_LINK_PROPS}
                  line1={th("appStoreCtaLine1")}
                  line2={th("appStoreCtaLine2")}
                  className="home-hero-app-store"
                  aria-label={`${th("appStoreCtaLine1")} ${th("appStoreCtaLine2")}`}
                />
              </div>
              <a href="#how" className="home-hero-seehow">
                {th("heroSeeHow")}
              </a>
            </div>
          </div>
          <div className="home-hero-visual">
            <div className="home-hero-phone-wrap home-phone-elevated">
              <PhoneFrame
                src={screens.hero}
                alt={th("imgHero")}
                priority
                className="home-hero-phone"
              />
            </div>
          </div>
        </div>
      </section>

      {stats?.show ? (
        <section className="home-stats section-beige">
          <div className="home-stats-grid">
            {stats.users != null ? (
              <div className="home-stat-item">
                <AnimatedCounter value={stats.users} locale={currentLocale} />
                <span className="home-stat-caption">{th("statsUsers")}</span>
              </div>
            ) : null}
            {stats.partners != null ? (
              <div className="home-stat-item">
                <AnimatedCounter value={stats.partners} locale={currentLocale} />
                <span className="home-stat-caption">{th("statsPartners")}</span>
              </div>
            ) : null}
            <div className="home-stat-item">
              <span className="home-stat-value">Rotterdam</span>
              <span className="home-stat-caption">{th("statsHome")}</span>
            </div>
          </div>
        </section>
      ) : null}

      <section id="how" className="home-section section-beige">
        <div className="home-section-inner">
          <p className="home-label reveal">{th("howLabel")}</p>
          <h2 className="home-h2 home-split-h2 home-how-h2 reveal">
            <span className="home-split-h2-line">{th("howTitleLine1")}</span>{" "}
            <span className="home-split-h2-line">{th("howTitleLine2")}</span>
          </h2>
          <div className="home-how-grid">
            {howSteps.map((step, i) => (
              <div key={step.h} className="home-step-card home-step-card--rich reveal">
                <span className="home-step-num-bg" aria-hidden>
                  {i + 1}
                </span>
                <span className="home-step-icon" aria-hidden>
                  {HOW_STEP_ICONS[i]}
                </span>
                <h3 className="home-step-h">{step.h}</h3>
                <p className="home-step-p">{step.p}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="features" className="section-dark home-sticky-features">
        <div className="home-sticky-inner">
          <div className="home-sticky-left">
            {featureSlides.map((slide, i) => (
              <div
                key={slide.label}
                ref={(el) => {
                  featurePanelRefs.current[i] = el;
                }}
                className="home-feature-panel"
                data-index={i}
              >
                <div className="home-feature-copy home-story-intro">
                  <p className="home-label reveal">{slide.label}</p>
                  <h2 className="home-feat-h2 reveal">
                    <span className="home-feat-h2-line">{slide.titleLine1}</span>
                    <span className="home-feat-h2-line">{slide.titleLine2}</span>
                  </h2>
                  <p className="home-feat-body reveal">{slide.body}</p>
                </div>
                <div className="home-sticky-mobile-visual">
                  <div className="home-feature-mobile-phone-wrap home-phone-elevated home-phone-elevated--band">
                    <PhoneFrame variant="band">
                      <FeatureBandPhoneMock index={i} locale={currentLocale} />
                    </PhoneFrame>
                  </div>
                </div>
              </div>
            ))}
          </div>
          <div className="home-sticky-right">
            <div
              className={`home-sticky-phone-slot ${featurePhoneFade ? "is-dim" : ""}`}
            >
              <div className="home-phone-elevated home-phone-elevated--band">
                <PhoneFrame variant="band">
                  <FeatureBandPhoneMock index={featurePhoneIdx} locale={currentLocale} />
                </PhoneFrame>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="mood-match" className="home-section home-mm section-beige">
        <div className="home-section-inner">
          <div className="home-mm-intro home-story-intro">
            <p className="home-label reveal">{th("mmLabel")}</p>
            <h2 className="home-h2 reveal">
              {th("mmH1")}
              <br />
              {th("mmH2")}
            </h2>
            <p className="home-mm-body reveal">{th("mmSub")}</p>
          </div>
          <div className="home-mm-phones-wrap">
            <div className="home-mm-phones">
              <div className="home-mm-phone1 home-phone-elevated">
                <PhoneFrame variant="band">
                  <MoodMatchMockup locale={currentLocale} />
                </PhoneFrame>
              </div>
              <div className="home-mm-phone2 home-phone-elevated">
                <PhoneFrame variant="band" src={screens.placeDetail} alt={th("imgPlace")} />
              </div>
            </div>
          </div>
          <div className="home-mm-cta-wrap">
            <a {...APP_STORE_LINK_PROPS} className="home-mm-cta reveal">
              {th("mmCta")}
            </a>
          </div>
        </div>
      </section>

      <section
        id="moods"
        ref={moodsSectionRef}
        className="home-section section-dark home-moods-section"
      >
        <div className="home-section-inner">
          <div className="home-moods-head">
            <h2 className="home-h2 home-split-h2 reveal">
              <span className="home-split-h2-line">{th("moodsH1")}</span>{" "}
              <span className="home-split-h2-line">{th("moodsH2")}</span>
            </h2>
            <p className="home-moods-intro reveal">{th("moodsIntro")}</p>
          </div>
          <div className="home-moods-grid">
            {MOOD_GRID.map(({ key, emoji }) => (
              <div key={key} className="home-mood-chip">
                <span className="home-mood-emoji" aria-hidden>
                  {emoji}
                </span>
                <span className="home-mood-label">{tMoods(key)}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="business" className="home-section home-b2b section-beige">
        <div className="home-section-inner">
          <p className="home-label reveal">{th("b2bLabel")}</p>
          <h2 className="home-h2 home-split-h2 reveal">
            <span className="home-split-h2-line">{th("b2bH1")}</span>{" "}
            <span className="home-split-h2-line">{th("b2bH2")}</span>
          </h2>
          <p className="home-b2b-sub reveal">{th("b2bSub")}</p>

          <div className="home-b2b-card reveal">
            <span className="home-b2b-pill">{th("b2bPill")}</span>
            <div className="home-b2b-price">{tLanding("b2b.price")}</div>
            <div className="home-b2b-per">{th("b2bPer")}</div>
            <ul className="home-b2b-list">
              <li>
                <span className="home-b2b-check" aria-hidden>
                  ✓
                </span>
                {th("b2bBul1")}
              </li>
              <li>
                <span className="home-b2b-check" aria-hidden>
                  ✓
                </span>
                {th("b2bBul2")}
              </li>
              <li>
                <span className="home-b2b-check" aria-hidden>
                  ✓
                </span>
                {th("b2bBul3")}
              </li>
            </ul>
            <Link href="/partners#aanvragen" className="home-b2b-btn">
              {th("b2bCta")}
            </Link>
            <p className="home-b2b-small">{th("b2bNote")}</p>
          </div>
        </div>
      </section>

      <section id="download" className="home-download section-dark">
        <div className="home-download-copy reveal">
          <p className="home-download-sub">
            {th("dlSubL1")}
            <br />
            {th("dlSubL2")}
          </p>
          <h2 className="home-download-h2">{th("dlH")}</h2>
        </div>
        <div className="home-download-badge-wrap reveal">
          <AppStoreCtaLink
            {...APP_STORE_LINK_PROPS}
            line1={th("appStoreCtaLine1")}
            line2={th("appStoreCtaLine2")}
            className="home-download-badge"
            aria-label={`${th("appStoreCtaLine1")} ${th("appStoreCtaLine2")}`}
          />
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
        </ul>
        <div className="footer-copy">
          © {new Date().getFullYear()} {tFooter("brand")}
        </div>
      </footer>
      </div>
      {menuPortalReady
        ? createPortal(
            <div className="landing-page--home landing-home-menu-portal">
              <div
                className={`home-sheet-backdrop ${menuOpen ? "open" : ""}`}
                aria-hidden
                onClick={() => setMenuOpen(false)}
              />
              <aside
                className={`home-sheet ${menuOpen ? "open" : ""}`}
                role="dialog"
                aria-modal="true"
                aria-hidden={!menuOpen}
                aria-labelledby="home-sheet-title"
              >
                <div className="home-sheet-header">
                  <span id="home-sheet-title" className="home-sheet-title">
                    {tFooter("brand")}
                  </span>
                  <button
                    type="button"
                    className="home-sheet-close"
                    aria-label={th("navMenuClose")}
                    onClick={() => setMenuOpen(false)}
                  >
                    ×
                  </button>
                </div>
                <div className="home-sheet-main">
                  <nav className="home-sheet-nav">
                    <a
                      href="#how"
                      className="home-sheet-nav-link"
                      onClick={() => setMenuOpen(false)}
                    >
                      {th("navHow")}
                    </a>
                    <a
                      href="#features"
                      className="home-sheet-nav-link"
                      onClick={() => setMenuOpen(false)}
                    >
                      {th("navFeatures")}
                    </a>
                    <Link
                      href="/partners"
                      className="home-sheet-nav-link"
                      onClick={() => setMenuOpen(false)}
                    >
                      {th("navPartners")}
                    </Link>
                  </nav>
                  <div className="home-sheet-footer">
                    <div
                      className="home-sheet-locales"
                      role="group"
                      aria-label="Language"
                    >
                      {LOCALES.map(({ code, label }) => (
                        <button
                          key={code}
                          type="button"
                          className={`home-nav-locale-btn home-sheet-locale-btn ${currentLocale === code ? "active" : ""}`}
                          onClick={() => {
                            router.replace(pathname, { locale: code });
                            setMenuOpen(false);
                          }}
                          aria-pressed={currentLocale === code}
                          aria-label={label}
                        >
                          {label}
                        </button>
                      ))}
                    </div>
                    <AppStoreCtaLink
                      {...APP_STORE_LINK_PROPS}
                      line1={th("appStoreCtaLine1")}
                      line2={th("appStoreCtaLine2")}
                      className="home-sheet-app-store"
                      onClick={() => setMenuOpen(false)}
                      aria-label={`${th("appStoreCtaLine1")} ${th("appStoreCtaLine2")}`}
                    />
                  </div>
                </div>
              </aside>
            </div>,
            document.body,
          )
        : null}
    </>
  );
}
