import createMiddleware from "next-intl/middleware";
import { routing } from "./i18n/routing";

export default createMiddleware(routing);

export const config = {
  // Exclude /admin and /api from locale routing (wandermood.com/admin)
  matcher: ["/((?!admin|api|_next|_vercel|.*\\..*).*)"],
};
