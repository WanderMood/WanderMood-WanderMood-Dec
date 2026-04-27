# `go_router` map — path → screen

**Single source of `GoRoute` definitions:** `lib/core/router/router.dart`  
**Provider:** `@Riverpod(keepAlive: true) GoRouter router(...)` — do not dispose the router during the app lifetime.

**Important:** `redirect:` and auth / onboarding logic live in the same file (large block after `routes:`). Per project rules, **do not change redirects or startup-sensitive behaviour** unless that is an explicit product task.

## In-app tabs (no dedicated `GoRoute`)

| UI | Where |
|----|--------|
| **Explore** | `MainScreen` tab (see `lib/features/home/presentation/screens/main_screen.dart` — embeds `ExploreScreen`). |
| Other main tabs | Same `MainScreen`; entry is **`/main`** (query `tab`) or **`/home`**. |

## Top-level routes (alphabetical by path)

| Path | Route `name` (if set) | Screen / widget |
|------|----------------------|-----------------|
| `/` | `splash` | `SplashScreen` |
| `/adventure-plan` | `adventure-plan` | `AdventurePlanScreen` |
| `/agenda` | `agenda` | `AgendaScreen` |
| `/auth-callback` | `auth-callback` | `FutureBuilder` → `AuthWelcomeScreen` (magic link handling) |
| `/auth/magic-link` | `magic-link` | `MagicLinkSignupScreen` |
| `/auth/signup` | `auth-signup` | `MagicLinkSignupScreen` |
| `/auth/verify-email` | `verify-email` | **redirect** → `/auth/magic-link` |
| `/day-plan` | `day-plan` | `DayPlanScreen` (extra: activities, moods, moody copy) |
| `/demo` | `demo` | `MoodyDemoScreen` |
| `/gamification` | `gamification` | `GamificationScreen` |
| `/generate-plan` | `generate-plan` | `PlanLoadingScreen` |
| `/guest-day-plan` | `guest-day-plan` | `GuestDayPlanScreen` |
| `/guest-explore` | — | **redirect** → `/demo` |
| `/home` | `home` | `MainScreen` |
| `/intro` | `intro` | `AppIntroScreen` |
| `/main` | `main` | `MainScreen` (tab from `tab` query / extra) |
| `/mood` | `mood` | `MoodHomeScreen` |
| `/moods/history` | `mood-history` | `MoodHistoryScreen` |
| `/moody` | `moody-standalone` | `MoodHomeScreen` |
| `/notifications` | `notifications` | `NotificationCentreScreen` |
| `/onboarding` | `onboarding` | `OnboardingScreen` |
| `/place/:id` | `place-detail` | `PlaceDetailScreen` |
| `/places/saved` | `saved-places` | `SavedPlacesScreen` |
| `/preferences` | — | **redirect** → `/settings/preferences` |
| `/preferences/communication` | `communication-preferences` | `CommunicationPreferenceScreen` |
| `/preferences/interests` | `travel-interests` | `TravelInterestsScreen` (unauth → signup) |
| `/preferences/loading` | `preferences-loading` | `OnboardingLoadingScreen` |
| `/preferences/mood` | — | **redirect** → `/preferences/interests` |
| `/preferences/planning-pace` | `planning-pace` | `PlanningPaceScreen` |
| `/preferences/social-vibe` | `social-vibe` | `SocialVibeScreen` |
| `/preferences/style` | `travel-style` | `TravelStyleScreen` |
| `/preferences/travel-preferences` | `combined-travel-preferences` | `CombinedTravelPreferencesScreen` |
| `/profile` | `profile` | `UserProfileScreen` |
| `/profile/edit` | `edit-profile` | `EditProfileScreen` |
| `/profile/globe` | `globe` | `GlobeScreen` |
| `/recommendations` | `recommendations` | `RecommendationsPage` |
| `/register` | `register` | `MagicLinkSignupScreen` |
| `/settings` | `settings` | `ComprehensiveSettingsScreen` |
| `/settings/2fa` | `2fa` | `TwoFactorAuthScreen` |
| `/settings/account-security` | `account-security` | `AccountSecurityScreen` |
| `/settings/achievements` | `achievements-settings` | `AchievementsSettingsScreen` |
| `/settings/data` | `data-storage` | `DataStorageScreen` |
| `/settings/delete-account` | `delete-account` | `DeleteAccountScreen` |
| `/settings/help` | `help-support` | `HelpSupportScreen` |
| `/settings/language` | `language-settings` | `LanguageSettingsScreen` |
| `/settings/location` | `location-settings` | `LocationSettingsScreen` |
| `/settings/location/picker` | `location-picker` | `LocationPickerScreen` |
| `/settings/notifications` | `settings-notifications` | `NotificationsScreen` |
| `/settings/preferences` | `preferences` | `PreferencesScreen` |
| `/settings/premium-upgrade` | `premium-upgrade` | `PremiumUpgradeScreen` |
| `/settings/privacy` | `privacy` | `PrivacySettingsScreen` |
| `/settings/sessions` | `active-sessions` | `ActiveSessionsScreen` |
| `/settings/subscription` | `subscription` | `SubscriptionScreen` |
| `/settings/theme` | `theme-settings` | `ThemeSettingsScreen` |
| `/share-profile` | `share-profile` | `ShareProfileScreen` |
| `/social/create-post` | `create-post` | `CreatePostScreen` |
| `/social/create-story` | `create-story` | `CreateStoryScreen` |
| `/social/edit-profile` | `edit-social-profile` | `EditSocialProfileScreen` |
| `/social/messages` | `messages` | `MessageHubScreen` |
| `/social/post/:id` | `post-detail` | `PostDetailScreen` |
| `/social/profile/:id` | `social-profile` | `UnifiedProfileScreen` |
| `/social/stories` | `view-stories` | `ViewStoryScreen` |
| `/social/user-profile` | `user-profile` | `UnifiedProfileScreen` (current user) |
| `/support` | `support` | `SupportScreen` |
| `/view-receipt` | `view-receipt` | `ViewReceiptScreen` |
| `/weather` | `weather` | `WeatherPage` |

