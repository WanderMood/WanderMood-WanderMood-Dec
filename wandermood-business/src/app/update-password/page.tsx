"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";

import { BrandMark } from "@/components/brand-mark";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { createClient } from "@/lib/supabase/client";
import { Eye, EyeOff } from "lucide-react";

export default function UpdatePasswordPage() {
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [show, setShow] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (password.length < 8) {
      setError("Gebruik minimaal 8 tekens.");
      return;
    }
    setLoading(true);
    const supabase = createClient();
    const { error: updErr } = await supabase.auth.updateUser({ password });
    setLoading(false);
    if (updErr) {
      setError(updErr.message);
      return;
    }
    router.push("/dashboard");
    router.refresh();
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-wm-bg px-4">
      <div className="w-full max-w-md space-y-6 rounded-2xl border border-[var(--wm-border)] bg-wm-card p-8 shadow-lg">
        <div className="text-center">
          <BrandMark />
          <p className="mt-2 text-sm text-muted-foreground">Nieuw wachtwoord</p>
        </div>
        <form onSubmit={onSubmit} className="space-y-4">
          {error ? (
            <p className="rounded-lg bg-destructive/15 px-3 py-2 text-sm text-destructive">
              {error}
            </p>
          ) : null}
          <div className="space-y-2">
            <Label htmlFor="password">Nieuw wachtwoord</Label>
            <div className="relative">
              <Input
                id="password"
                type={show ? "text" : "password"}
                autoComplete="new-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="border-[var(--wm-border)] bg-wm-bg pr-10"
              />
              <button
                type="button"
                className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                onClick={() => setShow((s) => !s)}
                aria-label={show ? "Verberg" : "Toon"}
              >
                {show ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
              </button>
            </div>
          </div>
          <Button
            type="submit"
            className="w-full bg-wm-forest text-wm-cream hover:bg-wm-forest/90"
            disabled={loading}
          >
            {loading ? "Bezig…" : "Opslaan"}
          </Button>
        </form>
        <p className="text-center text-sm">
          <Link href="/login" className="text-[var(--wm-green)] hover:underline">
            Naar inloggen
          </Link>
        </p>
      </div>
    </main>
  );
}
