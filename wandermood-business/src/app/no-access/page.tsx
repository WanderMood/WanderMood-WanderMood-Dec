import Link from "next/link";

import { BrandMark } from "@/components/brand-mark";

export default function NoAccessPage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-wm-bg px-4">
      <div className="max-w-md space-y-6 rounded-2xl border border-[var(--wm-border)] bg-wm-card p-8 text-center shadow-lg">
        <BrandMark />
        <h1 className="text-lg font-semibold text-wm-cream">Geen toegang</h1>
        <p className="text-sm text-muted-foreground">
          Je account heeft nog geen toegang tot het partnerdashboard. Neem contact
          op met{" "}
          <a
            href="mailto:info@wandermood.com"
            className="text-[var(--wm-green)] hover:underline"
          >
            info@wandermood.com
          </a>
          .
        </p>
        <Link
          href="/login"
          className="inline-block text-sm text-[var(--wm-green)] hover:underline"
        >
          Terug naar inloggen
        </Link>
      </div>
    </main>
  );
}
