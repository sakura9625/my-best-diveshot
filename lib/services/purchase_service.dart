import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // 商品IDリスト
  static const Set<String> kSheetProductIds = {
    'com.hikaru.mybestdiveshot.sheet.ishigaki',
    'com.hikaru.mybestdiveshot.sheet.izu',
    'com.hikaru.mybestdiveshot.sheet.macro',
    'com.hikaru.mybestdiveshot.sheet.wide',
    'com.hikaru.mybestdiveshot.sheet.kushimoto',
    'com.hikaru.mybestdiveshot.sheet.kashiwajima',
    'com.hikaru.mybestdiveshot.sheet.deep',
    'com.hikaru.mybestdiveshot.sheet.hanadi',
    'com.hikaru.mybestdiveshot.sheet.nudibranch_iro',
    'com.hikaru.mybestdiveshot.sheet.nudibranch_other',
    'com.hikaru.mybestdiveshot.sheet.goby_bingo',
    'com.hikaru.mybestdiveshot.sheet.crustacean_standard',
    'com.hikaru.mybestdiveshot.sheet.crustacean_hidden',
  };

  static const Set<String> kCloudProductIds = {
    'com.hikaru.mybestdiveshot.cloud.monthly',
    'com.hikaru.mybestdiveshot.cloud.yearly',
  };

  static Set<String> get kAllProductIds => {...kSheetProductIds, ...kCloudProductIds};

  // 商品IDからシートIDへのマッピング
  static const Map<String, String> kProductToSheetId = {
    'com.hikaru.mybestdiveshot.sheet.ishigaki': 'ishigaki',
    'com.hikaru.mybestdiveshot.sheet.izu': 'izu',
    'com.hikaru.mybestdiveshot.sheet.macro': 'macro',
    'com.hikaru.mybestdiveshot.sheet.wide': 'wide',
    'com.hikaru.mybestdiveshot.sheet.kushimoto': 'kushimoto',
    'com.hikaru.mybestdiveshot.sheet.kashiwajima': 'kashiwajima',
    'com.hikaru.mybestdiveshot.sheet.deep': 'deep',
    'com.hikaru.mybestdiveshot.sheet.hanadi': 'hanadi',
    'com.hikaru.mybestdiveshot.sheet.nudibranch_iro': 'nudibranch_iro',
    'com.hikaru.mybestdiveshot.sheet.nudibranch_other': 'nudibranch_other',
    'com.hikaru.mybestdiveshot.sheet.goby_bingo': 'goby_bingo',
    'com.hikaru.mybestdiveshot.sheet.crustacean_standard': 'crustacean_standard',
    'com.hikaru.mybestdiveshot.sheet.crustacean_hidden': 'crustacean_hidden',
  };

  // 購入完了コールバック
  Function(String productId)? onPurchaseSuccess;
  Function(String error)? onPurchaseError;

  // 初期化
  Future<void> initialize() async {
    if (Platform.isIOS) {
      final iosPlatformAddition = _iap
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  // 商品情報を取得
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds) async {
    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      debugPrint('Product query error: ${response.error}');
      return [];
    }
    return response.productDetails;
  }

  // 購入を開始
  Future<void> buyProduct(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    if (kCloudProductIds.contains(product.id)) {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  // 購入復元
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  // 購入状態の更新処理
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending: ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final valid = await _verifyPurchase(purchase);
        if (valid) {
          onPurchaseSuccess?.call(purchase.productID);
        }
        await _iap.completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        onPurchaseError?.call(purchase.error?.message ?? '購入に失敗しました');
        await _iap.completePurchase(purchase);
      }
    }
  }

  // 購入検証（簡易版・将来的にサーバー検証に変更）
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    return true;
  }
}

// iOS決済キューデリゲート
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
