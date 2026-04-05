import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import {
  edgeRateLimitConsume,
  getServiceSupabase,
  logApiInvocationFireAndForget,
  traceEdgeResponse,
  userRateKey,
} from '../_shared/edge_guard.ts'
import { corsHeaders } from './_shared/cors.ts'

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

interface DayPlanResponse {
  success: boolean
  activities: Activity[]
  location: { city: string; latitude: number; longitude: number }
  total_found: number
  error?: string
  moodyMessage?: string
  reasoning?: string
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
    console.log(`🎯 Moody v65: action=${action}, userId=${authUser.id}`)
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

// ============================================
// USER CONTEXT
// ============================================

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

// Maps request params to a Google Places languageCode
// Aligned with PlacesCacheUtils.normalizeExploreLanguageCode
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

// ============================================
// NORMALISE MOOD
// ============================================

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

// ============================================
// PLACES API v1 — with language support
// ============================================

const FIELD_MASK_STANDARD = [
  'places.id','places.displayName','places.formattedAddress','places.shortFormattedAddress',
  'places.location','places.rating','places.userRatingCount','places.priceLevel',
  'places.photos','places.primaryType','places.types','places.currentOpeningHours',
  'places.editorialSummary','places.businessStatus',
].join(',')

const FIELD_MASK_ATMOSPHERE = [
  ...FIELD_MASK_STANDARD.split(','),
  'places.outdoorSeating','places.liveMusic','places.goodForChildren',
  'places.goodForGroups','places.servesVegetarianFood','places.servesCocktails','places.servesCoffee',
].join(',')

async function searchPlacesV1(
  textQuery: string,
  coordinates: { lat: number; lng: number },
  radius = 15000,
  useAtmosphere = false,
  pageSize = 20,
  languageCode = 'en',
): Promise<PlaceCard[]> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey?.trim()) throw new Error('GOOGLE_PLACES_API_KEY not configured')
  try {
    const response = await fetch('https://places.googleapis.com/v1/places:searchText', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': useAtmosphere ? FIELD_MASK_ATMOSPHERE : FIELD_MASK_STANDARD,
      },
      body: JSON.stringify({
        textQuery,
        pageSize,
        locationBias: { circle: { center: { latitude: coordinates.lat, longitude: coordinates.lng }, radius } },
        languageCode, // now dynamic per user language
      }),
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
    id: `google_${p.id || ''}`,
    name: p.displayName?.text || '',
    rating: p.rating || 0,
    user_ratings_total: p.userRatingCount || 0,
    types: p.types || [],
    primaryType: p.primaryType || '',
    location: { lat: p.location?.latitude || 0, lng: p.location?.longitude || 0 },
    photo_reference: photo?.name,
    photo_url: photoUrl,
    price_level: typeof p.priceLevel === 'number' ? p.priceLevel : priceMap[String(p.priceLevel)] ?? undefined,
    vicinity: p.shortFormattedAddress || '',
    address: p.formattedAddress || p.shortFormattedAddress || '',
    description: p.editorialSummary?.text || '',
    editorial_summary: p.editorialSummary?.text || '',
    opening_hours: p.currentOpeningHours ? { open_now: p.currentOpeningHours.openNow, weekday_text: p.currentOpeningHours.weekdayDescriptions || [] } : undefined,
    outdoor_seating: p.outdoorSeating ?? undefined,
    live_music: p.liveMusic ?? undefined,
    good_for_children: p.goodForChildren ?? undefined,
    good_for_groups: p.goodForGroups ?? undefined,
    serves_vegetarian_food: p.servesVegetarianFood ?? undefined,
    serves_cocktails: p.servesCocktails ?? undefined,
    serves_coffee: p.servesCoffee ?? undefined,
  }
}

async function fetchPlacesFromGoogle(
  location: string,
  coordinates: { lat: number; lng: number },
  mood: string,
  filters: any,
  queriesOverride?: string[] | null,
  useAtmosphere = false,
  languageCode = 'en',
): Promise<PlaceCard[]> {
  const queries = queriesOverride?.length ? queriesOverride : getMoodQueries(mood)
  const all: PlaceCard[] = []
  for (const q of queries) {
    try {
      const r = await searchPlacesV1(`${q} in ${location}`, coordinates, filters?.radius || 15000, useAtmosphere, 20, languageCode)
      all.push(...r)
      await new Promise(r => setTimeout(r, 80))
    } catch (e) { console.error(`❌ query "${q}":`, e) }
  }
  return Array.from(new Map(all.map(p => [p.id, p])).values())
}

