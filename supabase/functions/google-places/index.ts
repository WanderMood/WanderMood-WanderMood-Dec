import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import { corsHeaders } from '../_shared/cors.ts'

const GOOGLE_PLACES_API_KEY = Deno.env.get('GOOGLE_PLACES_API_KEY') || 'AIzaSyAzmi2Z4Y0Z4ZMLTtiZcbZseOHwAlMux60'

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client for cache access
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseAnonKey)
    
    // Check if we're in dev mode
    const isDevMode = Deno.env.get('DEV_MODE') === 'true' || Deno.env.get('NODE_ENV') === 'development'
    
    const { 
      query, 
      latitude, 
      longitude, 
      radius = 5000, 
      type = 'tourist_attraction' 
    } = await req.json()

    console.log(`🔍 Places API request: ${query} near (${latitude}, ${longitude})`)
    console.log(`🔧 Dev mode: ${isDevMode ? 'ON (cache only)' : 'OFF (live API)'}`)

    // Check cache first (dev mode or always for performance)
    const cacheKey = `google_places_${query}_${latitude}_${longitude}_${radius}_${type}`
    const { data: cacheData, error: cacheError } = await supabase
      .from('places_cache')
      .select('data, expires_at')
      .eq('cache_key', cacheKey)
      .maybeSingle()

    if (!cacheError && cacheData) {
      const expiresAt = new Date(cacheData.expires_at)
      if (expiresAt > new Date()) {
        console.log('✅ Using cached response')
        return new Response(
          JSON.stringify(cacheData.data),
          {
            headers: { 
              ...corsHeaders, 
              'Content-Type': 'application/json' 
            }
          }
        )
      }
    }

    // DEV MODE: If cache miss and in dev mode, return empty (don't make API call)
    if (isDevMode) {
      console.log('🚫 DEV MODE: Cache miss - returning empty results to avoid API costs')
      return new Response(
        JSON.stringify({ 
          status: 'ZERO_RESULTS',
          results: [],
          message: 'DEV_MODE: No cached data available. Please populate cache in production mode first.'
        }),
        {
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          }
        }
      )
    }

    // PRODUCTION MODE: Make live API call
    console.log('🌐 Making live Google Places API call')

    // Construct the Google Places API URL
    const baseUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
    const params = new URLSearchParams({
      query: query,
      location: `${latitude},${longitude}`,
      radius: radius.toString(),
      type: type,
      key: GOOGLE_PLACES_API_KEY
    })

    const url = `${baseUrl}?${params}`
    
    // Make the API call to Google Places
    const response = await fetch(url)
    const data = await response.json()

    console.log(`✅ Places API response: ${data.status}, found ${data.results?.length || 0} places`)

    // Transform the results to match our app's format
    const transformedResults = data.results?.map((place: any) => ({
      id: place.place_id,
      name: place.name,
      address: place.formatted_address,
      rating: place.rating || 0,
      photos: place.photos?.map((photo: any) => 
        `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${photo.photo_reference}&key=${GOOGLE_PLACES_API_KEY}`
      ) || [],
      types: place.types || [],
      location: {
        lat: place.geometry?.location?.lat || 0,
        lng: place.geometry?.location?.lng || 0
      },
      description: place.editorial_summary?.overview || `Discover ${place.name}`,
      emoji: getEmojiForType(place.types?.[0] || ''),
      tag: getTagForType(place.types?.[0] || ''),
      priceLevel: place.price_level || 2,
      openingHours: place.opening_hours?.weekday_text || [],
      isOpen: place.opening_hours?.open_now || null
    })) || []

    const responseData = {
      status: data.status,
      results: transformedResults,
      nextPageToken: data.next_page_token
    }

    // Cache the response in Supabase (30 days expiration)
    const expiresAt = new Date()
    expiresAt.setDate(expiresAt.getDate() + 30)
    
    try {
      await supabase
        .from('places_cache')
        .upsert({
          cache_key: cacheKey,
          data: responseData,
          user_id: null, // Anonymous cache entry
          request_type: 'search',
          query: query,
          location_lat: latitude,
          location_lng: longitude,
          expires_at: expiresAt.toISOString(),
        }, { onConflict: 'cache_key' })
      
      console.log('💾 Cached API response in Supabase')
    } catch (cacheErr) {
      console.error('⚠️ Failed to cache response:', cacheErr)
      // Don't fail the request if caching fails
    }

    return new Response(
      JSON.stringify(responseData),
      {
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        }
      }
    )

  } catch (error) {
    console.error('❌ Places API error:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      { 
        status: 500,
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        }
      }
    )
  }
})

function getEmojiForType(type: string): string {
  const typeMap: Record<string, string> = {
    'restaurant': '🍽️',
    'tourist_attraction': '🎯',
    'museum': '🏛️',
    'park': '🌳',
    'shopping_mall': '🛍️',
    'night_club': '🌙',
    'bar': '🍻',
    'cafe': '☕',
    'gym': '💪',
    'spa': '🧘',
    'amusement_park': '🎢',
    'zoo': '🦁',
    'aquarium': '🐠',
    'art_gallery': '🎨',
    'church': '⛪',
    'mosque': '🕌',
    'synagogue': '✡️',
    'hindu_temple': '🛕',
    'library': '📚',
    'movie_theater': '🎬',
    'bowling_alley': '🎳',
    'casino': '🎰',
    'lodging': '🏨',
    'food': '🍽️',
    'meal_takeaway': '🥡',
    'bakery': '🥖',
    'meal_delivery': '🚚'
  }
  
  return typeMap[type] || '📍'
}

function getTagForType(type: string): string {
  const tagMap: Record<string, string> = {
    'restaurant': 'Food & Dining',
    'tourist_attraction': 'Attractions',
    'museum': 'Culture',
    'park': 'Nature',
    'shopping_mall': 'Shopping',
    'night_club': 'Nightlife',
    'bar': 'Nightlife',
    'cafe': 'Cafes',
    'gym': 'Fitness',
    'spa': 'Wellness',
    'amusement_park': 'Entertainment',
    'zoo': 'Family',
    'aquarium': 'Family',
    'art_gallery': 'Culture',
    'church': 'Religious',
    'mosque': 'Religious',
    'synagogue': 'Religious',
    'hindu_temple': 'Religious',
    'library': 'Education',
    'movie_theater': 'Entertainment',
    'bowling_alley': 'Entertainment',
    'casino': 'Entertainment',
    'lodging': 'Hotels',
    'food': 'Food & Dining',
    'meal_takeaway': 'Food & Dining',
    'bakery': 'Food & Dining',
    'meal_delivery': 'Food & Dining'
  }
  
  return tagMap[type] || 'Places'
} 