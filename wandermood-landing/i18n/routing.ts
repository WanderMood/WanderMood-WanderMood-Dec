import { defineRouting } from "next-intl/routing";

/** Same locales as the Flutter app: en, nl, de, es, fr */
export const routing = defineRouting({
  locales: ["en", "nl", "de", "es", "fr"],
  defaultLocale: "en",
  localePrefix: "always",
});
