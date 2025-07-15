import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WeatherRequest {
  latitude: number
  longitude: number
  type: 'current' | 'forecast' | 'onecall'
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
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Verify user is authenticated
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    // Get the OpenWeather API key from environment
    const apiKey = Deno.env.get('OPENWEATHER_API_KEY')
    if (!apiKey) {
      throw new Error('OpenWeather API key not configured')
    }

    // Parse request body
    const { latitude, longitude, type }: WeatherRequest = await req.json()

    if (!latitude || !longitude) {
      throw new Error('Missing latitude or longitude')
    }

    // Validate coordinates
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      throw new Error('Invalid coordinates')
    }

    let weatherUrl: string
    const baseUrl = 'https://api.openweathermap.org/data/2.5'

    switch (type) {
      case 'current':
        weatherUrl = `${baseUrl}/weather?lat=${latitude}&lon=${longitude}&appid=${apiKey}&units=metric`
        break
      case 'forecast':
        weatherUrl = `${baseUrl}/forecast?lat=${latitude}&lon=${longitude}&appid=${apiKey}&units=metric`
        break
      case 'onecall':
        weatherUrl = `https://api.openweathermap.org/data/3.0/onecall?lat=${latitude}&lon=${longitude}&appid=${apiKey}&units=metric&exclude=minutely`
        break
      default:
        throw new Error('Invalid weather type')
    }

    console.log(`Fetching weather data for ${latitude}, ${longitude} (type: ${type})`)

    // Fetch weather data from OpenWeatherMap
    const weatherResponse = await fetch(weatherUrl)
    
    if (!weatherResponse.ok) {
      const errorText = await weatherResponse.text()
      console.error('OpenWeather API error:', errorText)
      throw new Error(`Weather API error: ${weatherResponse.status}`)
    }

    const weatherData = await weatherResponse.json()

    // Cache the weather data in Supabase for performance
    const cacheKey = `weather_${type}_${latitude}_${longitude}`
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000) // 10 minutes cache

    try {
      await supabaseClient
        .from('weather_cache')
        .upsert({
          cache_key: cacheKey,
          data: weatherData,
          expires_at: expiresAt.toISOString(),
          user_id: user.id,
          location_lat: latitude,
          location_lng: longitude,
          weather_type: type,
        })
    } catch (cacheError) {
      console.warn('Failed to cache weather data:', cacheError)
      // Don't fail the request if caching fails
    }

    // Return the weather data
    return new Response(
      JSON.stringify({
        success: true,
        data: weatherData,
        cached_until: expiresAt.toISOString(),
      }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    )

  } catch (error) {
    console.error('Weather function error:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    )
  }
}) 