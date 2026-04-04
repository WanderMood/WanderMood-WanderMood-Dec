import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import LegalChrome from "@/components/LegalChrome";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "legal.privacy" });
  return {
    title: t("metaTitle"),
    description: t("metaDescription"),
  };
}

export default async function PrivacyPage({ params }: Props) {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "legal.privacy" });
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
        <p className="leading-relaxed">
          {t("p3")}{" "}
          <Link
            href="/account-deletion"
            className="font-semibold text-emerald-700 underline hover:text-emerald-800"
          >
            {t("p3Link")}
          </Link>{" "}
          {t("p3After")}
        </p>
        <p className="leading-relaxed">{t("p4")}</p>
        <p className="leading-relaxed">{t("p5")}</p>
        <p className="leading-relaxed">{t("p6")}</p>
        <p className="leading-relaxed">{t("p7")}</p>
        <p className="leading-relaxed">{t("p8")}</p>
        <p className="leading-relaxed">
          {t("questions")}{" "}
          <a
            href={`mailto:${tc("contactEmail")}`}
            className="font-semibold text-emerald-700 underline"
          >
            {tc("contactEmail")}
          </a>
          .
        </p>
      </article>
    </LegalChrome>
  );
}
