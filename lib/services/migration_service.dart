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

      if (localDeviceId == appleUserId) return; // 同じIDなら移行不要

      final sourceRef = _db.collection('users').doc(localDeviceId);
      final targetRef = _db.collection('users').doc(appleUserId);

      // すでに移行済みか確認
      final targetDoc = await targetRef.get();
      if (targetDoc.exists) {
        debugPrint('Migration: target already exists, skipping');
        return;
      }

      // tilesコレクションを移行
      await _migrateCollection(
        source: sourceRef.collection('tiles'),
        target: targetRef.collection('tiles'),
      );

      // settingsコレクションを移行
      await _migrateCollection(
        source: sourceRef.collection('settings'),
        target: targetRef.collection('settings'),
      );

      // sheetsコレクションを移行
      final sheetsSnapshot = await sourceRef.collection('sheets').get();
      for (final sheetDoc in sheetsSnapshot.docs) {
        await _migrateCollection(
          source: sheetDoc.reference.collection('tiles'),
          target: targetRef.collection('sheets').doc(sheetDoc.id).collection('tiles'),
        );
      }

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
