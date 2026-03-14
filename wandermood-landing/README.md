# WanderMood Landing Page

Landing page for [WanderMood](https://wandermood.com) – plan a feeling, not just a trip.

## Run locally

```bash
cd wandermood-landing
npm install   # if you haven't already
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Build

```bash
npm run build
```

## Deploy to Vercel (wandermood.com)

1. Push this repo to GitHub (include the `wandermood-landing` folder).
2. In [Vercel](https://vercel.com): **New Project** → Import your repo.
3. Set **Root Directory** to `wandermood-landing`.
4. Deploy. Then in **Settings → Domains** add `wandermood.com` and `www.wandermood.com`.
5. In **Namecheap** → **Advanced DNS** add the A and CNAME records Vercel shows.

See the main project docs for detailed Namecheap + Vercel steps.
