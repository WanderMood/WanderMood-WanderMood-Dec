import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: corsHeaders }
    )
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return new Response(
      JSON.stringify({ error: 'Missing or invalid Authorization header' }),
      { status: 401, headers: corsHeaders }
    )
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  if (!serviceRoleKey) {
    console.error('SUPABASE_SERVICE_ROLE_KEY is not set')
    return new Response(
      JSON.stringify({ error: 'Server configuration error' }),
      { status: 500, headers: corsHeaders }
    )
  }

  try {
    // Verify the requesting user with their JWT (anon client)
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user }, error: userError } = await userClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', detail: userError?.message }),
        { status: 401, headers: corsHeaders }
      )
    }

    const userId = user.id
    console.log('🗑️ Delete user request for:', userId)

    const adminClient = createClient(supabaseUrl, serviceRoleKey)

    // Remove FCM rows server-side (client DELETE may fail under RLS). Do this before
    // auth deletion so push-notify cannot target this user/device mapping.
    const { error: pushTokErr } = await adminClient.from('push_tokens').delete().eq('user_id', userId)
    if (pushTokErr) {
      console.warn('push_tokens cleanup:', pushTokErr.message)
    }

    // Delete the auth user using service role (only way to remove from auth.users)
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId)

    if (deleteError) {
      console.error('Delete user error:', deleteError)
      return new Response(
        JSON.stringify({ error: 'Failed to delete account', detail: deleteError.message }),
        { status: 400, headers: corsHeaders }
      )
    }

    console.log('✅ Auth user deleted:', userId)
    return new Response(
      JSON.stringify({ success: true, message: 'Account deleted' }),
      { status: 200, headers: corsHeaders }
    )
  } catch (e) {
    console.error('delete-user unexpected error:', e)
    return new Response(
      JSON.stringify({ error: 'Internal server error', detail: String(e) }),
      { status: 500, headers: corsHeaders }
    )
  }
})
