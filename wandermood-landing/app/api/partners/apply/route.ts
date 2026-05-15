import { createSupabaseAdmin } from "@/lib/supabase-admin";
import { NextRequest, NextResponse } from "next/server";
import Stripe from "stripe";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const ALLOWED_INCLUSION_TAGS = new Set([
  "specialty_coffee",
  "vegan",
  "halal",
  "vegetarian",
  "family_friendly",
  "kids_friendly",
  "wheelchair_accessible",
  "dog_friendly",
  "terrace_outdoor",
  "live_music",
]);

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function appBaseUrl(): string {
  const u = process.env.NEXT_PUBLIC_APP_URL?.trim().replace(/\/$/, "");
  return u && u.length > 0 ? u : "https://wandermood.com";
}

function stripePriceId(): string | null {
  const id =
    process.env.STRIPE_PRICE_ID?.trim() ||
    process.env.STRIPE_PREMIUM_PRICE_ID?.trim();
  return id && id.length > 0 ? id : null;
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as Record<string, unknown>;

    if (body.website_url) {
      return NextResponse.json({ success: true });
    }

    const stripeKey = process.env.STRIPE_SECRET_KEY?.trim();
    const priceId = stripePriceId();
    if (!stripeKey || !priceId) {
      return NextResponse.json(
        { error: "Betaling niet geconfigureerd. Neem contact op met support." },
        { status: 500 },
      );
    }

    const localeRaw = typeof body.locale === "string" ? body.locale.trim() : "en";
    const locale = /^[a-z]{2}$/i.test(localeRaw) ? localeRaw.toLowerCase() : "en";

    const businessName = String(body.business_name ?? "").trim();
    const businessType = String(body.business_type ?? "").trim();
    const streetAddress = String(body.street_address ?? "").trim();
    const city = String(body.city ?? "").trim();
    const googlePlaceUrl = String(body.google_place_url ?? "").trim();
    const priceRange = String(body.price_range ?? "").trim();
    const openingHours =
      typeof body.opening_hours === "string" && body.opening_hours.trim()
        ? body.opening_hours.trim()
        : null;
    const website =
      typeof body.website === "string" && body.website.trim()
        ? body.website.trim()
        : null;
    let instagram =
      typeof body.instagram_handle === "string" && body.instagram_handle.trim()
        ? body.instagram_handle.trim()
        : null;
    if (instagram) instagram = instagram.replace(/^@+/, "");

    const contactName = String(body.contact_name ?? "").trim();
    const contactEmail = String(body.contact_email ?? "").trim();
    const contactPhone = String(body.contact_phone ?? "").trim();
    const kvkRaw = String(body.kvk_number ?? "").replace(/\s/g, "");
    const billingName =
      typeof body.billing_name === "string" && body.billing_name.trim()
        ? body.billing_name.trim()
        : null;
    const billingAddress =
      typeof body.billing_address === "string" && body.billing_address.trim()
        ? body.billing_address.trim()
        : null;
    const vatNumber =
      typeof body.vat_number === "string" && body.vat_number.trim()
        ? body.vat_number.trim()
        : null;

    const targetMoods = Array.isArray(body.target_moods)
      ? (body.target_moods as unknown[]).filter((m) => typeof m === "string")
      : [];

    const inclusionRaw = Array.isArray(body.inclusion_tags)
      ? (body.inclusion_tags as unknown[]).filter((x) => typeof x === "string")
      : [];
    const inclusionTags = [
      ...new Set(
        inclusionRaw.filter((x): x is string => ALLOWED_INCLUSION_TAGS.has(x)),
      ),
    ];

    const gdprOk = body.gdpr_consent === true;
    const pricingOk = body.pricing_consent === true;

    if (
      !businessName ||
      !businessType ||
      !streetAddress ||
      !city ||
      !googlePlaceUrl ||
      !priceRange
    ) {
      return NextResponse.json({ error: "Verplichte velden ontbreken." }, { status: 400 });
    }

    try {
      const u = new URL(googlePlaceUrl.startsWith("http") ? googlePlaceUrl : `https://${googlePlaceUrl}`);
      if (!u.hostname) throw new Error("bad host");
    } catch {
      return NextResponse.json({ error: "Ongeldige Google Maps-link." }, { status: 400 });
    }

    if (!contactName || !contactEmail || !contactPhone) {
      return NextResponse.json({ error: "Contactgegevens zijn verplicht." }, { status: 400 });
    }

    if (!EMAIL_RE.test(contactEmail)) {
      return NextResponse.json({ error: "Invalid email address" }, { status: 400 });
    }

    if (kvkRaw && !/^\d{8}$/.test(kvkRaw)) {
      return NextResponse.json(
        { error: "KvK-nummer moet 8 cijfers bevatten" },
        { status: 400 },
      );
    }

    if (!vatNumber) {
      return NextResponse.json(
        { error: "BTW-/belastingnummer is verplicht." },
        { status: 400 },
      );
    }

    if (targetMoods.length < 1) {
      return NextResponse.json(
        { error: "Selecteer minimaal 1 stemming" },
        { status: 400 },
      );
    }

    if (!gdprOk) {
      return NextResponse.json({ error: "GDPR consent required" }, { status: 400 });
    }

    if (!pricingOk) {
      return NextResponse.json({ error: "Pricing consent required" }, { status: 400 });
    }

    const supabase = createSupabaseAdmin();
    if (!supabase) {
      return NextResponse.json(
        { error: "Server configuration error" },
        { status: 500 },
      );
    }

    const { data: insertedLead, error: dbError } = await supabase
      .from("partner_leads")
      .insert({
        business_name: businessName,
        business_type: businessType,
        city,
        country: "NL",
        street_address: streetAddress,
        opening_hours: openingHours,
        price_range: priceRange,
        website,
        instagram_handle: instagram,
        google_place_url: googlePlaceUrl,
        contact_name: contactName,
        contact_email: contactEmail,
        contact_phone: contactPhone,
        kvk_number: kvkRaw && /^\d{8}$/.test(kvkRaw) ? kvkRaw : null,
        billing_name: billingName,
        billing_address: billingAddress,
        vat_number: vatNumber,
        what_they_offer: null,
        why_wandermood: null,
        inclusion_tags: inclusionTags,
        target_moods: targetMoods,
        gdpr_consent: true,
        pricing_consent: true,
        status: "new",
        source: "website",
      })
      .select("id")
      .single();

    if (dbError || !insertedLead?.id) {
      console.error("partner_leads insert error:", dbError);
      return NextResponse.json({ error: "Database error" }, { status: 500 });
    }

    const leadId = insertedLead.id as string;
    const base = appBaseUrl();

    const businessNameRaw = businessName;
    const bnEscaped = escapeHtml(businessNameRaw);

    if (process.env.RESEND_API_KEY) {
      try {
        const emailRes = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: "WanderMood Partners <partners@wandermood.com>",
            to: ["info@wandermood.com"],
            subject: `Nieuwe partneraanvraag: ${businessNameRaw}`,
            html: `
              <div style="font-family:sans-serif;max-width:560px;margin:0 auto;padding:32px 24px;">
                <div style="background:#2A6049;border-radius:12px;padding:24px;margin-bottom:24px;">
                  <h2 style="color:#F5F0E8;margin:0;">Nieuwe partneraanvraag (checkout gestart) 🎉</h2>
                </div>
                <p><strong>Zaak:</strong> ${bnEscaped}</p>
                <p><strong>Type:</strong> ${escapeHtml(businessType)}</p>
                <p><strong>Adres:</strong> ${escapeHtml(streetAddress)}, ${escapeHtml(city)}</p>
                <p><strong>Contact:</strong> ${escapeHtml(contactName)} — ${escapeHtml(contactEmail)} — ${escapeHtml(contactPhone)}</p>
                <p><strong>KvK:</strong> ${kvkRaw ? escapeHtml(kvkRaw) : "—"}</p>
                <p><strong>BTW:</strong> ${escapeHtml(vatNumber)}</p>
                <p><strong>Prijsniveau:</strong> ${escapeHtml(priceRange)}</p>
                <p><strong>Website:</strong> ${website ? escapeHtml(website) : "—"}</p>
                <p><strong>Instagram:</strong> ${instagram ? escapeHtml(instagram) : "—"}</p>
                <p><strong>Google Maps:</strong> ${escapeHtml(googlePlaceUrl)}</p>
                <p><strong>Openingstijden:</strong> ${openingHours ? escapeHtml(openingHours) : "—"}</p>
                <p><strong>Stemmingen:</strong> ${targetMoods.length ? escapeHtml(targetMoods.join(", ")) : "—"}</p>
                <p><strong>Filters / inclusie:</strong> ${inclusionTags.length ? escapeHtml(inclusionTags.join(", ")) : "—"}</p>
                <p><strong>Aanbod (vrij):</strong> —</p>
                <p><strong>Waarom WanderMood (vrij):</strong> —</p>
                <hr style="margin:24px 0;border:1px solid #eee;">
                <p style="color:#6B6560;font-size:13px;">Lead id: ${escapeHtml(leadId)}</p>
              </div>
            `,
          }),
        });
        console.log("Resend team notify status:", emailRes.status);
        const emailResApplicant = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: "WanderMood Partners <partners@wandermood.com>",
            to: [contactEmail],
            subject: `Aanvraag ontvangen — ${businessNameRaw}`,
            html: `
        <div style="font-family:sans-serif;max-width:560px;margin:0 auto;padding:32px 24px;">
          <div style="background:#2A6049;border-radius:12px;padding:24px;margin-bottom:24px;">
            <h2 style="color:#F5F0E8;margin:0;">Volgende stap: betaalgegevens 🎉</h2>
          </div>
          <p style="color:#2C2A26;font-size:16px;">Hoi ${escapeHtml(contactName)},</p>
          <p style="color:#2C2A26;font-size:16px;line-height:1.6;">
            We hebben je aanvraag voor <strong>${bnEscaped}</strong> ontvangen.
            Rond je aanvraag af door je betaalgegevens veilig in te stellen via Stripe (geen kosten tijdens de proefperiode).
          </p>
          <p style="color:#2C2A26;font-size:16px;">
            Vragen? Mail naar <a href="mailto:info@wandermood.com" style="color:#2A6049;">info@wandermood.com</a>
          </p>
        </div>`,
          }),
        });
        console.log("Resend applicant status:", emailResApplicant.status);
      } catch (e) {
        console.error("Email send failed:", e);
      }
    }

    const stripe = new Stripe(stripeKey);

    let session: Stripe.Checkout.Session;
    try {
      session = await stripe.checkout.sessions.create({
        mode: "subscription",
        payment_method_types: ["card", "ideal", "sepa_debit"],
        customer_email: contactEmail,
        line_items: [{ price: priceId, quantity: 1 }],
        subscription_data: {
          trial_period_days: 30,
          metadata: {
            lead_id: leadId,
            business_name: businessName,
            city,
          },
        },
        metadata: {
          lead_id: leadId,
          business_name: businessName,
        },
        success_url: `${base}/${locale}/partners/bedankt?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: `${base}/${locale}/partners?cancelled=true`,
        locale: locale === "nl" ? "nl" : "auto",
      });
    } catch (e) {
      console.error("Stripe checkout create failed:", e);
      return NextResponse.json(
        { error: "Kon betaalpagina niet starten. Probeer later opnieuw." },
        { status: 502 },
      );
    }

    const { error: upErr } = await supabase
      .from("partner_leads")
      .update({ stripe_session_id: session.id })
      .eq("id", leadId);

    if (upErr) {
      console.error("partner_leads stripe_session_id update:", upErr);
    }

    if (!session.url) {
      return NextResponse.json({ error: "Geen checkout-URL" }, { status: 502 });
    }

    return NextResponse.json({ success: true, checkoutUrl: session.url });
  } catch (err) {
    console.error("Partner apply error:", err);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
