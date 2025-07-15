import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Inline CORS headers to avoid import issues
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

interface WanderMoodRequest {
  action: 'recommend' | 'chat' | 'plan' | 'optimize'
  message?: string
  location?: {
    latitude: number
    longitude: number
    city?: string
  }
  moods?: string[]
  preferences?: {
    budget?: number
    timeSlot?: string
    duration?: number
    groupSize?: number
  }
  conversationId?: string
  conversationContext?: string[]
  userContext?: any
}

interface OpenAIMessage {
  role: 'system' | 'user' | 'assistant'
  content: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse request body
    const body: WanderMoodRequest = await req.json()
    console.log('🎯 WanderMood AI Request:', { 
      action: body.action, 
      userId: user.id,
      location: body.location?.city,
      moods: body.moods 
    })

    // Get user context and preferences
    const userContext = await getUserContext(supabaseClient, user.id)
    console.log('👤 User context loaded:', { 
      placeHistory: userContext.visitedPlaces?.length || 0,
      preferences: userContext.preferences 
    })

    // Get relevant places based on location and moods
    const relevantPlaces = await getRelevantPlaces(
      supabaseClient, 
      body.location, 
      body.moods || []
    )
    console.log('🏢 Found relevant places:', relevantPlaces.length)

    // Build AI prompt based on action
    const aiPrompt = await buildAIPrompt(body, userContext, relevantPlaces)
    
    // Get conversation history if continuing a chat
    const conversationHistory = body.conversationId 
      ? await getConversationHistory(supabaseClient, body.conversationId)
      : []

    // Call OpenAI with enriched context
    const aiResponse = await callOpenAI(aiPrompt, conversationHistory, body.action, body.message)

    // Save conversation if it's a chat
    if (body.action === 'chat' && body.conversationId) {
      await saveConversation(supabaseClient, body.conversationId, user.id, body.message!, aiResponse)
    }

    // Process and format response
    const formattedResponse = await formatResponse(body.action, aiResponse, relevantPlaces)

    console.log('✅ WanderMood AI Response generated successfully')

