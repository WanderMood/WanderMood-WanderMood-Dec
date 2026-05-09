import Link from "next/link";
import { format, subDays } from "date-fns";

import { OverviewChart } from "@/components/overview-chart";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { PARTNER_MOOD_OPTIONS } from "@/lib/mood-options";
import { createClient } from "@/lib/supabase/server";
import { getPartnerListing } from "@/lib/partner-data";
import type { BusinessAnalyticsDaily } from "@/types/business";
import { Eye, Gift, Hand, MousePointerClick } from "lucide-react";

export default async function DashboardOverviewPage() {
  const listing = await getPartnerListing();
  if (!listing) {
    return null;
  }

  const supabase = await createClient();
  const from = format(subDays(new Date(), 29), "yyyy-MM-dd");
  const { data: rawAnalytics } = await supabase
    .from("business_analytics_daily")
    .select("date, views, taps")
    .eq("business_listing_id", listing.id)
    .gte("date", from)
    .order("date", { ascending: true });

  const analytics = (rawAnalytics ?? []) as Pick<
    BusinessAnalyticsDaily,
    "date" | "views" | "taps"
  >[];

  const moods = listing.target_moods ?? [];

  const showTrialBanner = listing.subscription_status === "trialing";
  const showPastDueBanner = listing.subscription_status === "past_due";

  return (
    <div className="space-y-8">
      {showTrialBanner ? (
        <div className="flex flex-col gap-3 rounded-xl border border-wm-sunset/40 bg-wm-sunset/10 p-4 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-wm-cream">
            Je proefperiode loopt af. Start je abonnement om zichtbaar te blijven in
            WanderMood.
          </p>
          <Link
            href="/dashboard/subscription"
            className={cn(
              buttonVariants({ size: "default" }),
              "bg-wm-sunset text-wm-cream hover:bg-wm-sunset/90",
            )}
          >
            Abonnement starten →
          </Link>
        </div>
      ) : null}
      {showPastDueBanner ? (
        <div className="flex flex-col gap-3 rounded-xl border border-destructive/50 bg-destructive/10 p-4 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-wm-cream">
            Betaling mislukt. Update je betaalmethode om je zichtbaarheid te behouden.
          </p>
          <Link
            href="/dashboard/subscription"
            className={cn(buttonVariants({ variant: "destructive" }))}
          >
            Betaling bijwerken →
          </Link>
        </div>
      ) : null}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          icon={<Eye className="size-5 text-[var(--wm-green)]" />}
          title="Weergaven"
          value={listing.total_views ?? 0}
          subtitle="Totaal aantal keer gezien in Explore en dagplannen"
        />
        <StatCard
          icon={<MousePointerClick className="size-5 text-[var(--wm-green)]" />}
          title="Tikken"
          value={listing.total_taps ?? 0}
          subtitle="Keer dat iemand op jouw plek heeft getikt"
        />
        <StatCard
          icon={<Gift className="size-5 text-[var(--wm-green)]" />}
          title="Aanbiedingen"
          value={listing.total_offer_redemptions ?? 0}
          subtitle="Gebruikers die jouw aanbieding hebben gebruikt"
        />
        <StatCard
          icon={<Hand className="size-5 text-[var(--wm-green)]" />}
          title="Check-ins"
          value={listing.total_checkins ?? 0}
          subtitle="Gebruikers die bij jou zijn geweest"
        />
      </div>

      <section>
        <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Laatste 30 dagen
        </h2>
        <OverviewChart data={analytics} />
      </section>

      <section className="rounded-xl border border-[var(--wm-border)] bg-wm-card p-4">
        <h2 className="mb-3 text-sm font-semibold text-wm-cream">
          Stemmingen voor jouw plek
        </h2>
        {moods.length === 0 ? (
          <p className="text-sm text-muted-foreground">
            Nog geen stemmingen gekozen. Voeg ze toe onder{" "}
            <Link href="/dashboard/listing" className="text-[var(--wm-green)] hover:underline">
              Mijn vermelding
            </Link>
            .
          </p>
        ) : (
          <div className="flex flex-wrap gap-2">
            {moods.map((id) => {
              const opt = PARTNER_MOOD_OPTIONS.find((o) => o.id === id);
              return (
                <span
                  key={id}
                  className="inline-flex items-center gap-1 rounded-full border border-wm-forest/50 bg-wm-forest/15 px-3 py-1 text-sm text-wm-cream"
                >
                  {opt ? `${opt.emoji} ${opt.label}` : id}
                </span>
              );
            })}
          </div>
        )}
      </section>
    </div>
  );
}

function StatCard({
  icon,
  title,
  value,
  subtitle,
}: {
  icon: React.ReactNode;
  title: string;
  value: number;
  subtitle: string;
}) {
  return (
    <Card className="border-[var(--wm-border)] bg-wm-card shadow-none">
      <CardHeader className="flex flex-row items-center gap-2 space-y-0 pb-2">
        {icon}
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {title}
        </CardTitle>
      </CardHeader>
      <CardContent>
        <p className="text-3xl font-bold text-[var(--wm-green)]">{value}</p>
        <p className="mt-2 text-xs text-muted-foreground">{subtitle}</p>
      </CardContent>
    </Card>
  );
}
