"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { format, parseISO } from "date-fns";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { useDashboardListing } from "@/context/dashboard-context";
import { PARTNER_MOOD_OPTIONS } from "@/lib/mood-options";
import { toast } from "sonner";

const INCLUSION_FIELDS = [
  { key: "is_halal" as const, label: "Halal" },
  { key: "is_vegan_friendly" as const, label: "Veganistisch" },
  { key: "is_vegetarian_friendly" as const, label: "Vegetarisch" },
  { key: "is_lgbtq_friendly" as const, label: "LHBTQ+ vriendelijk" },
  { key: "is_black_owned" as const, label: "Black-owned" },
  { key: "is_family_friendly" as const, label: "Gezinsvriendelijk" },
  { key: "is_kids_friendly" as const, label: "Kindvriendelijk" },
  { key: "is_wheelchair_accessible" as const, label: "Rolstoeltoegankelijk" },
];

export function ListingEditor() {
  const router = useRouter();
  const listing = useDashboardListing();
  const [desc, setDesc] = useState(listing.custom_description ?? "");
  const [offer, setOffer] = useState(listing.active_offer ?? "");
  const [offerEnabled, setOfferEnabled] = useState(
    Boolean(listing.active_offer && listing.active_offer.length > 0),
  );
  const [offerDate, setOfferDate] = useState(() =>
    listing.offer_expires_at
      ? format(parseISO(listing.offer_expires_at), "yyyy-MM-dd")
      : "",
  );
  const [moods, setMoods] = useState<string[]>(listing.target_moods ?? []);
  const [saving, setSaving] = useState<string | null>(null);

  useEffect(() => {
    setDesc(listing.custom_description ?? "");
    setOffer(listing.active_offer ?? "");
    setOfferEnabled(Boolean(listing.active_offer && listing.active_offer.length > 0));
    setOfferDate(
      listing.offer_expires_at
        ? format(parseISO(listing.offer_expires_at), "yyyy-MM-dd")
        : "",
    );
    setMoods(listing.target_moods ?? []);
  }, [
    listing.custom_description,
    listing.active_offer,
    listing.offer_expires_at,
    listing.target_moods,
    listing.updated_at,
  ]);

  const mapsUrl = useMemo(() => {
    if (!listing.place_id) return null;
    return `https://www.google.com/maps/search/?api=1&query_place_id=${encodeURIComponent(listing.place_id)}`;
  }, [listing.place_id]);

  async function patch(payload: Record<string, unknown>, label: string) {
    setSaving(label);
    try {
      const res = await fetch("/api/dashboard/listing", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) {
        const j = (await res.json().catch(() => ({}))) as { error?: string };
        throw new Error(j.error ?? res.statusText);
      }
      toast.success("Opgeslagen");
      router.refresh();
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Opslaan mislukt");
    } finally {
      setSaving(null);
    }
  }

  async function saveDescription() {
    await patch({ custom_description: desc || null }, "desc");
  }

  async function saveOffer() {
    if (!offerEnabled) {
      await patch(
        { active_offer: null, offer_expires_at: null },
        "offer",
      );
      setOffer("");
      setOfferDate("");
      return;
    }
    const expires = offerDate
      ? new Date(`${offerDate}T23:59:59.999Z`).toISOString()
      : null;
    await patch(
      {
        active_offer: offer.slice(0, 200) || null,
        offer_expires_at: expires,
      },
      "offer",
    );
  }

  async function saveMoods() {
    await patch({ target_moods: moods }, "moods");
  }

  async function toggleInclusion(
    key: (typeof INCLUSION_FIELDS)[number]["key"],
    value: boolean,
  ) {
    await patch({ [key]: value }, key);
  }

  return (
    <div className="mx-auto max-w-3xl space-y-8">
      <Card className="border-[var(--wm-border)] bg-wm-card shadow-none">
        <CardHeader>
          <CardTitle className="text-wm-cream">Basisgegevens</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2 text-sm">
          <p>
            <span className="text-muted-foreground">Bedrijfsnaam:</span>{" "}
            <span className="text-wm-cream">{listing.business_name}</span>
          </p>
          <p>
            <span className="text-muted-foreground">Stad:</span>{" "}
            <span className="text-wm-cream">{listing.city}</span>
          </p>
          <p>
            <span className="text-muted-foreground">Place ID:</span>{" "}
            {mapsUrl ? (
              <a
                href={mapsUrl}
                target="_blank"
                rel="noreferrer"
                className="text-[var(--wm-green)] hover:underline"
              >
                Google Maps
              </a>
            ) : (
              <span className="text-wm-cream">—</span>
            )}
          </p>
          <p className="pt-2 text-muted-foreground">
            Wil je je naam of locatie aanpassen? Mail naar{" "}
            <a
              href="mailto:info@wandermood.com"
              className="text-[var(--wm-green)] hover:underline"
            >
              info@wandermood.com
            </a>
            .
          </p>
        </CardContent>
      </Card>

      <Card className="border-[var(--wm-border)] bg-wm-card shadow-none">
        <CardHeader>
          <CardTitle className="text-wm-cream">Beschrijving voor gebruikers</CardTitle>
          <p className="text-sm text-muted-foreground">
            Dit ziet de gebruiker als ze op jouw plek tikken. Schrijf kort en
            persoonlijk.
          </p>
        </CardHeader>
        <CardContent className="space-y-3">
          <Textarea
            value={desc}
            onChange={(e) => setDesc(e.target.value.slice(0, 500))}
            rows={5}
            className="border-[var(--wm-border)] bg-wm-bg"
          />
          <div className="flex items-center justify-between gap-2">
            <span className="text-xs text-muted-foreground">
              {desc.length}/500
            </span>
            <Button
              type="button"
              onClick={() => void saveDescription()}
              disabled={saving === "desc"}
              className="bg-wm-forest text-wm-cream hover:bg-wm-forest/90"
            >
              Opslaan
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card className="border-[var(--wm-border)] bg-wm-card shadow-none">
        <CardHeader>
          <CardTitle className="text-wm-cream">Actieve aanbieding</CardTitle>
          <p className="text-sm text-muted-foreground">
            Zichtbaar in je vermelding, bijv. &quot;10% korting op je eerste bezoek
            deze week.&quot;
          </p>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center gap-2">
            <Switch
              checked={offerEnabled}
              onCheckedChange={(v) => {
                setOfferEnabled(v);
                if (!v) {
                  void patch(
                    { active_offer: null, offer_expires_at: null },
                    "offer",
                  );
                  setOffer("");
                  setOfferDate("");
                }
              }}
            />
            <Label>Aanbieding actief</Label>
          </div>
          {offerEnabled ? (
            <>
              <Input
                value={offer}
                onChange={(e) => setOffer(e.target.value.slice(0, 200))}
                placeholder="Jouw aanbieding"
                className="border-[var(--wm-border)] bg-wm-bg"
              />
              <div className="space-y-1">
                <Label>Geldig tot</Label>
                <Input
                  type="date"
                  value={offerDate}
                  onChange={(e) => setOfferDate(e.target.value)}
                  className="border-[var(--wm-border)] bg-wm-bg"
                />
              </div>
              <Button
                type="button"
                onClick={() => void saveOffer()}
                disabled={saving === "offer"}
                className="bg-wm-forest text-wm-cream hover:bg-wm-forest/90"
              >
                Opslaan
              </Button>
            </>
          ) : null}
        </CardContent>
      </Card>

      <Card className="border-[var(--wm-border)] bg-wm-card shadow-none">
        <CardHeader>
          <CardTitle className="text-wm-cream">Stemmingen</CardTitle>
          <p className="text-sm text-muted-foreground">
            Je verschijnt in Moody&apos;s aanbevelingen wanneer een gebruiker één van
            deze stemmingen kiest.
          </p>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-wrap gap-2">
            {PARTNER_MOOD_OPTIONS.map((m) => {
              const selected = moods.includes(m.id);
              return (
                <button
                  key={m.id}
                  type="button"
                  onClick={() => {
                    setMoods((prev) =>
                      selected
                        ? prev.filter((x) => x !== m.id)
                        : [...prev, m.id],
                    );
                  }}
                  className={`rounded-full border px-3 py-1.5 text-sm transition-colors ${
                    selected
                      ? "border-wm-forest bg-wm-forest/25 text-wm-cream"
                      : "border-[var(--wm-border)] text-muted-foreground hover:border-wm-forest/50"
                  }`}
                >
                  {m.emoji} {m.label}
                </button>
              );
            })}
          </div>
          <Button
            type="button"
            onClick={() => void saveMoods()}
            disabled={saving === "moods"}
            className="bg-wm-forest text-wm-cream hover:bg-wm-forest/90"
          >
            Stemmingen opslaan
          </Button>
        </CardContent>
      </Card>

      <Card className="border-[var(--wm-border)] bg-wm-card shadow-none">
        <CardHeader>
          <CardTitle className="text-wm-cream">Inclusiviteitstags</CardTitle>
          <p className="text-sm text-muted-foreground">
            Gebruikers kunnen hierop filteren. Wijzigingen worden direct
            opgeslagen.
          </p>
        </CardHeader>
        <CardContent className="space-y-4">
          {INCLUSION_FIELDS.map(({ key, label }) => {
            const checked = Boolean(
              listing[key as keyof typeof listing] as boolean | null,
            );
            return (
              <div key={key} className="flex items-center justify-between gap-4">
                <Label htmlFor={key}>{label}</Label>
                <Switch
                  id={key}
                  checked={checked}
                  onCheckedChange={(v) => {
                    void toggleInclusion(key, v);
                  }}
                />
              </div>
            );
          })}
        </CardContent>
      </Card>

      <Card className="border-[var(--wm-border)] bg-wm-card opacity-80 shadow-none">
        <CardHeader>
          <CardTitle className="text-wm-cream">Foto&apos;s (binnenkort)</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            Upload foto&apos;s van je zaak. Binnenkort beschikbaar.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
