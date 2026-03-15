import type { Metadata, Viewport } from "next";
import { Inter, MuseoModerno } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

const museo = MuseoModerno({
  variable: "--font-museo",
  subsets: ["latin"],
  weight: ["400", "600", "700", "800"],
});

const SITE_URL = "https://wandermood.com";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: "WanderMood – Plan your perfect day based on your mood",
  description:
    "Travel that matches your energy. Discover hidden gems and unforgettable moments — all shaped around how you feel. Pick your mood, get your day.",
  keywords: ["travel app", "mood-based travel", "day planning", "WanderMood", "explore by mood"],
  authors: [{ name: "WanderMood", url: SITE_URL }],
  creator: "WanderMood",
  openGraph: {
    type: "website",
    url: SITE_URL,
    siteName: "WanderMood",
    title: "WanderMood – Plan your perfect day based on your mood",
    description:
      "Travel that matches your energy. Discover hidden gems and unforgettable moments — all shaped around how you feel.",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "WanderMood – Plan your perfect day based on your mood",
    description:
      "Travel that matches your energy. Discover hidden gems and unforgettable moments — all shaped around how you feel.",
  },
  robots: {
    index: true,
    follow: true,
  },
  alternates: { canonical: SITE_URL },
  icons: {
    icon: "/logo.png",
    apple: "/logo.png",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  viewportFit: "cover",
};

const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      name: "WanderMood",
      url: SITE_URL,
      description:
        "Travel that matches your energy. Plan your perfect day based on your mood.",
    },
    {
      "@type": "WebSite",
      name: "WanderMood",
      url: SITE_URL,
      description:
        "Plan your perfect day based on your mood. Discover hidden gems and unforgettable moments — all shaped around how you feel.",
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
      <body className={`${inter.variable} ${museo.variable} font-sans antialiased`}>
        {children}
      </body>
    </html>
  );
}
