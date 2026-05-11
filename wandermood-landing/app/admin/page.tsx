"use client";

import { useCallback, useEffect, useState } from "react";

const SESSION_KEY = "wm_admin_secret_v1";

type PartnerLeadRow = {
  id: string;
  business_name: string | null;
  business_type: string | null;
  city: string | null;
  contact_email: string | null;
  contact_name: string | null;
  what_they_offer: string | null;
  target_moods: string[] | null;
  status: string | null;
  created_at: string | null;
  google_place_url: string | null;
  business_listing_id: string | null;
};

type BusinessListingRow = {
  id: string;
  business_name: string | null;
  contact_email: string | null;
  city: string | null;
  subscription_status: string | null;
  trial_ends_at: string | null;
  total_views: number | null;
  total_taps: number | null;
  total_offer_redemptions: number | null;
  total_checkins: number | null;
  active_offer: string | null;
  target_moods: string[] | null;
  created_at: string | null;
  stripe_customer_id: string | null;
};

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
  partnerPipeline?: {
    newLeads: number;
    approvedLeads: number;
    total: number;
    leads: PartnerLeadRow[];
  };
  businessListings?: {
    total: number;
    trialing: number;
    active: number;
    inactive: number;
    pastDue: number;
    monthlyRevenue: number;
    listings: BusinessListingRow[];
  };
};

function formatNlDate(iso: string | null): string {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleDateString("nl-NL", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });
  } catch {
    return "—";
  }
}

function leadStatusBadge(status: string | null) {
  const s = status ?? "";
  const base = "inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold";
  if (s === "new")
    return (
      <span className={`${base} bg-amber-500/20 text-amber-300`}>Nieuw</span>
    );
  if (s === "approved")
    return (
      <span className={`${base} bg-emerald-500/20 text-emerald-300`}>Goedgekeurd</span>
    );
  if (s === "rejected")
    return <span className={`${base} bg-zinc-500/20 text-zinc-400`}>Afgewezen</span>;
  if (s === "in_review")
    return (
      <span className={`${base} bg-sky-500/20 text-sky-300`}>In behandeling</span>
    );
  return (
    <span className={`${base} bg-zinc-500/20 text-zinc-400`}>{s || "—"}</span>
  );
}

function listingStatusBadge(status: string | null) {
  const s = status ?? "";
  const base = "inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold";
  if (s === "trialing")
    return (
      <span className={`${base} bg-sky-500/20 text-sky-300`}>Proefperiode</span>
    );
  if (s === "active")
    return (
      <span className={`${base} bg-emerald-500/20 text-emerald-300`}>Actief</span>
    );
  if (s === "past_due")
    return (
      <span className={`${base} bg-red-500/20 text-red-300`}>Achterstallig</span>
    );
  if (s === "inactive")
    return <span className={`${base} bg-zinc-500/20 text-zinc-400`}>Inactief</span>;
  if (s === "canceled" || s === "cancelled")
    return <span className={`${base} bg-zinc-500/20 text-zinc-400`}>Geannuleerd</span>;
  if (s === "pending_approval")
    return (
      <span className={`${base} bg-amber-500/20 text-amber-300`}>Wacht op goedkeuring</span>
    );
  if (s === "paused")
    return <span className={`${base} bg-zinc-500/20 text-zinc-400`}>Gepauzeerd</span>;
  return (
    <span className={`${base} bg-zinc-500/20 text-zinc-400`}>{s || "—"}</span>
  );
}

function listingTrialCell(listing: BusinessListingRow): { text: string; warn: boolean } {
  if (listing.subscription_status !== "trialing") return { text: "—", warn: false };
  const raw = listing.trial_ends_at;
  if (!raw) return { text: "—", warn: false };
  const end = new Date(raw).getTime();
  if (Number.isNaN(end)) return { text: "—", warn: false };
  const days = (end - Date.now()) / (24 * 60 * 60 * 1000);
  const warn = days >= 0 && days < 5;
  return { text: formatNlDate(raw), warn };
}

