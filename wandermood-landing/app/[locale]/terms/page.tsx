import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import LegalChrome from "@/components/LegalChrome";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "legal.terms" });
  return {
    title: t("metaTitle"),
    description: t("metaDescription"),
  };
}

export default async function TermsPage({ params }: Props) {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "legal.terms" });
  const tc = await getTranslations({ locale, namespace: "legal.common" });

  return (
    <LegalChrome locale={locale}>
      <article className="space-y-6 text-zinc-700">
        <h1
          className="text-3xl font-bold text-zinc-900"
          style={{ fontFamily: "var(--font-museo), system-ui, sans-serif" }}
        >
          {t("title")}
        </h1>
        <p className="text-sm text-zinc-500">{t("updated")}</p>
        <p className="leading-relaxed">{t("p1")}</p>
        <p className="leading-relaxed">{t("p2")}</p>
        <p className="leading-relaxed">{t("p3")}</p>
        <p className="leading-relaxed">
          {t("p4")}{" "}
          <a
            href={`mailto:${tc("contactEmail")}`}
            className="font-semibold text-emerald-700 underline"
          >
            {tc("contactEmail")}
          </a>
          .
        </p>
        <p className="text-sm">
          <Link href="/privacy" className="font-semibold text-emerald-700 underline">
            ← {t("backPrivacy")}
          </Link>
        </p>
      </article>
    </LegalChrome>
  );
}
