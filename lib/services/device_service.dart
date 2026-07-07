import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceService {
  static String? _deviceId;

  static Future<String> getDeviceId() async {
    // Appleログイン済みの場合はFirebase UIDを使用
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return firebaseUser.uid;
    }

    // 未ログインの場合はデバイスIDを使用
    if (_deviceId != null) return _deviceId!;

    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _deviceId = iosInfo.identifierForVendor ?? 'unknown_device';
    } else {
      _deviceId = 'unknown_device';
    }
    return _deviceId!;
  }

  // デバイスID（ローカル）を取得（移行処理用）
  static Future<String> getLocalDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_device';
    }
    return 'unknown_device';
  }
}
