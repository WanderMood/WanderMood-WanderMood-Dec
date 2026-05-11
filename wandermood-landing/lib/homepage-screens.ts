/** Homepage redesign — each asset used at most once per locale. */
export type HomepageScreens = {
  hero: string;
  moodyChat: string;
  myDay: string;
  explore: string;
  placeDetail: string;
  /** Mood Match duo — distinct from hero to avoid reusing the same asset twice. */
  moodMatchLeft: string;
};

export function getHomepageScreens(locale: string): HomepageScreens {
  const isNl = locale === "nl";
  return {
    hero: isNl ? "/landing/nl-mood-pick.png" : "/landing/en-mood-pick.png",
    moodyChat: isNl ? "/landing/nl-moody-chat.png" : "/landing/en-moody-chat.png",
    myDay: isNl ? "/landing/nl-my-day.png" : "/landing/en-my-day.png",
    explore: isNl ? "/landing/nl-explore.png" : "/landing/en-explore.png",
    placeDetail: isNl ? "/landing/nl-place-detail.png" : "/landing/en-place-detail.png",
    moodMatchLeft: isNl ? "/landing/nl-mood-match.png" : "/landing/en-mood-match.png",
  };
}