async function fetchFallbackPlaces(
  location: string,
  coordinates: { lat: number; lng: number },
  languageCode = 'en',
): Promise<PlaceCard[]> {
  const queries = [`popular restaurant in ${location}`, `cafe in ${location}`, `tourist attraction in ${location}`, `park in ${location}`]
  const all: PlaceCard[] = []
  for (const q of queries) {
    const r = await searchPlacesV1(q, coordinates, 20000, false, 20, languageCode)
    all.push(...r)
    await new Promise(r => setTimeout(r, 80))
  }
  return Array.from(new Map(all.map(p => [p.id, p])).values())
}

// ============================================
// MOOD DEFINITIONS v65
// ============================================

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
  if (m === 'surprise') return getMoodQueriesSurprise()
  return map[m] || ['popular restaurant', 'local cafe', 'city park', 'attraction', 'art gallery']
}

function getMoodQueriesSurprise(): string[] {
  return ['cozy hidden cafe', 'authentic local restaurant', 'unusual unique experience', 'rooftop bar view', 'art gallery or museum', 'street food market']
}

function getTimeOfDayContext(): { timeSlot: 'morning' | 'afternoon' | 'evening'; queryBoost: string[] } {
  const hour = new Date().getUTCHours() + 1
  if (hour >= 6 && hour < 12) return { timeSlot: 'morning', queryBoost: ['brunch', 'breakfast cafe', 'morning coffee', 'bakery'] }
  if (hour >= 12 && hour < 18) return { timeSlot: 'afternoon', queryBoost: ['lunch spot', 'afternoon activity', 'museum'] }
  return { timeSlot: 'evening', queryBoost: ['dinner restaurant', 'bar evening', 'cocktail bar', 'wine bar'] }
}

function getBroadExploreQueries(isLocalMode: boolean, interests: string[]): string[] {
  const base = isLocalMode
    ? ['neighbourhood restaurant hidden gem', 'local cafe specialty coffee', 'new opening restaurant', 'local market', 'afterwork bar local', 'neighbourhood bakery', 'wine bar local', 'cozy bistro neighbourhood']
    : ['best restaurant city', 'rooftop bar city views', 'scenic viewpoint', 'art museum', 'street food market', 'iconic cafe', 'cocktail bar', 'waterfront restaurant', 'cultural attraction', 'local market']
  const interestQueries: string[] = []
  for (const interest of interests.slice(0, 3)) {
    const i = interest.toLowerCase()
    if (i.includes('food') || i.includes('eat')) interestQueries.push('artisan food market', 'specialty restaurant')
    else if (i.includes('culture') || i.includes('art')) interestQueries.push('art gallery contemporary', 'cultural museum')
    else if (i.includes('nightlife') || i.includes('bar')) interestQueries.push('cocktail bar rooftop', 'live music bar')
    else if (i.includes('outdoor') || i.includes('nature')) interestQueries.push('park waterfront', 'outdoor terrace scenic')
    else if (i.includes('coffee')) interestQueries.push('specialty coffee roastery', 'concept cafe')
  }
  return [...new Set([...interestQueries, ...base])].slice(0, 12)
}

