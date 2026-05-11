"use client";

import Image from "next/image";
import styles from "./phone-frame.module.css";

type Props = {
  src: string;
  alt: string;
  priority?: boolean;
  className?: string;
};

export function PhoneFrame({ src, alt, priority, className }: Props) {
  return (
    <div className={[styles.frame, className].filter(Boolean).join(" ")}>
      <span className={styles.silent} aria-hidden />
      <span className={styles.volUp} aria-hidden />
      <span className={styles.volDown} aria-hidden />
      <div className={styles.screen}>
        <Image
          src={src}
          alt={alt}
          fill
          sizes="280px"
          priority={priority}
          className={styles.img}
        />
      </div>
    </div>
  );
}
