import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../constants/sheet_definitions.dart';
import '../../constants/app_config.dart';
import '../../providers/purchased_sheets_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/sheet_provider.dart';

class SheetShopScreen extends ConsumerWidget {
  const SheetShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchased = ref.watch(purchasedSheetsProvider);
    final productsAsync = ref.watch(productsProvider);
    final purchaseNotifier = ref.watch(purchaseNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ビンゴシートを追加',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(purchaseNotifierProvider).restorePurchases(),
            child: const Text('購入を復元', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 12)),
          ),
        ],
      ),
      body: Stack(
        children: [
          productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(
              child: Text('商品情報の取得に失敗しました', style: TextStyle(color: Colors.white54)),
            ),
            data: (products) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: kExtraSheets.length,
              itemBuilder: (context, index) {
                final sheet = kExtraSheets[index];
                final isPurchased = AppConfig.isProUser || purchased.contains(sheet.id);
                final productId = 'com.hikaru.mybestdiveshot.sheet.${sheet.id}';
                final product = products.where((p) => p.id == productId).firstOrNull;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPurchased ? const Color(0xFF00B4D8) : Colors.white12,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      sheet.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      '25テーマ',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    trailing: isPurchased
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF00B4D8), size: 20),
                              SizedBox(width: 6),
                              Text('追加済み', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 12)),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: product == null
                                ? null
                                : () => _showPurchaseDialog(context, ref, sheet, product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B4D8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: Text(
                              product?.price ?? '¥300',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          if (purchaseNotifier.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(
    BuildContext context,
    WidgetRef ref,
    SheetDefinition sheet,
    ProductDetails product,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(sheet.name, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '25テーマのビンゴシートを追加します。',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              product.price,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '一度購入すると永久に使えます',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(purchaseNotifierProvider).buyProduct(product);
            },
            child: const Text('購入する', style: TextStyle(color: Color(0xFF00B4D8))),
          ),
        ],
      ),
    );
  }
}
