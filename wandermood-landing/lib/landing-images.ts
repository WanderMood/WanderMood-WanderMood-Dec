/** Real app screenshots under /public/landing — EN vs NL where available. */
export type LandingImageSet = {
  heroPhone: string;
  heroMoodFloat: string;
  stepMood: string;
  stepMoody: string;
  stepPlan: string;
  stepDetail: string;
  meetMoody: string;
  moodMatch: string;
  moodMatchWait: string;
  explore: string;
  placeDetail: string;
  floatChat: string;
  floatMood: string;
  floatCard: string;
};

export function getLandingImages(locale: string): LandingImageSet {
  const isNl = locale === "nl";
  return {
    heroPhone: isNl ? "/landing/nl-my-plans.png" : "/landing/en-my-day.png",
    heroMoodFloat: isNl ? "/landing/nl-mood-pick.png" : "/landing/en-mood-evening.png",
    stepMood: isNl ? "/landing/nl-mood-pick.png" : "/landing/en-mood-pick.png",
    stepMoody: isNl ? "/landing/nl-moody-chat.png" : "/landing/en-moody-chat.png",
    stepPlan: isNl ? "/landing/nl-my-plans.png" : "/landing/en-my-day.png",
    stepDetail: isNl ? "/landing/nl-place-detail.png" : "/landing/en-place-detail.png",
    meetMoody: isNl ? "/landing/nl-moody-chat.png" : "/landing/en-moody-chat.png",
    moodMatch: isNl ? "/landing/nl-mood-match.png" : "/landing/en-mood-match.png",
    moodMatchWait: "/landing/en-mood-match-wait.png",
    explore: isNl ? "/landing/nl-explore.png" : "/landing/en-explore.png",
    placeDetail: isNl ? "/landing/nl-place-detail.png" : "/landing/en-place-detail.png",
    floatChat: "/landing/float-chat-bubble.png",
    floatMood: "/landing/float-mood-chip.png",
    floatCard: "/landing/float-activity-card.png",
  };
}
