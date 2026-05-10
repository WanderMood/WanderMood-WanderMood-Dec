/** Merge EN fallbacks for namespaces added only to en/nl (e.g. partners, nav link). */
export async function loadMergedMessages(locale: string): Promise<Record<string, unknown>> {
  const en = (await import("../messages/en.json")).default as Record<string, unknown>;
  const loc = (await import(`../messages/${locale}.json`)).default as Record<string, unknown>;

  const enLanding = en.landing as Record<string, unknown> | undefined;
  const locLanding = loc.landing as Record<string, unknown> | undefined;
  const enNav = (enLanding?.nav ?? {}) as Record<string, unknown>;
  const locNav = (locLanding?.nav ?? {}) as Record<string, unknown>;

  const enFooter = (en.footer ?? {}) as Record<string, unknown>;
  const locFooter = (loc.footer ?? {}) as Record<string, unknown>;

  return {
    ...loc,
    partners: (loc.partners ?? en.partners) as unknown,
    landing: {
      ...locLanding,
      nav: { ...enNav, ...locNav },
    },
    footer: { ...enFooter, ...locFooter },
  };
}
