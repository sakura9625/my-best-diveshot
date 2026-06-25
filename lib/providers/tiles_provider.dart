import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tile_data.dart';
import '../models/best_photo.dart';
import '../services/image_service.dart';

final tilesProvider = StateNotifierProvider<TilesNotifier, Map<String, TileData>>((ref) {
  return TilesNotifier();
});

class TilesNotifier extends StateNotifier<Map<String, TileData>> {
  TilesNotifier() : super({});

  Future<void> pickAndRegisterPhoto(String themeId, {bool fromFiles = false}) async {
    final path = fromFiles
        ? await ImageService.pickFromFiles(themeId)
        : await ImageService.pickFromGallery(themeId);
    if (path == null) return;

    final existing = state[themeId];
    final newPhoto = BestPhoto(
      localImagePath: path,
      subjectName: '',
      title: '',
      location: '',
      comment: '',
      registeredAt: DateTime.now(),
    );

    final newHistory = <BestPhoto>[
      ...existing?.history ?? [],
      if (existing?.currentBest != null) existing!.currentBest!,
    ];

    state = {
      ...state,
      themeId: TileData(
        themeId: themeId,
        currentBest: newPhoto,
        history: newHistory,
      ),
    };
  }

  Future<void> updatePhotoMeta(String themeId, BestPhoto updated) async {
    final existing = state[themeId];
    if (existing == null) return;
    state = {
      ...state,
      themeId: existing.copyWith(currentBest: updated),
    };
  }

  void restoreFromHistory(String themeId, int historyIndex) {
    final existing = state[themeId];
    if (existing == null || existing.currentBest == null) return;

    final historyPhoto = existing.history[historyIndex];
    final newHistory = List<BestPhoto>.from(existing.history)
      ..removeAt(historyIndex)
      ..add(existing.currentBest!);

    state = {
      ...state,
      themeId: TileData(
        themeId: themeId,
        currentBest: historyPhoto,
        history: newHistory,
      ),
    };
  }
}

final completedCountProvider = Provider<int>((ref) {
  final tiles = ref.watch(tilesProvider);
  return tiles.values.where((t) => t.hasPhoto).length;
});
