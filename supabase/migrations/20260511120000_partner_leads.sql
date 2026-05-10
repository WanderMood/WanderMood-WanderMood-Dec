-- Partner applications from wandermood.com/partners (landing form)

CREATE TABLE IF NOT EXISTS public.partner_leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_name text NOT NULL,
  business_type text NOT NULL,
  city text NOT NULL,
  country text NOT NULL DEFAULT 'NL',
  website text,
  google_place_url text,
  contact_email text NOT NULL,
  contact_name text,
  what_they_offer text,
  target_moods text[] NOT NULL DEFAULT '{}',
  gdpr_consent boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'new',
  source text NOT NULL DEFAULT 'website',
  business_listing_id uuid REFERENCES public.business_listings (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_partner_leads_status ON public.partner_leads (status);
CREATE INDEX IF NOT EXISTS idx_partner_leads_created_at ON public.partner_leads (created_at DESC);

ALTER TABLE public.partner_leads ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.partner_leads IS 'B2B leads from website; inserts via service role only.';
