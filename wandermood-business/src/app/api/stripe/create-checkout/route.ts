import { NextResponse } from "next/server";
import Stripe from "stripe";

import { createAdminClient } from "@/lib/supabase/admin";
import { getPartnerListing } from "@/lib/partner-data";

const appUrl =
  process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";

export async function POST() {
  const secret = process.env.STRIPE_SECRET_KEY;
  const priceId = process.env.STRIPE_PRICE_ID;
  if (!secret || !priceId) {
    return NextResponse.json(
      { error: "Stripe is not configured" },
      { status: 500 },
    );
  }

  const listing = await getPartnerListing();
  if (!listing) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const stripe = new Stripe(secret);
  const admin = createAdminClient();

  let customerId = listing.stripe_customer_id;
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: listing.contact_email,
      metadata: { business_listing_id: listing.id },
    });
    customerId = customer.id;
    await admin
      .from("business_listings")
      .update({ stripe_customer_id: customerId })
      .eq("id", listing.id);
  }

  const trialEnds = listing.trial_ends_at
    ? Math.floor(new Date(listing.trial_ends_at).getTime() / 1000)
    : undefined;
  const now = Math.floor(Date.now() / 1000);
  const useTrialEnd =
    trialEnds !== undefined && trialEnds > now ? trialEnds : undefined;

  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer: customerId,
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${appUrl}/dashboard/subscription?success=1`,
    cancel_url: `${appUrl}/dashboard/subscription`,
    allow_promotion_codes: true,
    subscription_data: {
      metadata: { business_listing_id: listing.id },
      ...(useTrialEnd ? { trial_end: useTrialEnd } : {}),
    },
    metadata: { business_listing_id: listing.id },
  });

  if (!session.url) {
    return NextResponse.json(
      { error: "No checkout URL" },
      { status: 500 },
    );
  }

  return NextResponse.json({ url: session.url });
}
