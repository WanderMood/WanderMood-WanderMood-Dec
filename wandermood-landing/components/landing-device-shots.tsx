"use client";

import Image from "next/image";
import { PhoneMockup } from "@/components/PhoneMockup";

export function PhoneShot({
  src,
  alt,
  priority,
  className,
}: {
  src: string;
  alt: string;
  priority?: boolean;
  className?: string;
}) {
  return (
    <div className={`landing-device-shell ${className ?? ""}`}>
      <div className="landing-device-screen">
        <Image
          src={src}
          alt={alt}
          fill
          className="landing-device-img"
          sizes="(max-width: 900px) 78vw, 240px"
          priority={priority}
        />
      </div>
    </div>
  );
}

/**
 * Preset: screenshot inside {@link PhoneMockup} with Pro-style side buttons.
 * `showIsland` defaults false — most simulator captures already include the island.
 */
export function IPhone16ProMaxShot({
  src,
  alt,
  className,
  sizes = "(max-width: 900px) 90vw, 300px",
  railMaxWidthPx,
  showIsland = false,
}: {
  src: string;
  alt: string;
  className?: string;
  sizes?: string;
  railMaxWidthPx?: number;
  showIsland?: boolean;
}) {
  return (
    <PhoneMockup
      sideButtons
      showIsland={showIsland}
      className={className}
      railMaxWidthPx={railMaxWidthPx}
    >
      <Image src={src} alt={alt} fill sizes={sizes} />
    </PhoneMockup>
  );
}
