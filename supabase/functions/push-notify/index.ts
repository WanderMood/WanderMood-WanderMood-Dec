import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT, importPKCS8 } from 'https://esm.sh/jose@5.2.0'
import {
  edgeRateLimitConsume,
  getServiceSupabase,
  logApiInvocationFireAndForget,
  traceEdgeResponse,
  userRateKey,
} from '../_shared/edge_guard.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

type ServiceAccount = {
  project_id: string
  client_email: string
  private_key: string
}

function sub(tpl: string, vars: Record<string, string>): string {
  let s = tpl
  for (const [k, v] of Object.entries(vars)) s = s.replaceAll(`[${k}]`, v)
  return s
}

function planBody(nl: boolean, event: string, d: Record<string, unknown>): string {
  const name = String(d.sender_username ?? d.proposed_by_username ?? '').trim()
  const place = String(d.place ?? d.proposed_place_name ?? d.proposedPlaceName ?? '').trim()
  const day = String(d.day ?? d.proposed_date ?? '').trim()
  const slot = String(d.slot ?? '').trim()
  const minutes = String(d.minutes ?? '').trim()
  const time = String(d.time ?? '').trim()
  const firstActivity = String(d.firstActivity ?? '').trim()
  const n = String(d.n ?? '').trim()
  switch (event) {
    case 'mood_match_invite':
      return sub(nl ? '[name] wil een dag plannen met je 👀 Doe je mee?' : '[name] wants to plan a day with you 👀 You in?', { name })
    case 'guest_joined':
      return sub(
        nl ? '[name] is erbij. Jullie kiezen allebei een vibe — jij eerst.' : '[name] joined. You both pick a mood — go first.',
        { name },
      )
    case 'mood_locked':
      return sub(
        nl ? '[name] heeft gekozen. Jouw beurt — wat is jouw vibe?' : "[name] locked in their mood. Your turn — what's yours?",
        { name },
      )
    case 'plan_ready':
      return sub(
        nl ? 'Jullie dag staat klaar. [name] heeft 3 plekken gekozen — kijk maar.' : 'Your day is ready. [name] picked 3 spots — take a look.',
        { name },
      )
    case 'day_proposed':
      return sub(
        nl ? '[name] stelt [day] voor. Komt dat uit?' : '[name] suggested [day] for your day out. Works for you?',
        { name, day },
      )
    case 'day_accepted':
      return sub(
        nl ? '[name] bevestigde [day]. Kies nu jouw starttijd.' : '[name] confirmed [day]. Now pick your start time.',
        { name, day },
      )
    case 'day_counter_proposed': {
      const previousDay = String(d.previous_day ?? d.previous_date ?? '').trim()
      const newDay = String(d.new_day ?? d.proposed_date ?? d.day ?? '').trim()
      return sub(
        nl
          ? '[name] kan niet op [previous_day]. Ze stellen [new_day] voor — komt dat uit?'
          : "[name] can't do [previous_day]. They suggested [new_day] instead — works for you?",
        { name, previous_day: previousDay, new_day: newDay },
      )
    }
    case 'swap_counter_proposed':
      return sub(
        nl ? '[name] heeft een ander idee voor de [slot]. Kijk maar — jij beslist.' : '[name] suggested a different activity for the [slot]. Take a look — your call.',
        { name, slot },
      )
    case 'swap_requested':
      return sub(
        nl ? '[name] wil de [slot] omwisselen. Ze hebben een idee — jij beslist.' : '[name] wants to swap the [slot]. They have an idea — your call.',
        { name, slot },
      )
    case 'swap_accepted':
      return sub(
        nl ? '[name] accepteerde jouw wissel. [slot] is geregeld ✓' : '[name] said yes to your swap. [slot] is sorted ✓',
        { name, slot },
      )
    case 'swap_declined':
      return sub(
        nl ? '[name] hield de originele keuze voor de [slot]. Prima.' : '[name] kept the original for the [slot]. Fair enough.',
        { name, slot },
      )
    case 'both_confirmed':
      return nl
        ? 'Jullie dag is bevestigd. Kies je starttijd en je bent klaar 🗓️'
        : "Your day is locked. Pick your start time and you're ready 🗓️"
    case 'leaving_soon':
      return sub(
        nl ? '[place] is [minutes] minuten rijden. Het kan slim zijn om nu te gaan.' : '[place] is [minutes] minutes away. Might be worth leaving now.',
        { place, minutes },
      )
    case 'confirm_tonight':
      return sub(nl ? '[place] om [time] — ga je nog?' : '[place] at [time] — still on for tonight?', { place, time })
    case 'rate_activity':
      return sub(
        nl ? 'Hoe was [place]? Een snelle beoordeling helpt me beter plannen.' : 'How was [place]? Quick rating helps me plan better for you.',
        { place },
      )
    case 'morning_summary':
      return sub(
        nl ? 'Goedemorgen. [n] dingen gepland vandaag. Eerst [firstActivity].' : 'Good morning. [n] things planned today. [firstActivity] first.',
        { n, firstActivity },
      )
    case 'weekend_nudge':
      return sub(
        nl ? 'Nog niks gepland voor het weekend. [day] is nog vrij — zal ik iets zoeken?' : "Nothing planned for the weekend yet. [day]'s wide open — want me to find something?",
        { day },
      )
    case 'milestone':
      return nl ? String(d.message_nl ?? d.message ?? '') : String(d.message_en ?? d.message ?? '')
    default:
      return nl ? 'Er is een update voor je Mood Match.' : "There's a Mood Match update."
  }
}

