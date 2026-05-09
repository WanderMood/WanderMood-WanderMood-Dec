"use client";

import { createContext, useContext } from "react";

import type { BusinessListing } from "@/types/business";

const DashboardContext = createContext<BusinessListing | null>(null);

export function DashboardProvider({
  listing,
  children,
}: {
  listing: BusinessListing;
  children: React.ReactNode;
}) {
  return (
    <DashboardContext.Provider value={listing}>
      {children}
    </DashboardContext.Provider>
  );
}

export function useDashboardListing(): BusinessListing {
  const listing = useContext(DashboardContext);
  if (!listing) {
    throw new Error("useDashboardListing must be used within DashboardProvider");
  }
  return listing;
}
