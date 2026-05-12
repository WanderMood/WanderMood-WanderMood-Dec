"use client";

import type { ReactNode, SVGProps, JSX } from "react";

/* ---------- SVG Tab Icons ---------- */
function IconMyDay(p: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...p}>
      <rect x="3" y="4" width="18" height="17" rx="3" stroke="currentColor" strokeWidth="1.8" />
      <rect x="3" y="4" width="18" height="5.5" rx="2" fill="currentColor" opacity="0.15" />
      <path d="M3 9.5h18" stroke="currentColor" strokeWidth="1.8" />
      <path d="M8 2.5v3M16 2.5v3" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
      <text x="12" y="19" textAnchor="middle" fontSize="6.5" fontWeight="700" fill="currentColor" fontFamily="system-ui,sans-serif">17</text>
    </svg>
  );
}

function IconExplore(p: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...p}>
      <circle cx="10.5" cy="10.5" r="6.5" stroke="currentColor" strokeWidth="1.8" />
      <path d="M15.5 15.5L20 20" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  );
}

function IconMoody(p: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...p}>
      <path d="M12 2L13.5 8.5L20 7L15 11.5L18 18L12 14L6 18L9 11.5L4 7L10.5 8.5L12 2Z" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round" fill="currentColor" fillOpacity="0.12" />
      <circle cx="12" cy="11.5" r="2" fill="currentColor" />
    </svg>
  );
}

function IconPlans(p: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...p}>
      <circle cx="9" cy="7" r="3.2" stroke="currentColor" strokeWidth="1.7" />
      <path d="M2 20c0-3.866 3.134-7 7-7s7 3.134 7 7" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
      <circle cx="17" cy="8" r="2.5" stroke="currentColor" strokeWidth="1.5" />
      <path d="M20 20c0-2.761-1.5-5-3.5-5.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function IconProfile(p: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...p}>
      <circle cx="12" cy="7.5" r="3.8" stroke="currentColor" strokeWidth="1.8" />
      <path d="M4 20.5c0-4.418 3.582-8 8-8s8 3.582 8 8" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  );
}

const TAB_ICONS: Record<string, (p: SVGProps<SVGSVGElement>) => JSX.Element> = {
  myDay: IconMyDay,
  explore: IconExplore,
  moody: IconMoody,
  plans: IconPlans,
  profile: IconProfile,
};

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
  const l = (locale ?? "en").toLowerCase();
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
  const tabs: { id: MockupNavActive; label: string }[] = [
    { id: "myDay", label: lab.myDay },
    { id: "explore", label: lab.explore },
    { id: "moody", label: lab.moody },
    { id: "plans", label: lab.plans },
    { id: "profile", label: lab.profile },
  ];

  const navClass =
    variant === "espresso"
      ? "wm-appNav wm-appNav--espresso"
      : "wm-appNav";

  return (
    <nav className={navClass} aria-hidden>
      {tabs.map((tab) => {
        const isActive = active === tab.id;
        const Icon = TAB_ICONS[tab.id];
        return (
          <div
            key={tab.id}
            className={`wm-appNav__tab ${isActive ? "wm-appNav__tab--active" : ""}`}
          >
            <span className="wm-appNav__icon" aria-hidden>
              <Icon
                width={20}
                height={20}
                className="wm-appNav__svg"
              />
            </span>
            <span className="wm-appNav__label">{tab.label}</span>
          </div>
        );
      })}
    </nav>
  );
}
