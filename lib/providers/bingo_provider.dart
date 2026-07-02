import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/themes.dart';
import '../constants/advance_themes.dart';
import '../constants/extra_sheet_themes.dart';
import '../constants/sheet_definitions.dart';
import 'tiles_provider.dart';
import 'my_select_provider.dart';

List<ThemeDefinition> getThemesForSheet(String sheetId, {List<ThemeDefinition>? mySelectThemes}) {
  switch (sheetId) {
    case 'advance':
      return kAdvanceThemes;
    case 'my_select':
      return mySelectThemes ?? kDefaultMySelectThemes.map((t) => toThemeDefinition(t)).toList();
    default:
      // 追加シートのテーマを検索
      if (kExtraSheetThemesMap.containsKey(sheetId)) {
        return kExtraSheetThemesMap[sheetId]!;
      }
      return kThemes;
  }
}

final completedBingoLinesProvider = Provider.family<List<int>, String>((ref, sheetId) {
  final tiles = ref.watch(tilesProvider(sheetId));
  final List<ThemeDefinition> themes;

  switch (sheetId) {
    case 'advance':
      themes = kAdvanceThemes;
      break;
    case 'my_select':
      // mySelectThemeDefinitionsProviderから最新のテーマを取得
      themes = ref.watch(mySelectThemeDefinitionsProvider);
      break;
    default:
      themes = kExtraSheetThemesMap[sheetId] ?? kThemes;
  }

  final completedLines = <int>[];

  for (int i = 0; i < kBingoLines.length; i++) {
    final line = kBingoLines[i];
    final isCompleted = line.every((index) {
      if (index >= themes.length) return false;
      final themeId = themes[index].id;
      return tiles[themeId]?.isKing ?? false;
    });
    if (isCompleted) completedLines.add(i);
  }
  return completedLines;
});

final bingoCountProvider = Provider.family<int, String>((ref, sheetId) {
  return ref.watch(completedBingoLinesProvider(sheetId)).length;
});
