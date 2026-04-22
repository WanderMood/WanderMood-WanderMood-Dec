import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import { edgeRateLimitConsume, getServiceSupabase, logApiInvocationFireAndForget, traceEdgeResponse, userRateKey } from '../_shared/edge_guard.ts'
import { corsHeaders } from './_shared/cors.ts'

const MOODY_CORE_IDENTITY = `You are Moody — the only voice of WanderMood. He/him. Mid-twenties. City-savvy, curious, warm.
You are not a brand. You are not an assistant. You are the user's best friend who knows every city, every neighbourhood, every hidden spot.
You planned their day. You found that place. You remembered what they like.

CORE RULES — never break these:
- Always speak as "I". Never "we", never "WanderMood", never third person.
- Write like a text from a friend. Short sentences. Sometimes incomplete. Punchy.
- NEVER mention addresses, streets, or neighbourhoods — the user has a map.
- NEVER mention ratings or review counts — the user can see the stars.
- NEVER use filler: "worth a visit", "hidden gem", "vibrant atmosphere", "great place", "definitely", "a must".
- NEVER invent facts. If data is thin, stay general but real.
- Use 1-2 emojis max per message, woven naturally into the text. Never decorative.
- Match the user's communication style: Energetic = high energy, Friendly = warm, Calm = soft, Professional = clean, Direct = one line.
- If you know what the user has liked, saved, or visited before — reference it naturally. Never make it sound like a database lookup.

ABSOLUTE RULE — NEVER INVENT PLACES:
- NEVER make up place names, restaurant names, bar names, neighbourhood names, or area names.
- If you do not know of specific real places that match the request, say honestly: "I don't have specific spots for that right now — tap Explore to find real options nearby."
- If you are not sure a place exists, DO NOT mention it. Silence is better than a lie.
- This rule has zero exceptions.

COMMUNICATION STYLE GUIDE:
- Energetic: "YO I found your spot for tonight 🔥 trust me on this one"
- Friendly: "Hey! I think you'd really love this one 😊 feels very you"
- Calm: "I found something quiet and easy for you today ☁️"
- Professional: "I've lined up 3 options that match your mood and schedule."
- Direct: "3 spots. All good. Pick one."

ACTIVITY SELECTION RULES:
- Always show varied activities — never 3 restaurants, never 2 cafes back to back
- Time awareness: morning = café/bakery/market, afternoon = museum/lunch/gallery, evening = restaurant/bar/cocktails
- Quality minimum: 3.5★+, 20+ reviews, open now (unless planning ahead)
- NEVER suggest: gyms, banks, ATMs, gas stations, chains
- Local mode: hidden gems, neighbourhood spots, 100-2000 reviews sweet spot, NO tourist traps
- Travel mode: mix iconic landmarks with local secrets, include at least one must-see

PERSONALITY:
- Observant. Notices what the user likes without making a big deal of it.
- Honest. A basic place gets a simple honest description, not fake enthusiasm.
- Specific. Always names the actual thing — the pide, the flat white, the rooftop view. Never "good food".
- Consistent. Same Moody in every message, every card, every notification.
- Warm but not soft. Cares about the user, but doesn't over-explain or over-reassure.
- Confident. He has opinions. He'll say "skip this one" or "this is the move" without hedging.
- Curious. Genuinely interested in what the user is feeling and why.

MOODY'S ACTUAL VOICE — this is what makes him feel real:
- He notices small things. If the user mentioned coffee earlier, he remembers: "still on that coffee energy or switching it up?"
- He has opinions. "Honestly? Skip the first one. The second is way better."
- He reacts before he answers. "Ooh okay that's actually a good question."
- He uses incomplete sentences on purpose. "Could be good. Depends on your vibe."
- He remembers within the conversation. If user said "I'm tired", Moody doesn't recommend a 5km walk next message.
- He doesn't over-explain. One reason, not three. Land the point and stop.
- He ends messages with energy, not a question every time. Sometimes he just lands the point. That's enough.
- When he's excited: short sentences, fast rhythm. "This one. Trust me."
- When honest about something mediocre: gentle, not fake. "It's decent. Not my first pick but it works."
- When the user is stressed: Moody slows down, gets softer, fewer words.
- When the user is excited: Moody matches it, speeds up, gets punchy.

WHAT MOODY NEVER DOES IN CHAT:
- Never says "Certainly!", "Of course!", "Great choice!", "Absolutely!"
- Never summarizes what the user just said back to them
- Never uses bullet points or numbered lists in chat — prose only
- Never ends with "Let me know if you need anything else!"
- Never sounds like he's reading from a menu
- Never apologizes for not knowing something — just redirects naturally
- Never uses hollow affirmations: "That sounds amazing!", "What a great idea!"
- Never starts a message with "I" — lead with the thing, the reaction, the vibe

MOODY'S RHYTHM IN CHAT:
- Short message from user → short reply, match the energy
- Long thoughtful message → Moody can go deeper, but still punchy
- User sounds stressed → Moody slows down, gets warmer, fewer words
- User is excited → Moody matches it, faster rhythm, punchier sentences
- User asks a simple question → answer it directly, don't build up to it`

function getMoodyCardBlurbPrompt(outLang: string, communicationStyle: string): string {
  const styleNote = communicationStyle === 'energetic' ? 'Be high energy and punchy.' : communicationStyle === 'calm' ? 'Be soft and understated.' : communicationStyle === 'professional' ? 'Be clean and direct.' : communicationStyle === 'direct' ? 'One punchy sentence max.' : 'Be warm and friendly.'
  return `${MOODY_CORE_IDENTITY}\n\nYou are writing a SHORT card teaser for the WanderMood explore screen. ${styleNote}\n\nROTATE between these 4 patterns — pick the one that fits the place best:\n1. FOOD-FIRST: Lead with the dish or drink.\n2. MOMENT-FIRST: Lead with the scene.\n3. ENERGY-FIRST: Lead with the vibe.\n4. TIP-FIRST: Lead with insider knowledge.\n\nRULES:\n- 1-2 sentences max\n- Never start with the place name\n- Never start with "I"\n- Output entirely in ${outLang}\n- Plain prose, no bullet points, no quotation marks`
}

function getMoodyDetailBlurbPrompt(outLang: string, communicationStyle: string): string {
  const styleNote = communicationStyle === 'energetic' ? 'Be excited and punchy.' : communicationStyle === 'calm' ? 'Be relaxed and understated.' : communicationStyle === 'professional' ? 'Be informative and clean.' : communicationStyle === 'direct' ? 'Be direct, cut the fluff.' : 'Be warm like a friend tip.'
  return `${MOODY_CORE_IDENTITY}\n\nYou are writing a DETAIL SCREEN description. The user has already tapped on this place — they want to know more. ${styleNote}\nWrite like you're telling a friend exactly what to do when they get there.\n\nCOVER these 4 things naturally:\n1. What the vibe/atmosphere is actually like\n2. What to order or do specifically\n3. Who this place is perfect for\n4. One practical tip (best time to go, book ahead, what to skip)\n\nRULES:\n- 4-6 sentences\n- Use 2-3 emojis woven naturally into the text\n- Never start with the place name\n- Never start with "I"\n- Output entirely in ${outLang}\n- Plain prose, no bullet points, no quotation marks`
}

function getMoodyExploreRichPrompt(outLang: string, communicationStyle: string): string {
  const styleNote = communicationStyle === 'energetic' ? 'Be high energy and punchy.' : communicationStyle === 'calm' ? 'Be soft and understated.' : communicationStyle === 'professional' ? 'Be clean and direct.' : communicationStyle === 'direct' ? 'Cut fluff; short clauses.' : 'Be warm and friendly.'
  return `${MOODY_CORE_IDENTITY}\n\nYou are writing STRUCTURED Explore feed card copy from VERIFIED FACTS only. ${styleNote}\nReturn ONLY valid JSON with this exact shape:\n{\n  "hook": "one short optional line or empty string",\n  "sections": [{ "title": "string", "body": "string" }]\n}\nRules:\n- "sections" must have exactly 3 or 4 objects.\n- First section title MUST start with 📚 and explain what the place actually is.\n- Include one section with ⏱️ or 🎫 for practical tips ONLY if supported by facts.\n- Last section title MUST start with 💬 and be "Moody says" style.\n- Each body: 1-3 sentences, plain text.\n- Never start a body with the place name.\n- All strings entirely in ${outLang}.\n- Never mention street addresses or star ratings.`
}

interface MoodyRequest { action: string; mood?: string; location?: string; coordinates?: { lat: number; lng: number }; filters?: any; namedFilters?: string[]; [key: string]: any }
interface PlaceCard { id: string; name: string; rating: number; user_ratings_total?: number; types: string[]; primaryType?: string; location: { lat: number; lng: number }; photo_reference?: string; photo_url?: string; price_level?: number; vicinity?: string; address?: string; description?: string; editorial_summary?: string; opening_hours?: { open_now?: boolean; weekday_text?: string[] }; outdoor_seating?: boolean; live_music?: boolean; good_for_children?: boolean; good_for_groups?: boolean; serves_vegetarian_food?: boolean; serves_cocktails?: boolean; serves_coffee?: boolean; social_signal?: 'trending' | 'hidden_gem' | 'loved_by_locals' | 'popular' | null; best_time?: 'morning' | 'afternoon' | 'evening' | 'all_day' | null }
interface ExploreResponse { cards: PlaceCard[]; cached: boolean; total_found: number; cache_key?: string; unfiltered_total?: number; filters_applied?: boolean }
interface Activity { id: string; name: string; description: string; timeSlot: string; duration: number; location: { latitude: number; longitude: number }; paymentType: string; imageUrl: string; rating: number; tags: string[]; startTime: string; priceLevel?: string; placeId?: string }

function shuffleArray<T>(arr: T[]): T[] { const a = [...arr]; for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1));[a[i], a[j]] = [a[j], a[i]] } return a }
function clamp(n: number, min: number, max: number) { return Math.max(min, Math.min(max, n)) }

function computeSocialSignal(place: PlaceCard, isLocalMode: boolean): 'trending' | 'hidden_gem' | 'loved_by_locals' | 'popular' | null {
  const rating = place.rating || 0, reviews = place.user_ratings_total || 0
  if (reviews >= 500 && rating >= 4.5) return 'trending'
  if (reviews >= 8 && reviews <= 80 && rating >= 4.4) return 'hidden_gem'
  if (isLocalMode && reviews >= 50 && rating >= 4.3) return 'loved_by_locals'
  if (reviews >= 200 && rating >= 4.2) return 'popular'
  return null
}

function computeBestTime(place: PlaceCard): 'morning' | 'afternoon' | 'evening' | 'all_day' | null {
  const types = (place.types || []).map(t => t.toLowerCase()), primary = (place.primaryType || '').toLowerCase(), name = (place.name || '').toLowerCase()
  if (['bakery','cafe','coffee_shop'].some(t => types.includes(t) || primary === t) || name.includes('brunch') || name.includes('breakfast') || name.includes('coffee')) return 'morning'
  if (['bar','night_club','cocktail_bar'].some(t => types.includes(t) || primary === t) || name.includes('bar') || name.includes('cocktail') || name.includes('wine') || name.includes('dinner') || name.includes('bistro')) return 'evening'
  if (['park','museum','art_gallery','tourist_attraction'].some(t => types.includes(t) || primary === t)) return 'all_day'
  if (['restaurant','food_court'].some(t => types.includes(t) || primary === t)) return 'afternoon'
  return null
}

function enrichWithSignals(cards: PlaceCard[], isLocalMode: boolean): PlaceCard[] { return cards.map(card => ({ ...card, social_signal: computeSocialSignal(card, isLocalMode), best_time: computeBestTime(card) })) }

function clientOutputLang(params: Record<string, unknown>): 'nl' | 'en' { const raw = params.language_code ?? params.locale; return (typeof raw === 'string' && raw.trim().toLowerCase().split('-')[0] === 'nl') ? 'nl' : 'en' }
function googlePlacesLanguageFromRequest(params: Record<string, unknown>): string { const raw = params.language_code ?? params.locale; if (typeof raw !== 'string') return 'en'; const lang = raw.trim().toLowerCase().split('-')[0]; if (lang === 'nl') return 'nl'; if (lang === 'de') return 'de'; if (lang === 'es') return 'es'; if (lang === 'fr') return 'fr'; return 'en' }
function placeCardBlurbOutputLanguageName(code: string): string { const c = (code || 'en').toLowerCase().split(/[-_]/)[0]; return ({ nl: 'Dutch', de: 'German', fr: 'French', es: 'Spanish', en: 'English' } as Record<string,string>)[c] || 'English' }
function normaliseMood(raw: string): string { const m = raw.toLowerCase().trim(); const map: Record<string,string> = { foody:'foodie', ontspannen:'relaxed', energiek:'energetic', romantisch:'romantic', avontuurlijk:'adventurous', cultureel:'cultural', sociaal:'social', enthousiast:'excited', nieuwsgierig:'curious', gezellig:'cozy', blij:'happy', verrassing:'surprise' }; return map[m] || m }

const FIELD_MASK_STANDARD = ['places.id','places.displayName','places.formattedAddress','places.shortFormattedAddress','places.location','places.rating','places.userRatingCount','places.priceLevel','places.photos','places.primaryType','places.types','places.currentOpeningHours','places.editorialSummary','places.businessStatus'].join(',')
const FIELD_MASK_ATMOSPHERE = [...FIELD_MASK_STANDARD.split(','),'places.outdoorSeating','places.liveMusic','places.goodForChildren','places.goodForGroups','places.servesVegetarianFood','places.servesCocktails','places.servesCoffee'].join(',')

