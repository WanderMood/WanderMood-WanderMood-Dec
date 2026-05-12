"use client";

export function WmStatusBar({ dark }: { dark?: boolean }) {
  return (
    <div
      className={`wm-mock__status${dark ? " wm-mock__status--dark" : ""}`}
    >
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

export type WmNavLabels = {
  day: string;
  explore: string;
  moody: string;
  plans: string;
  profile: string;
};

export function WmBottomNav({
  active,
  variant = "light",
  labels,
}: {
  active: WmNavTab;
  variant?: "light" | "dark";
  labels: WmNavLabels;
}) {
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

  const navClass =
    variant === "dark" ? "wm-nav wm-nav--dark" : "wm-nav";

  return (
    <nav className={navClass} aria-hidden>
      {tab("day", "📅", labels.day)}
      {tab("explore", "🔍", labels.explore)}
      {tab("moody", "✨", labels.moody)}
      {tab("plans", "👥", labels.plans)}
      {tab("profile", "👤", labels.profile)}
    </nav>
  );
}