    return new Response(
      JSON.stringify(formattedResponse),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('❌ WanderMood AI Error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'AI service temporarily unavailable',
        details: error.message 
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

// Get user context including preferences and history
async function getUserContext(supabase: any, userId: string) {
  const [preferencesResult, historyResult] = await Promise.all([
    supabase
      .from('user_preferences')
      .select('*')
      .eq('user_id', userId)
      .single(),
    
    supabase
      .from('user_activity_history')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(20)
  ])

  return {
    preferences: preferencesResult.data || {},
    visitedPlaces: historyResult.data || [],
    userId
  }
}

// Generate places query using Google Places API
export const generate_places_query = async (input: any) => {
  const { mood, location, preferences, query, language } = input;

  // Popular Rotterdam food places by time slot - what Moody should search for
  const rotterdamFoodPlaces = {
    morning: [
      "Baker & Moore Rotterdam", "Urban Espresso Bar Rotterdam", "Little V Rotterdam", 
      "Yay Koffie Rotterdam", "Posse Espressobar Rotterdam", "Spirit Rotterdam",
      "Picknick Rotterdam", "Jack Bean Coffee Kitchen Rotterdam", "Bagels & Beans Rotterdam"
    ],
    afternoon: [
      "Markthal Food Stalls Rotterdam", "De Foodhallen Rotterdam", "FOAM Rotterdam",
      "Bla Bla Rotterdam", "Kaapse Maria Rotterdam", "Bokaal Rotterdam",
      "Kokomo Rotterdam", "Mood Rotterdam", "Teds Rotterdam", "Café De Unie Rotterdam"
    ],
    evening: [
      "Grace Restaurant Rotterdam", "1nul8 Rotterdam", "Noya Restaurant Rotterdam",
      "The Oyster Club Rotterdam", "The Millèn Rotterdam", "FG Food Labs Rotterdam",
      "Parkheuvel Rotterdam", "Bokaal Rotterdam", "Kaap 8 Rotterdam", "De Matroos en Het Meisje Rotterdam"
    ]
  };

  const placeTypeMap: Record<string, string[]> = {
    Relaxed: ["spa", "cafe", "park"],
    Romantic: ["restaurant", "bar", "scenic_view"],
    Excited: ["amusement_park", "concert_hall", "arcade"],
    Creative: ["museum", "art_gallery", "workshop"],
    Adventure: ["park", "tourist_attraction", "amusement_park"],
    Foody: ["restaurant", "cafe", "bakery", "food"],
    Energetic: ["gym", "sports_club", "dance_studio", "arcade"],
    Mindful: ["spa", "park", "place_of_worship", "library"],
    Family: ["zoo", "park", "museum", "amusement_park"]
  };

  // Determine what to search for based on mood and preferences
  let searchQueries: string[] = [];
  
  // For food-related moods, search for specific popular Rotterdam places
  if (mood === 'Foody' || mood === 'Relaxed' || mood === 'Romantic') {
    const timeSlot = preferences?.timeSlot || 'afternoon';
    const timeKey = timeSlot.toLowerCase() as keyof typeof rotterdamFoodPlaces;
    
    if (rotterdamFoodPlaces[timeKey]) {
      searchQueries = rotterdamFoodPlaces[timeKey];
    } else {
      // Fallback to all food places
      searchQueries = [...rotterdamFoodPlaces.morning, ...rotterdamFoodPlaces.afternoon, ...rotterdamFoodPlaces.evening];
    }
  } else {
    // For other moods, use generic types
    const types = placeTypeMap[mood] || [];
    searchQueries = types.length > 0 ? types : ['popular restaurants Rotterdam', 'trending cafes Rotterdam'];
  }

  // If a specific query is provided, use that instead
  if (query) {
    searchQueries = [query];
  }

  const baseUrl = "https://places.googleapis.com/v1/places:searchText";
  const headers = {
    "Content-Type": "application/json",
    "X-Goog-Api-Key": Deno.env.get('GOOGLE_PLACES_API_KEY'),
    "X-Goog-FieldMask": "places.displayName,places.rating,places.userRatingCount,places.photos,places.formattedAddress,places.websiteUri,places.id,places.priceLevel,places.types"
  };

  // Search for each query and combine results
  const allPlaces: any[] = [];
  
  for (const searchQuery of searchQueries.slice(0, 5)) { // Limit to 5 searches to avoid API quota
    const body = {
      textQuery: searchQuery,
      locationBias: {
        circle: {
          center: {
            latitude: location?.lat || location?.latitude || 51.9225, // Rotterdam default
            longitude: location?.lng || location?.longitude || 4.4792
          },
          radius: 10000 // 10km radius
        }
      },
      languageCode: language || "en",
      maxResultCount: 5 // Limit per search
    };

    try {
      const response = await fetch(baseUrl, {
        method: "POST",
        headers,
        body: JSON.stringify(body)
      });

      if (response.ok) {
        const data = await response.json();
        const places = data?.places?.filter((place: any) => {
          return (
            place.rating >= 3.5 &&
            place.userRatingCount >= 20
          );
        }) || [];
        
        allPlaces.push(...places);
        console.log(`🔍 Found ${places.length} places for "${searchQuery}"`);
      }
    } catch (error) {
      console.error(`❌ Error searching for "${searchQuery}":`, error);
    }
  }

  // Remove duplicates and return top results
  const uniquePlaces = allPlaces.filter((place, index, self) => 
    index === self.findIndex(p => p.displayName?.text === place.displayName?.text)
  );

  console.log(`✅ Total unique places found: ${uniquePlaces.length}`);
  return uniquePlaces;
};

// Get relevant places from cache and Google Places API
async function getRelevantPlaces(supabase: any, location: any, moods: string[]) {
  if (!location) return []

  // First, try to get places from cache
  const { data: cachedPlaces } = await supabase
    .from('cached_places')
    .select('*')
    .gte('rating', 3.5)
    .order('rating', { ascending: false })
    .limit(30)

  console.log(`🏢 Found ${cachedPlaces?.length || 0} cached venues`)

  // If we have a Google Places API key and moods, also fetch from Google
  const googleApiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (googleApiKey && moods.length > 0) {
    try {
      console.log(`🔍 Fetching fresh places for moods: ${moods.join(', ')}`)
      
      // Generate places for each mood and combine
      const googlePlacesPromises = moods.map(mood => 
        generate_places_query({
          mood,
          location,
          language: 'en'
        })
      )
      
      const googlePlacesResults = await Promise.all(googlePlacesPromises)
      const googlePlaces = googlePlacesResults.flat()
      
      console.log(`🌐 Found ${googlePlaces.length} places from Google Places API`)
      
      // Combine and deduplicate places
      const allPlaces = [...(cachedPlaces || []), ...googlePlaces]
      const uniquePlaces = allPlaces.filter((place, index, self) => 
        index === self.findIndex(p => p.name === place.name || p.displayName?.text === place.displayName?.text)
      )
      
      return uniquePlaces.slice(0, 50) // Limit total results
    } catch (error) {
      console.error('❌ Error fetching from Google Places:', error)
      // Fall back to cached places only
    }
  }
  
  return cachedPlaces || []
}

// Build AI prompt based on request type and context
async function buildAIPrompt(
  request: WanderMoodRequest,
  userContext: any,
  places: any[]
): Promise<string> {
  const baseContext = `
🧳 You are Moody, the WanderMood app's AI travel buddy! You help users discover amazing, mood-based experiences.

📍 Current Context:
- Location: ${request.location?.city || 'Unknown'}
- User Vibes: ${request.moods?.join(', ') || 'Not specified yet'}
- Local Spots Available: ${places.length} curated venues

👤 User Profile:
- Communication Style: ${userContext.preferences?.communication_style || 'friendly'}
- Favorite Moods: ${userContext.preferences?.favorite_moods?.join(', ') || userContext.preferences?.selected_moods?.join(', ') || 'Not set'}
- Travel Interests: ${userContext.preferences?.travel_interests?.join(', ') || 'Not set'}
- Home Base: ${userContext.preferences?.home_base || 'Not set'}
- Social Vibe: ${userContext.preferences?.social_vibe?.join(', ') || 'Not set'}
- Planning Style: ${userContext.preferences?.planning_pace || 'Not set'}
- Travel Style: ${userContext.preferences?.travel_styles?.join(', ') || 'Not set'}
- Budget Level: ${userContext.preferences?.budget_level || 'Not set'}
- Preferred Times: ${userContext.preferences?.preferred_time_slots?.join(', ') || 'Any time'}
- Language: ${userContext.preferences?.language_preference || 'en'}

🕰️ Recent Adventures:
${userContext.visitedPlaces?.slice(0, 5).map((p: any) => `- ${p.name} (${p.mood} mood)`).join('\n') || 'First time using WanderMood! 🎉'}

🏢 Your Local Knowledge (Top Spots):
${places.slice(0, 10).map(place => 
  `- ${place.name}: ${place.rating}⭐ (${place.types?.join(', ')}) - ${place.description}`
).join('\n')}
`

  switch (request.action) {
    case 'recommend':
      return `${baseContext}

TASK: Generate 3-5 personalized activity recommendations for the user's current mood(s).

Requirements:
- Focus on real venues from the Available Venues Context above
- Match the user's current mood: ${request.moods?.join(', ')}
- Consider time of day: ${request.preferences?.timeSlot || 'any time'}
- Budget consideration: ${request.preferences?.budget || 'flexible'}
- Group size: ${request.preferences?.groupSize || 1} people
- Avoid places they've recently visited
- Include practical details (duration, cost, why it matches their mood)

Format your response as a structured JSON with:
{
  "recommendations": [
    {
      "name": "venue name",
      "type": "restaurant/attraction/cafe/etc",
      "rating": 4.5,
      "description": "why this matches their mood",
      "duration": "estimated time needed",
      "cost": "€€",
      "moodMatch": "explanation of mood alignment",
      "timeSlot": "morning/afternoon/evening"
    }
  ],
  "summary": "brief explanation of recommendations"
}`

    case 'chat':
      return `You are Moody, a Gen-Z travel bestie in the WanderMood app. You're warm, playful, slightly cheeky, and emotionally intelligent.

PERSONALITY: 
- Talk like a real friend texting, not a bot
- Use casual language & fun emojis 😎✨ (not too many)
- Keep responses SHORT (1-2 sentences max)
- Only greet once per conversation
- Be curious, supportive, slightly cheeky

VOICE EXAMPLES:
- "Yess friend 😌 I'm here"
- "Say lessss 👀"
- "Ugh rain 🙄... but I gotchu!"
- "You're in a romantic mood? Say no more 💘"
- "Spicy ramen? Sushi tower? Let's find your next bite 🍜"

CONTEXT:
Location: ${request.location?.city || 'unknown area'}
Available local venues: ${places.slice(0, 5).map(p => p.name).join(', ')}
User message: "${request.message}"

VENUE KNOWLEDGE RULES:
- If user mentions a specific venue name (restaurant, bar, etc), first check if it's in your venue list above
- If it's NOT in your list, say "Hmm, I don't have that one in my database yet 🤔 Tell me more!"
- If it IS in your list, share what you know about it
- Don't pretend to know venues that aren't in your available venues list
- When unsure about a venue, ask for clarification rather than guessing

CONVERSATION FLOW GUIDANCE:
- After 2-3 exchanges where you understand their vibe/preferences
- Proactively suggest the plan generator: "Want me to put together a full plan? Hit that green button below! 🎯"
- If they mention specific activities (dinner, parties, shopping, etc.), suggest planning
- Key phrases to trigger planning suggestion: "Want a full plan?", "Ready to make this happen?", "Let's plan this out!"

RULES:
- Respond naturally to THIS specific message
- Don't repeat previous suggestions unless asked
- Match their energy level
- If they mention activities, react authentically
- Suggest real venues from the list when relevant
- GUIDE toward planning when you have enough context
- Remember: you're their travel BESTIE, not an assistant

This is an ongoing conversation - respond like a real friend would!`

    case 'plan':
      return `${baseContext}

TASK: Create a complete day plan based on user's moods and preferences.

Requirements:
- Create a full day itinerary using real venues
- Balance different types of activities
- Consider travel time between locations
- Match activities to optimal time slots
- Include variety while staying true to mood
- Provide backup options

Format as structured day plan with timing, activities, and transitions.`

    case 'optimize':
      return `${baseContext}

TASK: Optimize an existing itinerary for better flow, timing, and user satisfaction.

Consider:
- Geographic efficiency (minimize travel time)
- Optimal timing for each activity type
- User energy levels throughout the day
- Weather considerations
- Alternative options if plans change

Provide optimized schedule with explanations for changes.`

    default:
      return `${baseContext}

TASK: General assistance with travel and activity planning.

User Request: "${request.message}"

Provide helpful, contextual advice based on available information.`
  }
}

// Get conversation history for context
async function getConversationHistory(supabase: any, conversationId: string) {
  const { data: messages } = await supabase
    .from('ai_conversations')
    .select('role, content, created_at')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: true })
    .limit(10)

  return messages || []
}

// Call OpenAI API with context
async function callOpenAI(
  prompt: string,
  conversationHistory: any[],
  action: string,
  currentUserMessage?: string
): Promise<string> {
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey) {
    throw new Error('OpenAI API key not configured')
  }

