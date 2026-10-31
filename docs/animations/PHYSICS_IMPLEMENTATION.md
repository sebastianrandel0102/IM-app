# Bear With Me — implementation and verification, 1 November 2026

This report supersedes the older contact-rig handoff for the files changed in
this pass. The starting commit was `01f3eb0`, with a clean working tree and
78 passing Flutter tests. A non-destructive tracked-source checkpoint is at
`.tools/physics-before-20261101.zip`.

## Reference usage and character models

The complete master specification was read from the supplied `Pasted text.txt`.
The four inline images were visually inspected before editing the models.
[REFERENCE_INTAKE.md](REFERENCE_INTAKE.md) records availability, dimensions,
purpose, inconsistencies and the initial six-gesture audit. None of the four
named PNG files has an accessible local path. Neither original illustration is
available, so original-versus-generated likeness cannot be certified.

The existing Dart vector system is retained and refined. The models have rigid
heads, separate face features, pivoted ears, torso contours, bounded curved arms,
rounded paw caps, hips/feet, shadows, and corrective sitting/lying geometry.
There is no new full-body PNG renderer, external animation dependency or Rive
binary. Rive remains the existing optional adapter; no editable Rive project
was supplied. This is a transform/path rig, not mesh skinning or soft-body
collision simulation.

Changes informed by the character sheets:

- Retain the white fill, oversized head, small eyes, thick brown outline and
  recognizable pink cheeks. Make cheeks circular and replace symmetric large
  inner-ear patches with the single small pink front-ear marking.
- Retain caramel coloring and the cream muzzle. Give the brown bear the small
  downward forked mouth from its sheet instead of the white bear's smile.
- Keep identifying ear details readable when the face turns toward a partner;
  do not blindly flip them with root facing. Hide the marking on rear views.
- Broaden the rounded torso contours slightly, preserving short limbs and
  keeping face geometry independent of torso squash.
- Refine the actual curled resting body with tilted, independently posed heads.
  Whole-character lying rotation stays zero.

Neutral editing handoffs are regenerated from the runtime contours in
`artifacts/animations/masters/brown.svg` and `white.svg`. Runtime has additional
corrective poses beyond these neutral masters. Older PNG masters describe the
earlier artwork and are not the current acceptance reference.

## Shared contact and physics design

`BearPlayback` remains the single animation clock, state machine, hold/release,
input gating, replay and interruption source. `TwoBearInteractionController`
authors intentional paired movement. `ContactAlignmentController` aligns posed
chest, front/rear paw, head-rest and forehead targets in the shared 400 × 340
scene. Viewport scaling is applied only when painting and converting touch
positions, so contact does not depend on screen dimensions.

The hug corrections lower and stagger the corrective front shoulder pivots,
thicken wrapping arms, and retain the rear-arm/body/head/front-arm draw passes.
Heads mask accidental arm crossings. The 64-unit arm reach remains bounded;
tests compare the actual rendered paw with the requested target, so silently
clamping an unreachable target fails verification. Contact is solved after the
small torso compression, breathing and shared spin projection.

`BearSecondaryMotion` adds 60-Hz fixed simulation steps with at most eight steps
of catch-up. The damped spring equation is
`w² × (target − position) − 2 × damping × w × velocity`, integrated using
semi-implicit Euler. Angular frequencies are 10–16 radians/second; damping
ratios are .73–1.0. Head, ear, paw, lean, compression and lift channels are
bounded. Props and blankets have separate spring channels. Contact impulses
are smaller for comfort/cozy scenes. Authored motion owns the pose; springs
provide restrained settling rather than ragdoll motion.

Lifecycle suspension drops accumulated background time and releases held local
paws. Hidden ticker suspension also releases touch state. The scene uses a
repaint notifier rather than rebuilding the widget tree per physics update.
Reduced motion preserves expression/contact while suppressing physical motion;
static reduced-motion previews stop requesting frames after settling.

## Hugs and cuddles: before and after

