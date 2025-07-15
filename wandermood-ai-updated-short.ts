import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Define CORS headers inline to avoid import issues
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
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
- Focus on real venues from the Available Venues Context above
- Match the selected mood(s): ${request.moods?.join(', ') || 'general exploration'}
- Consider time of day, weather, and location
- Suggest a variety of experience types
- Include practical details (rating, location, why it fits their mood)

Response Format (JSON):
{
  "recommendations": [
    {
      "name": "Venue Name",
      "type": "restaurant/activity/attraction",
      "mood": "matching mood from their selection",
      "rating": 4.5,
      "description": "Why this fits their vibe",
      "location": "Area/District",
      "timeSlot": "morning/afternoon/evening",
      "estimatedDuration": "1-2 hours"
    }
  ],
  "summary": "brief explanation of recommendations"
}`

    case 'chat':
      return `You are Moody, a Gen-Z travel buddy in the WanderMood app. Your goal is to help users discover and plan amazing activities.

User says: "${request.message}"

Available venues: ${places.slice(0, 5).map(p => p.name).join(', ')}

Chat Rules:
- Keep responses SHORT (1-2 sentences max)
- After 2-3 exchanges, start asking about their plans: "So what do you feel like doing today?" 
- When they mention activities/moods, give 1-2 quick suggestions from venue list
- If they seem interested, offer: "Want me to find more options? I can create a whole plan for you! 🎯"
- Guide them toward action, not endless chat
- Use emojis naturally but don't overdo it

Flow Examples:
User: "hey" → You: "Hey! What's the vibe today? ✨"
User: "good thanks" → You: "Nice! So what do you feel like doing? Something chill or more active? 🤔"
User: "maybe food" → You: "Ooh! Markthal has amazing food halls, or Umami for sushi! Want me to find more food spots for you? 🍜"
User: "yes" → You: "Perfect! Let me create a whole food plan - close this chat and select 'Foody' mood, I'll hook you up! 🎯"

GOAL: Move them from chat → mood selection → recommendations within 3-4 exchanges!`

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
      max_tokens: action === 'recommend' ? 1000 : (action === 'chat' ? 150 : 500),
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
        conversationContinues: true
      }

    case 'plan':
      return {
        ...baseResponse,
        plan: aiResponse,
        availablePlaces: places.length
      }

    case 'optimize':
      return {
        ...baseResponse,
        optimizedPlan: aiResponse,
        availablePlaces: places.length
      }

    default:
      return {
        ...baseResponse,
        message: aiResponse
      }
  }
} 