# Connect bear-with-me-f60a3 on Spark

The project ID is configured in `.firebaserc`. Live client credentials must be
retrieved from the project; an API key or app ID cannot be inferred from its ID.
No privileged key should be pasted into this repository or the chat.

## 1. Sign in and register the clients

From this project in PowerShell, after the development dependencies install:

```powershell
.\scripts\firebase.ps1 login
.\.tools\node.exe scripts\configure-firebase.mjs
```

With a system Node installation, use `node` instead of `.\.tools\node.exe`.
If needed, install development tools first with `npm ci` (`npm install` before
the initial lockfile is available). The helper uses the ordinary Firebase CLI
session. It reuses registered apps with matching identifiers or creates them:

- Android: `com.bearwithme.bear_with_me`
- iOS: `com.bearwithme.bearWithMe`
- Web: display name `Bear With Me Web`

It downloads genuine client configuration into `lib/firebase_options.dart`,
`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` and
platform-specific JSON define files under `config/`. No service accounts,
Cloud Functions, Storage bucket, billing attachment or paid hosting is created.
App Check configuration is a separate, opt-in step after basic pairing works.

## 2. Configure no-cost services in the Firebase Console

Open https://console.firebase.google.com/project/bear-with-me-f60a3/overview
and verify the plan is **Spark** and no billing account is attached. Do not
accept an upgrade prompt.

Enable Authentication → Email/Password. Do not enable SMS or phone auth.
Create the default Firestore database using **Standard edition** and production
rules in a suitable region. Keep its ID `(default)`. The app and tests do not
require TTL policies, backups, PITR, clones or restores.

Deploy the closed bootstrap rules and indexes:

```powershell
.\scripts\firebase.ps1 deploy --only firestore --project bear-with-me-f60a3
```

With membership placeholders still present, only authenticated users' own
profiles can be initialized or edited. Private pair/world data remains closed.
These rules do not make a public dating or discovery service.

## 3. Create the two accounts and configure membership

Run the configured app on both devices using `flutter run`. Register separate
email/password accounts. Both devices show their Firebase UID on the pairing
screen. The owner can alternatively find them in Authentication → Users.

Do not invent UIDs. Use the actual two account identifiers:

```powershell
.\.tools\node.exe scripts\configure-membership.mjs ACTUAL_FIRST_UID ACTUAL_SECOND_UID
.\scripts\firebase.ps1 deploy --only firestore --project bear-with-me-f60a3
flutter run
```

Rebuild/reinstall both apps so the membership UI addresses the right account.
The helper updates both rules and client addressing hints. A client-only UID
change never bypasses the deployed allowlist. The rules test runner substitutes
only emulator member IDs, even after the production UIDs have been configured.

The creator selects a bear and generates a private invitation. Share the entire
43-character token directly with the other person. The recipient pastes it,
accepts, then **each account confirms on its own device**. Their characters are
complementary. Do not put the token in a public issue or analytics service.

## 4. App Check (optional until configured)

Register the Android app in Firebase App Check with Play Integrity, add the
correct signing certificate SHA-256 fingerprint, and validate real-device
attestation. For debugging, register a debug token using the documented debug
provider. iOS uses App Attest; web requires a configured reCAPTCHA key.

Run with `--dart-define=ENABLE_APP_CHECK=true` only after provider configuration.
Do not enforce App Check server-side until your actual app has been tested with
valid attestation. App Check supplements Auth and rules; it does not replace
membership or reveal authorization. Debug credentials are not shipped in a
release binary. Rive native assets may require platform downloads at build time.

## 5. Emulator-only development

```powershell
.\scripts\firebase.ps1 emulators:start --only auth,firestore --project demo-bear-with-me
flutter run --dart-define-from-file=config/emulators.example.json
```

For Android emulator, host is `10.0.2.2`. For browser or same-machine tests use
`127.0.0.1`; physical devices need a reachable development host on the local
network. Never enable emulator settings in release; the app rejects that mode.
The example member UIDs are test identities, not automatically assigned to
manually registered emulator users. For manual pairing, create the two accounts
with those IDs through emulator REST testing or replace the emulator-only
allowlist with their real test UIDs. Production data is never used by tests.

## Account deletion and retention

The app reauthenticates the user, revokes any pairing, clears local drafts and
replay cache, deletes the user's profile, then deletes Firebase Auth identity.
Reauthentication happens before destructive writes. If a later network step
fails, retry after signing in; profile initialization is repairable.

Shared Firestore history remains in the project but becomes inaccessible to app
clients after revocation. Firebase Auth deletion does not delete subcollections.
The trusted project owner must remove the retained old world's nested
`moments`, `payloads`, `memories` and `liveSessions` documents in the Console,
then its world document and old invitation, when both partners no longer need
that data. Rules intentionally do not grant clients broad history purge rights.
Deleting a parent document alone does not delete Firestore subcollections.
Do not enable the paid Delete User Data extension for this Spark-only app.

## Troubleshooting

- Permission denied: verify the exact UIDs in deployed rules and the app build;
  verify both confirmations and current pairing status.
- Missing index: deploy `firebase/firestore.indexes.json` and wait until ready.
- Reveal offline: reconnect and explicitly retry Open Surprise. Unopened
  payloads cannot be unlocked from cached metadata.
- Quota exceeded: wait for the quota reset; do not upgrade automatically.
- Wrong password: use the recovery page. Never save or send a plaintext password.
- Missing animation: development Flutter animation works without a .riv file;
  authored Rive integration requires the external asset contract.

Official references verified 2026-10-30:
https://firebase.google.com/docs/flutter/setup,
https://firebase.google.com/docs/firestore/quotas,
https://firebase.google.com/docs/rules/rules-and-auth,
https://firebase.google.com/docs/app-check/flutter/default-providers.