| Interaction | Earlier visible result | Current implementation |
| --- | --- | --- |
| Warm Hug | Thin diagonal arms near the neck, making the embrace hard to read. | Staggered broad front wraps below the heads, rear support arms, joined chest anchors, contact compression, breathing hold and authored release. |
| Comfort Hug | Seated support existed, but used the neck-level wrap and a low cushion. | Slow approach to a sad seated recipient, staggered support arms, relaxing face/head rest, couch back/arms/seat/feet, independent pat/stay controls. |
| Spinning Hug | Shared orbit existed, with the same difficult-to-read arm pose. | The same shared center and continuously solved contacts now use the corrected wraps, projected shoulder direction, rear facial visibility, depth ordering and settling. |
| Cuddle Time | Seated head support on a small cushion. | A visible couch supports bent legs; the receiver leans on the sender and rests a paw on the chest, distinct from the full hug wrap. Blanket/lamp/closer controls remain independent. |
| Sleep Together | Replacement body but almost upright heads. | Horizontal curled replacement bodies with different head tilts, joined paws, pillows, different breathing phases, blanket settling and no rotated standing model. |
| Goodnight Kiss | Sleeping recipient and forehead solve already existed. | Recipient's sleeping head is tilted before forehead alignment; kiss, temple touch, nearby seated ending, blanket and dimming remain separate stages. |

Compare the preserved [baseline](../../artifacts/animations/contact-rig/contact-brown.png)
with the [current priority sheet](../../artifacts/animations/physics/contact-brown.png).
Role reversal is visible in the [white-sender sheet](../../artifacts/animations/physics/contact-white.png).

## Gesture catalog

All 24 identifiers, payload versions and existing send/reveal contracts remain
unchanged. The remaining 18 specialized timelines were retained and refined;
they are not represented as 18 entirely new animations. Every row has automated
timeline/playback coverage and sampled raster review in both color roles.
Production artistic acceptance and physical-device playback remain pending for
the whole catalog; this table is an implementation inventory, not a claim of
24 fully accepted professional animations.

| Gesture | Implemented behavior / refinement |
| --- | --- |
| Warm Hug | Full shared wrap, staggered arms, compression, breathing and hold/release. |
| Cheek Kiss | Existing precise profile contact; distinct receiving paw lift, blush and happy-eye reaction. |
| Forehead Kiss | Existing forehead alignment; restrained receiving arm/eye reaction. |
| Hold Hands | Shared contact and walking; correct independent paw interpolation before attachment, removing premature cross-scene reach. |
| Blowing Kisses | Existing curved heart flight/catch; warmer receiving blush and corrected character details. |
| Good Morning | Starts on the lying-body replacement and rises through waking; short stretching arms remain reachable throughout the morph. |
| Head Pats | Existing crown/forehead contact, different happy eyes and ear follow-through. |
| Nose Boop | Existing nose contact/repeat/reversal; surprise and then relaxed eyes. |
| Happy Dance | Existing offset rhythmic feet/arms, expressive eyes, new character identity details and intensity-scaled secondary movement. |
| Piggyback Ride | Existing back attachment plus folded rider legs and an additional far-paw attachment. Still a stylized front/rear projection. |
| Tiny Tickles | Sender approaches far enough for actual paw contact; outward head correction preserves head clearance; stop/recovery retained. |
| High Five | Joined paw target, impact/ear follow-through; heads shift outward to expose the touching paws. |
| Spinning Hug | Shared projected orbit, corrected continuous wraps, depth and settling. |
| Cuddle Time | Seated shoulder/head support, chest-rest paw, actual couch and separate controls. |
| Goodnight Kiss | Tilted sleeping recipient, aligned forehead, temple touch and quiet ending. |
| Sleep Together | Curled lying bodies, tilted heads, joined paws and restrained resting motion. |
| Comfort Hug | Slow sad-to-relaxed supporting embrace, couch and reassuring controls. |
| Dry Your Tears | Existing cheek-wipe/tear fade; distinct receiving eye reaction and correct character mouth. |
| I Miss You | Existing sad-to-happy paw connection; sender acknowledgment and gentler receiving eyes. |
| One Umbrella | Existing shared handle/canopy staging; relaxed outside paw and receiving expression. |
| A Little Flower | Existing hidden reveal/bloom/transfer; shy offering head tilt and happy receiving eyes. |
| Heart Delivery | Existing weighted offer/stumble/transfer; receiving lean and outside paw adjustment. |
| A Tiny Surprise | Existing box anticipation/reveal; receiving outside paw rises with the surprise. |
| A Shy Confession | Existing hesitation/heart offering; distinct hidden paw lift, shy glance and blush. |

## Local touch and interface

The living home scene now accepts expressive local touch. Head, nose, cheek,
paw, belly and back regions follow current rig coordinates; letterboxing is
excluded. Nose/cheek/paw targets have precedence over broader body zones.
Flutter's gesture arena separates tap, double tap, long press and drag. Strokes
must cover at least 14 logical units, stay on the same region/actor, and avoid
large jumps. A rejected stroke cannot re-enter and trigger later.

