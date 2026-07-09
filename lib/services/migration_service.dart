import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'device_service.dart';

class MigrationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // デバイスIDのデータをApple IDに移行
  static Future<void> migrateToAppleId() async {
    try {
      final localDeviceId = await DeviceService.getLocalDeviceId();
      final appleUserId = await DeviceService.getDeviceId();

      if (localDeviceId == appleUserId) return;

      final targetRef = _db.collection('users').doc(appleUserId);
      final targetDoc = await targetRef.get();
      if (targetDoc.exists) {
        // サブコレクションがあるか確認
        final targetTiles = await targetRef
            .collection('sheets')
            .doc('open_water')
            .collection('tiles')
            .limit(1)
            .get();
        if (targetTiles.docs.isNotEmpty) {
          debugPrint('Migration: target already has data, skipping');
          return;
        }
      }

      // 全シートIDを直接取得（ハンギングドキュメント対応）
      const sheetIds = [
        'open_water', 'advance', 'my_select',
        'ishigaki', 'izu', 'macro', 'wide', 'kushimoto',
        'kashiwajima', 'deep', 'hanadi', 'nudibranch_iro',
        'nudibranch_other', 'goby_bingo', 'crustacean_standard',
        'crustacean_hidden',
      ];

      final sourceRef = _db.collection('users').doc(localDeviceId);

      for (final sheetId in sheetIds) {
        await _migrateCollection(
          source: sourceRef.collection('sheets').doc(sheetId).collection('tiles'),
          target: targetRef.collection('sheets').doc(sheetId).collection('tiles'),
        );
      }

      // settingsを移行
      await _migrateCollection(
        source: sourceRef.collection('settings'),
        target: targetRef.collection('settings'),
      );

      debugPrint('Migration: completed successfully');
    } catch (e) {
      debugPrint('Migration error: $e');
    }
  }

  static Future<void> _migrateCollection({
    required CollectionReference source,
    required CollectionReference target,
  }) async {
    final snapshot = await source.get();
    for (final doc in snapshot.docs) {
      await target.doc(doc.id).set(doc.data() as Map<String, dynamic>);
    }
  }
}
