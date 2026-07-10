import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/purchase_service.dart';
import '../providers/purchased_sheets_provider.dart';
import 'extra_my_select_provider.dart';

// 商品情報Provider
final productsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  return PurchaseService().fetchProducts(PurchaseService.kAllProductIds);
});

// 購入処理Provider
final purchaseNotifierProvider = ChangeNotifierProvider<PurchaseNotifier>((ref) {
  return PurchaseNotifier(ref);
});

class PurchaseNotifier extends ChangeNotifier {
  final Ref _ref;
  bool isLoading = false;
  String? errorMessage;
  Function(String productId)? onDiveCloudPurchased;

  PurchaseNotifier(this._ref) {
    _initPurchaseService();
  }

  void _initPurchaseService() {
    PurchaseService().onPurchaseSuccess = (productId) async {
      // ビンゴシートの購入処理
      final sheetId = PurchaseService.kProductToSheetId[productId];
      if (sheetId != null) {
        await _ref.read(purchasedSheetsProvider.notifier).purchase(sheetId);
      }
      // DiveCloudの購入処理
      if (productId == 'com.hikaru.mybestdiveshot.cloud.monthly') {
        await _ref.read(diveCloudProvider.notifier).activate('monthly');
        onDiveCloudPurchased?.call(productId);
      } else if (productId == 'com.hikaru.mybestdiveshot.cloud.yearly') {
        await _ref.read(diveCloudProvider.notifier).activate('yearly');
        onDiveCloudPurchased?.call(productId);
      }
      // My Select追加の購入処理
      if (productId == PurchaseService.kMySelectExtraProductId) {
        await _ref.read(extraMySelectCountProvider.notifier).addSlot();
      }

      isLoading = false;
      notifyListeners();
    };

    PurchaseService().onPurchaseError = (error) {
      errorMessage = error;
      isLoading = false;
      notifyListeners();
    };
  }

  Future<void> buyProduct(ProductDetails product) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await PurchaseService().buyProduct(product);
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    isLoading = true;
    notifyListeners();
    try {
      await PurchaseService().restorePurchases();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}
