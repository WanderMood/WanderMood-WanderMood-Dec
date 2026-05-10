import { createSupabaseAdmin } from "@/lib/supabase-admin";
import { NextRequest, NextResponse } from "next/server";

const REQUIRED = [
  "business_name",
  "business_type",
  "city",
  "contact_email",
  "gdpr_consent",
] as const;

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as Record<string, unknown>;

    if (body.website_url) {
      return NextResponse.json({ success: true });
    }

    for (const field of REQUIRED) {
      if (body[field] === undefined || body[field] === null || body[field] === "") {
        return NextResponse.json({ error: `${field} is required` }, { status: 400 });
      }
    }

    if (body.gdpr_consent !== true) {
      return NextResponse.json({ error: "GDPR consent required" }, { status: 400 });
    }

    const contactEmail = String(body.contact_email).trim();
    if (!EMAIL_RE.test(contactEmail)) {
      return NextResponse.json({ error: "Invalid email address" }, { status: 400 });
    }

    const whatOffer =
      typeof body.what_they_offer === "string" ? body.what_they_offer.trim() : "";
    if (!whatOffer) {
      return NextResponse.json({ error: "what_they_offer is required" }, { status: 400 });
    }

    const contactName =
      typeof body.contact_name === "string" ? body.contact_name.trim() : "";
    if (!contactName) {
      return NextResponse.json({ error: "contact_name is required" }, { status: 400 });
    }

    const supabase = createSupabaseAdmin();
    if (!supabase) {
      return NextResponse.json(
        { error: "Server configuration error" },
        { status: 500 },
      );
    }

    const targetMoods = Array.isArray(body.target_moods)
      ? (body.target_moods as unknown[]).filter((m) => typeof m === "string")
      : [];

    const { error: dbError } = await supabase.from("partner_leads").insert({
      business_name: String(body.business_name).trim(),
      business_type: String(body.business_type).trim(),
      city: String(body.city).trim(),
      country:
        typeof body.country === "string" && body.country.trim()
          ? body.country.trim().toUpperCase().slice(0, 2)
          : "NL",
      website:
        typeof body.website === "string" && body.website.trim()
          ? body.website.trim()
          : null,
      google_place_url:
        typeof body.google_place_url === "string" && body.google_place_url.trim()
          ? body.google_place_url.trim()
          : null,
      contact_name: contactName,
      contact_email: contactEmail,
      what_they_offer: whatOffer.slice(0, 300),
      target_moods: targetMoods,
      gdpr_consent: true,
      status: "new",
      source: "website",
    });

    if (dbError) {
      console.error("partner_leads insert error:", dbError);
      return NextResponse.json({ error: "Database error" }, { status: 500 });
    }

    const businessNameRaw = String(body.business_name).trim();
    const bnEscaped = escapeHtml(businessNameRaw);

    if (process.env.RESEND_API_KEY) {
      try {
        const res = await fetch("https://api.resend.com/emails", {
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
                  <h2 style="color:#F5F0E8;margin:0;">Nieuwe partneraanvraag 🎉</h2>
                </div>
                <p><strong>Zaak:</strong> ${bnEscaped}</p>
                <p><strong>Type:</strong> ${escapeHtml(String(body.business_type))}</p>
                <p><strong>Stad:</strong> ${escapeHtml(String(body.city))}</p>
                <p><strong>Contact:</strong> ${escapeHtml(contactName)} — ${escapeHtml(contactEmail)}</p>
                <p><strong>Website:</strong> ${body.website ? escapeHtml(String(body.website)) : "—"}</p>
                <p><strong>Google Maps:</strong> ${body.google_place_url ? escapeHtml(String(body.google_place_url)) : "—"}</p>
                <p><strong>Stemmingen:</strong> ${targetMoods.length ? escapeHtml(targetMoods.join(", ")) : "—"}</p>
                <p><strong>Aanbod:</strong><br>${escapeHtml(whatOffer)}</p>
                <hr style="margin:24px 0;border:1px solid #eee;">
                <p style="color:#6B6560;font-size:13px;">Bekijk en keur goed op
                  <a href="https://wandermood.com/admin">wandermood.com/admin</a>
                </p>
              </div>
            `,
          }),
        });
        if (!res.ok) {
          console.warn("Resend API:", await res.text());
        }
      } catch (emailErr) {
        console.warn("Email notification failed:", emailErr);
      }

      // Confirmation email to the applicant
      try {
        await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: "WanderMood Partners <partners@wandermood.com>",
            to: [body.contact_email],
            subject: `Aanvraag ontvangen — ${body.business_name}`,
            html: `
        <div style="font-family:sans-serif;max-width:560px;
          margin:0 auto;padding:32px 24px;">
          <div style="background:#2A6049;border-radius:12px;
            padding:24px;margin-bottom:24px;">
            <h2 style="color:#F5F0E8;margin:0;">
              Aanvraag ontvangen! 🎉
            </h2>
          </div>
          <p style="color:#2C2A26;font-size:16px;">
            Hoi ${body.contact_name || body.business_name},
          </p>
          <p style="color:#2C2A26;font-size:16px;line-height:1.6;">
            We hebben je aanvraag voor
            <strong>${body.business_name}</strong>
            ontvangen. Bedankt!
          </p>
          <div style="background:#F5F0E8;border-radius:8px;
            padding:20px;margin:24px 0;">
            <h3 style="color:#2A6049;margin:0 0 12px;">
              Wat gebeurt er nu?
            </h3>
            <ul style="color:#2C2A26;margin:0;
              padding-left:20px;line-height:1.8;">
              <li>We reviewen je aanvraag handmatig</li>
              <li>Je hoort binnen 3 werkdagen van ons</li>
              <li>Bij goedkeuring starten we direct
                je gratis proefperiode van 30 dagen</li>
            </ul>
          </div>
          <p style="color:#2C2A26;font-size:16px;">
            Vragen? Mail naar
            <a href="mailto:info@wandermood.com"
              style="color:#2A6049;">
              info@wandermood.com
            </a>
          </p>
          <p style="color:#6B6560;font-size:14px;
            margin-top:32px;">
            Met groet,<br>
            <strong>Edvienne van WanderMood</strong><br>
            Rotterdam
          </p>
        </div>
      `,
          }),
        });
      } catch (e) {
        // Non-fatal — form still succeeds if email fails
        console.warn("Applicant confirmation email failed:", e);
      }
    }

    return NextResponse.json({ success: true });
  } catch (err) {
    console.error("Partner apply error:", err);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
