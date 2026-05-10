"use client";

import { useMemo, useRef, useState } from "react";
import { useLocale, useTranslations } from "next-intl";
import { Link, usePathname, useRouter } from "@/i18n/navigation";

const LOCALES = [
  { code: "en", label: "EN" },
  { code: "nl", label: "NL" },
  { code: "de", label: "DE" },
  { code: "es", label: "ES" },
  { code: "fr", label: "FR" },
] as const;

const BUSINESS_TYPES = [
  { value: "Restaurant / Café", msgKey: "restaurant" },
  { value: "Museum / Experience", msgKey: "museum" },
  { value: "Boutique hotel", msgKey: "hotel" },
  { value: "Tour / Workshop / Event", msgKey: "tour" },
  { value: "Bar / Nightlife", msgKey: "bar" },
  { value: "Park / Outdoor", msgKey: "park" },
  { value: "Destination / DMO", msgKey: "dmo" },
  { value: "Other", msgKey: "other" },
] as const;

const MOOD_KEYS = [
  { key: "happy", emoji: "😊" },
  { key: "adventurous", emoji: "🚀" },
  { key: "relaxed", emoji: "😌" },
  { key: "energetic", emoji: "⚡" },
  { key: "romantic", emoji: "💕" },
  { key: "social", emoji: "👫" },
  { key: "cultural", emoji: "🎭" },
  { key: "curious", emoji: "🔍" },
  { key: "cozy", emoji: "☕" },
  { key: "excited", emoji: "🤩" },
  { key: "foodie", emoji: "🍽️" },
  { key: "surprise", emoji: "😲" },
] as const;

