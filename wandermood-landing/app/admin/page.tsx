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
  note: string;
};

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
