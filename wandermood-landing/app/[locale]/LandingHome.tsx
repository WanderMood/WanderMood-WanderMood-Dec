"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Image from "next/image";
import { useLocale, useTranslations } from "next-intl";
import { Link, usePathname, useRouter } from "@/i18n/navigation";
import { PhoneFrame } from "@/components/PhoneFrame";
import { getHomepageScreens } from "@/lib/homepage-screens";

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
      { threshold: 0.15 },
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
  const [navScrolled, setNavScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [stats, setStats] = useState<PublicStats | null>(null);

  const screens = useMemo(() => getHomepageScreens(currentLocale), [currentLocale]);

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

  useEffect(() => {
    if (!menuOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setMenuOpen(false);
    };
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
    };
  }, [menuOpen]);

  const howSteps = [
    { h: th("how1h"), p: th("how1p") },
    { h: th("how2h"), p: th("how2p") },
    { h: th("how3h"), p: th("how3p") },
    { h: th("how4h"), p: th("how4p") },
  ] as const;

  return (
    <div ref={rootRef} className="landing-root landing-page--home">
      <header
        className={`home-nav ${navScrolled ? "home-nav--scrolled" : ""}`}
        id="landing-nav"
      >
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

      <div
        className={`home-sheet-backdrop ${menuOpen ? "open" : ""}`}
        aria-hidden
        onClick={() => setMenuOpen(false)}
      />
      <aside className={`home-sheet ${menuOpen ? "open" : ""}`} aria-hidden={!menuOpen}>
        <nav>
          <a href="#how" onClick={() => setMenuOpen(false)}>
            {th("navHow")}
          </a>
          <a href="#features" onClick={() => setMenuOpen(false)}>
            {th("navFeatures")}
          </a>
          <Link href="/partners" onClick={() => setMenuOpen(false)}>
            {th("navPartners")}
          </Link>
          <a {...APP_STORE_LINK_PROPS} className="home-nav-download" onClick={() => setMenuOpen(false)}>
            {th("navDownload")}
          </a>
        </nav>
      </aside>

      <section id="hero" className="home-hero section-dark">
        <div className="home-hero-inner">
          <div>
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
                <a {...APP_STORE_LINK_PROPS} className="home-app-badge">
                  <Image
                    src="/app-store-badge-white.svg"
                    alt="Download on the App Store"
                    width={157}
                    height={44}
                    priority
                  />
                </a>
                <p className="home-badge-sub">{th("dlFoot")}</p>
              </div>
              <a href="#how" className="home-hero-seehow">
                {th("heroSeeHow")}
              </a>
            </div>
          </div>
          <div className="home-hero-visual">
            <PhoneFrame
              src={screens.hero}
              alt={th("imgHero")}
              priority
              className="home-hero-phone"
            />
          </div>
        </div>
      </section>

      <div className="home-strip">
        <div className="home-strip-inner">
          <span>
            {th("stripAppStore")} {th("stripStars")}
          </span>
          <span className="home-strip-div" aria-hidden />
          <span>{th("stripGeo")}</span>
          <span className="home-strip-div" aria-hidden />
          <span>{th("stripTagline")}</span>
        </div>
      </div>

      {stats?.show ? (
        <section className="home-stats">
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
          <h2 className="home-h2 reveal">
            {th("howTitleLine1")}
            <br />
            {th("howTitleLine2")}
          </h2>
          <div className="home-how-grid">
            {howSteps.map((step, i) => (
              <div key={step.h} className="home-step-card reveal">
                <div className="home-step-num">{i + 1}</div>
                <h3 className="home-step-h">
                  {step.h.replace(/^\d+\s*·\s*/, "").trim()}
                </h3>
                <p className="home-step-p">{step.p}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="features" className="section-beige">
        <div className="home-band">
          <div className="home-band-inner">
            <div className="home-band-visual reveal">
              <PhoneFrame variant="band" src={screens.moodyChat} alt={th("imgChat")} />
            </div>
            <div className="home-band-copy">
              <p className="home-label reveal">{th("featMoodyLabel")}</p>
              <h2 className="home-feat-h2 reveal">{th("featMoodyH")}</h2>
              <p className="home-feat-body reveal">{th("featMoodyB")}</p>
            </div>
          </div>
        </div>

        <div className="home-band home-band--reverse">
          <div className="home-band-inner">
            <div className="home-band-visual reveal">
              <PhoneFrame variant="band" src={screens.myDay} alt={th("imgMyDay")} />
            </div>
            <div className="home-band-copy">
              <p className="home-label reveal">{th("featDayLabel")}</p>
              <h2 className="home-feat-h2 reveal">{th("featDayH")}</h2>
              <p className="home-feat-body reveal">{th("featDayB")}</p>
            </div>
          </div>
        </div>

        <div className="home-band">
          <div className="home-band-inner">
            <div className="home-band-visual reveal">
              <PhoneFrame variant="band" src={screens.explore} alt={th("imgExplore")} />
            </div>
            <div className="home-band-copy">
              <p className="home-label reveal">{th("featExploreLabel")}</p>
              <h2 className="home-feat-h2 reveal">{th("featExploreH")}</h2>
              <p className="home-feat-body reveal">{th("featExploreB")}</p>
            </div>
          </div>
        </div>
      </section>

      <section id="mood-match" className="home-section home-mm section-dark">
        <div className="home-section-inner">
          <p className="home-label reveal" style={{ textAlign: "center" }}>
            {th("mmLabel")}
          </p>
          <h2 className="home-h2 reveal" style={{ textAlign: "center" }}>
            {th("mmH1")}
            <br />
            {th("mmH2")}
          </h2>
          <p
            className="home-b2b-sub reveal"
            style={{ marginTop: 20, maxWidth: 480 }}
          >
            {th("mmSubL1")}
            <br />
            {th("mmSubL2")}
            <br />
            {th("mmSubL3")}
          </p>
          <div className="home-mm-phones">
            <PhoneFrame
              src={screens.moodMatchLeft}
              alt={th("imgMoodMatch")}
              className="home-mm-phone1"
            />
            <PhoneFrame
              src={screens.placeDetail}
              alt={th("imgPlace")}
              className="home-mm-phone2"
            />
          </div>
          <div className="home-mm-cta-wrap">
            <a {...APP_STORE_LINK_PROPS} className="home-mm-cta reveal">
              {th("mmCta")}
            </a>
          </div>
        </div>
      </section>

      <section id="moods" className="home-section section-beige">
        <div className="home-section-inner">
          <div className="home-moods-head">
            <h2 className="home-h2 reveal">
              {th("moodsH1")}
              <br />
              {th("moodsH2")}
            </h2>
          </div>
          <div className="home-moods-grid">
            {MOOD_GRID.map(({ key, emoji }) => (
              <div key={key} className="home-mood-chip reveal">
                {emoji} {tMoods(key)}
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="business" className="home-section home-b2b section-b2b">
        <div className="home-section-inner">
          <p className="home-label reveal">{th("b2bLabel")}</p>
          <h2 className="home-h2 reveal">
            {th("b2bH1")}
            <br />
            {th("b2bH2")}
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
        <h2 className="home-download-h2 reveal">{th("dlH")}</h2>
        <p className="home-download-sub reveal">
          {th("dlSubL1")}
          <br />
          {th("dlSubL2")}
        </p>
        <div className="home-download-badge-wrap reveal">
          <a {...APP_STORE_LINK_PROPS} className="home-download-badge">
            <Image
              src="/app-store-badge-white.svg"
              alt="Download on the App Store"
              width={157}
              height={44}
            />
          </a>
          <p className="home-download-note">{th("dlFoot")}</p>
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
