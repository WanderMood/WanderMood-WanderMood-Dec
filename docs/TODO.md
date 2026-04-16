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

## My Day (Screen 3) — post-launch polish (items 5–7)

Deferred after the pre-launch My Day pass (short titles, motion, typography, a11y). Tackle when you have a quiet release window.

- [ ] **(5) Split `dynamic_my_day_screen.dart`** — break into smaller widgets / files (timeline builder, sheets, status hero host) so changes stay reviewable and testable.
- [ ] **(6) Skeleton / loading polish** — stable loading states for My Day (scheduled activities, free-time carousel) instead of abrupt spinners or empty flashes.
- [ ] **(7) Pull-to-refresh + empty states** — refresh gesture for today’s plan where it fits the scroll model; align empty-state illustrations and copy with the rest of the app’s empty patterns.

---

## Community reviews — public, trustworthy WanderMood ratings

Today **`activity_ratings`** is **private per user** (RLS: only you can read your rows). It powers personalization and My Day “your review,” not a shared trust surface. To make **reviews visible to other travelers** (your stated goal), treat this as a **separate public layer** (or explicit publish flag + new policies), not “open up” the existing table without a product pass.

- [ ] **Product rules:** consent copy (“Public — other WanderMood travelers can see this”), default on/off, editable window, pseudonym vs display name, one review per user per **canonical place** (or per visit — decide).
- [ ] **Data model:** e.g. `public_place_reviews` (or equivalent) keyed by **stable Google `place_id`** + `user_id`, with `stars`, `body` / notes, `tags` / vibe, `created_at`, optional link to `activity_ratings.id` or scheduled activity id for “verified visit” later.
- [ ] **Supabase RLS:** authenticated **SELECT** for published rows; **INSERT/UPDATE/DELETE** only for `auth.uid() = user_id` (or staff role for moderation). Keep existing `activity_ratings` private unless you explicitly duplicate into public table on publish.
- [ ] **Write path:** extend Quick Review (or post-save step) to **publish** to the public table; handle idempotency (upsert on `user_id` + `place_id` if one-per-place).
- [ ] **Read path & UI:** show **aggregate** (avg + count) + **recent reviews** on **Place detail** / Explore where trust matters; optional “You published a community review” on My Day.
- [ ] **Abuse & trust (MVP+):** rate limits, reporting flag, optional “only if activity was completed / checked in” for a “verified” badge — full moderation UI can wait.
- [ ] **Deploy:** you merge SQL + RLS and apply on Supabase; align with `.cursor/rules/supabase-edge-deploy.mdc` for any Edge changes (this is mostly DB + Flutter).

---

## Reference

- Vercel + domain: `wandermood-landing/VERCEL_SETUP.md`
- Stripe Checkout API: `POST /api/stripe/create-checkout-session` (see file comments in `app/api/stripe/create-checkout-session/route.ts`)
