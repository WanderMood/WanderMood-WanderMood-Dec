import { createClient } from "@supabase/supabase-js";
import { NextResponse } from "next/server";

const SHOW_USERS_THRESHOLD = 200;
const SHOW_PARTNERS_THRESHOLD = 5;

const CACHE_HEADER = "public, s-maxage=300, stale-while-revalidate=600";

export async function GET() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) {
    return NextResponse.json(
      { users: null, partners: null, show: false },
      { headers: { "Cache-Control": CACHE_HEADER } },
    );
  }

  const supabase = createClient(url, key, {
    auth: { persistSession: false },
  });

  const [usersRes, partnersRes] = await Promise.all([
    supabase.from("profiles").select("id", { count: "exact", head: true }),
    supabase
      .from("business_listings")
      .select("id", { count: "exact", head: true })
      .in("subscription_status", ["active", "trial"]),
  ]);

  const userCount = usersRes.count ?? 0;
  const partnerCount = partnersRes.count ?? 0;

  return NextResponse.json(
    {
      users: userCount >= SHOW_USERS_THRESHOLD ? userCount : null,
      partners: partnerCount >= SHOW_PARTNERS_THRESHOLD ? partnerCount : null,
      show: userCount >= SHOW_USERS_THRESHOLD,
    },
    { headers: { "Cache-Control": CACHE_HEADER } },
  );
}
