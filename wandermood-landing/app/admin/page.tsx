"use client";

import { useCallback, useEffect, useState } from "react";

const SESSION_KEY = "wm_admin_secret_v1";

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
  accent = "green",
}: {
  label: string;
  value: string | number | null;
  accent?: "green" | "cream" | "sunset";
}) {
  const display =
    value === null ? "—" : typeof value === "number" ? value.toLocaleString() : value;
  const valueClass =
    accent === "cream"
      ? "text-[var(--wm-cream)]"
      : accent === "sunset"
        ? "text-[var(--wm-sunset)]"
        : "text-[var(--wm-green)]";
  return (
    <div className="rounded-xl border border-[var(--wm-border)] bg-[var(--wm-card)] p-5 shadow-sm transition-colors hover:border-[var(--wm-green)]/25">
      <p className="text-[11px] font-semibold uppercase tracking-wider text-[var(--wm-muted)]">
        {label}
      </p>
      <p className={`mt-2 text-2xl font-bold tabular-nums ${valueClass}`}>{display}</p>
    </div>
  );
}

const navSections = [
  { id: "overview", label: "Overview" },
  { id: "users", label: "Users" },
  { id: "subscriptions", label: "Subscriptions" },
  { id: "edge-api", label: "Edge API" },
  { id: "billing", label: "Billing" },
  { id: "activity", label: "Product activity" },
] as const;

