-- Self-serve partner signup: listings start as `onboarding` (not public in Explore;
-- only `active` and `trialing` remain in the public read policy).

ALTER TABLE public.business_listings
  DROP CONSTRAINT IF EXISTS business_listings_subscription_status_check;

ALTER TABLE public.business_listings
  ADD CONSTRAINT business_listings_subscription_status_check
  CHECK (
    subscription_status = ANY (
      ARRAY[
        'trialing',
        'active',
        'past_due',
        'canceled',
        'pending_approval',
        'paused',
        'inactive',
        'onboarding'
      ]::text[]
    )
  );
