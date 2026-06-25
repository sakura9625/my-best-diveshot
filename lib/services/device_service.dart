import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static String? _deviceId;

  static Future<String> getDeviceId() async {
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
}
