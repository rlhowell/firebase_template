import 'package:purchases_flutter/purchases_flutter.dart';

import '../utils/app_logger.dart';
import 'purchases_service.dart';

class RevenueCatService implements PurchasesService {
  @override
  Future<Offerings> getOfferings() => Purchases.getOfferings();

  @override
  Future<CustomerInfo> purchasePackage(Package package) =>
      Purchases.purchasePackage(package);

  @override
  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();

  @override
  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  @override
  Future<void> setUserId(String? uid) async {
    try {
      if (uid != null) {
        await Purchases.logIn(uid);
        log.d('RevenueCat logged in: $uid');
      } else {
        await Purchases.logOut();
        log.d('RevenueCat logged out');
      }
    } catch (e, s) {
      log.w('RevenueCat identity sync failed', error: e, stackTrace: s);
    }
  }
}
