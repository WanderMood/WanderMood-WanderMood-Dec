import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Join Mood Match · WanderMood",
  description:
    "Open WanderMood to join a friend’s Mood Match session, or install the app and enter your join code.",
};

export default function JoinLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
