# CLAUDE.md — Firebase Flutter Template

## What this project is

A multi-environment Flutter template. Every new app is spawned from this repo via `New-FirebaseApp.ps1`. The template is never run as a real app — it exists to be cloned.

---

## Running the app

Flutter is managed via FVM (version `3.38.5` in `.fvm/fvm_config.json`). Use `fvm flutter` not `flutter`.

Secrets live outside the repo at `~/.secrets/firebase_template/{dev,staging,prod}.json` and are injected via `--dart-define-from-file`. Use the scripts:

```powershell
scripts\run_dev.bat        # Windows
bash scripts/run_dev.sh    # Mac / Git Bash
```

Or directly:
```bash
fvm flutter run --dart-define-from-file=~/.secrets/firebase_template/dev.json --target=lib/main_dev.dart
```

---

## Architecture

### Environments
Three entry points — `main_dev.dart`, `main_staging.dart`, `main_prod.dart` — each calls `bootstrap()` with environment-specific parameters. The `--target` flag is the only switch needed; no code is mutated at release time.

### State management
**Riverpod only.** The `provider` package was removed. Do not use `ChangeNotifier`, `context.watch`, or `context.read` for state. Use `ConsumerWidget` / `ConsumerStatefulWidget` and `ref.watch` / `ref.read`.

### Navigation
GoRouter via `routerProvider`. Auth redirects are handled by `_RouterNotifier` in `router/app_router.dart`, which bridges `authStateProvider` to GoRouter's `refreshListenable`. Do not pass auth state into the router manually.

### SDK initialisation
All third-party SDK setup lives in `lib/bootstrap.dart`. When adding a new SDK:
1. Add its init to `bootstrap()` or a private `_setupX()` helper inside `bootstrap.dart`
2. Do **not** scatter init calls across `main_*.dart` files

### Secrets and config
- Secrets (bundle IDs, API keys, deep link host) live in `~/.secrets/firebase_template/` — never in the repo
- Adding a new secret: update all three `.secrets.example/*.json` files, add a field to `AppConfig`, and read it with `String.fromEnvironment('KEY')` in each `main_*.dart`
- Android manifest values that come from secrets use `manifestPlaceholders` set in `build.gradle.kts` from the already-decoded `dartDefines` map — do not hardcode keys in the manifest

---

## Key files

