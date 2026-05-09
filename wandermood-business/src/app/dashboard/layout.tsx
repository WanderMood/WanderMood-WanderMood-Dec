import { redirect } from "next/navigation";

import { DashboardShell } from "@/components/dashboard-shell";
import { DashboardProvider } from "@/context/dashboard-context";
import { createClient } from "@/lib/supabase/server";
import { getPartnerListing } from "@/lib/partner-data";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const listing = await getPartnerListing();
  if (!listing) {
    redirect("/no-access");
  }

  const typed = listing;

  return (
    <DashboardProvider listing={typed}>
      <DashboardShell listing={typed} userEmail={user.email ?? ""}>
        {children}
      </DashboardShell>
    </DashboardProvider>
  );
}
