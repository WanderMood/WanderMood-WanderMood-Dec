import {
  adminOperatorSecrets,
  isOperatorSecretValid,
  parseClientAdminSecret,
} from "@/lib/admin-auth";
import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  const { edgeForward } = adminOperatorSecrets();

  const provided = parseClientAdminSecret(req.headers);
  if (!isOperatorSecretValid(provided)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  if (!edgeForward) {
    return NextResponse.json(
      {
        error:
          "Server misconfigured: set ADMIN_SECRET or WANDERMOOD_ADMIN_SECRET on Vercel (must match Supabase partner-onboard secret), then redeploy.",
      },
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
      "x-admin-secret": edgeForward,
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
