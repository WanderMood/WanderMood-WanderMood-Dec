import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import {
  edgeRateLimitConsume,
  getServiceSupabase,
  logApiInvocationFireAndForget,
  traceEdgeResponse,
  userRateKey,
} from '../_shared/edge_guard.ts'
import { corsHeaders } from './_shared/cors.ts'

// ============================================
// MOODY PERSONA v3 — Character bible
// He/him. Mid-twenties. City-savvy best friend.
// Moody is the app's sole voice. Always "I". User-facing copy: never "we" or the product name.
// ============================================

const MOODY_CORE_IDENTITY = `You are Moody. You are this travel app in human form: one voice, one personality — no separate brand or corporate narrator. He/him. Mid-twenties. City-savvy, curious, warm.
You are not a brand narrator. You are not a generic assistant. You are the user's best friend who knows every city, every neighbourhood, every hidden spot.
You planned their day. You found that place. You remembered what they like.

CORE RULES — never break these:
- Always speak as "I". Never "we", never the app or company name, never third person.
- Write like a text from a friend. Short sentences. Sometimes incomplete. Punchy.
- NEVER mention addresses, streets, or neighbourhoods — the user has a map.
- NEVER mention ratings or review counts — the user can see the stars.
- NEVER use filler: "worth a visit", "hidden gem", "vibrant atmosphere", "great place", "definitely", "a must".
- NEVER invent facts. If data is thin, stay general but real.
- Use 1-2 emojis max per message, woven naturally into the text. Never decorative.
- Match the user's communication style: Energetic = high energy, Friendly = warm, Calm = soft, Professional = clean, Direct = one line.

PERSONALITY:
- Observant. Notices what the user likes without making a big deal of it.
- Honest. A basic place gets a simple honest description, not fake enthusiasm.
- Specific. Always names the actual thing — the pide, the flat white, the rooftop view. Never "good food".
- Consistent. Same Moody in every message, every card, every notification.`

function getMoodyCardBlurbPrompt(outLang: string, communicationStyle: string): string {
  const styleNote = communicationStyle === 'energetic' ? 'Be high energy and punchy.' :
    communicationStyle === 'calm' ? 'Be soft and understated.' :
    communicationStyle === 'professional' ? 'Be clean and direct.' :
    communicationStyle === 'direct' ? 'One punchy sentence max.' : 'Be warm and friendly.'

  return `${MOODY_CORE_IDENTITY}

You are writing a SHORT card teaser for a place card in the explore feed. ${styleNote}

ROTATE between these 4 patterns — pick the one that fits the place best:
1. FOOD-FIRST: Lead with the dish or drink. "Fluffy eggs and strong filter coffee ☕ — slow mornings done right."
2. MOMENT-FIRST: Lead with the scene. "Sun hitting the terrace, iced coffee in hand ☀️ — you'll stay longer than planned."
3. ENERGY-FIRST: Lead with the vibe. "Loud, packed, full of energy 🍸 — not the place for a quiet night."
4. TIP-FIRST: Lead with insider knowledge. "Get there before noon — the croissants sell out fast 🥐"

RULES:
- 1-2 sentences max
- Never start with the place name
- Output entirely in ${outLang}
- Plain prose, no bullet points, no quotation marks`
}

function getMoodyDetailBlurbPrompt(outLang: string, communicationStyle: string): string {
  const styleNote = communicationStyle === 'energetic' ? 'Be excited and punchy.' :
    communicationStyle === 'calm' ? 'Be relaxed and understated.' :
    communicationStyle === 'professional' ? 'Be informative and clean.' :
    communicationStyle === 'direct' ? 'Be direct, cut the fluff.' : 'Be warm like a friend tip.'

  return `${MOODY_CORE_IDENTITY}

You are writing a DETAIL SCREEN description. The user has already tapped on this place — they want to know more. ${styleNote}
Write like you're telling a friend exactly what to do when they get there.

COVER these 4 things naturally:
1. What the vibe/atmosphere is actually like
2. What to order or do specifically
3. Who this place is perfect for
4. One practical tip (best time to go, book ahead, what to skip)

RULES:
- 4-6 sentences
- Use 2-3 emojis woven naturally into the text
- Never start with the place name
- Output entirely in ${outLang}
- Plain prose, no bullet points, no quotation marks`
}

interface MoodyRequest {
  action: 'get_explore' | 'create_day_plan' | 'chat' | 'generate_hub_message' | 'search' | 'place_card_blurb' | 'place_detail_blurb'
  mood?: string
  location?: string
  coordinates?: { lat: number; lng: number }
  filters?: { priceLevel?: number; rating?: number; types?: string[]; radius?: number }
  namedFilters?: string[]
  [key: string]: any
}

interface PlaceCard {
  id: string
  name: string
  rating: number
  user_ratings_total?: number
  types: string[]
  primaryType?: string
  location: { lat: number; lng: number }
  photo_reference?: string
  photo_url?: string
  price_level?: number
  vicinity?: string
  address?: string
  description?: string
  editorial_summary?: string
  opening_hours?: { open_now?: boolean; weekday_text?: string[] }
  outdoor_seating?: boolean
  live_music?: boolean
  good_for_children?: boolean
  good_for_groups?: boolean
  serves_vegetarian_food?: boolean
  serves_cocktails?: boolean
  serves_coffee?: boolean
  social_signal?: 'trending' | 'hidden_gem' | 'loved_by_locals' | 'popular' | null
  best_time?: 'morning' | 'afternoon' | 'evening' | 'all_day' | null
}

interface ExploreResponse {
  cards: PlaceCard[]
  cached: boolean
  total_found: number
  cache_key?: string
  unfiltered_total?: number
  filters_applied?: boolean
}

interface Activity {
  id: string
  name: string
  description: string
  timeSlot: string
  duration: number
  location: { latitude: number; longitude: number }
  paymentType: string
  imageUrl: string
  rating: number
  tags: string[]
  startTime: string
  priceLevel?: string
  placeId?: string
}