## Group planning (`pageBuilder` + shared transition)

| Path | Route `name` | Screen |
|------|--------------|--------|
| `/group-planning` | `group-planning` | `GroupPlanningHubScreen` |
| `/group-planning/confirmation/:sessionId` | `group-planning-confirmation` | `GroupPlanningConfirmationScreen` |
| `/group-planning/create` | `group-planning-create` | `GroupPlanningCreateScreen` |
| `/group-planning/day-picker/:sessionId` | `group-planning-day-picker` | `GroupPlanningDayPickerScreen` |
| `/group-planning/invite-wm/:sessionId` | `group-planning-invite-wm` | `GroupPlanningInviteWandererScreen` (+ redirect if no join code) |
| `/group-planning/join` | `group-planning-join` | `GroupPlanningJoinScreen` |
| `/group-planning/lobby/:sessionId` | `group-planning-lobby` | `GroupPlanningLobbyScreen` |
| `/group-planning/match-loading/:sessionId` | `group-planning-match-loading` | `GroupPlanningMatchLoadingScreen` |
| `/group-planning/reveal/:sessionId` | `group-planning-reveal` | `GroupPlanningRevealScreen` |
| `/group-planning/result/:sessionId` | `group-planning-result` | `GroupPlanningResultScreen` |
| `/group-planning/scan` | `group-planning-scan` | `GroupPlanningScanScreen` |
| `/group-planning/time-picker/:sessionId` | `group-planning-time-picker` | `GroupPlanningTimePickerScreen` |

## Debug-only

| Path | Notes |
|------|--------|
| `/admin` | Registered only when `kDebugMode`; placeholder scaffold (admin not loaded in production). |

## Legacy deep links (handled in `redirect`, not as `GoRoute`)

Examples: `/social/discovery`, `/travelers/discovery`, `/diaries`, `/diaries/*` → **`/main`**. See `redirect:` in `router.dart`.

---

When moving screens between folders, **grep** for `context.go(`, `context.push(`, and **path strings** that must stay in sync with this table.
