import { createSupabaseAdmin } from "@/lib/supabase-admin";
import type { SupabaseClient } from "@supabase/supabase-js";
import { NextResponse } from "next/server";

const ADMIN_HEADER = "x-wandermood-admin";

async function safeCount(
  supabase: SupabaseClient,
  table: string
): Promise<number | null> {
  const { count, error } = await supabase
    .from(table)
    .select("*", { count: "exact", head: true });
  if (error) return null;
  return count ?? 0;
}

/** Stripe `billing_payments` + `stripe_webhook_events` — null if tables missing. */
async function stripeBillingSnapshot(supabase: SupabaseClient) {
  const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const payments = await supabase
    .from("billing_payments")
    .select("amount_paid_cents, currency")
    .gte("paid_at", since);

  if (payments.error) {
    return {
      paymentsLast30Days: null as number | null,
      revenueLast30DaysCents: null as number | null,
      revenueCurrency: null as string | null,
    };
  }

  const rows = payments.data ?? [];
  if (rows.length === 0) {
    return {
      paymentsLast30Days: 0,
      revenueLast30DaysCents: 0,
      revenueCurrency: null as string | null,
    };
  }

  const byCurrency = new Map<string, number>();
  for (const r of rows) {
    const c = (r.currency ?? "usd").toLowerCase();
    byCurrency.set(c, (byCurrency.get(c) ?? 0) + Number(r.amount_paid_cents ?? 0));
  }
  let topCurrency = "usd";
  let topCents = 0;
  for (const [cur, cents] of byCurrency) {
    if (cents > topCents) {
      topCents = cents;
      topCurrency = cur;
    }
  }

  return {
    paymentsLast30Days: rows.length,
    revenueLast30DaysCents: topCents,
    revenueCurrency: topCurrency,
    revenueByCurrencyNote:
      byCurrency.size > 1
        ? `${byCurrency.size} currencies in window; totals shown for largest amount.`
        : undefined,
  };
}

async function stripeWebhookEventCount(supabase: SupabaseClient) {
  const { count, error } = await supabase
    .from("stripe_webhook_events")
    .select("*", { count: "exact", head: true });
  if (error) return null;
  return count ?? 0;
}

/** Edge Function `api_invocations` rollup (last 24h); null fields if table missing. */
async function edgeApiSnapshot(supabase: SupabaseClient) {
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { data, error } = await supabase
    .from("api_invocations")
    .select("function_slug, http_status, operation, duration_ms")
    .gte("created_at", since)
    .limit(15_000);

  if (error) {
    return {
      available: false as const,
      totalLast24h: null as number | null,
      rateLimited429Last24h: null as number | null,
      byFunction: null as Record<string, number> | null,
      moodyByAction: null as Record<string, number> | null,
      medianDurationMsByFunction: null as Record<string, number> | null,
    };
  }

  type Row = {
    function_slug: string;
    http_status: number;
    operation: string | null;
    duration_ms: number | null;
  };
  const rows = (data ?? []) as Row[];
  const byFunction: Record<string, number> = {};
  const moodyByAction: Record<string, number> = {};
  let rate429 = 0;
  const durationsBySlug: Record<string, number[]> = {};

  for (const r of rows) {
    const slug = r.function_slug || "unknown";
    byFunction[slug] = (byFunction[slug] ?? 0) + 1;
    if (r.http_status === 429) rate429 += 1;
    if (slug === "moody" && r.operation) {
      moodyByAction[r.operation] = (moodyByAction[r.operation] ?? 0) + 1;
    }
    if (!durationsBySlug[slug]) durationsBySlug[slug] = [];
    durationsBySlug[slug].push(Number(r.duration_ms ?? 0));
  }

  const medianDurationMsByFunction: Record<string, number> = {};
  for (const [slug, arr] of Object.entries(durationsBySlug)) {
    if (arr.length === 0) continue;
    const sorted = [...arr].sort((a, b) => a - b);
    medianDurationMsByFunction[slug] = sorted[Math.floor(sorted.length / 2)] ?? 0;
  }

  return {
    available: true as const,
    totalLast24h: rows.length,
    rateLimited429Last24h: rate429,
    byFunction,
    moodyByAction: Object.keys(moodyByAction).length > 0 ? moodyByAction : null,
    medianDurationMsByFunction:
      Object.keys(medianDurationMsByFunction).length > 0 ? medianDurationMsByFunction : null,
  };
}

