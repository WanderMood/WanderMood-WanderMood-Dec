import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const OPENWEATHER_API_KEY = Deno.env.get('OPENWEATHER_API_KEY')
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')

serve(async (req) => {
  try {
    // Valideer request
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { latitude, longitude, start, end } = await req.json()

    if (!latitude || !longitude || !start || !end) {
      return new Response(
        JSON.stringify({ error: 'All parameters are required' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    // Check eerst in Supabase voor bestaande data
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
    
    const { data: existingData, error: fetchError } = await supabase
      .from('weather_data')
      .select('*')
      .eq('locationId', `${latitude},${longitude}`)
      .gte('timestamp', start)
      .lte('timestamp', end)
      .order('timestamp', { ascending: true })

    if (fetchError) {
      throw new Error('Failed to fetch existing weather data')
    }

    if (existingData && existingData.length > 0) {
      return new Response(JSON.stringify(existingData), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Haal historische data op van OpenWeather API
    const weatherResponse = await fetch(
      `https://api.openweathermap.org/data/2.5/onecall/timemachine?lat=${latitude}&lon=${longitude}&dt=${Math.floor(new Date(start).getTime() / 1000)}&appid=${OPENWEATHER_API_KEY}&units=metric`
    )

    if (!weatherResponse.ok) {
      throw new Error('Failed to fetch historical weather data')
    }

    const weatherData = await weatherResponse.json()

    // Converteer naar ons WeatherData formaat
    const formattedWeatherData = weatherData.hourly.map((hour: any) => ({
      id: crypto.randomUUID(),
      locationId: `${latitude},${longitude}`,
      timestamp: new Date(hour.dt * 1000).toISOString(),
      temperature: hour.temp,
      conditions: hour.weather[0].main,
      humidity: hour.humidity,
      windSpeed: hour.wind_speed,
      precipitation: hour.rain ? hour.rain['1h'] || 0 : 0,
      description: hour.weather[0].description,
      icon: hour.weather[0].icon,
    }))

    // Sla op in Supabase
    const { error: insertError } = await supabase
      .from('weather_data')
      .insert(formattedWeatherData)

    if (insertError) {
      console.error('Error saving historical weather data:', insertError)
    }

    return new Response(JSON.stringify(formattedWeatherData), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
}) 