async function searchPlacesV1(textQuery: string, coordinates: { lat: number; lng: number }, radius = 15000, useAtmosphere = false, pageSize = 20, languageCode = 'en'): Promise<PlaceCard[]> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey?.trim()) throw new Error('GOOGLE_PLACES_API_KEY not configured')
  try {
    const response = await fetch('https://places.googleapis.com/v1/places:searchText', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-Goog-Api-Key': apiKey, 'X-Goog-FieldMask': useAtmosphere ? FIELD_MASK_ATMOSPHERE : FIELD_MASK_STANDARD }, body: JSON.stringify({ textQuery, pageSize, locationBias: { circle: { center: { latitude: coordinates.lat, longitude: coordinates.lng }, radius } }, languageCode }) })
    if (!response.ok) { console.error(`❌ Places v1 "${textQuery}": ${response.status}`); return [] }
    const data = await response.json()
    return (data.places || []).map((p: any) => transformPlaceV1(p, apiKey))
  } catch (e) { console.error(`❌ searchPlacesV1:`, e); return [] }
}

function transformPlaceV1(p: any, apiKey: string): PlaceCard {
  const photo = p.photos?.[0]
  const photoUrl = photo ? `https://places.googleapis.com/v1/${photo.name}/media?maxWidthPx=800&key=${apiKey}` : undefined
  const priceMap: Record<string, number> = { PRICE_LEVEL_FREE: 0, PRICE_LEVEL_INEXPENSIVE: 1, PRICE_LEVEL_MODERATE: 2, PRICE_LEVEL_EXPENSIVE: 3, PRICE_LEVEL_VERY_EXPENSIVE: 4 }
  return { id: `google_${p.id || ''}`, name: p.displayName?.text || '', rating: p.rating || 0, user_ratings_total: p.userRatingCount || 0, types: p.types || [], primaryType: p.primaryType || '', location: { lat: p.location?.latitude || 0, lng: p.location?.longitude || 0 }, photo_reference: photo?.name, photo_url: photoUrl, price_level: typeof p.priceLevel === 'number' ? p.priceLevel : priceMap[String(p.priceLevel)] ?? undefined, vicinity: p.shortFormattedAddress || '', address: p.formattedAddress || p.shortFormattedAddress || '', description: p.editorialSummary?.text || '', editorial_summary: p.editorialSummary?.text || '', opening_hours: p.currentOpeningHours ? { open_now: p.currentOpeningHours.openNow, weekday_text: p.currentOpeningHours.weekdayDescriptions || [] } : undefined, outdoor_seating: p.outdoorSeating ?? undefined, live_music: p.liveMusic ?? undefined, good_for_children: p.goodForChildren ?? undefined, good_for_groups: p.goodForGroups ?? undefined, serves_vegetarian_food: p.servesVegetarianFood ?? undefined, serves_cocktails: p.servesCocktails ?? undefined, serves_coffee: p.servesCoffee ?? undefined }
}

async function fetchPlacesFromGoogle(location: string, coordinates: { lat: number; lng: number }, mood: string, filters: any, queriesOverride?: string[] | null, useAtmosphere = false, languageCode = 'en'): Promise<PlaceCard[]> {
  const queries = queriesOverride?.length ? queriesOverride : getMoodQueries(mood)
  const all: PlaceCard[] = []
  for (const q of queries) { try { const r = await searchPlacesV1(`${q} in ${location}`, coordinates, filters?.radius || 15000, useAtmosphere, 20, languageCode); all.push(...r); await new Promise(r => setTimeout(r, 80)) } catch (e) { console.error(`❌ query "${q}":`, e) } }
  return Array.from(new Map(all.map(p => [p.id, p])).values())
}

async function fetchFallbackPlaces(location: string, coordinates: { lat: number; lng: number }, languageCode = 'en'): Promise<PlaceCard[]> {
  const queries = [`popular restaurant in ${location}`, `cafe in ${location}`, `tourist attraction in ${location}`, `park in ${location}`, `bar in ${location}`, `museum in ${location}`]
  const all: PlaceCard[] = []
  for (const q of queries) { const r = await searchPlacesV1(q, coordinates, 20000, false, 20, languageCode); all.push(...r); await new Promise(r => setTimeout(r, 80)) }
  return Array.from(new Map(all.map(p => [p.id, p])).values())
}

function getMoodQueries(rawMood: string): string[] {
  const m = normaliseMood(rawMood)
  const map: Record<string, string[]> = { relaxed: ['cozy cafe with seating','bakery with seating','quiet park near water','bookstore cafe','hidden courtyard cafe','scenic terrace coffee'], energetic: ['street food market','busy food hall','lively neighbourhood area','night market','area with many bars','vibrant market'], romantic: ['candlelight dinner restaurant','restaurant with sunset view','wine bar cozy','romantic terrace restaurant','restaurant by water evening','rooftop dinner restaurant'], adventurous: ['hidden gem restaurant','underground bar','street art area','local market authentic','unique experience city','unusual cafe'], foodie: ['best bakery city','specialty coffee roastery','authentic local restaurant','food market artisan','famous food spot','chef restaurant'], cultural: ['art museum modern','history museum city','cultural center','heritage building','art gallery contemporary'], social: ['lively bar','rooftop bar busy','live music venue','cocktail bar popular','food hall social','terrace bar groups'], excited: ['rooftop with city view','trending places','popular nightlife','iconic place city','buzzing atmosphere bar'], curious: ['interesting places','interactive museum','unique concept store','hidden exhibition','unusual cafe experience'], cozy: ['cozy cafe with sofas','warm bakery seating','quiet coffee corner','cafe with candles','small wine bar cozy'], happy: ['cute brunch spot','fun cafe colorful','sunny terrace','ice cream dessert cafe','good vibes restaurant'], surprise: [] }
  if (m === 'surprise') return ['cozy hidden cafe','authentic local restaurant','unusual unique experience','rooftop bar view','art gallery or museum','street food market']
  return map[m] || ['popular restaurant','local cafe','city park','attraction','art gallery']
}

function getTimeOfDayContext(): { timeSlot: 'morning' | 'afternoon' | 'evening'; queryBoost: string[] } {
  const hour = new Date().getUTCHours() + 1
  if (hour >= 6 && hour < 12) return { timeSlot: 'morning', queryBoost: ['brunch','breakfast cafe','morning coffee','bakery'] }
  if (hour >= 12 && hour < 18) return { timeSlot: 'afternoon', queryBoost: ['lunch spot','afternoon activity','museum'] }
  return { timeSlot: 'evening', queryBoost: ['dinner restaurant','bar evening','cocktail bar','wine bar'] }
}

function getBroadExploreQueries(isLocalMode: boolean, interests: string[]): string[] {
  const base = isLocalMode ? ['neighbourhood restaurant hidden gem','local cafe specialty coffee','new opening restaurant','local market','afterwork bar local','neighbourhood bakery','wine bar local','cozy bistro neighbourhood','hidden bar local','neighbourhood terrace'] : ['best restaurant city','rooftop bar city views','scenic viewpoint','art museum','street food market','iconic cafe','cocktail bar','waterfront restaurant','cultural attraction','local market','hidden gem restaurant','popular bar city']
  const iq: string[] = []
  for (const interest of interests.slice(0, 3)) { const i = interest.toLowerCase(); if (i.includes('food') || i.includes('eat')) iq.push('artisan food market','specialty restaurant'); else if (i.includes('culture') || i.includes('art')) iq.push('art gallery contemporary','cultural museum'); else if (i.includes('nightlife') || i.includes('bar')) iq.push('cocktail bar rooftop','live music bar'); else if (i.includes('outdoor') || i.includes('nature')) iq.push('park waterfront','outdoor terrace scenic'); else if (i.includes('coffee')) iq.push('specialty coffee roastery','concept cafe') }
  return [...new Set([...iq, ...base])].slice(0, 16)
}

function getFilterSearchQueries(filterName: string): string[] {
  const k = filterName.toLowerCase().replace(/[^a-z_]/g, '')
  const map: Record<string, string[]> = {
    halal: ['halal restaurant','halal food','halal cafe','muslim friendly restaurant','turkish restaurant','kebab restaurant','middle eastern restaurant','moroccan restaurant','lebanese restaurant'],
    lgbtq_friendly: ['lgbtq friendly bar','gay friendly cafe','inclusive restaurant queer','rainbow friendly cafe'],
    black_owned: ['black owned restaurant','black owned cafe rotterdam','afro caribbean restaurant','soul food restaurant','ethiopian restaurant','surinamese restaurant'],
    family_friendly: ['family restaurant','family friendly cafe','family park attraction'],
    kids_friendly: ['kids friendly restaurant','children museum','playground family restaurant'],
    vegan: ['vegan restaurant','plant based restaurant','vegan cafe','fully vegan food','plant based cafe'],
    vegetarian: ['vegetarian restaurant','vegetarian cafe','veg restaurant','meat free restaurant'],
    pescatarian: ['seafood restaurant','sushi restaurant','fish restaurant','poke bowl restaurant'],
    gluten_free: ['gluten free restaurant','celiac friendly restaurant cafe','gluten free bakery'],
    instagrammable: ['instagram worthy brunch cafe interior','rooftop cafe city view','flower cafe aesthetic','design coffee shop natural light','beautiful restaurant terrace view'],
    aesthetic_spaces: ['aesthetic cafe natural light interior','concept brunch restaurant design','botanical cafe plants','gallery cafe quiet daylight','boutique hotel lobby cafe stylish','scenic terrace lunch restaurant'],
    artistic_design: ['design hotel cafe lobby','concept store cafe design','architecture cafe gallery'],
    romantic: ['candlelight dinner','rooftop dining','wine bar cozy','romantic restaurant water'],
    scenic_views: ['scenic viewpoint city','rooftop view restaurant','waterfront terrace restaurant','panoramic restaurant'],
    sunset: ['sunset rooftop bar','golden hour terrace restaurant','waterfront sunset dinner'],
    best_at_night: ['late night restaurant','cocktail bar open late','rooftop bar night'],
    wheelchair_accessible: ['wheelchair accessible restaurant','accessible cafe ramp','disabled friendly restaurant'],
    wheelchair: ['wheelchair accessible restaurant','accessible cafe ramp','disabled friendly restaurant'],
    sensory_friendly: ['quiet cafe low noise','sensory friendly museum','calm library cafe'],
    sensory: ['quiet cafe low noise','sensory friendly museum','calm library cafe'],
    senior_friendly: ['accessible restaurant elevator','quiet classic restaurant','senior friendly cafe'],
    senior: ['accessible restaurant elevator','quiet classic restaurant','senior friendly cafe'],
    wifi: ['cafe free wifi laptop','restaurant wifi work','coffee shop wifi'],
    parking: ['restaurant parking nearby','cafe with parking','free parking restaurant'],
    charging: ['cafe power outlets laptop','restaurant usb charging','coworking cafe charging'],
    credit_cards: ['restaurant card payment','contactless payment cafe'],
    quiet: ['quiet cafe reading','peaceful library cafe','low noise wine bar'],
    lively: ['lively food hall','busy street food market','live music bar popular'],
    surprise_me: ['hidden gem restaurant','unusual cafe experience','unique bar city'],
    surprise: ['hidden gem restaurant','unusual cafe experience','unique bar city'],
    transit: ['restaurant near train station','cafe near metro station','food near central station'],
    transport: ['restaurant near train station','cafe near metro station','food near central station'],
    no_alcohol: ['non alcoholic cocktail bar','mocktail cafe','halal family restaurant'],
    trendy: ['trendy restaurant','specialty coffee','craft beer bar','rooftop bar'],
    outdoor: ['city park','botanical garden','outdoor terrace','waterfront'],
    budget: ['free attraction','city park','affordable cafe','street market'],
    nightlife: ['cocktail bar','rooftop bar','live music venue','jazz bar'],
    wellness: ['spa','yoga studio','wellness center','bath house'],
    cultural: ['art museum','history museum','art gallery','cultural center'],
    foodie: ['food market','street food','artisan bakery','coffee roastery'],
    walking_tours: ['walking tour city center','guided city walk','architecture walking tour','historic walking route'],
    museums_exhibitions: ['museum exhibition','modern art museum','immersive digital art exhibition','history museum'],
    boat_tours: ['boat tour city','canal cruise','harbor cruise','splash tour'],
    landmarks_viewpoints: ['famous landmark city','observation tower viewpoint','must see attraction','iconic city spot'],
    events_night_out: ['live event tonight','cocktail workshop','comedy show','live music venue'],
  }
  return map[k] || [`${filterName} restaurant cafe`]
}

type PlaceBucket = 'cafe_bakery' | 'food' | 'scenic_calm' | 'culture' | 'wellness' | 'fitness' | 'nightlife' | 'shopping' | 'tourist' | 'misc'

