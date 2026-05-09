import { NextResponse } from "next/server";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { getPartnerListing } from "@/lib/partner-data";

const ALLOWED = new Set([
  "custom_description",
  "active_offer",
  "offer_expires_at",
  "target_moods",
  "is_halal",
  "is_vegan_friendly",
  "is_vegetarian_friendly",
  "is_lgbtq_friendly",
  "is_black_owned",
  "is_family_friendly",
  "is_kids_friendly",
  "is_wheelchair_accessible",
]);

export async function PATCH(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const listing = await getPartnerListing();
  if (!listing) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const patch: Record<string, unknown> = {};
  for (const key of Object.keys(body)) {
    if (!ALLOWED.has(key)) continue;
    patch[key] = body[key];
  }

  if (typeof patch.custom_description === "string") {
    patch.custom_description = patch.custom_description.slice(0, 500);
  }
  if (typeof patch.active_offer === "string") {
    patch.active_offer = patch.active_offer.slice(0, 200);
  }
  if (patch.offer_expires_at === "" || patch.offer_expires_at === null) {
    patch.offer_expires_at = null;
  }
  if (Array.isArray(patch.target_moods)) {
    patch.target_moods = patch.target_moods.filter((m) => typeof m === "string");
  }

  if (Object.keys(patch).length === 0) {
    return NextResponse.json({ error: "No valid fields" }, { status: 400 });
  }

  const admin = createAdminClient();
  const { error } = await admin
    .from("business_listings")
    .update(patch)
    .eq("id", listing.id);

  if (error) {
    console.error("[listing PATCH]", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
