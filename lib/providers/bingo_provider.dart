import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/themes.dart';
import 'tiles_provider.dart';

final completedBingoLinesProvider = Provider<List<int>>((ref) {
  final tiles = ref.watch(tilesProvider);
  final completedLines = <int>[];

  for (int i = 0; i < kBingoLines.length; i++) {
    final line = kBingoLines[i];
    final isCompleted = line.every((index) {
      final themeId = kThemes[index].id;
      return tiles[themeId]?.hasPhoto ?? false;
    });
    if (isCompleted) completedLines.add(i);
  }
  return completedLines;
});

final bingoCountProvider = Provider<int>((ref) {
  return ref.watch(completedBingoLinesProvider).length;
});
