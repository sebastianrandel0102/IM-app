# Shared contact rig QA — 2026-10-31 (Asia/Manila)

This report applies to the implementation in [CONTACT_RIG.md](CONTACT_RIG.md),
based on `c596feb`. Historical refinement build hashes and timing numbers in
other reports do not describe this change.

## Automated checks

| Check | Result |
| --- | --- |
| Baseline working tree/checkpoint | Clean; tracked source archived before editing |
| Baseline Flutter suite | 67 tests passed |
| `flutter analyze --no-pub` | Passed, no issues |
| Final `flutter test --dart-define=ANIMATION_PASS=contact-rig --reporter expanded` | **78 tests passed** |
| All 24 gesture timelines | Existing 120-Hz continuity, scene bounds, finite anchors, bounded deformation and arm-reach checks pass in normal/reduced motion |
| Four hug/cuddle contact tracks | New tests sample 161 poses per track, per variant and motion setting: **3,864 paired poses**, checking front and rear requested endpoints against actual rendered paws |
| Sleep support/contact | Dedicated lying geometry, zero whole-character lie rotation, feet on the resting surface and joined rendered paws checked across 101 timeline samples |
| Distinct choreography | Comfort starts with a sad seated recipient; cuddle starts with both seated and rests the recipient's paw on the sender's chest; Warm Hug stays standing; spinning changes shared orbit |
| Anchors and reversal | Posed/mirrored shoulder/head/foot transforms, scene-space head corrections, both sender colors and existing return-affection role tests pass |
| Lifecycle/input | Existing long-press/cancel/replay, held breathing, one completion, Stop, wake, bounded walking, background/TickerMode and reduced-motion settling checks retained |
| New controls | Early control edges rejected; blanket and lamp stay independent, ease toward selected state, and reset on action change/replay; actual player chips exercised |
| Pose library | All 24 named presets produce finite character-relative anchors |
| `git diff --check` | Passed |

An initial run revealed that the old reach test measured from a fixed standing
shoulder; it now uses the same posed shoulder as drawing. A stronger new contact
test then caught real overreach during the middle of the spin. Projected
shoulder orientation, rear-target placement and gentle shared turn compression
corrected it. The existing sleep tap-to-move-closer behavior was retained after
its regression test caught its omission. These failures were fixed before the
final passing suite.

## Rendered output reviewed

All **16 new sheets** in `artifacts/animations/contact-rig/` were opened and
visually inspected:

- Ten category/color sheets: all 24 gestures × two sender roles × six samples,
  **288 rendered scene cells**.
- Four priority contact sheets: six gestures × five exact timeline samples ×
  two roles × two motion settings, **120 rendered scene cells**.
- Two orbit/control sheets: five middle-orbit samples and five independent
  scene-control examples × two roles, **20 rendered scene cells**.

The priority samples are `.43`, `.46`, `.64`, `.84` and `.94` (contact
preparation, first contact, hold and release/recovery). The spin sheets also
inspect `.55`, `.59`, `.64`, `.69` and `.73`, which the six-frame category
sheets previously missed. Those images show cross-torso wrapping, readable
faces, seated/bent feet, replacement horizontal sleeping bodies, pillow
support, distinct recipient chest-rest versus full-wrap paws, blanket coverage,
lamp dimming and color-role reversal.

Review led to a separate recipient paw-to-chest target for Cuddle Time so its
held pose differs from Comfort Hug. The final sheets were regenerated after
that correction. Existing head/face palettes remain recognizable. Diagnostic
overlays are available only in the standalone workbench; normal player UI has
affection controls and no engineering labels.

This is sampled visual review, not a claim that every rendered frame, every
input combination or a complete on-device video has been manually inspected.
Large original head proportions still make these stylized poses. Piggyback
side/rear views, fully drawn multi-view turns and more anatomical head/shoulder
contact would benefit from artist-authored corrective art. A passing target
constraint is evidence of alignment, not a general collision/occlusion proof.

## Local profile and Android build

The final-source Android release build passed in 201 seconds. Output:
`build/app/outputs/flutter-apk/app-release.apk`, **85,344,091 bytes**.
SHA-256: `6e3ce836aa0e58c403ba6d4c039912dc95cca2d06d9df2132a3ec9fd4dc0a9cd`.
`py scripts/verify-apk.py` passed all seven package checks; its machine-readable
record is `artifacts/apk-verification.json`. This verifies packaging and the
existing private membership/Firebase configuration without printing account
identifiers. No installation on a physical device is claimed.
`apksigner verify --verbose` also passed, with APK Signature Scheme v2 and one
signer.

The local harness uses the actual scene widget and engine `FrameTiming`, plays
all 24 gestures in both roles, and does not initialize Firebase. Headless Chrome
on this development computer is not physical Android GPU acceptance. Any
simultaneous local build/test load also affects these observational timings.

Final-source run in isolated headless Chrome completed **all 48 scenes** in
**359.613 seconds** and recorded **26,806 frame-timing samples**:

| Measurement | Observed result |
| --- | --- |
| Build p95 | 1.899 ms |
| Raster p95 | 1.400 ms |
| Total-span p95 | 3.401 ms |
| Total spans above 16.667 ms | 16 (about 0.06%) |

The JSON and completion screenshot are
`artifacts/animations/contact-rig/profile-web.json` and `profile-web.png`.
Android compilation overlapped part of the run; this is an observational local
measurement, not a controlled before/after benchmark. Total span is latency,
not a direct dropped-frame count, and build/raster phases can overlap. These
numbers do not certify 60 FPS on an ordinary Android device. The final runtime
was compiled for this run after the last Cuddle Time contact correction.

## Pending manual/external acceptance

- Physical Android normal-speed/slow-motion review, contact-frame stepping,
  sustained held inputs, touch latency, haptics/audio and native performance.
- Full artistic/reference-image comparison: original reference images and
  editable external rigs were unavailable.
- Fully authored rear/side/piggyback turn artwork and mesh deformation/weights.
  Current code uses rigid vector parts, corrective contours and curved arms.
- Live two-device Firebase delivery and backend emulator tests were not rerun;
  no backend/auth/pairing/inbox/reveal/schema/rules/dependency file was changed.
- No iOS device/build environment is available here.

The implementation is locally integrated and tested. Final professional visual
acceptance and ordinary-Android 60-FPS certification remain pending, rather than
being inferred from source compilation, screenshot export or a browser profile.
