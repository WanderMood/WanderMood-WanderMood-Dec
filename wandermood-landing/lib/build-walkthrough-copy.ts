/**
 * Same six steps as the interactive tour / Remotion walkthrough.
 * Uses desktop-style nav copy for video (full link list in sentence).
 */
export function buildWalkthroughCopyForVideo(t: (key: string, values?: Record<string, string>) => string) {
  const navBody = t("tour.navBody", {
    how: t("nav.how"),
    moods: t("nav.moods"),
    business: t("nav.business"),
    download: t("nav.download"),
  });

  return {
    stepTitles: [
      t("tour.navTitle"),
      `${t("hero.title1")} ${t("hero.titleEm")} ${t("hero.title2")}`,
      `${t("how.title1")} ${t("how.titleEm")}`,
      `${t("moodsSection.title1")} ${t("moodsSection.titleEm")}`,
      `${t("b2b.titleBefore")}${t("b2b.titleEm")}`,
      `${t("cta.title1")} ${t("cta.titleEm")}`,
    ],
    stepBodies: [
      navBody,
      t("hero.sub"),
      t("how.sub"),
      t("tour.moodsBody"),
      t("b2b.desc1"),
      t("cta.sub"),
    ],
  };
}
