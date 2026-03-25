import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify the request is from an authenticated user
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user } } = await supabaseClient.auth.getUser()
    if (!user) {
      throw new Error('Unauthorized')
    }

    const request: PlacesRequest = await req.json()
    const { type, query, location, radius = 5000, placeId, photoReference, maxWidth = 400, maxHeight = 400, placeTypes, language = 'en' } = request

    const GOOGLE_PLACES_API_KEY = Deno.env.get('GOOGLE_PLACES_API_KEY')
    if (!GOOGLE_PLACES_API_KEY) {
      throw new Error('Google Places API key not configured')
    }

    let response
    let data

    switch (type) {
      case 'search':
        if (!query) throw new Error('Query required for search')
        
        const searchUrl = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(query)}&key=${GOOGLE_PLACES_API_KEY}&language=${language}`
        response = await fetch(searchUrl)
        data = await response.json()
        break

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
        
        const detailsUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&key=${GOOGLE_PLACES_API_KEY}&language=${language}&fields=place_id,name,formatted_address,geometry,photos,rating,user_ratings_total,price_level,opening_hours,website,formatted_phone_number,reviews,types,vicinity`
        response = await fetch(detailsUrl)
        data = await response.json()
        {
          const photos = Array.isArray(data?.result?.photos) ? data.result.photos : []
          console.log(
            `📸 places.details placeId=${placeId} status=${data?.status ?? 'unknown'} photos_count=${photos.length}`,
          )
          if (photos.length > 0) {
            const firstRef = photos[0]?.photo_reference ?? ''
            console.log(`📸 places.details first_photo_reference_present=${firstRef ? 'yes' : 'no'}`)
          } else {
            console.log(`📸 places.details no photos returned by Google for placeId=${placeId}`)
          }
          if (data?.error_message) {
            console.log(`📸 places.details error_message=${data.error_message}`)
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
          } catch (_) {}
          console.log(`📸 places.photos failed status=${response.status} body=${responsePreview}`)
          throw new Error('Failed to fetch photo')
        }

      case 'nearby':
        if (!location) throw new Error('Location required for nearby search')
        
        let nearbyUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.lat},${location.lng}&radius=${radius}&key=${GOOGLE_PLACES_API_KEY}&language=${language}`
        
        if (placeTypes && placeTypes.length > 0) {
          nearbyUrl += `&type=${placeTypes[0]}` // Nearby search only supports one type
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

    // Cache successful results in database for performance
    if (data.status === 'OK' && (type === 'search' || type === 'nearby' || type === 'details')) {
      try {
        const cacheKey = `places_${type}_${query || placeId || `${location?.lat}_${location?.lng}`}`
        const expiresAt = new Date()
        expiresAt.setHours(expiresAt.getHours() + 24) // Cache for 24 hours

        await supabaseClient
          .from('places_cache')
          .upsert({
            cache_key: cacheKey,
            data: data,
            user_id: user.id,
            request_type: type,
            expires_at: expiresAt.toISOString(),
          })
      } catch (cacheError) {
        console.warn('Failed to cache places data:', cacheError)
        // Don't fail the request if caching fails
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

  } catch (error) {
    console.error('Places function error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
}) 