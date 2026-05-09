import { NextResponse } from "next/server";
import Stripe from "stripe";

import { createAdminClient } from "@/lib/supabase/admin";
import { mapStripeSubscriptionStatus } from "@/lib/stripe-status";

export async function POST(request: Request) {
  const secret = process.env.STRIPE_SECRET_KEY;
  const whSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!secret || !whSecret) {
    return NextResponse.json(
      { error: "Stripe webhook not configured" },
      { status: 500 },
    );
  }

  const body = await request.text();
  const sig = request.headers.get("stripe-signature");
  if (!sig) {
    return NextResponse.json({ error: "No signature" }, { status: 400 });
  }

  const stripe = new Stripe(secret);
  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, whSecret);
  } catch (err) {
    console.error("[stripe webhook] signature", err);
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  const admin = createAdminClient();

  try {
    switch (event.type) {
      case "customer.subscription.created": {
        const sub = event.data.object as Stripe.Subscription;
        await syncSubscription(admin, sub, { setStartedAt: true });
        break;
      }
      case "customer.subscription.updated": {
        const sub = event.data.object as Stripe.Subscription;
        await syncSubscription(admin, sub, {});
        break;
      }
      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        await admin
          .from("business_listings")
          .update({
            subscription_status: "canceled",
            stripe_subscription_id: null,
          })
          .eq("stripe_subscription_id", sub.id);
        break;
      }
      case "invoice.payment_failed": {
        const inv = event.data.object as Stripe.Invoice;
        const customer =
          typeof inv.customer === "string"
            ? inv.customer
            : inv.customer?.id;
        if (customer) {
          await admin
            .from("business_listings")
            .update({ subscription_status: "past_due" })
            .eq("stripe_customer_id", customer);
        }
        break;
      }
      case "invoice.payment_succeeded": {
        const inv = event.data.object as Stripe.Invoice;
        const customer =
          typeof inv.customer === "string"
            ? inv.customer
            : inv.customer?.id;
        if (customer) {
          await admin
            .from("business_listings")
            .update({ subscription_status: "active" })
            .eq("stripe_customer_id", customer);
        }
        break;
      }
      default:
        break;
    }
  } catch (e) {
    console.error("[stripe webhook] handler", e);
    return NextResponse.json({ error: "Handler error" }, { status: 500 });
  }

  return NextResponse.json({ received: true });
}

async function syncSubscription(
  admin: ReturnType<typeof createAdminClient>,
  sub: Stripe.Subscription,
  opts: { setStartedAt?: boolean },
) {
  const priceId = sub.items.data[0]?.price?.id ?? null;
  const status = mapStripeSubscriptionStatus(sub.status);
  const trialEnd = sub.trial_end
    ? new Date(sub.trial_end * 1000).toISOString()
    : null;

  const patch: Record<string, unknown> = {
    stripe_subscription_id: sub.id,
    stripe_price_id: priceId,
    subscription_status: status,
    trial_ends_at: trialEnd,
  };

  if (opts.setStartedAt) {
    patch.subscription_started_at = new Date().toISOString();
  }

  const listingId = sub.metadata?.business_listing_id;
  const customerId =
    typeof sub.customer === "string" ? sub.customer : sub.customer?.id;

  if (listingId) {
    await admin.from("business_listings").update(patch).eq("id", listingId);
    return;
  }

  if (customerId) {
    await admin
      .from("business_listings")
      .update(patch)
      .eq("stripe_customer_id", customerId);
  }
}
