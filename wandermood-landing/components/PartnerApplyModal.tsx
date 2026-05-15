"use client";

import { useTranslations, useLocale } from "next-intl";
import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import styles from "./partner-apply-modal.module.css";

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

const PRICE_SYMBOLS = ["€", "€€", "€€€", "€€€€"] as const;

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const DAY_IDS = ["ma", "di", "wo", "do", "vr", "za", "zo"] as const;
type DayId = (typeof DAY_IDS)[number];

const INCLUSION_KEYS = [
  { key: "specialty_coffee", emoji: "☕" },
  { key: "vegan", emoji: "🥗" },
  { key: "halal", emoji: "🥩" },
  { key: "vegetarian", emoji: "🌱" },
  { key: "family_friendly", emoji: "👨‍👩‍👧" },
  { key: "kids_friendly", emoji: "👶" },
  { key: "wheelchair_accessible", emoji: "♿" },
  { key: "dog_friendly", emoji: "🐕" },
  { key: "terrace_outdoor", emoji: "🌿" },
  { key: "live_music", emoji: "🎵" },
] as const;

type InclusionKey = (typeof INCLUSION_KEYS)[number]["key"];

function buildHalfHourTimes(): string[] {
  const out: string[] = [];
  for (let h = 0; h < 24; h += 1) {
    out.push(`${String(h).padStart(2, "0")}:00`);
    out.push(`${String(h).padStart(2, "0")}:30`);
  }
  return out;
}

const OPEN_TIME_OPTIONS = buildHalfHourTimes();

type OpeningDayRow = {
  id: DayId;
  open: boolean;
  openTime: string;
  closeTime: string;
};

type Props = {
  open: boolean;
  onClose: () => void;
};

type FormState = ReturnType<typeof initialForm>;

function initialOpeningDays(): OpeningDayRow[] {
  return DAY_IDS.map((id) => ({
    id,
    open: false,
    openTime: "09:00",
    closeTime: "17:00",
  }));
}

function initialForm() {
  return {
    business_name: "",
    business_type: "",
    street_address: "",
    city: "",
    google_place_url: "",
    price_range: "",
    opening_days: initialOpeningDays(),
    website: "",
    instagram_handle: "",
    contact_name: "",
    contact_email: "",
    contact_phone: "",
    kvk_number: "",
    billing_name: "",
    billing_address: "",
    vat_number: "",
    inclusion_tags: [] as InclusionKey[],
    target_moods: [] as MoodKey[],
    gdpr_consent: false,
    pricing_consent: false,
  };
}

function serializeOpeningHours(
  rows: OpeningDayRow[],
  dayLabels: Record<DayId, string>,
  midnightLabel: string,
): string | null {
  const parts: string[] = [];
  for (const r of rows) {
    if (!r.open) continue;
    const close = r.closeTime === "24:00" ? midnightLabel : r.closeTime;
    parts.push(`${dayLabels[r.id]} ${r.openTime}\u2013${close}`);
  }
  return parts.length > 0 ? parts.join(", ") : null;
}

