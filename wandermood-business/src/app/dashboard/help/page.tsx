import Link from "next/link";

import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const faq = [
  {
    q: "Hoe werkt stemming-targeting?",
    a: "Gebruikers kiezen in de app hoe ze zich voelen. Als hun stemming overeenkomt met jouw instellingen, verschijn jij in hun Explore-feed en dagplannen.",
  },
  {
    q: "Wanneer zie ik analytics?",
    a: "Analytics worden bijgewerkt zodra gebruikers interactie hebben met jouw vermelding. Nieuwe partners zien de eerste data na een paar dagen.",
  },
  {
    q: "Hoe pas ik mijn vermelding aan?",
    a: "Ga naar 'Mijn vermelding' in het menu links. Je kunt je beschrijving, aanbieding en stemmingen zelf aanpassen.",
  },
  {
    q: "Hoe zeg ik mijn abonnement op?",
    a: "Ga naar 'Abonnement' en gebruik het klantenportaal om op te zeggen. Je behoudt toegang tot het einde van de betaalperiode.",
  },
  {
    q: "Kan ik mijn bedrijfsnaam wijzigen?",
    a: "Mail naar info@wandermood.com. We passen dit voor je aan.",
  },
];

export default function HelpPage() {
  return (
    <div className="mx-auto max-w-2xl space-y-8">
      <h1 className="text-xl font-semibold text-wm-cream">Help</h1>
      <div className="space-y-2">
        {faq.map((item) => (
          <details
            key={item.q}
            className="group rounded-lg border border-[var(--wm-border)] bg-wm-card px-4"
          >
            <summary className="cursor-pointer list-none py-4 font-medium text-wm-cream marker:content-none [&::-webkit-details-marker]:hidden">
              <span className="flex items-center justify-between gap-2">
                {item.q}
                <span className="text-muted-foreground transition group-open:rotate-180">▼</span>
              </span>
            </summary>
            <p className="border-t border-[var(--wm-border)] pb-4 pt-3 text-sm text-muted-foreground">
              {item.a}
            </p>
          </details>
        ))}
      </div>
      <div className="rounded-xl border border-[var(--wm-border)] bg-wm-card p-6 text-center">
        <p className="mb-4 text-sm text-muted-foreground">
          Vraag niet in de FAQ? Stuur ons een mail.
        </p>
        <Link
          href="mailto:info@wandermood.com"
          className={cn(
            buttonVariants({ size: "lg" }),
            "bg-wm-forest text-wm-cream hover:bg-wm-forest/90",
          )}
        >
          Mail info@wandermood.com
        </Link>
      </div>
    </div>
  );
}
