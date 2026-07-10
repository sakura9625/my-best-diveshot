import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/sheet_definitions.dart';
import '../models/tile_data.dart';
import '../providers/tiles_provider.dart';
import '../providers/purchased_sheets_provider.dart';
import '../constants/app_config.dart';
import 'storage_service.dart';

class BatchUploadService {
  // DiveCloud有効時に全写真をStorageにアップロード
  static Future<void> uploadAllPhotos(
    WidgetRef ref,
    BuildContext context,
  ) async {
    // 全シートIDを収集
    final purchased = ref.read(purchasedSheetsProvider);
    final allSheetIds = [
      ...kDefaultSheets.map((s) => s.id),
      ...kExtraSheets
          .where((s) => AppConfig.isProUser || purchased.contains(s.id))
          .map((s) => s.id),
    ];

    // 各シートのtilesを収集
    final allSheetTiles = <String, Map<String, TileData>>{};
    for (final sheetId in allSheetIds) {
      final tiles = ref.read(tilesProvider(sheetId));
      if (tiles.isNotEmpty) {
        allSheetTiles[sheetId] = tiles;
      }
    }

    if (allSheetTiles.isEmpty) return;

    // 進捗スナックバー表示
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📤 クラウドに写真を同期中...'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF00B4D8),
        ),
      );
    }

    // バックグラウンドでアップロード
    await StorageService.uploadAllLocalPhotos(
      allSheetTiles: allSheetTiles,
      onProgress: (done, total) {
        debugPrint('Upload progress: $done/$total');
      },
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ クラウドへの同期が完了しました'),
          duration: Duration(seconds: 3),
          backgroundColor: Color(0xFF00B4D8),
        ),
      );
    }
  }
}
