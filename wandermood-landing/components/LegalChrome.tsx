import { Link } from "@/i18n/navigation";
import { getTranslations } from "next-intl/server";

export default async function LegalChrome({
  children,
  locale,
}: {
  children: React.ReactNode;
  locale: string;
}) {
  const t = await getTranslations({ locale, namespace: "legal.common" });

  return (
    <div className="min-h-screen bg-[#fffdf5] text-zinc-800 antialiased">
      <header className="sticky top-0 z-10 border-b border-zinc-200/90 bg-[#fffdf5]/95 backdrop-blur-md">
        <div className="mx-auto flex max-w-3xl flex-wrap items-center justify-between gap-3 px-5 py-4">
          <Link
            href="/"
            className="text-lg font-bold tracking-tight text-emerald-700"
            style={{ fontFamily: "var(--font-fraunces), Georgia, serif" }}
          >
            {t("brand")}
          </Link>
          <nav
            className="flex flex-wrap gap-x-5 gap-y-1 text-sm text-zinc-600"
            aria-label="Legal"
          >
            <Link
              href="/privacy"
              className="underline-offset-4 hover:text-zinc-900 hover:underline"
            >
              {t("privacyNav")}
            </Link>
            <Link
              href="/terms"
              className="underline-offset-4 hover:text-zinc-900 hover:underline"
            >
              {t("termsNav")}
            </Link>
            <Link
              href="/account-deletion"
              className="underline-offset-4 hover:text-zinc-900 hover:underline"
            >
              {t("accountDeletionNav")}
            </Link>
          </nav>
        </div>
      </header>
      <main className="mx-auto max-w-3xl px-5 py-10">{children}</main>
    </div>
  );
}