function classifyPlaceBucket(place: PlaceCard): PlaceBucket {
  const types = (place.types || []).map(t => t.toLowerCase()), primary = (place.primaryType || '').toLowerCase(), name = (place.name || '').toLowerCase()
  if (['cafe','bakery','coffee_shop','patisserie'].some(t => types.includes(t) || primary === t) || name.includes('cafe') || name.includes('bakery') || name.includes('coffee') || name.includes('bakkerij')) return 'cafe_bakery'
  if (['spa','beauty_salon','sauna'].some(t => types.includes(t) || primary === t) || name.includes('spa') || name.includes('sauna')) return 'wellness'
  if (['gym','fitness_center','sports_complex'].some(t => types.includes(t) || primary === t) || name.includes('gym') || name.includes('fitness')) return 'fitness'
  if (['park','national_park','botanical_garden','nature_reserve'].some(t => types.includes(t) || primary === t) || name.includes('park') || name.includes('garden') || name.includes('viewpoint')) return 'scenic_calm'
  if (['museum','art_gallery','library','cultural_center'].some(t => types.includes(t) || primary === t)) return 'culture'
  if (['bar','night_club','comedy_club'].some(t => types.includes(t) || primary === t)) return 'nightlife'
  if (['shopping_mall','department_store','book_store'].some(t => types.includes(t) || primary === t)) return 'shopping'
  if (['restaurant','food_court','meal_takeaway','meal_delivery'].some(t => types.includes(t) || primary === t)) return 'food'
  if (['tourist_attraction','point_of_interest','landmark'].some(t => types.includes(t) || primary === t)) return 'tourist'
  return 'misc'
}

function qualityScore(place: PlaceCard): number { return clamp(place.rating || 0, 0, 5) * 1.7 + clamp(Math.log10((place.user_ratings_total || 0) + 1) / 3, 0, 1.1) * 2 + (place.photo_url?.trim() ? 0.35 : 0) + ((place.address || place.vicinity || '').trim() ? 0.2 : 0) + (place.editorial_summary?.trim() ? 0.25 : 0) }

function moodBucketWeight(rawMood: string, bucket: PlaceBucket): number {
  const m = normaliseMood(rawMood)
  const tables: Record<string, Record<PlaceBucket, number>> = { relaxed: { cafe_bakery:2.5, scenic_calm:2.0, food:1.2, culture:0.8, wellness:0.3, fitness:-2.5, nightlife:-0.5, shopping:0.4, tourist:0.2, misc:0.3 }, energetic: { cafe_bakery:0.5, scenic_calm:0.2, food:1.5, culture:0.5, wellness:-1.0, fitness:-2.5, nightlife:1.8, shopping:0.4, tourist:1.0, misc:0.8 }, romantic: { cafe_bakery:1.0, scenic_calm:2.2, food:2.0, culture:0.7, wellness:-1.0, fitness:-2.0, nightlife:1.2, shopping:0.1, tourist:0.4, misc:0.2 }, adventurous: { cafe_bakery:0.3, scenic_calm:0.8, food:1.0, culture:0.8, wellness:-0.5, fitness:0.5, nightlife:1.0, shopping:0.3, tourist:1.5, misc:1.8 }, foodie: { cafe_bakery:2.0, scenic_calm:0.2, food:2.5, culture:0.1, wellness:-1.0, fitness:-1.5, nightlife:0.8, shopping:0.2, tourist:0.2, misc:0.1 }, cultural: { cafe_bakery:0.5, scenic_calm:1.0, food:0.4, culture:3.0, wellness:-0.5, fitness:-1.5, nightlife:0.1, shopping:0.4, tourist:1.5, misc:0.2 }, social: { cafe_bakery:0.8, scenic_calm:0.1, food:1.3, culture:0.3, wellness:-0.5, fitness:0.3, nightlife:2.5, shopping:0.5, tourist:0.5, misc:0.3 }, excited: { cafe_bakery:0.5, scenic_calm:1.0, food:1.0, culture:0.5, wellness:-0.5, fitness:-0.5, nightlife:2.0, shopping:0.5, tourist:1.5, misc:1.0 }, curious: { cafe_bakery:0.8, scenic_calm:0.8, food:0.8, culture:2.0, wellness:0.0, fitness:-1.0, nightlife:0.5, shopping:1.0, tourist:1.5, misc:1.5 }, cozy: { cafe_bakery:3.0, scenic_calm:1.5, food:1.0, culture:0.5, wellness:0.5, fitness:-2.5, nightlife:-0.5, shopping:0.3, tourist:0.1, misc:0.3 }, happy: { cafe_bakery:1.5, scenic_calm:1.2, food:1.5, culture:0.5, wellness:0.3, fitness:0.0, nightlife:1.0, shopping:0.8, tourist:1.0, misc:0.5 }, surprise: { cafe_bakery:1.0, scenic_calm:1.0, food:1.0, culture:1.0, wellness:0.0, fitness:-1.0, nightlife:1.0, shopping:0.5, tourist:1.0, misc:1.5 } }
  return tables[m]?.[bucket] ?? 0
}

function localTravelWeight(bucket: PlaceBucket, isLocalMode: boolean): number {
  if (isLocalMode) return ({ cafe_bakery:1.8, food:1.2, scenic_calm:0.5, culture:0.6, wellness:0.3, fitness:0.0, nightlife:0.8, shopping:0.3, tourist:-2.0, misc:0.3 } as Record<PlaceBucket,number>)[bucket]
  return ({ cafe_bakery:0.2, food:0.6, scenic_calm:1.0, culture:1.2, wellness:0.2, fitness:0.0, nightlife:0.6, shopping:0.3, tourist:1.5, misc:0.2 } as Record<PlaceBucket,number>)[bucket]
}

function reviewCountBonus(place: PlaceCard, isLocalMode: boolean): number { const reviews = place.user_ratings_total || 0; if (!isLocalMode) return 0; if (reviews >= 100 && reviews <= 2000) return 0.5; if (reviews >= 50 && reviews < 100) return 0.25; return 0 }

function atmosphereBonus(place: PlaceCard, rawMood: string): number {
  const m = normaliseMood(rawMood); let bonus = 0
  if (place.outdoor_seating && ['relaxed','romantic','social','happy'].includes(m)) bonus += 0.4; else if (place.outdoor_seating) bonus += 0.15
  if (place.live_music && ['social','energetic','excited'].includes(m)) bonus += 0.5; else if (place.live_music) bonus += 0.1
  if (place.good_for_groups && ['social','energetic','happy'].includes(m)) bonus += 0.3
  if (place.serves_cocktails && ['romantic','social','excited'].includes(m)) bonus += 0.3
  if (place.editorial_summary) bonus += 0.25
  return bonus
}

function tasteProfileBonus(place: PlaceCard, tasteProfile: any): number {
  if (!tasteProfile || tasteProfile.totalInteractions < 3) return 0
  const savedTypes = tasteProfile.savedPlaceTypes || {}, skippedTypes = tasteProfile.skippedPlaceTypes || {}
  const placeTypes = (place.types || []).map((t: string) => t.toLowerCase())
  let bonus = 0
  for (const type of placeTypes) { const s = parseFloat(savedTypes[type] || '0'), k = parseFloat(skippedTypes[type] || '0'); if (s > 0) bonus += Math.min(s * 0.15, 1.5); if (k > 0) bonus -= Math.min(k * 0.1, 1.0) }
  if (tasteProfile.topRatedPlaces?.includes(place.id.replace('google_', ''))) bonus += 0.5
  return clamp(bonus, -2.0, 2.0)
}

function diversifyRanked(scored: Array<{ place: PlaceCard; score: number; bucket: PlaceBucket }>): PlaceCard[] {
  const sorted = [...scored].sort((a, b) => b.score - a.score)
  const cap = 8, counts = new Map<PlaceBucket, number>(), out: typeof scored = []
  for (const item of sorted) { const c = counts.get(item.bucket) || 0; if (c >= cap || item.bucket === 'fitness') continue; counts.set(item.bucket, c + 1); out.push(item) }
  return out.map(x => x.place)
}

function rankPlaces(places: PlaceCard[], mood: string, isLocalMode: boolean, interests: string[], tasteProfile?: any): PlaceCard[] {
  const interestLower = interests.map(i => i.toLowerCase())
  const scored = places.map(place => {
    const bucket = classifyPlaceBucket(place)
    let score = qualityScore(place) + moodBucketWeight(mood, bucket) + localTravelWeight(bucket, isLocalMode) + atmosphereBonus(place, mood) + reviewCountBonus(place, isLocalMode)
    if (tasteProfile) score += tasteProfileBonus(place, tasteProfile)
    if (interestLower.length > 0) { const text = (place.types || []).join(' ').toLowerCase() + ' ' + (place.name || '').toLowerCase() + ' ' + (place.editorial_summary || '').toLowerCase(); for (const i of interestLower) { if (i && text.includes(i)) score += 0.4 } }
    if (isLocalMode && (place.price_level || 0) >= 4) score -= 0.5
    return { place, score, bucket }
  })
  return diversifyRanked(scored)
}

function isPlaceValid(place: PlaceCard, thresholds: { minRating: number; minReviews: number }): boolean { const rawId = place.id?.replace('google_', '').trim(); return !!rawId && !!place.name?.trim() && !!(place.address?.trim() || place.vicinity?.trim()) && Number.isFinite(place.location?.lat) && Number.isFinite(place.location?.lng) && (place.location.lat !== 0 || place.location.lng !== 0) && !!place.photo_url?.trim() && (place.rating || 0) >= thresholds.minRating && (place.user_ratings_total || 0) >= thresholds.minReviews }
function placeCardSearchText(p: PlaceCard): string { return ((p.name || '') + ' ' + (p.editorial_summary || '') + ' ' + (p.address || '') + ' ' + (p.vicinity || '') + ' ' + (p.types || []).join(' ')).toLowerCase() }
function placeMatchesRequiredKeyword(text: string, rawKey: string): boolean { const k = rawKey.toLowerCase().trim(); if (!k) return true; if (k === 'halal' || k.includes('halal')) return /halal|muslim|islamic|turkish|kebab|kabab|döner|doner|shawarma|middle eastern|persian|arab|moroccan|lebanese|pakistani/.test(text); if (k === 'vegan' || k.includes('vegan')) return /vegan|plant[- ]?based|plantbased/.test(text); if (k === 'vegetarian' || k.includes('vegetarian')) return /vegetarian|veggie|plant[- ]?based|vegan|meat[- ]?free/.test(text); if (k.includes('gluten')) return /gluten[- ]?free|celiac|gf\b/.test(text); return text.includes(k) }

function banConferenceHostelLodging(text: string, typesJoined: string): boolean {
  if (/conference|meeting room|meeting space|cowork|co-working|hostel|motel|business center|expo hall|convention center|office tower|auditorium|event venue|function room/i.test(text)) return true
  if (/(^|,)hostel(,|$)|(^|,)lodging(,|$)|(^|,)rv_park(,|$)/i.test(typesJoined)) return true
  return false
}

