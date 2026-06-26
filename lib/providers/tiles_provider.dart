import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tile_data.dart';
import '../models/best_photo.dart';
import '../services/image_service.dart';
import '../services/firestore_service.dart';

final tilesProvider = StateNotifierProvider<TilesNotifier, Map<String, TileData>>((ref) {
  return TilesNotifier();
});

class TilesNotifier extends StateNotifier<Map<String, TileData>> {
  TilesNotifier() : super({}) {
    _loadFromFirestore();
  }

  List<int> _previousBingoLines = [];

  List<int> getNewlyCompletedLines(List<int> currentLines) {
    final newLines = currentLines
        .where((line) => !_previousBingoLines.contains(line))
        .toList();
    _previousBingoLines = List.from(currentLines);
    return newLines;
  }

  // Firestoreからロード
  Future<void> _loadFromFirestore() async {
    try {
      final tiles = await FirestoreService.fetchAllTiles();
      state = tiles;
    } catch (e) {
      // オフライン時はローカル状態を維持
    }
  }

  Future<void> pickAndRegisterPhoto(String themeId, {bool fromFiles = false}) async {
    final path = fromFiles
        ? await ImageService.pickFromFiles(themeId)
        : await ImageService.pickFromGallery(themeId);
    if (path == null) return;

    final existing = state[themeId];
    final newPhoto = BestPhoto(
      fileName: path,
      subjectName: '',
      title: '',
      location: '',
      comment: '',
      registeredAt: DateTime.now(),
    );

    final newHistory = [
      ...existing?.history ?? [],
      if (existing?.currentBest != null) existing!.currentBest!,
    ];

    final newTile = TileData(
      themeId: themeId,
      currentBest: newPhoto,
      history: newHistory,
    );

    // 先にstateを更新してUIに即反映
    state = {...state, themeId: newTile};

    // その後Firestoreに非同期保存
    FirestoreService.saveTile(themeId, newTile).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  Future<void> updatePhotoMeta(String themeId, BestPhoto updated) async {
    final existing = state[themeId];
    if (existing == null) return;

    final newTile = existing.copyWith(currentBest: updated);
    state = {...state, themeId: newTile};
    await FirestoreService.saveTile(themeId, newTile);
  }

  void restoreFromHistory(String themeId, int historyIndex) async {
    final existing = state[themeId];
    if (existing == null || existing.currentBest == null) return;

    final historyPhoto = existing.history[historyIndex];
    final newHistory = List<BestPhoto>.from(existing.history)
      ..removeAt(historyIndex)
      ..add(existing.currentBest!);

    final newTile = TileData(
      themeId: themeId,
      currentBest: historyPhoto,
      history: newHistory,
    );

    state = {...state, themeId: newTile};
    await FirestoreService.saveTile(themeId, newTile);
  }
}

final completedCountProvider = Provider<int>((ref) {
  final tiles = ref.watch(tilesProvider);
  return tiles.values.where((t) => t.hasPhoto).length;
});
