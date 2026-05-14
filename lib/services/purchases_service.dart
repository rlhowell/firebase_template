import 'package:purchases_flutter/purchases_flutter.dart';

export 'package:purchases_flutter/purchases_flutter.dart'
    show CustomerInfo, Offerings, Package, PurchasesErrorCode;

abstract class PurchasesService {
  /// Returns the current available offerings from RevenueCat.
  Future<Offerings> getOfferings();

  /// Initiates a purchase for the given [package].
  /// Throws [PurchasesErrorHelper] if the purchase fails or is cancelled.
  Future<CustomerInfo> purchasePackage(Package package);

  /// Restores previous purchases (required by App Store / Play Store guidelines).
  Future<CustomerInfo> restorePurchases();

  /// Returns the latest [CustomerInfo] (entitlement status, active subs, etc.).
  Future<CustomerInfo> getCustomerInfo();

  /// Logs in the given user to RevenueCat, linking purchase history to their
  /// account. Pass `null` to log out (reverts to anonymous user).
  Future<void> setUserId(String? uid);
}
