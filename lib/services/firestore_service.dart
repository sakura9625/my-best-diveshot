import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tile_data.dart';
import '../models/best_photo.dart';
import 'device_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<CollectionReference<Map<String, dynamic>>> _tilesRef() async {
    final deviceId = await DeviceService.getDeviceId();
    return _db.collection('users').doc(deviceId).collection('tiles');
  }

  // 全タイル取得
  static Future<Map<String, TileData>> fetchAllTiles() async {
    final ref = await _tilesRef();
    final snapshot = await ref.get();
    final result = <String, TileData>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentBestData = data['currentBest'] as Map<String, dynamic>?;
      final historyData = data['history'] as List<dynamic>? ?? [];

      result[doc.id] = TileData(
        themeId: doc.id,
        currentBest: currentBestData != null
            ? BestPhoto.fromMap(currentBestData)
            : null,
        history: historyData
            .map((h) => BestPhoto.fromMap(h as Map<String, dynamic>))
            .toList(),
      );
    }
    return result;
  }

  // タイルを保存
  static Future<void> saveTile(String themeId, TileData tile) async {
    final ref = await _tilesRef();
    await ref.doc(themeId).set({
      'themeId': themeId,
      'currentBest': tile.currentBest?.toMap(),
      'history': tile.history.map((h) => h.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
