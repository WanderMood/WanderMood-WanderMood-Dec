"use client";

import type { CSSProperties, ReactNode } from "react";
import styles from "./phone-mockup.module.css";

export type PhoneMockupProps = {
  /** Content inside the clipped screen (e.g. `<Image fill alt="" src="" />`). */
  children: ReactNode;
  /** Decorative hardware stripes (volume, power, camera control). */
  sideButtons?: boolean;
  /** Pill at top of bezel; set false if the screenshot already includes the island. */
  showIsland?: boolean;
  className?: string;
  /** Max width of the metallic outer rail in pixels (default 268). */
  railMaxWidthPx?: number;
};

/**
 * Reusable device chrome for marketing: outer body, inner bezel, Dynamic Island,
 * overflow-clipped screen. Does not style the screenshot directly beyond the screen clip.
 */
export function PhoneMockup({
  children,
  sideButtons = false,
  showIsland = true,
  className,
  railMaxWidthPx = 268,
}: PhoneMockupProps) {
  const railStyle = {
    "--phone-mockup-rail-max": `${railMaxWidthPx}px`,
  } as CSSProperties;

  return (
    <div className={[styles.root, className].filter(Boolean).join(" ")}>
      {sideButtons ? (
        <>
          <span className={`${styles.sideBtn} ${styles.sideBtnVolUp}`} aria-hidden />
          <span className={`${styles.sideBtn} ${styles.sideBtnVolDown}`} aria-hidden />
          <span className={`${styles.sideBtn} ${styles.sideBtnPower}`} aria-hidden />
          <span className={`${styles.sideBtn} ${styles.sideBtnCamera}`} aria-hidden />
        </>
      ) : null}
      <div className={styles.body} style={railStyle}>
        <div className={styles.bezel}>
          {showIsland ? <div className={styles.island} aria-hidden /> : null}
          <div className={styles.screen}>{children}</div>
        </div>
      </div>
    </div>
  );
}