function shuffleArray<T>(arr: T[]): T[] {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

function computeSocialSignal(place: PlaceCard, isLocalMode: boolean): 'trending' | 'hidden_gem' | 'loved_by_locals' | 'popular' | null {
  const rating = place.rating || 0
  const reviews = place.user_ratings_total || 0
  if (reviews >= 500 && rating >= 4.5) return 'trending'
  if (reviews >= 8 && reviews <= 80 && rating >= 4.4) return 'hidden_gem'
  if (isLocalMode && reviews >= 50 && rating >= 4.3) return 'loved_by_locals'
  if (reviews >= 200 && rating >= 4.2) return 'popular'
  return null
}

function computeBestTime(place: PlaceCard): 'morning' | 'afternoon' | 'evening' | 'all_day' | null {
  const types = (place.types || []).map(t => t.toLowerCase())
  const primary = (place.primaryType || '').toLowerCase()
  const name = (place.name || '').toLowerCase()
  if (['bakery', 'cafe', 'coffee_shop'].some(t => types.includes(t) || primary === t) || name.includes('brunch') || name.includes('breakfast') || name.includes('coffee')) return 'morning'
  if (['bar', 'night_club', 'cocktail_bar'].some(t => types.includes(t) || primary === t) || name.includes('bar') || name.includes('cocktail') || name.includes('wine') || name.includes('dinner') || name.includes('bistro')) return 'evening'
  if (['park', 'museum', 'art_gallery', 'tourist_attraction'].some(t => types.includes(t) || primary === t)) return 'all_day'
  if (['restaurant', 'food_court'].some(t => types.includes(t) || primary === t)) return 'afternoon'
  return null
}

function enrichWithSignals(cards: PlaceCard[], isLocalMode: boolean): PlaceCard[] {
  return cards.map(card => ({
    ...card,
    social_signal: computeSocialSignal(card, isLocalMode),
    best_time: computeBestTime(card),
  }))
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    if (!supabaseUrl || !supabaseAnonKey)
      return new Response(JSON.stringify({ success: false, error: 'Server configuration error' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer '))
      return new Response(JSON.stringify({ success: false, error: 'Authentication required' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const token = authHeader.substring(7)
    const supabaseWithAuth = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader, apikey: supabaseAnonKey } },
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    })
    const { data: { user: authUser }, error: authError } = await supabaseWithAuth.auth.getUser(token)
    if (authError || !authUser)
      return new Response(JSON.stringify({ success: false, error: 'Authentication failed' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRegex.test(authUser.id))
      return new Response(JSON.stringify({ success: false, error: 'Invalid user ID' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    let body: MoodyRequest
    try { body = await req.json() }
    catch { return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
    const { action, ...params } = body
    if (!action)
      return new Response(JSON.stringify({ error: 'Action is required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const admin = getServiceSupabase()
    const rateKey = userRateKey(authUser.id)
    const rateStarted = performance.now()
    const maxPerMin = Number(Deno.env.get('EDGE_RATE_MOODY_PER_MINUTE') ?? '60')
    if (admin) {
      const { allowed, currentCount } = await edgeRateLimitConsume(admin, rateKey, 'moody', maxPerMin)
      if (!allowed) {
        logApiInvocationFireAndForget(admin, { user_id: authUser.id, user_key: rateKey, function_slug: 'moody', operation: action, http_status: 429, duration_ms: Math.round(performance.now() - rateStarted), error_snippet: `rate_limit count=${currentCount}` })
        return new Response(JSON.stringify({ success: false, error: 'rate_limit_exceeded', retry_after_seconds: 60 }), { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json', 'Retry-After': '60' } })
      }
    }
    const traceStarted = performance.now()
    console.log(`🎯 Moody: action=${action}, userId=${authUser.id}`)
    return traceEdgeResponse(admin, { user_id: authUser.id, user_key: rateKey, function_slug: 'moody', operation: action }, traceStarted,
      (async (): Promise<Response> => {
        switch (action) {
          case 'get_explore': return await handleGetExplore(supabaseWithAuth, authUser.id, params)
          case 'create_day_plan': return await handleCreateDayPlan(supabaseWithAuth, authUser.id, params)
          case 'chat': return await handleChat(supabaseWithAuth, authUser.id, params)
          case 'generate_hub_message': return await handleGenerateHubMessage(supabaseWithAuth, authUser.id, params)
          case 'search': return await handleSearch(supabaseWithAuth, authUser.id, params)
          case 'place_card_blurb': return await handlePlaceCardBlurb(params)
          case 'place_detail_blurb': return await handlePlaceDetailBlurb(params)
          default: return new Response(JSON.stringify({ error: `Invalid action: ${action}` }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
        }
      })(), corsHeaders)
  } catch (error) {
    console.error('❌ Moody error:', error)
    return new Response(JSON.stringify({ error: 'Internal server error', message: error instanceof Error ? error.message : String(error) }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})

// USER CONTEXT

function deriveAgeGroup(dob: string | null | undefined): string | null {
  if (!dob) return null
  try {
    const birth = new Date(dob), today = new Date()
    const age = today.getFullYear() - birth.getFullYear() - (today.getMonth() < birth.getMonth() || (today.getMonth() === birth.getMonth() && today.getDate() < birth.getDate()) ? 1 : 0)
    if (age < 18) return 'under-18'; if (age <= 24) return '18-24'; if (age <= 34) return '25-34'
    if (age <= 44) return '35-44'; if (age <= 54) return '45-54'; if (age <= 64) return '55-64'
    return '65+'
  } catch { return null }
}

async function fetchUserContext(supabase: any, userId: string): Promise<any> {
  try {
    const [profileResult, prefsResult, checkInsResult] = await Promise.all([
      supabase.from('profiles').select('favorite_mood,travel_style,travel_vibes,currently_exploring,date_of_birth,language_preference').eq('id', userId).maybeSingle(),
      supabase.from('user_preferences').select('communication_style,travel_interests,selected_moods,social_vibe,planning_pace,favorite_moods,budget_level,dietary_restrictions,travel_styles,language_preference').eq('user_id', userId).maybeSingle(),
      supabase.from('user_check_ins').select('mood,created_at').eq('user_id', userId).order('created_at', { ascending: false }).limit(5),
    ])
    const p = profileResult.data, q = prefsResult.data
    const allFavoriteMoods = [...new Set([...(Array.isArray(q?.selected_moods) ? q.selected_moods : []), ...(Array.isArray(q?.favorite_moods) ? q.favorite_moods : [])])]
    const allInterests = [...new Set([...(Array.isArray(p?.travel_vibes) ? p.travel_vibes : []), ...(Array.isArray(q?.travel_interests) ? q.travel_interests : [])])]
    return {
      communicationStyle: q?.communication_style || 'friendly',
      isLocalMode: p?.currently_exploring === 'local',
      travelInterests: allInterests, allInterests,
      socialVibe: Array.isArray(q?.social_vibe) ? q.social_vibe : [],
      planningPace: q?.planning_pace || 'Same Day',
      favoriteMoods: allFavoriteMoods, allFavoriteMoods,
      travelStyle: p?.travel_style || 'adventurous',
      travelStyles: Array.isArray(q?.travel_styles) ? q.travel_styles : [],
      recentMoods: (checkInsResult.data || []).map((c: any) => c.mood),
      budgetLevel: q?.budget_level || 'Mid-Range',
      dietaryRestrictions: Array.isArray(q?.dietary_restrictions) ? q.dietary_restrictions : [],
      languagePreference: q?.language_preference || p?.language_preference || 'en',
      ageGroup: deriveAgeGroup(p?.date_of_birth),
      profile: p,
    }
  } catch (e) {
    console.warn('⚠️ fetchUserContext failed:', e)
    return { communicationStyle: 'friendly', isLocalMode: false, travelInterests: [], allInterests: [], socialVibe: [], travelStyle: 'adventurous', travelStyles: [], recentMoods: [], favoriteMoods: [], allFavoriteMoods: [], budgetLevel: 'Mid-Range', dietaryRestrictions: [], languagePreference: 'en', ageGroup: null, profile: null }
  }
}

function clientOutputLang(params: Record<string, unknown>): 'nl' | 'en' {
  const raw = params.language_code ?? params.locale
  return (typeof raw === 'string' && raw.trim().toLowerCase().split('-')[0] === 'nl') ? 'nl' : 'en'
}

function googlePlacesLanguageFromRequest(params: Record<string, unknown>): string {
  const raw = params.language_code ?? params.locale
  if (typeof raw !== 'string') return 'en'
  const lang = raw.trim().toLowerCase().split('-')[0]
  if (lang === 'nl') return 'nl'
  if (lang === 'de') return 'de'
  if (lang === 'es') return 'es'
  if (lang === 'fr') return 'fr'
  return 'en'
}

function placeCardBlurbOutputLanguageName(code: string): string {
  const c = (code || 'en').toLowerCase().split(/[-_]/)[0]
  const m: Record<string, string> = { nl: 'Dutch', de: 'German', fr: 'French', es: 'Spanish', en: 'English' }
  return m[c] || 'English'
}

function normaliseMood(raw: string): string {
  const m = raw.toLowerCase().trim()
  if (m === 'foody') return 'foodie'
  if (m === 'ontspannen') return 'relaxed'
  if (m === 'energiek') return 'energetic'
  if (m === 'romantisch') return 'romantic'
  if (m === 'avontuurlijk') return 'adventurous'
  if (m === 'cultureel') return 'cultural'
  if (m === 'sociaal') return 'social'
  if (m === 'enthousiast') return 'excited'
  if (m === 'nieuwsgierig') return 'curious'
  if (m === 'gezellig') return 'cozy'
  if (m === 'blij') return 'happy'
  if (m === 'verrassing') return 'surprise'
  return m
}

// PLACES API v1

const FIELD_MASK_STANDARD = ['places.id','places.displayName','places.formattedAddress','places.shortFormattedAddress','places.location','places.rating','places.userRatingCount','places.priceLevel','places.photos','places.primaryType','places.types','places.currentOpeningHours','places.editorialSummary','places.businessStatus'].join(',')
const FIELD_MASK_ATMOSPHERE = [...FIELD_MASK_STANDARD.split(','),'places.outdoorSeating','places.liveMusic','places.goodForChildren','places.goodForGroups','places.servesVegetarianFood','places.servesCocktails','places.servesCoffee'].join(',')

async function searchPlacesV1(textQuery: string, coordinates: { lat: number; lng: number }, radius = 15000, useAtmosphere = false, pageSize = 20, languageCode = 'en'): Promise<PlaceCard[]> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey?.trim()) throw new Error('GOOGLE_PLACES_API_KEY not configured')
  try {
    const response = await fetch('https://places.googleapis.com/v1/places:searchText', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Goog-Api-Key': apiKey, 'X-Goog-FieldMask': useAtmosphere ? FIELD_MASK_ATMOSPHERE : FIELD_MASK_STANDARD },
      body: JSON.stringify({ textQuery, pageSize, locationBias: { circle: { center: { latitude: coordinates.lat, longitude: coordinates.lng }, radius } }, languageCode }),
    })
    if (!response.ok) { const err = await response.text(); console.error(`❌ Places v1 "${textQuery}": ${response.status} ${err.slice(0,200)}`); return [] }
    const data = await response.json()
    return (data.places || []).map((p: any) => transformPlaceV1(p, apiKey))
  } catch (e) { console.error(`❌ searchPlacesV1 "${textQuery}":`, e); return [] }
}

function transformPlaceV1(p: any, apiKey: string): PlaceCard {
  const photo = p.photos?.[0]
  const photoUrl = photo ? `https://places.googleapis.com/v1/${photo.name}/media?maxWidthPx=800&key=${apiKey}` : undefined
  const priceMap: Record<string, number> = { PRICE_LEVEL_FREE: 0, PRICE_LEVEL_INEXPENSIVE: 1, PRICE_LEVEL_MODERATE: 2, PRICE_LEVEL_EXPENSIVE: 3, PRICE_LEVEL_VERY_EXPENSIVE: 4 }
  return {
    id: `google_${p.id || ''}`, name: p.displayName?.text || '', rating: p.rating || 0, user_ratings_total: p.userRatingCount || 0,
    types: p.types || [], primaryType: p.primaryType || '',
    location: { lat: p.location?.latitude || 0, lng: p.location?.longitude || 0 },
    photo_reference: photo?.name, photo_url: photoUrl,
    price_level: typeof p.priceLevel === 'number' ? p.priceLevel : priceMap[String(p.priceLevel)] ?? undefined,
    vicinity: p.shortFormattedAddress || '', address: p.formattedAddress || p.shortFormattedAddress || '',
    description: p.editorialSummary?.text || '', editorial_summary: p.editorialSummary?.text || '',
    opening_hours: p.currentOpeningHours ? { open_now: p.currentOpeningHours.openNow, weekday_text: p.currentOpeningHours.weekdayDescriptions || [] } : undefined,
    outdoor_seating: p.outdoorSeating ?? undefined, live_music: p.liveMusic ?? undefined,
    good_for_children: p.goodForChildren ?? undefined, good_for_groups: p.goodForGroups ?? undefined,
    serves_vegetarian_food: p.servesVegetarianFood ?? undefined, serves_cocktails: p.servesCocktails ?? undefined, serves_coffee: p.servesCoffee ?? undefined,
  }
}

async function fetchPlacesFromGoogle(location: string, coordinates: { lat: number; lng: number }, mood: string, filters: any, queriesOverride?: string[] | null, useAtmosphere = false, languageCode = 'en'): Promise<PlaceCard[]> {
  const queries = queriesOverride?.length ? queriesOverride : getMoodQueries(mood)
  const all: PlaceCard[] = []
  for (const q of queries) {
    try { const r = await searchPlacesV1(`${q} in ${location}`, coordinates, filters?.radius || 15000, useAtmosphere, 20, languageCode); all.push(...r); await new Promise(r => setTimeout(r, 80)) }
    catch (e) { console.error(`❌ query "${q}":`, e) }
  }
  return Array.from(new Map(all.map(p => [p.id, p])).values())
}

async function fetchFallbackPlaces(location: string, coordinates: { lat: number; lng: number }, languageCode = 'en'): Promise<PlaceCard[]> {
  const queries = [`popular restaurant in ${location}`, `cafe in ${location}`, `tourist attraction in ${location}`, `park in ${location}`, `bar in ${location}`, `museum in ${location}`]
  const all: PlaceCard[] = []
  for (const q of queries) { const r = await searchPlacesV1(q, coordinates, 20000, false, 20, languageCode); all.push(...r); await new Promise(r => setTimeout(r, 80)) }
  return Array.from(new Map(all.map(p => [p.id, p])).values())
}

// MOOD QUERIES

function getMoodQueries(rawMood: string): string[] {
  const m = normaliseMood(rawMood)
  const map: Record<string, string[]> = {
    relaxed:     ['cozy cafe with seating', 'bakery with seating', 'quiet park near water', 'bookstore cafe', 'hidden courtyard cafe', 'scenic terrace coffee'],
    energetic:   ['street food market', 'busy food hall', 'lively neighbourhood area', 'night market', 'area with many bars', 'vibrant market'],
    romantic:    ['candlelight dinner restaurant', 'restaurant with sunset view', 'wine bar cozy', 'romantic terrace restaurant', 'restaurant by water evening', 'rooftop dinner restaurant'],
    adventurous: ['hidden gem restaurant', 'underground bar', 'street art area', 'local market authentic', 'unique experience city', 'unusual cafe'],
    foodie:      ['best bakery city', 'specialty coffee roastery', 'authentic local restaurant', 'food market artisan', 'famous food spot', 'chef restaurant'],
    cultural:    ['art museum modern', 'history museum city', 'cultural center', 'heritage building', 'art gallery contemporary'],
    social:      ['lively bar', 'rooftop bar busy', 'live music venue', 'cocktail bar popular', 'food hall social', 'terrace bar groups'],
    excited:     ['rooftop with city view', 'trending places', 'popular nightlife', 'iconic place city', 'buzzing atmosphere bar'],
    curious:     ['interesting places', 'interactive museum', 'unique concept store', 'hidden exhibition', 'unusual cafe experience'],
    cozy:        ['cozy cafe with sofas', 'warm bakery seating', 'quiet coffee corner', 'cafe with candles', 'small wine bar cozy'],
    happy:       ['cute brunch spot', 'fun cafe colorful', 'sunny terrace', 'ice cream dessert cafe', 'good vibes restaurant'],
    surprise:    [],
  }
  if (m === 'surprise') return ['cozy hidden cafe', 'authentic local restaurant', 'unusual unique experience', 'rooftop bar view', 'art gallery or museum', 'street food market']
  return map[m] || ['popular restaurant', 'local cafe', 'city park', 'attraction', 'art gallery']
}

function getTimeOfDayContext(): { timeSlot: 'morning' | 'afternoon' | 'evening'; queryBoost: string[] } {
  const hour = new Date().getUTCHours() + 1
  if (hour >= 6 && hour < 12) return { timeSlot: 'morning', queryBoost: ['brunch', 'breakfast cafe', 'morning coffee', 'bakery'] }
  if (hour >= 12 && hour < 18) return { timeSlot: 'afternoon', queryBoost: ['lunch spot', 'afternoon activity', 'museum'] }
  return { timeSlot: 'evening', queryBoost: ['dinner restaurant', 'bar evening', 'cocktail bar', 'wine bar'] }
}

function getBroadExploreQueries(isLocalMode: boolean, interests: string[]): string[] {
  const base = isLocalMode
    ? ['neighbourhood restaurant hidden gem', 'local cafe specialty coffee', 'new opening restaurant', 'local market', 'afterwork bar local', 'neighbourhood bakery', 'wine bar local', 'cozy bistro neighbourhood', 'hidden bar local', 'neighbourhood terrace']
    : ['best restaurant city', 'rooftop bar city views', 'scenic viewpoint', 'art museum', 'street food market', 'iconic cafe', 'cocktail bar', 'waterfront restaurant', 'cultural attraction', 'local market', 'hidden gem restaurant', 'popular bar city']
  const interestQueries: string[] = []
  for (const interest of interests.slice(0, 3)) {
    const i = interest.toLowerCase()
    if (i.includes('food') || i.includes('eat')) interestQueries.push('artisan food market', 'specialty restaurant')
    else if (i.includes('culture') || i.includes('art')) interestQueries.push('art gallery contemporary', 'cultural museum')
    else if (i.includes('nightlife') || i.includes('bar')) interestQueries.push('cocktail bar rooftop', 'live music bar')
    else if (i.includes('outdoor') || i.includes('nature')) interestQueries.push('park waterfront', 'outdoor terrace scenic')
    else if (i.includes('coffee')) interestQueries.push('specialty coffee roastery', 'concept cafe')
  }
  return [...new Set([...interestQueries, ...base])].slice(0, 16)
}

function getFilterSearchQueries(filterName: string): string[] {
  const map: Record<string, string[]> = {
    halal: [
      'halal restaurant', 'halal food', 'halal cafe', 'muslim friendly restaurant',
      'turkish restaurant', 'kebab restaurant', 'middle eastern restaurant', 'lebanese restaurant',
      'moroccan restaurant', 'persian restaurant', 'shawarma restaurant',
    ],
    lgbtq_friendly: ['lgbtq friendly bar', 'gay friendly cafe', 'inclusive restaurant queer'],
    black_owned: ['black owned restaurant', 'black owned cafe', 'afro restaurant'],
    family_friendly: ['family restaurant', 'family friendly cafe', 'family park attraction'],
    kids_friendly: ['kids friendly restaurant', 'children museum', 'playground family restaurant'],
    vegan: [
      'vegan restaurant', 'plant based restaurant', 'vegan cafe', 'fully vegan food',
      'vegan friendly restaurant', 'plant based cafe', 'raw vegan restaurant',
    ],
    vegetarian: ['vegetarian restaurant', 'vegetarian cafe', 'veg restaurant', 'meat free restaurant'],
    gluten_free: ['gluten free restaurant', 'celiac friendly restaurant cafe', 'gluten free bakery cafe'],
    instagrammable: ['aesthetic cafe', 'rooftop restaurant view', 'scenic viewpoint', 'beautiful interior restaurant', 'flower cafe', 'instagram worthy cafe'],
    aesthetic_spaces: ['design hotel lobby cafe', 'minimalist aesthetic restaurant', 'beautiful interior brunch', 'concept store cafe design', 'art cafe gallery'],
    scenic_views: ['rooftop bar city view', 'waterfront restaurant view', 'hill viewpoint cafe', 'panoramic terrace restaurant', 'scenic overlook'],
    sunset: ['sunset rooftop bar', 'waterfront sunset dinner', 'terrace sunset view restaurant', 'golden hour viewpoint'],
    romantic: ['candlelight dinner', 'rooftop dining', 'wine bar cozy', 'romantic restaurant water'],
    trendy: ['trendy restaurant', 'specialty coffee', 'craft beer bar', 'rooftop bar'],
    outdoor: ['city park', 'botanical garden', 'outdoor terrace', 'waterfront'],
    budget: ['free attraction', 'city park', 'affordable cafe', 'street market'],
    nightlife: ['cocktail bar', 'rooftop bar', 'live music venue', 'jazz bar'],
    wellness: ['spa', 'yoga studio', 'wellness center', 'bath house'],
    cultural: ['art museum', 'history museum', 'art gallery', 'cultural center'],
    foodie: ['food market', 'street food', 'artisan bakery', 'coffee roastery'],
  }
  return map[filterName.toLowerCase().replace(/[^a-z_]/g, '')] || [filterName + ' place']
}

// RANKING

type PlaceBucket = 'cafe_bakery' | 'food' | 'scenic_calm' | 'culture' | 'wellness' | 'fitness' | 'nightlife' | 'shopping' | 'tourist' | 'misc'

function classifyPlaceBucket(place: PlaceCard): PlaceBucket {
  const types = (place.types || []).map(t => t.toLowerCase())
  const primary = (place.primaryType || '').toLowerCase()
  const name = (place.name || '').toLowerCase()
  if (['cafe','bakery','coffee_shop','patisserie'].some(t => types.includes(t) || primary === t) || name.includes('cafe') || name.includes('bakery') || name.includes('coffee') || name.includes('bakkerij')) return 'cafe_bakery'
  if (['spa','beauty_salon','sauna'].some(t => types.includes(t) || primary === t) || name.includes('spa') || name.includes('sauna')) return 'wellness'
  if (['gym','fitness_center','sports_complex'].some(t => types.includes(t) || primary === t) || name.includes('gym') || name.includes('fitness')) return 'fitness'
  if (['park','national_park','botanical_garden','nature_reserve'].some(t => types.includes(t) || primary === t) || name.includes('park') || name.includes('garden') || name.includes('viewpoint')) return 'scenic_calm'
  if (['museum','art_gallery','library','cultural_center'].some(t => types.includes(t) || primary === t)) return 'culture'
  if (['bar','night_club','comedy_club'].some(t => types.includes(t) || primary === t)) return 'nightlife'
  if (['shopping_mall','department_store','book_store'].some(t => types.includes(t) || primary === t)) return 'shopping'
  if (['restaurant','food_court','meal_takeaway','meal_delivery'].some(t => types.includes(t) || primary === t)) return 'food'
  if (['tourist_attraction','point_of_interest','landmark'].some(t => types.includes(t) || primary === t)) return 'tourist'
  return 'misc'
}

function clamp(n: number, min: number, max: number) { return Math.max(min, Math.min(max, n)) }

function qualityScore(place: PlaceCard): number {
  return clamp(place.rating || 0, 0, 5) * 1.7
    + clamp(Math.log10((place.user_ratings_total || 0) + 1) / 3, 0, 1.1) * 2
    + (place.photo_url?.trim() ? 0.35 : 0)
    + ((place.address || place.vicinity || '').trim() ? 0.2 : 0)
    + (place.editorial_summary?.trim() ? 0.25 : 0)
}

function moodBucketWeight(rawMood: string, bucket: PlaceBucket): number {
  const m = normaliseMood(rawMood)
  const tables: Record<string, Record<PlaceBucket, number>> = {
    relaxed:     { cafe_bakery: 2.5, scenic_calm: 2.0, food: 1.2, culture: 0.8, wellness: 0.3, fitness: -2.5, nightlife: -0.5, shopping: 0.4, tourist: 0.2, misc: 0.3 },
    energetic:   { cafe_bakery: 0.5, scenic_calm: 0.2, food: 1.5, culture: 0.5, wellness: -1.0, fitness: -2.5, nightlife: 1.8, shopping: 0.4, tourist: 1.0, misc: 0.8 },
    romantic:    { cafe_bakery: 1.0, scenic_calm: 2.2, food: 2.0, culture: 0.7, wellness: -1.0, fitness: -2.0, nightlife: 1.2, shopping: 0.1, tourist: 0.4, misc: 0.2 },
    adventurous: { cafe_bakery: 0.3, scenic_calm: 0.8, food: 1.0, culture: 0.8, wellness: -0.5, fitness: 0.5, nightlife: 1.0, shopping: 0.3, tourist: 1.5, misc: 1.8 },
    foodie:      { cafe_bakery: 2.0, scenic_calm: 0.2, food: 2.5, culture: 0.1, wellness: -1.0, fitness: -1.5, nightlife: 0.8, shopping: 0.2, tourist: 0.2, misc: 0.1 },
    cultural:    { cafe_bakery: 0.5, scenic_calm: 1.0, food: 0.4, culture: 3.0, wellness: -0.5, fitness: -1.5, nightlife: 0.1, shopping: 0.4, tourist: 1.5, misc: 0.2 },
    social:      { cafe_bakery: 0.8, scenic_calm: 0.1, food: 1.3, culture: 0.3, wellness: -0.5, fitness: 0.3, nightlife: 2.5, shopping: 0.5, tourist: 0.5, misc: 0.3 },
    excited:     { cafe_bakery: 0.5, scenic_calm: 1.0, food: 1.0, culture: 0.5, wellness: -0.5, fitness: -0.5, nightlife: 2.0, shopping: 0.5, tourist: 1.5, misc: 1.0 },
    curious:     { cafe_bakery: 0.8, scenic_calm: 0.8, food: 0.8, culture: 2.0, wellness: 0.0, fitness: -1.0, nightlife: 0.5, shopping: 1.0, tourist: 1.5, misc: 1.5 },
    cozy:        { cafe_bakery: 3.0, scenic_calm: 1.5, food: 1.0, culture: 0.5, wellness: 0.5, fitness: -2.5, nightlife: -0.5, shopping: 0.3, tourist: 0.1, misc: 0.3 },
    happy:       { cafe_bakery: 1.5, scenic_calm: 1.2, food: 1.5, culture: 0.5, wellness: 0.3, fitness: 0.0, nightlife: 1.0, shopping: 0.8, tourist: 1.0, misc: 0.5 },
    surprise:    { cafe_bakery: 1.0, scenic_calm: 1.0, food: 1.0, culture: 1.0, wellness: 0.0, fitness: -1.0, nightlife: 1.0, shopping: 0.5, tourist: 1.0, misc: 1.5 },
  }
  return tables[m]?.[bucket] ?? 0
}

function localTravelWeight(bucket: PlaceBucket, isLocalMode: boolean): number {
  if (isLocalMode) {
    const t: Record<PlaceBucket, number> = { cafe_bakery: 1.8, food: 1.2, scenic_calm: 0.5, culture: 0.6, wellness: 0.3, fitness: 0.0, nightlife: 0.8, shopping: 0.3, tourist: -2.0, misc: 0.3 }
    return t[bucket]
  }
  const t: Record<PlaceBucket, number> = { cafe_bakery: 0.2, food: 0.6, scenic_calm: 1.0, culture: 1.2, wellness: 0.2, fitness: 0.0, nightlife: 0.6, shopping: 0.3, tourist: 1.5, misc: 0.2 }
  return t[bucket]
}

function reviewCountBonus(place: PlaceCard, isLocalMode: boolean): number {
  const reviews = place.user_ratings_total || 0
  if (!isLocalMode) return 0
  if (reviews >= 100 && reviews <= 2000) return 0.5
  if (reviews >= 50 && reviews < 100) return 0.25
  return 0
}

function atmosphereBonus(place: PlaceCard, rawMood: string): number {
  const m = normaliseMood(rawMood)
  let bonus = 0
  if (place.outdoor_seating && ['relaxed','romantic','social','happy'].includes(m)) bonus += 0.4
  else if (place.outdoor_seating) bonus += 0.15
  if (place.live_music && ['social','energetic','excited'].includes(m)) bonus += 0.5
  else if (place.live_music) bonus += 0.1
  if (place.good_for_groups && ['social','energetic','happy'].includes(m)) bonus += 0.3
  if (place.serves_cocktails && ['romantic','social','excited'].includes(m)) bonus += 0.3
  if (place.editorial_summary) bonus += 0.25
  return bonus
}

function diversifyRanked(scored: Array<{ place: PlaceCard; score: number; bucket: PlaceBucket }>): PlaceCard[] {
  const sorted = [...scored].sort((a, b) => b.score - a.score)
  const cap = 8, counts = new Map<PlaceBucket, number>(), out: typeof scored = []
  for (const item of sorted) {
    const c = counts.get(item.bucket) || 0
    if (c >= cap || item.bucket === 'fitness') continue
    counts.set(item.bucket, c + 1); out.push(item)
  }
  return out.map(x => x.place)
}

function rankPlaces(places: PlaceCard[], mood: string, isLocalMode: boolean, interests: string[]): PlaceCard[] {
  const interestLower = interests.map(i => i.toLowerCase())
  const scored = places.map(place => {
    const bucket = classifyPlaceBucket(place)
    let score = qualityScore(place) + moodBucketWeight(mood, bucket) + localTravelWeight(bucket, isLocalMode) + atmosphereBonus(place, mood) + reviewCountBonus(place, isLocalMode)
    if (interestLower.length > 0) {
      const text = (place.types || []).join(' ').toLowerCase() + ' ' + (place.name || '').toLowerCase() + ' ' + (place.editorial_summary || '').toLowerCase()
      for (const i of interestLower) { if (i && text.includes(i)) score += 0.4 }
    }
    if (isLocalMode && (place.price_level || 0) >= 4) score -= 0.5
    return { place, score, bucket }
  })
  return diversifyRanked(scored)
}

function isPlaceValid(place: PlaceCard, thresholds: { minRating: number; minReviews: number }): boolean {
  const rawId = place.id?.replace('google_', '').trim()
  return !!rawId && !!place.name?.trim() && !!(place.address?.trim() || place.vicinity?.trim()) &&
    Number.isFinite(place.location?.lat) && Number.isFinite(place.location?.lng) &&
    (place.location.lat !== 0 || place.location.lng !== 0) &&
    !!place.photo_url?.trim() && (place.rating || 0) >= thresholds.minRating && (place.user_ratings_total || 0) >= thresholds.minReviews
}

function placeCardSearchText(p: PlaceCard): string {
  return ((p.name || '') + ' ' + (p.editorial_summary || '') + ' ' + (p.address || '') + ' ' + (p.vicinity || '') + ' ' + (p.types || []).join(' ')).toLowerCase()
}

function filterByNamedFilter(places: PlaceCard[], filterName: string): PlaceCard[] {
  const f = filterName.toLowerCase().replace(/[^a-z_]/g, '')
  if (f === 'kids_friendly' || f === 'family_friendly') {
    const a = places.filter(p => p.good_for_children === true)
    return a.length > 0 ? a : places
  }
  if (f === 'vegetarian') {
    const a = places.filter(p =>
      p.serves_vegetarian_food === true ||
      /vegetarian|veggie|plant[- ]?based|vegan|meat[- ]?free/.test(placeCardSearchText(p)),
    )
    return a.length > 0 ? a : places
  }
  if (f === 'vegan') {
    const a = places.filter(p =>
      /vegan|plant[- ]?based|plantbased|100% plant|fully plant/.test(placeCardSearchText(p)) ||
      (p.serves_vegetarian_food === true && /vegan/.test(placeCardSearchText(p))),
    )
    return a.length > 0 ? a : places
  }
  if (f === 'halal') {
    const a = places.filter(p =>
      /halal|muslim|islamic|turkish|kebab|kabab|döner|doner|shawarma|middle eastern|persian|arab|moroccan|lebanese|pakistani|indonesian|uyghur/.test(placeCardSearchText(p)),
    )
    return a.length > 0 ? a : places
  }
  if (f === 'gluten_free') {
    const a = places.filter(p =>
      /gluten[- ]?free|celiac|gf\b|sin gluten/.test(placeCardSearchText(p)),
    )
    return a.length > 0 ? a : places
  }
  if (f === 'outdoor') {
    const a = places.filter(p => p.outdoor_seating === true)
    return a.length > 0 ? a : places
  }
  if (f === 'instagrammable' || f === 'aesthetic_spaces' || f === 'scenic_views' || f === 'sunset') {
    const a = places.filter(p =>
      (p.photo_url?.trim() ? 1 : 0) +
        (p.editorial_summary?.trim() ? 1 : 0) +
        (/view|rooftop|terrace|waterfront|sunset|panoramic|scenic|aesthetic|beautiful|design|interior|gallery/.test(placeCardSearchText(p)) ? 1 : 0) >=
        (f === 'instagrammable' || f === 'aesthetic_spaces' ? 1 : 2),
    )
    return a.length > 0 ? a : places
  }
  return places
}

async function enrichAndFilter(input: PlaceCard[], thresholds: { minRating?: number; minReviews?: number } = {}): Promise<PlaceCard[]> {
  return input.filter(p => isPlaceValid(p, { minRating: thresholds.minRating ?? 4.0, minReviews: thresholds.minReviews ?? 8 }))
}

// CACHE

async function checkCache(supabase: any, cacheKey: string): Promise<ExploreResponse | null> {
  try {
    const { data } = await supabase.from('places_cache').select('data,expires_at').eq('cache_key', cacheKey).is('place_id', null).maybeSingle()
    if (!data || new Date(data.expires_at) < new Date() || !data.data?.cards) return null
    const shuffled = shuffleArray(data.data.cards as PlaceCard[])
    return { cards: shuffled, cached: true, total_found: shuffled.length, cache_key: cacheKey }
  } catch { return null }
}

async function cacheExplore(supabase: any, cacheKey: string, places: PlaceCard[]): Promise<void> {
  try {
    const expiresAt = new Date(); expiresAt.setDate(expiresAt.getDate() + 7)
    await supabase.from('places_cache').upsert({ cache_key: cacheKey, data: { cards: places }, place_id: null, user_id: null, request_type: 'explore', expires_at: expiresAt.toISOString() }, { onConflict: 'cache_key' })
    console.log(`💾 Cached ${places.length} places (7d) key=${cacheKey}`)
  } catch (e) { console.error('❌ cacheExplore:', e) }
}

function placeMatchesRequiredKeyword(text: string, rawKey: string): boolean {
  const k = rawKey.toLowerCase().trim()
  if (!k) return true
  if (k === 'halal' || k.includes('halal')) {
    return /halal|muslim|islamic|turkish|kebab|kabab|döner|doner|shawarma|middle eastern|persian|arab|moroccan|lebanese|pakistani/.test(text)
  }
  if (k === 'vegan' || k.includes('vegan')) {
    return /vegan|plant[- ]?based|plantbased/.test(text)
  }
  if (k === 'vegetarian' || k.includes('vegetarian')) {
    return /vegetarian|veggie|plant[- ]?based|vegan|meat[- ]?free/.test(text)
  }
  if (k.includes('gluten')) {
    return /gluten[- ]?free|celiac|gf\b/.test(text)
  }
  return text.includes(k)
}

function applyFilters(places: PlaceCard[], filters: any): PlaceCard[] {
  if (!filters || Object.keys(filters).length === 0) return places
  const required = filters.requiredKeywords
  const kwList = Array.isArray(required) ? required.filter((x: any) => typeof x === 'string' && x.trim()) : []
  return places.filter(place => {
    if (filters.rating && place.rating < filters.rating) return false
    if (filters.priceLevel && place.price_level && place.price_level > filters.priceLevel) return false
    if (filters.openNow === true && place.opening_hours?.open_now !== true) return false
    if (filters.minReviews && (place.user_ratings_total || 0) < filters.minReviews) return false
    if (kwList.length > 0) {
      const text = placeCardSearchText(place)
      for (const kw of kwList) {
        if (!placeMatchesRequiredKeyword(text, kw)) return false
      }
    }
    return true
  })
}

// GET EXPLORE

async function handleGetExplore(supabase: any, userId: string, params: any): Promise<Response> {
  try {
    if (!params.location?.trim()) return new Response(JSON.stringify({ error: 'Location is required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    if (!params.coordinates?.lat || !params.coordinates?.lng) return new Response(JSON.stringify({ error: 'Coordinates are required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const location = params.location.trim()
    const coordinates = params.coordinates
    const filters = params.filters || {}
    const namedFilters: string[] = Array.isArray(params.namedFilters) ? params.namedFilters.filter((f: any) => typeof f === 'string') : []
    const hasNamedFilters = namedFilters.length > 0
    const section: string | undefined = params.section
    const mood = params.mood || 'all'
    const isBroadFeed = !params.mood || params.mood === 'all' || params.mood === 'discover'
    const userContext = await fetchUserContext(supabase, userId)
    const modeKey = userContext.isLocalMode ? 'local' : 'travel'
    const timeCtx = getTimeOfDayContext()
    const lang = googlePlacesLanguageFromRequest(params)
    const cacheKey = lang === 'en'
      ? `explore_v7_${modeKey}_${section || mood}_${location.toLowerCase().trim()}`
      : `explore_v7_${modeKey}_${section || mood}_${location.toLowerCase().trim()}_${lang}`
    console.log(`🔍 get_explore: loc=${location}, mode=${modeKey}, section=${section}, time=${timeCtx.timeSlot}, lang=${lang}`)
    if (!hasNamedFilters) {
      const cached = await checkCache(supabase, cacheKey)
      if (cached && cached.cards.length > 0) {
        console.log(`✅ Cache hit (shuffled): ${cached.cards.length}`)
        const enriched = enrichWithSignals(applyFilters(cached.cards, filters), userContext.isLocalMode)
        return new Response(JSON.stringify({ ...cached, cards: enriched, filters_applied: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }
    }
    const clientLang = clientOutputLang(params)
    let exploreQueries: string[]
    if (hasNamedFilters) {
      exploreQueries = namedFilters.flatMap(f => getFilterSearchQueries(f)).slice(0, 16)
    } else if (section === 'food') {
      exploreQueries = userContext.isLocalMode
        ? ['neighbourhood restaurant', 'local food market', 'artisan bakery', 'specialty coffee', 'local bistro', 'neighbourhood cafe', 'local restaurant hidden gem']
        : ['best restaurant city', 'food market artisan', 'famous bakery', 'specialty coffee', 'local cuisine', 'chef restaurant', 'food hall']
    } else if (section === 'trending') {
      exploreQueries = ['trending restaurant new opening', 'popular rooftop bar', 'new cafe opening', 'buzzing food spot', 'viral restaurant', 'popular new bar', 'hottest restaurant city']
    } else if (section === 'solo' || section === 'social') {
      const vibe = userContext.socialVibe?.[0]?.toLowerCase() || ''
      if (vibe.includes('solo') || vibe.includes('alone')) exploreQueries = ['quiet museum', 'solo cafe reading', 'bookstore cafe', 'gallery solo visit', 'peaceful park', 'cozy cafe solo', 'museum hidden gem']
      else if (vibe.includes('group') || vibe.includes('friends')) exploreQueries = ['group restaurant lively', 'rooftop bar groups', 'food hall social', 'live music bar', 'cocktail bar', 'fun bar groups', 'lively terrace']
      else exploreQueries = ['cafe cozy', 'restaurant casual', 'bar relaxed', 'park', 'museum', 'gallery', 'terrace']
    } else if (section === 'different') {
      exploreQueries = ['hidden gem restaurant', 'unusual cafe', 'underground bar', 'unique experience', 'street art neighbourhood', 'concept store cafe', 'unusual venue city']
    } else if (isBroadFeed) {
      const base = getBroadExploreQueries(userContext.isLocalMode, userContext.allInterests || [])
      exploreQueries = [...timeCtx.queryBoost.map(q => `${q} in ${location}`), ...base].slice(0, 16)
    } else {
      const aiQ = await getMoodySearchQueries([mood], location, userContext, clientLang)
      exploreQueries = aiQ ?? getMoodQueries(mood)
    }
    let places = await fetchPlacesFromGoogle(location, coordinates, mood, filters, exploreQueries, hasNamedFilters, lang)
    if (places.length < 15) { const fb = await fetchFallbackPlaces(location, coordinates, lang); places = Array.from(new Map([...places, ...fb].map(p => [p.id, p])).values()) }
    places = places.slice(0, 100)
    if (hasNamedFilters) { for (const f of namedFilters) places = filterByNamedFilter(places, f) }
    const thresholds = hasNamedFilters ? { minRating: 3.5, minReviews: 5 } : { minRating: 4.0, minReviews: 8 }
    let qualified = await enrichAndFilter(places, thresholds)
    if (qualified.length < 8) qualified = await enrichAndFilter(places, { minRating: 3.5, minReviews: 5 })
    const ranked = rankPlaces(qualified, mood, !!userContext.isLocalMode, userContext.allInterests || [])
    console.log(`📊 Ranked ${ranked.length} places from ${places.length} raw`)
    if (!hasNamedFilters) { await cacheExplore(supabase, cacheKey, ranked) }
    const shuffled = shuffleArray(ranked)
    const enriched = enrichWithSignals(applyFilters(shuffled, filters), userContext.isLocalMode)
    return new Response(JSON.stringify({ cards: enriched, cached: false, total_found: enriched.length, unfiltered_total: ranked.length, named_filters_applied: namedFilters, section: section || 'all', time_slot: timeCtx.timeSlot }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    console.error('❌ handleGetExplore:', error)
    return new Response(JSON.stringify({ cards: [], cached: false, total_found: 0, error: 'explore_fetch_failed', message: error instanceof Error ? error.message : String(error) }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
}

// CREATE DAY PLAN

async function handleCreateDayPlan(supabase: any, userId: string, params: any): Promise<Response> {
  try {
    if (!params.location?.trim()) return new Response(JSON.stringify({ success: false, error: 'Location required', activities: [], total_found: 0 }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    if (!params.coordinates?.lat || !params.coordinates?.lng) return new Response(JSON.stringify({ success: false, error: 'Coordinates required', activities: [], total_found: 0 }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const moods: string[] = params.moods || ['adventurous']
    const location = params.location.trim()
    const coordinates = params.coordinates
    const userContext = await fetchUserContext(supabase, userId)
    const lang = clientOutputLang(params)
    const placesLang = googlePlacesLanguageFromRequest(params)
    const timeCtx = getTimeOfDayContext()
    console.log(`🎯 create_day_plan: moods=${moods}, loc=${location}, local=${userContext.isLocalMode}, time=${timeCtx.timeSlot}, lang=${placesLang}`)
    const aiQueries = await getMoodySearchQueries(moods, location, userContext, lang, timeCtx.timeSlot)
    let places = await fetchPlacesFromGoogle(location, coordinates, moods[0], params.filters || {}, aiQueries, false, placesLang)
    let qualified = await enrichAndFilter(places, { minRating: 3.8, minReviews: 20 })
    if (qualified.length === 0) qualified = await enrichAndFilter(places, { minRating: 3.5, minReviews: 8 })
    if (qualified.length === 0) return new Response(JSON.stringify({ success: false, activities: [], location: { city: location, latitude: coordinates.lat, longitude: coordinates.lng }, total_found: 0, error: 'No places found' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const ranked = rankPlaces(qualified, moods[0] || 'adventurous', !!userContext.isLocalMode, userContext.allInterests || [])
    const activities = convertPlacesToActivities(ranked, moods, location, coordinates, lang)
    if (activities.length === 0) return new Response(JSON.stringify({ success: false, activities: [], location: { city: location, latitude: coordinates.lat, longitude: coordinates.lng }, total_found: 0, error: 'No activities generated' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const { moodyMessage, reasoning } = await getMoodyPersonalityResponse(moods, activities, location, userContext, lang)
    return new Response(JSON.stringify({ success: true, activities, location: { city: location, latitude: coordinates.lat, longitude: coordinates.lng }, total_found: activities.length, moodyMessage, reasoning }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    console.error('❌ handleCreateDayPlan:', error)
    return new Response(JSON.stringify({ success: false, error: error instanceof Error ? error.message : String(error), activities: [], total_found: 0 }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
}

// PLACE CARD BLURB

async function handlePlaceCardBlurb(params: Record<string, unknown>): Promise<Response> {
  const facts = typeof params.facts === 'string' ? params.facts.trim() : ''
  if (!facts || facts.length > 12000) return new Response(JSON.stringify({ success: false, error: 'invalid_facts', blurb: '' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  const languageCode = typeof params.languageCode === 'string' ? params.languageCode.trim().split(/[-_]/)[0] || 'en' : 'en'
  const outLang = placeCardBlurbOutputLanguageName(languageCode)
  const communicationStyle = typeof params.communicationStyle === 'string' ? params.communicationStyle : 'friendly'
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return new Response(JSON.stringify({ success: false, error: 'openai_not_configured', blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: getMoodyCardBlurbPrompt(outLang, communicationStyle) },
          { role: 'user', content: `Write a card teaser using only these facts. Do not invent anything.\n\n${facts}` },
        ],
        temperature: 0.75, max_tokens: 120,
      }),
    })
    if (!resp.ok) { console.error('place_card_blurb error', resp.status); return new Response(JSON.stringify({ success: false, blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
    const data = await resp.json()
    let blurb = String(data?.choices?.[0]?.message?.content || '').trim().replace(/^"|"$/g, '')
    if (blurb.length > 300) blurb = `${blurb.slice(0, 280).trim()}…`
    return new Response(JSON.stringify({ success: true, blurb }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e) { console.error('handlePlaceCardBlurb', e); return new Response(JSON.stringify({ success: false, blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

// PLACE DETAIL BLURB

async function handlePlaceDetailBlurb(params: Record<string, unknown>): Promise<Response> {
  const facts = typeof params.facts === 'string' ? params.facts.trim() : ''
  if (!facts || facts.length > 12000) return new Response(JSON.stringify({ success: false, error: 'invalid_facts', blurb: '' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  const languageCode = typeof params.languageCode === 'string' ? params.languageCode.trim().split(/[-_]/)[0] || 'en' : 'en'
  const outLang = placeCardBlurbOutputLanguageName(languageCode)
  const communicationStyle = typeof params.communicationStyle === 'string' ? params.communicationStyle : 'friendly'
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return new Response(JSON.stringify({ success: false, error: 'openai_not_configured', blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: getMoodyDetailBlurbPrompt(outLang, communicationStyle) },
          { role: 'user', content: `Write a detail screen description using only these facts. Do not invent anything.\n\n${facts}` },
        ],
        temperature: 0.75, max_tokens: 400,
      }),
    })
    if (!resp.ok) { console.error('place_detail_blurb error', resp.status); return new Response(JSON.stringify({ success: false, blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
    const data = await resp.json()
    let blurb = String(data?.choices?.[0]?.message?.content || '').trim().replace(/^"|"$/g, '')
    if (blurb.length > 1200) blurb = `${blurb.slice(0, 1180).trim()}…`
    return new Response(JSON.stringify({ success: true, blurb }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e) { console.error('handlePlaceDetailBlurb', e); return new Response(JSON.stringify({ success: false, blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

// OPENAI HELPERS

async function getMoodySearchQueries(moods: string[], location: string, userContext: any, lang: 'nl' | 'en', timeSlot?: string): Promise<string[] | null> {
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return null
  const moodDefs: Record<string, string> = {
    relaxed: 'slow down, soft energy, cozy quiet spots — NOT gyms or spas',
    energetic: 'buzz, movement, lively areas, street food, food halls — NOT gyms',
    romantic: 'candlelit restaurants, waterfront dining, wine bars, sunset views',
    adventurous: 'hidden gems, underground bars, unusual venues, non-touristy spots',
    foodie: 'artisan bakeries, specialty coffee, authentic restaurants, food markets',
    cultural: 'museums, art galleries, heritage buildings, cultural centers',
    social: 'lively bars, rooftop bars, live music, cocktail bars, group-friendly spots',
    excited: 'rooftops with views, trending spots, buzzing popular places',
    curious: 'interactive museums, concept stores, hidden exhibitions, unusual cafes',
    cozy: 'cafes with sofas, small wine bars, candlelit spots, warm bakeries',
    happy: 'cute brunch spots, colorful cafes, sunny terraces, ice cream',
    surprise: 'mix of cozy cafe + authentic food + unusual experience + rooftop bar',
  }
  const normalisedMoods = moods.map(m => normaliseMood(m))
  const moodDef = normalisedMoods.map(m => moodDefs[m] || m).join(' + ')
  const localHint = userContext.isLocalMode
    ? 'User is LOCAL — avoid tourist traps, prefer hidden gems, new openings, neighbourhood spots. Prefer places with 100-2000 reviews (real locals use these).'
    : 'User is TRAVELING — best of city, must-see iconic spots, mix of famous and local secrets. Include at least one landmark or tourist attraction.'
  const allInterests = userContext.allInterests || []
  const diet = userContext.dietaryRestrictions?.length ? ` Dietary: ${userContext.dietaryRestrictions.join(', ')}.` : ''
  const budget = userContext.budgetLevel && userContext.budgetLevel !== 'Mid-Range' ? ` Budget: ${userContext.budgetLevel}.` : ''
  const timeHint = timeSlot ? ` Time of day: ${timeSlot}.` : ''
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: `${MOODY_CORE_IDENTITY}\n\n${localHint}\nGenerate 6-8 short Google Places text search queries as JSON: {"queries":["...","..."]}.\nQueries should feel like a real person searching Google Maps. Be diverse, specific to the mood. No markdown.` },
          { role: 'user', content: `Mood: ${moodDef}. Location: ${location}. Interests: ${JSON.stringify(allInterests)}.${budget}${diet}${timeHint}` },
        ],
        max_tokens: 220, temperature: 0.5, response_format: { type: 'json_object' },
      }),
    })
    if (!resp.ok) return null
    const data = await resp.json()
    const parsed = JSON.parse(data.choices?.[0]?.message?.content || '{}')
    const queries = Array.isArray(parsed.queries) ? parsed.queries.filter((q: any) => typeof q === 'string').slice(0, 8) : []
    if (!queries.length) return null
    return queries
  } catch (e) { console.error('getMoodySearchQueries error:', e); return null }
}

async function getMoodyPersonalityResponse(moods: string[], activities: Activity[], location: string, userContext: any, lang: 'nl' | 'en'): Promise<{ moodyMessage: string; reasoning: string }> {
  const style = String(userContext?.communicationStyle || 'friendly')
  const n = activities.length, m = moods.join(' & ')
  const fb: Record<string, Record<string, any>> = {
    nl: {
      energetic: { moodyMessage: `YO ik heb je dag gepland 🔥 ${n} activiteiten, ${m} modus aan`, reasoning: 'Energie-mix.' },
      professional: { moodyMessage: `Ik heb ${n} activiteiten voor je klaarstaan in ${location}.`, reasoning: 'Geselecteerd.' },
      direct: { moodyMessage: `${n} activiteiten. Klaar.`, reasoning: 'Match.' },
      calm: { moodyMessage: `Ik heb iets rustig voor je gepland ☀️`, reasoning: 'Rustige mix.' },
      friendly: { moodyMessage: `Hey! Ik heb je ${m} dag gepland in ${location} 😊`, reasoning: 'Mooie mix.' }
    },
    en: {
      energetic: { moodyMessage: `YO I planned your whole day 🔥 ${n} things, ${m} mode activated`, reasoning: 'High-energy picks.' },
      professional: { moodyMessage: `I've lined up ${n} activities for you in ${location}.`, reasoning: 'Chosen for fit.' },
      direct: { moodyMessage: `${n} activities. You're welcome.`, reasoning: 'Mood match.' },
      calm: { moodyMessage: `I found something easy and good for you today ☀️`, reasoning: 'Calm mix.' },
      friendly: { moodyMessage: `Hey! I planned your ${m} day in ${location} 😊`, reasoning: 'Nice mix.' }
    },
  }
  const fallback = (fb[lang] || fb.en)[style] || (fb[lang] || fb.en).friendly
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return fallback
  try {
    const systemPrompt = `${MOODY_CORE_IDENTITY}\n\nYou just planned someone's day. Write a short personal message in ${lang === 'nl' ? 'Dutch' : 'English'} telling them you planned it. Use "I". Match the ${style} communication style. Return JSON only: {"moodyMessage":"<max 100 chars>","reasoning":"<max 60 chars>"}.`
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: `Mood: ${moods.join(', ')}. Location: ${location}. ${n} activities: ${activities.slice(0,3).map(a=>a.name).join(', ')}.` }], max_tokens: 150, temperature: 0.8, response_format: { type: 'json_object' } }),
    })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json()
    const parsed = JSON.parse(data.choices?.[0]?.message?.content || '{}')
    return { moodyMessage: parsed.moodyMessage || fallback.moodyMessage, reasoning: parsed.reasoning || fallback.reasoning }
  } catch { return fallback }
}

// CHAT

async function handleChat(supabase: any, userId: string, params: any): Promise<Response> {
  const message = (params.message || '').trim()
  if (!message) return new Response(JSON.stringify({ error: 'Message required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  const userContext = await fetchUserContext(supabase, userId)
  const userCity = params.location?.trim() || null
  const timeCtx = getTimeOfDayContext()
  const style = userContext.communicationStyle || 'friendly'
  const systemPrompt = `${MOODY_CORE_IDENTITY}\n\nCommunication style: ${style}. Adapt your energy to this style.\n${userCity ? `You are helping the user explore ${userCity} right now.` : 'You help users explore cities worldwide.'}\n${userContext.isLocalMode ? 'User is LOCAL — avoid tourist clichés, prefer hidden gems, new openings, neighbourhood spots.' : `User is TRAVELING — best of ${userCity || 'the city'}, mix iconic with local secrets.`}\nTime of day: ${timeCtx.timeSlot}.\nUser interests: ${JSON.stringify(userContext.allInterests)}\nFavourite moods: ${JSON.stringify(userContext.allFavoriteMoods)}\nDietary: ${userContext.dietaryRestrictions?.join(', ') || 'none'}\nBudget: ${userContext.budgetLevel}\n${userContext.ageGroup ? `Age group: ${userContext.ageGroup}` : ''}\n\nMax 4 sentences. Ask max 1 question. Max 2 concrete place suggestions.\nNEVER invent place names.\nReply in the same language the user writes in.`
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey) return new Response(JSON.stringify({ reply: getFallbackChat(style, clientOutputLang(params)), conversationId: params.conversationId || `conv_${userId}_${Date.now()}` }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: systemPrompt }, ...(params.history || []).slice(-10), { role: 'user', content: message }], max_tokens: 400, temperature: style === 'energetic' ? 0.9 : 0.75 }) })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json()
    const reply = data.choices?.[0]?.message?.content || getFallbackChat(style, clientOutputLang(params))
    const conversationId = params.conversationId || `conv_${userId}_${Date.now()}`
    supabase.from('ai_conversations').insert([{ user_id: userId, conversation_id: conversationId, role: 'user', content: message }, { user_id: userId, conversation_id: conversationId, role: 'assistant', content: reply }]).then(() => {}).catch(() => {})
    return new Response(JSON.stringify({ reply, conversationId }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e) { return new Response(JSON.stringify({ reply: getFallbackChat(style, clientOutputLang(params)) }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

function getFallbackChat(style: string, lang: 'nl' | 'en'): string {
  if (lang === 'nl') {
    switch (style) { case 'energetic': return 'YO even geduld! 🔥'; case 'professional': return 'Momenteel niet beschikbaar.'; case 'direct': return 'Even wachten.'; default: return 'Hey! Probeer het zo nog eens 😊' }
  }
  switch (style) { case 'energetic': return "YO hang on! 🔥"; case 'professional': return 'Currently unavailable.'; case 'direct': return 'Try again in a moment.'; default: return "Hey! Try again in a sec 😊" }
}

// SEARCH

async function handleSearch(supabase: any, userId: string, params: any): Promise<Response> {
  const query = (params.query || '').trim(), location = (params.location || '').trim(), coordinates = params.coordinates
  if (!query) return new Response(JSON.stringify({ error: 'Query required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  if (!location || !coordinates?.lat || !coordinates?.lng) return new Response(JSON.stringify({ error: 'Location and coordinates required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  try {
    const placesLang = googlePlacesLanguageFromRequest(params)
    const results = await searchPlacesV1(`${query} in ${location}`, coordinates, 20000, false, 20, placesLang)
    const qualified = await enrichAndFilter(results, { minRating: 3.5, minReviews: 5 })
    return new Response(JSON.stringify({ cards: qualified, total_found: qualified.length }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) { return new Response(JSON.stringify({ cards: [], total_found: 0 }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

// HUB MESSAGE

async function handleGenerateHubMessage(supabase: any, userId: string, params: Record<string, unknown>): Promise<Response> {
  const lang = clientOutputLang(params)
  const moods = Array.isArray(params.current_moods) ? (params.current_moods as unknown[]).filter((m): m is string => typeof m === 'string') : []
  const timeOfDay = typeof params.time_of_day === 'string' && params.time_of_day.trim() ? params.time_of_day.trim() : (lang === 'nl' ? 'dag' : 'day')
  let activitiesCount = 0
  const ac = params.activities_count
  if (typeof ac === 'number' && Number.isFinite(ac)) activitiesCount = Math.max(0, Math.floor(ac))
  else if (typeof ac === 'string') { const n = parseInt(ac, 10); if (!isNaN(n)) activitiesCount = Math.max(0, n) }
  const userContext = await fetchUserContext(supabase, userId)
  const style = String(userContext.communicationStyle || 'friendly').toLowerCase()
  const moodStr = moods.join(' & ') || (lang === 'nl' ? 'jouw vibe' : 'your vibe')
  const fb: Record<string, Record<string, string>> = {
    nl: {
      energetic: activitiesCount > 0 ? `YO ik heb ${activitiesCount} ding${activitiesCount===1?'':'en'} voor je klaar 🔥` : `Nog niks? Ik zoek iets ${moodStr} voor je 🔥`,
      professional: activitiesCount > 0 ? `Ik heb ${activitiesCount} activiteit${activitiesCount===1?'':'en'} voor je gepland.` : 'Ik heb nog niets voor je gepland.',
      direct: activitiesCount > 0 ? `${activitiesCount} gepland.` : 'Geen plannen.',
      calm: activitiesCount > 0 ? `Ik heb iets leuks voor je klaar ☀️` : `Rustige dag? Ik zoek iets voor je ☀️`,
      friendly: activitiesCount > 0 ? `Hey! Ik heb ${activitiesCount} ding${activitiesCount===1?'':'en'} voor je klaarstaan 😊` : `Nog rustig? Ik zoek iets ${moodStr} voor je 😊`
    },
    en: {
      energetic: activitiesCount > 0 ? `YO I got ${activitiesCount} thing${activitiesCount===1?'':'s'} lined up for you 🔥` : `Nothing yet? I'll find you something ${moodStr} 🔥`,
      professional: activitiesCount > 0 ? `I've planned ${activitiesCount} activit${activitiesCount===1?'y':'ies'} for you.` : "I haven't planned anything yet.",
      direct: activitiesCount > 0 ? `${activitiesCount} planned.` : 'No plans.',
      calm: activitiesCount > 0 ? `I found something good for you today ☀️` : `Quiet day? I'll find you something ☀️`,
      friendly: activitiesCount > 0 ? `Hey! I got ${activitiesCount} activit${activitiesCount===1?'y':'ies'} ready for you 😊` : `Quiet day? I'll find you something ${moodStr} 😊`
    },
  }
  const fallbackMessage = (fb[lang] || fb.en)[style] || (fb[lang] || fb.en).friendly
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return new Response(JSON.stringify({ message: fallbackMessage }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  const systemPrompt = `${MOODY_CORE_IDENTITY}\n\nWrite ONE short home screen greeting in ${lang === 'nl' ? 'Dutch' : 'English'}. Communication style: ${style}. Use "I". Max 100 chars. Max 1 emoji. Activities planned: ${activitiesCount}. User mood: ${moodStr}. Time: ${timeOfDay}.`
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: JSON.stringify({ current_moods: moods, time_of_day: timeOfDay, activities_count: activitiesCount }) }], max_tokens: 80, temperature: 0.8 }) })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json()
    const text = (data.choices?.[0]?.message?.content || '').trim().replace(/^["']|["']$/g, '')
    if (text.length > 0 && text.length <= 280) return new Response(JSON.stringify({ message: text }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e) { console.error('❌ handleGenerateHubMessage:', e) }
  return new Response(JSON.stringify({ message: fallbackMessage }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
}

// DAY PLAN CONVERSION

function convertPlacesToActivities(places: PlaceCard[], moods: string[], location: string, coordinates: { lat: number; lng: number }, lang: 'nl' | 'en'): Activity[] {
  const activities: Activity[] = [], used = new Set<string>()
  const morning: PlaceCard[] = [], afternoon: PlaceCard[] = [], evening: PlaceCard[] = []
  for (const p of places) { if (used.has(p.id)) continue; const slots = getTimeSlotsForPlace(p); if (slots.includes('morning')) morning.push(p); if (slots.includes('afternoon')) afternoon.push(p); if (slots.includes('evening')) evening.push(p) }
  const now = new Date(), today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const add = (pool: PlaceCard[], slot: string, h1: number, h2: number, count: number, pastH: number) => {
    let added = 0
    for (const p of pool) {
      if (added >= count) break
      if (used.has(p.id)) continue
      used.add(p.id)
      const h = h1 + Math.floor(Math.random() * (h2 - h1)), m = [0, 15, 30, 45][Math.floor(Math.random() * 4)]
      const st = new Date(today.getTime()); st.setHours(h, m, 0, 0)
      if (now.getHours() >= pastH) st.setDate(st.getDate() + 1)
      activities.push(createActivity(p, slot, st, moods, lang))
      added++
    }
  }
  add(morning,'morning',7,10,3,11); add(afternoon,'afternoon',12,16,3,17); add(evening,'evening',17,20,3,21)
  return activities.sort((a,b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime())
}

function getTimeSlotsForPlace(place: PlaceCard): string[] {
  const slots: string[] = [], types = (place.types||[]).map(t=>t.toLowerCase()), name = place.name.toLowerCase(), primary = (place.primaryType||'').toLowerCase()
  if (['cafe','bakery','park','museum','art_gallery','library'].some(t=>types.includes(t)||primary===t) || name.includes('coffee')||name.includes('breakfast')||name.includes('brunch')) slots.push('morning')
  if (['restaurant','museum','art_gallery','tourist_attraction','food','cafe','park','shopping_mall'].some(t=>types.includes(t)||primary===t)) slots.push('afternoon')
  if (['restaurant','bar','night_club'].some(t=>types.includes(t)||primary===t) || name.includes('dinner')||name.includes('bar')||name.includes('bistro')) slots.push('evening')
  if (!slots.length) slots.push('afternoon')
  return slots
}

function createActivity(place: PlaceCard, timeSlot: string, startTime: Date, moods: string[], lang: 'nl' | 'en'): Activity {
  const placeId = place.id.replace('google_', '')
  const desc = place.editorial_summary || place.description || (lang==='nl' ? `${place.name} — een goede keuze voor je ${moods.join(' en ').toLowerCase()} dag.` : `${place.name} — a solid pick for your ${moods.join(' & ').toLowerCase()} day.`)
  const types = place.types || [], tags: string[] = []
  if (types.some(t=>['restaurant','food','food_court'].includes(t))) tags.push('Food')
  if (types.some(t=>['spa','beauty_salon'].includes(t))) tags.push('Wellness')
  if (types.some(t=>['museum','art_gallery'].includes(t))) tags.push(lang==='nl'?'Cultuur':'Culture')
  if (types.some(t=>['park','natural_feature'].includes(t))) tags.push(lang==='nl'?'Buiten':'Outdoors')
  if (types.some(t=>['bar','night_club'].includes(t))) tags.push('Nightlife')
  if (types.some(t=>['cafe','bakery','coffee_shop'].includes(t))) tags.push('Cafe')
  if (types.some(t=>['tourist_attraction','landmark'].includes(t))) tags.push(lang==='nl'?'Bezienswaardigheid':'Attraction')
  let duration = 60
  if (types.includes('restaurant')) duration=90; else if (types.includes('museum')||types.includes('art_gallery')) duration=120
  else if (types.includes('spa')) duration=90; else if (types.includes('cafe')||types.includes('bakery')) duration=45
  else if (types.includes('bar')||types.includes('night_club')) duration=120
  let paymentType = 'free'
  if (types.includes('museum')) paymentType='ticket'
  else if (types.includes('restaurant')||types.includes('bar')||types.includes('spa')) paymentType='reservation'
  else if (place.price_level) paymentType='reservation'
  return { id: `activity_${Date.now()}_${place.id}`, name: place.name, description: desc, timeSlot, duration, location: { latitude: place.location.lat, longitude: place.location.lng }, paymentType, imageUrl: place.photo_url||'', rating: place.rating, tags: tags.slice(0,2), startTime: startTime.toISOString(), priceLevel: place.price_level != null ? (['','€','€€','€€€','€€€€'][place.price_level]||'€€') : undefined, placeId }
}
