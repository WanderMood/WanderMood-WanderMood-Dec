"use client";

import { Suspense, useEffect, useMemo } from "react";
import { useSearchParams } from "next/navigation";

import de from "@/messages/de.json";
import en from "@/messages/en.json";
import es from "@/messages/es.json";
import fr from "@/messages/fr.json";
import nl from "@/messages/nl.json";

const ANDROID_STORE =
  "https://play.google.com/store/apps/details?id=com.edviennemer.wandermood";
const IOS_SEARCH = "https://apps.apple.com/search?term=WanderMood";

// Whitelist matches routing.ts (en, nl, de, es, fr). Default to `en` when the
// browser locale isn't supported so we never fall back to English-mid-sentence
// strings in a partially localised view.
const BUNDLES = { en, nl, de, es, fr } as const;
type SupportedLocale = keyof typeof BUNDLES;

function pickLocale(): SupportedLocale {
  if (typeof navigator === "undefined") return "en";
  // navigator.languages may contain e.g. "nl-NL" — we only care about the
  // primary subtag. `navigator.language` is the fallback for older browsers.
  const langs = (
    navigator.languages && navigator.languages.length > 0
      ? navigator.languages
      : [navigator.language]
  )
    .filter(Boolean)
    .map((l) => l.toLowerCase().split("-")[0]);
  for (const l of langs) {
    if (l in BUNDLES) return l as SupportedLocale;
  }
  return "en";
}

function JoinBody() {
  const searchParams = useSearchParams();
  const code = (searchParams.get("code") ?? "").trim().toUpperCase();

  // Locale is selected once at mount; the deep-link redirect fires immediately
  // after so there's no need to react to later language changes.
  const t = useMemo(() => BUNDLES[pickLocale()].moodMatchJoin, []);

  const appUrl = useMemo(() => {
    if (code.length < 4) return "";
    return `wandermood://group-planning/join?code=${encodeURIComponent(code)}`;
  }, [code]);

  useEffect(() => {
    if (!appUrl) return;
    window.location.href = appUrl;
  }, [appUrl]);

  if (code.length < 4) {
    return (
      <main style={{ padding: 24, fontFamily: "system-ui, sans-serif" }}>
        <h1 style={{ fontSize: 22 }}>{t.title}</h1>
        <p>{t.invalidCode}</p>
        <p>
          <a href="/">{t.backHome}</a>
        </p>
      </main>
    );
  }

  return (
    <main
      style={{
        padding: 24,
        fontFamily: "system-ui, sans-serif",
        maxWidth: 520,
        margin: "0 auto",
        lineHeight: 1.5,
      }}
    >
      <div
        style={{
          borderRadius: 20,
          border: "1px solid rgba(42, 96, 73, 0.18)",
          background: "linear-gradient(180deg, #ffffff 0%, #f5f0e8 100%)",
          boxShadow: "0 8px 28px rgba(30, 28, 24, 0.08)",
          padding: 22,
        }}
      >
        <h1 style={{ fontSize: 24, margin: "0 0 6px", color: "#1e1c18" }}>
          {t.title}
        </h1>
        <p style={{ margin: "0 0 14px", color: "#5a554f" }}>{t.openingBody}</p>
        <p
          style={{
            fontSize: 12,
            margin: "0 0 4px",
            color: "#6f6962",
            letterSpacing: 0.8,
            textTransform: "uppercase",
            fontWeight: 600,
          }}
        >
          {t.inviteCodeLabel}
        </p>
        <p
          style={{
            fontSize: 22,
            letterSpacing: 4,
            fontWeight: 800,
            margin: "0 0 16px",
            fontFamily: "ui-monospace, monospace",
            color: "#2a6049",
          }}
        >
          {code}
        </p>
        <a
          href={appUrl}
          style={{
            display: "inline-block",
            padding: "12px 18px",
            borderRadius: 999,
            backgroundColor: "#2a6049",
            color: "#fff",
            fontWeight: 700,
            textDecoration: "none",
            marginBottom: 14,
          }}
        >
          {t.openInWanderMood}
        </a>
        <p style={{ margin: 0, fontSize: 14, color: "#444" }}>
          {t.afterInstall} <strong>{t.afterInstallTarget}</strong>.
        </p>
      </div>
      <div style={{ marginTop: 14, fontSize: 14, color: "#444" }}>
        <a href={ANDROID_STORE}>{t.storeAndroid}</a>
        {" · "}
        <a href={IOS_SEARCH}>{t.storeIos}</a>
      </div>
    </main>
  );
}

export default function MoodMatchJoinPage() {
  return (
    <Suspense
      fallback={
        <main style={{ padding: 24, fontFamily: "system-ui, sans-serif" }}>
          <p>{en.moodMatchJoin.loading}</p>
        </main>
      }
    >
      <JoinBody />
    </Suspense>
  );
}
