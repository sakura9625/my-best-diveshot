import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tile_data.dart';
import '../models/best_photo.dart';
import '../services/image_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'purchased_sheets_provider.dart';

final tilesProvider = StateNotifierProvider.family<TilesNotifier, Map<String, TileData>, String>((ref, sheetId) {
  return TilesNotifier(sheetId, ref);
});

class TilesNotifier extends StateNotifier<Map<String, TileData>> {
  final String sheetId;
  final Ref? _ref;
  TilesNotifier(this.sheetId, [this._ref]) : super({}) {
    _loadFromFirestore();
  }

  List<int> _previousBingoLines = [];

  Future<void> _loadFromFirestore() async {
    try {
      final tiles = await FirestoreService.fetchAllTiles(sheetId);
      state = tiles;

      // DiveCloud有効時は写真をローカルに同期
      final diveCloud = _ref?.read(diveCloudProvider);
      if (diveCloud?.isActive == true) {
        await _syncPhotosFromStorage(tiles);
      }
    } catch (e) {
      debugPrint('Firestore load error: $e');
    }
  }

  Future<void> _syncPhotosFromStorage(Map<String, TileData> tiles) async {
    try {
      final allPhotos = <BestPhoto>[];
      for (final tile in tiles.values) {
        if (tile.currentBest != null) allPhotos.add(tile.currentBest!);
        allPhotos.addAll(tile.history);
      }

      for (final photo in allPhotos) {
        final localPath = await ImageService.resolveImagePath(photo.fileName);
        if (!File(localPath).existsSync()) {
          // ローカルにない場合はStorageからダウンロード
          final url = await StorageService.getDownloadUrl(
            sheetId: sheetId,
            fileName: photo.fileName,
          );
          if (url != null) {
            await StorageService.downloadPhoto(
              downloadUrl: url,
              fileName: photo.fileName,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Sync photos error: $e');
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

    // DiveCloud有効時はStorageにもアップロード
    final diveCloud = _ref?.read(diveCloudProvider);
    if (diveCloud?.isActive == true) {
      ImageService.resolveImagePath(result.fileName).then((localPath) {
        StorageService.uploadPhoto(
          localPath: localPath,
          sheetId: sheetId,
          themeId: themeId,
          fileName: result.fileName,
        );
      }).catchError((e) {
        debugPrint('Storage upload error: $e');
      });
    }

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
    final newPhoto = BestPhoto(
      fileName: result.fileName,
      subjectName: '',
      title: '',
      location: '',
      shotDate: result.shotDate,
      comment: '',
      registeredAt: DateTime.now(),
    );

    // 旧王者を歴代の末尾に追加（isKingの場合のみ）
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

    // DiveCloud有効時はStorageにもアップロード
    final diveCloud = _ref?.read(diveCloudProvider);
    if (diveCloud?.isActive == true) {
      final localPath = await ImageService.resolveImagePath(result.fileName);
      StorageService.uploadPhoto(
        localPath: localPath,
        sheetId: sheetId,
        themeId: themeId,
        fileName: result.fileName,
      ).catchError((e) {
        debugPrint('Storage upload error: $e');
        return null;
      });
    }

    FirestoreService.saveTile(sheetId, themeId, newTile).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  Future<void> cancelProvisional(String themeId) async {
    final existing = state[themeId];
    if (existing == null || !existing.isProvisional) return;

    if (existing.history.isNotEmpty) {
      // 歴代の末尾が直前の王者なので復元
      final previousKing = existing.history.last;
      final newHistory = existing.history.sublist(0, existing.history.length - 1);
      final newTile = TileData(
        themeId: themeId,
        currentBest: previousKing,
        status: TileStatus.king,
        history: newHistory,
      );
      state = {...state, themeId: newTile};
      FirestoreService.saveTile(sheetId, themeId, newTile).catchError((e) {
        debugPrint('Firestore save error: $e');
      });
    } else {
      // 歴代がない場合（初回仮登録のキャンセル）は空に戻す
      final newTile = TileData(
        themeId: themeId,
        currentBest: null,
        status: TileStatus.empty,
        history: const [],
      );
      state = {...state, themeId: newTile};
      FirestoreService.saveTile(sheetId, themeId, newTile).catchError((e) {
        debugPrint('Firestore save error: $e');
      });
    }
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
