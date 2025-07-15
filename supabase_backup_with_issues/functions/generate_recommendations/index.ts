import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

// Types
interface RequestBody {
  mood: string;
  weather: {
    temp: number;
    condition: string;
  };
  location: {
    latitude: number;
    longitude: number;
    city?: string;
  };
  preferences?: string[];
}

interface Recommendation {
  id: string;
  name: string;
  description?: string;
  score: number;
  match_reason: string;
  distance?: number;
  city: string;
  country: string;
  image_url?: string;
  price_level?: number;
  rating?: number;
}

// Weather matching logic
const getWeatherCompatibleMoods = (weather: RequestBody['weather']) => {
  const { temp, condition } = weather;
  
  // Define weather ranges
  const isHot = temp >= 28;
  const isWarm = temp >= 20 && temp < 28;
  const isModerate = temp >= 12 && temp < 20;
  const isCool = temp >= 5 && temp < 12;
  const isCold = temp < 5;
  
  // Weather condition categorization
  const isSunny = condition.toLowerCase().includes('sunny') || 
                 condition.toLowerCase().includes('clear');
  const isRainy = condition.toLowerCase().includes('rain') || 
                 condition.toLowerCase().includes('drizzle');
  const isSnowy = condition.toLowerCase().includes('snow');
  const isCloudy = condition.toLowerCase().includes('cloud') || 
                  condition.toLowerCase().includes('overcast');
  const isStormy = condition.toLowerCase().includes('storm') || 
                  condition.toLowerCase().includes('thunder');
  
  // Weather-mood compatibility mapping
  const weatherMoodMap = {
    energetic: (isWarm && isSunny) || (isModerate && isSunny),
    relaxed: (isModerate && (isSunny || isCloudy)) || (isWarm && isCloudy),
    adventurous: !isStormy && !isSnowy,
    happy: isSunny && (isWarm || isModerate),
    creative: isCloudy || isModerate || isRainy,
    romantic: (isSunny && (isWarm || isModerate)) || (isCloudy && !isCold),
    peaceful: isModerate || (isCloudy && !isRainy) || (isSunny && !isHot),
    melancholic: isRainy || isCloudy || isCold
  };
  
  return Object.entries(weatherMoodMap)
    .filter(([_, isCompatible]) => isCompatible)
    .map(([mood]) => mood);
};

// Distance calculation (in km)
const calculateDistance = (
  lat1: number, 
  lon1: number, 
  lat2: number, 
  lon2: number
): number => {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
};

// Score calculation based on matches
const calculateScore = (
  moodMatch: boolean,
  weatherMatch: boolean,
  distance: number, // in km
  rating: number = 3.0 // default if not available
): number => {
  // Base score
  let score = 60;
  
  // Mood match is important
  if (moodMatch) score += 20;
  
  // Weather match is important too
  if (weatherMatch) score += 15;
  
  // Distance factor (closer is better)
  // Maximum 10 points for distance, linear decrease up to 20km
  const distanceScore = Math.max(0, 10 - (distance / 2));
  score += distanceScore;
  
  // Rating factor (better rating is better)
  // Maximum 5 points for rating
  const ratingScore = (rating / 5) * 5;
  score += ratingScore;
  
  // Ensure score is between 0 and 100
  return Math.min(100, Math.max(0, score));
};

// Main edge function handler
Deno.serve(async (req) => {
  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Get request body
    const { mood, weather, location, preferences } = await req.json() as RequestBody;
    
    // Validate required parameters
    if (!mood || !weather || !location) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    // Get compatible mood types based on weather
    const weatherCompatibleMoods = getWeatherCompatibleMoods(weather);
    
    // Query database for places
    const { data: places, error } = await supabase
      .from('places')
      .select('*')
      .order('rating', { ascending: false });
    
    if (error) {
      console.error('Database query error:', error);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch places' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    if (!places || places.length === 0) {
      return new Response(
        JSON.stringify({ 
          message: 'No places found in database',
          recommendations: [] 
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Process places to calculate recommendations
    const recommendations: Recommendation[] = places.map(place => {
      // Extract location coordinates from geography point
      // This assumes the location is stored as a PostGIS point with lng,lat format
      const placeLocation = place.location?.coordinates || [0, 0];
      const placeLon = placeLocation[0];
      const placeLat = placeLocation[1];
      
      // Calculate distance
      const distance = calculateDistance(
        location.latitude, 
        location.longitude, 
        placeLat,
        placeLon
      );
      
      // Check mood match
      const moodMatch = place.mood_tags?.includes(mood) || false;
      
      // Check weather match
      const weatherMatch = weatherCompatibleMoods.some(
        compatibleMood => place.mood_tags?.includes(compatibleMood)
      );
      
      // Check preference match if preferences are provided
      const preferenceMatch = !preferences || preferences.length === 0 || 
        preferences.some(pref => 
          place.activities?.includes(pref) || 
          place.mood_tags?.includes(pref)
        );
      
      // Calculate score
      const score = calculateScore(
        moodMatch, 
        weatherMatch, 
        distance,
        place.rating
      );
      
      // Determine match reason
      let matchReason = 'Based on your preferences';
      if (moodMatch) matchReason = `Perfect for ${mood} mood`;
      else if (weatherMatch) matchReason = `Great for current weather`;
      else if (distance < 2) matchReason = 'Close to your location';
      else if (place.rating && place.rating >= 4.5) matchReason = 'Highly rated';
      
      return {
        id: place.id,
        name: place.name,
        description: place.description,
        score,
        match_reason: matchReason,
        distance,
        city: place.city,
        country: place.country,
        image_url: place.photos?.[0],
        price_level: place.price_level,
        rating: place.rating
      };
    })
    .filter(rec => rec.score >= 60) // Only include recommendations with scores above threshold
    .sort((a, b) => b.score - a.score) // Sort by score (descending)
    .slice(0, 10); // Limit to top 10
    
    // Return recommendations
    return new Response(
      JSON.stringify({ 
        recommendations,
        weather_compatible_moods: weatherCompatibleMoods,
        current_mood: mood
      }),
      { 
        headers: { 
          'Content-Type': 'application/json',
          'Cache-Control': 'max-age=60' // Cache for 1 minute
        } 
      }
    );
  } catch (error) {
    console.error('Edge function error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}); 