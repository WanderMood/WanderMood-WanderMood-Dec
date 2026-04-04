-- Stripe billing foundation: link subscriptions to Stripe + payment ledger + webhook idempotency.
-- Apply on Supabase when you enable Checkout / Billing. Safe to run once; uses IF NOT EXISTS.

ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_price_id TEXT,
  ADD COLUMN IF NOT EXISTS current_period_end TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancel_at_period_end BOOLEAN DEFAULT FALSE;

CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_stripe_customer_id_key
  ON public.subscriptions (stripe_customer_id)
  WHERE stripe_customer_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_stripe_subscription_id_key
  ON public.subscriptions (stripe_subscription_id)
  WHERE stripe_subscription_id IS NOT NULL;

-- Idempotent webhook processing (Stripe may retry).
CREATE TABLE IF NOT EXISTS public.stripe_webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_event_id TEXT NOT NULL UNIQUE,
  event_type TEXT NOT NULL,
  livemode BOOLEAN NOT NULL DEFAULT FALSE,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processing_error TEXT
);

ALTER TABLE public.stripe_webhook_events ENABLE ROW LEVEL SECURITY;

-- Successful charges (for admin revenue / MRR-style rollups later).
CREATE TABLE IF NOT EXISTS public.billing_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  stripe_invoice_id TEXT NOT NULL UNIQUE,
  stripe_subscription_id TEXT,
  amount_paid_cents BIGINT NOT NULL,
  currency TEXT NOT NULL DEFAULT 'usd',
  paid_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS billing_payments_paid_at_idx ON public.billing_payments (paid_at DESC);
CREATE INDEX IF NOT EXISTS billing_payments_user_id_idx ON public.billing_payments (user_id);

ALTER TABLE public.billing_payments ENABLE ROW LEVEL SECURITY;

-- No policies: anon/authenticated cannot read billing tables; service role bypasses RLS.

COMMENT ON TABLE public.billing_payments IS 'Stripe invoice.paid rows for revenue reporting; written by wandermood-landing /api/stripe/webhook';
COMMENT ON TABLE public.stripe_webhook_events IS 'Stripe webhook idempotency + debug; service role only';
