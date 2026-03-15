import { getTranslations } from "next-intl/server";

export default async function TermsPage() {
  const t = await getTranslations("termsPage");

  return (
    <main className="bg-[#fffdf5]">
      <section className="wm-section">
        <div className="wm-container max-w-3xl">
          <h1 className="text-3xl font-bold text-zinc-900 sm:text-4xl">{t("title")}</h1>
          <p className="mt-2 text-sm text-zinc-500">{t("updated")}</p>
          <p className="mt-6 text-zinc-700">{t("intro")}</p>
          <ul className="mt-6 list-disc space-y-3 pl-6 text-zinc-700">
            <li>{t("item1")}</li>
            <li>{t("item2")}</li>
            <li>{t("item3")}</li>
          </ul>
        </div>
      </section>
    </main>
  );
}
