/** Trim — Vercel/console pastes often include trailing newlines. */
export function readTrimmedEnv(name: string): string | undefined {
  const raw = process.env[name];
  if (raw == null) return undefined;
  const t = raw.trim();
  return t.length > 0 ? t : undefined;
}

export function adminOperatorSecrets(): {
  wandermood: string | undefined;
  admin: string | undefined;
  edgeForward: string | undefined;
} {
  const wandermood = readTrimmedEnv("WANDERMOOD_ADMIN_SECRET");
  const admin = readTrimmedEnv("ADMIN_SECRET");
  return {
    wandermood,
    admin,
    edgeForward: admin ?? wandermood,
  };
}

/** Accept x-wandermood-admin (dashboard), x-admin-secret (approve), or Bearer. */
export function parseClientAdminSecret(headers: Headers): string {
  const xWm = headers.get("x-wandermood-admin")?.trim() ?? "";
  const xAd = headers.get("x-admin-secret")?.trim() ?? "";
  const auth = headers.get("authorization")?.replace(/^Bearer\s+/i, "").trim() ?? "";
  return xWm || xAd || auth;
}

export function isOperatorSecretValid(provided: string): boolean {
  const { wandermood, admin } = adminOperatorSecrets();
  if (!provided) return false;
  return provided === wandermood || provided === admin;
}
