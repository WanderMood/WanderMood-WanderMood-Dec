"use client";

import { useRef, useState, useEffect, useCallback } from "react";
import { motion } from "framer-motion";
import Image from "next/image";
import { useTranslations, useLocale } from "next-intl";
import { useRouter, usePathname } from "@/i18n/navigation";

const BRAND_GREEN = "#16a34a";

const CARD_IDS = ["app-preview", "hero", "experience", "moods", "how-it-works", "cta"] as const;

const APP_PREVIEW_SCREENSHOTS = [
  "/screens/Simulator%20Screenshot%20-%20iPhone%2016%20Pro%20Max%20-%202026-03-14%20at%2022.09.17.png",
  "/screens/Simulator%20Screenshot%20-%20iPhone%2016%20Pro%20Max%20-%202026-03-14%20at%2022.11.50.png",
  "/screens/Simulator%20Screenshot%20-%20iPhone%2016%20Pro%20Max%20-%202026-03-14%20at%2022.16.41.png",
];

const AVATAR_OPTS = "mouth=smile&eyes=happy";
const REVIEWS = [
  { name: "Yara Swaab", rating: 5, initials: "YS", avatar: `https://api.dicebear.com/9.x/avataaars/png?seed=YaraSwaab&${AVATAR_OPTS}` },
  { name: "Lizanne van Sprang", rating: 5, initials: "LvS", avatar: `https://api.dicebear.com/9.x/avataaars/png?seed=LizanneVanSprang&${AVATAR_OPTS}` },
  { name: "Euan Huber", rating: 5, initials: "EH", avatar: `https://api.dicebear.com/9.x/avataaars/png?seed=EuanHuber&${AVATAR_OPTS}` },
  { name: "Jaden Fischer", rating: 5, initials: "JF", avatar: `https://api.dicebear.com/9.x/avataaars/png?seed=JadenFischer&${AVATAR_OPTS}` },
  { name: "Mohamed Sandoval", rating: 4, initials: "MS", avatar: `https://api.dicebear.com/9.x/avataaars/png?seed=MohamedSandoval&${AVATAR_OPTS}` },
];

const MOODS_GRID_KEYS = ["happy", "adventurous", "relaxed", "energetic", "romantic", "social", "cultural", "curious", "cozy", "excited", "foody", "surprise"] as const;
const MOODS_GRID_STYLE: Record<string, { emoji: string; bg: string; selected?: boolean }> = {
  happy: { emoji: "😊", bg: "bg-amber-100" },
  adventurous: { emoji: "🚀", bg: "bg-rose-100" },
  relaxed: { emoji: "😌", bg: "bg-teal-100" },
  energetic: { emoji: "⚡", bg: "bg-sky-100" },
  romantic: { emoji: "💕", bg: "bg-pink-100" },
  social: { emoji: "👥", bg: "bg-amber-50" },
  cultural: { emoji: "🎭", bg: "bg-violet-100" },
  curious: { emoji: "🔍", bg: "bg-orange-100" },
  cozy: { emoji: "☕", bg: "bg-stone-200/80" },
  excited: { emoji: "🤩", bg: "bg-emerald-100", selected: true },
  foody: { emoji: "🍽️", bg: "bg-orange-50", selected: true },
  surprise: { emoji: "😲", bg: "bg-sky-100", selected: true },
};

const MOCKUP_MOOD_KEYS = ["adventure", "relaxed", "foodie", "cultural", "nightOut"] as const;
const MOCKUP_MOOD_STYLE: Record<string, { emoji: string; bg: string }> = {
  adventure: { emoji: "🏔️", bg: "bg-rose-100" },
  relaxed: { emoji: "😌", bg: "bg-teal-100" },
  foodie: { emoji: "🍕", bg: "bg-amber-100" },
  cultural: { emoji: "🎨", bg: "bg-violet-100" },
  nightOut: { emoji: "🌙", bg: "bg-indigo-100" },
};

function getCardIndexFromHash(): number {
  if (typeof window === "undefined") return 0;
  const hash = window.location.hash.slice(1) || CARD_IDS[0];
  const i = CARD_IDS.indexOf(hash as (typeof CARD_IDS)[number]);
  return i >= 0 ? i : 0;
}

const LOCALES = [
  { code: "en", label: "EN" },
  { code: "nl", label: "NL" },
  { code: "de", label: "DE" },
  { code: "es", label: "ES" },
  { code: "fr", label: "FR" },
] as const;

function NavLink({ label, onPress }: { label: string; onPress: () => void }) {
  return (
    <button
      type="button"
      onClick={onPress}
      className="flex min-h-[48px] items-center rounded-xl px-4 text-left text-base font-medium text-zinc-800 hover:bg-zinc-100 active:bg-zinc-200"
    >
      {label}
    </button>
  );
}