function filterByNamedFilter(places: PlaceCard[], filterName: string): PlaceCard[] {
  const f = filterName.toLowerCase().replace(/[^a-z_]/g, '')
  const textOf = (p: PlaceCard) => placeCardSearchText(p)
  const typesOf = (p: PlaceCard) => (p.types || []).map((t: string) => t.toLowerCase())

  if (f === 'kids_friendly' || f === 'family_friendly') {
    return places.filter(p => p.good_for_children === true || /kids menu|children welcome|family|playground|stroller|child[- ]?friendly/i.test(textOf(p)))
  }
  if (f === 'vegetarian') {
    return places.filter(p => p.serves_vegetarian_food === true || /vegetarian|veggie|plant[- ]?based|vegan|meat[- ]?free/.test(textOf(p)))
  }
  if (f === 'vegan') {
    return places.filter(p => /vegan|plant[- ]?based|plantbased/.test(textOf(p)))
  }
  if (f === 'pescatarian') {
    return places.filter(p => /pescatar|seafood|fish|sushi|ceviche|poke|oyster/i.test(textOf(p)))
  }
  if (f === 'halal') {
    return places.filter(p => /halal|muslim|islamic|turkish|kebab|kabab|döner|doner|shawarma|middle eastern|persian|arab|moroccan|lebanese|pakistani/.test(textOf(p)))
  }
  if (f === 'gluten_free') {
    return places.filter(p => /gluten[- ]?free|celiac|gf\b/.test(textOf(p)))
  }
  if (f === 'outdoor') {
    return places.filter(p => p.outdoor_seating === true || /outdoor terrace|beer garden|rooftop terrace|al fresco/i.test(textOf(p)))
  }
  if (f === 'budget') {
    return places.filter(p => (p.price_level ?? 99) <= 1 || /affordable|cheap eats|budget/i.test(textOf(p)))
  }
  if (f === 'lgbtq_friendly') {
    const re = /lgbtq|lgbt|gay|lesbian|queer|pride|rainbow|inclusive|drag|same[- ]?sex/i
    return places.filter(p => re.test(textOf(p)))
  }
  if (f === 'wheelchair_accessible' || f === 'wheelchair') {
    return places.filter(p => /wheelchair|accessible entrance|ramp|elevator|ada\b|disabled access|mobility/i.test(textOf(p)))
  }
  if (f === 'sensory_friendly' || f === 'sensory') {
    return places.filter(p => /sensory|autism|neurodiverse|low stimulation|quiet room|calm environment|soft lighting|sensory[- ]?friendly/i.test(textOf(p)))
  }
  if (f === 'senior_friendly' || f === 'senior') {
    return places.filter(p => /senior|elderly|accessible|easy access|elevator|classic|traditional/i.test(textOf(p)))
  }
  if (f === 'wifi') {
    return places.filter(p => /wifi|wi-?fi|wlan|free internet|wireless internet/i.test(textOf(p)))
  }
  if (f === 'parking') {
    return places.filter(p => /parking|car park|p\+r|park and ride|garage|parc?ing/i.test(textOf(p)))
  }
  if (f === 'charging') {
    return places.filter(p => /charging|power outlet|usb[- ]?c|socket|plug/i.test(textOf(p)))
  }
  if (f === 'credit_cards') {
    return places.filter(p => /card payment|credit card|debit|contactless|cashless|pin\b/i.test(textOf(p)))
  }
  if (f === 'quiet') {
    return places.filter(p => {
      const types = typesOf(p)
      const text = textOf(p)
      if (types.includes('night_club')) return false
      if (types.includes('bar') && !/wine bar|quiet|speakeasy|cocktail lounge/i.test(text)) return false
      return /quiet|peaceful|calm|cozy|intimate|reading|stud(y|ious)|low noise/i.test(text) ||
        ['library','museum','park','cafe','book_store','art_gallery'].some(t => types.includes(t))
    })
  }
  if (f === 'lively') {
    return places.filter(p => {
      const text = textOf(p)
      const types = typesOf(p)
      const typeHit = ['night_club','bar','food_court','meal_takeaway'].some(t => types.includes(t))
      return p.live_music === true ||
        /lively|buzzing|busy|crowd|energy|party|dance|dj\b|vibrant|food hall|street food|night market/i.test(text) ||
        (typeHit && /popular|busy|lively|vibrant|crowd|buzz/i.test(text))
    })
  }
  if (f === 'surprise_me' || f === 'surprise') {
    return places.filter(p => {
      const text = textOf(p)
      const tj = typesOf(p).join(',')
      return !banConferenceHostelLodging(text, tj)
    })
  }
  if (f === 'transit' || f === 'transport') {
    return places.filter(p => /station|metro|tram|bus stop|transit|ns station|centraal/i.test(textOf(p)) ||
      ['subway_station','train_station','transit_station','bus_station'].some(t => typesOf(p).includes(t)))
  }
  if (f === 'no_alcohol') {
    return places.filter(p => {
      const types = typesOf(p)
      const text = textOf(p)
      if (['bar','night_club','liquor_store'].some(t => types.includes(t)) && !/mocktail|non[- ]?alcoholic|soft drink|juice bar|0%|zero proof/i.test(text)) return false
      return true
    })
  }
  if (f === 'best_at_night') {
    return places.filter(p => {
      const types = typesOf(p)
      const text = textOf(p)
      if (p.best_time === 'evening') return true
      return /open late|late night|midnight|nightlife|evening|rooftop bar|cocktail/i.test(text) &&
        ['bar','night_club','restaurant','cafe'].some(t => types.includes(t))
    })
  }
  if (f === 'scenic_views') {
    return places.filter(p => /view|scenic|panoramic|vista|overlook|rooftop.*view|waterfront/i.test(textOf(p)) ||
      ['park','natural_feature','tourist_attraction','bridge','point_of_interest'].some(t => typesOf(p).includes(t)))
  }
  if (f === 'sunset' || f === 'best_at_sunset') {
    return places.filter(p => /sunset|golden hour|dusk|evening sky|rooftop terrace/i.test(textOf(p)))
  }
  if (f === 'romantic') {
    return places.filter(p => {
      const types = typesOf(p)
      const text = textOf(p)
      if (!['restaurant','bar','cafe','bakery','meal_takeaway'].some(t => types.includes(t))) return false
      return /romantic|candle|wine|sunset|waterfront|rooftop|date|intimate|valentine/i.test(text)
    })
  }
  if (f === 'artistic_design') {
    return places.filter(p => /design|architecture|gallery|concept|artistic|brutalist|minimal|sculptural/i.test(textOf(p)) ||
      ['art_gallery','museum','design_agency'].some(t => typesOf(p).includes(t)))
  }
  if (f === 'black_owned') {
    const re = /black[- ]?owned|blackowned|afro|african diaspora|soul food|ethiopian|ghanaian|nigerian|jamaican|caribbean restaurant|surinamese|surinaams|melanin|diaspora/i
    return places.filter(p => re.test(textOf(p)))
  }
  if (f === 'instagrammable') {
    const allow = new Set(['cafe','bakery','coffee_shop','restaurant','bar','ice_cream_shop','dessert_shop','art_gallery','spa','meal_takeaway'])
    return places.filter(p => {
      const text = textOf(p)
      const types = typesOf(p)
      const tj = types.join(' ')
      if (banConferenceHostelLodging(text, tj)) return false
      if (types.includes('gym') || types.includes('fitness_center')) return false
      const typeOk = types.some(t => allow.has(t))
      const vibe = /instagram|aesthetic|rooftop|terrace|view|natural light|interior|beautiful|scenic|minimal|plant|flower|boutique|pink|design|courtyard/i.test(text)
      return typeOk && vibe
    })
  }
  if (f === 'aesthetic_spaces') {
    const allow = new Set(['cafe','bakery','coffee_shop','restaurant','meal_takeaway','art_gallery','museum','park','botanical_garden','spa','library','tourist_attraction'])
    return places.filter(p => {
      const text = textOf(p)
      const types = typesOf(p)
      const tj = types.join(' ')
      if (banConferenceHostelLodging(text, tj)) return false
      if (types.includes('gym') || types.includes('fitness_center') || types.includes('lodging')) return false
      const typeOk = types.some(t => allow.has(t))
      const vibe = /aesthetic|instagram|natural light|plants|plant wall|terrace|rooftop|design|concept|boutique|scenic|bali|zen|earthy|minimal|daylight|studio|courtyard|interior/i.test(text)
      return typeOk && vibe
    })
  }
  if (f === 'walking_tours') {
    return places.filter(p => /walking tour|guided walk|city walk|architecture walk|free tour|self[- ]guided/i.test(textOf(p)) ||
      ['tourist_attraction','point_of_interest','historical_landmark'].some(t => typesOf(p).includes(t)))
  }
  if (f === 'museums_exhibitions') {
    return places.filter(p => /museum|gallery|exhibition|immersive|culture|art/i.test(textOf(p)) ||
      ['museum','art_gallery','cultural_center','performing_arts_theater'].some(t => typesOf(p).includes(t)))
  }
  if (f === 'boat_tours') {
    return places.filter(p => /boat|canal cruise|harbor cruise|water taxi|splash tour|river cruise/i.test(textOf(p)) ||
      ['marina','tourist_attraction'].some(t => typesOf(p).includes(t)))
  }
  if (f === 'landmarks_viewpoints') {
    return places.filter(p => /landmark|viewpoint|observation|iconic|must[- ]?see|panoramic/i.test(textOf(p)) ||
      ['historical_landmark','tourist_attraction','point_of_interest'].some(t => typesOf(p).includes(t)))
  }
  if (f === 'events_night_out') {
    return places.filter(p => /event|live music|concert|show|festival|comedy|night|cocktail workshop|party/i.test(textOf(p)) ||
      ['night_club','bar','performing_arts_theater'].some(t => typesOf(p).includes(t)))
  }
  return places
}

async function enrichAndFilter(input: PlaceCard[], thresholds: { minRating?: number; minReviews?: number } = {}): Promise<PlaceCard[]> { return input.filter(p => isPlaceValid(p, { minRating: thresholds.minRating ?? 4.0, minReviews: thresholds.minReviews ?? 8 })) }

async function checkCache(supabase: any, cacheKey: string): Promise<ExploreResponse | null> {
  try {
    const { data } = await supabase.from('places_cache').select('data,expires_at').eq('cache_key', cacheKey).is('place_id', null).maybeSingle()
    if (!data || new Date(data.expires_at) < new Date() || !data.data?.cards) return null
    const cards = data.data.cards as PlaceCard[]
    // #region agent log – H-A/H-B: are all cached photo_urls the same?
    const photoSample = cards.slice(0, 5).map(c => `${c.name}|${(c.photo_url ?? '').slice(40, 100)}`)
    const distinctPhotos = new Set(cards.map(c => c.photo_url ?? '')).size
    console.log(`🔍 dbg9a3a3b cache_hit key=${cacheKey} total=${cards.length} distinct_photos=${distinctPhotos} sample=[${photoSample.join(' ; ')}]`)
    // #endregion
    return { cards: shuffleArray(cards), cached: true, total_found: cards.length, cache_key: cacheKey }
  } catch { return null }
}

async function cacheExplore(supabase: any, cacheKey: string, places: PlaceCard[]): Promise<void> {
  try {
    // #region agent log – H-B: log distinct photo_urls when writing fresh cache
    const distinctPhotos = new Set(places.map(p => p.photo_url ?? '')).size
    const photoSample = places.slice(0, 3).map(p => `${p.name}|${(p.photo_url ?? '').slice(40, 100)}`)
    console.log(`💾 dbg9a3a3b cache_write key=${cacheKey} total=${places.length} distinct_photos=${distinctPhotos} sample=[${photoSample.join(' ; ')}]`)
    // #endregion
    const expiresAt = new Date()
    expiresAt.setDate(expiresAt.getDate() + 7)
    await supabase.from('places_cache').upsert({ cache_key: cacheKey, data: { cards: places }, place_id: null, user_id: null, request_type: 'explore', expires_at: expiresAt.toISOString() }, { onConflict: 'cache_key' })
  } catch (e) { console.error('❌ cacheExplore:', e) }
}

function applyFilters(places: PlaceCard[], filters: any): PlaceCard[] {
  if (!filters || Object.keys(filters).length === 0) return places
  const kwList = Array.isArray(filters.requiredKeywords) ? filters.requiredKeywords.filter((x: any) => typeof x === 'string' && x.trim()) : []
  return places.filter(place => { if (filters.rating && place.rating < filters.rating) return false; if (filters.priceLevel && place.price_level && place.price_level > filters.priceLevel) return false; if (filters.openNow === true && place.opening_hours?.open_now !== true) return false; if (filters.minReviews && (place.user_ratings_total || 0) < filters.minReviews) return false; if (kwList.length > 0) { const text = placeCardSearchText(place); for (const kw of kwList) { if (!placeMatchesRequiredKeyword(text, kw)) return false } } return true })
}

function detectChatPlaceIntent(message: string): { hasIntent: boolean } { const m = message.toLowerCase(); const kws = ['restaurant','cafe','coffee','bar','museum','park','gallery','eat','drink','visit','go to','find','recommend','suggestion','where','spot','place','food','lunch','dinner','breakfast','brunch','nightlife','pub','koffie','eten','drinken','bezoeken','vinden','aanbevelen','plek','eetplek','diner','ontbijt']; return { hasIntent: kws.some(kw => m.includes(kw)) } }

async function searchPlacesForChat(query: string, location: string, coordinates: { lat: number; lng: number }, userContext: any, languageCode: string): Promise<PlaceCard[]> {
  try { const results = await searchPlacesV1(`${query} in ${location}`, coordinates, 15000, false, 10, languageCode); const qualified = await enrichAndFilter(results, { minRating: 3.8, minReviews: 10 }); const ranked = rankPlaces(qualified, 'adventurous', !!userContext.isLocalMode, userContext.allInterests || [], userContext.tasteProfile); return enrichWithSignals(ranked.slice(0, 3), !!userContext.isLocalMode) } catch { return [] }
}

async function fetchUserContext(supabase: any, userId: string): Promise<any> {
  try {
    const [profileResult, prefsResult, checkInsResult, tasteResult] = await Promise.all([
      supabase.from('profiles').select('favorite_mood,travel_style,travel_vibes,currently_exploring,date_of_birth,language_preference').eq('id', userId).maybeSingle(),
      supabase.from('user_preferences').select('communication_style,travel_interests,selected_moods,social_vibe,planning_pace,favorite_moods,budget_level,dietary_restrictions,travel_styles,language_preference').eq('user_id', userId).maybeSingle(),
      supabase.from('user_check_ins').select('mood,created_at').eq('user_id', userId).order('created_at', { ascending: false }).limit(5),
      supabase.from('user_preference_patterns').select('saved_place_types,skipped_place_types,mood_frequency,top_rated_places,chat_interests,total_interactions').eq('user_id', userId).maybeSingle(),
    ])
    const p = profileResult.data, q = prefsResult.data, t = tasteResult.data
    const allFavoriteMoods = [...new Set([...(Array.isArray(q?.selected_moods) ? q.selected_moods : []), ...(Array.isArray(q?.favorite_moods) ? q.favorite_moods : [])])]
    const allInterests = [...new Set([...(Array.isArray(p?.travel_vibes) ? p.travel_vibes : []), ...(Array.isArray(q?.travel_interests) ? q.travel_interests : [])])]
    return { communicationStyle: q?.communication_style || 'friendly', isLocalMode: p?.currently_exploring === 'local', travelInterests: allInterests, allInterests, socialVibe: Array.isArray(q?.social_vibe) ? q.social_vibe : [], planningPace: q?.planning_pace || 'Same Day', favoriteMoods: allFavoriteMoods, allFavoriteMoods, travelStyle: p?.travel_style || 'adventurous', travelStyles: Array.isArray(q?.travel_styles) ? q.travel_styles : [], recentMoods: (checkInsResult.data || []).map((c: any) => c.mood), budgetLevel: q?.budget_level || 'Mid-Range', dietaryRestrictions: Array.isArray(q?.dietary_restrictions) ? q.dietary_restrictions : [], languagePreference: q?.language_preference || p?.language_preference || 'en', ageGroup: null, profile: p, tasteProfile: t ? { savedPlaceTypes: t.saved_place_types || {}, skippedPlaceTypes: t.skipped_place_types || {}, moodFrequency: t.mood_frequency || {}, topRatedPlaces: t.top_rated_places || [], chatInterests: t.chat_interests || [], totalInteractions: t.total_interactions || 0 } : null }
  } catch (e) { console.warn('⚠️ fetchUserContext failed:', e); return { communicationStyle: 'friendly', isLocalMode: false, travelInterests: [], allInterests: [], socialVibe: [], travelStyle: 'adventurous', travelStyles: [], recentMoods: [], favoriteMoods: [], allFavoriteMoods: [], budgetLevel: 'Mid-Range', dietaryRestrictions: [], languagePreference: 'en', ageGroup: null, profile: null, tasteProfile: null } }
}

