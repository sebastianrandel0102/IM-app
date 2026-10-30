# Android build, signing and installation

Developed with Flutter 3.47.7 / Dart 3.13.5, Android SDK 36+ and Android Studio's
JBR. iOS compilation requires macOS/Xcode and has not been verified on Windows.

Complete `firebase.md`: real client options, Email/Password Auth, the default
Standard database, deployed rules/indexes and actual two-account UIDs. Use a
bootstrap configured build to register accounts if needed, then configure
membership and rebuild. Private pairing is intentionally denied before this.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Install by opening the
APK on each device, or use the Android SDK's `adb install -r`. Both phones need
different accounts. Run the two-device checklist in `docs/testing/TWO_DEVICE.md`.

## Signing

`scripts/create-release-key.ps1` creates a dedicated 3072-bit RSA PKCS12 upload
key and random password. It never overwrites existing signing files. Passwords
are passed to keytool through a temporary process environment variable and
saved only in ignored `android/key.properties`; they are not printed.

Back up `android/keystores/bear-with-me-upload.jks` and `android/key.properties`
securely. Future updates must use the same signing identity. For Google Play,
enroll separately in Play App Signing and run `flutter build appbundle --release`.
No Play registration, payment or publication is performed here.

If you already have a key, configure its alias/password/path in the ignored
properties file rather than generating another. Store paths resolve relative
to `android`. Do not paste signing passwords into chat or commit them.

The generated upload certificate's SHA-256 fingerprint (public, for App Check
registration) is:

```
4F:EB:7A:B9:8B:01:34:A8:8A:66:F8:DC:1D:9D:44:BA:FA:D1:70:3F:33:D2:5C:A6:20:91:A7:A1:47:7D:B4:64
```

## Windows notes

The project is on D: and pub cache on C:. Kotlin relocatable incremental caches
can fail across drive roots. This project disables Kotlin incremental caching
and compiles in-process. Gradle uses two workers and a 3 GiB heap.

For this private sideloaded APK, Java/resource shrinking is disabled by default
to avoid the long R8 optimization pass on this machine. Flutter still performs
release AOT compilation and Dart/icon tree shaking. The APK is larger. To opt
into shrinking on a suitable build machine, set the process environment variable
`ORG_GRADLE_PROJECT_enableReleaseShrinking=true` before building.

Current Firebase/Rive plugins may emit Flutter's future Built-in Kotlin migration
warning; their legacy plugin integration is permitted by this Flutter version.
Revalidate compatibility when upgrading. Native client options are explicitly
passed from `lib/firebase_options.dart`; no service account is embedded.

Check TalkBack, large text, gesture alternatives, reduced motion, sound and
haptics on physical devices. Register the release signing certificate with
Firebase App Check before enforcing it. Never ship emulator hosts or App Check
debug credentials in a production binary.
