import { getTranslations } from "next-intl/server";

const CONTACT_EMAIL = "hello@wandermood.com";

export default async function ContactPage() {
  const t = await getTranslations("contactPage");

  return (
    <main className="bg-[#fffdf5]">
      <section className="wm-section">
        <div className="wm-container max-w-3xl">
          <h1 className="text-3xl font-bold text-zinc-900 sm:text-4xl">{t("title")}</h1>
          <p className="mt-4 text-zinc-700">{t("subtitle")}</p>

          <form
            action={`mailto:${CONTACT_EMAIL}`}
            method="post"
            encType="text/plain"
            className="mt-8 space-y-4 rounded-2xl border border-zinc-200 bg-white p-6"
          >
            <div>
              <label className="mb-1 block text-sm font-medium text-zinc-700">{t("nameLabel")}</label>
              <input
                type="text"
                name="name"
                required
                className="w-full rounded-xl border border-zinc-300 px-4 py-2.5 outline-none focus:border-emerald-400"
              />
            </div>

            <div>
              <label className="mb-1 block text-sm font-medium text-zinc-700">{t("emailLabel")}</label>
              <input
                type="email"
                name="email"
                required
                className="w-full rounded-xl border border-zinc-300 px-4 py-2.5 outline-none focus:border-emerald-400"
              />
            </div>

            <div>
              <label className="mb-1 block text-sm font-medium text-zinc-700">{t("messageLabel")}</label>
              <textarea
                name="message"
                rows={5}
                required
                className="w-full rounded-xl border border-zinc-300 px-4 py-2.5 outline-none focus:border-emerald-400"
              />
            </div>

            <button
              type="submit"
              className="inline-flex h-11 items-center justify-center rounded-full px-6 font-semibold text-white"
              style={{ backgroundColor: "#16a34a" }}
            >
              {t("sendButton")}
            </button>
          </form>

          <p className="mt-4 text-sm text-zinc-500">{t("note")}</p>
        </div>
      </section>
    </main>
  );
}
