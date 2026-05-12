"use client";

export function WmStatusBar() {
  return (
    <div className="wm-mock__status">
      <span className="wm-mock__time">9:41</span>
      <div className="wm-mock__sys">
        <span className="wm-mock__signal" aria-hidden>
          <span />
          <span />
          <span />
        </span>
        <span className="wm-mock__wifi" aria-hidden />
        <span className="wm-mock__battery" aria-hidden>
          <span className="wm-mock__battery-fill" />
        </span>
      </div>
    </div>
  );
}

export type WmNavTab = "explore" | "day" | "moody" | "plans" | "profile";

export function WmBottomNav({ active }: { active: WmNavTab }) {
  const tab = (id: WmNavTab, icon: string, label: string) => (
    <div
      className={`wm-nav__tab ${active === id ? "wm-nav__tab--on" : ""}`}
      role="presentation"
    >
      <span className="wm-nav__ico" aria-hidden>
        {icon}
      </span>
      <span className="wm-nav__lbl">{label}</span>
    </div>
  );

  return (
    <nav className="wm-nav" aria-hidden>
      {tab("explore", "🔍", "Explore")}
      {tab("day", "📅", "Mijn Dag")}
      {tab("moody", "✨", "Moody")}
      {tab("plans", "👥", "Plans")}
      {tab("profile", "👤", "Profiel")}
    </nav>
  );
}
