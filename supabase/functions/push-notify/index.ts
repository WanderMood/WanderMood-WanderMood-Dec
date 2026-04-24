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

/// Mood Match events that require BOTH sender and recipient to be members of
/// the same group_sessions row. Any caller without a valid membership link
/// gets a 403 — previously anyone who could get an access token could spam
/// arbitrary Mood Match copy to any user.
const MOOD_MATCH_SESSION_EVENTS = new Set<string>([
  'guest_joined',
  'mood_locked',
  'plan_ready',
  'day_proposed',
  'day_accepted',
  'day_counter_proposed',
  'day_guest_declined_original',
  'swap_requested',
  'swap_accepted',
  'swap_declined',
  'swap_counter_proposed',
  'both_confirmed',
  'guest_left_session',
  'host_ended_session',
])

/// Events where the recipient is not yet a member, but the sender must be
/// (typically because they just created the session and are about to invite).
const MOOD_MATCH_SENDER_ONLY_SESSION_EVENTS = new Set<string>([
  'mood_match_invite',
])

const DEDUPE_WINDOW_SECONDS = 20

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
      return sub(nl ? 'Ik zag dat [name] met je wil plannen 👀 Zal ik jullie op weg helpen?' : 'I saw [name] wants to plan with you 👀 Want me to kick this off?', { name })
    case 'guest_joined':
      return sub(
        nl ? '[name] is erbij. Ik help jullie stap voor stap — jij mag eerst je vibe kiezen.' : '[name] joined. I will guide both of you — you pick your vibe first.',
        { name },
      )
    case 'mood_locked':
      return sub(
        nl ? '[name] heeft gekozen. Jouw beurt nu — wat voel je?' : "[name] locked their mood. Your turn now — what are you feeling?",
        { name },
      )
    case 'plan_ready':
      return sub(
        nl ? 'Jullie plan staat klaar. Ik heb alles netjes voor je klaargezet — check het even.' : "Your plan is ready. I lined everything up for you — take a look.",
        { name },
      )
    case 'day_proposed':
      return sub(
        nl ? '[name] stelt [day] voor. Past dat voor jou?' : '[name] suggested [day]. Does that work for you?',
        { name, day },
      )
    case 'day_accepted':
      return sub(
        nl ? '[name] bevestigde [day]. Kies nu je starttijd en ik regel de rest.' : '[name] confirmed [day]. Pick your start time and I will handle the rest.',
        { name, day },
      )
    case 'day_counter_proposed': {
      const previousDay = String(d.previous_day ?? d.previous_date ?? '').trim()
      const newDay = String(d.new_day ?? d.proposed_date ?? d.day ?? '').trim()
      return sub(
        nl
          ? '[name] kan niet op [previous_day]. Ze stellen [new_day] voor — past dat voor jou?'
          : "[name] can't do [previous_day]. They suggested [new_day] instead — does that work for you?",
        { name, previous_day: previousDay, new_day: newDay },
      )
    }
    case 'swap_counter_proposed':
      return sub(
        nl ? '[name] heeft een ander idee voor de [slot]. Ik heb het klaarstaan — jij beslist.' : '[name] suggested a different idea for the [slot]. I have it ready — your call.',
        { name, slot },
      )
    case 'swap_requested':
      return sub(
        nl ? '[name] wil de [slot] omwisselen. Ik heb hun voorstel voor je klaar.' : '[name] wants to swap the [slot]. I have their proposal ready for you.',
        { name, slot },
      )
    case 'swap_accepted':
      return sub(
        nl ? '[name] accepteerde je wissel. [slot] staat nu vast ✓' : '[name] accepted your swap. [slot] is now set ✓',
        { name, slot },
      )
    case 'swap_declined':
      return sub(
        nl ? '[name] houdt de originele keuze voor de [slot]. Ik laat het zo staan.' : '[name] kept the original for the [slot]. I will keep it as is.',
        { name, slot },
      )
    case 'both_confirmed':
      return nl
        ? 'Jullie dag is bevestigd. Kies je starttijd en ik ben klaar om je te begeleiden 🗓️'
        : "Your day is confirmed. Pick your start time and I am ready to guide you 🗓️"
    case 'guest_left_session':
      return sub(
        nl ? '[name] is uit deze Mood Match gegaan. Ik help je met de volgende stap.' : '[name] left this Mood Match. I can help you with the next step.',
        { name },
      )
    case 'host_ended_session':
      return sub(
        nl ? '[name] heeft deze Mood Match gestopt. Ik sta voor je klaar als je opnieuw wilt plannen.' : '[name] ended this Mood Match. I am here when you want to plan again.',
        { name },
      )
    case 'leaving_soon':
      return sub(
        nl ? '[place] is [minutes] minuten rijden. Ik zou nu vertrekken zodat je relaxed aankomt.' : '[place] is [minutes] minutes away. I would leave now so you arrive relaxed.',
        { place, minutes },
      )
    case 'confirm_tonight':
      return sub(nl ? '[place] om [time] — ga je nog? Ik kan je helpen voorbereiden.' : '[place] at [time] — still on tonight? I can help you prep.', { place, time })
    case 'rate_activity':
      return sub(
        nl ? 'Hoe was [place]? Als je me snel beoordeelt, plan ik morgen nog beter voor je.' : 'How was [place]? If you rate it quickly, I can plan even better for you tomorrow.',
        { place },
      )
    case 'morning_summary':
      return sub(
        nl ? 'Goedemorgen ☀️ Ik heb [n] dingen voor je vandaag. We starten met [firstActivity].' : 'Good morning ☀️ I lined up [n] things for today. We start with [firstActivity].',
        { n, firstActivity },
      )
    case 'weekend_nudge':
      return sub(
        nl ? '[day] is nog vrij. Zal ik iets leuks voor je weekend zoeken?' : "[day] is still open. Want me to find something fun for your weekend?",
        { day },
      )
    case 'milestone':
      return nl ? String(d.message_nl ?? d.message ?? '') : String(d.message_en ?? d.message ?? '')
    default:
      return nl ? 'Ik heb een update voor je klaargezet.' : 'I have an update ready for you.'
  }
}

