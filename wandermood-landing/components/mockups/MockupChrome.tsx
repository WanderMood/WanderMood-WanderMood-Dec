"use client";

import type { ReactNode } from "react";

export type MockupNavActive = "explore" | "myDay" | "moody" | "plans" | "profile";

export type MockupLocale = "nl" | "en" | "de" | "es" | "fr";

const NAV_LABELS: Record<
  MockupLocale,
  { myDay: string; explore: string; moody: string; plans: string; profile: string }
> = {
  nl: {
    myDay: "Mijn Dag",
    explore: "Explore",
    moody: "Moody",
    plans: "Plans",
    profile: "Profiel",
  },
  en: {
    myDay: "My Day",
    explore: "Explore",
    moody: "Moody",
    plans: "Plans",
    profile: "Profile",
  },
  de: {
    myDay: "Mein Tag",
    explore: "Entdecken",
    moody: "Moody",
    plans: "Pläne",
    profile: "Profil",
  },
  es: {
    myDay: "Mi día",
    explore: "Explorar",
    moody: "Moody",
    plans: "Planes",
    profile: "Perfil",
  },
  fr: {
    myDay: "Ma journée",
    explore: "Explorer",
    moody: "Moody",
    plans: "Plans",
    profile: "Profil",
  },
};

function normalizeLocale(locale?: string): MockupLocale {
  const l = (locale ?? "nl").toLowerCase();
  if (l === "nl" || l === "en" || l === "de" || l === "es" || l === "fr") return l;
  return "en";
}

type StatusVariant = "light" | "dark";

export function MockupStatusBar({ variant = "light" }: { variant?: StatusVariant }) {
  return (
    <div className={`wm-statusBar wm-statusBar--${variant}`}>
      <span className="wm-statusBar__time">9:41</span>
      <div className="wm-statusBar__icons" aria-hidden>
        <span className="wm-statusBar__signal">
          <span />
          <span />
          <span />
        </span>
        <span className="wm-statusBar__wifi" />
        <span className="wm-statusBar__bat">
          <span className="wm-statusBar__batTerm" />
        </span>
      </div>
    </div>
  );
}

type TopBarProps = {
  title: string;
  leftExtra?: ReactNode;
  right?: ReactNode;
};

export function MockupTopBar({ title, leftExtra, right }: TopBarProps) {
  return (
    <header className="wm-appTopBar">
      <div className="wm-appTopBar__left">
        {leftExtra}
        <span className="wm-appTopBar__title">{title}</span>
      </div>
      <div className="wm-appTopBar__right">{right}</div>
    </header>
  );
}

type BottomNavProps = {
  active: MockupNavActive;
  locale?: string;
  variant?: "default" | "espresso";
};

export function MockupBottomNav({ active, locale, variant = "default" }: BottomNavProps) {
  const loc = normalizeLocale(locale);
  const lab = NAV_LABELS[loc];
  /** Order: My Day, Explore, Moody, Plans, Profile */
  const tabs: { id: MockupNavActive; icon: string; label: string }[] = [
    { id: "myDay", icon: "📅", label: lab.myDay },
    { id: "explore", icon: "🔍", label: lab.explore },
    { id: "moody", icon: "✨", label: lab.moody },
    { id: "plans", icon: "👥", label: lab.plans },
    { id: "profile", icon: "👤", label: lab.profile },
  ];

  const navClass =
    variant === "espresso"
      ? "wm-appNav wm-appNav--espresso"
      : "wm-appNav";

  return (
    <nav className={navClass} aria-hidden>
      {tabs.map((tab) => (
        <div
          key={tab.id}
          className={`wm-appNav__tab ${active === tab.id ? "wm-appNav__tab--active" : ""}`}
        >
          <span className="wm-appNav__icon" aria-hidden>
            {tab.icon}
          </span>
          <span className="wm-appNav__label">{tab.label}</span>
        </div>
      ))}
    </nav>
  );
}
