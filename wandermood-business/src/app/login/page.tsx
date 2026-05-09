import Link from "next/link";
import { redirect } from "next/navigation";

import { BrandMark } from "@/components/brand-mark";
import { LoginForm } from "@/components/login-form";
import { createClient } from "@/lib/supabase/server";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: { next?: string; error?: string; registered?: string };
}) {
  const sp = searchParams;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (user) {
    redirect(sp.next?.startsWith("/") ? sp.next : "/dashboard");
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-wm-bg px-4">
      <div className="w-full max-w-md space-y-8 rounded-2xl border border-[var(--wm-border)] bg-wm-card p-8 shadow-lg">
        <div className="text-center">
          <BrandMark />
          <p className="mt-2 text-sm text-muted-foreground">Partner Portal</p>
        </div>
        {sp.error === "auth" ? (
          <p className="rounded-lg bg-destructive/15 px-3 py-2 text-center text-sm text-destructive">
            Inloggen mislukt. Probeer opnieuw of vraag een nieuwe uitnodiging aan.
          </p>
        ) : null}
        {sp.registered === "1" ? (
          <p className="rounded-lg bg-wm-forest/20 px-3 py-2 text-center text-sm text-wm-cream">
            Account aangemaakt. Log nu in om je abonnement te starten.
          </p>
        ) : null}
        <LoginForm nextPath={sp.next} />
        <p className="text-center text-sm text-muted-foreground">
          <Link href="/register" className="text-[var(--wm-green)] hover:underline">
            Nog geen account? Registreer je zaak
          </Link>
        </p>
        <p className="text-center text-sm text-muted-foreground">
          <Link href="/reset-password" className="text-[var(--wm-green)] hover:underline">
            Wachtwoord vergeten?
          </Link>
        </p>
      </div>
    </main>
  );
}
