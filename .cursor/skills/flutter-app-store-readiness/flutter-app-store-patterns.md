# Flutter-specific App Store patterns (reference)

Load for audits when the stack is Flutter, React Native, or other cross-platform frameworks.

---

## Location (Flutter)

**Packages:** `geolocator`, `location`, or `permission_handler`.

### Rejection pattern — permission after access

```dart
// BAD: accessing location before requesting permission
Position position = await Geolocator.getCurrentPosition();

// BAD: check then use without awaiting request / handling denial
await Geolocator.checkPermission();
Position position = await Geolocator.getCurrentPosition();
```

### Correct pattern

```dart
// GOOD: request (or check then request), handle denial, then access
LocationPermission permission = await Geolocator.requestPermission();
if (permission == LocationPermission.denied ||
    permission == LocationPermission.deniedForever) {
  return;
}
Position position = await Geolocator.getCurrentPosition();
```

### Info.plist (still required in Flutter)

- **`ios/Runner/Info.plist`** — not `pubspec.yaml`.
- **`NSLocationWhenInUseUsageDescription`** (and if needed **Always** string) must be **specific** and honest.

**Weak string:** “This app requires location access.”

**Stronger string:** “Your location shows places near you and your city in the app. Not shared without your consent.”

---

## Account deletion (Flutter)

### Rejection pattern

- Opening **mailto** only, or only a **web form** in Safari, with **no** in-app completion path (Apple expects account deletion **in app** for apps that support account creation — verify current rule scope).

```dart
// BAD: deletion = email only
launchUrl(Uri(scheme: 'mailto', path: 'support@app.com', ...));
```

### Correct pattern

```dart
// GOOD: in-app flow + server + auth provider delete where applicable
Future<void> deleteAccount() async {
  final confirmed = await showConfirmationDialog(context);
  if (!confirmed) return;

  await authService.deleteAccount(); // server-side
  await supabase.auth.admin /* or user API */; // per your backend
  // Sign out and navigate to onboarding / welcome
}
```

**Multi-provider note:** If you use **Cognito + Firebase** (or similar), delete **both** identities; one-sided delete leaves orphans and re-registration bugs.

---

## Block user (UGC / social)

### Rejection pattern

- **Report only**, no **block**; user cannot stop seeing harassing content.

### Correct pattern

- **Block** action: server-side block list + **immediate** local UI update.
- Surface block from **profile** and **chat / messages** (or equivalent).
- **Security rules** must enforce block (e.g. cannot read/write across block).

---

## In-app purchases / subscriptions (Flutter)

**Packages:** `in_app_purchase`, `purchases_flutter` (RevenueCat), `qonversion`, etc.

### Rejection pattern

- **Stripe** or web checkout for **digital subscriptions / features** that should use IAP.
- **Credits** that unlock **digital** content without IAP.

### Correct pattern

- **StoreKit** (or RevenueCat/Qonversion) for digital goods on iOS.
- **Restore purchases** must exist in UI (commonly Settings).

```dart
await InAppPurchase.instance.restorePurchases();
// or Purchases.restorePurchases()
```

**Credits:** Physical-goods / real-world escrow can be outside IAP; **digital** unlocks generally need IAP.

---

## Privacy / permission strings (Flutter → Info.plist)

All usage descriptions live in **`ios/Runner/Info.plist`**.

Common keys:

| Key | When |
|-----|------|
| `NSLocationWhenInUseUsageDescription` | Location |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Always (if used) |
| `NSCameraUsageDescription` | Camera |
| `NSPhotoLibraryUsageDescription` | Photos |
| `NSMicrophoneUsageDescription` | Mic |
| `NSSpeechRecognitionUsageDescription` | Speech recognition |
| `NSContactsUsageDescription` | Contacts |
| `NSUserTrackingUsageDescription` | ATT / IDFA |

Empty or generic strings increase rejection risk. Match **Privacy Nutrition** / **PrivacyInfo.xcprivacy** to real behavior.

---

## IPv6 / network (Flutter)

**Packages:** `dio`, `http`, etc.

### Rejection pattern

- Hardcoded **IPv4** literals in production.
- **`http://`** production APIs (use **https** + hostname).

### Correct pattern

```dart
static const String baseUrl = 'https://api.example.com/v1';
```

Firebase / Amplify URLs managed by SDKs are generally fine; **your** base URLs are what matter.

---

## Metadata / App Store Connect

- Screenshots from a **real build** (not Figma-in-frame only).
- **Hot reload** can glitch UI — prefer **cold launch** for captures.
- **iPad:** If the app is on the store for iPad, supply iPad screenshots (simulator OK).

---

## TestFlight vs distribution

- **TestFlight** is Apple’s beta channel for external testers.
- **Firebase App Distribution** (or similar) ≠ App Store review readiness.
- Always validate **`flutter build ipa --release`** (or Xcode Archive) on a **physical device** before submit.
