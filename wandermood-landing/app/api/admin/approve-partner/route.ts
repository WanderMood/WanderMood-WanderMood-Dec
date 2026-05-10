import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  const secret =
    req.headers.get("x-admin-secret") ??
    req.headers.get("authorization")?.replace("Bearer ", "");

  const isValid =
    secret === process.env.WANDERMOOD_ADMIN_SECRET ||
    secret === process.env.ADMIN_SECRET;

  if (!isValid) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  if (!process.env.ADMIN_SECRET) {
    return NextResponse.json(
      { error: "ADMIN_SECRET not configured on server" },
      { status: 500 }
    );
  }

  const body = await req.json().catch(() => ({}));
  const lead_id = body?.lead_id as string | undefined;
  if (!lead_id) {
    return NextResponse.json({ error: "lead_id required" }, { status: 400 });
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
      "x-admin-secret": process.env.ADMIN_SECRET,
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
