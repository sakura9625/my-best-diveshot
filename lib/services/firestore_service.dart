import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tile_data.dart';
import 'device_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<CollectionReference<Map<String, dynamic>>> _tilesRef(String sheetId) async {
    final deviceId = await DeviceService.getDeviceId();
    return _db
        .collection('users')
        .doc(deviceId)
        .collection('sheets')
        .doc(sheetId)
        .collection('tiles');
  }

  static Future<Map<String, TileData>> fetchAllTiles(String sheetId) async {
    final ref = await _tilesRef(sheetId);
    final snapshot = await ref.get();
    final result = <String, TileData>{};
    for (final doc in snapshot.docs) {
      result[doc.id] = TileData.fromMap(doc.id, doc.data());
    }
    return result;
  }

  static Future<void> saveTile(String sheetId, String themeId, TileData tile) async {
    final ref = await _tilesRef(sheetId);
    await ref.doc(themeId).set({
      ...tile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
