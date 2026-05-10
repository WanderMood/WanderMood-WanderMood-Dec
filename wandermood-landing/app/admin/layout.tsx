import type { Metadata } from "next";
import "./admin-theme.css";

export const metadata: Metadata = {
  title: "Admin — WanderMood",
  robots: { index: false, follow: false },
};

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <div className="admin-dashboard-root font-sans antialiased">{children}</div>;
}
