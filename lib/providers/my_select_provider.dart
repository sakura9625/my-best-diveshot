import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/my_select_theme.dart';
import '../services/device_service.dart';
import '../constants/themes.dart';

// デフォルトのMy Selectテーマ（25個）
List<MySelectTheme> get kDefaultMySelectThemes => List.generate(
  25,
  (i) => MySelectTheme(index: i, name: '自由枠${i + 1}'),
);

final mySelectThemesProvider = StateNotifierProvider<MySelectThemesNotifier, List<MySelectTheme>>((ref) {
  final notifier = MySelectThemesNotifier();
  notifier.load();
  return notifier;
});

class MySelectThemesNotifier extends StateNotifier<List<MySelectTheme>> {
  MySelectThemesNotifier() : super(kDefaultMySelectThemes);

  static final _db = FirebaseFirestore.instance;

  Future<DocumentReference<Map<String, dynamic>>> _ref() async {
    final deviceId = await DeviceService.getDeviceId();
    return _db.collection('users').doc(deviceId).collection('settings').doc('my_select_themes');
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
      debugPrint('MySelect load error: $e');
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
      debugPrint('MySelect save error: $e');
    }
  }
}

ThemeDefinition toThemeDefinition(MySelectTheme t) {
  return ThemeDefinition.mySelect(t.index, t.name);
}

final mySelectThemeDefinitionsProvider = Provider<List<ThemeDefinition>>((ref) {
  final mySelectThemes = ref.watch(mySelectThemesProvider);
  return mySelectThemes.map((t) => toThemeDefinition(t)).toList();
});