function getFilterSearchQueries(filterName: string): string[] {
  const map: Record<string, string[]> = {
    halal: ['halal restaurant', 'halal food', 'halal cafe', 'muslim friendly restaurant'],
    lgbtq_friendly: ['lgbtq friendly bar', 'gay friendly cafe', 'inclusive restaurant queer'],
    black_owned: ['black owned restaurant', 'black owned cafe', 'afro restaurant'],
    family_friendly: ['family restaurant', 'family friendly cafe', 'family park attraction'],
    kids_friendly: ['kids friendly restaurant', 'children museum', 'playground family restaurant'],
    vegan: ['vegan restaurant', 'plant based restaurant', 'vegan cafe'],
    vegetarian: ['vegetarian restaurant', 'vegetarian cafe', 'plant based food'],
    gluten_free: ['gluten free restaurant', 'celiac friendly restaurant cafe'],
    instagrammable: ['aesthetic cafe', 'rooftop restaurant view', 'scenic viewpoint', 'beautiful interior restaurant', 'flower cafe'],
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

// ============================================
// QUALITY + RANKING
// ============================================

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
    const t: Record<PlaceBucket, number> = { cafe_bakery: 1.5, food: 1.0, scenic_calm: 0.7, culture: 0.7, wellness: 0.3, fitness: 0.0, nightlife: 0.7, shopping: 0.4, tourist: -1.5, misc: 0.2 }
    return t[bucket]
  }
  const t: Record<PlaceBucket, number> = { cafe_bakery: 0.4, food: 0.6, scenic_calm: 1.0, culture: 1.0, wellness: 0.2, fitness: 0.0, nightlife: 0.6, shopping: 0.3, tourist: 1.2, misc: 0.2 }
  return t[bucket]
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
  if (sorted.length <= 8) return sorted.map(x => x.place)
  const cap = 4, counts = new Map<PlaceBucket, number>(), out: typeof scored = []
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
    let score = qualityScore(place) + moodBucketWeight(mood, bucket) + localTravelWeight(bucket, isLocalMode) + atmosphereBonus(place, mood)
    if (interestLower.length > 0) {
      const text = (place.types || []).join(' ').toLowerCase() + ' ' + (place.name || '').toLowerCase() + ' ' + (place.editorial_summary || '').toLowerCase()
      for (const i of interestLower) { if (i && text.includes(i)) score += 0.4 }
    }
    if (isLocalMode && (place.price_level || 0) >= 4) score -= 0.3
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

function filterByNamedFilter(places: PlaceCard[], filterName: string): PlaceCard[] {
  const f = filterName.toLowerCase()
  if (f === 'kids_friendly' || f === 'family_friendly') { const a = places.filter(p => p.good_for_children === true); return a.length > 0 ? a : places }
  if (f === 'vegan' || f === 'vegetarian') { const a = places.filter(p => p.serves_vegetarian_food === true); return a.length > 0 ? a : places }
  if (f === 'outdoor') { const a = places.filter(p => p.outdoor_seating === true); return a.length > 0 ? a : places }
  return places
}

async function enrichAndFilter(input: PlaceCard[], thresholds: { minRating?: number; minReviews?: number } = {}): Promise<PlaceCard[]> {
  return input.filter(p => isPlaceValid(p, { minRating: thresholds.minRating ?? 4.0, minReviews: thresholds.minReviews ?? 8 }))
}

// ============================================
// CACHE
// ============================================

async function checkCache(supabase: any, cacheKey: string): Promise<ExploreResponse | null> {
  try {
    const { data } = await supabase.from('places_cache').select('data,expires_at').eq('cache_key', cacheKey).is('place_id', null).maybeSingle()
    if (!data || new Date(data.expires_at) < new Date() || !data.data?.cards) return null
    return { cards: data.data.cards, cached: true, total_found: data.data.cards.length, cache_key: cacheKey }
  } catch { return null }
}

async function cacheExplore(supabase: any, cacheKey: string, places: PlaceCard[]): Promise<void> {
  try {
    const expiresAt = new Date(); expiresAt.setDate(expiresAt.getDate() + 7)
    await supabase.from('places_cache').upsert({ cache_key: cacheKey, data: { cards: places }, place_id: null, user_id: null, request_type: 'explore', expires_at: expiresAt.toISOString() }, { onConflict: 'cache_key' })
    console.log(`💾 Cached ${places.length} places key=${cacheKey}`)
  } catch (e) { console.error('❌ cacheExplore:', e) }
}

function applyFilters(places: PlaceCard[], filters: any): PlaceCard[] {
  if (!filters || Object.keys(filters).length === 0) return places
  return places.filter(place => {
    if (filters.rating && place.rating < filters.rating) return false
    if (filters.priceLevel && place.price_level && place.price_level > filters.priceLevel) return false
    if (filters.openNow === true && place.opening_hours?.open_now !== true) return false
    if (filters.minReviews && (place.user_ratings_total || 0) < filters.minReviews) return false
    return true
  })
}

// ============================================
// GET EXPLORE
// ============================================

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
    // Cache key includes language so Dutch/English get separate caches
    // Legacy: for English we also try the old key without _en suffix
    const cacheKey = lang === 'en'
      ? `explore_v7_${modeKey}_${section || mood}_${location.toLowerCase().trim()}`
      : `explore_v7_${modeKey}_${section || mood}_${location.toLowerCase().trim()}_${lang}`
    console.log(`🔍 get_explore v65: loc=${location}, mode=${modeKey}, section=${section}, time=${timeCtx.timeSlot}, lang=${lang}`)
    if (!hasNamedFilters) {
      const cached = await checkCache(supabase, cacheKey)
      if (cached && cached.cards.length > 0) {
        console.log(`✅ Cache hit: ${cached.cards.length}`)
        return new Response(JSON.stringify({ ...cached, cards: applyFilters(cached.cards, filters), filters_applied: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }
      // Legacy cache fallback for English only
      if (lang !== 'en') {
        // No legacy fallback for non-English — we want fresh localised results
      }
    }
    let exploreQueries: string[]
    if (hasNamedFilters) {
      exploreQueries = namedFilters.flatMap(f => getFilterSearchQueries(f)).slice(0, 12)
    } else if (section === 'food') {
      exploreQueries = userContext.isLocalMode
        ? ['neighbourhood restaurant', 'local food market', 'artisan bakery', 'specialty coffee', 'local bistro']
        : ['best restaurant city', 'food market artisan', 'famous bakery', 'specialty coffee', 'local cuisine']
    } else if (section === 'trending') {
      exploreQueries = ['trending restaurant new opening', 'popular rooftop bar', 'new cafe opening', 'buzzing food spot', 'viral restaurant']
    } else if (section === 'solo' || section === 'social') {
      const vibe = userContext.socialVibe?.[0]?.toLowerCase() || ''
      if (vibe.includes('solo') || vibe.includes('alone')) exploreQueries = ['quiet museum', 'solo cafe reading', 'bookstore cafe', 'gallery solo visit', 'peaceful park']
      else if (vibe.includes('group') || vibe.includes('friends')) exploreQueries = ['group restaurant lively', 'rooftop bar groups', 'food hall social', 'live music bar', 'cocktail bar']
      else exploreQueries = ['cafe cozy', 'restaurant casual', 'bar relaxed', 'park', 'museum']
    } else if (section === 'different') {
      exploreQueries = ['hidden gem restaurant', 'unusual cafe', 'underground bar', 'unique experience', 'street art neighbourhood', 'concept store cafe']
    } else if (isBroadFeed) {
      const base = getBroadExploreQueries(userContext.isLocalMode, userContext.allInterests || [])
      exploreQueries = [...timeCtx.queryBoost.map(q => `${q} in ${location}`), ...base].slice(0, 12)
    } else {
      const clientLang = clientOutputLang(params)
      const aiQ = await getMoodySearchQueries([mood], location, userContext, clientLang)
      exploreQueries = aiQ ?? getMoodQueries(mood)
    }
    let places = await fetchPlacesFromGoogle(location, coordinates, mood, filters, exploreQueries, hasNamedFilters, lang)
    if (places.length < 10) { const fb = await fetchFallbackPlaces(location, coordinates, lang); places = Array.from(new Map([...places, ...fb].map(p => [p.id, p])).values()) }
    places = places.slice(0, 50)
    if (hasNamedFilters) { for (const f of namedFilters) places = filterByNamedFilter(places, f) }
    const thresholds = hasNamedFilters ? { minRating: 3.5, minReviews: 5 } : { minRating: 4.0, minReviews: 8 }
    let qualified = await enrichAndFilter(places, thresholds)
    if (qualified.length < 8) qualified = await enrichAndFilter(places, { minRating: 3.5, minReviews: 5 })
    const ranked = rankPlaces(qualified, mood, !!userContext.isLocalMode, userContext.allInterests || [])
    if (!hasNamedFilters) { await cacheExplore(supabase, cacheKey, ranked) }
    const final = applyFilters(ranked, filters)
    return new Response(JSON.stringify({ cards: final, cached: false, total_found: final.length, unfiltered_total: ranked.length, named_filters_applied: namedFilters, section: section || 'all', time_slot: timeCtx.timeSlot }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    console.error('❌ handleGetExplore:', error)
    return new Response(JSON.stringify({ cards: [], cached: false, total_found: 0, error: 'explore_fetch_failed', message: error instanceof Error ? error.message : String(error) }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
}

// ============================================
// CREATE DAY PLAN
// ============================================

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
    console.log(`🎯 create_day_plan v65: moods=${moods}, loc=${location}, local=${userContext.isLocalMode}, time=${timeCtx.timeSlot}, lang=${placesLang}`)
    const aiQueries = await getMoodySearchQueries(moods, location, userContext, lang, timeCtx.timeSlot)
    let places = await fetchPlacesFromGoogle(location, coordinates, moods[0], params.filters || {}, aiQueries, false, placesLang)
    let qualified = await enrichAndFilter(places, { minRating: 3.8, minReviews: 8 })
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

// ============================================
// OPENAI
// ============================================

function placeCardBlurbOutputLanguageName(code: string): string {
  const c = (code || 'en').toLowerCase().split(/[-_]/)[0]
  const m: Record<string, string> = { nl: 'Dutch', de: 'German', fr: 'French', es: 'Spanish', en: 'English' }
  return m[c] || 'English'
}

/** Grounded Explore card copy; uses server OPENAI_API_KEY when the app has no client key. */
async function handlePlaceCardBlurb(params: Record<string, unknown>): Promise<Response> {
  const facts = typeof params.facts === 'string' ? params.facts.trim() : ''
  if (!facts || facts.length > 12000) {
    return new Response(JSON.stringify({ success: false, error: 'invalid_facts', blurb: '' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
  const languageCode = typeof params.languageCode === 'string'
    ? params.languageCode.trim().split(/[-_]/)[0] || 'en'
    : 'en'
  const outLang = placeCardBlurbOutputLanguageName(languageCode)
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) {
    return new Response(JSON.stringify({ success: false, error: 'openai_not_configured', blurb: '' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
  const systemPrompt =
    `You are Moody, the warm voice of the WanderMood travel app. Write accurate and engaging place descriptions for mobile cards. Never invent menu items, prices, or amenities not implied by the user's facts. If facts are thin, stay general but engaging.`
  const userMessage =
    `These are the only verified facts about a real place. Do not add unsupported details.\n\n${facts}\n\nWrite at least 3 detailed sentences about the atmosphere and offerings for a travel app card. Tone: friendly, like Moody. Use only the facts above. Output entirely in ${outLang}. Plain prose: no bullet points, no quotation marks.`
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage },
        ],
        temperature: 0.45,
        max_tokens: 400,
      }),
    })
    if (!resp.ok) {
      const t = await resp.text()
      console.error('place_card_blurb OpenAI error', resp.status, t.slice(0, 240))
      return new Response(JSON.stringify({ success: false, blurb: '' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    const data = await resp.json()
    let blurb = String(data?.choices?.[0]?.message?.content || '').trim().replace(/"/g, '')
    if (blurb.length > 600) blurb = `${blurb.slice(0, 580).trim()}…`
    return new Response(JSON.stringify({ success: true, blurb }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    console.error('handlePlaceCardBlurb', e)
    return new Response(JSON.stringify({ success: false, blurb: '' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
}

async function handlePlaceDetailBlurb(params: Record<string, unknown>): Promise<Response> {
  const facts = typeof params.facts === 'string' ? params.facts.trim() : ''
  if (!facts || facts.length > 12000) {
    return new Response(JSON.stringify({ success: false, error: 'invalid_facts', blurb: '' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
  const languageCode = typeof params.languageCode === 'string'
    ? params.languageCode.trim().split(/[-_]/)[0] || 'en'
    : 'en'
  const outLang = placeCardBlurbOutputLanguageName(languageCode)
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) {
    return new Response(JSON.stringify({ success: false, error: 'openai_not_configured', blurb: '' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
  const systemPrompt =
    `You are Moody, the warm voice of the WanderMood travel app. Write a fuller, accurate place description for a detail screen. Never invent menu items, prices, or amenities not implied by the user's facts. If facts are thin, stay general but engaging.`
  const userMessage =
    `These are the only verified facts about a real place. Do not add unsupported details.\n\n${facts}\n\nWrite 5 to 8 detailed sentences including practical tips, history, and why it's worth visiting for a travel app place detail screen. Expand on what visitors might experience, atmosphere, and practical cues only when supported by the facts above. Tone: friendly, like Moody. Output entirely in ${outLang}. Plain prose: no bullet points, no quotation marks.`
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage },
        ],
        temperature: 0.45,
        max_tokens: 1000,
      }),
    })
    if (!resp.ok) {
      const t = await resp.text()
      console.error('place_detail_blurb OpenAI error', resp.status, t.slice(0, 240))
      return new Response(JSON.stringify({ success: false, blurb: '' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    const data = await resp.json()
    let blurb = String(data?.choices?.[0]?.message?.content || '').trim().replace(/"/g, '')
    if (blurb.length > 2000) blurb = `${blurb.slice(0, 1980).trim()}…`
    return new Response(JSON.stringify({ success: true, blurb }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    console.error('handlePlaceDetailBlurb', e)
    return new Response(JSON.stringify({ success: false, blurb: '' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
}

async function getMoodySearchQueries(moods: string[], location: string, userContext: any, lang: 'nl' | 'en', timeSlot?: string): Promise<string[] | null> {
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return null
  const moodDefs: Record<string, string> = {
    relaxed: 'slow down, soft energy, cozy quiet spots — NOT gyms or spas',
    energetic: 'buzz, movement, lively areas, street food, food halls — NOT gyms or fitness centers',
    romantic: 'candlelit restaurants, waterfront dining, wine bars, sunset views — NOT spas or massages',
    adventurous: 'hidden gems, underground bars, unusual venues, non-touristy local spots',
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
    ? 'User is LOCAL — avoid tourist traps, prefer hidden gems, new openings, neighbourhood spots locals use.'
    : 'User is TRAVELING — best of city, must-see, mix of iconic and local secrets.'
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
          { role: 'system', content: `You are Moody, WanderMood assistant. ${localHint}\nGenerate 6-8 short Google Places text search queries as JSON: {"queries":["...","..."]}.\nQueries should feel like a real person searching Google Maps. Be diverse, specific to the mood definition. No markdown.` },
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
    console.log('🤖 AI queries:', queries)
    return queries
  } catch (e) { console.error('getMoodySearchQueries error:', e); return null }
}

async function getMoodyPersonalityResponse(moods: string[], activities: Activity[], location: string, userContext: any, lang: 'nl' | 'en'): Promise<{ moodyMessage: string; reasoning: string }> {
  const style = String(userContext?.communicationStyle || 'friendly')
  const n = activities.length, m = moods.join(' & ')
  const fb: Record<string, Record<string, any>> = {
    nl: { energetic: { moodyMessage: `YO! ${n} activiteiten voor je ${m} dag! 🔥`, reasoning: 'Energie-mix.' }, professional: { moodyMessage: `${n} activiteiten voor ${location}.`, reasoning: 'Geselecteerd.' }, direct: { moodyMessage: `${n} activiteiten.`, reasoning: 'Match.' }, friendly: { moodyMessage: `Hey! ${n} leuke activiteiten voor je ${m} dag in ${location} 😊`, reasoning: 'Mooie mix.' } },
    en: { energetic: { moodyMessage: `YO! ${n} epic activities for your ${m} day! 🔥`, reasoning: 'High-energy picks.' }, professional: { moodyMessage: `${n} activities for ${location}.`, reasoning: 'Chosen for fit.' }, direct: { moodyMessage: `${n} activities.`, reasoning: 'Mood match.' }, friendly: { moodyMessage: `Hey! ${n} great activities for your ${m} day in ${location} 😊`, reasoning: 'Nice mix.' } },
  }
  const fallback = (fb[lang] || fb.en)[style] || (fb[lang] || fb.en).friendly
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return fallback
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: `${getMoodyPersonalityForHubMessage(style, lang)} Return JSON only: {"moodyMessage":"<max 120 chars>","reasoning":"<max 80 chars>"}.` }, { role: 'user', content: `Mood: ${moods.join(', ')}. Location: ${location}. ${n} activities: ${activities.slice(0,3).map(a=>a.name).join(', ')}.` }], max_tokens: 200, temperature: style === 'energetic' ? 0.9 : 0.7, response_format: { type: 'json_object' } }),
    })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json()
    const parsed = JSON.parse(data.choices?.[0]?.message?.content || '{}')
    return { moodyMessage: parsed.moodyMessage || fallback.moodyMessage, reasoning: parsed.reasoning || fallback.reasoning }
  } catch { return fallback }
}

// ============================================
// PERSONALITY
// ============================================

function getMoodyPersonalityInstructions(style: string): string {
  switch (style.toLowerCase()) {
    case 'energetic': case 'playful': case 'cheeky': return `Je bent Moody in ENERGIEK mode. Enthousiaste beste vriend. Max 2 emojis. Nederlands.`
    case 'calm': case 'minimal': return `Je bent Moody in KALM mode. Kort, rustig. Max 1 emoji. Nederlands.`
    case 'professional': return `Je bent Moody in PROFESSIONEEL mode. Helder, efficiënt. Geen emojis. Nederlands.`
    case 'direct': case 'direct_practical': return `Je bent Moody in DIRECT mode. Één zin. Geen emojis. Max 10 woorden. Nederlands.`
    default: return `Je bent Moody in VRIENDELIJK mode. Warm, persoonlijk. Max 1-2 emojis. Nederlands.`
  }
}

function getMoodyPersonalityForHubMessage(style: string, lang: 'nl' | 'en'): string {
  if (lang === 'nl') return getMoodyPersonalityInstructions(style)
  switch (style.toLowerCase()) {
    case 'energetic': case 'playful': case 'cheeky': return `You are Moody in ENERGETIC mode. Enthusiastic best friend. Max 2 emojis. English.`
    case 'calm': case 'minimal': return `You are Moody in CALM mode. Short, grounded. Max 1 emoji. English.`
    case 'professional': return `You are Moody in PROFESSIONAL mode. Clear, efficient. No emojis. English.`
    case 'direct': case 'direct_practical': return `You are Moody in DIRECT mode. One sentence. No emojis. Max 10 words. English.`
    default: return `You are Moody in FRIENDLY mode. Warm, caring. Max 1-2 emojis. English.`
  }
}

// ============================================
// CHAT
// ============================================

async function handleChat(supabase: any, userId: string, params: any): Promise<Response> {
  const message = (params.message || '').trim()
  if (!message) return new Response(JSON.stringify({ error: 'Message required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  const userContext = await fetchUserContext(supabase, userId)
  const userCity = params.location?.trim() || null
  const timeCtx = getTimeOfDayContext()
  const systemPrompt = `${getMoodyPersonalityInstructions(userContext.communicationStyle)}

${userCity ? `You are a local expert currently helping a user in ${userCity}.` : 'You are a local expert in cities worldwide.'}
${userContext.isLocalMode ? 'User is LOCAL — avoid tourist clichés, prefer hidden gems, new openings, neighbourhood spots.' : `User is TRAVELING — best of ${userCity || 'the city'}, mix iconic with local secrets.`}
Time of day: ${timeCtx.timeSlot}.
User interests: ${JSON.stringify(userContext.allInterests)}
Favourite moods: ${JSON.stringify(userContext.allFavoriteMoods)}
Dietary: ${userContext.dietaryRestrictions?.join(', ') || 'none'}
Budget: ${userContext.budgetLevel}
${userContext.ageGroup ? `Age group: ${userContext.ageGroup}` : ''}

Max 4 sentences. Ask max 1 question. Max 2 concrete place suggestions.
NEVER invent place names. Only real places in ${userCity || "the user's city"}.
Max 2 emojis. Reply in the same language the user writes in.`
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey) return new Response(JSON.stringify({ reply: getFallbackChat(userContext.communicationStyle), conversationId: params.conversationId || `conv_${userId}_${Date.now()}` }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: systemPrompt }, ...(params.history || []).slice(-10), { role: 'user', content: message }], max_tokens: 400, temperature: userContext.communicationStyle === 'energetic' ? 0.9 : 0.75 }) })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json()
    const reply = data.choices?.[0]?.message?.content || getFallbackChat(userContext.communicationStyle)
    const conversationId = params.conversationId || `conv_${userId}_${Date.now()}`
    supabase.from('ai_conversations').insert([{ user_id: userId, conversation_id: conversationId, role: 'user', content: message }, { user_id: userId, conversation_id: conversationId, role: 'assistant', content: reply }]).then(() => {}).catch(() => {})
    return new Response(JSON.stringify({ reply, conversationId }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e) { return new Response(JSON.stringify({ reply: getFallbackChat(userContext.communicationStyle) }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

function getFallbackChat(style: string): string {
  switch (style) { case 'energetic': return 'YO! Even geduld! 🔥'; case 'professional': return 'Momenteel niet beschikbaar.'; case 'direct': return 'Even wachten.'; default: return 'Hey! Probeer het zo nog eens 😊' }
}

// ============================================
// SEARCH
// ============================================

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

// ============================================
// HUB MESSAGE
// ============================================

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
    nl: { energetic: activitiesCount > 0 ? `YO! ${activitiesCount} item${activitiesCount===1?'':'s'} — ${moodStr} modus! 🔥` : `Nog niks? Ga ${moodStr} ontdekken! 🔥`, professional: activitiesCount > 0 ? `${activitiesCount} activiteit${activitiesCount===1?'':'en'} gepland.` : 'Geen plannen vandaag.', direct: activitiesCount > 0 ? `${activitiesCount} gepland.` : 'Geen plannen.', friendly: activitiesCount > 0 ? `Hey! ${activitiesCount} ding${activitiesCount===1?'':'en'} klaar 😊` : `Nog rustig? Iets ${moodStr} voor je 😊` },
    en: { energetic: activitiesCount > 0 ? `YO! ${activitiesCount} thing${activitiesCount===1?'':'s'} on tap — ${moodStr} mode! 🔥` : `Nothing yet? Time to explore ${moodStr}! 🔥`, professional: activitiesCount > 0 ? `${activitiesCount} activit${activitiesCount===1?'y':'ies'} lined up.` : 'No plans today.', direct: activitiesCount > 0 ? `${activitiesCount} planned.` : 'No plans.', friendly: activitiesCount > 0 ? `Hey! ${activitiesCount} activit${activitiesCount===1?'y':'ies'} lined up 😊` : `Quiet day? Maybe something ${moodStr} 😊` },
  }
  const fallbackMessage = (fb[lang] || fb.en)[style] || (fb[lang] || fb.en).friendly
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return new Response(JSON.stringify({ message: fallbackMessage }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  const personality = getMoodyPersonalityForHubMessage(style, lang)
  const systemPrompt = `${personality}\n\n${lang === 'nl' ? `Schrijf één korte regel voor het startscherm (max 140 tekens). Moods: ${moodStr}, dagdeel: ${timeOfDay}, activiteiten: ${activitiesCount}. Max 1 emoji.` : `Write one short line for the home screen (max 140 chars). Moods: ${moodStr}, time: ${timeOfDay}, activities: ${activitiesCount}. Max 1 emoji.`}`
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: JSON.stringify({ current_moods: moods, time_of_day: timeOfDay, activities_count: activitiesCount }) }], max_tokens: 100, temperature: 0.75 }) })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json()
    const text = (data.choices?.[0]?.message?.content || '').trim().replace(/^["']|["']$/g, '')
    if (text.length > 0 && text.length <= 280) return new Response(JSON.stringify({ message: text }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e) { console.error('❌ handleGenerateHubMessage:', e) }
  return new Response(JSON.stringify({ message: fallbackMessage }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
}

// ============================================
// DAY PLAN CONVERSION
// ============================================

function convertPlacesToActivities(places: PlaceCard[], moods: string[], location: string, coordinates: { lat: number; lng: number }, lang: 'nl' | 'en'): Activity[] {
  const activities: Activity[] = [], used = new Set<string>()
  const morning: PlaceCard[] = [], afternoon: PlaceCard[] = [], evening: PlaceCard[] = []
  for (const p of places) { if (used.has(p.id)) continue; const slots = getTimeSlotsForPlace(p); if (slots.includes('morning')) morning.push(p); if (slots.includes('afternoon')) afternoon.push(p); if (slots.includes('evening')) evening.push(p) }
  const now = new Date(), today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  // Fill up to [count] per slot by scanning the whole pool — the old index loop skipped
  // slots when pool[i] was already used, so users often saw fewer than 3 per period.
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
  const placeId = place.id.replace('google_', ''), moodText = moods.join(lang==='nl'?' en ':' and ').toLowerCase(), r = place.rating.toFixed(1)
  const desc = place.editorial_summary || (lang==='nl' ? `${place.name} is een topadres voor je ${moodText} dag. Gewaardeerd ${r} sterren.` : `${place.name} is a top spot for your ${moodText} day. Rated ${r} stars.`)
  const types = place.types || [], tags: string[] = []
  if (types.some(t=>['restaurant','food','food_court'].includes(t))) tags.push('Food')
  if (types.some(t=>['spa','beauty_salon'].includes(t))) tags.push('Wellness')
  if (types.some(t=>['museum','art_gallery'].includes(t))) tags.push(lang==='nl'?'Cultuur':'Culture')
  if (types.some(t=>['park','natural_feature'].includes(t))) tags.push(lang==='nl'?'Buiten':'Outdoors')
  if (types.some(t=>['bar','night_club'].includes(t))) tags.push('Nightlife')
  if (types.some(t=>['cafe','bakery','coffee_shop'].includes(t))) tags.push('Cafe')
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
