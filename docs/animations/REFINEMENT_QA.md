# Character refinement verification — 2026-10-31, Asia/Manila

This is the current refinement record. The [previous QA report](QA.md) describes
an earlier build and its historical APK hash. The [implementation audit](REFINEMENT.md)
lists each of the 24 gestures, baseline problems, changes, controls, modified
files, dependencies and remaining limits.

## Checks

| Check | Observed result |
| --- | --- |
| Baseline checkpoint | Clean commit `768741d`; `.tools/animation-before-20261031.zip` created before editing |
| Baseline Flutter suite | 56 tests passed |
| `flutter pub get` | Passed; no dependency changes; existing incompatible newer-version notices only |
| `dart format .` | Completed; 44 Dart files formatted/checked; unrelated source was not changed |
| `flutter analyze` | Passed, no issues |
| Final Flutter suite | **67 tests passed**, including accepted reactions in all variants and supported holds |
| All 24 timelines | Existing 120-Hz normal/reduced-motion finite-position, continuity, reach and deformation-bound checks pass |
| All 24 cancellations | New test checks continuous interruption, one cancellation edge, no further accepted input and one recovery completion |
| Contact events | New test checks each gesture's authored contact threshold and one event per run |
| Foundation motion | New tests check variable/double/nonsynchronous blinks, continuous closure, planted stance/swing arcs and distance-driven gait phase |
| Input readiness | Early return kisses are consumed; first action/reaction cannot be replaced; high-five impact recovery is locked; walking waits for attachment |
| Player interaction | Actual buttons, physical long press/cancel, frame-clock debounce, background hold release, Stop, wake swipe and bounded walk controls pass |
| Role reversal | Existing forward complementary-role tests retained; forehead kiss now also swaps acting roles |
| Layout and lifecycle | Small scenes in both color roles, app mobile/desktop layouts, reduced-motion settling, background/TickerMode suspension and ticker cleanup pass |
| Visual export/review | All 10 polished category/color sheets inspected; 288 sampled poses, plus both master SVG rasters |
| SVG masters | Both parsed as well-formed XML, 1024×1024 viewBox, rendered with resvg and inspected |
| Browser profile | Final-source run completed all **48 scenes**, with 26,099 timing samples; total-span p95 **7.700 ms** |
| Android release build | Final-source Gradle build succeeded; package/signature checks recorded below; earlier stopped attempt is not the delivered build |
| Backend preservation | No Auth/pairing/reveal/delivery/history/memory/settings repository, Firebase configuration, rule, schema or dependency changes |

The all-variant test explicitly waits for each action's readiness window,
asserts the reaction was accepted, or exercises a supported hold/release, then
verifies completion. It does not pass by silently rejecting every early input.
The retargeting test also now taps after the initial reaction, rather than
asserting continuity of a rejected input. The rapid-tap regression exposed a
real stale-readiness race under a slower test run; readiness is consumed in the
same input event and debounce uses Flutter's monotonic frame timestamp.

## Visual findings and corrections

The baseline had a hard eye-art switch near 25% closure, center-based head/ear
rotation, a canvas-wide somersault for spinning hug, and a goodnight recipient
that reopened its eyes. The new artwork blends eye glyphs and local mouths;
neck and ear-base transforms are shared with target positions. The spinning hug
uses an upright projected orbit and foreground changes. Goodnight keeps the
recipient asleep. A subsequent raster review found the deeper sleeping pose
hid both faces behind the blanket; local neck offsets corrected that while
preserving joined paw targets and stage bounds.

`artifacts/animations/refined/` preserves the baseline for this pass.
`artifacts/animations/polished/` contains the new six-pose sheets (.04, .22, .40,
.54, .72 and .96), each category with brown and white senders. The masters and
1024-pixel transparent raster previews are in `artifacts/animations/masters/`.
These sampled sheets do not certify manual inspection of every rendered frame
or every possible touch combination.

## Profiling method and interpretation

