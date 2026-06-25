import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you need to reconfigure this following the FlutterFire CLI documentation.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB7m_72TN9Q3sablRAJcxfDhlFH2FJP5kk',
    appId: '1:632515537410:ios:90fce84cc0edaf0d96151b',
    messagingSenderId: '632515537410',
    projectId: 'my-best-diveshot',
    storageBucket: 'my-best-diveshot.firebasestorage.app',
    iosBundleId: 'com.hikaru.mybestdiveshot',
  );
}