function truncateOffer(s: string | null, max = 40): string {
  if (!s?.trim()) return "—";
  const t = s.trim();
  return t.length <= max ? t : `${t.slice(0, Math.max(0, max - 1))}…`;
}

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
  sub,
}: {
  label: string;
  value: string | number | null;
  accent?: "green" | "cream" | "sunset" | "orange" | "red" | "grey";
  sub?: string;
}) {
  const display =
    value === null ? "—" : typeof value === "number" ? value.toLocaleString() : value;
  const valueClass =
    accent === "cream"
      ? "text-[var(--wm-cream)]"
      : accent === "sunset"
        ? "text-[var(--wm-sunset)]"
        : accent === "orange"
          ? "text-orange-400"
          : accent === "red"
            ? "text-red-400"
            : accent === "grey"
              ? "text-[var(--wm-muted)]"
              : "text-[var(--wm-green)]";
  return (
    <div className="rounded-xl border border-[var(--wm-border)] bg-[var(--wm-card)] p-5 shadow-sm transition-colors hover:border-[var(--wm-green)]/25">
      <p className="text-[11px] font-semibold uppercase tracking-wider text-[var(--wm-muted)]">
        {label}
      </p>
      <p className={`mt-2 text-2xl font-bold tabular-nums ${valueClass}`}>{display}</p>
      {sub ? <p className="mt-1 text-xs text-[var(--wm-muted)]">{sub}</p> : null}
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
  { id: "partner-b2b", label: "Partner B2B" },
] as const;

export default function AdminPage() {
  const [secret, setSecret] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [stats, setStats] = useState<StatsResponse | null>(null);
  const [approvingId, setApprovingId] = useState<string | null>(null);

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

  const loadStats = useCallback(async () => {
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

  useEffect(() => {
    if (!stats) return;
    const interval = setInterval(() => void loadStats(), 60_000);
    return () => clearInterval(interval);
  }, [stats, loadStats]);

  const handleApprove = async (lead: PartnerLeadRow) => {
    const name = lead.business_name?.trim() || "deze partner";
    if (
      !window.confirm(
        `Weet je zeker dat je ${name} wilt goedkeuren? Er wordt automatisch een account aangemaakt en welkomstmail verstuurd.`
      )
    ) {
      return;
    }
    setApprovingId(lead.id);
    try {
      const res = await fetch("/api/admin/approve-partner", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-admin-secret": secret,
        },
        body: JSON.stringify({ lead_id: lead.id }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        const msg =
          typeof body.error === "string" ? body.error : res.statusText || "Onbekende fout";
        window.alert(`Fout: ${msg}`);
        return;
      }
      window.alert(`✓ ${name} is goedgekeurd!`);
      await loadStats();
    } catch (e) {
      window.alert(`Fout: ${e instanceof Error ? e.message : "Request failed"}`);
    } finally {
      setApprovingId(null);
    }
  };

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
            <div className="flex flex-wrap items-center gap-2">
              {stats ? (
                <>
                  <button
                    type="button"
                    onClick={() => void loadStats()}
                    disabled={loading || !secret.trim()}
                    className="rounded-full border border-[var(--wm-border)] bg-[var(--wm-card)] px-3 py-1 text-xs font-medium text-[var(--wm-cream)] transition-colors hover:border-[var(--wm-green)]/40 disabled:opacity-40"
                  >
                    ↻ Vernieuwen
                  </button>
                  <span className="rounded-full border border-[var(--wm-border)] bg-[var(--wm-card)] px-3 py-1 text-xs text-[var(--wm-muted)]">
                    Updated {new Date(stats.generatedAt).toLocaleString()}
                  </span>
                </>
              ) : null}
            </div>
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
                  if (e.key === "Enter" && secret.trim() && !loading) void loadStats();
                }}
                className="flex-1 rounded-xl border border-[var(--wm-border)] bg-[var(--wm-bg)] px-4 py-3 text-sm text-[var(--wm-cream)] outline-none ring-[var(--wm-green)]/30 placeholder:text-[var(--wm-muted)] focus:border-[var(--wm-green)] focus:ring-2"
              placeholder="Paste admin secret"
            />
            <button
              type="button"
                onClick={() => void loadStats()}
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

              <div
                id="partner-b2b"
                className="scroll-mt-24 border-t-2 border-green-600 pt-8 mt-8"
              >
                <h2 className="text-xl font-bold text-green-600 mb-6">PARTNER B2B</h2>

                {(() => {
                  const pp = stats.partnerPipeline ?? {
                    newLeads: 0,
                    approvedLeads: 0,
                    total: 0,
                    leads: [] as PartnerLeadRow[],
                  };
                  const bl = stats.businessListings ?? {
                    total: 0,
                    trialing: 0,
                    active: 0,
                    inactive: 0,
                    pastDue: 0,
                    monthlyRevenue: 0,
                    listings: [] as BusinessListingRow[],
                  };
                  const activePartners = bl.trialing + bl.active;
                  const attention = bl.inactive + bl.pastDue;

                  return (
                    <>
                      <div className="mb-10 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                        <StatCard
                          label="Nieuwe aanvragen"
                          value={pp.newLeads}
                          accent={pp.newLeads > 0 ? "orange" : "grey"}
                          sub="Wachten op goedkeuring"
                        />
                        <StatCard
                          label="Actieve partners"
                          value={activePartners}
                          accent="green"
                          sub={`${bl.trialing} in proefperiode`}
                        />
                        <StatCard
                          label="Maandelijkse omzet"
                          value={`€${bl.monthlyRevenue}`}
                          accent="green"
                          sub={`${bl.active} betalende partners`}
                        />
                        <StatCard
                          label="Aandacht vereist"
                          value={attention}
                          accent={attention > 0 ? "red" : "grey"}
                          sub="Inactief of betaling mislukt"
                        />
                      </div>

                      <section className="mb-10">
                        <h3 className="mb-3 text-xs font-semibold uppercase tracking-widest text-[var(--wm-muted)]">
                          Partner aanvragen
                        </h3>
                        {pp.leads.length === 0 ? (
                          <p className="text-sm text-[var(--wm-muted)]">Nog geen aanvragen.</p>
                        ) : (
                          <div className="overflow-x-auto rounded-xl border border-[var(--wm-border)] bg-[var(--wm-card)]">
                            <table className="w-full min-w-[720px] border-collapse text-left text-sm">
                              <thead>
                                <tr className="border-b border-[var(--wm-border)] text-[11px] uppercase tracking-wider text-[var(--wm-muted)]">
                                  <th className="px-4 py-3 font-semibold">Bedrijf</th>
                                  <th className="px-4 py-3 font-semibold">Type</th>
                                  <th className="px-4 py-3 font-semibold">Stad</th>
                                  <th className="px-4 py-3 font-semibold">Contact</th>
                                  <th className="px-4 py-3 font-semibold">Datum</th>
                                  <th className="px-4 py-3 font-semibold">Status</th>
                                  <th className="px-4 py-3 font-semibold">Actie</th>
                                </tr>
                              </thead>
                              <tbody>
                                {pp.leads.map((lead) => (
                                  <tr
                                    key={lead.id}
                                    className="border-b border-[var(--wm-border)] border-opacity-50 last:border-0"
                                  >
                                    <td className="px-4 py-3 font-semibold text-[var(--wm-cream)]">
                                      {lead.business_name ?? "—"}
                                    </td>
                                    <td className="px-4 py-3 text-[var(--wm-muted)]">
                                      {lead.business_type ?? "—"}
                                    </td>
                                    <td className="px-4 py-3 text-[var(--wm-muted)]">
                                      {lead.city ?? "—"}
                                    </td>
                                    <td className="px-4 py-3">
                                      {lead.contact_email ? (
                                        <a
                                          href={`mailto:${lead.contact_email}`}
                                          className="text-[var(--wm-green)] underline-offset-2 hover:underline"
                                        >
                                          {lead.contact_email}
                                        </a>
                                      ) : (
                                        "—"
                                      )}
                                    </td>
                                    <td className="px-4 py-3 tabular-nums text-[var(--wm-muted)]">
                                      {formatNlDate(lead.created_at)}
                                    </td>
                                    <td className="px-4 py-3">{leadStatusBadge(lead.status)}</td>
                                    <td className="px-4 py-3">
                                      {lead.status === "new" ? (
                                        <button
                                          type="button"
                                          disabled={approvingId !== null}
                                          onClick={() => void handleApprove(lead)}
                                          className="rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white transition-opacity hover:opacity-90 disabled:opacity-40"
                                        >
                                          {approvingId === lead.id
                                            ? "Bezig…"
                                            : "Goedkeuren →"}
                                        </button>
                                      ) : (
                                        "—"
                                      )}
                                    </td>
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                          </div>
                        )}
                      </section>

                      <section>
                        <h3 className="mb-3 text-xs font-semibold uppercase tracking-widest text-[var(--wm-muted)]">
                          Actieve vermeldingen
                        </h3>
                        {bl.listings.length === 0 ? (
                          <p className="text-sm text-[var(--wm-muted)]">Nog geen vermeldingen.</p>
                        ) : (
                          <div className="overflow-x-auto rounded-xl border border-[var(--wm-border)] bg-[var(--wm-card)]">
                            <table className="w-full min-w-[880px] border-collapse text-left text-sm">
                              <thead>
                                <tr className="border-b border-[var(--wm-border)] text-[11px] uppercase tracking-wider text-[var(--wm-muted)]">
                                  <th className="px-4 py-3 font-semibold">Bedrijf</th>
                                  <th className="px-4 py-3 font-semibold">Stad</th>
                                  <th className="px-4 py-3 font-semibold">Status</th>
                                  <th className="px-4 py-3 font-semibold">Proef eindigt</th>
                                  <th className="px-4 py-3 font-semibold">Views</th>
                                  <th className="px-4 py-3 font-semibold">Tikken</th>
                                  <th className="px-4 py-3 font-semibold">Aanbieding</th>
                                </tr>
                              </thead>
                              <tbody>
                                {bl.listings.map((listing) => {
                                  const trial = listingTrialCell(listing);
                                  return (
                                    <tr
                                      key={listing.id}
                                      className="border-b border-[var(--wm-border)] border-opacity-50 last:border-0"
                                    >
                                      <td className="px-4 py-3 font-semibold text-[var(--wm-cream)]">
                                        {listing.business_name ?? "—"}
                                      </td>
                                      <td className="px-4 py-3 text-[var(--wm-muted)]">
                                        {listing.city ?? "—"}
                                      </td>
                                      <td className="px-4 py-3">
                                        {listingStatusBadge(listing.subscription_status)}
                                      </td>
                                      <td
                                        className={`px-4 py-3 tabular-nums ${trial.warn ? "font-medium text-red-400" : "text-[var(--wm-muted)]"}`}
                                      >
                                        {trial.text}
                                      </td>
                                      <td className="px-4 py-3 tabular-nums text-[var(--wm-muted)]">
                                        {listing.total_views?.toLocaleString() ?? "0"}
                                      </td>
                                      <td className="px-4 py-3 tabular-nums text-[var(--wm-muted)]">
                                        {listing.total_taps?.toLocaleString() ?? "0"}
                                      </td>
                                      <td className="max-w-[200px] truncate px-4 py-3 text-[var(--wm-muted)]" title={listing.active_offer ?? undefined}>
                                        {truncateOffer(listing.active_offer)}
                                      </td>
                                    </tr>
                                  );
                                })}
                              </tbody>
                            </table>
                          </div>
                        )}
                      </section>
                    </>
                  );
                })()}
              </div>

              <p className="border-t border-[var(--wm-border)] pt-8 text-xs leading-relaxed text-[var(--wm-muted)]">
                {stats.note}
              </p>
          </div>
        ) : null}
      </main>
      </div>

      <nav className="fixed bottom-0 left-0 right-0 z-50 flex justify-around border-t border-[var(--wm-border)] bg-[var(--wm-card)] py-2 md:hidden">
        {navSections.slice(0, 5).map(({ id, label }) => (
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
