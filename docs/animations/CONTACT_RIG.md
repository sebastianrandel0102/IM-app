# Shared contact rig implementation — 2026-10-31 (Asia/Manila)

This pass implements the supplied hug/cuddle reconstruction request in the
existing Flutter app. Baseline: `c596feb`, with a clean Git working tree and
**67 passing Flutter tests**. Before editing, `git archive` saved the tracked
source to `.tools/contact-rig-before-20261031.zip`. Existing user changes were
not present. Older overhaul/refinement reports describe earlier builds.

## Initial audit

The active renderer was already editable Dart vector artwork, not whole-body
PNGs. `BearScene` owns a lifecycle-aware ticker, `BearPlayback` owns time,
completion, input windows and interruption blending, and `BearScenePainter`
renders `BearPose` values. Both characters already had heads, ears, facial
features, torsos, arms and a complete lower body. Rive is an existing opt-in
adapter; `assets/rive/` contains no `.riv` file or editable Rive project.
Original bear reference PNG/JPEG/SVG images were not supplied. This pass retains
the app's existing caramel/cream palette, outlines, head paths and facial design.
It does not claim a new reference trace, Rive export or mesh-weight edit.

Code inspection and the existing `artifacts/animations/polished/` render sheets
confirmed the following problems before changes:

| Gesture | Severity | Confirmed baseline problem | Implemented correction |
| --- | --- | --- | --- |
| Warm Hug | Critical | Shared switch block moved both roots inward, offset the heads outward and targeted only front paws. Far arms remained independent. The visible pose read as two standing bears beside each other. | Both chest anchors close together, both front paws target the partner's torso, and both rear paws wrap behind the partner. Welcome, reach, compression, delayed eye closure, breathing, release and ending remain on the shared timeline. |
| Comfort Hug | Critical | Shared Warm Hug track stayed standing; sadness changed the face without a seated supporting silhouette. | Recipient starts seated and sad. Sender approaches, sits, wraps and supports a head rest. Recipient's smile recovers slowly. Optional temple pat and stay-beside controls have separate channels. |
| Spinning Hug | Major | Projected orbit moved roots and necks, while shoulders remained in their original forward orientation. Contact could exceed the arm's reach when the pair changed sides. | One shared orbit projects both actors around their common center; shoulder orientation follows that projection, the turn compresses gently, depth changes drawing order and rear facial visibility, and paws are retargeted after projection. |
| Cuddle Time | Critical | Sitting shortened standing legs but retained the same symmetric hug and did not solve a head-rest contact. Blanket taps had no separate lamp/close controls. | Both start seated with bent legs/forward feet; recipient's head is aligned to a support point beside the sender's shoulder/head edge. Blanket, lamp and gentle tightening have independent eased inputs. |
| Sleep Together | Critical | Standing/seated models were rotated by opposite 0.68-radian angles. No horizontal body replacement or pillow support existed. | Separate curled, horizontal torso/leg/foot geometry starts on pillows; whole-character lying rotation is zero. Paws meet between the posed shoulders and remain joined while breathing. |
| Goodnight Kiss | Major | Recipient used a partly seated standing model. Bedtime shared the general forehead-kiss block. | Recipient starts on the sleeping replacement body, yawns and closes their eyes; sender approaches, kisses the forehead, touches the temple, settles nearby and dims the lamp. |
| Shared renderer | Major | Arms were drawn inside each bear and then redrawn in the foreground, with only the owner's head masked. | Explicit rear-arm, torso/leg, head/face and foreground-arm passes draw each arm once. Foreground arms mask both heads, except intentional face-touch targets. |
| Shared tools | Minor | Review tool supported timeline controls but no contact-anchor/bounds visualization. | Workbench adds roots, shoulder pivots, anchors, paw endpoints, target lines, bounds, roles, facing, scale, progress and stage. |

Initial source inspection confirmed the mathematical limitations. Rendered
sheets confirmed the visible standing/reclined poses. Neither code inspection
nor passing tests alone certifies professional visual quality on a device.

## Implementation and modified files

