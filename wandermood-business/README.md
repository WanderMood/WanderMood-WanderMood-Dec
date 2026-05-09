# WanderMood Partner Portal

Next.js dashboard for **business.wandermood.com**: partners manage their listing, view analytics, and handle Stripe billing.

## Setup

```bash
cd wandermood-business
cp env.example .env.local
# Fill in Supabase anon + service role keys, Stripe keys, STRIPE_PRICE_ID
npm install
npm run dev
```

Configure **Supabase Auth** redirect URLs:

- `https://business.wandermood.com/auth/callback` (production)
- `http://localhost:3000/auth/callback` (local)

Apply the repo migration that adds `business_users`, `business_analytics_daily`, Stripe fields, and RLS (`supabase/migrations/20260509120000_partner_dashboard.sql`).

## Stripe (manual)

1. Product **WanderMood Business**, price **€79/month** (EUR recurring).
2. Webhook URL: `https://business.wandermood.com/api/stripe/webhook` — events: `customer.subscription.*`, `invoice.payment_failed`, `invoice.payment_succeeded`.
3. Enable **Customer portal** (cancel + update payment method).

## Deploy (Vercel)

Root directory: `wandermood-business`. Set env vars from `env.example`. Custom domain: `business.wandermood.com`.
