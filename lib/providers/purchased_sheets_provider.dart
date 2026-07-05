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

// DiveCloudサブスク管理
final diveCloudProvider = StateNotifierProvider<DiveCloudNotifier, DiveCloudState>((ref) {
  final notifier = DiveCloudNotifier();
  notifier.load();
  return notifier;
});

class DiveCloudState {
  final bool isActive;
  final String? planType; // 'monthly' or 'yearly'
  final DateTime? expiresAt;

  const DiveCloudState({
    this.isActive = false,
    this.planType,
    this.expiresAt,
  });
}

class DiveCloudNotifier extends StateNotifier<DiveCloudState> {
  DiveCloudNotifier() : super(const DiveCloudState());

  static final _db = FirebaseFirestore.instance;

  Future<DocumentReference<Map<String, dynamic>>> _ref() async {
    final deviceId = await DeviceService.getDeviceId();
    return _db.collection('users').doc(deviceId).collection('settings').doc('dive_cloud');
  }

  Future<void> load() async {
    try {
      final ref = await _ref();
      final doc = await ref.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final expiresAt = data['expiresAt'] != null
            ? (data['expiresAt'] as dynamic).toDate()
            : null;
        final isActive = expiresAt == null || expiresAt.isAfter(DateTime.now());
        state = DiveCloudState(
          isActive: data['isActive'] == true && isActive,
          planType: data['planType'],
          expiresAt: expiresAt,
        );
      }
    } catch (e) {
      debugPrint('DiveCloud load error: $e');
    }
  }

  Future<void> activate(String planType) async {
    final now = DateTime.now();
    final expiresAt = planType == 'yearly'
        ? now.add(const Duration(days: 365))
        : now.add(const Duration(days: 30));

    state = DiveCloudState(
      isActive: true,
      planType: planType,
      expiresAt: expiresAt,
    );

    try {
      final ref = await _ref();
      await ref.set({
        'isActive': true,
        'planType': planType,
        'expiresAt': expiresAt,
        'activatedAt': now,
      });
    } catch (e) {
      debugPrint('DiveCloud save error: $e');
    }
  }
}
