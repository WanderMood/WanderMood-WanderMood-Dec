"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

import { BrandMark } from "@/components/brand-mark";
import { SubscriptionBadge } from "@/components/subscription-badge";
import { Button } from "@/components/ui/button";
import { createClient } from "@/lib/supabase/client";
import type { BusinessListing } from "@/types/business";
import {
  CreditCard,
  HelpCircle,
  LayoutDashboard,
  LogOut,
  MapPin,
} from "lucide-react";

const nav = [
  { href: "/dashboard", label: "Overzicht", icon: LayoutDashboard },
  { href: "/dashboard/listing", label: "Mijn vermelding", icon: MapPin },
  { href: "/dashboard/subscription", label: "Abonnement", icon: CreditCard },
  { href: "/dashboard/help", label: "Help", icon: HelpCircle },
];

export function DashboardShell({
  listing,
  userEmail,
  children,
}: {
  listing: BusinessListing;
  userEmail: string;
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();

  async function logout() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  }

  function NavLinks({ mobile }: { mobile?: boolean }) {
    return (
      <nav
        className={
          mobile
            ? "fixed bottom-0 left-0 right-0 z-50 flex justify-around border-t border-[var(--wm-border)] bg-wm-card py-2 md:hidden"
            : "hidden flex-col gap-1 md:flex"
        }
      >
        {nav.map(({ href, label, icon: Icon }) => {
          const active = pathname === href || (href !== "/dashboard" && pathname.startsWith(href));
          return (
            <Link
              key={href}
              href={href}
              className={
                mobile
                  ? `flex flex-col items-center gap-0.5 px-2 py-1 text-[10px] ${active ? "text-[var(--wm-green)]" : "text-muted-foreground"}`
                  : `flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium transition-colors ${active ? "bg-wm-forest/30 text-wm-cream" : "text-muted-foreground hover:bg-white/5 hover:text-wm-cream"}`
              }
            >
              <Icon className={mobile ? "size-5" : "size-4"} />
              {label}
            </Link>
          );
        })}
      </nav>
    );
  }

  return (
    <div className="min-h-screen bg-wm-bg pb-20 md:pb-0">
      <aside className="fixed left-0 top-0 z-40 hidden h-full w-56 flex-col border-r border-[var(--wm-border)] bg-wm-card md:flex">
        <div className="border-b border-[var(--wm-border)] p-4">
          <BrandMark />
          <p className="mt-1 text-xs text-muted-foreground">Partner Portal</p>
        </div>
        <div className="flex-1 overflow-y-auto p-3">
          <NavLinks />
        </div>
        <div className="border-t border-[var(--wm-border)] p-3">
          <Button
            variant="ghost"
            className="mb-2 w-full justify-start text-muted-foreground hover:text-wm-cream"
            onClick={() => void logout()}
          >
            <LogOut className="mr-2 size-4" />
            Uitloggen
          </Button>
          <p className="truncate text-xs text-muted-foreground">{userEmail}</p>
          <p className="truncate text-xs font-medium text-wm-cream">
            {listing.business_name}
          </p>
        </div>
      </aside>

      <div className="md:pl-56">
        <header className="sticky top-0 z-30 flex flex-wrap items-center justify-between gap-3 border-b border-[var(--wm-border)] bg-wm-bg/95 px-4 py-3 backdrop-blur">
          <div className="min-w-0 md:hidden">
            <BrandMark />
            <p className="text-xs text-muted-foreground">Partner Portal</p>
          </div>
          <h1 className="hidden min-w-0 truncate text-lg font-semibold text-wm-cream md:block">
            {listing.business_name}
          </h1>
          <SubscriptionBadge
            status={listing.subscription_status}
            trialEndsAt={listing.trial_ends_at}
          />
        </header>
        <main className="p-4 md:p-6">{children}</main>
      </div>

      <NavLinks mobile />
    </div>
  );
}
