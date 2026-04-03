import { MetadataRoute } from "next";

const SITE_URL = "https://wandermood.com";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      { userAgent: "*", allow: "/" },
      { userAgent: "*", disallow: ["/admin", "/api/admin/"] },
    ],
    sitemap: `${SITE_URL}/sitemap.xml`,
  };
}