  const messages: OpenAIMessage[] = [
    {
      role: 'system',
      content: prompt
    }
  ]

  // Add conversation history for chat
  if (conversationHistory.length > 0) {
    conversationHistory.forEach(msg => {
      messages.push({
        role: msg.role as 'user' | 'assistant',
        content: msg.content
      })
    })
  }

  // Add current user message for chat continuity
  if (action === 'chat' && currentUserMessage) {
    messages.push({
      role: 'user',
      content: currentUserMessage
    })
  }

  console.log('🤖 Sending to OpenAI:', { 
    messageCount: messages.length,
    lastMessage: messages[messages.length - 1]?.content?.substring(0, 100) + '...'
  })

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini', // Cost-effective and fast
      messages,
      max_tokens: action === 'recommend' ? 1000 : (action === 'chat' ? 200 : 500),
      temperature: 0.7,
      response_format: action === 'recommend' ? { type: 'json_object' } : undefined
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`OpenAI API error: ${error}`)
  }

  const data = await response.json()
  return data.choices[0]?.message?.content || 'No response generated'
}

// Save conversation for chat continuity
async function saveConversation(
  supabase: any,
  conversationId: string,
  userId: string,
  userMessage: string,
  aiResponse: string
) {
  await Promise.all([
    // Save user message
    supabase.from('ai_conversations').insert({
      conversation_id: conversationId,
      user_id: userId,
      role: 'user',
      content: userMessage,
      created_at: new Date().toISOString()
    }),
    
    // Save AI response
    supabase.from('ai_conversations').insert({
      conversation_id: conversationId,
      user_id: userId,
      role: 'assistant',
      content: aiResponse,
      created_at: new Date().toISOString()
    })
  ])
}

