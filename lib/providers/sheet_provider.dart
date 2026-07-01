import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/sheet_definitions.dart';
import 'bingo_provider.dart';

final currentSheetProvider = StateProvider<String>((ref) => 'open_water');

final currentSheetDefinitionProvider = Provider<SheetDefinition>((ref) {
  final sheetId = ref.watch(currentSheetProvider);
  return kDefaultSheets.firstWhere(
    (s) => s.id == sheetId,
    orElse: () => kDefaultSheets.first,
  );
});

// シートがアンロック済みかどうか
final sheetUnlockedProvider = Provider.family<bool, String>((ref, sheetId) {
  if (sheetId == 'open_water') return true;
  final sheet = kDefaultSheets.firstWhere(
    (s) => s.id == sheetId,
    orElse: () => kDefaultSheets.first,
  );
  if (sheet.unlockRequiredBingos == null) return true;
  final owBingoCount = ref.watch(bingoCountProvider('open_water'));
  return owBingoCount >= sheet.unlockRequiredBingos!;
});
