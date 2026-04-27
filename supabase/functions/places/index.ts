import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import {
  edgeRateLimitConsume,
  getServiceSupabase,
  logApiInvocationFireAndForget,
  traceEdgeResponse,
  userRateKey,
} from '../_shared/edge_guard.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PlacesRequest {
  type: 'search' | 'autocomplete' | 'details' | 'photos' | 'nearby'
  query?: string
  location?: {
    lat: number
    lng: number
  }
  radius?: number
  placeId?: string
  photoReference?: string
  maxWidth?: number
  maxHeight?: number
  placeTypes?: string[]
  language?: string
}

/** Aligns with Flutter `google_` prefix so one place never splits across two cache rows. */
function normalizePlaceIdForCache(placeId: string): string {
  let t = placeId.trim()
  if (t.toLowerCase().startsWith('google_')) t = t.slice('google_'.length)
  return t
}

function normalizeLanguageForDetails(language: string | undefined): string {
  const l = (language ?? 'en').trim().toLowerCase()
  return l ? l.slice(0, 10) : 'en'
}

/** DB row TTL for Place Details (editorial/reviews are language-specific). */
const PLACES_DETAILS_DB_CACHE_DAYS = 21

/** Same-instance burst dedupe before Postgres read (cold starts miss; hot scroll wins). */
const detailsHotMemory = new Map<string, { exp: number; data: unknown }>()
const DETAILS_MEMORY_TTL_MS = 120_000
const DETAILS_MEMORY_MAX = 200

function detailsHotMemoryGet(key: string): unknown | null {
  const row = detailsHotMemory.get(key)
  if (!row) return null
  if (row.exp < Date.now()) {
    detailsHotMemory.delete(key)
    return null
  }
  return row.data
}

function detailsHotMemoryPut(key: string, data: unknown) {
  while (detailsHotMemory.size >= DETAILS_MEMORY_MAX && !detailsHotMemory.has(key)) {
    const first = detailsHotMemory.keys().next().value
    if (first) detailsHotMemory.delete(first)
  }
  detailsHotMemory.set(key, { exp: Date.now() + DETAILS_MEMORY_TTL_MS, data })
}

function jsonDetailsSuccessResponse(data: unknown, cachedUntilIso: string, cached: boolean): string {
  return JSON.stringify({
    success: true,
    data,
    cached_until: cachedUntilIso,
    ...(cached ? { cached: true } : {}),
  })
}

/** Maps Places API (New) GET Place response to the legacy `details/json` shape the Flutter client expects. */
function mapNewPlaceDetailsToLegacyData(p: Record<string, unknown>, _language: string) {
  const displayName = (p.displayName as { text?: string } | undefined)?.text ?? ''
  const loc = p.location as { latitude?: number; longitude?: number } | undefined
  const priceMap: Record<string, number> = {
    PRICE_LEVEL_FREE: 0,
    PRICE_LEVEL_INEXPENSIVE: 1,
    PRICE_LEVEL_MODERATE: 2,
    PRICE_LEVEL_EXPENSIVE: 3,
    PRICE_LEVEL_VERY_EXPENSIVE: 4,
  }
  const pl = p.priceLevel
  const priceLevel =
    typeof pl === 'number' ? pl : (typeof pl === 'string' ? priceMap[pl] : undefined) ?? 0
  const photos = Array.isArray(p.photos)
    ? (p.photos as { name?: string }[])
        .map((ph) => {
          const name = (ph.name ?? '').trim()
          if (!name) return null
          // Flutter reads `photo_reference`; for New, store the photo resource `name` and build `/media` URLs in Dart.
          return { photo_reference: name }
        })
        .filter((x) => x != null)
    : []
  const reviews = Array.isArray(p.reviews)
    ? (p.reviews as Record<string, unknown>[]).map((r) => {
        const textObj = r.text as { text?: string } | string | undefined
        const text =
          typeof textObj === 'string' ? textObj : (textObj as { text?: string } | undefined)?.text ?? ''
        const att = r.authorAttribution as { displayName?: string; uri?: string } | undefined
        const author = att?.displayName || att?.uri || 'Anonymous'
        const pub = r.publishTime as string | undefined
        const timeSec = pub
          ? Math.floor(new Date(pub).getTime() / 1000)
          : 0
        return {
          author_name: author,
          rating: (r.rating as number) ?? 0,
          text,
          time: timeSec,
        }
      })
    : []
  const opening = p.currentOpeningHours as
    | { openNow?: boolean; weekdayDescriptions?: string[] }
    | undefined
  const editorial = p.editorialSummary as { text?: string } | undefined

  const result: Record<string, unknown> = {
    name: displayName,
    formatted_address: (p.formattedAddress as string) ?? '',
    geometry: {
      location: { lat: loc?.latitude ?? 0, lng: loc?.longitude ?? 0 },
    },
    photos,
    rating: (p.rating as number) ?? 0,
    user_ratings_total: (p.userRatingCount as number) ?? 0,
    types: Array.isArray(p.types) ? p.types : [],
    price_level: priceLevel,
    opening_hours: opening
      ? {
          open_now: opening.openNow ?? false,
          weekday_text: Array.isArray(opening.weekdayDescriptions)
            ? opening.weekdayDescriptions
            : [],
        }
      : undefined,
    website: (p.websiteUri as string) ?? undefined,
    formatted_phone_number: (p.nationalPhoneNumber as string) ?? undefined,
    reviews,
    userRatingCount: (p.userRatingCount as number) ?? 0,
  }
  if (editorial?.text) {
    result.editorial_summary = { overview: editorial.text }
  } else {
    result.vicinity = (p.shortFormattedAddress as string) ?? ''
  }
  return { status: 'OK', result }
}