// Format response based on action type
async function formatResponse(action: string, aiResponse: string, places: any[]) {
  const baseResponse = {
    success: true,
    action,
    timestamp: new Date().toISOString()
  }

  switch (action) {
    case 'recommend':
      try {
        const parsedResponse = JSON.parse(aiResponse)
        const enrichedRecommendations = await enrichRecommendationsWithPlaceData(
          parsedResponse.recommendations || [], 
          places
        )
        
        return {
          ...baseResponse,
          recommendations: enrichedRecommendations,
          summary: parsedResponse.summary || '',
          availablePlaces: places.length
        }
      } catch (e) {
        console.error('❌ Error parsing AI response:', e)
        return {
          ...baseResponse,
          message: aiResponse,
          availablePlaces: places.length
        }
      }

    case 'chat':
      return {
        ...baseResponse,
        message: aiResponse,
        contextUsed: {
          placesAvailable: places.length,
          hasLocationContext: places.length > 0
        }
      }

    default:
      return {
        ...baseResponse,
        message: aiResponse
      }
  }
}

// Enrich AI recommendations with actual Google Places data
async function enrichRecommendationsWithPlaceData(recommendations: any[], places: any[]) {
  return Promise.all(recommendations.map(async rec => {
    // Find matching place in Google Places data
    const matchingPlace = places.find(place => {
      const placeName = place.displayName?.text || place.name || ''
      const recName = rec.name || ''
      
      // Try exact match first
      if (placeName.toLowerCase() === recName.toLowerCase()) {
        return true
      }
      
      // Try partial match
      if (placeName.toLowerCase().includes(recName.toLowerCase()) || 
          recName.toLowerCase().includes(placeName.toLowerCase())) {
        return true
      }
      
      return false
    })

    if (matchingPlace) {
      console.log(`✅ Enriching ${rec.name} with Google Places data`)
      
      // Extract photo URL from Google Places photos - need to fetch the actual photo URI
      let imageUrl = null
      if (matchingPlace.photos && matchingPlace.photos.length > 0) {
        const photo = matchingPlace.photos[0]
        
        // Fetch the actual photo URI using Google Places Photos API
        try {
          const photoResponse = await fetch(`https://places.googleapis.com/v1/${photo.name}/media?maxHeightPx=600&maxWidthPx=800&key=${Deno.env.get('GOOGLE_PLACES_API_KEY')}`, {
            method: 'GET',
            headers: {
              'X-Goog-Api-Key': Deno.env.get('GOOGLE_PLACES_API_KEY')!
            }
          })
          
          if (photoResponse.ok) {
            const photoData = await photoResponse.json()
            imageUrl = photoData.photoUri
            console.log(`📸 Successfully fetched photo URI: ${imageUrl}`)
          } else {
            console.log(`⚠️ Failed to fetch photo for ${matchingPlace.displayName?.text}: ${photoResponse.status}`)
          }
        } catch (error) {
          console.log(`❌ Error fetching photo: ${error}`)
        }
      } else {
        console.log(`⚠️ No photos available for ${matchingPlace.displayName?.text}`)
      }
      
      // Extract coordinates from formatted address or use default
      const coordinates = extractCoordinatesFromPlace(matchingPlace)
      
      return {
        ...rec,
        name: matchingPlace.displayName?.text || matchingPlace.name || rec.name,
        rating: matchingPlace.rating || rec.rating,
        imageUrl: imageUrl,
        location: coordinates,
        address: matchingPlace.formattedAddress,
        websiteUri: matchingPlace.websiteUri,
        userRatingCount: matchingPlace.userRatingCount,
        placeId: matchingPlace.id
      }
    } else {
      console.log(`⚠️ No matching place found for: ${rec.name}`)
      
      // Return recommendation with fallback image
      return {
        ...rec,
        imageUrl: getFallbackImageForType(rec.type),
        location: null // Will use user location as fallback
      }
    }
  }))
}

