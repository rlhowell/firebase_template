<#
.SYNOPSIS
    Spawns a new Flutter Firebase app from the firebase_template.

.DESCRIPTION
    Creates a new GitHub repo from the firebase_template, clones it, renames all
    project references, generates the secrets files with correct bundle IDs, and
    runs flutter pub get. Call this from the PARENT folder of where you want the
    new project to live.

.PARAMETER AppName
    Snake_case name for the new project (e.g. my_new_app).
    Becomes the Flutter package name, repo name, and secrets folder name.

.PARAMETER OrgPrefix
    Reverse-domain organisation prefix (e.g. com.yourcompany).
    Bundle IDs become: <OrgPrefix>.<AppName>[.dev|.staging]

.PARAMETER GitHubUsername
    Your GitHub username — used to locate the firebase_template repo.

.PARAMETER Public
    Make the new GitHub repo public. Defaults to private.

.PARAMETER ParentDir
    Directory to clone the new project into. Defaults to the current directory.
    The project lands at <ParentDir>\<AppName>.

.PARAMETER Force
    Skip the confirmation prompt.

.EXAMPLE
    .\firebase_template\New-FirebaseApp.ps1 -AppName hooped -OrgPrefix io.hooped -GitHubUsername rupert -ParentDir D:\apps
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AppName,
    [Parameter(Mandatory)][string]$OrgPrefix,
    [Parameter(Mandatory)][string]$GitHubUsername,
    [string]$ParentDir = (Get-Location).Path,
    [switch]$Public,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Step([string]$msg) {
    Write-Host "`n  ▶  $msg" -ForegroundColor Cyan
}

function Write-Ok([string]$msg) {
    Write-Host "     ✓  $msg" -ForegroundColor Green
}

function Write-Info([string]$label, [string]$value) {
    Write-Host ("  {0,-16} {1}" -f $label, $value) -ForegroundColor White
}

function Assert-Command([string]$name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Error "'$name' is not installed or not in PATH. Aborting."
        exit 1
    }
}

function ReplaceInFile([string]$path, [string]$old, [string]$new) {
    if (-not (Test-Path $path)) { return }
    $content = Get-Content $path -Raw
    $updated = $content -replace [regex]::Escape($old), $new
    if ($content -ne $updated) {
        Set-Content $path $updated -NoNewline
        Write-Ok $path
    }
}

# ── Validate inputs ───────────────────────────────────────────────────────────

if ($AppName -notmatch '^[a-z][a-z0-9_]*$') {
    Write-Error "AppName must be lowercase snake_case (e.g. my_new_app)."
    exit 1
}

if ($OrgPrefix -notmatch '^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$') {
    Write-Error "OrgPrefix must be a valid reverse domain (e.g. com.yourcompany)."
    exit 1
}

# ── Check prerequisites ───────────────────────────────────────────────────────

Write-Step "Checking prerequisites"
Assert-Command "gh"
Assert-Command "fvm"
Write-Ok "gh and fvm found"

$KeytoolPath = $null
foreach ($c in @(
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
    "C:\Program Files\Android\Android Studio\jre\bin\keytool.exe"
)) {
    if (Test-Path $c) { $KeytoolPath = $c; break }
}
if (-not $KeytoolPath) {
    $kt = Get-Command keytool -ErrorAction SilentlyContinue
    if ($kt) { $KeytoolPath = $kt.Source }
}
if ($KeytoolPath) {
    Write-Ok "keytool found"
} else {
    Write-Host "     ⚠  keytool not found — Android keystores will be skipped." -ForegroundColor Yellow
}

# ── Derive values ─────────────────────────────────────────────────────────────

$AppDisplayName  = (Get-Culture).TextInfo.ToTitleCase(($AppName -replace '_', ' '))
$BundleIdDev     = "$OrgPrefix.$AppName.dev"
$BundleIdStaging = "$OrgPrefix.$AppName.staging"
$BundleIdProd    = "$OrgPrefix.$AppName"
$SecretsDir      = "C:\Users\$env:USERNAME\.secrets\$AppName"
$TemplateRepo    = "$GitHubUsername/firebase_template"
$Visibility      = if ($Public) { '--public' } else { '--private' }
$resolved = Resolve-Path $ParentDir -ErrorAction SilentlyContinue
if ($resolved) { $ParentDir = $resolved.Path }
$ProjectDir      = Join-Path $ParentDir $AppName

