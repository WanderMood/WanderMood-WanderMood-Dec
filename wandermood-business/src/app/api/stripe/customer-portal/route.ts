import { NextResponse } from "next/server";
import Stripe from "stripe";

import { getPartnerListing } from "@/lib/partner-data";

const appUrl =
  process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";

export async function POST() {
  const secret = process.env.STRIPE_SECRET_KEY;
  if (!secret) {
    return NextResponse.json(
      { error: "Stripe is not configured" },
      { status: 500 },
    );
  }

  const listing = await getPartnerListing();
  if (!listing?.stripe_customer_id) {
    return NextResponse.json(
      { error: "No billing customer" },
      { status: 400 },
    );
  }

  const stripe = new Stripe(secret);
  const session = await stripe.billingPortal.sessions.create({
    customer: listing.stripe_customer_id,
    return_url: `${appUrl}/dashboard/subscription`,
  });

  return NextResponse.json({ url: session.url });
}
