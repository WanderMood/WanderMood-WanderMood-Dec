# First-time App Store submission checklist

Load when the user mentions **first app**, **first time submitting**, or **new developer**. Walk through before the main code audit.

---

## Before you can submit (upload blockers)

- [ ] **Apple Developer Program** enrolled (~$99/year at developer.apple.com)
- [ ] **Latest Program License Agreement** accepted (banner on developer.apple.com if pending)
- [ ] **Paid apps / IAP:** Tax and banking complete in App Store Connect → **Agreements, Tax, and Banking**
- [ ] **App record** created in App Store Connect
- [ ] **Bundle ID** matches Xcode **exactly** (case-sensitive): e.g. `com.company.app` vs `com.company.App`
- [ ] **Primary language**, **pricing** (even if free)

## Xcode / signing

- [ ] **Distribution** certificate (Apple Distribution) in developer portal, installed locally
- [ ] **App Store** provisioning profile for the App ID
- [ ] Correct **Team** in Xcode → Signing & Capabilities
- [ ] Build with a **current** Xcode release appropriate for Apple’s requirements (check Apple’s minimum Xcode notes when submitting)

---

## Common first-time mistakes

| Mistake | What happens | Fix |
|--------|----------------|-----|
| Bundle ID mismatch ASC vs Xcode | Upload rejected | Copy-paste ID; match case |
| Missing/expired distribution cert | Archive/upload fails | Recreate in portal |
| License not accepted | Opaque upload block | Accept at developer.apple.com |
| Tax incomplete (paid/IAP) | Cannot distribute | Complete in ASC |
| Wrong team in Xcode | Signing errors | Pick correct team |
| App ID not registered | Profile/upload issues | Register identifier first |
| Development vs Distribution cert confusion | Wrong cert on archive | Use **Distribution** for App Store |

---

## Plain-English (vibe) version

1. **Paid Apple Developer account** — required to submit.
2. **Accept Apple’s agreement** when prompted — easy to miss; blocks everything.
3. **App Store Connect app** — bundle ID must **match Xcode exactly** (copy-paste).
4. **Distribution certificate** — create “Apple Distribution,” install, select correct team in Xcode.
5. **Tax/banking** — if you charge money or use IAP, finish in ASC before expecting live sales.

---

## Handoff to code audit

After confirming the checklist (or user says it’s already done), tell the user:

> Setup looks good — now let me scan your code for anything Apple would reject.

Then continue with the **Audit workflow** in `SKILL.md` (Info.plist, privacy manifest, location/IAP/deletion patterns).
