import { createClient, type SupabaseClient } from "@supabase/supabase-js";
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

export async function GET(request: Request) {
  const secret = request.headers.get(ADMIN_HEADER);
  const expected = process.env.WANDERMOOD_ADMIN_SECRET;

  if (!expected || secret !== expected) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const url = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceKey) {
    return NextResponse.json(
      {
        error:
          "Server missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY. Set them in Vercel env.",
      },
      { status: 500 }
    );
  }

  const supabase = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

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
    note:
      "Counts reflect your Supabase project. Tables missing or renamed show as null.",
  });
}