Write-Host ""
Write-Host "  ┌─────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
Write-Host "  │  New app summary                                     │" -ForegroundColor DarkGray
Write-Host "  ├─────────────────────────────────────────────────────┤" -ForegroundColor DarkGray
Write-Info "  App name:"      $AppName
Write-Info "  Display name:"  $AppDisplayName
Write-Info "  Dev bundle:"    $BundleIdDev
Write-Info "  Staging bundle:" $BundleIdStaging
Write-Info "  Prod bundle:"   $BundleIdProd
Write-Info "  Secrets dir:"   $SecretsDir
Write-Info "  Project dir:"   $ProjectDir
Write-Info "  GitHub:"        "$GitHubUsername/$AppName ($( if ($Public) { 'public' } else { 'private' } ))"
Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "  Proceed? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "  Aborted." -ForegroundColor Yellow
        exit 0
    }
}

# ── Keystore passwords ────────────────────────────────────────────────────────

$DevPass     = ""
$StagingPass = ""
$ProdPass    = ""

if ($KeytoolPath) {
    Write-Host ""
    Write-Host "  Android signing keystores will be created at:" -ForegroundColor White
    Write-Host "    $SecretsDir\android\{dev,staging,prod}\$AppName-{env}.jks" -ForegroundColor Gray
    Write-Host "  Keep these passwords safe — losing them means you can never update the app." -ForegroundColor Yellow
    Write-Host ""
    do {
        $DevPass = Read-Host "  Dev keystore password"
        if ([string]::IsNullOrWhiteSpace($DevPass)) {
            Write-Host "     ✗  Password cannot be blank." -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($DevPass))
    $StagingPass = Read-Host "  Staging keystore password [Enter = same as dev]"
    $ProdPass    = Read-Host "  Prod keystore password    [Enter = same as dev]"
    if ([string]::IsNullOrWhiteSpace($StagingPass)) { $StagingPass = $DevPass }
    if ([string]::IsNullOrWhiteSpace($ProdPass))    { $ProdPass    = $DevPass }
}

# ── Clone from GitHub template ────────────────────────────────────────────────

Write-Step "Creating GitHub repo from template and cloning"

if (-not (Test-Path $ParentDir)) {
    New-Item -ItemType Directory -Force $ParentDir | Out-Null
    Write-Ok "Created $ParentDir"
}
Set-Location $ParentDir

$savedPref = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
$null = gh repo view "$GitHubUsername/$AppName"
$repoCreated = $LASTEXITCODE -eq 0
$ErrorActionPreference = $savedPref

if (-not $repoCreated) {
    gh repo create $AppName --template $TemplateRepo $Visibility
    if ($LASTEXITCODE -ne 0) {
        Write-Error "gh repo create failed."
        exit 1
    }
    Write-Ok "GitHub repo created from template"
    Start-Sleep -Seconds 3  # give GitHub time to initialise the repo from the template
} else {
    Write-Host "     ⚠  Repo $GitHubUsername/$AppName already exists — skipping create." -ForegroundColor Yellow
}

if (-not (Test-Path $AppName)) {
    $savedPref = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    gh repo clone "$GitHubUsername/$AppName"
    $cloneExit = $LASTEXITCODE
    $ErrorActionPreference = $savedPref
    if ($cloneExit -ne 0) {
        Write-Error "gh repo clone failed."
        exit 1
    }
} else {
    Write-Host "     ⚠  Folder '$AppName' already exists — skipping clone." -ForegroundColor Yellow
}

Write-Ok "Repo created and cloned into $ProjectDir"
Set-Location $AppName

# ── Rename project references ─────────────────────────────────────────────────

Write-Step "Renaming project references (firebase_template -> $AppName)"

ReplaceInFile "pubspec.yaml"                   "name: firebase_template"           "name: $AppName"
ReplaceInFile "android\app\build.gradle.kts"   "com.yourcompany.firebase_template" "$OrgPrefix.$AppName"
ReplaceInFile "scripts\run_dev.bat"            "firebase_template"                 $AppName
ReplaceInFile "scripts\run_staging.bat"        "firebase_template"        $AppName
ReplaceInFile "scripts\run_prod.bat"           "firebase_template"        $AppName
ReplaceInFile "scripts\run_dev.sh"             "firebase_template"        $AppName
ReplaceInFile "scripts\run_staging.sh"         "firebase_template"        $AppName
ReplaceInFile "scripts\run_prod.sh"            "firebase_template"        $AppName
ReplaceInFile "fastlane\Fastfile"              "YOUR_APP_NAME"            $AppName
ReplaceInFile "fastlane\Fastfile"              "com.yourcompany.yourapp"  $BundleIdProd
ReplaceInFile "android\app\build.gradle.kts"   "YOUR_APP_NAME"            $AppName

# Dart imports in test/ use the package name, which changes with the rename.
# Glob rather than naming files so tests added to the template stay covered.
Get-ChildItem "test" -Recurse -Filter *.dart -ErrorAction SilentlyContinue | ForEach-Object {
    ReplaceInFile $_.FullName "package:firebase_template/" "package:$AppName/"
}

# ── Update iOS bundle identifiers ─────────────────────────────────────────────

Write-Step "Updating iOS bundle identifiers"

$pbxproj = "ios\Runner.xcodeproj\project.pbxproj"
ReplaceInFile $pbxproj "com.yourcompany.firebaseTemplate.RunnerTests" "$BundleIdProd.RunnerTests"
ReplaceInFile $pbxproj "com.yourcompany.firebaseTemplate.debug"       $BundleIdDev
ReplaceInFile $pbxproj "com.yourcompany.firebaseTemplate.profile"     $BundleIdStaging
ReplaceInFile $pbxproj "com.yourcompany.firebaseTemplate"             $BundleIdProd

# ── Move MainActivity.kt to correct package path ──────────────────────────────

Write-Step "Moving MainActivity.kt to correct package path"

$OrgPath     = $OrgPrefix -replace '\.', '\'
$OldKtDir    = "android\app\src\main\kotlin\com\yourcompany\firebase_template"
$NewKtDir    = "android\app\src\main\kotlin\$OrgPath\$AppName"
$OldMainPath = "$OldKtDir\MainActivity.kt"
$NewMainPath = "$NewKtDir\MainActivity.kt"

ReplaceInFile $OldMainPath "com.yourcompany.firebase_template" "$OrgPrefix.$AppName"
New-Item -ItemType Directory -Force $NewKtDir | Out-Null
Move-Item $OldMainPath $NewMainPath
Remove-Item $OldKtDir -Recurse -Force
Write-Ok "MainActivity.kt → $NewKtDir"

# ── Update app display names in entry points ──────────────────────────────────

Write-Step "Updating app display names in main_*.dart"

ReplaceInFile "lib\main_dev.dart"     "appName: 'MyApp Dev'"     "appName: '$AppDisplayName Dev'"
ReplaceInFile "lib\main_staging.dart" "appName: 'MyApp Staging'" "appName: '$AppDisplayName Staging'"
ReplaceInFile "lib\main_prod.dart"    "appName: 'MyApp'"         "appName: '$AppDisplayName'"

# ── Write secrets files ───────────────────────────────────────────────────────

Write-Step "Creating secrets at $SecretsDir"

New-Item -ItemType Directory -Force $SecretsDir | Out-Null

# CUSTOM_SCHEME: lowercase app name, underscores replaced with hyphens (URL scheme rules)
$CustomScheme = $AppName.ToLower() -replace '_', '-'

[ordered]@{ APP_BUNDLE_ID = $BundleIdDev; APP_NAME = "$AppDisplayName Dev"; DEEP_LINK_HOST = "TODO_DEV_PROJECT_ID.web.app"; CUSTOM_SCHEME = $CustomScheme; FUNCTIONS_REGION = "europe-west2"; REVENUE_CAT_KEY_APPLE = ""; REVENUE_CAT_KEY_ANDROID = ""; APP_CHECK_RECAPTCHA_KEY = "" } |
    ConvertTo-Json | Set-Content "$SecretsDir\dev.json"

[ordered]@{ APP_BUNDLE_ID = $BundleIdStaging; APP_NAME = "$AppDisplayName Staging"; DEEP_LINK_HOST = "TODO_STAGING_PROJECT_ID.web.app"; CUSTOM_SCHEME = $CustomScheme; FUNCTIONS_REGION = "europe-west2"; REVENUE_CAT_KEY_APPLE = ""; REVENUE_CAT_KEY_ANDROID = ""; APP_CHECK_RECAPTCHA_KEY = "" } |
    ConvertTo-Json | Set-Content "$SecretsDir\staging.json"

[ordered]@{ APP_BUNDLE_ID = $BundleIdProd; APP_NAME = $AppDisplayName; DEEP_LINK_HOST = "TODO_PROD_PROJECT_ID.web.app"; CUSTOM_SCHEME = $CustomScheme; FUNCTIONS_REGION = "europe-west2"; REVENUE_CAT_KEY_APPLE = ""; REVENUE_CAT_KEY_ANDROID = ""; APP_CHECK_RECAPTCHA_KEY = "" } |
    ConvertTo-Json | Set-Content "$SecretsDir\prod.json"

Write-Ok "dev.json"
Write-Ok "staging.json"
Write-Ok "prod.json"

# ── Generate Android keystores ────────────────────────────────────────────────

if ($KeytoolPath -and $DevPass) {
    Write-Step "Generating Android signing keystores"

    $keystoreBaseDir = "$SecretsDir\android"

    foreach ($envInfo in @(
        @{ Env = "dev";     Alias = "$AppName-dev";     Pass = $DevPass },
        @{ Env = "staging"; Alias = "$AppName-staging"; Pass = $StagingPass },
        @{ Env = "prod";    Alias = "$AppName-prod";    Pass = $ProdPass }
    )) {
        $envName = $envInfo.Env
        $alias   = $envInfo.Alias
        $pass    = $envInfo.Pass
        $dir     = "$keystoreBaseDir\$envName"
        $jks     = "$dir\$AppName-$envName.jks"

        New-Item -ItemType Directory -Force $dir | Out-Null

        & $KeytoolPath -genkey -noprompt `
            -keystore $jks `
            -storetype PKCS12 `
            -alias $alias `
            -keyalg RSA -keysize 2048 -validity 10000 `
            -storepass $pass -keypass $pass `
            -dname "CN=$AppName" | Out-Null

        # Java's Properties.load() does not strip a BOM, so a UTF-8 BOM here
        # becomes part of the first key name and every Gradle build fails with
        # "null cannot be cast to non-null type kotlin.String". Windows
        # PowerShell's -Encoding utf8 always writes one, so write the bytes
        # ourselves with a BOM-less encoder.
        $keystorePropsText = @"
storeFile=$AppName-$envName.jks
storePassword=$pass
keyAlias=$alias
keyPassword=$pass
"@
        [IO.File]::WriteAllText(
            (Join-Path $dir "keystore.properties"),
            $keystorePropsText,
            (New-Object Text.UTF8Encoding $false)
        )

        Write-Ok "$envName → $jks"
    }
} elseif (-not $KeytoolPath) {
    Write-Host "     ⚠  Skipped keystores (keytool not found — install Android Studio first)." -ForegroundColor Yellow
}

# ── Generate CLAUDE.md for the new project ───────────────────────────────────

Write-Step "Writing CLAUDE.md"

$claudeMd = @'
# CLAUDE.md — {{APP_DISPLAY_NAME}}

## Running the app

Flutter is managed via FVM (version `3.38.5` in `.fvm/fvm_config.json`). Use `fvm flutter` not `flutter`.

Secrets live outside the repo at `~/.secrets/{{APP_NAME}}/{dev,staging,prod}.json` and are injected
via `--dart-define-from-file`. Use the scripts:

```powershell
scripts\run_dev.bat        # Windows
bash scripts/run_dev.sh    # Mac / Git Bash
```

Or directly:
```bash
fvm flutter run --dart-define-from-file=~/.secrets/{{APP_NAME}}/dev.json --target=lib/main_dev.dart
```

---

## First-time Firebase setup

1. Create three Firebase projects: `{{APP_NAME}}-dev`, `{{APP_NAME}}-staging`, `{{APP_NAME}}-prod`
2. For each project run: `flutterfire configure --out=lib/firebase_options/<env>.dart`
3. Replace `android/app/google-services.json` with the prod one (or use flavors)
4. Add `ios/Runner/GoogleService-Info.plist` in Xcode for each scheme
5. Update `REVERSED_CLIENT_ID` in `ios/Runner/Info.plist`
6. Fill in `lib/config/store_config.dart` with your App Store ID and Play Store package name

---

## Architecture

### Environments
Three entry points — `main_dev.dart`, `main_staging.dart`, `main_prod.dart` — each calls `bootstrap()`
with environment-specific parameters. The `--target` flag is the only switch needed; no code is
mutated at release time.

### State management
**Riverpod only.** Do not use `ChangeNotifier`, `context.watch`, or `context.read` for state.
Use `ConsumerWidget` / `ConsumerStatefulWidget` and `ref.watch` / `ref.read`.

### Navigation
GoRouter via `routerProvider`. Auth redirects are handled by `_RouterNotifier` in
`router/app_router.dart`, which bridges `authStateProvider` to GoRouter's `refreshListenable`.
Do not pass auth state into the router manually.

### Service layer
Each external dependency has two files:

- `lib/services/foo_service.dart` — abstract interface (what providers and notifiers depend on)
- `lib/services/firebase_foo_service.dart` — concrete Firebase impl with injected SDK client

Providers are typed to the abstract interface so tests can override them with fakes.

### SDK initialisation
All third-party SDK setup lives in `lib/bootstrap.dart`. When adding a new SDK:
1. Add its init to `bootstrap()` or a private `_setupX()` helper inside `bootstrap.dart`
2. Do **not** scatter init calls across `main_*.dart` files

### Secrets and config
- Secrets live in `~/.secrets/{{APP_NAME}}/` — never in the repo
- Adding a new secret: update all three `.secrets.example/*.json` files, add a field to
  `AppConfig`, and read it with `String.fromEnvironment('KEY')` in each `main_*.dart`
- Android manifest values that come from secrets use `manifestPlaceholders` set in
  `build.gradle.kts` — do not hardcode keys in the manifest

---

## Key files

| File | Purpose |
|---|---|
| `lib/bootstrap.dart` | All SDK init in one place |
| `lib/config/app_config.dart` | Environment singleton — add new config fields here |
| `lib/config/offline_config.dart` | `OfflineCollection` class + list of collections to cache offline |
| `lib/config/remote_config_defaults.dart` | Remote Config keys and default values |
| `lib/config/store_config.dart` | App Store / Play Store IDs for force-update screen |
| `lib/models/user_profile.dart` | Firestore user document model |
| `lib/providers/auth_providers.dart` | `authStateProvider` (stream), `authNotifierProvider` (mutations) |
| `lib/providers/branch_providers.dart` | Deep link stream + identity sync |
| `lib/providers/crashlytics_providers.dart` | Crashlytics user identity sync |
| `lib/providers/messaging_providers.dart` | FCM token, foreground/opened/initial message providers |
| `lib/providers/offline_sync_provider.dart` | `offlineSyncProvider` — starts/stops listeners based on auth state |
| `lib/providers/remote_config_provider.dart` | RC instance, typed value extension, `versionCheckProvider` |
| `lib/providers/user_providers.dart` | `userProfileProvider` (stream), `userProfileSyncProvider` |
| `lib/router/app_router.dart` | GoRouter + `routerProvider` |
| `lib/screens/force_update_screen.dart` | Blocking update screen shown when build is below minimum |
| `lib/services/auth_service.dart` | Auth interface — override via `authServiceProvider` in tests |
| `lib/services/firebase_auth_service.dart` | Firebase auth impl — injects `FirebaseAuth` and `GoogleSignIn` |
| `lib/services/offline_sync_service.dart` | Offline sync interface |
| `lib/services/firestore_offline_sync_service.dart` | Firestore offline sync impl — injects `FirebaseFirestore` |
| `lib/services/user_service.dart` | User-profile interface |
| `lib/services/firebase_user_service.dart` | Firestore user-profile impl — injects `FirebaseFirestore` |
| `lib/utils/app_logger.dart` | Global `log` — console in debug, Crashlytics in release |
| `lib/app.dart` | Root widget — identity-sync providers + version gate |

---

## Patterns to follow

### Adding a new SDK
1. Add the package to `pubspec.yaml`
2. Add init to `lib/bootstrap.dart`
3. Create `lib/services/new_service.dart` — abstract interface with only the methods needed
4. Create `lib/services/firebase_new_service.dart` — concrete impl; inject the SDK client via
   constructor (`FirebaseFoo? foo`) so tests can supply a fake
5. Create `lib/providers/new_providers.dart` — type the provider to the interface:
   `Provider<NewService>((ref) => FirebaseNewService())`
6. If it needs user identity sync, add a `Provider<void>` that listens to `authStateProvider`,
   and watch it in `lib/app.dart`

### Adding a new secret
1. Add to `.secrets.example/dev.json`, `staging.json`, `prod.json`
2. Add a field to `AppConfig` in `lib/config/app_config.dart`
3. Read in each `main_*.dart` via `String.fromEnvironment('KEY')`
4. If it needs to go into the Android manifest, add
   `manifestPlaceholders["key"] = dartDefines["KEY"] ?: ""` in `android/app/build.gradle.kts`

### Logging

Use `log` from `lib/utils/app_logger.dart` everywhere:

```dart
import '../utils/app_logger.dart';

log.d('fetching profile');           // debug — dev only
log.i('user signed in');             // info — dev only
log.w('token refresh failed', error: e);            // warning — also to Crashlytics
log.e('unhandled error', error: e, stackTrace: s);  // error — also to Crashlytics
```

### Configuring offline sync

Edit `lib/config/offline_config.dart` — the only file you need to touch:

```dart
const List<OfflineCollection> offlineCollections = [
  OfflineCollection('products'),                                    // global
  OfflineCollection('orders', userScoped: true, uidField: 'userId'), // per-user
];
```

`offlineSyncProvider` opens Firestore listeners for every listed collection on sign-in
and closes them on sign-out. Firestore's disk cache (enabled in `bootstrap.dart`) serves
those documents instantly while offline. No code changes outside this file are needed.

### Adding a Remote Config key
1. Add a constant to `RemoteConfigKeys` in `lib/config/remote_config_defaults.dart`
2. Add a default to `remoteConfigDefaults` in the same file
3. Add a typed getter to `RemoteConfigValues` extension in `lib/providers/remote_config_provider.dart`
4. Set the value in Firebase Console → Remote Config for each project

### Adding a new screen
Use `ConsumerStatefulWidget` / `ConsumerState` if the screen has local state, `ConsumerWidget` if
not. Access auth actions via `ref.read(authNotifierProvider.notifier)`, auth state via
`ref.watch(authStateProvider)`.

### Testing

Providers are typed to abstract service interfaces, so tests override them with hand-written fakes —
no `mockito` or code generation needed.

```dart
class FakeAuthService implements AuthService {
  Exception? signInError;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    if (signInError != null) throw signInError!;
  }
  // ... implement remaining methods as no-ops
}

final container = ProviderContainer(
  overrides: [authServiceProvider.overrideWithValue(FakeAuthService())],
);
addTearDown(container.dispose);
```

See `test/auth/auth_notifier_test.dart` for the full example. Follow the same pattern for every
new service.

---

## SDK behaviour by environment

| | Dev | Staging | Prod |
|---|---|---|---|
| App Check | Debug in debug builds, Play Integrity / AppAttest in release | Debug in debug builds, Play Integrity / AppAttest in release | Debug in debug builds, Play Integrity / AppAttest in release |

App Check providers are chosen by **build mode**, not environment: `kDebugMode` uses the debug
provider so `flutter run` works without registering a token, and every release build — including
dev — attests via Play Integrity / App Attest. This matters when a non-prod flavour is distributed
through the Play Store, where each tester would otherwise need their own debug token allow-listed.
On web the provider is reCAPTCHA Enterprise, active only when `APP_CHECK_RECAPTCHA_KEY` is set.
| Crashlytics collection | Off | On | On |
| Deep link host | Dev Firebase project | Staging Firebase project | Prod Firebase project |
| Remote Config fetch | `Duration.zero` | 5 min | 1 hr |

---

## User profile

`userProfileProvider` is a `StreamProvider<UserProfile?>` — watch it anywhere you need the
signed-in user's Firestore data. `userProfileSyncProvider` (watched in `app.dart`) creates the
document automatically on first sign-in for every auth method.

To update the profile:
```dart
await ref.read(userServiceProvider).updateProfile(uid, {'displayName': newName});
```

## Calling Cloud Functions

Use `cloudFunctionsProvider`. Auth token and App Check token are attached automatically.

```dart
final result = await ref.read(cloudFunctionsProvider).call<Map<String, dynamic>>(
  'createOrder',
  data: {'productId': '123', 'quantity': 2},
);
```

Catch specific error codes:
```dart
try {
  await ref.read(cloudFunctionsProvider).call('deleteAccount');
} on FirebaseFunctionsException catch (e) {
  if (e.code == 'permission-denied') { ... }
}
```

For a non-default region: `Provider((ref) => CloudFunctionsService(region: 'europe-west1'))`.

For the local emulator, call `CloudFunctionsService.useEmulator()` in `main_dev.dart` before
`bootstrap()` when running `firebase emulators:start --only functions`.

## Deep linking

Short links are created via `deepLinkServiceProvider.createShortLink(path, params)`.
The `functions/` directory deploys a Cloud Function that serves the redirect page at `https://<DEEP_LINK_HOST>/l/<code>`.

**First-time setup per environment:**
1. Copy `functions/.env.example` → `functions/.env.<FIREBASE_PROJECT_ID>` and fill in values
2. `firebase deploy --only hosting,functions --project <alias>`
3. iOS — add `applinks:<DEEP_LINK_HOST>` to Associated Domains in Xcode and fill in `CUSTOM_SCHEME` in `ios/Runner/Info.plist`
4. Android — `DEEP_LINK_HOST` and `CUSTOM_SCHEME` are read from your secrets file automatically
5. Copy `.firebaserc.example` → `.firebaserc` and fill in project IDs

**Handling incoming links in the router:**
```dart
// In your router or root widget:
ref.listen(incomingDeepLinkProvider, (_, next) {
  next.whenData((link) => context.go(link.path));
});

// On first launch — checks cold-start link then deferred link:
ref.listen(initialDeepLinkProvider, (_, next) {
  next.whenData((link) { if (link != null) context.go(link.path); });
});
```

**Deferred deep linking** (link tapped before install): the redirect page records the click by IP. On first open `claimDeferredLink` matches the install to the click within a 10-minute window. Works reliably when the same network is used; cross-network installs will not match (acceptable trade-off — no third-party service needed).

## Minimum version enforcement

Set `minimum_build_number` in Firebase Console → Remote Config. When the device's build number
is below this value, `ForceUpdateScreen` is shown and all navigation is blocked. Set to `0`
(the default) to disable.

---

## Things to avoid

- **Do not** use the `provider` package — Riverpod only
- **Do not** add init calls directly to `main_*.dart` — use `bootstrap.dart`
- **Do not** hardcode secrets or API keys in Dart code or manifests — use `String.fromEnvironment`
  and `manifestPlaceholders`
- **Do not** commit `google-services.json`, `GoogleService-Info.plist`, or
  `lib/firebase_options/*.dart` once they contain real keys
- **Do not** call `FirebaseMessaging.instance.requestPermission()` on cold launch — trigger it
  contextually after the user has seen value
- **Do not** use `debugPrint` or `print` — use `log` from `lib/utils/app_logger.dart`
- **Do not** call Firebase SDK singletons (`FirebaseAuth.instance`, `FirebaseFirestore.instance`,
  etc.) directly in screens or notifiers — go through the injected service
- **Do not** add collections to `offlineCollections` without considering cache size — large global
  collections should be filtered or paginated
'@

$claudeMd = $claudeMd `
    -replace '{{APP_NAME}}',         $AppName `
    -replace '{{APP_DISPLAY_NAME}}', $AppDisplayName

Set-Content "CLAUDE.md" $claudeMd -Encoding utf8 -NoNewline
Write-Ok "CLAUDE.md"

# ── Flutter pub get ───────────────────────────────────────────────────────────

Write-Step "Running flutter pub get"

$FvmConfig  = Get-Content ".fvm\fvm_config.json" | ConvertFrom-Json
$FvmVersion = $FvmConfig.flutter
$FlutterBat = "C:\Users\$env:USERNAME\fvm\versions\$FvmVersion\bin\flutter.bat"

if (-not (Test-Path $FlutterBat)) {
    Write-Host "     ⚠  flutter.bat not found at $FlutterBat — skipping pub get." -ForegroundColor Yellow
    Write-Host "        Run 'fvm flutter pub get' manually inside the project." -ForegroundColor Yellow
} else {
    & $FlutterBat pub get
    Write-Ok "Dependencies resolved"
}

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ┌─────────────────────────────────────────────────────┐" -ForegroundColor Green
Write-Host "  │  $AppName is ready!$((' ' * (51 - $AppName.Length)))│" -ForegroundColor Green
Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor Green
Write-Host ""
Write-Host "  Location: $ProjectDir" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Create 3 Firebase projects and run flutterfire configure (see README)"
Write-Host "    2. Replace android\app\google-services.json"
Write-Host "    3. Add ios\Runner\GoogleService-Info.plist in Xcode"
Write-Host "    4. Update REVERSED_CLIENT_ID in ios\Runner\Info.plist"
Write-Host "    5. Run: scripts\run_dev.bat"
Write-Host "    6. For releases: run 'bundle install' then 'bash scripts/release_dev.sh'"
Write-Host ""
