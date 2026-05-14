# Firebase Flutter Template

A multi-environment Flutter template with Firebase, Riverpod, Branch, Crashlytics, Remote Config, and push notifications. Supports dev, staging, and prod environments with email/password, phone, Google, and Apple sign-in.

---

## Project structure

```
lib/
├── bootstrap.dart               # All SDK initialisation — called by each entry point
├── main_dev.dart                # Dev entry point
├── main_staging.dart            # Staging entry point
├── main_prod.dart               # Prod entry point
├── app.dart                     # Root widget, theme, identity-sync providers
├── config/
│   ├── app_config.dart          # Environment singleton (appName, bundleId, branchKey, …)
│   └── remote_config_defaults.dart  # Remote Config keys + default values
├── firebase_options/            # Per-env Firebase config — replace with real values
│   ├── firebase_options_dev.dart
│   ├── firebase_options_staging.dart
│   └── firebase_options_prod.dart
├── providers/
│   ├── auth_providers.dart       # authStateProvider, authNotifierProvider
│   ├── branch_providers.dart     # branchDeepLinkProvider, branchIdentitySyncProvider
│   ├── crashlytics_providers.dart
│   ├── messaging_providers.dart  # fcmTokenProvider, foregroundMessageProvider, …
│   └── remote_config_provider.dart
├── router/app_router.dart
├── services/
│   ├── auth_service.dart
│   ├── branch_service.dart
│   └── messaging_service.dart
├── widgets/
│   ├── error_banner.dart
│   └── social_sign_in_buttons.dart
└── screens/
    ├── onboarding_screen.dart
    ├── home_screen.dart
    └── auth/
        ├── login_screen.dart
        ├── register_screen.dart
        └── phone_verification_screen.dart
scripts/
├── run_dev.bat / run_dev.sh
├── run_staging.bat / run_staging.sh
└── run_prod.bat / run_prod.sh
.secrets.example/                # Copy to ~/.secrets/<app-name>/ and fill in
```

---

## Prerequisites

Install the following tools if you haven't already:

**GitHub CLI** — for creating and cloning repos from the template:
```powershell
winget install GitHub.cli
gh auth login
```

**FVM** — Flutter version manager:
```powershell
dart pub global activate fvm
fvm install
```

**Firebase CLI** — for deploying rules and running `flutterfire configure`:
```powershell
npm install -g firebase-tools
firebase login
```

**FlutterFire CLI** — for generating per-environment Dart config files:
```powershell
fvm dart pub global activate flutterfire_cli
```

Invoke it via `fvm dart pub global run flutterfire_cli:flutterfire` (as shown in Step 4) so it uses the same Dart SDK as FVM rather than your system Dart.

`New-FirebaseApp.ps1` checks for `gh` and `fvm` at startup (the only tools it actually invokes) and exits early if either is missing. `firebase` and `flutterfire` are only needed during the manual Firebase setup in Step 4.

---

## Using this as a template

### Step 1 — Make it a standalone repo

```powershell
cd D:\apps\firebase_template
git init
git add .
git commit -m "Initial Firebase multi-env template"
gh repo create firebase_template --public --source=. --push
```

Then in GitHub → repo Settings → tick **Template repository**.

---

### Step 2 — Spawn a new project

Run the included script from the **parent folder** (the folder that contains `firebase_template`):

```powershell
.\firebase_template\New-FirebaseApp.ps1 -AppName my_new_app -OrgPrefix com.yourcompany -GitHubUsername yourghusername -ParentDir D:\apps
```

The script will show a summary and prompt for confirmation before doing anything. Add `-Force` to skip the prompt, or `-Public` to make the repo public.

`-ParentDir` is optional — if omitted, the project is cloned into whatever directory you run the script from.

**What the script does:**
- Creates a new private GitHub repo from the template and clones it
- Renames `firebase_template` → your app name throughout `pubspec.yaml`, `build.gradle.kts`, and all run scripts
- Updates the app display names in `main_dev.dart`, `main_staging.dart`, and `main_prod.dart`
- Creates `~/.secrets/<app-name>/` with correct bundle IDs pre-filled
- Runs `flutter pub get`