| File | Purpose |
|---|---|
| `lib/bootstrap.dart` | All SDK init in one place |
| `lib/config/app_config.dart` | Environment singleton — add new config fields here |
| `lib/config/offline_config.dart` | `OfflineCollection` class + list of collections to keep in the Firestore disk cache |
| `lib/config/remote_config_defaults.dart` | Remote Config keys and default values |
| `lib/config/store_config.dart` | App Store / Play Store IDs for force-update screen |
| `lib/models/user_profile.dart` | Firestore user document model |
| `lib/providers/analytics_provider.dart` | `analyticsServiceProvider`, `analyticsIdentitySyncProvider` |
| `lib/providers/auth_providers.dart` | `authStateProvider` (stream), `authNotifierProvider` (mutations) |
| `lib/providers/deep_link_providers.dart` | `incomingDeepLinkProvider`, `initialDeepLinkProvider` |
| `lib/services/deep_link_service.dart` | Deep link interface |
| `lib/services/firebase_deep_link_service.dart` | impl — `app_links` + Cloud Functions |
| `lib/providers/crashlytics_providers.dart` | Crashlytics user identity sync |
| `lib/providers/messaging_providers.dart` | FCM token, foreground/opened/initial message providers |
| `lib/providers/offline_sync_provider.dart` | `offlineSyncProvider` — starts/stops listeners based on auth state |
| `lib/providers/paginated_notifier.dart` | `PaginatedNotifier<T>` base class + `PaginatedState<T>` + `PageResult<T>` |
| `lib/providers/purchases_provider.dart` | `purchasesServiceProvider`, `customerInfoProvider`, `hasEntitlementProvider` |
| `lib/providers/remote_config_provider.dart` | RC instance, typed value extension, `versionCheckProvider` |
| `lib/providers/user_providers.dart` | `userProfileProvider` (stream), `userProfileSyncProvider` |
| `lib/router/app_router.dart` | GoRouter + `routerProvider` + Firebase Analytics observer |
| `lib/screens/force_update_screen.dart` | Blocking update screen shown when build is below minimum |
| `lib/services/analytics_service.dart` | Analytics interface |
| `lib/services/firebase_analytics_service.dart` | Firebase Analytics impl |
| `lib/services/auth_service.dart` | Auth interface — override via `authServiceProvider` in tests |
| `lib/services/firebase_auth_service.dart` | Firebase auth impl — injects `FirebaseAuth` and `GoogleSignIn` |
| `lib/services/offline_sync_service.dart` | Offline sync interface |
| `lib/services/firestore_offline_sync_service.dart` | Firestore offline sync impl — injects `FirebaseFirestore` |
| `lib/services/purchases_service.dart` | Purchases interface (RevenueCat types re-exported) |
| `lib/services/revenue_cat_service.dart` | RevenueCat implementation |
| `lib/services/user_service.dart` | User-profile interface |
| `lib/services/firebase_user_service.dart` | Firestore user-profile impl — injects `FirebaseFirestore` |
| `lib/utils/app_logger.dart` | Global `log` — console in debug, Crashlytics in release |
| `lib/utils/mutation_notifier.dart` | `MutationState` + `MutationNotifier` base class for write operations |
| `lib/widgets/async_value_widget.dart` | `AsyncValueWidget<T>` + `AsyncErrorWidget` — standard async state UI |
| `lib/widgets/paginated_list_view.dart` | `PaginatedListView<T>` — infinite-scroll list wired to `PaginatedNotifier` |
| `lib/app.dart` | Root widget — all identity-sync providers + version gate |
| `firestore.rules` | Firestore security rules — deny-all by default, open per-collection |

---

## Patterns to follow

### Adding a new SDK
1. Add the package to `pubspec.yaml`
2. Add init to `lib/bootstrap.dart`
3. Create `lib/services/new_service.dart` — abstract interface with only the methods providers and notifiers need
4. Create `lib/services/firebase_new_service.dart` — Firebase/concrete impl; inject the SDK client via constructor (`FirebaseFoo? foo`) so tests can supply a fake
5. Create `lib/providers/new_providers.dart` — type the provider to the interface: `Provider<NewService>((ref) => FirebaseNewService())`
6. If it needs user identity sync, add a `Provider<void>` that listens to `authStateProvider`, and watch it in `lib/app.dart`

### Forms and write operations (MutationNotifier)

Extend `MutationNotifier` for any notifier that runs write operations. This eliminates the loading/error boilerplate:

```dart
class ProfileNotifier extends MutationNotifier {
  Future<bool> updateName(String name) => run(
    () => ref.read(userServiceProvider).updateProfile(uid, {'displayName': name}),
    mapError: (e) => 'Failed to update name.',
  );
}
```

Screens access the shared `MutationState` fields (`isLoading`, `error`) and `clearError()` without extra ceremony. The `ignoreError` parameter handles silent cancellations (e.g. dismissed social sign-in sheets).

### Displaying async data (AsyncValueWidget)

Use `AsyncValueWidget` instead of manually handling loading/error branches:

```dart
AsyncValueWidget(
  value: ref.watch(userProfileProvider),
  onRetry: () => ref.invalidate(userProfileProvider),
  data: (profile) => ProfileCard(profile: profile),
)
```

`AsyncErrorWidget` can also be used stand-alone for inline error states.

### Paginated Firestore lists

Extend `PaginatedNotifier<T>` and implement one method:

```dart
class ProductsNotifier extends PaginatedNotifier<Product> {
  @override
  Future<PageResult<Product>> fetchPage(DocumentSnapshot? cursor, int limit) async {
    var q = FirebaseFirestore.instance
        .collection('products')
        .orderBy('name')
        .limit(limit);
    if (cursor != null) q = q.startAfterDocument(cursor);
    final snap = await q.get();
    return PageResult(
      items: snap.docs.map(Product.fromFirestore).toList(),
      cursor: snap.docs.lastOrNull,
      hasMore: snap.docs.length == limit,
    );
  }
}

final productsProvider =
    NotifierProvider<ProductsNotifier, PaginatedState<Product>>(ProductsNotifier.new);
```

Wire into the UI with `PaginatedListView`:

```dart
PaginatedListView(
  state: ref.watch(productsProvider),
  onLoadMore: () => ref.read(productsProvider.notifier).loadMore(),
  onRefresh: () => ref.read(productsProvider.notifier).refresh(),
  itemBuilder: (ctx, product, _) => ProductTile(product: product),
)
```

### Logging analytics events

Call `ref.read(analyticsServiceProvider)` from any screen after a meaningful action. The user ID and screen views are tracked automatically.

```dart
// After a successful sign-in:
await ref.read(analyticsServiceProvider).logSignIn('email');

// After a custom action:
await ref.read(analyticsServiceProvider).logEvent(
  'item_purchased',
  parameters: {'item_id': id},
);
```

### Checking entitlements (RevenueCat)

```dart
// True when the user has an active 'pro' entitlement:
final isPro = ref.watch(hasEntitlementProvider('pro'));

// Trigger a purchase:
final offerings = await ref.read(purchasesServiceProvider).getOfferings();
final package = offerings.current?.monthly;
if (package != null) {
  await ref.read(purchasesServiceProvider).purchasePackage(package);
  ref.invalidate(customerInfoProvider); // refresh entitlement state
}

// Restore on user request (required by App Store guidelines):
await ref.read(purchasesServiceProvider).restorePurchases();
ref.invalidate(customerInfoProvider);
```

### Adding a new secret
1. Add to `.secrets.example/dev.json`, `staging.json`, `prod.json`
2. Add a field to `AppConfig` in `lib/config/app_config.dart`
3. Read in each `main_*.dart` via `String.fromEnvironment('KEY')`
4. If it needs to go into the Android manifest, add `manifestPlaceholders["key"] = dartDefines["KEY"] ?: ""` in `android/app/build.gradle.kts`

### Logging

Use `log` from `lib/utils/app_logger.dart` everywhere instead of `debugPrint` or `print`:

```dart
import '../utils/app_logger.dart';

log.d('fetching profile');           // debug — dev only
log.i('user signed in: ${uid}');     // info — dev only
log.w('token refresh failed', error: e);            // warning — also to Crashlytics
log.e('unhandled error', error: e, stackTrace: s);  // error — also to Crashlytics
```

### Configuring offline sync

Edit `lib/config/offline_config.dart` — this is the only file you need to touch:

```dart
const List<OfflineCollection> offlineCollections = [
  // All documents visible to this user in the collection:
  OfflineCollection('products'),

  // Documents filtered to the signed-in user (field name defaults to 'uid'):
  OfflineCollection('orders', userScoped: true, uidField: 'userId'),
];
```

`offlineSyncProvider` (watched in `app.dart`) opens Firestore listeners for every listed collection on sign-in and closes them on sign-out. Firestore's disk cache (`persistenceEnabled: true`, unlimited size — set in `bootstrap.dart`) then serves those documents instantly while the device is offline.

No code changes outside `offline_config.dart` are needed to add or remove a collection.

### Adding a Remote Config key
1. Add a constant to `RemoteConfigKeys` in `lib/config/remote_config_defaults.dart`
2. Add a default to `remoteConfigDefaults` in the same file
3. Add a typed getter to `RemoteConfigValues` extension in `lib/providers/remote_config_provider.dart`
4. Set the value in Firebase Console → Remote Config for each project

