import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/** Service-role client for server routes only (admin stats, Stripe webhook). */
export function createSupabaseAdmin(): SupabaseClient | null {
  const url = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceKey) return null;
  return createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
