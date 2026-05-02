/**
 * moody-prewarm — Supabase Scheduled Edge Function
 *
 * Pre-warms the Explore places_cache for the top Dutch cities every 6 days
 * so no real user ever hits a cold cache and triggers a Google Places API
 * cost spike.
 *
 * Recommended schedule (Supabase Cron / pg_cron):
 *   0 3 * / 6 * *   (03:00 UTC every 6 days)
 *
 * The function calls the production `moody` Edge Function's `get_explore`
 * action for each city × mode × section combination using the service-role
 * key (bypasses RLS; no real user session needed).
 *
 * Environment variables required:
 *   SUPABASE_URL              – your Supabase project URL
 *   SUPABASE_SERVICE_ROLE_KEY – service-role key (backend only, never exposed to clients)
 *   MOODY_FUNCTION_URL        – full URL of the deployed moody function
 *                               e.g. https://<project>.supabase.co/functions/v1/moody
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const CITIES: Array<{ name: string; lat: number; lng: number }> = [
  { name: 'Rotterdam',  lat: 51.9225, lng: 4.4792 },
  { name: 'Amsterdam',  lat: 52.3676, lng: 4.9041 },
  { name: 'Utrecht',    lat: 52.0907, lng: 5.1214 },
  { name: 'Den Haag',   lat: 52.0705, lng: 4.3007 },
  { name: 'Eindhoven',  lat: 51.4416, lng: 5.4697 },
  { name: 'Groningen',  lat: 53.2194, lng: 6.5665 },
  { name: 'Haarlem',    lat: 52.3874, lng: 4.6462 },
  { name: 'Leiden',     lat: 52.1601, lng: 4.4970 },
  { name: 'Delft',      lat: 52.0067, lng: 4.3556 },
  { name: 'Tilburg',    lat: 51.5555, lng: 5.0913 },
]

/** Sections to pre-warm per city (broad feed + key discovery sections). */
const SECTIONS = ['discovery', 'food', 'trending']

/** Modes to pre-warm. */
const MODES: Array<'local' | 'travel'> = ['local', 'travel']

/** Milliseconds to wait between calls so we don't slam the moody function. */
const DELAY_MS = 500

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

Deno.serve(async (req: Request) => {
  // Allow manual HTTP trigger for testing (e.g. from Supabase dashboard).
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204 })
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(JSON.stringify({ error: 'Missing env vars' }), { status: 500 })
  }

  // Use the service-role client so DB cache checks bypass RLS.
  // functions.invoke() will also use this service-role key as Bearer,
  // which moody detects via the JWT role claim (role === 'service_role').
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })

  const log: string[] = []
  const now = new Date().toISOString()
  log.push(`🔥 moody-prewarm started at ${now}`)

  let warmed = 0
  let skipped = 0
  let failed = 0

  for (const city of CITIES) {
    for (const mode of MODES) {
      for (const section of SECTIONS) {
        // Check if a fresh cache already exists to avoid unnecessary API calls.
        const lang = 'nl'
        const modeKey = mode === 'local' ? 'local' : 'travel'
        const cacheKey = `explore_v9_${modeKey}_${section}_${city.name.toLowerCase().trim()}_${lang}`
        const fallbackKey = `explore_v9_${modeKey}_${section}_${city.name.toLowerCase().trim()}`

        try {
          const { data: cacheRow } = await supabase
            .from('places_cache')
            .select('expires_at')
            .or(`cache_key.eq.${cacheKey},cache_key.eq.${fallbackKey}`)
            .is('place_id', null)
            .order('expires_at', { ascending: false })
            .limit(1)
            .maybeSingle()

          if (cacheRow?.expires_at) {
            const expiresAt = new Date(cacheRow.expires_at)
            const hoursLeft = (expiresAt.getTime() - Date.now()) / (1000 * 60 * 60)
            if (hoursLeft > 24) {
              // Cache is fresh enough — skip to save API cost
              log.push(`⏭️  ${city.name}/${mode}/${section} — cache valid (${Math.round(hoursLeft)}h left)`)
              skipped++
              continue
            }
          }
        } catch (e) {
          log.push(`⚠️  cache check failed for ${city.name}/${mode}/${section}: ${e}`)
        }

        // Trigger a cache warm via the moody Edge Function.
        // We include _prewarm_secret in the body so moody can bypass JWT auth
        // without relying on headers (which Supabase's internal router may strip).
        try {
          const prewarmSecret = Deno.env.get('PREWARM_SECRET') ?? ''
          const moodyUrl = `${supabaseUrl}/functions/v1/moody`
          const resp = await fetch(moodyUrl, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              // Still send a valid key so the gateway (if any) doesn't reject it
              'Authorization': `Bearer ${serviceRoleKey}`,
              'apikey': serviceRoleKey,
            },
            body: JSON.stringify({
              action: 'get_explore',
              location: city.name,
              is_local: mode === 'local',
              coordinates: { lat: city.lat, lng: city.lng },
              section,
              language_code: lang,
              client_hour: 14,
              _prewarm: true,
              _prewarm_secret: prewarmSecret,
            }),
          })

          if (resp.ok) {
            const json = await resp.json()
            log.push(`✅ ${city.name}/${mode}/${section} — ${json.total_found ?? json.cards?.length ?? '?'} cards (cached=${json.cached})`)
            warmed++
          } else {
            const errBody = await resp.text().catch(() => '')
            log.push(`❌ ${city.name}/${mode}/${section} — HTTP ${resp.status}: ${errBody.slice(0, 200)}`)
            failed++
          }
        } catch (e) {
          log.push(`❌ ${city.name}/${mode}/${section} — ${e}`)
          failed++
        }

        await sleep(DELAY_MS)
      }
    }
  }

  const summary = { warmed, skipped, failed, total: CITIES.length * MODES.length * SECTIONS.length }
  log.push(`\n📊 Summary: ${JSON.stringify(summary)}`)

  console.log(log.join('\n'))

  return new Response(JSON.stringify({ ok: true, summary, log }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
