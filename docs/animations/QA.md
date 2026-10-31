# Animation verification — 2026-10-31 (Asia/Manila)

Historical verification of the previous overhaul. See [REFINEMENT_QA.md](REFINEMENT_QA.md)
for the subsequent character refinement; the APK hash and 56-test count below
refer to the earlier build.

## Results

| Check | Result |
| --- | --- |
| Dart/Flutter static analysis | Passed, no issues |
| Complete Flutter suite | 56 tests passed |
| Catalog preservation | Existing 24 IDs/names/categories retained; existing catalog/rules authorization test passed |
| Full timeline sampling | All 24 actions sampled at 120 Hz in normal and reduced motion; finite anchors, continuity, bounded torso deformation and arm reach passed |
| Contact accuracy | Actual hand/high-five endpoints, kiss nose/cheek/forehead, head-pat and boop targets passed |
| Color roles and layout | All 24 render at 240×220 in both sender color roles; existing 360/430/1200-width layouts passed |
| Stage bounds | Representative head/ear extent points checked across all actions, the complete shared turn and both extreme walk offsets; passed |
| Variants | All 24 actions accept reactions and complete in gentle, shy and playful variants |
| Hold/release | Warm hug, comfort hug and cuddle remain active, continue breathing, then complete once after release |
| Physical controls | Long press, pointer cancellation, accessible hold/release, tap debounce, replay, Stop, wake swipe and bounded walk buttons passed |
| Lifecycle | Background and disabled TickerMode preserve elapsed action time; resume completes once; disposal leaves no scheduled scene tickers |
| Reduced-motion completion | Restrained playback completes and stops requesting frames after settling |
| Post-completion wake | Completed sleeping scene still blends to neutral and finishes recovery |
| Reused static thumbnails | Changing a gesture in a reused reduced-motion thumbnail shows the new pose without starting a ticker |
| Touch responses | Catch, persistent flower bloom, earlier tear wipe, extra closeness and non-reclosing gift lid passed |
| Visual artifacts | Original and refined category sheets exported; six timeline samples per gesture in both roles inspected |
| Android release build | Passed; `build/app/outputs/flutter-apk/app-release.apk` |
| APK package inspection | Passed all seven existing checks, including correct Firebase project/member configuration, bundled font/audio and no service-account file |
| APK signature | `apksigner verify --verbose` passed; APK Signature Scheme v2, one signer |

## Visual review artifacts

`artifacts/animations/original/` and `artifacts/animations/refined/` each contain
10 PNG contact sheets: Everyday, Playful, Cozy, Comfort and Surprises, each with
brown and white senders. Together they show 288 poses per implementation
(24 × 6 × 2). The original renderer source is retained as
`artifacts/animations/original-renderer.dart.txt`.

During review, the original head overlap, missing paw targets, repeated shared
kiss/high-five choreography, fixed piggyback attachment and binary prop changes
were replaced. Subsequent checks caught a resting forehead-contact offset,
idle arms drawing over faces, an offscreen rider, clipping at the leftmost
ride position, completed-scene wake handling and stale reused thumbnails.
Those issues were corrected and covered by the final checks.

The [per-gesture record](OVERHAUL.md) states each action's poses, curves,
corrections, controls, timing, emotional intent, modified source and limits.

## Reproduce

```powershell
flutter analyze
flutter test
flutter test test/animation_visual_test.dart
flutter run -t tool/animation_review.dart -d chrome
flutter build apk --release
py scripts/verify-apk.py
```

The local review entry point provides full/quarter-speed playback, scrubbing,
both sender colors, hold/release, tap, walking and reduced-motion controls
without Firebase initialization. Automated sampling is not a substitute for
watching every rendered frame on the target Android hardware.

## Remaining external work and limits

- No editable Rive, Spine or Live2D files were supplied. No external bone
  hierarchy, vertex weights or animation binary was modified. The Dart vector
  rig is the delivered editable implementation; Rive remains a separate
  [authoring deliverable](AUTHORING.md).
- No Android device was connected. Physical touch/haptic acceptance and GPU
  frame timing near 60 FPS remain unmeasured. The 120-Hz test samples validate
  poses and continuity, not device rendering throughput.
- Actual live two-device delivery, iOS builds, App Check and notifications
  were not retested in this animation pass. Their code/configuration was not
  changed. Backend emulator results from 2026-10-30 remain historical results.
- Frame sheets sample six poses per action/role. They do not certify a manual
  frame-by-frame inspection of every possible input combination.
- Existing Android plugins emit a future Kotlin Gradle Plugin migration
  warning; the current signed release build succeeds without dependency changes.

No real account message was sent and no Firebase deployment was performed.

Final APK: 85,278,539 bytes. SHA-256:
`ad78daf79e7a0dc7a6389a715f6bd05d043b03693d050a2878e6df040ca98714`.
Machine-readable package verification is in `artifacts/apk-verification.json`.