| File | Change |
| --- | --- |
| `lib/features/animation/presentation/two_bear_interaction.dart` | Shared `TwoBearInteractionController`, `ContactAlignmentController`, typed contacts, six independent scene-control channels and eased input values. It is a part of the existing choreography library, using the same playback clock. |
| `lib/features/animation/presentation/bear_pose_library.dart` | 24 reusable local pose presets: neutral/happy/shy/sad, open/reaching arms, front/side/held/released hug, sitting/close/cuddle/resting, lying/sleeping, kiss, hand-hold, pat, carrying, piggyback and surprise. These are local vector rig corrections, not 24 external art files. |
| `lib/features/animation/presentation/bear_choreography.dart` | Routes the six priority scenes through the shared solver; retains all other gesture tracks and existing identifiers. Adds resting/contact geometry fields, head-rest and foot anchors, rigid scene-space head adjustment, explicit release stage and local control transitions/reset. |
| `lib/features/animation/presentation/bear_artwork.dart` | Morphable seated, embracing and horizontal curled torso contours, using the original palette and outline style. |
| `lib/features/animation/presentation/bear_vector_rig.dart` | Separately selectable body/head passes, posed shoulder pivots, constrained arm curves, rounded paw caps, bent seated legs/feet, horizontal resting feet and rear facial visibility. Head geometry stays rigid during torso compression. |
| `lib/features/animation/presentation/bear_scene.dart` | Shared cross-character layer order, partner head masks, pillows, lower blanket edge, dimming and workbench-only diagnostic painter flags. |
| `lib/features/animation/presentation/player_screen.dart` | Contact-gated, independent comfort/cuddle/sleep controls; replay clears those selections. Existing hold/release, return affection, swipe, Stop, completion and protected reveal flow are retained. |
| `tool/animation_review.dart` | Anchor/bounds toggles and scene controls alongside existing pause, restart, 60-Hz step, quarter speed, role reversal, variants and reduced motion. |
| `test/two_bear_interaction_test.dart` | Tests rendered front/rear paw reach during every held/orbit sample, posed support geometry, distinct initial scenes, mirrored anchors, independent input channels and all 24 pose presets. |
| `test/interaction_visual_test.dart` | Exports exact first-contact/hold/release samples, the middle of the spin, independent controls and reduced-motion sheets in both bear roles. |
| `test/animation_player_test.dart` | Exercises the new real player buttons, readiness and replay reset. |
| `test/animation_test.dart` | Existing 24-gesture reach check now uses the actual posed shoulder instead of assuming a standing shoulder location. |

The new anchors are character-relative and use the same root, facing, torso
compression, sit offset and head/neck transforms as rendering. Existing anchors
remain compatible. The solver recomputes wrap endpoints after breathing and
orbit projection. Arm length stays capped at 64 logical pixels; the new tests
also compare the actual rendered endpoint with the requested endpoint, so a
clamped, unreachable paw cannot silently pass as contact. `headRest` is a
stylized support point at the sender's head edge, immediately above the shoulder;
the large original head proportions do not permit a realistic human neck pose.

This is rigid vector posing with corrective contours and bounded curved arms.
It does not provide mesh skinning or physically simulated soft-body collision.
Spinning remains a stylized upright 2D orbit with depth/occlusion, not a fully
authored 3D or multi-view turntable. Lying bodies are curled replacement drawings
with mostly upright readable faces, not whole-standing-model rotations.

## Complete gesture catalog

All 24 existing gesture IDs, names, Firestore payloads, gesture-specific
choreography and input contracts remain supported. The remaining 18 retain their
existing specialized tracks and gain the shared layer/paw/rendering corrections;
they are not described as 18 wholly new animations.

