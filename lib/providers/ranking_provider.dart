import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/themes.dart';
import '../constants/advance_themes.dart';
import '../models/tile_data.dart';
import 'tiles_provider.dart';
import 'my_select_provider.dart';
import '../services/device_service.dart';

// シートごとのランキングProvider
final rankingProvider = StateNotifierProvider.family<RankingNotifier, List<String>, String>((ref, sheetId) {
  List<String> defaultIds;
  switch (sheetId) {
    case 'advance':
      defaultIds = kAdvanceThemes.map((t) => t.id).toList();
      break;
    case 'my_select':
      final mySelectThemes = ref.watch(mySelectThemeDefinitionsProvider);
      defaultIds = mySelectThemes.map((t) => t.id).toList();
      break;
    default:
      defaultIds = kThemes.map((t) => t.id).toList();
  }
  final notifier = RankingNotifier(sheetId, defaultIds);
  notifier.loadRanking();
  return notifier;
});

class RankingNotifier extends StateNotifier<List<String>> {
  final String sheetId;
  final List<String> defaultIds;

  RankingNotifier(this.sheetId, this.defaultIds) : super(defaultIds);

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DocumentReference<Map<String, dynamic>>> _rankingRef() async {
    final deviceId = await DeviceService.getDeviceId();
    return _db
        .collection('users')
        .doc(deviceId)
        .collection('settings')
        .doc('ranking_$sheetId');
  }

  Future<void> loadRanking() async {
    try {
      final ref = await _rankingRef();
      final doc = await ref.get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['order'] is List) {
          final savedOrder = List<String>.from(data['order']);
          final missing = defaultIds.where((id) => !savedOrder.contains(id)).toList();
          state = [...savedOrder.where((id) => defaultIds.contains(id)), ...missing];
        }
      }
    } catch (e) {
      // オフライン時はデフォルト順
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...state];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    await _save();
  }

  Future<void> _save() async {
    try {
      final ref = await _rankingRef();
      await ref.set({'order': state});
    } catch (e) {
      // 保存失敗は無視
    }
  }
}
