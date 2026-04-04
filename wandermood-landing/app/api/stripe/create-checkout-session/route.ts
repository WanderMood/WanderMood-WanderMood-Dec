import { createClient } from "@supabase/supabase-js";
import { NextResponse } from "next/server";
import Stripe from "stripe";

export const runtime = "nodejs";

/**
 * Creates a Stripe Checkout Session (subscription).
 *
 * Auth: `Authorization: Bearer <Supabase access_token>` (same JWT the Flutter app uses).
 *
 * Body JSON:
 *   - successUrl, cancelUrl — full URLs; host must match STRIPE_CHECKOUT_ALLOWED_HOST_SUFFIXES
 *   - priceId (optional) — Stripe Price ID; defaults to STRIPE_PREMIUM_PRICE_ID
 *
 * Vercel env:
 *   STRIPE_SECRET_KEY
 *   STRIPE_PREMIUM_PRICE_ID — e.g. price_xxx from Stripe → Product → Pricing
 *   SUPABASE_URL
 *   SUPABASE_ANON_KEY (or NEXT_PUBLIC_SUPABASE_ANON_KEY) — anon key; used only to verify the user JWT server-side
 *   STRIPE_CHECKOUT_ALLOWED_HOST_SUFFIXES (optional) — comma-separated, default includes wandermood.com, localhost, vercel.app
 */
function parseAllowedHosts(): string[] {
  const raw =
    process.env.STRIPE_CHECKOUT_ALLOWED_HOST_SUFFIXES ??
    "wandermood.com,localhost,vercel.app";
  return raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

function assertSafeRedirectUrl(raw: string): string {
  let u: URL;
  try {
    u = new URL(raw);
  } catch {
    throw new Error("Invalid success/cancel URL");
  }
  const host = u.hostname.toLowerCase();
  const allowed = parseAllowedHosts();
  const ok = allowed.some((s) => host === s || host.endsWith("." + s));
  if (!ok) {
    throw new Error("Return URL host is not allowed");
  }
  const httpsOk = u.protocol === "https:";
  const localHttp = host === "localhost" && u.protocol === "http:";
  if (!httpsOk && !localHttp) {
    throw new Error("Return URL must use https (or http://localhost for dev)");
  }
  return raw;
}

export async function POST(request: Request) {
  const stripeKey = process.env.STRIPE_SECRET_KEY;
  const defaultPrice = process.env.STRIPE_PREMIUM_PRICE_ID;
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseAnon =
    process.env.SUPABASE_ANON_KEY ?? process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!stripeKey || !defaultPrice || !supabaseUrl || !supabaseAnon) {
    return NextResponse.json(
      {
        error:
          "Server missing STRIPE_SECRET_KEY, STRIPE_PREMIUM_PRICE_ID, SUPABASE_URL, or SUPABASE_ANON_KEY (or NEXT_PUBLIC_SUPABASE_ANON_KEY)",
      },
      { status: 500 },
    );
  }

  const authHeader = request.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  const accessToken = authHeader.slice(7).trim();
  if (!accessToken) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = createClient(supabaseUrl, supabaseAnon, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const {
    data: { user },
    error: userErr,
  } = await supabase.auth.getUser(accessToken);
  if (userErr || !user) {
    return NextResponse.json({ error: "Invalid or expired session" }, { status: 401 });
  }

  let body: { successUrl?: string; cancelUrl?: string; priceId?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { successUrl, cancelUrl, priceId } = body;
  if (!successUrl || !cancelUrl) {
    return NextResponse.json(
      { error: "successUrl and cancelUrl are required" },
      { status: 400 },
    );
  }

  let safeSuccess: string;
  let safeCancel: string;
  try {
    safeSuccess = assertSafeRedirectUrl(successUrl);
    safeCancel = assertSafeRedirectUrl(cancelUrl);
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Invalid URL";
    return NextResponse.json({ error: msg }, { status: 400 });
  }

  const price = (priceId || defaultPrice).trim();
  if (!price.startsWith("price_")) {
    return NextResponse.json(
      { error: "priceId must be a Stripe Price ID (price_...)" },
      { status: 400 },
    );
  }

  const stripe = new Stripe(stripeKey);

  try {
    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      line_items: [{ price, quantity: 1 }],
      success_url: safeSuccess,
      cancel_url: safeCancel,
      client_reference_id: user.id,
      metadata: { supabase_user_id: user.id },
      subscription_data: {
        metadata: { supabase_user_id: user.id },
      },
      ...(user.email ? { customer_email: user.email } : {}),
    });

    if (!session.url) {
      return NextResponse.json(
        { error: "Stripe did not return a checkout URL" },
        { status: 500 },
      );
    }

    return NextResponse.json({ url: session.url, id: session.id });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("[create-checkout-session]", msg);
    return NextResponse.json({ error: msg }, { status: 502 });
  }
}
