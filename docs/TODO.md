# WanderMood — deferred / follow-up checklist

Things you **do not** need to finish before TestFlight or normal development. Check them off when you’re ready.

---

## Landing & admin (`wandermood-landing`)

- [ ] **Deploy latest landing to Vercel** so production matches the repo (Edge API section, billing section, etc.). Push to `main` or **Redeploy**; confirm **Root Directory** = `wandermood-landing`.
- [ ] **Vercel env (admin):** `WANDERMOOD_ADMIN_SECRET`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` — then redeploy if you add or change them.
- [ ] **Optional local dev:** copy `wandermood-landing/.env.example` → `.env.local` and fill values (never commit secrets).

---

## Stripe (when you sell premium via web Checkout)

- [ ] **Vercel env:** `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PREMIUM_PRICE_ID`, `SUPABASE_ANON_KEY` (or `NEXT_PUBLIC_SUPABASE_ANON_KEY`). See `wandermood-landing/VERCEL_SETUP.md` for where each value comes from.
- [ ] **Stripe webhook:** endpoint `https://wandermood.com/api/stripe/webhook` with events `checkout.session.completed`, `invoice.paid`, `customer.subscription.updated`, `customer.subscription.deleted`.
- [ ] **DB:** ensure migration `20260404180000_stripe_billing_foundation.sql` is applied on Supabase (subscriptions columns + `billing_payments` + `stripe_webhook_events`).
- [ ] **Flutter app:** call `POST https://wandermood.com/api/stripe/create-checkout-session` with `Authorization: Bearer <Supabase access token>` and JSON `{ successUrl, cancelUrl }`, then open returned `url` (browser / SFSafariViewController). Decide StoreKit vs Stripe for App Store policy.

---

## Supabase Edge Functions

- [ ] **Weather:** if you use the `weather` function, add **`OPENWEATHER_API_KEY`** under **Edge Functions → Secrets**.
- [ ] **Rate limits (optional):** set `EDGE_RATE_MOODY_PER_MINUTE`, `EDGE_RATE_PLACES_PER_MINUTE`, `EDGE_RATE_WEATHER_PER_MINUTE` if defaults (60 / 120 / 60) are wrong for you.
- [ ] **Confirm** `SUPABASE_SERVICE_ROLE_KEY` is set in Edge secrets (needed for `api_invocations` + rate limits on `moody`, `places`, `weather`).

---

## Database migrations (if any env never applied them)

- [ ] `20260403120000_default_subscription_on_signup.sql` — default free row + trigger (if not applied yet).
- [ ] `20260404200000_edge_api_rate_limit_and_logs.sql` — `api_invocations` + rate limit RPC (if not applied yet).

---

## Product / analytics roadmap (not built yet)

- [ ] Admin: **block / suspend users** + audit log.
- [ ] **Geo analytics** (country / city, privacy-safe aggregation).
- [ ] **Product events** (e.g. top viewed places / categories).
- [ ] **Translate** `de` / `es` / `fr` privacy copy on the landing (if you keep English placeholders).

---

## Reference

- Vercel + domain: `wandermood-landing/VERCEL_SETUP.md`
- Stripe Checkout API: `POST /api/stripe/create-checkout-session` (see file comments in `app/api/stripe/create-checkout-session/route.ts`)
