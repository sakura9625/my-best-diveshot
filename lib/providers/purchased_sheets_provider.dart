import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/device_service.dart';

final purchasedSheetsProvider = StateNotifierProvider<PurchasedSheetsNotifier, List<String>>((ref) {
  final notifier = PurchasedSheetsNotifier();
  notifier.load();
  return notifier;
});

class PurchasedSheetsNotifier extends StateNotifier<List<String>> {
  PurchasedSheetsNotifier() : super([]);

  static final _db = FirebaseFirestore.instance;

  Future<DocumentReference<Map<String, dynamic>>> _ref() async {
    final deviceId = await DeviceService.getDeviceId();
    return _db.collection('users').doc(deviceId).collection('settings').doc('purchased_sheets');
  }

  Future<void> load() async {
    try {
      final ref = await _ref();
      final doc = await ref.get();
      if (doc.exists && doc.data()?['sheets'] != null) {
        state = List<String>.from(doc.data()!['sheets']);
      }
    } catch (e) {
      debugPrint('PurchasedSheets load error: $e');
    }
  }

  Future<void> purchase(String sheetId) async {
    if (state.contains(sheetId)) return;
    state = [...state, sheetId];
    try {
      final ref = await _ref();
      await ref.set({'sheets': state});
    } catch (e) {
      debugPrint('PurchasedSheets save error: $e');
    }
  }

  bool isPurchased(String sheetId) => state.contains(sheetId);
}
