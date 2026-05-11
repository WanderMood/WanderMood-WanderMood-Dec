-- Public read model for in-app partner visibility (Explore, My Day, Moody context).
-- Backed by business_listings; anon/authenticated can SELECT per existing RLS on base table.

CREATE OR REPLACE VIEW public.active_partner_listings AS
SELECT
  bl.id,
  bl.business_name,
  bl.place_id,
  bl.city,
  COALESCE(bl.target_moods, ARRAY[]::text[]) AS target_moods,
  bl.active_offer,
  bl.custom_description,
  (COALESCE(bl.subscription_tier, 'basic') = 'featured') AS is_featured_this_week,
  (bl.created_at > (now() - interval '30 days')) AS show_new_badge,
  (
    bl.active_offer IS NOT NULL
    AND btrim(bl.active_offer) <> ''
    AND (bl.offer_expires_at IS NULL OR bl.offer_expires_at > now())
  ) AS has_active_offer,
  COALESCE(bl.total_views, 0)::integer AS total_views,
  COALESCE(bl.total_taps, 0)::integer AS total_taps,
  COALESCE(bl.total_checkins, 0)::integer AS total_checkins
FROM public.business_listings bl
WHERE bl.subscription_status = ANY (ARRAY['active'::text, 'trialing'::text])
  AND bl.place_id IS NOT NULL
  AND btrim(bl.place_id) <> '';

COMMENT ON VIEW public.active_partner_listings IS
  'Active/trialing partner rows with a Google place_id for client-side Explore/My Day/Moody.';

GRANT SELECT ON public.active_partner_listings TO anon, authenticated;
