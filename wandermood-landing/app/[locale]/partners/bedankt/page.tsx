import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import Stripe from "stripe";
import { Link } from "@/i18n/navigation";

type Props = {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{ session_id?: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "partners.bedankt" });
  return { title: t("title") };
}

export default async function PartnerBedanktPage({ params, searchParams }: Props) {
  const { locale } = await params;
  const { session_id } = await searchParams;
  const t = await getTranslations({ locale, namespace: "partners.bedankt" });

  let email: string | null = null;
  const key = process.env.STRIPE_SECRET_KEY?.trim();
  if (session_id && key) {
    try {
      const stripe = new Stripe(key);
      const session = await stripe.checkout.sessions.retrieve(session_id);
      email =
        session.customer_details?.email ??
        (typeof session.customer_email === "string" ? session.customer_email : null);
    } catch {
      /* ignore */
    }
  }

  return (
    <div
      className="landing-root"
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 24,
        background: "var(--cream-warm, #f5f0e8)",
      }}
    >
      <div
        style={{
          maxWidth: 520,
          textAlign: "center",
          background: "#1a1916",
          color: "#f5f0e8",
          borderRadius: 16,
          padding: "40px 32px",
          border: "1px solid rgba(245, 240, 232, 0.08)",
          boxShadow: "0 24px 48px rgba(20, 18, 16, 0.2)",
        }}
      >
        <div
          style={{
            width: 64,
            height: 64,
            borderRadius: "50%",
            background: "rgba(93, 202, 165, 0.2)",
            color: "#5dcaa5",
            fontSize: 36,
            lineHeight: "64px",
            margin: "0 auto 24px",
            fontWeight: 700,
          }}
          aria-hidden
        >
          ✓
        </div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 12, lineHeight: 1.3 }}>
          {t("title")}
        </h1>
        <p style={{ fontSize: 15, color: "rgba(245, 240, 232, 0.7)", lineHeight: 1.6, marginBottom: 28 }}>
          {t("sub")}
        </p>
        <ul
          style={{
            textAlign: "left",
            listStyle: "none",
            padding: 0,
            margin: "0 0 32px",
            fontSize: 14,
            lineHeight: 1.6,
            color: "rgba(245, 240, 232, 0.85)",
          }}
        >
          <li style={{ marginBottom: 12 }}>
            📧 {email ? t("emailLine", { email }) : t("emailFallback")}
          </li>
          <li>⏳ {t("trialLine")}</li>
        </ul>
        <Link
          href="/"
          style={{
            display: "inline-flex",
            alignItems: "center",
            justifyContent: "center",
            width: "100%",
            padding: "14px 20px",
            borderRadius: 10,
            background: "#2a6049",
            color: "#f5f0e8",
            fontWeight: 700,
            fontSize: 15,
            textDecoration: "none",
          }}
        >
          {t("cta")}
        </Link>
      </div>
    </div>
  );
}