### Adding a new screen
Use `ConsumerStatefulWidget` / `ConsumerState` if the screen has local state, `ConsumerWidget` if not. Access auth actions via `ref.read(authNotifierProvider.notifier)`, auth state via `ref.watch(authStateProvider)`.

### Testing

Providers are typed to abstract service interfaces, so tests override them with hand-written fakes — no `mockito` or code generation needed.

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

See `test/auth/auth_notifier_test.dart` for the full example covering all `signInWithEmail` error codes. Follow the same pattern when adding a new service.

---

## SDK behaviour by environment

| | Dev | Staging | Prod |
|---|---|---|---|
| App Check | Debug provider | Debug provider | Play Integrity / AppAttest |
| Crashlytics collection | Off | On | On |
| Analytics | Collected | Collected | Collected |
| Deep link host | Dev Firebase project | Staging Firebase project | Prod Firebase project |
| Remote Config fetch | `Duration.zero` | 5 min | 1 hr |
| RevenueCat | Same key (sandbox receipts) | Same key (sandbox receipts) | Same key (production receipts) |

---

### User profile

`userProfileProvider` is a `StreamProvider<UserProfile?>` — watch it anywhere you need the signed-in user's Firestore data. `userProfileSyncProvider` (watched in `app.dart`) creates the document automatically on first sign-in for every auth method.

To update the profile:
```dart
await ref.read(userServiceProvider).updateProfile(uid, {'displayName': newName});
```

### Calling Cloud Functions

Use `cloudFunctionsProvider`. Auth token and App Check token are attached automatically by the SDK — do not pass them manually.

```dart
// In a widget or notifier:
final result = await ref.read(cloudFunctionsProvider).call<Map<String, dynamic>>(
  'createOrder',
  data: {'productId': '123', 'quantity': 2},
);

// Catch specific error codes:
try {
  await ref.read(cloudFunctionsProvider).call('deleteAccount');
} on FirebaseFunctionsException catch (e) {
  if (e.code == 'permission-denied') { ... }
}
```

For a non-default region, create a separate provider:
```dart
final euFunctions = Provider((ref) => CloudFunctionsService(region: 'europe-west1'));
```

For the local emulator, call `CloudFunctionsService.useEmulator()` in `main_dev.dart` before `bootstrap()` when running `firebase emulators:start --only functions`.

### Minimum version enforcement

Set `minimum_build_number` in Firebase Console → Remote Config. When the device's build number is below this value, `ForceUpdateScreen` is shown and all navigation is blocked. Set to `0` (the default) to disable enforcement.

Fill in `lib/config/store_config.dart` with your App Store ID and Play Store package when spawning a new app.

## Things to avoid

- **Do not** use the `provider` package — Riverpod only
- **Do not** add init calls directly to `main_*.dart` — use `bootstrap.dart`
- **Do not** hardcode secrets or API keys anywhere in the Dart code or manifests — use `String.fromEnvironment` and `manifestPlaceholders`
- **Do not** commit `google-services.json`, `GoogleService-Info.plist`, or `lib/firebase_options/*.dart` — these are always gitignored and must live in `~/.secrets/firebase_template/{dev,staging,prod}/`, copied into place by the run scripts
- **Do not** use `sed` or file mutation in release scripts to toggle App Check providers — the correct provider is already selected by `--target`
- **Do not** call `FirebaseMessaging.instance.requestPermission()` on cold launch — it must be triggered contextually after the user has seen value
- **Do not** use `debugPrint` or `print` — use `log` from `lib/utils/app_logger.dart`
- **Do not** call Firebase or RevenueCat SDK singletons directly in screens or notifiers — go through the injected service
- **Do not** write manually repeated loading/error state in notifiers — extend `MutationNotifier` and use `run()`
- **Do not** add large global collections to `offlineCollections` without pagination — cache the first page instead
- **Do not** open Firestore security rules beyond what each collection requires — start from `firestore.rules` deny-all and open per-collection
