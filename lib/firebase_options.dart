// Generated from Firebase Management API client configuration. No service credentials.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class DefaultFirebaseOptions {
  static const configured = true;
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS || TargetPlatform.macOS => ios,
      _ => throw UnsupportedError('Use Android, iOS or web.'),
    };
  }

  static const android = FirebaseOptions(
    apiKey: "AIzaSyCn_IUb2jLm3ES-lkuIGiwo2WDPFM6ZUuc",
    appId: "1:208434515122:android:82f3707ce28ea398198dab",
    messagingSenderId: "208434515122",
    projectId: "bear-with-me-f60a3",
  );
  static const ios = FirebaseOptions(
    apiKey: "AIzaSyAeqzhHAI_PCNv0Jfleb40CpwSe2WaMZCE",
    appId: "1:208434515122:ios:043439d68fd7ac74198dab",
    messagingSenderId: "208434515122",
    projectId: "bear-with-me-f60a3",
    iosBundleId: "com.bearwithme.bearWithMe",
  );
  static const web = FirebaseOptions(
    apiKey: "AIzaSyCL4b_184KI7cNuPP7p0XOx1-VBEv1hzKk",
    appId: "1:208434515122:web:f27e69b9b5143bd8198dab",
    messagingSenderId: "208434515122",
    projectId: "bear-with-me-f60a3",
    authDomain: "bear-with-me-f60a3.firebaseapp.com",
  );
}
