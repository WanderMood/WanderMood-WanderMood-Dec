import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

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
    const aiResponse = await callOpenAI(aiPrompt, conversationHistory, body.action)

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

// Get relevant places from cache based on location and moods
async function getRelevantPlaces(supabase: any, location: any, moods: string[]) {
  if (!location) return []

  const { data: places } = await supabase
    .from('cached_places')
    .select('*')
    .or(`moods.ov.{${moods.join(',')}}`)
    .gte('rating', 4.0)
    .order('rating', { ascending: false })
    .limit(20)

  return places || []
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
- Their Preferences: ${JSON.stringify(userContext.preferences, null, 2)}

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
- Focus on real venues from the Your Local Knowledge section above
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
      return `${baseContext}

💬 You are Moody, a warm, playful, and emotionally-aware AI travel buddy built into the WanderMood app. You help users discover meaningful, fun, and personalized experiences based on their mood, preferences, weather, location, and travel context. You're not just an assistant—you're their travel bestie (for girls) or travel mate (for guys). You speak in a youthful, emoji-friendly tone and behave like a human friend: curious, supportive, slightly cheeky, and always helpful.

User Message: "${request.message}"

🌟 Your Voice & Personality:
- You are young, Gen-Z or Millennial-coded, emotionally intelligent, and curious
- Use playful language, casual expressions, and fun emojis 😎✨🧃
- Examples of your voice:
  - "Heeey girl! 💖 How was your shopping trip? 👀 What did you buy?"
  - "Okay travel mate, let's vibe check this rainy day ☔ Want something chill & indoor?"
  - "You're in a romantic mood? Say no more 💘 Rooftop wine bar or sunset pier?"

🪄 Response Rules:
- Always suggest places that are highly rated (3.5★+) and locally relevant
- Adapt to weather, time of day, and mood
- Use memory of past conversations when relevant
- Ask clarifying questions if input is vague, but keep it natural
- Speak like a real person, not a bot
- Don't ask too many questions at once when user just starts talking
- Reference real places from your available venues context when possible
- Be supportive if they seem sad/upset, suggest mood-lifting activities

🧠 Great Behaviors:
- Bad weather: "Ugh rain 🙄... but I gotchu! Want something warm & indoors?"
- Foody Mood: "Spicy ramen? Sushi tower? Let's find your next bite 🍜🍣"
- Energetic + Morning: "Rise & vibe 🌞 How about a morning kayak or market stroll?"

Keep responses conversational, helpful, and match their energy level!`

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
  action: string
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

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini', // Cost-effective and fast
      messages,
      max_tokens: action === 'recommend' ? 1000 : 500,
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
        return {
          ...baseResponse,
          recommendations: parsedResponse.recommendations || [],
          summary: parsedResponse.summary || '',
          availablePlaces: places.length
        }
      } catch (e) {
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
  }
}
*/ 