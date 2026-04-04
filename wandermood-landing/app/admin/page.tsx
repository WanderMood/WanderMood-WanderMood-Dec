"use client";

import { useCallback, useState } from "react";

type StatsResponse = {
  generatedAt: string;
  users: {
    totalAuthUsers: number;
    newLast7Days: number;
    newLast30Days: number;
    profilesInDb: number | null;
  };
  subscriptions: {
    totalRows: number | null;
    activePremium: number | null;
  };
  activity: {
    scheduledActivitiesTotal: number | null;
    userCheckInsTotal: number | null;
    placesCacheRows: number | null;
  };
  billing: {
    paymentsLast30Days: number | null;
    revenueLast30DaysCents: number | null;
    revenueCurrency: string | null;
    note?: string;
    stripeWebhookEventsTotal: number | null;
  };
  edgeApi: {
    available: boolean;
    totalLast24h: number | null;
    rateLimited429Last24h: number | null;
    byFunction: Record<string, number> | null;
    moodyByAction: Record<string, number> | null;
    medianDurationMsByFunction: Record<string, number> | null;
  };
  note: string;
};

function formatMoneyCents(cents: number | null, currency: string | null): string {
  if (cents === null) return "—";
  const cur = (currency ?? "usd").toUpperCase();
  try {
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: cur,
    }).format(cents / 100);
  } catch {
    return `${(cents / 100).toFixed(2)} ${cur}`;
  }
}

function StatCard({
  label,
  value,
}: {
  label: string;
  value: string | number | null;
}) {
  const display = value === null ? "—" : typeof value === "number" ? value.toLocaleString() : value;
  return (
    <div className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
      <p className="text-xs font-medium uppercase tracking-wide text-zinc-500">{label}</p>
      <p className="mt-2 text-2xl font-semibold tabular-nums text-zinc-900">{display}</p>
    </div>
  );
}

