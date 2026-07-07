import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/my_select_theme.dart';
import '../constants/themes.dart';
import '../services/device_service.dart';

// 追加My Selectスロット数
final extraMySelectCountProvider = StateNotifierProvider<ExtraMySelectCountNotifier, int>((ref) {
  final notifier = ExtraMySelectCountNotifier();
  notifier.load();
  return notifier;
});

class ExtraMySelectCountNotifier extends StateNotifier<int> {
  ExtraMySelectCountNotifier() : super(0);

  static final _db = FirebaseFirestore.instance;

  Future<DocumentReference<Map<String, dynamic>>> _ref() async {
    final deviceId = await DeviceService.getDeviceId();
    return _db.collection('users').doc(deviceId).collection('settings').doc('extra_my_select');
  }

  Future<void> load() async {
    try {
      final ref = await _ref();
      final doc = await ref.get();
      if (doc.exists && doc.data()?['count'] != null) {
        state = doc.data()!['count'] as int;
      }
    } catch (e) {
      debugPrint('ExtraMySelect load error: $e');
    }
  }

  Future<void> addSlot() async {
    state = state + 1;
    try {
      final ref = await _ref();
      await ref.set({'count': state});
    } catch (e) {
      debugPrint('ExtraMySelect save error: $e');
    }
  }
}

// 追加My Selectのテーマ管理（スロットごと）
final extraMySelectThemesProvider = StateNotifierProvider.family<ExtraMySelectThemesNotifier, List<MySelectTheme>, int>((ref, slotIndex) {
  final notifier = ExtraMySelectThemesNotifier(slotIndex);
  notifier.load();
  return notifier;
});

class ExtraMySelectThemesNotifier extends StateNotifier<List<MySelectTheme>> {
  final int slotIndex;

  ExtraMySelectThemesNotifier(this.slotIndex)
      : super(List.generate(25, (i) => MySelectTheme(index: i, name: '自由枠${i + 1}')));

  static final _db = FirebaseFirestore.instance;

  Future<DocumentReference<Map<String, dynamic>>> _ref() async {
    final deviceId = await DeviceService.getDeviceId();
    return _db.collection('users').doc(deviceId).collection('settings').doc('extra_my_select_themes_$slotIndex');
  }

  Future<void> load() async {
    try {
      final ref = await _ref();
      final doc = await ref.get();
      if (doc.exists && doc.data()?['themes'] != null) {
        final list = (doc.data()!['themes'] as List)
            .map((e) => MySelectTheme.fromMap(e as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (e) {
      debugPrint('ExtraMySelectThemes load error: $e');
    }
  }

  Future<void> updateTheme(int index, String name) async {
    final newList = [...state];
    newList[index] = MySelectTheme(index: index, name: name);
    state = newList;
    try {
      final ref = await _ref();
      await ref.set({'themes': state.map((t) => t.toMap()).toList()});
    } catch (e) {
      debugPrint('ExtraMySelectThemes save error: $e');
    }
  }
}

// 指定スロットのMy SelectテーマをThemeDefinitionとして取得
final extraMySelectThemeDefinitionsProvider = Provider.family<List<ThemeDefinition>, int>((ref, slotIndex) {
  final themes = ref.watch(extraMySelectThemesProvider(slotIndex));
  return themes.map((t) => ThemeDefinition.extraMySelect(slotIndex, t.index, t.name)).toList();
});