export function PartnerApplyModal({ open, onClose }: Props) {
  const t = useTranslations("partners.modal");
  const tInclusionTags = useTranslations("partners.modal.inclusion.tags");
  const tForm = useTranslations("partners.form");
  const tMoods = useTranslations("landing.moods");
  const locale = useLocale();
  const honeypotRef = useRef<HTMLInputElement>(null);

  const [step, setStep] = useState(1);
  const [form, setForm] = useState(initialForm);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [priceTipOpen, setPriceTipOpen] = useState(false);

  const dayLabels = useMemo(
    () =>
      ({
        ma: t("openingDays.ma"),
        di: t("openingDays.di"),
        wo: t("openingDays.wo"),
        do: t("openingDays.do"),
        vr: t("openingDays.vr"),
        za: t("openingDays.za"),
        zo: t("openingDays.zo"),
      }) as Record<DayId, string>,
    [t],
  );

  const midnightLabel = t("midnightOption");

  const businessTypeOptions = useMemo(() => {
    try {
      const raw = t.raw("businessTypeOptions");
      if (Array.isArray(raw) && raw.every((x) => typeof x === "string")) {
        return raw as string[];
      }
    } catch {
      /* fall through */
    }
    return [];
  }, [t]);

  const trialEndLabel = useMemo(() => {
    const d = new Date();
    d.setDate(d.getDate() + 30);
    const loc = locale === "nl" ? "nl-NL" : "en-GB";
    return new Intl.DateTimeFormat(loc, {
      day: "numeric",
      month: "long",
      year: "numeric",
    }).format(d);
  }, [locale]);

  const reset = useCallback(() => {
    setStep(1);
    setForm(initialForm());
    setFieldErrors({});
    setSubmitError(null);
    setLoading(false);
    setPriceTipOpen(false);
  }, []);

  useEffect(() => {
    if (!open) {
      reset();
      return;
    }
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prev;
    };
  }, [open, onClose, reset]);

  const setField = useCallback(<K extends keyof FormState>(key: K, value: FormState[K]) => {
    setForm((f) => ({ ...f, [key]: value }));
    setFieldErrors((e) => {
      const next = { ...e };
      delete next[key as string];
      return next;
    });
  }, []);

  const patchOpeningDay = useCallback((id: DayId, patch: Partial<Omit<OpeningDayRow, "id">>) => {
    setForm((f) => ({
      ...f,
      opening_days: f.opening_days.map((row) =>
        row.id === id ? { ...row, ...patch } : row,
      ),
    }));
  }, []);

  const validateStep1b = (): boolean => {
    const err: Record<string, string> = {};
    if (!form.business_name.trim()) err.business_name = tForm("errorRequired");
    if (!form.business_type.trim()) err.business_type = tForm("errorRequired");
    if (!form.street_address.trim()) err.street_address = tForm("errorRequired");
    if (!form.city.trim()) err.city = tForm("errorRequired");
    if (!form.google_place_url.trim()) err.google_place_url = tForm("errorRequired");
    else {
      try {
        const u = form.google_place_url.trim();
        new URL(u.startsWith("http") ? u : `https://${u}`);
      } catch {
        err.google_place_url = tForm("errorEmail");
      }
    }
    if (!form.price_range) err.price_range = tForm("errorRequired");
    setFieldErrors((e) => {
      const next = { ...e };
      Object.keys(err).forEach((k) => delete next[k]);
      return { ...next, ...err };
    });
    return Object.keys(err).length === 0;
  };

  const validateStep2 = (): boolean => {
    const err: Record<string, string> = {};
    if (!form.contact_name.trim()) err.contact_name = tForm("errorRequired");
    const em = form.contact_email.trim();
    if (!em) err.contact_email = tForm("errorRequired");
    else if (!EMAIL_RE.test(em)) err.contact_email = tForm("errorEmail");
    if (!form.contact_phone.trim()) err.contact_phone = tForm("errorRequired");
    const kvk = form.kvk_number.replace(/\s/g, "");
    if (kvk && !/^\d{8}$/.test(kvk)) err.kvk_number = t("errorKvK");
    if (!form.vat_number.trim()) err.vat_number = tForm("errorRequired");
    setFieldErrors((e) => {
      const next = { ...e };
      Object.keys(err).forEach((k) => delete next[k]);
      return { ...next, ...err };
    });
    return Object.keys(err).length === 0;
  };

  const validateStep3 = (): boolean => {
    const err: Record<string, string> = {};
    if (form.target_moods.length < 1) err.target_moods = t("errorMoods");
    if (!form.gdpr_consent) err.gdpr_consent = tForm("errorGdpr");
    if (!form.pricing_consent) err.pricing_consent = tForm("errorRequired");
    setFieldErrors((e) => {
      const next = { ...e };
      Object.keys(err).forEach((k) => delete next[k]);
      return { ...next, ...err };
    });
    return Object.keys(err).length === 0;
  };

  const goNext = () => {
    setSubmitError(null);
    if (step === 1 && !validateStep1b()) return;
    if (step === 2 && !validateStep2()) return;
    if (step < 3) setStep((s) => s + 1);
  };

  const goBack = () => {
    setSubmitError(null);
    if (step > 1) setStep((s) => s - 1);
  };

  const handleSubmit = async () => {
    setSubmitError(null);
    if (!validateStep3()) return;
    const hp = honeypotRef.current?.value?.trim();
    if (hp) {
      onClose();
      return;
    }

    const opening_hours = serializeOpeningHours(form.opening_days, dayLabels, midnightLabel);

    setLoading(true);
    try {
      const res = await fetch("/api/partners/apply", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          business_name: form.business_name,
          business_type: form.business_type,
          street_address: form.street_address,
          city: form.city,
          google_place_url: form.google_place_url,
          price_range: form.price_range,
          opening_hours,
          website: form.website,
          instagram_handle: form.instagram_handle.replace(/^@+/, ""),
          contact_name: form.contact_name,
          contact_email: form.contact_email,
          contact_phone: form.contact_phone,
          kvk_number: form.kvk_number.replace(/\s/g, ""),
          billing_name: form.billing_name,
          billing_address: form.billing_address,
          vat_number: form.vat_number,
          inclusion_tags: form.inclusion_tags,
          target_moods: form.target_moods,
          gdpr_consent: true,
          pricing_consent: true,
          locale,
          website_url: "",
        }),
      });
      const data = (await res.json().catch(() => ({}))) as {
        error?: string;
        success?: boolean;
        checkoutUrl?: string;
      };
      if (!res.ok) {
        setSubmitError(
          typeof data.error === "string" ? data.error : tForm("errorGeneric"),
        );
        return;
      }
      if (data.checkoutUrl) {
        window.location.href = data.checkoutUrl;
        return;
      }
      if (data.success) {
        onClose();
        return;
      }
      setSubmitError(tForm("errorGeneric"));
    } catch {
      setSubmitError(tForm("errorGeneric"));
    } finally {
      setLoading(false);
    }
  };

  const toggleMood = (key: MoodKey) => {
    setForm((f) => ({
      ...f,
      target_moods: f.target_moods.includes(key)
        ? f.target_moods.filter((k) => k !== key)
        : [...f.target_moods, key],
    }));
    setFieldErrors((e) => {
      const n = { ...e };
      delete n.target_moods;
      return n;
    });
  };

  const toggleInclusion = (key: InclusionKey) => {
    setForm((f) => ({
      ...f,
      inclusion_tags: f.inclusion_tags.includes(key)
        ? f.inclusion_tags.filter((k) => k !== key)
        : [...f.inclusion_tags, key],
    }));
  };

  if (!open) return null;

  const labels = [t("step1"), t("step2"), t("step3")];

  const backdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) onClose();
  };

  const req = (children: ReactNode) => (
    <>
      {children} <span className={styles.req}>*</span>
    </>
  );

  const privacyHref = `/${locale}/privacy`;

  return (
    <div
      className={styles.backdrop}
      role="presentation"
      onMouseDown={backdropClick}
    >
      <div
        className={styles.card}
        role="dialog"
        aria-modal="true"
        aria-labelledby="partner-modal-title"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <button
          type="button"
          className={styles.close}
          aria-label="Close"
          onClick={onClose}
        >
          ×
        </button>

        <p id="partner-modal-title" className={styles.stepMobile}>
          {t("stepOf", { current: step, total: 3 })}
        </p>

        <div className={styles.progress}>
          <div className={styles.progressStep}>
            <div
              className={`${styles.progressDot} ${step === 1 ? styles.progressDotActive : ""} ${step > 1 ? styles.progressDotDone : ""}`}
            >
              {step > 1 ? "✓" : 1}
            </div>
            <div
              className={`${styles.progressLabel} ${step === 1 ? styles.progressLabelActive : ""}`}
            >
              {labels[0]}
            </div>
          </div>
          <div className={`${styles.progressLine} ${step > 1 ? styles.progressLineDone : ""}`} />
          <div className={styles.progressStep}>
            <div
              className={`${styles.progressDot} ${step === 2 ? styles.progressDotActive : ""} ${step > 2 ? styles.progressDotDone : ""}`}
            >
              {step > 2 ? "✓" : 2}
            </div>
            <div
              className={`${styles.progressLabel} ${step === 2 ? styles.progressLabelActive : ""}`}
            >
              {labels[1]}
            </div>
          </div>
          <div className={`${styles.progressLine} ${step > 2 ? styles.progressLineDone : ""}`} />
          <div className={styles.progressStep}>
            <div
              className={`${styles.progressDot} ${step === 3 ? styles.progressDotActive : ""} ${step > 3 ? styles.progressDotDone : ""}`}
            >
              {step > 3 ? "✓" : 3}
            </div>
            <div
              className={`${styles.progressLabel} ${step === 3 ? styles.progressLabelActive : ""}`}
            >
              {labels[2]}
            </div>
          </div>
        </div>

        <input
          ref={honeypotRef}
          type="text"
          name="website_url"
          tabIndex={-1}
          autoComplete="off"
          className={styles.honeypot}
          aria-hidden
        />

        {step === 1 ? (
          <>
            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-business_name">
                {req(t("venue.businessName"))}
              </label>
              <input
                id="pm-business_name"
                className={styles.input}
                value={form.business_name}
                onChange={(e) => setField("business_name", e.target.value)}
                placeholder={t("venue.businessNamePh")}
                autoComplete="organization"
              />
              {fieldErrors.business_name ? (
                <p className={styles.err}>{fieldErrors.business_name}</p>
              ) : null}
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-business_type">
                {req(t("venue.businessType"))}
              </label>
              <select
                id="pm-business_type"
                className={styles.select}
                value={form.business_type}
                onChange={(e) => setField("business_type", e.target.value)}
              >
                <option value="">{t("businessTypePlaceholder")}</option>
                {businessTypeOptions.map((opt) => (
                  <option key={opt} value={opt}>
                    {opt}
                  </option>
                ))}
              </select>
              {fieldErrors.business_type ? (
                <p className={styles.err}>{fieldErrors.business_type}</p>
              ) : null}
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-street">
                {req(t("venue.street"))}
              </label>
              <input
                id="pm-street"
                className={styles.input}
                value={form.street_address}
                onChange={(e) => setField("street_address", e.target.value)}
                placeholder={t("venue.streetPh")}
                autoComplete="street-address"
              />
              <p className={styles.help}>{t("venue.streetHelp")}</p>
              {fieldErrors.street_address ? (
                <p className={styles.err}>{fieldErrors.street_address}</p>
              ) : null}
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-city">
                {req(t("venue.city"))}
              </label>
              <input
                id="pm-city"
                className={styles.input}
                value={form.city}
                onChange={(e) => setField("city", e.target.value)}
                placeholder={t("venue.cityPh")}
                autoComplete="address-level2"
              />
              {fieldErrors.city ? (
                <p className={styles.err}>{fieldErrors.city}</p>
              ) : null}
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-gmaps">
                {req(t("venue.googleMaps"))}
              </label>
              <input
                id="pm-gmaps"
                className={styles.input}
                value={form.google_place_url}
                onChange={(e) => setField("google_place_url", e.target.value)}
                placeholder={t("venue.googleMapsPh")}
                inputMode="url"
                autoComplete="off"
              />
              {fieldErrors.google_place_url ? (
                <p className={styles.err}>{fieldErrors.google_place_url}</p>
              ) : null}
            </div>

            <div className={`${styles.field} ${styles.priceFieldWrap}`}>
              <div
                className={styles.priceLabelRow}
                onMouseLeave={() => setPriceTipOpen(false)}
              >
                <span className={styles.label}>{req(t("venue.priceRange"))}</span>
                <div
                  className={styles.priceTipAnchor}
                  onMouseEnter={() => setPriceTipOpen(true)}
                >
                  <button
                    type="button"
                    className={styles.priceInfoBtn}
                    aria-label={t("priceInfoAria")}
                    aria-expanded={priceTipOpen}
                    onClick={() => setPriceTipOpen((v) => !v)}
                  >
                    ⓘ
                  </button>
                  {priceTipOpen ? (
                    <div className={styles.priceTooltip} role="tooltip">
                      <p>{t("priceTooltip.e1")}</p>
                      <p>{t("priceTooltip.e2")}</p>
                      <p>{t("priceTooltip.e3")}</p>
                      <p>{t("priceTooltip.e4")}</p>
                    </div>
                  ) : null}
                </div>
              </div>
              <div className={styles.priceRow}>
                {PRICE_SYMBOLS.map((sym) => (
                  <button
                    key={sym}
                    type="button"
                    className={`${styles.pricePill} ${form.price_range === sym ? styles.pricePillSelected : ""}`}
                    onClick={() => setField("price_range", sym)}
                  >
                    {sym}
                  </button>
                ))}
              </div>
              {fieldErrors.price_range ? (
                <p className={styles.err}>{fieldErrors.price_range}</p>
              ) : null}
            </div>

            <details className={`${styles.details} ${styles.optionalVenueDetails}`}>
              <summary>{t("venue.optionalVenueSectionTitle")}</summary>
              <div className={styles.optionalVenuePanel}>
                <p className={styles.help}>{t("venue.optionalVenueSectionHelp")}</p>
                <div className={styles.field}>
                  <span className={styles.label}>{t("venue.openingHours")}</span>
                  <p className={styles.help}>{t("venue.openingHoursHelp")}</p>
                  {form.opening_days.map((row) => (
                    <div key={row.id} className={styles.openingRow}>
                      <button
                        type="button"
                        className={`${styles.toggleTrack} ${row.open ? styles.toggleTrackOn : ""}`}
                        aria-pressed={row.open}
                        aria-label={t("openingToggleAria", { day: dayLabels[row.id] })}
                        onClick={() => patchOpeningDay(row.id, { open: !row.open })}
                      >
                        <span
                          className={`${styles.toggleKnob} ${row.open ? styles.toggleKnobOn : ""}`}
                        />
                      </button>
                      <span className={styles.dayLabel}>{dayLabels[row.id]}</span>
                      <select
                        className={styles.timeSelect}
                        value={row.openTime}
                        disabled={!row.open}
                        aria-label={t("openTimeAria", { day: dayLabels[row.id] })}
                        onChange={(e) => patchOpeningDay(row.id, { openTime: e.target.value })}
                      >
                        {OPEN_TIME_OPTIONS.map((opt) => (
                          <option key={opt} value={opt}>
                            {opt}
                          </option>
                        ))}
                      </select>
                      <span className={styles.timeSep}>—</span>
                      <select
                        className={styles.timeSelect}
                        value={row.closeTime}
                        disabled={!row.open}
                        aria-label={t("closeTimeAria", { day: dayLabels[row.id] })}
                        onChange={(e) => patchOpeningDay(row.id, { closeTime: e.target.value })}
                      >
                        {OPEN_TIME_OPTIONS.map((opt) => (
                          <option key={opt} value={opt}>
                            {opt}
                          </option>
                        ))}
                        <option value="24:00">{midnightLabel}</option>
                      </select>
                    </div>
                  ))}
                </div>

                <div className={styles.field}>
                  <label className={styles.label} htmlFor="pm-web">
                    {t("venue.website")}
                  </label>
                  <input
                    id="pm-web"
                    className={styles.input}
                    value={form.website}
                    onChange={(e) => setField("website", e.target.value)}
                    placeholder={t("venue.websitePh")}
                    inputMode="url"
                  />
                </div>

                <div className={styles.field}>
                  <label className={styles.label} htmlFor="pm-ig">
                    {t("venue.instagram")}
                  </label>
                  <input
                    id="pm-ig"
                    className={styles.input}
                    value={form.instagram_handle}
                    onChange={(e) => setField("instagram_handle", e.target.value)}
                    placeholder={t("venue.instagramPh")}
                  />
                </div>
              </div>
            </details>
          </>
        ) : null}

        {step === 2 ? (
          <>
            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-cname">
                {req(t("details.contactName"))}
              </label>
              <input
                id="pm-cname"
                className={styles.input}
                value={form.contact_name}
                onChange={(e) => setField("contact_name", e.target.value)}
                placeholder={t("details.contactNamePh")}
                autoComplete="name"
              />
              {fieldErrors.contact_name ? (
                <p className={styles.err}>{fieldErrors.contact_name}</p>
              ) : null}
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-email">
                {req(t("details.email"))}
              </label>
              <input
                id="pm-email"
                type="email"
                className={styles.input}
                value={form.contact_email}
                onChange={(e) => setField("contact_email", e.target.value)}
                placeholder={t("details.emailPh")}
                autoComplete="email"
              />
              {fieldErrors.contact_email ? (
                <p className={styles.err}>{fieldErrors.contact_email}</p>
              ) : null}
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-phone">
                {req(t("details.phone"))}
              </label>
              <input
                id="pm-phone"
                type="tel"
                className={styles.input}
                value={form.contact_phone}
                onChange={(e) => setField("contact_phone", e.target.value)}
                placeholder={t("details.phonePh")}
                autoComplete="tel"
              />
              <p className={styles.help}>{t("details.phoneHelp")}</p>
              {fieldErrors.contact_phone ? (
                <p className={styles.err}>{fieldErrors.contact_phone}</p>
              ) : null}
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-kvk">
                {t("details.kvk")}
              </label>
              <input
                id="pm-kvk"
                className={styles.input}
                value={form.kvk_number}
                onChange={(e) => setField("kvk_number", e.target.value)}
                placeholder={t("details.kvkPh")}
                inputMode="numeric"
              />
              <p className={styles.help}>{t("details.kvkHelp")}</p>
              {fieldErrors.kvk_number ? (
                <p className={styles.err}>{fieldErrors.kvk_number}</p>
              ) : null}
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-bname">
                {t("details.billingName")}
              </label>
              <input
                id="pm-bname"
                className={styles.input}
                value={form.billing_name}
                onChange={(e) => setField("billing_name", e.target.value)}
                placeholder={t("details.billingNamePh")}
              />
              <p className={styles.help}>{t("details.billingNameHelp")}</p>
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-baddr">
                {t("details.billingAddress")}
              </label>
              <input
                id="pm-baddr"
                className={styles.input}
                value={form.billing_address}
                onChange={(e) => setField("billing_address", e.target.value)}
                placeholder={t("details.billingAddressPh")}
              />
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="pm-vat">
                {req(t("details.vat"))}
              </label>
              <input
                id="pm-vat"
                className={styles.input}
                value={form.vat_number}
                onChange={(e) => setField("vat_number", e.target.value)}
                placeholder={t("details.vatPh")}
              />
              <p className={styles.help}>{t("details.vatHelp")}</p>
              {fieldErrors.vat_number ? (
                <p className={styles.err}>{fieldErrors.vat_number}</p>
              ) : null}
            </div>
          </>
        ) : null}

        {step === 3 ? (
          <>
            <div className={styles.field}>
              <span className={styles.label}>{t("inclusion.title")}</span>
              <p className={styles.help}>{t("inclusion.help")}</p>
              <div className={styles.moodRow}>
                {INCLUSION_KEYS.map(({ key, emoji }) => (
                  <button
                    key={key}
                    type="button"
                    className={`${styles.inclusionChip} ${form.inclusion_tags.includes(key) ? styles.inclusionChipSelected : ""}`}
                    onClick={() => toggleInclusion(key)}
                  >
                    {emoji} {tInclusionTags(key)}
                  </button>
                ))}
              </div>
            </div>

            <div className={styles.field}>
              <span className={styles.label}>{req(t("final.moodsLabel"))}</span>
              <p className={styles.help}>{t("final.moodsHelp")}</p>
              <div className={styles.moodRow}>
                {MOOD_KEYS.map(({ key, emoji }) => (
                  <button
                    key={key}
                    type="button"
                    className={`${styles.moodChip} ${form.target_moods.includes(key) ? styles.moodChipSelected : ""}`}
                    onClick={() => toggleMood(key)}
                  >
                    {emoji} {tMoods(key)}
                  </button>
                ))}
              </div>
              {fieldErrors.target_moods ? (
                <p className={styles.err}>{fieldErrors.target_moods}</p>
              ) : null}
            </div>

            <label className={styles.checkRow}>
              <input
                type="checkbox"
                checked={form.gdpr_consent}
                onChange={(e) => setField("gdpr_consent", e.target.checked)}
              />
              <span className={styles.checkText}>
                {t("final.gdprBefore")}
                <a
                  href={privacyHref}
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{ color: "#5DCAA5" }}
                >
                  {t("final.gdprLink")}
                </a>
                {t("final.gdprAfter")}
              </span>
            </label>
            {fieldErrors.gdpr_consent ? (
              <p className={styles.err}>{fieldErrors.gdpr_consent}</p>
            ) : null}

            <label className={styles.checkRow}>
              <input
                type="checkbox"
                checked={form.pricing_consent}
                onChange={(e) => setField("pricing_consent", e.target.checked)}
              />
              <span className={styles.checkText}>{t("final.pricingConsent")}</span>
            </label>
            {fieldErrors.pricing_consent ? (
              <p className={styles.err}>{fieldErrors.pricing_consent}</p>
            ) : null}

            {submitError ? (
              <p className={styles.err} role="alert">
                {submitError}
              </p>
            ) : null}

            <div className={styles.navRow}>
              <button type="button" className={styles.back} onClick={goBack}>
                {t("back")}
              </button>
              <button
                type="button"
                className={styles.btnNext}
                disabled={loading}
                onClick={() => void handleSubmit()}
              >
                {loading ? (
                  <>
                    <span className={styles.spinner} aria-hidden />
                    {tForm("submitting")}
                  </>
                ) : (
                  t("submitCta")
                )}
              </button>
            </div>
            <p className={styles.reassurance}>
              {t("trialReassurance", { date: trialEndLabel })}
            </p>
          </>
        ) : null}

        {step < 3 ? (
          <div className={styles.navRow}>
            <button type="button" className={styles.btnNext} onClick={goNext}>
              {t("next")}
            </button>
            {step > 1 ? (
              <button type="button" className={styles.back} onClick={goBack}>
                {t("back")}
              </button>
            ) : null}
          </div>
        ) : null}
      </div>
    </div>
  );
}