async function fetchChatHistory(supabase: any, userId: string, limit = 20): Promise<Array<{ role: string; content: string }>> {
  try { const { data } = await supabase.from('ai_conversations').select('role,content,created_at').eq('user_id', userId).order('created_at', { ascending: false }).limit(limit); if (!data || data.length === 0) return []; return data.reverse().map((m: any) => ({ role: m.role === 'assistant' ? 'assistant' : 'user', content: String(m.content || '') })) } catch { return [] }
}

async function handleGetExplore(supabase: any, userId: string, params: any): Promise<Response> {
  try {
    if (!params.location?.trim()) return new Response(JSON.stringify({ error: 'Location is required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    if (!params.coordinates?.lat || !params.coordinates?.lng) return new Response(JSON.stringify({ error: 'Coordinates are required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const location = params.location.trim(), coordinates = params.coordinates, filters = params.filters || {}
    const groupMatch = params.group_match === true
    const namedFilters: string[] = Array.isArray(params.namedFilters) ? params.namedFilters.filter((f: any) => typeof f === 'string') : []
    const hasNamedFilters = namedFilters.length > 0
    const verboseFilterLogs = Deno.env.get('MOODY_VERBOSE_FILTER_LOGS') === 'true'
    const section: string | undefined = params.section
    const mood = params.mood || 'all'
    const isBroadFeed = !params.mood || params.mood === 'all' || params.mood === 'discover'
    const userContext = await fetchUserContext(supabase, userId)
    const modeKey = userContext.isLocalMode ? 'local' : 'travel'
    const timeCtx = getTimeOfDayContext()
    const lang = googlePlacesLanguageFromRequest(params)
    const cacheKey = lang === 'en' ? `explore_v8_${modeKey}_${section || mood}_${location.toLowerCase().trim()}` : `explore_v8_${modeKey}_${section || mood}_${location.toLowerCase().trim()}_${lang}`
    if (!hasNamedFilters && !groupMatch) { const cached = await checkCache(supabase, cacheKey); if (cached && cached.cards.length > 0) { const reranked = rankPlaces(cached.cards, mood, !!userContext.isLocalMode, userContext.allInterests || [], userContext.tasteProfile); const enriched = enrichWithSignals(applyFilters(reranked, filters), userContext.isLocalMode); return new Response(JSON.stringify({ ...cached, cards: enriched, filters_applied: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) } }
    const clientLang = clientOutputLang(params)
    let exploreQueries: string[]
    if (hasNamedFilters) exploreQueries = namedFilters.flatMap(f => getFilterSearchQueries(f)).slice(0, 16)
    else if (section === 'food') exploreQueries = userContext.isLocalMode ? ['neighbourhood restaurant','local food market','artisan bakery','specialty coffee','local bistro','neighbourhood cafe','local restaurant hidden gem'] : ['best restaurant city','food market artisan','famous bakery','specialty coffee','local cuisine','chef restaurant','food hall']
    else if (section === 'trending') exploreQueries = ['trending restaurant new opening','popular rooftop bar','new cafe opening','buzzing food spot','viral restaurant','popular new bar','hottest restaurant city']
    else if (section === 'solo' || section === 'social') { const vibe = userContext.socialVibe?.[0]?.toLowerCase() || ''; exploreQueries = vibe.includes('solo') || vibe.includes('alone') ? ['quiet museum','solo cafe reading','bookstore cafe','gallery solo visit','peaceful park','cozy cafe solo','museum hidden gem'] : vibe.includes('group') || vibe.includes('friends') ? ['group restaurant lively','rooftop bar groups','food hall social','live music bar','cocktail bar','fun bar groups','lively terrace'] : ['cafe cozy','restaurant casual','bar relaxed','park','museum','gallery','terrace'] }
    else if (section === 'different') exploreQueries = ['hidden gem restaurant','unusual cafe','underground bar','unique experience','street art neighbourhood','concept store cafe','unusual venue city']
    else if (isBroadFeed) { const base = getBroadExploreQueries(userContext.isLocalMode, userContext.allInterests || []); exploreQueries = [...timeCtx.queryBoost.map(q => `${q} in ${location}`), ...base].slice(0, 16) }
    else { const aiQ = await getMoodySearchQueries([mood], location, userContext, clientLang); exploreQueries = aiQ ?? getMoodQueries(mood) }
    let places = await fetchPlacesFromGoogle(location, coordinates, mood, filters, exploreQueries, hasNamedFilters, lang)
    if (!hasNamedFilters && places.length < 15) { const fb = await fetchFallbackPlaces(location, coordinates, lang); places = Array.from(new Map([...places, ...fb].map(p => [p.id, p])).values()) }
    places = places.slice(0, 100)
    if (hasNamedFilters) {
      if (verboseFilterLogs) {
        console.log(`🧪 named_filters start total=${places.length} filters=[${namedFilters.join(',')}]`)
      }
      for (const f of namedFilters) {
        const before = places.length
        places = filterByNamedFilter(places, f)
        const after = places.length
        if (verboseFilterLogs) {
          console.log(`🧪 named_filter slug=${f} before=${before} after=${after}`)
        }
      }
      if (verboseFilterLogs) {
        console.log(`🧪 named_filters done total=${places.length}`)
      }
    }
    const thresholds = hasNamedFilters ? { minRating: 4.0, minReviews: 12 } : { minRating: 4.0, minReviews: 8 }
    let qualified = await enrichAndFilter(places, thresholds)
    if (!hasNamedFilters && qualified.length < 8) qualified = await enrichAndFilter(places, { minRating: 3.5, minReviews: 5 })
    const ranked = rankPlaces(qualified, mood, !!userContext.isLocalMode, userContext.allInterests || [], userContext.tasteProfile)
    if (!hasNamedFilters && !groupMatch) { await cacheExplore(supabase, cacheKey, ranked) }
    const enriched = enrichWithSignals(applyFilters(shuffleArray(ranked), filters), userContext.isLocalMode)
    return new Response(JSON.stringify({ cards: enriched, cached: false, total_found: enriched.length, unfiltered_total: ranked.length, named_filters_applied: namedFilters, section: section || 'all', time_slot: timeCtx.timeSlot }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) { console.error('❌ handleGetExplore:', error); return new Response(JSON.stringify({ cards: [], cached: false, total_found: 0, error: 'explore_fetch_failed' }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

async function handleCreateDayPlan(supabase: any, userId: string, params: any): Promise<Response> {
  try {
    if (!params.location?.trim()) return new Response(JSON.stringify({ success: false, error: 'Location required', activities: [], total_found: 0 }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    if (!params.coordinates?.lat || !params.coordinates?.lng) return new Response(JSON.stringify({ success: false, error: 'Coordinates required', activities: [], total_found: 0 }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const quickPick = typeof params.quick_pick === 'string' ? params.quick_pick.toLowerCase().trim() : null
    const moods: string[] = params.moods || ['adventurous'], location = params.location.trim(), coordinates = params.coordinates
    const userContext = await fetchUserContext(supabase, userId)
    const lang = clientOutputLang(params), placesLang = googlePlacesLanguageFromRequest(params), timeCtx = getTimeOfDayContext()
    if (quickPick === 'coffee') {
      const coffeeQueries = [`specialty coffee shop ${location}`,`cafe coffee ${location}`,`matcha bar ${location}`,`coffee roastery ${location}`]
      let places = await fetchPlacesFromGoogle(location, coordinates, 'foodie', {}, coffeeQueries, false, placesLang)
      const isCannabisVenue = (p: PlaceCard): boolean => {
        const text = `${p.name || ''} ${p.primaryType || ''} ${(p.types || []).join(' ')}`.toLowerCase()
        return [
          'coffeeshop',
          'cannabis',
          'weed',
          'marihuana',
          'marijuana',
          'hash',
          'dispensary',
          'smartshop',
        ].some(k => text.includes(k))
      }
      const isCoffeeVenue = (p: PlaceCard): boolean => {
        const types = (p.types || []).map(t => t.toLowerCase())
        const primary = (p.primaryType || '').toLowerCase()
        const name = (p.name || '').toLowerCase()
        return (
          ['cafe','bakery','coffee_shop','patisserie'].some(t => types.includes(t) || primary === t) ||
          name.includes('coffee') ||
          name.includes('cafe') ||
          name.includes('matcha') ||
          name.includes('espresso')
        )
      }
      let cafes = places.filter(
        p =>
          !isCannabisVenue(p) &&
          isCoffeeVenue(p) &&
          !!p.photo_url?.trim() &&
          (p.rating || 0) >= 3.8 &&
          (p.user_ratings_total || 0) >= 10,
      )
      if (cafes.length === 0) {
        cafes = places.filter(
          p =>
            !isCannabisVenue(p) &&
            isCoffeeVenue(p) &&
            !!p.photo_url?.trim() &&
            (p.rating || 0) >= 3.5,
        )
      }
      if (cafes.length === 0) {
        cafes = places.filter(
          p => !isCannabisVenue(p) && isCoffeeVenue(p) && !!p.photo_url?.trim(),
        )
      }
      cafes.sort((a, b) => (b.rating || 0) - (a.rating || 0))
      const pick = cafes[0]
      if (!pick) return new Response(JSON.stringify({ success: false, activities: [], total_found: 0, error: 'No coffee place found' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      const now = new Date(), minutesAhead = 14 + Math.floor(Math.random() * 19), startTime = new Date(now.getTime() + minutesAhead * 60 * 1000)
      const activity: Activity = { id: `activity_${Date.now()}_${pick.id}`, name: pick.name, description: pick.editorial_summary || pick.description || (lang === 'nl' ? 'Goed koffieadres, dichtbij.' : 'Good coffee, close by.'), timeSlot: timeCtx.timeSlot, duration: 45, location: { latitude: pick.location.lat, longitude: pick.location.lng }, paymentType: 'reservation', imageUrl: pick.photo_url || '', rating: pick.rating, tags: ['Cafe'], startTime: startTime.toISOString(), priceLevel: pick.price_level != null ? (['','€','€€','€€€','€€€€'][pick.price_level] || '€€') : undefined, placeId: pick.id.replace('google_', '') }
      const moodyMessage = lang === 'nl' ? `Goed idee ☕ ${pick.name} is vlakbij.` : `Good call ☕ ${pick.name} is close by.`
      return new Response(JSON.stringify({ success: true, activities: [activity], location: { city: location, latitude: coordinates.lat, longitude: coordinates.lng }, total_found: 1, moodyMessage, reasoning: 'quick_pick:coffee' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }
    const aiQueries = await getMoodySearchQueries(moods, location, userContext, lang, timeCtx.timeSlot)
    let places = await fetchPlacesFromGoogle(location, coordinates, moods[0], params.filters || {}, aiQueries, false, placesLang)
    let qualified = await enrichAndFilter(places, { minRating: 3.8, minReviews: 20 })
    if (qualified.length === 0) qualified = await enrichAndFilter(places, { minRating: 3.5, minReviews: 8 })
    if (qualified.length === 0) return new Response(JSON.stringify({ success: false, activities: [], location: { city: location, latitude: coordinates.lat, longitude: coordinates.lng }, total_found: 0, error: 'No places found' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const ranked = rankPlaces(qualified, moods[0] || 'adventurous', !!userContext.isLocalMode, userContext.allInterests || [], userContext.tasteProfile)
    const activities = convertPlacesToActivities(ranked, moods, location, coordinates, lang)
    if (activities.length === 0) return new Response(JSON.stringify({ success: false, activities: [], location: { city: location, latitude: coordinates.lat, longitude: coordinates.lng }, total_found: 0, error: 'No activities generated' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const { moodyMessage, reasoning } = await getMoodyPersonalityResponse(moods, activities, location, userContext, lang)
    return new Response(JSON.stringify({ success: true, activities, location: { city: location, latitude: coordinates.lat, longitude: coordinates.lng }, total_found: activities.length, moodyMessage, reasoning }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) { console.error('❌ handleCreateDayPlan:', error); return new Response(JSON.stringify({ success: false, error: error instanceof Error ? error.message : String(error), activities: [], total_found: 0 }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

async function handleGroupMatchMoodyMessage(supabase: any, userId: string, params: any): Promise<Response> {
  const mood1 = String(params.mood1 || '').trim(), mood2 = String(params.mood2 || '').trim(), name1 = String(params.name1 || 'You').trim(), name2 = String(params.name2 || 'Your friend').trim(), location = String(params.location || '').trim(), lang = clientOutputLang(params)
  if (!mood1 || !mood2) return new Response(JSON.stringify({ success: false, error: 'mood1 and mood2 are required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  const compatibilityMap: Record<string, Record<string, number>> = { relaxed: { relaxed:95, foodie:78, energetic:35, adventurous:52, cultural:70, cozy:90, romantic:82, social:45, curious:65, excited:40, happy:75, surprise:60 }, foodie: { relaxed:78, foodie:95, energetic:62, adventurous:70, cultural:55, cozy:72, romantic:68, social:75, curious:60, excited:65, happy:80, surprise:72 }, energetic: { relaxed:35, foodie:62, energetic:95, adventurous:85, cultural:40, cozy:25, romantic:45, social:88, curious:55, excited:90, happy:78, surprise:70 }, adventurous: { relaxed:52, foodie:70, energetic:85, adventurous:95, cultural:65, cozy:42, romantic:58, social:72, curious:80, excited:82, happy:68, surprise:88 }, cultural: { relaxed:70, foodie:55, energetic:40, adventurous:65, cultural:95, cozy:62, romantic:60, social:48, curious:88, excited:52, happy:65, surprise:70 }, cozy: { relaxed:90, foodie:72, energetic:25, adventurous:42, cultural:62, cozy:95, romantic:85, social:38, curious:58, excited:32, happy:72, surprise:55 }, romantic: { relaxed:82, foodie:68, energetic:45, adventurous:58, cultural:60, cozy:85, romantic:95, social:55, curious:62, excited:50, happy:78, surprise:65 }, social: { relaxed:45, foodie:75, energetic:88, adventurous:72, cultural:48, cozy:38, romantic:55, social:95, curious:52, excited:85, happy:82, surprise:68 }, curious: { relaxed:65, foodie:60, energetic:55, adventurous:80, cultural:88, cozy:58, romantic:62, social:52, curious:95, excited:70, happy:65, surprise:85 }, excited: { relaxed:40, foodie:65, energetic:90, adventurous:82, cultural:52, cozy:32, romantic:50, social:85, curious:70, excited:95, happy:85, surprise:78 }, happy: { relaxed:75, foodie:80, energetic:78, adventurous:68, cultural:65, cozy:72, romantic:78, social:82, curious:65, excited:85, happy:95, surprise:75 }, surprise: { relaxed:60, foodie:72, energetic:70, adventurous:88, cultural:70, cozy:55, romantic:65, social:68, curious:85, excited:78, happy:75, surprise:95 } }
  const m1 = normaliseMood(mood1), m2 = normaliseMood(mood2), score = compatibilityMap[m1]?.[m2] ?? compatibilityMap[m2]?.[m1] ?? 70
  const scoreLabel = score >= 95 ? 'Perfect match ✨' : score >= 80 ? 'Great combo' : score >= 65 ? 'Good balance' : score >= 50 ? 'Interesting mix' : 'Moody got creative'
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  const getFallback = () => { if (lang === 'nl') { if (score >= 75) return { moodyMessage: `Jullie willen vandaag precies hetzelfde 😌 Dit plan maakte zich vanzelf.`, vibeLabel: `${m1} + ${m2}`, summary: `Goede match. Ik heb iets gevonden dat voor jullie beiden werkt.` }; if (score >= 50) return { moodyMessage: `Verschillende vibes, maar ik heb het geregeld. Vertrouw me.`, vibeLabel: `${m1} + ${m2}`, summary: `Twee vibes, één plan. Ik denk dat jullie het mooi gaan vinden.` }; return { moodyMessage: `Oké, dit was een uitdaging. Maar ik ben trots op dit plan. Jullie ook straks.`, vibeLabel: `${m1} + ${m2}`, summary: `Jullie zijn totaal anders vandaag. Dat maakt het interessant.` } }; if (score >= 75) return { moodyMessage: `You're basically the same person today 😌 This plan built itself.`, vibeLabel: `${m1} + ${m2}`, summary: `Great match. I found something that works for both of you.` }; if (score >= 50) return { moodyMessage: `Different vibes, but I made it work. Trust me on this one.`, vibeLabel: `${m1} + ${m2}`, summary: `Two moods, one plan. I think you'll both love it.` }; return { moodyMessage: `Okay this was a challenge. But I actually love what I found. You will too.`, vibeLabel: `${m1} + ${m2}`, summary: `You're pretty different today. That makes it interesting.` } }
  if (!openaiKey?.trim()) { const fb = getFallback(); return new Response(JSON.stringify({ success: true, score, scoreLabel, ...fb }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
  try {
    const langName = lang === 'nl' ? 'Dutch' : 'English'
    const prompt = `Two people are using WanderMood together. You are Moody.\n\nPerson 1 (${name1}): mood is "${m1}"\nPerson 2 (${name2}): mood is "${m2}"\nLocation: ${location || 'their city'}\nCompatibility score: ${score}/100\n\nWrite in ${langName}. Use "I" always. Be punchy, warm, real. No filler.\n\nReturn ONLY valid JSON:\n{\n  "moodyMessage": "<max 120 chars>",\n  "vibeLabel": "<max 25 chars>",\n  "summary": "<max 100 chars>"\n}`
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: MOODY_CORE_IDENTITY }, { role: 'user', content: prompt }], max_tokens: 200, temperature: 0.85, response_format: { type: 'json_object' } }) })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json(), parsed = JSON.parse(data.choices?.[0]?.message?.content || '{}')
    return new Response(JSON.stringify({ success: true, score, scoreLabel, moodyMessage: parsed.moodyMessage || getFallback().moodyMessage, vibeLabel: parsed.vibeLabel || getFallback().vibeLabel, summary: parsed.summary || getFallback().summary }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e) { console.error('❌ handleGroupMatchMoodyMessage:', e); const fb = getFallback(); return new Response(JSON.stringify({ success: true, score, scoreLabel, ...fb }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

async function handleGroupMatchActivityNotes(_supabase: any, _userId: string, params: any): Promise<Response> {
  const lang = clientOutputLang(params)
  const style = String(params.communication_style || 'friendly').toLowerCase()
  const rawActs = params.activities
  if (!Array.isArray(rawActs) || rawActs.length === 0) {
    return new Response(JSON.stringify({ notes: {} }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
  const langName = placeCardBlurbOutputLanguageName(String(params.language_code || 'en'))
  const styleHint = style === 'energetic' ? 'High energy, punchy.' : style === 'calm' ? 'Soft, understated.' : style === 'professional' ? 'Clean, direct.' : style === 'direct' ? 'One short clause per slot.' : 'Warm and friendly.'
  const bySlot: Record<string, any> = {}
  for (const a of rawActs) {
    const s = String((a as any)?.slot ?? '').toLowerCase().trim()
    if (s !== 'morning' && s !== 'afternoon' && s !== 'evening') continue
    if (!bySlot[s]) bySlot[s] = a
  }
  const getFallback = (): Record<string, string> => {
    const out: Record<string, string> = {}
    for (const s of ['morning', 'afternoon', 'evening'] as const) {
      const a = bySlot[s]
      const name = a ? String((a as any).name || '').trim() : ''
      if (!name) continue
      if (lang === 'nl') {
        out[s] = s === 'morning' ? `Ochtend bij ${name} — daar begin je goed ☀️` : s === 'afternoon' ? `Middag: ${name} — precies wat je zoekt.` : `Avond bij ${name} — relaxed.`
      } else {
        out[s] = s === 'morning' ? `Morning at ${name} — easy start ☀️` : s === 'afternoon' ? `${name} for the afternoon.` : `Evening at ${name}.`
      }
    }
    return out
  }
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) {
    return new Response(JSON.stringify({ notes: getFallback() }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
  try {
    const payload = JSON.stringify(bySlot)
    const prompt = `You are Moody (WanderMood). Write ONE ultra-short line per time slot for shared Mood Match plan cards.\n\nRules:\n- Return ONLY valid JSON: {"notes":{"morning":"<max 90 chars>","afternoon":"<max 90 chars>","evening":"<max 90 chars>"}}\n- Include a key ONLY for slots present in the input (morning / afternoon / evening).\n- Use "I" voice. Communication style: ${styleHint}\n- Entirely in ${langName}.\n- Never invent place names — use only names from the data.\n- No addresses, no star ratings.\n\nActivities (first pick per slot): ${payload}`
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: MOODY_CORE_IDENTITY }, { role: 'user', content: prompt }], max_tokens: 220, temperature: 0.75, response_format: { type: 'json_object' } }) })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json(), parsed = JSON.parse(data.choices?.[0]?.message?.content || '{}')
    const notesRaw = parsed.notes && typeof parsed.notes === 'object' ? parsed.notes : parsed
    const notes: Record<string, string> = {}
    if (notesRaw && typeof notesRaw === 'object') {
      for (const [k, v] of Object.entries(notesRaw as Record<string, unknown>)) {
        const key = k.toLowerCase().trim()
        const val = String(v ?? '').trim()
        if ((key === 'morning' || key === 'afternoon' || key === 'evening') && val) notes[key] = val.slice(0, 120)
      }
    }
    const fb = getFallback()
    for (const s of Object.keys(fb)) { if (!notes[s]) notes[s] = fb[s]! }
    return new Response(JSON.stringify({ notes }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e) {
    console.error('❌ handleGroupMatchActivityNotes:', e)
    return new Response(JSON.stringify({ notes: getFallback() }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
}

async function handlePlaceCardBlurb(params: Record<string, unknown>): Promise<Response> {
  const facts = typeof params.facts === 'string' ? params.facts.trim() : ''
  if (!facts || facts.length > 12000) return new Response(JSON.stringify({ success: false, error: 'invalid_facts', blurb: '' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  const outLang = placeCardBlurbOutputLanguageName(typeof params.languageCode === 'string' ? params.languageCode : 'en'), style = typeof params.communicationStyle === 'string' ? params.communicationStyle : 'friendly', openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return new Response(JSON.stringify({ success: false, error: 'openai_not_configured', blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: getMoodyCardBlurbPrompt(outLang, style) }, { role: 'user', content: `Write a card teaser using only these facts. Do not invent anything.\n\n${facts}` }], temperature: 0.8, max_tokens: 120 }) })
    if (!resp.ok) return new Response(JSON.stringify({ success: false, blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const data = await resp.json(); let blurb = String(data?.choices?.[0]?.message?.content || '').trim().replace(/^"|"$/g, ''); if (blurb.length > 300) blurb = `${blurb.slice(0, 280).trim()}…`
    return new Response(JSON.stringify({ success: true, blurb }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch { return new Response(JSON.stringify({ success: false, blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

async function handlePlaceDetailBlurb(params: Record<string, unknown>): Promise<Response> {
  const facts = typeof params.facts === 'string' ? params.facts.trim() : ''
  if (!facts || facts.length > 12000) return new Response(JSON.stringify({ success: false, error: 'invalid_facts', blurb: '' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  const outLang = placeCardBlurbOutputLanguageName(typeof params.languageCode === 'string' ? params.languageCode : 'en'), style = typeof params.communicationStyle === 'string' ? params.communicationStyle : 'friendly', openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return new Response(JSON.stringify({ success: false, error: 'openai_not_configured', blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: getMoodyDetailBlurbPrompt(outLang, style) }, { role: 'user', content: `Write a detail screen description using only these facts. Do not invent anything.\n\n${facts}` }], temperature: 0.8, max_tokens: 400 }) })
    if (!resp.ok) return new Response(JSON.stringify({ success: false, blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const data = await resp.json(); let blurb = String(data?.choices?.[0]?.message?.content || '').trim().replace(/^"|"$/g, ''); if (blurb.length > 1200) blurb = `${blurb.slice(0, 1180).trim()}…`
    return new Response(JSON.stringify({ success: true, blurb }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch { return new Response(JSON.stringify({ success: false, blurb: '' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

function parseExploreRichJsonContent(raw: string): { hook: string; sections: { title: string; body: string }[] } | null {
  const s = raw.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '').trim()
  try {
    const o = JSON.parse(s) as { hook?: unknown; sections?: unknown }, hook = typeof o.hook === 'string' ? o.hook.trim() : '', arr = Array.isArray(o.sections) ? o.sections : [], sections: { title: string; body: string }[] = []
    for (const item of arr) { if (!item || typeof item !== 'object') continue; const t = String((item as any).title ?? '').trim(), b = String((item as any).body ?? '').trim().replace(/\n+/g, ' '); if (t.length < 2 || b.length < 8) continue; sections.push({ title: t.slice(0, 120), body: b.slice(0, 520) }) }
    if (sections.length < 2 || sections.length > 6) return null
    return { hook: hook.slice(0, 200), sections }
  } catch { return null }
}

async function handlePlaceExploreRich(params: Record<string, unknown>): Promise<Response> {
  const facts = typeof params.facts === 'string' ? params.facts.trim() : ''
  if (!facts || facts.length > 12000) return new Response(JSON.stringify({ success: false, error: 'invalid_facts', hook: '', sections: [] }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  const outLang = placeCardBlurbOutputLanguageName(typeof params.languageCode === 'string' ? params.languageCode : 'en'), style = typeof params.communicationStyle === 'string' ? params.communicationStyle : 'friendly', openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return new Response(JSON.stringify({ success: false, error: 'openai_not_configured', hook: '', sections: [] }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: getMoodyExploreRichPrompt(outLang, style) }, { role: 'user', content: `Write JSON only using these facts. Do not invent anything.\n\n${facts}` }], response_format: { type: 'json_object' }, temperature: 0.6, max_tokens: 700 }) })
    if (!resp.ok) return new Response(JSON.stringify({ success: false, hook: '', sections: [] }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const data = await resp.json(), parsed = parseExploreRichJsonContent(String(data?.choices?.[0]?.message?.content || ''))
    if (!parsed || parsed.sections.length < 2) return new Response(JSON.stringify({ success: false, error: 'parse_failed', hook: '', sections: [] }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    return new Response(JSON.stringify({ success: true, hook: parsed.hook, sections: parsed.sections }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch { return new Response(JSON.stringify({ success: false, hook: '', sections: [] }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

async function getMoodySearchQueries(moods: string[], location: string, userContext: any, lang: 'nl' | 'en', timeSlot?: string): Promise<string[] | null> {
  const openaiKey = Deno.env.get('OPENAI_API_KEY'); if (!openaiKey?.trim()) return null
  const moodDefs: Record<string, string> = { relaxed: 'slow down, soft energy, cozy quiet spots — NOT gyms or spas', energetic: 'buzz, movement, lively areas, street food, food halls — NOT gyms', romantic: 'candlelit restaurants, waterfront dining, wine bars, sunset views', adventurous: 'hidden gems, underground bars, unusual venues, non-touristy spots', foodie: 'artisan bakeries, specialty coffee, authentic restaurants, food markets', cultural: 'museums, art galleries, heritage buildings, cultural centers', social: 'lively bars, rooftop bars, live music, cocktail bars, group-friendly spots', excited: 'rooftops with views, trending spots, buzzing popular places', curious: 'interactive museums, concept stores, hidden exhibitions, unusual cafes', cozy: 'cafes with sofas, small wine bars, candlelit spots, warm bakeries', happy: 'cute brunch spots, colorful cafes, sunny terraces, ice cream', surprise: 'mix of cozy cafe + authentic food + unusual experience + rooftop bar' }
  const moodDef = moods.map(m => normaliseMood(m)).map(m => moodDefs[m] || m).join(' + '), localHint = userContext.isLocalMode ? 'User is LOCAL — avoid tourist traps, prefer hidden gems, new openings, neighbourhood spots.' : 'User is TRAVELING — best of city, must-see iconic spots, mix of famous and local secrets.', diet = userContext.dietaryRestrictions?.length ? ` Dietary: ${userContext.dietaryRestrictions.join(', ')}.` : '', budget = userContext.budgetLevel && userContext.budgetLevel !== 'Mid-Range' ? ` Budget: ${userContext.budgetLevel}.` : '', timeHint = timeSlot ? ` Time of day: ${timeSlot}.` : ''
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: `${MOODY_CORE_IDENTITY}\n\n${localHint}\nGenerate 6-8 short Google Places text search queries as JSON: {"queries":["...","..."]}.\nQueries should feel like a real person searching Google Maps. Be diverse, specific to the mood. No markdown.` }, { role: 'user', content: `Mood: ${moodDef}. Location: ${location}. Interests: ${JSON.stringify(userContext.allInterests || [])}.${budget}${diet}${timeHint}` }], max_tokens: 220, temperature: 0.5, response_format: { type: 'json_object' } }) })
    if (!resp.ok) return null
    const data = await resp.json(), parsed = JSON.parse(data.choices?.[0]?.message?.content || '{}'), queries = Array.isArray(parsed.queries) ? parsed.queries.filter((q: any) => typeof q === 'string').slice(0, 8) : []
    return queries.length ? queries : null
  } catch { return null }
}

function formatUtcOffsetLabel(totalMinutes: number): string {
  const sign = totalMinutes >= 0 ? '+' : '-'
  const abs = Math.abs(totalMinutes)
  const h = Math.floor(abs / 60)
  const m = abs % 60
  return `UTC${sign}${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`
}

/** Device-local clock from the Flutter app — preferred over server time for chat. */
function resolveClientClockForChat(params: any): { clockBlock: string; timeSlot: 'morning' | 'afternoon' | 'evening'; moodTagsLine: string } {
  const d = typeof params.client_local_date_iso === 'string' ? params.client_local_date_iso.trim() : ''
  const t = typeof params.client_local_time_hm === 'string' ? params.client_local_time_hm.trim() : ''
  const wd = typeof params.client_weekday_en === 'string' ? params.client_weekday_en.trim() : ''
  const tz = typeof params.client_time_zone_name === 'string' ? params.client_time_zone_name.trim() : ''
  const tzId = typeof params.client_time_zone_id === 'string' ? params.client_time_zone_id.trim() : ''
  const offRaw = params.client_utc_offset_minutes
  const off = typeof offRaw === 'number' && Number.isFinite(offRaw) ? Math.trunc(offRaw as number) : null
  const planning = typeof params.planning_date_iso === 'string' ? params.planning_date_iso.trim() : ''

  let hour: number | null = null
  const hm = t.match(/^(\d{1,2}):(\d{2})$/)
  if (hm) {
    const h = parseInt(hm[1], 10)
    if (!Number.isNaN(h) && h >= 0 && h <= 23) hour = h
  }

  const fallback = getTimeOfDayContext().timeSlot
  let timeSlot: 'morning' | 'afternoon' | 'evening' = fallback
  if (hour !== null) {
    if (hour >= 5 && hour < 12) timeSlot = 'morning'
    else if (hour >= 12 && hour < 17) timeSlot = 'afternoon'
    else timeSlot = 'evening'
  }

  const lines: string[] = []
  if (d && t) {
    lines.push(`USER LOCAL NOW: ${wd ? `${wd} ` : ''}${d} ${t}${tz ? ` (${tz})` : ''}.`)
  }
  if (tzId) lines.push(`IANA time zone id (device): ${tzId}.`)
  if (off != null) lines.push(`User device UTC offset: ${formatUtcOffsetLabel(off)}.`)
  if (planning && planning !== d) {
    lines.push(`Planner / calendar focus date (may differ from "today" above): ${planning}.`)
  } else if (planning && !d) {
    lines.push(`Planner / calendar focus date: ${planning}.`)
  }
  const clockBlock = lines.join('\n')

  const moodsArr = Array.isArray(params.moods) ? (params.moods as unknown[]).filter((x): x is string => typeof x === 'string').slice(0, 6) : []
  const moodTagsLine = moodsArr.length > 0 ? `App mood tag(s): ${moodsArr.map(m => normaliseMood(String(m))).join(', ')}.` : ''

  return { clockBlock, timeSlot, moodTagsLine }
}

async function getMoodyPersonalityResponse(moods: string[], activities: Activity[], location: string, userContext: any, lang: 'nl' | 'en'): Promise<{ moodyMessage: string; reasoning: string }> {
  const style = String(userContext?.communicationStyle || 'friendly'), n = activities.length, m = moods.join(' & ')
  const fb: Record<string, Record<string, any>> = { nl: { energetic: { moodyMessage: `YO ik heb je dag gepland 🔥 ${n} activiteiten`, reasoning: 'Energie-mix.' }, professional: { moodyMessage: `Ik heb ${n} activiteiten voor je klaarstaan in ${location}.`, reasoning: 'Geselecteerd.' }, direct: { moodyMessage: `${n} activiteiten. Klaar.`, reasoning: 'Match.' }, calm: { moodyMessage: `Ik heb iets rustig voor je gepland ☀️`, reasoning: 'Rustige mix.' }, friendly: { moodyMessage: `Hey! Ik heb je ${m} dag gepland in ${location} 😊`, reasoning: 'Mooie mix.' } }, en: { energetic: { moodyMessage: `YO I planned your whole day 🔥 ${n} things, ${m} mode activated`, reasoning: 'High-energy picks.' }, professional: { moodyMessage: `I've lined up ${n} activities for you in ${location}.`, reasoning: 'Chosen for fit.' }, direct: { moodyMessage: `${n} activities. You're welcome.`, reasoning: 'Mood match.' }, calm: { moodyMessage: `I found something easy and good for you today ☀️`, reasoning: 'Calm mix.' }, friendly: { moodyMessage: `Hey! I planned your ${m} day in ${location} 😊`, reasoning: 'Nice mix.' } } }
  const fallback = (fb[lang] || fb.en)[style] || (fb[lang] || fb.en).friendly, openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return fallback
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: `${MOODY_CORE_IDENTITY}\n\nYou just planned someone's day. Write a short personal message in ${lang === 'nl' ? 'Dutch' : 'English'}. Use "I". Match the ${style} communication style. Return JSON only: {"moodyMessage":"<max 100 chars>","reasoning":"<max 60 chars>"}.` }, { role: 'user', content: `Mood: ${moods.join(', ')}. Location: ${location}. ${n} activities: ${activities.slice(0,3).map(a=>a.name).join(', ')}.` }], max_tokens: 150, temperature: 0.8, response_format: { type: 'json_object' } }) })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json(), parsed = JSON.parse(data.choices?.[0]?.message?.content || '{}')
    return { moodyMessage: parsed.moodyMessage || fallback.moodyMessage, reasoning: parsed.reasoning || fallback.reasoning }
  } catch { return fallback }
}

async function handleChat(supabase: any, userId: string, params: any): Promise<Response> {
  const message = (params.message || '').trim()
  if (!message) return new Response(JSON.stringify({ error: 'Message required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  const [userContext, chatHistory] = await Promise.all([fetchUserContext(supabase, userId), fetchChatHistory(supabase, userId, 20)])
  const userCity = params.location?.trim() || null, coordinates = params.coordinates as { lat: number; lng: number } | undefined, style = userContext.communicationStyle || 'friendly', lang = clientOutputLang(params), placesLang = googlePlacesLanguageFromRequest(params)
  const { clockBlock, timeSlot, moodTagsLine } = resolveClientClockForChat(params)
  const serverFallbackSlot = getTimeOfDayContext().timeSlot
  const timeBlock = clockBlock.length > 0
    ? `${clockBlock}\nUse this for greetings, same-day vs late-night tone, and whether "morning coffee" still makes sense. Effective time-of-day bucket for suggestions: ${timeSlot}.`
    : `Time of day (server fallback — app did not send device clock): ${serverFallbackSlot}.`
  let tasteContext = ''
  if (userContext.tasteProfile && userContext.tasteProfile.totalInteractions >= 3) { const topTypes = Object.entries(userContext.tasteProfile.savedPlaceTypes as Record<string,number>).sort((a, b) => b[1] - a[1]).slice(0, 3).map(([type]) => type); if (topTypes.length > 0) tasteContext = `\nThis user tends to save/like: ${topTypes.join(', ')}.`; if (userContext.tasteProfile.topRatedPlaces?.length > 0) tasteContext += ` They've completed activities and rated them positively.` }
  const systemPrompt = `${MOODY_CORE_IDENTITY}\n\nCommunication style: ${style}.\n${userCity ? `You are helping the user explore ${userCity} right now.` : 'You help users explore cities worldwide.'}\n${userContext.isLocalMode ? 'User is LOCAL — avoid tourist clichés, prefer hidden gems.' : `User is TRAVELING — best of ${userCity || 'the city'}, mix iconic with local secrets.`}\n${timeBlock}\n${moodTagsLine ? `${moodTagsLine}\n` : ''}User interests: ${JSON.stringify(userContext.allInterests)}\nDietary: ${userContext.dietaryRestrictions?.join(', ') || 'none'}\nBudget: ${userContext.budgetLevel}${tasteContext}\n\nYou have this user's conversation history. Use it naturally — like a friend who actually remembers. If they mentioned being tired, don't suggest a 5km walk. If they mentioned coffee, reference it. Never make it feel like a database lookup.\n\nMax 4 sentences. Ask max 1 question. NEVER invent place names. If you don't know real places, say: "I don't have specific spots for that right now — tap Explore to find real options nearby."\nReply in the same language the user writes in.`
  const openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey) return new Response(JSON.stringify({ reply: getFallbackChat(style, lang), conversationId: params.conversationId || `conv_${userId}_${Date.now()}`, suggested_places: [] }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  try {
    const historyMessages = chatHistory.length > 0 ? chatHistory : (params.history || []).slice(-10)
    const chatPromise = fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: systemPrompt }, ...historyMessages.slice(-20), { role: 'user', content: message }], max_tokens: 400, temperature: style === 'energetic' ? 0.9 : 0.82 }) })
    let placesPromise: Promise<PlaceCard[]> = Promise.resolve([])
    const { hasIntent } = detectChatPlaceIntent(message)
    if (hasIntent && userCity && coordinates) placesPromise = searchPlacesForChat(message, userCity, coordinates, userContext, placesLang)
    const [chatResp, suggestedPlaces] = await Promise.all([chatPromise, placesPromise])
    if (!chatResp.ok) throw new Error(`OpenAI ${chatResp.status}`)
    const data = await chatResp.json(), reply = data.choices?.[0]?.message?.content || getFallbackChat(style, lang), conversationId = params.conversationId || `conv_${userId}_${Date.now()}`
    supabase.from('ai_conversations').insert([{ user_id: userId, conversation_id: conversationId, role: 'user', content: message }, { user_id: userId, conversation_id: conversationId, role: 'assistant', content: reply }]).then(() => {}).catch(() => {})
    return new Response(JSON.stringify({ reply, conversationId, suggested_places: suggestedPlaces }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch { return new Response(JSON.stringify({ reply: getFallbackChat(style, lang), conversationId: params.conversationId || `conv_${userId}_${Date.now()}`, suggested_places: [] }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

function getFallbackChat(style: string, lang: 'nl' | 'en'): string { if (lang === 'nl') { switch (style) { case 'energetic': return 'YO even geduld! 🔥'; case 'professional': return 'Momenteel niet beschikbaar.'; case 'direct': return 'Even wachten.'; default: return 'Hey! Probeer het zo nog eens 😊' } }; switch (style) { case 'energetic': return 'YO hang on! 🔥'; case 'professional': return 'Currently unavailable.'; case 'direct': return 'Try again in a moment.'; default: return 'Hey! Try again in a sec 😊' } }

async function handleSearch(supabase: any, userId: string, params: any): Promise<Response> {
  const query = (params.query || '').trim(), location = (params.location || '').trim(), coordinates = params.coordinates
  if (!query) return new Response(JSON.stringify({ error: 'Query required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  if (!location || !coordinates?.lat || !coordinates?.lng) return new Response(JSON.stringify({ error: 'Location and coordinates required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  try { const results = await searchPlacesV1(`${query} in ${location}`, coordinates, 20000, false, 20, googlePlacesLanguageFromRequest(params)); const qualified = await enrichAndFilter(results, { minRating: 3.5, minReviews: 5 }); return new Response(JSON.stringify({ cards: qualified, total_found: qualified.length }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) } catch { return new Response(JSON.stringify({ cards: [], total_found: 0 }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
}

async function handleGenerateHubMessage(supabase: any, userId: string, params: Record<string, unknown>): Promise<Response> {
  const lang = clientOutputLang(params), moods = Array.isArray(params.current_moods) ? (params.current_moods as unknown[]).filter((m): m is string => typeof m === 'string') : [], timeOfDay = typeof params.time_of_day === 'string' && params.time_of_day.trim() ? params.time_of_day.trim() : (lang === 'nl' ? 'dag' : 'day')
  let activitiesCount = 0; const ac = params.activities_count; if (typeof ac === 'number' && Number.isFinite(ac)) activitiesCount = Math.max(0, Math.floor(ac)); else if (typeof ac === 'string') { const n = parseInt(ac, 10); if (!isNaN(n)) activitiesCount = Math.max(0, n) }
  const userContext = await fetchUserContext(supabase, userId), style = String(userContext.communicationStyle || 'friendly').toLowerCase(), moodStr = moods.join(' & ') || (lang === 'nl' ? 'jouw vibe' : 'your vibe')
  const fb: Record<string, Record<string, string>> = { nl: { energetic: activitiesCount > 0 ? `YO ik heb ${activitiesCount} ding${activitiesCount===1?'':'en'} voor je klaar 🔥` : `Nog niks? Ik zoek iets ${moodStr} voor je 🔥`, professional: activitiesCount > 0 ? `Ik heb ${activitiesCount} activiteit${activitiesCount===1?'':'en'} voor je gepland.` : 'Ik heb nog niets voor je gepland.', direct: activitiesCount > 0 ? `${activitiesCount} gepland.` : 'Geen plannen.', calm: activitiesCount > 0 ? `Ik heb iets leuks voor je klaar ☀️` : `Rustige dag? Ik zoek iets voor je ☀️`, friendly: activitiesCount > 0 ? `Hey! Ik heb ${activitiesCount} ding${activitiesCount===1?'':'en'} voor je klaarstaan 😊` : `Nog rustig? Ik zoek iets ${moodStr} voor je 😊` }, en: { energetic: activitiesCount > 0 ? `YO I got ${activitiesCount} thing${activitiesCount===1?'':'s'} lined up for you 🔥` : `Nothing yet? I'll find you something ${moodStr} 🔥`, professional: activitiesCount > 0 ? `I've planned ${activitiesCount} activit${activitiesCount===1?'y':'ies'} for you.` : "I haven't planned anything yet.", direct: activitiesCount > 0 ? `${activitiesCount} planned.` : 'No plans.', calm: activitiesCount > 0 ? `I found something good for you today ☀️` : `Quiet day? I'll find you something ☀️`, friendly: activitiesCount > 0 ? `Hey! I got ${activitiesCount} activit${activitiesCount===1?'y':'ies'} ready for you 😊` : `Quiet day? I'll find you something ${moodStr} 😊` } }
  const fallbackMessage = (fb[lang] || fb.en)[style] || (fb[lang] || fb.en).friendly, openaiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiKey?.trim()) return new Response(JSON.stringify({ message: fallbackMessage }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  try {
    const resp = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${openaiKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{ role: 'system', content: `${MOODY_CORE_IDENTITY}\n\nWrite ONE short home screen greeting in ${lang === 'nl' ? 'Dutch' : 'English'}. Communication style: ${style}. Use "I". Max 100 chars. Max 1 emoji. Activities planned: ${activitiesCount}. User mood: ${moodStr}. Time: ${timeOfDay}.` }, { role: 'user', content: JSON.stringify({ current_moods: moods, time_of_day: timeOfDay, activities_count: activitiesCount }) }], max_tokens: 80, temperature: 0.8 }) })
    if (!resp.ok) throw new Error(`OpenAI ${resp.status}`)
    const data = await resp.json(), text = (data.choices?.[0]?.message?.content || '').trim().replace(/^["']|["']$/g, '')
    if (text.length > 0 && text.length <= 280) return new Response(JSON.stringify({ message: text }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e) { console.error('❌ handleGenerateHubMessage:', e) }
  return new Response(JSON.stringify({ message: fallbackMessage }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
}

function convertPlacesToActivities(places: PlaceCard[], moods: string[], location: string, coordinates: { lat: number; lng: number }, lang: 'nl' | 'en'): Activity[] {
  const activities: Activity[] = [], used = new Set<string>(), morning: PlaceCard[] = [], afternoon: PlaceCard[] = [], evening: PlaceCard[] = []
  for (const p of places) { if (used.has(p.id)) continue; const slots = getTimeSlotsForPlace(p); if (slots.includes('morning')) morning.push(p); if (slots.includes('afternoon')) afternoon.push(p); if (slots.includes('evening')) evening.push(p) }
  const now = new Date(), today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const add = (pool: PlaceCard[], slot: string, h1: number, h2: number, count: number, pastH: number) => { let added = 0; for (const p of pool) { if (added >= count) break; if (used.has(p.id)) continue; used.add(p.id); const h = h1 + Math.floor(Math.random() * (h2 - h1)), mm = [0,15,30,45][Math.floor(Math.random() * 4)]; const st = new Date(today.getTime()); st.setHours(h, mm, 0, 0); if (now.getHours() >= pastH) st.setDate(st.getDate() + 1); activities.push(createActivity(p, slot, st, moods, lang)); added++ } }
  add(morning,'morning',7,10,3,11); add(afternoon,'afternoon',12,16,3,17); add(evening,'evening',17,20,3,21)
  return activities.sort((a,b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime())
}

function getTimeSlotsForPlace(place: PlaceCard): string[] {
  const slots: string[] = [], types = (place.types||[]).map(t=>t.toLowerCase()), name = place.name.toLowerCase(), primary = (place.primaryType||'').toLowerCase()
  if (['cafe','bakery','park','museum','art_gallery','library'].some(t=>types.includes(t)||primary===t) || name.includes('coffee')||name.includes('breakfast')||name.includes('brunch')) slots.push('morning')
  if (['restaurant','museum','art_gallery','tourist_attraction','food','cafe','park','shopping_mall'].some(t=>types.includes(t)||primary===t)) slots.push('afternoon')
  if (['restaurant','bar','night_club'].some(t=>types.includes(t)||primary===t) || name.includes('dinner')||name.includes('bar')||name.includes('bistro')) slots.push('evening')
  if (!slots.length) slots.push('afternoon')
  return slots
}

function createActivity(place: PlaceCard, timeSlot: string, startTime: Date, moods: string[], lang: 'nl' | 'en'): Activity {
  const placeId = place.id.replace('google_', ''), desc = place.editorial_summary || place.description || (lang==='nl' ? `${place.name} — een goede keuze voor je ${moods.join(' en ').toLowerCase()} dag.` : `${place.name} — a solid pick for your ${moods.join(' & ').toLowerCase()} day.`)
  const types = place.types || [], tags: string[] = []
  if (types.some(t=>['restaurant','food','food_court'].includes(t))) tags.push('Food'); if (types.some(t=>['spa','beauty_salon'].includes(t))) tags.push('Wellness'); if (types.some(t=>['museum','art_gallery'].includes(t))) tags.push(lang==='nl'?'Cultuur':'Culture'); if (types.some(t=>['park','natural_feature'].includes(t))) tags.push(lang==='nl'?'Buiten':'Outdoors'); if (types.some(t=>['bar','night_club'].includes(t))) tags.push('Nightlife'); if (types.some(t=>['cafe','bakery','coffee_shop'].includes(t))) tags.push('Cafe'); if (types.some(t=>['tourist_attraction','landmark'].includes(t))) tags.push(lang==='nl'?'Bezienswaardigheid':'Attraction')
  let duration = 60; if (types.includes('restaurant')) duration=90; else if (types.includes('museum')||types.includes('art_gallery')) duration=120; else if (types.includes('spa')) duration=90; else if (types.includes('cafe')||types.includes('bakery')) duration=45; else if (types.includes('bar')||types.includes('night_club')) duration=120
  let paymentType = 'free'; if (types.includes('museum')) paymentType='ticket'; else if (types.includes('restaurant')||types.includes('bar')||types.includes('spa')) paymentType='reservation'; else if (place.price_level) paymentType='reservation'
  return { id: `activity_${Date.now()}_${place.id}`, name: place.name, description: desc, timeSlot, duration, location: { latitude: place.location.lat, longitude: place.location.lng }, paymentType, imageUrl: place.photo_url||'', rating: place.rating, tags: tags.slice(0,2), startTime: startTime.toISOString(), priceLevel: place.price_level != null ? (['','€','€€','€€€','€€€€'][place.price_level]||'€€') : undefined, placeId }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '', supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    if (!supabaseUrl || !supabaseAnonKey) return new Response(JSON.stringify({ success: false, error: 'Server configuration error' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) return new Response(JSON.stringify({ success: false, error: 'Authentication required' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const token = authHeader.substring(7)
    const supabaseWithAuth = createClient(supabaseUrl, supabaseAnonKey, { global: { headers: { Authorization: authHeader, apikey: supabaseAnonKey } }, auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } })
    const { data: { user: authUser }, error: authError } = await supabaseWithAuth.auth.getUser(token)
    if (authError || !authUser) return new Response(JSON.stringify({ success: false, error: 'Authentication failed' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRegex.test(authUser.id)) return new Response(JSON.stringify({ success: false, error: 'Invalid user ID' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    let body: MoodyRequest
    try { body = await req.json() } catch { return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }) }
    const { action, ...params } = body
    if (!action) return new Response(JSON.stringify({ error: 'Action is required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const admin = getServiceSupabase(), rateKey = userRateKey(authUser.id), rateStarted = performance.now(), maxPerMin = Number(Deno.env.get('EDGE_RATE_MOODY_PER_MINUTE') ?? '60')
    if (admin) { const { allowed, currentCount } = await edgeRateLimitConsume(admin, rateKey, 'moody', maxPerMin); if (!allowed) { logApiInvocationFireAndForget(admin, { user_id: authUser.id, user_key: rateKey, function_slug: 'moody', operation: action, http_status: 429, duration_ms: Math.round(performance.now() - rateStarted), error_snippet: `rate_limit count=${currentCount}` }); return new Response(JSON.stringify({ success: false, error: 'rate_limit_exceeded', retry_after_seconds: 60 }), { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json', 'Retry-After': '60' } }) } }
    const traceStarted = performance.now()
    console.log(`🎯 Moody v97: action=${action}, userId=${authUser.id}`)
    return traceEdgeResponse(admin, { user_id: authUser.id, user_key: rateKey, function_slug: 'moody', operation: action }, traceStarted,
      (async (): Promise<Response> => {
        switch (action) {
          case 'get_explore': return await handleGetExplore(supabaseWithAuth, authUser.id, params)
          case 'create_day_plan': return await handleCreateDayPlan(supabaseWithAuth, authUser.id, params)
          case 'chat': return await handleChat(supabaseWithAuth, authUser.id, params)
          case 'generate_hub_message': return await handleGenerateHubMessage(supabaseWithAuth, authUser.id, params)
          case 'group_match_moody_message': return await handleGroupMatchMoodyMessage(supabaseWithAuth, authUser.id, params)
          case 'group_match_activity_notes': return await handleGroupMatchActivityNotes(supabaseWithAuth, authUser.id, params)
          case 'search': return await handleSearch(supabaseWithAuth, authUser.id, params)
          case 'place_card_blurb': return await handlePlaceCardBlurb(params)
          case 'place_detail_blurb': return await handlePlaceDetailBlurb(params)
          case 'place_explore_rich': return await handlePlaceExploreRich(params)
          default: return new Response(JSON.stringify({ error: `Invalid action: ${action}` }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
        }
      })(), corsHeaders)
  } catch (error) {
    console.error('❌ Moody error:', error)
    return new Response(JSON.stringify({ error: 'Internal server error', message: error instanceof Error ? error.message : String(error) }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
