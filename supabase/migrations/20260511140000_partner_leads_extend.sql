-- Extended partner application fields + Stripe checkout tracking

ALTER TABLE public.partner_leads
  ADD COLUMN IF NOT EXISTS contact_phone text,
  ADD COLUMN IF NOT EXISTS kvk_number text,
  ADD COLUMN IF NOT EXISTS billing_name text,
  ADD COLUMN IF NOT EXISTS billing_address text,
  ADD COLUMN IF NOT EXISTS vat_number text,
  ADD COLUMN IF NOT EXISTS street_address text,
  ADD COLUMN IF NOT EXISTS opening_hours text,
  ADD COLUMN IF NOT EXISTS price_range text,
  ADD COLUMN IF NOT EXISTS instagram_handle text,
  ADD COLUMN IF NOT EXISTS why_wandermood text,
  ADD COLUMN IF NOT EXISTS pricing_consent boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS stripe_session_id text,
  ADD COLUMN IF NOT EXISTS payment_captured_at timestamptz;

COMMENT ON COLUMN public.partner_leads.stripe_session_id IS 'Latest Stripe Checkout session id for this lead.';
COMMENT ON COLUMN public.partner_leads.payment_captured_at IS 'Set when checkout.session.completed webhook confirms payment setup.';