export async function GET(request: Request) {
  const secret = request.headers.get(ADMIN_HEADER);
  const expected = process.env.WANDERMOOD_ADMIN_SECRET;

  if (!expected || secret !== expected) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = createSupabaseAdmin();
  if (!supabase) {
    return NextResponse.json(
      {
        error:
          "Server missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY. Set them in Vercel env.",
      },
      { status: 500 }
    );
  }

  const now = Date.now();
  const d7 = new Date(now - 7 * 24 * 60 * 60 * 1000).toISOString();
  const d30 = new Date(now - 30 * 24 * 60 * 60 * 1000).toISOString();

  let totalAuthUsers = 0;
  let newUsers7d = 0;
  let newUsers30d = 0;
  const perPage = 1000;
  let page = 1;

  try {
    while (true) {
      const { data, error } = await supabase.auth.admin.listUsers({
        page,
        perPage,
      });
      if (error) {
        return NextResponse.json(
          { error: `Auth listUsers: ${error.message}` },
          { status: 500 }
        );
      }
      const users = data.users;
      totalAuthUsers += users.length;
      for (const u of users) {
        const created = u.created_at;
        if (created >= d7) newUsers7d += 1;
        if (created >= d30) newUsers30d += 1;
      }
      if (users.length < perPage) break;
      page += 1;
      if (page > 100) break;
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: msg }, { status: 500 });
  }

  const [
    profilesCount,
    subscriptionsTotal,
    premiumSubscriptions,
    scheduledActivities,
    checkIns,
    placesCacheRows,
    billing,
    webhookEventsTotal,
    edgeApi,
  ] = await Promise.all([
    safeCount(supabase, "profiles"),
    safeCount(supabase, "subscriptions"),
    (async () => {
      const { count, error } = await supabase
        .from("subscriptions")
        .select("*", { count: "exact", head: true })
        .eq("plan_type", "premium")
        .eq("status", "active");
      if (error) return null;
      return count ?? 0;
    })(),
    safeCount(supabase, "scheduled_activities"),
    safeCount(supabase, "user_check_ins"),
    safeCount(supabase, "places_cache"),
    stripeBillingSnapshot(supabase),
    stripeWebhookEventCount(supabase),
    edgeApiSnapshot(supabase),
  ]);

  return NextResponse.json({
    generatedAt: new Date().toISOString(),
    users: {
      totalAuthUsers,
      newLast7Days: newUsers7d,
      newLast30Days: newUsers30d,
      profilesInDb: profilesCount,
    },
    subscriptions: {
      totalRows: subscriptionsTotal,
      activePremium: premiumSubscriptions,
    },
    activity: {
      scheduledActivitiesTotal: scheduledActivities,
      userCheckInsTotal: checkIns,
      placesCacheRows,
    },
    billing: {
      paymentsLast30Days: billing.paymentsLast30Days,
      revenueLast30DaysCents: billing.revenueLast30DaysCents,
      revenueCurrency: billing.revenueCurrency,
      ...(billing.revenueByCurrencyNote
        ? { note: billing.revenueByCurrencyNote }
        : {}),
      stripeWebhookEventsTotal: webhookEventsTotal,
    },
    edgeApi: {
      available: edgeApi.available,
      totalLast24h: edgeApi.totalLast24h,
      rateLimited429Last24h: edgeApi.rateLimited429Last24h,
      byFunction: edgeApi.byFunction,
      moodyByAction: edgeApi.moodyByAction,
      medianDurationMsByFunction: edgeApi.medianDurationMsByFunction,
    },
    note:
      "Counts reflect your Supabase project. Edge API analytics need migration 20260404200000_edge_api_rate_limit_and_logs.sql + SUPABASE_SERVICE_ROLE_KEY on functions moody, places, weather. Stripe billing: 20260404180000_stripe_billing_foundation.sql.",
  });
}
