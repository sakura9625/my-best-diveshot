import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/sheet_definitions.dart';

final currentSheetProvider = StateProvider<String>((ref) => 'open_water');

final currentSheetDefinitionProvider = Provider<SheetDefinition>((ref) {
  final sheetId = ref.watch(currentSheetProvider);
  return kDefaultSheets.firstWhere(
    (s) => s.id == sheetId,
    orElse: () => kDefaultSheets.first,
  );
});
