import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["var(--font-poppins)", "system-ui", "sans-serif"],
      },
      colors: {
        background: "var(--background)",
        foreground: "var(--foreground)",
        card: "var(--card)",
        border: "var(--border)",
        primary: "var(--primary)",
        muted: "var(--muted)",
        "muted-foreground": "var(--muted-foreground)",
        ring: "var(--ring)",
        destructive: "var(--destructive)",
        wm: {
          bg: "var(--wm-bg)",
          card: "var(--wm-card)",
          forest: "var(--wm-forest)",
          green: "var(--wm-green)",
          sunset: "var(--wm-sunset)",
          cream: "var(--wm-cream)",
          muted: "var(--wm-muted)",
        },
      },
    },
  },
  plugins: [],
};
export default config;
