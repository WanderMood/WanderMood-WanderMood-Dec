"use client";

import type { ReactNode } from "react";
import { useTranslations } from "next-intl";

export type MockupNavActive = "explore" | "myDay" | "moody" | "plans" | "profile";

export function MockupStatusBar() {
  return (
    <div className="wm-statusBar wm-statusBar--light">
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
};

export function MockupBottomNav({ active }: BottomNavProps) {
  const t = useTranslations("landing.mockups");
  const tabs: { id: MockupNavActive; icon: string; labelKey: "navExplore" | "navMyDay" | "navMoody" | "navPlans" | "navProfile" }[] =
    [
      { id: "explore", icon: "🔍", labelKey: "navExplore" },
      { id: "myDay", icon: "📅", labelKey: "navMyDay" },
      { id: "moody", icon: "✨", labelKey: "navMoody" },
      { id: "plans", icon: "👥", labelKey: "navPlans" },
      { id: "profile", icon: "👤", labelKey: "navProfile" },
    ];

  return (
    <nav className="wm-appNav" aria-hidden>
      {tabs.map((tab) => (
        <div
          key={tab.id}
          className={`wm-appNav__tab ${active === tab.id ? "wm-appNav__tab--active" : ""}`}
        >
          <span className="wm-appNav__icon" aria-hidden>
            {tab.icon}
          </span>
          <span className="wm-appNav__label">{t(tab.labelKey)}</span>
        </div>
      ))}
    </nav>
  );
}
