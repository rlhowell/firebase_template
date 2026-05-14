import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/purchases_service.dart';
import '../services/revenue_cat_service.dart';
import 'auth_providers.dart';

final purchasesServiceProvider = Provider<PurchasesService>(
  (ref) => RevenueCatService(),
);

/// The customer's current entitlement/subscription state from RevenueCat.
/// Invalidate this after a purchase or restore to force a refresh:
///   `ref.invalidate(customerInfoProvider)`
final customerInfoProvider = FutureProvider<CustomerInfo>((ref) {
  return ref.read(purchasesServiceProvider).getCustomerInfo();
});

/// Available offerings (products) from RevenueCat.
/// Cached for the lifetime of the provider.
final offeringsProvider = FutureProvider<Offerings>((ref) {
  return ref.read(purchasesServiceProvider).getOfferings();
});

/// Side-effect provider: logs the RevenueCat user in/out as auth state changes
/// so purchase history is linked to the signed-in Firebase user.
/// Must be watched at the root of the widget tree (App) to stay active.
final purchasesIdentitySyncProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (previous, next) async {
    final user = next.valueOrNull;
    await ref.read(purchasesServiceProvider).setUserId(user?.uid);
    // Refresh entitlement state after identity change.
    ref.invalidate(customerInfoProvider);
  });
});

/// Convenience: returns true when the user has an active entitlement for [id].
///
/// ```dart
/// final isPro = ref.watch(hasEntitlementProvider('pro'));
/// ```
final hasEntitlementProvider = Provider.family<bool, String>((ref, id) {
  return ref
          .watch(customerInfoProvider)
          .valueOrNull
          ?.entitlements
          .active
          .containsKey(id) ??
      false;
});
