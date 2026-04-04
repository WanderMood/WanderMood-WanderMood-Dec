/**
 * Rate limiting + api_invocations logging for Supabase Edge Functions.
 * Requires SUPABASE_SERVICE_ROLE_KEY in function secrets for DB RPC + inserts.
 * Without it: limits and logging are skipped (fail-open).
 */
import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

export type ApiInvocationRow = {
  user_id: string | null;
  user_key: string;
  function_slug: string;
  operation?: string | null;
  http_status: number;
  duration_ms: number;
  error_snippet?: string | null;
};

export function getServiceSupabase(): SupabaseClient | null {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function userRateKey(userId: string): string {
  return `user:${userId}`;
}

/** Prefer cf-connecting-ip / x-forwarded-for first hop; fallback "unknown". */
export function clientIp(req: Request): string {
  const cf = req.headers.get("cf-connecting-ip");
  if (cf?.trim()) return cf.trim();
  const fwd = req.headers.get("x-forwarded-for");
  if (fwd?.trim()) return fwd.split(",")[0].trim();
  const real = req.headers.get("x-real-ip");
  if (real?.trim()) return real.trim();
  return "unknown";
}

export async function edgeRateLimitConsume(
  admin: SupabaseClient,
  userKey: string,
  functionSlug: string,
  maxPerMinute: number,
): Promise<{ allowed: boolean; currentCount: number }> {
  const { data, error } = await admin.rpc("edge_rate_limit_consume", {
    p_user_key: userKey,
    p_function_slug: functionSlug,
    p_max_per_minute: maxPerMinute,
  });
  if (error) {
    console.error("[edge_guard] edge_rate_limit_consume RPC failed:", error.message);
    return { allowed: true, currentCount: 0 };
  }
  const row = Array.isArray(data) ? data[0] : data;
  const allowed = row?.allowed !== false;
  const currentCount = typeof row?.current_count === "number" ? row.current_count : 0;
  return { allowed, currentCount };
}

export function logApiInvocationFireAndForget(
  admin: SupabaseClient | null,
  row: ApiInvocationRow,
): void {
  if (!admin) return;
  admin
    .from("api_invocations")
    .insert({
      user_id: row.user_id,
      user_key: row.user_key,
      function_slug: row.function_slug,
      operation: row.operation ?? null,
      http_status: row.http_status,
      duration_ms: row.duration_ms,
      error_snippet: row.error_snippet?.slice(0, 500) ?? null,
    })
    .then(({ error }) => {
      if (error) console.error("[edge_guard] api_invocations insert:", error.message);
    });
}

export async function traceEdgeResponse(
  admin: SupabaseClient | null,
  baseMeta: Omit<ApiInvocationRow, "http_status" | "duration_ms" | "error_snippet">,
  startedMs: number,
  work: Promise<Response>,
  responseHeaders: Record<string, string> = {},
): Promise<Response> {
  try {
    const res = await work;
    logApiInvocationFireAndForget(admin, {
      ...baseMeta,
      http_status: res.status,
      duration_ms: Math.max(0, Math.round(performance.now() - startedMs)),
    });
    return res;
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logApiInvocationFireAndForget(admin, {
      ...baseMeta,
      http_status: 500,
      duration_ms: Math.max(0, Math.round(performance.now() - startedMs)),
      error_snippet: msg,
    });
    return new Response(
      JSON.stringify({ success: false, error: "Internal server error", message: msg }),
      {
        status: 500,
        headers: { ...responseHeaders, "Content-Type": "application/json" },
      },
    );
  }
}