> **Manual alternative**
>
> <details>
> <summary>Manual steps</summary>
>
> ```powershell
> gh repo create my_new_app --template yourghusername/firebase_template --private --clone
> cd my_new_app
>
> # Rename references
> (Get-Content pubspec.yaml) -replace 'name: firebase_template', 'name: my_new_app' | Set-Content pubspec.yaml
> (Get-Content android\app\build.gradle.kts) -replace 'firebase_template', 'my_new_app' | Set-Content android\app\build.gradle.kts
>
> # Update run scripts
> (Get-Content scripts\run_dev.bat)     -replace 'firebase_template', 'my_new_app' | Set-Content scripts\run_dev.bat
> (Get-Content scripts\run_staging.bat) -replace 'firebase_template', 'my_new_app' | Set-Content scripts\run_staging.bat
> (Get-Content scripts\run_prod.bat)    -replace 'firebase_template', 'my_new_app' | Set-Content scripts\run_prod.bat
>
> # Create secrets
> New-Item -ItemType Directory "$env:USERPROFILE\.secrets\my_new_app"
> Copy-Item "$env:USERPROFILE\.secrets\firebase_template\*" "$env:USERPROFILE\.secrets\my_new_app\"
> # Then edit the three JSON files with your real values
> ```
>
> </details>

---

### Step 3 — Secrets files

The secrets directory at `~/.secrets/<app-name>/` has this structure:

```
~/.secrets/<app-name>/
  dev.json           ← dart-define secrets for dev builds
  staging.json       ← dart-define secrets for staging builds
  prod.json          ← dart-define secrets for prod builds
  dev/
    google-services.json
    GoogleService-Info.plist
    firebase_options.dart
  staging/
    google-services.json
    GoogleService-Info.plist
    firebase_options.dart
  prod/
    google-services.json
    GoogleService-Info.plist
    firebase_options.dart
```

The three top-level JSON files are passed to every build via `--dart-define-from-file`. The env subdirectories hold Firebase config — the run scripts copy these into the project before each build. None of this is ever committed.

The full dart-define format (see `.secrets.example/` for the template):

```json
{
  "APP_BUNDLE_ID": "com.yourcompany.app.dev",
  "APP_NAME": "MyApp Dev",
  "BRANCH_KEY": "key_test_…",
  "REVENUE_CAT_KEY_APPLE": "appl_…",
  "REVENUE_CAT_KEY_ANDROID": "goog_…"
}
```

- `dev.json` and `staging.json` use a Branch **test** key (`key_test_…`)
- `prod.json` uses a Branch **live** key (`key_live_…`)

---

### Step 4 — Firebase setup

Create three Firebase projects (e.g. `myapp-dev`, `myapp-staging`, `myapp-prod`) and for each:

1. Enable **Authentication** → Sign-in method → turn on **Email/Password**, **Phone**, **Google**, and **Apple**
2. Add an **Android app** with the bundle ID from your secrets file
3. Add an **iOS app** with the same bundle ID

Run `flutterfire configure` once per environment. This downloads `google-services.json` and `GoogleService-Info.plist` into the project and generates the Dart options file. Pass `--bundle-id` and `--android-package-name` explicitly so FlutterFire uses the correct per-environment identifiers rather than reading them from the Xcode project:

```
fvm dart pub global run flutterfire_cli:flutterfire configure --project=myapp-dev --out=lib/firebase_options/firebase_options_dev.dart --ios-bundle-id=com.yourcompany.myapp.dev --android-package-name=com.yourcompany.myapp.dev

fvm dart pub global run flutterfire_cli:flutterfire configure --project=myapp-staging --out=lib/firebase_options/firebase_options_staging.dart --ios-bundle-id=com.yourcompany.myapp.staging --android-package-name=com.yourcompany.myapp.staging

fvm dart pub global run flutterfire_cli:flutterfire configure --project=myapp-prod --out=lib/firebase_options/firebase_options_prod.dart --ios-bundle-id=com.yourcompany.myapp --android-package-name=com.yourcompany.myapp
```

