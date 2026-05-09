import Link from "next/link";
import { redirect } from "next/navigation";

import { BrandMark } from "@/components/brand-mark";
import { RegisterForm } from "@/components/register-form";
import { createClient } from "@/lib/supabase/server";

export default async function RegisterPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (user) {
    redirect("/dashboard");
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-wm-bg px-4 py-10">
      <div className="w-full max-w-md space-y-6 rounded-2xl border border-[var(--wm-border)] bg-wm-card p-8 shadow-lg">
        <div className="text-center">
          <BrandMark />
          <p className="mt-2 text-sm text-muted-foreground">Zakelijk account</p>
          <p className="mt-1 text-xs text-muted-foreground">
            Registreer je zaak voor WanderMood Business
          </p>
        </div>
        <RegisterForm />
        <p className="text-center text-xs text-muted-foreground">
          <Link href="/login" className="hover:underline">
            ← Terug naar inloggen
          </Link>
        </p>
      </div>
    </main>
  );
}