export default function Home() {
  const tNav = useTranslations("nav");
  const tFooter = useTranslations("footer");
  const router = useRouter();
  const pathname = usePathname();
  const currentLocale = useLocale();
  const [activeIndex, setActiveIndex] = useState(0);
  const [navSolid, setNavSolid] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const scrollRef = useRef<HTMLElement | null>(null);
  const sectionRefs = useRef<(HTMLElement | null)[]>([]);

  const goTo = useCallback((index: number) => {
    setMenuOpen(false);
    const el = document.getElementById(CARD_IDS[index]);
    if (el) el.scrollIntoView({ behavior: "smooth", block: "start" });
    window.history.replaceState(null, "", `#${CARD_IDS[index]}`);
  }, []);

  useEffect(() => {
    const hash = window.location.hash.slice(1);
    if (hash) {
      const i = CARD_IDS.indexOf(hash as (typeof CARD_IDS)[number]);
      if (i >= 0) {
        setActiveIndex(i);
        const el = document.getElementById(CARD_IDS[i]);
        if (el) el.scrollIntoView({ behavior: "instant", block: "start" });
      }
    }
  }, []);

  useEffect(() => {
    const container = scrollRef.current;
    if (!container) return;
    const observer = new IntersectionObserver(
      (entries) => {
        let best: { i: number; ratio: number } | null = null;
        for (const entry of entries) {
          const id = (entry.target as HTMLElement).id;
          const i = CARD_IDS.indexOf(id as (typeof CARD_IDS)[number]);
          if (i >= 0 && entry.intersectionRatio > 0.2 && (!best || entry.intersectionRatio > best.ratio)) {
            best = { i, ratio: entry.intersectionRatio };
          }
        }
        if (best) {
          setActiveIndex(best.i);
          window.history.replaceState(null, "", `#${CARD_IDS[best.i]}`);
        }
      },
      { root: container, threshold: [0.2, 0.5, 0.8] }
    );
    sectionRefs.current.forEach((el) => el && observer.observe(el));
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    const onHashChange = () => {
      const i = getCardIndexFromHash();
      setActiveIndex(i);
      document.getElementById(CARD_IDS[i])?.scrollIntoView({ behavior: "smooth", block: "start" });
    };
    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, []);

  useEffect(() => {
    setNavSolid(activeIndex > 0);
  }, [activeIndex]);

  return (
    <div className="min-h-screen bg-[#fffdf5]">
      <motion.nav
        initial={false}
        animate={{
          backgroundColor: navSolid ? "rgba(255,255,255,0.95)" : "rgba(255,255,255,0)",
          borderColor: navSolid ? "rgba(0,0,0,0.06)" : "transparent",
        }}
        transition={{ duration: 0.2 }}
        className="fixed left-0 right-0 top-0 z-50 border-b backdrop-blur-sm safe-top"
      >
        <div className="mx-auto flex h-14 min-h-[44px] max-w-6xl items-center justify-between px-4 sm:px-6 md:h-16">
          <button
            type="button"
            onClick={() => goTo(0)}
            className={`text-lg font-bold tracking-tight transition-colors sm:text-xl ${
              !navSolid && activeIndex === 1 ? "text-white" : "text-zinc-900"
            }`}
            style={{ fontFamily: "var(--font-museo)" }}
          >
            {tNav("brand")}
          </button>
          {/* Desktop nav */}
          <div className={`hidden items-center gap-4 text-sm font-medium transition-colors md:flex md:gap-6 ${
            !navSolid && activeIndex === 1 ? "text-white/90 hover:text-white" : "text-zinc-600 hover:text-zinc-900"
          }`}>
            <button type="button" onClick={() => goTo(0)} className="hover:text-zinc-900">{tNav("theApp")}</button>
            <button type="button" onClick={() => goTo(2)} className="hover:text-zinc-900">{tNav("experience")}</button>
            <button type="button" onClick={() => goTo(3)} className="hover:text-zinc-900">{tNav("moods")}</button>
            <button type="button" onClick={() => goTo(4)} className="hover:text-zinc-900">{tNav("howItWorks")}</button>
            <div className="flex items-center gap-1 rounded-full border border-zinc-200 bg-white/80 p-0.5">
              {LOCALES.map(({ code, label }) => (
                <button
                  key={code}
                  type="button"
                  onClick={() => router.replace(pathname, { locale: code })}
                  className={`rounded-full px-2 py-1 text-xs font-medium transition-colors ${
                    currentLocale === code ? "bg-emerald-100 text-emerald-800" : "text-zinc-600 hover:bg-zinc-100"
                  }`}
                  aria-label={`Switch to ${label}`}
                >
                  {label}
                </button>
              ))}
            </div>
            <button
              type="button"
              onClick={() => goTo(5)}
              className="rounded-full px-5 py-2.5 font-semibold text-white transition-transform hover:scale-105 active:scale-95"
              style={{ backgroundColor: BRAND_GREEN }}
            >
              {tNav("download")}
            </button>
          </div>
          {/* Mobile: hamburger */}
          <button
            type="button"
            onClick={() => setMenuOpen((o) => !o)}
            className={`flex h-10 w-10 min-h-[44px] min-w-[44px] items-center justify-center rounded-lg md:hidden ${
              !navSolid && activeIndex === 1 ? "text-white hover:bg-white/10" : "text-zinc-700 hover:bg-zinc-100"
            }`}
            aria-label={menuOpen ? "Close menu" : "Open menu"}
            aria-expanded={menuOpen}
          >
            {menuOpen ? (
              <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
            ) : (
              <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" /></svg>
            )}
          </button>
        </div>
        {/* Mobile menu overlay */}
        {menuOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 top-[calc(3.5rem+env(safe-area-inset-top,0px))] z-40 bg-[#fffdf5] md:hidden"
            aria-hidden="true"
          >
            <div className="flex flex-col gap-1 px-4 py-6">
              <NavLink label={tNav("theApp")} onPress={() => goTo(0)} />
              <NavLink label={tNav("experience")} onPress={() => goTo(2)} />
              <NavLink label={tNav("moods")} onPress={() => goTo(3)} />
              <NavLink label={tNav("howItWorks")} onPress={() => goTo(4)} />
              <div className="my-4 flex flex-wrap gap-2">
                {LOCALES.map(({ code, label }) => (
                  <button
                    key={code}
                    type="button"
                    onClick={() => router.replace(pathname, { locale: code })}
                    className={`min-h-[44px] min-w-[44px] rounded-full px-3 text-sm font-medium transition-colors ${
                      currentLocale === code ? "bg-emerald-100 text-emerald-800" : "bg-zinc-100 text-zinc-700"
                    }`}
                    aria-label={`Switch to ${label}`}
                  >
                    {label}
                  </button>
                ))}
              </div>
              <button
                type="button"
                onClick={() => goTo(5)}
                className="mt-4 flex min-h-[48px] items-center justify-center rounded-full font-semibold text-white"
                style={{ backgroundColor: BRAND_GREEN }}
              >
                {tNav("download")}
              </button>
            </div>
          </motion.div>
        )}
      </motion.nav>

      {/* Section dots: bottom center on mobile (touch-friendly), right side on desktop */}
      <div className="fixed bottom-24 left-1/2 z-50 flex -translate-x-1/2 flex-row gap-1 md:bottom-auto md:left-auto md:right-4 md:top-1/2 md:-translate-x-0 md:-translate-y-1/2 md:flex-col md:gap-2 safe-bottom">
        {CARD_IDS.map((_, i) => (
          <button
            key={i}
            type="button"
            onClick={() => goTo(i)}
            className="flex min-h-[44px] min-w-[44px] flex-shrink-0 items-center justify-center rounded-full transition-colors md:min-h-0 md:min-w-0 md:py-2"
            aria-label={`Go to section ${i + 1}`}
          >
            <span className={`rounded-full transition-all ${
              i === activeIndex ? "h-2 w-6 bg-zinc-900" : "h-2 w-2 bg-zinc-300 hover:bg-zinc-400"
            }`} />
          </button>
        ))}
      </div>

      <main
        ref={scrollRef}
        className="h-screen overflow-y-auto overflow-x-hidden snap-y snap-mandatory bg-[#fffdf5] scroll-smooth pb-24 pt-16 md:pb-0"
        style={{ scrollSnapType: "y mandatory" }}
      >
        <section id={CARD_IDS[0]} ref={(el) => { sectionRefs.current[0] = el; }} className="min-h-screen w-full shrink-0 snap-start scroll-mt-16 bg-[#fffdf5]">
          <AppPreviewCard onNext={() => goTo(1)} />
        </section>
        <section id={CARD_IDS[1]} ref={(el) => { sectionRefs.current[1] = el; }} className="min-h-screen w-full shrink-0 snap-start bg-zinc-900">
          <HeroCard onNext={() => goTo(2)} />
        </section>
        <section id={CARD_IDS[2]} ref={(el) => { sectionRefs.current[2] = el; }} className="min-h-screen w-full shrink-0 snap-start bg-[#fffdf5] pt-16">
          <ExperienceCard onBack={() => goTo(1)} onNext={() => goTo(3)} />
        </section>
        <section id={CARD_IDS[3]} ref={(el) => { sectionRefs.current[3] = el; }} className="min-h-screen w-full shrink-0 snap-start bg-[#fffdf5] pt-16">
          <MoodsCard onBack={() => goTo(2)} onNext={() => goTo(4)} />
        </section>
        <section id={CARD_IDS[4]} ref={(el) => { sectionRefs.current[4] = el; }} className="min-h-screen w-full shrink-0 snap-start bg-[#fffdf5] pt-16">
          <HowItWorksCard onBack={() => goTo(3)} onNext={() => goTo(5)} />
        </section>
        <section id={CARD_IDS[5]} ref={(el) => { sectionRefs.current[5] = el; }} className="min-h-screen w-full shrink-0 snap-start bg-[#fffdf5] pt-16">
          <CtaCard onBack={() => goTo(4)} />
        </section>
      </main>

      {activeIndex !== 0 && (
        <footer className="fixed bottom-0 left-0 right-0 z-40 border-t border-zinc-200/80 bg-[#fffdf5]/98 px-4 py-4 backdrop-blur-md safe-bottom sm:px-6">
          <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-3 text-sm">
            <span className="font-semibold" style={{ fontFamily: "var(--font-museo)", color: BRAND_GREEN }}>
              {tNav("brand")}
            </span>
            <nav className="flex items-center gap-6 text-zinc-500">
              <a href="#" className="hover:text-zinc-800">{tFooter("privacy")}</a>
              <a href="#" className="hover:text-zinc-800">{tFooter("contact")}</a>
            </nav>
            <span className="text-zinc-400">© {new Date().getFullYear()}</span>
          </div>
        </footer>
      )}
    </div>
  );
}

function HeroCard({ onNext }: { onNext: () => void }) {
  const t = useTranslations("hero");
  return (
    <section className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden px-6 text-center" aria-label="Hero">
      <div className="absolute inset-0 z-0">
        <Image
          src="https://images.unsplash.com/photo-1516483638261-f4dbaf036963?q=80&w=2574&auto=format&fit=crop"
          alt={t("imageAlt")}
          fill
          className="object-cover"
          priority
          sizes="100vw"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-black/30 via-black/20 to-black/60" />
      </div>
      <div className="relative z-10 flex flex-col items-center pt-20">
        <h1 className="text-4xl font-extrabold tracking-tight text-white drop-shadow-lg sm:text-5xl md:text-7xl lg:text-8xl xl:text-9xl" style={{ fontFamily: "var(--font-museo)" }}>
          {t("title")}
        </h1>
        <p className="mt-4 max-w-xl text-base font-medium text-white/90 drop-shadow-md sm:text-lg md:mt-6 md:text-2xl">{t("tagline")}</p>
        <motion.button
          type="button"
          onClick={onNext}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          className="mt-12 inline-flex h-16 min-w-[240px] items-center justify-center rounded-full px-8 text-lg font-bold text-white shadow-xl backdrop-blur-md transition-all hover:bg-white/20"
          style={{ backgroundColor: BRAND_GREEN }}
        >
          {t("cta")}
        </motion.button>
      </div>
    </section>
  );
}

function StatusBar() {
  return (
    <div className="flex h-9 items-center justify-between px-5 pt-2 text-[10px] font-medium text-zinc-700">
      <span className="font-mono">9:41</span>
      <div className="flex items-center gap-1.5">
        <span className="flex items-end gap-0.5">
          {[4, 6, 8, 10].map((h) => (
            <span key={h} className="w-0.5 rounded-sm bg-current" style={{ height: `${h}px` }} aria-hidden />
          ))}
        </span>
        <svg className="h-3 w-3" viewBox="0 0 24 24" fill="currentColor" aria-hidden><path d="M12 21l-1.5-1.5c2.5-2.5 6.5-2.5 9 0L18 21c-2-2-5.5-2-7.5 0zm3-4.5l-1.2-1.2c1.4-1.4 3.7-1.4 5.1 0L17 16.5c-1-1-2.6-1-3.5 0zm-6 0l-1.2 1.2c1.4 1.4 3.7 1.4 5.1 0L7 16.5c1-1 2.6-1 3.5 0zM12 9c-3.3 0-6 2.7-6 6l1.5 1.5C7.5 13 9.6 11 12 11s4.5 2 4.5 4.5L18 15c0-3.3-2.7-6-6-6z"/></svg>
        <span className="flex items-center gap-0.5">
          <span className="h-2.5 w-4 rounded-[2px] border border-current bg-current" aria-hidden />
          <span className="h-1.5 w-0.5 rounded-r-sm border border-l-0 border-current bg-current" aria-hidden />
        </span>
      </div>
    </div>
  );
}

function AppHeader() {
  return (
    <div className="flex h-11 shrink-0 items-center justify-between border-b border-zinc-100 px-4">
      <span className="text-sm font-bold tracking-tight" style={{ color: BRAND_GREEN, fontFamily: "var(--font-museo)" }}>WanderMood</span>
      <button type="button" className="flex h-8 w-8 items-center justify-center rounded-full text-zinc-500 hover:bg-zinc-100 hover:text-zinc-700" aria-label="Search">
        <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
      </button>
    </div>
  );
}

function TabBar() {
  const t = useTranslations("phoneMockup");
  const tabs = [
    { label: t("moody"), icon: "😊" },
    { label: t("myDay"), icon: "📅" },
    { label: t("feed"), icon: "✨" },
    { label: t("more"), icon: "⋯" },
  ];
  return (
    <div className="flex items-center justify-around border-t border-zinc-100 bg-white/80 py-2">
      {tabs.map((tab) => (
        <div key={tab.label} className="flex flex-col items-center gap-0.5">
          <span className="text-lg leading-none" aria-hidden>{tab.icon}</span>
          <span className="text-[9px] font-medium text-zinc-600">{tab.label}</span>
        </div>
      ))}
    </div>
  );
}

function DayCardsContent() {
  const t = useTranslations("phoneMockup");
  const items = [
    { period: t("morning"), label: t("coffeeJordaan"), image: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&q=80" },
    { period: t("afternoon"), label: t("rijksmuseum"), image: "https://images.unsplash.com/photo-1534351590666-13e3e96b5017?w=400&q=80" },
    { period: t("evening"), label: t("dinnerDrinks"), image: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&q=80" },
  ];
  const tMyDay = useTranslations("phoneMockup");
  return (
    <div className="flex-1 overflow-y-auto px-3 py-2">
      <p className="mb-2 text-[10px] font-semibold uppercase text-zinc-400">{tMyDay("myDay")}</p>
      {items.map((item) => (
        <div key={item.period} className="mb-2.5 flex overflow-hidden rounded-xl bg-white shadow-md">
          <div className="relative h-16 w-20 shrink-0">
            <Image src={item.image} alt="" fill className="object-cover" sizes="80px" />
          </div>
          <div className="flex flex-1 flex-col justify-center px-3 py-2">
            <span className="text-[9px] font-semibold uppercase tracking-wide text-zinc-400">{item.period}</span>
            <span className="text-xs font-medium text-zinc-800">{item.label}</span>
          </div>
        </div>
      ))}
    </div>
  );
}

function PhoneMockupContent() {
  const t = useTranslations("phoneMockup");
  const tMood = useTranslations("mockupMoods");
  const moodKeys = MOCKUP_MOOD_KEYS;
  return (
    <div className="flex h-[720px] flex-col rounded-[1.5rem] bg-[#fffdf5]">
      <StatusBar />
      <AppHeader />
      <div className="shrink-0 border-b border-zinc-100 px-4 py-3">
        <p className="text-center text-xs font-semibold text-zinc-500">{t("howDoYouFeel")}</p>
        <div className="mt-2 flex flex-wrap justify-center gap-2">
          {moodKeys.map((key) => (
            <div key={key} className={`flex flex-col items-center justify-center rounded-2xl px-3 py-2.5 shadow-md backdrop-blur-sm border border-white/50 ${MOCKUP_MOOD_STYLE[key].bg}`}>
              <span className="text-xl leading-none" aria-hidden>{MOCKUP_MOOD_STYLE[key].emoji}</span>
              <span className="mt-1.5 text-[10px] font-semibold text-zinc-800">{tMood(key)}</span>
            </div>
          ))}
        </div>
      </div>
      <DayCardsContent />
      <TabBar />
    </div>
  );
}

function ExperienceCard({ onBack, onNext }: { onBack: () => void; onNext: () => void }) {
  const t = useTranslations("experience");
  const tCards = useTranslations("featureCards");
  const featureCards = [
    { icon: "🎯", titleKey: "pickMood" as const },
    { icon: "📅", titleKey: "getYourDay" as const },
    { icon: "✨", titleKey: "wanderFeed" as const },
    { icon: "🎛️", titleKey: "advancedFilters" as const },
  ];
  return (
    <section className="min-h-[calc(100vh-5rem)] px-6 py-12 md:px-12 md:py-16">
      <div className="mx-auto grid max-w-6xl items-center gap-12 md:grid-cols-2 md:gap-16">
        <div className="flex justify-center">
          <div className="w-[320px] md:w-[380px]">
            <div className="relative overflow-hidden rounded-[2.75rem] border-[8px] border-zinc-700 p-1.5 shadow-2xl" style={{ background: "linear-gradient(145deg, #52525b 0%, #27272a 30%, #18181b 50%, #27272a 70%, #52525b 100%)" }}>
              <div className="absolute left-1/2 top-0 z-10 h-4 w-16 -translate-x-1/2 rounded-b-xl bg-zinc-800" aria-hidden />
              <div className="absolute left-0 top-0 z-10 h-full w-1.5 rounded-r-full bg-gradient-to-r from-zinc-400/60 via-zinc-500/25 to-transparent" aria-hidden />
              <div className="absolute right-0 top-0 z-10 h-full w-1.5 rounded-l-full bg-gradient-to-l from-zinc-400/60 via-zinc-500/25 to-transparent" aria-hidden />
              <div className="absolute left-0 right-0 top-0 z-10 h-2 rounded-b-full bg-gradient-to-b from-zinc-400/50 to-transparent" aria-hidden />
              <div className="absolute bottom-0 left-0 right-0 z-10 h-2 rounded-t-full bg-gradient-to-t from-zinc-500/30 to-transparent" aria-hidden />
              <div className="absolute -left-1 top-[12%] z-10 h-5 w-1 rounded-r-md bg-gradient-to-r from-zinc-400 to-zinc-600 shadow-[2px_0_4px_rgba(0,0,0,0.3)]" aria-hidden />
              <div className="absolute -left-1 top-[28%] z-10 h-8 w-1 rounded-r-md bg-gradient-to-r from-zinc-400 to-zinc-600 shadow-[2px_0_4px_rgba(0,0,0,0.3)]" aria-hidden />
              <div className="absolute -left-1 top-[40%] z-10 h-8 w-1 rounded-r-md bg-gradient-to-r from-zinc-400 to-zinc-600 shadow-[2px_0_4px_rgba(0,0,0,0.3)]" aria-hidden />
              <div className="absolute -right-1 top-[22%] z-10 h-14 w-1.5 rounded-l-full bg-gradient-to-l from-zinc-400 to-zinc-600 shadow-[-2px_0_4px_rgba(0,0,0,0.3)]" aria-hidden />
              <div className="overflow-hidden rounded-[1.75rem]">
                <PhoneMockupContent />
              </div>
            </div>
          </div>
        </div>
        <div>
          <p className="text-sm font-semibold uppercase tracking-wider text-emerald-600">{t("eyebrow")}</p>
          <h2 className="mt-2 text-3xl font-bold leading-tight md:text-4xl" style={{ fontFamily: "var(--font-museo)", color: BRAND_GREEN }}>{t("title")}</h2>
          <p className="mt-4 text-zinc-600">{t("intro")}</p>
          <div className="mt-8 space-y-4">
            {featureCards.map((card) => (
              <div key={card.titleKey} className="flex items-start gap-4 rounded-2xl border border-zinc-100 bg-white p-5 shadow-sm">
                <span className="text-2xl" aria-hidden>{card.icon}</span>
                <div>
                  <h3 className="font-bold text-zinc-900">{tCards(`${card.titleKey}.title`)}</h3>
                  <p className="mt-0.5 text-sm text-zinc-600">{tCards(`${card.titleKey}.line`)}</p>
                </div>
              </div>
            ))}
          </div>
          <div className="mt-8 flex gap-4">
            <button type="button" onClick={onBack} className="text-sm font-medium text-zinc-500 underline hover:text-zinc-700">{t("back")}</button>
            <motion.button type="button" onClick={onNext} whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }} className="rounded-full px-6 py-2.5 text-sm font-semibold text-white" style={{ backgroundColor: BRAND_GREEN }}>{t("nextButton")}</motion.button>
          </div>
        </div>
      </div>
    </section>
  );
}

function MoodsCard({ onBack, onNext }: { onBack: () => void; onNext: () => void }) {
  const t = useTranslations("moods");
  const tGrid = useTranslations("moodsGrid");
  return (
    <section className="min-h-[calc(100vh-5rem)] px-6 py-12 md:px-12 md:py-16">
      <div className="mx-auto grid max-w-6xl items-center gap-12 md:grid-cols-2 md:gap-16">
        <div>
          <p className="text-sm font-semibold uppercase tracking-wider text-emerald-600">{t("eyebrow")}</p>
          <h2 className="mt-4 text-3xl font-bold leading-tight text-zinc-900 md:text-4xl">{t("title")}</h2>
          <p className="mt-6 text-lg text-zinc-600">{t("subtitle")}</p>
          <div className="mt-8 flex gap-4">
            <button type="button" onClick={onBack} className="text-sm font-medium text-zinc-500 underline hover:text-zinc-700">{t("back")}</button>
            <motion.button type="button" onClick={onNext} whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }} className="rounded-full px-6 py-2.5 text-sm font-semibold text-white" style={{ backgroundColor: BRAND_GREEN }}>{t("nextButton")}</motion.button>
          </div>
        </div>
        <div className="grid grid-cols-3 gap-3 md:gap-4">
          {MOODS_GRID_KEYS.map((key) => (
            <div key={key} className={`relative flex flex-col items-center justify-center rounded-2xl p-5 shadow-md backdrop-blur transition-shadow hover:shadow-lg md:p-6 ${MOODS_GRID_STYLE[key].bg}`}>
              {MOODS_GRID_STYLE[key].selected && (
                <span className="absolute right-2 top-2 flex h-6 w-6 items-center justify-center rounded-full text-white" style={{ backgroundColor: BRAND_GREEN }}>
                  <svg className="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" /></svg>
                </span>
              )}
              <span className="text-3xl md:text-4xl">{MOODS_GRID_STYLE[key].emoji}</span>
              <p className="mt-2 text-center text-xs font-semibold text-zinc-800 md:text-sm">{tGrid(key)}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function HowItWorksCard({ onBack, onNext }: { onBack: () => void; onNext: () => void }) {
  const t = useTranslations("howItWorks");
  const tSteps = useTranslations("steps");
  const steps = [
    { icon: "😊", titleKey: "step1Title" as const, subtitleKey: "step1Subtitle" as const },
    { icon: "📅", titleKey: "step2Title" as const, subtitleKey: "step2Subtitle" as const },
    { icon: "✨", titleKey: "step3Title" as const, subtitleKey: "step3Subtitle" as const },
  ];
  return (
    <section className="relative min-h-[calc(100vh-5rem)] px-6 py-12 md:px-12 md:py-16">
      <p className="text-center text-sm font-semibold uppercase tracking-wider text-emerald-600">{t("eyebrow")}</p>
      <h2 className="mt-2 text-center text-3xl font-bold md:text-4xl" style={{ fontFamily: "var(--font-museo)", color: BRAND_GREEN }}>{t("title")}</h2>
      <p className="mt-3 text-center text-zinc-600">{t("subtitle")}</p>
      <div className="relative mx-auto mt-14 max-w-4xl">
        <div className="absolute left-0 right-0 top-[4.5rem] hidden h-0.5 md:block" aria-hidden>
          <div className="mx-auto h-full w-2/3 rounded-full bg-gradient-to-r from-emerald-200 via-emerald-300 to-emerald-200" />
        </div>
        <div className="grid gap-8 md:grid-cols-3">
          {steps.map((step, i) => (
            <motion.div
              key={step.titleKey}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{ duration: 0.4, delay: i * 0.1 }}
              className="relative rounded-2xl border border-zinc-100 bg-white p-8 text-center shadow-md transition-shadow hover:shadow-lg"
            >
              <div className="flex flex-col items-center">
                <span className="text-4xl" aria-hidden>{step.icon}</span>
                <span className="mt-2 inline-flex h-10 w-10 items-center justify-center rounded-full text-sm font-bold text-white" style={{ backgroundColor: BRAND_GREEN }}>{i + 1}</span>
              </div>
              <h3 className="mt-5 text-xl font-bold text-zinc-900">{tSteps(step.titleKey)}</h3>
              <p className="mt-2 text-zinc-600">{tSteps(step.subtitleKey)}</p>
            </motion.div>
          ))}
        </div>
      </div>
      <div className="mx-auto mt-12 flex max-w-md justify-center gap-4">
        <button type="button" onClick={onBack} className="text-sm font-medium text-zinc-500 underline hover:text-zinc-700">{t("back")}</button>
        <motion.button type="button" onClick={onNext} whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }} className="rounded-full px-6 py-2.5 text-sm font-semibold text-white" style={{ backgroundColor: BRAND_GREEN }}>{t("nextButton")}</motion.button>
      </div>
    </section>
  );
}

function BigPhoneMockup({ screenshot, alt }: { screenshot: string; alt: string }) {
  const [error, setError] = useState(false);
  return (
    <div className="overflow-hidden rounded-[2rem] border-[8px] border-zinc-700 bg-zinc-800 shadow-2xl" style={{ background: "linear-gradient(145deg, #52525b 0%, #27272a 50%, #52525b 100%)" }}>
      <div className="relative aspect-[9/19] w-full max-w-[280px] md:max-w-[320px]">
        {!error ? (
          <Image src={screenshot} alt={alt} fill className="object-cover object-top" sizes="320px" onError={() => setError(true)} />
        ) : (
          <div className="flex h-full w-full items-center justify-center bg-zinc-100 text-zinc-400">📱</div>
        )}
      </div>
    </div>
  );
}

function ReviewCard({ name, rating, initials, avatar, className }: { name: string; rating: number; initials: string; avatar?: string; className?: string }) {
  const stars = "★".repeat(5);
  return (
    <div className={`absolute z-30 flex items-center gap-3 rounded-2xl border border-zinc-100 bg-white p-3 shadow-lg ${className ?? ""}`}>
      <div className="relative h-10 w-10 shrink-0 overflow-hidden rounded-full bg-zinc-200">
        {avatar ? (
          <Image src={avatar} alt="" width={40} height={40} className="object-cover" />
        ) : (
          <span className="flex h-full w-full items-center justify-center text-sm font-semibold text-zinc-700">{initials}</span>
        )}
      </div>
      <div>
        <p className="text-sm font-semibold text-zinc-900">{name}</p>
        <p className="text-xs text-amber-600">{rating.toFixed(1)} {stars}</p>
      </div>
    </div>
  );
}

function AppPreviewCard({ onNext }: { onNext: () => void }) {
  const t = useTranslations("appPreview");
  const tPreviews = useTranslations("appPreviews");
  const previewKeys = ["pickMood", "myDay", "wanderFeed"] as const;
  return (
    <section className="relative min-h-[calc(100vh-5rem)] overflow-hidden px-6 py-12 md:px-12 md:py-16">
      <p className="text-center text-sm font-semibold uppercase tracking-wider text-emerald-600">{t("eyebrow")}</p>
      <h2 className="mt-2 text-center text-3xl font-bold md:text-4xl" style={{ fontFamily: "var(--font-museo)", color: BRAND_GREEN }}>{t("title")}</h2>
      <p className="mt-3 text-center text-base text-zinc-600">{t("subtitle")}</p>
      <div className="relative mx-auto mt-8 flex min-h-[320px] w-full max-w-5xl items-center justify-center sm:min-h-[400px] md:mt-12 md:min-h-[520px]">
        <div className="absolute left-0 top-[58%] z-10 w-[200px] sm:left-[2%] sm:w-[240px] md:left-[6%] md:w-auto" style={{ transform: "translateY(-50%) rotate(-14deg)" }}>
          <BigPhoneMockup screenshot={APP_PREVIEW_SCREENSHOTS[0]} alt={tPreviews("pickMood.label")} />
        </div>
        <div className="relative z-20 w-[220px] sm:w-[260px] md:w-auto">
          <BigPhoneMockup screenshot={APP_PREVIEW_SCREENSHOTS[1]} alt={tPreviews("myDay.label")} />
        </div>
        <div className="absolute right-0 top-[58%] z-10 w-[200px] sm:right-[2%] sm:w-[240px] md:right-[6%] md:w-auto" style={{ transform: "translateY(-50%) rotate(14deg)" }}>
          <BigPhoneMockup screenshot={APP_PREVIEW_SCREENSHOTS[2]} alt={tPreviews("wanderFeed.label")} />
        </div>
        <ReviewCard name={REVIEWS[0].name} rating={REVIEWS[0].rating} initials={REVIEWS[0].initials} avatar={REVIEWS[0].avatar} className="left-0 top-[8%] md:left-0 md:top-[12%]" />
        <ReviewCard name={REVIEWS[1].name} rating={REVIEWS[1].rating} initials={REVIEWS[1].initials} avatar={REVIEWS[1].avatar} className="right-0 top-[10%] md:right-0 md:top-[14%] translate-x-10 md:translate-x-16" />
        <ReviewCard name={REVIEWS[2].name} rating={REVIEWS[2].rating} initials={REVIEWS[2].initials} avatar={REVIEWS[2].avatar} className="right-0 top-[55%] md:right-0" />
        <ReviewCard name={REVIEWS[3].name} rating={REVIEWS[3].rating} initials={REVIEWS[3].initials} avatar={REVIEWS[3].avatar} className="left-0 bottom-[15%] md:left-0 md:bottom-[18%]" />
        <ReviewCard name={REVIEWS[4].name} rating={REVIEWS[4].rating} initials={REVIEWS[4].initials} avatar={REVIEWS[4].avatar} className="right-0 bottom-[12%] md:right-0 md:bottom-[14%] translate-x-4 md:translate-x-8" />
      </div>
      <div className="mx-auto mt-16 flex max-w-md justify-center">
        <motion.button type="button" onClick={onNext} whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }} className="rounded-full px-6 py-2.5 text-sm font-semibold text-white" style={{ backgroundColor: BRAND_GREEN }}>{t("nextButton")}</motion.button>
      </div>
    </section>
  );
}

