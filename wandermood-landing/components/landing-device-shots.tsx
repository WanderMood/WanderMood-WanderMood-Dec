"use client";

import Image from "next/image";

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

/** iPhone 16 Pro Max–style frame: titanium rail + side controls (CSS). */
export function IPhone16ProMaxShot({
  src,
  alt,
  className,
  sizes = "(max-width: 900px) 90vw, 300px",
}: {
  src: string;
  alt: string;
  className?: string;
  sizes?: string;
}) {
  return (
    <div className={`landing-iphone16 ${className ?? ""}`}>
      <span className="landing-iphone16-btn landing-iphone16-btn--vol-up" aria-hidden />
      <span className="landing-iphone16-btn landing-iphone16-btn--vol-down" aria-hidden />
      <span className="landing-iphone16-btn landing-iphone16-btn--power" aria-hidden />
      <span className="landing-iphone16-btn landing-iphone16-btn--camera-ctl" aria-hidden />
      <div className="landing-iphone16-rail">
        <div className="landing-iphone16-inner">
          <div className="landing-iphone16-screen">
            <Image src={src} alt={alt} fill className="landing-iphone16-img" sizes={sizes} />
          </div>
        </div>
      </div>
    </div>
  );
}
