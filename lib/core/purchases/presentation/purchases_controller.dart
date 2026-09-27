import 'dart:io' show Platform;

import 'package:ai_teacher/core/purchases/data/revenuecat_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final purchasesControllerProvider =
    NotifierProvider<PurchasesController, CustomerInfo?>(
      PurchasesController.new,
    );

/// Owns the RevenueCat SDK lifecycle and exposes the latest [CustomerInfo].
/// The RevenueCat app user id is our backend user id (the JWT `sub`), so
/// purchases follow the account across devices and reach the API webhook
/// under the same id.
class PurchasesController extends Notifier<CustomerInfo?> {
  bool _configured = false;

  @override
  CustomerInfo? build() => null;

  static String get _apiKey => Platform.isIOS
      ? RevenueCatConfig.appleApiKey
      : RevenueCatConfig.googleApiKey;

  /// Configures the SDK once per app launch. Pass the logged-in user id when
  /// there is one; otherwise RevenueCat starts with an anonymous id until
  /// [identify] is called.
  Future<void> configure({String? userId}) async {
    if (_configured) return;
    if (_apiKey.isEmpty) {
      debugPrint('RevenueCat API key missing — purchases disabled.');
      return;
    }
    try {
      if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);
      final config = PurchasesConfiguration(_apiKey)..appUserID = userId;
      await Purchases.configure(config);
      _configured = true;
      Purchases.addCustomerInfoUpdateListener((info) => state = info);
      state = await Purchases.getCustomerInfo();
    } on PlatformException catch (e) {
      debugPrint('RevenueCat configure failed: $e');
    }
  }

  /// Links purchases to [userId]. Call right after login/register.
  Future<void> identify(String userId) async {
    if (!_configured) return;
    try {
      final result = await Purchases.logIn(userId);
      state = result.customerInfo;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat logIn failed: $e');
    }
  }

  /// Detaches the current user. Call on logout.
  Future<void> reset() async {
    if (!_configured) return;
    try {
      if (await Purchases.isAnonymous) return;
      state = await Purchases.logOut();
    } on PlatformException catch (e) {
      debugPrint('RevenueCat logOut failed: $e');
    }
  }

  bool get isEnabled => _configured;

  /// Packages of the offering marked "current" in the RevenueCat dashboard,
  /// with localized store prices. Null when nothing is configured.
  Future<Offering?> currentOffering() async {
    if (!_configured) return null;
    final offerings = await Purchases.getOfferings();
    return offerings.current;
  }

  /// Buys [package]. Returns true once the store transaction completes and
  /// false when the user backs out of the store sheet; other store errors are
  /// rethrown. The extra conversations themselves are granted by the API when
  /// RevenueCat reports the purchase, not by the app.
  Future<bool> purchase(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      state = result.customerInfo;
      return true;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }
}