// Extract coordinates from Google Places data
function extractCoordinatesFromPlace(place: any) {
  // Google Places API v1 doesn't include coordinates in text search
  // We'll need to make a separate Place Details call or use a geocoding service
  // For now, return null and we'll use user location as fallback
  return null
}

// Get fallback image based on activity type
function getFallbackImageForType(type: string) {
  const imageMap: Record<string, string> = {
    'restaurant': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400',
    'cafe': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
    'bar': 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400',
    'museum': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
    'park': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
    'attraction': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400',
    'shopping': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400'
  }
  
  return imageMap[type.toLowerCase()] || 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400'
}

// Enhance recommendations with conversation context
async function enhanceRecommendationsWithConversation(recommendations: any[], conversationContext: string[], moods: string[]) {
  const conversationText = conversationContext.join(' ');
  
  // Extract place names and preferences mentioned in conversation
  const mentionedPlaces = extractMentionedPlaces(conversationText);
  const preferences = extractPreferences(conversationText);
  
  console.log(`📝 Extracted mentioned places: ${mentionedPlaces.join(', ')}`);
  console.log(`💭 Extracted preferences: ${JSON.stringify(preferences)}`);
  
  // Prioritize recommendations based on conversation
  const enhancedRecommendations = recommendations.map(rec => {
    let score = rec.matchScore || 0;
    
    // Boost score if mentioned in conversation
    if (mentionedPlaces.some(place => 
      rec.name?.toLowerCase().includes(place.toLowerCase()) ||
      rec.description?.toLowerCase().includes(place.toLowerCase())
    )) {
      score += 0.3;
    }
    
    // Boost score based on preferences
    if (preferences.cuisine && rec.description?.toLowerCase().includes(preferences.cuisine.toLowerCase())) {
      score += 0.2;
    }
    if (preferences.activity && rec.description?.toLowerCase().includes(preferences.activity.toLowerCase())) {
      score += 0.2;
    }
    
    return { ...rec, matchScore: score, conversationMatch: true };
  });
  
  // Sort by enhanced score
  return enhancedRecommendations.sort((a, b) => (b.matchScore || 0) - (a.matchScore || 0));
}