export default function AdminPage() {
  const [secret, setSecret] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [stats, setStats] = useState<StatsResponse | null>(null);

  useEffect(() => {
    try {
      const s = sessionStorage.getItem(SESSION_KEY);
      if (s) setSecret(s);
    } catch {
      /* private mode */
    }
  }, []);

  useEffect(() => {
    if (!secret.trim()) return;
    try {
      sessionStorage.setItem(SESSION_KEY, secret);
    } catch {
      /* */
    }
  }, [secret]);

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

  const scrollToId = (id: string) => {
    document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  return (
    <div className="flex min-h-screen">
      <aside className="fixed left-0 top-0 z-40 hidden h-full w-56 flex-col border-r border-[var(--wm-border)] bg-[var(--wm-card)] md:flex">
        <div className="border-b border-[var(--wm-border)] p-4">
          <div className="text-xl font-bold tracking-tight text-[var(--wm-cream)]">WanderMood</div>
          <p className="mt-1 text-xs text-[var(--wm-muted)]">Operator console</p>
        </div>
        <nav className="flex flex-1 flex-col gap-0.5 overflow-y-auto p-3">
          {navSections.map(({ id, label }) => (
            <button
              key={id}
              type="button"
              onClick={() => scrollToId(id)}
              className="rounded-lg px-3 py-2 text-left text-sm font-medium text-[var(--wm-muted)] transition-colors hover:bg-[var(--wm-elevated)] hover:text-[var(--wm-cream)]"
            >
              {label}
            </button>
          ))}
        </nav>
        <div className="border-t border-[var(--wm-border)] p-3 text-xs">
          <a
            href="https://wandermood.com"
            className="block rounded-lg px-3 py-2 text-[var(--wm-muted)] transition-colors hover:bg-[var(--wm-elevated)] hover:text-[var(--wm-green)]"
          >
            ← Marketing site
          </a>
          <a
            href="https://business.wandermood.com"
            className="mt-1 block rounded-lg px-3 py-2 text-[var(--wm-muted)] transition-colors hover:bg-[var(--wm-elevated)] hover:text-[var(--wm-green)]"
          >
            Partner portal
          </a>
        </div>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col md:pl-56">
        <header className="sticky top-0 z-30 border-b border-[var(--wm-border)] bg-[var(--wm-bg)]/90 px-4 py-4 backdrop-blur-md">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h1 className="text-lg font-semibold text-[var(--wm-cream)]">Platform health</h1>
              <p className="text-xs text-[var(--wm-muted)]">
                Supabase + Edge + Stripe — same visual language as the partner dashboard.
              </p>
            </div>
            {stats ? (
              <span className="rounded-full border border-[var(--wm-border)] bg-[var(--wm-card)] px-3 py-1 text-xs text-[var(--wm-muted)]">
                Updated {new Date(stats.generatedAt).toLocaleString()}
              </span>
            ) : null}
          </div>
        </header>

        <main className="flex-1 px-4 py-6 pb-24 md:px-8 md:py-8 md:pb-8">
          <div
            id="unlock"
            className="rounded-xl border border-[var(--wm-border)] bg-[var(--wm-card)] p-6 shadow-lg shadow-black/20"
          >
            <label htmlFor="admin-secret" className="block text-sm font-medium text-[var(--wm-cream)]">
              Admin secret
            </label>
            <p className="mt-1 text-xs text-[var(--wm-muted)]">
              Set{" "}
              <code className="rounded bg-[var(--wm-elevated)] px-1.5 py-0.5 text-[var(--wm-green)]">
                WANDERMOOD_ADMIN_SECRET
              </code>{" "}
              in Vercel. Stored in this browser tab only (session) after you type it — not sent anywhere except
              your own API.
            </p>
            <div className="mt-4 flex flex-col gap-3 sm:flex-row">
              <input
                id="admin-secret"
                type="password"
                autoComplete="off"
                value={secret}
                onChange={(e) => setSecret(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && secret.trim() && !loading) void load();
                }}
                className="flex-1 rounded-xl border border-[var(--wm-border)] bg-[var(--wm-bg)] px-4 py-3 text-sm text-[var(--wm-cream)] outline-none ring-[var(--wm-green)]/30 placeholder:text-[var(--wm-muted)] focus:border-[var(--wm-green)] focus:ring-2"
                placeholder="Paste admin secret"
              />
              <button
                type="button"
                onClick={() => void load()}
                disabled={loading || !secret.trim()}
                className="rounded-xl bg-[var(--wm-forest)] px-6 py-3 text-sm font-semibold text-[var(--wm-cream)] transition-opacity hover:opacity-90 disabled:opacity-40"
              >
                {loading ? "Loading…" : "Load stats"}
              </button>
            </div>
            {error ? (
              <p className="mt-4 rounded-lg border border-red-500/30 bg-red-500/10 px-3 py-2 text-sm text-red-200">
                {error}
              </p>
            ) : null}
          </div>

          {stats ? (
            <div className="mt-10 space-y-12">
              <section id="overview" className="scroll-mt-24">
                <h2 className="mb-4 text-xs font-semibold uppercase tracking-widest text-[var(--wm-muted)]">
                  At a glance
                </h2>
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                  <StatCard label="Registered users (auth)" value={stats.users.totalAuthUsers} />
                  <StatCard label="New signups — 7 days" value={stats.users.newLast7Days} accent="sunset" />
                  <StatCard
                    label="Edge calls — 24h"
                    value={stats.edgeApi.available ? stats.edgeApi.totalLast24h : "—"}
                  />
                  <StatCard
                    label="Revenue — 30 days"
                    value={formatMoneyCents(
                      stats.billing.revenueLast30DaysCents,
                      stats.billing.revenueCurrency
                    )}
                    accent="cream"
                  />
                </div>
              </section>

              <section id="users" className="scroll-mt-24">
                <h2 className="mb-4 text-xs font-semibold uppercase tracking-widest text-[var(--wm-muted)]">
                  Users
                </h2>
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                  <StatCard label="Registered (auth)" value={stats.users.totalAuthUsers} />
                  <StatCard label="New — last 7 days" value={stats.users.newLast7Days} />
                  <StatCard label="New — last 30 days" value={stats.users.newLast30Days} />
                  <StatCard label="Profiles row count" value={stats.users.profilesInDb} />
                </div>
              </section>

              <section id="subscriptions" className="scroll-mt-24">
                <h2 className="mb-4 text-xs font-semibold uppercase tracking-widest text-[var(--wm-muted)]">
                  Subscriptions
                </h2>
                <div className="grid gap-4 sm:grid-cols-2">
                  <StatCard label="Subscription rows" value={stats.subscriptions.totalRows} />
                  <StatCard label="Active premium" value={stats.subscriptions.activePremium} />
                </div>
              </section>

              <section id="edge-api" className="scroll-mt-24">
                <h2 className="mb-4 text-xs font-semibold uppercase tracking-widest text-[var(--wm-muted)]">
                  Edge API
                </h2>
                <details className="mb-4 rounded-xl border border-[var(--wm-border)] bg-[var(--wm-card)] px-4 py-3 text-xs text-[var(--wm-muted)] open:pb-4">
                  <summary className="cursor-pointer select-none text-[var(--wm-cream)]">
                    Setup & env hints
                  </summary>
                  <p className="mt-3 leading-relaxed">
                    Logged from Supabase Edge Functions{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1 text-[var(--wm-green)]">moody</code>,{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1 text-[var(--wm-green)]">places</code>,{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1 text-[var(--wm-green)]">weather</code>.
                    Set{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1">SUPABASE_SERVICE_ROLE_KEY</code> on
                    each function. Optional:{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1">EDGE_RATE_MOODY_PER_MINUTE</code>{" "}
                    (60),{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1">EDGE_RATE_PLACES_PER_MINUTE</code>{" "}
                    (120),{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1">EDGE_RATE_WEATHER_PER_MINUTE</code>{" "}
                    (60).
                  </p>
                </details>
                {!stats.edgeApi.available ? (
                  <p className="text-sm text-[var(--wm-muted)]">
                    No{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1 text-[var(--wm-green)]">
                      api_invocations
                    </code>{" "}
                    table yet — apply migration{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1">
                      20260404200000_edge_api_rate_limit_and_logs.sql
                    </code>
                    .
                  </p>
                ) : (
                  <>
                    <div className="grid gap-4 sm:grid-cols-2">
                      <StatCard label="Logged calls — last 24h" value={stats.edgeApi.totalLast24h} />
                      <StatCard
                        label="Rate limited (429) — last 24h"
                        value={stats.edgeApi.rateLimited429Last24h}
                        accent="sunset"
                      />
                    </div>
                    {stats.edgeApi.byFunction && Object.keys(stats.edgeApi.byFunction).length > 0 ? (
                      <div className="mt-4 rounded-xl border border-[var(--wm-border)] bg-[var(--wm-card)] p-5">
                        <p className="text-[11px] font-semibold uppercase tracking-wider text-[var(--wm-muted)]">
                          By function (24h)
                        </p>
                        <ul className="mt-3 space-y-2 text-sm">
                          {Object.entries(stats.edgeApi.byFunction)
                            .sort((a, b) => b[1] - a[1])
                            .map(([name, count]) => {
                              const med =
                                stats.edgeApi.medianDurationMsByFunction?.[name] ?? null;
                              const medLabel =
                                med != null ? ` · median ${med.toLocaleString()} ms` : "";
                              return (
                                <li
                                  key={name}
                                  className="flex justify-between gap-4 border-b border-[var(--wm-border)] border-opacity-50 py-2 last:border-0 tabular-nums"
                                >
                                  <span className="font-medium text-[var(--wm-cream)]">{name}</span>
                                  <span className="text-[var(--wm-muted)]">
                                    {count.toLocaleString()}
                                    {medLabel}
                                  </span>
                                </li>
                              );
                            })}
                        </ul>
                      </div>
                    ) : (
                      <p className="mt-4 text-sm text-[var(--wm-muted)]">No calls logged in the last 24 hours.</p>
                    )}
                    {stats.edgeApi.moodyByAction &&
                    Object.keys(stats.edgeApi.moodyByAction).length > 0 ? (
                      <div className="mt-4 rounded-xl border border-[var(--wm-border)] bg-[var(--wm-card)] p-5">
                        <p className="text-[11px] font-semibold uppercase tracking-widest text-[var(--wm-muted)]">
                          Moody — by action (24h)
                        </p>
                        <ul className="mt-3 space-y-2 text-sm">
                          {Object.entries(stats.edgeApi.moodyByAction)
                            .sort((a, b) => b[1] - a[1])
                            .map(([action, count]) => (
                              <li
                                key={action}
                                className="flex justify-between gap-4 border-b border-[var(--wm-border)] py-2 last:border-0 tabular-nums"
                              >
                                <span className="text-[var(--wm-cream)]">{action}</span>
                                <span className="text-[var(--wm-muted)]">{count.toLocaleString()}</span>
                              </li>
                            ))}
                        </ul>
                      </div>
                    ) : null}
                  </>
                )}
              </section>

              <section id="billing" className="scroll-mt-24">
                <h2 className="mb-4 text-xs font-semibold uppercase tracking-widest text-[var(--wm-muted)]">
                  Billing (Stripe)
                </h2>
                <details className="mb-4 rounded-xl border border-[var(--wm-border)] bg-[var(--wm-card)] px-4 py-3 text-xs text-[var(--wm-muted)] open:pb-4">
                  <summary className="cursor-pointer select-none text-[var(--wm-cream)]">
                    Webhook setup
                  </summary>
                  <p className="mt-3 leading-relaxed">
                    From{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1 text-[var(--wm-green)]">
                      billing_payments
                    </code>{" "}
                    after webhooks. Set{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1">STRIPE_SECRET_KEY</code>,{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1">STRIPE_WEBHOOK_SECRET</code> in Vercel;
                    endpoint{" "}
                    <code className="rounded bg-[var(--wm-elevated)] px-1">/api/stripe/webhook</code>.
                  </p>
                </details>
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                  <StatCard label="Paid invoices — last 30 days" value={stats.billing.paymentsLast30Days} />
                  <StatCard
                    label="Revenue — last 30 days (largest currency)"
                    value={formatMoneyCents(
                      stats.billing.revenueLast30DaysCents,
                      stats.billing.revenueCurrency
                    )}
                    accent="cream"
                  />
                  <StatCard
                    label="Stripe webhook events (all time)"
                    value={stats.billing.stripeWebhookEventsTotal}
                  />
                </div>
                {stats.billing.note ? (
                  <p className="mt-3 text-xs text-[var(--wm-sunset)]">{stats.billing.note}</p>
                ) : null}
              </section>

              <section id="activity" className="scroll-mt-24">
                <h2 className="mb-4 text-xs font-semibold uppercase tracking-widest text-[var(--wm-muted)]">
                  Product activity
                </h2>
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                  <StatCard label="Scheduled activities" value={stats.activity.scheduledActivitiesTotal} />
                  <StatCard label="Mood check-ins" value={stats.activity.userCheckInsTotal} />
                  <StatCard label="Places cache rows" value={stats.activity.placesCacheRows} />
                </div>
              </section>

              <p className="border-t border-[var(--wm-border)] pt-8 text-xs leading-relaxed text-[var(--wm-muted)]">
                {stats.note}
              </p>
            </div>
          ) : null}
        </main>
      </div>

      <nav className="fixed bottom-0 left-0 right-0 z-50 flex justify-around border-t border-[var(--wm-border)] bg-[var(--wm-card)] py-2 md:hidden">
        {navSections.slice(0, 4).map(({ id, label }) => (
          <button
            key={id}
            type="button"
            onClick={() => scrollToId(id)}
            className="px-2 py-1 text-[10px] font-medium text-[var(--wm-muted)]"
          >
            {label.split(" ")[0]}
          </button>
        ))}
      </nav>
    </div>
  );
}
