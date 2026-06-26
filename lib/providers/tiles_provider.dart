import 'package:flutter/material.dart';
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

  Future<void> _loadFromFirestore() async {
    try {
      final tiles = await FirestoreService.fetchAllTiles();
      state = tiles;
    } catch (e) {
      debugPrint('Firestore load error: $e');
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

    final newTile = TileData(
      themeId: themeId,
      currentBest: newPhoto,
      status: TileStatus.provisional,
      history: existing?.history ?? [],
    );

    state = {...state, themeId: newTile};
    FirestoreService.saveTile(themeId, newTile).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  Future<void> crownAsKing(String themeId) async {
    final existing = state[themeId];
    if (existing == null || existing.currentBest == null) return;
    if (existing.isKing) return;

    final newTile = existing.copyWith(status: TileStatus.king);
    state = {...state, themeId: newTile};
    FirestoreService.saveTile(themeId, newTile).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  Future<void> updateKing(String themeId, {bool fromFiles = false}) async {
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
      if (existing?.isKing == true) existing!.currentBest!,
    ];

    final newTile = TileData(
      themeId: themeId,
      currentBest: newPhoto,
      status: TileStatus.provisional,
      history: newHistory,
    );

    state = {...state, themeId: newTile};
    FirestoreService.saveTile(themeId, newTile).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  Future<void> updatePhotoMeta(String themeId, BestPhoto updated) async {
    final existing = state[themeId];
    if (existing == null) return;
    final newTile = existing.copyWith(currentBest: updated);
    state = {...state, themeId: newTile};
    FirestoreService.saveTile(themeId, newTile).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  void restoreFromHistory(String themeId, int historyIndex) {
    final existing = state[themeId];
    if (existing == null || existing.currentBest == null) return;

    final historyPhoto = existing.history[historyIndex];
    final newHistory = List<BestPhoto>.from(existing.history)
      ..removeAt(historyIndex)
      ..add(existing.currentBest!);

    final newTile = TileData(
      themeId: themeId,
      currentBest: historyPhoto,
      status: TileStatus.king,
      history: newHistory,
    );

    state = {...state, themeId: newTile};
    FirestoreService.saveTile(themeId, newTile).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  List<int> getNewlyCompletedLines(List<int> currentLines) {
    final newLines = currentLines
        .where((line) => !_previousBingoLines.contains(line))
        .toList();
    _previousBingoLines = List.from(currentLines);
    return newLines;
  }
}

final completedCountProvider = Provider<int>((ref) {
  final tiles = ref.watch(tilesProvider);
  return tiles.values.where((t) => t.isKing).length;
});
