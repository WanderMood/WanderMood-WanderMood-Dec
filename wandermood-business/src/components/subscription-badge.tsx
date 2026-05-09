import { differenceInCalendarDays, parseISO } from "date-fns";

import { Badge } from "@/components/ui/badge";
import type { SubscriptionStatus } from "@/types/business";

export function SubscriptionBadge({
  status,
  trialEndsAt,
}: {
  status: SubscriptionStatus;
  trialEndsAt: string | null;
}) {
  if (status === "trialing" && trialEndsAt) {
    const end = parseISO(trialEndsAt);
    const days = Math.max(0, differenceInCalendarDays(end, new Date()));
    return (
      <Badge className="border-0 bg-wm-sunset/25 text-wm-sunset hover:bg-wm-sunset/30">
        Proefperiode · {days} dagen resterend
      </Badge>
    );
  }
  if (status === "active") {
    return (
      <Badge className="border-0 bg-wm-forest/40 text-[var(--wm-green)] hover:bg-wm-forest/50">
        Actief
      </Badge>
    );
  }
  if (status === "past_due") {
    return (
      <Badge variant="destructive" className="border-0">
        Betaling mislukt
      </Badge>
    );
  }
  if (status === "canceled") {
    return (
      <Badge className="border-0 bg-muted text-muted-foreground hover:bg-muted">
        Opgezegd
      </Badge>
    );
  }
  if (status === "pending_approval") {
    return (
      <Badge className="border-0 bg-blue-500/20 text-blue-300 hover:bg-blue-500/25">
        In behandeling
      </Badge>
    );
  }
  if (status === "onboarding") {
    return (
      <Badge className="border-0 bg-amber-500/20 text-amber-200 hover:bg-amber-500/25">
        Account nieuw · abonnement nodig
      </Badge>
    );
  }
  return (
    <Badge className="border-0 bg-muted text-muted-foreground">{status}</Badge>
  );
}
