import { redirect } from "next/navigation";

/**
 * Admin lives at /admin (no locale) so it stays outside next-intl.
 * Users often try /nl/admin after browsing /nl — send them to the real URL.
 */
export default function LocaleAdminRedirect() {
  redirect("/admin");
}
