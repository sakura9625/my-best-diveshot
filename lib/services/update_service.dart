import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// アップデート確認の結果
class UpdateCheckResult {
  final bool updateAvailable;
  final String? appStoreUrl;

  const UpdateCheckResult({required this.updateAvailable, this.appStoreUrl});

  static const none = UpdateCheckResult(updateAvailable: false);
}

/// Firestore の config/appVersion を見て、アップデートが必要か判定する
class UpdateService {
  static Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('appVersion')
          .get();
      final data = doc.data();
      if (data == null) return UpdateCheckResult.none;

      final minVersion = data['minVersion'];
      final appStoreUrl = data['appStoreUrl'];
      if (minVersion is! int ||
          appStoreUrl is! String ||
          appStoreUrl.isEmpty) {
        return UpdateCheckResult.none;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final buildNumber = int.tryParse(packageInfo.buildNumber);
      if (buildNumber == null) return UpdateCheckResult.none;

      if (buildNumber < minVersion) {
        return UpdateCheckResult(
          updateAvailable: true,
          appStoreUrl: appStoreUrl,
        );
      }
      return UpdateCheckResult.none;
    } catch (e) {
      // 通信エラーなどはアップデートなしとして扱い、アプリの動作を妨げない
      debugPrint('UpdateService.checkForUpdate failed: $e');
      return UpdateCheckResult.none;
    }
  }
}
