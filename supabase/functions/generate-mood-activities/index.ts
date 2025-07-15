import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface MoodActivityRequest {
  moods: string[]
  userId: string
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
  startTime: string
  priceLevel: string
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { moods, userId }: MoodActivityRequest = await req.json()

    if (!moods || !Array.isArray(moods) || moods.length === 0) {
      throw new Error('Moods array is required')
    }

    if (!userId) {
      throw new Error('User ID is required')
    }

    console.log(`🎯 Generating Rotterdam mood activities for user ${userId} with moods: ${moods.join(', ')}`)

    // FIXED ROTTERDAM COORDINATES - No more location detection issues!
    const ROTTERDAM_LAT = 51.9225
    const ROTTERDAM_LNG = 4.4792
    const ROTTERDAM_CITY = 'Rotterdam'

    console.log(`📍 Using fixed Rotterdam coordinates: ${ROTTERDAM_LAT}, ${ROTTERDAM_LNG}`)

    // Generate Rotterdam-specific activities based on moods
    const activities = await generateRotterdamActivities(moods, ROTTERDAM_LAT, ROTTERDAM_LNG)

    console.log(`✅ Generated ${activities.length} Rotterdam activities`)

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Clear old activities and save new ones
    console.log(`🧹 Clearing old activities for user ${userId}`)
    await supabase
      .from('scheduled_activities')
      .delete()
      .eq('user_id', userId)

    console.log(`💾 Saving ${activities.length} new Rotterdam activities`)
    const { error: insertError } = await supabase
      .from('scheduled_activities')
      .insert(
        activities.map(activity => ({
          user_id: userId,
          activity_name: activity.name,
          description: activity.description,
          time_slot: activity.timeSlot,
          duration_minutes: activity.duration,
          latitude: activity.location.latitude,
          longitude: activity.location.longitude,
          payment_type: activity.paymentType,
          image_url: activity.imageUrl,
          rating: activity.rating,
          tags: activity.tags,
          start_time: activity.startTime,
          price_level: activity.priceLevel,
          is_confirmed: false,
          created_at: new Date().toISOString(),
        }))
      )

    if (insertError) {
      console.error('❌ Error saving activities:', insertError)
      throw insertError
    }

    console.log(`✅ Successfully saved ${activities.length} Rotterdam activities to database`)

    return new Response(
      JSON.stringify({
        success: true,
        activities,
        location: {
          city: ROTTERDAM_CITY,
          latitude: ROTTERDAM_LAT,
          longitude: ROTTERDAM_LNG,
        },
        message: `Generated ${activities.length} mood-based activities for Rotterdam`,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ Error in generate-mood-activities function:', error)
    
    return new Response(
      JSON.stringify({
        error: error.message,
        success: false,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

async function generateRotterdamActivities(
  moods: string[], 
  lat: number, 
  lng: number
): Promise<Activity[]> {
  console.log(`🏗️ Generating Rotterdam activities for moods: ${moods.join(', ')}`)

  // Rotterdam-specific activity database based on moods
  const rotterdamActivities = {
    'Foody': [
      {
        name: 'Markthal Food Court Experience',
        description: 'Explore the iconic Markthal with its amazing food vendors and fresh market stalls. Perfect for food lovers!',
        types: ['restaurant', 'food', 'market'],
        rating: 4.6,
        timeSlots: ['morning', 'afternoon'],
      },
      {
        name: 'Hotel New York Restaurant',
        description: 'Dine at the historic Hotel New York with stunning harbor views and excellent cuisine.',
        types: ['restaurant', 'fine_dining'],
        rating: 4.4,
        timeSlots: ['afternoon', 'evening'],
      },
      {
        name: 'Fenix Food Factory',
        description: 'Local food market with artisanal producers, perfect for discovering Rotterdam\'s food scene.',
        types: ['food', 'market', 'local'],
        rating: 4.3,
        timeSlots: ['morning', 'afternoon'],
      },
    ],
    'Adventurous': [
      {
        name: 'Euromast Tower Experience',
        description: 'Take the elevator to the top of Rotterdam\'s iconic Euromast for breathtaking city views.',
        types: ['tourist_attraction', 'observation_deck'],
        rating: 4.5,
        timeSlots: ['morning', 'afternoon', 'evening'],
      },
      {
        name: 'Erasmus Bridge Walk',
        description: 'Walk across Rotterdam\'s famous "Swan" bridge and enjoy the modern skyline views.',
        types: ['tourist_attraction', 'bridge', 'walking'],
        rating: 4.7,
        timeSlots: ['morning', 'afternoon', 'evening'],
      },
      {
        name: 'SS Rotterdam Ship Tour',
        description: 'Explore the historic SS Rotterdam ocean liner, now a floating hotel and museum.',
        types: ['museum', 'historical', 'ship'],
        rating: 4.2,
        timeSlots: ['morning', 'afternoon'],
      },
    ],
    'Cultural': [
      {
        name: 'Boijmans Van Beuningen Museum',
        description: 'Discover world-class art collections in Rotterdam\'s premier art museum.',
        types: ['museum', 'art_gallery'],
        rating: 4.4,
        timeSlots: ['morning', 'afternoon'],
      },
      {
        name: 'Kunsthal Rotterdam',
        description: 'Experience innovative exhibitions at this dynamic contemporary art space.',
        types: ['art_gallery', 'contemporary_art'],
        rating: 4.3,
        timeSlots: ['morning', 'afternoon'],
      },
      {
        name: 'Historic Delfshaven District',
        description: 'Wander through Rotterdam\'s historic harbor district with charming old buildings.',
        types: ['historical', 'neighborhood', 'walking'],
        rating: 4.2,
        timeSlots: ['morning', 'afternoon'],
      },
    ],
    'Relaxed': [
      {
        name: 'Kralingse Bos Park',
        description: 'Relax in Rotterdam\'s largest park with beautiful lake views and walking paths.',
        types: ['park', 'nature', 'lake'],
        rating: 4.4,
        timeSlots: ['morning', 'afternoon'],
      },
      {
        name: 'Arboretum Trompenburg',
        description: 'Peaceful botanical garden perfect for a relaxing stroll among rare trees and plants.',
        types: ['park', 'botanical_garden'],
        rating: 4.3,
        timeSlots: ['morning', 'afternoon'],
      },
      {
        name: 'Witte de Withstraat Café Hopping',
        description: 'Enjoy a relaxed afternoon exploring the cozy cafés along Rotterdam\'s cultural street.',
        types: ['cafe', 'cultural_street'],
        rating: 4.2,
        timeSlots: ['afternoon', 'evening'],
      },
    ],
    'Active': [
      {
        name: 'Cycling Rotterdam Highlights',
        description: 'Bike tour through Rotterdam\'s modern architecture and major landmarks.',
        types: ['cycling', 'tour', 'active'],
        rating: 4.5,
        timeSlots: ['morning', 'afternoon'],
      },
      {
        name: 'Climbing at Klimcentrum Rotterdam',
        description: 'Indoor rock climbing experience in one of Europe\'s largest climbing centers.',
        types: ['climbing', 'sports', 'indoor'],
        rating: 4.3,
        timeSlots: ['morning', 'afternoon', 'evening'],
      },
      {
        name: 'Watersports at Kralingse Plas',
        description: 'Kayaking, sailing, or paddleboarding on Rotterdam\'s popular lake.',
        types: ['watersports', 'lake', 'outdoor'],
        rating: 4.4,
        timeSlots: ['morning', 'afternoon'],
      },
    ],
    'Social': [
      {
        name: 'Witte de Withstraat Nightlife',
        description: 'Experience Rotterdam\'s vibrant nightlife scene along the famous cultural street.',
        types: ['bar', 'nightlife', 'cultural'],
        rating: 4.3,
        timeSlots: ['evening'],
      },
      {
        name: 'Rooftop Bar Sky Lounge',
        description: 'Enjoy drinks with a view at one of Rotterdam\'s trendy rooftop bars.',
        types: ['bar', 'rooftop', 'views'],
        rating: 4.2,
        timeSlots: ['afternoon', 'evening'],
      },
      {
        name: 'Oude Haven Harbor District',
        description: 'Socialize at the historic harbor with its many bars, restaurants, and terraces.',
        types: ['harbor', 'bars', 'restaurants'],
        rating: 4.4,
        timeSlots: ['afternoon', 'evening'],
      },
    ],
  }

  const selectedActivities: Activity[] = []
  const usedNames = new Set<string>()

  // Select activities based on moods
  for (const mood of moods) {
    const moodActivities = rotterdamActivities[mood as keyof typeof rotterdamActivities] || []
    
    for (const activity of moodActivities) {
      if (usedNames.has(activity.name)) continue
      if (selectedActivities.length >= 8) break // Limit to 8 activities max

      usedNames.add(activity.name)

      // Determine time slot based on current time and activity preferences
      const timeSlot = determineTimeSlot(activity.timeSlots)
      const startTime = generateStartTime(timeSlot)

      const activityObj: Activity = {
        id: `rotterdam_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        name: activity.name,
        description: activity.description,
        timeSlot,
        duration: determineDuration(activity.types),
        location: {
          latitude: lat + (Math.random() - 0.5) * 0.02, // Slight variation around Rotterdam
          longitude: lng + (Math.random() - 0.5) * 0.02,
        },
        paymentType: determinePaymentType(activity.types),
        imageUrl: generateImageUrl(activity.types),
        rating: activity.rating,
        tags: [mood, ...activity.types.slice(0, 2)],
        startTime,
        priceLevel: determinePriceLevel(activity.types),
      }

      selectedActivities.push(activityObj)
    }
  }

  // If we don't have enough activities, add some general Rotterdam highlights
  if (selectedActivities.length < 5) {
    const generalActivities = [
      {
        name: 'Cube Houses Tour',
        description: 'Visit Rotterdam\'s famous tilted cube houses, an architectural marvel.',
        types: ['architecture', 'tourist_attraction'],
        rating: 4.1,
        timeSlots: ['morning', 'afternoon'],
      },
      {
        name: 'Miniworld Rotterdam',
        description: 'Experience the Netherlands in miniature at this detailed model world.',
        types: ['attraction', 'family', 'indoor'],
        rating: 4.2,
        timeSlots: ['morning', 'afternoon'],
      },
    ]

    for (const activity of generalActivities) {
      if (usedNames.has(activity.name)) continue
      if (selectedActivities.length >= 8) break

      const timeSlot = determineTimeSlot(activity.timeSlots)
      const startTime = generateStartTime(timeSlot)

      selectedActivities.push({
        id: `rotterdam_general_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        name: activity.name,
        description: activity.description,
        timeSlot,
        duration: determineDuration(activity.types),
        location: {
          latitude: lat + (Math.random() - 0.5) * 0.02,
          longitude: lng + (Math.random() - 0.5) * 0.02,
        },
        paymentType: determinePaymentType(activity.types),
        imageUrl: generateImageUrl(activity.types),
        rating: activity.rating,
        tags: ['Rotterdam Highlight', ...activity.types.slice(0, 1)],
        startTime,
        priceLevel: determinePriceLevel(activity.types),
      })

      usedNames.add(activity.name)
    }
  }

  console.log(`✅ Generated ${selectedActivities.length} Rotterdam activities`)
  return selectedActivities
}

function determineTimeSlot(availableSlots: string[]): string {
  const currentHour = new Date().getHours()
  
  if (currentHour < 12 && availableSlots.includes('morning')) {
    return 'morning'
  } else if (currentHour < 17 && availableSlots.includes('afternoon')) {
    return 'afternoon'
  } else if (availableSlots.includes('evening')) {
    return 'evening'
  }
  
  // Fallback to first available slot
  return availableSlots[0] || 'afternoon'
}

function generateStartTime(timeSlot: string): string {
  const today = new Date()
  let hour: number
  
  switch (timeSlot) {
    case 'morning':
      hour = 9 + Math.floor(Math.random() * 3) // 9-11 AM
      break
    case 'afternoon':
      hour = 13 + Math.floor(Math.random() * 4) // 1-4 PM
      break
    case 'evening':
      hour = 18 + Math.floor(Math.random() * 3) // 6-8 PM
      break
    default:
      hour = 14 // 2 PM default
  }
  
  const minutes = [0, 15, 30, 45][Math.floor(Math.random() * 4)]
  
  return new Date(today.getFullYear(), today.getMonth(), today.getDate(), hour, minutes).toISOString()
}

function determineDuration(types: string[]): number {
  if (types.includes('restaurant') || types.includes('fine_dining')) return 90
  if (types.includes('museum') || types.includes('art_gallery')) return 120
  if (types.includes('park') || types.includes('walking')) return 60
  if (types.includes('tour') || types.includes('attraction')) return 90
  if (types.includes('bar') || types.includes('cafe')) return 60
  if (types.includes('sports') || types.includes('active')) return 90
  return 75 // Default
}

function determinePaymentType(types: string[]): string {
  if (types.includes('park') || types.includes('walking') || types.includes('bridge')) return 'free'
  if (types.includes('museum') || types.includes('attraction') || types.includes('tour')) return 'ticket'
  return 'reservation' // For restaurants, bars, etc.
}

function determinePriceLevel(types: string[]): string {
  if (types.includes('park') || types.includes('walking')) return '0'
  if (types.includes('fine_dining') || types.includes('rooftop')) return '3'
  if (types.includes('restaurant') || types.includes('bar')) return '2'
  return '1' // Default moderate pricing
}

function generateImageUrl(types: string[]): string {
  const imageMap: { [key: string]: string } = {
    restaurant: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400',
    food: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
    museum: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
    art_gallery: 'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400',
    park: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
    tourist_attraction: 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400',
    bar: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400',
    bridge: 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=400',
    architecture: 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=400',
    harbor: 'https://images.unsplash.com/photo-1544198365-f5d60b6d8190?w=400',
    default: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400', // Rotterdam skyline
  }

  // Find matching image based on activity types
  for (const type of types) {
    if (imageMap[type]) {
      return imageMap[type]
    }
  }

  return imageMap.default
} 