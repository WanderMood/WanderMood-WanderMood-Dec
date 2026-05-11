"use client";

import Image from "next/image";
import styles from "./phone-frame.module.css";

type Props = {
  src: string;
  alt: string;
  priority?: boolean;
  /** Merged onto the outer wrapper (e.g. hero float animation). */
  className?: string;
  /** Feature bands use a narrower frame on mobile. */
  variant?: "hero" | "band";
};

export function PhoneFrame({ src, alt, priority, className, variant = "hero" }: Props) {
  const outerClass = [
    styles.phoneOuter,
    variant === "band" ? styles["phoneOuter--band"] : "",
    className,
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div className={outerClass}>
      <div className={styles.phoneFrame}>
        <div className={styles.phoneInner}>
          <div className={styles.phoneScreen}>
            <Image
              src={src}
              alt={alt}
              fill
              sizes={
              variant === "band"
                ? "(max-width: 767px) 180px, 260px"
                : "(max-width: 767px) 200px, 260px"
            }
              priority={priority}
              className={styles.img}
            />
          </div>
        </div>
      </div>
      <div className={styles.phonePowerBtn} aria-hidden />
      <div className={styles.phoneSilentBtn} aria-hidden />
      <div className={styles.phoneVolUp} aria-hidden />
      <div className={styles.phoneVolDown} aria-hidden />
    </div>
  );
}