function CtaCard({ onBack }: { onBack: () => void }) {
  const t = useTranslations("cta");
  return (
    <section className="flex min-h-full w-full flex-col items-center justify-center bg-[#fffdf5] px-6 py-24">
      <h2 className="text-center text-4xl font-bold md:text-5xl" style={{ fontFamily: "var(--font-museo)", color: BRAND_GREEN }}>{t("title")}</h2>
      <p className="mt-4 text-center text-lg text-zinc-600">{t("subtitle")}</p>
      <div className="mt-10 flex flex-wrap items-center justify-center gap-4">
        <motion.a href="#" whileHover={{ scale: 1.04 }} whileTap={{ scale: 0.98 }} className="inline-flex h-12 items-center gap-2 rounded-xl border-2 border-zinc-200 bg-white px-5 py-3 font-semibold text-zinc-800 transition hover:border-emerald-300 hover:bg-emerald-50" aria-label="Download on the App Store">
          <svg className="h-6 w-6" viewBox="0 0 24 24" fill="currentColor" aria-hidden><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19z"/></svg>
          {t("appStore")}
        </motion.a>
        <motion.a href="#" whileHover={{ scale: 1.04 }} whileTap={{ scale: 0.98 }} className="inline-flex h-12 items-center gap-2 rounded-xl border-2 border-zinc-200 bg-white px-5 py-3 font-semibold text-zinc-800 transition hover:border-emerald-300 hover:bg-emerald-50" aria-label="Get it on Google Play">
          <svg className="h-6 w-6" viewBox="0 0 24 24" aria-hidden><path fill="currentColor" d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.6 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.53,12.9 20.18,13.18L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z"/></svg>
          {t("googlePlay")}
        </motion.a>
      </div>
      <motion.a href="#" whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.98 }} className="mt-6 inline-flex h-14 min-w-[220px] items-center justify-center rounded-full font-semibold text-white shadow-lg" style={{ backgroundColor: BRAND_GREEN }}>{t("downloadButton")}</motion.a>
      <button type="button" onClick={onBack} className="mt-8 text-sm font-medium text-zinc-500 underline hover:text-zinc-700">{t("backToHowItWorks")}</button>
    </section>
  );
}
