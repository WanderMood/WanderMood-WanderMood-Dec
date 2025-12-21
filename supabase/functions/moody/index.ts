import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import { corsHeaders } from '../_shared/cors.ts'

// ============================================
// Types
// ============================================

interface MoodyRequest {
  action: 'get_explore' | 'create_day_plan' | 'chat'
  mood?: string
  location?: string
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
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    
    // Check if this is a service role request (dashboard testing)
    const authHeader = req.headers.get('Authorization')
    
    // For dashboard testing: always use service role (more permissive)
    // In production (from Flutter app), we'll require proper auth
    let supabase
    let user
    
    // Use service role if available (dashboard testing), otherwise try anon key
    const keyToUse = serviceRoleKey || supabaseAnonKey
    supabase = createClient(supabaseUrl, keyToUse)
    
    // Try to get user if auth header exists, otherwise use test user
    if (authHeader && authHeader.startsWith('Bearer ')) {
      // Try to authenticate with the provided token
      const supabaseWithAuth = createClient(supabaseUrl, supabaseAnonKey, {
        global: {
          headers: { Authorization: authHeader },
        },
      })
      
      const { data: { user: authUser }, error: authError } = await supabaseWithAuth.auth.getUser()
      if (!authError && authUser) {
        user = authUser
        supabase = supabaseWithAuth
        console.log('✅ Authenticated user:', user.id)
      } else {
        // Auth failed, but allow for testing
        user = { id: 'dashboard-test-user' }
        console.log('⚠️ Auth failed, using test user for dashboard testing')
      }
    } else {
      // No auth header - dashboard testing mode
      user = { id: 'dashboard-test-user' }
      console.log('⚠️ No auth header - dashboard testing mode')
    }

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
        return new Response(
          JSON.stringify({ error: 'Not implemented yet' }),
          { 
            status: 501, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      
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

async function handleGetExplore(
  supabase: any,
  userId: string,
  params: any
): Promise<Response> {
  try {
    const mood = params.mood || 'adventurous'
    const location = params.location || 'Rotterdam'
    const filters = params.filters || {}

    console.log(`🔍 get_explore: mood=${mood}, location=${location}`)

    // 1. Get user preferences from profiles table
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('favorite_mood, travel_style, travel_vibes')
      .eq('id', userId)
      .maybeSingle()

    if (profileError) {
      console.warn('⚠️ Could not fetch user profile:', profileError)
    }

    // 2. Check cache first
    const cacheKey = `explore_${mood}_${location}_${JSON.stringify(filters)}`
    const cachedResult = await checkCache(supabase, cacheKey, userId)

    if (cachedResult) {
      console.log('✅ Using cached explore results')
      return new Response(
        JSON.stringify(cachedResult),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 3. Cache miss - fetch from Google Places API
    console.log('🔄 Cache miss - fetching from Google Places API')
    const places = await fetchPlacesFromGoogle(location, mood, filters)

    // 4. Ensure we have at least 60-80 places (with fallback)
    let finalPlaces = places
    if (places.length < 60) {
      console.log(`⚠️ Only found ${places.length} places, fetching more...`)
      const fallbackPlaces = await fetchFallbackPlaces(location)
      finalPlaces = [...places, ...fallbackPlaces].slice(0, 80) // Cap at 80
    }

    // 5. Rank/filter by user preferences (soft filtering)
    const rankedPlaces = rankPlacesByPreferences(finalPlaces, profile, mood, filters)

    // 6. Cache results
    await cachePlaces(supabase, cacheKey, rankedPlaces, userId, location)

    // 7. Return response
    const response: ExploreResponse = {
      cards: rankedPlaces.slice(0, 80), // Return up to 80 places
      cached: false,
      total_found: rankedPlaces.length,
      cache_key: cacheKey,
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
  mood: string,
  filters: any
): Promise<PlaceCard[]> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey) {
    console.error('❌ GOOGLE_PLACES_API_KEY not set in environment')
    throw new Error('GOOGLE_PLACES_API_KEY not set')
  }

  console.log(`🔑 API Key exists: ${apiKey.substring(0, 10)}...`)

  // Get coordinates for location (simplified - in production, use geocoding)
  const locationCoords = getLocationCoords(location)
  console.log(`📍 Location coords: ${locationCoords.lat}, ${locationCoords.lng}`)
  
  // Build query based on mood
  const moodQueries = getMoodQueries(mood)
  console.log(`🎯 Mood queries for "${mood}":`, moodQueries)
  const allPlaces: PlaceCard[] = []

  // Fetch places for each mood query (to get variety)
  for (const query of moodQueries) {
    try {
      const fullQuery = `${query} in ${location}`
      const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?` +
        `query=${encodeURIComponent(fullQuery)}` +
        `&location=${locationCoords.lat},${locationCoords.lng}` +
        `&radius=${filters.radius || 15000}` +
        `&key=${apiKey}`

      console.log(`🌐 Fetching: ${fullQuery}`)
      const response = await fetch(url)
      const data = await response.json()

      console.log(`📊 API Response status: ${data.status}, results: ${data.results?.length || 0}`)
      
      if (data.status === 'OK' && data.results) {
        const places = data.results.map((place: any) => transformPlace(place))
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

async function fetchFallbackPlaces(location: string): Promise<PlaceCard[]> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey) {
    return []
  }

  const locationCoords = getLocationCoords(location)
  
  // Fetch popular/tourist attractions as fallback
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
        `&location=${locationCoords.lat},${locationCoords.lng}` +
        `&radius=20000` +
        `&key=${apiKey}`

      const response = await fetch(url)
      const data = await response.json()

      if (data.status === 'OK' && data.results) {
        const places = data.results.map((place: any) => transformPlace(place))
        allPlaces.push(...places)
      }

      await new Promise(resolve => setTimeout(resolve, 100))
    } catch (error) {
      console.error(`❌ Error fetching fallback places:`, error)
    }
  }

  // Remove duplicates
  const uniquePlaces = Array.from(
    new Map(allPlaces.map(p => [p.id, p])).values()
  )

  return uniquePlaces
}

function transformPlace(place: any): PlaceCard {
  return {
    id: `google_${place.place_id}`,
    name: place.name,
    rating: place.rating || 0,
    types: place.types || [],
    location: {
      lat: place.geometry?.location?.lat || 0,
      lng: place.geometry?.location?.lng || 0,
    },
    photo_reference: place.photos?.[0]?.photo_reference,
    price_level: place.price_level,
    vicinity: place.vicinity,
    address: place.formatted_address,
    description: place.editorial_summary?.overview,
  }
}

function rankPlacesByPreferences(
  places: PlaceCard[],
  profile: any,
  mood: string,
  filters: any
): PlaceCard[] {
  // Simple ranking: prefer higher ratings, match mood types, respect filters
  return places
    .filter(place => {
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
    .sort((a, b) => {
      // Sort by rating (descending)
      if (b.rating !== a.rating) return b.rating - a.rating
      // Then by price level (ascending - cheaper first)
      if (a.price_level && b.price_level) {
        return a.price_level - b.price_level
      }
      return 0
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

function getLocationCoords(location: string): { lat: number; lng: number } {
  // Simple location mapping (in production, use geocoding API)
  const locations: Record<string, { lat: number; lng: number }> = {
    'rotterdam': { lat: 51.9225, lng: 4.4792 },
    'amsterdam': { lat: 52.3676, lng: 4.9041 },
    'the hague': { lat: 52.0705, lng: 4.3007 },
    'utrecht': { lat: 52.0907, lng: 5.1214 },
  }

  const key = location.toLowerCase()
  return locations[key] || locations['rotterdam']
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