Replace `myapp` with your app name and `com.yourcompany` with your org prefix — these match the values `New-FirebaseApp.ps1` writes to your secrets files.

> **Windows — `GoogleService-Info.plist`:** `flutterfire configure` on Windows skips this file — it requires a Mac/Xcode toolchain. Download it manually from Firebase Console → your iOS app → gear icon → **Download config file**, place it at `ios/Runner/GoogleService-Info.plist`, then run `save_firebase_config.ps1` as normal.

After each `flutterfire configure` run, save the outputs to the secrets directory:

```powershell
.\scripts\save_firebase_config.ps1 -Env dev
.\scripts\save_firebase_config.ps1 -Env staging
.\scripts\save_firebase_config.ps1 -Env prod
```

The run scripts copy these files back into the project before each build — the project directory copies are disposable, the secrets folder is the source of truth.

#### Firebase Console — App Check

App Check prevents unauthorised API calls. Do this for each of your three Firebase projects:

1. Firebase Console → **App Check** → **Get started**
2. Register your Android app with **Play Integrity** (prod) or **Debug provider** (dev/staging)
3. Register your iOS app with **App Attest** (prod) or **Debug provider** (dev/staging)
4. Once registered, go to each Firebase service (Auth, Firestore, Storage, etc.) → **Enforce**

**Debug tokens** (dev/staging only): On first run the SDK logs a debug token. Find it and register it:
- **Android**: run the app and search logcat for `FirebaseAppCheck` — copy the token
- **iOS Simulator**: the token is automatically trusted, no registration needed
- **iOS real device**: check the Xcode console for the token

Then: Firebase Console → App Check → your app → ⋮ → **Manage debug tokens** → paste it in.

#### Firebase Console — Crashlytics

1. Firebase Console → **Crashlytics** → **Get started** for each project
2. Run the app and trigger a test crash to verify the pipeline is working:
   ```dart
   FirebaseCrashlytics.instance.crash();
   ```
3. Crashes from dev are **not** sent (collection is disabled); staging and prod are enabled.

#### Firebase Console — Push Notifications (iOS APNs key)

Apple requires an APNs authentication key to deliver notifications:

