export type SubscriptionStatus =
  | "onboarding"
  | "trialing"
  | "active"
  | "past_due"
  | "canceled"
  | "pending_approval"
  | "paused"
  | "inactive";

export type BusinessListing = {
  id: string;
  business_name: string;
  contact_email: string;
  city: string;
  country: string;
  place_id: string | null;
  subscription_tier: string;
  subscription_status: SubscriptionStatus;
  subscription_started_at: string | null;
  subscription_expires_at: string | null;
  trial_ends_at: string | null;
  target_moods: string[] | null;
  target_filters: string[] | null;
  is_halal: boolean | null;
  is_vegan_friendly: boolean | null;
  is_vegetarian_friendly: boolean | null;
  is_lgbtq_friendly: boolean | null;
  is_black_owned: boolean | null;
  is_family_friendly: boolean | null;
  is_kids_friendly: boolean | null;
  is_wheelchair_accessible: boolean | null;
  custom_description: string | null;
  custom_photos: string[] | null;
  active_offer: string | null;
  offer_expires_at: string | null;
  total_views: number | null;
  total_taps: number | null;
  total_offer_redemptions: number | null;
  total_checkins: number | null;
  stripe_customer_id: string | null;
  stripe_subscription_id: string | null;
  stripe_price_id: string | null;
  created_at: string;
  updated_at: string;
};

export type BusinessAnalyticsDaily = {
  id: string;
  business_listing_id: string;
  date: string;
  views: number;
  taps: number;
};
