import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import { corsHeaders } from '../_shared/cors.ts'

// ============================================
// Types
// ============================================

interface MoodyRequest {
  action: 'get_explore' | 'create_day_plan' | 'chat'
  mood?: string
  location?: string // City name (e.g., "Rotterdam")
  coordinates?: {
    lat: number
    lng: number
  }
  filters?: {
    priceLevel?: number
    rating?: number
    types?: string[]
    radius?: number
  }
  [key: string]: any // Allow additional params for future actions
}

interface PlaceCard {
  id: string
  name: string
  rating: number
  types: string[]
  location: {
    lat: number
    lng: number
  }
  photo_reference?: string
  photo_url?: string // Full photo URL from Google Places API
  price_level?: number
  vicinity?: string
  address?: string
  description?: string
}

interface ExploreResponse {
  cards: PlaceCard[]
  cached: boolean
  total_found: number
  cache_key?: string
  unfiltered_total?: number // Total places before client-side filtering
  filters_applied?: boolean // Whether filters were applied client-side
}

interface Activity {
  id: string
  name: string
  description: string
  timeSlot: string
  duration: number
  location: {
    latitude: number
    longitude: number
  }
  paymentType: string
  imageUrl: string
  rating: number
  tags: string[]
  startTime: string // ISO 8601
  priceLevel?: string
  placeId?: string // Google Place ID for photos, open_now, etc.
}

interface DayPlanResponse {
  success: boolean
  activities: Activity[]
  location: {
    city: string
    latitude: number
    longitude: number
  }
  total_found: number
  error?: string
  moodyMessage?: string
  reasoning?: string
}

