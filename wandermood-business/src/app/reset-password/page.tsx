"use client";

import { useState } from "react";
import Link from "next/link";

import { BrandMark } from "@/components/brand-mark";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { createClient } from "@/lib/supabase/client";

const appUrl =
  process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";

export default function ResetPasswordPage() {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setMessage(null);
    setLoading(true);
    const supabase = createClient();
    const { error: resetErr } = await supabase.auth.resetPasswordForEmail(
      email.trim(),
      {
        redirectTo: `${appUrl}/auth/callback?next=/update-password`,
      },
    );
    setLoading(false);
    if (resetErr) {
      setError(resetErr.message);
      return;
    }
    setMessage(
      "Als dit e-mailadres bij ons bekend is, ontvang je zo een resetlink.",
    );
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-wm-bg px-4">
      <div className="w-full max-w-md space-y-6 rounded-2xl border border-[var(--wm-border)] bg-wm-card p-8 shadow-lg">
        <div className="text-center">
          <BrandMark />
          <p className="mt-2 text-sm text-muted-foreground">Wachtwoord resetten</p>
        </div>
        <form onSubmit={onSubmit} className="space-y-4">
          {error ? (
            <p className="rounded-lg bg-destructive/15 px-3 py-2 text-sm text-destructive">
              {error}
            </p>
          ) : null}
          {message ? (
            <p className="rounded-lg bg-wm-forest/20 px-3 py-2 text-sm text-wm-cream">
              {message}
            </p>
          ) : null}
          <div className="space-y-2">
            <Label htmlFor="email">E-mail</Label>
            <Input
              id="email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="border-[var(--wm-border)] bg-wm-bg"
            />
          </div>
          <Button
            type="submit"
            className="w-full bg-wm-forest text-wm-cream hover:bg-wm-forest/90"
            disabled={loading}
          >
            {loading ? "Bezig…" : "Stuur resetlink"}
          </Button>
        </form>
        <p className="text-center text-sm">
          <Link href="/login" className="text-[var(--wm-green)] hover:underline">
            Terug naar inloggen
          </Link>
        </p>
      </div>
    </main>
  );
}
