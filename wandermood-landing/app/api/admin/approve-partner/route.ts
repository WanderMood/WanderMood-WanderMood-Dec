import {
  isOperatorSecretValid,
  parseClientAdminSecret,
  readTrimmedEnv,
} from "@/lib/admin-auth";
import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  const provided = parseClientAdminSecret(req.headers);
  if (!isOperatorSecretValid(provided)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
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

  // Edge Functions verify JWT at the gateway; anon or service_role is required to invoke.
  const supabaseJwt =
    readTrimmedEnv("SUPABASE_SERVICE_ROLE_KEY") ??
    readTrimmedEnv("SUPABASE_ANON_KEY") ??
    readTrimmedEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY");
  if (!supabaseJwt) {
    return NextResponse.json(
      {
        error:
          "Server misconfigured: set SUPABASE_SERVICE_ROLE_KEY (or SUPABASE_ANON_KEY) on Vercel to call partner-onboard.",
      },
      { status: 500 }
    );
  }

  const res = await fetch(`${supabaseUrl}/functions/v1/partner-onboard`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${supabaseJwt}`,
      // Must match what the operator used to pass auth — not ADMIN_SECRET ?? WANDERMOOD
      // when those two Vercel env values differ (otherwise Edge sees the wrong secret).
      "x-admin-secret": provided,
    },
    body: JSON.stringify({ lead_id }),
  });

  const data = (await res.json().catch(() => ({}))) as { error?: string };
  if (!res.ok) {
    const base = data.error ?? "Onboarding failed";
    const error =
      res.status === 401
        ? `${base} — zet Supabase Edge secret ADMIN_SECRET gelijk aan hetzelfde wachtwoord als hier in /admin.`
        : base;
    return NextResponse.json({ error }, { status: res.status });
  }

  return NextResponse.json({ success: true, ...data });
}
