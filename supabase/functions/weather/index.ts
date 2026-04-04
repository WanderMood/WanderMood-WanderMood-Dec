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

interface WeatherRequest {
  latitude: number
  longitude: number
  type: 'current' | 'forecast' | 'onecall'
}

async function processWeatherBody(
  supabaseClient: ReturnType<typeof createClient>,
  user: { id: string },
  body: WeatherRequest,
): Promise<Response> {
  const { latitude, longitude, type } = body

  const apiKey = Deno.env.get('OPENWEATHER_API_KEY')
  if (!apiKey) {
    throw new Error('OpenWeather API key not configured')
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

  const weatherResponse = await fetch(weatherUrl)

  if (!weatherResponse.ok) {
    const errorText = await weatherResponse.text()
    console.error('OpenWeather API error:', errorText)
    throw new Error(`Weather API error: ${weatherResponse.status}`)
  }

  const weatherData = await weatherResponse.json()

  const cacheKey = `weather_${type}_${latitude}_${longitude}`
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000)

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
  }

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
      {
        global: {
          headers: { Authorization: authHeader },
        },
      },
    )

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    const body: WeatherRequest = await req.json()

    if (!Number.isFinite(body.latitude) || !Number.isFinite(body.longitude)) {
      throw new Error('Missing latitude or longitude')
    }

    if (body.latitude < -90 || body.latitude > 90 || body.longitude < -180 || body.longitude > 180) {
      throw new Error('Invalid coordinates')
    }

    const admin = getServiceSupabase()
    const rateKey = userRateKey(user.id)
    const rateStarted = performance.now()
    const maxWeatherPerMin = Number(Deno.env.get('EDGE_RATE_WEATHER_PER_MINUTE') ?? '60')
    if (admin) {
      const { allowed, currentCount } = await edgeRateLimitConsume(admin, rateKey, 'weather', maxWeatherPerMin)
      if (!allowed) {
        logApiInvocationFireAndForget(admin, {
          user_id: user.id,
          user_key: rateKey,
          function_slug: 'weather',
          operation: body.type,
          http_status: 429,
          duration_ms: Math.round(performance.now() - rateStarted),
          error_snippet: `rate_limit count=${currentCount} max=${maxWeatherPerMin}/min`,
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
      { user_id: user.id, user_key: rateKey, function_slug: 'weather', operation: body.type },
      traceStarted,
      processWeatherBody(supabaseClient, user, body),
      corsHeaders,
    )
  } catch (error) {
    console.error('Weather function error:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    )
  }
})
