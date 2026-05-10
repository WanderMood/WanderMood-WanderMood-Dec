/**
 * App screenshots under /public/landing.
 * Filenames do not always match content — this map keys each slot to the
 * screen that actually matches the section copy (see inline comments).
 */
export type LandingImageSet = {
  heroPhone: string;
  stepMood: string;
  stepMoody: string;
  stepPlan: string;
  stepDetail: string;
  meetMoody: string;
  moodMatch: string;
  moodMatchWait: string;
  explore: string;
  placeDetail: string;
};

export function getLandingImages(locale: string): LandingImageSet {
  const isNl = locale === "nl";
  return {
    // NL: Moody-chat; EN: hub mood grid (no dedicated EN Moody-chat asset).
    heroPhone: isNl ? "/landing/nl-mood-pick.png" : "/landing/en-mood-pick.png",
    // Step 1 — mood grid: file is misnamed "en-mood-evening" but UI is NL hub.
    stepMood: isNl ? "/landing/en-mood-evening.png" : "/landing/en-mood-pick.png",
    // Step 2 — chat with recommendations (not "mood-pick" name).
    stepMoody: isNl ? "/landing/nl-mood-pick.png" : "/landing/nl-mood-pick.png",
    // Step 3 — timeline (file wrongly named nl-moody-chat).
    stepPlan: isNl ? "/landing/nl-moody-chat.png" : "/landing/en-my-day.png",
    stepDetail: isNl ? "/landing/nl-place-detail.png" : "/landing/en-place-detail.png",
    meetMoody: isNl ? "/landing/nl-mood-pick.png" : "/landing/en-mood-pick.png",
    // Mood Match: wait + picker (not place-detail mislabeled "mood-match-wait").
    moodMatchWait: isNl ? "/landing/nl-my-plans.png" : "/landing/en-moody-chat.png",
    // Outcome: shared plan in My Day.
    moodMatch: isNl ? "/landing/nl-moody-chat.png" : "/landing/en-my-day.png",
    explore: isNl ? "/landing/nl-explore.png" : "/landing/en-explore.png",
    placeDetail: isNl ? "/landing/nl-place-detail.png" : "/landing/en-place-detail.png",
  };
}
