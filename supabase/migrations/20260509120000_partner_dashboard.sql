-- Partner dashboard (business.wandermood.com): linking auth users to listings,
-- Stripe-friendly subscription statuses, daily analytics, check-in totals.

-- ---------------------------------------------------------------------------
-- business_users: link auth.users -> business_listings (create first — RLS on
-- business_listings references this table)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.business_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  business_listing_id uuid NOT NULL REFERENCES public.business_listings (id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'owner',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT business_users_user_listing_unique UNIQUE (user_id, business_listing_id)
);

ALTER TABLE public.business_users ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_business_users_user_id ON public.business_users (user_id);
CREATE INDEX IF NOT EXISTS idx_business_users_listing_id ON public.business_users (business_listing_id);

DROP POLICY IF EXISTS "Users read own business_users rows" ON public.business_users;

CREATE POLICY "Users read own business_users rows"
  ON public.business_users
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

GRANT SELECT ON public.business_users TO authenticated;
GRANT ALL ON public.business_users TO service_role;

-- ---------------------------------------------------------------------------
-- business_listings: Stripe + trial + check-in aggregate
-- ---------------------------------------------------------------------------
ALTER TABLE public.business_listings
  ADD COLUMN IF NOT EXISTS stripe_customer_id text,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id text,
  ADD COLUMN IF NOT EXISTS stripe_price_id text,
  ADD COLUMN IF NOT EXISTS trial_ends_at timestamptz,
  ADD COLUMN IF NOT EXISTS total_checkins integer NOT NULL DEFAULT 0;

ALTER TABLE public.business_listings
  DROP CONSTRAINT IF EXISTS business_listings_subscription_status_check;

UPDATE public.business_listings
SET subscription_status = CASE subscription_status
  WHEN 'trial' THEN 'trialing'
  WHEN 'cancelled' THEN 'canceled'
  ELSE subscription_status
END
WHERE subscription_status IN ('trial', 'cancelled');

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
        'inactive'
      ]::text[]
    )
  );

DROP POLICY IF EXISTS "Active listings are publicly readable" ON public.business_listings;

CREATE POLICY "Active listings are publicly readable"
  ON public.business_listings
  AS PERMISSIVE
  FOR SELECT
  TO public
  USING (
    subscription_status = ANY (ARRAY['active'::text, 'trialing'::text])
  );

DROP POLICY IF EXISTS "Partners read own business listing" ON public.business_listings;

CREATE POLICY "Partners read own business listing"
  ON public.business_listings
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.business_users bu
      WHERE bu.business_listing_id = business_listings.id
        AND bu.user_id = (SELECT auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- business_analytics_daily
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.business_analytics_daily (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_listing_id uuid NOT NULL REFERENCES public.business_listings (id) ON DELETE CASCADE,
  date date NOT NULL,
  views integer NOT NULL DEFAULT 0,
  taps integer NOT NULL DEFAULT 0,
  CONSTRAINT business_analytics_daily_listing_date_unique UNIQUE (business_listing_id, date)
);

ALTER TABLE public.business_analytics_daily ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_business_analytics_daily_listing_date
  ON public.business_analytics_daily (business_listing_id, date DESC);

DROP POLICY IF EXISTS "Partners read own analytics" ON public.business_analytics_daily;

CREATE POLICY "Partners read own analytics"
  ON public.business_analytics_daily
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.business_users bu
      WHERE bu.business_listing_id = business_analytics_daily.business_listing_id
        AND bu.user_id = (SELECT auth.uid())
    )
  );

GRANT SELECT ON public.business_analytics_daily TO authenticated;
GRANT ALL ON public.business_analytics_daily TO service_role;

-- ---------------------------------------------------------------------------
-- Backfill + maintain total_checkins
-- ---------------------------------------------------------------------------
UPDATE public.business_listings bl
SET total_checkins = COALESCE(sub.c, 0)
FROM (
  SELECT business_listing_id, count(*)::integer AS c
  FROM public.business_checkins
  GROUP BY business_listing_id
) sub
WHERE bl.id = sub.business_listing_id;

CREATE OR REPLACE FUNCTION public.increment_business_listing_checkins ()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.business_listings
  SET
    total_checkins = coalesce(total_checkins, 0) + 1,
    updated_at = now()
  WHERE id = NEW.business_listing_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS business_checkins_bump_total_checkins ON public.business_checkins;

CREATE TRIGGER business_checkins_bump_total_checkins
  AFTER INSERT ON public.business_checkins
  FOR EACH ROW
  EXECUTE FUNCTION public.increment_business_listing_checkins ();
