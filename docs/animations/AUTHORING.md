# Rive asset authoring contract — pending external assets

No editable Rive files were supplied, and this project does not fabricate them.
`assets/rive/bear_world.riv` and its editable source are **not delivered**.
The app uses editable Flutter vector choreography documented in
[OVERHAUL.md](OVERHAUL.md). This document remains the authoring handoff for the
separate Rive deliverable; the vector rig does not edit an external Rive mesh.

## Visual authority

Use the two reference images attached in the request. Caramel bear: oversized
rounded head, dark chocolate outline, tiny eyes, cream muzzle, rounded body.
White bear: white head and body, tiny eyes, original little mouth, pink cheeks
and pink ear detail. Complete its lower body with the same proportions. No
photorealism, 3D redesign or human anime features. Preserve faces and outline.

Canvas: 800 × 680, ground baseline y=550. Normal idle root anchors x=274 and
x=526. Hug contact roots x=328 and x=472. Author anchors for forehead, cheek,
nose, paws and hips. Mirror pose logic while retaining each character's color.
Outlines: #352320, 5–6 px at authoring scale; fur #D2A06B / #FFFDFC, blush
#F4AFBF. Match the cream, lavender, pink and sage palette from app_theme.dart.

## Reusable layers and rig

`BrownBearRoot` and `WhiteBearRoot`, each with:

```
GroundShadow
LeftLeg / RightLeg
Body
LeftArm / LeftPawAnchor
RightArm / RightPawAnchor
Head
  LeftEar / LeftEarInner
  RightEar / RightEarInner
  LeftEye / RightEye / EyeClosedShapes
  Nose / Muzzle / Mouth
  LeftCheek / RightCheek
  ForeheadAnchor / CheekAnchor / NoseAnchor
Accessories (bow, scarf, flower)
Effects (heart, sparkle, tear, breath)
```

Keep arm and head rotation origins stable. Use translation for approach and
contact anchors for coordinated touch. Idle breathing: 3.8-second loop with
1.5% vertical body scale. Blink: 120 ms close/open, irregular 3–7-second gaps.
Subtle ears and cheeks must follow the head; do not animate face parts apart.

## Runtime interface

Bundle one coordinated `bear_world.riv` file (reusable nested character
artboards are encouraged), default artboard `OurWorld`, state machine
`BearWorld`, auto-bound default ViewModel instance. Export the editable source
separately in the authoring handoff.

ViewModel properties: Number `Action` (0 idle, then 1–24 in the exact order of
`AffectionType.values`); Number `SenderRole` (0 brown / 1 white); Number
`ReceiverRole`; Number `Variant` (0 gentle, 1 shy, 2 playful); Boolean `HoldActive`;
Boolean `ReducedMotion`; Trigger `TapTrigger`. The current adapter drives these
properties. Reserve Number `BlushIntensity`, `Theme`, `WalkOffset` and Trigger `ReactionTrigger`,
`CompleteTrigger` for the expanded authoring pass. Connect them in the adapter
before claiming those controls are wired to an authored rig.

State flow: Idle → Approach → Anticipation → InteractionStart → InteractionLoop
→ RecipientReaction → AwaitInput → InteractionEnd → Complete. Asset failures
return to the working development renderer and must not lose a moment.

## Core timelines (60 FPS)

Warm hug: 0–60f approach; 60–90f open arms/anticipation; 90–120f contact, close
eyes; 120–240f soft sway and blush; HoldActive loops the contact section;
release → 240–300f slowly separate; 300–360f smile and resolve. No detach while
the user holds. Tap alternative toggles holding for accessible operation.

Cheek kiss: 0–60f approach; 60–100f shy anticipation; 100–135f head tilt and
cheek contact; 135–165f heart pop; 165–220f receiver surprise → blush; 220–300f
await tap; TapTrigger swaps the *motion roles*, not physical character colors,
and plays a 90f return kiss; 300–360f resolve. Avoid overlapping head geometry.

Forehead kiss: 0–60f approach; 60–100f sender lowers head; 100–140f forehead
contact; 140–220f close eyes and pat; tap repeats contact, then resolve.

Hold hands: 0–60f look and extend paws; 60–100f receiver reaches; 100–140f
contact; loop holds both paw anchors together; swipes translate both roots
within the scene's visible bounds. Accessible arrow buttons provide equivalent
walk controls.

## Additional scene specifications

| Interaction | Primary action and reaction | Awaited input / resolution |
| --- | --- | --- |
| Head pat | Raise paw, 3 soft pats, recipient eyes close, ears wiggle | Tap repeats 120f pat loop |
| Nose boop | Paw touches nose, surprised blink, small heart | 3 taps reverse motion roles |
| Cuddle | Sit on couch, lean, arm rests around shoulder | Tap blanket covers both |
| Goodnight | Tuck blanket, kiss forehead, soft wave | Lamp tap dims room, stars appear |
| Sleep together | Lie facing one another, touching paws, breathing | Closer / hold hands / wake controls |
| Blowing kisses | Paw to mouth, blow heart, heart flies to recipient | Tap catches and lands it on cheek |
| Flower surprise | Hidden flower revealed, recipient smiles and accepts | Tap blooms and reveals note |
| Comfort hug | Sad recipient seated, sender approaches, joins and hugs | Stay / repeat; no abrupt separation |
| Dry tears | Sender wipes one stylized tear, recipient smiles | Tap removes tear and softens expression |
| Happy dance | Shy invitation, silly step, both sway | Tap selects next 180f dance loop |
| Piggyback | Crouch, climb, stand, walk with stable hip anchor | Swipe bounded walking |
| Tiny tickles | Gentle tickle, laughing expression, small wiggle | Tap continues; Stop resolves immediately |
| I miss you | Seated under moon, sender joins, paws meet | Moon tap reveals note |
| Heart delivery | Carry large heart, small stumble, offer and receive | Heart tap reveals note |
| Good morning | Sleeping receiver, sender approaches, gentle wake | Sun tap brightens scene |
| Surprise box | Present closed box, curious expression, tiny shake | Box tap opens with heart/flower and note |
| High five | Raise compatible paw anchors, bring together | Timed tap adds sparkle |
| Spinning hug | Approach, hug, one slow coordinated turn, laugh | Tap extra turn; no turn with reduced motion |
| Shy confession | Hold small heart, shy approach, offer and receive | Heart tap reveals note |
| One umbrella | Rain, sender brings umbrella, receiver steps under | Tap moves closer, hands touch |

Default scenes should last 5–8 seconds before an optional input loop. Use short
easing, gentle squash and stretch, aligned contacts and explicit recipient
reactions. All 24 scenes must pass both brown→white and white→brown playback.
Reduced motion removes spinning, bouncing, moving rain and extra particles,
while preserving static contact and note reveal. No sudden sound on load.

## Acceptance before enabling authored assets

Verify exact artboard/state machine/ViewModel names with Rive Flutter 0.14.11,
both role directions, missing-file fallback, holding/release, return kiss,
scene bounds, Stop, app lifecycle pause, system reduced-motion setting, Android
GPU performance, and resource disposal. The advanced scene table is an
authoring specification; development painter poses are not certification that
these bespoke Rive timelines exist.

Runtime reference verified 2026-10-30:
https://rive.app/docs/runtimes/flutter/flutter (stable 0.14.11; 0.15 is dev).
