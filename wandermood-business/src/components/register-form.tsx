"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Eye, EyeOff } from "lucide-react";

const COUNTRIES = [
  { code: "NL", label: "Nederland" },
  { code: "BE", label: "België" },
  { code: "DE", label: "Duitsland" },
  { code: "FR", label: "Frankrijk" },
  { code: "ES", label: "Spanje" },
  { code: "GB", label: "Verenigd Koninkrijk" },
];

export function RegisterForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [businessName, setBusinessName] = useState("");
  const [city, setCity] = useState("");
  const [country, setCountry] = useState("NL");
  const [showPw, setShowPw] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (password !== confirm) {
      setError("Wachtwoorden komen niet overeen.");
      return;
    }
    setLoading(true);
    try {
      const res = await fetch("/api/auth/register-partner", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: email.trim(),
          password,
          business_name: businessName.trim(),
          city: city.trim(),
          country,
        }),
      });
      const data = (await res.json()) as { ok?: boolean; error?: string };
      if (!res.ok) {
        throw new Error(data.error ?? "Registratie mislukt");
      }
      router.push("/login?registered=1");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registratie mislukt");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      {error ? (
        <p className="rounded-lg bg-destructive/15 px-3 py-2 text-sm text-destructive">
          {error}
        </p>
      ) : null}
      <div className="space-y-2">
        <Label htmlFor="biz">Bedrijfsnaam</Label>
        <Input
          id="biz"
          required
          value={businessName}
          onChange={(e) => setBusinessName(e.target.value)}
          className="border-[var(--wm-border)] bg-wm-bg"
          autoComplete="organization"
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="city">Stad</Label>
        <Input
          id="city"
          required
          value={city}
          onChange={(e) => setCity(e.target.value)}
          className="border-[var(--wm-border)] bg-wm-bg"
          autoComplete="address-level2"
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="country">Land</Label>
        <select
          id="country"
          value={country}
          onChange={(e) => setCountry(e.target.value)}
          className="flex h-10 w-full rounded-md border border-[var(--wm-border)] bg-wm-bg px-3 py-2 text-sm text-wm-cream"
        >
          {COUNTRIES.map((c) => (
            <option key={c.code} value={c.code} className="bg-wm-card">
              {c.label}
            </option>
          ))}
        </select>
      </div>
      <div className="space-y-2">
        <Label htmlFor="email">E-mail</Label>
        <Input
          id="email"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="border-[var(--wm-border)] bg-wm-bg"
          autoComplete="email"
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="password">Wachtwoord</Label>
        <div className="relative">
          <Input
            id="password"
            type={showPw ? "text" : "password"}
            required
            minLength={8}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="border-[var(--wm-border)] bg-wm-bg pr-10"
            autoComplete="new-password"
          />
          <button
            type="button"
            className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
            onClick={() => setShowPw((s) => !s)}
            aria-label={showPw ? "Verberg" : "Toon"}
          >
            {showPw ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
          </button>
        </div>
      </div>
      <div className="space-y-2">
        <Label htmlFor="confirm">Bevestig wachtwoord</Label>
        <Input
          id="confirm"
          type={showPw ? "text" : "password"}
          required
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          className="border-[var(--wm-border)] bg-wm-bg"
          autoComplete="new-password"
        />
      </div>
      <p className="text-xs text-muted-foreground">
        Na registratie kun je inloggen en je abonnement (€79/maand) starten. Je bent
        pas zichtbaar in de app als je abonnement actief is.
      </p>
      <Button
        type="submit"
        className="w-full bg-wm-forest text-wm-cream hover:bg-wm-forest/90"
        disabled={loading}
      >
        {loading ? "Bezig…" : "Account aanmaken"}
      </Button>
      <p className="text-center text-sm text-muted-foreground">
        Al een account?{" "}
        <Link href="/login" className="text-[var(--wm-green)] hover:underline">
          Inloggen
        </Link>
      </p>
    </form>
  );
}
