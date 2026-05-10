import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  const adminSecret = req.headers.get("x-admin-secret");
  if (adminSecret !== process.env.WANDERMOOD_ADMIN_SECRET) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await req.json().catch(() => ({}));
  const lead_id = body?.lead_id as string | undefined;
  if (!lead_id) {
    return NextResponse.json({ error: "lead_id required" }, { status: 400 });
  }

  // Same value as Supabase Edge secret ADMIN_SECRET (partner-onboard). Optional
  // fallback: if you use one shared operator secret everywhere, set only
  // WANDERMOOD_ADMIN_SECRET on Vercel to match Supabase ADMIN_SECRET.
  const adminSecret2 =
    process.env.ADMIN_SECRET ?? process.env.WANDERMOOD_ADMIN_SECRET;
  if (!adminSecret2) {
    return NextResponse.json(
      {
        error:
          "ADMIN_SECRET not configured (set to match Supabase Edge Functions ADMIN_SECRET, or set WANDERMOOD_ADMIN_SECRET to that same value)",
      },
      { status: 500 }
    );
  }

  const supabaseUrl =
    process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!supabaseUrl) {
    return NextResponse.json(
      { error: "SUPABASE_URL not configured" },
      { status: 500 }
    );
  }

  const res = await fetch(`${supabaseUrl}/functions/v1/partner-onboard`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-admin-secret": adminSecret2,
    },
    body: JSON.stringify({ lead_id }),
  });

  const data = (await res.json().catch(() => ({}))) as { error?: string };
  if (!res.ok) {
    return NextResponse.json(
      { error: data.error ?? "Onboarding failed" },
      { status: res.status }
    );
  }

  return NextResponse.json({ success: true, ...data });
}
