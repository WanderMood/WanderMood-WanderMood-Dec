import { Suspense } from "react";

import { SubscriptionContent } from "./subscription-content";

export default function SubscriptionPage() {
  return (
    <Suspense fallback={<p className="text-sm text-muted-foreground">Laden…</p>}>
      <SubscriptionContent />
    </Suspense>
  );
}
