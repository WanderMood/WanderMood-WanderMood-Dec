import Link from "next/link";

import { BrandMark } from "@/components/brand-mark";

export default function InviteTokenPage({
  params,
}: {
  params: { token: string };
}) {
  const { token } = params;
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-wm-bg px-4">
      <div className="max-w-md space-y-6 rounded-2xl border border-[var(--wm-border)] bg-wm-card p-8 text-center shadow-lg">
        <BrandMark />
        <h1 className="text-lg font-semibold text-wm-cream">Partneruitnodiging</h1>
        <p className="text-sm text-muted-foreground">
          Open de link in de e-mail van WanderMood om je account te activeren. Daarna
          kun je hier inloggen.
        </p>
        <p className="font-mono text-xs text-wm-muted">Referentie: {token}</p>
        <Link
          href="/login"
          className="inline-block rounded-full bg-wm-forest px-5 py-2.5 text-sm font-semibold text-wm-cream hover:bg-wm-forest/90"
        >
          Naar inloggen
        </Link>
      </div>
    </main>
  );
}
