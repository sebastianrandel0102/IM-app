import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';
import 'private_membership.dart';

final bootstrapProvider = Provider<Bootstrap>(
  (ref) => const Bootstrap(ready: false),
);

class AppConfig {
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const memberA = String.fromEnvironment(
    'MEMBER_A_UID',
    defaultValue: privateMemberA,
  );
  static const memberB = String.fromEnvironment(
    'MEMBER_B_UID',
    defaultValue: privateMemberB,
  );
  static const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static const emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );
  static const enableAppCheck = bool.fromEnvironment('ENABLE_APP_CHECK');
  static const recaptchaKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');
  static bool get configured =>
      projectId.isNotEmpty &&
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      senderId.isNotEmpty;
  static bool get membershipConfigured =>
      memberA.isNotEmpty && memberB.isNotEmpty && memberA != memberB;
  static String? partnerOf(String uid) => uid == memberA
      ? memberB
      : uid == memberB
      ? memberA
      : null;
}

class Bootstrap {
  const Bootstrap({required this.ready, this.error});
  final bool ready;
  final String? error;
  static Future<Bootstrap> initialize() async {
    if (!AppConfig.configured && !DefaultFirebaseOptions.configured) {
      return const Bootstrap(ready: false);
    }
    try {
      await Firebase.initializeApp(
        options: AppConfig.configured
            ? const FirebaseOptions(
                apiKey: AppConfig.apiKey,
                appId: AppConfig.appId,
                messagingSenderId: AppConfig.senderId,
                projectId: AppConfig.projectId,
                authDomain: AppConfig.authDomain,
                iosBundleId: 'com.bearwithme.bearWithMe',
              )
            : DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      if (AppConfig.useEmulators) {
        if (kReleaseMode) {
          throw StateError('Emulators are disabled in release builds.');
        }
        await FirebaseAuth.instance.useAuthEmulator(
          AppConfig.emulatorHost,
          9099,
        );
        FirebaseFirestore.instance.useFirestoreEmulator(
          AppConfig.emulatorHost,
          8080,
        );
      } else if (AppConfig.enableAppCheck) {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestProvider(),
          providerWeb: AppConfig.recaptchaKey.isEmpty
              ? null
              : ReCaptchaV3Provider(AppConfig.recaptchaKey),
        );
      }
      return const Bootstrap(ready: true);
    } catch (_) {
      return const Bootstrap(
        ready: false,
        error: 'Our world could not connect. Check the Firebase configuration and restart.',
      );
    }
  }
}
