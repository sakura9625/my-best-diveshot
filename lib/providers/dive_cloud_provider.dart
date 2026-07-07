import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'purchased_sheets_provider.dart';

// DiveCloudが有効かどうか
final diveCloudActiveProvider = Provider<bool>((ref) {
  final diveCloud = ref.watch(diveCloudProvider);
  return diveCloud.isActive;
});
