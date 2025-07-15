import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers
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

    // Get user context
    const userContext = await getUserContext(supabaseClient, user.id)
    
    // Get relevant places based on location and moods
    const relevantPlaces = await getRelevantPlaces(
      supabaseClient, 
      body.location, 
      body.moods || []
    )

    // Build AI prompt based on action
    const aiPrompt = buildAIPrompt(body, userContext, relevantPlaces)
    
    // Call OpenAI with context
    const aiResponse = await callOpenAI(aiPrompt, body.action)

    // Save conversation if it's a chat
    if (body.action === 'chat' && body.conversationId) {
      await saveConversation(supabaseClient, body.conversationId, user.id, body.message!, aiResponse)
    }

    // Format response
    const formattedResponse = formatResponse(body.action, aiResponse, relevantPlaces)

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
      .limit(10)
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

  // Try to get places that match the moods from existing places table
  const { data: places } = await supabase
    .from('places')
    .select('*')
    .gte('rating', 4.0)
    .order('rating', { ascending: false })
    .limit(20)

  return places || []
}

// Build AI prompt based on request type and context
function buildAIPrompt(
  request: WanderMoodRequest,
  userContext: any,
  places: any[]
): string {
  const baseContext = `
You are WanderMood AI, an expert travel assistant for the WanderMood app. You help users discover amazing experiences based on their mood and preferences.

Current Context:
- Location: ${request.location?.city || 'Unknown'}
- User Moods: ${request.moods?.join(', ') || 'None specified'}
- Available Places: ${places.length} curated local venues
- User Preferences: ${JSON.stringify(userContext.preferences, null, 2)}

Recent User Activity:
${userContext.visitedPlaces?.slice(0, 5).map((p: any) => `- ${p.name} (${p.mood})`).join('\n') || 'No recent activity'}

Available Venues Context:
${places.slice(0, 10).map(place => 
  `- ${place.name}: ${place.rating}⭐ - ${place.description || 'Great local venue'}`
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
      return `${baseContext}

TASK: Respond to the user's message naturally and helpfully.

User Message: "${request.message}"

Instructions:
- Be conversational and friendly
- Use knowledge of available venues when relevant
- Ask clarifying questions if needed
- Provide specific, actionable advice
- Reference real places from the context when possible
- Keep responses concise but helpful`

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

    default:
      return `${baseContext}

TASK: General assistance with travel and activity planning.

User Request: "${request.message}"

Provide helpful, contextual advice based on available information.`
  }
}

// Call OpenAI API with context
async function callOpenAI(
  prompt: string,
  action: string
): Promise<string> {
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey) {
    throw new Error('OpenAI API key not configured')
  }

  const messages = [
    {
      role: 'system',
      content: prompt
    }
  ]

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
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
function formatResponse(action: string, aiResponse: string, places: any[]) {
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