function socialBody(nl: boolean, event: string, d: Record<string, unknown>): string {
  const name = String(d.sender_username ?? '').trim()
  switch (event) {
    case 'post_reaction':
      return sub(nl ? 'Ik zag dat [name] op je post reageerde.' : 'I saw [name] reacted to your post.', { name })
    case 'post_comment':
      return sub(nl ? 'Ik zag dat [name] een reactie achterliet op je bericht.' : 'I saw [name] commented on your post.', { name })
    case 'new_follower':
      return sub(nl ? '[name] volgt je nu. Ik dacht dat je dit meteen wilde weten.' : '[name] started following you. Thought you would want to know right away.', { name })
    default:
      return nl ? 'Ik heb een update voor je.' : 'I have an update for you.'
  }
}

function notificationCopy(
  nl: boolean,
  event: string,
  data: Record<string, unknown>,
): { title: string; body: string } {
  const isSocial = event === 'post_reaction' || event === 'post_comment' || event === 'new_follower'
  if (isSocial) return { title: 'Moody', body: socialBody(nl, event, data) }
  if (event === 'morning_summary' || event === 'weekend_nudge' || event === 'milestone') {
    return { title: 'Moody', body: planBody(nl, event, data) }
  }
  return { title: 'Moody', body: planBody(nl, event, data) }
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

function isRecord(v: unknown): v is Record<string, unknown> {
  return !!v && typeof v === 'object' && !Array.isArray(v)
}

async function hasRecentDuplicateRealtimeEvent(
  admin: any,
  recipientId: string,
  event: string,
  dataObj: Record<string, unknown>,
): Promise<boolean> {
  const sessionId = String(dataObj.session_id ?? '').trim()
  const sinceIso = new Date(Date.now() - DEDUPE_WINDOW_SECONDS * 1000).toISOString()

  try {
    // Newer schema (recipient_id / event_type / event_data)
    const { data: rows, error } = await admin
      .from('realtime_events')
      .select('id,event_data,created_at')
      .eq('recipient_id', recipientId)
      .eq('event_type', 'systemUpdate')
      .gte('created_at', sinceIso)
      .order('created_at', { ascending: false })
      .limit(30)
    if (!error && Array.isArray(rows)) {
      for (const row of rows) {
        const payloadRaw = (row as Record<string, unknown>).event_data
        if (!isRecord(payloadRaw)) continue
        const prevEvent = String(payloadRaw.event ?? '').trim()
        if (prevEvent != event) continue
        if (sessionId.length === 0) return true
        const prevSessionId = String(payloadRaw.session_id ?? '').trim()
        if (prevSessionId == sessionId) return true
      }
      return false
    }
  } catch {
    // Fall through to legacy schema query.
  }

  try {
    // Legacy schema (user_id / type / data)
    const { data: rows, error } = await admin
      .from('realtime_events')
      .select('id,data,created_at')
      .eq('user_id', recipientId)
      .eq('type', 'systemUpdate')
      .gte('created_at', sinceIso)
      .order('created_at', { ascending: false })
      .limit(30)
    if (error || !Array.isArray(rows)) return false
    for (const row of rows) {
      const payloadRaw = (row as Record<string, unknown>).data
      if (!isRecord(payloadRaw)) continue
      const prevEvent = String(payloadRaw.event ?? '').trim()
      if (prevEvent != event) continue
      if (sessionId.length === 0) return true
      const prevSessionId = String(payloadRaw.session_id ?? '').trim()
      if (prevSessionId == sessionId) return true
    }
  } catch {
    return false
  }
  return false
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
    persist_in_app?: boolean
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

  // Refuse self-pushes — caller cannot notify themselves through this edge.
  // Genuine in-app feedback is local, and this keeps the attack surface
  // smaller (no "pretend the other person pinged me" spoof).
  if (recipientId === user.id) {
    return new Response(JSON.stringify({ success: false, error: 'self_push_forbidden' }), {
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

      // ------------------------------------------------------------------
      // AUTHORIZATION: Mood Match events must prove a legitimate session link
      // between the sender (authenticated user) and the recipient. Without
      // this check, any user could call `push-notify` with recipient_id=X and
      // event='day_proposed' to deliver arbitrary Mood Match copy to X.
      // ------------------------------------------------------------------
      const dataObj: Record<string, unknown> =
        bodyJson.data && typeof bodyJson.data === 'object'
          ? (bodyJson.data as Record<string, unknown>)
          : {}
      const sessionId = String(dataObj.session_id ?? '').trim()

      const requiresSession =
        MOOD_MATCH_SESSION_EVENTS.has(event) ||
        MOOD_MATCH_SENDER_ONLY_SESSION_EVENTS.has(event)

      if (requiresSession) {
        if (!UUID_RE.test(sessionId)) {
          return new Response(
            JSON.stringify({ success: false, error: 'session_id_required' }),
            {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            },
          )
        }

        // Sender must always be a member of the session.
        const { data: senderRow, error: senderErr } = await admin
          .from('group_session_members')
          .select('user_id')
          .eq('session_id', sessionId)
          .eq('user_id', user.id)
          .maybeSingle()
        if (senderErr || !senderRow) {
          console.warn(
            `[push-notify] sender=${user.id} not a member of session=${sessionId} event=${event}`,
          )
          return new Response(
            JSON.stringify({ success: false, error: 'not_session_member' }),
            {
              status: 403,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            },
          )
        }

        // For non-invite events, recipient must also be a member — this is
        // how we prevent strangers from blasting Mood Match updates at any
        // user whose uuid they happen to know.
        if (MOOD_MATCH_SESSION_EVENTS.has(event)) {
          const { data: recipRow, error: recipErr } = await admin
            .from('group_session_members')
            .select('user_id')
            .eq('session_id', sessionId)
            .eq('user_id', recipientId)
            .maybeSingle()
          if (recipErr || !recipRow) {
            console.warn(
              `[push-notify] recipient=${recipientId} not a member of session=${sessionId} event=${event}`,
            )
            return new Response(
              JSON.stringify({
                success: false,
                error: 'recipient_not_session_member',
              }),
              {
                status: 403,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              },
            )
          }
        }
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
      const { title, body: notifBody } = notificationCopy(nl, event, dataObj)
      const shouldPersistInApp = bodyJson.persist_in_app !== false
      const duplicate = await hasRecentDuplicateRealtimeEvent(
        admin,
        recipientId,
        event,
        dataObj,
      )
      if (duplicate) {
        return new Response(
          JSON.stringify({
            success: true,
            deduped: true,
            sent: 0,
            attempted: 0,
            message: 'duplicate_suppressed',
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
      if (shouldPersistInApp) {
        try {
          await admin.rpc('send_realtime_notification', {
            target_user_id: recipientId,
            event_type: 'systemUpdate',
            event_title: title,
            event_message: notifBody,
            event_data: dataObj,
            source_user_id: user.id,
            related_post_id: null,
            priority_level: 3,
          })
        } catch (e) {
          console.warn('[push-notify] realtime mirror failed:', e)
        }
      }
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