Head tap gives curiosity; head stroke gives a happy tilt; nose gives surprise;
cheek gives shy blush; belly gives a physical wiggle; paw tap waves outside the
head silhouette; back strokes relax the body; double tap gives a small jump.
Home enables local touch. The deliberately opened Sleep Together player also
accepts gentle taps: the touched bear briefly opens its sleepy eyelids and its
head/ears settle. The existing tap-to-move-closer and swipe-to-wake controls are
preserved. Gesture previews do not intercept player controls.

Holding a paw retains that specific near/far paw's scene-space contact point,
then blends back on release. This is local affection; it never silently sends
a partner message. Sending uses the existing explicit gesture selection/send
flow, including the existing hugs, kisses and cuddle invitation.

Accessible custom semantics actions can pet either bear. A short home hint
explains touch. Settings persist an intensity slider alongside existing motion,
sound and haptic controls, with safe defaults for older saved preferences.
No talking, microphone, speech bubbles, voice recording, chat or lip sync was
added.

## Firebase and Together Mode

The existing protected two-document inbox design remains intact: metadata is
generic, and the receiver must deliberately open a moment before server rules
allow its payload to be fetched. Playback completion is separate from opening;
replay/history/memories and old interaction identifiers remain supported.

Together Mode still requires invitation and acceptance. It now carries the
acting user's `actionSenderUid`, uses the existing confirmed `updatedAt`
timestamp to start late clients at the corresponding point, and ignores pending
local-write estimates. Sequence changes identify new intents. No bone or
physics frames are uploaded. Old stored live events use the initiator fallback;
new live action writes must attribute the authenticated sender.

Rules reject an outsider, forged sender, omitted sender, early action before
acceptance, non-monotonic sequence and rapid repeated actions. Deploy the new
rules with the updated clients; old clients that omit the new live-action field
need the app update to send Together Mode actions. Stored inbox payload schemas
and older moments are unaffected. Rules were tested locally, not deployed.

No Functions, Storage, paid APIs, billing changes or new cloud infrastructure
were added. Animation and physics run locally. Firestore remains subject to
the existing Spark quotas; see the official
[Firebase pricing plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans).
The private inbox is the verified delivery surface. Closed-app push delivery
was not added. Together timestamp alignment uses client wall clocks and has not
been tested on two physical devices with clock skew/network delay.

## Validation

| Check | Result |
| --- | --- |
| Baseline Flutter suite | 78 passed. |
| Full final Flutter suite | **90 passed**, including visual exports, player interaction/lifecycle tests and sleepy touch alongside the existing wake swipe. |
| New physics/touch suite | 11 tests: fixed-step equivalence at 30/60/120/144 Hz, bounded catch-up, all reactions settling, zero intensity/reduced motion, moving hit zones, ambiguous-stroke rejection, near/far held paw stability, priority contact, settings compatibility, real pointer arbitration, and sleepy tap/wake-swipe coexistence. |
| All-gesture actual paw reach | 24 gestures × 3 variants × 2 motion settings × 121 samples = 17,424 paired poses / 69,696 endpoints, with no hidden reach-clamp errors. |
| Existing hug contact coverage | 3,864 paired held/orbit poses across front/rear paws, variants and motion settings. |
| Firestore rules | 35 tests passed, including sealed payload access and Together sender attribution. |
| Two-client Auth/Firestore emulators | Pairing, separate authenticated clients, warm-hug/cheek-kiss delivery, sealed-read denial, deliberate reveal, playback status, memories after sign-out/in, revocation passed. |
| Static analysis | No issues. |
| Android release | Final source built successfully; all seven package-verification checks passed. |
| Physical mobile device | None connected; native frame timing, sustained GPU performance, touch latency and device-level haptics/sound acceptance remain unverified. |

The tests caught and corrected a reduced-motion ticker regression, premature
Hold Hands paw snapping, unreachable Good Morning stretch extremes and a held
paw moving away from the contact point. Passing code/constraint tests alone are
not treated as artistic approval.

