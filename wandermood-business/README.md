# WanderMood Partner Portal

Next.js dashboard for **business.wandermood.com**: partners manage their listing, view analytics, and handle Stripe billing.

## Setup

```bash
cd wandermood-business
cp env.example .env.local
# Fill Stripe keys + STRIPE_PRICE_ID (Supabase keys are optional if you use values below from Dashboard / CLI)
npm install
npm run dev
```

## Supabase Auth (Dashboard — required once)

In [Supabase Dashboard](https://supabase.com/dashboard) → your project → **Authentication** → **URL configuration**:

1. Leave **Site URL** as your primary app URL (consumer app / deep link) unless you know you want to change it.
2. Under **Redirect URLs**, add **exactly**:
   - `https://business.wandermood.com/auth/callback`
   - `http://localhost:3000/auth/callback`

Without these, password reset and invite links will not return users to the partner app correctly.

## Database migration

Partner schema is applied on project `oojpipspxwdmiyaymldo` (`business_users`, `business_analytics_daily`, Stripe columns, RLS). Local repo file: [`supabase/migrations/20260509120000_partner_dashboard.sql`](../supabase/migrations/20260509120000_partner_dashboard.sql) (keep in sync with remote migration history if you use `supabase db push`).

## Stripe

1. Product **WanderMood Business**, price **€79/month** (EUR recurring) → copy **Price ID** (`price_...`).
2. **Developers → Webhooks** → endpoint `https://business.wandermood.com/api/stripe/webhook` — subscribe to:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_failed`
   - `invoice.payment_succeeded`  
   Copy the **signing secret** (`whsec_...`).
3. **Settings → Billing → Customer portal** — enable cancel subscription and payment method updates.
4. Add to **Vercel** (project **wandermood-business** → Settings → Environment Variables → Production):
   - `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`
   - `STRIPE_SECRET_KEY`
   - `STRIPE_WEBHOOK_SECRET`
   - `STRIPE_PRICE_ID`

## Vercel

- Project: **wandermood-business** (linked; root directory is this folder when deploying from monorepo).
- Production URL: **https://business.wandermood.com** (custom domain on the Vercel team).
- Supabase-related env vars are set for **Production**; add Stripe vars when you have them, then redeploy.
