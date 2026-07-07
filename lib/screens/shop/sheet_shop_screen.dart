import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/sheet_definitions.dart';
import '../../constants/app_config.dart';
import '../../providers/purchased_sheets_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/extra_my_select_provider.dart';
import '../../services/purchase_service.dart';
import '../../services/auth_service.dart';
import '../../services/migration_service.dart';

class SheetShopScreen extends ConsumerWidget {
  const SheetShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchased = ref.watch(purchasedSheetsProvider);
    final productsAsync = ref.watch(productsProvider);
    final purchaseNotifier = ref.watch(purchaseNotifierProvider);
    final diveCloud = ref.watch(diveCloudProvider);
    final extraMySelectCount = ref.watch(extraMySelectCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ショップ',
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
            data: (products) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // DiveCloudセクション
                _buildSectionHeader('☁️ DiveCloud'),
                const SizedBox(height: 4),
                const Text(
                  '写真をクラウドに保存し、機種変更や複数端末での同期ができます',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 12),
                _buildCloudProduct(
                  context, ref, products,
                  'com.hikaru.mybestdiveshot.cloud.monthly',
                  'DiveCloud Monthly', '月額プラン', '',
                  diveCloud.isActive && diveCloud.planType == 'monthly',
                ),
                const SizedBox(height: 8),
                _buildCloudProduct(
                  context, ref, products,
                  'com.hikaru.mybestdiveshot.cloud.yearly',
                  'DiveCloud Yearly', '年額プラン', '6ヶ月分お得',
                  diveCloud.isActive && diveCloud.planType == 'yearly',
                ),
                const SizedBox(height: 24),

                // My Select追加セクション
                _buildSectionHeader('✨ My Select を追加'),
                const SizedBox(height: 4),
                Text(
                  extraMySelectCount > 0
                      ? '自分だけのテーマで新しいビンゴシートを追加できます。現在$extraMySelectCount枚追加済み。何度でも購入可能です。'
                      : '自分だけのテーマで新しいビンゴシートを追加できます。何度でも購入可能です。',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 12),
                _buildMySelectProduct(context, ref, products),
                const SizedBox(height: 24),

                // ビンゴシートセクション
                _buildSectionHeader('🎯 ビンゴシートを追加'),
                const SizedBox(height: 4),
                const Text(
                  '新しいビンゴシートを追加して挑戦の幅を広げましょう',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...kExtraSheets.map((sheet) {
                  final isPurchased = AppConfig.isProUser || purchased.contains(sheet.id);
                  final productId = 'com.hikaru.mybestdiveshot.sheet.${sheet.id}';
                  final product = products.where((p) => p.id == productId).firstOrNull;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPurchased ? const Color(0xFF00B4D8) : Colors.white12,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                                  : () => _showSheetPurchaseDialog(context, ref, sheet, product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00B4D8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                product?.price ?? '¥300',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
              ],
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCloudProduct(
    BuildContext context,
    WidgetRef ref,
    List<ProductDetails> products,
    String productId,
    String name,
    String label,
    String badge,
    bool isActive,
  ) {
    final product = products.where((p) => p.id == productId).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFF00B4D8)
              : const Color(0xFF00B4D8).withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            if (badge.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          product?.price ?? '',
          style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 14),
        ),
        trailing: isActive
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF00B4D8), size: 20),
                  SizedBox(width: 6),
                  Text('利用中', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 12)),
                ],
              )
            : ElevatedButton(
                onPressed: product == null
                    ? null
                    : () => _showCloudPurchaseDialog(context, ref, label, product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: const Text('購入', style: TextStyle(fontSize: 12)),
              ),
      ),
    );
  }

  void _showCloudPurchaseDialog(
    BuildContext context,
    WidgetRef ref,
    String label,
    ProductDetails product,
  ) async {
    // サインイン確認
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 未サインインの場合はサインインを促す
      final shouldSignIn = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('サインインが必要です', style: TextStyle(color: Colors.white)),
          content: const Text(
            'DiveCloudはクラウド同期のためApple IDでのサインインが必要です。',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('サインインする', style: TextStyle(color: Color(0xFF00B4D8))),
            ),
          ],
        ),
      );

      if (shouldSignIn != true) return;
      if (!context.mounted) return;

      // サインイン実行
      final result = await AuthService.signInWithApple();
      if (result == null) return;
      if (!context.mounted) return;

      // データ移行
      await MigrationService.migrateToAppleId();
      if (!context.mounted) return;
    }

    // 購入ダイアログ表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('DiveCloud $label', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '写真をクラウドに保存し、機種変更や複数端末での同期ができます。',
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
              'いつでもキャンセルできます',
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

  Widget _buildMySelectProduct(
    BuildContext context,
    WidgetRef ref,
    List<ProductDetails> products,
  ) {
    final product = products
        .where((p) => p.id == PurchaseService.kMySelectExtraProductId)
        .firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: const Text(
          'My Select追加',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          '25テーマを自由に設定できるシートを1枚追加',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: ElevatedButton(
          onPressed: product == null
              ? null
              : () => _showMySelectPurchaseDialog(context, ref, product),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B4D8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
          ),
          child: Text(
            product?.price ?? '¥200',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  void _showMySelectPurchaseDialog(
    BuildContext context,
    WidgetRef ref,
    ProductDetails product,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('My Select追加', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '25テーマを自由に設定できるビンゴシートを1枚追加します。',
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
              '何度でも購入して枠を追加できます',
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

  void _showSheetPurchaseDialog(
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