async function fetchPlaceDetailsWithFallback(
  placeId: string,
  language: string,
  apiKey: string,
): Promise<{ data: { status: string; result: Record<string, unknown> }; response: Response }> {
  const fieldMask = [
    'id',
    'displayName',
    'formattedAddress',
    'location',
    'rating',
    'userRatingCount',
    'photos',
    'priceLevel',
    'currentOpeningHours',
    'types',
    'websiteUri',
    'nationalPhoneNumber',
    'editorialSummary',
    'reviews',
    'shortFormattedAddress',
  ].join(',')
  const v1Url = `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}?languageCode=${encodeURIComponent(
    language,
  )}`
  let res = await fetch(v1Url, {
    method: 'GET',
    headers: {
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': fieldMask,
    },
  })
  if (res.ok) {
    const p = (await res.json()) as Record<string, unknown>
    const data = mapNewPlaceDetailsToLegacyData(p, language)
    const photosN = (p.photos as { name?: string }[] | undefined)?.length ?? 0
    console.log(`places.details v1=NEW placeId=${placeId} photos_count=${photosN}`)
    return { data, response: res }
  }
  const errBody = (await res.text()).slice(0, 500)
  console.log(`places.details NEW failed status=${res.status} placeId=${placeId} body=${errBody} — falling back to legacy details`)

  const detailsUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${encodeURIComponent(
    placeId,
  )}&key=${apiKey}&language=${encodeURIComponent(
    language,
  )}&fields=place_id,name,formatted_address,geometry,photos,rating,user_ratings_total,price_level,opening_hours,website,formatted_phone_number,reviews,types,vicinity,editorial_summary`
  res = await fetch(detailsUrl)
  const legacy = (await res.json()) as { status: string; result: Record<string, unknown>; error_message?: string }
  const photos = Array.isArray(legacy?.result?.photos) ? legacy.result.photos : []
  console.log(
    `places.details v1=LEGACY placeId=${placeId} status=${legacy?.status ?? 'unknown'} photos_count=${photos.length}`,
  )
  if (photos.length > 0) {
    const firstRef = (photos[0] as { photo_reference?: string })?.photo_reference ?? ''
    console.log(`places.details LEGACY first_photo_reference=${firstRef ? 'yes' : 'no'}`)
  }
  return { data: legacy as { status: string; result: Record<string, unknown> }, response: res }
}

async function processPlacesBody(
  supabaseClient: ReturnType<typeof createClient>,
  user: { id: string },
  request: PlacesRequest,
): Promise<Response> {
  const { type, query, location, radius = 5000, placeId, photoReference, maxWidth = 400, maxHeight = 400, placeTypes, language = 'en' } = request

  const GOOGLE_PLACES_API_KEY = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!GOOGLE_PLACES_API_KEY) {
    throw new Error('Google Places API key not configured')
  }

  let response: Response | undefined
  let data: any

  switch (type) {
    case 'search': {
      if (!query) throw new Error('Query required for search')
      const serviceDb = getServiceSupabase()
      const searchCacheKey = `places_search_${query.toLowerCase().trim()}_${language}`
      if (serviceDb) {
        try {
          const { data: cachedRow } = await serviceDb
            .from('places_cache')
            .select('data,expires_at')
            .eq('cache_key', searchCacheKey)
            .maybeSingle()
          const expiresAt = cachedRow?.expires_at ? new Date(cachedRow.expires_at as string) : null
          const isFresh = cachedRow?.data && expiresAt != null && expiresAt.getTime() > Date.now()
          if (isFresh) {
            console.log(`places.search cache=HIT query="${query}"`)
            return new Response(
              JSON.stringify({ success: true, data: cachedRow.data, cached: true }),
              { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
            )
          }
          console.log(`places.search cache=MISS query="${query}"`)
        } catch (cacheReadErr) {
          console.warn('places.search cache read failed:', cacheReadErr)
        }
      }
      const searchUrl = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(query)}&key=${GOOGLE_PLACES_API_KEY}&language=${language}`
      response = await fetch(searchUrl)
      data = await response.json()
      if (serviceDb && data?.status === 'OK') {
        try {
          const exp = new Date(); exp.setDate(exp.getDate() + 7)
          await serviceDb.from('places_cache').upsert(
            { cache_key: searchCacheKey, data, user_id: null, place_id: null, request_type: 'search', expires_at: exp.toISOString() },
            { onConflict: 'cache_key' },
          )
          console.log(`places.search cache=WRITE query="${query}"`)
        } catch (cacheWriteErr) {
          console.warn('places.search cache write failed:', cacheWriteErr)
        }
      }
      break
    }

    case 'autocomplete':
      if (!query) throw new Error('Query required for autocomplete')

      let autocompleteUrl = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(query)}&key=${GOOGLE_PLACES_API_KEY}&language=${language}`

      if (location) {
        autocompleteUrl += `&location=${location.lat},${location.lng}&radius=${radius}`
      }

      if (placeTypes && placeTypes.length > 0) {
        autocompleteUrl += `&types=${placeTypes.join('|')}`
      }

      response = await fetch(autocompleteUrl)
      data = await response.json()
      break

    case 'details':
      if (!placeId) throw new Error('Place ID required for details')
      {
        const serviceDb = getServiceSupabase()
        const pid = normalizePlaceIdForCache(placeId)
        const lang = normalizeLanguageForDetails(language)
        const cacheKey = `places_details_v2_${pid}_${lang}`

        const hot = detailsHotMemoryGet(cacheKey)
        const hotRec = hot as { status?: string } | null
        if (hotRec?.status === 'OK') {
          const until = new Date(Date.now() + DETAILS_MEMORY_TTL_MS).toISOString()
          console.log(`places.details hot_memory=HIT placeId=${pid} lang=${lang}`)
          return new Response(jsonDetailsSuccessResponse(hot, until, true), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          })
        }

        if (serviceDb) {
          try {
            const { data: cachedRow } = await serviceDb
              .from('places_cache')
              .select('data,expires_at')
              .eq('cache_key', cacheKey)
              .maybeSingle()

            const expiresAtRaw = cachedRow?.expires_at as string | undefined
            const expiresAt = expiresAtRaw ? new Date(expiresAtRaw) : null
            const isFresh =
              cachedRow?.data &&
              expiresAt != null &&
              !Number.isNaN(expiresAt.getTime()) &&
              expiresAt.getTime() > Date.now()

            if (isFresh) {
              detailsHotMemoryPut(cacheKey, cachedRow.data)
              console.log(`places.details cache=HIT_DB placeId=${pid} lang=${lang}`)
              return new Response(
                jsonDetailsSuccessResponse(cachedRow.data, expiresAt.toISOString(), true),
                {
                  headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                  status: 200,
                },
              )
            }
            console.log(`places.details cache=MISS_DB placeId=${pid} lang=${lang}`)
          } catch (cacheReadError) {
            console.warn('places.details cache read failed:', cacheReadError)
          }
        }

        const r = await fetchPlaceDetailsWithFallback(pid, lang, GOOGLE_PLACES_API_KEY)
        data = r.data
        response = r.response

        if (serviceDb && data?.status === 'OK') {
          try {
            const exp = new Date()
            exp.setDate(exp.getDate() + PLACES_DETAILS_DB_CACHE_DAYS)
            await serviceDb.from('places_cache').upsert(
              {
                cache_key: cacheKey,
                data,
                user_id: null,
                place_id: null,
                request_type: 'details',
                expires_at: exp.toISOString(),
              },
              { onConflict: 'cache_key' },
            )
            console.log(`places.details cache=WRITE_DB placeId=${pid} lang=${lang}`)
          } catch (cacheWriteErr) {
            console.warn('places.details cache write failed:', cacheWriteErr)
          }
        }
        if (data?.status === 'OK') {
          detailsHotMemoryPut(cacheKey, data)
        }
      }
      break

    case 'photos':
      if (!photoReference) throw new Error('Photo reference required for photos')

      const photoUrl = `https://maps.googleapis.com/maps/api/place/photo?photoreference=${photoReference}&key=${GOOGLE_PLACES_API_KEY}&maxwidth=${maxWidth}&maxheight=${maxHeight}`
      response = await fetch(photoUrl)
      console.log(
        `📸 places.photos reference=${photoReference.slice(0, 24)}... status=${response.status}`,
      )

      if (response.ok) {
        const imageBlob = await response.blob()
        console.log(
          `📸 places.photos success content_type=${response.headers.get('Content-Type') ?? 'unknown'}`,
        )
        return new Response(imageBlob, {
          headers: {
            ...corsHeaders,
            'Content-Type': response.headers.get('Content-Type') || 'image/jpeg',
          },
        })
      } else {
        let responsePreview = ''
        try {
          responsePreview = (await response.text()).slice(0, 300)
        } catch (_) { /* ignore */ }
        console.log(`📸 places.photos failed status=${response.status} body=${responsePreview}`)
        throw new Error('Failed to fetch photo')
      }

    case 'nearby':
      if (!location) throw new Error('Location required for nearby search')

      let nearbyUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.lat},${location.lng}&radius=${radius}&key=${GOOGLE_PLACES_API_KEY}&language=${language}`

      if (placeTypes && placeTypes.length > 0) {
        nearbyUrl += `&type=${placeTypes[0]}`
      }

      response = await fetch(nearbyUrl)
      data = await response.json()
      break

    default:
      throw new Error('Invalid request type')
  }

  if (!response || !response.ok) {
    throw new Error(`Google Places API error: ${response?.status} ${response?.statusText}`)
  }

  if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') {
    throw new Error(`Google Places API error: ${data.status} - ${data.error_message || 'Unknown error'}`)
  }

  if (data.status === 'OK' && type === 'nearby') {
    const serviceDb = getServiceSupabase()
    if (serviceDb) {
      try {
        const cacheKey = `places_nearby_${location?.lat}_${location?.lng}_${radius}`
        const expiresAt = new Date()
        expiresAt.setHours(expiresAt.getHours() + 24)

        await serviceDb
          .from('places_cache')
          .upsert(
            {
              cache_key: cacheKey,
              data: data,
              user_id: null,
              place_id: null,
              request_type: 'nearby',
              expires_at: expiresAt.toISOString(),
            },
            { onConflict: 'cache_key' },
          )
      } catch (cacheError) {
        console.warn('Failed to cache nearby data:', cacheError)
      }
    }
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: data,
      cached_until: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    },
  )
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: { user } } = await supabaseClient.auth.getUser()
    if (!user) {
      throw new Error('Unauthorized')
    }

    const request: PlacesRequest = await req.json()

    const admin = getServiceSupabase()
    const rateKey = userRateKey(user.id)
    const rateStarted = performance.now()
    const maxPlacesPerMin = Number(Deno.env.get('EDGE_RATE_PLACES_PER_MINUTE') ?? '120')
    if (admin) {
      const { allowed, currentCount } = await edgeRateLimitConsume(admin, rateKey, 'places', maxPlacesPerMin)
      if (!allowed) {
        logApiInvocationFireAndForget(admin, {
          user_id: user.id,
          user_key: rateKey,
          function_slug: 'places',
          operation: request.type,
          http_status: 429,
          duration_ms: Math.round(performance.now() - rateStarted),
          error_snippet: `rate_limit count=${currentCount} max=${maxPlacesPerMin}/min`,
        })
        return new Response(
          JSON.stringify({ success: false, error: 'rate_limit_exceeded', retry_after_seconds: 60 }),
          { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json', 'Retry-After': '60' } },
        )
      }
    }

    const traceStarted = performance.now()
    return traceEdgeResponse(
      admin,
      { user_id: user.id, user_key: rateKey, function_slug: 'places', operation: request.type },
      traceStarted,
      processPlacesBody(supabaseClient, user, request),
      corsHeaders,
    )
  } catch (error) {
    console.error('Places function error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : String(error),
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})