// ============================================
// Main Handler
// ============================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Initialize Supabase client
    // CRITICAL: Supabase automatically provides SUPABASE_URL and SUPABASE_ANON_KEY
    // These should NOT be set as secrets (Supabase blocks SUPABASE_ prefix)
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    
    // CRITICAL: Log environment variable availability for debugging
    console.log('🔧 Edge Function Environment Check:')
    console.log(`   SUPABASE_URL: ${supabaseUrl ? 'EXISTS (' + supabaseUrl.substring(0, 30) + '...)' : 'MISSING ❌'}`)
    console.log(`   SUPABASE_ANON_KEY: ${supabaseAnonKey ? 'EXISTS (' + supabaseAnonKey.substring(0, 20) + '...)' : 'MISSING ❌'}`)
    
    // CRITICAL: If auto-provided env vars are missing, Edge Function cannot validate tokens
    if (!supabaseUrl || supabaseUrl === '') {
      console.error('❌ CRITICAL: SUPABASE_URL is missing!')
      console.error('   This should be auto-provided by Supabase. Redeploy the function.')
      return new Response(
        JSON.stringify({ 
          success: false,
          error: 'Server configuration error',
          message: 'Edge Function environment not properly configured'
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }
    
    if (!supabaseAnonKey || supabaseAnonKey === '') {
      console.error('❌ CRITICAL: SUPABASE_ANON_KEY is missing!')
      console.error('   This should be auto-provided by Supabase. Redeploy the function.')
      return new Response(
        JSON.stringify({ 
          success: false,
          error: 'Server configuration error',
          message: 'Edge Function environment not properly configured'
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }
    
    // CRITICAL: Require proper authentication - no test user fallbacks
    const authHeader = req.headers.get('Authorization')
    
    // Log auth header presence (without exposing full token)
    if (authHeader) {
      console.log(`🔑 Authorization header: PRESENT (Bearer ${authHeader.substring(7, 27)}...)`)
    } else {
      console.log('🔑 Authorization header: MISSING')
    }
    
    let supabase
    let user: any = null
    
    // CRITICAL: Must have auth header with Bearer token
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.error('❌ No authorization header provided')
      return new Response(
        JSON.stringify({ 
          success: false,
          error: 'Authentication required',
          message: 'Please provide a valid authorization token'
        }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }
    
    // Authenticate with the provided token
    // CRITICAL: Extract token from Bearer header and pass directly to getUser()
    // When session persistence is disabled, getUser() without a token will fail with "Auth session missing!"
    const token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : authHeader
    
    console.log('🔧 Creating Supabase client with auth...')
    console.log(`   supabaseUrl: ${supabaseUrl.substring(0, 30)}...`)
    console.log(`   supabaseAnonKey: ${supabaseAnonKey ? supabaseAnonKey.substring(0, 20) + '...' : 'MISSING'}`)
    console.log(`   Token preview: ${token.substring(0, 30)}...`)
    
      const supabaseWithAuth = createClient(supabaseUrl, supabaseAnonKey, {
        global: {
        headers: {
          Authorization: authHeader, // user JWT from request
          apikey: supabaseAnonKey, // ensure GoTrue sees the project key as well
        },
      },
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
        },
      })
      
    console.log('🔍 Calling getUser() with token to validate...')
    // CRITICAL: Pass token directly to getUser() instead of relying on session
    // This prevents "Auth session missing!" error when session persistence is disabled
    const { data: { user: authUser }, error: authError } = await supabaseWithAuth.auth.getUser(token)
    
    if (authError) {
      console.error('❌ getUser() error details:')
      console.error(`   Error message: ${authError.message}`)
      console.error(`   Error status: ${authError.status}`)
      console.error(`   Error name: ${authError.name}`)
      console.error(`   Full error: ${JSON.stringify(authError, null, 2)}`)
    }
    
    if (authError || !authUser) {
      console.error('❌ Authentication failed:', authError?.message || 'No user returned')
      console.error('   Full error object:', JSON.stringify(authError, null, 2))
      return new Response(
        JSON.stringify({ 
          success: false,
          error: 'Authentication failed',
          message: authError?.message || 'Invalid or expired token'
        }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }
    
    // CRITICAL: Validate user ID is a valid UUID (not a test string)
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!authUser.id || typeof authUser.id !== 'string' || !uuidRegex.test(authUser.id)) {
      console.error('❌ Invalid user ID format:', authUser.id)
      return new Response(
        JSON.stringify({ 
          success: false,
          error: 'Invalid user ID',
          message: 'User ID must be a valid UUID'
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }
    
        user = authUser
        supabase = supabaseWithAuth
        console.log('✅ Authenticated user:', user.id)

    // 2. Parse request body
    let body: MoodyRequest
    try {
      body = await req.json()
    } catch (error) {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON in request body' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }
    const { action, ...params } = body

    if (!action) {
      return new Response(
        JSON.stringify({ error: 'Action is required' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log(`🎯 Moody Edge Function: action=${action}, userId=${user.id}`)

    // 3. Route by action
    switch (action) {
      case 'get_explore':
        return await handleGetExplore(supabase, user.id, params)
      
      case 'create_day_plan':
        return await handleCreateDayPlan(supabase, user.id, params)
      
      case 'chat':
        return new Response(
          JSON.stringify({ error: 'Not implemented yet' }),
          { 
            status: 501, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      
      default:
        return new Response(
          JSON.stringify({ error: `Invalid action: ${action}` }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
    }
  } catch (error) {
    console.error('❌ Moody Edge Function error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

// ============================================
// Action Handlers
// ============================================

async function handleCreateDayPlan(
  supabase: any,
  userId: string,
  params: any
): Promise<Response> {
  try {
    // CRITICAL: Location is REQUIRED - no defaults allowed
    if (!params.location || params.location.trim() === '') {
      console.error('❌ Location is required but missing')
      return new Response(
        JSON.stringify({ 
          success: false,
          error: 'Location is required',
          message: 'Please provide a valid location (city name)',
          activities: [],
          total_found: 0
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // CRITICAL: Coordinates are REQUIRED - no defaults allowed
    if (!params.coordinates || typeof params.coordinates.lat !== 'number' || typeof params.coordinates.lng !== 'number') {
      console.error('❌ Coordinates are required but missing or invalid')
      return new Response(
        JSON.stringify({ 
          success: false,
          error: 'Coordinates are required',
          message: 'Please provide valid latitude and longitude coordinates',
          activities: [],
          total_found: 0
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const moods = params.moods || ['adventurous']
    const location = params.location.trim()
    const coordinates = params.coordinates

    console.log(`🎯 create_day_plan: moods=${moods.join(', ')}, location=${location}, coordinates=(${coordinates.lat}, ${coordinates.lng})`)

    // 1. (Optional) Fetch user profile so Moody can consider preferences
    let profile: { favorite_mood?: string; travel_style?: string; travel_vibes?: string; [key: string]: any } | null = null
    const { data: profileData } = await supabase
      .from('profiles')
      .select('favorite_mood, travel_style, travel_vibes, mood_preferences, travel_preferences')
      .eq('id', userId)
      .maybeSingle()
    if (profileData) profile = profileData

    // 2. Ask Moody (OpenAI) for search queries based on moods + user context; fallback to fixed map if unavailable
    const moodyQueries = await getMoodySearchQueries(moods, location, profile)
    const filters = params.filters || {}

    // 3. Fetch places from Google using Moody's queries (or fallback)
    const places = await fetchPlacesFromGoogle(location, coordinates, moods[0], filters, moodyQueries)

    // 2. CRITICAL: If no places found, return structured empty state
    if (places.length === 0) {
      console.log('⚠️ No places found for day plan - returning empty state')
      return new Response(
        JSON.stringify({
          success: false,
          activities: [],
          location: {
            city: location,
            latitude: coordinates.lat,
            longitude: coordinates.lng,
          },
          total_found: 0,
          error: 'No places found',
          message: 'No activities found for your selected moods and location. Please try different moods or check your location settings.'
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 3. Convert places to activities with time slots
    const activities = convertPlacesToActivities(places, moods, location, coordinates)

    // 4. CRITICAL: If conversion resulted in no activities, return empty state
    if (activities.length === 0) {
      console.log('⚠️ No activities generated from places - returning empty state')
      return new Response(
        JSON.stringify({
          success: false,
          activities: [],
          location: {
            city: location,
            latitude: coordinates.lat,
            longitude: coordinates.lng,
          },
          total_found: 0,
          error: 'No activities generated',
          message: 'Could not generate activities from available places. Please try different moods.'
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log(`✅ Generated ${activities.length} activities for day plan`)

    // 5. Generate Moody personality response (non-blocking; graceful fallback)
    const { moodyMessage, reasoning } = await getMoodyPersonalityResponse(moods, activities, location)

    // 6. Return successful response
    const response: DayPlanResponse = {
      success: true,
      activities: activities,
      location: {
        city: location,
        latitude: coordinates.lat,
        longitude: coordinates.lng,
      },
      total_found: activities.length,
      moodyMessage,
      reasoning,
    }

    return new Response(
      JSON.stringify(response),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    console.error('❌ Error in handleCreateDayPlan:', error)
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message || 'Failed to create day plan',
        activities: [],
        total_found: 0
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
}

async function handleGetExplore(
  supabase: any,
  userId: string,
  params: any
): Promise<Response> {
  try {
    // CRITICAL: Location is REQUIRED - no defaults allowed
    if (!params.location || params.location.trim() === '') {
      console.error('❌ Location is required but missing')
      return new Response(
        JSON.stringify({ 
          error: 'Location is required',
          message: 'Please provide a valid location (city name)'
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // CRITICAL: Coordinates are REQUIRED - no defaults allowed
    if (!params.coordinates || typeof params.coordinates.lat !== 'number' || typeof params.coordinates.lng !== 'number') {
      console.error('❌ Coordinates are required but missing or invalid')
      return new Response(
        JSON.stringify({ 
          error: 'Coordinates are required',
          message: 'Please provide valid latitude and longitude coordinates'
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const mood = params.mood || 'adventurous'
    const location = params.location.trim()
    const coordinates = params.coordinates
    const filters = params.filters || {}

    console.log(`🔍 get_explore: mood=${mood}, location=${location}, coordinates=(${coordinates.lat}, ${coordinates.lng})`)

    // 1. Get user preferences from profiles table
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('favorite_mood, travel_style, travel_vibes')
      .eq('id', userId)
      .maybeSingle()

    if (profileError) {
      // Log error but don't fail - profile is optional
      console.warn('⚠️ Could not fetch user profile:', profileError)
      // If error is due to invalid UUID, log it specifically
      if (profileError.code === '22P02' || profileError.message?.includes('invalid input syntax for type uuid')) {
        console.error('❌ CRITICAL: Invalid user ID format in profile query:', userId)
        console.error('   This should not happen - user ID was validated earlier')
      }
    }

    // 2. Check if we're in dev mode (use cache only, no API calls)
    const isDevMode = Deno.env.get('DEV_MODE') === 'true' || Deno.env.get('NODE_ENV') === 'development'
    
    // 3. Check cache first - CRITICAL: Cache by city + mood only (NOT filters)
    // Filters are applied client-side to avoid fragmenting cache
    const cacheKey = `explore_${mood}_${location.toLowerCase().trim()}`
    const cachedResult = await checkCache(supabase, cacheKey, userId)

    if (cachedResult && cachedResult.cards.length >= 50) {
      console.log(`✅ Using cached explore results (${cachedResult.cards.length} places)`)
      // Apply filters client-side (filters are passed in response but not used for caching)
      const filteredCards = applyFilters(cachedResult.cards, filters)
      return new Response(
        JSON.stringify({
          ...cachedResult,
          cards: filteredCards,
          total_found: filteredCards.length,
          filters_applied: true,
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 4. DEV MODE: If cache miss and in dev mode, return empty or error (don't make API calls)
    if (isDevMode) {
      console.log('🚫 DEV MODE: Cache miss - returning empty results to avoid API costs')
      console.log('💡 To populate cache, make API calls in production mode first')
      return new Response(
        JSON.stringify({
          cards: [],
          cached: false,
          total_found: 0,
          error: 'DEV_MODE: No cached data available. Please populate cache in production mode first.',
          message: 'Development mode is enabled. API calls are disabled to save costs. Use cached data or switch to production mode.',
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 5. PRODUCTION MODE: Cache miss - fetch from Google Places API
    console.log('🔄 Cache miss or insufficient places - fetching from Google Places API')
    let places = await fetchPlacesFromGoogle(location, coordinates, mood, {})

    // 4. CRITICAL: Ensure we have MINIMUM 50 places (keep fetching until we have 50+)
    let fetchAttempts = 0
    const maxAttempts = 5
    while (places.length < 50 && fetchAttempts < maxAttempts) {
      fetchAttempts++
      console.log(`⚠️ Only found ${places.length} places, fetching more (attempt ${fetchAttempts}/${maxAttempts})...`)
      
      const additionalPlaces = await fetchFallbackPlaces(location, coordinates, [mood])
      
      // Combine and remove duplicates
      const allPlaces = [...places, ...additionalPlaces]
      const uniquePlaces = Array.from(
        new Map(allPlaces.map(p => [p.id, p])).values()
      )
      
      places = uniquePlaces
      
      // If we still don't have 50, try broader searches
      if (places.length < 50 && fetchAttempts < maxAttempts) {
        const broaderPlaces = await fetchBroaderPlaces(location, coordinates, [mood])
        const allPlacesWithBroader = [...places, ...broaderPlaces]
        places = Array.from(
          new Map(allPlacesWithBroader.map(p => [p.id, p])).values()
        )
      }
    }

    // Cap at 80 places max
    places = places.slice(0, 80)
    console.log(`✅ Fetched ${places.length} total places (minimum 50 required)`)

    // 5. Rank by user preferences (soft ranking, not filtering)
    const rankedPlaces = rankPlacesByPreferences(places, profile, mood, {})

    // 6. Cache results (without filters - filters applied client-side)
    // Cache the full explore response for dev mode reuse
    await cachePlaces(supabase, cacheKey, rankedPlaces, userId, location)

    // 7. Apply filters client-side and return response
    const filteredCards = applyFilters(rankedPlaces, filters)
    
    const response: ExploreResponse = {
      cards: filteredCards,
      cached: false,
      total_found: filteredCards.length,
      cache_key: cacheKey,
      unfiltered_total: rankedPlaces.length, // Total before filtering
    }

    console.log(`✅ Returning ${response.cards.length} places (${response.unfiltered_total} unfiltered) for explore`)

    // 8. CRITICAL: If filtered results < 5, log warning (client should trigger wider fetch)
    if (filteredCards.length < 5 && rankedPlaces.length >= 50) {
      console.warn(`⚠️ Filters reduced results to ${filteredCards.length} places. Client should trigger wider fetch.`)
    }

    console.log(`✅ Returning ${response.cards.length} places for explore`)

    return new Response(
      JSON.stringify(response),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    console.error('❌ Error in handleGetExplore:', error)
    throw error
  }
}

// ============================================
// Helper Functions
// ============================================

async function checkCache(
  supabase: any,
  cacheKey: string,
  userId: string
): Promise<ExploreResponse | null> {
  try {
    const { data, error } = await supabase
      .from('places_cache')
      .select('data, place_id, expires_at')
      .eq('cache_key', cacheKey)
      .eq('user_id', userId)
      .maybeSingle()

    if (error || !data) return null

    const expiresAt = new Date(data.expires_at)
    if (expiresAt < new Date()) {
      console.log('⏰ Cache expired')
      return null
    }

    const cachedData = data.data
    if (!cachedData || !cachedData.cards) return null

    return {
      cards: cachedData.cards,
      cached: true,
      total_found: cachedData.cards.length,
      cache_key: cacheKey,
    }
  } catch (error) {
    console.error('❌ Error checking cache:', error)
    return null
  }
}

async function fetchPlacesFromGoogle(
  location: string,
  coordinates: { lat: number; lng: number },
  mood: string,
  filters: any,
  queriesOverride?: string[] | null
): Promise<PlaceCard[]> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey || apiKey.trim() === '') {
    console.error('❌ GOOGLE_PLACES_API_KEY not set in Edge Function environment')
    console.error('🔧 Please set GOOGLE_PLACES_API_KEY in Supabase Dashboard → Edge Functions → Settings → Secrets')
    throw new Error('GOOGLE_PLACES_API_KEY not configured in Edge Function environment')
  }

  console.log(`🔑 API Key verified: ${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 4)}`)
  console.log(`📍 Using provided coordinates: (${coordinates.lat}, ${coordinates.lng})`)
  
  // Use Moody-suggested queries when provided; otherwise fallback to fixed mood map
  const moodQueries = (queriesOverride && queriesOverride.length > 0) ? queriesOverride : getMoodQueries(mood)
  console.log(`🎯 Queries for "${mood}":`, moodQueries)
  const allPlaces: PlaceCard[] = []

  // Fetch places for each mood query (to get variety)
  for (const query of moodQueries) {
    try {
      const fullQuery = `${query} in ${location}`
      const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?` +
        `query=${encodeURIComponent(fullQuery)}` +
        `&location=${coordinates.lat},${coordinates.lng}` +
        `&radius=${filters.radius || 15000}` +
        `&key=${apiKey}`

      console.log(`🌐 Fetching: ${fullQuery}`)
      const response = await fetch(url)
      const data = await response.json()

      console.log(`📊 API Response status: ${data.status}, results: ${data.results?.length || 0}`)
      
      if (data.status === 'OK' && data.results) {
        const places = data.results.map((place: any) => transformPlace(place, [mood]))
        allPlaces.push(...places)
        console.log(`✅ Added ${places.length} places from query "${query}"`)
      } else if (data.status !== 'OK') {
        console.error(`❌ Google Places API error: ${data.status} - ${data.error_message || 'Unknown error'}`)
      }

      // Rate limiting: small delay between requests
      await new Promise(resolve => setTimeout(resolve, 100))
    } catch (error) {
      console.error(`❌ Error fetching places for query "${query}":`, error)
    }
  }

  // Remove duplicates by place_id
  const uniquePlaces = Array.from(
    new Map(allPlaces.map(p => [p.id, p])).values()
  )

  console.log(`📦 Total unique places fetched: ${uniquePlaces.length}`)
  return uniquePlaces
}

async function fetchFallbackPlaces(location: string, coordinates: { lat: number; lng: number }, moods: string[] = ['adventurous']): Promise<PlaceCard[]> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey || apiKey.trim() === '') {
    console.error('❌ GOOGLE_PLACES_API_KEY not set for fallback fetch')
    return []
  }
  
  const queries = [
    'popular attractions',
    'tourist spots',
    'things to do',
    'restaurants',
    'cafes',
    'museums',
  ]

  const allPlaces: PlaceCard[] = []

  for (const query of queries) {
    try {
      const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?` +
        `query=${encodeURIComponent(query + ' in ' + location)}` +
        `&location=${coordinates.lat},${coordinates.lng}` +
        `&radius=20000` +
        `&key=${apiKey}`

      const response = await fetch(url)
      const data = await response.json()

      if (data.status === 'OK' && data.results) {
        const places = data.results.map((place: any) => transformPlace(place, moods))
        allPlaces.push(...places)
      }

      await new Promise(resolve => setTimeout(resolve, 100))
    } catch (error) {
      console.error(`❌ Error fetching fallback places:`, error)
    }
  }

  const uniquePlaces = Array.from(
    new Map(allPlaces.map(p => [p.id, p])).values()
  )

  return uniquePlaces
}

async function fetchBroaderPlaces(location: string, coordinates: { lat: number; lng: number }, moods: string[] = ['adventurous']): Promise<PlaceCard[]> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey || apiKey.trim() === '') {
    return []
  }
  
  const queries = [
    'attractions',
    'landmarks',
    'shopping',
    'entertainment',
    'nightlife',
    'parks',
    'beaches',
    'markets',
  ]

  const allPlaces: PlaceCard[] = []

  for (const query of queries) {
    try {
      const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?` +
        `query=${encodeURIComponent(query + ' in ' + location)}` +
        `&location=${coordinates.lat},${coordinates.lng}` +
        `&radius=30000` +
        `&key=${apiKey}`

      const response = await fetch(url)
      const data = await response.json()

      if (data.status === 'OK' && data.results) {
        const places = data.results.map((place: any) => transformPlace(place, moods))
        allPlaces.push(...places)
      }

      await new Promise(resolve => setTimeout(resolve, 100))
    } catch (error) {
      console.error(`❌ Error fetching broader places:`, error)
    }
  }

  const uniquePlaces = Array.from(
    new Map(allPlaces.map(p => [p.id, p])).values()
  )

  return uniquePlaces
}

function transformPlace(place: any, moods: string[] = []): PlaceCard {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  const photoReference = place.photos?.[0]?.photo_reference
  
  // Build full photo URL if photo reference exists
  let photoUrl: string | undefined
  if (photoReference && apiKey) {
    photoUrl = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${photoReference}&key=${apiKey}`
  }

  // CRITICAL: Always generate a description (either from Google or custom)
  const description = place.editorial_summary?.overview || generatePlaceDescription(place, moods)

  return {
    id: `google_${place.place_id}`,
    name: place.name,
    rating: place.rating || 0,
    types: place.types || [],
    location: {
      lat: place.geometry?.location?.lat || 0,
      lng: place.geometry?.location?.lng || 0,
    },
    photo_reference: photoReference, // Keep for backward compatibility
    photo_url: photoUrl, // Full URL ready to use
    price_level: place.price_level,
    vicinity: place.vicinity,
    address: place.formatted_address,
    description: description, // CRITICAL: Always populated
  }
}

// Generate a description for a place if Google Places API doesn't provide one
function generatePlaceDescription(place: any, moods: string[] = []): string {
  const name = place.name || 'This place'
  const rating = place.rating ? place.rating.toFixed(1) : '4.0'
  const types = place.types || []
  const moodText = moods.length > 0 ? moods.join(' and ').toLowerCase() : 'your'
  
  if (types.some((t: string) => t.includes('restaurant') || t.includes('food'))) {
    return `${name} offers delicious cuisine perfect for ${moodText} mood. A welcoming atmosphere with ${rating} stars.`
  } else if (types.some((t: string) => t.includes('cafe') || t.includes('coffee'))) {
    return `${name} is a cozy spot perfect for coffee and ${moodText} vibes. Rated ${rating} stars.`
  } else if (types.some((t: string) => t.includes('museum') || t.includes('gallery'))) {
    return `Explore culture and art at ${name}. A fascinating destination for ${moodText} experiences with ${rating} stars.`
  } else if (types.some((t: string) => t.includes('park') || t.includes('garden'))) {
    return `${name} offers a peaceful natural setting perfect for ${moodText} outdoor moments. Rated ${rating} stars.`
  } else if (types.some((t: string) => t.includes('tourist_attraction') || t.includes('landmark'))) {
    return `Discover ${name}, a popular attraction that captures ${moodText} spirit. Rated ${rating} stars.`
  } else if (types.some((t: string) => t.includes('bar') || t.includes('nightclub'))) {
    return `${name} is a vibrant venue perfect for ${moodText} evening entertainment. Rated ${rating} stars.`
  } else if (types.some((t: string) => t.includes('shopping') || t.includes('store'))) {
    return `${name} offers great shopping experiences for ${moodText} adventures. Rated ${rating} stars.`
  }
  
  return `${name} is a highly-rated local destination perfect for ${moodText} experiences. Rated ${rating} stars.`
}

function rankPlacesByPreferences(
  places: PlaceCard[],
  profile: any,
  mood: string,
  filters: any
): PlaceCard[] {
  // CRITICAL: Only RANK, do NOT filter - filters are applied client-side
  // This ensures we always have 50+ places to work with
  return places.sort((a, b) => {
    // Sort by rating (descending)
    if (b.rating !== a.rating) return b.rating - a.rating
    // Then by price level (ascending - cheaper first)
    if (a.price_level && b.price_level) {
      return a.price_level - b.price_level
    }
    return 0
  })
}

// Apply filters client-side (after fetching 50+ places)
function applyFilters(places: PlaceCard[], filters: any): PlaceCard[] {
  if (!filters || Object.keys(filters).length === 0) {
    return places // No filters, return all
  }

  return places.filter(place => {
      // Hard filters (if specified)
      if (filters.rating && place.rating < filters.rating) return false
      if (filters.priceLevel && place.price_level && place.price_level > filters.priceLevel) return false
      if (filters.types && filters.types.length > 0) {
        const hasMatchingType = place.types.some(type => 
          filters.types.some((filterType: string) => 
            type.toLowerCase().includes(filterType.toLowerCase())
          )
        )
        if (!hasMatchingType) return false
      }
      return true
    })
}

async function cachePlaces(
  supabase: any,
  cacheKey: string,
  places: PlaceCard[],
  userId: string,
  location: string
): Promise<void> {
  try {
    const expiresAt = new Date()
    expiresAt.setHours(expiresAt.getHours() + 1) // Cache for 1 hour

    // Store each place in places_cache with place_id
    const cacheEntries = places.map(place => {
      // Extract place_id from id (format: "google_ChIJ...")
      const placeId = place.id.startsWith('google_') 
        ? place.id.substring('google_'.length)
        : place.id

      return {
        cache_key: `${cacheKey}_${placeId}`,
        data: place,
        place_id: placeId, // Store place_id as column
        user_id: userId,
        request_type: 'explore',
        expires_at: expiresAt.toISOString(),
      }
    })

    // Batch insert (Supabase allows up to 1000 rows per insert)
    for (let i = 0; i < cacheEntries.length; i += 100) {
      const batch = cacheEntries.slice(i, i + 100)
      await supabase
        .from('places_cache')
        .upsert(batch, { onConflict: 'cache_key' })
    }

    // Also store the full response in a single cache entry
    await supabase
      .from('places_cache')
      .upsert({
        cache_key: cacheKey,
        data: { cards: places },
        place_id: null, // This is the aggregate cache entry
        user_id: userId,
        request_type: 'explore',
        expires_at: expiresAt.toISOString(),
      }, { onConflict: 'cache_key' })

    console.log(`💾 Cached ${places.length} places`)
  } catch (error) {
    console.error('❌ Error caching places:', error)
    // Don't throw - caching failure shouldn't break the request
  }
}

// REMOVED: getLocationCoords() - coordinates must now be provided by client
// This ensures location is always accurate and not hardcoded

/** Ask Moody (OpenAI) for 5–8 Google Places search query strings from moods + location + optional profile. Returns null on missing key or failure. */
async function getMoodySearchQueries(
  moods: string[],
  location: string,
  profile: { favorite_mood?: string; travel_style?: string; travel_vibes?: string; [key: string]: any } | null
): Promise<string[] | null> {
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey || openaiKey.trim() === '') {
    console.log('⚠️ OPENAI_API_KEY not set; using fallback mood queries')
    return null
  }

  const profileSnippet = profile
    ? `User profile: favorite_mood=${profile.favorite_mood || 'any'}, travel_style=${profile.travel_style || 'any'}, travel_vibes=${profile.travel_vibes || 'any'}.`
    : 'No user profile.'

  const systemPrompt = `You are Moody, the WanderMood travel assistant. Given the user's moods and location, output exactly one JSON object with a single key "queries" whose value is an array of 5 to 8 short Google Places search query strings (e.g. "romantic restaurants", "sunset viewpoints", "food tours"). Each string should be a few words only, no full sentences. These will be used to search Google Places API in "${location}". Consider the user's profile when relevant. Output only valid JSON, no markdown.`

  const userPrompt = `Moods: ${moods.join(', ')}. Location: ${location}. ${profileSnippet} Return JSON: { "queries": ["query1", "query2", ...] }`

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        max_tokens: 300,
        temperature: 0.5,
        response_format: { type: 'json_object' },
      }),
    })

    if (!response.ok) {
      const errText = await response.text()
      console.error('❌ OpenAI error:', response.status, errText)
      return null
    }

    const data = await response.json()
    const content = data.choices?.[0]?.message?.content
    if (!content || typeof content !== 'string') return null

    const parsed = JSON.parse(content) as { queries?: unknown }
    const queries = Array.isArray(parsed.queries)
      ? (parsed.queries as unknown[]).filter((q): q is string => typeof q === 'string').slice(0, 8)
      : []
    if (queries.length === 0) return null

    console.log('🤖 Moody suggested queries:', queries)
    return queries
  } catch (e) {
    console.error('❌ getMoodySearchQueries error:', e)
    return null
  }
}

/** Generate a warm Moody personality message after a day plan is created.
 *  Falls back to a template when OpenAI is unavailable. */
async function getMoodyPersonalityResponse(
  moods: string[],
  activities: Activity[],
  location: string
): Promise<{ moodyMessage: string; reasoning: string }> {
  const fallback = {
    moodyMessage: `Found ${activities.length} amazing activities for your ${moods.join(' & ')} day in ${location}! 🎯`,
    reasoning: `Picked a mix of morning, afternoon and evening experiences matched to your ${moods.join(' and ')} mood.`,
  }

  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey || openaiKey.trim() === '') {
    return fallback
  }

  const activityNames = activities.slice(0, 3).map(a => a.name).join(', ')

  const systemPrompt = `You are Moody, a friendly AI travel companion for WanderMood. Speak warmly and concisely. Use 1-2 emojis max. Never be cheesy or over-the-top.`
  const userPrompt = `The user chose these moods: ${moods.join(', ')}. I found ${activities.length} activities in ${location} including: ${activityNames}. Return ONLY a JSON object: {"moodyMessage": "<1-2 sentence warm reaction, max 100 chars>", "reasoning": "<1 sentence why these fit their mood, max 80 chars>"}`

  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        max_tokens: 150,
        temperature: 0.7,
        response_format: { type: 'json_object' },
      }),
    })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json()
    const content = data.choices?.[0]?.message?.content
    if (!content) throw new Error('No content')
    const parsed = JSON.parse(content) as { moodyMessage?: string; reasoning?: string }
    return {
      moodyMessage: parsed.moodyMessage || fallback.moodyMessage,
      reasoning: parsed.reasoning || fallback.reasoning,
    }
  } catch (e) {
    console.error('getMoodyPersonalityResponse error (non-fatal):', e)
    return fallback
  }
}

function getMoodQueries(mood: string): string[] {
  const moodMap: Record<string, string[]> = {
    'adventurous': [
      'adventure activities',
      'extreme sports',
      'hiking trails',
      'outdoor activities',
      'adventure tours',
    ],
    'relaxed': [
      'spa centers',
      'beaches',
      'parks',
      'cafes',
      'relaxation spots',
    ],
    'cultural': [
      'museums',
      'art galleries',
      'historical sites',
      'cultural centers',
      'monuments',
    ],
    'romantic': [
      'romantic restaurants',
      'scenic spots',
      'sunset views',
      'romantic places',
    ],
    'social': [
      'bars',
      'nightlife',
      'social events',
      'meeting places',
    ],
    'contemplative': [
      'quiet places',
      'libraries',
      'gardens',
      'meditation centers',
    ],
    'energetic': [
      'gyms',
      'sports facilities',
      'dance clubs',
      'fitness centers',
    ],
    'creative': [
      'art studios',
      'workshops',
      'creative spaces',
      'design centers',
    ],
  }

  return moodMap[mood.toLowerCase()] || moodMap['adventurous']
}

// ============================================
// Day Plan Conversion
// ============================================

function convertPlacesToActivities(
  places: PlaceCard[],
  moods: string[],
  location: string,
  coordinates: { lat: number; lng: number }
): Activity[] {
  const activities: Activity[] = []
  const usedPlaceIds = new Set<string>()
  
  // Shuffle places for variety
  const shuffledPlaces = [...places].sort(() => Math.random() - 0.5)
  
  // Categorize places by time slot suitability
  const morningPlaces: PlaceCard[] = []
  const afternoonPlaces: PlaceCard[] = []
  const eveningPlaces: PlaceCard[] = []
  
  for (const place of shuffledPlaces) {
    if (usedPlaceIds.has(place.id)) continue
    
    const timeSlots = getTimeSlotsForPlace(place)
    
    if (timeSlots.includes('morning')) morningPlaces.push(place)
    if (timeSlots.includes('afternoon')) afternoonPlaces.push(place)
    if (timeSlots.includes('evening')) eveningPlaces.push(place)
  }
  
  // Distribute activities across time slots (2-3 per slot)
  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  
  // Morning activities (7-11 AM)
  for (let i = 0; i < Math.min(3, morningPlaces.length); i++) {
    const place = morningPlaces[i]
    if (usedPlaceIds.has(place.id)) continue
    
    usedPlaceIds.add(place.id)
    const hour = 7 + Math.floor(Math.random() * 4) // 7-10 AM
    const minute = [0, 15, 30, 45][Math.floor(Math.random() * 4)]
    const startTime = new Date(today.getTime())
    startTime.setHours(hour, minute, 0, 0)
    
    // If it's already past morning, schedule for next day
    if (now.getHours() >= 11) {
      startTime.setDate(startTime.getDate() + 1)
    }
    
    activities.push(createActivityFromPlace(place, 'morning', startTime, moods))
  }
  
  // Afternoon activities (12-5 PM)
  for (let i = 0; i < Math.min(3, afternoonPlaces.length); i++) {
    const place = afternoonPlaces[i]
    if (usedPlaceIds.has(place.id)) continue
    
    usedPlaceIds.add(place.id)
    const hour = 12 + Math.floor(Math.random() * 5) // 12-4 PM
    const minute = [0, 15, 30, 45][Math.floor(Math.random() * 4)]
    const startTime = new Date(today.getTime())
    startTime.setHours(hour, minute, 0, 0)
    
    // If it's already past afternoon, schedule for next day
    if (now.getHours() >= 17) {
      startTime.setDate(startTime.getDate() + 1)
    }
    
    activities.push(createActivityFromPlace(place, 'afternoon', startTime, moods))
  }
  
  // Evening activities (5-9 PM)
  for (let i = 0; i < Math.min(3, eveningPlaces.length); i++) {
    const place = eveningPlaces[i]
    if (usedPlaceIds.has(place.id)) continue
    
    usedPlaceIds.add(place.id)
    const hour = 17 + Math.floor(Math.random() * 4) // 5-8 PM
    const minute = [0, 15, 30, 45][Math.floor(Math.random() * 4)]
    const startTime = new Date(today.getTime())
    startTime.setHours(hour, minute, 0, 0)
    
    // If it's already past evening, schedule for next day
    if (now.getHours() >= 21) {
      startTime.setDate(startTime.getDate() + 1)
    }
    
    activities.push(createActivityFromPlace(place, 'evening', startTime, moods))
  }
  
  // Sort activities by start time
  activities.sort((a, b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime())
  
  return activities
}

function getTimeSlotsForPlace(place: PlaceCard): string[] {
  const slots: string[] = []
  const types = place.types.map(t => t.toLowerCase())
  const name = place.name.toLowerCase()
  
  // Morning suitable
  if (types.some(t => ['cafe', 'bakery', 'park', 'library', 'spa', 'museum', 'art_gallery'].includes(t)) ||
      name.includes('coffee') || name.includes('breakfast') || name.includes('brunch')) {
    slots.push('morning')
  }
  
  // Afternoon suitable (most flexible)
  if (types.some(t => ['restaurant', 'museum', 'art_gallery', 'shopping_mall', 'tourist_attraction', 'food', 'cafe', 'park'].includes(t)) ||
      !name.includes('breakfast') && !name.includes('night') && !name.includes('club')) {
    slots.push('afternoon')
  }
  
  // Evening suitable
  if (types.some(t => ['restaurant', 'bar', 'night_club', 'entertainment'].includes(t)) ||
      name.includes('dinner') || name.includes('evening') || name.includes('bar') || name.includes('restaurant')) {
    slots.push('evening')
  }
  
  // Default to afternoon if no specific slots
  if (slots.length === 0) {
    slots.push('afternoon')
  }
  
  return slots
}

function createActivityFromPlace(
  place: PlaceCard,
  timeSlot: string,
  startTime: Date,
  moods: string[]
): Activity {
  const duration = estimateDuration(place.types)
  const paymentType = determinePaymentType(place.types, place.price_level)
  const priceLevel = place.price_level ? getPriceLevelText(place.price_level) : undefined
  
  // Generate description
  const description = generateDescription(place, moods)
  
  // Generate tags
  const tags = generateTags(place.types, moods)
  
  const placeId = place.id.startsWith('google_') ? place.id.substring(7) : place.id
  return {
    id: `activity_${Date.now()}_${place.id}`,
    name: place.name,
    description: description,
    timeSlot: timeSlot,
    duration: duration,
    location: {
      latitude: place.location.lat,
      longitude: place.location.lng,
    },
    paymentType: paymentType,
    imageUrl: place.photo_url || '',
    rating: place.rating,
    tags: tags,
    startTime: startTime.toISOString(),
    priceLevel: priceLevel,
    placeId: placeId,
  }
}

function estimateDuration(types: string[]): number {
  if (types.includes('restaurant')) return 90 // 1.5 hours
  if (types.includes('museum') || types.includes('art_gallery')) return 120 // 2 hours
  if (types.includes('park')) return 60 // 1 hour
  if (types.includes('spa') || types.includes('health')) return 90 // 1.5 hours
  if (types.includes('cafe') || types.includes('bakery')) return 45 // 45 minutes
  if (types.includes('bar') || types.includes('night_club')) return 120 // 2 hours
  return 60 // Default 1 hour
}

function determinePaymentType(types: string[], priceLevel?: number): string {
  if (types.includes('park') || types.includes('beach')) return 'free'
  if (types.includes('museum') || types.includes('amusement_park') || types.includes('movie_theater')) return 'ticket'
  if (types.includes('restaurant') || types.includes('bar') || types.includes('spa') || types.includes('gym')) return 'reservation'
  if (priceLevel === null || priceLevel === undefined || priceLevel === 0) return 'free'
  return 'reservation'
}

function getPriceLevelText(priceLevel: number): string | undefined {
  switch (priceLevel) {
    case 1: return '€'
    case 2: return '€€'
    case 3: return '€€€'
    case 4: return '€€€€'
    default: return undefined
  }
}

function generateDescription(place: PlaceCard, moods: string[]): string {
  const moodText = moods.join(' and ').toLowerCase()
  const rating = place.rating.toFixed(1)
  
  if (place.types.includes('restaurant')) {
    return `${place.name} serves exceptional cuisine that locals and tourists love. Experience flavors that match your ${moodText} mood. Rated ${rating} stars.`
  } else if (place.types.includes('cafe')) {
    return `${place.name} is the perfect coffee spot for your ${moodText} day. Enjoy quality coffee and a welcoming atmosphere. Rated ${rating} stars.`
  } else if (place.types.includes('museum') || place.types.includes('art_gallery')) {
    return `Immerse yourself in culture at ${place.name}. This inspiring venue offers enriching experiences perfect for your ${moodText} mood. Rated ${rating} stars.`
  } else if (place.types.includes('park')) {
    return `Escape to ${place.name} for a peaceful retreat in nature. This beautiful green space offers the perfect setting for your ${moodText} day. Rated ${rating} stars.`
  } else if (place.types.includes('tourist_attraction')) {
    return `Discover ${place.name}, a must-visit attraction that perfectly captures your ${moodText} spirit. This popular destination is rated ${rating} stars.`
  }
  
  return `${place.name} is a highly-rated local gem perfect for your ${moodText} experience. Discover what makes this place special. Rated ${rating} stars.`
}

function generateTags(types: string[], moods: string[]): string[] {
  const tags: string[] = []
  
  // Add type-based tags
  if (types.includes('restaurant') || types.includes('food')) tags.push('Food')
  if (types.includes('spa') || types.includes('beauty_salon')) tags.push('Wellness')
  if (types.includes('museum') || types.includes('art_gallery')) tags.push('Culture')
  if (types.includes('park') || types.includes('natural_feature')) tags.push('Outdoor')
  if (types.includes('bar') || types.includes('night_club')) tags.push('Nightlife')
  if (types.includes('cafe') || types.includes('bakery')) tags.push('Cafe')
  
  // Add mood-based tags if relevant
  for (const mood of moods) {
    const lowerMood = mood.toLowerCase()
    if (lowerMood === 'romantic' && (types.includes('restaurant') || types.includes('bar'))) {
      tags.push('Romantic')
    } else if (lowerMood === 'creative' && (types.includes('museum') || types.includes('art_gallery'))) {
      tags.push('Creative')
    } else if ((lowerMood === 'relaxed' || lowerMood === 'mindful') && (types.includes('spa') || types.includes('park'))) {
      tags.push('Relaxing')
    }
  }
  
  return tags.slice(0, 2) // Limit to 2 tags
}

