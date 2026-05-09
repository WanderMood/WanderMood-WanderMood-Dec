import { cache } from "react";
import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";
import type { BusinessListing } from "@/types/business";

export const getPartnerListing = cache(async (): Promise<BusinessListing | null> => {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: bu } = await supabase
    .from("business_users")
    .select("business_listing_id")
    .eq("user_id", user.id)
    .maybeSingle();

  if (!bu?.business_listing_id) return null;

  const { data: listing } = await supabase
    .from("business_listings")
    .select("*")
    .eq("id", bu.business_listing_id)
    .single();

  if (!listing) return null;
  return listing as BusinessListing;
});

export async function requirePartnerListing(): Promise<BusinessListing> {
  const listing = await getPartnerListing();
  if (!listing) {
    redirect("/no-access");
  }
  return listing;
}
