// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBIrVFFruH43mFBaYzz7KPWD04JRhBG6B0",
    authDomain: "synnex-17430.firebaseapp.com",
    projectId: "synnex-17430",
    storageBucket: "synnex-17430.firebasestorage.app",
    messagingSenderId: "837907556855",
    appId: "1:837907556855:web:8d6caf54a108c8303366f2",
    measurementId: "G-MPHXWXG686",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBIrVFFruH43mFBaYzz7KPWD04JRhBG6B0",
    appId: "1:837907556855:android:8d6caf54a108c8303366f2",
    messagingSenderId: "837907556855",
    projectId: "synnex-17430",
    storageBucket: "synnex-17430.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBIrVFFruH43mFBaYzz7KPWD04JRhBG6B0",
    appId: "1:837907556855:ios:8d6caf54a108c8303366f2",
    messagingSenderId: "837907556855",
    projectId: "synnex-17430",
    storageBucket: "synnex-17430.firebasestorage.app",
    iosBundleId: "com.example.teacherApp",
  );

  static const FirebaseOptions macos = ios;
}
