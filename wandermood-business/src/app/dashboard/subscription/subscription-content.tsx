"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { differenceInCalendarDays, parseISO } from "date-fns";

import { Button, buttonVariants } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { useDashboardListing } from "@/context/dashboard-context";
import { cn } from "@/lib/utils";
import { Check } from "lucide-react";
import { toast } from "sonner";

export function SubscriptionContent() {
  const listing = useDashboardListing();
  const searchParams = useSearchParams();
  const [loading, setLoading] = useState<string | null>(null);

  useEffect(() => {
    if (searchParams.get("success") === "1") {
      toast.success("Betaling geslaagd. Je abonnement wordt bijgewerkt.");
    }
  }, [searchParams]);

  const status = listing.subscription_status;
  const trialEnds = listing.trial_ends_at
    ? parseISO(listing.trial_ends_at)
    : null;
  const trialDaysLeft =
    trialEnds != null
      ? Math.max(0, differenceInCalendarDays(trialEnds, new Date()))
      : null;

  async function openCheckout() {
    setLoading("checkout");
    try {
      const res = await fetch("/api/stripe/create-checkout", { method: "POST" });
      const data = (await res.json()) as { url?: string; error?: string };
      if (!res.ok) throw new Error(data.error ?? "Checkout mislukt");
      if (data.url) window.open(data.url, "_blank", "noopener,noreferrer");
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Checkout mislukt");
    } finally {
      setLoading(null);
    }
  }

  async function openPortal() {
    setLoading("portal");
    try {
      const res = await fetch("/api/stripe/customer-portal", { method: "POST" });
      const data = (await res.json()) as { url?: string; error?: string };
      if (!res.ok) throw new Error(data.error ?? "Portaal mislukt");
      if (data.url) window.location.href = data.url;
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Portaal mislukt");
    } finally {
      setLoading(null);
    }
  }

  const benefits = [
    "Zichtbaar in Explore en Moody's dagplannen",
    "Stemming-targeting voor jouw doelgroep",
    "Actieve aanbiedingen voor gebruikers",
    "Analytics dashboard",
    "Maandelijks opzegbaar",
  ];

  if (status === "trialing") {
    return (
      <div className="mx-auto max-w-lg space-y-6">
        <Card className="border-wm-sunset/40 bg-wm-sunset/10 shadow-none">
          <CardHeader>
            <CardTitle className="text-wm-cream">Proefperiode actief</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-sm text-wm-cream">
              {trialDaysLeft != null
                ? `${trialDaysLeft} dagen resterend.`
                : "Je proefperiode is actief."}
            </p>
            <p className="text-sm text-muted-foreground">
              Na je proefperiode: €79/maand. Geen contract.
            </p>
            <Button
              onClick={() => void openCheckout()}
              disabled={loading !== null}
              className="w-full bg-wm-forest text-wm-cream hover:bg-wm-forest/90"
            >
              {loading === "checkout" ? "Bezig…" : "Abonnement starten"}
            </Button>
          </CardContent>
        </Card>
        <BenefitsList items={benefits} />
      </div>
    );
  }

  if (status === "active") {
    return (
      <div className="mx-auto max-w-lg space-y-6">
        <Card className="border-wm-forest/50 bg-wm-forest/15 shadow-none">
          <CardHeader>
            <CardTitle className="text-wm-cream">Abonnement actief ✓</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-sm text-wm-cream">
              €79/maand
              {listing.subscription_expires_at
                ? ` · Volgende periode: ${new Date(
                    listing.subscription_expires_at,
                  ).toLocaleDateString("nl-NL")}`
                : null}
            </p>
            <Button
              variant="outline"
              className="w-full border-[var(--wm-border)]"
              onClick={() => void openPortal()}
              disabled={loading !== null}
            >
              {loading === "portal" ? "Bezig…" : "Betaalmethode beheren"}
            </Button>
            <Dialog>
              <DialogTrigger
                className={cn(
                  buttonVariants({ variant: "ghost" }),
                  "w-full text-muted-foreground",
                )}
              >
                Abonnement opzeggen
              </DialogTrigger>
              <DialogContent className="border-[var(--wm-border)] bg-wm-card">
                <DialogHeader>
                  <DialogTitle>Opzeggen</DialogTitle>
                  <DialogDescription>
                    Je gaat naar het Stripe-klantenportaal om je abonnement te
                    beheren of op te zeggen. Je behoudt toegang tot het einde van
                    de betaalperiode.
                  </DialogDescription>
                </DialogHeader>
                <DialogFooter>
                  <Button
                    onClick={() => void openPortal()}
                    className="bg-wm-forest text-wm-cream"
                  >
                    Naar portaal
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (status === "past_due") {
    return (
      <div className="mx-auto max-w-lg">
        <Card className="border-destructive/50 bg-destructive/10 shadow-none">
          <CardHeader>
            <CardTitle className="text-destructive">Betaling mislukt</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-sm text-wm-cream">
              Werk je betaalmethode bij om actief te blijven.
            </p>
            <Button
              variant="destructive"
              className="w-full"
              onClick={() => void openPortal()}
              disabled={loading !== null}
            >
              {loading === "portal" ? "Bezig…" : "Betaling bijwerken"}
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (status === "canceled") {
    return (
      <div className="mx-auto max-w-lg space-y-6">
        <Card className="border-[var(--wm-border)] bg-muted/20 shadow-none">
          <CardHeader>
            <CardTitle className="text-wm-cream">Abonnement opgezegd</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Je vermelding is niet meer zichtbaar voor gebruikers.
            </p>
            <Button
              onClick={() => void openCheckout()}
              disabled={loading !== null}
              className="w-full bg-wm-forest text-wm-cream hover:bg-wm-forest/90"
            >
              {loading === "checkout" ? "Bezig…" : "Opnieuw abonneren"}
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-lg">
      <Card className="border-[var(--wm-border)] bg-wm-card shadow-none">
        <CardHeader>
          <CardTitle className="text-wm-cream">Abonnement</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Status: {status}. Neem contact op met info@wandermood.com voor hulp.
          </p>
          <Button
            onClick={() => void openCheckout()}
            className="bg-wm-forest text-wm-cream"
          >
            Abonnement starten
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}

function BenefitsList({ items }: { items: string[] }) {
  return (
    <ul className="space-y-2 text-sm text-muted-foreground">
      {items.map((t) => (
        <li key={t} className="flex gap-2">
          <Check className="mt-0.5 size-4 shrink-0 text-[var(--wm-green)]" />
          <span>{t}</span>
        </li>
      ))}
    </ul>
  );
}
