import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import { corsHeaders } from './_shared/cors.ts'

interface MoodyRequest {
  action: 'get_explore' | 'create_day_plan' | 'chat' | 'generate_hub_message'
  mood?: string
  location?: string
  coordinates?: { lat: number; lng: number }
  filters?: { priceLevel?: number; rating?: number; types?: string[]; radius?: number }
  [key: string]: any
}

interface PlaceCard {
  id: string
  name: string
  rating: number
  user_ratings_total?: number
  types: string[]
  location: { lat: number; lng: number }
  photo_reference?: string
  photo_url?: string
  price_level?: number
  vicinity?: string
  address?: string
  description?: string
  opening_hours?: { open_now?: boolean; weekday_text?: string[] }
}

interface ExploreResponse {
  cards: PlaceCard[]
  cached: boolean
  total_found: number
  cache_key?: string
  unfiltered_total?: number
  filters_applied?: boolean
}

interface Activity {
  id: string
  name: string
  description: string
  timeSlot: string
  duration: number
  location: { latitude: number; longitude: number }
  paymentType: string
  imageUrl: string
  rating: number
  tags: string[]
  startTime: string
  priceLevel?: string
  placeId?: string
}

interface DayPlanResponse {
  success: boolean
  activities: Activity[]
  location: { city: string; latitude: number; longitude: number }
  total_found: number
  error?: string
  moodyMessage?: string
  reasoning?: string
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(JSON.stringify({ success: false, error: 'Server configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ success: false, error: 'Authentication required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const token = authHeader.substring(7)
    const supabaseWithAuth = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader, apikey: supabaseAnonKey } },
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    })

    const { data: { user: authUser }, error: authError } = await supabaseWithAuth.auth.getUser(token)
    if (authError || !authUser) {
      return new Response(JSON.stringify({ success: false, error: 'Authentication failed', message: authError?.message || 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRegex.test(authUser.id)) {
      return new Response(JSON.stringify({ success: false, error: 'Invalid user ID' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    let body: MoodyRequest
    try { body = await req.json() }
    catch { return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }

    const { action, ...params } = body
    if (!action) {
      return new Response(JSON.stringify({ error: 'Action is required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    console.log(`🎯 Moody: action=${action}, userId=${authUser.id}`)

    switch (action) {
      case 'get_explore': return await handleGetExplore(supabaseWithAuth, authUser.id, params)
      case 'create_day_plan': return await handleCreateDayPlan(supabaseWithAuth, authUser.id, params)
      case 'chat': return await handleChat(supabaseWithAuth, authUser.id, params)
      case 'generate_hub_message': return await handleGenerateHubMessage(supabaseWithAuth, authUser.id, params)
      default:
        return new Response(JSON.stringify({ error: `Invalid action: ${action}` }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }
  } catch (error) {
    console.error('❌ Moody error:', error)
    const errMsg = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: 'Internal server error', message: errMsg }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})

// ============================================
// USER CONTEXT
// ============================================

async function fetchUserContext(supabase: any, userId: string): Promise<any> {
  try {
    const [profileResult, prefsResult, checkInsResult] = await Promise.all([
      supabase.from('profiles').select('favorite_mood, travel_style, travel_vibes, currently_exploring').eq('id', userId).maybeSingle(),
      supabase.from('user_preferences').select('communication_style, travel_interests, selected_moods, social_vibe, planning_pace, favorite_moods').eq('user_id', userId).maybeSingle(),
      supabase.from('user_check_ins').select('mood, created_at').eq('user_id', userId).order('created_at', { ascending: false }).limit(5),
    ])
    return {
      communicationStyle: prefsResult.data?.communication_style || 'friendly',
      isLocalMode: (profileResult.data?.currently_exploring || 'local') === 'local',
      travelInterests: prefsResult.data?.travel_interests || [],
      socialVibe: prefsResult.data?.social_vibe || [],
      planningPace: prefsResult.data?.planning_pace || 'Same Day',
      favoriteMoods: prefsResult.data?.favorite_moods || [],
      travelStyle: profileResult.data?.travel_style || 'adventurous',
      recentMoods: (checkInsResult.data || []).map((c: any) => c.mood),
      profile: profileResult.data,
    }
  } catch (e) {
    console.warn('⚠️ Could not fetch user context:', e)
    return { communicationStyle: 'friendly', isLocalMode: true, travelInterests: [], travelStyle: 'adventurous', recentMoods: [] }
  }
}

// ============================================
// PERSONALITY
// ============================================

function getMoodyPersonalityInstructions(communicationStyle: string): string {
  switch (communicationStyle.toLowerCase()) {
    case 'energetic':
      return `Je bent Moody in ENERGIEK mode. Praat als een enthousiaste beste vriend. Gebruik informele taal, grappige opmerkingen, en veel energie. Toon: "YO! Dit is precies wat jij nodig hebt 🔥". Gebruik uitroeptekens. Max 2 emojis. Altijd in het Nederlands.`
    case 'professional':
      return `Je bent Moody in PROFESSIONEEL mode. Praat helder, efficiënt en to-the-point. Geen fluff. Zakelijke toon maar niet koud. Toon: "Ik heb 3 activiteiten geselecteerd die aansluiten bij je voorkeur.". Geen uitroeptekens. Geen emojis. Altijd in het Nederlands.`
    case 'direct':
      return `Je bent Moody in DIRECT mode. Één zin. Geen uitleg tenzij gevraagd. Gewoon het antwoord. Toon: "Fenix Food Factory. 0.4km. Gaat goed.". Geen emojis. Maximaal 10 woorden. Altijd in het Nederlands.`
    case 'friendly':
    default:
      return `Je bent Moody in VRIENDELIJK mode. Praat als een warme, attente vriend. Gebruik "je/jij". Persoonlijk en betrokken. Toon: "Hey! Ik heb iets leuks gevonden voor je 😊". Max 1-2 emojis. Altijd in het Nederlands.`
  }
}

/** Hub one-liner: match app [language_code] so English UI does not get Dutch output. */
function getMoodyPersonalityForHubMessage(communicationStyle: string, lang: 'nl' | 'en'): string {
  if (lang === 'nl') return getMoodyPersonalityInstructions(communicationStyle)
  switch (communicationStyle.toLowerCase()) {
    case 'energetic':
      return `You are Moody in ENERGETIC mode. Talk like an enthusiastic best friend. Informal, playful, high energy. Tone: "YO! This is exactly what you need 🔥". Use exclamation marks. Max 2 emojis. Always write in English.`
    case 'professional':
      return `You are Moody in PROFESSIONAL mode. Clear, efficient, to-the-point. No fluff. Businesslike but warm. No exclamation marks. No emojis. Always write in English.`
    case 'direct':
      return `You are Moody in DIRECT mode. One sentence. No explanation unless asked. Just the answer. No emojis. Max 10 words. Always write in English.`
    case 'friendly':
    default:
      return `You are Moody in FRIENDLY mode. Talk like a warm, attentive friend. Use "you". Personal and caring. Tone: "Hey! I found something fun for you 😊". Max 1–2 emojis. Always write in English.`
  }
}

// ============================================
// CHAT HANDLER
// ============================================

async function handleChat(supabase: any, userId: string, params: any): Promise<Response> {
  const message = (params.message || '').trim()
  if (!message) {
    return new Response(JSON.stringify({ error: 'Message is required' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }

  const conversationHistory = params.history || []
  const userContext = await fetchUserContext(supabase, userId)
  const personalityInstructions = getMoodyPersonalityInstructions(userContext.communicationStyle)

  const localContext = userContext.isLocalMode
    ? 'De gebruiker is een LOCAL — vermijd toeristische clichés. Geef aanbevelingen die locals écht doen: hidden gems, nieuwe openingen, buurtplekken.'
    : 'De gebruiker is OP REIS — help ze het beste van de stad te ontdekken. Mix bekende plekken met lokale geheimen.'

  const systemPrompt = `${personalityInstructions}

Je bent een lokale expert in steden wereldwijd, met specialisatie in Rotterdam.
${localContext}

Gebruiker interesses: ${JSON.stringify(userContext.travelInterests)}
Favoriete stemmingen: ${JSON.stringify(userContext.favoriteMoods)}
Recente stemmingen: ${userContext.recentMoods.slice(0, 3).join(', ') || 'onbekend'}

Houd antwoorden kort en praktisch (max 150 woorden tenzij gevraagd om meer detail).
Altijd in het Nederlands tenzij de gebruiker een andere taal gebruikt.
Nooit meer dan 2 emojis per bericht.`

  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey) {
    const fallback = getFallbackChatResponse(userContext.communicationStyle)
    return new Response(JSON.stringify({ reply: fallback, conversationId: params.conversationId || `conv_${userId}_${Date.now()}` }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }

  const messages = [
    { role: 'system', content: systemPrompt },
    ...conversationHistory.slice(-10),
    { role: 'user', content: message },
  ]

  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages,
        max_tokens: 400,
        temperature: userContext.communicationStyle === 'energetic' ? 0.9 : userContext.communicationStyle === 'direct' ? 0.3 : 0.75,
      }),
    })

    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json()
    const reply = data.choices?.[0]?.message?.content || getFallbackChatResponse(userContext.communicationStyle)

    const conversationId = params.conversationId || `conv_${userId}_${Date.now()}`
    // Save to ai_conversations (non-blocking)
    supabase.from('ai_conversations').insert([
      { user_id: userId, conversation_id: conversationId, role: 'user', content: message },
      { user_id: userId, conversation_id: conversationId, role: 'assistant', content: reply },
    ]).then(() => {}).catch(() => {})

    return new Response(JSON.stringify({ reply, conversationId }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e) {
    console.error('handleChat error:', e)
    return new Response(JSON.stringify({ reply: getFallbackChatResponse(userContext.communicationStyle) }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
}

function getFallbackChatResponse(style: string): string {
  switch (style) {
    case 'energetic': return 'YO! Even geduld, ik ben zo terug! 🔥'
    case 'professional': return 'Momenteel niet beschikbaar. Probeer het later opnieuw.'
    case 'direct': return 'Even wachten.'
    default: return 'Hey! Ik ben even niet beschikbaar. Probeer het zo nog eens 😊'
  }
}

// ============================================
// MOODY HUB ONE-LINER (Flutter: MoodyHubMessageService)
// ============================================

/** Flutter sends `language_code` (BCP 47). `nl` → Dutch user-facing strings; otherwise English (de/es/fr use English until expanded). */
function clientOutputLang(params: Record<string, unknown>): 'nl' | 'en' {
  const raw = params.language_code ?? params.locale
  if (typeof raw === 'string' && raw.trim().toLowerCase().split('-')[0] === 'nl') return 'nl'
  return 'en'
}

async function handleGenerateHubMessage(
  supabase: any,
  userId: string,
  params: Record<string, unknown>
): Promise<Response> {
  const lang = clientOutputLang(params)
  const moods = Array.isArray(params.current_moods)
    ? (params.current_moods as unknown[]).filter((m): m is string => typeof m === 'string')
    : []
  const timeOfDay =
    typeof params.time_of_day === 'string' && params.time_of_day.trim() !== ''
      ? params.time_of_day.trim()
      : lang === 'nl' ? 'dag' : 'day'
  let activitiesCount = 0
  const ac = params.activities_count
  if (typeof ac === 'number' && Number.isFinite(ac)) {
    activitiesCount = Math.max(0, Math.floor(ac))
  } else if (typeof ac === 'string' && ac.trim() !== '') {
    const n = Number.parseInt(ac.trim(), 10)
    if (!Number.isNaN(n)) activitiesCount = Math.max(0, n)
  }

  const userContext = await fetchUserContext(supabase, userId)
  const style = String(userContext.communicationStyle || 'friendly').toLowerCase()
  const moodStr = moods.length > 0 ? moods.join(' & ') : (lang === 'nl' ? 'jouw vibe' : 'your vibe')

  const fallbacksNl: Record<string, string> = {
    energetic: activitiesCount > 0
      ? `YO! ${activitiesCount} item${activitiesCount === 1 ? '' : 's'} vandaag — ${moodStr} modus aan! 🔥`
      : `Nog niks gepland? Tijd om ${moodStr} te gaan ontdekken! 🔥`,
    professional: activitiesCount > 0
      ? `Je hebt ${activitiesCount} activiteit${activitiesCount === 1 ? '' : 'en'} gepland; afgestemd op ${moodStr}.`
      : `Geen plannen vandaag; overweeg iets in ${moodStr} stijl.`,
    direct: activitiesCount > 0 ? `${activitiesCount} gepland. ${moodStr}.` : `Geen plannen. ${moodStr}.`,
    friendly: activitiesCount > 0
      ? `Hey! Je hebt ${activitiesCount} ding${activitiesCount === 1 ? '' : 'en'} klaar — lekker die ${moodStr} energie 😊`
      : `Nog rustig vandaag? Misschien iets ${moodStr} voor je 😊`,
  }
  const fallbacksEn: Record<string, string> = {
    energetic: activitiesCount > 0
      ? `YO! ${activitiesCount} thing${activitiesCount === 1 ? '' : 's'} on tap today — ${moodStr} mode on! 🔥`
      : `Nothing planned yet? Time to explore your ${moodStr}! 🔥`,
    professional: activitiesCount > 0
      ? `You have ${activitiesCount} activit${activitiesCount === 1 ? 'y' : 'ies'} lined up, tuned to ${moodStr}.`
      : `No plans today; consider something in a ${moodStr} style.`,
    direct: activitiesCount > 0 ? `${activitiesCount} planned. ${moodStr}.` : `No plans. ${moodStr}.`,
    friendly: activitiesCount > 0
      ? `Hey! You've got ${activitiesCount} fun activit${activitiesCount === 1 ? 'y' : 'ies'} lined up this ${timeOfDay} to boost those ${moodStr} vibes! 😊`
      : `Quiet day? Maybe something ${moodStr} for you 😊`,
  }
  const fallbacks = lang === 'nl' ? fallbacksNl : fallbacksEn
  const fallbackMessage = fallbacks[style] || fallbacks.friendly

  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) {
    console.log('⚠️ generate_hub_message: geen OPENAI_API_KEY, fallback')
    return new Response(JSON.stringify({ message: fallbackMessage }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const personality = getMoodyPersonalityForHubMessage(userContext.communicationStyle, lang)
  const systemPromptNl = `${personality}

Schrijf precies één korte regel voor het Moody Hub startscherm (max 140 tekens). Vermeld kort: aantal activiteiten (${activitiesCount}), stemmingen (${moodStr}), dagdeel (${timeOfDay}). Max 1 emoji. Geen aanhalingstekens, geen lijstjes.`
  const systemPromptEn = `${personality}

Write exactly one short line for the Moody Hub home screen (max 140 characters). Briefly mention: number of activities (${activitiesCount}), moods (${moodStr}), time of day (${timeOfDay}). Max 1 emoji. No quotation marks, no bullet lists.`
  const systemPrompt = lang === 'nl' ? systemPromptNl : systemPromptEn

  const userPayload = JSON.stringify({
    current_moods: moods,
    time_of_day: timeOfDay,
    activities_count: activitiesCount,
  })

  const userMsgNl = `Schrijf de hub-regel. Context: ${userPayload}`
  const userMsgEn = `Write the hub line. Context: ${userPayload}`
  const userMsg = lang === 'nl' ? userMsgNl : userMsgEn

  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMsg },
        ],
        max_tokens: 100,
        temperature: style === 'energetic' ? 0.85 : style === 'direct' ? 0.35 : 0.75,
      }),
    })
    if (!resp.ok) {
      const errText = await resp.text()
      console.error('❌ generate_hub_message OpenAI:', resp.status, errText)
      throw new Error(`OpenAI ${resp.status}`)
    }
    const data = await resp.json()
    const raw = data.choices?.[0]?.message?.content
    const text = typeof raw === 'string' ? raw.trim().replace(/^["']|["']$/g, '').trim() : ''
    if (text.length > 0 && text.length <= 280) {
      return new Response(JSON.stringify({ message: text }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
  } catch (e) {
    console.error('❌ handleGenerateHubMessage:', e)
  }

  return new Response(JSON.stringify({ message: fallbackMessage }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================
// CREATE DAY PLAN
// ============================================

async function handleCreateDayPlan(supabase: any, userId: string, params: any): Promise<Response> {
  try {
    if (!params.location?.trim()) {
      return new Response(JSON.stringify({ success: false, error: 'Location is required', activities: [], total_found: 0 }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }
    if (!params.coordinates || typeof params.coordinates.lat !== 'number' || typeof params.coordinates.lng !== 'number') {
      return new Response(JSON.stringify({ success: false, error: 'Coordinates are required', activities: [], total_found: 0 }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const moods = params.moods || ['adventurous']
    const location = params.location.trim()
    const coordinates = params.coordinates
    const userContext = await fetchUserContext(supabase, userId)
    const lang = clientOutputLang(params)

    console.log(`🎯 create_day_plan: moods=${moods.join(', ')}, location=${location}, local=${userContext.isLocalMode}, lang=${lang}`)

    const moodyQueries = await getMoodySearchQueries(moods, location, userContext, lang)
    let places = await fetchPlacesFromGoogle(location, coordinates, moods[0], params.filters || {}, moodyQueries)
    places = await enrichAndFilterPlaces(places, { minRating: 3.8, minReviews: 8 })

    if (places.length === 0) {
      return new Response(JSON.stringify({ success: false, activities: [], location: { city: location, latitude: coordinates.lat, longitude: coordinates.lng }, total_found: 0, error: 'No places found' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const activities = convertPlacesToActivities(places, moods, location, coordinates, lang)
    if (activities.length === 0) {
      return new Response(JSON.stringify({ success: false, activities: [], location: { city: location, latitude: coordinates.lat, longitude: coordinates.lng }, total_found: 0, error: 'No activities generated' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { moodyMessage, reasoning } = await getMoodyPersonalityResponse(moods, activities, location, userContext, lang)
    const response: DayPlanResponse = {
      success: true, activities, location: { city: location, latitude: coordinates.lat, longitude: coordinates.lng },
      total_found: activities.length, moodyMessage, reasoning,
    }
    return new Response(JSON.stringify(response), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    console.error('❌ handleCreateDayPlan:', error)
    return new Response(JSON.stringify({ success: false, error: error.message, activities: [], total_found: 0 }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
}

// ============================================
// GET EXPLORE
// ============================================

async function handleGetExplore(supabase: any, userId: string, params: any): Promise<Response> {
  try {
    if (!params.location?.trim()) {
      return new Response(JSON.stringify({ error: 'Location is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }
    if (!params.coordinates || typeof params.coordinates.lat !== 'number' || typeof params.coordinates.lng !== 'number') {
      return new Response(JSON.stringify({ error: 'Coordinates are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const mood = params.mood || 'adventurous'
    const location = params.location.trim()
    const coordinates = params.coordinates
    const filters = params.filters || {}
    const userContext = await fetchUserContext(supabase, userId)

    console.log(`🔍 get_explore: mood=${mood}, location=${location}`)

    const isDevMode = Deno.env.get('DEV_MODE') === 'true'
    // Keep key aligned with Flutter PlacesCacheUtils.standardExploreCacheKey.
    const cacheKey = `explore_${mood}_${location.toLowerCase().trim()}`
    const cachedResult = await checkCache(supabase, cacheKey, userId)

    if (cachedResult && cachedResult.cards.length > 0) {
      console.log(`✅ Cache hit: ${cachedResult.cards.length} places`)
      const filteredCards = applyFilters(cachedResult.cards, filters)
      return new Response(JSON.stringify({ ...cachedResult, cards: filteredCards, total_found: filteredCards.length, filters_applied: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    if (isDevMode) {
      return new Response(JSON.stringify({ cards: [], cached: false, total_found: 0, error: 'DEV_MODE: No cache available' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    console.log('🔄 Cache miss — fetching from Google Places')
    let places = await fetchPlacesFromGoogle(location, coordinates, mood, {})

    // FIX: reduced from 50/5 to 15/2 to prevent timeout
    let fetchAttempts = 0
    const maxAttempts = 2
    while (places.length < 15 && fetchAttempts < maxAttempts) {
      fetchAttempts++
      console.log(`⚠️ Only ${places.length} places, attempt ${fetchAttempts}/${maxAttempts}`)
      const additionalPlaces = await fetchFallbackPlaces(location, coordinates, [mood])
      const allPlaces = [...places, ...additionalPlaces]
      places = Array.from(new Map(allPlaces.map(p => [p.id, p])).values())
    }

    // Cap before enrichment: sequential per-place Details calls caused edge timeouts (502).
    places = places.slice(0, 45)
    console.log(`✅ Total places before enrichment: ${places.length}`)

    // Enrich and enforce quality contract:
    // - Require valid id/name/address/location/photo/rating/reviews
    // - Prefer real Google details (opening hours + review totals)
    // - If too strict yields too few cards, relax only min reviews/rating (never id/photo/address)
    const strictQuality = await enrichAndFilterPlaces(places)
    let qualifiedPlaces = strictQuality
    if (qualifiedPlaces.length < 15) {
      console.log(`⚠️ Strict quality yielded ${qualifiedPlaces.length}. Applying relaxed thresholds.`)
      qualifiedPlaces = await enrichAndFilterPlaces(places, { minRating: 3.8, minReviews: 8 })
    }
    places = qualifiedPlaces
    console.log(`✅ Total places after quality gating: ${places.length}`)

    const rankedPlaces = rankPlacesByPreferences(places, userContext.profile, mood, {})
    await cachePlaces(supabase, cacheKey, rankedPlaces, userId, location)

    const filteredCards = applyFilters(rankedPlaces, filters)
    return new Response(JSON.stringify({ cards: filteredCards, cached: false, total_found: filteredCards.length, cache_key: cacheKey, unfiltered_total: rankedPlaces.length }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    console.error('❌ handleGetExplore:', error)
    const errMsg = error instanceof Error ? error.message : String(error)
    // Return 200 with empty cards so the app gets JSON (Dio) instead of 502 when upstream fails.
    return new Response(
      JSON.stringify({
        cards: [],
        cached: false,
        total_found: 0,
        error: 'explore_fetch_failed',
        message: errMsg,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
}

// ============================================
// GOOGLE PLACES
// ============================================

async function fetchPlacesFromGoogle(location: string, coordinates: { lat: number; lng: number }, mood: string, filters: any, queriesOverride?: string[] | null): Promise<PlaceCard[]> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey?.trim()) throw new Error('GOOGLE_PLACES_API_KEY not configured')

  const moodQueries = (queriesOverride && queriesOverride.length > 0) ? queriesOverride : getMoodQueries(mood)
  const allPlaces: PlaceCard[] = []

  for (const query of moodQueries) {
    try {
      const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(query + ' in ' + location)}&location=${coordinates.lat},${coordinates.lng}&radius=${filters.radius || 15000}&key=${apiKey}`
      const response = await fetch(url)
      const data = await response.json()
      if (data.status === 'OK' && data.results) {
        allPlaces.push(...data.results.map((p: any) => transformPlace(p, [mood])))
      }
      await new Promise(resolve => setTimeout(resolve, 100))
    } catch (e) {
      console.error(`❌ Error fetching "${query}":`, e)
    }
  }

  return Array.from(new Map(allPlaces.map(p => [p.id, p])).values())
}

async function fetchFallbackPlaces(location: string, coordinates: { lat: number; lng: number }, moods: string[] = []): Promise<PlaceCard[]> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey?.trim()) return []
  const queries = ['popular restaurants', 'tourist attractions', 'cafes', 'museums', 'parks']
  const allPlaces: PlaceCard[] = []
  for (const query of queries) {
    try {
      const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(query + ' in ' + location)}&location=${coordinates.lat},${coordinates.lng}&radius=20000&key=${apiKey}`
      const response = await fetch(url)
      const data = await response.json()
      if (data.status === 'OK' && data.results) {
        allPlaces.push(...data.results.map((p: any) => transformPlace(p, moods)))
      }
      await new Promise(resolve => setTimeout(resolve, 100))
    } catch (e) { console.error('❌ Fallback error:', e) }
  }
  return Array.from(new Map(allPlaces.map(p => [p.id, p])).values())
}

function transformPlace(place: any, moods: string[] = []): PlaceCard {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  const photoReference = place.photos?.[0]?.photo_reference
  const photoUrl = photoReference && apiKey
    ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${photoReference}&key=${apiKey}`
    : undefined
  return {
    id: `google_${place.place_id}`,
    name: place.name,
    rating: place.rating || 0,
    user_ratings_total: place.user_ratings_total || 0,
    types: place.types || [],
    location: { lat: place.geometry?.location?.lat || 0, lng: place.geometry?.location?.lng || 0 },
    photo_reference: photoReference,
    photo_url: photoUrl,
    price_level: place.price_level,
    vicinity: place.vicinity,
    address: place.formatted_address,
    description: place.editorial_summary?.overview || generatePlaceDescription(place, moods),
    opening_hours: place.opening_hours
      ? {
          open_now: place.opening_hours.open_now,
          weekday_text: place.opening_hours.weekday_text || [],
        }
      : undefined,
  }
}

async function enrichAndFilterPlaces(
  input: PlaceCard[],
  thresholds: { minRating?: number; minReviews?: number } = {},
): Promise<PlaceCard[]> {
  const minRating = thresholds.minRating ?? 4.0
  const minReviews = thresholds.minReviews ?? 20
  const out: PlaceCard[] = []
  const concurrency = 6
  for (let i = 0; i < input.length; i += concurrency) {
    const chunk = input.slice(i, i + concurrency)
    const enrichedChunk = await Promise.all(chunk.map((p) => enrichPlaceIfNeeded(p)))
    for (const enriched of enrichedChunk) {
      if (!isPlaceCardValidForExplore(enriched, { minRating, minReviews })) continue
      out.push(enriched)
    }
    // Enough for Explore UI; stop early to stay under edge CPU/time limits.
    if (out.length >= 35) break
  }
  return out
}

function normalizeRawPlaceId(id: string): string {
  return id.startsWith('google_') ? id.substring(7) : id
}

async function enrichPlaceIfNeeded(place: PlaceCard): Promise<PlaceCard> {
  const needsDetails =
    !place.address?.trim() ||
    !place.photo_url?.trim() ||
    !place.user_ratings_total ||
    !place.opening_hours
  if (!needsDetails) return place
  try {
    const details = await fetchGooglePlaceDetails(normalizeRawPlaceId(place.id))
    if (!details) return place
    return {
      ...place,
      address: place.address || details.address || place.vicinity,
      photo_reference: place.photo_reference || details.photo_reference,
      photo_url: place.photo_url || details.photo_url,
      rating: place.rating || details.rating || 0,
      user_ratings_total: place.user_ratings_total || details.user_ratings_total || 0,
      opening_hours: place.opening_hours || details.opening_hours,
      price_level: place.price_level ?? details.price_level,
      types: place.types.length > 0 ? place.types : (details.types || []),
    }
  } catch (e) {
    console.warn('⚠️ enrichPlaceIfNeeded failed:', e)
    return place
  }
}

async function fetchGooglePlaceDetails(placeId: string): Promise<Partial<PlaceCard> | null> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey?.trim()) return null
  const fields = [
    'place_id',
    'name',
    'formatted_address',
    'geometry',
    'photos',
    'rating',
    'user_ratings_total',
    'price_level',
    'opening_hours',
    'types',
  ].join(',')
  const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${encodeURIComponent(placeId)}&fields=${encodeURIComponent(fields)}&key=${apiKey}`
  const response = await fetch(url)
  const data = await response.json()
  if (data.status !== 'OK' || !data.result) return null
  const r = data.result
  const photoReference = r.photos?.[0]?.photo_reference
  return {
    address: r.formatted_address,
    rating: r.rating || 0,
    user_ratings_total: r.user_ratings_total || 0,
    price_level: r.price_level,
    types: r.types || [],
    photo_reference: photoReference,
    photo_url: photoReference
      ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${photoReference}&key=${apiKey}`
      : undefined,
    opening_hours: r.opening_hours
      ? {
          open_now: r.opening_hours.open_now,
          weekday_text: r.opening_hours.weekday_text || [],
        }
      : undefined,
  }
}

function isPlaceCardValidForExplore(
  place: PlaceCard,
  thresholds: { minRating: number; minReviews: number },
): boolean {
  const rawId = normalizeRawPlaceId(place.id || '')
  const hasStableId = rawId.trim().length > 0
  const hasName = !!place.name?.trim()
  const hasAddress = !!(place.address?.trim() || place.vicinity?.trim())
  const hasCoords = Number.isFinite(place.location?.lat) && Number.isFinite(place.location?.lng) && (place.location.lat !== 0 || place.location.lng !== 0)
  const hasPhoto = !!place.photo_url?.trim()
  const ratingOk = (place.rating || 0) >= thresholds.minRating
  const reviewsOk = (place.user_ratings_total || 0) >= thresholds.minReviews
  return hasStableId && hasName && hasAddress && hasCoords && hasPhoto && ratingOk && reviewsOk
}

function generatePlaceDescription(place: any, moods: string[] = []): string {
  const name = place.name || 'This place'
  const rating = place.rating ? place.rating.toFixed(1) : '4.0'
  const types = place.types || []
  const moodText = moods.length > 0 ? moods.join(' and ').toLowerCase() : 'your'
  if (types.some((t: string) => t.includes('restaurant') || t.includes('food'))) return `${name} offers delicious cuisine perfect for ${moodText} mood. Rated ${rating} stars.`
  if (types.some((t: string) => t.includes('cafe') || t.includes('coffee'))) return `${name} is a cozy spot for coffee and ${moodText} vibes. Rated ${rating} stars.`
  if (types.some((t: string) => t.includes('museum') || t.includes('gallery'))) return `Explore culture at ${name}. Perfect for ${moodText} experiences. Rated ${rating} stars.`
  if (types.some((t: string) => t.includes('park') || t.includes('garden'))) return `${name} offers a peaceful natural setting for ${moodText} moments. Rated ${rating} stars.`
  return `${name} is a highly-rated destination perfect for ${moodText} experiences. Rated ${rating} stars.`
}

function rankPlacesByPreferences(places: PlaceCard[], profile: any, mood: string, filters: any): PlaceCard[] {
  return places.sort((a, b) => {
    if (b.rating !== a.rating) return b.rating - a.rating
    if (a.price_level && b.price_level) return a.price_level - b.price_level
    return 0
  })
}

function applyFilters(places: PlaceCard[], filters: any): PlaceCard[] {
  if (!filters || Object.keys(filters).length === 0) return places
  return places.filter(place => {
    if (filters.rating && place.rating < filters.rating) return false
    if (filters.priceLevel && place.price_level && place.price_level > filters.priceLevel) return false
    if (filters.types?.length > 0) {
      const hasType = place.types.some(t => filters.types.some((ft: string) => t.toLowerCase().includes(ft.toLowerCase())))
      if (!hasType) return false
    }
    if (filters.minReviews && (place.user_ratings_total || 0) < filters.minReviews) return false
    return true
  })
}

async function checkCache(supabase: any, cacheKey: string, userId: string): Promise<ExploreResponse | null> {
  try {
    let { data, error } = await supabase.from('places_cache').select('data, expires_at').eq('cache_key', cacheKey).is('place_id', null).maybeSingle()
    if (error || !data) {
      const legacy = await supabase.from('places_cache').select('data, expires_at').eq('cache_key', cacheKey).eq('user_id', userId).is('place_id', null).maybeSingle()
      data = legacy.data; error = legacy.error
    }
    if (error || !data) return null
    if (new Date(data.expires_at) < new Date()) return null
    if (!data.data?.cards) return null
    return { cards: data.data.cards, cached: true, total_found: data.data.cards.length, cache_key: cacheKey }
  } catch { return null }
}

async function cachePlaces(supabase: any, cacheKey: string, places: PlaceCard[], userId: string, location: string): Promise<void> {
  try {
    const expiresAt = new Date()
    expiresAt.setDate(expiresAt.getDate() + 30)
    await supabase.from('places_cache').upsert({
      cache_key: cacheKey, data: { cards: places }, place_id: null,
      user_id: userId, request_type: 'explore', expires_at: expiresAt.toISOString(),
    }, { onConflict: 'cache_key' })
    console.log(`💾 Cached ${places.length} places for 30 days`)
  } catch (e) { console.error('❌ Cache error:', e) }
}

// ============================================
// OPENAI HELPERS
// ============================================

async function getMoodySearchQueries(moods: string[], location: string, userContext: any, lang: 'nl' | 'en'): Promise<string[] | null> {
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return null

  const isLocal = userContext.isLocalMode
  const localModeNl = isLocal
    ? `BELANGRIJK: Gebruiker is LOCAL. Vermijd toeristische dingen. Geef hidden gems, nieuwe openingen, buurtplekken die locals kennen.`
    : `BELANGRIJK: Gebruiker is OP REIS. Mix bekende bezienswaardigheden met lokale geheimen.`
  const localModeEn = isLocal
    ? `IMPORTANT: User is a LOCAL. Avoid tourist clichés. Prefer hidden gems, new openings, neighborhood spots locals actually use.`
    : `IMPORTANT: User is TRAVELING. Mix well-known sights with local secrets.`

  const systemNl = `Je bent Moody, de WanderMood reisassistent. ${localModeNl} Geef 5-7 korte Google Places zoektermen als JSON: {"queries": ["term1", "term2"]}. Geen markdown.`
  const systemEn = `You are Moody, the WanderMood travel assistant. ${localModeEn} Return 5-7 short Google Places search query strings as JSON: {"queries": ["term1", "term2"]}. No markdown. Queries should work well in English for the Places API.`
  const userNl = `Moods: ${moods.join(', ')}. Locatie: ${location}. Interesses: ${JSON.stringify(userContext.travelInterests)}.`
  const userEn = `Moods: ${moods.join(', ')}. Location: ${location}. Interests: ${JSON.stringify(userContext.travelInterests)}.`

  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: lang === 'nl' ? systemNl : systemEn },
          { role: 'user', content: lang === 'nl' ? userNl : userEn },
        ],
        max_tokens: 200, temperature: 0.5, response_format: { type: 'json_object' },
      }),
    })
    if (!resp.ok) return null
    const data = await resp.json()
    const parsed = JSON.parse(data.choices?.[0]?.message?.content || '{}')
    const queries = Array.isArray(parsed.queries) ? parsed.queries.filter((q: any) => typeof q === 'string').slice(0, 7) : []
    if (queries.length === 0) return null
    console.log('🤖 Moody queries:', queries)
    return queries
  } catch (e) { console.error('getMoodySearchQueries error:', e); return null }
}

async function getMoodyPersonalityResponse(moods: string[], activities: Activity[], location: string, userContext: any, lang: 'nl' | 'en'): Promise<{ moodyMessage: string; reasoning: string }> {
  const style = String(userContext?.communicationStyle || 'friendly')
  const fallbacksNl: Record<string, any> = {
    energetic: { moodyMessage: `YO! ${activities.length} epic activiteiten voor je ${moods.join(' & ')} dag! 🔥`, reasoning: `Perfecte energie-mix voor jou.` },
    professional: { moodyMessage: `${activities.length} activiteiten geselecteerd voor ${location} op basis van je ${moods.join(' en ')} stemming.`, reasoning: `Geselecteerd op beoordeling en beschikbaarheid.` },
    direct: { moodyMessage: `${activities.length} activiteiten. ${location}. Klaar.`, reasoning: `Match met stemming.` },
    friendly: { moodyMessage: `Hey! ${activities.length} leuke activiteiten voor je ${moods.join(' & ')} dag in ${location} 😊`, reasoning: `Mooie mix die bij je stemming past.` },
  }
  const fallbacksEn: Record<string, any> = {
    energetic: { moodyMessage: `YO! ${activities.length} epic activities for your ${moods.join(' & ')} day! 🔥`, reasoning: `High-energy picks for you.` },
    professional: { moodyMessage: `${activities.length} activities selected for ${location} based on your ${moods.join(' & ')} mood.`, reasoning: `Chosen for ratings and fit.` },
    direct: { moodyMessage: `${activities.length} activities. ${location}. Done.`, reasoning: `Mood match.` },
    friendly: { moodyMessage: `Hey! ${activities.length} fun activities for your ${moods.join(' & ')} day in ${location} 😊`, reasoning: `A nice mix for your vibe.` },
  }
  const fallbacks = lang === 'nl' ? fallbacksNl : fallbacksEn
  const fallback = fallbacks[style] || fallbacks.friendly
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return fallback
  const jsonSuffixNl = ` Geef ALLEEN JSON: {"moodyMessage": "<max 120 tekens>", "reasoning": "<max 80 tekens>"}`
  const jsonSuffixEn = ` Reply with JSON only: {"moodyMessage": "<max 120 characters>", "reasoning": "<max 80 characters>"}`
  const systemContent = `${getMoodyPersonalityForHubMessage(style, lang)}${lang === 'nl' ? jsonSuffixNl : jsonSuffixEn}`
  const userNl = `Stemming: ${moods.join(', ')}. Locatie: ${location}. ${activities.length} activiteiten gevonden waaronder: ${activities.slice(0, 3).map(a => a.name).join(', ')}.`
  const userEn = `Moods: ${moods.join(', ')}. Location: ${location}. ${activities.length} activities found including: ${activities.slice(0, 3).map(a => a.name).join(', ')}.`
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemContent },
          { role: 'user', content: lang === 'nl' ? userNl : userEn },
        ],
        max_tokens: 200, temperature: style === 'energetic' ? 0.9 : style === 'direct' ? 0.3 : 0.7,
        response_format: { type: 'json_object' },
      }),
    })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json()
    const parsed = JSON.parse(data.choices?.[0]?.message?.content || '{}')
    return { moodyMessage: parsed.moodyMessage || fallback.moodyMessage, reasoning: parsed.reasoning || fallback.reasoning }
  } catch (e) { return fallback }
}

function getMoodQueries(mood: string): string[] {
  const moodMap: Record<string, string[]> = {
    adventurous: ['adventure activities', 'outdoor activities', 'adventure tours', 'extreme sports', 'hiking'],
    relaxed: ['spa', 'parks', 'cafes', 'relaxation', 'wellness'],
    cultural: ['museums', 'art galleries', 'historical sites', 'cultural centers', 'monuments'],
    romantic: ['romantic restaurants', 'scenic spots', 'sunset views', 'romantic cafes'],
    social: ['bars', 'nightlife', 'social clubs', 'entertainment'],
    foodie: ['restaurants', 'food markets', 'street food', 'local cuisine', 'cafes'],
    energetic: ['sports facilities', 'gyms', 'dance clubs', 'fitness activities'],
    creative: ['art studios', 'workshops', 'galleries', 'creative spaces'],
  }
  return moodMap[mood.toLowerCase()] || moodMap.adventurous
}

// ============================================
// DAY PLAN CONVERSION
// ============================================

function convertPlacesToActivities(places: PlaceCard[], moods: string[], location: string, coordinates: { lat: number; lng: number }, lang: 'nl' | 'en'): Activity[] {
  const activities: Activity[] = []
  const usedPlaceIds = new Set<string>()
  const shuffled = [...places].sort(() => Math.random() - 0.5)
  const morning: PlaceCard[] = [], afternoon: PlaceCard[] = [], evening: PlaceCard[] = []
  for (const place of shuffled) {
    if (usedPlaceIds.has(place.id)) continue
    const slots = getTimeSlotsForPlace(place)
    if (slots.includes('morning')) morning.push(place)
    if (slots.includes('afternoon')) afternoon.push(place)
    if (slots.includes('evening')) evening.push(place)
  }
  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const addActivities = (pool: PlaceCard[], slot: string, startHour: number, maxHour: number, count: number, pastHour: number) => {
    for (let i = 0; i < Math.min(count, pool.length); i++) {
      const place = pool[i]
      if (usedPlaceIds.has(place.id)) continue
      usedPlaceIds.add(place.id)
      const hour = startHour + Math.floor(Math.random() * (maxHour - startHour))
      const minute = [0, 15, 30, 45][Math.floor(Math.random() * 4)]
      const startTime = new Date(today.getTime())
      startTime.setHours(hour, minute, 0, 0)
      if (now.getHours() >= pastHour) startTime.setDate(startTime.getDate() + 1)
      activities.push(createActivityFromPlace(place, slot, startTime, moods, lang))
    }
  }
  addActivities(morning, 'morning', 7, 10, 3, 11)
  addActivities(afternoon, 'afternoon', 12, 16, 3, 17)
  addActivities(evening, 'evening', 17, 20, 3, 21)
  return activities.sort((a, b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime())
}

function getTimeSlotsForPlace(place: PlaceCard): string[] {
  const slots: string[] = []
  const types = place.types.map(t => t.toLowerCase())
  const name = place.name.toLowerCase()
  if (types.some(t => ['cafe', 'bakery', 'park', 'library', 'spa', 'museum', 'art_gallery'].includes(t)) || name.includes('coffee') || name.includes('breakfast')) slots.push('morning')
  if (types.some(t => ['restaurant', 'museum', 'art_gallery', 'shopping_mall', 'tourist_attraction', 'food', 'cafe', 'park'].includes(t))) slots.push('afternoon')
  if (types.some(t => ['restaurant', 'bar', 'night_club', 'entertainment'].includes(t)) || name.includes('dinner') || name.includes('bar')) slots.push('evening')
  if (slots.length === 0) slots.push('afternoon')
  return slots
}

function createActivityFromPlace(place: PlaceCard, timeSlot: string, startTime: Date, moods: string[], lang: 'nl' | 'en'): Activity {
  const placeId = place.id.startsWith('google_') ? place.id.substring(7) : place.id
  return {
    id: `activity_${Date.now()}_${place.id}`,
    name: place.name,
    description: generateDescription(place, moods, lang),
    timeSlot,
    duration: estimateDuration(place.types),
    location: { latitude: place.location.lat, longitude: place.location.lng },
    paymentType: determinePaymentType(place.types, place.price_level),
    imageUrl: place.photo_url || '',
    rating: place.rating,
    tags: generateTags(place.types, moods, lang),
    startTime: startTime.toISOString(),
    priceLevel: place.price_level ? getPriceLevelText(place.price_level) : undefined,
    placeId,
  }
}

function estimateDuration(types: string[]): number {
  if (types.includes('restaurant')) return 90
  if (types.includes('museum') || types.includes('art_gallery')) return 120
  if (types.includes('park')) return 60
  if (types.includes('spa')) return 90
  if (types.includes('cafe') || types.includes('bakery')) return 45
  if (types.includes('bar') || types.includes('night_club')) return 120
  return 60
}

function determinePaymentType(types: string[], priceLevel?: number): string {
  if (types.includes('park') || types.includes('beach')) return 'free'
  if (types.includes('museum') || types.includes('amusement_park')) return 'ticket'
  if (types.includes('restaurant') || types.includes('bar') || types.includes('spa')) return 'reservation'
  if (!priceLevel) return 'free'
  return 'reservation'
}

function getPriceLevelText(priceLevel: number): string {
  return ['', '€', '€€', '€€€', '€€€€'][priceLevel] || '€€'
}

function generateDescription(place: PlaceCard, moods: string[], lang: 'nl' | 'en'): string {
  const moodJoin = lang === 'nl' ? ' en ' : ' and '
  const moodText = moods.join(moodJoin).toLowerCase()
  const rating = place.rating.toFixed(1)
  if (lang === 'nl') {
    if (place.types.includes('restaurant')) return `${place.name} serveert heerlijke gerechten perfect voor een ${moodText} dag. Gewaardeerd met ${rating} sterren.`
    if (place.types.includes('cafe')) return `${place.name} is de perfecte koffieplek voor je ${moodText} dag. Gewaardeerd met ${rating} sterren.`
    if (place.types.includes('museum') || place.types.includes('art_gallery')) return `Ontdek cultuur bij ${place.name}. Inspirerende ervaringen voor je ${moodText} stemming. Gewaardeerd ${rating} sterren.`
    if (place.types.includes('park')) return `${place.name} biedt een prachtige groene omgeving voor je ${moodText} dag. Gewaardeerd ${rating} sterren.`
    return `${place.name} is een topadres voor je ${moodText} ervaring. Gewaardeerd ${rating} sterren.`
  }
  if (place.types.includes('restaurant')) return `${place.name} serves great food — a strong pick for a ${moodText} day. Rated ${rating} stars.`
  if (place.types.includes('cafe')) return `${place.name} is a great coffee stop for your ${moodText} day. Rated ${rating} stars.`
  if (place.types.includes('museum') || place.types.includes('art_gallery')) return `Explore culture at ${place.name}. An inspiring fit for your ${moodText} mood. Rated ${rating} stars.`
  if (place.types.includes('park')) return `${place.name} offers a beautiful green space for your ${moodText} day. Rated ${rating} stars.`
  return `${place.name} is a top spot for your ${moodText} experience. Rated ${rating} stars.`
}

function generateTags(types: string[], moods: string[], lang: 'nl' | 'en'): string[] {
  const tags: string[] = []
  const culture = lang === 'nl' ? 'Cultuur' : 'Culture'
  const outdoors = lang === 'nl' ? 'Buiten' : 'Outdoors'
  const romantic = lang === 'nl' ? 'Romantisch' : 'Romantic'
  const creative = lang === 'nl' ? 'Creatief' : 'Creative'
  if (types.includes('restaurant') || types.includes('food')) tags.push('Food')
  if (types.includes('spa') || types.includes('beauty_salon')) tags.push('Wellness')
  if (types.includes('museum') || types.includes('art_gallery')) tags.push(culture)
  if (types.includes('park') || types.includes('natural_feature')) tags.push(outdoors)
  if (types.includes('bar') || types.includes('night_club')) tags.push('Nightlife')
  if (types.includes('cafe') || types.includes('bakery')) tags.push('Cafe')
  for (const mood of moods) {
    const m = mood.toLowerCase()
    if (m === 'romantic' && (types.includes('restaurant') || types.includes('bar'))) tags.push(romantic)
    if (m === 'creative' && types.includes('museum')) tags.push(creative)
  }
  return tags.slice(0, 2)
}
