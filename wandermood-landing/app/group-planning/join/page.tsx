"use client";

import { Suspense, useEffect, useMemo } from "react";
import { useSearchParams } from "next/navigation";

const ANDROID_STORE =
  "https://play.google.com/store/apps/details?id=com.edviennemer.wandermood";
const IOS_SEARCH = "https://apps.apple.com/search?term=WanderMood";

function JoinBody() {
  const searchParams = useSearchParams();
  const code = (searchParams.get("code") ?? "").trim().toUpperCase();

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
        <h1 style={{ fontSize: 22 }}>Mood Match</h1>
        <p>This invite link does not include a valid join code.</p>
        <p>
          <a href="/">Back to WanderMood</a>
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
      <h1 style={{ fontSize: 22, marginBottom: 12 }}>Join Mood Match</h1>
      <p style={{ marginBottom: 16 }}>
        We are opening the WanderMood app for you. If nothing happens, tap
        &quot;Open in app&quot; below, or install WanderMood and enter this code
        under <strong>Plan with a friend</strong>.
      </p>
      <p
        style={{
          fontSize: 20,
          letterSpacing: 3,
          fontWeight: 700,
          marginBottom: 20,
          fontFamily: "ui-monospace, monospace",
        }}
      >
        {code}
      </p>
      <p style={{ marginBottom: 12 }}>
        <a href={appUrl} style={{ fontWeight: 600 }}>
          Open in WanderMood
        </a>
      </p>
      <p style={{ fontSize: 14, color: "#444" }}>
        <a href={ANDROID_STORE}>Android — Google Play</a>
        {" · "}
        <a href={IOS_SEARCH}>iPhone — App Store search</a>
      </p>
    </main>
  );
}

export default function MoodMatchJoinPage() {
  return (
    <Suspense
      fallback={
        <main style={{ padding: 24, fontFamily: "system-ui, sans-serif" }}>
          <p>Loading…</p>
        </main>
      }
    >
      <JoinBody />
    </Suspense>
  );
}
