import 'best_photo.dart';

class TileData {
  final String themeId;
  final BestPhoto? currentBest;
  final List<BestPhoto> history;

  const TileData({
    required this.themeId,
    this.currentBest,
    this.history = const [],
  });

  bool get hasPhoto => currentBest != null;

  TileData copyWith({
    BestPhoto? currentBest,
    List<BestPhoto>? history,
  }) => TileData(
    themeId: themeId,
    currentBest: currentBest ?? this.currentBest,
    history: history ?? this.history,
  );
}
