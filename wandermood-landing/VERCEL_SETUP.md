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

### Environment variables (optional)

- **Public site only:** none required.
- **`/admin` dashboard** (user & usage stats from Supabase): add under **Settings → Environment Variables**:
  - `WANDERMOOD_ADMIN_SECRET` — long random string; you enter it on `https://wandermood.com/admin` to load stats.
  - `SUPABASE_URL` — same project URL as the Flutter app.
  - `SUPABASE_SERVICE_ROLE_KEY` — **server only**; never put in the Flutter app or client code. Only Vercel serverless reads this.

After saving env vars, **redeploy** the project.

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