| Existing gesture | Result in this pass |
| --- | --- |
| Warm Hug | Shared full embrace, both front and rear contacts, compression and live breathing hold |
| Cheek Kiss | Existing muzzle-to-cheek solver/return kiss retained; partner-aware arm masking |
| Forehead Kiss | Existing forehead solver/return kiss retained; one-pass arm drawing |
| Hold Hands | Existing shared paw connection and distance-driven walking retained; rounded paw cap |
| Blowing Kisses | Existing paw arc/heart catch retained; head-safe arm layers |
| Good Morning | Existing wake/stretch track retained; seated lower-body correction |
| Head Pats | Existing crown alignment retained; intentional recipient-head contact remains visible |
| Nose Boop | Existing nose constraint/repeat retained; intentional facial contact exception |
| Happy Dance | Existing rhythmic feet/arms and weights retained; cleaner arm composition |
| Piggyback Ride | Existing back attachment retained; rear/front body ordering retained without duplicate arms |
| Tiny Tickles | Existing laughter/wiggle/Stop retained; arm cannot draw through either head |
| High Five | Existing shared impact target/tap window retained; rounded contact paws |
| Spinning Hug | Shared grounded orbit, depth-facing layer and continuous shoulder/paw alignment |
| Cuddle Time | Seated support/head-rest contact; separate blanket/lamp/tightening controls |
| Goodnight Kiss | Sleeping recipient, yawn, forehead contact, temple touch, nearby seated ending |
| Sleep Together | Curled horizontal body replacement, pillows, joined paws and restrained breathing |
| Comfort Hug | Sad seated recipient, quiet approach/sit, wrap, support, pat and stay controls |
| Dry Your Tears | Existing cheek wipe/tear fade retained; face-contact layering remains available |
| I Miss You | Existing sad-to-happy/holding paws retained; better seated leg silhouette |
| One Umbrella | Existing canopy sway/shared handle retained; head-safe arm rendering |
| A Little Flower | Existing hidden/reveal/bloom track retained; single front-paw cap |
| Heart Delivery | Existing weighted offer/stumble retained; cleaner near/rear arm composition |
| A Tiny Surprise | Existing anticipation/open box/recipient surprise retained; head-safe arms |
| A Shy Confession | Existing hesitation/gaze/blush retained; no catalog or reveal change |

Existing `gentle`, `shy` and `playful` variant identifiers remain valid. They
adjust pace, expression and secondary motion. No renamed/new public catalog
entries or incompatible variant IDs were introduced. The new 24-pose library
provides reusable corrections; difficult rear/profile artwork still benefits
from a dedicated artist-authored multi-view source.

## Before and after

Baseline sheets are preserved in `artifacts/animations/polished/`.
New category sheets are in `artifacts/animations/contact-rig/`.

- [Before: cozy scenes](../../artifacts/animations/polished/cozy-brown.png)
- [After: cozy scenes](../../artifacts/animations/contact-rig/cozy-brown.png)
- [Before: comfort scenes](../../artifacts/animations/polished/comfort-brown.png)
- [After: comfort scenes](../../artifacts/animations/contact-rig/comfort-brown.png)
- [Exact contact/hold/release samples](../../artifacts/animations/contact-rig/contact-brown.png)
- [Orbit and independent controls](../../artifacts/animations/contact-rig/orbit-controls-brown.png)

Companion `white` sheets reverse sender/receiver color roles. `-reduced` sheets
exercise the same priority contact poses with continuous motion suppressed.

## Verification and remaining acceptance

Current check results are recorded in [CONTACT_RIG_QA.md](CONTACT_RIG_QA.md).
Use the standalone workbench without Firebase:

```powershell
flutter run -t tool/animation_review.dart -d chrome
flutter analyze
flutter test --dart-define=ANIMATION_PASS=contact-rig
flutter run --profile -t tool/animation_profile.dart -d chrome
```

For each of the six priority gestures, the manual device checklist is:

- [ ] Play the entire scene at normal speed and quarter speed.
- [ ] Step through first contact, maximum contact, held breathing and release.
- [ ] Inspect both rear/front arms, head silhouettes, muzzle, seat/feet and blanket.
- [ ] Hold and release repeatedly; repeat during recovery; replay after completion.
- [ ] Toggle each applicable blanket/lamp/closer/pat/stay/paw control independently.
- [ ] Reverse sender color, try all three variants and repeat at a small phone size.
- [ ] Enable reduced motion, background/resume and leave/reopen the player.
- [ ] Profile on an ordinary physical Android device, checking build/raster time,
      touch latency, haptics and sustained playback.

Automated and sampled visual checks do not mark that manual physical-device
checklist complete. No Android/iOS device is connected. Original reference
images and editable Rive/mesh projects remain unavailable; exact reference
matching, artist-authored rear/side turn artwork and native-device performance
acceptance remain external deliverables. Existing authoring guidance is in
[ARTWORK.md](ARTWORK.md) and [AUTHORING.md](AUTHORING.md).

Firebase Auth, login/registration, pairing, protected open-to-reveal, inbox,
delivery, history, memories, rules, plans and dependencies are unchanged. All
posing runs locally. No bone/frame data is uploaded, no backend deployment or
real account message was performed, and no paid service was introduced.
