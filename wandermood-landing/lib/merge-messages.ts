function isPlainObject(v: unknown): v is Record<string, unknown> {
  return v !== null && typeof v === "object" && !Array.isArray(v);
}

function deepMerge(
  base: Record<string, unknown>,
  override: Record<string, unknown>,
): Record<string, unknown> {
  const out: Record<string, unknown> = { ...base };
  for (const key of Object.keys(override)) {
    const o = override[key];
    const b = base[key];
    if (isPlainObject(o) && isPlainObject(b)) {
      out[key] = deepMerge(b, o);
    } else if (o !== undefined) {
      out[key] = o;
    }
  }
  return out;
}

/** Merge EN fallbacks into `landing` so new keys in EN work for de/es/fr until translated. */
export async function loadMergedMessages(locale: string): Promise<Record<string, unknown>> {
  const en = (await import("../messages/en.json")).default as Record<string, unknown>;
  const loc = (await import(`../messages/${locale}.json`)).default as Record<string, unknown>;

  const enLanding = (en.landing ?? {}) as Record<string, unknown>;
  const locLanding = (loc.landing ?? {}) as Record<string, unknown>;

  const enFooter = (en.footer ?? {}) as Record<string, unknown>;
  const locFooter = (loc.footer ?? {}) as Record<string, unknown>;

  return {
    ...loc,
    partners: (loc.partners ?? en.partners) as unknown,
    landing: deepMerge(enLanding, locLanding) as unknown,
    footer: { ...enFooter, ...locFooter },
  };
}
