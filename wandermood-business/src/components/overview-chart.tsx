"use client";

import {
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { format, parseISO } from "date-fns";
import { nl } from "date-fns/locale";

export type AnalyticsRow = { date: string; views: number; taps: number };

export function OverviewChart({ data }: { data: AnalyticsRow[] }) {
  if (data.length === 0) {
    return (
      <div className="flex min-h-[280px] items-center justify-center rounded-xl border border-[var(--wm-border)] bg-wm-card p-8 text-center text-sm text-muted-foreground">
        Analytics worden bijgehouden vanaf je eerste dag. Je ziet hier
        binnenkort data.
      </div>
    );
  }

  const chartData = data.map((row) => ({
    ...row,
    label: format(parseISO(row.date), "d MMM", { locale: nl }),
  }));

  return (
    <div className="h-[300px] w-full rounded-xl border border-[var(--wm-border)] bg-wm-card p-4">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={chartData} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
          <CartesianGrid stroke="rgba(245,240,232,0.06)" strokeDasharray="3 3" />
          <XAxis
            dataKey="label"
            tick={{ fill: "var(--wm-muted)", fontSize: 11 }}
            tickLine={false}
            axisLine={{ stroke: "var(--wm-border)" }}
          />
          <YAxis
            tick={{ fill: "var(--wm-muted)", fontSize: 11 }}
            tickLine={false}
            axisLine={{ stroke: "var(--wm-border)" }}
            allowDecimals={false}
          />
          <Tooltip
            contentStyle={{
              background: "var(--wm-card)",
              border: "1px solid var(--wm-border)",
              borderRadius: 8,
            }}
            labelStyle={{ color: "var(--wm-cream)" }}
          />
          <Legend />
          <Line
            type="monotone"
            dataKey="views"
            name="Weergaven"
            stroke="var(--wm-forest)"
            strokeWidth={2}
            dot={false}
          />
          <Line
            type="monotone"
            dataKey="taps"
            name="Tikken"
            stroke="var(--wm-sunset)"
            strokeWidth={2}
            dot={false}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