`tool/animation_profile.dart` runs the real scene widget through all 24 gestures
in both sender colors in profile mode. It does not initialize Firebase. Its
`FrameTiming` listener records engine build duration, raster duration and total
span, then displays and prints a JSON result. The final JSON and screenshot are
saved as `artifacts/animations/profile-web.json` and `profile-web.png`.

The final browser run completed all 48 scenes in **359.799 seconds**, with
**26,099 timing samples**: build p95 **3.401 ms**, raster p95 **3.800 ms** and
total-span p95 **7.700 ms**. **220** total spans exceeded 16.667 ms (about 0.84%).
An earlier refinement run measured 13.500 ms total-span p95; these runs were
not a controlled before/after benchmark and had different concurrent build/test
load. Use the final-source JSON as the recorded observation, not as evidence
of a quantified performance improvement over the baseline.

Total span is latency, not a direct dropped-frame count. Build and raster can
overlap through pipelining. Interpretation follows the [Flutter frame timing
API](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addTimingsCallback.html).
This headless Chrome measurement on the development computer does not establish
ordinary Android device GPU performance, touch latency, battery use or a
certified 60-FPS result. [Flutter's performance guidance](https://docs.flutter.dev/perf/ui-performance)
calls for profiling on a physical device; its web profile mode uses Chrome
DevTools rather than native Dart DevTools. No Android/iOS device was connected.

## Reproduce

```powershell
flutter pub get
dart format .
flutter analyze
flutter test --dart-define=ANIMATION_PASS=polished
flutter run -t tool/animation_review.dart -d chrome
flutter run --profile -t tool/animation_profile.dart -d chrome
flutter build apk --release
py scripts/verify-apk.py
```

The review tool supports gentle/shy/playful variants, both sender colors,
quarter-speed playback, one-frame advancement, scrubbing, readiness-aware tap,
hold/release, walking, reduced motion and recent event edges. All workbench and
profile controls are local-only tooling; no technical controls were added to
the couple's normal app flow.

## Verified Android artifact

`build/app/outputs/flutter-apk/app-release.apk` was built successfully from the
final runtime source using `flutter build apk --release --no-pub -v`.
Size: **85,294,923 bytes**. SHA-256:

`86ea5c56f39b1fa28d60876e722aece99fde5c6a46354a7c38f5fcd102beebf9`

`py scripts/verify-apk.py` passed all seven existing package checks (release
ARM64 code, both configured member UIDs, correct Firebase project, no emulator
project, bundled font and original audio, and no service-account file).
`apksigner verify --verbose` passed: APK Signature Scheme v2, one signer.
Machine-readable results are in `artifacts/apk-verification.json`.
This verifies building and packaging, not installation or device performance.

## Pending acceptance and external assets

- Original reference images were unavailable. The SVGs derive from the current
  app artwork; no faithful image trace/reference comparison is claimed.
- No editable Rive/Spine/Live2D source, binary export, mesh weights or paid
  authoring account was available. No subscription/export purchase was made.
  [ARTWORK.md](ARTWORK.md) gives exact reconstruction/pivot/export steps, and
  [AUTHORING.md](AUTHORING.md) retains the optional Rive contract.
- Horizontal sleep replacement drawings and fully authored rear/side turn and
  piggyback views remain external. Current sleep is reclined; the orbit is a
  stylized 2D projection. Procedural curves and rigid layers are not mesh skinning.
- Physical Android touch/haptics, slow-device and 60-Hz acceptance, listening to
  sound on hardware, and native GPU profiling remain pending.
- Live two-device Firebase delivery, iOS builds and backend emulator suites were
  not rerun in this animation-only pass. Their implementation was not changed.
- Existing Android plugin KGP/native-access and web PWA deprecation notices are
  toolchain warnings; no unrelated plugin upgrades were made to suppress them.

No real account message was sent, no Firestore deployment occurred, and no
backend/service subscription was added. Firebase Spark architecture is preserved.
