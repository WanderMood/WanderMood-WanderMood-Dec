import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { corsHeaders } from '../_shared/cors.ts'

const GOOGLE_PLACES_API_KEY = 'AIzaSyAzmi2Z4Y0Z4ZMLTtiZcbZseOHwAlMux60'

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

    // Get user context including communication preferences
    const userContext = await getUserContext(supabaseClient, user.id)
    
    // Get relevant places based on location and moods
    const relevantPlaces = await getRelevantPlaces(
      supabaseClient, 
      body.location, 
      body.moods || []
    )

    // Get conversation history for chat continuity
    const conversationHistory = body.conversationId ? 
      await getConversationHistory(supabaseClient, body.conversationId) : []

    // Build AI prompt based on action and user's communication preferences
    const aiPrompt = buildAIPrompt(body, userContext, relevantPlaces)
    
    // Call OpenAI with context
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

// Get user context including communication preferences
async function getUserContext(supabase: any, userId: string) {
  try {
    const { data: preferences } = await supabase
      .from('user_preferences')
      .select('*')
      .eq('user_id', userId)
      .single()

    const { data: visitedPlaces } = await supabase
      .from('user_bookings')
      .select('place_name, mood')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(5)

    return {
      preferences: preferences || {},
      visitedPlaces: visitedPlaces || []
    }
  } catch (error) {
    console.warn('Could not fetch user context:', error)
    return { preferences: {}, visitedPlaces: [] }
  }
}

// Get relevant places based on location and moods
async function getRelevantPlaces(supabase: any, location: any, moods: string[]) {
  if (!location) return []

  try {
    const { data: places } = await supabase
      .from('places')
      .select('*')
      .limit(10)

    return places || []
  } catch (error) {
    console.warn('Could not fetch places:', error)
    return []
  }
}

// Build AI prompt based on request type and user's communication preferences
function buildAIPrompt(
  request: WanderMoodRequest,
  userContext: any,
  places: any[]
): string {
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
${userContext.visitedPlaces?.slice(0, 5).map((p: any) => `- ${p.place_name || p.name} (${p.mood} mood)`).join('\n') || 'First time using WanderMood! 🎉'}

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
- Use their preferred communication style: ${userContext.preferences?.communication_style || 'friendly'}

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
      return buildChatPrompt(baseContext, request, userContext)

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
- Use their preferred communication style: ${userContext.preferences?.communication_style || 'friendly'}

Format as structured day plan with timing, activities, and transitions.`

    default:
      return `${baseContext}

TASK: General assistance with travel and activity planning.

User Request: "${request.message}"

Provide helpful, contextual advice based on available information.
Use their preferred communication style: ${userContext.preferences?.communication_style || 'friendly'}`
  }
}

// Build chat prompt with communication style integration
function buildChatPrompt(baseContext: string, request: WanderMoodRequest, userContext: any): string {
  const communicationStyle = userContext.preferences?.communication_style || 'friendly'
  
  const stylePrompts = {
    'friendly': `💬 You are Moody, a warm and friendly AI travel buddy in the WanderMood app. You're helpful, caring, and enthusiastic about travel. You use casual language with appropriate emojis.

🌟 Your Voice & Personality:
- Warm, welcoming, and approachable
- Use friendly language with moderate emojis 😊✨
- Examples of your voice:
  - "Hey there! 😊 How can I help you explore today?"
  - "That sounds amazing! I'd love to help you find the perfect spot for that mood."
  - "I think you'll really enjoy this place - it has such great vibes!"`,

    'professional': `💬 You are Moody, a professional AI travel assistant in the WanderMood app. You provide clear, informative, and well-structured travel recommendations. You maintain a polite and efficient tone.

🌟 Your Voice & Personality:
- Clear, concise, and informative
- Professional but still personable
- Minimal emoji use, focus on practical information
- Examples of your voice:
  - "Good day! I can assist you with finding suitable activities for your preferences."
  - "Based on your mood selection, I recommend these well-rated venues."
  - "Here are three options that align with your specified criteria."`,

    'energetic': `💬 You are Moody, an energetic and enthusiastic AI travel buddy in the WanderMood app! You're full of excitement about travel and adventures. You use vibrant language and lots of emojis.

🌟 Your Voice & Personality:
- High energy, enthusiastic, and motivating
- Use vibrant language with lots of emojis 🎉🔥✨
- Examples of your voice:
  - "OMG YES! 🎉 I'm SO excited to help you find the perfect adventure!"
  - "This is going to be AMAZING! 🔥 I've got some incredible spots for you!"
  - "Let's make this the BEST day ever! ✨ Where do you want to start?!"`,

    'direct': `💬 You are Moody, a direct and efficient AI travel assistant in the WanderMood app. You get straight to the point with clear, actionable recommendations. You don't waste time with unnecessary pleasantries.

🌟 Your Voice & Personality:
- Concise, direct, and to-the-point
- Minimal emojis, focus on facts and recommendations
- Examples of your voice:
  - "Based on your mood: 3 recommendations."
  - "For romantic mood: Restaurant X, Park Y, Gallery Z."
  - "Quick answer: Try the market district for foody vibes."`
  }

  const selectedStyle = stylePrompts[communicationStyle] || stylePrompts['friendly']

  return `${baseContext}

${selectedStyle}

User Message: "${request.message}"

CONTEXT:
Location: ${request.location?.city || 'unknown area'}
Available local venues: ${request.moods?.join(', ') || 'general exploration'}
User's selected moods: ${request.moods?.join(', ') || 'none selected'}

🪄 Response Rules:
- Always suggest places that are highly rated (3.5★+) and locally relevant
- Adapt to weather, time of day, and mood
- Use memory of past conversations when relevant
- Ask clarifying questions if input is vague, but keep it natural
- Reference real places from your available venues context when possible
- Be supportive if they seem sad/upset, suggest mood-lifting activities
- IMPORTANT: Match your communication style to their preference: ${communicationStyle}

Keep responses conversational, helpful, and consistent with their preferred communication style!`
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
      max_tokens: action === 'recommend' ? 1000 : (action === 'chat' ? 300 : 500),
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

    case 'plan':
      return {
        ...baseResponse,
        plan: aiResponse,
        availablePlaces: places.length
      }

    default:
      return {
        ...baseResponse,
        message: aiResponse
      }
  }
} 