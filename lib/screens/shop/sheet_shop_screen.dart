import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/sheet_definitions.dart';
import '../../constants/app_config.dart';
import '../../providers/purchased_sheets_provider.dart';
import '../../providers/sheet_provider.dart';

class SheetShopScreen extends ConsumerWidget {
  const SheetShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchased = ref.watch(purchasedSheetsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ビンゴシートを追加',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: kExtraSheets.length,
        itemBuilder: (context, index) {
          final sheet = kExtraSheets[index];
          final isPurchased = AppConfig.isProUser || purchased.contains(sheet.id);

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
                      onPressed: () => _showPurchaseDialog(context, ref, sheet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('追加する', style: TextStyle(fontSize: 12)),
                    ),
            ),
          );
        },
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, WidgetRef ref, SheetDefinition sheet) {
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
            // 将来：価格表示
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white38, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '開発中：現在は無料で追加できます',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(purchasedSheetsProvider.notifier).purchase(sheet.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${sheet.name}を追加しました！'),
                    backgroundColor: const Color(0xFF00B4D8),
                  ),
                );
              }
            },
            child: const Text('追加する', style: TextStyle(color: Color(0xFF00B4D8))),
          ),
        ],
      ),
    );
  }
}