// Enhance day plan with conversation context
async function enhancePlanWithConversation(dayPlan: any, conversationContext: string[], moods: string[]) {
  const conversationText = conversationContext.join(' ');
  
  // Extract specific requests from conversation
  const timePreferences = extractTimePreferences(conversationText);
  const activityPreferences = extractActivityPreferences(conversationText);
  
  console.log(`⏰ Time preferences: ${JSON.stringify(timePreferences)}`);
  console.log(`🎯 Activity preferences: ${JSON.stringify(activityPreferences)}`);
  
  // Enhance plan with conversation insights
  if (dayPlan.activities) {
    dayPlan.activities = dayPlan.activities.map((activity: any, index: number) => ({
      ...activity,
      conversationEnhanced: true,
      reasoning: `Enhanced based on your conversation preferences`,
    }));
  }
  
  return dayPlan;
}

// Helper functions for conversation analysis
function extractMentionedPlaces(text: string): string[] {
  const placeKeywords = ['restaurant', 'cafe', 'bar', 'museum', 'park', 'gallery', 'theater', 'cinema'];
  const places: string[] = [];
  
  // Look for place names (capitalize first letter patterns)
  const capitalizedWords = text.match(/\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b/g) || [];
  places.push(...capitalizedWords.filter(word => word.length > 3));
  
  return [...new Set(places)]; // Remove duplicates
}

function extractPreferences(text: string): any {
  const preferences: any = {};
  
  if (text.includes('food') || text.includes('eat') || text.includes('hungry')) {
    preferences.activity = 'dining';
  }
  if (text.includes('italian') || text.includes('asian') || text.includes('mexican')) {
    preferences.cuisine = text.match(/(italian|asian|mexican|french|thai|indian|chinese)/i)?.[0];
  }
  if (text.includes('outdoor') || text.includes('nature')) {
    preferences.setting = 'outdoor';
  }
  if (text.includes('quiet') || text.includes('calm') || text.includes('peaceful')) {
    preferences.atmosphere = 'quiet';
  }
  
  return preferences;
}

function extractTimePreferences(text: string): any {
  const timePrefs: any = {};
  
  if (text.includes('morning') || text.includes('early')) {
    timePrefs.preferred = 'morning';
  }
  if (text.includes('evening') || text.includes('night') || text.includes('late')) {
    timePrefs.preferred = 'evening';
  }
  if (text.includes('lunch') || text.includes('afternoon')) {
    timePrefs.preferred = 'afternoon';
  }
  
  return timePrefs;
}

function extractActivityPreferences(text: string): any {
  const activityPrefs: any = {};
  
  if (text.includes('active') || text.includes('exercise') || text.includes('sport')) {
    activityPrefs.type = 'active';
  }
  if (text.includes('cultural') || text.includes('art') || text.includes('history')) {
    activityPrefs.type = 'cultural';
  }
  if (text.includes('social') || text.includes('friends') || text.includes('people')) {
    activityPrefs.social = true;
  }
  
  return activityPrefs;
}

/* 
Example Usage from Flutter:

POST /functions/v1/wandermood-ai
Authorization: Bearer <user-token>

{
  "action": "recommend",
  "location": {
    "latitude": 51.9244,
    "longitude": 4.4777,
    "city": "Rotterdam"
  },
  "moods": ["Foody", "Romantic"],
  "preferences": {
    "budget": 150,
    "timeSlot": "evening",
    "groupSize": 2
  },
  "conversationContext": [
    "I'm looking for something romantic tonight",
    "Maybe some Italian food would be nice",
    "I prefer quieter places"
  ]
}
*/ 