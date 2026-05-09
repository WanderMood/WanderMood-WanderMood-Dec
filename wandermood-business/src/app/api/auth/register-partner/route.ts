import { NextResponse } from "next/server";

import { createAdminClient } from "@/lib/supabase/admin";

type Body = {
  email?: string;
  password?: string;
  business_name?: string;
  city?: string;
  country?: string;
};

export async function POST(request: Request) {
  let body: Body;
  try {
    body = (await request.json()) as Body;
  } catch {
    return NextResponse.json({ error: "Ongeldige aanvraag" }, { status: 400 });
  }

  const email = (body.email ?? "").trim().toLowerCase();
  const password = body.password ?? "";
  const businessName = (body.business_name ?? "").trim();
  const city = (body.city ?? "").trim();
  const country = (body.country ?? "NL").trim().toUpperCase().slice(0, 2) || "NL";

  if (!email || !email.includes("@")) {
    return NextResponse.json({ error: "Vul een geldig e-mailadres in." }, { status: 400 });
  }
  if (password.length < 8) {
    return NextResponse.json(
      { error: "Wachtwoord moet minimaal 8 tekens zijn." },
      { status: 400 },
    );
  }
  if (businessName.length < 2 || businessName.length > 200) {
    return NextResponse.json(
      { error: "Vul een geldige bedrijfsnaam in." },
      { status: 400 },
    );
  }
  if (city.length < 2 || city.length > 120) {
    return NextResponse.json({ error: "Vul een geldige stad in." }, { status: 400 });
  }

  const admin = createAdminClient();
  let createdUserId: string | null = null;

  try {
    const { data: authData, error: authError } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });

    if (authError || !authData.user) {
      const msg = authError?.message ?? "Account aanmaken mislukt";
      if (
        msg.toLowerCase().includes("already") ||
        msg.toLowerCase().includes("registered")
      ) {
        return NextResponse.json(
          { error: "Dit e-mailadres is al geregistreerd. Log in." },
          { status: 409 },
        );
      }
      return NextResponse.json({ error: msg }, { status: 400 });
    }

    createdUserId = authData.user.id;

    const { data: listing, error: listingError } = await admin
      .from("business_listings")
      .insert({
        business_name: businessName,
        contact_email: email,
        city,
        country,
        subscription_tier: "basic",
        subscription_status: "onboarding",
      })
      .select("id")
      .single();

    if (listingError || !listing) {
      console.error("[register-partner] listing", listingError);
      throw new Error(listingError?.message ?? "listing insert failed");
    }

    const { error: buError } = await admin.from("business_users").insert({
      user_id: createdUserId,
      business_listing_id: listing.id,
      role: "owner",
    });

    if (buError) {
      console.error("[register-partner] business_users", buError);
      await admin.from("business_listings").delete().eq("id", listing.id);
      throw new Error(buError.message);
    }

    return NextResponse.json({ ok: true });
  } catch (e) {
    if (createdUserId) {
      await admin.auth.admin.deleteUser(createdUserId);
    }
    const message = e instanceof Error ? e.message : "Registratie mislukt";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
