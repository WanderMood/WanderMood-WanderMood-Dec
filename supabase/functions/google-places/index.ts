import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { corsHeaders } from '../_shared/cors.ts'

const GOOGLE_PLACES_API_KEY = 'AIzaSyAzmi2Z4Y0Z4ZMLTtiZcbZseOHwAlMux60'

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    const { 
      query, 
      latitude, 
      longitude, 
      radius = 5000, 
      type = 'tourist_attraction' 
    } = await req.json()

    console.log(`🔍 Places API request: ${query} near (${latitude}, ${longitude})`)

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

    return new Response(
      JSON.stringify({
        status: data.status,
        results: transformedResults,
        nextPageToken: data.next_page_token
      }),
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