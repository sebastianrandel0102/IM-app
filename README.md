# bear with me

**A little world, just for us.** Android-first Flutter app for two people to send
affection through the caramel and white bears from the supplied references.

## Run

```powershell
flutter pub get
flutter run
# Or on this computer:
flutter run -d web-server --web-port 5173 --web-hostname 127.0.0.1
```

Real Android, iOS and web client options are generated for `bear-with-me-f60a3`.
Billing is disabled. The default Firestore database is Standard edition in
`asia-southeast1`. Email/password Firebase Auth is enabled, and the two actual
account UIDs are configured in the client and deployed rules. Create an
invitation in the app and confirm it separately on both accounts to pair.
For a future account replacement, the membership setup command is:

```powershell
.\.tools\node.exe scripts\configure-membership.mjs FIRST_UID SECOND_UID
.\scripts\firebase.ps1 deploy --only firestore --project bear-with-me-f60a3
flutter run
```

With system Node, use `node` instead of `.\.tools\node.exe`. A fresh clone needs
Node 22+ and `npm ci` for the development CLI/tests. The Flutter app never uses
Node, a service account, or privileged credentials. See [Firebase setup](docs/setup/firebase.md).

## Implemented

- Registration, login, password reset/change, persistent Auth and logout.
- Fixed two-account membership, 256-bit invitations, separate confirmations.
- Shared illustrated world, complementary bears, local themes and accessories.
- Searchable 24-gesture catalog, optional notes and account-scoped local drafts.
- Atomic real delivery with stable request IDs and no automatic offline queue.
- Real-time sealed inbox, outgoing history, explicit server-authorized reveal.
- Interactive hold/release, tap and bounded swipe, accessible alternatives,
  replay, optional original sound, haptics and reduced motion.
- Personal memory books, favorites, removal and bounded history pagination.
- Optional accepted live room with sequenced logical actions.
- Friendly network/quota errors and documented account deletion/retention.
- Clearly labeled local preview that never simulates messages from a partner.

**Animation status:** all 24 gestures have dedicated editable Flutter vector
choreography, bounded contact rigs, recipient reactions, secondary motion,
reduced motion and playback-driven completion. See the [per-gesture implementation
record](docs/animations/OVERHAUL.md) and [QA results](docs/animations/QA.md).
Run `flutter run -t tool/animation_review.dart -d chrome` for slow playback and
frame scrubbing without Firebase. External Rive rigs remain an authoring
deliverable; no `.riv` files or mesh-weight edits are claimed. The opt-in adapter
and [authoring specification](docs/animations/AUTHORING.md) remain available.
App Check remains opt-in until attestation is configured.

## Checks

```powershell
flutter analyze
flutter test
npm run test:rules
npm run test:integration
```

On this Windows machine, `.\scripts\test-backend.ps1` runs both backend suites
using the portable Node and Android Studio JDK without a global npm install.

The Flutter suite checks mobile/desktop layouts, private routes, hug controls,
invitation entropy and preferences, and exports visual previews to `artifacts/`.
34 Firestore rules tests exercise allowed and denied operations. A separate
two-client integration checks real emulator Auth registration, pairing, live
delivery in both directions, sealed reads, reveal and memory persistence.
Emulator tests use `demo-bear-with-me`, never live project data. Physical
two-device testing is still required: [acceptance checklist](docs/testing/TWO_DEVICE.md).

## Android

```powershell
# Only once, if no signing files exist:
.\scripts\create-release-key.ps1
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Release builds use a
dedicated upload key and refuse to silently use a debug key. Back up
`android/keystores/bear-with-me-upload.jks` and `android/key.properties` securely;
both are ignored by Git. See [installation and signing](docs/setup/android.md).

## Source

`lib/app` contains configuration, routing and theme; `lib/core` contains shared
providers/widgets/errors. `lib/features` separates authentication, pairing,
home, affection, inbox, animation, memories, together and settings into data,
domain and presentation concerns. `firebase` contains rules, indexes and
security/integration tests. `assets` bundles the font, original audio and Rive
handoff marker. `scripts`, `test`, `tool` and `docs` contain setup, checks,
vector icon export and handoff documentation.

No Cloud Functions, Firebase Storage, paid backend or automatic FCM sender is
included. Notes are ordinary private Firestore text, accessible to authorized
accounts and project administrators, not end-to-end encrypted. Reveal does not
prove a physical tap. Revocation denies old world access to clients; the project
owner separately cleans retained server data. See [architecture and privacy](docs/architecture/README.md).