type MoodKey = (typeof MOOD_KEYS)[number]["key"];

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function PartnersClient() {
  const t = useTranslations("partners");
  const tFooter = useTranslations("footer");
  const tLegal = useTranslations("legal.common");
  const tLanding = useTranslations("landing");
  const router = useRouter();
  const pathname = usePathname();
  const currentLocale = useLocale();
  const honeypotRef = useRef<HTMLInputElement>(null);

  const [businessName, setBusinessName] = useState("");
  const [businessType, setBusinessType] = useState("");
  const [city, setCity] = useState("");
  const [googlePlaceUrl, setGooglePlaceUrl] = useState("");
  const [website, setWebsite] = useState("");
  const [contactName, setContactName] = useState("");
  const [contactEmail, setContactEmail] = useState("");
  const [whatTheyOffer, setWhatTheyOffer] = useState("");
  const [selectedMoods, setSelectedMoods] = useState<MoodKey[]>([]);
  const [gdprConsent, setGdprConsent] = useState(false);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [successEmail, setSuccessEmail] = useState<string | null>(null);
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

  function toggleMood(key: MoodKey) {
    setSelectedMoods((prev) =>
      prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key],
    );
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitError(null);
    const hp = honeypotRef.current?.value?.trim();
    if (hp) {
      setSuccessEmail(contactEmail.trim());
      return;
    }

    const err: Record<string, string> = {};
    if (!businessName.trim()) err.business_name = t("form.errorRequired");
    if (!businessType) err.business_type = t("form.errorRequired");
    if (!city.trim()) err.city = t("form.errorRequired");
    if (!contactName.trim()) err.contact_name = t("form.errorRequired");
    const em = contactEmail.trim();
    if (!em) err.contact_email = t("form.errorRequired");
    else if (!EMAIL_RE.test(em)) err.contact_email = t("form.errorEmail");
    if (!whatTheyOffer.trim()) err.what_they_offer = t("form.errorRequired");
    if (!gdprConsent) err.gdpr = t("form.errorGdpr");

    setFieldErrors(err);
    if (Object.keys(err).length > 0) return;

    setLoading(true);
    try {
      const res = await fetch("/api/partners/apply", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          business_name: businessName.trim(),
          business_type: businessType,
          city: city.trim(),
          country: "NL",
          website: website.trim() || null,
          google_place_url: googlePlaceUrl.trim() || null,
          contact_name: contactName.trim(),
          contact_email: em,
          what_they_offer: whatTheyOffer.trim().slice(0, 300),
          target_moods: selectedMoods,
          gdpr_consent: true,
          website_url: "",
        }),
      });
      const data = (await res.json().catch(() => ({}))) as { error?: string };
      if (!res.ok) {
        setSubmitError(t("form.errorGeneric"));
        return;
      }
      if (data.error) {
        setSubmitError(t("form.errorGeneric"));
        return;
      }
      setSuccessEmail(em);
    } catch {
      setSubmitError(t("form.errorGeneric"));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="landing-root">
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
          <a href="#aanvragen" className="nav-cta">
            {t("hero.ctaPrimary")}
          </a>
        </div>
      </nav>

      <section className="partners-hero">
        <p className="section-eyebrow">{t("hero.eyebrow")}</p>
        <h1>{t("hero.title")}</h1>
        <p className="hero-sub" style={{ marginBottom: 32 }}>
          {t("hero.sub")}
        </p>
        <div className="hero-actions">
          <a href="#aanvragen" className="btn-primary">
            {t("hero.ctaPrimary")}
          </a>
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
            <a href="#aanvragen" className="partners-btn-cream">
              {t("what.pricingCta")}
            </a>
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

        {successEmail ? (
          <div className="partners-form-card" role="status">
            <p style={{ fontSize: 18, fontWeight: 600, marginBottom: 12, color: "var(--forest)" }}>
              {t("form.successTitle")}
            </p>
            <p style={{ fontSize: 15, color: "var(--dusk)", lineHeight: 1.6 }}>
              {t("form.successBody", { email: successEmail })}
            </p>
          </div>
        ) : (
          <form className="partners-form-card" onSubmit={handleSubmit} noValidate>
            <input
              ref={honeypotRef}
              type="text"
              name="website_url"
              tabIndex={-1}
              autoComplete="off"
              aria-hidden
              style={{
                position: "absolute",
                left: -9999,
                width: 1,
                height: 1,
                opacity: 0,
              }}
            />

            <div className="partners-field">
              <label htmlFor="business_name">{t("form.businessName")}</label>
              <input
                id="business_name"
                className="partners-input"
                value={businessName}
                onChange={(e) => setBusinessName(e.target.value)}
                placeholder={t("form.businessNamePh")}
                autoComplete="organization"
                aria-invalid={Boolean(fieldErrors.business_name)}
                aria-describedby={fieldErrors.business_name ? "err-business_name" : undefined}
              />
              {fieldErrors.business_name ? (
                <p id="err-business_name" className="err" role="alert">
                  {fieldErrors.business_name}
                </p>
              ) : null}
            </div>

            <div className="partners-field">
              <label htmlFor="business_type">{t("form.businessType")}</label>
              <select
                id="business_type"
                className="partners-select"
                value={businessType}
                onChange={(e) => setBusinessType(e.target.value)}
                aria-invalid={Boolean(fieldErrors.business_type)}
              >
                <option value="">—</option>
                {BUSINESS_TYPES.map((opt) => (
                  <option key={opt.msgKey} value={opt.value}>
                    {t(`form.businessTypes.${opt.msgKey}` as "form.businessTypes.restaurant")}
                  </option>
                ))}
              </select>
              {fieldErrors.business_type ? (
                <p className="err" role="alert">
                  {fieldErrors.business_type}
                </p>
              ) : null}
            </div>

            <div className="partners-field">
              <label htmlFor="city">{t("form.city")}</label>
              <input
                id="city"
                className="partners-input"
                value={city}
                onChange={(e) => setCity(e.target.value)}
                placeholder={t("form.cityPh")}
                autoComplete="address-level2"
                aria-invalid={Boolean(fieldErrors.city)}
              />
              {fieldErrors.city ? (
                <p className="err" role="alert">
                  {fieldErrors.city}
                </p>
              ) : null}
            </div>

            <div className="partners-field">
              <label htmlFor="google_place_url">{t("form.googleMaps")}</label>
              <input
                id="google_place_url"
                className="partners-input"
                value={googlePlaceUrl}
                onChange={(e) => setGooglePlaceUrl(e.target.value)}
                placeholder={t("form.googleMapsPh")}
                inputMode="url"
                autoComplete="off"
              />
              <p className="help">{t("form.googleMapsHelp")}</p>
            </div>

            <div className="partners-field">
              <label htmlFor="website">{t("form.website")}</label>
              <input
                id="website"
                className="partners-input"
                value={website}
                onChange={(e) => setWebsite(e.target.value)}
                placeholder={t("form.websitePh")}
                inputMode="url"
                autoComplete="url"
              />
            </div>

            <div className="partners-field">
              <label htmlFor="contact_name">{t("form.contactName")}</label>
              <input
                id="contact_name"
                className="partners-input"
                value={contactName}
                onChange={(e) => setContactName(e.target.value)}
                placeholder={t("form.contactNamePh")}
                autoComplete="name"
                aria-invalid={Boolean(fieldErrors.contact_name)}
              />
              {fieldErrors.contact_name ? (
                <p className="err" role="alert">
                  {fieldErrors.contact_name}
                </p>
              ) : null}
            </div>

            <div className="partners-field">
              <label htmlFor="contact_email">{t("form.email")}</label>
              <input
                id="contact_email"
                type="email"
                className="partners-input"
                value={contactEmail}
                onChange={(e) => setContactEmail(e.target.value)}
                placeholder={t("form.emailPh")}
                autoComplete="email"
                aria-invalid={Boolean(fieldErrors.contact_email)}
              />
              {fieldErrors.contact_email ? (
                <p className="err" role="alert">
                  {fieldErrors.contact_email}
                </p>
              ) : null}
            </div>

            <div className="partners-field">
              <label htmlFor="what_they_offer">{t("form.offer")}</label>
              <textarea
                id="what_they_offer"
                className="partners-textarea"
                value={whatTheyOffer}
                maxLength={300}
                onChange={(e) => setWhatTheyOffer(e.target.value)}
                placeholder={t("form.offerPh")}
                aria-invalid={Boolean(fieldErrors.what_they_offer)}
              />
              <p className="help">{t("form.chars", { count: whatTheyOffer.length })}</p>
              {fieldErrors.what_they_offer ? (
                <p className="err" role="alert">
                  {fieldErrors.what_they_offer}
                </p>
              ) : null}
            </div>

            <div className="partners-field">
              <span id="moods-label">{t("form.moodsLabel")}</span>
              <p className="help" id="moods-help">
                {t("form.moodsHelp")}
              </p>
              <div
                className="partners-mood-row"
                role="group"
                aria-labelledby="moods-label"
                aria-describedby="moods-help"
                style={{ marginTop: 10 }}
              >
                {MOOD_KEYS.map(({ key, emoji }) => (
                  <button
                    key={key}
                    type="button"
                    className={`partners-mood-chip ${selectedMoods.includes(key) ? "selected" : ""}`}
                    onClick={() => toggleMood(key)}
                    aria-pressed={selectedMoods.includes(key)}
                  >
                    {emoji} {tLanding(`moods.${key}` as "moods.happy")}
                  </button>
                ))}
              </div>
            </div>

            <div className="partners-field">
              <label
                style={{ display: "flex", gap: 10, alignItems: "flex-start", cursor: "pointer" }}
              >
                <input
                  type="checkbox"
                  checked={gdprConsent}
                  onChange={(e) => setGdprConsent(e.target.checked)}
                  style={{ marginTop: 4 }}
                  aria-invalid={Boolean(fieldErrors.gdpr)}
                />
                <span style={{ fontSize: 14, color: "var(--dusk)", lineHeight: 1.5 }}>
                  {t("form.gdprBefore")}
                  <Link href="/privacy" style={{ color: "var(--forest)", textDecoration: "underline" }}>
                    {t("form.gdprLink")}
                  </Link>
                </span>
              </label>
              {fieldErrors.gdpr ? (
                <p className="err" role="alert">
                  {fieldErrors.gdpr}
                </p>
              ) : null}
            </div>

            {submitError ? (
              <p className="err" role="alert" style={{ marginBottom: 16 }}>
                {submitError}
              </p>
            ) : null}

            <button type="submit" className="btn-trial" disabled={loading}>
              {loading ? t("form.submitting") : t("form.submit")}
            </button>
          </form>
        )}
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
        <a href="#aanvragen" className="btn-primary" style={{ justifyContent: "center" }}>
          {t("final.cta")}
        </a>
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
