---
name: flutter-app-store-readiness
description: Audits Flutter and cross-platform (React Native, etc.) iOS apps for App Store rejection patterns, Info.plist privacy strings, account deletion, IAP, networking, and first-time submission blockers. Use when the user mentions App Store, TestFlight, Apple review, rejection, IAP, account deletion, privacy manifest, first submission, or iOS compliance for a Flutter project.
---

# Flutter / cross-platform App Store readiness

## When to load

- Stack is **Flutter**, **React Native**, or similar (not pure native Swift only).
- User asks: App Store, TestFlight, review, rejection, **first app**, **first submission**, compliance, **PrivacyInfo.xcprivacy**, permissions, **Sign in with Apple**, **IAP**, account deletion, **Guideline 4.8**, **5.1.1**.

## Audit workflow

1. **First-time submitter?** If the user signals “first app” / “never submitted,” walk through [first-submission-checklist.md](first-submission-checklist.md) first (Developer Program, ASC record, signing, tax). Then say: *Setup looks good — now scanning the project for rejection risks.* Continue with steps 2–5.

2. **Project paths (Flutter)**  
   - Permissions: `ios/Runner/Info.plist` (not `pubspec.yaml`).  
   - Privacy manifest: `ios/**/PrivacyInfo.xcprivacy` if present.  
   - Entitlements: `*.entitlements`, Xcode Signing & Capabilities.

3. **Code scan** — Check against [flutter-app-store-patterns.md](flutter-app-store-patterns.md):  
   location permission order, account deletion (in-app vs mailto-only), UGC block/report, IAP vs external payments, `https` + hostnames, restore purchases.

4. **WanderMood-specific hooks** (if this repo): magic link + `social_auth`; subscription UI vs StoreKit; `delete_account_screen`; `Info.plist` usage strings; launch assets.

5. **Output** — Short verdict table: **Risk** (High/Med/Low), **Finding**, **Fix**, **File**. Offer diffs only when the user asks to implement.

## Progressive disclosure

| File | Contents |
|------|----------|
| [flutter-app-store-patterns.md](flutter-app-store-patterns.md) | Location, account deletion, block user, IAP, Info.plist keys, IPv6, ASC metadata, TestFlight vs release |
| [first-submission-checklist.md](first-submission-checklist.md) | Pre-upload blockers, common mistakes table, plain-English checklist |

## Principles

- **Rejection patterns** are illustrative; always verify against **current** Apple guidelines and the **actual** code path.
- Flutter **release** builds can differ from debug — recommend **device test of release IPA** before submit.
- **Firebase App Distribution ≠ TestFlight**; Apple betas for external testers are TestFlight.
