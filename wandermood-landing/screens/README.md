# App screenshots for the static landing (`index.html`)

Add **PNG** (or JPG) exports from the simulator or device. The page loads these paths; if a file is missing, the **CSS mock** shows instead.

| File | Where it appears |
|------|------------------|
| `my-day.png` | Hero phone — My Day |
| `explore.png` | Explore feature section |
| `moody-hub.png` | Moody Hub chat section |
| `my-plans.png` | My Plans section |

**Tips**

- Portrait ~**390×844** (or similar iPhone ratio) works well; images use `object-fit: cover` and align to the **top**.
- Prefer **PNG** for UI screenshots.
- After adding files, commit and push so Vercel can serve them from `/screens/…`.
