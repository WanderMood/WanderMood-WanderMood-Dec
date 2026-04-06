import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import LegalChrome from "@/components/LegalChrome";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "legal.accountDeletion" });
  return {
    title: t("metaTitle"),
    description: t("metaDescription"),
  };
}

export default async function AccountDeletionPage({ params }: Props) {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "legal.accountDeletion" });
  const tc = await getTranslations({ locale, namespace: "legal.common" });

  const dataItems = [
    t("dataItem1"),
    t("dataItem2"),
    t("dataItem3"),
    t("dataItem4"),
  ];

  return (
    <LegalChrome locale={locale}>
      <article className="space-y-8 text-zinc-700">
        <div className="space-y-3">
          <h1
            className="text-3xl font-bold text-zinc-900"
            style={{ fontFamily: "var(--font-fraunces), Georgia, serif" }}
          >
            {t("title")}
          </h1>
          <p className="text-lg leading-relaxed text-zinc-600">{t("subtitle")}</p>
        </div>

        <section className="space-y-3 rounded-2xl border border-zinc-200 bg-white/80 p-6 shadow-sm">
          <h2 className="text-xl font-bold text-zinc-900">{t("sectionAppTitle")}</h2>
          <p className="leading-relaxed">{t("sectionAppIntro")}</p>
          <ol className="list-decimal space-y-2 pl-5 leading-relaxed">
            <li>{t("step1")}</li>
            <li>{t("step2")}</li>
            <li>{t("step3")}</li>
            <li>{t("step4")}</li>
          </ol>
        </section>

        <section className="space-y-3 rounded-2xl border border-zinc-200 bg-white/80 p-6 shadow-sm">
          <h2 className="text-xl font-bold text-zinc-900">{t("sectionEmailTitle")}</h2>
          <p className="leading-relaxed">{t("sectionEmailBody")}</p>
          <p>
            <a
              href={`mailto:${tc("contactEmail")}?subject=Account%20deletion`}
              className="font-semibold text-emerald-700 underline hover:text-emerald-800"
            >
              {tc("contactEmail")}
            </a>
          </p>
          <p className="leading-relaxed text-zinc-600">{t("sectionEmailAfter")}</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-zinc-900">{t("sectionDataTitle")}</h2>
          <p className="leading-relaxed">{t("sectionDataIntro")}</p>
          <ul className="list-disc space-y-2 pl-5 leading-relaxed">
            {dataItems.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-zinc-900">{t("sectionRetainTitle")}</h2>
          <p className="leading-relaxed">{t("sectionRetainBody")}</p>
        </section>

        <p className="text-sm">
          <Link href="/privacy" className="font-semibold text-emerald-700 underline">
            ← {t("backToPrivacy")}
          </Link>
        </p>
      </article>
    </LegalChrome>
  );
}
