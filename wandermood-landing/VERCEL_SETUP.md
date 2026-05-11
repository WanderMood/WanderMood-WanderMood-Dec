# Deploy WanderMood landing page to Vercel

You’ve already set up Namecheap; follow these steps in Vercel.

---

## 1. Push your code

Make sure your repo (e.g. `WanderMood-WanderMood-Dec`) is on **GitHub**, **GitLab**, or **Bitbucket**. Vercel deploys from git.

---

## 2. Import project in Vercel

1. Go to [vercel.com](https://vercel.com) and sign in (GitHub/GitLab/Bitbucket).
2. Click **Add New… → Project**.
3. **Import** the repo that contains `wandermood-landing` (e.g. `WanderMood-WanderMood-Dec`).
4. **Do not** click Deploy yet.

---

## 3. Set Root Directory (important)

The Next.js app lives in a subfolder, so Vercel must build from that folder:

1. Under **Root Directory**, click **Edit**.
2. Enter: **`wandermood-landing`**
3. Confirm. Vercel will now use `wandermood-landing` as the project root and run `npm install` and `npm run build` there.

---

## 4. Build settings (optional check)

- **Framework Preset:** Next.js (auto-detected)
- **Build Command:** `npm run build` (default)
- **Output Directory:** leave default (Next.js handles it)
- **Install Command:** `npm install` (default)

**Legacy `vercel.json`:** If the build log warns that **`builds` in your configuration file** means Project Settings won’t apply, and **“Build Completed” takes only a few milliseconds**, you are not running `next build`. An old static-site `vercel.json` (e.g. `@vercel/static` and `index.html`) causes that. **Delete that `vercel.json`** so Vercel auto-detects Next.js and runs a real production build (typically tens of seconds).

### Environment variables (optional)

- **Public site only:** none required.
- **`/admin` dashboard** (user & usage stats from Supabase): add under **Settings → Environment Variables**:
  - `WANDERMOOD_ADMIN_SECRET` — long random string; you enter it on `https://wandermood.com/admin` to load stats.
  - `ADMIN_SECRET` — optional on Vercel if you already set `WANDERMOOD_ADMIN_SECRET` to the **same** value as **Supabase → Edge Functions → Secrets** `ADMIN_SECRET` for `partner-onboard`. The approve route sends **`ADMIN_SECRET` ?? `WANDERMOOD_ADMIN_SECRET`** to Edge.
  - `SUPABASE_URL` — same project URL as the Flutter app.
  - `SUPABASE_SERVICE_ROLE_KEY` — **server only**; never put in the Flutter app or client code. Vercel serverless reads this for `/admin` stats, `/api/admin/approve-partner`, and **`/api/partners/apply`** (inserts into `partner_leads`). Value: Supabase → **Project Settings → API** → **service_role** secret key.
  - `NEXT_PUBLIC_SUPABASE_URL` — optional fallback where code reads the public URL; may match `SUPABASE_URL`.
- **Stripe** (Checkout + webhook + admin revenue): see [Stripe on Vercel](#stripe-on-vercel-subscriptions) below.
- **Checkout API** (`/api/stripe/create-checkout-session`): also needs `SUPABASE_ANON_KEY` (same as Flutter “anon” key), `STRIPE_SECRET_KEY`, `STRIPE_PREMIUM_PRICE_ID`.
- **Partner application + Stripe Checkout** (`POST /api/partners/apply`): requires `SUPABASE_SERVICE_ROLE_KEY` (and `SUPABASE_URL` or `NEXT_PUBLIC_SUPABASE_URL`), **`STRIPE_SECRET_KEY`**, and a subscription **price** id: **`STRIPE_PRICE_ID`** (or reuse **`STRIPE_PREMIUM_PRICE_ID`**). Set **`NEXT_PUBLIC_APP_URL`** to `https://wandermood.com` (no trailing slash) so success/cancel URLs for partner Checkout are correct. Apply migration `20260511140000_partner_leads_extend.sql` on Supabase for the extra lead columns + `stripe_session_id` / `payment_captured_at`. Optional: **`RESEND_API_KEY`** — notifies `info@wandermood.com` on each application. Configure a verified sender/domain in [Resend](https://resend.com) for `from: partners@wandermood.com`.

After saving env vars, **redeploy** the project (Deployments → … → Redeploy, or push a new commit).

---

## How to deploy updates (get latest `/admin`, Stripe routes, etc.)

1. **Commit and push** your changes to the branch Vercel is connected to (usually `main`).
2. Vercel **builds automatically** on push. Or open the project → **Deployments** → **Redeploy** on the latest commit.
3. Confirm **Root Directory** is still `wandermood-landing` so the right app builds.

**CLI (optional):**

```bash
cd wandermood-landing
npx vercel --prod
```

---

## Stripe on Vercel (subscriptions)

Set these in **Vercel → Project → Settings → Environment Variables** (Production + Preview as you prefer). **Do not** put `STRIPE_SECRET_KEY` or `SUPABASE_SERVICE_ROLE_KEY` in the Flutter app or in any client bundle.

| Variable | Where the value comes from |
|----------|----------------------------|
| `STRIPE_SECRET_KEY` | [Stripe Dashboard](https://dashboard.stripe.com) → **Developers → API keys** → **Secret key** (`sk_live_...` or `sk_test_...`). Use **test** keys until you go live. |
| `STRIPE_WEBHOOK_SECRET` | **Developers → Webhooks** → **Add endpoint** → URL: `https://wandermood.com/api/stripe/webhook` → select events: `checkout.session.completed`, `invoice.paid`, `customer.subscription.updated`, `customer.subscription.deleted` → after creating, open the endpoint and reveal **Signing secret** (`whsec_...`). |
| `STRIPE_PREMIUM_PRICE_ID` | **Product catalog** → your premium **Product** → **Pricing** → copy the **Price ID** (`price_...`) for the subscription price you want Checkout to use by default. |
| `STRIPE_PRICE_ID` | Optional alias used by **`/api/partners/apply`** for the €79/mo partner subscription; if unset, the apply route falls back to `STRIPE_PREMIUM_PRICE_ID`. |
| `NEXT_PUBLIC_APP_URL` | Public site origin, e.g. `https://wandermood.com`. Used for partner Stripe Checkout `success_url` / `cancel_url`. |
| `SUPABASE_ANON_KEY` (or `NEXT_PUBLIC_SUPABASE_ANON_KEY`) | Supabase → **Project Settings → API** → **anon public** key. Server-only use here: verifies the user JWT for `/api/stripe/create-checkout-session`. Prefer `SUPABASE_ANON_KEY` on Vercel so the key isn’t exposed in the browser bundle unless you already use the `NEXT_PUBLIC_` variant. |

Optional:

- `STRIPE_CHECKOUT_ALLOWED_HOST_SUFFIXES` — comma-separated host suffixes allowed for `successUrl` / `cancelUrl` (default: `wandermood.com,localhost,vercel.app`).

After changing env vars, **Redeploy** so serverless routes pick them up.

---

## 5. Deploy

Click **Deploy**. Wait for the build to finish. You’ll get a URL like `your-project-xxx.vercel.app`.

---

## 6. Add your Namecheap domain in Vercel

1. In the Vercel project, go to **Settings → Domains**.
2. Click **Add** and enter your domain (e.g. `wandermood.com` or `www.wandermood.com`).
3. Vercel will show the DNS records you need.

**If you already set DNS in Namecheap:**

- **A record** for `@` (or `www`) → Vercel’s IP, **or**
- **CNAME** for `www` → `cname.vercel-dns.com` (Vercel’s value may be slightly different; use what Vercel shows).

In Namecheap:

- **Domain List → Manage** for your domain.
- **Advanced DNS** (or **DNS**): add or update the A or CNAME record to match what Vercel shows.
- Save. Propagation can take a few minutes up to 48 hours.

**In Vercel:** After adding the domain, Vercel will issue an SSL certificate. When the domain shows as “Valid”, you’re done.

---

## 7. Optional: Vercel CLI

To deploy from your machine without going through the dashboard:

```bash
cd wandermood-landing
npx vercel
```

Follow the prompts (login, link to existing project or create new). For production:

```bash
npx vercel --prod
```

---

## Quick checklist

- [ ] Repo connected to Vercel
- [ ] **Root Directory** = `wandermood-landing`
- [ ] First deploy succeeded
- [ ] Domain added in **Settings → Domains**
- [ ] Namecheap DNS points to Vercel (A or CNAME as shown in Vercel)
- [ ] Domain shows “Valid” in Vercel and loads the site

If you tell me your exact domain (e.g. `wandermood.com` vs `www.wandermood.com`) and what you already set in Namecheap, I can double-check the DNS part.