function socialBody(nl: boolean, event: string, d: Record<string, unknown>): string {
  const name = String(d.sender_username ?? '').trim()
  switch (event) {
    case 'post_reaction':
      return sub(nl ? '[name] reageerde op je post.' : '[name] reacted to your post.', { name })
    case 'post_comment':
      return sub(nl ? '[name] reageerde op je bericht.' : '[name] commented on your post.', { name })
    case 'new_follower':
      return sub(nl ? '[name] volgt je nu.' : '[name] started following you.', { name })
    default:
      return nl ? 'Je hebt een melding.' : 'You have an update.'
  }
}

function notificationCopy(
  nl: boolean,
  event: string,
  data: Record<string, unknown>,
): { title: string; body: string } {
  const isSocial = event === 'post_reaction' || event === 'post_comment' || event === 'new_follower'
  if (isSocial) return { title: 'WanderMood', body: socialBody(nl, event, data) }
  if (event === 'morning_summary' || event === 'weekend_nudge' || event === 'milestone') {
    return { title: nl ? 'Moody' : 'Moody', body: planBody(nl, event, data) }
  }
  return { title: 'Mood Match', body: planBody(nl, event, data) }
}

function parseServiceAccount(raw: string | undefined): ServiceAccount {
  if (!raw?.trim()) throw new Error('FCM_SERVICE_ACCOUNT_JSON is not set')
  const sa = JSON.parse(raw) as ServiceAccount
  if (!sa.project_id || !sa.client_email || !sa.private_key) {
    throw new Error('FCM_SERVICE_ACCOUNT_JSON missing project_id, client_email, or private_key')
  }
  return sa
}

async function googleAccessToken(sa: ServiceAccount): Promise<string> {
  const pem = sa.private_key.replace(/\\n/g, '\n')
  const key = await importPKCS8(pem, 'RS256')
  const jwt = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt()
    .setExpirationTime('35m')
    .sign(key)

  const tr = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })
  const tj = (await tr.json()) as { access_token?: string; error?: string; error_description?: string }
  if (!tj.access_token) {
    throw new Error(tj.error_description || tj.error || 'Google OAuth token exchange failed')
  }
  return tj.access_token
}

function fcmDataStrings(
  event: string,
  data: Record<string, unknown>,
): Record<string, string> {
  const out: Record<string, string> = { event: String(event) }
  for (const [k, v] of Object.entries(data)) {
    if (v == null) continue
    out[k] = typeof v === 'string' ? v : JSON.stringify(v)
  }
  return out
}

