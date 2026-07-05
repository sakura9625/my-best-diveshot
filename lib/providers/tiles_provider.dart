import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tile_data.dart';
import '../models/best_photo.dart';
import '../services/image_service.dart';
import '../services/firestore_service.dart';

final tilesProvider = StateNotifierProvider.family<TilesNotifier, Map<String, TileData>, String>((ref, sheetId) {
  return TilesNotifier(sheetId);
});

class TilesNotifier extends StateNotifier<Map<String, TileData>> {
  final String sheetId;
  TilesNotifier(this.sheetId) : super({}) {
    _loadFromFirestore();
  }

  List<int> _previousBingoLines = [];

  Future<void> _loadFromFirestore() async {
    try {
      final tiles = await FirestoreService.fetchAllTiles(sheetId);
      state = tiles;
    } catch (e) {
      debugPrint('Firestore load error: $e');
    }
  }

  Future<void> pickAndRegisterPhoto(String themeId, {bool fromFiles = false}) async {
    final result = fromFiles
        ? await ImageService.pickFromFiles(themeId)
        : await ImageService.pickFromGallery(themeId);
    if (result == null) return;

    final existing = state[themeId];
    final newPhoto = BestPhoto(
      fileName: result.fileName,
      subjectName: '',
      title: '',
      location: '',
      shotDate: result.shotDate,
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
    FirestoreService.saveTile(sheetId, themeId, newTile).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  Future<void> crownAsKing(String themeId) async {
    final existing = state[themeId];
    if (existing == null || existing.currentBest == null) return;
    if (existing.isKing) return;

    final allCrownCounts = [
      ...existing.history.map((h) => h.crownCount),
      existing.currentBest!.crownCount,
    ];
    final maxCrownCount = allCrownCounts.isEmpty ? 0 : allCrownCounts.reduce((a, b) => a > b ? a : b);

    final crowned = existing.currentBest!.copyWith(
      crownedAt: DateTime.now(),
      crownCount: maxCrownCount + 1,
      isRestored: false,
    );

    final newTile = TileData(
      themeId: themeId,
      currentBest: crowned,
      status: TileStatus.king,
      history: existing.history,
    );

    state = {...state, themeId: newTile};
    FirestoreService.saveTile(sheetId, themeId, newTile).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  Future<void> updateKing(String themeId, {bool fromFiles = false}) async {
    final result = fromFiles
        ? await ImageService.pickFromFiles(themeId)
        : await ImageService.pickFromGallery(themeId);
    if (result == null) return;

    final existing = state[themeId];
    final prevCrownCount = existing?.history.isNotEmpty == true
        ? existing!.history.map((h) => h.crownCount).reduce((a, b) => a > b ? a : b)
        : existing?.currentBest?.crownCount ?? 0;

    final newPhoto = BestPhoto(
      fileName: result.fileName,
      subjectName: '',
      title: '',
      location: '',
      shotDate: result.shotDate,
      comment: '',
      registeredAt: DateTime.now(),
      crownedAt: DateTime.now(),
      crownCount: prevCrownCount + 1,
      isRestored: false,
    );

    final newHistory = <BestPhoto>[
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
    FirestoreService.saveTile(sheetId, themeId, newTile).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  Future<void> updatePhotoMeta(String themeId, BestPhoto updated) async {
    final existing = state[themeId];
    if (existing == null) return;
    final newTile = existing.copyWith(currentBest: updated);
    state = {...state, themeId: newTile};
    FirestoreService.saveTile(sheetId, themeId, newTile).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  void restoreFromHistory(String themeId, int historyIndex) {
    final existing = state[themeId];
    if (existing == null || existing.currentBest == null) return;

    final historyPhoto = existing.history[historyIndex];
    final prevCrownCount = existing.history.isNotEmpty
        ? existing.history.map((h) => h.crownCount).reduce((a, b) => a > b ? a : b)
        : 0;

    final restored = historyPhoto.copyWith(
      crownedAt: DateTime.now(),
      crownCount: prevCrownCount + 1,
      isRestored: true,
    );

    final newHistory = <BestPhoto>[...existing.history]
      ..removeAt(historyIndex)
      ..add(existing.currentBest!);

    final newTile = TileData(
      themeId: themeId,
      currentBest: restored,
      status: TileStatus.king,
      history: newHistory,
    );

    state = {...state, themeId: newTile};
    FirestoreService.saveTile(sheetId, themeId, newTile).catchError((e) {
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

final completedCountProvider = Provider.family<int, String>((ref, sheetId) {
  final tiles = ref.watch(tilesProvider(sheetId));
  return tiles.values.where((t) => t.isKing).length;
});
