import type { Metadata } from "next";
import { DM_Sans, Fraunces } from "next/font/google";
import "./globals.css";
import "./landing.css";
import "./home-redesign.css";

const dmSans = DM_Sans({
  variable: "--font-dm-sans",
  subsets: ["latin"],
  weight: ["300", "400", "500"],
});

const fraunces = Fraunces({
  variable: "--font-fraunces",
  subsets: ["latin"],
  weight: ["300", "400", "600"],
  style: ["normal", "italic"],
});

const SITE_URL = "https://wandermood.com";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: "WanderMood — Plan your perfect day",
  description:
    "Tell Moody how you're feeling — he'll plan your perfect day. Mood-based plans for your city, weather-aware, no endless scrolling.",
  keywords: ["travel app", "mood-based travel", "day planning", "WanderMood", "Moody"],
  authors: [{ name: "WanderMood", url: SITE_URL }],
  creator: "WanderMood",
  openGraph: {
    type: "website",
    url: SITE_URL,
    siteName: "WanderMood",
    title: "WanderMood — Plan your perfect day",
    description:
      "Your city. Your mood. Your day. Pick your vibe and let Moody plan it — morning, afternoon, evening.",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "WanderMood — Plan your perfect day",
    description:
      "Your city. Your mood. Your day. Pick your vibe and let Moody plan it.",
  },
  robots: {
    index: true,
    follow: true,
  },
  alternates: { canonical: SITE_URL },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      name: "WanderMood",
      url: SITE_URL,
      description: "Mood-based day planning with Moody — your city, your vibe.",
    },
    {
      "@type": "WebSite",
      name: "WanderMood",
      url: SITE_URL,
      description: "Plan your perfect day based on your mood and the weather.",
      publisher: { "@type": "Organization", name: "WanderMood", url: SITE_URL },
    },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="scroll-smooth">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body className={`${dmSans.variable} ${fraunces.variable} font-sans antialiased`}>
        {children}
      </body>
    </html>
  );
}