Final APK: `build/app/outputs/flutter-apk/app-release.apk`, 85,917,531 bytes.
SHA-256: `a5f5feb2cdfa39641ba2405b82b63347b19c62eddc4a5f1e803b33dbb12f8da7`.
`py scripts/verify-apk.py` verified the production Firebase project, private
membership packaging, arm64 release code, bundled font/sound, absence of the
emulator project and absence of service-account files. Machine-readable results
are in `artifacts/apk-verification.json`. The build emits upstream Kotlin/plugin
tooling warnings; dependencies and Firebase configuration were preserved.
`git diff --check` also passed. No installation on a mobile device is claimed.

Actual Flutter raster output is in `artifacts/animations/physics/`:
ten category/color sheets (288 cells), four exact priority/reduced-motion sheets
(120 cells), two orbit/control sheets (20 cells), and two touch sheets (100
cells). All 18 sheets were opened for visual inspection, along with the phone
and desktop home captures. These are sampled sequences, not a claim that every
frame of a normal/slow-motion recording was manually watched. The existing
standalone workbench remains available:

```powershell
flutter run -t tool/animation_review.dart -d chrome
flutter test --dart-define=ANIMATION_PASS=physics
flutter analyze --no-pub
powershell -File scripts/test-backend.ps1
```

## Modified project files

| Path (relative to repository) | Purpose |
| --- | --- |
| `lib/features/animation/presentation/bear_physics.dart` | New fixed-step springs and bounded actor/prop channels. |
| `lib/features/animation/presentation/bear_touch.dart` | New moving hit geometry and stroke arbitration. |
| `lib/features/animation/presentation/bear_artwork.dart` | Broader contours, ear marking, brown mouth and SVG export. |
| `lib/features/animation/presentation/bear_vector_rig.dart` | Character identity details and thicker contact arms. |
| `lib/features/animation/presentation/bear_choreography.dart` | Physics/touch composition, held-paw contact, gesture corrections and playback integration. |
| `lib/features/animation/presentation/two_bear_interaction.dart` | Staggered corrective shoulders, spring compression and sleeping head poses. |
| `lib/features/animation/presentation/bear_scene.dart` | Touch routing/semantics, lifecycle handling, couch, blanket/prop settling and late live start. |
| `lib/features/animation/presentation/player_screen.dart` | Persisted intensity and sleepy local touch integration, retaining existing tap/swipe controls. |
| `lib/features/home/presentation/home_screen.dart` | Interactive living bears, hint and preference-aware haptics. |
| `lib/features/settings/data/settings_repository.dart` | Compatible persisted intensity preference. |
| `lib/features/settings/presentation/settings_screen.dart` | Accessible intensity slider. |
| `lib/features/affection/presentation/affection_screens.dart` | Intensity in gesture preview. |
| `lib/features/affection/domain/models.dart` | Compatible live-event actor/timestamp fields. |
| `lib/features/together/data/live_session_repository.dart` | Attributed actions and confirmed timestamp stream. |
| `lib/features/together/presentation/together_screen.dart` | Actual actor role and timestamp-based late playback. |
| `firebase/firestore.rules` | Authenticated live-action attribution. |
| `firebase/tests/rules.test.mjs` | Positive/negative attribution and legacy-event transition coverage. |
| `test/bear_physics_touch_test.dart` | New physical, contact, preference and pointer verification. |
| `test/touch_visual_test.dart` | New real Flutter touch sequence export. |
| `test/interaction_visual_test.dart` | Named output pass preserves earlier comparison images. |
| `docs/animations/ARTWORK.md` | Points the historical handoff to the new implementation. |
| `docs/animations/REFERENCE_INTAKE.md` | Full reference availability/usage/audit report. |
| `docs/animations/PHYSICS_IMPLEMENTATION.md` | This report. |
| `artifacts/animations/masters/{brown,white}.svg` | Current editable neutral vector masters. |
| `artifacts/animations/physics/*.png` | 18 current review sheets. |
| `artifacts/home-{phone,desktop}.png` | Updated actual home UI captures. |
| `artifacts/apk-verification.json` | Final release package checks and SHA-256. |

## Remaining acceptance

Obtain the original illustrations for exact identity comparison and the four
separate PNG files if file-metadata verification is required. More fully authored
side/rear views would improve the projected spinning hug and piggyback pose;
the current rig is stylized rigid vector artwork, not a multi-view mesh export.
Run complete normal/quarter-speed playback and interruption review on an
ordinary Android device in both roles, including small/large screens, all
variants, accessibility, haptics/sound, clock skew and network interruption.
No additional paid service or approval is required for the implemented local
features. Backend deployment and any future push service remain separate work.
