import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/sheet_definitions.dart';
import '../constants/app_config.dart';
import 'bingo_provider.dart';
import 'purchased_sheets_provider.dart';

final currentSheetProvider = StateProvider<String>((ref) => 'open_water');

final currentSheetDefinitionProvider = Provider<SheetDefinition>((ref) {
  final sheetId = ref.watch(currentSheetProvider);
  return kDefaultSheets.firstWhere(
    (s) => s.id == sheetId,
    orElse: () => kDefaultSheets.first,
  );
});

final sheetUnlockedProvider = Provider.family<bool, String>((ref, sheetId) {
  if (sheetId == 'open_water') return true;

  // 追加My Select（購入済みスロットのみタブに表示されるため常に解放）
  if (sheetId.startsWith('extra_my_select_')) return true;

  // 追加シート（課金）の判定
  final isExtraSheet = kExtraSheets.any((s) => s.id == sheetId);
  if (isExtraSheet) {
    if (AppConfig.isProUser) return true;
    final purchased = ref.watch(purchasedSheetsProvider);
    return purchased.contains(sheetId);
  }

  // デフォルトシートのロック判定
  final sheetIndex = kDefaultSheets.indexWhere((s) => s.id == sheetId);
  if (sheetIndex == -1) return false;

  final sheet = kDefaultSheets[sheetIndex];
  if (sheet.unlockRequiredBingos == null) return true;

  final requiredSheetId = sheet.unlockRequiredSheetId ?? 'open_water';
  final bingoCount = ref.watch(bingoCountProvider(requiredSheetId));
  return bingoCount >= sheet.unlockRequiredBingos!;
});
