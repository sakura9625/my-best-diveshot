import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/tile_data.dart';
import '../models/best_photo.dart';

final tilesProvider = StateNotifierProvider<TilesNotifier, Map<String, TileData>>((ref) {
  return TilesNotifier();
});

class TilesNotifier extends StateNotifier<Map<String, TileData>> {
  TilesNotifier() : super({});

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  Future<void> pickAndRegisterPhoto(String themeId) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${themeId}_${_uuid.v4()}.jpg';
    final destPath = '${dir.path}/$fileName';
    await File(picked.path).copy(destPath);

    final existing = state[themeId];
    final newPhoto = BestPhoto(
      localImagePath: destPath,
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
}

final completedCountProvider = Provider<int>((ref) {
  final tiles = ref.watch(tilesProvider);
  return tiles.values.where((t) => t.hasPhoto).length;
});
