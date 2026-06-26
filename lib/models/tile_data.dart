import 'best_photo.dart';

enum TileStatus { empty, provisional, king }

class TileData {
  final String themeId;
  final BestPhoto? currentBest;
  final TileStatus status;
  final List<BestPhoto> history;

  const TileData({
    required this.themeId,
    this.currentBest,
    this.status = TileStatus.empty,
    this.history = const [],
  });

  bool get hasPhoto => currentBest != null;
  bool get isKing => status == TileStatus.king;
  bool get isProvisional => status == TileStatus.provisional;

  TileData copyWith({
    BestPhoto? currentBest,
    TileStatus? status,
    List<BestPhoto>? history,
  }) => TileData(
    themeId: themeId,
    currentBest: currentBest ?? this.currentBest,
    status: status ?? this.status,
    history: history ?? this.history,
  );

  Map<String, dynamic> toMap() => {
    'themeId': themeId,
    'status': status.name,
    'currentBest': currentBest?.toMap(),
    'history': history.map((h) => h.toMap()).toList(),
  };

  factory TileData.fromMap(String themeId, Map<String, dynamic> data) {
    final statusStr = data['status'] as String? ?? 'empty';
    TileStatus status;
    switch (statusStr) {
      case 'king':
        status = TileStatus.king;
        break;
      case 'provisional':
        status = TileStatus.provisional;
        break;
      default:
        status = TileStatus.empty;
    }

    final currentBestData = data['currentBest'] as Map<String, dynamic>?;
    final historyData = data['history'] as List<dynamic>? ?? [];

    return TileData(
      themeId: themeId,
      status: status,
      currentBest: currentBestData != null
          ? BestPhoto.fromMap(currentBestData)
          : null,
      history: historyData
          .map((h) => BestPhoto.fromMap(h as Map<String, dynamic>))
          .toList(),
    );
  }
}