1. [Apple Developer](https://developer.apple.com) → **Certificates, IDs & Profiles** → **Keys** → **+**
2. Tick **Apple Push Notifications service (APNs)** → Continue → Register → Download the `.p8` file
3. Firebase Console → **Project Settings** → **Cloud Messaging** → scroll to your iOS app → **APNs Authentication Key** → upload the `.p8`, enter your Key ID and Team ID

Do this once — the same APNs key works across dev, staging, and prod Firebase projects.

---

### Step 5 — Branch setup

1. Create a Branch account and a new app at [branch.io](https://branch.io)
2. Copy your **test key** (`key_test_…`) into `dev.json` and `staging.json` in your secrets folder
3. Copy your **live key** (`key_live_…`) into `prod.json`

#### Android

Replace `YOUR_BRANCH_DOMAIN` in `android/app/src/main/AndroidManifest.xml` with your Branch link domain (shown in the Branch dashboard under Configuration, e.g. `yourapp.app.link`).

The Branch key itself is injected automatically from your secrets file via `--dart-define-from-file` → Gradle `manifestPlaceholders` — no manual manifest edits needed for the key.

#### iOS

**Associated Domains** (required for Universal Links):

1. Xcode → select the **Runner** target → **Signing & Capabilities** → **+ Capability** → **Associated Domains**
2. Add: `applinks:yourapp.app.link`
3. If you have a custom Branch domain, add that too

**URL scheme** (for older link handling):

In `ios/Runner/Info.plist`, add your Branch URI scheme to `CFBundleURLTypes`:

```xml
<dict>
  <key>CFBundleTypeRole</key>
  <string>Editor</string>
  <key>CFBundleURLSchemes</key>
  <array>
    <string>yourapp</string>
  </array>
</dict>
```

---

### Step 6 — iOS Xcode capabilities

Open `ios/Runner.xcworkspace` in Xcode and add the following capabilities to the **Runner** target (Signing & Capabilities → **+ Capability**):

| Capability | Required for |
|---|---|
| **Sign In with Apple** | Apple authentication |
| **Push Notifications** | FCM push notifications |
| **Background Modes** → Remote notifications | Background push delivery |
| **Associated Domains** | Branch Universal Links (see Step 5) |

> **Background Modes** note: `UIBackgroundModes` with `remote-notification` is already in `Info.plist`, but you must also enable the capability in Xcode or iOS will ignore it.

**Google Sign-In** — open `ios/Runner/Info.plist` and replace the two placeholder values with values from your `GoogleService-Info.plist`:

```xml
<key>GIDClientID</key>
<string><!-- CLIENT_ID from GoogleService-Info.plist --></string>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string><!-- REVERSED_CLIENT_ID from GoogleService-Info.plist --></string>
    </array>
  </dict>
</array>
```

**Android Google Sign-In** — add your debug SHA-1 fingerprint to the Firebase console under Authentication → Google → SHA certificate fingerprints:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Android release signing** — replace the `signingConfig` stub in `android/app/build.gradle.kts` with your real keystore before building a release.

---

### Step 7 — Push notifications: requesting permission

Permission is **not** requested automatically on launch. Call this at a contextually appropriate moment (e.g. after the user has signed in and seen some value):

```dart
final settings = await ref.read(messagingServiceProvider).requestPermission();
if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  final token = await ref.read(messagingServiceProvider).getToken();
  // Send token to your backend here
  ref.invalidate(fcmTokenProvider); // refresh the token provider
}
```

**Handling incoming notifications** — four providers are available:

```dart
// In-app banner while app is foregrounded
ref.listen(foregroundMessageProvider, (_, next) {
  next.whenData((message) { /* show banner */ });
});

// User tapped a notification from the background
ref.listen(notificationOpenedProvider, (_, next) {
  next.whenData((message) { /* navigate */ });
});

// App cold-launched by a notification tap
ref.watch(initialMessageProvider).whenData((message) {
  if (message != null) { /* navigate */ }
});
```

---

## Running the app

```powershell
# Windows
scripts\run_dev.bat
scripts\run_staging.bat
scripts\run_prod.bat
```

```bash
# Mac / Git Bash
bash scripts/run_dev.sh
bash scripts/run_staging.sh
bash scripts/run_prod.sh
```

Or directly:

```bash
fvm flutter run \
  --dart-define-from-file=/Users/rlhowell/.secrets/my_new_app/dev.json \
  --target=lib/main_dev.dart
```

---

## Offline support

Firestore disk persistence is enabled with an unlimited cache size (configured in `bootstrap.dart`). When a device goes offline, `StreamProvider`s and `FutureProvider`s backed by Firestore automatically serve cached data — no extra code needed in your screens.

### Pinning collections

To ensure a collection is in the cache *before* the user navigates to it, add it to `lib/config/offline_config.dart`:

```dart
const List<OfflineCollection> offlineCollections = [
  // All documents in a global collection:
  OfflineCollection('products'),

  // Only documents belonging to the signed-in user:
  OfflineCollection('orders', userScoped: true, uidField: 'userId'),
];
```

`offlineSyncProvider` opens a live Firestore listener for each listed collection when the user signs in (and closes them on sign-out). This is the only place you need to edit — everything else is wired up automatically.

### How it works

```
Sign in ──▶ offlineSyncProvider
               │
               ├─▶ FirestoreOfflineSyncService.startSync(uid)
               │       opens snapshots() listeners per collection
               │       Firestore writes results to disk cache
               │
               └─▶ on sign-out: stopSync() → all listeners cancelled

Device goes offline
  │
  └─▶ Firestore StreamProviders return cached data transparently
```

### Writes while offline

Firestore queues writes locally and syncs them to the server automatically when connectivity is restored. No extra handling is required for creates, updates, and deletes — they appear immediately in the local cache and are committed to the server once online.

---

## Adding a Remote Config key

1. Add the key string to `lib/config/remote_config_defaults.dart`:

```dart
abstract final class RemoteConfigKeys {
  static const String showNewFeature = 'show_new_feature';
}

const Map<String, dynamic> remoteConfigDefaults = {
  RemoteConfigKeys.showNewFeature: false,
};
```

2. Add a typed getter to the extension in `lib/providers/remote_config_provider.dart`:

```dart
extension RemoteConfigValues on FirebaseRemoteConfig {
  bool get showNewFeature => getBool(RemoteConfigKeys.showNewFeature);
}
```

3. Set the value in Firebase Console → **Remote Config** → **+ Add parameter** for each project.

4. Read it anywhere:

```dart
final show = ref.watch(remoteConfigProvider).showNewFeature;
```

The default value is always used when the device is offline or before the first fetch completes.

---

## SDK behaviour by environment

| | Dev | Staging | Prod |
|---|---|---|---|
| **App Check** | Debug provider | Debug provider | Play Integrity / AppAttest |
| **Crashlytics** | Collection off | Collection on | Collection on |
| **Branch** | Test key, logging on | Test key, logging on | Live key, logging off |
| **Remote Config** | Fetch interval: 0 | Fetch interval: 5 min | Fetch interval: 1 hr |

---

## Analytics

Firebase Analytics is wired up automatically:

- **Screen tracking** — `FirebaseAnalyticsObserver` is registered with GoRouter; every navigation is logged automatically.
- **User identity** — `analyticsIdentitySyncProvider` sets the Analytics user ID when the user signs in and clears it on sign-out.
- **Custom events** — call `ref.read(analyticsServiceProvider).logEvent(...)` from any screen or notifier:

```dart
await ref.read(analyticsServiceProvider).logSignIn('email');
await ref.read(analyticsServiceProvider).logEvent('item_shared', parameters: {'item_id': id});
```

No setup is required beyond the Firebase project being configured. To disable Analytics collection (e.g. while respecting a user's tracking preference):

```dart
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
```

---

## In-app purchases (RevenueCat)

### Setup

1. Create a [RevenueCat](https://www.revenuecat.com) account and a new project.
2. Add your iOS app (App Store) and Android app (Play Store) in the RevenueCat dashboard.
3. Copy the **Apple API key** (`appl_…`) and **Google API key** (`goog_…`) into your secrets files under `REVENUE_CAT_KEY_APPLE` and `REVENUE_CAT_KEY_ANDROID`.
4. Configure your products and offerings in the RevenueCat dashboard.
5. Set up entitlement identifiers (e.g. `'pro'`) — these are what you check in code.

RevenueCat handles sandbox vs. production automatically based on the store receipt — you use the same API key in all environments.

### Usage

```dart
// Check whether the user has an active entitlement:
final isPro = ref.watch(hasEntitlementProvider('pro'));

// Fetch available packages and trigger a purchase:
final offerings = await ref.read(purchasesServiceProvider).getOfferings();
final package = offerings.current?.monthly;
if (package != null) {
  await ref.read(purchasesServiceProvider).purchasePackage(package);
  ref.invalidate(customerInfoProvider); // refresh entitlement state
}

// Restore purchases (required button in iOS apps):
await ref.read(purchasesServiceProvider).restorePurchases();
ref.invalidate(customerInfoProvider);
```

`purchasesIdentitySyncProvider` (watched in `App`) links the RevenueCat customer to the Firebase user automatically on sign-in/out.

---

## Firestore security rules

`firestore.rules` ships with a **deny-all default** and pre-built rules for the `users` collection. Deploy it with:

```bash
firebase deploy --only firestore:rules
```

Add rules for each collection you add. The file contains commented examples for global read-only collections and per-user document collections. Helper functions (`isSignedIn`, `isOwner`, `onlyUpdates`) are defined at the top.

---

## Security notes

- **Never commit** `google-services.json`, `GoogleService-Info.plist`, or `lib/firebase_options/` — these are already gitignored; keep the real files in `~/.secrets/` only
- Bundle IDs, app names, and Branch keys live in `~/.secrets/` and are never in the repo
- Firebase API keys for mobile are embedded in the app binary but access is restricted via Firebase Security Rules and App Check
- The APNs `.p8` key file should be stored securely and never committed