async function sendFcmV1(
  accessToken: string,
  projectId: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ ok: boolean; status: number; text: string }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          apns: {
            payload: {
              aps: { sound: 'default' },
            },
          },
          android: { priority: 'HIGH' },
        },
      }),
    },
  )
  const text = await res.text()
  return { ok: res.ok, status: res.status, text: text.slice(0, 500) }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: { user }, error: userError } = await userClient.auth.getUser()
  if (userError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  let bodyJson: {
    recipient_id?: string
    event?: string
    lang?: string
    data?: Record<string, unknown>
  }
  try {
    bodyJson = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const recipientId = bodyJson.recipient_id?.trim() ?? ''
  const event = bodyJson.event?.trim() ?? ''
  if (!UUID_RE.test(recipientId) || !event) {
    return new Response(JSON.stringify({ error: 'recipient_id and event are required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const admin = getServiceSupabase()
  const rateKey = userRateKey(user.id)
  const rateStarted = performance.now()
  const maxPerMin = Number(Deno.env.get('EDGE_RATE_PUSH_NOTIFY_PER_MINUTE') ?? '45')
  if (admin) {
    const { allowed, currentCount } = await edgeRateLimitConsume(admin, rateKey, 'push-notify', maxPerMin)
    if (!allowed) {
      logApiInvocationFireAndForget(admin, {
        user_id: user.id,
        user_key: rateKey,
        function_slug: 'push-notify',
        operation: event,
        http_status: 429,
        duration_ms: Math.round(performance.now() - rateStarted),
        error_snippet: `rate_limit count=${currentCount}`,
      })
      return new Response(
        JSON.stringify({ success: false, error: 'rate_limit_exceeded' }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json', 'Retry-After': '60' } },
      )
    }
  }

  const traceStarted = performance.now()
  return traceEdgeResponse(
    admin,
    { user_id: user.id, user_key: rateKey, function_slug: 'push-notify', operation: event },
    traceStarted,
    (async (): Promise<Response> => {
      let sa: ServiceAccount
      try {
        sa = parseServiceAccount(Deno.env.get('FCM_SERVICE_ACCOUNT_JSON'))
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e)
        console.error('[push-notify]', msg)
        return new Response(JSON.stringify({ success: false, error: 'fcm_not_configured', message: msg }), {
          status: 503,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      if (!admin) {
        return new Response(JSON.stringify({ success: false, error: 'server_misconfigured' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      const { data: rows, error: tokErr } = await admin
        .from('push_tokens')
        .select('token')
        .eq('user_id', recipientId)

      if (tokErr) {
        console.error('[push-notify] push_tokens:', tokErr.message)
        return new Response(JSON.stringify({ success: false, error: 'db_error' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      const tokens = (rows ?? []).map((r) => String(r.token ?? '').trim()).filter((t) => t.length > 8)
      if (tokens.length === 0) {
        return new Response(JSON.stringify({ success: true, sent: 0, message: 'no_tokens' }), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      const nl = (bodyJson.lang ?? 'en').toLowerCase().startsWith('nl')
      const dataObj = bodyJson.data && typeof bodyJson.data === 'object' ? bodyJson.data : {}
      const { title, body: notifBody } = notificationCopy(nl, event, dataObj)
      const dataStrings = fcmDataStrings(event, dataObj)
      dataStrings.sender_id = user.id

      const accessToken = await googleAccessToken(sa)
      let sent = 0
      const failures: string[] = []
      for (const t of tokens) {
        const r = await sendFcmV1(accessToken, sa.project_id, t, title, notifBody, dataStrings)
        if (r.ok) sent++
        else failures.push(`${r.status}: ${r.text}`)
      }

      return new Response(
        JSON.stringify({
          success: true,
          sent,
          attempted: tokens.length,
          failures: failures.length ? failures : undefined,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    })(),
    corsHeaders,
  )
})
