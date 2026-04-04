import { createSupabaseAdmin } from "@/lib/supabase-admin";
import { NextResponse } from "next/server";
import Stripe from "stripe";

export const runtime = "nodejs";

/**
 * Stripe → Supabase sync.
 *
 * Env (Vercel):
 *   STRIPE_SECRET_KEY          — required to expand/retrieve subscription on checkout
 *   STRIPE_WEBHOOK_SECRET      — signing secret from Stripe Dashboard → Webhooks
 *   SUPABASE_URL               — same as admin stats
 *   SUPABASE_SERVICE_ROLE_KEY  — same as admin stats
 *
 * Checkout: create sessions with metadata.supabase_user_id = auth user UUID
 * (or client_reference_id set to that UUID). See premium_upgrade_screen when you wire Checkout.
 */
export async function POST(request: Request) {
  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  const stripeKey = process.env.STRIPE_SECRET_KEY;
  if (!secret || !stripeKey) {
    return NextResponse.json(
      { error: "Missing STRIPE_WEBHOOK_SECRET or STRIPE_SECRET_KEY" },
      { status: 500 }
    );
  }

  const supabase = createSupabaseAdmin();
  if (!supabase) {
    return NextResponse.json(
      { error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" },
      { status: 500 }
    );
  }

  const rawBody = await request.text();
  const sig = request.headers.get("stripe-signature");
  if (!sig) {
    return NextResponse.json({ error: "No stripe-signature" }, { status: 400 });
  }

  const stripe = new Stripe(stripeKey);

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(rawBody, sig, secret);
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Invalid signature";
    return NextResponse.json({ error: msg }, { status: 400 });
  }

  const { error: dupErr } = await supabase.from("stripe_webhook_events").insert({
    stripe_event_id: event.id,
    event_type: event.type,
    livemode: event.livemode,
  });

  if (dupErr) {
    if (dupErr.code === "23505" || dupErr.message.includes("duplicate")) {
      return NextResponse.json({ received: true, duplicate: true });
    }
    return NextResponse.json({ error: dupErr.message }, { status: 500 });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed":
        await handleCheckoutSessionCompleted(stripe, supabase, event.data.object as Stripe.Checkout.Session);
        break;
      case "invoice.paid":
        await handleInvoicePaid(supabase, event.data.object as Stripe.Invoice);
        break;
      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        if (event.type === "customer.subscription.deleted") {
          await handleSubscriptionDeleted(supabase, sub);
        } else {
          await handleSubscriptionUpdated(supabase, sub);
        }
        break;
      }
      default:
        break;
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    await supabase
      .from("stripe_webhook_events")
      .update({ processing_error: msg })
      .eq("stripe_event_id", event.id);
    return NextResponse.json({ error: msg }, { status: 500 });
  }

  return NextResponse.json({ received: true });
}

async function handleCheckoutSessionCompleted(
  stripe: Stripe,
  supabase: NonNullable<ReturnType<typeof createSupabaseAdmin>>,
  session: Stripe.Checkout.Session
) {
  const userId = session.metadata?.supabase_user_id ?? session.client_reference_id;
  if (!userId) {
    console.warn("[stripe webhook] checkout.session.completed: missing supabase_user_id / client_reference_id");
    return;
  }

  const customerId =
    typeof session.customer === "string" ? session.customer : session.customer?.id;
  const subId =
    typeof session.subscription === "string" ? session.subscription : session.subscription?.id;

  if (!customerId || !subId) {
    console.warn("[stripe webhook] checkout.session.completed: missing customer or subscription");
    return;
  }

  const sub = await stripe.subscriptions.retrieve(subId);
  const priceId = sub.items.data[0]?.price.id ?? null;
  const activeLike = sub.status === "active" || sub.status === "trialing";

  const { error } = await supabase.from("subscriptions").upsert(
    {
      user_id: userId,
      plan_type: activeLike ? "premium" : "free",
      status: activeLike ? "active" : "cancelled",
      stripe_customer_id: customerId,
      stripe_subscription_id: subId,
      stripe_price_id: priceId,
      current_period_end: new Date(sub.current_period_end * 1000).toISOString(),
      cancel_at_period_end: sub.cancel_at_period_end ?? false,
    },
    { onConflict: "user_id" }
  );

  if (error) throw new Error(`subscriptions upsert: ${error.message}`);
}

async function handleInvoicePaid(
  supabase: NonNullable<ReturnType<typeof createSupabaseAdmin>>,
  invoice: Stripe.Invoice
) {
  if (!invoice.paid || invoice.amount_paid == null) return;

  const invId = invoice.id;
  if (!invId) return;

  const customerId =
    typeof invoice.customer === "string" ? invoice.customer : invoice.customer?.id ?? null;
  const subId =
    typeof invoice.subscription === "string"
      ? invoice.subscription
      : invoice.subscription && typeof invoice.subscription !== "string"
        ? invoice.subscription.id
        : null;

  let userId: string | null = null;
  if (customerId) {
    const { data } = await supabase
      .from("subscriptions")
      .select("user_id")
      .eq("stripe_customer_id", customerId)
      .maybeSingle();
    userId = data?.user_id ?? null;
  }

  const paidAtUnix =
    invoice.status_transitions?.paid_at ?? Math.floor(Date.now() / 1000);

  const { error } = await supabase.from("billing_payments").insert({
    user_id: userId,
    stripe_invoice_id: invId,
    stripe_subscription_id: subId,
    amount_paid_cents: invoice.amount_paid,
    currency: invoice.currency ?? "usd",
    paid_at: new Date(paidAtUnix * 1000).toISOString(),
  });

  if (error) {
    if (error.code === "23505" || error.message.includes("duplicate")) return;
    throw new Error(`billing_payments insert: ${error.message}`);
  }
}

async function handleSubscriptionUpdated(
  supabase: NonNullable<ReturnType<typeof createSupabaseAdmin>>,
  sub: Stripe.Subscription
) {
  const activeLike = sub.status === "active" || sub.status === "trialing";
  const priceId = sub.items.data[0]?.price.id ?? null;

  const row = {
    plan_type: activeLike ? ("premium" as const) : ("free" as const),
    status:
      sub.status === "canceled"
        ? ("cancelled" as const)
        : activeLike
          ? ("active" as const)
          : ("expired" as const),
    stripe_price_id: priceId,
    current_period_end: new Date(sub.current_period_end * 1000).toISOString(),
    cancel_at_period_end: sub.cancel_at_period_end ?? false,
  };

  const { data: updated, error } = await supabase
    .from("subscriptions")
    .update(row)
    .eq("stripe_subscription_id", sub.id)
    .select("user_id")
    .maybeSingle();

  if (error) throw new Error(`subscriptions update: ${error.message}`);
  if (!updated) {
    const customerId = typeof sub.customer === "string" ? sub.customer : sub.customer.id;
    const { error: e2 } = await supabase
      .from("subscriptions")
      .update(row)
      .eq("stripe_customer_id", customerId);
    if (e2) throw new Error(`subscriptions update by customer: ${e2.message}`);
  }
}

async function handleSubscriptionDeleted(
  supabase: NonNullable<ReturnType<typeof createSupabaseAdmin>>,
  sub: Stripe.Subscription
) {
  const row = {
    plan_type: "free" as const,
    status: "cancelled" as const,
    cancel_at_period_end: false,
  };

  const { error } = await supabase.from("subscriptions").update(row).eq("stripe_subscription_id", sub.id);
  if (error) throw new Error(`subscriptions delete-state: ${error.message}`);
}
