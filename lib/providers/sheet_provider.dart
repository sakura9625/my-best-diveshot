import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/sheet_definitions.dart';
import '../constants/app_config.dart';
import 'bingo_provider.dart';

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

  // 追加シート（課金）は課金フラグで管理（将来課金実装時に変更）
  final isExtraSheet = kExtraSheets.any((s) => s.id == sheetId);
  if (isExtraSheet) return AppConfig.isProUser;

  final sheetIndex = kDefaultSheets.indexWhere((s) => s.id == sheetId);
  if (sheetIndex == -1) return false;

  final sheet = kDefaultSheets[sheetIndex];
  if (sheet.unlockRequiredBingos == null) return true;

  final requiredSheetId = sheet.unlockRequiredSheetId ?? 'open_water';
  final bingoCount = ref.watch(bingoCountProvider(requiredSheetId));
  return bingoCount >= sheet.unlockRequiredBingos!;
});