export default function AdminPage() {
  const [secret, setSecret] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [stats, setStats] = useState<StatsResponse | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/stats", {
        headers: { "x-wandermood-admin": secret },
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(typeof body.error === "string" ? body.error : res.statusText);
        setStats(null);
        return;
      }
      setStats(body as StatsResponse);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Request failed");
      setStats(null);
    } finally {
      setLoading(false);
    }
  }, [secret]);

  return (
    <div className="min-h-screen bg-zinc-50 text-zinc-900">
      <header className="border-b border-zinc-200 bg-white">
        <div className="mx-auto flex max-w-3xl flex-col gap-4 px-4 py-8 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="text-xl font-semibold tracking-tight">WanderMood admin</h1>
            <p className="mt-1 text-sm text-zinc-600">
              User and usage totals from Supabase (not in the public app).
            </p>
          </div>
          <a
            href="https://wandermood.com"
            className="text-sm font-medium text-emerald-800 hover:underline"
          >
            ← wandermood.com
          </a>
        </div>
      </header>

      <main className="mx-auto max-w-3xl px-4 py-8">
        <div className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
          <label htmlFor="admin-secret" className="block text-sm font-medium text-zinc-700">
            Admin secret
          </label>
          <p className="mt-1 text-xs text-zinc-500">
            Set <code className="rounded bg-zinc-100 px-1">WANDERMOOD_ADMIN_SECRET</code> in Vercel.
            Never share it or commit it.
          </p>
          <div className="mt-3 flex flex-col gap-3 sm:flex-row">
            <input
              id="admin-secret"
              type="password"
              autoComplete="off"
              value={secret}
              onChange={(e) => setSecret(e.target.value)}
              className="flex-1 rounded-xl border border-zinc-300 bg-zinc-50 px-4 py-2.5 text-sm outline-none ring-emerald-800/20 focus:border-emerald-800 focus:ring-2"
              placeholder="Paste admin secret"
            />
            <button
              type="button"
              onClick={() => void load()}
              disabled={loading || !secret.trim()}
              className="rounded-xl bg-emerald-900 px-5 py-2.5 text-sm font-semibold text-white disabled:opacity-50"
            >
              {loading ? "Loading…" : "Load stats"}
            </button>
          </div>
          {error ? (
            <p className="mt-4 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-800">{error}</p>
          ) : null}
        </div>

        {stats ? (
          <div className="mt-8 space-y-8">
            <p className="text-xs text-zinc-500">
              Updated {new Date(stats.generatedAt).toLocaleString()}
            </p>

            <section>
              <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-zinc-500">
                Users
              </h2>
              <div className="grid gap-3 sm:grid-cols-2">
                <StatCard label="Registered (auth)" value={stats.users.totalAuthUsers} />
                <StatCard label="New — last 7 days" value={stats.users.newLast7Days} />
                <StatCard label="New — last 30 days" value={stats.users.newLast30Days} />
                <StatCard label="Profiles row count" value={stats.users.profilesInDb} />
              </div>
            </section>

            <section>
              <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-zinc-500">
                Subscriptions
              </h2>
              <div className="grid gap-3 sm:grid-cols-2">
                <StatCard label="Subscription rows" value={stats.subscriptions.totalRows} />
                <StatCard label="Active premium" value={stats.subscriptions.activePremium} />
              </div>
            </section>

            <section>
              <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-zinc-500">
                Edge API (rate limit + calls)
              </h2>
              <p className="mb-3 text-xs text-zinc-500">
                Logged from Supabase Edge Functions <code className="rounded bg-zinc-100 px-1">moody</code>,{" "}
                <code className="rounded bg-zinc-100 px-1">places</code>, <code className="rounded bg-zinc-100 px-1">weather</code>.
                Set secret <code className="rounded bg-zinc-100 px-1">SUPABASE_SERVICE_ROLE_KEY</code> on each function.
                Optional env: <code className="rounded bg-zinc-100 px-1">EDGE_RATE_MOODY_PER_MINUTE</code> (default 60),{" "}
                <code className="rounded bg-zinc-100 px-1">EDGE_RATE_PLACES_PER_MINUTE</code> (120),{" "}
                <code className="rounded bg-zinc-100 px-1">EDGE_RATE_WEATHER_PER_MINUTE</code> (60).
              </p>
              {!stats.edgeApi.available ? (
                <p className="text-sm text-zinc-600">
                  No <code className="rounded bg-zinc-100 px-1">api_invocations</code> table yet — apply migration{" "}
                  <code className="rounded bg-zinc-100 px-1">20260404200000_edge_api_rate_limit_and_logs.sql</code>.
                </p>
              ) : (
                <>
                  <div className="grid gap-3 sm:grid-cols-2">
                    <StatCard label="Logged calls — last 24h" value={stats.edgeApi.totalLast24h} />
                    <StatCard label="Rate limited (429) — last 24h" value={stats.edgeApi.rateLimited429Last24h} />
                  </div>
                  {stats.edgeApi.byFunction && Object.keys(stats.edgeApi.byFunction).length > 0 ? (
                    <div className="mt-4 rounded-xl border border-zinc-200 bg-white p-4">
                      <p className="text-xs font-semibold uppercase tracking-wide text-zinc-500">
                        By function (24h)
                      </p>
                      <ul className="mt-2 space-y-1 text-sm">
                        {Object.entries(stats.edgeApi.byFunction)
                          .sort((a, b) => b[1] - a[1])
                          .map(([name, count]) => {
                            const med =
                              stats.edgeApi.medianDurationMsByFunction?.[name] ?? null;
                            const medLabel =
                              med != null ? ` · median ${med.toLocaleString()} ms` : "";
                            return (
                              <li key={name} className="flex justify-between gap-4 tabular-nums">
                                <span className="font-medium text-zinc-800">{name}</span>
                                <span className="text-zinc-600">
                                  {count.toLocaleString()}
                                  {medLabel}
                                </span>
                              </li>
                            );
                          })}
                      </ul>
                    </div>
                  ) : (
                    <p className="mt-3 text-sm text-zinc-600">No calls logged in the last 24 hours.</p>
                  )}
                  {stats.edgeApi.moodyByAction && Object.keys(stats.edgeApi.moodyByAction).length > 0 ? (
                    <div className="mt-4 rounded-xl border border-zinc-200 bg-white p-4">
                      <p className="text-xs font-semibold uppercase tracking-wide text-zinc-500">
                        Moody — by action (24h)
                      </p>
                      <ul className="mt-2 space-y-1 text-sm">
                        {Object.entries(stats.edgeApi.moodyByAction)
                          .sort((a, b) => b[1] - a[1])
                          .map(([action, count]) => (
                            <li key={action} className="flex justify-between gap-4 tabular-nums">
                              <span className="text-zinc-800">{action}</span>
                              <span className="text-zinc-600">{count.toLocaleString()}</span>
                            </li>
                          ))}
                      </ul>
                    </div>
                  ) : null}
                </>
              )}
            </section>

            <section>
              <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-zinc-500">
                Billing (Stripe)
              </h2>
              <p className="mb-3 text-xs text-zinc-500">
                From <code className="rounded bg-zinc-100 px-1">billing_payments</code> after webhooks.
                Set <code className="rounded bg-zinc-100 px-1">STRIPE_SECRET_KEY</code>,{" "}
                <code className="rounded bg-zinc-100 px-1">STRIPE_WEBHOOK_SECRET</code> in Vercel and point Stripe to{" "}
                <code className="rounded bg-zinc-100 px-1">/api/stripe/webhook</code>.
              </p>
              <div className="grid gap-3 sm:grid-cols-2">
                <StatCard
                  label="Paid invoices — last 30 days"
                  value={stats.billing.paymentsLast30Days}
                />
                <StatCard
                  label="Revenue — last 30 days (largest currency)"
                  value={formatMoneyCents(
                    stats.billing.revenueLast30DaysCents,
                    stats.billing.revenueCurrency
                  )}
                />
                <StatCard
                  label="Stripe webhook events (all time)"
                  value={stats.billing.stripeWebhookEventsTotal}
                />
              </div>
              {stats.billing.note ? (
                <p className="mt-2 text-xs text-amber-800">{stats.billing.note}</p>
              ) : null}
            </section>

            <section>
              <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-zinc-500">
                Product activity (proxies)
              </h2>
              <div className="grid gap-3 sm:grid-cols-2">
                <StatCard label="Scheduled activities" value={stats.activity.scheduledActivitiesTotal} />
                <StatCard label="Mood check-ins" value={stats.activity.userCheckInsTotal} />
                <StatCard label="Places cache rows" value={stats.activity.placesCacheRows} />
              </div>
            </section>

            <p className="text-xs text-zinc-500">{stats.note}</p>
          </div>
        ) : null}
      </main>
    </div>
  );
}
